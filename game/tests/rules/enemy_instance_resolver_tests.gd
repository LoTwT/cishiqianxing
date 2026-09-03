extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatKernelScript := preload(
	"res://src/rules/contact_combat_kernel.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyInstanceSnapshotScript := preload(
	"res://src/rules/enemy_instance_snapshot.gd"
)
const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
)
const EnemyInstanceResolverScript := preload(
	"res://src/rules/enemy_instance_resolver.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const EnemyProfileCatalogOracle := preload(
	"res://tests/content/enemy_profile_catalog_oracle.gd"
)
const StatefulContentRegistryScript := preload(
	"res://tests/support/stateful_content_registry.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)

const CONTENT_SCHEMA_VERSION: int = 5
const CONTENT_VERSION: int = 5
const EXPECTED_PRIMARY_PROJECTION_COUNT: int = 24
const EXPECTED_ALTERNATE_PROJECTION_COUNT: int = 4
const EXPECTED_TOTAL_PROJECTION_COUNT: int = 28
const EXPECTED_SHIELD_PROFILE_COUNT: int = 5
const EXPECTED_NON_ALTERNATE_PROFILE_COUNT: int = 20

var _cached_registry: ContentRegistryScript


class StatefulEnemyInstance extends EnemyInstanceStateScript:
	var _reads: int = 0

	func copy() -> EnemyInstanceState:
		_reads += 1
		return super.copy()

	func is_initialized() -> bool:
		_reads += 1
		return true

	func instance_id() -> StringName:
		_reads += 1
		return &"enemy.instance.derived"

	func read_count() -> int:
		return _reads


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"enemy_instance.freezes_literal_runtime_oracle",
			_freezes_literal_runtime_oracle,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.creates_all_canonical_primary_instances",
			_creates_all_canonical_primary_instances,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.resolves_all_primary_and_alternate_projections",
			_resolves_all_primary_and_alternate_projections,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.rehydrates_dynamic_state_matrix",
			_rehydrates_dynamic_state_matrix,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.rejects_invalid_inputs_in_stable_priority",
			_rejects_invalid_inputs_in_stable_priority,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.rejects_derived_inputs_without_reads",
			_rejects_derived_inputs_without_reads,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.isolates_inputs_outputs_and_registry_truth",
			_isolates_inputs_outputs_and_registry_truth,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.bridges_every_profile_to_h43_kernel",
			_bridges_every_profile_to_h43_kernel,
		),
		HeadlessTestCaseScript.new(
			"enemy_instance.replays_deterministically",
			_replays_deterministically,
		),
	]


func _freezes_literal_runtime_oracle(context: HeadlessTestContextScript) -> void:
	var rows: Array[EnemyProfileCatalogOracle.ProfileRow] = (
		EnemyProfileCatalogOracle.profile_rows()
	)
	context.expect_equal(
		rows.size(),
		EXPECTED_PRIMARY_PROJECTION_COUNT,
		"The literal oracle must retain all 24 primary enemy profiles.",
	)
	var alternate_count: int = 0
	var shield_count: int = 0
	var seen_ids: Dictionary[StringName, bool] = {}
	for row: EnemyProfileCatalogOracle.ProfileRow in rows:
		context.expect_true(
			not String(row.profile_id).is_empty(),
			"Every literal profile ID must be stable and non-empty.",
		)
		context.expect_true(
			not seen_ids.has(row.profile_id),
			"Literal profile IDs must be unique.",
		)
		seen_ids[row.profile_id] = true
		if row.has_alternate_state:
			alternate_count += 1
			context.expect_true(
				row.alternate_expectation != null,
				"Every alternate profile must freeze a combat expectation.",
			)
		else:
			context.expect_true(
				row.alternate_expectation == null,
				"Profiles without an alternate state must freeze no alternate oracle.",
			)
		if row.combat_trait_ids.has(EnemyProfileDefinitionScript.SHIELD_TRAIT_ID):
			shield_count += 1
	context.expect_equal(
		alternate_count,
		EXPECTED_ALTERNATE_PROJECTION_COUNT,
		"The oracle must freeze exactly four alternate projections.",
	)
	context.expect_equal(
		rows.size() + alternate_count,
		EXPECTED_TOTAL_PROJECTION_COUNT,
		"The runtime oracle must cover 24 primary plus four alternate projections.",
	)
	context.expect_equal(
		shield_count,
		EXPECTED_SHIELD_PROFILE_COUNT,
		"The oracle must retain exactly five shield-capable profiles.",
	)
	var registry: ContentRegistryScript = _canonical_registry(context)
	context.expect_equal(
		registry.schema_version(),
		CONTENT_SCHEMA_VERSION,
		"Runtime resolution must retain manifest schema v5.",
	)
	context.expect_equal(
		registry.content_version(),
		CONTENT_VERSION,
		"Runtime resolution must retain manifest content v5.",
	)
	context.expect_true(
		EnemyInstanceStateScript.is_valid_instance_id(
			&"enemy.instance-01:room_A"
		),
		"Stable instance IDs may use the frozen ASCII identifier punctuation.",
	)
	context.expect_true(
		EnemyInstanceStateScript.is_valid_instance_id(
			StringName("a".repeat(EnemyInstanceStateScript.MAXIMUM_INSTANCE_ID_LENGTH))
		),
		"The exact maximum instance-ID length must remain valid.",
	)
	context.expect_true(
		not EnemyInstanceStateScript.is_valid_instance_id(
			StringName(
				"a".repeat(EnemyInstanceStateScript.MAXIMUM_INSTANCE_ID_LENGTH + 1)
			)
		),
		"An instance ID beyond the bounded maximum must fail closed.",
	)
	context.expect_true(
		not EnemyInstanceSnapshotScript.new().has_method(
			&"contact_combat_opponent_state"
		),
		"A defensive snapshot must not expose a Registry-free H4.3 bridge.",
	)
	for invalid_instance_id: StringName in [&"", &" ", &"...", &"敌人.实例"]:
		context.expect_true(
			not EnemyInstanceStateScript.is_valid_instance_id(invalid_instance_id),
			"Empty, punctuation-only, whitespace or localized IDs must be rejected.",
		)


