class_name WorldStepTransactionCandidate
extends RefCounted

const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepCommandScript := preload("res://src/rules/world_step_command.gd")
const WorldStepContactLockScript := preload("res://src/rules/world_step_contact_lock.gd")
const ContactCombatTransactionCandidateScript := preload("res://src/rules/contact_combat_transaction_candidate.gd")

var _previous_state: WorldStepStateScript
var _integrity_previous_state: WorldStepStateScript
var _command: WorldStepCommandScript
var _integrity_command: WorldStepCommandScript
var _contact_lock: WorldStepContactLockScript
var _integrity_contact_lock: WorldStepContactLockScript
var _combat_candidate: ContactCombatTransactionCandidateScript
var _integrity_combat_candidate: ContactCombatTransactionCandidateScript
var _initialized: bool = false


func is_valid() -> bool:
	if not (
		_initialized
		and _previous_state != null and _previous_state.get_script() == WorldStepStateScript
		and _command != null and _command.get_script() == WorldStepCommandScript
		and _previous_state.is_valid() and _command.is_valid()
		and _previous_state.is_equal_to(_integrity_previous_state)
		and _command.is_equal_to(_integrity_command)
	):
		return false
	if _contact_lock == null:
		return _combat_candidate == null and _integrity_contact_lock == null and _integrity_combat_candidate == null
	return (
		_contact_lock.get_script() == WorldStepContactLockScript
		and _combat_candidate != null
		and _combat_candidate.get_script() == ContactCombatTransactionCandidateScript
		and _contact_lock.is_equal_to(_integrity_contact_lock)
		and _combat_candidate.is_equal_to(_integrity_combat_candidate)
	)


func copy() -> WorldStepTransactionCandidate:
	var result := new()
	if not is_valid():
		return result
	result._previous_state = _previous_state.copy()
	result._command = _command.copy()
	if _contact_lock != null:
		result._contact_lock = _contact_lock.copy()
		result._combat_candidate = _combat_candidate.copy()
	result._initialized = true
	result._capture_integrity()
	return result


func previous_state() -> WorldStepStateScript:
	return _previous_state.copy() if is_valid() else null


func command() -> WorldStepCommandScript:
	return _command.copy() if is_valid() else null


func contact_lock() -> WorldStepContactLockScript:
	return _contact_lock.copy() if is_valid() and _contact_lock != null else null


func combat_candidate() -> ContactCombatTransactionCandidateScript:
	return _combat_candidate.copy() if is_valid() and _combat_candidate != null else null


func is_commit_boundary() -> bool:
	return false


func is_equal_to(other: WorldStepTransactionCandidate) -> bool:
	if not (other != null and other.get_script() == get_script() and is_valid() and other.is_valid()):
		return false
	if not (_previous_state.is_equal_to(other._previous_state) and _command.is_equal_to(other._command)):
		return false
	if _contact_lock == null:
		return other._contact_lock == null
	return _contact_lock.is_equal_to(other._contact_lock) and _combat_candidate.is_equal_to(other._combat_candidate)


func _capture_integrity() -> void:
	_integrity_previous_state = _previous_state.copy()
	_integrity_command = _command.copy()
	_integrity_contact_lock = _contact_lock.copy() if _contact_lock != null else null
	_integrity_combat_candidate = _combat_candidate.copy() if _combat_candidate != null else null
