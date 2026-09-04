class_name ContactCombatTransactionKernel
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatKernelScript := preload(
	"res://src/rules/contact_combat_kernel.gd"
)
const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
)
const ContactCombatTransactionCandidateScript := preload(
	"res://src/rules/contact_combat_transaction_candidate.gd"
)
const ContactCombatTransactionCommandScript := preload(
	"res://src/rules/contact_combat_transaction_command.gd"
)
const ContactCombatTransactionEventScript := preload(
	"res://src/rules/contact_combat_transaction_event.gd"
)
const ContactCombatTransactionResultScript := preload(
	"res://src/rules/contact_combat_transaction_result.gd"
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
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
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
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryResolverScript := preload(
	"res://src/rules/portable_inventory_resolver.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

static func prepare(
	player_state_candidate: RefCounted,
	enemy_world_state_candidate: RefCounted,
	inventory_state_candidate: RefCounted,
	command_candidate: RefCounted,
	registry: RefCounted,
) -> ContactCombatTransactionResultScript:
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_REGISTRY
		)
	if not _is_exact_player_state(player_state_candidate):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PLAYER_STATE
		)
	var player_state: PlayerProgressionStateScript = (
		player_state_candidate as PlayerProgressionStateScript
	).copy()
	if (
		not player_state.is_valid()
		or not PermanentGrowthClaimKernelScript.derive_snapshot(
			player_state,
			registry,
		).succeeded()
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PLAYER_STATE
		)

	var world_resolution: EnemyWorldResolutionResultScript = (
		EnemyWorldResolverScript.resolve(enemy_world_state_candidate, registry)
	)
	if not world_resolution.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.ENEMY_WORLD_STATE_REJECTED
		)
	var inventory_resolution: PortableInventoryResolutionResultScript = (
		PortableInventoryResolverScript.resolve(inventory_state_candidate, registry)
	)
	if not inventory_resolution.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVENTORY_STATE_REJECTED
		)
	if not _is_exact_command(command_candidate):
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_COMMAND
		)
	var command: ContactCombatTransactionCommandScript = (
		command_candidate as ContactCombatTransactionCommandScript
	).copy()
	if not command.is_valid():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_COMMAND
		)

	var target_query: EnemyWorldQueryResultScript = world_resolution.lookup_enemy(
		command.target_instance_id()
	)
	if not target_query.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.UNKNOWN_TARGET
		)
	if target_query.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.TARGET_INACTIVE
		)
	if (
		not target_query.has_world_address()
		or not target_query.world_address().is_equal_to(command.contact_address())
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.CONTACT_ADDRESS_MISMATCH
		)

	var support_rejection_reason: int = _validate_support_context(
		world_resolution,
		command,
		registry,
	)
	if support_rejection_reason != ContactCombatTransactionResultScript.RejectionReason.NONE:
		return _rejected(support_rejection_reason)
	var target_instance_resolution: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(target_query.instance_state(), registry)
	)
	if not target_instance_resolution.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
		)
	var inventory_state: PortableInventoryStateScript = inventory_resolution.snapshot()
	var combat_command: ContactCombatCommandScript = ContactCombatCommandScript.evaluate(
		command.initiator_side(),
		inventory_state.selected_temporary_effect(),
		command.supporting_instance_ids().size(),
	)
	var combat_result: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		target_instance_resolution.contact_combat_opponent_state(),
		combat_command,
		registry,
	)
	if combat_result.is_blocked():
		var blocked_result: ContactCombatTransactionResultScript = (
			ContactCombatTransactionResultScript.blocked(
				combat_result.resolution(),
				registry,
			)
		)
		return (
			blocked_result
			if blocked_result.is_blocked()
			else _rejected(
				ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
			)
		)
	if combat_result.is_rejected():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.COMBAT_REJECTED,
			combat_result.rejection_reason(),
		)
	if (
		combat_result.resolution().temporary_effect_should_be_consumed()
		and inventory_state.revision()
		>= PortableInventoryStateScript.MAXIMUM_REVISION
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVENTORY_REVISION_OVERFLOW
		)

	var resolution = combat_result.resolution()
	if resolution == null or not resolution.is_resolution_candidate():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
		)
	var candidate := ContactCombatTransactionCandidateScript.new()
	candidate._command = command.copy()
	candidate._previous_player_state = player_state.copy()
	candidate._previous_enemy_world_state = world_resolution.snapshot()
	candidate._previous_inventory_state = inventory_state.copy()
	candidate._resolution = resolution.copy()
	candidate._initialized = true
	candidate._capture_integrity()
	if not candidate.is_resolved_against(registry):
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
		)
	var prepared_result := ContactCombatTransactionResultScript.new()
	prepared_result._status = ContactCombatTransactionResultScript.Status.PREPARED
	prepared_result._rejection_reason = (
		ContactCombatTransactionResultScript.RejectionReason.NONE
	)
	prepared_result._combat_rejection_reason = (
		ContactCombatResultScript.RejectionReason.NONE
	)
	prepared_result._candidate = candidate.copy()
	prepared_result._registry_validation_passed = true
	prepared_result._capture_integrity()
	return (
		prepared_result
		if prepared_result.is_prepared()
		else _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
		)
	)


