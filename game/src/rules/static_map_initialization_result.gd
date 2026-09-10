class_name StaticMapInitializationResult
extends RefCounted

const WorldStepStateScript := preload("res://src/rules/world_step_state.gd")
const WorldStepTransactionEventScript := preload("res://src/rules/world_step_transaction_event.gd")

enum FailureReason {
	NONE = 0,
	INVALID_REGISTRY,
	INVALID_MAP_ID,
	UNKNOWN_MAP_ID,
	INVALID_PLAYER_STATE,
	INVALID_INVENTORY_STATE,
	CONTENT_VERSION_MISMATCH,
	INVALID_MAP_DEFINITION,
	INITIAL_STATE_REJECTED,
}

var _failure_reason: int = FailureReason.INITIAL_STATE_REJECTED
var _world_state: WorldStepStateScript
var _integrity_world_state: WorldStepStateScript


func succeeded() -> bool:
	return (
		_failure_reason == FailureReason.NONE
		and _world_state != null and _world_state.get_script() == WorldStepStateScript
		and _world_state.is_valid() and _world_state.is_equal_to(_integrity_world_state)
		and _world_state.grid_state().world_step() == 0
		and _world_state.enemy_world_state().world_step() == 0
	)


func failure_reason() -> int:
	if _failure_reason == FailureReason.NONE and not succeeded():
		return FailureReason.INITIAL_STATE_REJECTED
	return _failure_reason


func world_state() -> WorldStepStateScript:
	return _world_state.copy() if succeeded() else null


func is_commit_boundary() -> bool:
	return false


func domain_events() -> Array[WorldStepTransactionEventScript]:
	return []
