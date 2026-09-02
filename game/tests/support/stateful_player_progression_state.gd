extends "res://src/rules/player_progression_state.gd"

var _copy_reads: int = 0
var _validity_reads: int = 0
var _profile_reads: int = 0


func copy() -> PlayerProgressionState:
	_copy_reads += 1
	return super.copy()


func is_valid() -> bool:
	_validity_reads += 1
	return true


func profile_id() -> StringName:
	_profile_reads += 1
	return &"progression.player.loer"


func read_count() -> int:
	return _copy_reads + _validity_reads + _profile_reads