func _creates_all_canonical_primary_instances(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var created_count: int = 0
	var rows: Array[EnemyProfileCatalogOracle.ProfileRow] = (
		EnemyProfileCatalogOracle.profile_rows()
	)
	for index: int in range(rows.size()):
		var row: EnemyProfileCatalogOracle.ProfileRow = rows[index]
		var instance_id: StringName = _instance_id(index, "primary")
		var result: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.create_initial(
				instance_id,
				row.profile_id,
				registry,
			)
		)
		_expect_success(context, result, "%s initial instance" % row.profile_id)
		if not result.succeeded():
			continue
		var state: EnemyInstanceStateScript = result.instance_state()
		context.expect_equal(state.instance_id(), instance_id, "Initial instance ID.")
		context.expect_equal(state.profile_id(), row.profile_id, "Initial profile ID.")
		context.expect_equal(
			state.content_schema_version(),
			CONTENT_SCHEMA_VERSION,
			"Initial instance schema version.",
		)
		context.expect_equal(
			state.content_version(),
			CONTENT_VERSION,
			"Initial instance content version.",
		)
		context.expect_equal(
			state.current_durability(),
			row.maximum_durability,
			"Initial instances must start at primary maximum durability.",
		)
		context.expect_equal(
			state.state_kind(),
			EnemyInstanceStateScript.StateKind.PRIMARY,
			"Initial instances must start in the primary state.",
		)
		context.expect_equal(
			state.shield_intact(),
			row.combat_trait_ids.has(EnemyProfileDefinitionScript.SHIELD_TRAIT_ID),
			"Initial shield state must come from the central profile trait.",
		)
		_assert_projection(context, result, row, false)
		created_count += 1
	context.expect_equal(
		created_count,
		EXPECTED_PRIMARY_PROJECTION_COUNT,
		"All 24 canonical profiles must create a primary runtime instance.",
	)

	var first_profile_id: StringName = rows[0].profile_id
	var first: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.create_initial(
			&"enemy.instance.identity.a",
			first_profile_id,
			registry,
		)
	)
	var second: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.create_initial(
			&"enemy.instance.identity.b",
			first_profile_id,
			registry,
		)
	)
	context.expect_true(first.succeeded() and second.succeeded(), "Identity fixtures.")
	context.expect_equal(
		first.instance_state().profile_id(),
		second.instance_state().profile_id(),
		"Two instances may reference the same central profile.",
	)
	context.expect_true(
		first.instance_state().instance_id() != second.instance_state().instance_id(),
		"Runtime identity must remain independent from profile identity.",
	)
	var forbidden_properties: Array[StringName] = [
		&"_maximum_durability",
		&"_attack",
		&"_defense",
		&"_speed",
		&"_behavior_id",
		&"_combat_trait_ids",
		&"_visual_binding_id",
	]
	var state_property_names: Array[StringName] = []
	for property: Dictionary in first.instance_state().get_property_list():
		state_property_names.append(StringName(property.get("name", "")))
	for forbidden_property: StringName in forbidden_properties:
		context.expect_true(
			not state_property_names.has(forbidden_property),
			"Persistent runtime state must not copy static field %s."
			% String(forbidden_property),
		)


func _resolves_all_primary_and_alternate_projections(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var resolved_count: int = 0
	var rejected_alternate_count: int = 0
	var rows: Array[EnemyProfileCatalogOracle.ProfileRow] = (
		EnemyProfileCatalogOracle.profile_rows()
	)
	for index: int in range(rows.size()):
		var row: EnemyProfileCatalogOracle.ProfileRow = rows[index]
		var primary: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(
				_state(
					_instance_id(index, "rehydrated-primary"),
					row.profile_id,
					row.maximum_durability,
					EnemyInstanceStateScript.StateKind.PRIMARY,
					row.primary_expectation.shield_intact,
				),
				registry,
			)
		)
		_expect_success(context, primary, "%s primary projection" % row.profile_id)
		if primary.succeeded():
			_assert_projection(context, primary, row, false)
			resolved_count += 1

		var alternate_state: EnemyInstanceStateScript = _state(
			_instance_id(index, "rehydrated-alternate"),
			row.profile_id,
			row.alternate_maximum_durability,
			EnemyInstanceStateScript.StateKind.ALTERNATE,
			row.primary_expectation.shield_intact,
		)
		var alternate: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(alternate_state, registry)
		)
		if row.has_alternate_state:
			_expect_success(context, alternate, "%s alternate projection" % row.profile_id)
			if alternate.succeeded():
				_assert_projection(context, alternate, row, true)
				resolved_count += 1
		else:
			_expect_failure(
				context,
				alternate,
				(
					EnemyInstanceResolutionResultScript
					.FailureReason
					.ALTERNATE_STATE_UNAVAILABLE
				),
				"%s unavailable alternate" % row.profile_id,
			)
			rejected_alternate_count += 1
	context.expect_equal(
		resolved_count,
		EXPECTED_TOTAL_PROJECTION_COUNT,
		"Resolution must cover all 28 primary and alternate projections.",
	)
	context.expect_equal(
		rejected_alternate_count,
		EXPECTED_NON_ALTERNATE_PROFILE_COUNT,
		"All 20 profiles without alternates must reject alternate restoration.",
	)


