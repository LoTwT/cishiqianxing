extends RefCounted

const Initializer := preload("res://src/rules/static_map_initializer.gd")
const InitializationResult := preload("res://src/rules/static_map_initialization_result.gd")
const World := preload("res://src/rules/world_step_state.gd")
const WorldKernel := preload("res://src/rules/world_step_transaction_kernel.gd")
const WorldCommand := preload("res://src/rules/world_step_command.gd")
const WorldResult := preload("res://src/rules/world_step_transaction_result.gd")
const Player := preload("res://src/rules/player_progression_state.gd")
const Inventory := preload("res://src/rules/portable_inventory_state.gd")
const Stack := preload("res://src/rules/portable_inventory_stack.gd")
const EnemyResolver := preload("res://src/rules/enemy_world_resolver.gd")
const EnemyRecord := preload("res://src/rules/enemy_world_record.gd")
const Instance := preload("res://src/rules/enemy_instance_state.gd")
const Registry := preload("res://src/content/content_registry.gd")
const Builder := preload("res://src/content/content_registry_builder.gd")
const Manifest := preload("res://src/content/definitions/content_manifest_resource.gd")
const Fixture := preload("res://tests/support/canonical_registry_fixture.gd")
const Oracle := preload("res://tests/content/static_map_catalog_oracle.gd")
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")
const Reason = InitializationResult.FailureReason
const EAST: Vector3i = Vector3i(1, 0, 0)
const STACK_ID: StringName = &"stack.map.attack"

class DerivedPlayer extends Player:
	var read_count: int = 0
	func copy() -> Player:
		read_count += 1
		return Player.new()

class DerivedInventory extends Inventory:
	var read_count: int = 0
	func copy() -> Inventory:
		read_count += 1
		return Inventory.new()

class DerivedRegistry extends Registry:
	var read_count: int = 0
	func is_initialized() -> bool:
		read_count += 1
		return true


func cases() -> Array[Case]:
	return [
		Case.new("map_initialization.loads_new_world_from_resources", _loads_new_world_from_resources),
		Case.new("map_initialization.rejects_boundary_inputs", _rejects_boundary_inputs),
		Case.new("map_initialization.rejects_versions_and_invalid_states", _rejects_versions_and_invalid_states),
		Case.new("map_initialization.preserves_inputs_and_deep_snapshots", _preserves_inputs_and_deep_snapshots),
		Case.new("map_initialization.deterministic_reordered_resource_load", _deterministic_reordered_resource_load),
		Case.new("map_initialization.move_wait_and_geometry_rejections", _move_wait_and_geometry_rejections),
		Case.new("map_initialization.contact_consumption_and_multiple_enemies", _contact_consumption_and_multiple_enemies),
		Case.new("map_initialization.zero_damage_has_no_partial_commit", _zero_damage_has_no_partial_commit),
		Case.new("map_initialization.replays_same_candidate_without_consuming", _replays_same_candidate_without_consuming),
		Case.new("map_initialization.content_drift_closes_initialization_and_commit", _content_drift_closes_initialization_and_commit),
	]


func _registry(context: Context) -> Registry:
	var result := Fixture.canonical_registry(context, "Map initialization")
	context.expect_true(result != null and result.is_initialized(), "Tests require an actual canonical .tres registration.")
	return result


func _player(health: int = 149) -> Player:
	return Player.create(&"progression.player.loer", 6, 6, health, Oracle.mainline_rewards())


func _inventory(selected: bool = true) -> Inventory:
	return Inventory.create(6, 6, 20, 7, [Stack.create(STACK_ID, &"blueprint.20", Stack.Provenance.CRAFTED_FROM_RECIPE, &"recipe.standard.20", 2)], STACK_ID if selected else &"")


func _world(context: Context, registry: Registry, player: Player, inventory: Inventory) -> World:
	var result := Initializer.initialize(Oracle.MAP_ID, player, inventory, registry)
	context.expect_true(result.succeeded(), "Official initialization must succeed; reason %d." % result.failure_reason())
	context.expect_equal(result.domain_events(), [], "Initialization emits no world-step event.")
	context.expect_true(not result.is_commit_boundary(), "Initialization does not submit a transaction.")
	return result.world_state()


