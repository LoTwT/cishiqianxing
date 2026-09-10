extends RefCounted

const CanonicalRegistryFixtureScript := preload(
	"res://tests/support/canonical_registry_fixture.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryReadSnapshotScript := preload(
	"res://src/rules/portable_inventory_read_snapshot.gd"
)
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryResolverScript := preload(
	"res://src/rules/portable_inventory_resolver.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)
const TemporaryEffectSelectionCommandScript := preload(
	"res://src/rules/temporary_effect_selection_command.gd"
)
const TemporaryEffectSelectionKernelScript := preload(
	"res://src/rules/temporary_effect_selection_kernel.gd"
)
const TemporaryEffectSelectionResultScript := preload(
	"res://src/rules/temporary_effect_selection_result.gd"
)
const StatefulContentRegistryScript := preload(
	"res://tests/support/stateful_content_registry.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)

const CONTENT_SCHEMA_VERSION: int = 6
const CONTENT_VERSION: int = 6


class StatefulPortableInventoryState extends PortableInventoryStateScript:
	var _reads: int = 0

	func copy():
		_reads += 1
		return super.copy()

	func read_count() -> int:
		return _reads


class StatefulPortableInventoryStack extends PortableInventoryStackScript:
	var _reads: int = 0

	func copy():
		_reads += 1
		return super.copy()

	func read_count() -> int:
		return _reads


class StatefulTemporaryEffectSelectionCommand extends TemporaryEffectSelectionCommandScript:
	var _reads: int = 0

	func copy():
		_reads += 1
		return super.copy()

	func stack_id() -> StringName:
		_reads += 1
		return super.stack_id()

	func read_count() -> int:
		return _reads


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"portable_inventory.resolves_capacity_stacks_and_provenance",
			_resolves_capacity_stacks_and_provenance,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.maps_all_temporary_effect_blueprints",
			_maps_all_temporary_effect_blueprints,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.rejects_structural_invariants_in_stable_priority",
			_rejects_structural_invariants_in_stable_priority,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.rejects_registry_drift_and_content_references",
			_rejects_registry_drift_and_content_references,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.selects_effect_without_consuming_inventory",
			_selects_effect_without_consuming_inventory,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.requires_explicit_replacement_confirmation",
			_requires_explicit_replacement_confirmation,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.rejects_selection_command_failures",
			_rejects_selection_command_failures,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.rejects_derived_inputs_without_reads",
			_rejects_derived_inputs_without_reads,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.isolates_inputs_outputs_and_integrity",
			_isolates_inputs_outputs_and_integrity,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.matches_exact_prestates_and_replays",
			_matches_exact_prestates_and_replays,
		),
		HeadlessTestCaseScript.new(
			"portable_inventory.result_constructors_fail_closed",
			_result_constructors_fail_closed,
		),
	]