func _rehydrates_dynamic_state_matrix(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var shield_row: EnemyProfileCatalogOracle.ProfileRow = _row(
		&"enemy.profile.f03.base"
	)
	var cases_to_restore: Array[Array] = [
		[shield_row.maximum_durability, true, "full-shield", "full shield"],
		[shield_row.maximum_durability - 5, true, "damaged-shield", "damaged shield"],
		[shield_row.maximum_durability - 5, false, "broken-shield", "broken shield"],
		[0, false, "zero-durability", "zero durability"],
		[0, true, "zero-durability-shield", "zero durability with retained shield state"],
	]
	for fixture: Array in cases_to_restore:
		var restored: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(
				_state(
					StringName("enemy.instance.restore.%s" % fixture[2]),
					shield_row.profile_id,
					fixture[0],
					EnemyInstanceStateScript.StateKind.PRIMARY,
					fixture[1],
				),
				registry,
			)
		)
		_expect_success(context, restored, "Restore %s" % fixture[3])
		if restored.succeeded():
			context.expect_equal(
				restored.instance_state().current_durability(),
				fixture[0],
				"Restored durability must remain exact.",
			)
			context.expect_equal(
				restored.instance_state().shield_intact(),
				fixture[1],
				"Restored shield state must remain exact.",
			)
			context.expect_equal(
				restored.snapshot().shield_intact(),
				fixture[1],
				"The defensive snapshot must preserve restored shield state.",
			)
			context.expect_equal(
				restored.contact_combat_opponent_state().shield_intact(),
				fixture[1],
				"The H4.3 bridge must preserve restored shield state.",
			)

	var zero: EnemyInstanceResolutionResultScript = EnemyInstanceResolverScript.resolve(
		_state(
			&"enemy.instance.zero",
			shield_row.profile_id,
			0,
			EnemyInstanceStateScript.StateKind.PRIMARY,
			false,
		),
		registry,
	)
	var inactive: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_initial_player_state(),
		zero.contact_combat_opponent_state(),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)
	context.expect_equal(
		inactive.rejection_reason(),
		ContactCombatResultScript.RejectionReason.OPPONENT_INACTIVE,
		"Zero durability is a valid resolved instance and H4.3 owns inactivity.",
	)


