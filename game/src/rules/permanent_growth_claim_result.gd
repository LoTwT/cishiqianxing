class_name PermanentGrowthClaimResult
extends RefCounted

const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const PermanentGrowthClaimEventScript := preload(
	"res://src/rules/permanent_growth_claim_event.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum Status {
	APPLIED = 1,
	ALREADY_CLAIMED = 2,
	REJECTED = 3,
}

enum RejectionReason {
	NONE = 0,
	INVALID_STATE = 1,
	INVALID_REGISTRY = 2,
	CONTENT_SCHEMA_VERSION_MISMATCH = 3,
	CONTENT_VERSION_MISMATCH = 4,
	PROFILE_ID_MISMATCH = 5,
	UNKNOWN_CLAIMED_REWARD_ID = 6,
	INVALID_REWARD_DEFINITION = 7,
	INTEGER_OVERFLOW = 8,
	CURRENT_HEALTH_OUT_OF_RANGE = 9,
	INVALID_INITIAL_PLAYER_STATS = 10,
	INVALID_COMMAND = 11,
	EMPTY_REWARD_ID = 12,
	PLAYER_INCAPACITATED = 13,
	UNKNOWN_REWARD_ID = 14,
	INVALID_RESULT = 15,
}

var _status: int
var _rejection_reason: int
var _requested_reward_id: StringName
var _next_state: PlayerProgressionStateScript
var _previous_player_progression_snapshot: PlayerProgressionSnapshotScript
var _player_progression_snapshot: PlayerProgressionSnapshotScript
var _domain_events: Array[PermanentGrowthClaimEventScript] = []
var _domain_event_input_matches_status: bool = false


func _init(
	status: int,
	rejection_reason: int,
	requested_reward_id: StringName,
	next_state: PlayerProgressionStateScript,
	previous_player_progression_snapshot: PlayerProgressionSnapshotScript,
	player_progression_snapshot: PlayerProgressionSnapshotScript,
	domain_events: Array[PermanentGrowthClaimEventScript],
) -> void:
	_status = status
	_rejection_reason = rejection_reason
	_requested_reward_id = requested_reward_id
	if next_state != null and next_state.get_script() == PlayerProgressionStateScript:
		_next_state = next_state.copy()
	if (
		previous_player_progression_snapshot != null
		and (
			previous_player_progression_snapshot.get_script()
			== PlayerProgressionSnapshotScript
		)
	):
		_previous_player_progression_snapshot = (
			previous_player_progression_snapshot.copy()
		)
	if (
		player_progression_snapshot != null
		and (
			player_progression_snapshot.get_script()
			== PlayerProgressionSnapshotScript
		)
	):
		_player_progression_snapshot = player_progression_snapshot.copy()
	if _status == Status.APPLIED and domain_events.size() == 1:
		var domain_event: PermanentGrowthClaimEventScript = domain_events[0]
		if (
			domain_event != null
			and domain_event.get_script() == PermanentGrowthClaimEventScript
			and domain_event.is_valid()
		):
			_domain_events.append(domain_event.copy())
			_domain_event_input_matches_status = true
	elif _status != Status.APPLIED and domain_events.is_empty():
		_domain_event_input_matches_status = true
	_domain_events.make_read_only()


static func applied(
	requested_reward_id: StringName,
	previous_player_progression_snapshot: PlayerProgressionSnapshotScript,
	next_state: PlayerProgressionStateScript,
	player_progression_snapshot: PlayerProgressionSnapshotScript,
	domain_event: PermanentGrowthClaimEventScript,
) -> PermanentGrowthClaimResult:
	var domain_events: Array[PermanentGrowthClaimEventScript] = [domain_event]
	return new(
		Status.APPLIED,
		RejectionReason.NONE,
		requested_reward_id,
		next_state,
		previous_player_progression_snapshot,
		player_progression_snapshot,
		domain_events,
	)


static func already_claimed(
	requested_reward_id: StringName,
	unchanged_state: PlayerProgressionStateScript,
	player_progression_snapshot: PlayerProgressionSnapshotScript,
) -> PermanentGrowthClaimResult:
	var no_events: Array[PermanentGrowthClaimEventScript] = []
	return new(
		Status.ALREADY_CLAIMED,
		RejectionReason.NONE,
		requested_reward_id,
		unchanged_state,
		null,
		player_progression_snapshot,
		no_events,
	)


