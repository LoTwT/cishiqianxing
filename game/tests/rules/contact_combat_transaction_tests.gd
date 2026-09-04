extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
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
const ContactCombatTransactionKernelScript := preload(
	"res://src/rules/contact_combat_transaction_kernel.gd"
)
const ContactCombatTransactionResultScript := preload(
	"res://src/rules/contact_combat_transaction_result.gd"
)
const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
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
const EnemyWorldResolverScript := preload(
	"res://src/rules/enemy_world_resolver.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)

const CONTENT_SCHEMA_VERSION: int = 5
const CONTENT_VERSION: int = 5
const PLAYER_PROFILE_ID: StringName = &"progression.player.loer"
const SIMPLE_PROFILE_ID: StringName = &"enemy.profile.f01.base"
const SHIELD_PROFILE_ID: StringName = &"enemy.profile.f03.base"
const SUPPORT_PROFILE_ID: StringName = &"enemy.profile.f05.base"
const TARGET_ID: StringName = &"enemy.instance.contact.target"
const SUPPORTER_ALPHA_ID: StringName = &"enemy.instance.contact.support.alpha"
const SUPPORTER_BETA_ID: StringName = &"enemy.instance.contact.support.beta"
const SPACE_ID: StringName = &"space.contact.transaction"
const TARGET_CELL: Vector3i = Vector3i(4, 0, -3)
const WORLD_STEP: int = 41
const EFFECT_STACK_ID: StringName = &"stack.effect.attack"

var _cached_registry: ContentRegistryScript


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"contact_transaction.prepares_without_publishing_authoritative_state",
			_prepares_without_publishing_authoritative_state,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.keeps_commit_construction_internal",
			_keeps_commit_construction_internal,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.commits_world_player_and_inventory_atomically",
			_commits_world_player_and_inventory_atomically,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.consumes_last_selected_stack",
			_consumes_last_selected_stack,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.keeps_surviving_target_active",
			_keeps_surviving_target_active,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.blocks_zero_damage_without_consumption",
			_blocks_zero_damage_without_consumption,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.rejects_each_stale_authoritative_prestate",
			_rejects_each_stale_authoritative_prestate,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.validates_contact_and_support_context",
			_validates_contact_and_support_context,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.rejects_invalid_inputs_and_revision_overflow",
			_rejects_invalid_inputs_and_revision_overflow,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.isolates_outputs_and_fails_closed",
			_isolates_outputs_and_fails_closed,
		),
		HeadlessTestCaseScript.new(
			"contact_transaction.replays_deterministically",
			_replays_deterministically,
		),
	]


func _prepares_without_publishing_authoritative_state(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _simple_world()
	var inventory_state: PortableInventoryStateScript = _inventory([], 3)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Simple contact")
	if not prepared.is_prepared():
		return
	var candidate: ContactCombatTransactionCandidateScript = prepared.candidate()
	context.expect_true(candidate.is_valid(), "Prepared candidate is internally valid.")
	context.expect_true(
		candidate.is_resolved_against(registry),
		"Prepared candidate remains tied to the sealed Registry.",
	)
	context.expect_true(
		not candidate.is_commit_boundary(),
		"A prepared candidate is not an authoritative commit boundary.",
	)
	context.expect_equal(
		candidate.previous_enemy_world_state().world_step(),
		WORLD_STEP,
		"Candidate binds the exact world-step token.",
	)
	context.expect_true(
		prepared.player_state() == null
		and prepared.enemy_world_state() == null
		and prepared.inventory_state() == null,
		"Prepared results publish no authoritative replacement states.",
	)
	context.expect_true(
		prepared.domain_events().is_empty(),
		"Preparation emits no committed domain event.",
	)


func _keeps_commit_construction_internal(
	context: HeadlessTestContextScript,
) -> void:
	context.expect_true(
		not _script_declares_method(
			ContactCombatTransactionEventScript,
			&"_from_verified_commit",
		),
		"The committed event has no callable construction factory.",
	)
	context.expect_true(
		not _script_declares_method(
			ContactCombatTransactionResultScript,
			&"_from_verified_commit",
		),
		"The committed result has no callable construction factory.",
	)
	context.expect_true(
		not _script_declares_method(
			ContactCombatTransactionResultScript,
			&"prepared",
		),
		"A PREPARED result has no callable construction factory.",
	)
	context.expect_true(
		not _script_declares_method(
			ContactCombatTransactionCandidateScript,
			&"from_evaluation",
		)
		and not _script_declares_method(
			ContactCombatTransactionCandidateScript,
			&"_capture_verified_transition",
		),
		"A transaction candidate has no callable initializer or verifier marker.",
	)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			_player_state(100),
			_simple_world(),
			_inventory([], 3),
			_simple_command(),
			_canonical_registry(context),
		)
	)
	_expect_prepared(context, prepared, "Internal construction fixture")
	if not prepared.is_prepared():
		return
	var candidate: ContactCombatTransactionCandidateScript = prepared.candidate()
	context.expect_true(
		not candidate.has_method(&"proposed_player_state")
		and not candidate.has_method(&"proposed_enemy_world_state")
		and not candidate.has_method(&"proposed_inventory_state")
		and not candidate.has_method(&"_proposed_player_state_for_verified_commit")
		and not candidate.has_method(&"_proposed_enemy_world_state_for_verified_commit")
		and not candidate.has_method(&"_proposed_inventory_state_for_verified_commit"),
		"A prepared candidate exposes no authoritative replacement-state getters.",
	)
	context.expect_true(
		not _object_declares_property(candidate, &"_proposed_player_state")
		and not _object_declares_property(candidate, &"_proposed_enemy_world_state")
		and not _object_declares_property(candidate, &"_proposed_inventory_state"),
		"A prepared candidate carries no authoritative replacement states.",
	)
	context.expect_true(
		candidate.resolution() != null,
		"A prepared candidate still exposes its non-committing combat resolution.",
	)