func _rejects_invalid_inputs_in_stable_priority(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var base_state: EnemyInstanceStateScript = _state(
		&"enemy.instance.invalid-matrix",
		&"enemy.profile.f01.base",
		12,
		EnemyInstanceStateScript.StateKind.PRIMARY,
		false,
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(null, registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Null state",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(RefCounted.new(), registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Wrong state type",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(EnemyInstanceStateScript.new(), registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Uninitialized state",
	)
	for invalid_state: EnemyInstanceStateScript in [
		_state(&"", &"enemy.profile.f01.base", 12, 1, false),
		_state(&" ", &"enemy.profile.f01.base", 12, 1, false),
		_state(&"敌人.实例", &"enemy.profile.f01.base", 12, 1, false),
		_state(
			StringName(
				"a".repeat(EnemyInstanceStateScript.MAXIMUM_INSTANCE_ID_LENGTH + 1)
			),
			&"enemy.profile.f01.base",
			12,
			1,
			false,
		),
		_state(&"enemy.instance.empty-profile", &"", 12, 1, false),
		_state(&"enemy.instance.bad-schema", &"enemy.profile.f01.base", 12, 1, false, 0, 5),
		_state(&"enemy.instance.bad-content", &"enemy.profile.f01.base", 12, 1, false, 5, 0),
	]:
		_expect_failure(
			context,
			EnemyInstanceResolverScript.resolve(invalid_state, registry),
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
			"Invalid identity or version",
		)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"", &"enemy.profile.f01.base", 12, 99, false),
			null,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Invalid instance identity precedes state kind and Registry validation",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.bad-kind", &"enemy.profile.f01.base", 12, 99, false),
			null,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_STATE_KIND,
		"Invalid state kind precedes registry validation",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(base_state, null),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Null registry",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(base_state, RefCounted.new()),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Wrong registry type",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(base_state, ContentRegistryScript.new()),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Uninitialized registry",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(
				&"enemy.instance.registry-priority",
				&"enemy.profile.f01.base",
				12,
				EnemyInstanceStateScript.StateKind.PRIMARY,
				false,
				4,
				5,
			),
			null,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Invalid Registry precedes content schema mismatch",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.version", &"enemy.profile.f01.base", 12, 1, false, 4, 4),
			registry,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.CONTENT_SCHEMA_VERSION_MISMATCH
		),
		"Schema mismatch precedes content mismatch",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.version", &"enemy.profile.f01.base", 12, 1, false, 5, 4),
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.CONTENT_VERSION_MISMATCH,
		"Content mismatch",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(
				&"enemy.instance.content-priority",
				&"enemy.profile.unknown",
				0,
				EnemyInstanceStateScript.StateKind.PRIMARY,
				false,
				5,
				4,
			),
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.CONTENT_VERSION_MISMATCH,
		"Content version mismatch precedes unknown profile lookup",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.unknown", &"enemy.profile.unknown", -1, 2, true),
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID,
		"Unknown profile precedes profile-dependent checks",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.no-alt", &"enemy.profile.f01.base", 999, 2, true),
			registry,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.ALTERNATE_STATE_UNAVAILABLE
		),
		"Unavailable alternate precedes durability and shield checks",
	)
	var alternate_row: EnemyProfileCatalogOracle.ProfileRow = _row(
		&"enemy.profile.f06.base"
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(
				&"enemy.instance.alternate-over",
				alternate_row.profile_id,
				alternate_row.alternate_maximum_durability + 1,
				EnemyInstanceStateScript.StateKind.ALTERNATE,
				false,
			),
			registry,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.CURRENT_DURABILITY_OUT_OF_RANGE
		),
		"A declared alternate state must enforce its selected durability bound",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.negative", &"enemy.profile.f01.base", -1, 1, false),
			registry,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.CURRENT_DURABILITY_OUT_OF_RANGE
		),
		"Negative durability",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.over", &"enemy.profile.f01.base", 13, 1, true),
			registry,
		),
		(
			EnemyInstanceResolutionResultScript
			.FailureReason
			.CURRENT_DURABILITY_OUT_OF_RANGE
		),
		"Durability bounds precede shield legality",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.fake-shield", &"enemy.profile.f01.base", 12, 1, true),
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.SHIELD_STATE_INVALID,
		"Non-shield profile cannot forge a shield",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.create_initial(&"", &"enemy.profile.f01.base", registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Initial creation rejects empty instance ID",
	)
	_expect_failure(
		context,
		EnemyInstanceResolverScript.create_initial(&"enemy.instance.unknown", &"enemy.profile.unknown", registry),
		EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID,
		"Initial creation rejects unknown profile",
	)

	var tampered_registry: ContentRegistryScript = _fresh_registry(context)
	tampered_registry._enemy_profiles_by_id[&"enemy.profile.f01.base"].attack = 999
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(base_state, tampered_registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Internally tampered registry",
	)

	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.success(
			EnemyInstanceStateScript.new(),
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"Malformed public success result",
	)
	var caller_profile = registry.lookup_enemy_profile(
		&"enemy.profile.f01.base"
	).profile()
	caller_profile.attack = 999
	caller_profile.behavior_id = &"enemy.behavior.forged"
	var central_snapshot: EnemyInstanceSnapshotScript = (
		EnemyInstanceSnapshotScript.from_registry(base_state, registry)
	)
	context.expect_true(
		central_snapshot.is_valid(),
		"The public snapshot factory must resolve through the sealed Registry.",
	)
	context.expect_equal(
		central_snapshot.attack(),
		_row(&"enemy.profile.f01.base").attack,
		"Mutating a query copy cannot forge snapshot combat truth.",
	)
	context.expect_equal(
		central_snapshot.behavior_id(),
		&"enemy.behavior.patrol",
		"Mutating a query copy cannot forge snapshot behavior truth.",
	)
	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.success(central_snapshot, registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"The public success factory accepts instance state, never a snapshot",
	)
	central_snapshot._attack = 999
	central_snapshot._behavior_id = &"enemy.behavior.forged"
	var rebuilt_result: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolutionResultScript.success(
			central_snapshot.instance_state(),
			registry,
		)
	)
	_expect_success(
		context,
		rebuilt_result,
		"Public success rebuilds central profile truth",
	)
	context.expect_equal(
		rebuilt_result.snapshot().attack(),
		_row(&"enemy.profile.f01.base").attack,
		"Public success accepts state rather than caller-owned static projection data.",
	)
	var inconsistent_alternate_state: EnemyInstanceStateScript = _state(
		&"enemy.instance.inconsistent-snapshot",
		&"enemy.profile.f01.base",
		12,
		EnemyInstanceStateScript.StateKind.ALTERNATE,
		false,
	)
	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.success(
			inconsistent_alternate_state,
			registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"Public result with inconsistent alternate-state metadata",
	)
	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.failure(-1),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"Unknown public failure reason",
	)