static func rejected(
	requested_reward_id: StringName,
	unchanged_state: PlayerProgressionStateScript,
	rejection_reason: int,
) -> PermanentGrowthClaimResult:
	var no_events: Array[PermanentGrowthClaimEventScript] = []
	return new(
		Status.REJECTED,
		rejection_reason,
		requested_reward_id,
		unchanged_state,
		null,
		null,
		no_events,
	)


func status() -> int:
	return _status if _is_well_formed() else Status.REJECTED


func rejection_reason() -> int:
	return _rejection_reason if _is_well_formed() else RejectionReason.INVALID_RESULT


func requested_reward_id() -> StringName:
	return _requested_reward_id


func succeeded() -> bool:
	return status() == Status.APPLIED


func was_applied() -> bool:
	return status() == Status.APPLIED


func is_already_claimed() -> bool:
	return status() == Status.ALREADY_CLAIMED


func was_already_claimed() -> bool:
	return status() == Status.ALREADY_CLAIMED


func is_rejected() -> bool:
	return status() == Status.REJECTED


func was_rejected() -> bool:
	return status() == Status.REJECTED


func is_commit_boundary() -> bool:
	return (
		status() == Status.APPLIED
		and _domain_events.size() == 1
		and _domain_events[0].is_commit_boundary()
	)


func next_state() -> PlayerProgressionStateScript:
	if not _is_well_formed() or _next_state == null:
		return null
	return _next_state.copy()


func previous_player_progression_snapshot() -> PlayerProgressionSnapshotScript:
	if (
		not _is_well_formed()
		or _previous_player_progression_snapshot == null
	):
		return null
	return _previous_player_progression_snapshot.copy()


func player_progression_snapshot() -> PlayerProgressionSnapshotScript:
	if not _is_well_formed() or _player_progression_snapshot == null:
		return null
	return _player_progression_snapshot.copy()


func domain_events() -> Array[PermanentGrowthClaimEventScript]:
	var copied_events: Array[PermanentGrowthClaimEventScript] = []
	if not _is_well_formed():
		return copied_events
	for domain_event: PermanentGrowthClaimEventScript in _domain_events:
		copied_events.append(domain_event.copy())
	return copied_events


func _is_well_formed() -> bool:
	if not _domain_event_input_matches_status:
		return false
	if _status == Status.REJECTED:
		return (
			_rejection_reason > RejectionReason.NONE
			and _rejection_reason < RejectionReason.INVALID_RESULT
			and (
				_next_state == null
				or _next_state.get_script() == PlayerProgressionStateScript
			)
			and _previous_player_progression_snapshot == null
			and _player_progression_snapshot == null
			and _domain_events.is_empty()
		)
	if (
		_rejection_reason != RejectionReason.NONE
		or String(_requested_reward_id).is_empty()
		or _next_state == null
		or _next_state.get_script() != PlayerProgressionStateScript
		or not _next_state.is_valid()
		or _player_progression_snapshot == null
		or (
			_player_progression_snapshot.get_script()
			!= PlayerProgressionSnapshotScript
		)
		or not _player_progression_snapshot.is_valid()
		or not _state_matches_snapshot(_next_state, _player_progression_snapshot)
	):
		return false
	if _status == Status.ALREADY_CLAIMED:
		return (
			_previous_player_progression_snapshot == null
			and _domain_events.is_empty()
			and _next_state.has_claimed_reward(_requested_reward_id)
		)
	if (
		_status != Status.APPLIED
		or _previous_player_progression_snapshot == null
		or (
			_previous_player_progression_snapshot.get_script()
			!= PlayerProgressionSnapshotScript
		)
		or not _previous_player_progression_snapshot.is_valid()
		or _domain_events.size() != 1
	):
		return false
	var domain_event: PermanentGrowthClaimEventScript = _domain_events[0]
	return (
		domain_event != null
		and domain_event.get_script() == PermanentGrowthClaimEventScript
		and domain_event.is_valid()
		and domain_event.reward_id() == _requested_reward_id
		and domain_event.profile_id() == _next_state.profile_id()
		and (
			domain_event.content_schema_version()
			== _next_state.content_schema_version()
		)
		and domain_event.content_version() == _next_state.content_version()
		and domain_event.next_current_health() == _next_state.current_health()
		and _next_state.has_claimed_reward(_requested_reward_id)
		and _applied_delta_is_valid(domain_event)
	)


