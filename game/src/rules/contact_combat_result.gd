class_name ContactCombatResult
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
const ContactCombatPlayerStateCandidateScript := preload(
	"res://src/rules/contact_combat_player_state_candidate.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
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
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum Status {
	EVALUATED = 1,
	BLOCKED = 2,
	REJECTED = 3,
}

enum RejectionReason {
	NONE = 0,
	INVALID_PLAYER_STATE = 1,
	INVALID_REGISTRY = 2,
	CONTENT_SCHEMA_VERSION_MISMATCH = 3,
	CONTENT_VERSION_MISMATCH = 4,
	PROFILE_ID_MISMATCH = 5,
	UNKNOWN_CLAIMED_REWARD_ID = 6,
	INVALID_REWARD_DEFINITION = 7,
	INTEGER_OVERFLOW = 8,
	CURRENT_HEALTH_OUT_OF_RANGE = 9,
	INVALID_INITIAL_PLAYER_STATS = 10,
	PLAYER_INCAPACITATED = 11,
	INVALID_OPPONENT_STATE = 12,
	OPPONENT_INACTIVE = 13,
	INVALID_COMMAND = 14,
	INVALID_INITIATOR = 15,
	INVALID_TEMPORARY_EFFECT = 16,
	INVALID_SUPPORT_COUNT = 17,
	PLAYER_DAMAGE_ZERO = 18,
	INVALID_RESULT = 19,
}

var _status: int
var _rejection_reason: int
var _command: ContactCombatCommandScript
var _previous_player_state: PlayerProgressionStateScript
var _next_player_state: PlayerProgressionStateScript
var _previous_player_snapshot: PlayerProgressionSnapshotScript
var _player_snapshot: PlayerProgressionSnapshotScript
var _previous_opponent_state: ContactCombatOpponentStateScript
var _opponent_state: ContactCombatOpponentStateScript
var _resolution: ContactCombatResolutionScript
var _domain_events: Array[ContactCombatEventScript] = []
var _domain_event_input_matches_status: bool = false
var _registry_derivation_matches_inputs: bool = false


func _init(
	status: int,
	rejection_reason: int,
	command: ContactCombatCommandScript,
	previous_player_state: PlayerProgressionStateScript,
	next_player_state: PlayerProgressionStateScript,
	previous_player_snapshot: PlayerProgressionSnapshotScript,
	player_snapshot: PlayerProgressionSnapshotScript,
	previous_opponent_state: ContactCombatOpponentStateScript,
	opponent_state: ContactCombatOpponentStateScript,
	resolution: ContactCombatResolutionScript,
	domain_events: Array[ContactCombatEventScript],
	registry: RefCounted = null,
) -> void:
	_status = status
	_rejection_reason = rejection_reason
	if (
		command != null
		and is_instance_valid(command)
		and command.get_script() == ContactCombatCommandScript
	):
		_command = command.copy()
	if (
		previous_player_state != null
		and is_instance_valid(previous_player_state)
		and previous_player_state.get_script() == PlayerProgressionStateScript
	):
		_previous_player_state = previous_player_state.copy()
	if (
		next_player_state != null
		and is_instance_valid(next_player_state)
		and next_player_state.get_script() == PlayerProgressionStateScript
	):
		_next_player_state = next_player_state.copy()
	if (
		previous_player_snapshot != null
		and is_instance_valid(previous_player_snapshot)
		and previous_player_snapshot.get_script() == PlayerProgressionSnapshotScript
	):
		_previous_player_snapshot = previous_player_snapshot.copy()
	if (
		player_snapshot != null
		and is_instance_valid(player_snapshot)
		and player_snapshot.get_script() == PlayerProgressionSnapshotScript
	):
		_player_snapshot = player_snapshot.copy()
	if (
		previous_opponent_state != null
		and is_instance_valid(previous_opponent_state)
		and (
			previous_opponent_state.get_script()
			== ContactCombatOpponentStateScript
		)
	):
		_previous_opponent_state = previous_opponent_state.copy()
	if (
		opponent_state != null
		and is_instance_valid(opponent_state)
		and opponent_state.get_script() == ContactCombatOpponentStateScript
	):
		_opponent_state = opponent_state.copy()
	if (
		resolution != null
		and is_instance_valid(resolution)
		and resolution.get_script() == ContactCombatResolutionScript
		and resolution.is_valid()
	):
		_resolution = resolution.copy()
	if _status == Status.EVALUATED and domain_events.size() == 1:
		var domain_event: ContactCombatEventScript = domain_events[0]
		if (
			domain_event != null
			and is_instance_valid(domain_event)
			and domain_event.get_script() == ContactCombatEventScript
			and domain_event.is_valid()
		):
			_domain_events.append(domain_event.copy())
			_domain_event_input_matches_status = true
	elif _status != Status.EVALUATED and domain_events.is_empty():
		_domain_event_input_matches_status = true
	_domain_events.make_read_only()
	_registry_derivation_matches_inputs = _registry_derivation_matches(
		registry
	)


static func evaluated(
	previous_player_state: PlayerProgressionStateScript,
	previous_player_snapshot: PlayerProgressionSnapshotScript,
	command: ContactCombatCommandScript,
	next_player_state: PlayerProgressionStateScript,
	player_snapshot: PlayerProgressionSnapshotScript,
	previous_opponent_state: ContactCombatOpponentStateScript,
	opponent_state: ContactCombatOpponentStateScript,
	resolution: ContactCombatResolutionScript,
	domain_event: ContactCombatEventScript,
	registry: RefCounted,
) -> ContactCombatResult:
	var events: Array[ContactCombatEventScript] = [domain_event]
	return new(
		Status.EVALUATED,
		RejectionReason.NONE,
		command,
		previous_player_state,
		next_player_state,
		previous_player_snapshot,
		player_snapshot,
		previous_opponent_state,
		opponent_state,
		resolution,
		events,
		registry,
	)


static func blocked(
	unchanged_player_state: PlayerProgressionStateScript,
	player_snapshot: PlayerProgressionSnapshotScript,
	unchanged_opponent_state: ContactCombatOpponentStateScript,
	command: ContactCombatCommandScript,
	resolution: ContactCombatResolutionScript,
	registry: RefCounted,
) -> ContactCombatResult:
	var no_events: Array[ContactCombatEventScript] = []
	return new(
		Status.BLOCKED,
		RejectionReason.PLAYER_DAMAGE_ZERO,
		command,
		unchanged_player_state,
		unchanged_player_state,
		player_snapshot,
		player_snapshot,
		unchanged_opponent_state,
		unchanged_opponent_state,
		resolution,
		no_events,
		registry,
	)


static func rejected(
	rejection_reason: int,
	unchanged_player_state: PlayerProgressionStateScript = null,
	unchanged_opponent_state: ContactCombatOpponentStateScript = null,
) -> ContactCombatResult:
	var no_events: Array[ContactCombatEventScript] = []
	return new(
		Status.REJECTED,
		rejection_reason,
		null,
		null,
		unchanged_player_state,
		null,
		null,
		null,
		unchanged_opponent_state,
		null,
		no_events,
	)


func status() -> int:
	return _status if _is_well_formed() else Status.REJECTED


func rejection_reason() -> int:
	return _rejection_reason if _is_well_formed() else RejectionReason.INVALID_RESULT


func was_evaluated() -> bool:
	return status() == Status.EVALUATED


func is_blocked() -> bool:
	return status() == Status.BLOCKED


func is_rejected() -> bool:
	return status() == Status.REJECTED


func is_resolution_candidate() -> bool:
	return (
		status() == Status.EVALUATED
		and _resolution != null
		and _resolution.is_resolution_candidate()
	)


func is_commit_boundary() -> bool:
	return false


func command() -> ContactCombatCommandScript:
	if not _is_well_formed() or _command == null:
		return null
	return _command.copy()


func previous_player_state() -> PlayerProgressionStateScript:
	if not _is_well_formed() or _previous_player_state == null:
		return null
	return _previous_player_state.copy()


func player_state_candidate() -> ContactCombatPlayerStateCandidateScript:
	if not _is_well_formed() or _next_player_state == null:
		return null
	var candidate: ContactCombatPlayerStateCandidateScript = (
		ContactCombatPlayerStateCandidateScript.from_progression_state(
			_next_player_state
		)
	)
	return candidate if candidate.is_valid() else null


func previous_player_progression_snapshot() -> PlayerProgressionSnapshotScript:
	if not _is_well_formed() or _previous_player_snapshot == null:
		return null
	return _previous_player_snapshot.copy()


func player_progression_snapshot() -> PlayerProgressionSnapshotScript:
	if not _is_well_formed() or _player_snapshot == null:
		return null
	return _player_snapshot.copy()


func previous_opponent_state() -> ContactCombatOpponentStateScript:
	if not _is_well_formed() or _previous_opponent_state == null:
		return null
	return _previous_opponent_state.copy()


func opponent_state() -> ContactCombatOpponentStateScript:
	if not _is_well_formed() or _opponent_state == null:
		return null
	return _opponent_state.copy()


func resolution() -> ContactCombatResolutionScript:
	if not _is_well_formed() or _resolution == null:
		return null
	return _resolution.copy()


func domain_events() -> Array[ContactCombatEventScript]:
	var copied_events: Array[ContactCombatEventScript] = []
	if not _is_well_formed():
		return copied_events
	for domain_event: ContactCombatEventScript in _domain_events:
		copied_events.append(domain_event.copy())
	return copied_events


func _is_well_formed() -> bool:
	if not _domain_event_input_matches_status:
		return false
	if _status == Status.REJECTED:
		return (
			_rejection_reason > RejectionReason.NONE
			and _rejection_reason < RejectionReason.INVALID_RESULT
			and _rejection_reason != RejectionReason.PLAYER_DAMAGE_ZERO
			and (
				_next_player_state == null
				or (
					_next_player_state.get_script() == PlayerProgressionStateScript
					and _next_player_state.is_valid()
				)
			)
			and (
				_opponent_state == null
				or (
					_opponent_state.get_script() == ContactCombatOpponentStateScript
					and _opponent_state.is_valid()
				)
			)
			and _previous_player_snapshot == null
			and _player_snapshot == null
			and _previous_opponent_state == null
			and _previous_player_state == null
			and _command == null
			and _resolution == null
			and _domain_events.is_empty()
		)
	if not _common_candidate_fields_are_valid():
		return false
	if _status == Status.BLOCKED:
		return (
			_rejection_reason == RejectionReason.PLAYER_DAMAGE_ZERO
			and not _resolution.is_resolution_candidate()
			and (
				_resolution.block_reason()
				== ContactCombatResolutionScript.BlockReason.PLAYER_DAMAGE_ZERO
			)
			and _previous_player_snapshot.is_equal_to(_player_snapshot)
			and _previous_opponent_state.is_equal_to(_opponent_state)
			and _domain_events.is_empty()
		)
	if (
		_status != Status.EVALUATED
		or _rejection_reason != RejectionReason.NONE
		or not _resolution.is_resolution_candidate()
		or _domain_events.size() != 1
	):
		return false
	var domain_event: ContactCombatEventScript = _domain_events[0]
	var event_resolution: ContactCombatResolutionScript = domain_event.resolution()
	return (
		domain_event.is_valid()
		and event_resolution != null
		and event_resolution.is_equal_to(_resolution)
	)


func _common_candidate_fields_are_valid() -> bool:
	if (
		_next_player_state == null
		or _command == null
		or _command.get_script() != ContactCombatCommandScript
		or not _command.is_valid()
		or _previous_player_state == null
		or _previous_player_state.get_script() != PlayerProgressionStateScript
		or not _previous_player_state.is_valid()
		or _next_player_state.get_script() != PlayerProgressionStateScript
		or not _next_player_state.is_valid()
		or _previous_player_snapshot == null
		or (
			_previous_player_snapshot.get_script()
			!= PlayerProgressionSnapshotScript
		)
		or not _previous_player_snapshot.is_valid()
		or _player_snapshot == null
		or _player_snapshot.get_script() != PlayerProgressionSnapshotScript
		or not _player_snapshot.is_valid()
		or _previous_opponent_state == null
		or (
			_previous_opponent_state.get_script()
			!= ContactCombatOpponentStateScript
		)
		or not _previous_opponent_state.is_valid()
		or _opponent_state == null
		or _opponent_state.get_script() != ContactCombatOpponentStateScript
		or not _opponent_state.is_valid()
		or _resolution == null
		or _resolution.get_script() != ContactCombatResolutionScript
		or not _resolution.is_valid()
		or not _registry_derivation_matches_inputs
		or not _state_matches_snapshot(
			_previous_player_state,
			_previous_player_snapshot,
		)
		or not _state_matches_snapshot(_next_player_state, _player_snapshot)
		or not _player_snapshots_preserve_progression()
		or not _opponent_states_preserve_identity_and_stats()
		or not _resolution_matches_states()
	):
		return false
	return true


func _player_snapshots_preserve_progression() -> bool:
	return (
		_previous_player_state.profile_id() == _next_player_state.profile_id()
		and (
			_previous_player_state.content_schema_version()
			== _next_player_state.content_schema_version()
		)
		and (
			_previous_player_state.content_version()
			== _next_player_state.content_version()
		)
		and (
			_previous_player_state.claimed_reward_ids()
			== _next_player_state.claimed_reward_ids()
		)
		and (
		_previous_player_snapshot.profile_id() == _player_snapshot.profile_id()
		)
		and (
			_previous_player_snapshot.content_schema_version()
			== _player_snapshot.content_schema_version()
		)
		and (
			_previous_player_snapshot.content_version()
			== _player_snapshot.content_version()
		)
		and (
			_previous_player_snapshot.maximum_health()
			== _player_snapshot.maximum_health()
		)
		and _previous_player_snapshot.attack() == _player_snapshot.attack()
		and _previous_player_snapshot.defense() == _player_snapshot.defense()
		and _previous_player_snapshot.speed() == _player_snapshot.speed()
		and (
			_previous_player_snapshot.claimed_reward_ids()
			== _player_snapshot.claimed_reward_ids()
		)
	)


func _opponent_states_preserve_identity_and_stats() -> bool:
	return (
		_previous_opponent_state.opponent_instance_id()
		== _opponent_state.opponent_instance_id()
		and (
			_previous_opponent_state.maximum_durability()
			== _opponent_state.maximum_durability()
		)
		and _previous_opponent_state.attack() == _opponent_state.attack()
		and _previous_opponent_state.defense() == _opponent_state.defense()
		and _previous_opponent_state.speed() == _opponent_state.speed()
	)


func _resolution_matches_states() -> bool:
	var effect_bonuses: Array[int] = _temporary_effect_bonuses(
		_command.temporary_effect()
	)
	if effect_bonuses.is_empty():
		return false
	if (
		ValidationSupportScript.would_add_overflow(
			_previous_player_snapshot.attack(),
			effect_bonuses[0],
		)
		or ValidationSupportScript.would_add_overflow(
			_previous_player_snapshot.defense(),
			effect_bonuses[1],
		)
		or ValidationSupportScript.would_add_overflow(
			_previous_player_snapshot.speed(),
			effect_bonuses[2],
		)
		or ValidationSupportScript.would_add_overflow(
			_previous_opponent_state.attack(),
			_resolution.support_attack_bonus(),
		)
	):
		return false
	return (
		_resolution.initiator_side() == _command.initiator_side()
		and _resolution.temporary_effect() == _command.temporary_effect()
		and (
			_resolution.supporting_opponents_alive()
			== _command.supporting_opponents_alive()
		)
		and (
		_resolution.player_profile_id()
		== _previous_player_snapshot.profile_id()
		)
		and (
			_resolution.content_schema_version()
			== _previous_player_snapshot.content_schema_version()
		)
		and (
			_resolution.content_version()
			== _previous_player_snapshot.content_version()
		)
		and (
			_resolution.opponent_instance_id()
			== _previous_opponent_state.opponent_instance_id()
		)
		and (
			_resolution.effective_player_attack()
			== _previous_player_snapshot.attack() + effect_bonuses[0]
		)
		and (
			_resolution.effective_player_defense()
			== _previous_player_snapshot.defense() + effect_bonuses[1]
		)
		and (
			_resolution.effective_player_speed()
			== _previous_player_snapshot.speed() + effect_bonuses[2]
		)
		and (
			_resolution.effective_opponent_attack()
			== (
				_previous_opponent_state.attack()
				+ _resolution.support_attack_bonus()
			)
		)
		and (
			_resolution.effective_opponent_defense()
			== _previous_opponent_state.defense()
		)
		and (
			_resolution.effective_opponent_speed()
			== _previous_opponent_state.speed()
		)
		and (
			_resolution.previous_player_health()
			== _previous_player_snapshot.current_health()
		)
		and _resolution.next_player_health() == _player_snapshot.current_health()
		and (
			_resolution.previous_opponent_durability()
			== _previous_opponent_state.current_durability()
		)
		and (
			_resolution.next_opponent_durability()
			== _opponent_state.current_durability()
		)
		and (
			_resolution.opponent_shield_intact_before()
			== _previous_opponent_state.shield_intact()
		)
		and (
			_resolution.opponent_shield_intact_after()
			== _opponent_state.shield_intact()
		)
	)


func _registry_derivation_matches(registry: RefCounted) -> bool:
	if (
		_status != Status.EVALUATED
		and _status != Status.BLOCKED
	):
		return false
	if (
		registry == null
		or not is_instance_valid(registry)
		or registry.get_script() != ContentRegistryScript
		or _previous_player_state == null
		or _next_player_state == null
		or _previous_player_snapshot == null
		or _player_snapshot == null
	):
		return false
	var previous_derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(
			_previous_player_state,
			registry,
		)
	)
	if not previous_derivation.succeeded():
		return false
	var next_derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(
			_next_player_state,
			registry,
		)
	)
	if not next_derivation.succeeded():
		return false
	return (
		previous_derivation.snapshot().is_equal_to(
			_previous_player_snapshot
		)
		and next_derivation.snapshot().is_equal_to(_player_snapshot)
	)


func _temporary_effect_bonuses(temporary_effect: int) -> Array[int]:
	return ContactCombatCommandScript.temporary_effect_bonuses(temporary_effect)


func _state_matches_snapshot(
	state: PlayerProgressionStateScript,
	snapshot: PlayerProgressionSnapshotScript,
) -> bool:
	return (
		state.profile_id() == snapshot.profile_id()
		and state.content_schema_version() == snapshot.content_schema_version()
		and state.content_version() == snapshot.content_version()
		and state.current_health() == snapshot.current_health()
		and state.claimed_reward_ids() == snapshot.claimed_reward_ids()
	)
