extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const WorldStepContactCommandScript := preload(
	"res://src/rules/world_step_contact_command.gd"
)
const WorldStepContactKernelScript := preload(
	"res://src/rules/world_step_contact_kernel.gd"
)
const WorldStepContactLockScript := preload(
	"res://src/rules/world_step_contact_lock.gd"
)
const WorldStepContactResultScript := preload(
	"res://src/rules/world_step_contact_result.gd"
)

const CONTENT_SCHEMA_VERSION: int = 5
const CONTENT_VERSION: int = 5
const PLAYER_PROFILE_ID: StringName = &"progression.player.loer"
const PLAYER_ACTOR_ID: StringName = &"actor.loer"
const TARGET_PROFILE_ID: StringName = &"enemy.profile.f01.base"
const TARGET_ID: StringName = &"enemy.instance.contact.target"
const REMOTE_TARGET_ID: StringName = &"enemy.instance.contact.remote"
const NPC_ACTOR_ID: StringName = &"actor.aria"
const SPACE_ID: StringName = &"space.world-step.contact"
const OTHER_SPACE_ID: StringName = &"space.world-step.remote"
const PLAYER_CELL: Vector3i = Vector3i.ZERO
const TARGET_CELL: Vector3i = Vector3i.RIGHT
const BLOCKED_CELL: Vector3i = Vector3i.BACK
const WORLD_STEP: int = 41

var _cached_registry: ContentRegistryScript


class DerivedGridRuleState extends GridRuleStateScript:
	pass


class DerivedPlayerProgressionState extends PlayerProgressionStateScript:
	pass


class DerivedEnemyWorldState extends EnemyWorldStateScript:
	pass


class DerivedWorldStepContactCommand extends WorldStepContactCommandScript:
	pass


class DerivedWorldStepContactResult extends WorldStepContactResultScript:
	pass


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"world_step_contact.derives_player_initiated_lock",
			_derives_player_initiated_lock,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.derives_enemy_initiated_lock",
			_derives_enemy_initiated_lock,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.reports_non_contact_without_approving_movement",
			_reports_non_contact_without_approving_movement,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.composes_exact_enemy_projection",
			_composes_exact_enemy_projection,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.allows_remote_enemies_outside_local_grid",
			_allows_remote_enemies_outside_local_grid,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.rejects_stale_and_illegal_entry",
			_rejects_stale_and_illegal_entry,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.rejects_invalid_inputs_and_inactive_player",
			_rejects_invalid_inputs_and_inactive_player,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.revalidates_unchanged_lock",
			_revalidates_unchanged_lock,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.cancels_inactive_participants",
			_cancels_inactive_participants,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.rejects_revalidation_drift",
			_rejects_revalidation_drift,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.isolates_outputs_and_fails_closed",
			_isolates_outputs_and_fails_closed,
		),
		HeadlessTestCaseScript.new(
			"world_step_contact.replays_deterministically",
			_replays_deterministically,
		),
	]