func _commits_world_player_and_inventory_atomically(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _support_world()
	var inventory_state: PortableInventoryStateScript = _selected_inventory(2, 7)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_support_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Supported effect contact")
	if not prepared.is_prepared():
		return
	var preview_resolution: ContactCombatResolutionScript = prepared.resolution()
	context.expect_equal(
		preview_resolution.supporting_opponents_alive(),
		2,
		"The bound supporter set projects the full +2 support count.",
	)
	context.expect_equal(
		preview_resolution.temporary_effect(),
		ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
		"The selected concrete stack projects attack +2.",
	)
	context.expect_equal(
		preview_resolution.next_player_health(),
		2,
		"The committed fixture retains the exact previewed health result.",
	)

	var committed: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_committed(context, committed, "Supported effect contact")
	if not committed.was_committed():
		return
	context.expect_equal(
		committed.player_state().current_health(),
		preview_resolution.next_player_health(),
		"Committed player health equals the prepared candidate exactly.",
	)
	var committed_world = EnemyWorldResolverScript.resolve(
		committed.enemy_world_state(),
		registry,
	)
	context.expect_true(committed_world.succeeded(), "Committed world resolves.")
	var target_query: EnemyWorldQueryResultScript = committed_world.lookup_enemy(
		TARGET_ID
	)
	context.expect_equal(
		target_query.lifecycle(),
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
		"A cleared target becomes a stable RESOLVED world record.",
	)
	context.expect_equal(
		target_query.instance_state().current_durability(),
		0,
		"The target receives the prepared zero-durability result.",
	)
	context.expect_true(
		not target_query.has_world_address(),
		"A resolved target releases its world address.",
	)
	for supporter_id: StringName in [SUPPORTER_ALPHA_ID, SUPPORTER_BETA_ID]:
		var supporter_query: EnemyWorldQueryResultScript = (
			committed_world.lookup_enemy(supporter_id)
		)
		context.expect_equal(
			supporter_query.lifecycle(),
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
			"Non-target supporter remains active: %s" % supporter_id,
		)
		context.expect_true(
			supporter_query.has_world_address(),
			"Non-target supporter retains its address: %s" % supporter_id,
		)
	var next_inventory: PortableInventoryStateScript = committed.inventory_state()
	context.expect_equal(next_inventory.revision(), 8, "Consumption advances revision once.")
	context.expect_equal(
		next_inventory.selected_temporary_effect_stack_id(),
		&"",
		"Consumption clears the next-battle selection.",
	)
	context.expect_equal(
		next_inventory.stack_snapshot(EFFECT_STACK_ID).quantity(),
		1,
		"Consumption decrements exactly one item from the selected stack.",
	)
	context.expect_equal(
		committed.enemy_world_state().world_step(),
		WORLD_STEP,
		"The phase-seven subtransaction does not claim a full world-step advance.",
	)
	var events: Array[ContactCombatTransactionEventScript] = committed.domain_events()
	context.expect_equal(events.size(), 1, "Atomic commit emits one domain event.")
	if events.size() == 1:
		context.expect_true(events[0].is_commit_boundary(), "Event marks the commit boundary.")
		context.expect_equal(
			events[0].target_instance_id(),
			TARGET_ID,
			"Event binds target identity.",
		)
		context.expect_equal(
			events[0].supporting_instance_ids(),
			[SUPPORTER_ALPHA_ID, SUPPORTER_BETA_ID],
			"Event binds the canonical supporter set.",
		)
		context.expect_equal(
			events[0].consumed_stack_id(),
			EFFECT_STACK_ID,
			"Event names the exact consumed stack.",
		)


func _consumes_last_selected_stack(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _simple_world()
	var inventory_state: PortableInventoryStateScript = _selected_inventory(1, 11)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Last-stack effect contact")
	if not prepared.is_prepared():
		return
	var committed: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_committed(context, committed, "Last-stack effect contact")
	if not committed.was_committed():
		return
	var next_inventory: PortableInventoryStateScript = committed.inventory_state()
	context.expect_equal(next_inventory.revision(), 12, "Last-item use advances revision.")
	context.expect_true(
		next_inventory.stack_snapshot(EFFECT_STACK_ID) == null,
		"The selected stack is removed when its final item is consumed.",
	)
	context.expect_equal(
		next_inventory.stack_ids(),
		[&"stack.utility"],
		"Unrelated inventory stacks are retained exactly.",
	)


func _keeps_surviving_target_active(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(9)
	var world_state: EnemyWorldStateScript = _single_enemy_world(
		SHIELD_PROFILE_ID,
		12,
		WORLD_STEP,
		true,
	)
	var inventory_state: PortableInventoryStateScript = _inventory([], 6)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Player-incapacitation contact")
	if not prepared.is_prepared():
		return
	context.expect_equal(
		prepared.resolution().outcome(),
		ContactCombatResolutionScript.Outcome.PLAYER_INCAPACITATED,
		"Fixture prepares the player-incapacitated branch.",
	)
	context.expect_true(
		prepared.resolution().opponent_shield_absorbed_attack(),
		"The surviving target's shield absorption is part of the candidate.",
	)
	var committed: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_committed(context, committed, "Player-incapacitation contact")
	if not committed.was_committed():
		return
	context.expect_equal(
		committed.player_state().current_health(),
		0,
		"Committed player state applies incapacitation.",
	)
	var committed_world = EnemyWorldResolverScript.resolve(
		committed.enemy_world_state(),
		registry,
	)
	context.expect_true(committed_world.succeeded(), "Surviving-target world resolves.")
	var target_query: EnemyWorldQueryResultScript = committed_world.lookup_enemy(
		TARGET_ID
	)
	context.expect_equal(
		target_query.lifecycle(),
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		"A surviving target remains ACTIVE.",
	)
	context.expect_equal(
		target_query.instance_state().current_durability(),
		12,
		"The shield absorbed the player's only attack before incapacitation.",
	)
	context.expect_true(
		not target_query.instance_state().shield_intact(),
		"The committed target preserves the previewed broken shield.",
	)
	context.expect_true(
		target_query.world_address().is_equal_to(_target_address()),
		"A surviving target retains the exact contact address.",
	)
	context.expect_true(
		committed.inventory_state().is_equal_to(inventory_state),
		"A battle without a selected effect leaves inventory exact.",
	)
	context.expect_equal(
		committed.domain_events()[0].consumed_stack_id(),
		&"",
		"The commit event records no inventory consumption.",
	)


func _blocks_zero_damage_without_consumption(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _single_enemy_world(
		SUPPORT_PROFILE_ID,
		14,
	)
	var empty_inventory: PortableInventoryStateScript = _inventory([], 9)
	var blocked: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			empty_inventory,
			_simple_command(),
			registry,
		)
	)
	context.expect_true(blocked.is_blocked(), "Zero player damage blocks preparation.")
	context.expect_equal(
		blocked.resolution().block_reason(),
		ContactCombatResolutionScript.BlockReason.PLAYER_DAMAGE_ZERO,
		"Blocked result preserves the explicit zero-damage reason.",
	)
	context.expect_true(blocked.candidate() == null, "Blocked preview has no candidate.")
	context.expect_true(
		not blocked.is_commit_boundary(),
		"Blocked preview is never a commit boundary.",
	)
	var commit_attempt: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			empty_inventory,
			blocked,
			registry,
		)
	)
	_expect_rejected(
		context,
		commit_attempt,
		ContactCombatTransactionResultScript
		.RejectionReason
		.INVALID_PREPARED_RESULT,
		"Blocked commit attempt",
	)

	var saturated_defense_inventory: PortableInventoryStateScript = _inventory(
		[_gift(EFFECT_STACK_ID, &"blueprint.21", 1)],
		PortableInventoryStateScript.MAXIMUM_REVISION,
		EFFECT_STACK_ID,
	)
	var saturated_blocked: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			saturated_defense_inventory,
			_simple_command(),
			registry,
		)
	)
	context.expect_true(
		saturated_blocked.is_blocked(),
		"A non-consuming blocked preview remains legal at maximum revision.",
	)


