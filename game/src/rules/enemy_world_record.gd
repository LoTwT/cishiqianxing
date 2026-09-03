class_name EnemyWorldRecord
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)

enum Lifecycle {
	ACTIVE = 1,
	RESOLVED = 2,
}

var _instance_state: EnemyInstanceStateScript
var _lifecycle: int = 0
var _initialized: bool = false
var _instance_state_type_valid: bool = false


static func create(
	instance_state_candidate: RefCounted,
	lifecycle: int,
) -> EnemyWorldRecord:
	var record := new()
	record._lifecycle = lifecycle
	record._initialized = true
	if _is_exact_instance_state(instance_state_candidate):
		record._instance_state = (
			instance_state_candidate as EnemyInstanceStateScript
		).copy()
		record._instance_state_type_valid = true
	return record


func copy() -> EnemyWorldRecord:
	var copied_record := new()
	copied_record._lifecycle = _lifecycle
	copied_record._initialized = _initialized
	if _is_exact_instance_state(_instance_state):
		copied_record._instance_state = _instance_state.copy()
		copied_record._instance_state_type_valid = _instance_state_type_valid
	return copied_record


func is_valid() -> bool:
	if (
		not _initialized
		or not _instance_state_type_valid
		or not _is_exact_instance_state(_instance_state)
		or not _instance_state.is_valid()
	):
		return false
	if _lifecycle == Lifecycle.ACTIVE:
		return _instance_state.current_durability() > 0
	if _lifecycle == Lifecycle.RESOLVED:
		return _instance_state.current_durability() == 0
	return false


func is_initialized() -> bool:
	return _initialized


func lifecycle() -> int:
	return _lifecycle


func instance_id() -> StringName:
	if not _is_exact_instance_state(_instance_state):
		return &""
	return _instance_state.instance_id()


func instance_state() -> EnemyInstanceStateScript:
	if not _is_exact_instance_state(_instance_state):
		return null
	return _instance_state.copy()


func is_equal_to(other: EnemyWorldRecord) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other._instance_state_type_valid == _instance_state_type_valid
		and other._lifecycle == _lifecycle
		and _is_exact_instance_state(_instance_state)
		and _is_exact_instance_state(other._instance_state)
		and _instance_state.is_equal_to(other._instance_state)
	)


static func _is_exact_instance_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyInstanceStateScript
	)
