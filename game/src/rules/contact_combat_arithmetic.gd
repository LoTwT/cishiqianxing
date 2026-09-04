class_name ContactCombatArithmetic
extends RefCounted

# 接触战候选评价与结果自校验共用的唯一战斗数学实现。此前 kernel 与
# resolution 各持一份且已在 _ceil_positive 的入参守卫上发生行为分歧
# （kernel 版 ceil(0, d) == 1，resolution 版 == 0），本模块以带守卫的
# 数学正确版为准；双方输入均经上游校验排除非正值，统一后行为等价。

const ContactCombatCommandScript := preload("res://src/rules/contact_combat_command.gd")


static func first_attacker_side(
	player_speed: int,
	opponent_speed: int,
	initiator_side: int,
) -> int:
	if player_speed > opponent_speed:
		return ContactCombatCommandScript.Side.PLAYER
	if opponent_speed > player_speed:
		return ContactCombatCommandScript.Side.OPPONENT
	return initiator_side


static func ceil_positive(value: int, divisor: int) -> int:
	if value <= 0 or divisor <= 0:
		return 0
	@warning_ignore("integer_division")
	var quotient: int = (value - 1) / divisor
	return quotient + 1


static func remaining_after_attacks(
	starting_value: int,
	damage: int,
	attack_count: int,
) -> int:
	if damage == 0 or attack_count == 0:
		return starting_value
	var attacks_to_zero: int = ceil_positive(starting_value, damage)
	if attack_count >= attacks_to_zero:
		return 0
	return starting_value - damage * attack_count


static func is_side(value: int) -> bool:
	return (
		value == ContactCombatCommandScript.Side.PLAYER
		or value == ContactCombatCommandScript.Side.OPPONENT
	)
