class_name WorldStepContactKernel
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyGridProjectionResultScript := preload(
	"res://src/rules/enemy_grid_projection_result.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldQueryResultScript := preload(
	"res://src/rules/enemy_world_query_result.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldResolutionResultScript := preload(
	"res://src/rules/enemy_world_resolution_result.gd"
)
const EnemyWorldResolverScript := preload(
	"res://src/rules/enemy_world_resolver.gd"
)
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const PermanentGrowthClaimKernelScript := preload(
	"res://src/rules/permanent_growth_claim_kernel.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const WorldStepContactCommandScript := preload(
	"res://src/rules/world_step_contact_command.gd"
)
const WorldStepContactLockScript := preload(
	"res://src/rules/world_step_contact_lock.gd"
)
const WorldStepContactResultScript := preload(
	"res://src/rules/world_step_contact_result.gd"
)


static func prepare(
	grid_state_candidate: RefCounted,
	player_state_candidate: RefCounted,
	enemy_world_state_candidate: RefCounted,
	command_candidate: RefCounted,
	registry: RefCounted,
) -> WorldStepContactResultScript:
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_REGISTRY)
	if not _is_exact_grid_state(grid_state_candidate):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_GRID_STATE)
	var grid_state: GridRuleStateScript = (
		grid_state_candidate as GridRuleStateScript
	).copy()
	if not grid_state.is_valid():
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_GRID_STATE)
	if not _is_exact_player_state(player_state_candidate):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_PLAYER_STATE
		)
	var player_state: PlayerProgressionStateScript = (
		player_state_candidate as PlayerProgressionStateScript
	).copy()
	if (
		not player_state.is_valid()
		or not PermanentGrowthClaimKernelScript.derive_snapshot(
			player_state,
			registry,
		).succeeded()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_PLAYER_STATE
		)
	if player_state.current_health() == 0:
		return _rejected(WorldStepContactResultScript.RejectionReason.PLAYER_INACTIVE)

	var world_resolution: EnemyWorldResolutionResultScript = (
		EnemyWorldResolverScript.resolve(enemy_world_state_candidate, registry)
	)
	if not world_resolution.succeeded():
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.ENEMY_WORLD_STATE_REJECTED
		)
	if not _is_exact_command(command_candidate):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_COMMAND)
	var command: WorldStepContactCommandScript = (
		command_candidate as WorldStepContactCommandScript
	).copy()
	if not command.is_valid():
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_COMMAND)
	if (
		grid_state.world_step() != command.expected_world_step()
		or world_resolution.snapshot().world_step()
		!= command.expected_world_step()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.WORLD_STEP_MISMATCH
		)
	if world_resolution.instance_ids().has(
		WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
	):
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.PLAYER_IDENTITY_CONFLICT
		)
	if not grid_state.has_actor(
		WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.PLAYER_ACTOR_MISSING
		)
	if not _grid_matches_enemy_projection(
		grid_state,
		world_resolution,
		command.space_id(),
	):
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.ENEMY_GRID_PROJECTION_MISMATCH
		)
	if not grid_state.has_actor(command.moving_actor_id()):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.MOVING_ACTOR_MISSING
		)
	if (
		grid_state.actor_position(command.moving_actor_id())
		!= command.expected_from_cell()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.FROM_CELL_MISMATCH
		)
	if ValidationSupportScript.would_overflow_target(
		command.expected_from_cell(), command.direction()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.COORDINATE_OVERFLOW
		)
	var attempted_destination: Vector3i = (
		command.expected_from_cell() + command.direction()
	)
	if not grid_state.is_grid_cell(attempted_destination):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.TARGET_OUT_OF_BOUNDS
		)
	if grid_state.is_blocked_cell(attempted_destination):
		return _rejected(WorldStepContactResultScript.RejectionReason.TARGET_BLOCKED)

	var occupying_actor_id: StringName = _actor_at_cell(
		grid_state,
		attempted_destination,
	)
	if String(occupying_actor_id).is_empty():
		return _no_contact()
	var enemy_positions: Dictionary[StringName, Vector3i] = (
		world_resolution.project_space(command.space_id()).actor_positions()
	)
	var target_enemy_instance_id: StringName = &""
	var initiator_side: int = 0
	if (
		command.moving_actor_id()
		== WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
		and enemy_positions.has(occupying_actor_id)
	):
		target_enemy_instance_id = occupying_actor_id
		initiator_side = ContactCombatCommandScript.Side.PLAYER
	elif (
		enemy_positions.has(command.moving_actor_id())
		and occupying_actor_id
		== WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
	):
		target_enemy_instance_id = command.moving_actor_id()
		initiator_side = ContactCombatCommandScript.Side.OPPONENT
	else:
		return _no_contact()

	var target_query: EnemyWorldQueryResultScript = world_resolution.lookup_enemy(
		target_enemy_instance_id
	)
	if (
		not target_query.succeeded()
		or target_query.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE
		or not target_query.has_world_address()
		or target_query.world_address().space_id() != command.space_id()
	):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	var contact_lock: WorldStepContactLockScript = _build_contact_lock(
		grid_state,
		command,
		target_enemy_instance_id,
		initiator_side,
		attempted_destination,
	)
	if (
		not contact_lock.is_valid()
		or not contact_lock.target_enemy_address().is_equal_to(
			target_query.world_address()
		)
	):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	return _locked(contact_lock)


