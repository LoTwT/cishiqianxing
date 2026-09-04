class_name ContactCombatCommand
extends RefCounted

enum Kind {
	EVALUATE = 1,
}

enum Side {
	PLAYER = 1,
	OPPONENT = 2,
}

enum TemporaryEffect {
	NONE = 0,
	ATTACK_2 = 1,
	DEFENSE_2 = 2,
	SPEED_2 = 3,
	ATTACK_SPEED_2 = 4,
	ATTACK_DEFENSE_2 = 5,
}

var _kind: int = 0
var _initiator_side: int = 0
var _temporary_effect: int = TemporaryEffect.NONE
var _supporting_opponents_alive: int = 0
var _initialized: bool = false


func _init() -> void:
	pass


static func evaluate(
	initiator_side: int,
	temporary_effect: int = TemporaryEffect.NONE,
	supporting_opponents_alive: int = 0,
) -> ContactCombatCommand:
	var command := new()
	command._kind = Kind.EVALUATE
	command._initiator_side = initiator_side
	command._temporary_effect = temporary_effect
	command._supporting_opponents_alive = supporting_opponents_alive
	command._initialized = true
	return command


func copy() -> ContactCombatCommand:
	var copied_command := new()
	copied_command._kind = _kind
	copied_command._initiator_side = _initiator_side
	copied_command._temporary_effect = _temporary_effect
	copied_command._supporting_opponents_alive = _supporting_opponents_alive
	copied_command._initialized = _initialized
	return copied_command


func kind() -> int:
	return _kind


func initiator_side() -> int:
	return _initiator_side


func temporary_effect() -> int:
	return _temporary_effect


func supporting_opponents_alive() -> int:
	return _supporting_opponents_alive


func is_valid() -> bool:
	return (
		_initialized
		and _kind == Kind.EVALUATE
		and (_initiator_side == Side.PLAYER or _initiator_side == Side.OPPONENT)
		and not temporary_effect_bonuses(_temporary_effect).is_empty()
		and _supporting_opponents_alive >= 0
		and _supporting_opponents_alive <= 2
	)


static func temporary_effect_bonuses(temporary_effect: int) -> Array[int]:
	match temporary_effect:
		TemporaryEffect.NONE:
			return [0, 0, 0]
		TemporaryEffect.ATTACK_2:
			return [2, 0, 0]
		TemporaryEffect.DEFENSE_2:
			return [0, 2, 0]
		TemporaryEffect.SPEED_2:
			return [0, 0, 2]
		TemporaryEffect.ATTACK_SPEED_2:
			return [2, 0, 2]
		TemporaryEffect.ATTACK_DEFENSE_2:
			return [2, 2, 0]
	return []
