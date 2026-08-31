extends RefCounted

const GridRuleCommandScript := preload("res://src/rules/grid_rule_command.gd")
const GridRuleEventScript := preload("res://src/rules/grid_rule_event.gd")
const GridRuleKernelScript := preload("res://src/rules/grid_rule_kernel.gd")
const GridRuleResultScript := preload("res://src/rules/grid_rule_result.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")
const MinimalGridFixture := preload("res://tests/fixtures/minimal_grid_fixture.gd")
const ReplayTraceScript := preload("res://tests/support/rule_replay_trace.gd")
const StatefulGridRuleCommandScript := preload(
	"res://tests/support/stateful_grid_rule_command.gd"
)


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new("grid_kernel.initializes_fixture", _initializes_fixture),
		HeadlessTestCaseScript.new("grid_kernel.freezes_state_storage", _freezes_state_storage),
		HeadlessTestCaseScript.new("grid_kernel.rejects_invalid_state", _rejects_invalid_state),
		HeadlessTestCaseScript.new("grid_kernel.rejects_null_references", _rejects_null_references),
		HeadlessTestCaseScript.new("grid_kernel.moves_one_cell", _moves_one_cell),
		HeadlessTestCaseScript.new(
			"grid_kernel.snapshots_command_direction", _snapshots_command_direction
		),
		HeadlessTestCaseScript.new("grid_kernel.rejects_blocked_cell", _rejects_blocked_cell),
		HeadlessTestCaseScript.new("grid_kernel.rejects_out_of_bounds", _rejects_out_of_bounds),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_coordinate_overflow", _rejects_coordinate_overflow
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_world_step_overflow", _rejects_world_step_overflow
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_invalid_directions", _rejects_invalid_directions
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_unknown_command", _rejects_unknown_command
		),
		HeadlessTestCaseScript.new("grid_kernel.rejects_unknown_actor", _rejects_unknown_actor),
		HeadlessTestCaseScript.new("grid_kernel.rejects_occupied_cell", _rejects_occupied_cell),
		HeadlessTestCaseScript.new(
			"grid_kernel.replays_deterministically", _replays_deterministically
		),
		HeadlessTestCaseScript.new("grid_kernel.does_not_mutate_input", _does_not_mutate_input),
	]


func _initializes_fixture(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	context.expect_equal(state.world_step(), 0, "The fixture must start before the first world step.")
	context.expect_equal(state.actor_ids().size(), 1, "The base fixture must contain one actor.")
	context.expect_equal(
		state.actor_position(MinimalGridFixture.PRIMARY_ACTOR_ID),
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		"The primary actor must start at the declared integer cell.",
	)
	context.expect_equal(state.grid_cells().size(), 9, "The fixture must expose nine grid cells.")
	context.expect_true(
		state.is_blocked_cell(MinimalGridFixture.BLOCKED_CELL),
		"The fixture must expose its declared blocked cell.",
	)


func _freezes_state_storage(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
	)
	_expect_read_only_storage(context, GridRuleStateScript.new(), "raw")
	_expect_read_only_storage(context, state, "initial")
	_expect_read_only_storage(context, result.next_state(), "derived")


func _rejects_invalid_state(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state(
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		false,
		-1,
	)
	var before: GridRuleStateScript = state.copy()
	context.expect_true(not state.is_valid(), "A negative world step must invalidate the state.")
	context.expect_true(
		not state.validation_errors().is_empty(),
		"An invalid state must expose at least one diagnostic.",
	)
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.INVALID_STATE,
		&"",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)


func _rejects_null_references(context: HeadlessTestContextScript) -> void:
	var command: GridRuleCommandScript = GridRuleCommandScript.move(
		MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)
	)
	var null_state_result: GridRuleResultScript = GridRuleKernelScript.execute(null, command)
	context.expect_true(
		not null_state_result.next_state().is_valid(),
		"A null state must become a deterministic invalid state result.",
	)
	_expect_event(
		context,
		null_state_result,
		GridRuleEventScript.Kind.COMMAND_REJECTED,
		GridRuleEventScript.RejectionReason.INVALID_STATE,
		&"",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)

	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var null_command_result: GridRuleResultScript = GridRuleKernelScript.execute(state, null)
	_expect_rejection(
		context,
		state,
		before,
		null_command_result,
		GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		&"",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)