func _derives_player_initiated_lock(
	context: HeadlessTestContextScript,
) -> void:
	var grid_state: GridRuleStateScript = _default_grid_state()
	var player_state: PlayerProgressionStateScript = _player_state()
	var world_state: EnemyWorldStateScript = _active_world()
	var grid_before: GridRuleStateScript = grid_state.copy()
	var player_before: PlayerProgressionStateScript = player_state.copy()
	var world_before: EnemyWorldStateScript = world_state.copy()
	var result: WorldStepContactResultScript = _prepare(
		grid_state,
		player_state,
		world_state,
		_player_entry_command(),
	)
	_expect_locked(context, result, "Player entry")
	if not result.is_locked():
		return
	var contact_lock: WorldStepContactLockScript = result.contact_lock()
	context.expect_equal(
		contact_lock.space_id(),
		SPACE_ID,
		"The lock binds the selected space.",
	)
	context.expect_equal(
		contact_lock.world_step(),
		WORLD_STEP,
		"The lock binds the exact in-progress world step.",
	)
	context.expect_equal(
		contact_lock.player_actor_id(),
		PLAYER_ACTOR_ID,
		"The player identity is derived from the authoritative actor contract.",
	)
	context.expect_equal(
		contact_lock.target_enemy_instance_id(),
		TARGET_ID,
		"The occupied destination derives the enemy target.",
	)
	context.expect_equal(
		contact_lock.player_cell(),
		PLAYER_CELL,
		"Contact keeps the player at the pre-contact cell.",
	)
	context.expect_equal(
		contact_lock.target_enemy_cell(),
		TARGET_CELL,
		"Contact keeps the enemy at the pre-contact cell.",
	)
	context.expect_equal(
		contact_lock.attempted_destination_cell(),
		TARGET_CELL,
		"The attempted destination records how contact formed.",
	)
	context.expect_equal(
		contact_lock.initiator_side(),
		ContactCombatCommandScript.Side.PLAYER,
		"The moving player becomes the combat initiator.",
	)
	context.expect_true(
		contact_lock.target_enemy_address().is_equal_to(
			EnemyWorldAddressScript.create(SPACE_ID, TARGET_CELL)
		),
		"The target address is derived rather than caller supplied.",
	)
	context.expect_equal(
		contact_lock.locked_actor_ids(),
		[PLAYER_ACTOR_ID, TARGET_ID],
		"Locked actor IDs use canonical order.",
	)
	context.expect_true(
		result.is_actor_locked(PLAYER_ACTOR_ID)
		and result.is_actor_locked(TARGET_ID)
		and not result.is_actor_locked(NPC_ACTOR_ID),
		"Only both contact participants are locked.",
	)
	context.expect_true(
		grid_state.is_equal_to(grid_before)
		and player_state.is_equal_to(player_before)
		and world_state.is_equal_to(world_before),
		"Preparing contact does not mutate authoritative inputs.",
	)


func _derives_enemy_initiated_lock(
	context: HeadlessTestContextScript,
) -> void:
	var result: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			TARGET_ID,
			TARGET_CELL,
			Vector3i.LEFT,
			WORLD_STEP,
		),
	)
	_expect_locked(context, result, "Enemy entry")
	if not result.is_locked():
		return
	var contact_lock: WorldStepContactLockScript = result.contact_lock()
	context.expect_equal(
		contact_lock.target_enemy_instance_id(),
		TARGET_ID,
		"An enemy mover remains the combat target.",
	)
	context.expect_equal(
		contact_lock.moving_actor_id(),
		TARGET_ID,
		"The lock records the enemy mover.",
	)
	context.expect_equal(
		contact_lock.attempted_destination_cell(),
		PLAYER_CELL,
		"Enemy contact records the player's occupied destination.",
	)
	context.expect_equal(
		contact_lock.initiator_side(),
		ContactCombatCommandScript.Side.OPPONENT,
		"The moving enemy becomes the combat initiator.",
	)


func _reports_non_contact_without_approving_movement(
	context: HeadlessTestContextScript,
) -> void:
	var distant_enemy_cell := Vector3i(2, 0, 0)
	var distant_world: EnemyWorldStateScript = _active_world(
		distant_enemy_cell
	)
	var clear_grid: GridRuleStateScript = _grid_state({
		PLAYER_ACTOR_ID: PLAYER_CELL,
		TARGET_ID: distant_enemy_cell,
	})
	var clear_result: WorldStepContactResultScript = _prepare(
		clear_grid,
		_player_state(),
		distant_world,
		_player_entry_command(),
	)
	context.expect_true(
		clear_result.has_no_contact(),
		"An empty destination contains no player-enemy contact.",
	)
	context.expect_true(
		clear_result.contact_lock() == null
		and not clear_result.is_commit_boundary(),
		"NO_CONTACT neither creates a lock nor approves a world commit.",
	)

	var npc_grid: GridRuleStateScript = _grid_state({
		PLAYER_ACTOR_ID: PLAYER_CELL,
		NPC_ACTOR_ID: TARGET_CELL,
		TARGET_ID: distant_enemy_cell,
	})
	var npc_result: WorldStepContactResultScript = _prepare(
		npc_grid,
		_player_state(),
		distant_world,
		_player_entry_command(),
	)
	context.expect_true(
		npc_result.has_no_contact(),
		"An occupied non-enemy destination is not forged into combat.",
	)