func _loads_new_world_from_resources(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var player := _player()
	var inventory := _inventory()
	var world := _world(context, registry, player, inventory)
	if world == null:
		return
	context.expect_equal(world.space_id(), Oracle.SPACE_ID, "Map owns selected space.")
	context.expect_equal(world.grid_state().world_step(), 0, "New grid starts at zero.")
	context.expect_equal(world.enemy_world_state().world_step(), 0, "New enemies start at zero.")
	context.expect_equal(world.grid_state().grid_cells(), Oracle.GRID_CELLS, "Grid comes from real .tres.")
	context.expect_equal(world.grid_state().blocked_cells(), Oracle.BLOCKED_CELLS, "Blocking comes from real .tres.")
	context.expect_equal(world.grid_state().actor_position(Oracle.PLAYER_ID), Vector3i.ZERO, "Authoritative player identity and spawn.")
	context.expect_true(world.player_state().is_equal_to(player), "Player is copied exactly.")
	context.expect_true(world.inventory_state().is_equal_to(inventory), "Inventory and selected crafted stack are copied exactly.")
	var stages := world.stage_inputs()
	context.expect_true(stages.complete(), "Loader proves source completeness.")
	context.expect_equal(stages.construct_sources(), [], "No construct source.")
	context.expect_equal(stages.environment_sources(), [], "No environment source.")
	context.expect_equal(stages.patrol_sources(), [], "No patrol source.")
	context.expect_equal(stages.periodic_sources(), [], "No periodic source.")
	context.expect_equal(stages.support_sources(), [], "No support source.")
	var enemies := EnemyResolver.resolve(world.enemy_world_state(), registry)
	context.expect_true(enemies.succeeded(), "Generated enemy world must resolve.")
	if not enemies.succeeded():
		return
	context.expect_equal(enemies.instance_ids(), Oracle.INSTANCE_IDS, "Only manifest placements spawn.")
	var records := enemies.record_snapshots()
	context.expect_equal(records.size(), 2, "Both enemies spawn.")
	for index: int in range(mini(2, records.size())):
		var instance := records[index].instance_state()
		context.expect_equal(instance.profile_id(), Oracle.PROFILE_IDS[index], "Central enemy identity.")
		context.expect_equal(instance.current_durability(), Oracle.DURABILITIES[index], "Central full durability literal.")
		context.expect_equal(instance.state_kind(), Instance.StateKind.PRIMARY, "Initial primary state.")
		context.expect_true(instance.shield_intact(), "Central initial shield is intact.")
		context.expect_equal(records[index].lifecycle(), EnemyRecord.Lifecycle.ACTIVE, "Initial lifecycle ACTIVE.")
		context.expect_equal(world.grid_state().actor_position(instance.instance_id()), Oracle.ENEMY_CELLS[index], "Instance ID is the grid actor ID.")
		context.expect_equal(enemies.address_snapshots()[instance.instance_id()].cell(), Oracle.ENEMY_CELLS[index], "Address agrees with grid.")


func _rejects_boundary_inputs(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	for invalid_id: StringName in [&"", &" ", &"地图", &"--", StringName("m".repeat(129))]:
		_expect_failure(context, Initializer.initialize(invalid_id, _player(), _inventory(), registry), Reason.INVALID_MAP_ID, "Invalid map ID")
	_expect_failure(context, Initializer.initialize(&"map.unknown", _player(), _inventory(), registry), Reason.UNKNOWN_MAP_ID, "Unknown map")
	for invalid: RefCounted in [null, RefCounted.new()]:
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, invalid, _inventory(), registry), Reason.INVALID_PLAYER_STATE, "Wrong player type")
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), invalid, registry), Reason.INVALID_INVENTORY_STATE, "Wrong inventory type")
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), _inventory(), invalid), Reason.INVALID_REGISTRY, "Wrong registry type")
	_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), _inventory(), Registry.new()), Reason.INVALID_REGISTRY, "Unsealed registry")
	var derived_player := DerivedPlayer.new()
	var derived_inventory := DerivedInventory.new()
	var derived_registry := DerivedRegistry.new()
	_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, derived_player, _inventory(), registry), Reason.INVALID_PLAYER_STATE, "Derived player")
	_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), derived_inventory, registry), Reason.INVALID_INVENTORY_STATE, "Derived inventory")
	_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), _inventory(), derived_registry), Reason.INVALID_REGISTRY, "Derived registry")
	context.expect_equal([derived_player.read_count, derived_inventory.read_count, derived_registry.read_count], [0, 0, 0], "Reject derived behavior without invoking it.")
	_expect_failure(context, InitializationResult.new(), Reason.INITIAL_STATE_REJECTED, "Raw result cannot fabricate success")


