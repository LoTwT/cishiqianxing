class_name WorldStepTransactionEvent
extends RefCounted

const WorldStepCommandScript := preload("res://src/rules/world_step_command.gd")
const ContactCombatTransactionEventScript := preload("res://src/rules/contact_combat_transaction_event.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

var _command: WorldStepCommandScript
var _integrity_command: WorldStepCommandScript
var _player_cell_after: Vector3i = Vector3i.ZERO
var _integrity_player_cell_after: Vector3i = Vector3i.ZERO
var _world_step_after: int = -1
var _integrity_world_step_after: int = -1
var _combat_event: ContactCombatTransactionEventScript
var _integrity_combat_event: ContactCombatTransactionEventScript
var _initialized: bool = false


func is_valid() -> bool:
	if not (
		_initialized and _command != null and _command.get_script() == WorldStepCommandScript
		and _command.is_equal_to(_integrity_command)
		and _player_cell_after == _integrity_player_cell_after
		and _world_step_after == _integrity_world_step_after
		and _command.expected_world_step() < ValidationSupportScript.MAX_WORLD_STEP
		and _world_step_after == _command.expected_world_step() + 1
	):
		return false
	if _combat_event == null:
		return _integrity_combat_event == null and _player_cell_after == _command.expected_from_cell() + _command.direction()
	return (
		_combat_event.get_script() == ContactCombatTransactionEventScript
		and _combat_event.is_equal_to(_integrity_combat_event)
		and _combat_event.world_step() == _command.expected_world_step()
		and _player_cell_after == _command.expected_from_cell()
	)


func copy() -> WorldStepTransactionEvent:
	var result := new()
	if not is_valid():
		return result
	result._command = _command.copy()
	result._player_cell_after = _player_cell_after
	result._world_step_after = _world_step_after
	result._combat_event = _combat_event.copy() if _combat_event != null else null
	result._initialized = true
	result._capture_integrity()
	return result


func world_step_before() -> int:
	return _command.expected_world_step() if is_valid() else -1


func world_step_after() -> int:
	return _world_step_after if is_valid() else -1


func command() -> WorldStepCommandScript:
	return _command.copy() if is_valid() else null


func player_cell_after() -> Vector3i:
	return _player_cell_after


func combat_event() -> ContactCombatTransactionEventScript:
	return _combat_event.copy() if is_valid() and _combat_event != null else null


func is_commit_boundary() -> bool:
	return is_valid()


func is_equal_to(other: WorldStepTransactionEvent) -> bool:
	if not (other != null and other.get_script() == get_script() and is_valid() and other.is_valid()):
		return false
	if not (_command.is_equal_to(other._command) and _player_cell_after == other._player_cell_after and _world_step_after == other._world_step_after):
		return false
	return other._combat_event == null if _combat_event == null else _combat_event.is_equal_to(other._combat_event)


func _capture_integrity() -> void:
	_integrity_command = _command.copy()
	_integrity_player_cell_after = _player_cell_after
	_integrity_world_step_after = _world_step_after
	_integrity_combat_event = _combat_event.copy() if _combat_event != null else null
