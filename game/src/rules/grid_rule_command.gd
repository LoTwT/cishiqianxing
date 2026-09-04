class_name GridRuleCommand
extends RefCounted

enum Kind {
	MOVE = 1,
}

var _kind: int = 0
var _actor_id: StringName = &""
var _direction: Vector3i = Vector3i.ZERO
var _initialized: bool = false


func _init() -> void:
	pass


static func move(actor_id: StringName, direction: Vector3i) -> GridRuleCommand:
	var command := new()
	command._kind = Kind.MOVE
	command._actor_id = actor_id
	command._direction = direction
	command._initialized = true
	return command


# 方向合法性由 GridRuleKernel 的 INVALID_DIRECTION 拒绝路径独立校验，
# 命令自身的有效性只覆盖构造合同。
func is_valid() -> bool:
	return (
		_initialized
		and _kind == Kind.MOVE
		and not String(_actor_id).is_empty()
	)


func kind() -> int:
	return _kind


func actor_id() -> StringName:
	return _actor_id


func direction() -> Vector3i:
	return _direction
