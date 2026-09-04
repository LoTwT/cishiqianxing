class_name ContactCombatTransactionResult
extends RefCounted

const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContactCombatTransactionCandidateScript := preload(
	"res://src/rules/contact_combat_transaction_candidate.gd"
)
const ContactCombatTransactionEventScript := preload(
	"res://src/rules/contact_combat_transaction_event.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

enum Status {
	PREPARED = 1,
	BLOCKED = 2,
	COMMITTED = 3,
	REJECTED = 4,
}

enum RejectionReason {
	NONE = 0,
	INVALID_PLAYER_STATE = 1,
	INVALID_REGISTRY = 2,
	ENEMY_WORLD_STATE_REJECTED = 3,
	INVENTORY_STATE_REJECTED = 4,
	INVALID_COMMAND = 5,
	UNKNOWN_TARGET = 6,
	TARGET_INACTIVE = 7,
	CONTACT_ADDRESS_MISMATCH = 8,
	UNKNOWN_SUPPORTER = 9,
	SUPPORTER_INACTIVE = 10,
	SUPPORTER_SPACE_MISMATCH = 11,
	SUPPORT_LINK_TRAIT_MISMATCH = 12,
	INVENTORY_REVISION_OVERFLOW = 13,
	COMBAT_REJECTED = 14,
	INVALID_PREPARED_RESULT = 15,
	PLAYER_PRESTATE_MISMATCH = 16,
	ENEMY_WORLD_PRESTATE_MISMATCH = 17,
	INVENTORY_PRESTATE_MISMATCH = 18,
	NEXT_STATE_REJECTED = 19,
	INVALID_RESULT = 20,
}

var _status: int = Status.REJECTED
var _integrity_status: int = Status.REJECTED
var _rejection_reason: int = RejectionReason.INVALID_RESULT
var _integrity_rejection_reason: int = RejectionReason.INVALID_RESULT
var _combat_rejection_reason: int = ContactCombatResultScript.RejectionReason.NONE
var _integrity_combat_rejection_reason: int = (
	ContactCombatResultScript.RejectionReason.NONE
)
var _candidate: ContactCombatTransactionCandidateScript
var _integrity_candidate: ContactCombatTransactionCandidateScript
var _blocked_resolution: ContactCombatResolutionScript
var _integrity_blocked_resolution: ContactCombatResolutionScript
var _domain_event: ContactCombatTransactionEventScript
var _integrity_domain_event: ContactCombatTransactionEventScript
var _committed_player_state: PlayerProgressionStateScript
var _integrity_committed_player_state: PlayerProgressionStateScript
var _committed_enemy_world_state: EnemyWorldStateScript
var _integrity_committed_enemy_world_state: EnemyWorldStateScript
var _committed_inventory_state: PortableInventoryStateScript
var _integrity_committed_inventory_state: PortableInventoryStateScript
var _registry_validation_passed: bool = false
var _integrity_registry_validation_passed: bool = false


static func blocked(
	resolution_value: RefCounted,
	registry: RefCounted,
) -> ContactCombatTransactionResult:
	var result := new()
	if not _is_exact_resolution(resolution_value):
		return result
	result._status = Status.BLOCKED
	result._integrity_status = result._status
	result._rejection_reason = RejectionReason.NONE
	result._integrity_rejection_reason = result._rejection_reason
	result._combat_rejection_reason = ContactCombatResultScript.RejectionReason.NONE
	result._integrity_combat_rejection_reason = result._combat_rejection_reason
	result._blocked_resolution = (
		resolution_value as ContactCombatResolutionScript
	).copy()
	result._integrity_blocked_resolution = result._blocked_resolution.copy()
	result._registry_validation_passed = _is_exact_initialized_registry(registry)
	result._integrity_registry_validation_passed = (
		result._registry_validation_passed
	)
	return result


static func rejected(
	rejection_reason_value: int,
	combat_rejection_reason_value: int = (
		ContactCombatResultScript.RejectionReason.NONE
	),
) -> ContactCombatTransactionResult:
	var result := new()
	result._status = Status.REJECTED
	result._integrity_status = result._status
	result._rejection_reason = rejection_reason_value
	result._integrity_rejection_reason = result._rejection_reason
	result._combat_rejection_reason = combat_rejection_reason_value
	result._integrity_combat_rejection_reason = result._combat_rejection_reason
	return result


func status() -> int:
	return _status if _is_well_formed() else Status.REJECTED


func rejection_reason() -> int:
	return (
		_rejection_reason
		if _is_well_formed()
		else RejectionReason.INVALID_RESULT
	)


func combat_rejection_reason() -> int:
	return (
		_combat_rejection_reason
		if _is_well_formed()
		else ContactCombatResultScript.RejectionReason.NONE
	)


func is_prepared() -> bool:
	return status() == Status.PREPARED


func is_blocked() -> bool:
	return status() == Status.BLOCKED


func was_committed() -> bool:
	return status() == Status.COMMITTED


func was_rejected() -> bool:
	return status() == Status.REJECTED


func candidate() -> ContactCombatTransactionCandidateScript:
	return _candidate.copy() if _is_well_formed() and _candidate != null else null


func resolution() -> ContactCombatResolutionScript:
	if not _is_well_formed():
		return null
	if _status == Status.BLOCKED:
		return _blocked_resolution.copy()
	return _candidate.resolution() if _candidate != null else null


func player_state() -> PlayerProgressionStateScript:
	return (
		_committed_player_state.copy()
		if was_committed() and _committed_player_state != null
		else null
	)


func enemy_world_state() -> EnemyWorldStateScript:
	return (
		_committed_enemy_world_state.copy()
		if was_committed() and _committed_enemy_world_state != null
		else null
	)


func inventory_state() -> PortableInventoryStateScript:
	return (
		_committed_inventory_state.copy()
		if was_committed() and _committed_inventory_state != null
		else null
	)


func domain_events() -> Array[ContactCombatTransactionEventScript]:
	var events: Array[ContactCombatTransactionEventScript] = []
	if was_committed() and _domain_event != null:
		events.append(_domain_event.copy())
	return events


func is_commit_boundary() -> bool:
	return (
		was_committed()
		and _domain_event != null
		and _domain_event.is_commit_boundary()
	)


func _is_well_formed() -> bool:
	if not _integrity_scalar_fields_match():
		return false
	if _status == Status.REJECTED:
		return (
			_rejection_reason > RejectionReason.NONE
			and _rejection_reason < RejectionReason.INVALID_RESULT
			and _candidate == null
			and _integrity_candidate == null
			and _blocked_resolution == null
			and _integrity_blocked_resolution == null
			and _domain_event == null
			and _integrity_domain_event == null
			and _committed_states_are_absent()
			and not _registry_validation_passed
			and (
				(
					_rejection_reason == RejectionReason.COMBAT_REJECTED
					and _combat_rejection_reason
					> ContactCombatResultScript.RejectionReason.NONE
					and _combat_rejection_reason
					< ContactCombatResultScript.RejectionReason.INVALID_RESULT
				)
				or (
					_rejection_reason != RejectionReason.COMBAT_REJECTED
					and _combat_rejection_reason
					== ContactCombatResultScript.RejectionReason.NONE
				)
			)
		)
	if (
		_rejection_reason != RejectionReason.NONE
		or _combat_rejection_reason
		!= ContactCombatResultScript.RejectionReason.NONE
		or not _registry_validation_passed
	):
		return false
	if _status == Status.BLOCKED:
		return (
			_is_exact_resolution(_blocked_resolution)
			and _is_exact_resolution(_integrity_blocked_resolution)
			and _blocked_resolution.is_valid()
			and not _blocked_resolution.is_resolution_candidate()
			and _blocked_resolution.block_reason()
			== ContactCombatResolutionScript.BlockReason.PLAYER_DAMAGE_ZERO
			and _blocked_resolution.is_equal_to(_integrity_blocked_resolution)
			and _candidate == null
			and _integrity_candidate == null
			and _domain_event == null
			and _integrity_domain_event == null
			and _committed_states_are_absent()
		)
	if (
		not _is_exact_candidate(_candidate)
		or not _is_exact_candidate(_integrity_candidate)
		or not _candidate.is_valid()
		or not _candidate.is_equal_to(_integrity_candidate)
		or _blocked_resolution != null
		or _integrity_blocked_resolution != null
	):
		return false
	if _status == Status.PREPARED:
		return (
			_domain_event == null
			and _integrity_domain_event == null
			and _committed_states_are_absent()
		)
	if _status == Status.COMMITTED:
		return (
			_is_exact_event(_domain_event)
			and _is_exact_event(_integrity_domain_event)
			and _domain_event.is_commit_boundary()
			and _domain_event.is_equal_to(_integrity_domain_event)
			and _committed_states_are_valid()
			and _event_matches_candidate_and_states(
				_domain_event,
				_candidate,
				_committed_player_state,
				_committed_enemy_world_state,
				_committed_inventory_state,
			)
		)
	return false


func _integrity_scalar_fields_match() -> bool:
	return (
		_status == _integrity_status
		and _rejection_reason == _integrity_rejection_reason
		and _combat_rejection_reason == _integrity_combat_rejection_reason
		and _registry_validation_passed
		== _integrity_registry_validation_passed
	)


func _committed_states_are_absent() -> bool:
	return (
		_committed_player_state == null
		and _integrity_committed_player_state == null
		and _committed_enemy_world_state == null
		and _integrity_committed_enemy_world_state == null
		and _committed_inventory_state == null
		and _integrity_committed_inventory_state == null
	)


func _committed_states_are_valid() -> bool:
	return (
		_is_exact_player_state(_committed_player_state)
		and _is_exact_player_state(_integrity_committed_player_state)
		and _committed_player_state.is_valid()
		and _committed_player_state.is_equal_to(_integrity_committed_player_state)
		and _is_exact_enemy_world_state(_committed_enemy_world_state)
		and _is_exact_enemy_world_state(_integrity_committed_enemy_world_state)
		and _committed_enemy_world_state.is_valid()
		and _committed_enemy_world_state.is_equal_to(
			_integrity_committed_enemy_world_state
		)
		and _is_exact_inventory_state(_committed_inventory_state)
		and _is_exact_inventory_state(_integrity_committed_inventory_state)
		and _committed_inventory_state.is_valid()
		and _committed_inventory_state.is_equal_to(
			_integrity_committed_inventory_state
		)
	)


static func _event_matches_candidate_and_states(
	event: ContactCombatTransactionEventScript,
	candidate_value: ContactCombatTransactionCandidateScript,
	committed_player_state: PlayerProgressionStateScript,
	committed_enemy_world_state: EnemyWorldStateScript,
	committed_inventory_state: PortableInventoryStateScript,
) -> bool:
	var command = candidate_value.command()
	var previous_world = candidate_value.previous_enemy_world_state()
	var previous_inventory = candidate_value.previous_inventory_state()
	var previous_player = candidate_value.previous_player_state()
	var candidate_resolution = candidate_value.resolution()
	var expected_consumed_stack_id: StringName = &""
	if candidate_resolution.temporary_effect_should_be_consumed():
		expected_consumed_stack_id = (
			previous_inventory.selected_temporary_effect_stack_id()
		)
	return (
		event.target_instance_id() == command.target_instance_id()
		and event.contact_address().is_equal_to(command.contact_address())
		and event.supporting_instance_ids() == command.supporting_instance_ids()
		and event.world_step() == previous_world.world_step()
		and event.previous_inventory_revision() == previous_inventory.revision()
		and event.next_inventory_revision() == committed_inventory_state.revision()
		and event.consumed_stack_id() == expected_consumed_stack_id
		and event.resolution().is_equal_to(candidate_resolution)
		and committed_player_state.profile_id() == previous_player.profile_id()
		and committed_player_state.content_schema_version()
		== previous_player.content_schema_version()
		and committed_player_state.content_version()
		== previous_player.content_version()
		and committed_player_state.claimed_reward_ids()
		== previous_player.claimed_reward_ids()
		and committed_player_state.current_health()
		== candidate_resolution.next_player_health()
		and committed_enemy_world_state.world_step() == previous_world.world_step()
	)


static func _is_exact_candidate(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == ContactCombatTransactionCandidateScript
	)


static func _is_exact_resolution(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == ContactCombatResolutionScript
	)


static func _is_exact_event(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == ContactCombatTransactionEventScript
	)


static func _is_exact_player_state(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == PlayerProgressionStateScript
	)


static func _is_exact_enemy_world_state(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == EnemyWorldStateScript
	)


static func _is_exact_inventory_state(candidate_value: RefCounted) -> bool:
	return (
		candidate_value != null
		and is_instance_valid(candidate_value)
		and candidate_value.get_script() == PortableInventoryStateScript
	)


static func _is_exact_initialized_registry(registry: RefCounted) -> bool:
	return (
		registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
		and (registry as ContentRegistryScript).is_initialized()
	)
