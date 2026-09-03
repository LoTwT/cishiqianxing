class_name ContactCombatKernel
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatEventScript := preload(
	"res://src/rules/contact_combat_event.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const PermanentGrowthClaimKernelScript := preload(
	"res://src/rules/permanent_growth_claim_kernel.gd"
)
const PlayerProgressionDerivationResultScript := preload(
	"res://src/rules/player_progression_derivation_result.gd"
)
const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const MAX_INT: int = 9_223_372_036_854_775_807


static func evaluate(
	player_state: RefCounted,
	opponent_state: RefCounted,
	command: RefCounted,
	registry: RefCounted,
) -> ContactCombatResultScript:
	var unchanged_player_state: PlayerProgressionStateScript = (
		_copy_exact_player_state(player_state)
	)
	if unchanged_player_state == null or not unchanged_player_state.is_valid():
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE
		)
	if (
		registry == null
		or not is_instance_valid(registry)
		or registry.get_script() != ContentRegistryScript
	):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_REGISTRY,
			unchanged_player_state,
		)
	var derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(
			unchanged_player_state,
			registry,
		)
	)
	if not derivation.succeeded():
		return ContactCombatResultScript.rejected(
			_map_derivation_failure(derivation.failure_reason()),
			unchanged_player_state,
		)
	var player_snapshot: PlayerProgressionSnapshotScript = derivation.snapshot()
	if player_snapshot.current_health() == 0:
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.PLAYER_INCAPACITATED,
			unchanged_player_state,
		)

	var unchanged_opponent_state: ContactCombatOpponentStateScript = (
		_copy_exact_opponent_state(opponent_state)
	)
	if (
		unchanged_opponent_state == null
		or not unchanged_opponent_state.is_valid()
	):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_OPPONENT_STATE,
			unchanged_player_state,
		)
	if unchanged_opponent_state.current_durability() == 0:
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.OPPONENT_INACTIVE,
			unchanged_player_state,
			unchanged_opponent_state,
		)

	var authoritative_command: ContactCombatCommandScript = (
		_copy_exact_command(command)
	)
	if authoritative_command == null:
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_COMMAND,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	if authoritative_command.kind() != ContactCombatCommandScript.Kind.EVALUATE:
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_COMMAND,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	if not _is_side(authoritative_command.initiator_side()):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_INITIATOR,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	var effect_bonuses: Array[int] = ContactCombatCommandScript.temporary_effect_bonuses(
		authoritative_command.temporary_effect()
	)
	if effect_bonuses.is_empty():
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_TEMPORARY_EFFECT,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	if (
		authoritative_command.supporting_opponents_alive() < 0
		or authoritative_command.supporting_opponents_alive() > 2
	):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INVALID_SUPPORT_COUNT,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	if (
		_would_add_overflow(player_snapshot.attack(), effect_bonuses[0])
		or _would_add_overflow(player_snapshot.defense(), effect_bonuses[1])
		or _would_add_overflow(player_snapshot.speed(), effect_bonuses[2])
		or _would_add_overflow(
			unchanged_opponent_state.attack(),
			authoritative_command.supporting_opponents_alive(),
		)
	):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INTEGER_OVERFLOW,
			unchanged_player_state,
			unchanged_opponent_state,
		)

	var effective_player_attack: int = player_snapshot.attack() + effect_bonuses[0]
	var effective_player_defense: int = player_snapshot.defense() + effect_bonuses[1]
	var effective_player_speed: int = player_snapshot.speed() + effect_bonuses[2]
	var effective_opponent_attack: int = (
		unchanged_opponent_state.attack()
		+ authoritative_command.supporting_opponents_alive()
	)
	var player_damage: int = max(
		effective_player_attack - unchanged_opponent_state.defense(),
		0,
	)
	var opponent_damage: int = max(
		effective_opponent_attack - effective_player_defense,
		0,
	)
	var first_attacker_side: int = _first_attacker_side(
		effective_player_speed,
		unchanged_opponent_state.speed(),
		authoritative_command.initiator_side(),
	)

	if player_damage == 0:
		var blocked_resolution := ContactCombatResolutionScript.new(
			player_snapshot.profile_id(),
			player_snapshot.content_schema_version(),
			player_snapshot.content_version(),
			unchanged_opponent_state.opponent_instance_id(),
			authoritative_command.initiator_side(),
			first_attacker_side,
			authoritative_command.temporary_effect(),
			false,
			authoritative_command.supporting_opponents_alive(),
			authoritative_command.supporting_opponents_alive(),
			effective_player_attack,
			effective_player_defense,
			effective_player_speed,
			effective_opponent_attack,
			unchanged_opponent_state.defense(),
			unchanged_opponent_state.speed(),
			player_damage,
			opponent_damage,
			false,
			0,
			0,
			0,
			player_snapshot.current_health(),
			player_snapshot.current_health(),
			unchanged_opponent_state.current_durability(),
			unchanged_opponent_state.current_durability(),
			unchanged_opponent_state.shield_intact(),
			false,
			unchanged_opponent_state.shield_intact(),
			false,
			ContactCombatResolutionScript.Outcome.NONE,
			ContactCombatResolutionScript.BlockReason.PLAYER_DAMAGE_ZERO,
		)
		return ContactCombatResultScript.blocked(
			unchanged_player_state,
			player_snapshot,
			unchanged_opponent_state,
			authoritative_command,
			blocked_resolution,
			registry,
		)

	var damaging_player_attacks_required: int = _ceil_positive(
		unchanged_opponent_state.current_durability(),
		player_damage,
	)
	if (
		unchanged_opponent_state.shield_intact()
		and damaging_player_attacks_required == MAX_INT
	):
		return ContactCombatResultScript.rejected(
			ContactCombatResultScript.RejectionReason.INTEGER_OVERFLOW,
			unchanged_player_state,
			unchanged_opponent_state,
		)
	var player_attacks_required: int = damaging_player_attacks_required
	if unchanged_opponent_state.shield_intact():
		player_attacks_required += 1

	var player_attacks_executed: int
	var opponent_attacks_executed: int
	var outcome: int
	if opponent_damage == 0:
		player_attacks_executed = player_attacks_required
		outcome = ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED
		if first_attacker_side == ContactCombatCommandScript.Side.PLAYER:
			opponent_attacks_executed = player_attacks_required - 1
		else:
			opponent_attacks_executed = player_attacks_required
	else:
		var opponent_attacks_required: int = _ceil_positive(
			player_snapshot.current_health(),
			opponent_damage,
		)
		if first_attacker_side == ContactCombatCommandScript.Side.PLAYER:
			if player_attacks_required <= opponent_attacks_required:
				player_attacks_executed = player_attacks_required
				opponent_attacks_executed = player_attacks_required - 1
				outcome = ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED
			else:
				player_attacks_executed = opponent_attacks_required
				opponent_attacks_executed = opponent_attacks_required
				outcome = ContactCombatResolutionScript.Outcome.PLAYER_INCAPACITATED
		else:
			if player_attacks_required < opponent_attacks_required:
				player_attacks_executed = player_attacks_required
				opponent_attacks_executed = player_attacks_required
				outcome = ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED
			else:
				player_attacks_executed = opponent_attacks_required - 1
				opponent_attacks_executed = opponent_attacks_required
				outcome = ContactCombatResolutionScript.Outcome.PLAYER_INCAPACITATED

	var shield_absorbed_attack: bool = (
		unchanged_opponent_state.shield_intact()
		and player_attacks_executed > 0
	)
	var damaging_player_attacks: int = player_attacks_executed
	if shield_absorbed_attack:
		damaging_player_attacks -= 1
	var next_player_health: int = 0
	if outcome == ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED:
		next_player_health = _remaining_after_attacks(
			player_snapshot.current_health(),
			opponent_damage,
			opponent_attacks_executed,
		)
	var next_opponent_durability: int = 0
	if outcome == ContactCombatResolutionScript.Outcome.PLAYER_INCAPACITATED:
		next_opponent_durability = _remaining_after_attacks(
			unchanged_opponent_state.current_durability(),
			player_damage,
			damaging_player_attacks,
		)

	var next_player_state: PlayerProgressionStateScript = (
		PlayerProgressionStateScript.create(
			unchanged_player_state.profile_id(),
			unchanged_player_state.content_schema_version(),
			unchanged_player_state.content_version(),
			next_player_health,
			unchanged_player_state.claimed_reward_ids(),
		)
	)
	var next_derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(
			next_player_state,
			registry,
		)
	)
	if not next_derivation.succeeded():
		return ContactCombatResultScript.rejected(
			_map_derivation_failure(next_derivation.failure_reason()),
			unchanged_player_state,
			unchanged_opponent_state,
		)
	var next_player_snapshot: PlayerProgressionSnapshotScript = (
		next_derivation.snapshot()
	)
	var next_opponent_state: ContactCombatOpponentStateScript = (
		ContactCombatOpponentStateScript.create(
			unchanged_opponent_state.opponent_instance_id(),
			unchanged_opponent_state.maximum_durability(),
			next_opponent_durability,
			unchanged_opponent_state.attack(),
			unchanged_opponent_state.defense(),
			unchanged_opponent_state.speed(),
			(
				unchanged_opponent_state.shield_intact()
				and not shield_absorbed_attack
			),
		)
	)
	var resolution := ContactCombatResolutionScript.new(
		player_snapshot.profile_id(),
		player_snapshot.content_schema_version(),
		player_snapshot.content_version(),
		unchanged_opponent_state.opponent_instance_id(),
		authoritative_command.initiator_side(),
		first_attacker_side,
		authoritative_command.temporary_effect(),
		(
			authoritative_command.temporary_effect()
			!= ContactCombatCommandScript.TemporaryEffect.NONE
		),
		authoritative_command.supporting_opponents_alive(),
		authoritative_command.supporting_opponents_alive(),
		effective_player_attack,
		effective_player_defense,
		effective_player_speed,
		effective_opponent_attack,
		unchanged_opponent_state.defense(),
		unchanged_opponent_state.speed(),
		player_damage,
		opponent_damage,
		true,
		player_attacks_required,
		player_attacks_executed,
		opponent_attacks_executed,
		player_snapshot.current_health(),
		next_player_health,
		unchanged_opponent_state.current_durability(),
		next_opponent_durability,
		unchanged_opponent_state.shield_intact(),
		shield_absorbed_attack,
		next_opponent_state.shield_intact(),
		true,
		outcome,
		ContactCombatResolutionScript.BlockReason.NONE,
	)
	var domain_event: ContactCombatEventScript = (
		ContactCombatEventScript.contact_resolution_candidate(resolution)
	)
	return ContactCombatResultScript.evaluated(
		unchanged_player_state,
		player_snapshot,
		authoritative_command,
		next_player_state,
		next_player_snapshot,
		unchanged_opponent_state,
		next_opponent_state,
		resolution,
		domain_event,
		registry,
	)


