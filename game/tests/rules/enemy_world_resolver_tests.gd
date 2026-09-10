extends RefCounted

const CanonicalRegistryFixtureScript := preload(
	"res://tests/support/canonical_registry_fixture.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyGridProjectionResultScript := preload(
	"res://src/rules/enemy_grid_projection_result.gd"
)
const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
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
const EnemyWorldReadSnapshotScript := preload(
	"res://src/rules/enemy_world_read_snapshot.gd"
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
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const StatefulContentRegistryScript := preload(
	"res://tests/support/stateful_content_registry.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

const CONTENT_SCHEMA_VERSION: int = 6
const CONTENT_VERSION: int = 6
const PRIMARY_PROFILE_ID := &"enemy.profile.f01.base"
const ALTERNATE_SHIELD_PROFILE_ID := &"enemy.profile.f12.enhanced"
const PRIMARY_MAXIMUM_DURABILITY: int = 12
const ALTERNATE_MAXIMUM_DURABILITY: int = 10


class StatefulEnemyWorldState extends EnemyWorldStateScript:
	var _reads: int = 0

	func copy() -> EnemyWorldState:
		_reads += 1
		return super.copy()

	func is_resolved_against(_registry: RefCounted) -> bool:
		_reads += 1
		return true

	func is_equal_to(_other: EnemyWorldState) -> bool:
		_reads += 1
		return true

	func read_count() -> int:
		return _reads


class StatefulEnemyWorldRecord extends EnemyWorldRecordScript:
	var _reads: int = 0

	func copy() -> EnemyWorldRecord:
		_reads += 1
		return super.copy()

	func read_count() -> int:
		return _reads


class StatefulEnemyWorldAddress extends EnemyWorldAddressScript:
	var _reads: int = 0

	func copy() -> EnemyWorldAddress:
		_reads += 1
		return super.copy()

	func is_valid() -> bool:
		_reads += 1
		return true

	func read_count() -> int:
		return _reads


class StatefulEnemyWorldReadSnapshot extends EnemyWorldReadSnapshotScript:
	var _reads: int = 0

	func is_valid() -> bool:
		_reads += 1
		return true

	func read_count() -> int:
		return _reads


class StatefulEnemyInstance extends EnemyInstanceStateScript:
	var _reads: int = 0

	func copy() -> EnemyInstanceState:
		_reads += 1
		return super.copy()

	func read_count() -> int:
		return _reads


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"enemy_world.rebuilds_active_and_resolved_catalog",
			_rebuilds_active_and_resolved_catalog,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.preserves_resolved_state_without_refresh",
			_preserves_resolved_state_without_refresh,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.projects_spaces_with_canonical_actor_ids",
			_projects_spaces_with_canonical_actor_ids,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.rejects_world_invariants_in_stable_priority",
			_rejects_world_invariants_in_stable_priority,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.reuses_instance_and_registry_validation",
			_reuses_instance_and_registry_validation,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.rejects_derived_inputs_without_reads",
			_rejects_derived_inputs_without_reads,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.isolates_inputs_outputs_and_integrity",
			_isolates_inputs_outputs_and_integrity,
		),
		HeadlessTestCaseScript.new(
			"enemy_world.matches_exact_prestates_and_replays",
			_matches_exact_prestates_and_replays,
		),
	]


func _rebuilds_active_and_resolved_catalog(
	context: HeadlessTestContextScript,
) -> void:
	var records: Array = [
		_record(
			&"enemy.instance.resolved",
			ALTERNATE_SHIELD_PROFILE_ID,
			0,
			EnemyWorldRecordScript.Lifecycle.RESOLVED,
			EnemyInstanceStateScript.StateKind.ALTERNATE,
			true,
		),
		_record(
			&"enemy.instance.shield-broken",
			ALTERNATE_SHIELD_PROFILE_ID,
			6,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
			EnemyInstanceStateScript.StateKind.ALTERNATE,
			false,
		),
		_record(
			&"enemy.instance.full",
			PRIMARY_PROFILE_ID,
			PRIMARY_MAXIMUM_DURABILITY,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
		),
		_record(
			&"enemy.instance.damaged",
			PRIMARY_PROFILE_ID,
			5,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
		),
		_record(
			&"enemy.instance.shield-intact",
			ALTERNATE_SHIELD_PROFILE_ID,
			ALTERNATE_MAXIMUM_DURABILITY,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
			EnemyInstanceStateScript.StateKind.ALTERNATE,
			true,
		),
	]
	var addresses: Dictionary = {
		&"enemy.instance.shield-intact": _address(&"space.harbor", Vector3i(4, 0, 1)),
		&"enemy.instance.full": _address(&"space.harbor", Vector3i(1, 0, 1)),
		&"enemy.instance.shield-broken": _address(&"space.archive", Vector3i(-2, 3, 8)),
		&"enemy.instance.damaged": _address(&"space.harbor", Vector3i(2, 0, 1)),
	}
	var result: EnemyWorldResolutionResultScript = _resolve(records, addresses, 41)
	_expect_success(context, result, "Mixed active and resolved rebuild")
	if not result.succeeded():
		return
	var snapshot: EnemyWorldStateScript = result.snapshot()
	context.expect_equal(snapshot.world_step(), 41, "World-step prestate is retained.")
	context.expect_equal(
		result.instance_ids(),
		[
			&"enemy.instance.damaged",
			&"enemy.instance.full",
			&"enemy.instance.resolved",
			&"enemy.instance.shield-broken",
			&"enemy.instance.shield-intact",
		],
		"World records use canonical instance-ID order.",
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.full",
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		PRIMARY_MAXIMUM_DURABILITY,
		true,
		&"space.harbor",
		Vector3i(1, 0, 1),
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.damaged",
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		5,
		true,
		&"space.harbor",
		Vector3i(2, 0, 1),
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.shield-intact",
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		ALTERNATE_MAXIMUM_DURABILITY,
		true,
		&"space.harbor",
		Vector3i(4, 0, 1),
		true,
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.shield-broken",
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		6,
		true,
		&"space.archive",
		Vector3i(-2, 3, 8),
		false,
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.resolved",
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
		0,
		false,
		&"",
		Vector3i.ZERO,
		true,
	)
	for forbidden_method: StringName in [
		&"maximum_durability",
		&"attack",
		&"defense",
		&"speed",
		&"behavior_id",
		&"combat_trait_ids",
		&"visual_binding_id",
	]:
		context.expect_true(
			not snapshot.has_method(forbidden_method),
			"Enemy world state must not duplicate static field %s." % forbidden_method,
		)
		context.expect_true(
			not result.record_snapshots()[0].has_method(forbidden_method),
			"Enemy world records must not duplicate static field %s." % forbidden_method,
		)