func _moves_one_cell(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var direction := Vector3i(-1, 0, 0)
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, direction),
	)

	context.expect_equal(
		result.next_state().actor_position(MinimalGridFixture.PRIMARY_ACTOR_ID),
		Vector3i(0, 0, 1),
		"A legal move must advance exactly one horizontal cell.",
	)
	context.expect_equal(result.next_state().world_step(), 1, "A legal move must advance the world step.")
	_expect_event(
		context,
		result,
		GridRuleEventScript.Kind.ACTOR_MOVED,
		GridRuleEventScript.RejectionReason.NONE,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		Vector3i(1, 0, 1),
		Vector3i(0, 0, 1),
	)


func _snapshots_command_direction(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var command: StatefulGridRuleCommandScript = StatefulGridRuleCommandScript.new(
		MinimalGridFixture.PRIMARY_ACTOR_ID
	)
	var result: GridRuleResultScript = GridRuleKernelScript.execute(state, command)
	context.expect_equal(
		command.direction_reads(),
		1,
		"A command direction must be snapshotted exactly once per execution.",
	)
	context.expect_equal(
		result.next_state().actor_position(MinimalGridFixture.PRIMARY_ACTOR_ID),
		Vector3i(0, 0, 1),
		"A changing command object must not bypass one-cell movement validation.",
	)
	_expect_event(
		context,
		result,
		GridRuleEventScript.Kind.ACTOR_MOVED,
		GridRuleEventScript.RejectionReason.NONE,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		Vector3i(1, 0, 1),
		Vector3i(0, 0, 1),
	)


func _rejects_blocked_cell(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.BLOCKED,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		MinimalGridFixture.BLOCKED_CELL,
	)


func _rejects_out_of_bounds(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state(Vector3i(0, 0, 1))
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		Vector3i(0, 0, 1),
		Vector3i(-1, 0, 1),
	)


func _rejects_coordinate_overflow(context: HeadlessTestContextScript) -> void:
	var maximum_cell := Vector3i(2_147_483_647, 0, 0)
	var wrapped_cell := Vector3i(-2_147_483_648, 0, 0)
	var grid_cells: Array[Vector3i] = [maximum_cell, wrapped_cell]
	var blocked_cells: Array[Vector3i] = []
	var actor_positions: Dictionary[StringName, Vector3i] = {
		MinimalGridFixture.PRIMARY_ACTOR_ID: maximum_cell,
	}
	var state: GridRuleStateScript = GridRuleStateScript.create(
		grid_cells,
		blocked_cells,
		actor_positions,
	)
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.OUT_OF_BOUNDS,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		maximum_cell,
		maximum_cell,
	)
	var domain_events: Array[GridRuleEventScript] = result.domain_events()
	if domain_events.size() == 1:
		context.expect_equal(
			domain_events[0].to_cell(),
			maximum_cell,
			"A coordinate overflow must be rejected before it can wrap to another grid cell.",
		)


func _rejects_world_step_overflow(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state(
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		false,
		GridRuleStateScript.MAX_WORLD_STEP,
	)
	var before: GridRuleStateScript = state.copy()
	context.expect_true(state.is_valid(), "The maximum representable world step remains a valid state.")
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.WORLD_STEP_LIMIT,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
	)


func _rejects_invalid_directions(context: HeadlessTestContextScript) -> void:
	var invalid_directions: Array[Vector3i] = [
		Vector3i.ZERO,
		Vector3i(1, 0, 1),
		Vector3i(0, 1, 0),
		Vector3i(2, 0, 0),
		Vector3i(2_147_483_647, 0, 0),
	]
	for direction: Vector3i in invalid_directions:
		var state: GridRuleStateScript = MinimalGridFixture.create_state()
		var before: GridRuleStateScript = state.copy()
		var result: GridRuleResultScript = GridRuleKernelScript.execute(
			state,
			GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, direction),
		)
		_expect_rejection(
			context,
			state,
			before,
			result,
			GridRuleEventScript.RejectionReason.INVALID_DIRECTION,
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			MinimalGridFixture.DEFAULT_ACTOR_POSITION,
			MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		)
		var domain_events: Array[GridRuleEventScript] = result.domain_events()
		if domain_events.size() == 1:
			context.expect_equal(
				domain_events[0].to_cell(),
				MinimalGridFixture.DEFAULT_ACTOR_POSITION,
				"An invalid direction must be rejected before target-cell arithmetic.",
			)


