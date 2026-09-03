extends RefCounted

const STATUS_EVALUATED: int = 1
const STATUS_BLOCKED: int = 2
const REJECTION_NONE: int = 0
const REJECTION_PLAYER_DAMAGE_ZERO: int = 18

const SIDE_PLAYER: int = 1
const SIDE_OPPONENT: int = 2

const EFFECT_NONE: int = 0
const EFFECT_ATTACK_2: int = 1
const EFFECT_DEFENSE_2: int = 2
const EFFECT_SPEED_2: int = 3
const EFFECT_ATTACK_SPEED_2: int = 4
const EFFECT_ATTACK_DEFENSE_2: int = 5

const OUTCOME_NONE: int = 0
const OUTCOME_OPPONENT_CLEARED: int = 1
const OUTCOME_PLAYER_INCAPACITATED: int = 2

const BLOCK_NONE: int = 0
const BLOCK_PLAYER_DAMAGE_ZERO: int = 1


class CombatProjection extends RefCounted:
	var status: int = 0
	var rejection_reason: int = 0
	var initiator_side: int = 0
	var first_attacker_side: int = 0
	var temporary_effect: int = 0
	var temporary_effect_should_be_consumed: bool = false
	var supporting_opponents_alive: int = 0
	var support_attack_bonus: int = 0
	var effective_player_attack: int = 0
	var effective_player_defense: int = 0
	var effective_player_speed: int = 0
	var effective_opponent_attack: int = 0
	var effective_opponent_defense: int = 0
	var effective_opponent_speed: int = 0
	var player_damage_per_attack: int = 0
	var opponent_damage_per_attack: int = 0
	var has_finite_player_attack_requirement: bool = false
	var player_attacks_required_to_clear: int = 0
	var player_attacks_executed: int = 0
	var opponent_attacks_executed: int = 0
	var previous_player_health: int = 0
	var next_player_health: int = 0
	var previous_opponent_durability: int = 0
	var next_opponent_durability: int = 0
	var opponent_shield_intact_before: bool = false
	var opponent_shield_absorbed_attack: bool = false
	var opponent_shield_intact_after: bool = false
	var is_resolution_candidate: bool = false
	var outcome: int = 0
	var block_reason: int = 0
	var event_count: int = 0

	func encode() -> Array:
		return [
			status,
			rejection_reason,
			initiator_side,
			first_attacker_side,
			temporary_effect,
			temporary_effect_should_be_consumed,
			supporting_opponents_alive,
			support_attack_bonus,
			effective_player_attack,
			effective_player_defense,
			effective_player_speed,
			effective_opponent_attack,
			effective_opponent_defense,
			effective_opponent_speed,
			player_damage_per_attack,
			opponent_damage_per_attack,
			has_finite_player_attack_requirement,
			player_attacks_required_to_clear,
			player_attacks_executed,
			opponent_attacks_executed,
			previous_player_health,
			next_player_health,
			previous_opponent_durability,
			next_opponent_durability,
			opponent_shield_intact_before,
			opponent_shield_absorbed_attack,
			opponent_shield_intact_after,
			is_resolution_candidate,
			outcome,
			block_reason,
			event_count,
		]


static func effect_rows() -> Array[Array]:
	return [
		[EFFECT_NONE, 0, 0, 0],
		[EFFECT_ATTACK_2, 2, 0, 0],
		[EFFECT_DEFENSE_2, 0, 2, 0],
		[EFFECT_SPEED_2, 0, 0, 2],
		[EFFECT_ATTACK_SPEED_2, 2, 0, 2],
		[EFFECT_ATTACK_DEFENSE_2, 2, 2, 0],
	]


static func effect_bonuses(effect: int) -> Array[int]:
	for row: Array in effect_rows():
		if row[0] == effect:
			return [row[1], row[2], row[3]]
	return []