func _composes_exact_enemy_projection(
	context: HeadlessTestContextScript,
) -> void:
	var moved_enemy_grid: GridRuleStateScript = _grid_state({
		PLAYER_ACTOR_ID: PLAYER_CELL,
		TARGET_ID: Vector3i(2, 0, 0),
	})
	_expect_prepare_rejection(
		context,
		moved_enemy_grid,
		_active_world(),
		_player_entry_command(),
		WorldStepContactResultScript
		.RejectionReason
		.ENEMY_GRID_PROJECTION_MISMATCH,
		"Enemy coordinate mismatch",
	)
	_expect_prepare_rejection(
		context,
		_grid_state({PLAYER_ACTOR_ID: PLAYER_CELL}),
		_active_world(),
		_player_entry_command(),
		WorldStepContactResultScript
		.RejectionReason
		.ENEMY_GRID_PROJECTION_MISMATCH,
		"Missing local enemy actor",
	)
	_expect_prepare_rejection(
		context,
		_default_grid_state(),
		_active_world(TARGET_CELL, OTHER_SPACE_ID),
		_player_entry_command(),
		WorldStepContactResultScript
		.RejectionReason
		.ENEMY_GRID_PROJECTION_MISMATCH,
		"Cross-space enemy leakage",
	)
	_expect_prepare_rejection(
		context,
		_default_grid_state(WORLD_STEP + 1),
		_active_world(),
		_player_entry_command(),
		WorldStepContactResultScript.RejectionReason.WORLD_STEP_MISMATCH,
		"Grid step mismatch",
	)
	var conflicting_world: EnemyWorldStateScript = _active_world(
		TARGET_CELL,
		SPACE_ID,
		WORLD_STEP,
		PLAYER_ACTOR_ID,
	)
	_expect_prepare_rejection(
		context,
		_grid_state({PLAYER_ACTOR_ID: PLAYER_CELL}),
		conflicting_world,
		_player_entry_command(),
		WorldStepContactResultScript.RejectionReason.PLAYER_IDENTITY_CONFLICT,
		"Player identity reused by enemy world",
	)


func _allows_remote_enemies_outside_local_grid(
	context: HeadlessTestContextScript,
) -> void:
	var records: Array = [
		_record(REMOTE_TARGET_ID, 12, EnemyWorldRecordScript.Lifecycle.ACTIVE),
		_record(TARGET_ID, 12, EnemyWorldRecordScript.Lifecycle.ACTIVE),
	]
	var addresses: Dictionary = {
		REMOTE_TARGET_ID: EnemyWorldAddressScript.create(
			OTHER_SPACE_ID,
			TARGET_CELL,
		),
		TARGET_ID: EnemyWorldAddressScript.create(SPACE_ID, TARGET_CELL),
	}
	var world_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		records,
		addresses,
		WORLD_STEP,
	)
	var result: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		world_state,
		_player_entry_command(),
	)
	_expect_locked(context, result, "Local contact with remote enemy record")
	if result.is_locked():
		context.expect_equal(
			result.contact_lock().target_enemy_instance_id(),
			TARGET_ID,
			"Only the selected-space projection participates in contact.",
		)


