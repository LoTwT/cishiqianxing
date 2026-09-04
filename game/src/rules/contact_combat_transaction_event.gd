class_name ContactCombatTransactionEvent
extends RefCounted

const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

enum Kind {
	COMMITTED = 1,
}

var _kind: int = 0
var _integrity_kind: int = 0
var _target_instance_id: StringName = &""
var _integrity_target_instance_id: StringName = &""
var _contact_address: EnemyWorldAddressScript
var _integrity_contact_address: EnemyWorldAddressScript
var _supporting_instance_ids: Array[StringName] = []
var _integrity_supporting_instance_ids: Array[StringName] = []
var _world_step: int = -1
var _integrity_world_step: int = -1
var _previous_inventory_revision: int = -1
var _integrity_previous_inventory_revision: int = -1
var _next_inventory_revision: int = -1
var _integrity_next_inventory_revision: int = -1
var _consumed_stack_id: StringName = &""
var _integrity_consumed_stack_id: StringName = &""
var _resolution: ContactCombatResolutionScript
var _integrity_resolution: ContactCombatResolutionScript
var _initialized: bool = false
var _integrity_initialized: bool = false


func _init() -> void:
	_supporting_instance_ids.make_read_only()
	_integrity_supporting_instance_ids.make_read_only()


func copy() -> ContactCombatTransactionEvent:
	var copied_event := new()
	copied_event._kind = _kind
	copied_event._integrity_kind = _integrity_kind
	copied_event._target_instance_id = _target_instance_id
	copied_event._integrity_target_instance_id = _integrity_target_instance_id
	if _is_exact_address(_contact_address):
		copied_event._contact_address = _contact_address.copy()
	if _is_exact_address(_integrity_contact_address):
		copied_event._integrity_contact_address = _integrity_contact_address.copy()
	copied_event._supporting_instance_ids = _copy_ids(_supporting_instance_ids)
	copied_event._supporting_instance_ids.make_read_only()
	copied_event._integrity_supporting_instance_ids = _copy_ids(
		_integrity_supporting_instance_ids
	)
	copied_event._integrity_supporting_instance_ids.make_read_only()
	copied_event._world_step = _world_step
	copied_event._integrity_world_step = _integrity_world_step
	copied_event._previous_inventory_revision = _previous_inventory_revision
	copied_event._integrity_previous_inventory_revision = (
		_integrity_previous_inventory_revision
	)
	copied_event._next_inventory_revision = _next_inventory_revision
	copied_event._integrity_next_inventory_revision = _integrity_next_inventory_revision
	copied_event._consumed_stack_id = _consumed_stack_id
	copied_event._integrity_consumed_stack_id = _integrity_consumed_stack_id
	if _is_exact_resolution(_resolution):
		copied_event._resolution = _resolution.copy()
	if _is_exact_resolution(_integrity_resolution):
		copied_event._integrity_resolution = _integrity_resolution.copy()
	copied_event._initialized = _initialized
	copied_event._integrity_initialized = _integrity_initialized
	return copied_event


func is_valid() -> bool:
	if (
		not _integrity_fields_match()
		or not _initialized
		or _kind != Kind.COMMITTED
		or not EnemyInstanceStateScript.is_valid_instance_id(_target_instance_id)
		or not _is_exact_address(_contact_address)
		or not _is_exact_address(_integrity_contact_address)
		or not _contact_address.is_valid()
		or not _contact_address.is_equal_to(_integrity_contact_address)
		or not _supporting_ids_are_valid()
		or _world_step < 0
		or _world_step > GridRuleStateScript.MAX_WORLD_STEP
		or _previous_inventory_revision < 0
		or _previous_inventory_revision
		> PortableInventoryStateScript.MAXIMUM_REVISION
		or _next_inventory_revision < 0
		or _next_inventory_revision > PortableInventoryStateScript.MAXIMUM_REVISION
		or not _is_exact_resolution(_resolution)
		or not _is_exact_resolution(_integrity_resolution)
		or not _resolution.is_resolution_candidate()
		or not _resolution.is_equal_to(_integrity_resolution)
		or _resolution.opponent_instance_id() != _target_instance_id
		or _resolution.supporting_opponents_alive()
		!= _supporting_instance_ids.size()
	):
		return false
	if _resolution.temporary_effect_should_be_consumed():
		return (
			PortableInventoryStackScript.is_valid_stack_id(_consumed_stack_id)
			and _previous_inventory_revision
			< PortableInventoryStateScript.MAXIMUM_REVISION
			and _next_inventory_revision == _previous_inventory_revision + 1
		)
	return (
		String(_consumed_stack_id).is_empty()
		and _next_inventory_revision == _previous_inventory_revision
	)


func kind() -> int:
	return _kind if is_valid() else 0


func target_instance_id() -> StringName:
	return _target_instance_id if is_valid() else &""


func contact_address() -> EnemyWorldAddressScript:
	return _contact_address.copy() if is_valid() else null


func supporting_instance_ids() -> Array[StringName]:
	return _copy_ids(_supporting_instance_ids) if is_valid() else []


func world_step() -> int:
	return _world_step if is_valid() else -1


func previous_inventory_revision() -> int:
	return _previous_inventory_revision if is_valid() else -1


func next_inventory_revision() -> int:
	return _next_inventory_revision if is_valid() else -1


func consumed_stack_id() -> StringName:
	return _consumed_stack_id if is_valid() else &""


func resolution() -> ContactCombatResolutionScript:
	return _resolution.copy() if is_valid() else null


func is_commit_boundary() -> bool:
	return is_valid() and _kind == Kind.COMMITTED


func is_equal_to(other: ContactCombatTransactionEvent) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and is_valid()
		and other.is_valid()
		and other._kind == _kind
		and other._target_instance_id == _target_instance_id
		and _contact_address.is_equal_to(other._contact_address)
		and other._supporting_instance_ids == _supporting_instance_ids
		and other._world_step == _world_step
		and other._previous_inventory_revision == _previous_inventory_revision
		and other._next_inventory_revision == _next_inventory_revision
		and other._consumed_stack_id == _consumed_stack_id
		and _resolution.is_equal_to(other._resolution)
	)


func _integrity_fields_match() -> bool:
	return (
		_initialized == _integrity_initialized
		and _kind == _integrity_kind
		and _target_instance_id == _integrity_target_instance_id
		and _supporting_instance_ids == _integrity_supporting_instance_ids
		and _world_step == _integrity_world_step
		and _previous_inventory_revision
		== _integrity_previous_inventory_revision
		and _next_inventory_revision == _integrity_next_inventory_revision
		and _consumed_stack_id == _integrity_consumed_stack_id
	)


func _supporting_ids_are_valid() -> bool:
	if (
		_supporting_instance_ids.size() > 2
		or _supporting_instance_ids.has(_target_instance_id)
	):
		return false
	for index: int in range(_supporting_instance_ids.size()):
		var instance_id: StringName = _supporting_instance_ids[index]
		if not EnemyInstanceStateScript.is_valid_instance_id(instance_id):
			return false
		if (
			index > 0
			and String(instance_id)
			<= String(_supporting_instance_ids[index - 1])
		):
			return false
	return true


static func _copy_ids(ids: Array[StringName]) -> Array[StringName]:
	var copied_ids: Array[StringName] = []
	for instance_id: StringName in ids:
		copied_ids.append(instance_id)
	return copied_ids


static func _is_exact_address(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldAddressScript
	)


static func _is_exact_resolution(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == ContactCombatResolutionScript
	)
