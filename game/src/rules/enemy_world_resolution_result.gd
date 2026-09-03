class_name EnemyWorldResolutionResult
extends RefCounted

const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyGridProjectionResultScript := preload(
	"res://src/rules/enemy_grid_projection_result.gd"
)
const EnemyWorldQueryResultScript := preload(
	"res://src/rules/enemy_world_query_result.gd"
)
const EnemyWorldReadSnapshotScript := preload(
	"res://src/rules/enemy_world_read_snapshot.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)

enum FailureReason {
	NONE = 0,
	INVALID_WORLD_STATE = 1,
	INVALID_WORLD_STEP = 2,
	INVALID_WORLD_RECORD = 3,
	INVALID_LIFECYCLE = 4,
	INVALID_WORLD_ADDRESS = 5,
	DUPLICATE_INSTANCE_ID = 6,
	ENEMY_INSTANCE_REJECTED = 7,
	ORPHAN_GRID_ACTOR = 8,
	ACTIVE_REQUIRES_POSITIVE_DURABILITY = 9,
	RESOLVED_REQUIRES_ZERO_DURABILITY = 10,
	ACTIVE_REQUIRES_WORLD_ADDRESS = 11,
	RESOLVED_CANNOT_OCCUPY_WORLD_ADDRESS = 12,
	DUPLICATE_WORLD_ADDRESS = 13,
	INVALID_RESULT = 14,
}

var _read_snapshot: EnemyWorldReadSnapshotScript
var _integrity_read_snapshot: EnemyWorldReadSnapshotScript
var _failure_reason: int = FailureReason.NONE
var _integrity_failure_reason: int = FailureReason.NONE
var _failed_instance_id: StringName = &""
var _integrity_failed_instance_id: StringName = &""
var _failed_space_id: StringName = &""
var _integrity_failed_space_id: StringName = &""
var _enemy_instance_failure_reason: int = (
	EnemyInstanceResolutionResultScript.FailureReason.NONE
)
var _integrity_enemy_instance_failure_reason: int = (
	EnemyInstanceResolutionResultScript.FailureReason.NONE
)


func _init(
	snapshot_candidate: RefCounted,
	registry: RefCounted,
	failure_reason: int,
	failed_instance_id: StringName,
	failed_space_id: StringName,
	enemy_instance_failure_reason: int,
) -> void:
	var read_snapshot: EnemyWorldReadSnapshotScript = (
		EnemyWorldReadSnapshotScript.create(snapshot_candidate, registry)
	)
	if (
		failure_reason == FailureReason.NONE
		and read_snapshot.is_valid()
		and failed_instance_id == &""
		and failed_space_id == &""
		and enemy_instance_failure_reason
		== EnemyInstanceResolutionResultScript.FailureReason.NONE
	):
		_read_snapshot = read_snapshot
		_integrity_read_snapshot = read_snapshot.copy()
		_set_failure_state(
			FailureReason.NONE,
			&"",
			&"",
			EnemyInstanceResolutionResultScript.FailureReason.NONE,
		)
		return
	if (
		failure_reason >= FailureReason.INVALID_WORLD_STATE
		and failure_reason <= FailureReason.INVALID_RESULT
		and _failure_metadata_is_valid(
			failure_reason,
			failed_instance_id,
			failed_space_id,
			enemy_instance_failure_reason,
		)
	):
		_set_failure_state(
			failure_reason,
			failed_instance_id,
			failed_space_id,
			enemy_instance_failure_reason,
		)
	else:
		_set_failure_state(
			FailureReason.INVALID_RESULT,
			&"",
			&"",
			EnemyInstanceResolutionResultScript.FailureReason.NONE,
		)


static func success(
	snapshot_candidate: RefCounted,
	registry: RefCounted,
) -> EnemyWorldResolutionResult:
	return new(
		snapshot_candidate,
		registry,
		FailureReason.NONE,
		&"",
		&"",
		EnemyInstanceResolutionResultScript.FailureReason.NONE,
	)


static func failure(
	failure_reason: int,
	failed_instance_id: StringName = &"",
	failed_space_id: StringName = &"",
	enemy_instance_failure_reason: int = (
		EnemyInstanceResolutionResultScript.FailureReason.NONE
	),
) -> EnemyWorldResolutionResult:
	return new(
		null,
		null,
		failure_reason,
		failed_instance_id,
		failed_space_id,
		enemy_instance_failure_reason,
	)


func succeeded() -> bool:
	return (
		_failure_state_is_intact()
		and _failure_reason == FailureReason.NONE
		and _read_snapshot != null
		and is_instance_valid(_read_snapshot)
		and _read_snapshot.get_script() == EnemyWorldReadSnapshotScript
		and _read_snapshot.is_valid()
		and _integrity_read_snapshot != null
		and is_instance_valid(_integrity_read_snapshot)
		and _integrity_read_snapshot.get_script() == EnemyWorldReadSnapshotScript
		and _integrity_read_snapshot.is_valid()
		and _read_snapshot.is_equal_to(_integrity_read_snapshot)
	)


func failure_reason() -> int:
	if succeeded():
		return FailureReason.NONE
	if (
		_failure_state_is_intact()
		and _failure_reason != FailureReason.NONE
		and _failure_reason >= FailureReason.INVALID_WORLD_STATE
		and _failure_reason <= FailureReason.INVALID_RESULT
	):
		return _failure_reason
	return FailureReason.INVALID_RESULT


func failed_instance_id() -> StringName:
	if succeeded() or not _failure_state_is_intact():
		return &""
	return _failed_instance_id


func failed_space_id() -> StringName:
	if succeeded() or not _failure_state_is_intact():
		return &""
	return _failed_space_id


func enemy_instance_failure_reason() -> int:
	if succeeded() or not _failure_state_is_intact():
		return EnemyInstanceResolutionResultScript.FailureReason.NONE
	return _enemy_instance_failure_reason


func snapshot() -> EnemyWorldStateScript:
	return _read_snapshot.world_state() if succeeded() else null


func instance_ids() -> Array[StringName]:
	return _read_snapshot.instance_ids() if succeeded() else []


func record_snapshots() -> Array[EnemyWorldRecordScript]:
	if not succeeded():
		return []
	return _read_snapshot.record_snapshots()


func address_snapshots() -> Dictionary[StringName, EnemyWorldAddressScript]:
	if not succeeded():
		var empty_addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
		return empty_addresses
	return _read_snapshot.address_snapshots()


func lookup_enemy(instance_id: StringName) -> EnemyWorldQueryResultScript:
	if not succeeded():
		return EnemyWorldQueryResultScript.failure(
			EnemyWorldQueryResultScript.FailureReason.INVALID_WORLD_STATE
		)
	if not EnemyInstanceStateScript.is_valid_instance_id(instance_id):
		return EnemyWorldQueryResultScript.failure(
			EnemyWorldQueryResultScript.FailureReason.INVALID_INSTANCE_ID
		)
	if _read_snapshot.record_snapshot(instance_id) == null:
		return EnemyWorldQueryResultScript.failure(
			EnemyWorldQueryResultScript.FailureReason.UNKNOWN_INSTANCE_ID
		)
	return EnemyWorldQueryResultScript.success(_read_snapshot, instance_id)


func project_space(space_id: StringName) -> EnemyGridProjectionResultScript:
	if not succeeded():
		return EnemyGridProjectionResultScript.failure(
			EnemyGridProjectionResultScript.FailureReason.INVALID_WORLD_STATE
		)
	if not EnemyWorldAddressScript.is_valid_space_id(space_id):
		return EnemyGridProjectionResultScript.failure(
			EnemyGridProjectionResultScript.FailureReason.INVALID_SPACE_ID
		)
	return EnemyGridProjectionResultScript.success(_read_snapshot, space_id)


func matches_exact_prestate(expected: RefCounted) -> bool:
	return (
		get_script() == EnemyWorldResolutionResult
		and expected != null
		and is_instance_valid(expected)
		and expected.get_script() == EnemyWorldResolutionResult
		and succeeded()
		and (expected as EnemyWorldResolutionResult).succeeded()
		and _read_snapshot.is_equal_to(
			(expected as EnemyWorldResolutionResult)._read_snapshot
		)
	)


func is_commit_boundary() -> bool:
	return false


static func _failure_metadata_is_valid(
	failure_reason: int,
	failed_instance_id: StringName,
	failed_space_id: StringName,
	enemy_instance_failure_reason: int,
) -> bool:
	if failure_reason == FailureReason.ENEMY_INSTANCE_REJECTED:
		return (
			failed_space_id == &""
			and enemy_instance_failure_reason
			>= EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE
			and enemy_instance_failure_reason
			<= EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT
		)
	if (
		enemy_instance_failure_reason
		!= EnemyInstanceResolutionResultScript.FailureReason.NONE
	):
		return false
	if failure_reason in [
		FailureReason.NONE,
		FailureReason.INVALID_WORLD_STATE,
		FailureReason.INVALID_WORLD_STEP,
		FailureReason.INVALID_WORLD_RECORD,
		FailureReason.INVALID_RESULT,
	]:
		return failed_instance_id == &"" and failed_space_id == &""
	if failure_reason in [
		FailureReason.INVALID_LIFECYCLE,
		FailureReason.DUPLICATE_INSTANCE_ID,
	]:
		return failed_space_id == &""
	if failure_reason == FailureReason.INVALID_WORLD_ADDRESS:
		return true
	if failure_reason in [
		FailureReason.ORPHAN_GRID_ACTOR,
		FailureReason.RESOLVED_CANNOT_OCCUPY_WORLD_ADDRESS,
		FailureReason.DUPLICATE_WORLD_ADDRESS,
	]:
		return (
			EnemyInstanceStateScript.is_valid_instance_id(failed_instance_id)
			and EnemyWorldAddressScript.is_valid_space_id(failed_space_id)
		)
	if failure_reason in [
		FailureReason.ACTIVE_REQUIRES_POSITIVE_DURABILITY,
		FailureReason.RESOLVED_REQUIRES_ZERO_DURABILITY,
		FailureReason.ACTIVE_REQUIRES_WORLD_ADDRESS,
	]:
		return (
			EnemyInstanceStateScript.is_valid_instance_id(failed_instance_id)
			and failed_space_id == &""
		)
	return false


func _set_failure_state(
	failure_reason: int,
	failed_instance_id: StringName,
	failed_space_id: StringName,
	enemy_instance_failure_reason: int,
) -> void:
	_failure_reason = failure_reason
	_integrity_failure_reason = failure_reason
	_failed_instance_id = failed_instance_id
	_integrity_failed_instance_id = failed_instance_id
	_failed_space_id = failed_space_id
	_integrity_failed_space_id = failed_space_id
	_enemy_instance_failure_reason = enemy_instance_failure_reason
	_integrity_enemy_instance_failure_reason = enemy_instance_failure_reason


func _failure_state_is_intact() -> bool:
	return (
		_failure_reason == _integrity_failure_reason
		and _failed_instance_id == _integrity_failed_instance_id
		and _failed_space_id == _integrity_failed_space_id
		and _enemy_instance_failure_reason
		== _integrity_enemy_instance_failure_reason
		and _failure_metadata_is_valid(
			_failure_reason,
			_failed_instance_id,
			_failed_space_id,
			_enemy_instance_failure_reason,
		)
	)
