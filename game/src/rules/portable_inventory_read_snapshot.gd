class_name PortableInventoryReadSnapshot
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

var _state: PortableInventoryStateScript
var _integrity_state: PortableInventoryStateScript
var _initialized: bool = false


static func create(
	state_candidate: RefCounted,
	registry: RefCounted,
) -> PortableInventoryReadSnapshot:
	var snapshot := new()
	if (
		state_candidate != null
		and is_instance_valid(state_candidate)
		and state_candidate.get_script() == PortableInventoryStateScript
		and (state_candidate as PortableInventoryStateScript).is_resolved_against(
			registry
		)
	):
		snapshot._state = (state_candidate as PortableInventoryStateScript).copy()
		snapshot._integrity_state = snapshot._state.copy()
		snapshot._initialized = true
	return snapshot


func copy() -> PortableInventoryReadSnapshot:
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


func inventory_state() -> PortableInventoryStateScript:
	return _state.copy() if is_valid() else null


func content_schema_version() -> int:
	return _state.content_schema_version() if is_valid() else 0


func content_version() -> int:
	return _state.content_version() if is_valid() else 0


func capacity() -> int:
	return _state.capacity() if is_valid() else 0


func occupied_slot_count() -> int:
	return _state.occupied_slot_count() if is_valid() else 0


func available_slot_count() -> int:
	return _state.available_slot_count() if is_valid() else 0


func revision() -> int:
	return _state.revision() if is_valid() else 0


func stack_ids() -> Array[StringName]:
	return _state.stack_ids() if is_valid() else []


func stack_snapshots() -> Array[PortableInventoryStackScript]:
	if not is_valid():
		var empty_stacks: Array[PortableInventoryStackScript] = []
		return empty_stacks
	return _state.stack_snapshots()


func stack_snapshot(stack_id: StringName) -> PortableInventoryStackScript:
	return _state.stack_snapshot(stack_id) if is_valid() else null


func selected_temporary_effect_stack_id() -> StringName:
	return _state.selected_temporary_effect_stack_id() if is_valid() else &""


func selected_temporary_effect_blueprint_id() -> StringName:
	return _state.selected_temporary_effect_blueprint_id() if is_valid() else &""


func selected_temporary_effect() -> int:
	return (
		_state.selected_temporary_effect()
		if is_valid()
		else ContactCombatCommandScript.TemporaryEffect.NONE
	)


func is_equal_to(other: PortableInventoryReadSnapshot) -> bool:
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
		and candidate.get_script() == PortableInventoryStateScript
	)