func _rejects_stale_and_illegal_entry(
	context: HeadlessTestContextScript,
) -> void:
	_expect_prepare_rejection(
		context,
		_default_grid_state(),
		_active_world(),
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			&"actor.unknown",
			PLAYER_CELL,
			Vector3i.RIGHT,
			WORLD_STEP,
		),
		WorldStepContactResultScript.RejectionReason.MOVING_ACTOR_MISSING,
		"Unknown mover",
	)
	_expect_prepare_rejection(
		context,
		_default_grid_state(),
		_active_world(),
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			PLAYER_ACTOR_ID,
			Vector3i.LEFT,
			Vector3i.RIGHT,
			WORLD_STEP,
		),
		WorldStepContactResultScript.RejectionReason.FROM_CELL_MISMATCH,
		"Stale source cell",
	)

	var narrow_grid: GridRuleStateScript = _custom_grid_state(
		[PLAYER_CELL, TARGET_CELL],
		[],
		{PLAYER_ACTOR_ID: PLAYER_CELL, TARGET_ID: TARGET_CELL},
	)
	_expect_prepare_rejection(
		context,
		narrow_grid,
		_active_world(),
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			PLAYER_ACTOR_ID,
			PLAYER_CELL,
			Vector3i.LEFT,
			WORLD_STEP,
		),
		WorldStepContactResultScript.RejectionReason.TARGET_OUT_OF_BOUNDS,
		"Out-of-grid destination",
	)
	_expect_prepare_rejection(
		context,
		_default_grid_state(),
		_active_world(),
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			PLAYER_ACTOR_ID,
			PLAYER_CELL,
			Vector3i.BACK,
			WORLD_STEP,
		),
		WorldStepContactResultScript.RejectionReason.TARGET_BLOCKED,
		"Blocked destination",
	)

	var maximum_cell := Vector3i(2_147_483_647, 0, 0)
	var overflow_enemy_cell := Vector3i(2_147_483_646, 0, 0)
	var overflow_grid: GridRuleStateScript = _custom_grid_state(
		[overflow_enemy_cell, maximum_cell],
		[],
		{PLAYER_ACTOR_ID: maximum_cell, TARGET_ID: overflow_enemy_cell},
	)
	var overflow_world: EnemyWorldStateScript = _active_world(
		overflow_enemy_cell
	)
	_expect_prepare_rejection(
		context,
		overflow_grid,
		overflow_world,
		WorldStepContactCommandScript.attempt_entry(
			SPACE_ID,
			PLAYER_ACTOR_ID,
			maximum_cell,
			Vector3i.RIGHT,
			WORLD_STEP,
		),
		WorldStepContactResultScript.RejectionReason.COORDINATE_OVERFLOW,
		"Coordinate overflow",
	)


func _rejects_invalid_inputs_and_inactive_player(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var valid_command: WorldStepContactCommandScript = _player_entry_command()
	_expect_rejected(
		context,
		WorldStepContactKernelScript.prepare(
			_default_grid_state(),
			_player_state(),
			_active_world(),
			valid_command,
			null,
		),
		WorldStepContactResultScript.RejectionReason.INVALID_REGISTRY,
		"Null Registry",
	)
	for invalid_grid_state: RefCounted in [
		GridRuleStateScript.new(),
		DerivedGridRuleState.new(),
	]:
		_expect_rejected(
			context,
			WorldStepContactKernelScript.prepare(
				invalid_grid_state,
				_player_state(),
				_active_world(),
				valid_command,
				registry,
			),
			WorldStepContactResultScript.RejectionReason.INVALID_GRID_STATE,
			"Invalid grid state",
		)
	for invalid_player_state: RefCounted in [
		PlayerProgressionStateScript.new(),
		DerivedPlayerProgressionState.new(),
	]:
		_expect_rejected(
			context,
			WorldStepContactKernelScript.prepare(
				_default_grid_state(),
				invalid_player_state,
				_active_world(),
				valid_command,
				registry,
			),
			WorldStepContactResultScript.RejectionReason.INVALID_PLAYER_STATE,
			"Invalid player state",
		)
	_expect_rejected(
		context,
		WorldStepContactKernelScript.prepare(
			_default_grid_state(),
			_player_state(),
			DerivedEnemyWorldState.new(),
			valid_command,
			registry,
		),
		WorldStepContactResultScript
		.RejectionReason
		.ENEMY_WORLD_STATE_REJECTED,
		"Derived enemy world state",
	)
	for invalid_command: RefCounted in [
		WorldStepContactCommandScript.new(),
		DerivedWorldStepContactCommand.new(),
	]:
		_expect_rejected(
			context,
			WorldStepContactKernelScript.prepare(
				_default_grid_state(),
				_player_state(),
				_active_world(),
				invalid_command,
				registry,
			),
			WorldStepContactResultScript.RejectionReason.INVALID_COMMAND,
			"Invalid contact command",
		)
	_expect_rejected(
		context,
		WorldStepContactKernelScript.prepare(
			_default_grid_state(),
			_player_state(0),
			_active_world(),
			valid_command,
			registry,
		),
		WorldStepContactResultScript.RejectionReason.PLAYER_INACTIVE,
		"Inactive player",
	)
	_expect_rejected(
		context,
		WorldStepContactKernelScript.prepare(
			_default_grid_state(),
			_player_state(),
			_active_world(),
			WorldStepContactCommandScript.attempt_entry(
				SPACE_ID,
				PLAYER_ACTOR_ID,
				PLAYER_CELL,
				Vector3i(1, 0, 1),
				WORLD_STEP,
			),
			registry,
		),
		WorldStepContactResultScript.RejectionReason.INVALID_COMMAND,
		"Diagonal direction",
	)


func _revalidates_unchanged_lock(
	context: HeadlessTestContextScript,
) -> void:
	var grid_state: GridRuleStateScript = _default_grid_state()
	var player_state: PlayerProgressionStateScript = _player_state()
	var world_state: EnemyWorldStateScript = _active_world()
	var prepared: WorldStepContactResultScript = _prepare(
		grid_state,
		player_state,
		world_state,
		_player_entry_command(),
	)
	var revalidated: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			prepared,
			grid_state,
			player_state,
			world_state,
			_canonical_registry_for_helpers(),
		)
	)
	_expect_locked(context, revalidated, "Unchanged lock")
	context.expect_true(
		prepared.is_equal_to(revalidated),
		"Revalidation preserves the exact contact lock.",
	)