static func revalidate(
	locked_result_candidate: RefCounted,
	current_grid_state_candidate: RefCounted,
	current_player_state_candidate: RefCounted,
	current_enemy_world_state_candidate: RefCounted,
	registry: RefCounted,
) -> WorldStepContactResultScript:
	if (
		locked_result_candidate == null
		or not is_instance_valid(locked_result_candidate)
		or locked_result_candidate.get_script() != WorldStepContactResultScript
		or not (
			locked_result_candidate as WorldStepContactResultScript
		).is_locked()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_LOCKED_RESULT
		)
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_REGISTRY)
	if not _is_exact_grid_state(current_grid_state_candidate):
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_GRID_STATE)
	var current_grid_state: GridRuleStateScript = (
		current_grid_state_candidate as GridRuleStateScript
	).copy()
	if not current_grid_state.is_valid():
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_GRID_STATE)
	if not _is_exact_player_state(current_player_state_candidate):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_PLAYER_STATE
		)
	var current_player_state: PlayerProgressionStateScript = (
		current_player_state_candidate as PlayerProgressionStateScript
	).copy()
	if (
		not current_player_state.is_valid()
		or not PermanentGrowthClaimKernelScript.derive_snapshot(
			current_player_state,
			registry,
		).succeeded()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_PLAYER_STATE
		)
	var current_world_resolution: EnemyWorldResolutionResultScript = (
		EnemyWorldResolverScript.resolve(
			current_enemy_world_state_candidate,
			registry,
		)
	)
	if not current_world_resolution.succeeded():
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.ENEMY_WORLD_STATE_REJECTED
		)

	var locked_result: WorldStepContactResultScript = (
		locked_result_candidate as WorldStepContactResultScript
	)
	var contact_lock: WorldStepContactLockScript = locked_result.contact_lock()
	if contact_lock == null or not contact_lock.is_valid():
		return _rejected(
			WorldStepContactResultScript.RejectionReason.INVALID_LOCKED_RESULT
		)
	if (
		current_grid_state.world_step() != contact_lock.world_step()
		or current_world_resolution.snapshot().world_step()
		!= contact_lock.world_step()
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.WORLD_STEP_MISMATCH
		)
	if current_world_resolution.instance_ids().has(contact_lock.player_actor_id()):
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.PLAYER_IDENTITY_CONFLICT
		)
	if not _grid_matches_enemy_projection(
		current_grid_state,
		current_world_resolution,
		contact_lock.space_id(),
	):
		return _rejected(
			WorldStepContactResultScript
			.RejectionReason
			.ENEMY_GRID_PROJECTION_MISMATCH
		)
	var target_query: EnemyWorldQueryResultScript = (
		current_world_resolution.lookup_enemy(
			contact_lock.target_enemy_instance_id()
		)
	)
	if not target_query.succeeded():
		return _rejected(
			WorldStepContactResultScript.RejectionReason.CONTACT_PRESTATE_MISMATCH
		)
	if current_player_state.current_health() == 0:
		return _cancelled(
			contact_lock,
			WorldStepContactResultScript.CancellationReason.PLAYER_INACTIVE,
		)
	if target_query.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
		return _cancelled(
			contact_lock,
			WorldStepContactResultScript.CancellationReason.ENEMY_INACTIVE,
		)
	if (
		not current_grid_state.has_actor(contact_lock.player_actor_id())
		or current_grid_state.actor_position(contact_lock.player_actor_id())
		!= contact_lock.player_cell()
		or not current_grid_state.has_actor(
			contact_lock.target_enemy_instance_id()
		)
		or current_grid_state.actor_position(
			contact_lock.target_enemy_instance_id()
		) != contact_lock.target_enemy_cell()
		or not target_query.has_world_address()
		or not target_query.world_address().is_equal_to(
			contact_lock.target_enemy_address()
		)
	):
		return _rejected(
			WorldStepContactResultScript.RejectionReason.CONTACT_PRESTATE_MISMATCH
		)
	return _locked(contact_lock)


