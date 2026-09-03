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


func _init(
	kind: int,
	initiator_side: int,
	temporary_effect: int,
	supporting_opponents_alive: int,
) -> void:
	_kind = kind
	_initiator_side = initiator_side
	_temporary_effect = temporary_effect
	_supporting_opponents_alive = supporting_opponents_alive


static func evaluate(
	initiator_side: int,
	temporary_effect: int = TemporaryEffect.NONE,
	supporting_opponents_alive: int = 0,
) -> ContactCombatCommand:
	return new(
		Kind.EVALUATE,
		initiator_side,
		temporary_effect,
		supporting_opponents_alive,
	)


func copy() -> ContactCombatCommand:
	return new(
		_kind,
		_initiator_side,
		_temporary_effect,
		_supporting_opponents_alive,
	)


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
		_kind == Kind.EVALUATE
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
