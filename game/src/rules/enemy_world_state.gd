class_name EnemyWorldState
extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyInstanceResolverScript := preload(
	"res://src/rules/enemy_instance_resolver.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")

var _records: Array[EnemyWorldRecordScript] = []
var _addresses_by_instance_id: Dictionary[StringName, EnemyWorldAddressScript] = {}
var _world_step: int = 0
var _initialized: bool = false
var _record_input_types_valid: bool = true
var _address_input_types_valid: bool = true


func _init() -> void:
	_freeze_collections()


static func create(
	record_candidates: Array,
	address_candidates: Dictionary,
	world_step: int = 0,
) -> EnemyWorldState:
	var state := new()
	state._records = state._copy_record_candidates(record_candidates)
	state._addresses_by_instance_id = state._copy_address_candidates(
		address_candidates
	)
	state._world_step = world_step
	state._initialized = true
	state._freeze_collections()
	return state


func copy() -> EnemyWorldState:
	var copied_state := new()
	var copied_records: Array[EnemyWorldRecordScript] = []
	for record: EnemyWorldRecordScript in _records:
		if _is_exact_record(record):
			copied_records.append(record.copy())
		else:
			copied_state._record_input_types_valid = false
	var copied_addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	for instance_id: StringName in _sorted_address_ids():
		var address: EnemyWorldAddressScript = _addresses_by_instance_id[instance_id]
		if _is_exact_address(address):
			copied_addresses[instance_id] = address.copy()
		else:
			copied_state._address_input_types_valid = false
	copied_state._records = copied_records
	copied_state._addresses_by_instance_id = copied_addresses
	copied_state._world_step = _world_step
	copied_state._initialized = _initialized
	copied_state._record_input_types_valid = (
		copied_state._record_input_types_valid and _record_input_types_valid
	)
	copied_state._address_input_types_valid = (
		copied_state._address_input_types_valid and _address_input_types_valid
	)
	copied_state._freeze_collections()
	return copied_state


func is_valid() -> bool:
	if (
		not _initialized
		or not _record_input_types_valid
		or not _address_input_types_valid
		or _world_step < 0
		or _world_step > GridRuleStateScript.MAX_WORLD_STEP
		or not _records_use_canonical_order()
	):
		return false
	var records_by_id: Dictionary[StringName, EnemyWorldRecordScript] = {}
	for record: EnemyWorldRecordScript in _records:
		if not _is_exact_record(record) or not record.is_valid():
			return false
		var instance_id: StringName = record.instance_id()
		if records_by_id.has(instance_id):
			return false
		records_by_id[instance_id] = record

	var occupied_addresses: Dictionary[String, bool] = {}
	for instance_id: StringName in _sorted_address_ids():
		var address: EnemyWorldAddressScript = _addresses_by_instance_id[instance_id]
		if (
			not EnemyInstanceStateScript.is_valid_instance_id(instance_id)
			or not _is_exact_address(address)
			or not address.is_valid()
			or not records_by_id.has(instance_id)
		):
			return false
		var record: EnemyWorldRecordScript = records_by_id[instance_id]
		if record.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
			return false
		var address_key: String = address.canonical_slot_key()
		if occupied_addresses.has(address_key):
			return false
		occupied_addresses[address_key] = true

	for record: EnemyWorldRecordScript in _records:
		var has_address: bool = _addresses_by_instance_id.has(record.instance_id())
		if (
			(record.lifecycle() == EnemyWorldRecordScript.Lifecycle.ACTIVE and not has_address)
			or (
				record.lifecycle() == EnemyWorldRecordScript.Lifecycle.RESOLVED
				and has_address
			)
		):
			return false
	return true


func world_step() -> int:
	return _world_step


func is_resolved_against(registry: RefCounted) -> bool:
	if not is_valid():
		return false
	if (
		registry == null
		or not is_instance_valid(registry)
		or registry.get_script() != ContentRegistryScript
		or not (registry as ContentRegistryScript).is_initialized()
	):
		return false
	for record: EnemyWorldRecordScript in _records:
		if not EnemyInstanceResolverScript.resolve(
			record.instance_state(),
			registry,
		).succeeded():
			return false
	return true


func is_equal_to(other: EnemyWorldState) -> bool:
	if (
		other == null
		or not is_instance_valid(other)
		or other.get_script() != get_script()
		or other._initialized != _initialized
		or other._record_input_types_valid != _record_input_types_valid
		or other._address_input_types_valid != _address_input_types_valid
		or other._world_step != _world_step
		or other._records.size() != _records.size()
		or other._addresses_by_instance_id.size()
		!= _addresses_by_instance_id.size()
	):
		return false
	for index: int in range(_records.size()):
		if (
			not _is_exact_record(_records[index])
			or not _is_exact_record(other._records[index])
			or not _records[index].is_equal_to(other._records[index])
		):
			return false
	for instance_id: StringName in _sorted_address_ids():
		if (
			not other._addresses_by_instance_id.has(instance_id)
			or not _is_exact_address(_addresses_by_instance_id[instance_id])
			or not _is_exact_address(other._addresses_by_instance_id[instance_id])
			or not _addresses_by_instance_id[instance_id].is_equal_to(
				other._addresses_by_instance_id[instance_id]
			)
		):
			return false
	return true


func _copy_record_candidates(record_candidates: Array) -> Array[EnemyWorldRecordScript]:
	var copied_records: Array[EnemyWorldRecordScript] = []
	for candidate: Variant in record_candidates:
		if not candidate is RefCounted:
			_record_input_types_valid = false
			continue
		if not _is_exact_record(candidate as RefCounted):
			_record_input_types_valid = false
			continue
		copied_records.append((candidate as EnemyWorldRecordScript).copy())
	return copied_records


func _copy_address_candidates(
	address_candidates: Dictionary,
) -> Dictionary[StringName, EnemyWorldAddressScript]:
	var copied_addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	var instance_ids: Array[StringName] = []
	for key_candidate: Variant in address_candidates:
		if typeof(key_candidate) != TYPE_STRING_NAME:
			_address_input_types_valid = false
			continue
		var instance_id: StringName = key_candidate as StringName
		var value_candidate: Variant = address_candidates[key_candidate]
		if not value_candidate is RefCounted:
			_address_input_types_valid = false
			continue
		if not _is_exact_address(value_candidate as RefCounted):
			_address_input_types_valid = false
			continue
		instance_ids.append(instance_id)
	instance_ids.sort_custom(_id_less_than)
	for instance_id: StringName in instance_ids:
		copied_addresses[instance_id] = (
			address_candidates[instance_id] as EnemyWorldAddressScript
		).copy()
	return copied_addresses


func _freeze_collections() -> void:
	_records.make_read_only()
	_addresses_by_instance_id.make_read_only()


func _sorted_address_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for instance_id: StringName in _addresses_by_instance_id:
		ids.append(instance_id)
	ids.sort_custom(_id_less_than)
	return ids


func _records_use_canonical_order() -> bool:
	for index: int in range(1, _records.size()):
		if (
			not _is_exact_record(_records[index - 1])
			or not _is_exact_record(_records[index])
			or String(_records[index].instance_id())
			< String(_records[index - 1].instance_id())
		):
			return false
	return true


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


static func _id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