func _preserves_resolved_state_without_refresh(
	context: HeadlessTestContextScript,
) -> void:
	var resolved_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.persisted-resolved",
		ALTERNATE_SHIELD_PROFILE_ID,
		0,
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
		EnemyInstanceStateScript.StateKind.ALTERNATE,
		true,
	)
	var first: EnemyWorldResolutionResultScript = _resolve([resolved_record], {}, 9)
	_expect_success(context, first, "Resolved-only rebuild")
	if not first.succeeded():
		return
	var second: EnemyWorldResolutionResultScript = EnemyWorldResolverScript.resolve(
		first.snapshot(),
		CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
	)
	_expect_success(context, second, "Resolved state reconstruction")
	if not second.succeeded():
		return
	var query: EnemyWorldQueryResultScript = second.lookup_enemy(
		&"enemy.instance.persisted-resolved"
	)
	context.expect_true(query.succeeded(), "Resolved record remains queryable.")
	context.expect_equal(
		query.lifecycle(),
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
		"Resolved lifecycle survives reconstruction.",
	)
	context.expect_equal(
		query.instance_state().current_durability(),
		0,
		"Resolved durability must not refresh during reconstruction.",
	)
	context.expect_true(
		query.instance_state().shield_intact(),
		"Resolution must preserve a legal zero-durability shield state.",
	)
	context.expect_true(
		not query.has_world_address(),
		"Resolved records must remain outside grid occupancy.",
	)
	var projection: EnemyGridProjectionResultScript = (
		second.project_space(&"space.return-visit")
	)
	context.expect_true(projection.succeeded(), "Empty return-space projection succeeds.")
	context.expect_equal(
		projection.actor_positions(),
		{},
		"Resolved enemies do not reappear when a space is projected.",
	)
	context.expect_true(
		first.snapshot().is_equal_to(second.snapshot()),
		"Rebuilding a resolved world is deterministic and idempotent.",
	)


func _projects_spaces_with_canonical_actor_ids(
	context: HeadlessTestContextScript,
) -> void:
	var shared_cell := Vector3i(-7, 2, 14)
	var records: Array = [
		_record(
			&"enemy.instance.zeta",
			PRIMARY_PROFILE_ID,
			7,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
		),
		_record(
			&"enemy.instance.alpha",
			PRIMARY_PROFILE_ID,
			8,
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
		),
	]
	var addresses: Dictionary = {
		&"enemy.instance.zeta": _address(&"space.zeta", shared_cell),
		&"enemy.instance.alpha": _address(&"space.alpha", shared_cell),
	}
	var result: EnemyWorldResolutionResultScript = _resolve(records, addresses, 73)
	_expect_success(context, result, "Cross-space equal local coordinates")
	if not result.succeeded():
		return
	var alpha_projection: EnemyGridProjectionResultScript = result.project_space(
		&"space.alpha"
	)
	context.expect_true(alpha_projection.succeeded(), "Alpha projection succeeds.")
	context.expect_equal(
		alpha_projection.world_step(),
		73,
		"Projection carries the exact world-step prestate.",
	)
	context.expect_equal(
		alpha_projection.actor_ids(),
		[&"enemy.instance.alpha"],
		"Projection actor ID is the canonical instance ID.",
	)
	context.expect_equal(
		alpha_projection.actor_positions(),
		{&"enemy.instance.alpha": shared_cell},
		"Projection is directly composable with GridRuleState actor positions.",
	)
	var composed_grid_state: GridRuleStateScript = GridRuleStateScript.create(
		[shared_cell],
		[],
		alpha_projection.actor_positions(),
		alpha_projection.world_step(),
	)
	context.expect_true(
		composed_grid_state.is_valid(),
		"Enemy projection uses the existing GridRuleState actor contract.",
	)
	context.expect_equal(
		composed_grid_state.actor_ids(),
		[&"enemy.instance.alpha"],
		"GridRuleState preserves the canonical enemy instance actor ID.",
	)
	var zeta_projection: EnemyGridProjectionResultScript = result.project_space(
		&"space.zeta"
	)
	context.expect_equal(
		zeta_projection.actor_positions(),
		{&"enemy.instance.zeta": shared_cell},
		"A different space can reuse the same local coordinate.",
	)
	var empty_projection: EnemyGridProjectionResultScript = result.project_space(
		&"space.empty"
	)
	context.expect_true(empty_projection.succeeded(), "A valid empty space succeeds.")
	context.expect_equal(empty_projection.actor_ids(), [], "Empty space has no enemies.")
	for invalid_space_id: StringName in [&"", &"...", &"地区", &"res://scene.tscn"]:
		var invalid_projection: EnemyGridProjectionResultScript = (
			result.project_space(invalid_space_id)
		)
		context.expect_true(
			not invalid_projection.succeeded(),
			"Invalid space IDs fail structurally.",
		)
		context.expect_equal(
			invalid_projection.failure_reason(),
			EnemyGridProjectionResultScript.FailureReason.INVALID_SPACE_ID,
			"Invalid space projection failure reason.",
		)
		context.expect_equal(
			invalid_projection.actor_positions(),
			{},
			"Invalid projection exposes no partial actor positions.",
		)

	var same_space_addresses: Dictionary = {
		&"enemy.instance.alpha": _address(&"space.shared", shared_cell),
		&"enemy.instance.zeta": _address(&"space.shared", shared_cell),
	}
	_expect_failure(
		context,
		_resolve(records, same_space_addresses, 73),
		EnemyWorldResolutionResultScript.FailureReason.DUPLICATE_WORLD_ADDRESS,
		"Same-space duplicate address",
		&"enemy.instance.zeta",
		&"space.shared",
	)


