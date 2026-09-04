class_name ContactCombatResolution
extends RefCounted

const ContactCombatArithmeticScript := preload(
	"res://src/rules/contact_combat_arithmetic.gd"
)
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum Outcome {
	NONE = 0,
	OPPONENT_CLEARED = 1,
	PLAYER_INCAPACITATED = 2,
}

enum BlockReason {
	NONE = 0,
	PLAYER_DAMAGE_ZERO = 1,
}

var _player_profile_id: StringName
var _content_schema_version: int
var _content_version: int
var _opponent_instance_id: StringName
var _initiator_side: int
var _first_attacker_side: int
var _temporary_effect: int
var _temporary_effect_should_be_consumed: bool
var _supporting_opponents_alive: int
var _support_attack_bonus: int
var _effective_player_attack: int
var _effective_player_defense: int
var _effective_player_speed: int
var _effective_opponent_attack: int
var _effective_opponent_defense: int
var _effective_opponent_speed: int
var _player_damage_per_attack: int
var _opponent_damage_per_attack: int
var _has_finite_player_attack_requirement: bool
var _player_attacks_required_to_clear: int
var _player_attacks_executed: int
var _opponent_attacks_executed: int
var _previous_player_health: int
var _next_player_health: int
var _previous_opponent_durability: int
var _next_opponent_durability: int
var _opponent_shield_intact_before: bool
var _opponent_shield_absorbed_attack: bool
var _opponent_shield_intact_after: bool
var _is_resolution_candidate: bool
var _outcome: int
var _block_reason: int


func _init(
	player_profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	opponent_instance_id: StringName,
	initiator_side: int,
	first_attacker_side: int,
	temporary_effect: int,
	temporary_effect_should_be_consumed: bool,
	supporting_opponents_alive: int,
	support_attack_bonus: int,
	effective_player_attack: int,
	effective_player_defense: int,
	effective_player_speed: int,
	effective_opponent_attack: int,
	effective_opponent_defense: int,
	effective_opponent_speed: int,
	player_damage_per_attack: int,
	opponent_damage_per_attack: int,
	has_finite_player_attack_requirement: bool,
	player_attacks_required_to_clear: int,
	player_attacks_executed: int,
	opponent_attacks_executed: int,
	previous_player_health: int,
	next_player_health: int,
	previous_opponent_durability: int,
	next_opponent_durability: int,
	opponent_shield_intact_before: bool,
	opponent_shield_absorbed_attack: bool,
	opponent_shield_intact_after: bool,
	is_resolution_candidate: bool,
	outcome: int,
	block_reason: int,
) -> void:
	_player_profile_id = player_profile_id
	_content_schema_version = content_schema_version
	_content_version = content_version
	_opponent_instance_id = opponent_instance_id
	_initiator_side = initiator_side
	_first_attacker_side = first_attacker_side
	_temporary_effect = temporary_effect
	_temporary_effect_should_be_consumed = temporary_effect_should_be_consumed
	_supporting_opponents_alive = supporting_opponents_alive
	_support_attack_bonus = support_attack_bonus
	_effective_player_attack = effective_player_attack
	_effective_player_defense = effective_player_defense
	_effective_player_speed = effective_player_speed
	_effective_opponent_attack = effective_opponent_attack
	_effective_opponent_defense = effective_opponent_defense
	_effective_opponent_speed = effective_opponent_speed
	_player_damage_per_attack = player_damage_per_attack
	_opponent_damage_per_attack = opponent_damage_per_attack
	_has_finite_player_attack_requirement = has_finite_player_attack_requirement
	_player_attacks_required_to_clear = player_attacks_required_to_clear
	_player_attacks_executed = player_attacks_executed
	_opponent_attacks_executed = opponent_attacks_executed
	_previous_player_health = previous_player_health
	_next_player_health = next_player_health
	_previous_opponent_durability = previous_opponent_durability
	_next_opponent_durability = next_opponent_durability
	_opponent_shield_intact_before = opponent_shield_intact_before
	_opponent_shield_absorbed_attack = opponent_shield_absorbed_attack
	_opponent_shield_intact_after = opponent_shield_intact_after
	_is_resolution_candidate = is_resolution_candidate
	_outcome = outcome
	_block_reason = block_reason


