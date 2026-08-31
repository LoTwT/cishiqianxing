extends "res://src/rules/grid_rule_command.gd"

var _direction_reads: int = 0
var _kind_reads: int = 0
var _actor_id_reads: int = 0


func _init(actor_id: StringName) -> void:
	super(Kind.MOVE, actor_id, Vector3i(-1, 0, 0))


func direction() -> Vector3i:
	_direction_reads += 1
	if _direction_reads == 1:
		return Vector3i(-1, 0, 0)
	return Vector3i(2, 0, 0)


func kind() -> int:
	_kind_reads += 1
	return super.kind()


func actor_id() -> StringName:
	_actor_id_reads += 1
	return super.actor_id()


func direction_reads() -> int:
	return _direction_reads


func kind_reads() -> int:
	return _kind_reads


func actor_id_reads() -> int:
	return _actor_id_reads