func _rejects_derived_inputs_without_reads(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var derived_state := StatefulEnemyInstance.new()
	var derived_registry := StatefulContentRegistryScript.new()
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(derived_state, derived_registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE,
		"Derived instance state",
	)
	context.expect_equal(
		derived_state.read_count(),
		0,
		"Derived instance state must be rejected before overridable reads.",
	)
	context.expect_equal(
		derived_registry.read_count(),
		0,
		"Earlier invalid state must prevent all derived registry reads.",
	)

	var exact_state: EnemyInstanceStateScript = _state(
		&"enemy.instance.exact",
		&"enemy.profile.f01.base",
		12,
		EnemyInstanceStateScript.StateKind.PRIMARY,
		false,
	)
	var second_derived_registry := StatefulContentRegistryScript.new()
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(exact_state, second_derived_registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Derived registry",
	)
	context.expect_equal(
		second_derived_registry.read_count(),
		0,
		"Derived registry must be rejected before overridable reads.",
	)
	var creation_registry := StatefulContentRegistryScript.new()
	_expect_failure(
		context,
		EnemyInstanceResolverScript.create_initial(
			&"enemy.instance.derived-registry",
			&"enemy.profile.f01.base",
			creation_registry,
		),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Initial creation with a derived registry",
	)
	context.expect_equal(
		creation_registry.read_count(),
		0,
		"Initial creation must reject a derived registry before reads.",
	)
	var snapshot_registry := StatefulContentRegistryScript.new()
	context.expect_true(
		not EnemyInstanceSnapshotScript.from_registry(
			exact_state,
			snapshot_registry,
		).is_valid(),
		"The public snapshot factory must reject a derived Registry.",
	)
	context.expect_equal(
		snapshot_registry.read_count(),
		0,
		"The snapshot factory must reject a derived Registry before reads.",
	)
	var result_registry := StatefulContentRegistryScript.new()
	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.success(exact_state, result_registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"The public success factory must reject a derived Registry",
	)
	context.expect_equal(
		result_registry.read_count(),
		0,
		"The success factory must reject a derived Registry before reads.",
	)

	var derived_snapshot_state := StatefulEnemyInstance.new()
	var rejected_snapshot: EnemyInstanceSnapshotScript = (
		EnemyInstanceSnapshotScript.from_registry(derived_snapshot_state, registry)
	)
	context.expect_true(
		not rejected_snapshot.is_valid(),
		"The public snapshot factory must reject a derived state.",
	)
	context.expect_equal(
		derived_snapshot_state.read_count(),
		0,
		"The snapshot factory must reject a derived state before reads.",
	)
	context.expect_true(
		not EnemyInstanceSnapshotScript.from_registry(
			RefCounted.new(),
			registry,
		).is_valid(),
		"The public snapshot factory must fail closed for a wrong state type.",
	)

	var derived_result_state := StatefulEnemyInstance.new()
	_expect_failure(
		context,
		EnemyInstanceResolutionResultScript.success(derived_result_state, registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"Derived state in a public result",
	)
	context.expect_equal(
		derived_result_state.read_count(),
		0,
		"Public results must reject derived states before overridable reads.",
	)


func _isolates_inputs_outputs_and_registry_truth(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_registry(context)
	var input_state: EnemyInstanceStateScript = _state(
		&"enemy.instance.isolation",
		&"enemy.profile.f12.enhanced",
		10,
		EnemyInstanceStateScript.StateKind.ALTERNATE,
		true,
	)
	var result: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(input_state, registry)
	)
	_expect_success(context, result, "Isolation fixture")
	if not result.succeeded():
		return
	input_state._instance_id = &"enemy.instance.input-tampered"
	input_state._current_durability = 0
	input_state._shield_intact = false
	context.expect_equal(
		result.instance_state().instance_id(),
		&"enemy.instance.isolation",
		"Resolution must snapshot its input state.",
	)
	context.expect_equal(
		result.instance_state().current_durability(),
		10,
		"Input durability mutation must not affect the result.",
	)
	context.expect_true(
		result.instance_state().shield_intact(),
		"Input shield mutation must not affect the result.",
	)

	var first_state: EnemyInstanceStateScript = result.instance_state()
	var second_state: EnemyInstanceStateScript = result.instance_state()
	context.expect_true(first_state != second_state, "State getters must return copies.")
	first_state._current_durability = 0
	context.expect_equal(
		result.instance_state().current_durability(),
		10,
		"Returned state mutation must not affect later getters.",
	)
	var first_snapshot: EnemyInstanceSnapshotScript = result.snapshot()
	var second_snapshot: EnemyInstanceSnapshotScript = result.snapshot()
	context.expect_true(
		first_snapshot != second_snapshot,
		"Snapshot getters must return defensive copies.",
	)
	first_snapshot._attack = 999
	context.expect_equal(
		result.snapshot().attack(),
		17,
		"Returned snapshot mutation must not affect the retained projection.",
	)
	var returned_traits: Array[StringName] = result.snapshot().combat_trait_ids()
	returned_traits.append(&"enemy.trait.caller-mutation")
	context.expect_equal(
		result.snapshot().combat_trait_ids(),
		[&"enemy.trait.phase_alternation", &"enemy.trait.shield"],
		"Trait getters must return defensive copies.",
	)
	var first_opponent: ContactCombatOpponentStateScript = (
		result.contact_combat_opponent_state()
	)
	var second_opponent: ContactCombatOpponentStateScript = (
		result.contact_combat_opponent_state()
	)
	context.expect_true(
		first_opponent != second_opponent,
		"Contact-combat bridge getters must create independent values.",
	)
	first_opponent._attack = 999
	context.expect_equal(
		result.contact_combat_opponent_state().attack(),
		17,
		"Returned combat-state mutation must not affect later bridge values.",
	)

	var returned_profile = registry.lookup_enemy_profile(
		&"enemy.profile.f12.enhanced"
	).profile()
	returned_profile.alternate_attack = 999
	returned_profile.combat_trait_ids.clear()
	var central_again: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(
			_state(
				&"enemy.instance.central-again",
				&"enemy.profile.f12.enhanced",
				10,
				EnemyInstanceStateScript.StateKind.ALTERNATE,
				true,
			),
			registry,
		)
	)
	_expect_success(context, central_again, "Registry query snapshot isolation")
	if central_again.succeeded():
		context.expect_equal(
			central_again.snapshot().attack(),
			17,
			"Caller-owned profile mutation must not alter central truth.",
		)

	registry._enemy_profiles_by_id[&"enemy.profile.f12.enhanced"].attack = 999
	_expect_failure(
		context,
		EnemyInstanceResolverScript.resolve(result.instance_state(), registry),
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		"Central registry tampering after instance creation",
	)

	var self_invalidating: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(
			_state(
				&"enemy.instance.self-invalidating",
				&"enemy.profile.f01.base",
				12,
				EnemyInstanceStateScript.StateKind.PRIMARY,
				false,
			),
			_fresh_registry(context),
		)
	)
	context.expect_true(self_invalidating.succeeded(), "Self-invalidating fixture.")
	self_invalidating._snapshot._attack = 999
	_expect_failure(
		context,
		self_invalidating,
		EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT,
		"Structurally valid static-data tampering of a public result",
	)