func _rejects_versions_and_invalid_states(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	for variant: int in range(4):
		var player := _player()
		var inventory := _inventory()
		match variant:
			0: player._content_schema_version = 5
			1: player._content_version = 5
			2: inventory._content_schema_version = 5
			3: inventory._content_version = 5
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, player, inventory, registry), Reason.CONTENT_VERSION_MISMATCH, "Old v5 runtime input %d" % variant)
	for player: Player in [Player.new(), _player(-1), _player(161), Player.create(&"progression.unknown", 6, 6, 1, []), Player.create(&"progression.player.loer", 6, 6, 100, [&"reward.unknown"])]:
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, player, _inventory(), registry), Reason.INVALID_PLAYER_STATE, "Invalid progression")
	for inventory: Inventory in [Inventory.new(), Inventory.create(6, 6, 1, 0, []), Inventory.create(6, 6, 20, 0, [], &"missing.stack"), Inventory.create(6, 6, 20, 0, [Stack.create(&"stack.unknown", &"blueprint.unknown", Stack.Provenance.NON_DISMANTLABLE_GIFT, &"", 1)])]:
		_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), inventory, registry), Reason.INVALID_INVENTORY_STATE, "Invalid inventory")
	var dead_world := _world(context, registry, _player(0), Inventory.create(6, 6, 20, 0, []))
	if dead_world == null:
		return
	context.expect_equal(dead_world.player_state().current_health(), 0, "Valid zero health remains zero; initialization never heals.")
	context.expect_equal(dead_world.inventory_state().occupied_slot_count(), 0, "Empty inventory receives no gifts.")