func _resolves_capacity_stacks_and_provenance(
	context: HeadlessTestContextScript,
) -> void:
	for capacity: int in [12, 16, 20, 24]:
		var input_stacks: Array = [
			_gift(&"stack.zeta", &"blueprint.20", 9),
			_crafted(
				&"stack.alpha",
				&"blueprint.01",
				&"recipe.standard.01",
				2,
			),
		]
		var state: PortableInventoryStateScript = _state(
			input_stacks,
			capacity,
			7,
			&"stack.zeta",
		)
		var result: PortableInventoryResolutionResultScript = _resolve(state)
		_expect_resolution_success(
			context,
			result,
			"Capacity %d inventory" % capacity,
		)
		if not result.succeeded():
			continue
		context.expect_equal(
			result.capacity(),
			capacity,
			"Supported capacity is retained.",
		)
		context.expect_equal(
			result.occupied_slot_count(),
			2,
			"Each stack occupies exactly one slot.",
		)
		context.expect_equal(
			result.available_slot_count(),
			capacity - 2,
			"Available slots derive from stack count only.",
		)
		context.expect_equal(
			result.stack_ids(),
			[&"stack.alpha", &"stack.zeta"],
			"Stack IDs use canonical stable order.",
		)
		context.expect_equal(result.revision(), 7, "Inventory revision is retained.")
		context.expect_equal(
			result.selected_temporary_effect(),
			ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
			"Blueprint 20 projects the attack temporary effect.",
		)
		var crafted_stack: PortableInventoryStackScript = result.stack_snapshot(
			&"stack.alpha"
		)
		context.expect_equal(
			crafted_stack.provenance(),
			PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE,
			"Crafted stack provenance is retained.",
		)
		context.expect_equal(
			crafted_stack.source_recipe_id(),
			&"recipe.standard.01",
			"Crafted stack retains the exact recipe identity.",
		)
		var gift_stack: PortableInventoryStackScript = result.stack_snapshot(
			&"stack.zeta"
		)
		context.expect_equal(
			gift_stack.provenance(),
			PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT,
			"Gift provenance remains explicitly non-dismantlable.",
		)
		context.expect_equal(
			gift_stack.source_recipe_id(),
			&"",
			"Gift stacks cannot counterfeit recipe provenance.",
		)
		context.expect_equal(gift_stack.quantity(), 9, "Nine is a legal stack maximum.")
		context.expect_true(
			not result.is_commit_boundary(),
			"Inventory resolution is not a world commit boundary.",
		)
		for forbidden_method: StringName in [
			&"weight",
			&"total_load",
			&"shape",
			&"grid_width",
		]:
			context.expect_true(
				not result.snapshot().has_method(forbidden_method),
				"Inventory model must not expose %s." % forbidden_method,
			)
		var full_result: PortableInventoryResolutionResultScript = _resolve(
			_state(_gift_stacks(capacity), capacity)
		)
		_expect_resolution_success(
			context,
			full_result,
			"Exactly full capacity %d" % capacity,
		)
		if full_result.succeeded():
			context.expect_equal(
				full_result.occupied_slot_count(),
				capacity,
				"Every supported capacity accepts exactly that many stacks.",
			)
			context.expect_equal(
				full_result.available_slot_count(),
				0,
				"Exactly full inventory has no available slots.",
			)
		_expect_resolution_failure(
			context,
			_resolve(_state(_gift_stacks(capacity + 1), capacity)),
			PortableInventoryResolutionResultScript.FailureReason.CAPACITY_EXCEEDED,
			"Capacity %d plus one stack" % capacity,
		)


func _maps_all_temporary_effect_blueprints(
	context: HeadlessTestContextScript,
) -> void:
	var blueprint_ids: Array[StringName] = [
		&"blueprint.20",
		&"blueprint.21",
		&"blueprint.22",
		&"blueprint.23",
		&"blueprint.24",
	]
	var expected_effects: Array[int] = [
		ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
		ContactCombatCommandScript.TemporaryEffect.DEFENSE_2,
		ContactCombatCommandScript.TemporaryEffect.SPEED_2,
		ContactCombatCommandScript.TemporaryEffect.ATTACK_SPEED_2,
		ContactCombatCommandScript.TemporaryEffect.ATTACK_DEFENSE_2,
	]
	for index: int in range(blueprint_ids.size()):
		var stack_id := StringName("stack.effect.%02d" % (index + 20))
		var result: PortableInventoryResolutionResultScript = _resolve(
			_state(
				[_gift(stack_id, blueprint_ids[index], 1)],
				12,
				index,
				stack_id,
			)
		)
		_expect_resolution_success(
			context,
			result,
			"Temporary effect %s" % blueprint_ids[index],
		)
		if result.succeeded():
			context.expect_equal(
				result.selected_temporary_effect(),
				expected_effects[index],
				"Temporary effect projection matches the combat enum.",
			)
			context.expect_equal(
				result.selected_temporary_effect_blueprint_id(),
				blueprint_ids[index],
				"Selected blueprint identity remains inspectable.",
			)


