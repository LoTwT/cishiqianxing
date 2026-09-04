class_name GridRuleEvent
extends RefCounted

enum Kind {
	ACTOR_MOVED = 1,
	COMMAND_REJECTED = 2,
}

enum RejectionReason {
	NONE = 0,
	UNKNOWN_COMMAND = 1,
	INVALID_DIRECTION = 2,
	UNKNOWN_ACTOR = 3,
	OUT_OF_BOUNDS = 4,
	BLOCKED = 5,
	OCCUPIED = 6,
	INVALID_STATE = 7,
	WORLD_STEP_LIMIT = 8,
}

var _kind: int
var _actor_id: StringName
var _from_cell: Vector3i
var _to_cell: Vector3i
var _rejection_reason: int


func _init(
	kind: int,
	actor_id: StringName,
	from_cell: Vector3i,
	to_cell: Vector3i,
	rejection_reason: int = RejectionReason.NONE,
) -> void:
	_kind = kind
	_actor_id = actor_id
	_from_cell = from_cell
	_to_cell = to_cell
	_rejection_reason = rejection_reason


static func actor_moved(
	actor_id: StringName, from_cell: Vector3i, to_cell: Vector3i
) -> GridRuleEvent:
	return new(Kind.ACTOR_MOVED, actor_id, from_cell, to_cell)


static func command_rejected(
	actor_id: StringName,
	from_cell: Vector3i,
	to_cell: Vector3i,
	rejection_reason: int,
) -> GridRuleEvent:
	return new(
		Kind.COMMAND_REJECTED,
		actor_id,
		from_cell,
		to_cell,
		rejection_reason,
	)


func kind() -> int:
	return _kind


func actor_id() -> StringName:
	return _actor_id


func from_cell() -> Vector3i:
	return _from_cell


func to_cell() -> Vector3i:
	return _to_cell


func rejection_reason() -> int:
	return _rejection_reason


func copy() -> GridRuleEvent:
	return new(
		_kind,
		_actor_id,
		_from_cell,
		_to_cell,
		_rejection_reason,
	)


func is_equal_to(other: GridRuleEvent) -> bool:
	return (
		other != null
		and other.get_script() == get_script()
		and other.kind() == _kind
		and other.actor_id() == _actor_id
		and other.from_cell() == _from_cell
		and other.to_cell() == _to_cell
		and other.rejection_reason() == _rejection_reason
	)