func _cancels_inactive_participants(
	context: HeadlessTestContextScript,
) -> void:
	var prepared: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		_player_entry_command(),
	)
	var player_cancelled: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			prepared,
			_default_grid_state(),
			_player_state(0),
			_active_world(),
			_canonical_registry_for_helpers(),
		)
	)
	_expect_cancelled(
		context,
		player_cancelled,
		WorldStepContactResultScript.CancellationReason.PLAYER_INACTIVE,
		"Player deactivation",
	)

	var resolved_world: EnemyWorldStateScript = _resolved_world()
	var resolved_grid: GridRuleStateScript = _grid_state({
		PLAYER_ACTOR_ID: PLAYER_CELL,
	})
	var enemy_cancelled: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			prepared,
			resolved_grid,
			_player_state(),
			resolved_world,
			_canonical_registry_for_helpers(),
		)
	)
	_expect_cancelled(
		context,
		enemy_cancelled,
		WorldStepContactResultScript.CancellationReason.ENEMY_INACTIVE,
		"Enemy deactivation",
	)
	context.expect_true(
		not enemy_cancelled.is_actor_locked(PLAYER_ACTOR_ID)
		and not enemy_cancelled.is_actor_locked(TARGET_ID),
		"A cancelled result releases both movement locks.",
	)
	context.expect_true(
		enemy_cancelled.contact_lock() != null,
		"Cancellation retains the historical contact context for diagnostics.",
	)

	var both_cancelled: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			prepared,
			resolved_grid,
			_player_state(0),
			resolved_world,
			_canonical_registry_for_helpers(),
		)
	)
	context.expect_equal(
		both_cancelled.cancellation_reason(),
		WorldStepContactResultScript.CancellationReason.PLAYER_INACTIVE,
		"Simultaneous inactivity uses stable player-first reason priority.",
	)


func _rejects_revalidation_drift(
	context: HeadlessTestContextScript,
) -> void:
	var prepared: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		_player_entry_command(),
	)
	_expect_revalidation_rejection(
		context,
		prepared,
		_default_grid_state(WORLD_STEP + 1),
		_player_state(),
		_active_world(TARGET_CELL, SPACE_ID, WORLD_STEP + 1),
		WorldStepContactResultScript.RejectionReason.WORLD_STEP_MISMATCH,
		"Advanced world step",
	)
	_expect_revalidation_rejection(
		context,
		prepared,
		_grid_state({
			PLAYER_ACTOR_ID: Vector3i.LEFT,
			TARGET_ID: TARGET_CELL,
		}),
		_player_state(),
		_active_world(),
		WorldStepContactResultScript.RejectionReason.CONTACT_PRESTATE_MISMATCH,
		"Moved player",
	)
	var moved_target_cell := Vector3i(2, 0, 0)
	_expect_revalidation_rejection(
		context,
		prepared,
		_grid_state({
			PLAYER_ACTOR_ID: PLAYER_CELL,
			TARGET_ID: moved_target_cell,
		}),
		_player_state(),
		_active_world(moved_target_cell),
		WorldStepContactResultScript.RejectionReason.CONTACT_PRESTATE_MISMATCH,
		"Moved enemy",
	)
	_expect_revalidation_rejection(
		context,
		prepared,
		_default_grid_state(),
		_player_state(),
		_active_world(Vector3i(2, 0, 0)),
		WorldStepContactResultScript
		.RejectionReason
		.ENEMY_GRID_PROJECTION_MISMATCH,
		"Divergent current projection",
	)