func _rejects_structural_invariants_in_stable_priority(
	context: HeadlessTestContextScript,
) -> void:
	_expect_resolution_failure(
		context,
		PortableInventoryResolverScript.resolve(
			PortableInventoryStateScript.new(),
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_INVENTORY_STATE,
		"Uninitialized state",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 13, 0, &"", 0, 0)),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_CONTENT_SCHEMA_VERSION,
		"Schema precedes all later structural failures",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 12, 0, &"", CONTENT_SCHEMA_VERSION, 0)),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_CONTENT_VERSION,
		"Invalid content version",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 13)),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_CAPACITY,
		"Unsupported capacity",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 12, -1)),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_REVISION,
		"Negative revision",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([RefCounted.new()])),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_STACK_COLLECTION,
		"Wrong stack type",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([_gift(&"bad id", &"blueprint.20", 1)])),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_STACK_ID,
		"Invalid stack ID",
		&"bad id",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([_gift(&"stack.empty-blueprint", &"", 1)])),
		PortableInventoryResolutionResultScript.FailureReason.EMPTY_BLUEPRINT_ID,
		"Empty blueprint ID",
		&"stack.empty-blueprint",
	)
	for invalid_quantity: int in [0, 10]:
		_expect_resolution_failure(
			context,
			_resolve(
				_state(
					[_gift(&"stack.invalid-quantity", &"blueprint.20", invalid_quantity)]
				)
			),
			PortableInventoryResolutionResultScript.FailureReason.INVALID_QUANTITY,
			"Invalid quantity %d" % invalid_quantity,
			&"stack.invalid-quantity",
		)
	var invalid_provenance: PortableInventoryStackScript = _gift(
		&"stack.invalid-provenance",
		&"blueprint.20",
		1,
	)
	invalid_provenance._provenance = 99
	_expect_resolution_failure(
		context,
		_resolve(_state([invalid_provenance])),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_PROVENANCE,
		"Unknown provenance",
		&"stack.invalid-provenance",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[
					PortableInventoryStackScript.create(
						&"stack.crafted-without-recipe",
						&"blueprint.20",
						PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE,
						&"",
						1,
					)
				]
			)
		),
		(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_PROVENANCE_RECIPE_REFERENCE
		),
		"Crafted stack without recipe",
		&"stack.crafted-without-recipe",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[
					PortableInventoryStackScript.create(
						&"stack.gift-with-recipe",
						&"blueprint.20",
						PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT,
						&"recipe.standard.20",
						1,
					)
				]
			)
		),
		(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_PROVENANCE_RECIPE_REFERENCE
		),
		"Gift stack with forged recipe",
		&"stack.gift-with-recipe",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[
					_gift(&"stack.duplicate", &"blueprint.20", 1),
					_gift(&"stack.duplicate", &"blueprint.21", 1),
				]
			)
		),
		PortableInventoryResolutionResultScript.FailureReason.DUPLICATE_STACK_ID,
		"Duplicate stack ID",
		&"stack.duplicate",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state(_gift_stacks(13), 12)),
		PortableInventoryResolutionResultScript.FailureReason.CAPACITY_EXCEEDED,
		"Thirteen stacks exceed twelve slots",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 12, 0, &"bad id")),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_SELECTED_STACK_ID,
		"Invalid selected stack ID",
		&"bad id",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([], 12, 0, &"stack.missing")),
		PortableInventoryResolutionResultScript.FailureReason.UNKNOWN_SELECTED_STACK_ID,
		"Unknown selected stack ID",
		&"stack.missing",
	)


func _rejects_registry_drift_and_content_references(
	context: HeadlessTestContextScript,
) -> void:
	var valid_state: PortableInventoryStateScript = _state(
		[_gift(&"stack.effect", &"blueprint.20", 1)]
	)
	_expect_resolution_failure(
		context,
		PortableInventoryResolverScript.resolve(valid_state, null),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Null registry",
	)
	var stateful_registry := StatefulContentRegistryScript.new()
	_expect_resolution_failure(
		context,
		PortableInventoryResolverScript.resolve(valid_state, stateful_registry),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Derived registry",
	)
	context.expect_equal(
		stateful_registry.read_count(),
		0,
		"Derived registry is rejected before virtual reads.",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[],
				12,
				0,
				&"",
				CONTENT_SCHEMA_VERSION - 1,
				CONTENT_VERSION,
			)
		),
		(
			PortableInventoryResolutionResultScript
			.FailureReason
			.CONTENT_SCHEMA_VERSION_MISMATCH
		),
		"Schema drift",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[],
				12,
				0,
				&"",
				CONTENT_SCHEMA_VERSION,
				CONTENT_VERSION - 1,
			)
		),
		PortableInventoryResolutionResultScript.FailureReason.CONTENT_VERSION_MISMATCH,
		"Content drift",
	)
	_expect_resolution_failure(
		context,
		_resolve(_state([_gift(&"stack.unknown", &"blueprint.unknown", 1)])),
		PortableInventoryResolutionResultScript.FailureReason.UNKNOWN_BLUEPRINT_ID,
		"Unknown blueprint",
		&"stack.unknown",
		&"blueprint.unknown",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[
					_crafted(
						&"stack.unknown-recipe",
						&"blueprint.20",
						&"recipe.unknown",
						1,
					)
				]
			)
		),
		PortableInventoryResolutionResultScript.FailureReason.UNKNOWN_RECIPE_ID,
		"Unknown recipe",
		&"stack.unknown-recipe",
		&"recipe.unknown",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[
					_crafted(
						&"stack.recipe-mismatch",
						&"blueprint.20",
						&"recipe.standard.21",
						1,
					)
				]
			)
		),
		PortableInventoryResolutionResultScript.FailureReason.RECIPE_BLUEPRINT_MISMATCH,
		"Recipe output mismatch",
		&"stack.recipe-mismatch",
		&"recipe.standard.21",
	)
	_expect_resolution_failure(
		context,
		_resolve(
			_state(
				[_gift(&"stack.structure", &"blueprint.01", 1)],
				12,
				0,
				&"stack.structure",
			)
		),
		(
			PortableInventoryResolutionResultScript
			.FailureReason
			.SELECTED_STACK_NOT_TEMPORARY_EFFECT
		),
		"Non-attribute selected stack",
		&"stack.structure",
		&"blueprint.01",
	)


