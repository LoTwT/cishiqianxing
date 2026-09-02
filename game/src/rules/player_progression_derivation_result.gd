class_name PlayerProgressionDerivationResult
extends RefCounted

const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)

enum FailureReason {
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
}

var _snapshot: PlayerProgressionSnapshotScript
var _failure_reason: int = FailureReason.NONE


func _init(
	snapshot: PlayerProgressionSnapshotScript,
	failure_reason: int,
) -> void:
	if (
		failure_reason == FailureReason.NONE
		and snapshot != null
		and snapshot.get_script() == PlayerProgressionSnapshotScript
		and snapshot.is_valid()
	):
		_snapshot = snapshot.copy()
		_failure_reason = FailureReason.NONE
	elif (
		failure_reason >= FailureReason.INVALID_STATE
		and failure_reason <= FailureReason.INVALID_INITIAL_PLAYER_STATS
	):
		_failure_reason = failure_reason
	else:
		_failure_reason = FailureReason.INVALID_STATE


static func success(
	snapshot: PlayerProgressionSnapshotScript,
) -> PlayerProgressionDerivationResult:
	return new(snapshot, FailureReason.NONE)


static func failure(failure_reason: int) -> PlayerProgressionDerivationResult:
	return new(null, failure_reason)


func succeeded() -> bool:
	return (
		_failure_reason == FailureReason.NONE
		and _snapshot != null
		and _snapshot.get_script() == PlayerProgressionSnapshotScript
		and _snapshot.is_valid()
	)


func snapshot() -> PlayerProgressionSnapshotScript:
	if not succeeded():
		return null
	return _snapshot.copy()


func failure_reason() -> int:
	return FailureReason.NONE if succeeded() else _failure_reason
