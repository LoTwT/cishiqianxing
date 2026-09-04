class_name EnemyGridProjectionResult
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldReadSnapshotScript := preload(
	"res://src/rules/enemy_world_read_snapshot.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum FailureReason {
	NONE = 0,
	INVALID_WORLD_STATE = 1,
	INVALID_SPACE_ID = 2,
	INVALID_RESULT = 3,
}

var _space_id: StringName = &""
var _integrity_space_id: StringName = &""
var _world_step: int = 0
var _integrity_world_step: int = 0
var _actor_positions: Dictionary[StringName, Vector3i] = {}
var _integrity_actor_positions: Dictionary[StringName, Vector3i] = {}
var _failure_reason: int = FailureReason.NONE
var _integrity_failure_reason: int = FailureReason.NONE

# 全部基础字段名的镜像声明（walker 统一处理）；字典镜像
# _integrity_actor_positions 捕获后与业务字段共享同一只读字典，
# == 内容比对语义不变（原实现为两份独立只读字典）。
const _INTEGRITY_FIELD_NAMES: Array[StringName] = [
	&"space_id",
	&"world_step",
	&"actor_positions",
	&"failure_reason",
]


func _init(
	read_snapshot_candidate: RefCounted,
	space_id: StringName,
	failure_reason: int,
) -> void:
	if (
		failure_reason == FailureReason.NONE
		and _is_exact_read_snapshot(read_snapshot_candidate)
		and (read_snapshot_candidate as EnemyWorldReadSnapshotScript).is_valid()
		and EnemyWorldAddressScript.is_valid_space_id(space_id)
	):
		var read_snapshot: EnemyWorldReadSnapshotScript = (
			read_snapshot_candidate as EnemyWorldReadSnapshotScript
		)
		var actor_positions: Dictionary[StringName, Vector3i] = (
			_project_actor_positions(read_snapshot, space_id)
		)
		var world_step: int = read_snapshot.world_step()
		if (
			world_step >= 0
			and world_step <= ValidationSupportScript.MAX_WORLD_STEP
			and _positions_are_valid(actor_positions)
		):
			_space_id = space_id
			_world_step = world_step
			_actor_positions = _copy_actor_positions(actor_positions)
			_failure_reason = FailureReason.NONE
		else:
			_failure_reason = FailureReason.INVALID_RESULT
	else:
		_failure_reason = (
			failure_reason
			if (
				failure_reason >= FailureReason.INVALID_WORLD_STATE
				and failure_reason <= FailureReason.INVALID_RESULT
			)
			else FailureReason.INVALID_RESULT
		)
	_capture_integrity()
	_actor_positions.make_read_only()
	_integrity_actor_positions.make_read_only()


static func success(
	read_snapshot_candidate: RefCounted,
	space_id: StringName,
) -> EnemyGridProjectionResult:
	return new(read_snapshot_candidate, space_id, FailureReason.NONE)


static func failure(failure_reason: int) -> EnemyGridProjectionResult:
	return new(null, &"", failure_reason)


func succeeded() -> bool:
	return (
		ValidationSupportScript.field_integrity_matches(self, _INTEGRITY_FIELD_NAMES)
		and _failure_reason == FailureReason.NONE
		and EnemyWorldAddressScript.is_valid_space_id(_space_id)
		and _world_step >= 0
		and _world_step <= ValidationSupportScript.MAX_WORLD_STEP
		and _positions_are_valid(_actor_positions)
		and _positions_are_valid(_integrity_actor_positions)
	)


func failure_reason() -> int:
	if succeeded():
		return FailureReason.NONE
	if (
		_failure_reason == _integrity_failure_reason
		and _failure_reason >= FailureReason.INVALID_WORLD_STATE
		and _failure_reason <= FailureReason.INVALID_RESULT
	):
		return _failure_reason
	return FailureReason.INVALID_RESULT


func space_id() -> StringName:
	return _space_id if succeeded() else &""


func world_step() -> int:
	return _world_step if succeeded() else 0


func actor_ids() -> Array[StringName]:
	if not succeeded():
		return []
	var ids: Array[StringName] = []
	for actor_id: StringName in _actor_positions:
		ids.append(actor_id)
	ids.sort_custom(ValidationSupportScript.id_less_than)
	return ids


func actor_positions() -> Dictionary[StringName, Vector3i]:
	if not succeeded():
		var empty_positions: Dictionary[StringName, Vector3i] = {}
		return empty_positions
	return _copy_actor_positions(_actor_positions)


func is_commit_boundary() -> bool:
	return false


func _capture_integrity() -> void:
	ValidationSupportScript.capture_field_integrity(self, _INTEGRITY_FIELD_NAMES)


static func _positions_are_valid(
	actor_positions: Dictionary[StringName, Vector3i],
) -> bool:
	var occupied_cells: Dictionary[Vector3i, bool] = {}
	for actor_id: StringName in actor_positions:
		if (
			not EnemyInstanceStateScript.is_valid_instance_id(actor_id)
			or occupied_cells.has(actor_positions[actor_id])
		):
			return false
		occupied_cells[actor_positions[actor_id]] = true
	return true


static func _copy_actor_positions(
	actor_positions: Dictionary[StringName, Vector3i],
) -> Dictionary[StringName, Vector3i]:
	var copied_positions: Dictionary[StringName, Vector3i] = {}
	var actor_ids: Array[StringName] = []
	for actor_id: StringName in actor_positions:
		actor_ids.append(actor_id)
	actor_ids.sort_custom(ValidationSupportScript.id_less_than)
	for actor_id: StringName in actor_ids:
		copied_positions[actor_id] = actor_positions[actor_id]
	return copied_positions


static func _is_exact_read_snapshot(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldReadSnapshotScript
	)


static func _project_actor_positions(
	read_snapshot: EnemyWorldReadSnapshotScript,
	space_id: StringName,
) -> Dictionary[StringName, Vector3i]:
	var projected_positions: Dictionary[StringName, Vector3i] = {}
	var addresses: Dictionary[StringName, EnemyWorldAddressScript] = (
		read_snapshot.address_snapshots()
	)
	for instance_id: StringName in addresses:
		var address: EnemyWorldAddressScript = addresses[instance_id]
		if address.space_id() == space_id:
			projected_positions[instance_id] = address.cell()
	return projected_positions


