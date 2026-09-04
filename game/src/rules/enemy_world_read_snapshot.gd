class_name EnemyWorldReadSnapshot
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

var _state: EnemyWorldStateScript
var _integrity_state: EnemyWorldStateScript
var _initialized: bool = false


static func create(
	state_candidate: RefCounted,
	registry: RefCounted,
) -> EnemyWorldReadSnapshot:
	var snapshot := new()
	if (
		state_candidate != null
		and is_instance_valid(state_candidate)
		and state_candidate.get_script() == EnemyWorldStateScript
		and (state_candidate as EnemyWorldStateScript).is_resolved_against(registry)
	):
		snapshot._state = (state_candidate as EnemyWorldStateScript).copy()
		snapshot._initialized = true
		snapshot._capture_integrity()
	return snapshot


func copy() -> EnemyWorldReadSnapshot:
	var copied_snapshot := new()
	if _is_exact_state(_state) and _is_exact_state(_integrity_state):
		copied_snapshot._state = _state.copy()
		copied_snapshot._integrity_state = _integrity_state.copy()
		copied_snapshot._initialized = _initialized
	return copied_snapshot


func is_valid() -> bool:
	return (
		_initialized
		and _is_exact_state(_state)
		and _is_exact_state(_integrity_state)
		and _state.is_valid()
		and _integrity_state.is_valid()
		and _state.is_equal_to(_integrity_state)
	)


func world_state() -> EnemyWorldStateScript:
	return _state.copy() if is_valid() else null


func world_step() -> int:
	return _state.world_step() if is_valid() else 0


func instance_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if not is_valid():
		return ids
	for record: EnemyWorldRecordScript in _state._records:
		ids.append(record.instance_id())
	return ids


func record_snapshots() -> Array[EnemyWorldRecordScript]:
	var copied_records: Array[EnemyWorldRecordScript] = []
	if not is_valid():
		return copied_records
	for record: EnemyWorldRecordScript in _state._records:
		copied_records.append(record.copy())
	return copied_records


func address_snapshots() -> Dictionary[StringName, EnemyWorldAddressScript]:
	var copied_addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	if not is_valid():
		return copied_addresses
	var instance_ids: Array[StringName] = []
	for instance_id: StringName in _state._addresses_by_instance_id:
		instance_ids.append(instance_id)
	instance_ids.sort_custom(ValidationSupportScript.id_less_than)
	for instance_id: StringName in instance_ids:
		copied_addresses[instance_id] = (
			_state._addresses_by_instance_id[instance_id].copy()
		)
	return copied_addresses


func record_snapshot(instance_id: StringName) -> EnemyWorldRecordScript:
	if (
		not is_valid()
		or not EnemyInstanceStateScript.is_valid_instance_id(instance_id)
	):
		return null
	for record: EnemyWorldRecordScript in _state._records:
		if record.instance_id() == instance_id:
			return record.copy()
	return null


func address_snapshot(instance_id: StringName) -> EnemyWorldAddressScript:
	if (
		not is_valid()
		or not EnemyInstanceStateScript.is_valid_instance_id(instance_id)
		or not _state._addresses_by_instance_id.has(instance_id)
	):
		return null
	return _state._addresses_by_instance_id[instance_id].copy()


func is_equal_to(other: EnemyWorldReadSnapshot) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and is_valid()
		and other.is_valid()
		and _state.is_equal_to(other._state)
	)


static func _is_exact_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldStateScript
	)


# 仅嵌套对象镜像 _integrity_state（无平字段镜像）：深拷贝捕获、is_equal_to
# 值比较与 copy() 镜像深拷贝保留手写，无 schema 声明。
func _capture_integrity() -> void:
	if _is_exact_state(_state):
		_integrity_state = _state.copy()