func _selects_effect_without_consuming_inventory(
	context: HeadlessTestContextScript,
) -> void:
	var initial_state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 2),
			_crafted(
				&"stack.defense",
				&"blueprint.21",
				&"recipe.standard.21",
				3,
			),
			_gift(&"stack.structure", &"blueprint.01", 9),
		],
		12,
		10,
	)
	var initial_resolution: PortableInventoryResolutionResultScript = _resolve(
		initial_state
	)
	_expect_resolution_success(context, initial_resolution, "Selection prestate")
	var command: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.attack", 10)
	)
	var result: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			initial_state,
			command,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(result.was_selected(), "First temporary effect is selected.")
	context.expect_true(result.is_selection_candidate(), "Selection returns a candidate.")
	context.expect_true(
		not result.is_commit_boundary(),
		"Selection candidate is not a world commit boundary.",
	)
	context.expect_equal(
		result.selected_temporary_effect_stack_id(),
		&"stack.attack",
		"Selection retains the exact source stack identity.",
	)
	context.expect_equal(
		result.selected_temporary_effect(),
		ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
		"Selection projects the attack effect.",
	)
	var next_state: PortableInventoryStateScript = result.next_state()
	context.expect_true(next_state != null, "Selection exposes a defensive state candidate.")
	if next_state == null:
		return
	context.expect_equal(next_state.revision(), 11, "Selection increments revision once.")
	context.expect_equal(
		next_state.stack_snapshot(&"stack.attack").quantity(),
		2,
		"Selecting does not consume the chosen stack.",
	)
	context.expect_equal(
		next_state.stack_snapshot(&"stack.defense").quantity(),
		3,
		"Selecting does not mutate other stacks.",
	)
	context.expect_equal(
		next_state.stack_snapshot(&"stack.structure").quantity(),
		9,
		"Selecting preserves unrelated inventory.",
	)
	context.expect_true(
		result.matches_exact_prestate(initial_resolution),
		"Selection binds the exact inventory prestate.",
	)
	var next_resolution: PortableInventoryResolutionResultScript = _resolve(next_state)
	_expect_resolution_success(context, next_resolution, "Selection state candidate")


func _requires_explicit_replacement_confirmation(
	context: HeadlessTestContextScript,
) -> void:
	var state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 1),
			_gift(&"stack.defense", &"blueprint.21", 1),
		],
		12,
		20,
		&"stack.attack",
	)
	var prestate: PortableInventoryResolutionResultScript = _resolve(state)
	var unconfirmed_command: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.defense", 20)
	)
	var required: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			state,
			unconfirmed_command,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(
		required.needs_replacement_confirmation(),
		"Replacing a retained effect requires explicit confirmation.",
	)
	context.expect_equal(
		required.next_state().revision(),
		20,
		"Confirmation request does not advance inventory revision.",
	)
	context.expect_equal(
		required.selected_temporary_effect_stack_id(),
		&"stack.attack",
		"Confirmation request preserves the existing effect.",
	)
	context.expect_true(
		required.matches_exact_prestate(prestate),
		"Confirmation request binds the exact inventory prestate.",
	)
	var confirmed_command: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.defense", 20, true)
	)
	var replaced: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			state,
			confirmed_command,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(replaced.was_selected(), "Confirmed replacement is selected.")
	context.expect_equal(
		replaced.selected_temporary_effect_stack_id(),
		&"stack.defense",
		"Confirmed replacement changes the source stack.",
	)
	context.expect_equal(
		replaced.selected_temporary_effect(),
		ContactCombatCommandScript.TemporaryEffect.DEFENSE_2,
		"Confirmed replacement changes the combat projection.",
	)
	context.expect_equal(
		replaced.next_state().revision(),
		21,
		"Confirmed replacement increments revision once.",
	)
	var unchanged: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			replaced.next_state(),
			TemporaryEffectSelectionCommandScript.select(&"stack.defense", 21),
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(unchanged.was_unchanged(), "Selecting the same stack is idempotent.")
	context.expect_equal(
		unchanged.next_state().revision(),
		21,
		"Idempotent selection does not increment revision.",
	)


