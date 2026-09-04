class_name TemporaryEffectSelectionResult
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryReadSnapshotScript := preload(
	"res://src/rules/portable_inventory_read_snapshot.gd"
)
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)
const TemporaryEffectSelectionCommandScript := preload(
	"res://src/rules/temporary_effect_selection_command.gd"
)

enum Status {
	SELECTED = 1,
	UNCHANGED = 2,
	CONFIRMATION_REQUIRED = 3,
	REJECTED = 4,
}

enum RejectionReason {
	NONE = 0,
	INVENTORY_STATE_REJECTED = 1,
	INVALID_COMMAND = 2,
	INVALID_EXPECTED_REVISION = 3,
	STALE_REVISION = 4,
	EMPTY_STACK_ID = 5,
	INVALID_STACK_ID = 6,
	UNKNOWN_STACK_ID = 7,
	STACK_NOT_TEMPORARY_EFFECT = 8,
	REVISION_OVERFLOW = 9,
	NEXT_STATE_REJECTED = 10,
	INVALID_RESULT = 11,
}

var _status: int = Status.REJECTED
var _integrity_status: int = Status.REJECTED
var _rejection_reason: int = RejectionReason.INVALID_RESULT
var _integrity_rejection_reason: int = RejectionReason.INVALID_RESULT
var _inventory_failure_reason: int = (
	PortableInventoryResolutionResultScript.FailureReason.NONE
)
var _integrity_inventory_failure_reason: int = (
	PortableInventoryResolutionResultScript.FailureReason.NONE
)
var _requested_stack_id: StringName = &""
var _integrity_requested_stack_id: StringName = &""
var _command: TemporaryEffectSelectionCommandScript
var _integrity_command: TemporaryEffectSelectionCommandScript
var _previous_read_snapshot: PortableInventoryReadSnapshotScript
var _read_snapshot: PortableInventoryReadSnapshotScript


func _init(
	status: int,
	rejection_reason: int,
	inventory_failure_reason: int,
	requested_stack_id: StringName,
	command_candidate: RefCounted,
	previous_resolution: PortableInventoryResolutionResultScript,
	resolution: PortableInventoryResolutionResultScript,
) -> void:
	_status = status
	_integrity_status = status
	_rejection_reason = rejection_reason
	_integrity_rejection_reason = rejection_reason
	_inventory_failure_reason = inventory_failure_reason
	_integrity_inventory_failure_reason = inventory_failure_reason
	_requested_stack_id = requested_stack_id
	_integrity_requested_stack_id = requested_stack_id
	if _is_exact_command(command_candidate):
		_command = (
			command_candidate as TemporaryEffectSelectionCommandScript
		).copy()
		_integrity_command = _command.copy()
	if _is_successful_resolution(previous_resolution):
		_previous_read_snapshot = previous_resolution.read_snapshot()
	if _is_successful_resolution(resolution):
		_read_snapshot = resolution.read_snapshot()


static func selected(
	command: TemporaryEffectSelectionCommandScript,
	previous_resolution: PortableInventoryResolutionResultScript,
	resolution: PortableInventoryResolutionResultScript,
) -> TemporaryEffectSelectionResult:
	var requested_stack_id: StringName = _stack_id_from_exact_command(command)
	return new(
		Status.SELECTED,
		RejectionReason.NONE,
		PortableInventoryResolutionResultScript.FailureReason.NONE,
		requested_stack_id,
		command,
		previous_resolution,
		resolution,
	)


static func unchanged(
	command: TemporaryEffectSelectionCommandScript,
	resolution: PortableInventoryResolutionResultScript,
) -> TemporaryEffectSelectionResult:
	var requested_stack_id: StringName = _stack_id_from_exact_command(command)
	return new(
		Status.UNCHANGED,
		RejectionReason.NONE,
		PortableInventoryResolutionResultScript.FailureReason.NONE,
		requested_stack_id,
		command,
		null,
		resolution,
	)


static func confirmation_required(
	command: TemporaryEffectSelectionCommandScript,
	resolution: PortableInventoryResolutionResultScript,
) -> TemporaryEffectSelectionResult:
	var requested_stack_id: StringName = _stack_id_from_exact_command(command)
	return new(
		Status.CONFIRMATION_REQUIRED,
		RejectionReason.NONE,
		PortableInventoryResolutionResultScript.FailureReason.NONE,
		requested_stack_id,
		command,
		null,
		resolution,
	)


