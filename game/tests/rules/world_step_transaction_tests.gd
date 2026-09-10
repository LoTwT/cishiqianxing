extends RefCounted

const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepCommandScript := preload("res://src/rules/world_step_command.gd")
const WorldStepStageInputsScript := preload("res://src/rules/world_step_stage_inputs.gd")
const WorldStepTransactionKernelScript := preload("res://src/rules/world_step_transaction_kernel.gd")
const WorldStepTransactionResultScript := preload("res://src/rules/world_step_transaction_result.gd")
const WorldStepTransactionCandidateScript := preload("res://src/rules/world_step_transaction_candidate.gd")
const WorldStepTransactionEventScript := preload("res://src/rules/world_step_transaction_event.gd")
const WorldStepContactKernelScript := preload("res://src/rules/world_step_contact_kernel.gd")
const WorldStepContactCommandScript := preload("res://src/rules/world_step_contact_command.gd")
const ContactCombatTransactionKernelScript := preload("res://src/rules/contact_combat_transaction_kernel.gd")
const ContactCombatTransactionCommandScript := preload("res://src/rules/contact_combat_transaction_command.gd")
const ContactCombatCommandScript := preload("res://src/rules/contact_combat_command.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const EnemyWorldStateScript := preload("res://src/rules/enemy_world_state.gd")
const EnemyWorldAddressScript := preload("res://src/rules/enemy_world_address.gd")
const EnemyWorldRecordScript := preload("res://src/rules/enemy_world_record.gd")
const EnemyInstanceStateScript := preload("res://src/rules/enemy_instance_state.gd")
const PlayerProgressionStateScript := preload("res://src/rules/player_progression_state.gd")
const PortableInventoryStateScript := preload("res://src/rules/portable_inventory_state.gd")
const PortableInventoryStackScript := preload("res://src/rules/portable_inventory_stack.gd")
const EnemyWorldResolverScript := preload("res://src/rules/enemy_world_resolver.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const CanonicalRegistryFixtureScript := preload("res://tests/support/canonical_registry_fixture.gd")
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const PLAYER_ID: StringName = &"actor.loer"
const TARGET_ID: StringName = &"enemy.instance.world.target"
const SPACE_ID: StringName = &"space.world.transaction"
const STEP: int = 41
const EAST: Vector3i = Vector3i(1, 0, 0)
const Reason = WorldStepTransactionResultScript.RejectionReason


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new("world_step_transaction.move_and_wait", _move_and_wait),
		HeadlessTestCaseScript.new("world_step_transaction.contact_victory_and_next_entry", _contact_victory_and_next_entry),
		HeadlessTestCaseScript.new("world_step_transaction.defeat_retains_enemy", _defeat_retains_enemy),
		HeadlessTestCaseScript.new("world_step_transaction.shield_and_all_temporary_effects", _shield_and_all_temporary_effects),
		HeadlessTestCaseScript.new("world_step_transaction.invalid_commands_and_geometry", _invalid_commands_and_geometry),
		HeadlessTestCaseScript.new("world_step_transaction.unsupported_stages_and_enemy_behaviors", _unsupported_stages_and_enemy_behaviors),
		HeadlessTestCaseScript.new("world_step_transaction.full_prestate_revalidation", _full_prestate_revalidation),
		HeadlessTestCaseScript.new("world_step_transaction.duplicate_commit_and_determinism", _duplicate_commit_and_determinism),
		HeadlessTestCaseScript.new("world_step_transaction.content_drift", _content_drift),
		HeadlessTestCaseScript.new("world_step_transaction.world_step_limit", _world_step_limit),
		HeadlessTestCaseScript.new("world_step_transaction.projection_and_lifecycle", _projection_and_lifecycle),
		HeadlessTestCaseScript.new("world_step_transaction.snapshot_isolation", _snapshot_isolation),
		HeadlessTestCaseScript.new("world_step_transaction.tampering_and_closed_construction", _tampering_and_closed_construction),
		HeadlessTestCaseScript.new("world_step_transaction.contact_binding", _contact_binding),
		HeadlessTestCaseScript.new("world_step_transaction.cancelled_contact_contract", _cancelled_contact_contract),
	]


func _registry() -> ContentRegistryScript:
	return CanonicalRegistryFixtureScript.canonical_registry_for_helpers()


func _state(
	profile_id: StringName = &"", health: int = 100, step: int = STEP,
	selected_blueprint: StringName = &"", quantity: int = 2, shield: bool = true,
) -> WorldStepStateScript:
	var records: Array[EnemyWorldRecordScript] = []
	var addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	var positions: Dictionary[StringName, Vector3i] = {PLAYER_ID: Vector3i.ZERO}
	if profile_id != &"":
		var profile := _registry().lookup_enemy_profile(profile_id).profile()
		records.append(EnemyWorldRecordScript.create(EnemyInstanceStateScript.create(
			TARGET_ID, profile_id, 6, 6, profile.maximum_durability,
			EnemyInstanceStateScript.StateKind.PRIMARY,
			shield and profile.combat_trait_ids.has(&"enemy.trait.shield"),
		), EnemyWorldRecordScript.Lifecycle.ACTIVE))
		addresses[TARGET_ID] = EnemyWorldAddressScript.create(SPACE_ID, EAST)
		positions[TARGET_ID] = EAST
	var stacks: Array[PortableInventoryStackScript] = []
	var selected_id: StringName = &""
	if selected_blueprint != &"":
		selected_id = &"stack.temporary"
		stacks.append(PortableInventoryStackScript.create(selected_id, selected_blueprint,
			PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT, &"", quantity))
	return WorldStepStateScript.create(
		SPACE_ID, GridRuleStateScript.create([Vector3i.ZERO, EAST, EAST * 2, Vector3i(0, 0, 1)], [], positions, step),
		PlayerProgressionStateScript.create(&"progression.player.loer", 6, 6, health, []),
		EnemyWorldStateScript.create(records, addresses, step),
		PortableInventoryStateScript.create(6, 6, 12, 3, stacks, selected_id),
		WorldStepStageInputsScript.create([], [], [], [], [], true),
	)


func _move(state: WorldStepStateScript, direction: Vector3i = EAST) -> WorldStepCommandScript:
	return WorldStepCommandScript.create(WorldStepCommandScript.Kind.MOVE, state.grid_state().world_step(), state.grid_state().actor_position(PLAYER_ID), direction)


func _wait(state: WorldStepStateScript) -> WorldStepCommandScript:
	return WorldStepCommandScript.create(WorldStepCommandScript.Kind.WAIT, state.grid_state().world_step(), state.grid_state().actor_position(PLAYER_ID), Vector3i.ZERO)


func _prepare(state: WorldStepStateScript, command: WorldStepCommandScript) -> WorldStepTransactionResultScript:
	return WorldStepTransactionKernelScript.prepare(state, command, _registry())


func _commit(state: WorldStepStateScript, prepared: WorldStepTransactionResultScript) -> WorldStepTransactionResultScript:
	return WorldStepTransactionKernelScript.commit(state, prepared, _registry())


func _expect_failed(context: HeadlessTestContextScript, result: WorldStepTransactionResultScript, label: String, reason: int = -1) -> void:
	context.expect_true(result.was_rejected() or result.is_blocked(), label + ": fails closed")
	context.expect_true(result.next_state() == null and result.domain_events().is_empty(), label + ": no partial state or event")
	context.expect_true(result.candidate() == null and not result.is_commit_boundary(), label + ": no commit candidate")
	if reason >= 0:
		context.expect_equal(result.rejection_reason(), reason, label + ": reason")


func _expect_commit(context: HeadlessTestContextScript, state: WorldStepStateScript, result: WorldStepTransactionResultScript, label: String) -> bool:
	context.expect_true(result.was_committed(), label + ": committed, reason=%s" % result.rejection_reason())
	if not result.was_committed():
		return false
	context.expect_equal(result.next_state().grid_state().world_step(), state.grid_state().world_step() + 1, label + ": grid advances exactly once")
	context.expect_equal(result.next_state().enemy_world_state().world_step(), state.enemy_world_state().world_step() + 1, label + ": enemies advance exactly once")
	context.expect_equal(result.domain_events().size(), 1, label + ": one world publication")
	context.expect_equal(result.domain_events()[0].world_step_before(), state.grid_state().world_step(), label + ": event before")
	context.expect_equal(result.domain_events()[0].world_step_after(), state.grid_state().world_step() + 1, label + ": event after")
	return true


func _replace_grid(state: WorldStepStateScript, grid: GridRuleStateScript) -> WorldStepStateScript:
	return WorldStepStateScript.create(state.space_id(), grid, state.player_state(), state.enemy_world_state(), state.inventory_state(), state.stage_inputs())


func _move_and_wait(context: HeadlessTestContextScript) -> void:
	var state := _state(&"", 100, STEP, &"blueprint.20")
	var before := state.copy()
	for command: WorldStepCommandScript in [_move(state), _wait(state)]:
		var prepared := _prepare(state, command)
		context.expect_true(prepared.is_prepared(), "Valid action prepares")
		context.expect_true(prepared.next_state() == null and prepared.domain_events().is_empty(), "Preview publishes nothing")
		context.expect_true(state.is_equal_to(before), "Prepare/cancel preview preserves all input")
		var result := _commit(state, prepared)
		if _expect_commit(context, state, result, "Move/wait"):
			context.expect_equal(result.next_state().grid_state().actor_position(PLAYER_ID), command.direction(), "Expected position")
			context.expect_true(result.next_state().player_state().is_equal_to(state.player_state()), "No player cost")
			context.expect_true(result.next_state().inventory_state().is_equal_to(state.inventory_state()), "No inventory cost")
		context.expect_true(state.is_equal_to(before), "Commit does not mutate input")


func _contact_victory_and_next_entry(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")
	var prepared := _prepare(state, _move(state))
	context.expect_true(prepared.is_prepared(), "Real central shield contact prepares")
	if not prepared.is_prepared():
		return
	var original_resolution := prepared.candidate().combat_candidate().resolution()
	var result := _commit(state, prepared)
	if not _expect_commit(context, state, result, "Shield victory"):
		return
	var next := result.next_state()
	context.expect_true(original_resolution.is_equal_to(result.domain_events()[0].combat_event().resolution()), "Commit applies the same evaluated candidate")
	context.expect_equal(next.player_state().current_health(), 60, "10+2 attack vs 9 defense: shield + four hits, five enemy attacks at 8")
	context.expect_equal(next.grid_state().actor_position(PLAYER_ID), Vector3i.ZERO, "Victory retains original player cell")
	context.expect_true(not next.grid_state().has_actor(TARGET_ID), "Resolved enemy releases occupancy")
	var target := EnemyWorldResolverScript.resolve(next.enemy_world_state(), _registry()).lookup_enemy(TARGET_ID)
	context.expect_equal(target.lifecycle(), EnemyWorldRecordScript.Lifecycle.RESOLVED, "Retain resolved catalog record")
	context.expect_true(not target.has_world_address(), "Resolved record has no address")
	context.expect_equal(next.inventory_state().stack_snapshot(&"stack.temporary").quantity(), 1, "Consume one effect")
	context.expect_equal(next.inventory_state().revision(), 4, "Advance inventory revision once")
	context.expect_equal(next.inventory_state().selected_temporary_effect_stack_id(), &"", "Clear selection")
	var entered := _commit(next, _prepare(next, _move(next)))
	if _expect_commit(context, next, entered, "Next step enters freed cell"):
		context.expect_equal(entered.next_state().grid_state().actor_position(PLAYER_ID), EAST, "Freed cell entered on next step")
		context.expect_equal(entered.next_state().grid_state().world_step(), STEP + 2, "Contact and entry cost two steps")
		context.expect_true(entered.domain_events()[0].combat_event() == null, "No repeated combat or late terrain trigger")


func _defeat_retains_enemy(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base", 9, STEP, &"blueprint.20", 1)
	var result := _commit(state, _prepare(state, _move(state)))
	if not _expect_commit(context, state, result, "Player defeat"):
		return
	var next := result.next_state()
	context.expect_equal(next.player_state().current_health(), 0, "Defeat sets health to zero")
	context.expect_equal(next.grid_state().actor_position(PLAYER_ID), Vector3i.ZERO, "Defeat retains player cell")
	context.expect_equal(next.grid_state().actor_position(TARGET_ID), EAST, "Surviving enemy retains cell")
	var enemy := EnemyWorldResolverScript.resolve(next.enemy_world_state(), _registry()).lookup_enemy(TARGET_ID)
	context.expect_equal(enemy.lifecycle(), EnemyWorldRecordScript.Lifecycle.ACTIVE, "Enemy remains active")
	context.expect_true(not enemy.instance_state().shield_intact(), "First player hit consumes shield")
	context.expect_true(next.inventory_state().stack_snapshot(&"stack.temporary") == null, "Last temporary item removed even in defeat")
	_expect_failed(context, _prepare(next, _wait(next)), "Inactive player cannot advance")


func _shield_and_all_temporary_effects(context: HeadlessTestContextScript) -> void:
	for blueprint: StringName in [&"", &"blueprint.20", &"blueprint.21", &"blueprint.22", &"blueprint.23", &"blueprint.24"]:
		for intact: bool in [true, false]:
			var state := _state(&"enemy.profile.f03.base", 100, STEP, blueprint, 1, intact)
			var prepared := _prepare(state, _move(state))
			context.expect_true(prepared.is_prepared(), "All supported effects prepare")
			if not prepared.is_prepared():
				continue
			var resolution := prepared.candidate().combat_candidate().resolution()
			var result := _commit(state, prepared)
			if _expect_commit(context, state, result, "Effect and shield"):
				context.expect_equal(result.next_state().player_state().current_health(), resolution.next_player_health(), "Same health candidate")
				context.expect_true(resolution.is_equal_to(result.domain_events()[0].combat_event().resolution()), "Exact effect/shield resolution retained")
				context.expect_equal(result.next_state().inventory_state().revision(), 3 if blueprint == &"" else 4, "Only selected effect advances revision")
				context.expect_equal(resolution.opponent_shield_absorbed_attack(), intact, "Intact shield absorbs first player attack")
	var saturated := _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")
	var inventory := saturated.inventory_state()
	var overflow_inventory := PortableInventoryStateScript.create(6, 6, 12, PortableInventoryStateScript.MAXIMUM_REVISION, inventory.stack_snapshots(), inventory.selected_temporary_effect_stack_id())
	var overflow_state := WorldStepStateScript.create(SPACE_ID, saturated.grid_state(), saturated.player_state(), saturated.enemy_world_state(), overflow_inventory, saturated.stage_inputs())
	_expect_failed(context, _prepare(overflow_state, _move(overflow_state)), "Temporary consumption revision overflow")
	context.expect_true(_commit(overflow_state, _prepare(overflow_state, _wait(overflow_state))).was_committed(), "Wait does not consume selected effect at saturated revision")
	var blocked := _state(&"enemy.profile.f03.enhanced", 100, STEP, &"blueprint.21")
	var before := blocked.copy()
	var result := _prepare(blocked, _move(blocked))
	context.expect_true(result.is_blocked(), "10 attack vs 10 defense is blocked, not a step")
	_expect_failed(context, result, "Zero damage")
	context.expect_true(blocked.is_equal_to(before), "Zero damage keeps item, health, shield and step")
	_expect_failed(context, _commit(blocked, result), "Cannot commit blocked preview")


func _invalid_commands_and_geometry(context: HeadlessTestContextScript) -> void:
	var state := _state()
	var commands: Array[WorldStepCommandScript] = [
		WorldStepCommandScript.new(), WorldStepCommandScript.create(99, STEP, Vector3i.ZERO, EAST),
		_move(state, Vector3i.ZERO), _move(state, Vector3i(0, 1, 0)), _move(state, EAST * 2),
		_move(state, -EAST), WorldStepCommandScript.create(WorldStepCommandScript.Kind.WAIT, STEP, Vector3i.ZERO, EAST),
		WorldStepCommandScript.create(WorldStepCommandScript.Kind.WAIT, STEP - 1, Vector3i.ZERO, Vector3i.ZERO),
		WorldStepCommandScript.create(WorldStepCommandScript.Kind.MOVE, STEP, EAST, EAST),
	]
	for command: WorldStepCommandScript in commands:
		_expect_failed(context, _prepare(state, command), "Invalid command/geometry")
	var grid := state.grid_state()
	var blocked := _replace_grid(state, GridRuleStateScript.create(grid.grid_cells(), [EAST], grid.actor_positions(), STEP))
	_expect_failed(context, _prepare(blocked, _move(blocked)), "Blocked terrain")
	var edge: Vector3i = Vector3i(2147483647, 0, 0)
	var extreme := _replace_grid(state, GridRuleStateScript.create([edge], [], {PLAYER_ID: edge}, STEP))
	_expect_failed(context, _prepare(extreme, _move(extreme)), "Coordinate overflow")
	_expect_failed(context, WorldStepTransactionKernelScript.prepare(null, _wait(state), _registry()), "Null state")
	_expect_failed(context, WorldStepTransactionKernelScript.prepare(state, RefCounted.new(), _registry()), "Wrong command type")


func _unsupported_stages_and_enemy_behaviors(context: HeadlessTestContextScript) -> void:
	var state := _state()
	for index: int in range(6):
		var sources: Array[StringName] = [&"source.pending"]
		var empty: Array[StringName] = []
		var stages := WorldStepStageInputsScript.create(
			sources if index == 0 else empty, sources if index == 1 else empty,
			sources if index == 2 else empty, sources if index == 3 else empty,
			sources if index == 4 else empty, index != 5,
		)
		var unsupported := WorldStepStateScript.create(SPACE_ID, state.grid_state(), state.player_state(), state.enemy_world_state(), state.inventory_state(), stages)
		_expect_failed(context, _prepare(unsupported, _wait(unsupported)), "Nonempty or incomplete stage inputs", Reason.UNSUPPORTED_SCENARIO)
	for profile: StringName in [&"enemy.profile.f01.base", &"enemy.profile.f02.base", &"enemy.profile.f04.base", &"enemy.profile.f05.base", &"enemy.profile.f06.base"]:
		var unsupported := _state(profile)
		_expect_failed(context, _prepare(unsupported, _wait(unsupported)), "Central behavior requires unsupported stage", Reason.UNSUPPORTED_SCENARIO)
	var grid := state.grid_state()
	var cells := grid.grid_cells()
	cells.append(Vector3i(0, 1, 0))
	var vertical := _replace_grid(state, GridRuleStateScript.create(cells, [], grid.actor_positions(), STEP))
	_expect_failed(context, _prepare(vertical, _wait(vertical)), "Nonhorizontal grid", Reason.UNSUPPORTED_SCENARIO)


func _full_prestate_revalidation(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")
	var prepared := _prepare(state, _move(state))
	context.expect_true(prepared.is_prepared(), "Prepare stale-state fixture")
	var changed: Array[WorldStepStateScript] = []
	var grid := state.grid_state()
	var positions := grid.actor_positions()
	positions[PLAYER_ID] = Vector3i(0, 0, 1)
	changed.append(_replace_grid(state, GridRuleStateScript.create(grid.grid_cells(), [], positions, STEP)))
	# Unrelated topology is part of the complete prestate too.
	changed.append(_replace_grid(state, GridRuleStateScript.create(grid.grid_cells(), [EAST * 2], grid.actor_positions(), STEP)))
	changed.append(_state(&"enemy.profile.f03.base", 99, STEP, &"blueprint.20"))
	changed.append(_state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20", 1))
	changed.append(_state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20", 2, false))
	changed.append(_state(&"enemy.profile.f03.base", 100, STEP + 1, &"blueprint.20"))
	changed.append(WorldStepStateScript.create(&"space.other", state.grid_state(), state.player_state(), state.enemy_world_state(), state.inventory_state(), state.stage_inputs()))
	changed.append(WorldStepStateScript.create(SPACE_ID, state.grid_state(), state.player_state(), state.enemy_world_state(), state.inventory_state(), WorldStepStageInputsScript.create([&"new.construct"], [], [], [], [], true)))
	for current: WorldStepStateScript in changed:
		var before := current.copy()
		_expect_failed(context, _commit(current, prepared), "Full prestate mismatch", Reason.PRESTATE_MISMATCH)
		context.expect_true(current.is_equal_to(before), "Rejected commit preserves current state")
	context.expect_true(_commit(state, prepared).was_committed(), "Original candidate remains usable against unchanged prestate")


func _duplicate_commit_and_determinism(context: HeadlessTestContextScript) -> void:
	for state: WorldStepStateScript in [_state(), _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")]:
		for command: WorldStepCommandScript in [_wait(state), _move(state)]:
			var scenario: String = "%s/%s" % [
				"shield" if state.grid_state().has_actor(TARGET_ID) else "empty",
				"MOVE" if command.kind() == WorldStepCommandScript.Kind.MOVE else "WAIT",
			]
			var prepared := _prepare(state, command)
			context.expect_true(prepared.is_prepared(), scenario + ": prepares repeatable candidate")
			if not prepared.is_prepared():
				continue
			var candidate_before := prepared.candidate()
			var first := _commit(state, prepared)
			var first_committed: bool = _expect_commit(context, state, first, "First commit " + scenario)
			var replay := _commit(state, prepared)
			var replay_committed: bool = _expect_commit(context, state, replay, "Replay commit " + scenario)
			if first_committed and replay_committed:
				context.expect_true(first.next_state().is_equal_to(replay.next_state()), "Same inputs yield identical states without mutable used flag")
				context.expect_true(first.domain_events()[0].is_equal_to(replay.domain_events()[0]), "Same inputs yield identical events")
			if first_committed:
				_expect_failed(context, _commit(first.next_state(), prepared), "Reject duplicate on advanced current state", Reason.PRESTATE_MISMATCH)
			context.expect_true(prepared.is_prepared(), "Commit does not consume candidate")
			context.expect_true(candidate_before.is_equal_to(prepared.candidate()), "Commit preserves the complete prepared candidate")


func _content_drift(context: HeadlessTestContextScript) -> void:
	var registry := CanonicalRegistryFixtureScript.fresh_canonical_registry(context, "World step drift")
	var state := _state()
	var prepared := WorldStepTransactionKernelScript.prepare(state, _wait(state), registry)
	context.expect_true(prepared.is_prepared(), "Prepare before drift")
	registry._enemy_profiles[0].attack += 1
	_expect_failed(context, WorldStepTransactionKernelScript.commit(state, prepared, registry), "Drift in unrelated content rejects commit", Reason.INVALID_REGISTRY)
	_expect_failed(context, WorldStepTransactionKernelScript.prepare(state, _wait(state), registry), "Drift rejects prepare", Reason.INVALID_REGISTRY)
	context.expect_true(registry._verified_read_scope == null, "No fast-path leak")


func _world_step_limit(context: HeadlessTestContextScript) -> void:
	for profile: StringName in [&"", &"enemy.profile.f03.base"]:
		var state := _state(profile, 100, ValidationSupportScript.MAX_WORLD_STEP - 1, &"blueprint.20")
		for command: WorldStepCommandScript in [_move(state), _wait(state)]:
			var result := _commit(state, _prepare(state, command))
			if _expect_commit(context, state, result, "Last representable step"):
				var next := result.next_state()
				_expect_failed(context, _prepare(next, _wait(next)), "Maximum step wait", Reason.WORLD_STEP_LIMIT)
				_expect_failed(context, _prepare(next, _move(next)), "Maximum step move", Reason.WORLD_STEP_LIMIT)


func _projection_and_lifecycle(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base")
	var grid := state.grid_state()
	var projections: Array[Dictionary] = [{PLAYER_ID: Vector3i.ZERO}, {PLAYER_ID: Vector3i.ZERO, TARGET_ID: EAST * 2}, {PLAYER_ID: Vector3i.ZERO, TARGET_ID: EAST, &"actor.orphan": EAST * 2}]
	for positions: Dictionary in projections:
		var typed: Dictionary[StringName, Vector3i] = {}
		typed.assign(positions)
		var bad := _replace_grid(state, GridRuleStateScript.create(grid.grid_cells(), [], typed, STEP))
		_expect_failed(context, _prepare(bad, _wait(bad)), "Enemy projection mismatch", Reason.PROJECTION_MISMATCH)
	var bad_step := _replace_grid(state, GridRuleStateScript.create(grid.grid_cells(), [], grid.actor_positions(), STEP + 1))
	_expect_failed(context, _prepare(bad_step, _wait(bad_step)), "Different component steps", Reason.PROJECTION_MISMATCH)
	var resolved_instance := EnemyInstanceStateScript.create(TARGET_ID, &"enemy.profile.f03.base", 6, 6, 0, EnemyInstanceStateScript.StateKind.PRIMARY, false)
	var invalid_world := EnemyWorldStateScript.create([EnemyWorldRecordScript.create(resolved_instance, EnemyWorldRecordScript.Lifecycle.ACTIVE)], {TARGET_ID: EnemyWorldAddressScript.create(SPACE_ID, EAST)}, STEP)
	var invalid := WorldStepStateScript.create(SPACE_ID, grid, state.player_state(), invalid_world, state.inventory_state(), state.stage_inputs())
	_expect_failed(context, _prepare(invalid, _wait(state)), "Zero-durability active lifecycle")
	var world := EnemyWorldResolverScript.resolve(state.enemy_world_state(), _registry())
	var foreign_world := EnemyWorldStateScript.create(world.record_snapshots(), {TARGET_ID: EnemyWorldAddressScript.create(&"space.other", EAST)}, STEP)
	var foreign := WorldStepStateScript.create(SPACE_ID, _state().grid_state(), state.player_state(), foreign_world, state.inventory_state(), state.stage_inputs())
	_expect_failed(context, _prepare(foreign, _wait(foreign)), "Multiple spaces", Reason.UNSUPPORTED_SCENARIO)


func _snapshot_isolation(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")
	var prepared := _prepare(state, _move(state))
	context.expect_true(prepared.is_prepared(), "Isolation fixture prepares")
	if not prepared.is_prepared():
		return
	var input_grid := state.grid_state()
	var input_player := state.player_state()
	var input_enemies := state.enemy_world_state()
	var input_inventory := state.inventory_state()
	var input_stages := state.stage_inputs()
	var constructed := WorldStepStateScript.create(SPACE_ID, input_grid, input_player, input_enemies, input_inventory, input_stages)
	input_grid._world_step += 1
	input_player._current_health = 0
	input_enemies._world_step += 1
	input_inventory._revision += 1
	input_stages._complete = false
	context.expect_true(constructed.is_equal_to(state), "Aggregate construction copies every nested input")
	var cells := constructed.grid_state().grid_cells()
	cells.clear()
	var sources := constructed.stage_inputs().construct_sources()
	sources.append(&"source.new")
	context.expect_true(constructed.is_equal_to(state), "Nested collection getters are isolated")
	var exposed := prepared.candidate()
	exposed._previous_state._grid_state._world_step = 999
	context.expect_true(prepared.is_prepared(), "Candidate getter deep copies")
	state.grid_state()._world_step = 999
	state.player_state()._current_health = 1
	state.inventory_state()._revision = 999
	context.expect_true(state.is_valid(), "State getters do not expose internal references")
	var result := _commit(state, prepared)
	if not _expect_commit(context, state, result, "Snapshot isolation"):
		return
	var next := result.next_state()
	next._grid_state._world_step = 999
	var event := result.domain_events()[0]
	event._world_step_after = 999
	context.expect_true(result.was_committed(), "Returned state and event are isolated")
	var combat_event := result.domain_events()[0].combat_event()
	combat_event._world_step = 999
	context.expect_true(result.domain_events()[0].is_valid(), "Nested combat event isolated")
	state._grid_state._world_step = 999
	context.expect_true(prepared.is_prepared(), "Mutating original after prepare cannot rewrite captured prestate")
	_expect_failed(context, _commit(state, prepared), "Mutated original rejects commit")


func _tampering_and_closed_construction(context: HeadlessTestContextScript) -> void:
	var state := _state()
	var prepared := _prepare(state, _move(state))
	prepared._candidate._command._direction = -EAST
	_expect_failed(context, _commit(state, prepared), "Tampered prepared command")
	prepared = _prepare(state, _move(state))
	prepared._candidate._previous_state._inventory_state._revision += 1
	_expect_failed(context, _commit(state, prepared), "Tampered nested prestate")
	_expect_failed(context, _commit(state, WorldStepTransactionResultScript.new()), "Default result is not committable")
	for script: Script in [WorldStepTransactionResultScript, WorldStepTransactionCandidateScript, WorldStepTransactionEventScript]:
		for method: Dictionary in script.get_script_method_list():
			context.expect_true(method.name not in [&"prepared", &"committed", &"success", &"create"], "No public successful construction factory")
	var result := _commit(state, _prepare(state, _move(state)))
	context.expect_true(result.was_committed(), "Valid result exists before tampering")
	if not result.was_committed():
		return
	result._next_state._player_state._current_health = 99
	_expect_failed(context, result, "Tampered committed state hides event and state")


func _contact_binding(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base", 100, STEP, &"blueprint.20")
	var command := _move(state)
	var prepared := _prepare(state, command)
	context.expect_true(prepared.is_prepared(), "Binding fixture prepares")
	if not prepared.is_prepared():
		return
	var candidate := prepared.candidate()
	var lock := candidate.contact_lock()
	var combat := candidate.combat_candidate()
	context.expect_true(WorldStepTransactionKernelScript.validate_contact_binding(state, command, lock, combat), "Correct lock binds")
	var enemy_contact := WorldStepContactKernelScript.prepare(state.grid_state(), state.player_state(), state.enemy_world_state(), WorldStepContactCommandScript.attempt_entry(SPACE_ID, TARGET_ID, EAST, -EAST, STEP), _registry())
	context.expect_true(enemy_contact.is_locked(), "Opposite mover creates valid historical lock")
	context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(state, command, enemy_contact.contact_lock(), combat), "Wrong moving side cannot bind")
	for altered: WorldStepCommandScript in [_move(state, Vector3i(0, 0, 1)), _wait(state), WorldStepCommandScript.create(WorldStepCommandScript.Kind.MOVE, STEP + 1, Vector3i.ZERO, EAST)]:
		context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(state, altered, lock, combat), "Direction/action/step must bind")
	var other_combat := ContactCombatTransactionKernelScript.prepare(state.player_state(), state.enemy_world_state(), state.inventory_state(), ContactCombatTransactionCommandScript.resolve_contact(TARGET_ID, lock.target_enemy_address(), [], ContactCombatCommandScript.Side.OPPONENT), _registry())
	context.expect_true(other_combat.is_prepared(), "Opposite-initiator combat is independently valid")
	context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(state, command, lock, other_combat.candidate()), "Wrong combat initiator cannot bind")
	# 使用各自合法且重新封装的两层工件，确保失败来自衔接校验而非镜像篡改检测。
	prepared._candidate._combat_candidate = other_combat.candidate()
	prepared._candidate._capture_integrity()
	prepared._capture_integrity()
	_expect_failed(context, _commit(state, prepared), "Commit enforces binding", Reason.CONTACT_BINDING_MISMATCH)
	var world := EnemyWorldResolverScript.resolve(state.enemy_world_state(), _registry())
	var records := world.record_snapshots()
	var addresses := world.address_snapshots()
	var second_id: StringName = &"enemy.instance.world.second"
	var second_cell: Vector3i = Vector3i(0, 0, 1)
	records.append(EnemyWorldRecordScript.create(EnemyInstanceStateScript.create(second_id, &"enemy.profile.f03.base", 6, 6, 12, EnemyInstanceStateScript.StateKind.PRIMARY, true), EnemyWorldRecordScript.Lifecycle.ACTIVE))
	addresses[second_id] = EnemyWorldAddressScript.create(SPACE_ID, second_cell)
	var positions := state.grid_state().actor_positions()
	positions[second_id] = second_cell
	var two_enemies := WorldStepStateScript.create(SPACE_ID, GridRuleStateScript.create(state.grid_state().grid_cells(), [], positions, STEP), state.player_state(), EnemyWorldResolverScript.resolve(EnemyWorldStateScript.create(records, addresses, STEP), _registry()).snapshot(), state.inventory_state(), state.stage_inputs())
	context.expect_true(two_enemies.is_valid(), "Multi-enemy fixture uses canonical resolved world state")
	if not two_enemies.is_valid():
		return
	var first_contact := _prepare(two_enemies, _move(two_enemies))
	var second_contact := _prepare(two_enemies, _move(two_enemies, second_cell))
	context.expect_true(first_contact.is_prepared() and second_contact.is_prepared(), "Two independently valid targets")
	if first_contact.is_prepared() and second_contact.is_prepared():
		context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(two_enemies, _move(two_enemies), first_contact.candidate().contact_lock(), second_contact.candidate().combat_candidate()), "Target ID and address must match the locked enemy")
	# Same instance in another space/address is a valid subtransaction, but cannot bind this lock.
	var displaced_world := EnemyWorldStateScript.create(world.record_snapshots(), {TARGET_ID: EnemyWorldAddressScript.create(&"space.displaced", EAST)}, STEP)
	var displaced := ContactCombatTransactionKernelScript.prepare(state.player_state(), displaced_world, state.inventory_state(), ContactCombatTransactionCommandScript.resolve_contact(TARGET_ID, EnemyWorldAddressScript.create(&"space.displaced", EAST), [], ContactCombatCommandScript.Side.PLAYER), _registry())
	context.expect_true(displaced.is_prepared(), "Displaced target is valid only in its own subtransaction")
	context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(state, command, lock, displaced.candidate()), "Same target ID at another address cannot bind")
	var shifted := _state(&"enemy.profile.f03.base", 100, STEP + 1, &"blueprint.20")
	context.expect_true(not WorldStepTransactionKernelScript.validate_contact_binding(shifted, _move(shifted), lock, combat), "Lock cannot migrate to another step")


func _cancelled_contact_contract(context: HeadlessTestContextScript) -> void:
	var state := _state(&"enemy.profile.f03.base")
	var lock := WorldStepContactKernelScript.prepare(state.grid_state(), state.player_state(), state.enemy_world_state(), WorldStepContactCommandScript.attempt_entry(SPACE_ID, PLAYER_ID, Vector3i.ZERO, EAST, STEP), _registry())
	var inactive := PlayerProgressionStateScript.create(&"progression.player.loer", 6, 6, 0, [])
	var cancelled := WorldStepContactKernelScript.revalidate(lock, state.grid_state(), inactive, state.enemy_world_state(), _registry())
	context.expect_true(cancelled.was_cancelled() and not cancelled.was_rejected(), "Periodic inactivity remains cancellation, not validation failure")
	context.expect_equal(inactive.current_health(), 0, "Cancellation preserves prior-stage effective result")
	context.expect_true(not cancelled.is_actor_locked(PLAYER_ID), "Cancelled contact releases lock")
	var prepared := _prepare(state, _move(state))
	var changed := WorldStepStateScript.create(SPACE_ID, state.grid_state(), inactive, state.enemy_world_state(), state.inventory_state(), state.stage_inputs())
	_expect_failed(context, _commit(changed, prepared), "External inactivity is stale prestate, not simulated periodic cancellation", Reason.PRESTATE_MISMATCH)