func _rejects_selection_command_failures(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory")
	var state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 1),
			_gift(&"stack.structure", &"blueprint.01", 1),
		],
		12,
		5,
	)
	var invalid_state_result: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			_state([], 12, 0, &"", 0, 0),
			TemporaryEffectSelectionCommandScript.select(&"stack.attack", 0),
			registry,
		)
	)
	_expect_selection_rejection(
		context,
		invalid_state_result,
		TemporaryEffectSelectionResultScript.RejectionReason.INVENTORY_STATE_REJECTED,
		"Invalid inventory state",
		(
			PortableInventoryResolutionResultScript
			.FailureReason
			.INVALID_CONTENT_SCHEMA_VERSION
		),
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(state, null, registry),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_COMMAND,
		"Null command",
	)
	var wrong_kind: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.attack", 5)
	)
	wrong_kind._kind = 99
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(state, wrong_kind, registry),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_COMMAND,
		"Unknown command kind",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"stack.attack", -1),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_EXPECTED_REVISION,
		"Negative expected revision",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"", 5),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.EMPTY_STACK_ID,
		"Empty requested stack ID",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"bad id", 5),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_STACK_ID,
		"Invalid requested stack ID",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"stack.attack", 4),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.STALE_REVISION,
		"Stale expected revision",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"stack.missing", 5),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.UNKNOWN_STACK_ID,
		"Unknown requested stack",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"stack.structure", 5),
			registry,
		),
		(
			TemporaryEffectSelectionResultScript
			.RejectionReason
			.STACK_NOT_TEMPORARY_EFFECT
		),
		"Non-attribute requested stack",
	)
	var maximum_revision_state: PortableInventoryStateScript = _state(
		[_gift(&"stack.attack", &"blueprint.20", 1)],
		12,
		PortableInventoryStateScript.MAXIMUM_REVISION,
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			maximum_revision_state,
			TemporaryEffectSelectionCommandScript.select(
				&"stack.attack",
				PortableInventoryStateScript.MAXIMUM_REVISION,
			),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.REVISION_OVERFLOW,
		"Revision overflow",
	)
	var maximum_revision_selected_state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 1),
			_gift(&"stack.defense", &"blueprint.21", 1),
		],
		12,
		PortableInventoryStateScript.MAXIMUM_REVISION,
		&"stack.attack",
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			maximum_revision_selected_state,
			TemporaryEffectSelectionCommandScript.select(
				&"stack.defense",
				PortableInventoryStateScript.MAXIMUM_REVISION,
			),
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.REVISION_OVERFLOW,
		"Revision overflow precedes impossible replacement confirmation",
	)


func _rejects_derived_inputs_without_reads(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory")
	var derived_state := StatefulPortableInventoryState.new()
	_expect_resolution_failure(
		context,
		PortableInventoryResolverScript.resolve(derived_state, registry),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_INVENTORY_STATE,
		"Derived inventory state",
	)
	context.expect_equal(
		derived_state.read_count(),
		0,
		"Derived state is rejected before virtual copy reads.",
	)
	var derived_stack := StatefulPortableInventoryStack.new()
	_expect_resolution_failure(
		context,
		_resolve(_state([derived_stack])),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_STACK_COLLECTION,
		"Derived stack",
	)
	context.expect_equal(
		derived_stack.read_count(),
		0,
		"Derived stack is rejected before virtual copy reads.",
	)
	var derived_command := StatefulTemporaryEffectSelectionCommand.new(
		TemporaryEffectSelectionCommandScript.Kind.SELECT,
		&"stack.attack",
		0,
		false,
	)
	_expect_selection_rejection(
		context,
		TemporaryEffectSelectionKernelScript.execute(
			_state([_gift(&"stack.attack", &"blueprint.20", 1)]),
			derived_command,
			registry,
		),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_COMMAND,
		"Derived command",
	)
	context.expect_equal(
		derived_command.read_count(),
		0,
		"Derived command is rejected before virtual copy reads.",
	)
	var resolved_state: PortableInventoryResolutionResultScript = _resolve(
		_state([_gift(&"stack.attack", &"blueprint.20", 1)])
	)
	var malformed_public_result: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.selected(
			derived_command,
			resolved_state,
			resolved_state,
		)
	)
	context.expect_equal(
		malformed_public_result.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Public result construction rejects a derived command.",
	)
	context.expect_equal(
		derived_command.read_count(),
		0,
		"Public result construction rejects derived command before virtual reads.",
	)