static func rejected(
	requested_stack_id: StringName,
	rejection_reason: int,
	inventory_failure_reason: int = (
		PortableInventoryResolutionResultScript.FailureReason.NONE
	),
) -> TemporaryEffectSelectionResult:
	return new(
		Status.REJECTED,
		rejection_reason,
		inventory_failure_reason,
		requested_stack_id,
		null,
		null,
		null,
	)


func status() -> int:
	return _status if _is_well_formed() else Status.REJECTED


func rejection_reason() -> int:
	return (
		_rejection_reason
		if _is_well_formed()
		else RejectionReason.INVALID_RESULT
	)


func inventory_failure_reason() -> int:
	return (
		_inventory_failure_reason
		if _is_well_formed()
		else PortableInventoryResolutionResultScript.FailureReason.NONE
	)


func requested_stack_id() -> StringName:
	return _requested_stack_id if _integrity_fields_match() else &""


func was_selected() -> bool:
	return status() == Status.SELECTED


func was_unchanged() -> bool:
	return status() == Status.UNCHANGED


func needs_replacement_confirmation() -> bool:
	return status() == Status.CONFIRMATION_REQUIRED


func was_rejected() -> bool:
	return status() == Status.REJECTED


func is_selection_candidate() -> bool:
	return status() == Status.SELECTED


func is_commit_boundary() -> bool:
	return false


func command() -> TemporaryEffectSelectionCommandScript:
	return _command.copy() if _is_well_formed() and _command != null else null


func previous_read_snapshot() -> PortableInventoryReadSnapshotScript:
	return (
		_previous_read_snapshot.copy()
		if _is_well_formed() and _previous_read_snapshot != null
		else null
	)


func read_snapshot() -> PortableInventoryReadSnapshotScript:
	return (
		_read_snapshot.copy()
		if _is_well_formed() and _read_snapshot != null
		else null
	)


func next_state() -> PortableInventoryStateScript:
	return _read_snapshot.inventory_state() if _is_well_formed() and _read_snapshot != null else null


func selected_temporary_effect_stack_id() -> StringName:
	return (
		_read_snapshot.selected_temporary_effect_stack_id()
		if _is_well_formed() and _read_snapshot != null
		else &""
	)


func selected_temporary_effect() -> int:
	return (
		_read_snapshot.selected_temporary_effect()
		if _is_well_formed() and _read_snapshot != null
		else ContactCombatCommandScript.TemporaryEffect.NONE
	)


func matches_exact_prestate(
	expected: PortableInventoryResolutionResultScript,
) -> bool:
	if not _is_well_formed() or not _is_successful_resolution(expected):
		return false
	var prestate_snapshot: PortableInventoryReadSnapshotScript = (
		_previous_read_snapshot
		if _status == Status.SELECTED
		else _read_snapshot
	)
	return (
		prestate_snapshot != null
		and prestate_snapshot.is_equal_to(expected._read_snapshot)
	)


func _is_well_formed() -> bool:
	if not _integrity_fields_match():
		return false
	if _status == Status.REJECTED:
		return (
			_rejection_reason > RejectionReason.NONE
			and _rejection_reason < RejectionReason.INVALID_RESULT
			and _command == null
			and _integrity_command == null
			and _previous_read_snapshot == null
			and _read_snapshot == null
			and (
				(
					_rejection_reason
					== RejectionReason.INVENTORY_STATE_REJECTED
					and _inventory_failure_reason
					> PortableInventoryResolutionResultScript.FailureReason.NONE
					and _inventory_failure_reason
					< PortableInventoryResolutionResultScript.FailureReason.INVALID_RESULT
				)
				or (
					_rejection_reason
					!= RejectionReason.INVENTORY_STATE_REJECTED
					and _inventory_failure_reason
					== PortableInventoryResolutionResultScript.FailureReason.NONE
				)
			)
		)
	if (
		_rejection_reason != RejectionReason.NONE
		or _inventory_failure_reason
		!= PortableInventoryResolutionResultScript.FailureReason.NONE
		or not _commands_are_equal(_command, _integrity_command)
		or not _is_exact_valid_snapshot(_read_snapshot)
	):
		return false
	var prestate_snapshot: PortableInventoryReadSnapshotScript = (
		_previous_read_snapshot
		if _status == Status.SELECTED
		else _read_snapshot
	)
	if (
		prestate_snapshot == null
		or _command.stack_id() != _requested_stack_id
		or _command.expected_revision() != prestate_snapshot.revision()
	):
		return false
	if _status == Status.SELECTED:
		return (
			_is_exact_valid_snapshot(_previous_read_snapshot)
			and _selection_transition_is_valid()
		)
	if _previous_read_snapshot != null:
		return false
	if _status == Status.UNCHANGED:
		return (
			_read_snapshot.selected_temporary_effect_stack_id()
			== _requested_stack_id
			and _read_snapshot.selected_temporary_effect()
			!= ContactCombatCommandScript.TemporaryEffect.NONE
		)
	if _status == Status.CONFIRMATION_REQUIRED:
		return (
			not String(
				_read_snapshot.selected_temporary_effect_stack_id()
			).is_empty()
			and _read_snapshot.revision()
			< PortableInventoryStateScript.MAXIMUM_REVISION
			and (
				_read_snapshot.selected_temporary_effect_stack_id()
				!= _requested_stack_id
			)
			and _requested_stack_is_temporary_effect(_read_snapshot)
			and not _command.replacement_confirmed()
		)
	return false


