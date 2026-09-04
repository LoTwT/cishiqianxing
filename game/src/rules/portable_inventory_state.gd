class_name PortableInventoryState
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
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)

const INITIAL_CAPACITY: int = 12
const CHAPTER_THREE_CAPACITY: int = 16
const CHAPTER_FIVE_CAPACITY: int = 20
const MAXIMUM_CAPACITY: int = 24
const MAXIMUM_REVISION: int = 9_223_372_036_854_775_807
const _TEMPORARY_EFFECT_BLUEPRINT_CONTRACTS := {
	&"blueprint.20": [
		ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
		20,
		&"mechanic.blueprint.next_battle_attack",
	],
	&"blueprint.21": [
		ContactCombatCommandScript.TemporaryEffect.DEFENSE_2,
		21,
		&"mechanic.blueprint.next_battle_defense",
	],
	&"blueprint.22": [
		ContactCombatCommandScript.TemporaryEffect.SPEED_2,
		22,
		&"mechanic.blueprint.next_battle_speed",
	],
	&"blueprint.23": [
		ContactCombatCommandScript.TemporaryEffect.ATTACK_SPEED_2,
		23,
		&"mechanic.blueprint.next_battle_attack_speed",
	],
	&"blueprint.24": [
		ContactCombatCommandScript.TemporaryEffect.ATTACK_DEFENSE_2,
		24,
		&"mechanic.blueprint.next_battle_attack_defense",
	],
}

var _content_schema_version: int = 0
var _content_version: int = 0
var _capacity: int = 0
var _revision: int = 0
var _stacks: Array[PortableInventoryStackScript] = []
var _selected_temporary_effect_stack_id: StringName = &""
var _initialized: bool = false
var _stack_input_types_valid: bool = true


func _init() -> void:
	_stacks.make_read_only()


static func create(
	content_schema_version: int,
	content_version: int,
	capacity: int,
	revision: int,
	stack_candidates: Array,
	selected_temporary_effect_stack_id: StringName = &"",
) -> PortableInventoryState:
	var state := new()
	state._content_schema_version = content_schema_version
	state._content_version = content_version
	state._capacity = capacity
	state._revision = revision
	state._stacks = state._copy_stack_candidates(stack_candidates)
	state._stacks.sort_custom(_stack_less_than)
	state._selected_temporary_effect_stack_id = (
		selected_temporary_effect_stack_id
	)
	state._initialized = true
	state._stacks.make_read_only()
	return state


func copy() -> PortableInventoryState:
	var copied_state := new()
	var copied_stacks: Array[PortableInventoryStackScript] = []
	for stack: PortableInventoryStackScript in _stacks:
		if _is_exact_stack(stack):
			copied_stacks.append(stack.copy())
		else:
			copied_state._stack_input_types_valid = false
	copied_state._content_schema_version = _content_schema_version
	copied_state._content_version = _content_version
	copied_state._capacity = _capacity
	copied_state._revision = _revision
	copied_state._stacks = copied_stacks
	copied_state._selected_temporary_effect_stack_id = (
		_selected_temporary_effect_stack_id
	)
	copied_state._initialized = _initialized
	copied_state._stack_input_types_valid = (
		copied_state._stack_input_types_valid and _stack_input_types_valid
	)
	copied_state._stacks.make_read_only()
	return copied_state


func is_valid() -> bool:
	if (
		not _initialized
		or not _stack_input_types_valid
		or _content_schema_version <= 0
		or _content_version <= 0
		or not is_supported_capacity(_capacity)
		or _revision < 0
		or _revision > MAXIMUM_REVISION
		or _stacks.size() > _capacity
		or not _stacks_are_canonical_and_unique()
	):
		return false
	var selected_stack_exists: bool = (
		String(_selected_temporary_effect_stack_id).is_empty()
	)
	for stack: PortableInventoryStackScript in _stacks:
		if not _is_exact_stack(stack) or not stack.is_valid():
			return false
		if stack.stack_id() == _selected_temporary_effect_stack_id:
			selected_stack_exists = true
	return (
		selected_stack_exists
		and (
			String(_selected_temporary_effect_stack_id).is_empty()
			or PortableInventoryStackScript.is_valid_stack_id(
				_selected_temporary_effect_stack_id
			)
		)
	)


static func is_supported_capacity(candidate: int) -> bool:
	return candidate in [
		INITIAL_CAPACITY,
		CHAPTER_THREE_CAPACITY,
		CHAPTER_FIVE_CAPACITY,
		MAXIMUM_CAPACITY,
	]


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func capacity() -> int:
	return _capacity


func occupied_slot_count() -> int:
	return _stacks.size()


func available_slot_count() -> int:
	return _capacity - _stacks.size() if is_valid() else 0


func revision() -> int:
	return _revision


func stack_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for stack: PortableInventoryStackScript in _stacks:
		if _is_exact_stack(stack):
			ids.append(stack.stack_id())
	return ids


func stack_snapshots() -> Array[PortableInventoryStackScript]:
	var copied_stacks: Array[PortableInventoryStackScript] = []
	for stack: PortableInventoryStackScript in _stacks:
		if _is_exact_stack(stack):
			copied_stacks.append(stack.copy())
	return copied_stacks


func stack_snapshot(stack_id: StringName) -> PortableInventoryStackScript:
	if not PortableInventoryStackScript.is_valid_stack_id(stack_id):
		return null
	for stack: PortableInventoryStackScript in _stacks:
		if _is_exact_stack(stack) and stack.stack_id() == stack_id:
			return stack.copy()
	return null


func selected_temporary_effect_stack_id() -> StringName:
	return _selected_temporary_effect_stack_id