func copy() -> ContactCombatResolution:
	return new(
		_player_profile_id,
		_content_schema_version,
		_content_version,
		_opponent_instance_id,
		_initiator_side,
		_first_attacker_side,
		_temporary_effect,
		_temporary_effect_should_be_consumed,
		_supporting_opponents_alive,
		_support_attack_bonus,
		_effective_player_attack,
		_effective_player_defense,
		_effective_player_speed,
		_effective_opponent_attack,
		_effective_opponent_defense,
		_effective_opponent_speed,
		_player_damage_per_attack,
		_opponent_damage_per_attack,
		_has_finite_player_attack_requirement,
		_player_attacks_required_to_clear,
		_player_attacks_executed,
		_opponent_attacks_executed,
		_previous_player_health,
		_next_player_health,
		_previous_opponent_durability,
		_next_opponent_durability,
		_opponent_shield_intact_before,
		_opponent_shield_absorbed_attack,
		_opponent_shield_intact_after,
		_is_resolution_candidate,
		_outcome,
		_block_reason,
	)


func is_valid() -> bool:
	if not _common_fields_are_valid():
		return false
	if _is_resolution_candidate:
		return _candidate_fields_are_valid()
	return _blocked_fields_are_valid()


func player_profile_id() -> StringName:
	return _player_profile_id


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func opponent_instance_id() -> StringName:
	return _opponent_instance_id


func initiator_side() -> int:
	return _initiator_side


func first_attacker_side() -> int:
	return _first_attacker_side


func temporary_effect() -> int:
	return _temporary_effect


func temporary_effect_should_be_consumed() -> bool:
	return _temporary_effect_should_be_consumed


func supporting_opponents_alive() -> int:
	return _supporting_opponents_alive


func support_attack_bonus() -> int:
	return _support_attack_bonus


func effective_player_attack() -> int:
	return _effective_player_attack


func effective_player_defense() -> int:
	return _effective_player_defense


func effective_player_speed() -> int:
	return _effective_player_speed


func effective_opponent_attack() -> int:
	return _effective_opponent_attack


func effective_opponent_defense() -> int:
	return _effective_opponent_defense


func effective_opponent_speed() -> int:
	return _effective_opponent_speed


func player_damage_per_attack() -> int:
	return _player_damage_per_attack


func opponent_damage_per_attack() -> int:
	return _opponent_damage_per_attack


func has_finite_player_attack_requirement() -> bool:
	return _has_finite_player_attack_requirement


func player_attacks_required_to_clear() -> int:
	return _player_attacks_required_to_clear


func player_attacks_executed() -> int:
	return _player_attacks_executed


func opponent_attacks_executed() -> int:
	return _opponent_attacks_executed


func previous_player_health() -> int:
	return _previous_player_health


func next_player_health() -> int:
	return _next_player_health


func player_health_loss() -> int:
	return _previous_player_health - _next_player_health


func previous_opponent_durability() -> int:
	return _previous_opponent_durability


func next_opponent_durability() -> int:
	return _next_opponent_durability


func opponent_shield_intact_before() -> bool:
	return _opponent_shield_intact_before


func opponent_shield_absorbed_attack() -> bool:
	return _opponent_shield_absorbed_attack


func opponent_shield_intact_after() -> bool:
	return _opponent_shield_intact_after


func is_resolution_candidate() -> bool:
	return _is_resolution_candidate and is_valid()


func is_commit_boundary() -> bool:
	return false


func outcome() -> int:
	return _outcome if is_valid() else Outcome.NONE


func block_reason() -> int:
	return _block_reason if is_valid() else BlockReason.NONE