func _isolates_inputs_outputs_and_integrity(
	context: HeadlessTestContextScript,
) -> void:
	var input_stack: PortableInventoryStackScript = _gift(
		&"stack.attack",
		&"blueprint.20",
		2,
	)
	var state: PortableInventoryStateScript = _state([input_stack], 12, 4)
	input_stack._quantity = 9
	var result: PortableInventoryResolutionResultScript = _resolve(state)
	_expect_resolution_success(context, result, "Input isolation")
	if not result.succeeded():
		return
	context.expect_equal(
		result.stack_snapshot(&"stack.attack").quantity(),
		2,
		"State construction copies caller-owned stack values.",
	)
	var exposed_stack: PortableInventoryStackScript = result.stack_snapshot(
		&"stack.attack"
	)
	exposed_stack._quantity = 8
	context.expect_equal(
		result.stack_snapshot(&"stack.attack").quantity(),
		2,
		"Stack query returns a defensive copy.",
	)
	var exposed_state: PortableInventoryStateScript = result.snapshot()
	exposed_state._revision = 99
	context.expect_equal(result.revision(), 4, "State query returns a defensive copy.")
	var exposed_snapshot: PortableInventoryReadSnapshotScript = result.read_snapshot()
	exposed_snapshot._state._revision = 100
	context.expect_equal(
		result.revision(),
		4,
		"Read snapshot query cannot mutate the stored result.",
	)
	var tampered_result: PortableInventoryResolutionResultScript = _resolve(state)
	tampered_result._read_snapshot._state._revision = 5
	context.expect_true(
		not tampered_result.succeeded(),
		"Internal snapshot tampering invalidates the result.",
	)
	context.expect_equal(
		tampered_result.failure_reason(),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT,
		"Tampered resolution fails closed.",
	)
	context.expect_true(
		tampered_result.snapshot() == null,
		"Tampered resolution exposes no partial state.",
	)
	var selection: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			state,
			TemporaryEffectSelectionCommandScript.select(&"stack.attack", 4),
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(selection.was_selected(), "Integrity test selection succeeds first.")
	var exposed_command: TemporaryEffectSelectionCommandScript = selection.command()
	exposed_command._stack_id = &"stack.changed"
	context.expect_equal(
		selection.command().stack_id(),
		&"stack.attack",
		"Selection command query returns a defensive copy.",
	)
	selection._status = TemporaryEffectSelectionResultScript.Status.REJECTED
	context.expect_equal(
		selection.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Tampered selection result fails closed.",
	)
	context.expect_true(
		selection.next_state() == null,
		"Tampered selection exposes no candidate state.",
	)


func _matches_exact_prestates_and_replays(
	context: HeadlessTestContextScript,
) -> void:
	var state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 1),
			_gift(&"stack.defense", &"blueprint.21", 1),
		],
		16,
		14,
	)
	var first: PortableInventoryResolutionResultScript = _resolve(state)
	var second: PortableInventoryResolutionResultScript = _resolve(state.copy())
	var changed_revision: PortableInventoryResolutionResultScript = _resolve(
		_state(state.stack_snapshots(), 16, 15)
	)
	var changed_selection: PortableInventoryResolutionResultScript = _resolve(
		_state(state.stack_snapshots(), 16, 14, &"stack.attack")
	)
	context.expect_true(first.matches_exact_prestate(second), "Equal prestates match.")
	context.expect_true(second.matches_exact_prestate(first), "Prestate match is symmetric.")
	context.expect_true(
		not first.matches_exact_prestate(changed_revision),
		"Revision change invalidates exact prestate match.",
	)
	context.expect_true(
		not first.matches_exact_prestate(changed_selection),
		"Selection change invalidates exact prestate match.",
	)
	var command: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.attack", 14)
	)
	var first_selection: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			state,
			command,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	var second_selection: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionKernelScript.execute(
			state.copy(),
			command.copy(),
			CanonicalRegistryFixtureScript.canonical_registry(context, "Portable inventory"),
		)
	)
	context.expect_true(
		first_selection.matches_exact_prestate(first),
		"Selection candidate records its exact original prestate.",
	)
	context.expect_equal(
		_encode_selection(first_selection),
		_encode_selection(second_selection),
		"Identical state and command replay deterministically.",
	)