func _rejects_unknown_command(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var command := GridRuleCommandScript.new(
		999,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		Vector3i(-1, 0, 0),
	)
	var result: GridRuleResultScript = GridRuleKernelScript.execute(state, command)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
	)


func _rejects_unknown_actor(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(&"actor.unknown", Vector3i(-1, 0, 0)),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.UNKNOWN_ACTOR,
		&"actor.unknown",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)


func _rejects_occupied_cell(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state(
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		true,
	)
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(0, 0, -1),
		),
	)
	_expect_rejection(
		context,
		state,
		before,
		result,
		GridRuleEventScript.RejectionReason.OCCUPIED,
		MinimalGridFixture.PRIMARY_ACTOR_ID,
		MinimalGridFixture.DEFAULT_ACTOR_POSITION,
		MinimalGridFixture.SECONDARY_ACTOR_POSITION,
	)


func _replays_deterministically(context: HeadlessTestContextScript) -> void:
	var commands: Array[GridRuleCommandScript] = [
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(0, 0, -1)),
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(1, 0, 0)),
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(0, 0, 1)),
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(1, 0, 0)),
	]
	var first_trace: ReplayTraceScript = _replay(MinimalGridFixture.create_state(), commands)
	var second_trace: ReplayTraceScript = _replay(MinimalGridFixture.create_state(), commands)
	var expected_events: Array[GridRuleEventScript] = [
		GridRuleEventScript.actor_moved(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(1, 0, 1),
			Vector3i(0, 0, 1),
		),
		GridRuleEventScript.actor_moved(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(0, 0, 1),
			Vector3i(0, 0, 0),
		),
		GridRuleEventScript.actor_moved(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(0, 0, 0),
			Vector3i(1, 0, 0),
		),
		GridRuleEventScript.actor_moved(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(1, 0, 0),
			Vector3i(1, 0, 1),
		),
		GridRuleEventScript.command_rejected(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(1, 0, 1),
			Vector3i(2, 0, 1),
			GridRuleEventScript.RejectionReason.BLOCKED,
		),
	]

	context.expect_equal(
		first_trace.final_state.actor_position(MinimalGridFixture.PRIMARY_ACTOR_ID),
		Vector3i(1, 0, 1),
		"The replay must finish at its literal expected cell.",
	)
	context.expect_equal(
		first_trace.final_state.world_step(),
		4,
		"Only the four accepted replay commands may advance the world step.",
	)
	context.expect_equal(
		first_trace.domain_events.size(),
		expected_events.size(),
		"The replay must emit its complete literal event sequence.",
	)
	if first_trace.domain_events.size() == expected_events.size():
		for index: int in expected_events.size():
			context.expect_true(
				first_trace.domain_events[index].is_equal_to(expected_events[index]),
				"The replay event at index %d must match its literal oracle." % index,
			)
	context.expect_true(
		first_trace.final_state.is_equal_to(second_trace.final_state),
		"Equivalent initial states and commands must produce equivalent final states.",
	)
	context.expect_equal(
		first_trace.domain_events.size(),
		second_trace.domain_events.size(),
		"Equivalent replays must produce the same event count.",
	)
	if first_trace.domain_events.size() != second_trace.domain_events.size():
		return
	for index: int in first_trace.domain_events.size():
		context.expect_true(
			first_trace.domain_events[index].is_equal_to(second_trace.domain_events[index]),
			"Equivalent replays must preserve ordered event fields at index %d." % index,
		)


func _does_not_mutate_input(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var first_result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(MinimalGridFixture.PRIMARY_ACTOR_ID, Vector3i(-1, 0, 0)),
	)

	context.expect_true(state.is_equal_to(before), "Executing a command must not mutate its input state.")
	context.expect_true(
		first_result.next_state() != state,
		"Executing a command must return a distinct state instance.",
	)
	var derived_state: GridRuleStateScript = first_result.next_state()
	var derived_before: GridRuleStateScript = derived_state.copy()
	var second_result: GridRuleResultScript = GridRuleKernelScript.execute(
		derived_state,
		GridRuleCommandScript.move(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(0, 0, -1),
		),
	)
	context.expect_true(
		derived_state.is_equal_to(derived_before),
		"Advancing a derived state must not modify an earlier state.",
	)
	context.expect_true(
		second_result.next_state() != derived_state,
		"Advancing a derived state must return another distinct state instance.",
	)
	context.expect_true(state.is_equal_to(before), "Derived commands must not alter the original state.")