static func commit(
	current_player_state_candidate: RefCounted,
	current_enemy_world_state_candidate: RefCounted,
	current_inventory_state_candidate: RefCounted,
	prepared_result_candidate: RefCounted,
	registry: RefCounted,
) -> ContactCombatTransactionResultScript:
	if (
		prepared_result_candidate == null
		or not is_instance_valid(prepared_result_candidate)
		or (
			prepared_result_candidate.get_script()
			!= ContactCombatTransactionResultScript
		)
		or not (
			prepared_result_candidate as ContactCombatTransactionResultScript
		).is_prepared()
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PREPARED_RESULT
		)
	if not ContentRegistryScript.is_exact_initialized_instance(registry):
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_REGISTRY
		)
	var prepared_result: ContactCombatTransactionResultScript = (
		prepared_result_candidate as ContactCombatTransactionResultScript
	)
	var candidate: ContactCombatTransactionCandidateScript = (
		prepared_result.candidate()
	)
	if candidate == null or not candidate.is_resolved_against(registry):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PREPARED_RESULT
		)

	if not _is_exact_player_state(current_player_state_candidate):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PLAYER_STATE
		)
	var current_player_state: PlayerProgressionStateScript = (
		current_player_state_candidate as PlayerProgressionStateScript
	).copy()
	if (
		not current_player_state.is_valid()
		or not PermanentGrowthClaimKernelScript.derive_snapshot(
			current_player_state,
			registry,
		).succeeded()
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVALID_PLAYER_STATE
		)
	var current_world_resolution: EnemyWorldResolutionResultScript = (
		EnemyWorldResolverScript.resolve(
			current_enemy_world_state_candidate,
			registry,
		)
	)
	if not current_world_resolution.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.ENEMY_WORLD_STATE_REJECTED
		)
	var current_inventory_resolution: PortableInventoryResolutionResultScript = (
		PortableInventoryResolverScript.resolve(
			current_inventory_state_candidate,
			registry,
		)
	)
	if not current_inventory_resolution.succeeded():
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVENTORY_STATE_REJECTED
		)

	if not current_player_state.is_equal_to(candidate.previous_player_state()):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.PLAYER_PRESTATE_MISMATCH
		)
	if not current_world_resolution.snapshot().is_equal_to(
		candidate.previous_enemy_world_state()
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.ENEMY_WORLD_PRESTATE_MISMATCH
		)
	if not current_inventory_resolution.snapshot().is_equal_to(
		candidate.previous_inventory_state()
	):
		return _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.INVENTORY_PRESTATE_MISMATCH
		)

	var transaction_command: ContactCombatTransactionCommandScript = candidate.command()
	var resolution = candidate.resolution()
	var current_world_state: EnemyWorldStateScript = current_world_resolution.snapshot()
	var current_inventory_state: PortableInventoryStateScript = (
		current_inventory_resolution.snapshot()
	)
	if transaction_command == null or resolution == null:
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
		)

	var next_player_state: PlayerProgressionStateScript = (
		PlayerProgressionStateScript.create(
			current_player_state.profile_id(),
			current_player_state.content_schema_version(),
			current_player_state.content_version(),
			resolution.next_player_health(),
			current_player_state.claimed_reward_ids(),
		)
	)
	if not PermanentGrowthClaimKernelScript.derive_snapshot(
		next_player_state,
		registry,
	).succeeded():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
		)

	var next_world_records: Array[EnemyWorldRecordScript] = []
	var target_record_found: bool = false
	for record: EnemyWorldRecordScript in current_world_resolution.record_snapshots():
		if record.instance_id() != transaction_command.target_instance_id():
			next_world_records.append(record.copy())
			continue
		target_record_found = true
		var previous_instance_state: EnemyInstanceStateScript = record.instance_state()
		var next_instance_state: EnemyInstanceStateScript = EnemyInstanceStateScript.create(
			previous_instance_state.instance_id(),
			previous_instance_state.profile_id(),
			previous_instance_state.content_schema_version(),
			previous_instance_state.content_version(),
			resolution.next_opponent_durability(),
			previous_instance_state.state_kind(),
			resolution.opponent_shield_intact_after(),
		)
		var next_lifecycle: int = EnemyWorldRecordScript.Lifecycle.ACTIVE
		if resolution.next_opponent_durability() == 0:
			next_lifecycle = EnemyWorldRecordScript.Lifecycle.RESOLVED
		next_world_records.append(
			EnemyWorldRecordScript.create(next_instance_state, next_lifecycle)
		)
	if not target_record_found:
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
		)
	var next_world_addresses: Dictionary[StringName, EnemyWorldAddressScript] = (
		current_world_resolution.address_snapshots()
	)
	if resolution.next_opponent_durability() == 0:
		next_world_addresses.erase(transaction_command.target_instance_id())
	var next_enemy_world_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		next_world_records,
		next_world_addresses,
		current_world_state.world_step(),
	)
	if not EnemyWorldResolverScript.resolve(
		next_enemy_world_state,
		registry,
	).succeeded():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
		)

	var consumed_stack_id: StringName = &""
	var next_inventory_state: PortableInventoryStateScript
	if resolution.temporary_effect_should_be_consumed():
		consumed_stack_id = (
			current_inventory_state.selected_temporary_effect_stack_id()
		)
		var selected_stack: PortableInventoryStackScript = (
			current_inventory_state.stack_snapshot(consumed_stack_id)
		)
		if (
			String(consumed_stack_id).is_empty()
			or selected_stack == null
			or current_inventory_state.revision()
			>= PortableInventoryStateScript.MAXIMUM_REVISION
			or current_inventory_state.selected_temporary_effect()
			!= resolution.temporary_effect()
		):
			return _rejected(
				ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
			)
		var next_stacks: Array[PortableInventoryStackScript] = []
		for stack: PortableInventoryStackScript in (
			current_inventory_state.stack_snapshots()
		):
			if stack.stack_id() != consumed_stack_id:
				next_stacks.append(stack.copy())
				continue
			if stack.quantity() > 1:
				next_stacks.append(
					PortableInventoryStackScript.create(
						stack.stack_id(),
						stack.blueprint_id(),
						stack.provenance(),
						stack.source_recipe_id(),
						stack.quantity() - 1,
					)
				)
		next_inventory_state = PortableInventoryStateScript.create(
			current_inventory_state.content_schema_version(),
			current_inventory_state.content_version(),
			current_inventory_state.capacity(),
			current_inventory_state.revision() + 1,
			next_stacks,
			&"",
		)
	else:
		next_inventory_state = current_inventory_state.copy()
	if not PortableInventoryResolverScript.resolve(
		next_inventory_state,
		registry,
	).succeeded():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.NEXT_STATE_REJECTED
		)

	var domain_event := ContactCombatTransactionEventScript.new()
	domain_event._kind = ContactCombatTransactionEventScript.Kind.COMMITTED
	domain_event._target_instance_id = transaction_command.target_instance_id()
	domain_event._contact_address = transaction_command.contact_address()
	domain_event._supporting_instance_ids = transaction_command.supporting_instance_ids()
	domain_event._supporting_instance_ids.make_read_only()
	domain_event._world_step = current_world_state.world_step()
	domain_event._previous_inventory_revision = current_inventory_state.revision()
	domain_event._next_inventory_revision = next_inventory_state.revision()
	domain_event._consumed_stack_id = consumed_stack_id
	domain_event._resolution = resolution.copy()
	domain_event._initialized = true
	domain_event._capture_integrity()
	if not domain_event.is_commit_boundary():
		return _rejected(
			ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
		)
	var committed_result := ContactCombatTransactionResultScript.new()
	committed_result._status = ContactCombatTransactionResultScript.Status.COMMITTED
	committed_result._rejection_reason = (
		ContactCombatTransactionResultScript.RejectionReason.NONE
	)
	committed_result._combat_rejection_reason = (
		ContactCombatResultScript.RejectionReason.NONE
	)
	committed_result._candidate = candidate.copy()
	committed_result._domain_event = domain_event.copy()
	committed_result._committed_player_state = next_player_state.copy()
	committed_result._committed_enemy_world_state = next_enemy_world_state.copy()
	committed_result._committed_inventory_state = next_inventory_state.copy()
	committed_result._registry_validation_passed = true
	committed_result._capture_integrity()
	return (
		committed_result
		if committed_result.was_committed()
		else _rejected(
			ContactCombatTransactionResultScript
			.RejectionReason
			.NEXT_STATE_REJECTED
		)
	)


