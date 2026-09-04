class_name PortableInventoryResolver
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const ContentLookupResultScript := preload(
	"res://src/content/content_lookup_result.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)


static func resolve(
	state_candidate: RefCounted,
	registry: RefCounted,
) -> PortableInventoryResolutionResultScript:
	if not _is_exact_state(state_candidate):
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_INVENTORY_STATE
		)
	var candidate: PortableInventoryStateScript = (
		state_candidate as PortableInventoryStateScript
	).copy()
	if not candidate._initialized:
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_INVENTORY_STATE
		)
	if candidate._content_schema_version <= 0:
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_CONTENT_SCHEMA_VERSION
		)
	if candidate._content_version <= 0:
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_CONTENT_VERSION
		)
	if not PortableInventoryStateScript.is_supported_capacity(candidate._capacity):
		return _failure(
			PortableInventoryResolutionResultScript.FailureReason.INVALID_CAPACITY
		)
	if (
		candidate._revision < 0
		or candidate._revision > PortableInventoryStateScript.MAXIMUM_REVISION
	):
		return _failure(
			PortableInventoryResolutionResultScript.FailureReason.INVALID_REVISION
		)
	if not candidate._stack_input_types_valid:
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_STACK_COLLECTION
		)

	var stacks: Array[PortableInventoryStackScript] = []
	for stack: PortableInventoryStackScript in candidate._stacks:
		if not _is_exact_stack(stack):
			return _failure(
				PortableInventoryResolutionResultScript
				.FailureReason
				.INVALID_STACK_COLLECTION
			)
		var copied_stack: PortableInventoryStackScript = stack.copy()
		if not PortableInventoryStackScript.is_valid_stack_id(
			copied_stack._stack_id
		):
			return _failure(
				PortableInventoryResolutionResultScript.FailureReason.INVALID_STACK_ID,
				copied_stack._stack_id,
			)
		if String(copied_stack._blueprint_id).is_empty():
			return _failure(
				PortableInventoryResolutionResultScript.FailureReason.EMPTY_BLUEPRINT_ID,
				copied_stack._stack_id,
			)
		if (
			copied_stack._quantity < 1
			or copied_stack._quantity > PortableInventoryStackScript.MAXIMUM_QUANTITY
		):
			return _failure(
				PortableInventoryResolutionResultScript.FailureReason.INVALID_QUANTITY,
				copied_stack._stack_id,
			)
		if copied_stack._provenance not in [
			PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE,
			PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT,
		]:
			return _failure(
				PortableInventoryResolutionResultScript.FailureReason.INVALID_PROVENANCE,
				copied_stack._stack_id,
			)
		if (
			(
				copied_stack._provenance
				== PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE
				and String(copied_stack._source_recipe_id).is_empty()
			)
			or (
				copied_stack._provenance
				== PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT
				and not String(copied_stack._source_recipe_id).is_empty()
			)
		):
			return _failure(
				(
					PortableInventoryResolutionResultScript
					.FailureReason
					.INVALID_PROVENANCE_RECIPE_REFERENCE
				),
				copied_stack._stack_id,
			)
		stacks.append(copied_stack)
	stacks.sort_custom(_stack_less_than)
	for index: int in range(1, stacks.size()):
		if stacks[index].stack_id() == stacks[index - 1].stack_id():
			return _failure(
				PortableInventoryResolutionResultScript
				.FailureReason
				.DUPLICATE_STACK_ID,
				stacks[index].stack_id(),
			)
	if stacks.size() > candidate._capacity:
		return _failure(
			PortableInventoryResolutionResultScript.FailureReason.CAPACITY_EXCEEDED
		)

	var selected_stack_id: StringName = (
		candidate._selected_temporary_effect_stack_id
	)
	if (
		not String(selected_stack_id).is_empty()
		and not PortableInventoryStackScript.is_valid_stack_id(selected_stack_id)
	):
		return _failure(
			(
				PortableInventoryResolutionResultScript
				.FailureReason
				.INVALID_SELECTED_STACK_ID
			),
			selected_stack_id,
		)
	if not String(selected_stack_id).is_empty() and not _has_stack(
		stacks,
		selected_stack_id,
	):
		return _failure(
			(
				PortableInventoryResolutionResultScript
				.FailureReason
				.UNKNOWN_SELECTED_STACK_ID
			),
			selected_stack_id,
		)

	if not _is_exact_initialized_registry(registry):
		return _failure(
			PortableInventoryResolutionResultScript.FailureReason.INVALID_REGISTRY
		)
	var sealed_registry: ContentRegistryScript = registry as ContentRegistryScript
	if candidate._content_schema_version != sealed_registry.schema_version():
		return _failure(
			(
				PortableInventoryResolutionResultScript
				.FailureReason
				.CONTENT_SCHEMA_VERSION_MISMATCH
			)
		)
	if candidate._content_version != sealed_registry.content_version():
		return _failure(
			PortableInventoryResolutionResultScript
			.FailureReason
			.CONTENT_VERSION_MISMATCH
		)

	var blueprints_by_stack_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
	for stack: PortableInventoryStackScript in stacks:
		var blueprint_lookup: ContentLookupResultScript = (
			sealed_registry.lookup_blueprint(stack.blueprint_id())
		)
		if (
			blueprint_lookup == null
			or blueprint_lookup.get_script() != ContentLookupResultScript
		):
			return _failure(
				(
					PortableInventoryResolutionResultScript
					.FailureReason
					.INVALID_BLUEPRINT_DEFINITION
				),
				stack.stack_id(),
				stack.blueprint_id(),
			)
		if not blueprint_lookup.succeeded():
			return _failure(
				PortableInventoryResolutionResultScript
				.FailureReason
				.UNKNOWN_BLUEPRINT_ID,
				stack.stack_id(),
				stack.blueprint_id(),
			)
		var blueprint: BlueprintDefinitionScript = blueprint_lookup.blueprint()
		if (
			blueprint == null
			or blueprint.get_script() != BlueprintDefinitionScript
			or blueprint.content_id != stack.blueprint_id()
		):
			return _failure(
				(
					PortableInventoryResolutionResultScript
					.FailureReason
					.INVALID_BLUEPRINT_DEFINITION
				),
				stack.stack_id(),
				stack.blueprint_id(),
			)
		blueprints_by_stack_id[stack.stack_id()] = blueprint
		if (
			stack.provenance()
			== PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE
		):
			var recipe_lookup: ContentLookupResultScript = (
				sealed_registry.lookup_recipe(stack.source_recipe_id())
			)
			if (
				recipe_lookup == null
				or recipe_lookup.get_script() != ContentLookupResultScript
			):
				return _failure(
					(
						PortableInventoryResolutionResultScript
						.FailureReason
						.INVALID_RECIPE_DEFINITION
					),
					stack.stack_id(),
					stack.source_recipe_id(),
				)
			if not recipe_lookup.succeeded():
				return _failure(
					PortableInventoryResolutionResultScript
					.FailureReason
					.UNKNOWN_RECIPE_ID,
					stack.stack_id(),
					stack.source_recipe_id(),
				)
			var recipe: RecipeDefinitionScript = recipe_lookup.recipe()
			if (
				recipe == null
				or recipe.get_script() != RecipeDefinitionScript
				or recipe.recipe_id != stack.source_recipe_id()
			):
				return _failure(
					(
						PortableInventoryResolutionResultScript
						.FailureReason
						.INVALID_RECIPE_DEFINITION
					),
					stack.stack_id(),
					stack.source_recipe_id(),
				)
			if recipe.output_blueprint_id != stack.blueprint_id():
				return _failure(
					(
						PortableInventoryResolutionResultScript
						.FailureReason
						.RECIPE_BLUEPRINT_MISMATCH
					),
					stack.stack_id(),
					stack.source_recipe_id(),
				)

	if not String(selected_stack_id).is_empty():
		var selected_blueprint: BlueprintDefinitionScript = (
			blueprints_by_stack_id[selected_stack_id]
		)
		if not PortableInventoryStateScript.is_valid_temporary_effect_definition(
			selected_blueprint
		):
			return _failure(
				(
					PortableInventoryResolutionResultScript
					.FailureReason
					.SELECTED_STACK_NOT_TEMPORARY_EFFECT
				),
				selected_stack_id,
				selected_blueprint.content_id,
			)

	var resolved_state: PortableInventoryStateScript = (
		PortableInventoryStateScript.create(
			candidate._content_schema_version,
			candidate._content_version,
			candidate._capacity,
			candidate._revision,
			stacks,
			selected_stack_id,
		)
	)
	if (
		not resolved_state.is_valid()
		or not resolved_state.is_resolved_against(sealed_registry)
	):
		return _failure(
			PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT
		)
	return PortableInventoryResolutionResultScript.success(
		resolved_state,
		sealed_registry,
	)


static func _failure(
	failure_reason: int,
	failed_stack_id: StringName = &"",
	failed_content_id: StringName = &"",
) -> PortableInventoryResolutionResultScript:
	return PortableInventoryResolutionResultScript.failure(
		failure_reason,
		failed_stack_id,
		failed_content_id,
	)


static func _has_stack(
	stacks: Array[PortableInventoryStackScript],
	stack_id: StringName,
) -> bool:
	for stack: PortableInventoryStackScript in stacks:
		if stack.stack_id() == stack_id:
			return true
	return false


static func _is_exact_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryStateScript
	)


static func _is_exact_stack(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryStackScript
	)


static func _is_exact_initialized_registry(registry: RefCounted) -> bool:
	return (
		registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
		and (registry as ContentRegistryScript).is_initialized()
	)


static func _stack_less_than(
	left: PortableInventoryStackScript,
	right: PortableInventoryStackScript,
) -> bool:
	return String(left.stack_id()) < String(right.stack_id())
