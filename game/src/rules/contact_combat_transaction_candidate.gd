class_name ContactCombatTransactionCandidate
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContactCombatTransactionCommandScript := preload(
	"res://src/rules/contact_combat_transaction_command.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
)
const EnemyInstanceResolverScript := preload(
	"res://src/rules/enemy_instance_resolver.gd"
)
const EnemyWorldQueryResultScript := preload(
	"res://src/rules/enemy_world_query_result.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldResolutionResultScript := preload(
	"res://src/rules/enemy_world_resolution_result.gd"
)
const EnemyWorldResolverScript := preload(
	"res://src/rules/enemy_world_resolver.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const PermanentGrowthClaimKernelScript := preload(
	"res://src/rules/permanent_growth_claim_kernel.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PortableInventoryResolverScript := preload(
	"res://src/rules/portable_inventory_resolver.gd"
)
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

var _command: ContactCombatTransactionCommandScript
var _integrity_command: ContactCombatTransactionCommandScript
var _previous_player_state: PlayerProgressionStateScript
var _integrity_previous_player_state: PlayerProgressionStateScript
var _previous_enemy_world_state: EnemyWorldStateScript
var _integrity_previous_enemy_world_state: EnemyWorldStateScript
var _previous_inventory_state: PortableInventoryStateScript
var _integrity_previous_inventory_state: PortableInventoryStateScript
var _resolution: ContactCombatResolutionScript
var _integrity_resolution: ContactCombatResolutionScript
var _initialized: bool = false
var _integrity_initialized: bool = false


func copy() -> ContactCombatTransactionCandidate:
	var copied_candidate := new()
	if not _all_fields_have_exact_types():
		return copied_candidate
	copied_candidate._command = _command.copy()
	copied_candidate._integrity_command = _integrity_command.copy()
	copied_candidate._previous_player_state = _previous_player_state.copy()
	copied_candidate._integrity_previous_player_state = (
		_integrity_previous_player_state.copy()
	)
	copied_candidate._previous_enemy_world_state = _previous_enemy_world_state.copy()
	copied_candidate._integrity_previous_enemy_world_state = (
		_integrity_previous_enemy_world_state.copy()
	)
	copied_candidate._previous_inventory_state = _previous_inventory_state.copy()
	copied_candidate._integrity_previous_inventory_state = (
		_integrity_previous_inventory_state.copy()
	)
	copied_candidate._resolution = _resolution.copy()
	copied_candidate._integrity_resolution = _integrity_resolution.copy()
	copied_candidate._initialized = _initialized
	copied_candidate._integrity_initialized = _integrity_initialized
	return copied_candidate


func is_valid() -> bool:
	return (
		_initialized
		and _integrity_initialized
		and _all_fields_have_exact_types()
		and _integrity_copies_match()
		and _command.is_valid()
		and _previous_player_state.is_valid()
		and _previous_enemy_world_state.is_valid()
		and _previous_inventory_state.is_valid()
		and _resolution.is_resolution_candidate()
		and _transition_metadata_is_valid()
	)


func is_resolved_against(registry: RefCounted) -> bool:
	if not is_valid() or not _is_exact_initialized_registry(registry):
		return false
	var player_derivation = PermanentGrowthClaimKernelScript.derive_snapshot(
		_previous_player_state,
		registry,
	)
	if not player_derivation.succeeded():
		return false
	var next_player_state: PlayerProgressionStateScript = (
		PlayerProgressionStateScript.create(
			_previous_player_state.profile_id(),
			_previous_player_state.content_schema_version(),
			_previous_player_state.content_version(),
			_resolution.next_player_health(),
			_previous_player_state.claimed_reward_ids(),
		)
	)
	if not PermanentGrowthClaimKernelScript.derive_snapshot(
		next_player_state,
		registry,
	).succeeded():
		return false
	var world_resolution: EnemyWorldResolutionResultScript = (
		EnemyWorldResolverScript.resolve(_previous_enemy_world_state, registry)
	)
	if not world_resolution.succeeded():
		return false
	var inventory_resolution: PortableInventoryResolutionResultScript = (
		PortableInventoryResolverScript.resolve(_previous_inventory_state, registry)
	)
	return (
		inventory_resolution.succeeded()
		and _world_context_is_valid(world_resolution, registry)
		and _inventory_transition_is_possible(inventory_resolution)
	)


func command() -> ContactCombatTransactionCommandScript:
	return _command.copy() if is_valid() else null


func previous_player_state() -> PlayerProgressionStateScript:
	return _previous_player_state.copy() if is_valid() else null


func previous_enemy_world_state() -> EnemyWorldStateScript:
	return _previous_enemy_world_state.copy() if is_valid() else null


func previous_inventory_state() -> PortableInventoryStateScript:
	return _previous_inventory_state.copy() if is_valid() else null


func resolution() -> ContactCombatResolutionScript:
	return _resolution.copy() if is_valid() else null


func is_commit_boundary() -> bool:
	return false


func is_equal_to(other: ContactCombatTransactionCandidate) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and is_valid()
		and other.is_valid()
		and _command.is_equal_to(other._command)
		and _previous_player_state.is_equal_to(other._previous_player_state)
		and _previous_enemy_world_state.is_equal_to(
			other._previous_enemy_world_state
		)
		and _previous_inventory_state.is_equal_to(
			other._previous_inventory_state
		)
		and _resolution.is_equal_to(other._resolution)
	)


