class_name StaticMapInitializer
extends RefCounted

const StaticMapInitializationResultScript := preload("res://src/rules/static_map_initialization_result.gd")
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")
const MapEnemyPlacementScript := preload("res://src/content/definitions/map_enemy_placement_resource.gd")
const PlayerProgressionStateScript := preload("res://src/rules/player_progression_state.gd")
const PortableInventoryStateScript := preload("res://src/rules/portable_inventory_state.gd")
const PermanentGrowthClaimKernelScript := preload("res://src/rules/permanent_growth_claim_kernel.gd")
const PortableInventoryResolverScript := preload("res://src/rules/portable_inventory_resolver.gd")
const EnemyInstanceResolverScript := preload("res://src/rules/enemy_instance_resolver.gd")
const EnemyWorldResolverScript := preload("res://src/rules/enemy_world_resolver.gd")
const EnemyWorldRecordScript := preload("res://src/rules/enemy_world_record.gd")
const EnemyWorldAddressScript := preload("res://src/rules/enemy_world_address.gd")
const EnemyWorldStateScript := preload("res://src/rules/enemy_world_state.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepStageInputsScript := preload("res://src/rules/world_step_stage_inputs.gd")
const WorldStepStaticScenarioScript := preload("res://src/rules/world_step_static_scenario.gd")
const WorldStepContactCommandScript := preload("res://src/rules/world_step_contact_command.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

const Reason = StaticMapInitializationResultScript.FailureReason
const PLAYER_ID: StringName = WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID


# 仅从封印静态内容创建新世界；不恢复生命、不消费选择、不执行或提交世界步。
static func initialize(
	map_id: StringName,
	player_candidate: RefCounted,
	inventory_candidate: RefCounted,
	registry: RefCounted,
) -> StaticMapInitializationResultScript:
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _failure(Reason.INVALID_REGISTRY)
	var scope := (registry as ContentRegistryScript)._begin_verified_read_scope()
	if scope == null:
		return _failure(Reason.INVALID_REGISTRY)
	var result := _initialize(map_id, player_candidate, inventory_candidate, scope._registry)
	var captured_content_valid: bool = scope._close()
	if not captured_content_valid or not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _failure(Reason.INVALID_REGISTRY)
	return result


static func _initialize(
	map_id: StringName,
	player_candidate: RefCounted,
	inventory_candidate: RefCounted,
	registry: ContentRegistryScript,
) -> StaticMapInitializationResultScript:
	if not ValidationSupportScript.is_valid_identifier(map_id, StaticMapDefinitionScript.MAXIMUM_MAP_ID_LENGTH):
		return _failure(Reason.INVALID_MAP_ID)
	var query := registry.lookup_static_map(map_id)
	if not query.succeeded():
		return _failure(Reason.UNKNOWN_MAP_ID)
	if player_candidate == null or player_candidate.get_script() != PlayerProgressionStateScript:
		return _failure(Reason.INVALID_PLAYER_STATE)
	if inventory_candidate == null or inventory_candidate.get_script() != PortableInventoryStateScript:
		return _failure(Reason.INVALID_INVENTORY_STATE)
	var player: PlayerProgressionStateScript = (player_candidate as PlayerProgressionStateScript).copy()
	var inventory: PortableInventoryStateScript = (inventory_candidate as PortableInventoryStateScript).copy()
	if not player.is_valid():
		return _failure(Reason.INVALID_PLAYER_STATE)
	if not inventory.is_valid():
		return _failure(Reason.INVALID_INVENTORY_STATE)
	if player.content_schema_version() != registry.schema_version() or player.content_version() != registry.content_version() or inventory.content_schema_version() != registry.schema_version() or inventory.content_version() != registry.content_version():
		return _failure(Reason.CONTENT_VERSION_MISMATCH)
	if not PermanentGrowthClaimKernelScript.derive_snapshot(player, registry).succeeded():
		return _failure(Reason.INVALID_PLAYER_STATE)
	if not PortableInventoryResolverScript.resolve(inventory, registry).succeeded():
		return _failure(Reason.INVALID_INVENTORY_STATE)
	var definition := query.definition()
	if not StaticMapDefinitionScript.has_exact_entry_types(definition) or not definition.source_declarations_are_valid() or not (definition.terrain_effect_ids_snapshot().is_empty() and definition.dynamic_behavior_ids_snapshot().is_empty() and definition.other_entity_ids_snapshot().is_empty()):
		return _failure(Reason.INVALID_MAP_DEFINITION)
	var records: Array[EnemyWorldRecordScript] = []
	var addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	var positions: Dictionary[StringName, Vector3i] = {PLAYER_ID: definition.player_spawn_cell}
	for placement: MapEnemyPlacementScript in definition.enemies:
		var initial := EnemyInstanceResolverScript.create_initial(placement.instance_id, placement.profile_id, registry)
		if not initial.succeeded():
			return _failure(Reason.INVALID_MAP_DEFINITION)
		var enemy := initial.snapshot()
		if not WorldStepStaticScenarioScript.has_no_pending_enemy_effects(enemy.behavior_id(), enemy.has_alternate_state(), enemy.combat_trait_ids()):
			return _failure(Reason.INVALID_MAP_DEFINITION)
		records.append(EnemyWorldRecordScript.create(initial.instance_state(), EnemyWorldRecordScript.Lifecycle.ACTIVE))
		addresses[placement.instance_id] = EnemyWorldAddressScript.create(definition.space_id, placement.cell)
		positions[placement.instance_id] = placement.cell
	var grid := GridRuleStateScript.create(definition.grid_cells, definition.blocked_cells, positions, 0)
	var enemies := EnemyWorldStateScript.create(records, addresses, 0)
	if not grid.is_valid() or not EnemyWorldResolverScript.resolve(enemies, registry).succeeded():
		return _failure(Reason.INITIAL_STATE_REJECTED)
	# 定义的全部非敌人来源为空，且每个敌人均已证明静态，才发布完整空来源清单。
	var stages := WorldStepStageInputsScript.create([], [], [], [], [], true)
	var world := WorldStepStateScript.create(definition.space_id, grid, player, enemies, inventory, stages)
	if not world.is_valid():
		return _failure(Reason.INITIAL_STATE_REJECTED)
	var result := StaticMapInitializationResultScript.new()
	result._world_state = world.copy()
	result._integrity_world_state = world.copy()
	result._failure_reason = Reason.NONE
	return result


static func _failure(reason: int) -> StaticMapInitializationResultScript:
	var result := StaticMapInitializationResultScript.new()
	result._failure_reason = reason
	return result