func _isolates_outputs_and_fails_closed(
	context: HeadlessTestContextScript,
) -> void:
	var prepared: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		_player_entry_command(),
	)
	_expect_locked(context, prepared, "Isolation source")
	if not prepared.is_locked():
		return
	var exposed_lock: WorldStepContactLockScript = prepared.contact_lock()
	exposed_lock._world_step += 1
	context.expect_true(
		prepared.is_locked(),
		"Mutating a returned lock copy cannot alter the result.",
	)
	context.expect_equal(
		prepared.contact_lock().world_step(),
		WORLD_STEP,
		"A fresh lock snapshot preserves the bound step.",
	)
	prepared._contact_lock._world_step += 1
	context.expect_true(
		prepared.was_rejected()
		and prepared.rejection_reason()
		== WorldStepContactResultScript.RejectionReason.INVALID_RESULT,
		"Mutating internal lock data invalidates the entire result.",
	)
	context.expect_true(
		prepared.contact_lock() == null,
		"An invalidated result exposes no partial lock.",
	)

	var raw_result := WorldStepContactResultScript.new()
	context.expect_true(
		raw_result.was_rejected()
		and raw_result.rejection_reason()
		== WorldStepContactResultScript.RejectionReason.INVALID_RESULT,
		"A raw result fails closed.",
	)
	var malformed_rejection: WorldStepContactResultScript = (
		WorldStepContactResultScript.rejected(
			WorldStepContactResultScript.RejectionReason.NONE
		)
	)
	context.expect_equal(
		malformed_rejection.rejection_reason(),
		WorldStepContactResultScript.RejectionReason.INVALID_RESULT,
		"A NONE rejection cannot masquerade as a valid outcome.",
	)
	context.expect_true(
		not _script_declares_method(WorldStepContactLockScript, &"create")
		and not _script_declares_method(WorldStepContactResultScript, &"locked")
		and not _script_declares_method(WorldStepContactResultScript, &"cancelled")
		and not _script_declares_method(WorldStepContactResultScript, &"no_contact"),
		"Locking and cancellation construction remain kernel-internal.",
	)
	context.expect_true(
		not _forged_wrapped_contact_lock().is_valid(),
		"Opposite 32-bit coordinate extremes cannot wrap into false adjacency.",
	)
	_expect_rejected(
		context,
		WorldStepContactKernelScript.revalidate(
			DerivedWorldStepContactResult.new(),
			_default_grid_state(),
			_player_state(),
			_active_world(),
			_canonical_registry_for_helpers(),
		),
		WorldStepContactResultScript.RejectionReason.INVALID_LOCKED_RESULT,
		"Derived locked result",
	)


func _replays_deterministically(
	context: HeadlessTestContextScript,
) -> void:
	var first: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		_player_entry_command(),
	)
	var second: WorldStepContactResultScript = _prepare(
		_default_grid_state(),
		_player_state(),
		_active_world(),
		_player_entry_command(),
	)
	context.expect_true(
		first.is_equal_to(second),
		"Identical contact inputs produce equal results.",
	)
	context.expect_equal(
		_encode_lock(first),
		_encode_lock(second),
		"Identical contact inputs produce byte-order-independent field traces.",
	)
	var first_revalidated: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			first,
			_default_grid_state(),
			_player_state(),
			_active_world(),
			_canonical_registry_for_helpers(),
		)
	)
	var second_revalidated: WorldStepContactResultScript = (
		WorldStepContactKernelScript.revalidate(
			second,
			_default_grid_state(),
			_player_state(),
			_active_world(),
			_canonical_registry_for_helpers(),
		)
	)
	context.expect_true(
		first_revalidated.is_equal_to(second_revalidated),
		"Revalidation is deterministic.",
	)


func _prepare(
	grid_state: RefCounted,
	player_state: RefCounted,
	world_state: RefCounted,
	command: RefCounted,
) -> WorldStepContactResultScript:
	return WorldStepContactKernelScript.prepare(
		grid_state,
		player_state,
		world_state,
		command,
		_canonical_registry_for_helpers(),
	)


