class_name EnemyWorldAddress
extends RefCounted

const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const MAXIMUM_SPACE_ID_LENGTH: int = 128

var _space_id: StringName = &""
var _cell: Vector3i = Vector3i.ZERO
var _initialized: bool = false


static func create(space_id: StringName, cell: Vector3i) -> EnemyWorldAddress:
	var address := new()
	address._space_id = space_id
	address._cell = cell
	address._initialized = true
	return address


func copy() -> EnemyWorldAddress:
	var copied_address := new()
	copied_address._space_id = _space_id
	copied_address._cell = _cell
	copied_address._initialized = _initialized
	return copied_address


func is_valid() -> bool:
	return _initialized and is_valid_space_id(_space_id)


static func is_valid_space_id(space_id: StringName) -> bool:
	return ValidationSupportScript.is_valid_identifier(
		space_id,
		MAXIMUM_SPACE_ID_LENGTH
	)


func is_initialized() -> bool:
	return _initialized


func space_id() -> StringName:
	return _space_id


func cell() -> Vector3i:
	return _cell


func canonical_slot_key() -> String:
	if not is_valid():
		return ""
	return "%s\u001f%d\u001f%d\u001f%d" % [
		String(_space_id),
		_cell.x,
		_cell.y,
		_cell.z,
	]


func is_equal_to(other: EnemyWorldAddress) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other._space_id == _space_id
		and other._cell == _cell
	)