func _result_constructors_fail_closed(
	context: HeadlessTestContextScript,
) -> void:
	var state: PortableInventoryStateScript = _state(
		[_gift(&"stack.attack", &"blueprint.20", 1)]
	)
	var invalid_success: PortableInventoryResolutionResultScript = (
		PortableInventoryResolutionResultScript.success(state, null)
	)
	_expect_resolution_failure(
		context,
		invalid_success,
		PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT,
		"Success without sealed registry",
	)
	_expect_resolution_failure(
		context,
		PortableInventoryResolutionResultScript.failure(
			PortableInventoryResolutionResultScript.FailureReason.NONE
		),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT,
		"Failure with NONE reason",
	)
	_expect_resolution_failure(
		context,
		PortableInventoryResolutionResultScript.failure(999),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT,
		"Failure with unknown reason",
	)
	_expect_resolution_failure(
		context,
		PortableInventoryResolutionResultScript.failure(
			PortableInventoryResolutionResultScript.FailureReason.UNKNOWN_BLUEPRINT_ID,
			&"stack.attack",
			&"",
		),
		PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT,
		"Failure with malformed metadata",
	)
	var resolution: PortableInventoryResolutionResultScript = _resolve(state)
	var command: TemporaryEffectSelectionCommandScript = (
		TemporaryEffectSelectionCommandScript.select(&"stack.attack", 0)
	)
	var invalid_selected: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.selected(command, resolution, resolution)
	)
	context.expect_equal(
		invalid_selected.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Selection constructor rejects a non-incrementing candidate.",
	)
	var selected_state: PortableInventoryStateScript = _state(
		[
			_gift(&"stack.attack", &"blueprint.20", 1),
			_gift(&"stack.defense", &"blueprint.21", 1),
		],
		12,
		4,
		&"stack.attack",
	)
	var selected_resolution: PortableInventoryResolutionResultScript = _resolve(
		selected_state
	)
	var replaced_state: PortableInventoryStateScript = _state(
		selected_state.stack_snapshots(),
		12,
		5,
		&"stack.defense",
	)
	var replaced_resolution: PortableInventoryResolutionResultScript = _resolve(
		replaced_state
	)
	var unconfirmed_replacement: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.selected(
			TemporaryEffectSelectionCommandScript.select(&"stack.defense", 4),
			selected_resolution,
			replaced_resolution,
		)
	)
	context.expect_equal(
		unconfirmed_replacement.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Selection constructor cannot bypass replacement confirmation.",
	)
	var stale_constructor_result: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.unchanged(
			TemporaryEffectSelectionCommandScript.select(&"stack.attack", 3),
			selected_resolution,
		)
	)
	context.expect_equal(
		stale_constructor_result.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Selection constructor binds the command revision to its prestate.",
	)
	var saturated_resolution: PortableInventoryResolutionResultScript = _resolve(
		_state(
			[
				_gift(&"stack.attack", &"blueprint.20", 1),
				_gift(&"stack.defense", &"blueprint.21", 1),
			],
			12,
			PortableInventoryStateScript.MAXIMUM_REVISION,
			&"stack.attack",
		)
	)
	var impossible_confirmation: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.confirmation_required(
			TemporaryEffectSelectionCommandScript.select(
				&"stack.defense",
				PortableInventoryStateScript.MAXIMUM_REVISION,
			),
			saturated_resolution,
		)
	)
	context.expect_equal(
		impossible_confirmation.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Result constructors reject impossible saturated confirmations.",
	)
	var invalid_rejection: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.rejected(
			&"",
			TemporaryEffectSelectionResultScript.RejectionReason.NONE,
		)
	)
	context.expect_equal(
		invalid_rejection.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Rejected result cannot use NONE reason.",
	)
	var invalid_nested_rejection: TemporaryEffectSelectionResultScript = (
		TemporaryEffectSelectionResultScript.rejected(
			&"",
			(
				TemporaryEffectSelectionResultScript
				.RejectionReason
				.INVENTORY_STATE_REJECTED
			),
			PortableInventoryResolutionResultScript.FailureReason.NONE,
		)
	)
	context.expect_equal(
		invalid_nested_rejection.rejection_reason(),
		TemporaryEffectSelectionResultScript.RejectionReason.INVALID_RESULT,
		"Inventory rejection requires a nested failure reason.",
	)