func _rejects_world_invariants_in_stable_priority(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world")
	var valid_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.valid",
		PRIMARY_PROFILE_ID,
		8,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var valid_address: EnemyWorldAddressScript = _address(
		&"space.valid",
		Vector3i(1, 0, 1),
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(null, registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE,
		"Null world state",
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(RefCounted.new(), registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE,
		"Wrong world-state type",
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(EnemyWorldStateScript.new(), registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE,
		"Uninitialized world state",
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(
			EnemyWorldStateScript.create([RefCounted.new()], {}, 0),
			registry,
		),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD,
		"Wrong record element type",
	)
	var record_with_wrong_instance_type: EnemyWorldRecordScript = (
		EnemyWorldRecordScript.create(
			RefCounted.new(),
			EnemyWorldRecordScript.Lifecycle.ACTIVE,
		)
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(
			EnemyWorldStateScript.create(
				[record_with_wrong_instance_type],
				{},
				-1,
			),
			registry,
		),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD,
		"Wrong nested instance type precedes invalid world step",
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(
			EnemyWorldStateScript.create(
				[valid_record],
				{&"enemy.instance.valid": RefCounted.new()},
				0,
			),
			registry,
		),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_ADDRESS,
		"Wrong address value type",
	)
	_expect_failure(
		context,
		_resolve([valid_record], {&"enemy.instance.valid": valid_address}, -1),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STEP,
		"Negative world step",
	)
	_expect_success(
		context,
		_resolve(
			[valid_record],
			{&"enemy.instance.valid": valid_address},
			ValidationSupportScript.MAX_WORLD_STEP,
		),
		"Maximum world step remains representable",
	)

	var invalid_lifecycle_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.bad-lifecycle",
		PRIMARY_PROFILE_ID,
		8,
		99,
	)
	var invalid_address: EnemyWorldAddressScript = _address(
		&"res://forbidden-scene.tscn",
		Vector3i.ZERO,
	)
	_expect_failure(
		context,
		_resolve(
			[invalid_lifecycle_record],
			{&"enemy.instance.bad-lifecycle": invalid_address},
			0,
		),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_LIFECYCLE,
		"Lifecycle validation precedes address validation",
		&"enemy.instance.bad-lifecycle",
	)
	_expect_failure(
		context,
		_resolve(
			[valid_record, valid_record.copy()],
			{&"enemy.instance.valid": invalid_address},
			0,
		),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_ADDRESS,
		"Address validation precedes duplicate identity",
		&"enemy.instance.valid",
		&"res://forbidden-scene.tscn",
	)
	for duplicate_records: Array in [
		[valid_record, valid_record.copy()],
		[valid_record.copy(), valid_record],
	]:
		_expect_failure(
			context,
			EnemyWorldResolverScript.resolve(
				EnemyWorldStateScript.create(
					duplicate_records,
					{&"enemy.instance.valid": valid_address},
					0,
				),
				null,
			),
			EnemyWorldResolutionResultScript.FailureReason.DUPLICATE_INSTANCE_ID,
			"Duplicate identity precedes registry validation",
			&"enemy.instance.valid",
		)

	var orphan_addresses: Dictionary = {
		&"enemy.instance.orphan": _address(&"space.valid", Vector3i(2, 0, 1)),
		&"enemy.instance.valid": valid_address,
	}
	_expect_failure(
		context,
		_resolve([valid_record], orphan_addresses, 0),
		EnemyWorldResolutionResultScript.FailureReason.ORPHAN_GRID_ACTOR,
		"Orphan grid actor",
		&"enemy.instance.orphan",
		&"space.valid",
	)
	_expect_failure(
		context,
		_resolve(
			[
				_record(
					&"enemy.instance.active-zero",
					PRIMARY_PROFILE_ID,
					0,
					EnemyWorldRecordScript.Lifecycle.ACTIVE,
				)
			],
			{
				&"enemy.instance.active-zero": _address(
					&"space.valid", Vector3i.ZERO
				)
			},
			0,
		),
		(
			EnemyWorldResolutionResultScript
			.FailureReason
			.ACTIVE_REQUIRES_POSITIVE_DURABILITY
		),
		"ACTIVE with zero durability",
		&"enemy.instance.active-zero",
	)
	_expect_failure(
		context,
		_resolve(
			[
				_record(
					&"enemy.instance.resolved-positive",
					PRIMARY_PROFILE_ID,
					1,
					EnemyWorldRecordScript.Lifecycle.RESOLVED,
				)
			],
			{},
			0,
		),
		(
			EnemyWorldResolutionResultScript
			.FailureReason
			.RESOLVED_REQUIRES_ZERO_DURABILITY
		),
		"RESOLVED with positive durability",
		&"enemy.instance.resolved-positive",
	)
	_expect_failure(
		context,
		_resolve([valid_record], {}, 0),
		(
			EnemyWorldResolutionResultScript
			.FailureReason
			.ACTIVE_REQUIRES_WORLD_ADDRESS
		),
		"ACTIVE without a world address",
		&"enemy.instance.valid",
	)
	var resolved_with_address: EnemyWorldRecordScript = _record(
		&"enemy.instance.resolved-occupant",
		PRIMARY_PROFILE_ID,
		0,
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
	)
	_expect_failure(
		context,
		_resolve(
			[resolved_with_address],
			{
				&"enemy.instance.resolved-occupant": _address(
					&"space.valid", Vector3i.ZERO
				)
			},
			0,
		),
		(
			EnemyWorldResolutionResultScript
			.FailureReason
			.RESOLVED_CANNOT_OCCUPY_WORLD_ADDRESS
		),
		"RESOLVED still occupying a grid slot",
		&"enemy.instance.resolved-occupant",
		&"space.valid",
	)

	var successful: EnemyWorldResolutionResultScript = _resolve(
		[valid_record],
		{&"enemy.instance.valid": valid_address},
		0,
	)
	_expect_success(context, successful, "Query failure fixture")
	if successful.succeeded():
		var invalid_query: EnemyWorldQueryResultScript = (
			successful.lookup_enemy(&"")
		)
		context.expect_true(not invalid_query.succeeded(), "Invalid query must fail.")
		context.expect_equal(
			invalid_query.failure_reason(),
			EnemyWorldQueryResultScript.FailureReason.INVALID_INSTANCE_ID,
			"Invalid query failure reason.",
		)
		context.expect_true(
			invalid_query.record() == null,
			"Invalid query exposes no record.",
		)
		var unknown_query: EnemyWorldQueryResultScript = (
			successful.lookup_enemy(&"enemy.instance.unknown")
		)
		context.expect_equal(
			unknown_query.failure_reason(),
			EnemyWorldQueryResultScript.FailureReason.UNKNOWN_INSTANCE_ID,
			"Unknown query has a distinct structured failure.",
		)


func _reuses_instance_and_registry_validation(
	context: HeadlessTestContextScript,
) -> void:
	var valid_addresses: Dictionary = {
		&"enemy.instance.validation": _address(&"space.validation", Vector3i.ZERO),
	}
	var valid_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.validation",
		PRIMARY_PROFILE_ID,
		8,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	for invalid_registry: RefCounted in [
		null,
		RefCounted.new(),
		ContentRegistryScript.new(),
	]:
		_expect_instance_failure(
			context,
			EnemyWorldResolverScript.resolve(
				EnemyWorldStateScript.create([valid_record], valid_addresses, 0),
				invalid_registry,
			),
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
			&"enemy.instance.validation",
			"Invalid sealed Registry",
		)
	_expect_instance_failure(
		context,
		_resolve(
			[
				_record(
					&"enemy.instance.schema-drift",
					PRIMARY_PROFILE_ID,
					8,
					EnemyWorldRecordScript.Lifecycle.ACTIVE,
					EnemyInstanceStateScript.StateKind.PRIMARY,
					false,
					CONTENT_SCHEMA_VERSION - 1,
					CONTENT_VERSION,
				)
			],
			{
				&"enemy.instance.schema-drift": _address(
					&"space.validation", Vector3i.ZERO
				)
			},
			0,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.CONTENT_SCHEMA_VERSION_MISMATCH
		),
		&"enemy.instance.schema-drift",
		"Schema-version drift",
	)
	_expect_instance_failure(
		context,
		_resolve(
			[
				_record(
					&"enemy.instance.content-drift",
					PRIMARY_PROFILE_ID,
					8,
					EnemyWorldRecordScript.Lifecycle.ACTIVE,
					EnemyInstanceStateScript.StateKind.PRIMARY,
					false,
					CONTENT_SCHEMA_VERSION,
					CONTENT_VERSION - 1,
				)
			],
			{
				&"enemy.instance.content-drift": _address(
					&"space.validation", Vector3i.ZERO
				)
			},
			0,
		),
		EnemyInstanceResolutionResultScript.FailureReason.CONTENT_VERSION_MISMATCH,
		&"enemy.instance.content-drift",
		"Content-version drift",
	)
	_expect_instance_failure(
		context,
		_resolve(
			[
				_record(
					&"enemy.instance.unknown-profile",
					&"enemy.profile.unknown",
					1,
					EnemyWorldRecordScript.Lifecycle.ACTIVE,
				)
			],
			{
				&"enemy.instance.unknown-profile": _address(
					&"space.validation", Vector3i.ZERO
				)
			},
			0,
		),
		EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID,
		&"enemy.instance.unknown-profile",
		"Unknown profile",
	)
	var unresolved_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.unresolved-query",
		&"enemy.profile.unknown",
		1,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var unresolved_address: EnemyWorldAddressScript = _address(
		&"space.validation",
		Vector3i.ZERO,
	)
	var unresolved_candidate: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[unresolved_record],
		{&"enemy.instance.unresolved-query": unresolved_address},
		0,
	)
	context.expect_true(
		unresolved_candidate.is_valid(),
		"Registry-invalid input remains a structurally valid resolution candidate.",
	)
	for resolved_result_only_method: StringName in [
		&"instance_ids",
		&"record_snapshots",
		&"address_snapshots",
		&"lookup_enemy",
		&"project_space",
		&"matches_exact_prestate",
	]:
		context.expect_true(
			not unresolved_candidate.has_method(resolved_result_only_method),
			"Candidates do not expose provenance-dependent read methods.",
		)
	var unresolved_read_snapshot: EnemyWorldReadSnapshotScript = (
		EnemyWorldReadSnapshotScript.create(
			unresolved_candidate,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
		)
	)
	context.expect_true(
		not unresolved_read_snapshot.is_valid(),
		"Unknown profiles cannot create a resolved read snapshot.",
	)
	var forged_query: EnemyWorldQueryResultScript = EnemyWorldQueryResultScript.success(
		unresolved_read_snapshot,
		&"enemy.instance.unresolved-query",
	)
	context.expect_equal(
		forged_query.failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_RESULT,
		"Public query construction cannot bypass Registry resolution.",
	)
	var forged_projection: EnemyGridProjectionResultScript = (
		EnemyGridProjectionResultScript.success(
			unresolved_read_snapshot,
			&"space.validation",
		)
	)
	context.expect_equal(
		forged_projection.failure_reason(),
		EnemyGridProjectionResultScript.FailureReason.INVALID_RESULT,
		"Public projection construction cannot bypass Registry resolution.",
	)
	var empty_resolved_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[],
		{},
		0,
	)
	var empty_read_snapshot: EnemyWorldReadSnapshotScript = (
		EnemyWorldReadSnapshotScript.create(
			empty_resolved_state,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
		)
	)
	context.expect_true(
		empty_read_snapshot.is_valid(),
		"A resolved empty world has a distinguishable successful read snapshot.",
	)
	var phantom_query: EnemyWorldQueryResultScript = EnemyWorldQueryResultScript.success(
		empty_read_snapshot,
		&"enemy.instance.phantom",
	)
	context.expect_equal(
		phantom_query.failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_RESULT,
		"Public query construction cannot invent an enemy outside its source world.",
	)
	var empty_projection: EnemyGridProjectionResultScript = (
		EnemyGridProjectionResultScript.success(
			empty_read_snapshot,
			&"space.validation",
		)
	)
	context.expect_true(
		empty_projection.succeeded(),
		"Public projection construction accepts an exact resolved empty world.",
	)
	context.expect_equal(
		empty_projection.actor_positions(),
		{},
		"Projection derives emptiness from its source world without raw actor input.",
	)

	var alpha_unknown: EnemyWorldRecordScript = _record(
		&"enemy.instance.alpha-unknown",
		&"enemy.profile.unknown",
		1,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var zeta_drift: EnemyWorldRecordScript = _record(
		&"enemy.instance.zeta-drift",
		PRIMARY_PROFILE_ID,
		8,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		EnemyInstanceStateScript.StateKind.PRIMARY,
		false,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION - 1,
	)
	var multi_addresses: Dictionary = {
		&"enemy.instance.alpha-unknown": _address(&"space.validation", Vector3i.ZERO),
		&"enemy.instance.zeta-drift": _address(&"space.validation", Vector3i.ONE),
	}
	for input_records: Array in [
		[alpha_unknown, zeta_drift],
		[zeta_drift, alpha_unknown],
	]:
		_expect_instance_failure(
			context,
			_resolve(input_records, multi_addresses, 0),
			EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID,
			&"enemy.instance.alpha-unknown",
			"Canonical first rejected instance",
		)

	var empty_result: EnemyWorldResolutionResultScript = _resolve([], {}, 3)
	_expect_success(context, empty_result, "Empty enemy catalog with valid Registry")
	_expect_instance_failure(
		context,
		EnemyWorldResolverScript.resolve(
			EnemyWorldStateScript.create([], {}, 3),
			null,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		&"",
		"Empty catalog still validates Registry",
	)


func _rejects_derived_inputs_without_reads(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world")
	var derived_world := StatefulEnemyWorldState.new()
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(derived_world, registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE,
		"Derived world state",
	)
	context.expect_equal(
		derived_world.read_count(),
		0,
		"Derived world state is rejected before overridable reads.",
	)
	var rejected_read_snapshot: EnemyWorldReadSnapshotScript = (
		EnemyWorldReadSnapshotScript.create(derived_world, registry)
	)
	context.expect_true(
		not rejected_read_snapshot.is_valid(),
		"Derived world states cannot create resolved read snapshots.",
	)
	var rejected_public_success: EnemyWorldResolutionResultScript = (
		EnemyWorldResolutionResultScript.success(derived_world, registry)
	)
	context.expect_equal(
		rejected_public_success.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT,
		"Derived world states cannot construct public resolution success.",
	)
	context.expect_equal(
		derived_world.read_count(),
		0,
		"Read-snapshot and result factories reject derived worlds without reads.",
	)

	var derived_record := StatefulEnemyWorldRecord.new()
	var record_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[derived_record],
		{},
		0,
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(record_state, registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD,
		"Derived world record",
	)
	context.expect_equal(
		derived_record.read_count(),
		0,
		"Derived world record is rejected before copy or getters.",
	)

	var derived_instance := StatefulEnemyInstance.new()
	var invalid_record: EnemyWorldRecordScript = EnemyWorldRecordScript.create(
		derived_instance,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	_expect_failure(
		context,
		_resolve([invalid_record], {}, 0),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD,
		"Derived nested enemy instance",
	)
	context.expect_equal(
		derived_instance.read_count(),
		0,
		"Derived nested enemy instance is rejected before copy or getters.",
	)

	var valid_record: EnemyWorldRecordScript = _record(
		&"enemy.instance.derived-address",
		PRIMARY_PROFILE_ID,
		8,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var derived_address := StatefulEnemyWorldAddress.new()
	var address_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[valid_record],
		{&"enemy.instance.derived-address": derived_address},
		0,
	)
	_expect_failure(
		context,
		EnemyWorldResolverScript.resolve(address_state, registry),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_ADDRESS,
		"Derived world address",
	)
	context.expect_equal(
		derived_address.read_count(),
		0,
		"Derived address is rejected before copy or validity reads.",
	)

	var derived_registry := StatefulContentRegistryScript.new()
	_expect_instance_failure(
		context,
		EnemyWorldResolverScript.resolve(
			EnemyWorldStateScript.create(
				[valid_record],
				{
					&"enemy.instance.derived-address": _address(
						&"space.valid", Vector3i.ZERO
					)
				},
				0,
			),
			derived_registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		&"enemy.instance.derived-address",
		"Derived Registry",
	)
	context.expect_equal(
		derived_registry.read_count(),
		0,
		"Derived Registry is rejected before overridable reads.",
	)
	var derived_read_snapshot := StatefulEnemyWorldReadSnapshot.new()
	var derived_query: EnemyWorldQueryResultScript = EnemyWorldQueryResultScript.success(
		derived_read_snapshot,
		&"enemy.instance.derived-source",
	)
	context.expect_equal(
		derived_query.failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_RESULT,
		"Derived read snapshots cannot construct query success.",
	)
	var derived_projection: EnemyGridProjectionResultScript = (
		EnemyGridProjectionResultScript.success(
			derived_read_snapshot,
			&"space.derived-source",
		)
	)
	context.expect_equal(
		derived_projection.failure_reason(),
		EnemyGridProjectionResultScript.FailureReason.INVALID_RESULT,
		"Derived read snapshots cannot construct projection success.",
	)
	context.expect_equal(
		derived_read_snapshot.read_count(),
		0,
		"Derived read snapshots are rejected before overridable reads.",
	)


func _isolates_inputs_outputs_and_integrity(
	context: HeadlessTestContextScript,
) -> void:
	var input_instance: EnemyInstanceStateScript = _instance_state(
		&"enemy.instance.isolation",
		ALTERNATE_SHIELD_PROFILE_ID,
		6,
		EnemyInstanceStateScript.StateKind.ALTERNATE,
		true,
	)
	var input_record: EnemyWorldRecordScript = EnemyWorldRecordScript.create(
		input_instance,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var input_address: EnemyWorldAddressScript = _address(
		&"space.isolation",
		Vector3i(3, -2, 7),
	)
	var input_records: Array = [input_record]
	var input_addresses: Dictionary = {
		&"enemy.instance.isolation": input_address,
	}
	var candidate: EnemyWorldStateScript = EnemyWorldStateScript.create(
		input_records,
		input_addresses,
		22,
	)
	var result: EnemyWorldResolutionResultScript = EnemyWorldResolverScript.resolve(
		candidate,
		CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
	)
	_expect_success(context, result, "Isolation fixture")
	if not result.succeeded():
		return

	input_instance._current_durability = 0
	input_record._lifecycle = EnemyWorldRecordScript.Lifecycle.RESOLVED
	input_address._space_id = &"space.input-tampered"
	input_records.clear()
	input_addresses.clear()
	candidate._world_step = 999
	context.expect_equal(
		result.snapshot().world_step(),
		22,
		"Input state mutation cannot alter resolved world truth.",
	)
	_assert_query(
		context,
		result,
		&"enemy.instance.isolation",
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		6,
		true,
		&"space.isolation",
		Vector3i(3, -2, 7),
		true,
	)

	var first_snapshot: EnemyWorldStateScript = result.snapshot()
	var second_snapshot: EnemyWorldStateScript = result.snapshot()
	context.expect_true(
		first_snapshot != second_snapshot,
		"Resolution snapshot getters return independent copies.",
	)
	first_snapshot._world_step = 1
	first_snapshot._records[0]._instance_state._current_durability = 1
	context.expect_equal(
		result.snapshot().world_step(),
		22,
		"Returned world-step mutation cannot alter later snapshots.",
	)
	context.expect_equal(
		result.lookup_enemy(
			&"enemy.instance.isolation"
		).instance_state().current_durability(),
		6,
		"Returned record mutation cannot alter later snapshots.",
	)

	var returned_records: Array[EnemyWorldRecordScript] = (
		result.record_snapshots()
	)
	var next_records: Array[EnemyWorldRecordScript] = result.record_snapshots()
	context.expect_true(
		returned_records[0] != next_records[0],
		"Record enumeration returns defensive snapshots.",
	)
	returned_records[0]._lifecycle = EnemyWorldRecordScript.Lifecycle.RESOLVED
	context.expect_equal(
		result.record_snapshots()[0].lifecycle(),
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
		"Returned record changes cannot alter the state.",
	)
	var returned_addresses: Dictionary[StringName, EnemyWorldAddressScript] = (
		result.address_snapshots()
	)
	returned_addresses[&"enemy.instance.isolation"]._space_id = &"space.output-tampered"
	returned_addresses.clear()
	context.expect_equal(
		result.lookup_enemy(
			&"enemy.instance.isolation"
		).world_address().space_id(),
		&"space.isolation",
		"Returned address map and values cannot alter the state.",
	)

	var query: EnemyWorldQueryResultScript = result.lookup_enemy(
		&"enemy.instance.isolation"
	)
	var returned_query_record: EnemyWorldRecordScript = query.record()
	var returned_query_address: EnemyWorldAddressScript = query.world_address()
	returned_query_record._instance_state._current_durability = 2
	returned_query_address._cell = Vector3i.ZERO
	context.expect_equal(
		query.instance_state().current_durability(),
		6,
		"Query record getter is defensive.",
	)
	context.expect_equal(
		query.world_address().cell(),
		Vector3i(3, -2, 7),
		"Query address getter is defensive.",
	)

	var projection: EnemyGridProjectionResultScript = result.project_space(
		&"space.isolation"
	)
	var returned_positions: Dictionary[StringName, Vector3i] = (
		projection.actor_positions()
	)
	returned_positions[&"enemy.instance.isolation"] = Vector3i.ZERO
	returned_positions.clear()
	context.expect_equal(
		projection.actor_positions(),
		{&"enemy.instance.isolation": Vector3i(3, -2, 7)},
		"Projection actor dictionary is defensive.",
	)

	query._record._lifecycle = EnemyWorldRecordScript.Lifecycle.RESOLVED
	context.expect_true(not query.succeeded(), "Tampered query fails closed.")
	context.expect_equal(
		query.failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_RESULT,
		"Tampered query exposes INVALID_RESULT.",
	)
	context.expect_true(query.record() == null, "Tampered query exposes no record.")
	projection._actor_positions = {&"enemy.instance.isolation": Vector3i.ZERO}
	context.expect_true(not projection.succeeded(), "Tampered projection fails closed.")
	context.expect_equal(
		projection.failure_reason(),
		EnemyGridProjectionResultScript.FailureReason.INVALID_RESULT,
		"Tampered projection exposes INVALID_RESULT.",
	)
	context.expect_equal(
		projection.actor_positions(),
		{},
		"Tampered projection exposes no actor positions.",
	)
	var scalar_projection: EnemyGridProjectionResultScript = (
		result.project_space(&"space.isolation")
	)
	scalar_projection._space_id = &"space.other"
	context.expect_true(
		not scalar_projection.succeeded(),
		"Tampering a projection space ID invalidates the result.",
	)
	var step_projection: EnemyGridProjectionResultScript = result.project_space(
		&"space.isolation"
	)
	step_projection._world_step = 23
	context.expect_true(
		not step_projection.succeeded(),
		"Tampering a projection world step invalidates the result.",
	)

	var self_invalidating: EnemyWorldResolutionResultScript = _resolve(
		[
			_record(
				&"enemy.instance.self-invalidating",
				PRIMARY_PROFILE_ID,
				8,
				EnemyWorldRecordScript.Lifecycle.ACTIVE,
			)
		],
		{
			&"enemy.instance.self-invalidating": _address(
				&"space.integrity", Vector3i.ZERO
			)
		},
		0,
	)
	context.expect_true(self_invalidating.succeeded(), "Integrity fixture succeeds.")
	self_invalidating._read_snapshot._state._world_step = 1
	context.expect_true(
		not self_invalidating.succeeded(),
		"Internal result tampering invalidates success.",
	)
	context.expect_equal(
		self_invalidating.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT,
		"Internal result tampering returns INVALID_RESULT.",
	)
	context.expect_true(
		self_invalidating.snapshot() == null,
		"Invalidated result exposes no partial world snapshot.",
	)
	var read_invalidating: EnemyWorldResolutionResultScript = _resolve(
		[
			_record(
				&"enemy.instance.read-integrity",
				PRIMARY_PROFILE_ID,
				8,
				EnemyWorldRecordScript.Lifecycle.ACTIVE,
			)
		],
		{
			&"enemy.instance.read-integrity": _address(
				&"space.integrity", Vector3i.ONE
			)
		},
		0,
	)
	context.expect_true(read_invalidating.succeeded(), "Read integrity fixture succeeds.")
	read_invalidating._read_snapshot._state._world_step = 1
	context.expect_true(
		not read_invalidating.succeeded(),
		"Resolved read-source tampering invalidates success.",
	)
	context.expect_equal(
		read_invalidating.instance_ids(),
		[],
		"Invalidated read source exposes no catalog IDs.",
	)
	context.expect_equal(
		read_invalidating.lookup_enemy(
			&"enemy.instance.read-integrity"
		).failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_WORLD_STATE,
		"Invalidated read source cannot answer queries.",
	)
	context.expect_equal(
		read_invalidating.project_space(
			&"space.integrity"
		).failure_reason(),
		EnemyGridProjectionResultScript.FailureReason.INVALID_WORLD_STATE,
		"Invalidated read source cannot project actors.",
	)
	var forged_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		[
			_record(
				&"enemy.instance.forged-profile",
				&"enemy.profile.unknown",
				1,
				EnemyWorldRecordScript.Lifecycle.ACTIVE,
			)
		],
		{
			&"enemy.instance.forged-profile": _address(
				&"space.integrity", Vector3i.ZERO
			)
		},
		0,
	)
	var forged_result: EnemyWorldResolutionResultScript = (
		EnemyWorldResolutionResultScript.success(
			forged_state,
			CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
		)
	)
	context.expect_true(
		not forged_result.succeeded(),
		"Public success construction cannot bypass Registry resolution.",
	)
	context.expect_equal(
		forged_result.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT,
		"Forged public success returns INVALID_RESULT.",
	)
	for failure_tamper: Dictionary in [
		{
			"field": &"_failure_reason",
			"value": EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STEP,
		},
		{
			"field": &"_failed_instance_id",
			"value": &"enemy.instance.tampered",
		},
		{
			"field": &"_failed_space_id",
			"value": &"space.tampered",
		},
		{
			"field": &"_enemy_instance_failure_reason",
			"value": EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		},
	]:
		var tampered_failure: EnemyWorldResolutionResultScript = (
			EnemyWorldResolutionResultScript.failure(
				EnemyWorldResolutionResultScript.FailureReason.ORPHAN_GRID_ACTOR,
				&"enemy.instance.orphan",
				&"space.integrity",
			)
		)
		tampered_failure.set(failure_tamper["field"], failure_tamper["value"])
		context.expect_equal(
			tampered_failure.failure_reason(),
			EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT,
			"Tampered failure metadata collapses to INVALID_RESULT.",
		)
		context.expect_equal(
			tampered_failure.failed_instance_id(),
			&"",
			"Tampered failure exposes no instance ID.",
		)
		context.expect_equal(
			tampered_failure.failed_space_id(),
			&"",
			"Tampered failure exposes no space ID.",
		)
		context.expect_equal(
			tampered_failure.enemy_instance_failure_reason(),
			EnemyInstanceResolutionResultScript.FailureReason.NONE,
			"Tampered failure exposes no nested reason.",
		)
	var malformed_failure: EnemyWorldResolutionResultScript = (
		EnemyWorldResolutionResultScript.failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE,
			&"enemy.instance.injected",
			&"space.injected",
		)
	)
	context.expect_equal(
		malformed_failure.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT,
		"Public failure construction rejects metadata forbidden by its reason.",
	)
	context.expect_equal(
		malformed_failure.failed_instance_id(),
		&"",
		"Malformed public failure exposes no injected ID.",
	)
	var tampered_query_failure: EnemyWorldQueryResultScript = (
		EnemyWorldQueryResultScript.failure(
			EnemyWorldQueryResultScript.FailureReason.UNKNOWN_INSTANCE_ID
		)
	)
	tampered_query_failure._failure_reason = (
		EnemyWorldQueryResultScript.FailureReason.INVALID_INSTANCE_ID
	)
	context.expect_equal(
		tampered_query_failure.failure_reason(),
		EnemyWorldQueryResultScript.FailureReason.INVALID_RESULT,
		"Tampered query failure reason collapses to INVALID_RESULT.",
	)
	var tampered_projection_failure: EnemyGridProjectionResultScript = (
		EnemyGridProjectionResultScript.failure(
			EnemyGridProjectionResultScript.FailureReason.INVALID_SPACE_ID
		)
	)
	tampered_projection_failure._failure_reason = (
		EnemyGridProjectionResultScript.FailureReason.INVALID_WORLD_STATE
	)
	context.expect_equal(
		tampered_projection_failure.failure_reason(),
		EnemyGridProjectionResultScript.FailureReason.INVALID_RESULT,
		"Tampered projection failure reason collapses to INVALID_RESULT.",
	)


func _matches_exact_prestates_and_replays(
	context: HeadlessTestContextScript,
) -> void:
	var alpha: EnemyWorldRecordScript = _record(
		&"enemy.instance.alpha",
		PRIMARY_PROFILE_ID,
		4,
		EnemyWorldRecordScript.Lifecycle.ACTIVE,
	)
	var beta: EnemyWorldRecordScript = _record(
		&"enemy.instance.beta",
		PRIMARY_PROFILE_ID,
		0,
		EnemyWorldRecordScript.Lifecycle.RESOLVED,
	)
	var addresses: Dictionary = {
		&"enemy.instance.alpha": _address(&"space.replay", Vector3i(-1, 0, -1)),
	}
	var first: EnemyWorldResolutionResultScript = _resolve(
		[beta, alpha],
		addresses,
		17,
	)
	var second: EnemyWorldResolutionResultScript = _resolve(
		[alpha, beta],
		addresses,
		17,
	)
	_expect_success(context, first, "First canonical replay")
	_expect_success(context, second, "Second canonical replay")
	if not first.succeeded() or not second.succeeded():
		return
	context.expect_true(
		first.matches_exact_prestate(second),
		"Equivalent unordered inputs match as exact prestates.",
	)
	context.expect_equal(
		_encode_state(first),
		_encode_state(second),
		"Equivalent unordered inputs expose identical canonical snapshots.",
	)
	for _iteration: int in range(3):
		context.expect_equal(
			_encode_state(
				EnemyWorldResolverScript.resolve(
					first.snapshot(),
					CanonicalRegistryFixtureScript.canonical_registry(context, "Enemy world"),
				)
			),
			_encode_state(first),
			"Repeated reconstruction is deterministic.",
		)

	var later_step: EnemyWorldResolutionResultScript = _resolve(
		[alpha, beta],
		addresses,
		18,
	)
	context.expect_true(
		not first.matches_exact_prestate(later_step),
		"A different world step is stale.",
	)
	var changed_durability: EnemyWorldResolutionResultScript = _resolve(
		[
			_record(
				&"enemy.instance.alpha",
				PRIMARY_PROFILE_ID,
				3,
				EnemyWorldRecordScript.Lifecycle.ACTIVE,
			),
			beta,
		],
		addresses,
		17,
	)
	context.expect_true(
		not first.matches_exact_prestate(changed_durability),
		"Changed durability is a different exact prestate.",
	)
	var changed_address: EnemyWorldResolutionResultScript = _resolve(
		[alpha, beta],
		{
			&"enemy.instance.alpha": _address(
				&"space.replay", Vector3i(-2, 0, -1)
			)
		},
		17,
	)
	context.expect_true(
		not first.matches_exact_prestate(changed_address),
		"Changed address is a different exact prestate.",
	)
	context.expect_true(
		not first.matches_exact_prestate(RefCounted.new()),
		"Wrong prestate types never match.",
	)
	var derived_prestate := StatefulEnemyWorldState.new()
	context.expect_true(
		not first.matches_exact_prestate(derived_prestate),
		"Derived expected prestates never match.",
	)
	context.expect_equal(
		derived_prestate.read_count(),
		0,
		"Exact prestate checks reject derived states before overridable reads.",
	)
	context.expect_true(
		not first.is_commit_boundary(),
		"H-4.6 remains a prestate contract, not a transaction commit.",
	)


func _assert_query(
	context: HeadlessTestContextScript,
	world_result: EnemyWorldResolutionResultScript,
	instance_id: StringName,
	expected_lifecycle: int,
	expected_durability: int,
	expected_has_address: bool,
	expected_space_id: StringName,
	expected_cell: Vector3i,
	expected_shield_intact: bool = false,
) -> void:
	var query: EnemyWorldQueryResultScript = world_result.lookup_enemy(instance_id)
	context.expect_true(query.succeeded(), "Enemy query %s succeeds." % instance_id)
	if not query.succeeded():
		return
	context.expect_equal(
		query.record().get_script(),
		EnemyWorldRecordScript,
		"Enemy query returns the exact record type.",
	)
	context.expect_equal(
		query.instance_state().get_script(),
		EnemyInstanceStateScript,
		"Enemy query returns the exact H-4.5 state type.",
	)
	context.expect_equal(query.lifecycle(), expected_lifecycle, "Enemy lifecycle.")
	context.expect_equal(
		query.instance_state().instance_id(),
		instance_id,
		"Query identity remains the canonical instance ID.",
	)
	context.expect_equal(
		query.instance_state().current_durability(),
		expected_durability,
		"Enemy durability is preserved.",
	)
	context.expect_equal(
		query.instance_state().shield_intact(),
		expected_shield_intact,
		"Enemy shield state is preserved.",
	)
	context.expect_equal(
		query.has_world_address(),
		expected_has_address,
		"Enemy address presence follows lifecycle.",
	)
	if expected_has_address:
		context.expect_equal(
			query.world_address().get_script(),
			EnemyWorldAddressScript,
			"Enemy query returns the exact address type.",
		)
		context.expect_equal(
			query.world_address().space_id(),
			expected_space_id,
			"Enemy space ID is preserved.",
		)
		context.expect_equal(
			query.world_address().cell(),
			expected_cell,
			"Enemy Vector3i cell is preserved.",
		)
	else:
		context.expect_true(
			query.world_address() == null,
			"Resolved query exposes no world address.",
		)


func _expect_success(
	context: HeadlessTestContextScript,
	result: EnemyWorldResolutionResultScript,
	label: String,
) -> void:
	context.expect_true(result != null, "%s must return a result." % label)
	if result == null:
		return
	context.expect_true(result.succeeded(), "%s must succeed." % label)
	context.expect_equal(
		result.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.NONE,
		"%s success reason." % label,
	)
	context.expect_equal(
		result.enemy_instance_failure_reason(),
		EnemyInstanceResolutionResultScript.FailureReason.NONE,
		"%s has no nested instance failure." % label,
	)
	context.expect_true(result.snapshot() != null, "%s exposes a snapshot." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s remains outside the commit boundary." % label,
	)


func _expect_failure(
	context: HeadlessTestContextScript,
	result: EnemyWorldResolutionResultScript,
	expected_reason: int,
	label: String,
	expected_instance_id: StringName = &"",
	expected_space_id: StringName = &"",
) -> void:
	context.expect_true(result != null, "%s must return a result." % label)
	if result == null:
		return
	context.expect_true(not result.succeeded(), "%s must fail closed." % label)
	context.expect_equal(
		result.failure_reason(),
		expected_reason,
		"%s failure reason." % label,
	)
	context.expect_equal(
		result.failed_instance_id(),
		expected_instance_id,
		"%s failed instance ID." % label,
	)
	context.expect_equal(
		result.failed_space_id(),
		expected_space_id,
		"%s failed space ID." % label,
	)
	context.expect_equal(
		result.enemy_instance_failure_reason(),
		EnemyInstanceResolutionResultScript.FailureReason.NONE,
		"%s has no nested instance failure." % label,
	)
	context.expect_true(result.snapshot() == null, "%s exposes no snapshot." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s remains outside the commit boundary." % label,
	)


func _expect_instance_failure(
	context: HeadlessTestContextScript,
	result: EnemyWorldResolutionResultScript,
	expected_instance_reason: int,
	expected_instance_id: StringName,
	label: String,
) -> void:
	context.expect_true(result != null, "%s must return a result." % label)
	if result == null:
		return
	context.expect_true(not result.succeeded(), "%s must fail closed." % label)
	context.expect_equal(
		result.failure_reason(),
		EnemyWorldResolutionResultScript.FailureReason.ENEMY_INSTANCE_REJECTED,
		"%s world failure reason." % label,
	)
	context.expect_equal(
		result.enemy_instance_failure_reason(),
		expected_instance_reason,
		"%s nested H-4.5 failure reason." % label,
	)
	context.expect_equal(
		result.failed_instance_id(),
		expected_instance_id,
		"%s failed instance ID." % label,
	)
	context.expect_true(result.snapshot() == null, "%s exposes no snapshot." % label)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s remains outside the commit boundary." % label,
	)


func _resolve(
	records: Array,
	addresses: Dictionary,
	world_step: int,
) -> EnemyWorldResolutionResultScript:
	return EnemyWorldResolverScript.resolve(
		EnemyWorldStateScript.create(records, addresses, world_step),
		CanonicalRegistryFixtureScript.canonical_registry_for_helpers(),
	)


func _record(
	instance_id: StringName,
	profile_id: StringName,
	current_durability: int,
	lifecycle: int,
	state_kind: int = EnemyInstanceStateScript.StateKind.PRIMARY,
	shield_intact: bool = false,
	content_schema_version: int = CONTENT_SCHEMA_VERSION,
	content_version: int = CONTENT_VERSION,
) -> EnemyWorldRecordScript:
	return EnemyWorldRecordScript.create(
		_instance_state(
			instance_id,
			profile_id,
			current_durability,
			state_kind,
			shield_intact,
			content_schema_version,
			content_version,
		),
		lifecycle,
	)


func _instance_state(
	instance_id: StringName,
	profile_id: StringName,
	current_durability: int,
	state_kind: int,
	shield_intact: bool,
	content_schema_version: int = CONTENT_SCHEMA_VERSION,
	content_version: int = CONTENT_VERSION,
) -> EnemyInstanceStateScript:
	return EnemyInstanceStateScript.create(
		instance_id,
		profile_id,
		content_schema_version,
		content_version,
		current_durability,
		state_kind,
		shield_intact,
	)


func _address(space_id: StringName, cell: Vector3i) -> EnemyWorldAddressScript:
	return EnemyWorldAddressScript.create(space_id, cell)


func _encode_state(result: EnemyWorldResolutionResultScript) -> Array:
	if result == null or not result.succeeded():
		return []
	var state: EnemyWorldStateScript = result.snapshot()
	var encoded: Array = [state.world_step(), result.instance_ids()]
	for record: EnemyWorldRecordScript in result.record_snapshots():
		var instance_state: EnemyInstanceStateScript = record.instance_state()
		encoded.append(
			[
				record.lifecycle(),
				instance_state.instance_id(),
				instance_state.profile_id(),
				instance_state.content_schema_version(),
				instance_state.content_version(),
				instance_state.current_durability(),
				instance_state.state_kind(),
				instance_state.shield_intact(),
			]
		)
	var encoded_addresses: Array = []
	var addresses: Dictionary[StringName, EnemyWorldAddressScript] = (
		result.address_snapshots()
	)
	for instance_id: StringName in result.instance_ids():
		if addresses.has(instance_id):
			encoded_addresses.append(
				[
					instance_id,
					addresses[instance_id].space_id(),
					addresses[instance_id].cell(),
				]
			)
	encoded.append(encoded_addresses)
	return encoded
