class_name ContactCombatTransactionCommand
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)

enum Kind {
	RESOLVE_CONTACT = 1,
}

var _kind: int = 0
var _target_instance_id: StringName = &""
var _contact_address: EnemyWorldAddressScript
var _supporting_instance_ids: Array[StringName] = []
var _initiator_side: int = 0
var _initialized: bool = false
var _contact_address_type_valid: bool = false
var _supporting_instance_id_types_valid: bool = true


func _init() -> void:
	_supporting_instance_ids.make_read_only()


static func resolve_contact(
	target_instance_id: StringName,
	contact_address_candidate: RefCounted,
	supporting_instance_id_candidates: Array,
	initiator_side: int,
) -> ContactCombatTransactionCommand:
	var command := new()
	command._kind = Kind.RESOLVE_CONTACT
	command._target_instance_id = target_instance_id
	if _is_exact_address(contact_address_candidate):
		command._contact_address = (
			contact_address_candidate as EnemyWorldAddressScript
		).copy()
		command._contact_address_type_valid = true
	command._supporting_instance_ids = command._copy_supporting_instance_ids(
		supporting_instance_id_candidates
	)
	command._supporting_instance_ids.sort_custom(_id_less_than)
	command._supporting_instance_ids.make_read_only()
	command._initiator_side = initiator_side
	command._initialized = true
	return command


func copy() -> ContactCombatTransactionCommand:
	var copied_command := new()
	copied_command._kind = _kind
	copied_command._target_instance_id = _target_instance_id
	if _is_exact_address(_contact_address):
		copied_command._contact_address = _contact_address.copy()
		copied_command._contact_address_type_valid = _contact_address_type_valid
	copied_command._supporting_instance_ids = _copy_ids(
		_supporting_instance_ids
	)
	copied_command._supporting_instance_ids.make_read_only()
	copied_command._initiator_side = _initiator_side
	copied_command._initialized = _initialized
	copied_command._supporting_instance_id_types_valid = (
		_supporting_instance_id_types_valid
	)
	return copied_command


func is_valid() -> bool:
	return (
		_initialized
		and _kind == Kind.RESOLVE_CONTACT
		and EnemyInstanceStateScript.is_valid_instance_id(_target_instance_id)
		and _contact_address_type_valid
		and _is_exact_address(_contact_address)
		and _contact_address.is_valid()
		and _supporting_instance_id_types_valid
		and _supporting_instance_ids.size() <= 2
		and _supporting_instance_ids_are_canonical_and_unique()
		and not _supporting_instance_ids.has(_target_instance_id)
		and _initiator_side in [
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.Side.OPPONENT,
		]
	)


func kind() -> int:
	return _kind


func target_instance_id() -> StringName:
	return _target_instance_id


func contact_address() -> EnemyWorldAddressScript:
	return _contact_address.copy() if is_valid() else null


func supporting_instance_ids() -> Array[StringName]:
	return _copy_ids(_supporting_instance_ids) if is_valid() else []


func initiator_side() -> int:
	return _initiator_side


func is_equal_to(other: ContactCombatTransactionCommand) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other._kind == _kind
		and other._target_instance_id == _target_instance_id
		and other._contact_address_type_valid == _contact_address_type_valid
		and _is_exact_address(_contact_address)
		and _is_exact_address(other._contact_address)
		and _contact_address.is_equal_to(other._contact_address)
		and other._supporting_instance_id_types_valid
		== _supporting_instance_id_types_valid
		and other._supporting_instance_ids == _supporting_instance_ids
		and other._initiator_side == _initiator_side
	)


func _copy_supporting_instance_ids(candidates: Array) -> Array[StringName]:
	var copied_ids: Array[StringName] = []
	for candidate: Variant in candidates:
		if typeof(candidate) != TYPE_STRING_NAME:
			_supporting_instance_id_types_valid = false
			continue
		copied_ids.append(candidate as StringName)
		if copied_ids.size() > 2:
			break
	return copied_ids


func _supporting_instance_ids_are_canonical_and_unique() -> bool:
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


static func _id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