func _bridges_every_profile_to_h43_kernel(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var bridge_count: int = 0
	var rows: Array[EnemyProfileCatalogOracle.ProfileRow] = (
		EnemyProfileCatalogOracle.profile_rows()
	)
	for index: int in range(rows.size()):
		var row: EnemyProfileCatalogOracle.ProfileRow = rows[index]
		_bridge_projection(
			context,
			registry,
			row,
			false,
			_instance_id(index, "bridge-primary"),
			row.primary_expectation,
		)
		bridge_count += 1
		if row.has_alternate_state:
			_bridge_projection(
				context,
				registry,
				row,
				true,
				_instance_id(index, "bridge-alternate"),
				row.alternate_expectation,
			)
			bridge_count += 1
	context.expect_equal(
		bridge_count,
		EXPECTED_TOTAL_PROJECTION_COUNT,
		"All 28 literal projections must pass through the real H4.5 bridge.",
	)

	var direct_instance_result: ContactCombatResultScript = (
		ContactCombatKernelScript.evaluate(
			_initial_player_state(),
			_state(
				&"enemy.instance.not-an-opponent-state",
				&"enemy.profile.f01.base",
				12,
				EnemyInstanceStateScript.StateKind.PRIMARY,
				false,
			),
			ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
			registry,
		)
	)
	context.expect_equal(
		direct_instance_result.rejection_reason(),
		ContactCombatResultScript.RejectionReason.INVALID_OPPONENT_STATE,
		"The explicit H4.5 bridge must remain the only H4.3 entry for instances.",
	)


func _replays_deterministically(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var first_create: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.create_initial(
			&"enemy.instance.replay-create",
			&"enemy.profile.f12.enhanced",
			registry,
		)
	)
	var second_create: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.create_initial(
			&"enemy.instance.replay-create",
			&"enemy.profile.f12.enhanced",
			registry,
		)
	)
	context.expect_equal(
		_encode_result(first_create),
		_encode_result(second_create),
		"Repeated initial creation must have identical public values.",
	)
	context.expect_true(
		first_create != second_create,
		"Repeated initial creation must not alias result objects.",
	)
	context.expect_true(
		first_create.snapshot() != second_create.snapshot(),
		"Repeated initial creation must not alias snapshots.",
	)

	var restored_state: EnemyInstanceStateScript = _state(
		&"enemy.instance.replay-restore",
		&"enemy.profile.f12.enhanced",
		7,
		EnemyInstanceStateScript.StateKind.ALTERNATE,
		false,
	)
	var first_restore: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(restored_state, registry)
	)
	var second_restore: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(restored_state, registry)
	)
	context.expect_equal(
		_encode_result(first_restore),
		_encode_result(second_restore),
		"Repeated restoration must have identical public values.",
	)
	context.expect_true(
		first_restore.contact_combat_opponent_state()
		!= second_restore.contact_combat_opponent_state(),
		"Repeated restoration must not alias combat bridge values.",
	)

	var first_failure: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.replay-fail", &"enemy.profile.f01.base", 13, 1, true),
			registry,
		)
	)
	var second_failure: EnemyInstanceResolutionResultScript = (
		EnemyInstanceResolverScript.resolve(
			_state(&"enemy.instance.replay-fail", &"enemy.profile.f01.base", 13, 1, true),
			registry,
		)
	)
	context.expect_equal(
		_encode_result(first_failure),
		_encode_result(second_failure),
		"Repeated rejection must preserve stable failure priority.",
	)