func is_equal_to(other: ContactCombatResolution) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other._player_profile_id == _player_profile_id
		and other._content_schema_version == _content_schema_version
		and other._content_version == _content_version
		and other._opponent_instance_id == _opponent_instance_id
		and other._initiator_side == _initiator_side
		and other._first_attacker_side == _first_attacker_side
		and other._temporary_effect == _temporary_effect
		and (
			other._temporary_effect_should_be_consumed
			== _temporary_effect_should_be_consumed
		)
		and other._supporting_opponents_alive == _supporting_opponents_alive
		and other._support_attack_bonus == _support_attack_bonus
		and other._effective_player_attack == _effective_player_attack
		and other._effective_player_defense == _effective_player_defense
		and other._effective_player_speed == _effective_player_speed
		and other._effective_opponent_attack == _effective_opponent_attack
		and other._effective_opponent_defense == _effective_opponent_defense
		and other._effective_opponent_speed == _effective_opponent_speed
		and other._player_damage_per_attack == _player_damage_per_attack
		and other._opponent_damage_per_attack == _opponent_damage_per_attack
		and (
			other._has_finite_player_attack_requirement
			== _has_finite_player_attack_requirement
		)
		and (
			other._player_attacks_required_to_clear
			== _player_attacks_required_to_clear
		)
		and other._player_attacks_executed == _player_attacks_executed
		and other._opponent_attacks_executed == _opponent_attacks_executed
		and other._previous_player_health == _previous_player_health
		and other._next_player_health == _next_player_health
		and (
			other._previous_opponent_durability
			== _previous_opponent_durability
		)
		and other._next_opponent_durability == _next_opponent_durability
		and (
			other._opponent_shield_intact_before
			== _opponent_shield_intact_before
		)
		and (
			other._opponent_shield_absorbed_attack
			== _opponent_shield_absorbed_attack
		)
		and (
			other._opponent_shield_intact_after
			== _opponent_shield_intact_after
		)
		and other._is_resolution_candidate == _is_resolution_candidate
		and other._outcome == _outcome
		and other._block_reason == _block_reason
	)


func _common_fields_are_valid() -> bool:
	return (
		not String(_player_profile_id).is_empty()
		and _content_schema_version > 0
		and _content_version > 0
		and not String(_opponent_instance_id).is_empty()
		and ContactCombatArithmeticScript.is_side(_initiator_side)
		and ContactCombatArithmeticScript.is_side(_first_attacker_side)
		and _is_temporary_effect(_temporary_effect)
		and _supporting_opponents_alive >= 0
		and _supporting_opponents_alive <= 2
		and _support_attack_bonus == _supporting_opponents_alive
		and _effective_player_attack > 0
		and _effective_player_defense > 0
		and _effective_player_speed > 0
		and _effective_opponent_attack > 0
		and _effective_opponent_defense > 0
		and _effective_opponent_speed > 0
		and _player_damage_per_attack == max(
			_effective_player_attack - _effective_opponent_defense,
			0,
		)
		and _opponent_damage_per_attack == max(
			_effective_opponent_attack - _effective_player_defense,
			0,
		)
		and _first_attacker_side == _expected_first_attacker()
		and _previous_player_health > 0
		and _next_player_health >= 0
		and _next_player_health <= _previous_player_health
		and _previous_opponent_durability > 0
		and _next_opponent_durability >= 0
		and _next_opponent_durability <= _previous_opponent_durability
		and _player_attacks_required_to_clear >= 0
		and _player_attacks_executed >= 0
		and _opponent_attacks_executed >= 0
	)


