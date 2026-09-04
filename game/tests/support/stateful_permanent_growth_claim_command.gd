extends "res://src/rules/permanent_growth_claim_command.gd"

var _copy_reads: int = 0
var _kind_reads: int = 0
var _reward_id_reads: int = 0


func _init() -> void:
	super()
	_kind = Kind.CLAIM
	_reward_id = &"progression.reward.main.chapter.01.attack"
	_initialized = true


func copy() -> PermanentGrowthClaimCommand:
	_copy_reads += 1
	return super.copy()


func kind() -> int:
	_kind_reads += 1
	return super.kind()


func reward_id() -> StringName:
	_reward_id_reads += 1
	return super.reward_id()


func read_count() -> int:
	return _copy_reads + _kind_reads + _reward_id_reads