static func _copy_exact_player_state(
	state: RefCounted,
) -> PlayerProgressionStateScript:
	if (
		state == null
		or not is_instance_valid(state)
		or state.get_script() != PlayerProgressionStateScript
	):
		return null
	return (state as PlayerProgressionStateScript).copy()


static func _copy_exact_opponent_state(
	state: RefCounted,
) -> ContactCombatOpponentStateScript:
	if (
		state == null
		or not is_instance_valid(state)
		or state.get_script() != ContactCombatOpponentStateScript
	):
		return null
	return (state as ContactCombatOpponentStateScript).copy()


static func _copy_exact_command(command: RefCounted) -> ContactCombatCommandScript:
	if (
		command == null
		or not is_instance_valid(command)
		or command.get_script() != ContactCombatCommandScript
	):
		return null
	return (command as ContactCombatCommandScript).copy()


static func _first_attacker_side(
	player_speed: int,
	opponent_speed: int,
	initiator_side: int,
) -> int:
	if player_speed > opponent_speed:
		return ContactCombatCommandScript.Side.PLAYER
	if opponent_speed > player_speed:
		return ContactCombatCommandScript.Side.OPPONENT
	return initiator_side


static func _ceil_positive(value: int, divisor: int) -> int:
	@warning_ignore("integer_division")
	var quotient: int = (value - 1) / divisor
	return quotient + 1