func _bridge_projection(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	row: EnemyProfileCatalogOracle.ProfileRow,
	use_alternate: bool,
	instance_id: StringName,
	expectation: EnemyProfileCatalogOracle.CombatExpectation,
) -> void:
	var maximum_durability: int = (
		row.alternate_maximum_durability if use_alternate else row.maximum_durability
	)
	var state_kind: int = (
		EnemyInstanceStateScript.StateKind.ALTERNATE
		if use_alternate
		else EnemyInstanceStateScript.StateKind.PRIMARY
	)
	var resolved: EnemyInstanceResolutionResultScript = EnemyInstanceResolverScript.resolve(
		_state(
			instance_id,
			row.profile_id,
			maximum_durability,
			state_kind,
			expectation.shield_intact,
		),
		registry,
	)
	_expect_success(context, resolved, "%s H4.5 bridge" % instance_id)
	if not resolved.succeeded():
		return
	var route_query = registry.lookup_representative_route_contract(
		row.balance_contract_id
	)
	context.expect_true(route_query.succeeded(), "%s route contract." % instance_id)
	if not route_query.succeeded():
		return
	var player_stats = route_query.stage_end_minimum_player_stats()
	context.expect_equal(
		[
			player_stats.maximum_health,
			player_stats.attack,
			player_stats.defense,
			player_stats.speed,
		],
		expectation.player_stats,
		"H4.5 bridge must use the literal route-end player fixture.",
	)
	var player_state: PlayerProgressionStateScript = _player_state_for_route(
		registry,
		route_query.contract(),
		player_stats,
	)
	context.expect_true(player_state != null, "%s player state." % instance_id)
	if player_state == null:
		return
	var combat_result: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		resolved.contact_combat_opponent_state(),
		ContactCombatCommandScript.evaluate(
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.TemporaryEffect.NONE,
			expectation.supporting_opponents_alive,
		),
		registry,
	)
	context.expect_true(
		combat_result.is_resolution_candidate(),
		"%s must produce an H4.3 candidate." % instance_id,
	)
	if not combat_result.is_resolution_candidate():
		return
	var resolution: ContactCombatResolutionScript = combat_result.resolution()
	context.expect_equal(
		resolution.opponent_instance_id(),
		instance_id,
		"Resolution must preserve stable instance identity.",
	)
	context.expect_equal(
		combat_result.previous_opponent_state().opponent_instance_id(),
		instance_id,
		"Previous opponent state must preserve stable instance identity.",
	)
	context.expect_equal(
		combat_result.opponent_state().opponent_instance_id(),
		instance_id,
		"Next opponent state must preserve stable instance identity.",
	)
	context.expect_equal(
		combat_result.domain_events()[0].resolution().opponent_instance_id(),
		instance_id,
		"Candidate event must preserve stable instance identity.",
	)
	context.expect_equal(
		resolution.first_attacker_side() == ContactCombatCommandScript.Side.PLAYER,
		expectation.player_first_attacker,
		"Literal first-attacker expectation.",
	)
	context.expect_equal(
		resolution.player_damage_per_attack(),
		expectation.player_damage_per_attack,
		"Literal player-damage expectation.",
	)
	context.expect_equal(
		resolution.opponent_damage_per_attack(),
		expectation.opponent_damage_per_attack,
		"Literal opponent-damage expectation.",
	)
	context.expect_equal(
		resolution.player_attacks_required_to_clear(),
		expectation.player_attacks_with_traits,
		"Literal shield-aware attack-count expectation.",
	)
	context.expect_equal(
		resolution.player_attacks_executed(),
		expectation.player_attacks_with_traits,
		"Literal executed-player-attacks expectation.",
	)
	context.expect_equal(
		resolution.opponent_attacks_executed(),
		expectation.opponent_attacks_executed,
		"Literal opponent-attacks expectation.",
	)
	context.expect_equal(
		resolution.player_health_loss(),
		expectation.player_health_loss,
		"Literal player-health-loss expectation.",
	)
	context.expect_equal(
		resolution.outcome(),
		ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
		"Every frozen route-end projection must remain clearable.",
	)


func _assert_projection(
	context: HeadlessTestContextScript,
	result: EnemyInstanceResolutionResultScript,
	row: EnemyProfileCatalogOracle.ProfileRow,
	use_alternate: bool,
) -> void:
	var snapshot: EnemyInstanceSnapshotScript = result.snapshot()
	context.expect_true(snapshot != null and snapshot.is_valid(), "Valid projection snapshot.")
	if snapshot == null or not snapshot.is_valid():
		return
	context.expect_equal(snapshot.profile_id(), row.profile_id, "Projected profile ID.")
	context.expect_equal(
		snapshot.state_kind(),
		(
			EnemyInstanceStateScript.StateKind.ALTERNATE
			if use_alternate
			else EnemyInstanceStateScript.StateKind.PRIMARY
		),
		"Projected selected state.",
	)
	context.expect_equal(
		snapshot.maximum_durability(),
		row.alternate_maximum_durability if use_alternate else row.maximum_durability,
		"Projected selected maximum durability.",
	)
	context.expect_equal(
		snapshot.attack(),
		row.alternate_attack if use_alternate else row.attack,
		"Projected selected attack.",
	)
	context.expect_equal(
		snapshot.defense(),
		row.alternate_defense if use_alternate else row.defense,
		"Projected selected defense.",
	)
	context.expect_equal(
		snapshot.speed(),
		row.alternate_speed if use_alternate else row.speed,
		"Projected selected speed.",
	)
	context.expect_equal(
		snapshot.has_alternate_state(),
		row.has_alternate_state,
		"Projected alternate-state capability.",
	)
	context.expect_equal(snapshot.behavior_id(), row.behavior_id, "Projected behavior ID.")
	context.expect_equal(
		snapshot.combat_trait_ids(),
		row.combat_trait_ids,
		"Projected defensive combat-trait snapshot.",
	)
	context.expect_equal(
		snapshot.visual_binding_id(),
		row.visual_binding_id,
		"Projected visual binding ID.",
	)
	var opponent: ContactCombatOpponentStateScript = (
		result.contact_combat_opponent_state()
	)
	context.expect_true(
		opponent != null and opponent.get_script() == ContactCombatOpponentStateScript,
		"Projection must create the exact H4.3 opponent script.",
	)
	if opponent != null:
		context.expect_equal(
			opponent.opponent_instance_id(),
			snapshot.instance_id(),
			"Combat bridge must preserve instance ID.",
		)
		context.expect_equal(
			opponent.maximum_durability(),
			snapshot.maximum_durability(),
			"Combat bridge maximum durability.",
		)
		context.expect_equal(
			opponent.current_durability(),
			snapshot.current_durability(),
			"Combat bridge current durability.",
		)
		context.expect_equal(opponent.attack(), snapshot.attack(), "Combat bridge attack.")
		context.expect_equal(opponent.defense(), snapshot.defense(), "Combat bridge defense.")
		context.expect_equal(opponent.speed(), snapshot.speed(), "Combat bridge speed.")
		context.expect_equal(
			opponent.shield_intact(),
			snapshot.shield_intact(),
			"Combat bridge shield state.",
		)