func _rejects_each_stale_authoritative_prestate(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _simple_world()
	var inventory_state: PortableInventoryStateScript = _inventory([], 5)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Staleness fixture")
	if not prepared.is_prepared():
		return

	var stale_player: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			_player_state(99),
			world_state,
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_rejected(
		context,
		stale_player,
		ContactCombatTransactionResultScript
		.RejectionReason
		.PLAYER_PRESTATE_MISMATCH,
		"Stale player prestate",
	)

	var stale_world: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			_single_enemy_world(SIMPLE_PROFILE_ID, 12, WORLD_STEP + 1),
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_rejected(
		context,
		stale_world,
		ContactCombatTransactionResultScript
		.RejectionReason
		.ENEMY_WORLD_PRESTATE_MISMATCH,
		"Stale world prestate",
	)

	var stale_inventory: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			_inventory([], 6),
			prepared,
			registry,
		)
	)
	_expect_rejected(
		context,
		stale_inventory,
		ContactCombatTransactionResultScript
		.RejectionReason
		.INVENTORY_PRESTATE_MISMATCH,
		"Stale inventory prestate",
	)


func _validates_contact_and_support_context(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _support_world()
	var inventory_state: PortableInventoryStateScript = _selected_inventory(2, 4)
	var wrong_address_command: ContactCombatTransactionCommandScript = (
		ContactCombatTransactionCommandScript.resolve_contact(
			TARGET_ID,
			_address(SPACE_ID, TARGET_CELL + Vector3i.RIGHT),
			[SUPPORTER_ALPHA_ID, SUPPORTER_BETA_ID],
			ContactCombatCommandScript.Side.PLAYER,
		)
	)
	_expect_prepare_rejection(
		context,
		player_state,
		world_state,
		inventory_state,
		wrong_address_command,
		ContactCombatTransactionResultScript
		.RejectionReason
		.CONTACT_ADDRESS_MISMATCH,
		"Wrong contact address",
	)
	var unknown_supporter_command: ContactCombatTransactionCommandScript = (
		ContactCombatTransactionCommandScript.resolve_contact(
			TARGET_ID,
			_target_address(),
			[&"enemy.instance.contact.missing"],
			ContactCombatCommandScript.Side.PLAYER,
		)
	)
	_expect_prepare_rejection(
		context,
		player_state,
		world_state,
		inventory_state,
		unknown_supporter_command,
		ContactCombatTransactionResultScript.RejectionReason.UNKNOWN_SUPPORTER,
		"Unknown supporter",
	)

	var cross_space_world: EnemyWorldStateScript = _support_world(
		&"space.contact.other"
	)
	_expect_prepare_rejection(
		context,
		player_state,
		cross_space_world,
		inventory_state,
		_support_command(),
		ContactCombatTransactionResultScript
		.RejectionReason
		.SUPPORTER_SPACE_MISMATCH,
		"Cross-space supporter",
	)

	var non_support_records: Array = [
		_record(TARGET_ID, SIMPLE_PROFILE_ID, 12),
		_record(SUPPORTER_ALPHA_ID, SUPPORT_PROFILE_ID, 14),
	]
	var non_support_addresses: Dictionary = {
		TARGET_ID: _target_address(),
		SUPPORTER_ALPHA_ID: _address(SPACE_ID, TARGET_CELL + Vector3i.RIGHT),
	}
	var non_support_world: EnemyWorldStateScript = EnemyWorldStateScript.create(
		non_support_records,
		non_support_addresses,
		WORLD_STEP,
	)
	var trait_command: ContactCombatTransactionCommandScript = (
		ContactCombatTransactionCommandScript.resolve_contact(
			TARGET_ID,
			_target_address(),
			[SUPPORTER_ALPHA_ID],
			ContactCombatCommandScript.Side.PLAYER,
		)
	)
	_expect_prepare_rejection(
		context,
		player_state,
		non_support_world,
		inventory_state,
		trait_command,
		ContactCombatTransactionResultScript
		.RejectionReason
		.SUPPORT_LINK_TRAIT_MISMATCH,
		"Target without support-link trait",
	)

	var duplicate_support_command: ContactCombatTransactionCommandScript = (
		ContactCombatTransactionCommandScript.resolve_contact(
			TARGET_ID,
			_target_address(),
			[SUPPORTER_ALPHA_ID, SUPPORTER_ALPHA_ID],
			ContactCombatCommandScript.Side.PLAYER,
		)
	)
	context.expect_true(
		not duplicate_support_command.is_valid(),
		"Duplicate supporter identities invalidate the command.",
	)
	_expect_prepare_rejection(
		context,
		player_state,
		world_state,
		inventory_state,
		duplicate_support_command,
		ContactCombatTransactionResultScript.RejectionReason.INVALID_COMMAND,
		"Duplicate supporter command",
	)


func _rejects_invalid_inputs_and_revision_overflow(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _simple_world()
	var inventory_state: PortableInventoryStateScript = _inventory([], 2)
	_expect_prepare_rejection(
		context,
		player_state,
		world_state,
		inventory_state,
		RefCounted.new(),
		ContactCombatTransactionResultScript.RejectionReason.INVALID_COMMAND,
		"Wrong command type",
	)
	var invalid_registry_result: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			RefCounted.new(),
		)
	)
	_expect_rejected(
		context,
		invalid_registry_result,
		ContactCombatTransactionResultScript.RejectionReason.INVALID_REGISTRY,
		"Wrong Registry type",
	)
	var invalid_player_result: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			RefCounted.new(),
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_rejected(
		context,
		invalid_player_result,
		ContactCombatTransactionResultScript
		.RejectionReason
		.INVALID_PLAYER_STATE,
		"Wrong player type",
	)
	var saturated_inventory: PortableInventoryStateScript = _selected_inventory(
		1,
		PortableInventoryStateScript.MAXIMUM_REVISION,
	)
	_expect_prepare_rejection(
		context,
		player_state,
		world_state,
		saturated_inventory,
		_simple_command(),
		ContactCombatTransactionResultScript
		.RejectionReason
		.INVENTORY_REVISION_OVERFLOW,
		"Selected effect at maximum revision",
	)
	var incapacitated: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			_player_state(0),
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_rejected(
		context,
		incapacitated,
		ContactCombatTransactionResultScript.RejectionReason.COMBAT_REJECTED,
		"Incapacitated player",
		ContactCombatResultScript.RejectionReason.PLAYER_INCAPACITATED,
	)
	var resolved_world: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[
			_record(
				TARGET_ID,
				SIMPLE_PROFILE_ID,
				0,
				EnemyWorldRecordScript.Lifecycle.RESOLVED,
			)
		],
		{},
		WORLD_STEP,
	)
	_expect_prepare_rejection(
		context,
		player_state,
		resolved_world,
		inventory_state,
		_simple_command(),
		ContactCombatTransactionResultScript.RejectionReason.TARGET_INACTIVE,
		"Resolved target",
	)


