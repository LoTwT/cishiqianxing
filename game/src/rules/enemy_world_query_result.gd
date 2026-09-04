class_name EnemyWorldQueryResult
extends RefCounted

const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldReadSnapshotScript := preload(
	"res://src/rules/enemy_world_read_snapshot.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum FailureReason {
	NONE = 0,
	INVALID_WORLD_STATE = 1,
	INVALID_INSTANCE_ID = 2,
	UNKNOWN_INSTANCE_ID = 3,
	INVALID_RESULT = 4,
}

var _record: EnemyWorldRecordScript
var _integrity_record: EnemyWorldRecordScript
var _address: EnemyWorldAddressScript
var _integrity_address: EnemyWorldAddressScript
var _failure_reason: int = FailureReason.NONE
var _integrity_failure_reason: int = FailureReason.NONE

# 平字段镜像声明（walker 统一处理）；嵌套镜像 _integrity_record 与
# _integrity_address 为深拷贝捕获 + is_equal_to 值比较，保留手写。
const _INTEGRITY_FIELD_NAMES: Array[StringName] = [&"failure_reason"]


func _init(
	read_snapshot_candidate: RefCounted,
	instance_id: StringName,
	failure_reason: int,
) -> void:
	if (
		failure_reason == FailureReason.NONE
		and EnemyInstanceStateScript.is_valid_instance_id(instance_id)
		and _is_exact_read_snapshot(read_snapshot_candidate)
		and (read_snapshot_candidate as EnemyWorldReadSnapshotScript).is_valid()
	):
		var read_snapshot: EnemyWorldReadSnapshotScript = (
			read_snapshot_candidate as EnemyWorldReadSnapshotScript
		)
		var record: EnemyWorldRecordScript = read_snapshot.record_snapshot(instance_id)
		var address: EnemyWorldAddressScript = read_snapshot.address_snapshot(instance_id)
		var address_is_exact: bool = _is_exact_address(address)
		var active_record_is_complete: bool = (
			_is_exact_record(record)
			and record.lifecycle() == EnemyWorldRecordScript.Lifecycle.ACTIVE
			and address_is_exact
			and address.is_valid()
		)
		var resolved_record_is_complete: bool = (
			_is_exact_record(record)
			and record.lifecycle() == EnemyWorldRecordScript.Lifecycle.RESOLVED
			and address == null
		)
		if (
			_is_exact_record(record)
			and record.is_valid()
			and (
				active_record_is_complete or resolved_record_is_complete
			)
		):
			_record = record.copy()
			if address_is_exact:
				_address = address.copy()
			_failure_reason = FailureReason.NONE
		else:
			_failure_reason = FailureReason.INVALID_RESULT
	elif (
		failure_reason >= FailureReason.INVALID_WORLD_STATE
		and failure_reason <= FailureReason.INVALID_RESULT
	):
		_failure_reason = failure_reason
	else:
		_failure_reason = FailureReason.INVALID_RESULT
	_capture_integrity()


static func success(
	read_snapshot_candidate: RefCounted,
	instance_id: StringName,
) -> EnemyWorldQueryResult:
	return new(read_snapshot_candidate, instance_id, FailureReason.NONE)


static func failure(failure_reason: int) -> EnemyWorldQueryResult:
	return new(null, &"", failure_reason)


func succeeded() -> bool:
	if (
		not ValidationSupportScript.field_integrity_matches(self, _INTEGRITY_FIELD_NAMES)
		or _failure_reason != FailureReason.NONE
		or not _is_exact_record(_record)
		or not _is_exact_record(_integrity_record)
		or not _record.is_valid()
		or not _integrity_record.is_valid()
		or not _record.is_equal_to(_integrity_record)
	):
		return false
	if _record.lifecycle() == EnemyWorldRecordScript.Lifecycle.ACTIVE:
		return (
			_is_exact_address(_address)
			and _is_exact_address(_integrity_address)
			and _address.is_valid()
			and _integrity_address.is_valid()
			and _address.is_equal_to(_integrity_address)
		)
	return _address == null and _integrity_address == null


func failure_reason() -> int:
	if succeeded():
		return FailureReason.NONE
	if (
		ValidationSupportScript.field_integrity_matches(self, _INTEGRITY_FIELD_NAMES)
		and _failure_reason >= FailureReason.INVALID_WORLD_STATE
		and _failure_reason <= FailureReason.INVALID_RESULT
	):
		return _failure_reason
	return FailureReason.INVALID_RESULT


func record() -> EnemyWorldRecordScript:
	return _record.copy() if succeeded() else null


func instance_state() -> EnemyInstanceStateScript:
	return _record.instance_state() if succeeded() else null


func lifecycle() -> int:
	return _record.lifecycle() if succeeded() else 0


func has_world_address() -> bool:
	return succeeded() and _address != null


func world_address() -> EnemyWorldAddressScript:
	if not succeeded() or _address == null:
		return null
	return _address.copy()


func _capture_integrity() -> void:
	if _is_exact_record(_record):
		_integrity_record = _record.copy()
	if _is_exact_address(_address):
		_integrity_address = _address.copy()
	ValidationSupportScript.capture_field_integrity(self, _INTEGRITY_FIELD_NAMES)


static func _is_exact_record(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldRecordScript
	)


static func _is_exact_address(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldAddressScript
	)


static func _is_exact_read_snapshot(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldReadSnapshotScript
	)