func _candidate_fields_are_valid() -> bool:
	if (
		_block_reason != BlockReason.NONE
		or _outcome < Outcome.OPPONENT_CLEARED
		or _outcome > Outcome.PLAYER_INCAPACITATED
		or _player_damage_per_attack <= 0
		or not _has_finite_player_attack_requirement
		or (
			_temporary_effect_should_be_consumed
			!= (
				_temporary_effect
				!= ContactCombatCommandScript.TemporaryEffect.NONE
			)
		)
	):
		return false
	var damaging_attacks_required: int = ContactCombatArithmeticScript.ceil_positive(
		_previous_opponent_durability,
		_player_damage_per_attack,
	)
	if (
		damaging_attacks_required <= 0
		or (
			_opponent_shield_intact_before
			and damaging_attacks_required == ValidationSupportScript.MAX_INT
		)
	):
		return false
	var expected_player_attacks_required: int = damaging_attacks_required
	if _opponent_shield_intact_before:
		expected_player_attacks_required += 1
	if _player_attacks_required_to_clear != expected_player_attacks_required:
		return false
	var expected_counts: Array[int] = _expected_executed_counts(
		expected_player_attacks_required
	)
	if expected_counts.is_empty():
		return false
	if (
		_player_attacks_executed != expected_counts[0]
		or _opponent_attacks_executed != expected_counts[1]
		or _outcome != expected_counts[2]
	):
		return false
	var expected_shield_absorption: bool = (
		_opponent_shield_intact_before and _player_attacks_executed > 0
	)
	if (
		_opponent_shield_absorbed_attack != expected_shield_absorption
		or (
			_opponent_shield_intact_after
			!= (
				_opponent_shield_intact_before
				and not expected_shield_absorption
			)
		)
	):
		return false
	var damaging_player_attacks: int = _player_attacks_executed
	if expected_shield_absorption:
		damaging_player_attacks -= 1
	return (
		_next_player_health
		== ContactCombatArithmeticScript.remaining_after_attacks(
			_previous_player_health,
			_opponent_damage_per_attack,
			_opponent_attacks_executed,
		)
		and _next_opponent_durability
		== ContactCombatArithmeticScript.remaining_after_attacks(
			_previous_opponent_durability,
			_player_damage_per_attack,
			damaging_player_attacks,
		)
		and (
			(
				_outcome == Outcome.OPPONENT_CLEARED
				and _next_opponent_durability == 0
				and _next_player_health > 0
			)
			or (
				_outcome == Outcome.PLAYER_INCAPACITATED
				and _next_player_health == 0
				and _next_opponent_durability > 0
			)
		)
	)


func _blocked_fields_are_valid() -> bool:
	return (
		_block_reason == BlockReason.PLAYER_DAMAGE_ZERO
		and _outcome == Outcome.NONE
		and _player_damage_per_attack == 0
		and not _has_finite_player_attack_requirement
		and _player_attacks_required_to_clear == 0
		and _player_attacks_executed == 0
		and _opponent_attacks_executed == 0
		and _previous_player_health == _next_player_health
		and _previous_opponent_durability == _next_opponent_durability
		and not _temporary_effect_should_be_consumed
		and not _opponent_shield_absorbed_attack
		and (
			_opponent_shield_intact_after
			== _opponent_shield_intact_before
		)
	)


func _expected_first_attacker() -> int:
	return ContactCombatArithmeticScript.first_attacker_side(
		_effective_player_speed,
		_effective_opponent_speed,
		_initiator_side
	)


func _expected_executed_counts(
	player_attacks_required: int,
) -> Array[int]:
	if _opponent_damage_per_attack == 0:
		if _first_attacker_side == ContactCombatCommandScript.Side.PLAYER:
			return [
				player_attacks_required,
				player_attacks_required - 1,
				Outcome.OPPONENT_CLEARED,
			]
		return [
			player_attacks_required,
			player_attacks_required,
			Outcome.OPPONENT_CLEARED,
		]
	var opponent_attacks_required: int = ContactCombatArithmeticScript.ceil_positive(
		_previous_player_health,
		_opponent_damage_per_attack,
	)
	if opponent_attacks_required <= 0:
		return []
	if _first_attacker_side == ContactCombatCommandScript.Side.PLAYER:
		if player_attacks_required <= opponent_attacks_required:
			return [
				player_attacks_required,
				player_attacks_required - 1,
				Outcome.OPPONENT_CLEARED,
			]
		return [
			opponent_attacks_required,
			opponent_attacks_required,
			Outcome.PLAYER_INCAPACITATED,
		]
	if player_attacks_required < opponent_attacks_required:
		return [
			player_attacks_required,
			player_attacks_required,
			Outcome.OPPONENT_CLEARED,
		]
	return [
		opponent_attacks_required - 1,
		opponent_attacks_required,
		Outcome.PLAYER_INCAPACITATED,
	]


func _is_temporary_effect(value: int) -> bool:
	return (
		value >= ContactCombatCommandScript.TemporaryEffect.NONE
		and value <= ContactCombatCommandScript.TemporaryEffect.ATTACK_DEFENSE_2
	)