func _applied_delta_is_valid(
	domain_event: PermanentGrowthClaimEventScript,
) -> bool:
	var previous_snapshot: PlayerProgressionSnapshotScript = (
		_previous_player_progression_snapshot
	)
	var next_snapshot: PlayerProgressionSnapshotScript = (
		_player_progression_snapshot
	)
	if (
		previous_snapshot.profile_id() != next_snapshot.profile_id()
		or (
			previous_snapshot.content_schema_version()
			!= next_snapshot.content_schema_version()
		)
		or previous_snapshot.content_version() != next_snapshot.content_version()
		or domain_event.profile_id() != previous_snapshot.profile_id()
		or (
			domain_event.content_schema_version()
			!= previous_snapshot.content_schema_version()
		)
		or domain_event.content_version() != previous_snapshot.content_version()
		or domain_event.previous_current_health() != previous_snapshot.current_health()
		or domain_event.next_current_health() != next_snapshot.current_health()
		or not _claimed_ledger_adds_requested_id(
			previous_snapshot.claimed_reward_ids(),
			next_snapshot.claimed_reward_ids(),
			_requested_reward_id,
		)
	):
		return false
	var increase: int = domain_event.increase()
	match domain_event.stat_kind():
		PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH:
			return (
				_increases_by(
					previous_snapshot.maximum_health(),
					next_snapshot.maximum_health(),
					increase,
				)
				and _increases_by(
					previous_snapshot.current_health(),
					next_snapshot.current_health(),
					increase,
				)
				and next_snapshot.attack() == previous_snapshot.attack()
				and next_snapshot.defense() == previous_snapshot.defense()
				and next_snapshot.speed() == previous_snapshot.speed()
			)
		PermanentGrowthRewardDefinitionScript.StatKind.ATTACK:
			return (
				next_snapshot.maximum_health() == previous_snapshot.maximum_health()
				and next_snapshot.current_health() == previous_snapshot.current_health()
				and _increases_by(
					previous_snapshot.attack(),
					next_snapshot.attack(),
					increase,
				)
				and next_snapshot.defense() == previous_snapshot.defense()
				and next_snapshot.speed() == previous_snapshot.speed()
			)
		PermanentGrowthRewardDefinitionScript.StatKind.DEFENSE:
			return (
				next_snapshot.maximum_health() == previous_snapshot.maximum_health()
				and next_snapshot.current_health() == previous_snapshot.current_health()
				and next_snapshot.attack() == previous_snapshot.attack()
				and _increases_by(
					previous_snapshot.defense(),
					next_snapshot.defense(),
					increase,
				)
				and next_snapshot.speed() == previous_snapshot.speed()
			)
		PermanentGrowthRewardDefinitionScript.StatKind.SPEED:
			return (
				next_snapshot.maximum_health() == previous_snapshot.maximum_health()
				and next_snapshot.current_health() == previous_snapshot.current_health()
				and next_snapshot.attack() == previous_snapshot.attack()
				and next_snapshot.defense() == previous_snapshot.defense()
				and _increases_by(
					previous_snapshot.speed(),
					next_snapshot.speed(),
					increase,
				)
			)
	return false


static func _claimed_ledger_adds_requested_id(
	previous_ids: Array[StringName],
	next_ids: Array[StringName],
	requested_reward_id: StringName,
) -> bool:
	if (
		previous_ids.has(requested_reward_id)
		or next_ids.size() != previous_ids.size() + 1
		or not next_ids.has(requested_reward_id)
	):
		return false
	for previous_id: StringName in previous_ids:
		if not next_ids.has(previous_id):
			return false
	return true


static func _increases_by(previous_value: int, next_value: int, increase: int) -> bool:
	return (
		increase > 0
		and previous_value <= ValidationSupportScript.MAX_INT - increase
		and next_value == previous_value + increase
	)


static func _state_matches_snapshot(
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
