class_name PortableInventoryResolutionResult
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryReadSnapshotScript := preload(
	"res://src/rules/portable_inventory_read_snapshot.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

enum FailureReason {
	NONE = 0,
	INVALID_INVENTORY_STATE = 1,
	INVALID_CONTENT_SCHEMA_VERSION = 2,
	INVALID_CONTENT_VERSION = 3,
	INVALID_CAPACITY = 4,
	INVALID_REVISION = 5,
	INVALID_STACK_COLLECTION = 6,
	INVALID_STACK_ID = 7,
	EMPTY_BLUEPRINT_ID = 8,
	INVALID_QUANTITY = 9,
	INVALID_PROVENANCE = 10,
	INVALID_PROVENANCE_RECIPE_REFERENCE = 11,
	DUPLICATE_STACK_ID = 12,
	CAPACITY_EXCEEDED = 13,
	INVALID_SELECTED_STACK_ID = 14,
	UNKNOWN_SELECTED_STACK_ID = 15,
	INVALID_REGISTRY = 16,
	CONTENT_SCHEMA_VERSION_MISMATCH = 17,
	CONTENT_VERSION_MISMATCH = 18,
	UNKNOWN_BLUEPRINT_ID = 19,
	INVALID_BLUEPRINT_DEFINITION = 20,
	UNKNOWN_RECIPE_ID = 21,
	INVALID_RECIPE_DEFINITION = 22,
	RECIPE_BLUEPRINT_MISMATCH = 23,
	SELECTED_STACK_NOT_TEMPORARY_EFFECT = 24,
	INVALID_RESULT = 25,
}

var _read_snapshot: PortableInventoryReadSnapshotScript
var _integrity_read_snapshot: PortableInventoryReadSnapshotScript
var _failure_reason: int = FailureReason.NONE
var _integrity_failure_reason: int = FailureReason.NONE
var _failed_stack_id: StringName = &""
var _integrity_failed_stack_id: StringName = &""
var _failed_content_id: StringName = &""
var _integrity_failed_content_id: StringName = &""

# 平字段镜像声明（walker 统一处理）；嵌套镜像 _integrity_read_snapshot 为
# 深拷贝捕获 + is_equal_to 值比较，保留手写。
const _INTEGRITY_FIELD_NAMES: Array[StringName] = [
	&"failure_reason",
	&"failed_stack_id",
	&"failed_content_id",
]


func _init(
	state_candidate: RefCounted,
	registry: RefCounted,
	failure_reason: int,
	failed_stack_id: StringName,
	failed_content_id: StringName,
) -> void:
	var read_snapshot: PortableInventoryReadSnapshotScript = (
		PortableInventoryReadSnapshotScript.create(state_candidate, registry)
	)
	if (
		failure_reason == FailureReason.NONE
		and read_snapshot.is_valid()
		and failed_stack_id == &""
		and failed_content_id == &""
	):
		_read_snapshot = read_snapshot
		_set_failure_state(FailureReason.NONE, &"", &"")
		return
	if (
		failure_reason >= FailureReason.INVALID_INVENTORY_STATE
		and failure_reason <= FailureReason.INVALID_RESULT
		and _failure_metadata_is_valid(
			failure_reason,
			failed_stack_id,
			failed_content_id,
		)
	):
		_set_failure_state(
			failure_reason,
			failed_stack_id,
			failed_content_id,
		)
	else:
		_set_failure_state(FailureReason.INVALID_RESULT, &"", &"")


static func success(
	state_candidate: RefCounted,
	registry: RefCounted,
) -> PortableInventoryResolutionResult:
	return new(
		state_candidate,
		registry,
		FailureReason.NONE,
		&"",
		&"",
	)


static func failure(
	failure_reason: int,
	failed_stack_id: StringName = &"",
	failed_content_id: StringName = &"",
) -> PortableInventoryResolutionResult:
	return new(
		null,
		null,
		failure_reason,
		failed_stack_id,
		failed_content_id,
	)


func succeeded() -> bool:
	return (
		_failure_state_is_intact()
		and _failure_reason == FailureReason.NONE
		and _read_snapshot != null
		and is_instance_valid(_read_snapshot)
		and _read_snapshot.get_script() == PortableInventoryReadSnapshotScript
		and _read_snapshot.is_valid()
		and _integrity_read_snapshot != null
		and is_instance_valid(_integrity_read_snapshot)
		and (
			_integrity_read_snapshot.get_script()
			== PortableInventoryReadSnapshotScript
		)
		and _integrity_read_snapshot.is_valid()
		and _read_snapshot.is_equal_to(_integrity_read_snapshot)
	)


func failure_reason() -> int:
	if succeeded():
		return FailureReason.NONE
	if (
		_failure_state_is_intact()
		and _failure_reason >= FailureReason.INVALID_INVENTORY_STATE
		and _failure_reason <= FailureReason.INVALID_RESULT
	):
		return _failure_reason
	return FailureReason.INVALID_RESULT


func failed_stack_id() -> StringName:
	return _failed_stack_id if not succeeded() and _failure_state_is_intact() else &""


func failed_content_id() -> StringName:
	return _failed_content_id if not succeeded() and _failure_state_is_intact() else &""


func snapshot() -> PortableInventoryStateScript:
	return _read_snapshot.inventory_state() if succeeded() else null


func read_snapshot() -> PortableInventoryReadSnapshotScript:
	return _read_snapshot.copy() if succeeded() else null


func content_schema_version() -> int:
	return _read_snapshot.content_schema_version() if succeeded() else 0


func content_version() -> int:
	return _read_snapshot.content_version() if succeeded() else 0


func capacity() -> int:
	return _read_snapshot.capacity() if succeeded() else 0


func occupied_slot_count() -> int:
	return _read_snapshot.occupied_slot_count() if succeeded() else 0


func available_slot_count() -> int:
	return _read_snapshot.available_slot_count() if succeeded() else 0


func revision() -> int:
	return _read_snapshot.revision() if succeeded() else 0


func stack_ids() -> Array[StringName]:
	return _read_snapshot.stack_ids() if succeeded() else []


func stack_snapshots() -> Array[PortableInventoryStackScript]:
	if not succeeded():
		var empty_stacks: Array[PortableInventoryStackScript] = []
		return empty_stacks
	return _read_snapshot.stack_snapshots()


func stack_snapshot(stack_id: StringName) -> PortableInventoryStackScript:
	return _read_snapshot.stack_snapshot(stack_id) if succeeded() else null


func selected_temporary_effect_stack_id() -> StringName:
	return _read_snapshot.selected_temporary_effect_stack_id() if succeeded() else &""


func selected_temporary_effect_blueprint_id() -> StringName:
	return (
		_read_snapshot.selected_temporary_effect_blueprint_id()
		if succeeded()
		else &""
	)


func selected_temporary_effect() -> int:
	return (
		_read_snapshot.selected_temporary_effect()
		if succeeded()
		else ContactCombatCommandScript.TemporaryEffect.NONE
	)


func matches_exact_prestate(expected: RefCounted) -> bool:
	if (
		expected == null
		or not is_instance_valid(expected)
		or expected.get_script() != get_script()
		or not succeeded()
	):
		return false
	var expected_result: PortableInventoryResolutionResult = (
		expected as PortableInventoryResolutionResult
	)
	if not expected_result.succeeded():
		return false
	var expected_snapshot_candidate: Variant = expected_result.read_snapshot()
	return (
		expected_snapshot_candidate is RefCounted
		and (
			expected_snapshot_candidate as RefCounted
		).get_script() == PortableInventoryReadSnapshotScript
		and _read_snapshot.is_equal_to(
			expected_snapshot_candidate as PortableInventoryReadSnapshotScript
		)
	)


func is_commit_boundary() -> bool:
	return false


static func _failure_metadata_is_valid(
	failure_reason: int,
	failed_stack_id: StringName,
	failed_content_id: StringName,
) -> bool:
	if failure_reason == FailureReason.NONE:
		return failed_stack_id == &"" and failed_content_id == &""
	if failure_reason in [
		FailureReason.INVALID_INVENTORY_STATE,
		FailureReason.INVALID_CONTENT_SCHEMA_VERSION,
		FailureReason.INVALID_CONTENT_VERSION,
		FailureReason.INVALID_CAPACITY,
		FailureReason.INVALID_REVISION,
		FailureReason.INVALID_STACK_COLLECTION,
		FailureReason.CAPACITY_EXCEEDED,
		FailureReason.INVALID_REGISTRY,
		FailureReason.CONTENT_SCHEMA_VERSION_MISMATCH,
		FailureReason.CONTENT_VERSION_MISMATCH,
		FailureReason.INVALID_RESULT,
	]:
		return failed_stack_id == &"" and failed_content_id == &""
	if failure_reason in [
		FailureReason.INVALID_STACK_ID,
		FailureReason.INVALID_QUANTITY,
		FailureReason.INVALID_PROVENANCE,
		FailureReason.INVALID_PROVENANCE_RECIPE_REFERENCE,
		FailureReason.DUPLICATE_STACK_ID,
		FailureReason.INVALID_SELECTED_STACK_ID,
		FailureReason.UNKNOWN_SELECTED_STACK_ID,
	]:
		return failed_content_id == &""
	if failure_reason == FailureReason.EMPTY_BLUEPRINT_ID:
		return failed_content_id == &""
	if failure_reason in [
		FailureReason.UNKNOWN_BLUEPRINT_ID,
		FailureReason.INVALID_BLUEPRINT_DEFINITION,
		FailureReason.UNKNOWN_RECIPE_ID,
		FailureReason.INVALID_RECIPE_DEFINITION,
		FailureReason.RECIPE_BLUEPRINT_MISMATCH,
		FailureReason.SELECTED_STACK_NOT_TEMPORARY_EFFECT,
	]:
		return not String(failed_content_id).is_empty()
	return false


func _capture_integrity() -> void:
	if _read_snapshot != null:
		_integrity_read_snapshot = _read_snapshot.copy()
	ValidationSupportScript.capture_field_integrity(self, _INTEGRITY_FIELD_NAMES)


func _set_failure_state(
	failure_reason: int,
	failed_stack_id: StringName,
	failed_content_id: StringName,
) -> void:
	_failure_reason = failure_reason
	_failed_stack_id = failed_stack_id
	_failed_content_id = failed_content_id
	_capture_integrity()


func _failure_state_is_intact() -> bool:
	return (
		ValidationSupportScript.field_integrity_matches(self, _INTEGRITY_FIELD_NAMES)
		and _failure_metadata_is_valid(
			_failure_reason,
			_failed_stack_id,
			_failed_content_id,
		)
	)