static func _validate_support_context(
	world_resolution: EnemyWorldResolutionResultScript,
	command: ContactCombatTransactionCommandScript,
	registry: RefCounted,
) -> int:
	var supporter_ids: Array[StringName] = command.supporting_instance_ids()
	if supporter_ids.is_empty():
		return ContactCombatTransactionResultScript.RejectionReason.NONE
	var participant_ids: Array[StringName] = []
	participant_ids.append(command.target_instance_id())
	participant_ids.append_array(supporter_ids)
	var target_space_id: StringName = command.contact_address().space_id()
	for participant_id: StringName in participant_ids:
		var query: EnemyWorldQueryResultScript = world_resolution.lookup_enemy(
			participant_id
		)
		if not query.succeeded():
			return (
				ContactCombatTransactionResultScript.RejectionReason.UNKNOWN_SUPPORTER
				if participant_id != command.target_instance_id()
				else ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT
			)
		if query.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
			return (
				ContactCombatTransactionResultScript.RejectionReason.SUPPORTER_INACTIVE
				if participant_id != command.target_instance_id()
				else ContactCombatTransactionResultScript.RejectionReason.TARGET_INACTIVE
			)
		if (
			not query.has_world_address()
			or query.world_address().space_id() != target_space_id
		):
			return (
				ContactCombatTransactionResultScript
				.RejectionReason
				.SUPPORTER_SPACE_MISMATCH
			)
		var instance_resolution: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(query.instance_state(), registry)
		)
		if (
			not instance_resolution.succeeded()
			or not instance_resolution.snapshot().combat_trait_ids().has(
				EnemyProfileDefinitionScript.SUPPORT_LINK_TRAIT_ID
			)
		):
			return (
				ContactCombatTransactionResultScript
				.RejectionReason
				.SUPPORT_LINK_TRAIT_MISMATCH
			)
	return ContactCombatTransactionResultScript.RejectionReason.NONE


static func _rejected(
	rejection_reason: int,
	combat_rejection_reason: int = ContactCombatResultScript.RejectionReason.NONE,
) -> ContactCombatTransactionResultScript:
	return ContactCombatTransactionResultScript.rejected(
		rejection_reason,
		combat_rejection_reason,
	)


static func _is_exact_player_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == PlayerProgressionStateScript
	)


static func _is_exact_command(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == ContactCombatTransactionCommandScript
	)


