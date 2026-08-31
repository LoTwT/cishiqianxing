class_name GridRuleState
extends RefCounted

const MAX_WORLD_STEP := 9_223_372_036_854_775_807

var _grid_cells: Array[Vector3i] = []
var _blocked_cells: Array[Vector3i] = []
var _grid_lookup: Dictionary[Vector3i, bool] = {}
var _blocked_lookup: Dictionary[Vector3i, bool] = {}
var _actor_positions: Dictionary[StringName, Vector3i] = {}
var _world_step: int = 0
var _static_validation_errors: Array[String] = [
	"GridRuleState must be initialized through create().",
]
var _dynamic_validation_errors: Array[String] = []


func _init() -> void:
	_freeze_collections()


static func create(
	grid_cells: Array[Vector3i],
	blocked_cells: Array[Vector3i],
	actor_positions: Dictionary[StringName, Vector3i],
	world_step: int = 0,
) -> GridRuleState:
	var state := new()
	state._grid_cells = _copy_and_sort_cells(grid_cells)
	state._blocked_cells = _copy_and_sort_cells(blocked_cells)
	state._grid_lookup = _build_cell_lookup(state._grid_cells)
	state._blocked_lookup = _build_cell_lookup(state._blocked_cells)
	state._actor_positions = _copy_actor_positions(actor_positions)
	state._world_step = world_step
	state._static_validation_errors = state._collect_static_validation_errors()
	state._dynamic_validation_errors = state._collect_dynamic_validation_errors()
	state._freeze_collections()
	return state


func copy() -> GridRuleState:
	return _copy_with_owned_actor_positions(
		_copy_actor_positions(_actor_positions), _world_step
	)


func copy_with_actor_position(actor_id: StringName, position: Vector3i) -> GridRuleState:
	var copied_positions: Dictionary[StringName, Vector3i] = _copy_actor_positions(
		_actor_positions
	)
	copied_positions[actor_id] = position
	return _copy_with_owned_actor_positions(copied_positions, _world_step + 1)


func is_valid() -> bool:
	return _static_validation_errors.is_empty() and _dynamic_validation_errors.is_empty()


func validation_errors() -> Array[String]:
	var copied_errors: Array[String] = []
	for error: String in _static_validation_errors:
		copied_errors.append(error)
	for error: String in _dynamic_validation_errors:
		copied_errors.append(error)
	return copied_errors


func world_step() -> int:
	return _world_step


func has_actor(actor_id: StringName) -> bool:
	return _actor_positions.has(actor_id)


func actor_position(actor_id: StringName) -> Vector3i:
	assert(has_actor(actor_id), "Cannot read an unknown actor position.")
	return _actor_positions[actor_id]


func actor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for actor_id: StringName in _actor_positions:
		ids.append(actor_id)
	ids.sort_custom(_actor_id_less_than)
	return ids


func is_grid_cell(cell: Vector3i) -> bool:
	return _grid_lookup.has(cell)


func is_blocked_cell(cell: Vector3i) -> bool:
	return _blocked_lookup.has(cell)


func is_occupied_cell(cell: Vector3i, ignored_actor_id: StringName = &"") -> bool:
	for actor_id: StringName in actor_ids():
		if actor_id != ignored_actor_id and actor_position(actor_id) == cell:
			return true
	return false


func grid_cells() -> Array[Vector3i]:
	return _copy_cells(_grid_cells)


func blocked_cells() -> Array[Vector3i]:
	return _copy_cells(_blocked_cells)


func is_equal_to(other: GridRuleState) -> bool:
	if other == null:
		return false
	if (
		other.world_step() != _world_step
		or other.grid_cells() != _grid_cells
		or other.blocked_cells() != _blocked_cells
		or other.actor_ids() != actor_ids()
	):
		return false
	for actor_id: StringName in actor_ids():
		if other.actor_position(actor_id) != actor_position(actor_id):
			return false
	return true


