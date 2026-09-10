class_name WorldStepTransactionKernel
extends RefCounted

const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepCommandScript := preload("res://src/rules/world_step_command.gd")
const WorldStepTransactionCandidateScript := preload("res://src/rules/world_step_transaction_candidate.gd")
const WorldStepTransactionEventScript := preload("res://src/rules/world_step_transaction_event.gd")
const WorldStepTransactionResultScript := preload("res://src/rules/world_step_transaction_result.gd")
const WorldStepContactKernelScript := preload("res://src/rules/world_step_contact_kernel.gd")
const WorldStepContactCommandScript := preload("res://src/rules/world_step_contact_command.gd")
const WorldStepContactLockScript := preload("res://src/rules/world_step_contact_lock.gd")
const ContactCombatTransactionKernelScript := preload("res://src/rules/contact_combat_transaction_kernel.gd")
const ContactCombatTransactionResultScript := preload("res://src/rules/contact_combat_transaction_result.gd")
const ContactCombatTransactionCommandScript := preload("res://src/rules/contact_combat_transaction_command.gd")
const ContactCombatTransactionCandidateScript := preload("res://src/rules/contact_combat_transaction_candidate.gd")
const ContactCombatCommandScript := preload("res://src/rules/contact_combat_command.gd")
const GridRuleKernelScript := preload("res://src/rules/grid_rule_kernel.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const GridRuleCommandScript := preload("res://src/rules/grid_rule_command.gd")
const EnemyWorldResolverScript := preload("res://src/rules/enemy_world_resolver.gd")
const EnemyWorldStateScript := preload("res://src/rules/enemy_world_state.gd")
const EnemyWorldRecordScript := preload("res://src/rules/enemy_world_record.gd")
const EnemyWorldAddressScript := preload("res://src/rules/enemy_world_address.gd")
const EnemyInstanceResolverScript := preload("res://src/rules/enemy_instance_resolver.gd")
const PermanentGrowthClaimKernelScript := preload("res://src/rules/permanent_growth_claim_kernel.gd")
const PortableInventoryResolverScript := preload("res://src/rules/portable_inventory_resolver.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyProfileDefinitionScript := preload("res://src/content/definitions/enemy_profile_definition_resource.gd")

const PLAYER_ID: StringName = WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
const Reason = WorldStepTransactionResultScript.RejectionReason


static func prepare(
	state_candidate: RefCounted,
	command_candidate: RefCounted,
	registry: RefCounted,
) -> WorldStepTransactionResultScript:
	return _run(state_candidate, command_candidate, registry, false)


static func commit(
	current_state_candidate: RefCounted,
	prepared_result_candidate: RefCounted,
	registry: RefCounted,
) -> WorldStepTransactionResultScript:
	return _run(current_state_candidate, prepared_result_candidate, registry, true)


# 同步作用域只持有注册表副本；发布前同时复验副本与来源封印。
static func _run(
	state_candidate: RefCounted,
	input_candidate: RefCounted,
	registry: RefCounted,
	is_commit: bool,
) -> WorldStepTransactionResultScript:
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(Reason.INVALID_REGISTRY)
	var scope := (registry as ContentRegistryScript)._begin_verified_read_scope()
	if scope == null:
		return _rejected(Reason.INVALID_REGISTRY)
	var result: WorldStepTransactionResultScript
	if is_commit:
		result = _commit(state_candidate, input_candidate, scope._registry)
	else:
		result = _prepare(state_candidate, input_candidate, scope._registry)
	var captured_content_valid: bool = scope._close()
	if not captured_content_valid or not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(Reason.INVALID_REGISTRY)
	return result


static func _prepare(
	state_candidate: RefCounted,
	command_candidate: RefCounted,
	registry: ContentRegistryScript,
) -> WorldStepTransactionResultScript:
	if not _is_exact_state(state_candidate):
		return _rejected(Reason.INVALID_STATE)
	var state: WorldStepStateScript = (state_candidate as WorldStepStateScript).copy()
	var rejection: int = _validate_world(state, registry, true)
	if rejection != Reason.NONE:
		return _rejected(rejection)
	if command_candidate == null or command_candidate.get_script() != WorldStepCommandScript:
		return _rejected(Reason.INVALID_COMMAND)
	var command: WorldStepCommandScript = (command_candidate as WorldStepCommandScript).copy()
	if not command.is_valid():
		return _rejected(Reason.INVALID_COMMAND)
	var grid := state.grid_state()
	if command.expected_world_step() != grid.world_step() or command.expected_from_cell() != grid.actor_position(PLAYER_ID):
		return _rejected(Reason.STALE_COMMAND)
	if grid.world_step() >= ValidationSupportScript.MAX_WORLD_STEP:
		return _rejected(Reason.WORLD_STEP_LIMIT)
	var candidate := WorldStepTransactionCandidateScript.new()
	candidate._previous_state = state.copy()
	candidate._command = command.copy()
	if command.kind() == WorldStepCommandScript.Kind.MOVE:
		var contact := WorldStepContactKernelScript.prepare(
			grid, state.player_state(), state.enemy_world_state(),
			WorldStepContactCommandScript.attempt_entry(
				state.space_id(), PLAYER_ID, command.expected_from_cell(),
				command.direction(), command.expected_world_step(),
			), registry,
		)
		if contact.was_rejected():
			return _rejected(Reason.CONTACT_REJECTED)
		if contact.is_locked():
			candidate._contact_lock = contact.contact_lock()
			var lock := candidate._contact_lock
			var combat := ContactCombatTransactionKernelScript.prepare(
				state.player_state(), state.enemy_world_state(), state.inventory_state(),
				ContactCombatTransactionCommandScript.resolve_contact(
					lock.target_enemy_instance_id(), lock.target_enemy_address(), [], lock.initiator_side(),
				), registry,
			)
			if combat.is_blocked():
				var blocked := WorldStepTransactionResultScript.new()
				blocked._status = WorldStepTransactionResultScript.Status.BLOCKED
				blocked._rejection_reason = Reason.NONE
				blocked._capture_integrity()
				return blocked
			if not combat.is_prepared():
				return _rejected(Reason.COMBAT_REJECTED)
			candidate._combat_candidate = combat.candidate()
			if not validate_contact_binding(state, command, lock, candidate._combat_candidate):
				return _rejected(Reason.CONTACT_BINDING_MISMATCH)
		else:
			# 复用旧格网完整移动验证。它的 +1 结果仅供验证，既不保存也不发布；
			# 组合事务始终保留原步数，唯一推进点位于 _commit() 的发布构造。
			var movement := GridRuleKernelScript.execute(grid, GridRuleCommandScript.move(PLAYER_ID, command.direction()))
			if movement.next_state().actor_position(PLAYER_ID) != command.expected_from_cell() + command.direction():
				return _rejected(Reason.MOVEMENT_REJECTED)
	candidate._initialized = true
	candidate._capture_integrity()
	var result := WorldStepTransactionResultScript.new()
	result._status = WorldStepTransactionResultScript.Status.PREPARED
	result._rejection_reason = Reason.NONE
	result._candidate = candidate.copy()
	result._capture_integrity()
	return result if result.is_prepared() else _rejected(Reason.INVALID_CANDIDATE)


static func _commit(
	state_candidate: RefCounted,
	prepared_candidate: RefCounted,
	registry: ContentRegistryScript,
) -> WorldStepTransactionResultScript:
	if prepared_candidate == null or prepared_candidate.get_script() != WorldStepTransactionResultScript:
		return _rejected(Reason.INVALID_CANDIDATE)
	var prepared: WorldStepTransactionResultScript = prepared_candidate as WorldStepTransactionResultScript
	if not prepared.is_prepared():
		return _rejected(Reason.INVALID_CANDIDATE)
	if not _is_exact_state(state_candidate):
		return _rejected(Reason.INVALID_STATE)
	var current: WorldStepStateScript = (state_candidate as WorldStepStateScript).copy()
	var candidate := prepared.candidate()
	if not current.is_equal_to(candidate.previous_state()):
		return _rejected(Reason.PRESTATE_MISMATCH)
	var rejection: int = _validate_world(current, registry, true)
	if rejection != Reason.NONE:
		return _rejected(rejection)
	var command := candidate.command()
	var grid := current.grid_state()
	if command.expected_world_step() != grid.world_step() or command.expected_from_cell() != grid.actor_position(PLAYER_ID):
		return _rejected(Reason.STALE_COMMAND)
	if grid.world_step() >= ValidationSupportScript.MAX_WORLD_STEP:
		return _rejected(Reason.WORLD_STEP_LIMIT)
	var next_player := current.player_state()
	var next_enemies := current.enemy_world_state()
	var next_inventory := current.inventory_state()
	var next_positions := grid.actor_positions()
	var event := WorldStepTransactionEventScript.new()
	if candidate.contact_lock() != null:
		var lock := candidate.contact_lock()
		if not validate_contact_binding(current, command, lock, candidate.combat_candidate()):
			return _rejected(Reason.CONTACT_BINDING_MISMATCH)
		var contact := WorldStepContactKernelScript.revalidate(
			WorldStepContactKernelScript._locked(lock), grid, next_player, next_enemies, registry,
		)
		# v1 已证明阶段2—6无效果，故没有周期失活取消路径；外部失活属于陈旧前态。
		# 完整阶段执行器未来须保留 CANCELLED 的阶段结果，不能把它并入 REJECTED。
		if not contact.is_locked():
			return _rejected(Reason.CONTACT_REJECTED)
		var combat_prepared := ContactCombatTransactionResultScript.new()
		combat_prepared._status = ContactCombatTransactionResultScript.Status.PREPARED
		combat_prepared._rejection_reason = ContactCombatTransactionResultScript.RejectionReason.NONE
		combat_prepared._candidate = candidate.combat_candidate()
		combat_prepared._registry_validation_passed = true
		combat_prepared._capture_integrity()
		var combat := ContactCombatTransactionKernelScript.commit(
			next_player, next_enemies, next_inventory, combat_prepared, registry,
		)
		if not combat.was_committed():
			return _rejected(Reason.COMBAT_REJECTED)
		next_player = combat.player_state()
		next_enemies = combat.enemy_world_state()
		next_inventory = combat.inventory_state()
		event._combat_event = combat.domain_events()[0]
		# 战后保持玩家原格，仅释放已解除敌人的占格。
		if combat.resolution().next_opponent_durability() == 0:
			next_positions.erase(lock.target_enemy_instance_id())
	else:
		if command.kind() == WorldStepCommandScript.Kind.MOVE:
			var movement := GridRuleKernelScript.execute(grid, GridRuleCommandScript.move(PLAYER_ID, command.direction()))
			if movement.next_state().actor_position(PLAYER_ID) != command.expected_from_cell() + command.direction():
				return _rejected(Reason.MOVEMENT_REJECTED)
		next_positions[PLAYER_ID] = command.expected_from_cell() + command.direction()
	var next_step: int = grid.world_step() + 1
	var next_grid := GridRuleStateScript.create(grid.grid_cells(), grid.blocked_cells(), next_positions, next_step)
	var enemy_resolution := EnemyWorldResolverScript.resolve(next_enemies, registry)
	next_enemies = EnemyWorldStateScript.create(enemy_resolution.record_snapshots(), enemy_resolution.address_snapshots(), next_step)
	var next_state := WorldStepStateScript.create(current.space_id(), next_grid, next_player, next_enemies, next_inventory, current.stage_inputs())
	if _validate_world(next_state, registry, false) != Reason.NONE:
		return _rejected(Reason.NEXT_STATE_REJECTED)
	event._command = command.copy()
	event._player_cell_after = next_grid.actor_position(PLAYER_ID)
	event._world_step_after = next_step
	event._initialized = true
	event._capture_integrity()
	var result := WorldStepTransactionResultScript.new()
	result._status = WorldStepTransactionResultScript.Status.COMMITTED
	result._rejection_reason = Reason.NONE
	result._candidate = candidate.copy()
	result._next_state = next_state.copy()
	result._event = event.copy()
	result._capture_integrity()
	return result if result.was_committed() else _rejected(Reason.NEXT_STATE_REJECTED)


# 独立可验的两层衔接：不接受仅有合法战斗候选、但与实际移动锁定无关的提交。
static func validate_contact_binding(
	state: WorldStepStateScript,
	command: WorldStepCommandScript,
	lock: WorldStepContactLockScript,
	combat: ContactCombatTransactionCandidateScript,
) -> bool:
	if not (_is_exact_state(state) and state.is_valid()):
		return false
	if command == null or command.get_script() != WorldStepCommandScript or not command.is_valid():
		return false
	if lock == null or lock.get_script() != WorldStepContactLockScript or not lock.is_valid():
		return false
	if combat == null or combat.get_script() != ContactCombatTransactionCandidateScript or not combat.is_valid():
		return false
	var combat_command := combat.command()
	var grid := state.grid_state()
	return (
		command.kind() == WorldStepCommandScript.Kind.MOVE
		and lock.moving_actor_id() == PLAYER_ID and lock.player_actor_id() == PLAYER_ID
		and lock.initiator_side() == ContactCombatCommandScript.Side.PLAYER
		and lock.space_id() == state.space_id()
		and lock.world_step() == command.expected_world_step()
		and lock.world_step() == grid.world_step()
		and lock.world_step() == combat.previous_enemy_world_state().world_step()
		and grid.has_actor(PLAYER_ID) and grid.has_actor(lock.target_enemy_instance_id())
		and lock.player_cell() == command.expected_from_cell()
		and lock.player_cell() == grid.actor_position(PLAYER_ID)
		and not ValidationSupportScript.would_overflow_target(command.expected_from_cell(), command.direction())
		and lock.attempted_destination_cell() == command.expected_from_cell() + command.direction()
		and lock.target_enemy_cell() == grid.actor_position(lock.target_enemy_instance_id())
		and combat_command.target_instance_id() == lock.target_enemy_instance_id()
		and combat_command.contact_address().is_equal_to(lock.target_enemy_address())
		and combat_command.initiator_side() == lock.initiator_side()
		and combat_command.supporting_instance_ids().is_empty()
		and combat.previous_player_state().is_equal_to(state.player_state())
		and combat.previous_enemy_world_state().is_equal_to(state.enemy_world_state())
		and combat.previous_inventory_state().is_equal_to(state.inventory_state())
	)


static func _validate_world(state: WorldStepStateScript, registry: ContentRegistryScript, require_active_player: bool) -> int:
	if not state.is_valid() or not EnemyWorldAddressScript.is_valid_space_id(state.space_id()):
		return Reason.INVALID_STATE
	var grid := state.grid_state()
	if not PermanentGrowthClaimKernelScript.derive_snapshot(state.player_state(), registry).succeeded():
		return Reason.INVALID_STATE
	if require_active_player and state.player_state().current_health() == 0:
		return Reason.INVALID_STATE
	var world := EnemyWorldResolverScript.resolve(state.enemy_world_state(), registry)
	if not world.succeeded() or not PortableInventoryResolverScript.resolve(state.inventory_state(), registry).succeeded():
		return Reason.INVALID_STATE
	if grid.world_step() != world.snapshot().world_step() or not grid.has_actor(PLAYER_ID) or world.instance_ids().has(PLAYER_ID):
		return Reason.PROJECTION_MISMATCH
	var projection := world.project_space(state.space_id())
	if not projection.succeeded():
		return Reason.PROJECTION_MISMATCH
	var positions := projection.actor_positions()
	if grid.actor_ids().size() != positions.size() + 1:
		return Reason.PROJECTION_MISMATCH
	for actor_id: StringName in positions:
		if not grid.has_actor(actor_id) or grid.actor_position(actor_id) != positions[actor_id]:
			return Reason.PROJECTION_MISMATCH
	for cell: Vector3i in grid.grid_cells():
		if cell.y != grid.actor_position(PLAYER_ID).y:
			return Reason.UNSUPPORTED_SCENARIO
	var stages := state.stage_inputs()
	if not stages.complete() or not (stages.construct_sources().is_empty() and stages.environment_sources().is_empty() and stages.patrol_sources().is_empty() and stages.periodic_sources().is_empty() and stages.support_sources().is_empty()):
		return Reason.UNSUPPORTED_SCENARIO
	for address: EnemyWorldAddressScript in world.address_snapshots().values():
		if address.space_id() != state.space_id():
			return Reason.UNSUPPORTED_SCENARIO
	for record: EnemyWorldRecordScript in world.record_snapshots():
		if record.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
			continue
		var enemy := EnemyInstanceResolverScript.resolve(record.instance_state(), registry).snapshot()
		# 只放行中央已知静态护盾行为；未知行为或复合特性一律关闭。
		if enemy.behavior_id() != &"enemy.behavior.shield" or enemy.has_alternate_state():
			return Reason.UNSUPPORTED_SCENARIO
		for trait_id: StringName in enemy.combat_trait_ids():
			if trait_id != EnemyProfileDefinitionScript.SHIELD_TRAIT_ID:
				return Reason.UNSUPPORTED_SCENARIO
	return Reason.NONE


static func _is_exact_state(state: RefCounted) -> bool:
	return state != null and state.get_script() == WorldStepStateScript


static func _rejected(reason: int) -> WorldStepTransactionResultScript:
	var result := WorldStepTransactionResultScript.new()
	result._rejection_reason = reason
	result._capture_integrity()
	return result
