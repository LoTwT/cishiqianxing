class_name PermanentGrowthClaimCommand
extends RefCounted

enum Kind {
	CLAIM = 1,
}

var _kind: int = 0
var _reward_id: StringName = &""
var _initialized: bool = false


func _init() -> void:
	pass


static func claim(reward_id: StringName) -> PermanentGrowthClaimCommand:
	var command := new()
	command._kind = Kind.CLAIM
	command._reward_id = reward_id
	command._initialized = true
	return command


# 奖励 ID 是否存在于注册表由领取内核解析；命令自身的有效性只覆盖构造合同。
func is_valid() -> bool:
	return (
		_initialized
		and _kind == Kind.CLAIM
		and not String(_reward_id).is_empty()
	)


func kind() -> int:
	return _kind


func reward_id() -> StringName:
	return _reward_id


func copy() -> PermanentGrowthClaimCommand:
	var copied_command := new()
	copied_command._kind = _kind
	copied_command._reward_id = _reward_id
	copied_command._initialized = _initialized
	return copied_command