func _all_fields_have_exact_types() -> bool:
	return (
		_is_exact_transaction_command(_command)
		and _is_exact_transaction_command(_integrity_command)
		and _is_exact_player_state(_previous_player_state)
		and _is_exact_player_state(_integrity_previous_player_state)
		and _is_exact_enemy_world_state(_previous_enemy_world_state)
		and _is_exact_enemy_world_state(_integrity_previous_enemy_world_state)
		and _is_exact_inventory_state(_previous_inventory_state)
		and _is_exact_inventory_state(_integrity_previous_inventory_state)
		and _is_exact_resolution(_resolution)
		and _is_exact_resolution(_integrity_resolution)
	)


func _integrity_copies_match() -> bool:
	return (
		_initialized == _integrity_initialized
		and _command.is_equal_to(_integrity_command)
		and _previous_player_state.is_equal_to(_integrity_previous_player_state)
		and _previous_enemy_world_state.is_equal_to(
			_integrity_previous_enemy_world_state
		)
		and _previous_inventory_state.is_equal_to(
			_integrity_previous_inventory_state
		)
		and _resolution.is_equal_to(_integrity_resolution)
	)


func _transition_metadata_is_valid() -> bool:
	return (
		_resolution.opponent_instance_id() == _command.target_instance_id()
		and _resolution.initiator_side() == _command.initiator_side()
		and _resolution.supporting_opponents_alive()
		== _command.supporting_instance_ids().size()
		and _resolution.player_profile_id() == _previous_player_state.profile_id()
		and _resolution.content_schema_version()
		== _previous_player_state.content_schema_version()
		and _resolution.content_version()
		== _previous_player_state.content_version()
		and _resolution.previous_player_health()
		== _previous_player_state.current_health()
		and _resolution.temporary_effect()
		== _previous_inventory_state.selected_temporary_effect()
		and _resolution.temporary_effect_should_be_consumed()
		== (
			_resolution.temporary_effect()
			!= ContactCombatCommandScript.TemporaryEffect.NONE
		)
	)


func _world_context_is_valid(
	world_resolution: EnemyWorldResolutionResultScript,
	registry: RefCounted,
) -> bool:
	var target_query: EnemyWorldQueryResultScript = world_resolution.lookup_enemy(
		_command.target_instance_id()
	)
	if (
		not target_query.succeeded()
		or target_query.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE
		or not target_query.has_world_address()
		or not target_query.world_address().is_equal_to(_command.contact_address())
	):
		return false
	var target_resolution: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(target_query.instance_state(), registry)
	)
	if not target_resolution.succeeded():
		return false
	var target_opponent_state = target_resolution.contact_combat_opponent_state()
	if (
		target_opponent_state == null
		or _resolution.previous_opponent_durability()
		!= target_opponent_state.current_durability()
		or _resolution.opponent_shield_intact_before()
		!= target_opponent_state.shield_intact()
	):
		return false
	var target_space_id: StringName = _command.contact_address().space_id()
	for supporter_id: StringName in _command.supporting_instance_ids():
		var supporter_query: EnemyWorldQueryResultScript = (
			world_resolution.lookup_enemy(supporter_id)
		)
		if (
			not supporter_query.succeeded()
			or supporter_query.lifecycle()
			!= EnemyWorldRecordScript.Lifecycle.ACTIVE
			or not supporter_query.has_world_address()
			or supporter_query.world_address().space_id() != target_space_id
		):
			return false
	return _support_traits_are_valid(world_resolution, registry)


func _support_traits_are_valid(
	world_resolution: EnemyWorldResolutionResultScript,
	registry: RefCounted,
) -> bool:
	var participant_ids: Array[StringName] = _command.supporting_instance_ids()
	if participant_ids.is_empty():
		return true
	participant_ids.append(_command.target_instance_id())
	for participant_id: StringName in participant_ids:
		var query: EnemyWorldQueryResultScript = world_resolution.lookup_enemy(
			participant_id
		)
		if not query.succeeded():
			return false
		var instance_resolution: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(query.instance_state(), registry)
		)
		if (
			not instance_resolution.succeeded()
			or not instance_resolution.snapshot().combat_trait_ids().has(
				EnemyProfileDefinitionScript.SUPPORT_LINK_TRAIT_ID
			)
		):
			return false
	return true


func _inventory_transition_is_possible(
	inventory_resolution: PortableInventoryResolutionResultScript,
) -> bool:
	var inventory_state: PortableInventoryStateScript = inventory_resolution.snapshot()
	if not _resolution.temporary_effect_should_be_consumed():
		return true
	if inventory_state.revision() >= PortableInventoryStateScript.MAXIMUM_REVISION:
		return false
	var selected_stack_id: StringName = (
		inventory_state.selected_temporary_effect_stack_id()
	)
	return (
		not String(selected_stack_id).is_empty()
		and inventory_state.stack_snapshot(selected_stack_id) != null
		and inventory_state.selected_temporary_effect()
		== _resolution.temporary_effect()
	)


static func _is_exact_player_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PlayerProgressionStateScript
	)


static func _is_exact_enemy_world_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldStateScript
	)


static func _is_exact_inventory_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PortableInventoryStateScript
	)


static func _is_exact_transaction_command(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == ContactCombatTransactionCommandScript
	)


static func _is_exact_resolution(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == ContactCombatResolutionScript
	)


static func _is_exact_initialized_registry(registry: RefCounted) -> bool:
	return (
		registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
		and (registry as ContentRegistryScript).is_initialized()
	)
