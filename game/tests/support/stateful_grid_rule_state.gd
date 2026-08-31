extends "res://src/rules/grid_rule_state.gd"

var _is_valid_reads: int = 0
var _copy_reads: int = 0


func is_valid() -> bool:
	_is_valid_reads += 1
	return true


func copy() -> GridRuleState:
	_copy_reads += 1
	return super.copy()


func is_valid_reads() -> int:
	return _is_valid_reads


func copy_reads() -> int:
	return _copy_reads
