class_name WorldStepContactCommand
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")

const AUTHORITATIVE_PLAYER_ACTOR_ID: StringName = &"actor.loer"

enum Kind {
	ATTEMPT_ENTRY = 1,
}

var _kind: int = 0
var _space_id: StringName = &""
var _moving_actor_id: StringName = &""
var _expected_from_cell: Vector3i = Vector3i.ZERO
var _direction: Vector3i = Vector3i.ZERO
var _expected_world_step: int = -1
var _initialized: bool = false


static func attempt_entry(
	space_id: StringName,
	moving_actor_id: StringName,
	expected_from_cell: Vector3i,
	direction: Vector3i,
	expected_world_step: int,
) -> WorldStepContactCommand:
	var command := new()
	command._kind = Kind.ATTEMPT_ENTRY
	command._space_id = space_id
	command._moving_actor_id = moving_actor_id
	command._expected_from_cell = expected_from_cell
	command._direction = direction
	command._expected_world_step = expected_world_step
	command._initialized = true
	return command


func copy() -> WorldStepContactCommand:
	var copied_command := new()
	copied_command._kind = _kind
	copied_command._space_id = _space_id
	copied_command._moving_actor_id = _moving_actor_id
	copied_command._expected_from_cell = _expected_from_cell
	copied_command._direction = _direction
	copied_command._expected_world_step = _expected_world_step
	copied_command._initialized = _initialized
	return copied_command


func is_valid() -> bool:
	return (
		_initialized
		and _kind == Kind.ATTEMPT_ENTRY
		and EnemyWorldAddressScript.is_valid_space_id(_space_id)
		and EnemyInstanceStateScript.is_valid_instance_id(_moving_actor_id)
		and _is_horizontal_unit_direction(_direction)
		and _expected_world_step >= 0
		and _expected_world_step <= GridRuleStateScript.MAX_WORLD_STEP
	)


func kind() -> int:
	return _kind


func space_id() -> StringName:
	return _space_id


func moving_actor_id() -> StringName:
	return _moving_actor_id


func expected_from_cell() -> Vector3i:
	return _expected_from_cell


func direction() -> Vector3i:
	return _direction


func expected_world_step() -> int:
	return _expected_world_step


func is_equal_to(other: WorldStepContactCommand) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other._kind == _kind
		and other._space_id == _space_id
		and other._moving_actor_id == _moving_actor_id
		and other._expected_from_cell == _expected_from_cell
		and other._direction == _direction
		and other._expected_world_step == _expected_world_step
	)


static func _is_horizontal_unit_direction(direction: Vector3i) -> bool:
	return direction.y == 0 and absi(direction.x) + absi(direction.z) == 1
