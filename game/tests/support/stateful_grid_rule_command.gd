extends "res://src/rules/grid_rule_command.gd"

var _direction_reads: int = 0


func _init(actor_id: StringName) -> void:
	super(Kind.MOVE, actor_id, Vector3i(-1, 0, 0))


func direction() -> Vector3i:
	_direction_reads += 1
	if _direction_reads == 1:
		return Vector3i(-1, 0, 0)
	return Vector3i(2, 0, 0)


func direction_reads() -> int:
	return _direction_reads