static func evaluate(
	player_health: int,
	player_attack: int,
	player_defense: int,
	player_speed: int,
	opponent_durability: int,
	opponent_attack: int,
	opponent_defense: int,
	opponent_speed: int,
	initiator_side: int,
	temporary_effect: int,
	supporting_opponents_alive: int,
	opponent_shield_intact: bool,
) -> CombatProjection:
	var projection := CombatProjection.new()
	var bonuses: Array[int] = effect_bonuses(temporary_effect)
	if bonuses.is_empty():
		return projection
	if supporting_opponents_alive < 0 or supporting_opponents_alive > 2:
		return projection
	projection.initiator_side = initiator_side
	projection.temporary_effect = temporary_effect
	projection.supporting_opponents_alive = supporting_opponents_alive
	projection.support_attack_bonus = supporting_opponents_alive
	projection.effective_player_attack = player_attack + bonuses[0]
	projection.effective_player_defense = player_defense + bonuses[1]
	projection.effective_player_speed = player_speed + bonuses[2]
	projection.effective_opponent_attack = (
		opponent_attack + supporting_opponents_alive
	)
	projection.effective_opponent_defense = opponent_defense
	projection.effective_opponent_speed = opponent_speed
	projection.player_damage_per_attack = max(
		projection.effective_player_attack - opponent_defense,
		0,
	)
	projection.opponent_damage_per_attack = max(
		projection.effective_opponent_attack - projection.effective_player_defense,
		0,
	)
	projection.first_attacker_side = _first_attacker(
		projection.effective_player_speed,
		opponent_speed,
		initiator_side,
	)
	projection.previous_player_health = player_health
	projection.next_player_health = player_health
	projection.previous_opponent_durability = opponent_durability
	projection.next_opponent_durability = opponent_durability
	projection.opponent_shield_intact_before = opponent_shield_intact
	projection.opponent_shield_intact_after = opponent_shield_intact

	if projection.player_damage_per_attack == 0:
		projection.status = STATUS_BLOCKED
		projection.rejection_reason = REJECTION_PLAYER_DAMAGE_ZERO
		projection.block_reason = BLOCK_PLAYER_DAMAGE_ZERO
		return projection

	projection.has_finite_player_attack_requirement = true
	projection.player_attacks_required_to_clear = _required_player_attacks(
		opponent_durability,
		projection.player_damage_per_attack,
		opponent_shield_intact,
	)
	var player_turn: bool = projection.first_attacker_side == SIDE_PLAYER
	while (
		projection.next_player_health > 0
		and projection.next_opponent_durability > 0
	):
		if player_turn:
			projection.player_attacks_executed += 1
			if projection.opponent_shield_intact_after:
				projection.opponent_shield_absorbed_attack = true
				projection.opponent_shield_intact_after = false
			else:
				projection.next_opponent_durability = max(
					projection.next_opponent_durability
					- projection.player_damage_per_attack,
					0,
				)
		else:
			projection.opponent_attacks_executed += 1
			projection.next_player_health = max(
				projection.next_player_health
				- projection.opponent_damage_per_attack,
				0,
			)
		player_turn = not player_turn

	projection.status = STATUS_EVALUATED
	projection.rejection_reason = REJECTION_NONE
	projection.temporary_effect_should_be_consumed = (
		temporary_effect != EFFECT_NONE
	)
	projection.is_resolution_candidate = true
	projection.event_count = 1
	if projection.next_opponent_durability == 0:
		projection.outcome = OUTCOME_OPPONENT_CLEARED
	else:
		projection.outcome = OUTCOME_PLAYER_INCAPACITATED
	return projection


static func _first_attacker(
	player_speed: int,
	opponent_speed: int,
	initiator_side: int,
) -> int:
	if player_speed > opponent_speed:
		return SIDE_PLAYER
	if opponent_speed > player_speed:
		return SIDE_OPPONENT
	return initiator_side


static func _required_player_attacks(
	opponent_durability: int,
	player_damage: int,
	opponent_shield_intact: bool,
) -> int:
	var attacks: int = 0
	var remaining: int = opponent_durability
	var shield_remaining: bool = opponent_shield_intact
	while remaining > 0:
		attacks += 1
		if shield_remaining:
			shield_remaining = false
		else:
			remaining = max(remaining - player_damage, 0)
	return attacks
