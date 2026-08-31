class_name GridRuleKernel
extends RefCounted

const GridRuleCommandScript := preload("res://src/rules/grid_rule_command.gd")
const GridRuleEventScript := preload("res://src/rules/grid_rule_event.gd")
const GridRuleResultScript := preload("res://src/rules/grid_rule_result.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const VECTOR3I_COMPONENT_MIN := -2_147_483_648
const VECTOR3I_COMPONENT_MAX := 2_147_483_647


static func execute(
	state: GridRuleStateScript, command: GridRuleCommandScript
) -> GridRuleResultScript:
	if state == null:
		var invalid_state: GridRuleStateScript = GridRuleStateScript.new()
		return _rejected(
			invalid_state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)
	if not state.is_valid():
		return _rejected(
			state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)
	if command == null:
		return _rejected(
			state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		)

	var command_kind: int = command.kind()
	var actor_id: StringName = command.actor_id()
	var direction: Vector3i = command.direction()
	var from_cell := Vector3i.ZERO
	if state.has_actor(actor_id):
		from_cell = state.actor_position(actor_id)

	if command_kind != GridRuleCommandScript.Kind.MOVE:
		return _rejected(
			state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		)
	if not _is_horizontal_unit_direction(direction):
		return _rejected(
			state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.INVALID_DIRECTION,
		)
	if not state.has_actor(actor_id):
		return _rejected(
			state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.UNKNOWN_ACTOR,
		)
	if state.world_step() >= GridRuleStateScript.MAX_WORLD_STEP:
		return _rejected(
			state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.WORLD_STEP_LIMIT,
		)
	if _would_overflow_target(from_cell, direction):
		return _rejected(
			state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		)

	var to_cell: Vector3i = from_cell + direction
	if not state.is_grid_cell(to_cell):
		return _rejected(
			state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		)
	if state.is_blocked_cell(to_cell):
		return _rejected(
			state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.BLOCKED,
		)
	if state.is_occupied_cell(to_cell, actor_id):
		return _rejected(
			state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.OCCUPIED,
		)

	var next_state: GridRuleStateScript = state.copy_with_actor_position(actor_id, to_cell)
	if not next_state.is_valid():
		return _rejected(
			state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)
	var domain_events: Array[GridRuleEventScript] = []
	domain_events.append(GridRuleEventScript.actor_moved(actor_id, from_cell, to_cell))
	return GridRuleResultScript.new(next_state, domain_events)


static func _is_horizontal_unit_direction(direction: Vector3i) -> bool:
	return direction.y == 0 and absi(direction.x) + absi(direction.z) == 1


static func _would_overflow_target(from_cell: Vector3i, direction: Vector3i) -> bool:
	return (
		(direction.x > 0 and from_cell.x == VECTOR3I_COMPONENT_MAX)
		or (direction.x < 0 and from_cell.x == VECTOR3I_COMPONENT_MIN)
		or (direction.z > 0 and from_cell.z == VECTOR3I_COMPONENT_MAX)
		or (direction.z < 0 and from_cell.z == VECTOR3I_COMPONENT_MIN)
	)


static func _rejected(
	input_state: GridRuleStateScript,
	actor_id: StringName,
	from_cell: Vector3i,
	to_cell: Vector3i,
	rejection_reason: int,
) -> GridRuleResultScript:
	var next_state: GridRuleStateScript = input_state.copy()
	var domain_events: Array[GridRuleEventScript] = []
	domain_events.append(
		GridRuleEventScript.command_rejected(
			actor_id,
			from_cell,
			to_cell,
			rejection_reason,
		)
	)
	return GridRuleResultScript.new(next_state, domain_events)
