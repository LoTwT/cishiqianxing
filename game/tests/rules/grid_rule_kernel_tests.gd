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
const StatefulGridRuleStateScript := preload("res://tests/support/stateful_grid_rule_state.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new("grid_kernel.initializes_fixture", _initializes_fixture),
		HeadlessTestCaseScript.new("grid_kernel.freezes_state_storage", _freezes_state_storage),
		HeadlessTestCaseScript.new("grid_kernel.rejects_invalid_state", _rejects_invalid_state),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_invalid_state_matrix", _rejects_invalid_state_matrix
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_polymorphic_state", _rejects_polymorphic_state
		),
		HeadlessTestCaseScript.new("grid_kernel.rejects_null_references", _rejects_null_references),
		HeadlessTestCaseScript.new("grid_kernel.moves_one_cell", _moves_one_cell),
		HeadlessTestCaseScript.new(
			"grid_kernel.rejects_polymorphic_command", _rejects_polymorphic_command
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.revalidates_rebound_state", _revalidates_rebound_state
		),
		HeadlessTestCaseScript.new(
			"grid_kernel.isolates_result_snapshots", _isolates_result_snapshots
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


func _rejects_invalid_state_matrix(context: HeadlessTestContextScript) -> void:
	var first_cell := Vector3i.ZERO
	var second_cell := Vector3i(1, 0, 0)
	var grid_cells: Array[Vector3i] = [first_cell, second_cell]
	var no_blocked_cells: Array[Vector3i] = []
	var primary_actor: Dictionary[StringName, Vector3i] = {
		MinimalGridFixture.PRIMARY_ACTOR_ID: first_cell,
	}

	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.new(),
		"GridRuleState must be initialized through create().",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			[],
			no_blocked_cells,
			primary_actor,
		),
		"A grid state needs grid cells.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			no_blocked_cells,
			{},
		),
		"A grid state needs at least one actor.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			[first_cell, first_cell],
			no_blocked_cells,
			primary_actor,
		),
		"Grid cells must be unique.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			[second_cell, second_cell],
			primary_actor,
		),
		"Blocked cells must be unique.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			no_blocked_cells,
			{&"": first_cell},
		),
		"Actor IDs cannot be empty.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			no_blocked_cells,
			{MinimalGridFixture.PRIMARY_ACTOR_ID: Vector3i(2, 0, 0)},
		),
		"Every actor must start on the grid.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			[second_cell],
			{MinimalGridFixture.PRIMARY_ACTOR_ID: second_cell},
		),
		"An actor cannot start on a blocked cell.",
	)
	_expect_invalid_state_invariant(
		context,
		GridRuleStateScript.create(
			grid_cells,
			no_blocked_cells,
			{
				MinimalGridFixture.PRIMARY_ACTOR_ID: first_cell,
				MinimalGridFixture.SECONDARY_ACTOR_ID: first_cell,
			},
		),
		"Two actors cannot occupy the same cell.",
	)

	var noncanonical_blocked_state: GridRuleStateScript = GridRuleStateScript.create(
		[first_cell, second_cell, Vector3i(2, 0, 0)],
		[first_cell, second_cell],
		{MinimalGridFixture.PRIMARY_ACTOR_ID: Vector3i(2, 0, 0)},
	)
	noncanonical_blocked_state._blocked_cells = [second_cell, first_cell]
	_expect_invalid_state_invariant(
		context,
		noncanonical_blocked_state,
		"Blocked cells must use canonical order.",
	)