func _isolates_outputs_and_fails_closed(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _simple_world()
	var inventory_state: PortableInventoryStateScript = _inventory([], 1)
	var prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_simple_command(),
			registry,
		)
	)
	_expect_prepared(context, prepared, "Isolation fixture")
	if not prepared.is_prepared():
		return
	var first_candidate: ContactCombatTransactionCandidateScript = prepared.candidate()
	first_candidate.set("_initialized", false)
	context.expect_true(
		prepared.candidate().is_valid(),
		"Mutating a returned candidate cannot alter the prepared result.",
	)
	var committed: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			prepared,
			registry,
		)
	)
	_expect_committed(context, committed, "Isolation fixture")
	if committed.was_committed():
		var first_world: EnemyWorldStateScript = committed.enemy_world_state()
		first_world.set("_world_step", 999)
		context.expect_equal(
			committed.enemy_world_state().world_step(),
			WORLD_STEP,
			"Mutating a returned world cannot alter committed output.",
		)
		var first_event: ContactCombatTransactionEventScript = (
			committed.domain_events()[0]
		)
		first_event.set("_world_step", 999)
		context.expect_true(
			committed.domain_events()[0].is_valid(),
			"Mutating a returned event cannot alter committed output.",
		)

	prepared.set("_candidate", ContactCombatTransactionCandidateScript.new())
	context.expect_true(
		not prepared.is_prepared(),
		"Tampering with a prepared result invalidates it.",
	)
	_expect_rejected(
		context,
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			prepared,
			registry,
		),
		ContactCombatTransactionResultScript
		.RejectionReason
		.INVALID_PREPARED_RESULT,
		"Tampered prepared result",
	)
	var malformed_prepared := ContactCombatTransactionResultScript.new()
	context.expect_equal(
		malformed_prepared.rejection_reason(),
		ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT,
		"An empty result cannot claim PREPARED status.",
	)
	var invalid_rejection: ContactCombatTransactionResultScript = (
		ContactCombatTransactionResultScript.rejected(
			ContactCombatTransactionResultScript.RejectionReason.NONE
		)
	)
	context.expect_equal(
		invalid_rejection.rejection_reason(),
		ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT,
		"Rejected result cannot use the NONE reason.",
	)
	var invalid_nested_rejection: ContactCombatTransactionResultScript = (
		ContactCombatTransactionResultScript.rejected(
			ContactCombatTransactionResultScript.RejectionReason.COMBAT_REJECTED,
			ContactCombatResultScript.RejectionReason.NONE,
		)
	)
	context.expect_equal(
		invalid_nested_rejection.rejection_reason(),
		ContactCombatTransactionResultScript.RejectionReason.INVALID_RESULT,
		"Combat rejection requires a nested combat reason.",
	)