func _copy_with_owned_actor_positions(
	actor_positions: Dictionary[StringName, Vector3i], world_step: int
) -> GridRuleState:
	var copied_state := new()
	copied_state._grid_cells = _grid_cells
	copied_state._blocked_cells = _blocked_cells
	copied_state._grid_lookup = _grid_lookup
	copied_state._blocked_lookup = _blocked_lookup
	copied_state._static_validation_errors = _static_validation_errors
	copied_state._actor_positions = actor_positions
	copied_state._world_step = world_step
	copied_state._dynamic_validation_errors = copied_state._collect_dynamic_validation_errors()
	copied_state._freeze_collections()
	return copied_state


func _freeze_collections() -> void:
	_grid_cells.make_read_only()
	_blocked_cells.make_read_only()
	_grid_lookup.make_read_only()
	_blocked_lookup.make_read_only()
	_actor_positions.make_read_only()
	_static_validation_errors.make_read_only()
	_dynamic_validation_errors.make_read_only()


func _collect_static_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if _grid_cells.is_empty():
		errors.append("A grid state needs grid cells.")
	if _cells_have_duplicates(_grid_cells):
		errors.append("Grid cells must be unique.")
	if _cells_have_duplicates(_blocked_cells):
		errors.append("Blocked cells must be unique.")

	for blocked_cell: Vector3i in _blocked_cells:
		if not _grid_lookup.has(blocked_cell):
			errors.append("Every blocked cell must be part of the grid.")
	return errors


func _collect_dynamic_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if _world_step < 0:
		errors.append("World step cannot be negative.")
	if _actor_positions.is_empty():
		errors.append("A grid state needs at least one actor.")

	var occupied_cells: Array[Vector3i] = []
	for actor_id: StringName in actor_ids():
		if String(actor_id).is_empty():
			errors.append("Actor IDs cannot be empty.")
		var position: Vector3i = actor_position(actor_id)
		if not _grid_lookup.has(position):
			errors.append("Every actor must start on the grid.")
		if _blocked_lookup.has(position):
			errors.append("An actor cannot start on a blocked cell.")
		if occupied_cells.has(position):
			errors.append("Two actors cannot occupy the same cell.")
		occupied_cells.append(position)
	return errors


static func _copy_and_sort_cells(cells: Array[Vector3i]) -> Array[Vector3i]:
	var copied_cells: Array[Vector3i] = _copy_cells(cells)
	copied_cells.sort_custom(_cell_less_than)
	return copied_cells


static func _copy_cells(cells: Array[Vector3i]) -> Array[Vector3i]:
	var copied_cells: Array[Vector3i] = []
	for cell: Vector3i in cells:
		copied_cells.append(cell)
	return copied_cells


static func _build_cell_lookup(
	cells: Array[Vector3i]
) -> Dictionary[Vector3i, bool]:
	var lookup: Dictionary[Vector3i, bool] = {}
	for cell: Vector3i in cells:
		lookup[cell] = true
	return lookup


static func _copy_actor_positions(
	actor_positions: Dictionary[StringName, Vector3i]
) -> Dictionary[StringName, Vector3i]:
	var copied_positions: Dictionary[StringName, Vector3i] = {}
	var ids: Array[StringName] = []
	for actor_id: StringName in actor_positions:
		ids.append(actor_id)
	ids.sort_custom(_actor_id_less_than)
	for actor_id: StringName in ids:
		copied_positions[actor_id] = actor_positions[actor_id]
	return copied_positions


static func _cell_less_than(left: Vector3i, right: Vector3i) -> bool:
	if left.x != right.x:
		return left.x < right.x
	if left.y != right.y:
		return left.y < right.y
	return left.z < right.z


static func _actor_id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


static func _cells_have_duplicates(cells: Array[Vector3i]) -> bool:
	for index: int in range(1, cells.size()):
		if cells[index - 1] == cells[index]:
			return true
	return false