func _preserves_inputs_and_deep_snapshots(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var player := _player()
	var inventory := _inventory()
	var player_before := player.copy()
	var inventory_before := inventory.copy()
	var initialized := Initializer.initialize(Oracle.MAP_ID, player, inventory, registry)
	context.expect_true(initialized.succeeded(), "Isolation fixture must initialize.")
	if not initialized.succeeded():
		return
	context.expect_true(player.is_equal_to(player_before), "Initializer does not mutate player.")
	context.expect_true(inventory.is_equal_to(inventory_before), "Initializer does not mutate inventory.")
	var before := initialized.world_state()
	player._current_health = 1
	inventory._revision += 1
	inventory._stacks[0]._quantity = 1
	var output := initialized.world_state()
	output._player_state._current_health = 2
	output._inventory_state._stacks[0]._quantity = 1
	output._enemy_world_state._world_step = 90
	context.expect_true(initialized.world_state().is_equal_to(before), "Input and nested returned state mutations cannot reach result.")
	var grid := before.grid_state()
	grid._world_step = 80
	var enemies := before.enemy_world_state()
	enemies._world_step = 70
	var stages := before.stage_inputs()
	stages._complete = false
	context.expect_true(before.is_equal_to(initialized.world_state()), "World queries isolate grid, enemies and stages.")
	context.expect_true(registry.is_initialized(), "Snapshot mutations do not reach central content.")
	initialized._world_state._player_state._current_health = 3
	context.expect_true(not initialized.succeeded(), "Tampered result fails closed.")
	context.expect_equal(initialized.world_state(), null, "Tampered result exposes no partial world.")


func _deterministic_reordered_resource_load(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var world := _world(context, registry, _player(), _inventory())
	if world == null:
		return
	var manifest := ResourceLoader.load(Builder.CANONICAL_MANIFEST_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Manifest
	manifest.static_map_catalog.maps[0].grid_cells.reverse()
	manifest.static_map_catalog.maps[0].enemies.reverse()
	var rebuilt := Builder.build(manifest)
	context.expect_true(rebuilt.succeeded(), "Permuted real resource manifest must register.")
	if not rebuilt.succeeded():
		return
	var reordered := _world(context, rebuilt.registry(), _player(), _inventory())
	context.expect_true(world.is_equal_to(reordered), "Same input / reordered declarations produce identical worlds.")
	var repeated := _world(context, registry, _player(), _inventory())
	context.expect_true(world.is_equal_to(repeated), "Repeated initialization is deterministic and independent.")


func _move_wait_and_geometry_rejections(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var world := _world(context, registry, _player(), _inventory())
	if world == null:
		return
	var original := world.copy()
	for direction: Vector3i in [Vector3i(0, 0, -1), Vector3i(0, 0, 2), Vector3i(0, 1, 0)]:
		_expect_uncommitted(context, WorldKernel.prepare(world, _command(world, WorldCommand.Kind.MOVE, direction), registry), "Blocked or invalid movement")
	context.expect_true(world.is_equal_to(original), "All rejected inputs leave the full world unchanged.")
	var moved := _commit(context, world, WorldCommand.Kind.MOVE, Vector3i(-1, 0, 0), registry)
	if moved == null:
		return
	context.expect_equal(moved.grid_state().actor_position(Oracle.PLAYER_ID), Vector3i(-1, 0, 0), "Legal movement follows map geometry.")
	_expect_uncommitted(context, WorldKernel.prepare(moved, _command(moved, WorldCommand.Kind.MOVE, -EAST), registry), "Out-of-bounds movement")
	var waited := _commit(context, moved, WorldCommand.Kind.WAIT, Vector3i.ZERO, registry)
	if waited == null:
		return
	context.expect_equal(waited.grid_state().actor_position(Oracle.PLAYER_ID), Vector3i(-1, 0, 0), "Wait keeps position.")
	context.expect_true(waited.player_state().is_equal_to(world.player_state()), "Movement / wait do not change progression.")
	context.expect_true(waited.inventory_state().is_equal_to(world.inventory_state()), "Movement / wait preserve selection and quantities.")
	context.expect_equal(waited.grid_state().world_step(), 2, "Two successful actions advance two steps.")


func _contact_consumption_and_multiple_enemies(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var initial := _world(context, registry, _player(), _inventory())
	if initial == null:
		return
	var prepared := WorldKernel.prepare(initial, _command(initial, WorldCommand.Kind.MOVE, EAST), registry)
	context.expect_true(prepared.is_prepared(), "Resource-loaded contact must prepare.")
	if not prepared.is_prepared():
		return
	var committed := WorldKernel.commit(initial, prepared, registry)
	context.expect_true(committed.was_committed(), "Resource-loaded contact must commit.")
	if not committed.was_committed():
		return
	var first := committed.next_state()
	context.expect_equal(first.grid_state().world_step(), 1, "First contact advances once.")
	context.expect_equal(first.enemy_world_state().world_step(), 1, "Enemy step advances together.")
	context.expect_equal(committed.domain_events().size(), 1, "Exactly one world-step event.")
	var combat := committed.domain_events()[0].combat_event()
	context.expect_true(combat != null, "Contact carries the real combat subtransaction event.")
	if combat == null:
		return
	context.expect_equal(combat.world_step(), 0, "Combat uses the current step before outer advancement.")
	context.expect_equal(combat.consumed_stack_id(), STACK_ID, "Selected crafted item is consumed.")
	context.expect_equal(combat.resolution().player_damage_per_attack(), 7, "Central growth 15 plus temporary 2 minus enemy defense 10.")
	context.expect_equal(combat.resolution().player_attacks_required_to_clear(), 5, "Four damaging attacks plus initial shield.")
	context.expect_equal(first.player_state().current_health(), 129, "Independent first-battle loss is 20.")
	context.expect_equal(first.inventory_state().stack_snapshots()[0].quantity(), 1, "Exactly one temporary item consumed.")
	context.expect_equal(first.inventory_state().selected_temporary_effect_stack_id(), &"", "Consumed selection clears.")
	context.expect_equal(first.inventory_state().revision(), 8, "Inventory revision advances once for consumption.")
	context.expect_equal(first.grid_state().actor_position(Oracle.PLAYER_ID), Vector3i.ZERO, "Victory leaves player at original cell.")
	context.expect_true(not first.grid_state().has_actor(Oracle.INSTANCE_IDS[0]), "Resolved enemy releases actor occupancy.")
	var records := EnemyResolver.resolve(first.enemy_world_state(), registry).record_snapshots()
	context.expect_equal(records[0].lifecycle(), EnemyRecord.Lifecycle.RESOLVED, "First record remains resolved history.")
	context.expect_equal(records[0].instance_state().current_durability(), 0, "Resolved durability is zero.")
	context.expect_equal(records[1].instance_state().current_durability(), 30, "Second enemy retains full central durability.")
	var entered := _commit(context, first, WorldCommand.Kind.MOVE, EAST, registry)
	if entered == null:
		return
	context.expect_equal(entered.grid_state().actor_position(Oracle.PLAYER_ID), EAST, "Next world step enters released cell.")
	var second := _commit(context, entered, WorldCommand.Kind.MOVE, EAST, registry)
	if second == null:
		return
	context.expect_equal(second.grid_state().actor_position(Oracle.PLAYER_ID), EAST, "Second victory also retains original player cell.")
	context.expect_true(not second.grid_state().has_actor(Oracle.INSTANCE_IDS[1]), "Second enemy releases its cell.")
	context.expect_equal(second.player_state().current_health(), 109, "Unselected second battle loses 20 without reusing the temporary effect.")
	context.expect_true(second.inventory_state().is_equal_to(first.inventory_state()), "Unselected remaining item is not consumed.")
	var final_world := _commit(context, second, WorldCommand.Kind.MOVE, EAST, registry)
	if final_world == null:
		return
	context.expect_equal(final_world.grid_state().world_step(), 4, "Two contacts plus two entries take four steps.")
	context.expect_equal(final_world.grid_state().actor_position(Oracle.PLAYER_ID), EAST * 2, "Player enters second freed cell next step.")
	context.expect_equal(final_world.grid_state().actor_ids(), [Oracle.PLAYER_ID], "Both enemies are absent from occupancy.")
	context.expect_equal(initial.grid_state().world_step(), 0, "Original initialized world never changed.")


func _zero_damage_has_no_partial_commit(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var world := _world(context, registry, Player.create(&"progression.player.loer", 6, 6, 100, []), _inventory(false))
	if world == null:
		return
	var before := world.copy()
	var blocked := WorldKernel.prepare(world, _command(world, WorldCommand.Kind.MOVE, EAST), registry)
	context.expect_true(blocked.is_blocked(), "Initial attack 10 against central defense 10 must block.")
	_expect_uncommitted(context, blocked, "Zero damage")
	_expect_uncommitted(context, WorldKernel.commit(world, blocked, registry), "Blocked result cannot commit")
	context.expect_true(world.is_equal_to(before), "Zero damage preserves every input field, selected items and occupancy.")
	context.expect_equal(world.grid_state().world_step(), 0, "Zero damage advances zero steps.")


func _replays_same_candidate_without_consuming(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	for direction: Vector3i in [Vector3i.ZERO, -EAST, EAST]:
		var world := _world(context, registry, _player(), _inventory())
		if world == null:
			return
		var kind: int = WorldCommand.Kind.WAIT if direction == Vector3i.ZERO else WorldCommand.Kind.MOVE
		var command := _command(world, kind, direction)
		var prepared := WorldKernel.prepare(world, command, registry)
		context.expect_true(prepared.is_prepared(), "Wait / move / contact candidate must prepare.")
		if not prepared.is_prepared():
			continue
		var candidate_before := prepared.candidate()
		var committed := WorldKernel.commit(world, prepared, registry)
		context.expect_true(committed.was_committed(), "First commit must succeed.")
		if not committed.was_committed():
			continue
		var replay := WorldKernel.commit(world, prepared, registry)
		context.expect_true(replay.was_committed(), "Same candidate against same prestate must commit again.")
		if replay.was_committed():
			context.expect_true(replay.next_state().is_equal_to(committed.next_state()), "Replay state is deterministic.")
			context.expect_true(replay.domain_events()[0].is_equal_to(committed.domain_events()[0]), "Replay event is deterministic.")
		context.expect_true(prepared.is_prepared(), "Candidate remains prepared after commit.")
		context.expect_true(prepared.candidate().is_equal_to(candidate_before), "Candidate is never consumed or changed.")
		_expect_uncommitted(context, WorldKernel.commit(committed.next_state(), prepared, registry), "Advanced prestate rejects replay")
		context.expect_equal(world.grid_state().world_step(), 0, "Repeated pure evaluation leaves initial world at zero.")


func _content_drift_closes_initialization_and_commit(context: Context) -> void:
	var built := Builder.build_canonical()
	context.expect_true(built.succeeded(), "Drift fixture must register actual resources.")
	if not built.succeeded():
		return
	var registry := built.registry()
	var world := _world(context, registry, _player(), _inventory())
	if world == null:
		return
	var prepared := WorldKernel.prepare(world, _command(world, WorldCommand.Kind.MOVE, EAST), registry)
	context.expect_true(prepared.is_prepared(), "Content drift test has a real prepared candidate.")
	registry._static_map_catalog.maps[0].player_spawn_cell = -EAST
	_expect_failure(context, Initializer.initialize(Oracle.MAP_ID, _player(), _inventory(), registry), Reason.INVALID_REGISTRY, "Map content drift")
	_expect_uncommitted(context, WorldKernel.commit(world, prepared, registry), "Map drift between prepare and commit")
	context.expect_equal(world.grid_state().world_step(), 0, "Map drift leaves loaded world unchanged.")


func _command(world: World, kind: int, direction: Vector3i) -> WorldCommand:
	return WorldCommand.create(kind, world.grid_state().world_step(), world.grid_state().actor_position(Oracle.PLAYER_ID), direction)


func _commit(context: Context, world: World, kind: int, direction: Vector3i, registry: Registry) -> World:
	var before := world.copy()
	var prepared := WorldKernel.prepare(world, _command(world, kind, direction), registry)
	context.expect_true(prepared.is_prepared(), "Legal action must prepare.")
	context.expect_equal(prepared.next_state(), null, "Prepare does not publish state.")
	context.expect_equal(prepared.domain_events(), [], "Prepare does not publish events.")
	if not prepared.is_prepared():
		return null
	var committed := WorldKernel.commit(world, prepared, registry)
	context.expect_true(committed.was_committed(), "Legal action must commit.")
	context.expect_true(world.is_equal_to(before), "Pure commit preserves full original state.")
	if not committed.was_committed():
		return null
	context.expect_equal(committed.next_state().grid_state().world_step(), before.grid_state().world_step() + 1, "Success advances grid exactly once.")
	context.expect_equal(committed.next_state().enemy_world_state().world_step(), before.enemy_world_state().world_step() + 1, "Success advances enemy world exactly once.")
	context.expect_equal(committed.domain_events().size(), 1, "Success emits exactly one world event.")
	return committed.next_state()


func _expect_failure(context: Context, result: InitializationResult, reason: int, label: String) -> void:
	context.expect_true(not result.succeeded(), label + " must fail.")
	context.expect_equal(result.failure_reason(), reason, label + " structured reason.")
	context.expect_equal(result.world_state(), null, label + " exposes no partial world.")
	context.expect_equal(result.domain_events(), [], label + " exposes no commit event.")


func _expect_uncommitted(context: Context, result: WorldResult, label: String) -> void:
	context.expect_true(result.was_rejected() or result.is_blocked(), label + " must reject or block.")
	context.expect_equal(result.next_state(), null, label + " exposes no partial world.")
	context.expect_equal(result.domain_events(), [], label + " exposes no commit event.")