func _state(
	stacks: Array,
	capacity: int = PortableInventoryStateScript.INITIAL_CAPACITY,
	revision: int = 0,
	selected_stack_id: StringName = &"",
	content_schema_version: int = CONTENT_SCHEMA_VERSION,
	content_version: int = CONTENT_VERSION,
) -> PortableInventoryStateScript:
	return PortableInventoryStateScript.create(
		content_schema_version,
		content_version,
		capacity,
		revision,
		stacks,
		selected_stack_id,
	)


func _gift(
	stack_id: StringName,
	blueprint_id: StringName,
	quantity: int,
) -> PortableInventoryStackScript:
	return PortableInventoryStackScript.create(
		stack_id,
		blueprint_id,
		PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT,
		&"",
		quantity,
	)


func _crafted(
	stack_id: StringName,
	blueprint_id: StringName,
	recipe_id: StringName,
	quantity: int,
) -> PortableInventoryStackScript:
	return PortableInventoryStackScript.create(
		stack_id,
		blueprint_id,
		PortableInventoryStackScript.Provenance.CRAFTED_FROM_RECIPE,
		recipe_id,
		quantity,
	)


func _gift_stacks(count: int) -> Array:
	var stacks: Array = []
	for index: int in range(count):
		stacks.append(
			_gift(
				StringName("stack.capacity.%02d" % index),
				&"blueprint.01",
				1,
			)
		)
	return stacks


func _resolve(
	state: PortableInventoryStateScript,
) -> PortableInventoryResolutionResultScript:
	return PortableInventoryResolverScript.resolve(
		state,
		CanonicalRegistryFixtureScript.canonical_registry_for_helpers(),
	)


func _encode_selection(result: TemporaryEffectSelectionResultScript) -> Array:
	if result == null:
		return []
	var encoded: Array = [
		result.status(),
		result.rejection_reason(),
		result.inventory_failure_reason(),
		result.requested_stack_id(),
		result.selected_temporary_effect_stack_id(),
		result.selected_temporary_effect(),
	]
	var next_state: PortableInventoryStateScript = result.next_state()
	if next_state != null:
		encoded.append(next_state.content_schema_version())
		encoded.append(next_state.content_version())
		encoded.append(next_state.capacity())
		encoded.append(next_state.revision())
		for stack: PortableInventoryStackScript in next_state.stack_snapshots():
			encoded.append(
				[
					stack.stack_id(),
					stack.blueprint_id(),
					stack.provenance(),
					stack.source_recipe_id(),
					stack.quantity(),
				]
			)
	return encoded


func _expect_resolution_success(
	context: HeadlessTestContextScript,
	result: PortableInventoryResolutionResultScript,
	label: String,
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(result.succeeded(), "%s succeeds." % label)
	context.expect_equal(
		result.failure_reason(),
		PortableInventoryResolutionResultScript.FailureReason.NONE,
		"%s has no failure reason." % label,
	)
	context.expect_true(result.snapshot() != null, "%s exposes a snapshot." % label)


func _expect_resolution_failure(
	context: HeadlessTestContextScript,
	result: PortableInventoryResolutionResultScript,
	expected_reason: int,
	label: String,
	expected_stack_id: StringName = &"",
	expected_content_id: StringName = &"",
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(not result.succeeded(), "%s fails." % label)
	context.expect_equal(
		result.failure_reason(),
		expected_reason,
		"%s failure reason." % label,
	)
	context.expect_equal(
		result.failed_stack_id(),
		expected_stack_id,
		"%s failed stack ID." % label,
	)
	context.expect_equal(
		result.failed_content_id(),
		expected_content_id,
		"%s failed content ID." % label,
	)
	context.expect_true(result.snapshot() == null, "%s exposes no snapshot." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _expect_selection_rejection(
	context: HeadlessTestContextScript,
	result: TemporaryEffectSelectionResultScript,
	expected_reason: int,
	label: String,
	expected_inventory_reason: int = (
		PortableInventoryResolutionResultScript.FailureReason.NONE
	),
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(result.was_rejected(), "%s is rejected." % label)
	context.expect_equal(
		result.rejection_reason(),
		expected_reason,
		"%s rejection reason." % label,
	)
	context.expect_equal(
		result.inventory_failure_reason(),
		expected_inventory_reason,
		"%s nested inventory reason." % label,
	)
	context.expect_true(result.next_state() == null, "%s exposes no candidate." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)