func _replays_deterministically(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _player_state(100)
	var world_state: EnemyWorldStateScript = _support_world()
	var inventory_state: PortableInventoryStateScript = _selected_inventory(2, 13)
	var first_prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_support_command(),
			registry,
		)
	)
	var second_prepared: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			_support_command(),
			registry,
		)
	)
	_expect_prepared(context, first_prepared, "First deterministic preparation")
	_expect_prepared(context, second_prepared, "Second deterministic preparation")
	if not first_prepared.is_prepared() or not second_prepared.is_prepared():
		return
	context.expect_true(
		first_prepared.candidate().is_equal_to(second_prepared.candidate()),
		"Equivalent preparations produce one exact candidate.",
	)
	var first_commit: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			first_prepared,
			registry,
		)
	)
	var second_commit: ContactCombatTransactionResultScript = (
		ContactCombatTransactionKernelScript.commit(
			player_state,
			world_state,
			inventory_state,
			second_prepared,
			registry,
		)
	)
	_expect_committed(context, first_commit, "First deterministic commit")
	_expect_committed(context, second_commit, "Second deterministic commit")
	if not first_commit.was_committed() or not second_commit.was_committed():
		return
	context.expect_equal(
		_encode_commit(first_commit),
		_encode_commit(second_commit),
		"Repeated commits expose byte-for-byte equivalent public projections.",
	)