func _expect_success(
	context: HeadlessTestContextScript,
	result: EnemyInstanceResolutionResultScript,
	label: String,
) -> void:
	context.expect_true(result != null, "%s must return a result." % label)
	if result == null:
		return
	context.expect_true(result.succeeded(), "%s must succeed." % label)
	context.expect_equal(
		result.failure_reason(),
		EnemyInstanceResolutionResultScript.FailureReason.NONE,
		"%s success reason." % label,
	)
	context.expect_true(result.snapshot() != null, "%s must expose a snapshot." % label)
	context.expect_true(
		result.instance_state() != null,
		"%s must expose an instance state." % label,
	)
	context.expect_true(
		result.contact_combat_opponent_state() != null,
		"%s must expose an H4.3 bridge state." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s must remain outside the commit boundary." % label,
	)


func _expect_failure(
	context: HeadlessTestContextScript,
	result: EnemyInstanceResolutionResultScript,
	expected_reason: int,
	label: String,
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
	context.expect_true(result.snapshot() == null, "%s must expose no snapshot." % label)
	context.expect_true(
		result.instance_state() == null,
		"%s must expose no partial instance state." % label,
	)
	context.expect_true(
		result.contact_combat_opponent_state() == null,
		"%s must expose no partial H4.3 state." % label,
	)
	context.expect_true(
		not result.is_commit_boundary(),
		"%s must remain outside the commit boundary." % label,
	)


func _state(
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


func _instance_id(index: int, suffix: String) -> StringName:
	return StringName("enemy.instance.h45.%02d.%s" % [index + 1, suffix])


func _row(profile_id: StringName) -> EnemyProfileCatalogOracle.ProfileRow:
	for row: EnemyProfileCatalogOracle.ProfileRow in EnemyProfileCatalogOracle.profile_rows():
		if row.profile_id == profile_id:
			return row
	return null


func _initial_player_state() -> PlayerProgressionStateScript:
	return PlayerProgressionStateScript.create(
		&"progression.player.loer",
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		100,
		[],
	)


func _player_state_for_route(
	registry: ContentRegistryScript,
	contract,
	player_stats,
) -> PlayerProgressionStateScript:
	if contract == null or player_stats == null:
		return null
	var reward_ids: Array[StringName] = []
	for progression_id: StringName in contract.mainline_progression_reference_ids:
		var progression_query = registry.lookup_mainline_progression(progression_id)
		if not progression_query.succeeded():
			return null
		var progression = progression_query.mainline_progression()
		if progression == null:
			return null
		for reward_id: StringName in progression.reward_ids:
			reward_ids.append(reward_id)
	return PlayerProgressionStateScript.create(
		player_stats.profile_id,
		registry.schema_version(),
		registry.content_version(),
		player_stats.maximum_health,
		reward_ids,
	)


func _encode_result(result: EnemyInstanceResolutionResultScript) -> Array:
	if result == null:
		return [false, EnemyInstanceResolutionResultScript.FailureReason.INVALID_RESULT]
	if not result.succeeded():
		return [false, result.failure_reason()]
	var snapshot: EnemyInstanceSnapshotScript = result.snapshot()
	var opponent: ContactCombatOpponentStateScript = (
		result.contact_combat_opponent_state()
	)
	return [
		true,
		result.failure_reason(),
		snapshot.instance_id(),
		snapshot.profile_id(),
		snapshot.content_schema_version(),
		snapshot.content_version(),
		snapshot.current_durability(),
		snapshot.state_kind(),
		snapshot.shield_intact(),
		snapshot.maximum_durability(),
		snapshot.attack(),
		snapshot.defense(),
		snapshot.speed(),
		snapshot.has_alternate_state(),
		snapshot.behavior_id(),
		snapshot.combat_trait_ids(),
		snapshot.visual_binding_id(),
		opponent.opponent_instance_id(),
		opponent.maximum_durability(),
		opponent.current_durability(),
		opponent.attack(),
		opponent.defense(),
		opponent.speed(),
		opponent.shield_intact(),
	]


func _canonical_registry(context: HeadlessTestContextScript) -> ContentRegistryScript:
	if _cached_registry != null:
		return _cached_registry
	_cached_registry = _fresh_registry(context)
	return _cached_registry


func _fresh_registry(context: HeadlessTestContextScript) -> ContentRegistryScript:
	var build_result = ContentRegistryBuilderScript.build_canonical()
	context.expect_true(
		build_result.succeeded(),
		"Enemy runtime tests need the canonical sealed Registry.",
	)
	var registry: ContentRegistryScript = build_result.registry()
	context.expect_true(
		registry != null and registry.is_initialized(),
		"Enemy runtime test Registry must be initialized.",
	)
	return registry