func _selection_transition_is_valid() -> bool:
	var previous_selected_stack_id: StringName = (
		_previous_read_snapshot.selected_temporary_effect_stack_id()
	)
	if (
		_previous_read_snapshot.revision()
		>= PortableInventoryStateScript.MAXIMUM_REVISION
		or _read_snapshot.revision()
		!= _previous_read_snapshot.revision() + 1
		or (
			_read_snapshot.selected_temporary_effect_stack_id()
			!= _requested_stack_id
		)
		or not _requested_stack_is_temporary_effect(_read_snapshot)
		or _read_snapshot.content_schema_version()
		!= _previous_read_snapshot.content_schema_version()
		or _read_snapshot.content_version()
		!= _previous_read_snapshot.content_version()
		or _read_snapshot.capacity() != _previous_read_snapshot.capacity()
		or _read_snapshot.stack_ids() != _previous_read_snapshot.stack_ids()
		or previous_selected_stack_id == _requested_stack_id
		or (
			not String(previous_selected_stack_id).is_empty()
			and not _command.replacement_confirmed()
		)
	):
		return false
	for stack_id: StringName in _read_snapshot.stack_ids():
		var previous_stack: PortableInventoryStackScript = (
			_previous_read_snapshot.stack_snapshot(stack_id)
		)
		var next_stack: PortableInventoryStackScript = (
			_read_snapshot.stack_snapshot(stack_id)
		)
		if (
			previous_stack == null
			or next_stack == null
			or not previous_stack.is_equal_to(next_stack)
		):
			return false
	return true


func _requested_stack_is_temporary_effect(
	snapshot: PortableInventoryReadSnapshotScript,
) -> bool:
	var stack: PortableInventoryStackScript = snapshot.stack_snapshot(
		_requested_stack_id
	)
	return (
		stack != null
		and PortableInventoryStateScript.temporary_effect_for_blueprint_id(
			stack.blueprint_id()
		)
		!= ContactCombatCommandScript.TemporaryEffect.NONE
	)


func _integrity_fields_match() -> bool:
	return (
		_status == _integrity_status
		and _rejection_reason == _integrity_rejection_reason
		and _inventory_failure_reason == _integrity_inventory_failure_reason
		and _requested_stack_id == _integrity_requested_stack_id
	)


static func _commands_are_equal(
	left: TemporaryEffectSelectionCommandScript,
	right: TemporaryEffectSelectionCommandScript,
) -> bool:
	return (
		_is_exact_command(left)
		and _is_exact_command(right)
		and left.is_valid()
		and right.is_valid()
		and left.kind() == right.kind()
		and left.stack_id() == right.stack_id()
		and left.expected_revision() == right.expected_revision()
		and left.replacement_confirmed() == right.replacement_confirmed()
	)


static func _is_exact_command(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == TemporaryEffectSelectionCommandScript
	)


static func _stack_id_from_exact_command(candidate: RefCounted) -> StringName:
	if not _is_exact_command(candidate):
		return &""
	return (candidate as TemporaryEffectSelectionCommandScript).stack_id()


static func _is_exact_valid_snapshot(
	candidate: PortableInventoryReadSnapshotScript,
) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryReadSnapshotScript
		and candidate.is_valid()
	)


static func _is_successful_resolution(
	candidate: PortableInventoryResolutionResultScript,
) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryResolutionResultScript
		and candidate.succeeded()
	)