func selected_temporary_effect_blueprint_id() -> StringName:
	var stack: PortableInventoryStackScript = stack_snapshot(
		_selected_temporary_effect_stack_id
	)
	return stack.blueprint_id() if stack != null else &""


func selected_temporary_effect() -> int:
	return temporary_effect_for_blueprint_id(
		selected_temporary_effect_blueprint_id()
	)


static func temporary_effect_for_blueprint_id(blueprint_id: StringName) -> int:
	if not _TEMPORARY_EFFECT_BLUEPRINT_CONTRACTS.has(blueprint_id):
		return ContactCombatCommandScript.TemporaryEffect.NONE
	var contract: Array = _TEMPORARY_EFFECT_BLUEPRINT_CONTRACTS[blueprint_id]
	return contract[0]


func is_resolved_against(registry: RefCounted) -> bool:
	if not is_valid() or not _is_exact_initialized_registry(registry):
		return false
	var sealed_registry: ContentRegistryScript = registry as ContentRegistryScript
	if (
		_content_schema_version != sealed_registry.schema_version()
		or _content_version != sealed_registry.content_version()
	):
		return false
	var selected_definition: BlueprintDefinitionScript
	for stack: PortableInventoryStackScript in _stacks:
		var blueprint_lookup: ContentLookupResultScript = (
			sealed_registry.lookup_blueprint(stack.blueprint_id())
		)
		if (
			blueprint_lookup == null
			or blueprint_lookup.get_script() != ContentLookupResultScript
			or not blueprint_lookup.succeeded()
		):
			return false
		var blueprint: BlueprintDefinitionScript = blueprint_lookup.blueprint()
		if (
			blueprint == null
			or blueprint.get_script() != BlueprintDefinitionScript
			or blueprint.content_id != stack.blueprint_id()
		):
			return false
		if stack.provenance() == PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE:
			var recipe_lookup: ContentLookupResultScript = (
				sealed_registry.lookup_recipe(stack.source_recipe_id())
			)
			if (
				recipe_lookup == null
				or recipe_lookup.get_script() != ContentLookupResultScript
				or not recipe_lookup.succeeded()
			):
				return false
			var recipe: RecipeDefinitionScript = recipe_lookup.recipe()
			if (
				recipe == null
				or recipe.get_script() != RecipeDefinitionScript
				or recipe.recipe_id != stack.source_recipe_id()
				or recipe.output_blueprint_id != stack.blueprint_id()
			):
				return false
		if stack.stack_id() == _selected_temporary_effect_stack_id:
			selected_definition = blueprint
	if String(_selected_temporary_effect_stack_id).is_empty():
		return true
	return is_valid_temporary_effect_definition(selected_definition)


func is_equal_to(other: PortableInventoryState) -> bool:
	if (
		other == null
		or not is_instance_valid(other)
		or other.get_script() != get_script()
		or other._initialized != _initialized
		or other._stack_input_types_valid != _stack_input_types_valid
		or other._content_schema_version != _content_schema_version
		or other._content_version != _content_version
		or other._capacity != _capacity
		or other._revision != _revision
		or (
			other._selected_temporary_effect_stack_id
			!= _selected_temporary_effect_stack_id
		)
		or other._stacks.size() != _stacks.size()
	):
		return false
	for index: int in range(_stacks.size()):
		if (
			not _is_exact_stack(_stacks[index])
			or not _is_exact_stack(other._stacks[index])
			or not _stacks[index].is_equal_to(other._stacks[index])
		):
			return false
	return true


func _copy_stack_candidates(
	stack_candidates: Array,
) -> Array[PortableInventoryStackScript]:
	var copied_stacks: Array[PortableInventoryStackScript] = []
	for candidate: Variant in stack_candidates:
		if not candidate is RefCounted:
			_stack_input_types_valid = false
			continue
		var reference_candidate: RefCounted = candidate as RefCounted
		if not _is_exact_stack(reference_candidate):
			_stack_input_types_valid = false
			continue
		copied_stacks.append(
			(reference_candidate as PortableInventoryStackScript).copy()
		)
	return copied_stacks


func _stacks_are_canonical_and_unique() -> bool:
	for index: int in range(_stacks.size()):
		if not _is_exact_stack(_stacks[index]):
			return false
		if (
			index > 0
			and String(_stacks[index].stack_id())
			<= String(_stacks[index - 1].stack_id())
		):
			return false
	return true


static func is_valid_temporary_effect_definition(
	definition: BlueprintDefinitionScript,
) -> bool:
	if (
		definition == null
		or definition.get_script() != BlueprintDefinitionScript
		or definition.category != BlueprintDefinitionScript.Category.ATTRIBUTE
		or definition.default_lifecycle
		!= BlueprintDefinitionScript.Lifecycle.CONSUMABLE
	):
		return false
	if not _TEMPORARY_EFFECT_BLUEPRINT_CONTRACTS.has(definition.content_id):
		return false
	var expected_contract: Array = (
		_TEMPORARY_EFFECT_BLUEPRINT_CONTRACTS[definition.content_id]
	)
	return (
		definition.ordinal == expected_contract[1]
		and definition.mechanic_id == expected_contract[2]
		and temporary_effect_for_blueprint_id(definition.content_id)
		!= ContactCombatCommandScript.TemporaryEffect.NONE
	)


static func _is_exact_initialized_registry(registry: RefCounted) -> bool:
	return (
		registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
		and (registry as ContentRegistryScript).is_initialized()
	)


static func _is_exact_stack(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryStackScript
	)


static func _stack_less_than(
	left: PortableInventoryStackScript,
	right: PortableInventoryStackScript,
) -> bool:
	return String(left.stack_id()) < String(right.stack_id())
