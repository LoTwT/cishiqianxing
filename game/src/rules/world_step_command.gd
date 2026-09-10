class_name WorldStepCommand
extends RefCounted


const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum Kind { MOVE = 1, WAIT = 2 }
var _kind: int = 0
var _integrity_kind: int = 0
var _expected_world_step: int = -1
var _integrity_expected_world_step: int = -1
var _expected_from_cell: Vector3i = Vector3i.ZERO
var _integrity_expected_from_cell: Vector3i = Vector3i.ZERO
var _direction: Vector3i = Vector3i.ZERO
var _integrity_direction: Vector3i = Vector3i.ZERO
var _initialized: bool = false
var _integrity_initialized: bool = false


static func create(
	kind_value: int,
	expected_world_step_value: int,
	expected_from_cell_value: Vector3i,
	direction_value: Vector3i,
) -> WorldStepCommand:
	var result := new()
	result._kind = kind_value
	result._expected_world_step = expected_world_step_value
	result._expected_from_cell = expected_from_cell_value
	result._direction = direction_value
	result._initialized = true
	result._capture_integrity()
	return result


func copy() -> WorldStepCommand:
	var result := new()
	if not is_valid():
		return result
	result._kind = _kind
	result._expected_world_step = _expected_world_step
	result._expected_from_cell = _expected_from_cell
	result._direction = _direction
	result._initialized = true
	result._capture_integrity()
	return result


func is_valid() -> bool:
	return (
		_initialized and _integrity_initialized
		and _kind == _integrity_kind
		and _expected_world_step == _integrity_expected_world_step
		and _expected_from_cell == _integrity_expected_from_cell
		and _direction == _integrity_direction
		and (_expected_world_step >= 0 and ((_kind == Kind.WAIT and _direction == Vector3i.ZERO) or (_kind == Kind.MOVE and ValidationSupportScript.is_horizontal_unit_direction(_direction))))
	)


func kind() -> int:
	return _kind


func expected_world_step() -> int:
	return _expected_world_step


func expected_from_cell() -> Vector3i:
	return _expected_from_cell


func direction() -> Vector3i:
	return _direction


func is_equal_to(other: WorldStepCommand) -> bool:
	return (
		other != null and other.get_script() == get_script()
		and is_valid() and other.is_valid()
		and _kind == other._kind
		and _expected_world_step == other._expected_world_step
		and _expected_from_cell == other._expected_from_cell
		and _direction == other._direction
	)


func _capture_integrity() -> void:
	_integrity_kind = _kind
	_integrity_expected_world_step = _expected_world_step
	_integrity_expected_from_cell = _expected_from_cell
	_integrity_direction = _direction
	_integrity_initialized = _initialized
