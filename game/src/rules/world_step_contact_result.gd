class_name WorldStepContactResult
extends RefCounted

const WorldStepContactLockScript := preload(
	"res://src/rules/world_step_contact_lock.gd"
)

enum Status {
	NO_CONTACT = 1,
	LOCKED = 2,
	CANCELLED = 3,
	REJECTED = 4,
}

enum CancellationReason {
	NONE = 0,
	PLAYER_INACTIVE = 1,
	ENEMY_INACTIVE = 2,
}

enum RejectionReason {
	NONE = 0,
	INVALID_REGISTRY = 1,
	INVALID_GRID_STATE = 2,
	INVALID_PLAYER_STATE = 3,
	PLAYER_INACTIVE = 4,
	ENEMY_WORLD_STATE_REJECTED = 5,
	INVALID_COMMAND = 6,
	WORLD_STEP_MISMATCH = 7,
	PLAYER_IDENTITY_CONFLICT = 8,
	PLAYER_ACTOR_MISSING = 9,
	ENEMY_GRID_PROJECTION_MISMATCH = 10,
	MOVING_ACTOR_MISSING = 11,
	FROM_CELL_MISMATCH = 12,
	COORDINATE_OVERFLOW = 13,
	TARGET_OUT_OF_BOUNDS = 14,
	TARGET_BLOCKED = 15,
	INVALID_LOCKED_RESULT = 16,
	CONTACT_PRESTATE_MISMATCH = 17,
	INVALID_RESULT = 18,
}

var _status: int = Status.REJECTED
var _integrity_status: int = Status.REJECTED
var _cancellation_reason: int = CancellationReason.NONE
var _integrity_cancellation_reason: int = CancellationReason.NONE
var _rejection_reason: int = RejectionReason.INVALID_RESULT
var _integrity_rejection_reason: int = RejectionReason.INVALID_RESULT
var _contact_lock: WorldStepContactLockScript
var _integrity_contact_lock: WorldStepContactLockScript
var _registry_validation_passed: bool = false
var _integrity_registry_validation_passed: bool = false


static func rejected(rejection_reason_value: int) -> WorldStepContactResult:
	var result := new()
	result._status = Status.REJECTED
	result._integrity_status = result._status
	result._rejection_reason = rejection_reason_value
	result._integrity_rejection_reason = result._rejection_reason
	return result


func status() -> int:
	return _status if _is_well_formed() else Status.REJECTED


func cancellation_reason() -> int:
	return (
		_cancellation_reason
		if _is_well_formed()
		else CancellationReason.NONE
	)


func rejection_reason() -> int:
	return (
		_rejection_reason
		if _is_well_formed()
		else RejectionReason.INVALID_RESULT
	)


func has_no_contact() -> bool:
	return status() == Status.NO_CONTACT


func is_locked() -> bool:
	return status() == Status.LOCKED


func was_cancelled() -> bool:
	return status() == Status.CANCELLED


func was_rejected() -> bool:
	return status() == Status.REJECTED


func contact_lock() -> WorldStepContactLockScript:
	return (
		_contact_lock.copy()
		if (
			_is_well_formed()
			and _status in [Status.LOCKED, Status.CANCELLED]
			and _contact_lock != null
		)
		else null
	)


func is_actor_locked(actor_id: StringName) -> bool:
	return is_locked() and _contact_lock.is_actor_locked(actor_id)


func is_commit_boundary() -> bool:
	return false


func is_equal_to(other: WorldStepContactResult) -> bool:
	if (
		other == null
		or not is_instance_valid(other)
		or other.get_script() != get_script()
		or not _is_well_formed()
		or not other._is_well_formed()
		or other._status != _status
		or other._cancellation_reason != _cancellation_reason
		or other._rejection_reason != _rejection_reason
	):
		return false
	if _contact_lock == null or other._contact_lock == null:
		return _contact_lock == null and other._contact_lock == null
	return _contact_lock.is_equal_to(other._contact_lock)


func _is_well_formed() -> bool:
	if (
		_status != _integrity_status
		or _cancellation_reason != _integrity_cancellation_reason
		or _rejection_reason != _integrity_rejection_reason
		or _registry_validation_passed
		!= _integrity_registry_validation_passed
	):
		return false
	if _status == Status.REJECTED:
		return (
			_rejection_reason > RejectionReason.NONE
			and _rejection_reason < RejectionReason.INVALID_RESULT
			and _cancellation_reason == CancellationReason.NONE
			and _contact_lock == null
			and _integrity_contact_lock == null
			and not _registry_validation_passed
		)
	if (
		_rejection_reason != RejectionReason.NONE
		or not _registry_validation_passed
	):
		return false
	if _status == Status.NO_CONTACT:
		return (
			_cancellation_reason == CancellationReason.NONE
			and _contact_lock == null
			and _integrity_contact_lock == null
		)
	if (
		not _is_exact_contact_lock(_contact_lock)
		or not _is_exact_contact_lock(_integrity_contact_lock)
		or not _contact_lock.is_valid()
		or not _contact_lock.is_equal_to(_integrity_contact_lock)
	):
		return false
	if _status == Status.LOCKED:
		return _cancellation_reason == CancellationReason.NONE
	if _status == Status.CANCELLED:
		return _cancellation_reason in [
			CancellationReason.PLAYER_INACTIVE,
			CancellationReason.ENEMY_INACTIVE,
		]
	return false


static func _is_exact_contact_lock(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == WorldStepContactLockScript
	)
