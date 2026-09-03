class_name EnemyInstanceResolutionResult
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyInstanceSnapshotScript := preload(
	"res://src/rules/enemy_instance_snapshot.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)

enum FailureReason {
	NONE = 0,
	INVALID_INSTANCE_STATE = 1,
	INVALID_STATE_KIND = 2,
	INVALID_REGISTRY = 3,
	CONTENT_SCHEMA_VERSION_MISMATCH = 4,
	CONTENT_VERSION_MISMATCH = 5,
	UNKNOWN_PROFILE_ID = 6,
	ALTERNATE_STATE_UNAVAILABLE = 7,
	CURRENT_DURABILITY_OUT_OF_RANGE = 8,
	SHIELD_STATE_INVALID = 9,
	INVALID_RESULT = 10,
}

var _snapshot: EnemyInstanceSnapshotScript
var _integrity_snapshot: EnemyInstanceSnapshotScript
var _failure_reason: int = FailureReason.NONE


func _init(
	instance_state_candidate: RefCounted,
	failure_reason: int,
	registry: RefCounted = null,
) -> void:
	if (
		failure_reason == FailureReason.NONE
		and instance_state_candidate != null
		and is_instance_valid(instance_state_candidate)
		and instance_state_candidate.get_script() == EnemyInstanceStateScript
	):
		var snapshot: EnemyInstanceSnapshotScript = (
			EnemyInstanceSnapshotScript.from_registry(
				instance_state_candidate as EnemyInstanceStateScript,
				registry,
			)
		)
		if snapshot.is_valid():
			_snapshot = snapshot
			_integrity_snapshot = snapshot.copy()
			_failure_reason = FailureReason.NONE
		else:
			_failure_reason = FailureReason.INVALID_RESULT
	elif (
		failure_reason >= FailureReason.INVALID_INSTANCE_STATE
		and failure_reason <= FailureReason.INVALID_RESULT
	):
		_failure_reason = failure_reason
	else:
		_failure_reason = FailureReason.INVALID_RESULT


static func success(
	instance_state_candidate: RefCounted,
	registry: RefCounted,
) -> EnemyInstanceResolutionResult:
	return new(instance_state_candidate, FailureReason.NONE, registry)


static func failure(failure_reason: int) -> EnemyInstanceResolutionResult:
	return new(null, failure_reason, null)


func succeeded() -> bool:
	return (
		_failure_reason == FailureReason.NONE
		and _snapshot != null
		and is_instance_valid(_snapshot)
		and _snapshot.get_script() == EnemyInstanceSnapshotScript
		and _snapshot.is_valid()
		and _integrity_snapshot != null
		and is_instance_valid(_integrity_snapshot)
		and _integrity_snapshot.get_script() == EnemyInstanceSnapshotScript
		and _integrity_snapshot.is_valid()
		and _snapshot.is_equal_to(_integrity_snapshot)
	)


func failure_reason() -> int:
	if succeeded():
		return FailureReason.NONE
	if (
		_failure_reason >= FailureReason.INVALID_INSTANCE_STATE
		and _failure_reason <= FailureReason.INVALID_RESULT
	):
		return _failure_reason
	return FailureReason.INVALID_RESULT


func snapshot() -> EnemyInstanceSnapshotScript:
	if not succeeded():
		return null
	return _snapshot.copy()


func instance_state() -> EnemyInstanceStateScript:
	if not succeeded():
		return null
	return _snapshot.instance_state()


func contact_combat_opponent_state() -> ContactCombatOpponentStateScript:
	if not succeeded():
		return null
	return ContactCombatOpponentStateScript.create(
		_snapshot.instance_id(),
		_snapshot.maximum_durability(),
		_snapshot.current_durability(),
		_snapshot.attack(),
		_snapshot.defense(),
		_snapshot.speed(),
		_snapshot.shield_intact(),
	)


func is_commit_boundary() -> bool:
	return false