func _expect_prepared(
	context: HeadlessTestContextScript,
	result: ContactCombatTransactionResultScript,
	label: String,
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(result.is_prepared(), "%s is prepared." % label)
	context.expect_equal(
		result.rejection_reason(),
		ContactCombatTransactionResultScript.RejectionReason.NONE,
		"%s has no rejection reason." % label,
	)
	context.expect_true(result.candidate() != null, "%s exposes a candidate." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _expect_committed(
	context: HeadlessTestContextScript,
	result: ContactCombatTransactionResultScript,
	label: String,
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(result.was_committed(), "%s commits." % label)
	context.expect_equal(
		result.rejection_reason(),
		ContactCombatTransactionResultScript.RejectionReason.NONE,
		"%s has no rejection reason." % label,
	)
	context.expect_true(result.player_state() != null, "%s publishes player state." % label)
	context.expect_true(
		result.enemy_world_state() != null,
		"%s publishes enemy world state." % label,
	)
	context.expect_true(
		result.inventory_state() != null,
		"%s publishes inventory state." % label,
	)
	context.expect_true(result.is_commit_boundary(), "%s is a commit boundary." % label)


func _expect_rejected(
	context: HeadlessTestContextScript,
	result: ContactCombatTransactionResultScript,
	expected_reason: int,
	label: String,
	expected_combat_reason: int = ContactCombatResultScript.RejectionReason.NONE,
) -> void:
	context.expect_true(result != null, "%s returns a result." % label)
	if result == null:
		return
	context.expect_true(result.was_rejected(), "%s is rejected." % label)
	context.expect_equal(
		result.rejection_reason(),
		expected_reason,
		"%s rejection reason." % label,
	)
	context.expect_equal(
		result.combat_rejection_reason(),
		expected_combat_reason,
		"%s nested combat reason." % label,
	)
	context.expect_true(result.candidate() == null, "%s exposes no candidate." % label)
	context.expect_true(result.player_state() == null, "%s exposes no player output." % label)
	context.expect_true(
		result.enemy_world_state() == null,
		"%s exposes no world output." % label,
	)
	context.expect_true(
		result.inventory_state() == null,
		"%s exposes no inventory output." % label,
	)
	context.expect_true(
		result.domain_events().is_empty(),
		"%s emits no domain event." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _expect_prepare_rejection(
	context: HeadlessTestContextScript,
	player_state: RefCounted,
	world_state: RefCounted,
	inventory_state: RefCounted,
	command: RefCounted,
	expected_reason: int,
	label: String,
) -> void:
	_expect_rejected(
		context,
		ContactCombatTransactionKernelScript.prepare(
			player_state,
			world_state,
			inventory_state,
			command,
			_canonical_registry_for_helpers(),
		),
		expected_reason,
		label,
	)


func _player_state(current_health: int) -> PlayerProgressionStateScript:
	var claimed_reward_ids: Array[StringName] = []
	return PlayerProgressionStateScript.create(
		PLAYER_PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		current_health,
		claimed_reward_ids,
	)


func _simple_world() -> EnemyWorldStateScript:
	return _single_enemy_world(SIMPLE_PROFILE_ID, 12)


func _single_enemy_world(
	profile_id: StringName,
	current_durability: int,
	world_step: int = WORLD_STEP,
	shield_intact: bool = false,
) -> EnemyWorldStateScript:
	return EnemyWorldStateScript.create(
		[_record(
			TARGET_ID,
			profile_id,
			current_durability,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
			shield_intact,
		)],
		{TARGET_ID: _target_address()},
		world_step,
	)


func _support_world(
	beta_space_id: StringName = SPACE_ID,
) -> EnemyWorldStateScript:
	return EnemyWorldStateScript.create(
		[
			_record(TARGET_ID, SUPPORT_PROFILE_ID, 14),
			_record(SUPPORTER_ALPHA_ID, SUPPORT_PROFILE_ID, 14),
			_record(SUPPORTER_BETA_ID, SUPPORT_PROFILE_ID, 14),
		],
		{
			TARGET_ID: _target_address(),
			SUPPORTER_ALPHA_ID: _address(
				SPACE_ID,
				TARGET_CELL + Vector3i.RIGHT,
			),
			SUPPORTER_BETA_ID: _address(
				beta_space_id,
				TARGET_CELL + Vector3i(2, 0, 0),
			),
		},
		WORLD_STEP,
	)


func _record(
	instance_id: StringName,
	profile_id: StringName,
	current_durability: int,
	lifecycle: int = EnemyWorldRecordScript.Lifecycle.ACTIVE,
	shield_intact: bool = false,
) -> EnemyWorldRecordScript:
	return EnemyWorldRecordScript.create(
		EnemyInstanceStateScript.create(
			instance_id,
			profile_id,
			CONTENT_SCHEMA_VERSION,
			CONTENT_VERSION,
			current_durability,
			EnemyInstanceStateScript.StateKind.PRIMARY,
			shield_intact,
		),
		lifecycle,
	)


func _simple_command() -> ContactCombatTransactionCommandScript:
	return ContactCombatTransactionCommandScript.resolve_contact(
		TARGET_ID,
		_target_address(),
		[],
		ContactCombatCommandScript.Side.PLAYER,
	)


func _support_command() -> ContactCombatTransactionCommandScript:
	return ContactCombatTransactionCommandScript.resolve_contact(
		TARGET_ID,
		_target_address(),
		[SUPPORTER_BETA_ID, SUPPORTER_ALPHA_ID],
		ContactCombatCommandScript.Side.PLAYER,
	)


func _target_address() -> EnemyWorldAddressScript:
	return _address(SPACE_ID, TARGET_CELL)


func _address(
	space_id: StringName,
	cell: Vector3i,
) -> EnemyWorldAddressScript:
	return EnemyWorldAddressScript.create(space_id, cell)


func _inventory(
	stacks: Array,
	revision: int,
	selected_stack_id: StringName = &"",
) -> PortableInventoryStateScript:
	var all_stacks: Array = stacks.duplicate()
	all_stacks.append(_gift(&"stack.utility", &"blueprint.01", 3))
	return PortableInventoryStateScript.create(
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		PortableInventoryStateScript.INITIAL_CAPACITY,
		revision,
		all_stacks,
		selected_stack_id,
	)


func _selected_inventory(
	quantity: int,
	revision: int,
) -> PortableInventoryStateScript:
	return _inventory(
		[_gift(EFFECT_STACK_ID, &"blueprint.20", quantity)],
		revision,
		EFFECT_STACK_ID,
	)


func _gift(
	stack_id: StringName,
	blueprint_id: StringName,
	quantity: int,
) -> PortableInventoryStackScript:
	return PortableInventoryStackScript.create(
		stack_id,
		blueprint_id,
		PortableInventoryStackScript.Provenance.NON_DISMANTLABLE_GIFT,
		&"",
		quantity,
	)


func _encode_commit(result: ContactCombatTransactionResultScript) -> Array:
	if not result.was_committed():
		return []
	var encoded: Array = [
		result.player_state().current_health(),
		result.enemy_world_state().world_step(),
		result.inventory_state().revision(),
		result.inventory_state().selected_temporary_effect_stack_id(),
	]
	for record: EnemyWorldRecordScript in result.enemy_world_state()._records:
		encoded.append(
			[
				record.instance_id(),
				record.lifecycle(),
				record.instance_state().current_durability(),
				record.instance_state().shield_intact(),
			]
		)
	for stack: PortableInventoryStackScript in result.inventory_state().stack_snapshots():
		encoded.append([stack.stack_id(), stack.quantity()])
	var event: ContactCombatTransactionEventScript = result.domain_events()[0]
	encoded.append(
		[
			event.target_instance_id(),
			event.supporting_instance_ids(),
			event.world_step(),
			event.previous_inventory_revision(),
			event.next_inventory_revision(),
			event.consumed_stack_id(),
		]
	)
	return encoded


func _script_declares_method(script: Script, method_name: StringName) -> bool:
	for method_data: Dictionary in script.get_script_method_list():
		if StringName(method_data.get("name", "")) == method_name:
			return true
	return false


func _object_declares_property(object: Object, property_name: StringName) -> bool:
	for property_data: Dictionary in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			return true
	return false


func _canonical_registry(
	context: HeadlessTestContextScript,
) -> ContentRegistryScript:
	if _cached_registry != null:
		return _cached_registry
	var build_result = ContentRegistryBuilderScript.build_canonical()
	context.expect_true(
		build_result.succeeded(),
		"Contact transaction tests need the canonical sealed Registry.",
	)
	_cached_registry = build_result.registry()
	context.expect_true(
		_cached_registry != null and _cached_registry.is_initialized(),
		"Contact transaction test Registry must be initialized.",
	)
	return _cached_registry


func _canonical_registry_for_helpers() -> ContentRegistryScript:
	if _cached_registry == null:
		var build_result = ContentRegistryBuilderScript.build_canonical()
		if build_result.succeeded():
			_cached_registry = build_result.registry()
	return _cached_registry