func _rejects_polymorphic_state(context: HeadlessTestContextScript) -> void:
	var state: StatefulGridRuleStateScript = StatefulGridRuleStateScript.new()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(-1, 0, 0),
		),
	)
	context.expect_equal(
		state.is_valid_reads(),
		0,
		"A polymorphic state must be rejected before its validity method runs.",
	)
	context.expect_equal(
		state.copy_reads(),
		0,
		"A polymorphic state must be rejected before its copy method runs.",
	)
	context.expect_true(
		not result.next_state().is_valid(),
		"A rejected polymorphic state must produce an invalid state snapshot.",
	)
	_expect_event(
		context,
		result,
		GridRuleEventScript.Kind.COMMAND_REJECTED,
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


func _rejects_polymorphic_command(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	var before: GridRuleStateScript = state.copy()
	var command: StatefulGridRuleCommandScript = StatefulGridRuleCommandScript.new(
		MinimalGridFixture.PRIMARY_ACTOR_ID
	)
	var first_result: GridRuleResultScript = GridRuleKernelScript.execute(state, command)
	var second_result: GridRuleResultScript = GridRuleKernelScript.execute(state, command)
	context.expect_equal(
		command.direction_reads(),
		0,
		"A polymorphic command must be rejected before an overrideable getter runs.",
	)
	context.expect_equal(
		command.kind_reads(),
		0,
		"A polymorphic command must be rejected before its kind getter runs.",
	)
	context.expect_equal(
		command.actor_id_reads(),
		0,
		"A polymorphic command must be rejected before its actor getter runs.",
	)
	_expect_rejection(
		context,
		state,
		before,
		first_result,
		GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		&"",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)
	_expect_rejection(
		context,
		state,
		before,
		second_result,
		GridRuleEventScript.RejectionReason.UNKNOWN_COMMAND,
		&"",
		Vector3i.ZERO,
		Vector3i.ZERO,
	)
	context.expect_true(
		first_result.next_state().is_equal_to(second_result.next_state()),
		"Reusing a rejected polymorphic command must produce the same state snapshot.",
	)
	var first_events: Array[GridRuleEventScript] = first_result.domain_events()
	var second_events: Array[GridRuleEventScript] = second_result.domain_events()
	context.expect_equal(
		first_events.size(),
		second_events.size(),
		"Reusing a rejected polymorphic command must produce the same event count.",
	)
	if first_events.size() == 1 and second_events.size() == 1:
		context.expect_true(
			first_events[0].is_equal_to(second_events[0]),
			"Reusing a rejected polymorphic command must produce the same event snapshot.",
		)


func _revalidates_rebound_state(context: HeadlessTestContextScript) -> void:
	var state: GridRuleStateScript = MinimalGridFixture.create_state()
	context.expect_true(state.is_valid(), "The fixture must begin valid.")
	state._world_step = -1
	context.expect_true(
		not state.is_valid(),
		"Validation must reflect rebound scalar state instead of cached diagnostics.",
	)
	context.expect_true(
		state.validation_errors().has("World step cannot be negative."),
		"Revalidation must report the rebound field's concrete invariant violation.",
	)

	state = MinimalGridFixture.create_state()
	state._grid_cells = [MinimalGridFixture.DEFAULT_ACTOR_POSITION]
	context.expect_true(
		state.is_grid_cell(MinimalGridFixture.DEFAULT_ACTOR_POSITION),
		"Grid queries must use the current canonical grid storage.",
	)
	context.expect_true(
		not state.is_grid_cell(Vector3i.ZERO),
		"Grid queries must not use a stale duplicate lookup after storage is rebound.",
	)

	state = MinimalGridFixture.create_state()
	state._blocked_cells = [Vector3i(99, 0, 99)]
	context.expect_true(
		not state.is_valid(),
		"Rebinding a blocked cell outside the grid must invalidate the state.",
	)
	context.expect_true(
		state.validation_errors().has("Every blocked cell must be part of the grid."),
		"Fresh static validation must report a rebound blocked-cell violation.",
	)

	state = MinimalGridFixture.create_state()
	var initialized_before: GridRuleStateScript = state.copy()
	state._initialized = false
	context.expect_true(
		not state.is_valid(),
		"Rebinding the initialization marker must invalidate the state.",
	)
	context.expect_true(
		not state.is_equal_to(initialized_before),
		"State equality must include every field that changes authoritative validity.",
	)

	state = MinimalGridFixture.create_state()
	var reversed_grid_cells: Array[Vector3i] = state.grid_cells()
	reversed_grid_cells.reverse()
	state._grid_cells = reversed_grid_cells
	context.expect_true(
		not state.is_valid(),
		"Rebinding grid cells out of canonical order must invalidate the state.",
	)
	context.expect_true(
		state.validation_errors().has("Grid cells must use canonical order."),
		"Revalidation must report noncanonical grid ordering.",
	)
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(-1, 0, 0),
		),
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


func _isolates_result_snapshots(context: HeadlessTestContextScript) -> void:
	var source_state: GridRuleStateScript = MinimalGridFixture.create_state()
	var source_events: Array[GridRuleEventScript] = [
		GridRuleEventScript.actor_moved(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(1, 0, 1),
			Vector3i(0, 0, 1),
		),
	]
	var result: GridRuleResultScript = GridRuleResultScript.new(
		source_state,
		source_events,
	)
	source_state._world_step = 99
	source_events[0]._to_cell = Vector3i(88, 0, 88)
	context.expect_equal(
		result.next_state().world_step(),
		0,
		"Mutating constructor input state must not alter the stored result snapshot.",
	)
	var stored_events: Array[GridRuleEventScript] = result.domain_events()
	context.expect_equal(stored_events.size(), 1, "The stored result must retain one event.")
	if stored_events.size() == 1:
		context.expect_equal(
			stored_events[0].to_cell(),
			Vector3i(0, 0, 1),
			"Mutating a constructor input event must not alter the stored result snapshot.",
		)

	var exposed_state: GridRuleStateScript = result.next_state()
	exposed_state._world_step = 77
	context.expect_equal(
		result.next_state().world_step(),
		0,
		"Mutating one returned state object must not alter the stored result snapshot.",
	)

	var exposed_events: Array[GridRuleEventScript] = result.domain_events()
	context.expect_equal(exposed_events.size(), 1, "The fixture move must emit one event.")
	if exposed_events.size() != 1:
		return
	exposed_events[0]._to_cell = Vector3i(99, 0, 99)
	var fresh_events: Array[GridRuleEventScript] = result.domain_events()
	context.expect_equal(fresh_events.size(), 1, "The stored result must retain one event.")
	if fresh_events.size() != 1:
		return
	context.expect_equal(
		fresh_events[0].to_cell(),
		Vector3i(0, 0, 1),
		"Mutating one returned event object must not alter the stored event snapshot.",
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
		ValidationSupportScript.MAX_WORLD_STEP,
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
	var command := GridRuleCommandScript.new()
	command._kind = 999
	command._actor_id = MinimalGridFixture.PRIMARY_ACTOR_ID
	command._direction = Vector3i(-1, 0, 0)
	command._initialized = true
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


func _expect_invalid_state_invariant(
	context: HeadlessTestContextScript,
	state: GridRuleStateScript,
	expected_error: String,
) -> void:
	context.expect_true(not state.is_valid(), "The invariant fixture must be invalid.")
	context.expect_true(
		state.validation_errors().has(expected_error),
		"Invalid state diagnostics must include: %s" % expected_error,
	)
	var before: GridRuleStateScript = state.copy()
	var result: GridRuleResultScript = GridRuleKernelScript.execute(
		state,
		GridRuleCommandScript.move(
			MinimalGridFixture.PRIMARY_ACTOR_ID,
			Vector3i(1, 0, 0),
		),
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
	context.expect_true(
		state._actor_positions.is_read_only(), "%s actor positions must be frozen." % state_label
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
