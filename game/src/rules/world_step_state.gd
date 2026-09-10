class_name WorldStepState
extends RefCounted

const EnemyWorldStateScript := preload("res://src/rules/enemy_world_state.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const PlayerProgressionStateScript := preload("res://src/rules/player_progression_state.gd")
const PortableInventoryStateScript := preload("res://src/rules/portable_inventory_state.gd")
const WorldStepStageInputsScript := preload("res://src/rules/world_step_stage_inputs.gd")

var _space_id: StringName = &""
var _integrity_space_id: StringName = &""
var _grid_state: GridRuleStateScript
var _integrity_grid_state: GridRuleStateScript
var _player_state: PlayerProgressionStateScript
var _integrity_player_state: PlayerProgressionStateScript
var _enemy_world_state: EnemyWorldStateScript
var _integrity_enemy_world_state: EnemyWorldStateScript
var _inventory_state: PortableInventoryStateScript
var _integrity_inventory_state: PortableInventoryStateScript
var _stage_inputs: WorldStepStageInputsScript
var _integrity_stage_inputs: WorldStepStageInputsScript
var _initialized: bool = false
var _integrity_initialized: bool = false


static func create(
	space_id_value: StringName,
	grid_state_value: GridRuleStateScript,
	player_state_value: PlayerProgressionStateScript,
	enemy_world_state_value: EnemyWorldStateScript,
	inventory_state_value: PortableInventoryStateScript,
	stage_inputs_value: WorldStepStageInputsScript,
) -> WorldStepState:
	var result := new()
	result._space_id = space_id_value
	result._grid_state = grid_state_value.copy() if grid_state_value != null and grid_state_value.get_script() == GridRuleStateScript else null
	result._player_state = player_state_value.copy() if player_state_value != null and player_state_value.get_script() == PlayerProgressionStateScript else null
	result._enemy_world_state = enemy_world_state_value.copy() if enemy_world_state_value != null and enemy_world_state_value.get_script() == EnemyWorldStateScript else null
	result._inventory_state = inventory_state_value.copy() if inventory_state_value != null and inventory_state_value.get_script() == PortableInventoryStateScript else null
	result._stage_inputs = stage_inputs_value.copy() if stage_inputs_value != null and stage_inputs_value.get_script() == WorldStepStageInputsScript else null
	result._initialized = true
	result._capture_integrity()
	return result


func copy() -> WorldStepState:
	var result := new()
	if not is_valid():
		return result
	result._space_id = _space_id
	result._grid_state = _grid_state.copy()
	result._player_state = _player_state.copy()
	result._enemy_world_state = _enemy_world_state.copy()
	result._inventory_state = _inventory_state.copy()
	result._stage_inputs = _stage_inputs.copy()
	result._initialized = true
	result._capture_integrity()
	return result


func is_valid() -> bool:
	return (
		_initialized and _integrity_initialized
		and _space_id == _integrity_space_id
		and _grid_state != null and _grid_state.get_script() == GridRuleStateScript
		and _integrity_grid_state != null and _integrity_grid_state.get_script() == GridRuleStateScript
		and _grid_state.is_valid() and _grid_state.is_equal_to(_integrity_grid_state)
		and _player_state != null and _player_state.get_script() == PlayerProgressionStateScript
		and _integrity_player_state != null and _integrity_player_state.get_script() == PlayerProgressionStateScript
		and _player_state.is_valid() and _player_state.is_equal_to(_integrity_player_state)
		and _enemy_world_state != null and _enemy_world_state.get_script() == EnemyWorldStateScript
		and _integrity_enemy_world_state != null and _integrity_enemy_world_state.get_script() == EnemyWorldStateScript
		and _enemy_world_state.is_valid() and _enemy_world_state.is_equal_to(_integrity_enemy_world_state)
		and _inventory_state != null and _inventory_state.get_script() == PortableInventoryStateScript
		and _integrity_inventory_state != null and _integrity_inventory_state.get_script() == PortableInventoryStateScript
		and _inventory_state.is_valid() and _inventory_state.is_equal_to(_integrity_inventory_state)
		and _stage_inputs != null and _stage_inputs.get_script() == WorldStepStageInputsScript
		and _integrity_stage_inputs != null and _integrity_stage_inputs.get_script() == WorldStepStageInputsScript
		and _stage_inputs.is_valid() and _stage_inputs.is_equal_to(_integrity_stage_inputs)
	)


func space_id() -> StringName:
	return _space_id


func grid_state() -> GridRuleStateScript:
	return _grid_state.copy() if is_valid() else null


func player_state() -> PlayerProgressionStateScript:
	return _player_state.copy() if is_valid() else null


func enemy_world_state() -> EnemyWorldStateScript:
	return _enemy_world_state.copy() if is_valid() else null


func inventory_state() -> PortableInventoryStateScript:
	return _inventory_state.copy() if is_valid() else null


func stage_inputs() -> WorldStepStageInputsScript:
	return _stage_inputs.copy() if is_valid() else null


func is_equal_to(other: WorldStepState) -> bool:
	return (
		other != null and other.get_script() == get_script()
		and is_valid() and other.is_valid()
		and _space_id == other._space_id
		and _grid_state.is_equal_to(other._grid_state)
		and _player_state.is_equal_to(other._player_state)
		and _enemy_world_state.is_equal_to(other._enemy_world_state)
		and _inventory_state.is_equal_to(other._inventory_state)
		and _stage_inputs.is_equal_to(other._stage_inputs)
	)


func _capture_integrity() -> void:
	_integrity_space_id = _space_id
	_integrity_grid_state = _grid_state.copy() if _grid_state != null and _grid_state.get_script() == GridRuleStateScript else null
	_integrity_player_state = _player_state.copy() if _player_state != null and _player_state.get_script() == PlayerProgressionStateScript else null
	_integrity_enemy_world_state = _enemy_world_state.copy() if _enemy_world_state != null and _enemy_world_state.get_script() == EnemyWorldStateScript else null
	_integrity_inventory_state = _inventory_state.copy() if _inventory_state != null and _inventory_state.get_script() == PortableInventoryStateScript else null
	_integrity_stage_inputs = _stage_inputs.copy() if _stage_inputs != null and _stage_inputs.get_script() == WorldStepStageInputsScript else null
	_integrity_initialized = _initialized
