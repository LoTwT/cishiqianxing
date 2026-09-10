class_name WorldStepTransactionResult
extends RefCounted

const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepTransactionCandidateScript := preload("res://src/rules/world_step_transaction_candidate.gd")
const WorldStepTransactionEventScript := preload("res://src/rules/world_step_transaction_event.gd")

enum Status { REJECTED = 0, BLOCKED = 1, PREPARED = 2, COMMITTED = 3 }
enum RejectionReason {
	NONE = 0, INVALID_REGISTRY, INVALID_STATE, INVALID_COMMAND,
	UNSUPPORTED_SCENARIO, PROJECTION_MISMATCH, STALE_COMMAND, WORLD_STEP_LIMIT,
	MOVEMENT_REJECTED, CONTACT_REJECTED, COMBAT_REJECTED, INVALID_CANDIDATE,
	PRESTATE_MISMATCH, CONTACT_BINDING_MISMATCH, NEXT_STATE_REJECTED,
}

var _status: int = Status.REJECTED
var _integrity_status: int = Status.REJECTED
var _rejection_reason: int = RejectionReason.INVALID_CANDIDATE
var _integrity_rejection_reason: int = RejectionReason.INVALID_CANDIDATE
var _candidate: WorldStepTransactionCandidateScript
var _integrity_candidate: WorldStepTransactionCandidateScript
var _next_state: WorldStepStateScript
var _integrity_next_state: WorldStepStateScript
var _event: WorldStepTransactionEventScript
var _integrity_event: WorldStepTransactionEventScript


func is_prepared() -> bool:
	return _is_valid() and _status == Status.PREPARED


func was_committed() -> bool:
	return _is_valid() and _status == Status.COMMITTED


func is_blocked() -> bool:
	return _is_valid() and _status == Status.BLOCKED


func was_rejected() -> bool:
	return not _is_valid() or _status == Status.REJECTED


func rejection_reason() -> int:
	return _rejection_reason if _is_valid() else RejectionReason.INVALID_CANDIDATE


func candidate() -> WorldStepTransactionCandidateScript:
	return _candidate.copy() if is_prepared() or was_committed() else null


func next_state() -> WorldStepStateScript:
	return _next_state.copy() if was_committed() else null


func domain_events() -> Array[WorldStepTransactionEventScript]:
	return [_event.copy()] if was_committed() else []


func is_commit_boundary() -> bool:
	return was_committed()


func _is_valid() -> bool:
	if _status != _integrity_status or _rejection_reason != _integrity_rejection_reason:
		return false
	if _status in [Status.REJECTED, Status.BLOCKED]:
		return _candidate == null and _next_state == null and _event == null
	if not (
		_rejection_reason == RejectionReason.NONE
		and _candidate != null and _candidate.get_script() == WorldStepTransactionCandidateScript
		and _candidate.is_equal_to(_integrity_candidate)
	):
		return false
	if _status == Status.PREPARED:
		return _next_state == null and _event == null
	return (
		_status == Status.COMMITTED
		and _next_state != null and _next_state.get_script() == WorldStepStateScript
		and _next_state.is_equal_to(_integrity_next_state)
		and _event != null and _event.get_script() == WorldStepTransactionEventScript
		and _event.is_equal_to(_integrity_event)
		and _next_state.grid_state().world_step() == _event.world_step_after()
		and _next_state.enemy_world_state().world_step() == _event.world_step_after()
		and _next_state.grid_state().has_actor(&"actor.loer")
		and _next_state.grid_state().actor_position(&"actor.loer") == _event.player_cell_after()
		and _candidate.command().is_equal_to(_event.command())
	)


func _capture_integrity() -> void:
	_integrity_status = _status
	_integrity_rejection_reason = _rejection_reason
	_integrity_candidate = _candidate.copy() if _candidate != null else null
	_integrity_next_state = _next_state.copy() if _next_state != null else null
	_integrity_event = _event.copy() if _event != null else null
