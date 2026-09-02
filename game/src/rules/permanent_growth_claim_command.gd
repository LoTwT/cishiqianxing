class_name PermanentGrowthClaimCommand
extends RefCounted

enum Kind {
	CLAIM = 1,
}

var _kind: int
var _reward_id: StringName


func _init(kind: int, reward_id: StringName) -> void:
	_kind = kind
	_reward_id = reward_id


static func claim(reward_id: StringName) -> PermanentGrowthClaimCommand:
	return new(Kind.CLAIM, reward_id)


func kind() -> int:
	return _kind


func reward_id() -> StringName:
	return _reward_id


func copy() -> PermanentGrowthClaimCommand:
	return new(_kind, _reward_id)