static func _build_contact_lock(
	grid_state: GridRuleStateScript,
	command: WorldStepContactCommandScript,
	target_enemy_instance_id: StringName,
	initiator_side: int,
	attempted_destination: Vector3i,
) -> WorldStepContactLockScript:
	var contact_lock := WorldStepContactLockScript.new()
	contact_lock._space_id = command.space_id()
	contact_lock._integrity_space_id = contact_lock._space_id
	contact_lock._world_step = command.expected_world_step()
	contact_lock._integrity_world_step = contact_lock._world_step
	contact_lock._player_actor_id = (
		WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
	)
	contact_lock._integrity_player_actor_id = contact_lock._player_actor_id
	contact_lock._target_enemy_instance_id = target_enemy_instance_id
	contact_lock._integrity_target_enemy_instance_id = (
		contact_lock._target_enemy_instance_id
	)
	contact_lock._player_cell = grid_state.actor_position(
		contact_lock._player_actor_id
	)
	contact_lock._integrity_player_cell = contact_lock._player_cell
	contact_lock._target_enemy_cell = grid_state.actor_position(
		target_enemy_instance_id
	)
	contact_lock._integrity_target_enemy_cell = contact_lock._target_enemy_cell
	contact_lock._moving_actor_id = command.moving_actor_id()
	contact_lock._integrity_moving_actor_id = contact_lock._moving_actor_id
	contact_lock._attempted_destination_cell = attempted_destination
	contact_lock._integrity_attempted_destination_cell = (
		contact_lock._attempted_destination_cell
	)
	contact_lock._initiator_side = initiator_side
	contact_lock._integrity_initiator_side = contact_lock._initiator_side
	contact_lock._initialized = true
	contact_lock._integrity_initialized = true
	return contact_lock


static func _grid_matches_enemy_projection(
	grid_state: GridRuleStateScript,
	world_resolution: EnemyWorldResolutionResultScript,
	space_id: StringName,
) -> bool:
	var projection: EnemyGridProjectionResultScript = world_resolution.project_space(
		space_id
	)
	if (
		not projection.succeeded()
		or projection.world_step() != grid_state.world_step()
	):
		return false
	var projected_positions: Dictionary[StringName, Vector3i] = (
		projection.actor_positions()
	)
	for instance_id: StringName in world_resolution.instance_ids():
		var grid_has_actor: bool = grid_state.has_actor(instance_id)
		var projection_has_actor: bool = projected_positions.has(instance_id)
		if grid_has_actor != projection_has_actor:
			return false
		if (
			grid_has_actor
			and grid_state.actor_position(instance_id)
			!= projected_positions[instance_id]
		):
			return false
	return true


static func _actor_at_cell(
	grid_state: GridRuleStateScript,
	cell: Vector3i,
) -> StringName:
	for actor_id: StringName in grid_state.actor_ids():
		if grid_state.actor_position(actor_id) == cell:
			return actor_id
	return &""


static func _no_contact() -> WorldStepContactResultScript:
	var result := WorldStepContactResultScript.new()
	result._status = WorldStepContactResultScript.Status.NO_CONTACT
	result._integrity_status = result._status
	result._cancellation_reason = (
		WorldStepContactResultScript.CancellationReason.NONE
	)
	result._integrity_cancellation_reason = result._cancellation_reason
	result._rejection_reason = WorldStepContactResultScript.RejectionReason.NONE
	result._integrity_rejection_reason = result._rejection_reason
	result._registry_validation_passed = true
	result._integrity_registry_validation_passed = true
	return (
		result
		if result.has_no_contact()
		else _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	)


static func _locked(
	contact_lock: WorldStepContactLockScript,
) -> WorldStepContactResultScript:
	if contact_lock == null or not contact_lock.is_valid():
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	var result := WorldStepContactResultScript.new()
	result._status = WorldStepContactResultScript.Status.LOCKED
	result._integrity_status = result._status
	result._cancellation_reason = (
		WorldStepContactResultScript.CancellationReason.NONE
	)
	result._integrity_cancellation_reason = result._cancellation_reason
	result._rejection_reason = WorldStepContactResultScript.RejectionReason.NONE
	result._integrity_rejection_reason = result._rejection_reason
	result._contact_lock = contact_lock.copy()
	result._integrity_contact_lock = result._contact_lock.copy()
	result._registry_validation_passed = true
	result._integrity_registry_validation_passed = true
	return (
		result
		if result.is_locked()
		else _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	)


static func _cancelled(
	contact_lock: WorldStepContactLockScript,
	cancellation_reason: int,
) -> WorldStepContactResultScript:
	if contact_lock == null or not contact_lock.is_valid():
		return _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	var result := WorldStepContactResultScript.new()
	result._status = WorldStepContactResultScript.Status.CANCELLED
	result._integrity_status = result._status
	result._cancellation_reason = cancellation_reason
	result._integrity_cancellation_reason = result._cancellation_reason
	result._rejection_reason = WorldStepContactResultScript.RejectionReason.NONE
	result._integrity_rejection_reason = result._rejection_reason
	result._contact_lock = contact_lock.copy()
	result._integrity_contact_lock = result._contact_lock.copy()
	result._registry_validation_passed = true
	result._integrity_registry_validation_passed = true
	return (
		result
		if result.was_cancelled()
		else _rejected(WorldStepContactResultScript.RejectionReason.INVALID_RESULT)
	)


static func _rejected(rejection_reason: int) -> WorldStepContactResultScript:
	return WorldStepContactResultScript.rejected(rejection_reason)


static func _is_exact_grid_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == GridRuleStateScript
	)


static func _is_exact_player_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PlayerProgressionStateScript
	)


static func _is_exact_command(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == WorldStepContactCommandScript
	)


