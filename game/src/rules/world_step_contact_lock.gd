class_name WorldStepContactLock
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const WorldStepContactCommandScript := preload(
	"res://src/rules/world_step_contact_command.gd"
)

var _space_id: StringName = &""
var _integrity_space_id: StringName = &""
var _world_step: int = -1
var _integrity_world_step: int = -1
var _player_actor_id: StringName = &""
var _integrity_player_actor_id: StringName = &""
var _target_enemy_instance_id: StringName = &""
var _integrity_target_enemy_instance_id: StringName = &""
var _player_cell: Vector3i = Vector3i.ZERO
var _integrity_player_cell: Vector3i = Vector3i.ZERO
var _target_enemy_cell: Vector3i = Vector3i.ZERO
var _integrity_target_enemy_cell: Vector3i = Vector3i.ZERO
var _moving_actor_id: StringName = &""
var _integrity_moving_actor_id: StringName = &""
var _attempted_destination_cell: Vector3i = Vector3i.ZERO
var _integrity_attempted_destination_cell: Vector3i = Vector3i.ZERO
var _initiator_side: int = 0
var _integrity_initiator_side: int = 0
var _initialized: bool = false
var _integrity_initialized: bool = false


func copy() -> WorldStepContactLock:
	var copied_lock := new()
	copied_lock._space_id = _space_id
	copied_lock._integrity_space_id = _integrity_space_id
	copied_lock._world_step = _world_step
	copied_lock._integrity_world_step = _integrity_world_step
	copied_lock._player_actor_id = _player_actor_id
	copied_lock._integrity_player_actor_id = _integrity_player_actor_id
	copied_lock._target_enemy_instance_id = _target_enemy_instance_id
	copied_lock._integrity_target_enemy_instance_id = (
		_integrity_target_enemy_instance_id
	)
	copied_lock._player_cell = _player_cell
	copied_lock._integrity_player_cell = _integrity_player_cell
	copied_lock._target_enemy_cell = _target_enemy_cell
	copied_lock._integrity_target_enemy_cell = _integrity_target_enemy_cell
	copied_lock._moving_actor_id = _moving_actor_id
	copied_lock._integrity_moving_actor_id = _integrity_moving_actor_id
	copied_lock._attempted_destination_cell = _attempted_destination_cell
	copied_lock._integrity_attempted_destination_cell = (
		_integrity_attempted_destination_cell
	)
	copied_lock._initiator_side = _initiator_side
	copied_lock._integrity_initiator_side = _integrity_initiator_side
	copied_lock._initialized = _initialized
	copied_lock._integrity_initialized = _integrity_initialized
	return copied_lock


func is_valid() -> bool:
	return (
		_integrity_fields_match()
		and _initialized
		and EnemyWorldAddressScript.is_valid_space_id(_space_id)
		and _world_step >= 0
		and _world_step <= ValidationSupportScript.MAX_WORLD_STEP
		and _player_actor_id
		== WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID
		and EnemyInstanceStateScript.is_valid_instance_id(
			_target_enemy_instance_id
		)
		and _target_enemy_instance_id != _player_actor_id
		and _moving_actor_id in [_player_actor_id, _target_enemy_instance_id]
		and _player_cell != _target_enemy_cell
		and _cells_are_orthogonally_adjacent(_player_cell, _target_enemy_cell)
		and _movement_metadata_is_valid()
	)


func space_id() -> StringName:
	return _space_id if is_valid() else &""


func world_step() -> int:
	return _world_step if is_valid() else -1


func player_actor_id() -> StringName:
	return _player_actor_id if is_valid() else &""


func target_enemy_instance_id() -> StringName:
	return _target_enemy_instance_id if is_valid() else &""


func player_cell() -> Vector3i:
	return _player_cell if is_valid() else Vector3i.ZERO


func target_enemy_cell() -> Vector3i:
	return _target_enemy_cell if is_valid() else Vector3i.ZERO


func moving_actor_id() -> StringName:
	return _moving_actor_id if is_valid() else &""


func attempted_destination_cell() -> Vector3i:
	return _attempted_destination_cell if is_valid() else Vector3i.ZERO


func initiator_side() -> int:
	return _initiator_side if is_valid() else 0


func target_enemy_address() -> EnemyWorldAddressScript:
	if not is_valid():
		return null
	return EnemyWorldAddressScript.create(_space_id, _target_enemy_cell)


func locked_actor_ids() -> Array[StringName]:
	if not is_valid():
		return []
	var actor_ids: Array[StringName] = [
		_player_actor_id,
		_target_enemy_instance_id,
	]
	actor_ids.sort_custom(ValidationSupportScript.id_less_than)
	return actor_ids


func is_actor_locked(actor_id: StringName) -> bool:
	return is_valid() and actor_id in [_player_actor_id, _target_enemy_instance_id]


func is_commit_boundary() -> bool:
	return false


func is_equal_to(other: WorldStepContactLock) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and is_valid()
		and other.is_valid()
		and other._space_id == _space_id
		and other._world_step == _world_step
		and other._player_actor_id == _player_actor_id
		and other._target_enemy_instance_id == _target_enemy_instance_id
		and other._player_cell == _player_cell
		and other._target_enemy_cell == _target_enemy_cell
		and other._moving_actor_id == _moving_actor_id
		and other._attempted_destination_cell == _attempted_destination_cell
		and other._initiator_side == _initiator_side
	)


func _integrity_fields_match() -> bool:
	return (
		_initialized == _integrity_initialized
		and _space_id == _integrity_space_id
		and _world_step == _integrity_world_step
		and _player_actor_id == _integrity_player_actor_id
		and _target_enemy_instance_id == _integrity_target_enemy_instance_id
		and _player_cell == _integrity_player_cell
		and _target_enemy_cell == _integrity_target_enemy_cell
		and _moving_actor_id == _integrity_moving_actor_id
		and _attempted_destination_cell
		== _integrity_attempted_destination_cell
		and _initiator_side == _integrity_initiator_side
	)


func _movement_metadata_is_valid() -> bool:
	if _moving_actor_id == _player_actor_id:
		return (
			_attempted_destination_cell == _target_enemy_cell
			and _initiator_side == ContactCombatCommandScript.Side.PLAYER
		)
	return (
		_attempted_destination_cell == _player_cell
		and _initiator_side == ContactCombatCommandScript.Side.OPPONENT
	)


static func _cells_are_orthogonally_adjacent(
	left: Vector3i,
	right: Vector3i,
) -> bool:
	return (
		left.y == right.y
		and (
			(
				left.x == right.x
				and absi(int(right.z) - int(left.z)) == 1
			)
			or (
				left.z == right.z
				and absi(int(right.x) - int(left.x)) == 1
			)
		)
	)