func _expect_prepare_rejection(
	context: HeadlessTestContextScript,
	grid_state: RefCounted,
	world_state: RefCounted,
	command: RefCounted,
	expected_reason: int,
	label: String,
) -> void:
	_expect_rejected(
		context,
		_prepare(grid_state, _player_state(), world_state, command),
		expected_reason,
		label,
	)


func _expect_revalidation_rejection(
	context: HeadlessTestContextScript,
	prepared: RefCounted,
	grid_state: RefCounted,
	player_state: RefCounted,
	world_state: RefCounted,
	expected_reason: int,
	label: String,
) -> void:
	_expect_rejected(
		context,
		WorldStepContactKernelScript.revalidate(
			prepared,
			grid_state,
			player_state,
			world_state,
			_canonical_registry_for_helpers(),
		),
		expected_reason,
		label,
	)


func _expect_locked(
	context: HeadlessTestContextScript,
	result: WorldStepContactResultScript,
	label: String,
) -> void:
	context.expect_true(result.is_locked(), "%s is LOCKED." % label)
	context.expect_equal(
		result.rejection_reason(),
		WorldStepContactResultScript.RejectionReason.NONE,
		"%s has no rejection reason." % label,
	)
	context.expect_equal(
		result.cancellation_reason(),
		WorldStepContactResultScript.CancellationReason.NONE,
		"%s has no cancellation reason." % label,
	)
	context.expect_true(
		result.contact_lock() != null,
		"%s publishes a defensive contact lock." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _expect_cancelled(
	context: HeadlessTestContextScript,
	result: WorldStepContactResultScript,
	expected_reason: int,
	label: String,
) -> void:
	context.expect_true(result.was_cancelled(), "%s is CANCELLED." % label)
	context.expect_equal(
		result.cancellation_reason(),
		expected_reason,
		"%s exposes the expected cancellation reason." % label,
	)
	context.expect_equal(
		result.rejection_reason(),
		WorldStepContactResultScript.RejectionReason.NONE,
		"%s is not rejected." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _expect_rejected(
	context: HeadlessTestContextScript,
	result: WorldStepContactResultScript,
	expected_reason: int,
	label: String,
) -> void:
	context.expect_true(result.was_rejected(), "%s is REJECTED." % label)
	context.expect_equal(
		result.rejection_reason(),
		expected_reason,
		"%s exposes the expected rejection reason." % label,
	)
	context.expect_true(
		result.contact_lock() == null,
		"%s exposes no partial lock." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s is not a commit boundary." % label,
	)


func _player_entry_command() -> WorldStepContactCommandScript:
	return WorldStepContactCommandScript.attempt_entry(
		SPACE_ID,
		PLAYER_ACTOR_ID,
		PLAYER_CELL,
		Vector3i.RIGHT,
		WORLD_STEP,
	)


func _player_state(current_health: int = 100) -> PlayerProgressionStateScript:
	var claimed_reward_ids: Array[StringName] = []
	return PlayerProgressionStateScript.create(
		PLAYER_PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		current_health,
		claimed_reward_ids,
	)


func _active_world(
	target_cell: Vector3i = TARGET_CELL,
	space_id: StringName = SPACE_ID,
	world_step: int = WORLD_STEP,
	target_id: StringName = TARGET_ID,
) -> EnemyWorldStateScript:
	return EnemyWorldStateScript.create(
		[_record(target_id, 12, EnemyWorldRecordScript.Lifecycle.ACTIVE)],
		{target_id: EnemyWorldAddressScript.create(space_id, target_cell)},
		world_step,
	)


func _resolved_world() -> EnemyWorldStateScript:
	return EnemyWorldStateScript.create(
		[_record(TARGET_ID, 0, EnemyWorldRecordScript.Lifecycle.RESOLVED)],
		{},
		WORLD_STEP,
	)


func _record(
	instance_id: StringName,
	current_durability: int,
	lifecycle: int,
) -> EnemyWorldRecordScript:
	return EnemyWorldRecordScript.create(
		EnemyInstanceStateScript.create(
			instance_id,
			TARGET_PROFILE_ID,
			CONTENT_SCHEMA_VERSION,
			CONTENT_VERSION,
			current_durability,
			EnemyInstanceStateScript.StateKind.PRIMARY,
			false,
		),
		lifecycle,
	)


func _default_grid_state(
	world_step: int = WORLD_STEP,
) -> GridRuleStateScript:
	return _grid_state(
		{PLAYER_ACTOR_ID: PLAYER_CELL, TARGET_ID: TARGET_CELL},
		world_step,
	)


func _grid_state(
	actor_positions: Dictionary,
	world_step: int = WORLD_STEP,
) -> GridRuleStateScript:
	return _custom_grid_state(
		_default_grid_cells(),
		[BLOCKED_CELL],
		actor_positions,
		world_step,
	)


func _custom_grid_state(
	grid_cells: Array[Vector3i],
	blocked_cells: Array[Vector3i],
	actor_position_candidates: Dictionary,
	world_step: int = WORLD_STEP,
) -> GridRuleStateScript:
	var actor_positions: Dictionary[StringName, Vector3i] = {}
	for actor_id: StringName in actor_position_candidates:
		actor_positions[actor_id] = actor_position_candidates[actor_id]
	return GridRuleStateScript.create(
		grid_cells,
		blocked_cells,
		actor_positions,
		world_step,
	)


func _default_grid_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for z: int in range(-1, 3):
		for x: int in range(-1, 4):
			cells.append(Vector3i(x, 0, z))
	return cells


func _encode_lock(result: WorldStepContactResultScript) -> Array:
	if not result.is_locked():
		return []
	var contact_lock: WorldStepContactLockScript = result.contact_lock()
	return [
		String(contact_lock.space_id()),
		contact_lock.world_step(),
		String(contact_lock.player_actor_id()),
		String(contact_lock.target_enemy_instance_id()),
		contact_lock.player_cell(),
		contact_lock.target_enemy_cell(),
		String(contact_lock.moving_actor_id()),
		contact_lock.attempted_destination_cell(),
		contact_lock.initiator_side(),
		contact_lock.locked_actor_ids(),
	]


func _forged_wrapped_contact_lock() -> WorldStepContactLockScript:
	var contact_lock := WorldStepContactLockScript.new()
	contact_lock._space_id = SPACE_ID
	contact_lock._integrity_space_id = SPACE_ID
	contact_lock._world_step = WORLD_STEP
	contact_lock._integrity_world_step = WORLD_STEP
	contact_lock._player_actor_id = PLAYER_ACTOR_ID
	contact_lock._integrity_player_actor_id = PLAYER_ACTOR_ID
	contact_lock._target_enemy_instance_id = TARGET_ID
	contact_lock._integrity_target_enemy_instance_id = TARGET_ID
	contact_lock._player_cell = Vector3i(-2_147_483_648, 0, 0)
	contact_lock._integrity_player_cell = contact_lock._player_cell
	contact_lock._target_enemy_cell = Vector3i(2_147_483_647, 0, 0)
	contact_lock._integrity_target_enemy_cell = contact_lock._target_enemy_cell
	contact_lock._moving_actor_id = PLAYER_ACTOR_ID
	contact_lock._integrity_moving_actor_id = PLAYER_ACTOR_ID
	contact_lock._attempted_destination_cell = contact_lock._target_enemy_cell
	contact_lock._integrity_attempted_destination_cell = (
		contact_lock._attempted_destination_cell
	)
	contact_lock._initiator_side = ContactCombatCommandScript.Side.PLAYER
	contact_lock._integrity_initiator_side = contact_lock._initiator_side
	contact_lock._initialized = true
	contact_lock._integrity_initialized = true
	return contact_lock


func _script_declares_method(script: Script, method_name: StringName) -> bool:
	for method_data: Dictionary in script.get_script_method_list():
		if StringName(method_data.get("name", "")) == method_name:
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
		"World-step contact tests need the canonical sealed Registry.",
	)
	_cached_registry = build_result.registry()
	context.expect_true(
		_cached_registry != null and _cached_registry.is_initialized(),
		"World-step contact test Registry must be initialized.",
	)
	return _cached_registry


func _canonical_registry_for_helpers() -> ContentRegistryScript:
	if _cached_registry == null:
		var build_result = ContentRegistryBuilderScript.build_canonical()
		if build_result.succeeded():
			_cached_registry = build_result.registry()
	return _cached_registry