static func _remaining_after_attacks(
	starting_value: int,
	damage: int,
	attack_count: int,
) -> int:
	if damage == 0 or attack_count == 0:
		return starting_value
	var attacks_to_zero: int = _ceil_positive(starting_value, damage)
	if attack_count >= attacks_to_zero:
		return 0
	return starting_value - damage * attack_count


static func _would_add_overflow(left: int, right: int) -> bool:
	return right > 0 and left > MAX_INT - right


static func _is_side(value: int) -> bool:
	return (
		value == ContactCombatCommandScript.Side.PLAYER
		or value == ContactCombatCommandScript.Side.OPPONENT
	)


static func _map_derivation_failure(failure_reason: int) -> int:
	match failure_reason:
		PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE:
			return ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE
		PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY:
			return ContactCombatResultScript.RejectionReason.INVALID_REGISTRY
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.CONTENT_SCHEMA_VERSION_MISMATCH
		):
			return (
				ContactCombatResultScript
				.RejectionReason
				.CONTENT_SCHEMA_VERSION_MISMATCH
			)
		PlayerProgressionDerivationResultScript.FailureReason.CONTENT_VERSION_MISMATCH:
			return ContactCombatResultScript.RejectionReason.CONTENT_VERSION_MISMATCH
		PlayerProgressionDerivationResultScript.FailureReason.PROFILE_ID_MISMATCH:
			return ContactCombatResultScript.RejectionReason.PROFILE_ID_MISMATCH
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.UNKNOWN_CLAIMED_REWARD_ID
		):
			return ContactCombatResultScript.RejectionReason.UNKNOWN_CLAIMED_REWARD_ID
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.INVALID_REWARD_DEFINITION
		):
			return ContactCombatResultScript.RejectionReason.INVALID_REWARD_DEFINITION
		PlayerProgressionDerivationResultScript.FailureReason.INTEGER_OVERFLOW:
			return ContactCombatResultScript.RejectionReason.INTEGER_OVERFLOW
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.CURRENT_HEALTH_OUT_OF_RANGE
		):
			return ContactCombatResultScript.RejectionReason.CURRENT_HEALTH_OUT_OF_RANGE
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.INVALID_INITIAL_PLAYER_STATS
		):
			return ContactCombatResultScript.RejectionReason.INVALID_INITIAL_PLAYER_STATS
	return ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE
