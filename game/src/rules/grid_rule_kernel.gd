class_name GridRuleKernel
extends RefCounted

const GridRuleCommandScript := preload("res://src/rules/grid_rule_command.gd")
const GridRuleEventScript := preload("res://src/rules/grid_rule_event.gd")
const GridRuleResultScript := preload("res://src/rules/grid_rule_result.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")


static func execute(
	state: GridRuleStateScript, command: GridRuleCommandScript
) -> GridRuleResultScript:
	if state == null or state.get_script() != GridRuleStateScript:
		var invalid_state: GridRuleStateScript = GridRuleStateScript.new()
		return _rejected(
			invalid_state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)

	var authoritative_state: GridRuleStateScript = state.copy()
	if not authoritative_state.is_valid():
		return _rejected(
			authoritative_state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)
	if command == null or command.get_script() != GridRuleCommandScript:
		return _rejected(
			authoritative_state,
			&"",
			Vector3i.ZERO,
			Vector3i.ZERO,
			GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		)

	var command_kind: int = command.kind()
	if command_kind != GridRuleCommandScript.Kind.MOVE:
		var unknown_actor_id: StringName = command.actor_id()
		var unknown_from_cell := Vector3i.ZERO
		if authoritative_state.has_actor(unknown_actor_id):
			unknown_from_cell = authoritative_state.actor_position(unknown_actor_id)
		return _rejected(
			authoritative_state,
			unknown_actor_id,
			unknown_from_cell,
			unknown_from_cell,
			GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		)

	var actor_id: StringName = command.actor_id()
	var from_cell := Vector3i.ZERO
	if authoritative_state.has_actor(actor_id):
		from_cell = authoritative_state.actor_position(actor_id)
	var direction: Vector3i = command.direction()
	if not ValidationSupportScript.is_horizontal_unit_direction(direction):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.INVALID_DIRECTION,
		)
	if not authoritative_state.has_actor(actor_id):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.UNKNOWN_ACTOR,
		)
	if authoritative_state.world_step() >= ValidationSupportScript.MAX_WORLD_STEP:
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.WORLD_STEP_LIMIT,
		)
	if ValidationSupportScript.would_overflow_target(from_cell, direction):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			from_cell,
			GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		)

	var to_cell: Vector3i = from_cell + direction
	if not authoritative_state.is_grid_cell(to_cell):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		)
	if authoritative_state.is_blocked_cell(to_cell):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.BLOCKED,
		)
	if authoritative_state.is_occupied_cell(to_cell, actor_id):
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.OCCUPIED,
		)

	var next_actor_positions: Dictionary[StringName, Vector3i] = (
		authoritative_state.actor_positions()
	)
	next_actor_positions[actor_id] = to_cell
	var next_state: GridRuleStateScript = GridRuleStateScript.create(
		authoritative_state.grid_cells(),
		authoritative_state.blocked_cells(),
		next_actor_positions,
		authoritative_state.world_step() + 1,
	)
	if not next_state.is_valid():
		return _rejected(
			authoritative_state,
			actor_id,
			from_cell,
			to_cell,
			GridRuleEventScript.RejectionReason.INVALID_STATE,
		)
	var domain_events: Array[GridRuleEventScript] = []
	domain_events.append(GridRuleEventScript.actor_moved(actor_id, from_cell, to_cell))
	return GridRuleResultScript.new(next_state, domain_events)


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