func _single_event(
	context: HeadlessTestContextScript, result: GridRuleResultScript
) -> GridRuleEventScript:
	var domain_events: Array[GridRuleEventScript] = result.domain_events()
	context.expect_equal(domain_events.size(), 1, "Each minimal movement command must emit one event.")
	if domain_events.size() != 1:
		return null
	return domain_events[0]


func _expect_rejection(
	context: HeadlessTestContextScript,
	input_state: GridRuleStateScript,
	input_before: GridRuleStateScript,
	result: GridRuleResultScript,
	expected_reason: int,
	expected_actor_id: StringName,
	expected_from_cell: Vector3i,
	expected_to_cell: Vector3i,
) -> void:
	context.expect_true(
		input_state.is_equal_to(input_before),
		"A rejected command must not mutate its input state.",
	)
	context.expect_true(
		result.next_state().is_equal_to(input_state),
		"A rejected command must preserve authoritative state fields.",
	)
	context.expect_true(
		result.next_state() != input_state,
		"A rejected command must still return a distinct state instance.",
	)
	_expect_event(
		context,
		result,
		GridRuleEventScript.Kind.COMMAND_REJECTED,
		expected_reason,
		expected_actor_id,
		expected_from_cell,
		expected_to_cell,
	)


func _expect_event(
	context: HeadlessTestContextScript,
	result: GridRuleResultScript,
	expected_kind: int,
	expected_reason: int,
	expected_actor_id: StringName,
	expected_from_cell: Vector3i,
	expected_to_cell: Vector3i,
) -> void:
	var event: GridRuleEventScript = _single_event(context, result)
	if event == null:
		return
	context.expect_equal(
		event.kind(),
		expected_kind,
		"A command must emit the expected event kind.",
	)
	context.expect_equal(
		event.rejection_reason(),
		expected_reason,
		"A command event must expose its stable rejection reason.",
	)
	context.expect_equal(
		event.actor_id(),
		expected_actor_id,
		"A command event must retain its expected actor.",
	)
	context.expect_equal(
		event.from_cell(),
		expected_from_cell,
		"A command event must retain its expected origin.",
	)
	context.expect_equal(
		event.to_cell(),
		expected_to_cell,
		"A command event must retain its expected target.",
	)


func _expect_read_only_storage(
	context: HeadlessTestContextScript,
	state: GridRuleStateScript,
	state_label: String,
) -> void:
	context.expect_true(state._grid_cells.is_read_only(), "%s grid cells must be frozen." % state_label)
	context.expect_true(
		state._blocked_cells.is_read_only(), "%s blocked cells must be frozen." % state_label
	)
	context.expect_true(state._grid_lookup.is_read_only(), "%s grid lookup must be frozen." % state_label)
	context.expect_true(
		state._blocked_lookup.is_read_only(), "%s blocked lookup must be frozen." % state_label
	)
	context.expect_true(
		state._actor_positions.is_read_only(), "%s actor positions must be frozen." % state_label
	)
	context.expect_true(
		state._static_validation_errors.is_read_only(),
		"%s static validation errors must be frozen." % state_label,
	)
	context.expect_true(
		state._dynamic_validation_errors.is_read_only(),
		"%s dynamic validation errors must be frozen." % state_label,
	)


func _replay(
	initial_state: GridRuleStateScript,
	commands: Array[GridRuleCommandScript],
) -> ReplayTraceScript:
	var current_state: GridRuleStateScript = initial_state
	var domain_events: Array[GridRuleEventScript] = []
	for command: GridRuleCommandScript in commands:
		var result: GridRuleResultScript = GridRuleKernelScript.execute(
			current_state,
			command,
		)
		current_state = result.next_state()
		domain_events.append_array(result.domain_events())
	return ReplayTraceScript.new(current_state, domain_events)
