class_name GridRuleCommand
extends RefCounted

enum Kind {
	MOVE = 1,
}

var _kind: int
var _actor_id: StringName
var _direction: Vector3i


func _init(kind: int, actor_id: StringName, direction: Vector3i) -> void:
	_kind = kind
	_actor_id = actor_id
	_direction = direction


static func move(actor_id: StringName, direction: Vector3i) -> GridRuleCommand:
	return new(Kind.MOVE, actor_id, direction)


func kind() -> int:
	return _kind


func actor_id() -> StringName:
	return _actor_id


func direction() -> Vector3i:
	return _direction
