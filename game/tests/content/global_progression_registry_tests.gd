extends RefCounted

const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const MainlineProgressionDefinitionScript := preload(
	"res://src/content/definitions/mainline_progression_definition_resource.gd"
)
const OptionalProgressionDefinitionScript := preload(
	"res://src/content/definitions/optional_progression_definition_resource.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const ContentManifestScript := preload(
	"res://src/content/definitions/content_manifest_resource.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContentRegistryBuildResultScript := preload(
	"res://src/content/content_registry_build_result.gd"
)
const GlobalProgressionQueryResultScript := preload(
	"res://src/content/global_progression_query_result.gd"
)
const ContentContractFingerprintScript := preload(
	"res://src/content/content_contract_fingerprint.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const GlobalProgressionCatalogOracle := preload(
	"res://tests/content/global_progression_catalog_oracle.gd"
)
const DerivedGlobalProgressionCatalogScript := preload(
	"res://tests/content/support/derived_global_progression_catalog_resource.gd"
)
const DerivedPlayerStatProfileScript := preload(
	"res://tests/content/support/derived_player_stat_profile_resource.gd"
)
const DerivedMainlineProgressionDefinitionScript := preload(
	"res://tests/content/support/derived_mainline_progression_definition_resource.gd"
)
const DerivedOptionalProgressionDefinitionScript := preload(
	"res://tests/content/support/derived_optional_progression_definition_resource.gd"
)
const DerivedPermanentGrowthRewardDefinitionScript := preload(
	"res://tests/content/support/derived_permanent_growth_reward_definition_resource.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"global_progression.builds_canonical_catalog",
			_builds_canonical_catalog,
		),
		HeadlessTestCaseScript.new(
			"global_progression.matches_independent_oracle",
			_matches_independent_oracle,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_baseline_field_regressions",
			_rejects_baseline_field_regressions,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_baseline_resource_regressions",
			_rejects_baseline_resource_regressions,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_malformed_rewards_atomically",
			_rejects_malformed_rewards_atomically,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_reward_membership_violations",
			_rejects_reward_membership_violations,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_same_total_reward_swaps",
			_rejects_same_total_reward_swaps,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_null_wrong_and_derived_rewards",
			_rejects_null_wrong_and_derived_rewards,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_oversized_catalog_at_header",
			_rejects_oversized_catalog_at_header,
		),
		HeadlessTestCaseScript.new(
			"global_progression.orders_success_deterministically",
			_orders_success_deterministically,
		),
		HeadlessTestCaseScript.new(
			"global_progression.orders_errors_deterministically",
			_orders_errors_deterministically,
		),
		HeadlessTestCaseScript.new(
			"global_progression.reports_structured_reward_queries",
			_reports_structured_reward_queries,
		),
		HeadlessTestCaseScript.new(
			"global_progression.reports_baseline_structured_queries",
			_reports_baseline_structured_queries,
		),
		HeadlessTestCaseScript.new(
			"global_progression.isolates_input_and_returned_resources",
			_isolates_input_and_returned_resources,
		),
		HeadlessTestCaseScript.new(
			"global_progression.isolates_query_results",
			_isolates_query_results,
		),
		HeadlessTestCaseScript.new(
			"global_progression.isolates_resource_loader_cache",
			_isolates_resource_loader_cache,
		),
		HeadlessTestCaseScript.new(
			"global_progression.invalidates_tampered_registry_state",
			_invalidates_tampered_registry_state,
		),
		HeadlessTestCaseScript.new(
			"global_progression.invalidates_baseline_metadata_tampering",
			_invalidates_baseline_metadata_tampering,
		),
		HeadlessTestCaseScript.new(
			"global_progression.fingerprints_and_rebuilds_deterministically",
			_fingerprints_and_rebuilds_deterministically,
		),
	]


func _builds_canonical_catalog(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Canonical H-4.4 catalog",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	context.expect_true(registry.is_initialized(), "Canonical H-4.4 registry must initialize.")
	context.expect_equal(registry.schema_version(), 6, "Content schema version must be six.")
	context.expect_equal(registry.content_version(), 6, "Content version must be six.")
	context.expect_equal(
		registry.mainline_progression_ids().size(),
		9,
		"The registry must expose nine mainline groups.",
	)
	context.expect_equal(
		registry.optional_progression_ids().size(),
		4,
		"The registry must expose four optional groups.",
	)
	context.expect_equal(
		registry.permanent_growth_reward_count(),
		30,
		"The registry must expose thirty atomic permanent rewards.",
	)
	context.expect_equal(
		registry.mainline_progression_ids(),
		_expected_mainline_ids(),
		"Mainline group IDs must use frozen lexical order.",
	)
	context.expect_equal(
		registry.optional_progression_ids(),
		_expected_optional_ids(),
		"Optional group IDs must use frozen lexical order.",
	)
	context.expect_equal(
		registry.permanent_growth_reward_ids(),
		_expected_reward_ids(),
		"All thirty reward IDs must use frozen lexical order.",
	)
	var catalog: GlobalProgressionCatalogScript = registry.global_progression_catalog()
	context.expect_true(catalog != null, "The registry must expose a catalog snapshot.")
	if catalog == null:
		return
	context.expect_equal(catalog.catalog_id, &"progression.global", "Catalog ID must be frozen.")
	context.expect_equal(catalog.mainline_progression.size(), 9, "Catalog must retain 9 groups.")
	context.expect_equal(catalog.optional_progression.size(), 4, "Catalog must retain 4 groups.")
	context.expect_equal(
		catalog.permanent_growth_rewards.size(),
		30,
		"Catalog must retain 30 atomic rewards.",
	)
	context.expect_equal(
		[
			PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH,
			PermanentGrowthRewardDefinitionScript.StatKind.ATTACK,
			PermanentGrowthRewardDefinitionScript.StatKind.DEFENSE,
			PermanentGrowthRewardDefinitionScript.StatKind.SPEED,
		],
		[1, 2, 3, 4],
		"Permanent reward stat kinds must remain frozen at literal values 1 through 4.",
	)
	var old_delta_fields: Array[StringName] = [
		&"maximum_health_increase",
		&"attack_increase",
		&"defense_increase",
		&"speed_increase",
	]
	for field_name: StringName in old_delta_fields:
		context.expect_true(
			not _resource_has_property(catalog.mainline_progression[0], field_name),
			"Mainline groups must not retain legacy delta field '%s'."
			% String(field_name),
		)
		context.expect_true(
			not _resource_has_property(catalog.optional_progression[0], field_name),
			"Optional groups must not retain legacy delta field '%s'."
			% String(field_name),
		)
		context.expect_true(
			not _resource_has_property(catalog.permanent_growth_rewards[0], field_name),
			"Atomic rewards must not retain legacy delta field '%s'."
			% String(field_name),
		)
	var group_only_fields: Array[StringName] = [
		&"content_id",
		&"chapter",
		&"optional_map_id",
		&"available_after_chapter",
		&"reward_ids",
	]
	for field_name: StringName in group_only_fields:
		context.expect_true(
			not _resource_has_property(catalog.permanent_growth_rewards[0], field_name),
			"Atomic rewards must not expose group field '%s'." % String(field_name),
		)
	var bundle_ids: Array[StringName] = registry.mainline_progression_ids()
	bundle_ids.append_array(registry.optional_progression_ids())
	for reward_id: StringName in registry.permanent_growth_reward_ids():
		context.expect_true(
			not bundle_ids.has(reward_id),
			"Reward ID '%s' must not share the bundle namespace." % String(reward_id),
		)
	var initial_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	context.expect_true(initial_query.succeeded(), "Initial player stats must be queryable.")
	if initial_query.succeeded():
		context.expect_equal(
			_profile_values(initial_query.player_stats()),
			GlobalProgressionCatalogOracle.initial_stats().values(),
			"Initial player stats must remain 100/10/5/10.",
		)


func _matches_independent_oracle(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Independent H-4.4 oracle",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var reward_rows: Array[GlobalProgressionCatalogOracle.RewardRow] = (
		GlobalProgressionCatalogOracle.reward_rows()
	)
	var group_rows: Array[GlobalProgressionCatalogOracle.GroupRow] = (
		GlobalProgressionCatalogOracle.group_rows()
	)
	context.expect_equal(reward_rows.size(), 30, "Literal oracle must contain 30 rewards.")
	context.expect_equal(group_rows.size(), 13, "Literal oracle must contain 13 groups.")
	for row: GlobalProgressionCatalogOracle.RewardRow in reward_rows:
		var lookup: GlobalProgressionQueryResultScript = (
			registry.lookup_permanent_growth_reward(row.reward_id)
		)
		context.expect_true(
			lookup.succeeded(),
			"Oracle reward '%s' must be queryable." % String(row.reward_id),
		)
		if not lookup.succeeded():
			continue
		var reward: PermanentGrowthRewardDefinitionScript = (
			lookup.permanent_growth_reward()
		)
		context.expect_equal(reward.reward_id, row.reward_id, "Reward ID must match oracle.")
		context.expect_equal(reward.stat_kind, row.stat_kind, "Reward stat kind must match oracle.")
		context.expect_equal(reward.increase, row.increase, "Reward increase must match oracle.")

	var aggregate_values: Array[int] = GlobalProgressionCatalogOracle.initial_stats().values()
	var mainline_atomic_counts: Array[int] = [0, 0, 0, 0]
	var optional_atomic_counts: Array[int] = [0, 0, 0, 0]
	for row: GlobalProgressionCatalogOracle.GroupRow in group_rows:
		if row.group_kind == 1:
			var mainline_lookup: GlobalProgressionQueryResultScript = (
				registry.lookup_mainline_progression(row.content_id)
			)
			context.expect_true(
				mainline_lookup.succeeded(),
				"Mainline group '%s' must be queryable." % String(row.content_id),
			)
			if mainline_lookup.succeeded():
				var definition: MainlineProgressionDefinitionScript = (
					mainline_lookup.mainline_progression()
				)
				context.expect_equal(definition.chapter, row.chapter, "Chapter must match oracle.")
				context.expect_equal(
					definition.reward_ids,
					row.reward_ids,
					"Mainline reward membership must match oracle.",
				)
		else:
			var optional_lookup: GlobalProgressionQueryResultScript = (
				registry.lookup_optional_progression(row.content_id)
			)
			context.expect_true(
				optional_lookup.succeeded(),
				"Optional group '%s' must be queryable." % String(row.content_id),
			)
			if optional_lookup.succeeded():
				var definition: OptionalProgressionDefinitionScript = (
					optional_lookup.optional_progression()
				)
				context.expect_equal(
					definition.optional_map_id,
					row.optional_map_id,
					"Optional map ID must match oracle.",
				)
				context.expect_equal(
					definition.available_after_chapter,
					row.available_after_chapter,
					"Optional availability must match oracle.",
				)
				context.expect_equal(
					definition.reward_ids,
					row.reward_ids,
					"Optional reward membership must match oracle.",
				)
		for reward_id: StringName in row.reward_ids:
			var reward_query: GlobalProgressionQueryResultScript = (
				registry.lookup_permanent_growth_reward(reward_id)
			)
			if not reward_query.succeeded():
				continue
			var reward: PermanentGrowthRewardDefinitionScript = (
				reward_query.permanent_growth_reward()
			)
			aggregate_values[reward.stat_kind - 1] += reward.increase
			if row.group_kind == 1:
				mainline_atomic_counts[reward.stat_kind - 1] += 1
			else:
				optional_atomic_counts[reward.stat_kind - 1] += 1
		if row.group_kind == 1:
			context.expect_equal(
				aggregate_values,
				row.chapter_end_stats,
				"Chapter %d cumulative stats must match oracle." % row.chapter,
			)
			var chapter_query: GlobalProgressionQueryResultScript = (
				registry.mainline_stats_after_chapter(row.chapter)
			)
			context.expect_true(chapter_query.succeeded(), "Chapter stats must be queryable.")
			if chapter_query.succeeded():
				context.expect_equal(
					_profile_values(chapter_query.player_stats()),
					row.chapter_end_stats,
					"Registry chapter aggregate must match literal oracle.",
				)
	context.expect_equal(
		mainline_atomic_counts,
		[8, 6, 6, 4],
		"Mainline atomic counts must be 8/6/6/4 (24 total).",
	)
	context.expect_equal(
		optional_atomic_counts,
		[2, 2, 2, 0],
		"Optional atomic counts must be 2/2/2/0 (6 total).",
	)
	context.expect_equal(
		aggregate_values,
		GlobalProgressionCatalogOracle.full_completion_stats(),
		"All 30 atomic rewards must aggregate to 200/18/13/14.",
	)
	var completion_query: GlobalProgressionQueryResultScript = (
		registry.full_completion_player_stats()
	)
	context.expect_true(completion_query.succeeded(), "Full-completion stats must be queryable.")
	if completion_query.succeeded():
		context.expect_equal(
			_profile_values(completion_query.player_stats()),
			GlobalProgressionCatalogOracle.full_completion_stats(),
			"Registry full-completion aggregate must match literal oracle.",
		)


func _rejects_baseline_field_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Baseline H-4.4 field regressions",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var identity_manifest: ContentManifestScript = _manifest_from_registry(registry)
	identity_manifest.global_progression_catalog.catalog_id = &"progression.invalid"
	identity_manifest.global_progression_catalog.initial_stats.profile_id = (
		&"progression.player.invalid"
	)
	var identity_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(identity_manifest)
	)
	_expect_issue(
		context,
		identity_result,
		ContentValidationIssueScript.PROGRESSION_CATALOG_ID_INVALID,
		&"progression.invalid",
		"global_progression_catalog.catalog_id",
		"Invalid baseline catalog ID",
	)
	_expect_issue_tuple(
		context,
		identity_result,
		ContentValidationIssueScript.PROGRESSION_PROFILE_ID_INVALID,
		&"progression.player.invalid",
		"global_progression_catalog.initial_stats.profile_id",
		"Invalid baseline profile ID",
	)

	var profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var profile: PlayerStatProfileScript = profile_manifest.global_progression_catalog.initial_stats
	profile.maximum_health = 101
	profile.attack = 11
	profile.defense = 6
	profile.speed = 11
	var profile_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(profile_manifest)
	)
	for field_name: String in ["maximum_health", "attack", "defense", "speed"]:
		_expect_issue_tuple(
			context,
			profile_result,
			ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
			&"progression.player.loer",
			"global_progression_catalog.initial_stats.%s" % field_name,
			"Invalid baseline profile field '%s'" % field_name,
		)
	context.expect_true(not profile_result.succeeded(), "Invalid profile fields must fail.")
	context.expect_equal(profile_result.registry(), null, "Invalid profile fields must fail closed.")

	var mainline_identity_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var mainline_identity_catalog: GlobalProgressionCatalogScript = (
		mainline_identity_manifest.global_progression_catalog
	)
	_find_mainline(
		mainline_identity_catalog,
		&"progression.main.chapter.01",
	).content_id = &""
	_find_mainline(
		mainline_identity_catalog,
		&"progression.main.chapter.02",
	).content_id = &"progression.main.unknown"
	_find_mainline(
		mainline_identity_catalog,
		&"progression.main.chapter.03",
	).content_id = &"progression.main.chapter.04"
	var mainline_identity_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(mainline_identity_manifest)
	)
	_expect_issue(
		context,
		mainline_identity_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_EMPTY,
		&"",
		"mainline_progression.content_id",
		"Empty baseline mainline content ID",
	)
	_expect_issue_tuple(
		context,
		mainline_identity_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_INVALID,
		&"progression.main.unknown",
		"mainline_progression.content_id",
		"Invalid baseline mainline content ID",
	)
	_expect_issue_tuple(
		context,
		mainline_identity_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_DUPLICATE,
		&"progression.main.chapter.04",
		"mainline_progression.content_id",
		"Duplicate baseline mainline content ID",
	)

	var mainline_chapter_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var mainline_chapter_catalog: GlobalProgressionCatalogScript = (
		mainline_chapter_manifest.global_progression_catalog
	)
	_find_mainline(
		mainline_chapter_catalog,
		&"progression.main.chapter.01",
	).chapter = 0
	_find_mainline(
		mainline_chapter_catalog,
		&"progression.main.chapter.02",
	).chapter = 10
	_find_mainline(
		mainline_chapter_catalog,
		&"progression.main.chapter.03",
	).chapter = 4
	_find_mainline(
		mainline_chapter_catalog,
		&"progression.main.chapter.04",
	).chapter = 3
	_find_mainline(
		mainline_chapter_catalog,
		&"progression.main.chapter.05",
	).chapter = 6
	var mainline_chapter_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(mainline_chapter_manifest)
	)
	_expect_issue(
		context,
		mainline_chapter_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_INVALID,
		&"progression.main.chapter.01",
		"mainline_progression.chapter",
		"Mainline chapter zero",
	)
	_expect_issue_tuple(
		context,
		mainline_chapter_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_INVALID,
		&"progression.main.chapter.02",
		"mainline_progression.chapter",
		"Mainline chapter ten",
	)
	_expect_issue_tuple(
		context,
		mainline_chapter_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_DUPLICATE,
		&"6",
		"mainline_progression.chapter",
		"Duplicate baseline mainline chapter",
	)
	_expect_issue_tuple(
		context,
		mainline_chapter_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_MISMATCH,
		&"progression.main.chapter.03",
		"mainline_progression.chapter",
		"Valid-but-wrong mainline chapter",
	)

	var optional_identity_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var optional_identity_catalog: GlobalProgressionCatalogScript = (
		optional_identity_manifest.global_progression_catalog
	)
	_find_optional(
		optional_identity_catalog,
		&"progression.optional.m01",
	).content_id = &""
	_find_optional(
		optional_identity_catalog,
		&"progression.optional.m02",
	).content_id = &"progression.optional.unknown"
	_find_optional(
		optional_identity_catalog,
		&"progression.optional.m03",
	).content_id = &"progression.optional.m04"
	var optional_identity_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(optional_identity_manifest)
	)
	_expect_issue(
		context,
		optional_identity_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_EMPTY,
		&"",
		"optional_progression.content_id",
		"Empty baseline optional content ID",
	)
	_expect_issue_tuple(
		context,
		optional_identity_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_INVALID,
		&"progression.optional.unknown",
		"optional_progression.content_id",
		"Invalid baseline optional content ID",
	)
	_expect_issue_tuple(
		context,
		optional_identity_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_DUPLICATE,
		&"progression.optional.m04",
		"optional_progression.content_id",
		"Duplicate baseline optional content ID",
	)

	var optional_metadata_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var optional_metadata_catalog: GlobalProgressionCatalogScript = (
		optional_metadata_manifest.global_progression_catalog
	)
	var optional_one: OptionalProgressionDefinitionScript = _find_optional(
		optional_metadata_catalog,
		&"progression.optional.m01",
	)
	var optional_two: OptionalProgressionDefinitionScript = _find_optional(
		optional_metadata_catalog,
		&"progression.optional.m02",
	)
	var optional_three: OptionalProgressionDefinitionScript = _find_optional(
		optional_metadata_catalog,
		&"progression.optional.m03",
	)
	optional_one.optional_map_id = &"M99"
	optional_one.available_after_chapter = 0
	optional_two.optional_map_id = &"M03"
	optional_two.available_after_chapter = 10
	optional_three.available_after_chapter = 8
	var optional_metadata_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(optional_metadata_manifest)
	)
	_expect_issue(
		context,
		optional_metadata_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_INVALID,
		&"progression.optional.m01",
		"optional_progression.optional_map_id",
		"Invalid baseline optional map ID",
	)
	_expect_issue_tuple(
		context,
		optional_metadata_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_DUPLICATE,
		&"M03",
		"optional_progression.optional_map_id",
		"Duplicate baseline optional map ID",
	)
	_expect_issue_tuple(
		context,
		optional_metadata_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID,
		&"progression.optional.m01",
		"optional_progression.available_after_chapter",
		"Optional availability chapter zero",
	)
	_expect_issue_tuple(
		context,
		optional_metadata_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID,
		&"progression.optional.m02",
		"optional_progression.available_after_chapter",
		"Optional availability chapter ten",
	)
	_expect_issue_tuple(
		context,
		optional_metadata_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_MISMATCH,
		&"progression.optional.m03",
		"optional_progression.available_after_chapter",
		"Valid-but-wrong optional availability chapter",
	)

	var membership_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var membership_catalog: GlobalProgressionCatalogScript = (
		membership_manifest.global_progression_catalog
	)
	var mainline_one: MainlineProgressionDefinitionScript = _find_mainline(
		membership_catalog,
		&"progression.main.chapter.01",
	)
	mainline_one.reward_ids[0] = &""
	var optional_speed_reward := &"progression.reward.main.chapter.04.speed"
	_find_optional(
		membership_catalog,
		&"progression.optional.m01",
	).reward_ids.append(optional_speed_reward)
	var attack_reward_id := &"progression.reward.main.chapter.01.attack"
	_find_reward(membership_catalog, attack_reward_id).stat_kind = 3
	var membership_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(membership_manifest)
	)
	_expect_issue(
		context,
		membership_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_EMPTY,
		&"progression.main.chapter.01",
		"mainline_progression.reward_ids",
		"Empty group reward ID",
	)
	_expect_issue_tuple(
		context,
		membership_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_SPEED_FORBIDDEN,
		optional_speed_reward,
		"optional_progression.reward_ids",
		"Optional speed reward reference",
	)
	_expect_issue_tuple(
		context,
		membership_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_STAT_KIND_MISMATCH,
		attack_reward_id,
		"permanent_growth_rewards.stat_kind",
		"Valid-but-wrong reward stat kind",
	)


func _rejects_baseline_resource_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Baseline H-4.4 exact-resource regressions",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var null_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_catalog_manifest.global_progression_catalog = null
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(null_catalog_manifest),
		ContentValidationIssueScript.MANIFEST_PROGRESSION_CATALOG_NULL,
		&"",
		"global_progression_catalog",
		"Null progression catalog",
	)

	var wrong_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var wrong_catalog: Resource = wrong_catalog_manifest.global_progression_catalog as Resource
	wrong_catalog.set_script(DerivedGlobalProgressionCatalogScript)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(wrong_catalog_manifest),
		ContentValidationIssueScript.PROGRESSION_CATALOG_INVALID_SCRIPT,
		&"",
		"global_progression_catalog",
		"Wrong progression catalog script",
	)

	var derived_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_catalog: GlobalProgressionCatalogScript = (
		DerivedGlobalProgressionCatalogScript.new()
	)
	derived_catalog_manifest.global_progression_catalog = derived_catalog
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(derived_catalog_manifest),
		ContentValidationIssueScript.PROGRESSION_CATALOG_INVALID_SCRIPT,
		&"",
		"global_progression_catalog",
		"Derived progression catalog script",
	)

	var null_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_profile_manifest.global_progression_catalog.initial_stats = null
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(null_profile_manifest),
		ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_NULL,
		&"",
		"global_progression_catalog.initial_stats",
		"Null initial profile",
	)

	var wrong_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var wrong_profile: Resource = (
		wrong_profile_manifest.global_progression_catalog.initial_stats as Resource
	)
	wrong_profile.set_script(DerivedPlayerStatProfileScript)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(wrong_profile_manifest),
		ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.initial_stats",
		"Wrong initial profile script",
	)

	var derived_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_profile: PlayerStatProfileScript = DerivedPlayerStatProfileScript.new()
	derived_profile_manifest.global_progression_catalog.initial_stats = derived_profile
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(derived_profile_manifest),
		ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.initial_stats",
		"Derived initial profile script",
	)

	var null_group_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_group_manifest.global_progression_catalog.mainline_progression[0] = null
	null_group_manifest.global_progression_catalog.optional_progression[0] = null
	var null_group_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null_group_manifest)
	)
	_expect_issue(
		context,
		null_group_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_NULL,
		&"",
		"global_progression_catalog.mainline_progression[0]",
		"Null mainline group",
	)
	_expect_issue_tuple(
		context,
		null_group_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_NULL,
		&"",
		"global_progression_catalog.optional_progression[0]",
		"Null optional group",
	)

	var wrong_group_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var wrong_mainline: Resource = (
		wrong_group_manifest.global_progression_catalog.mainline_progression[0] as Resource
	)
	var wrong_optional: Resource = (
		wrong_group_manifest.global_progression_catalog.optional_progression[0] as Resource
	)
	wrong_mainline.set_script(DerivedMainlineProgressionDefinitionScript)
	wrong_optional.set_script(DerivedOptionalProgressionDefinitionScript)
	var wrong_group_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(wrong_group_manifest)
	)
	_expect_issue(
		context,
		wrong_group_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.mainline_progression[0]",
		"Wrong mainline group script",
	)
	_expect_issue_tuple(
		context,
		wrong_group_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.optional_progression[0]",
		"Wrong optional group script",
	)

	var derived_group_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_mainline: MainlineProgressionDefinitionScript = (
		DerivedMainlineProgressionDefinitionScript.new()
	)
	var derived_optional: OptionalProgressionDefinitionScript = (
		DerivedOptionalProgressionDefinitionScript.new()
	)
	derived_group_manifest.global_progression_catalog.mainline_progression[0] = (
		derived_mainline
	)
	derived_group_manifest.global_progression_catalog.optional_progression[0] = (
		derived_optional
	)
	var derived_group_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_group_manifest)
	)
	_expect_issue(
		context,
		derived_group_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.mainline_progression[0]",
		"Derived mainline group script",
	)
	_expect_issue_tuple(
		context,
		derived_group_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.optional_progression[0]",
		"Derived optional group script",
	)


func _rejects_malformed_rewards_atomically(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Malformed reward fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var first_id := &"progression.reward.main.chapter.01.attack"
	var second_id := &"progression.reward.main.chapter.01.maximum_health"

	var empty_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_reward(empty_manifest.global_progression_catalog, first_id).reward_id = &""
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(empty_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_ID_EMPTY,
		&"",
		"permanent_growth_rewards.reward_id",
		"Empty reward ID",
	)

	var invalid_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_reward(invalid_manifest.global_progression_catalog, first_id).reward_id = (
		&"progression.reward.invalid"
	)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(invalid_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_ID_INVALID,
		&"progression.reward.invalid",
		"permanent_growth_rewards.reward_id",
		"Invalid reward ID",
	)

	var duplicate_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_reward(duplicate_manifest.global_progression_catalog, first_id).reward_id = second_id
	var duplicate_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(duplicate_manifest)
	)
	_expect_issue(
		context,
		duplicate_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_ID_DUPLICATE,
		second_id,
		"permanent_growth_rewards.reward_id",
		"Duplicate reward ID",
	)
	_expect_issue_tuple(
		context,
		duplicate_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_ID_MISSING,
		first_id,
		"permanent_growth_rewards.reward_id",
		"Missing reward ID",
	)

	for invalid_kind: int in [0, 5]:
		var kind_manifest: ContentManifestScript = _manifest_from_registry(registry)
		_find_reward(kind_manifest.global_progression_catalog, first_id).stat_kind = invalid_kind
		_expect_issue(
			context,
			ContentRegistryBuilderScript.build(kind_manifest),
			ContentValidationIssueScript.PROGRESSION_REWARD_STAT_KIND_INVALID,
			first_id,
			"permanent_growth_rewards.stat_kind",
			"Reward stat kind %d" % invalid_kind,
		)

	for invalid_increase: int in [0, -1]:
		var increase_manifest: ContentManifestScript = _manifest_from_registry(registry)
		_find_reward(increase_manifest.global_progression_catalog, first_id).increase = (
			invalid_increase
		)
		_expect_issue(
			context,
			ContentRegistryBuilderScript.build(increase_manifest),
			ContentValidationIssueScript.PROGRESSION_REWARD_INCREASE_INVALID,
			first_id,
			"permanent_growth_rewards.increase",
			"Reward increase %d" % invalid_increase,
		)

	var wrong_positive_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_reward(wrong_positive_manifest.global_progression_catalog, second_id).increase = 20
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(wrong_positive_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_INCREASE_MISMATCH,
		second_id,
		"permanent_growth_rewards.increase",
		"Wrong positive reward increase",
	)


func _rejects_reward_membership_violations(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Reward membership fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var group_one_id := &"progression.main.chapter.01"
	var group_two_id := &"progression.main.chapter.02"
	var reward_one_id := &"progression.reward.main.chapter.01.attack"

	var missing_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_mainline(missing_manifest.global_progression_catalog, group_one_id).reward_ids.erase(
		reward_one_id
	)
	var missing_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(missing_manifest)
	)
	_expect_issue(
		context,
		missing_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		group_one_id,
		"mainline_progression.reward_ids",
		"Missing group member",
	)
	_expect_issue_tuple(
		context,
		missing_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_UNREFERENCED,
		reward_one_id,
		"progression.reward_ids",
		"Unreferenced reward after missing membership",
	)

	var unknown_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var unknown_group: MainlineProgressionDefinitionScript = _find_mainline(
		unknown_manifest.global_progression_catalog,
		group_one_id,
	)
	unknown_group.reward_ids[unknown_group.reward_ids.find(reward_one_id)] = (
		&"progression.reward.unknown"
	)
	var unknown_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(unknown_manifest)
	)
	_expect_issue(
		context,
		unknown_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_UNKNOWN,
		&"progression.reward.unknown",
		"mainline_progression.reward_ids",
		"Unknown group reward ID",
	)
	_expect_issue_tuple(
		context,
		unknown_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_UNREFERENCED,
		reward_one_id,
		"progression.reward_ids",
		"Unreferenced reward after unknown membership",
	)

	var duplicate_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_mainline(duplicate_manifest.global_progression_catalog, group_one_id).reward_ids.append(
		reward_one_id
	)
	var duplicate_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(duplicate_manifest)
	)
	_expect_issue(
		context,
		duplicate_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_DUPLICATE,
		reward_one_id,
		"mainline_progression.reward_ids",
		"In-group duplicate reward",
	)
	context.expect_true(
		not _issue_codes(duplicate_result).has(
			ContentValidationIssueScript.PROGRESSION_REWARD_REFERENCED_MULTIPLE
		),
		"An in-group duplicate must remain distinct from cross-group reuse.",
	)

	var cross_group_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_mainline(
		cross_group_manifest.global_progression_catalog,
		group_two_id,
	).reward_ids.append(reward_one_id)
	var cross_group_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(cross_group_manifest)
	)
	_expect_issue(
		context,
		cross_group_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		group_two_id,
		"mainline_progression.reward_ids",
		"Cross-group duplicate membership",
	)
	_expect_issue_tuple(
		context,
		cross_group_result,
		ContentValidationIssueScript.PROGRESSION_REWARD_REFERENCED_MULTIPLE,
		reward_one_id,
		"progression.reward_ids",
		"Cross-group multiply referenced reward",
	)

	var unreferenced_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var optional_reward_id := &"progression.reward.optional.m01.maximum_health"
	_find_optional(
		unreferenced_manifest.global_progression_catalog,
		&"progression.optional.m01",
	).reward_ids.clear()
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(unreferenced_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_UNREFERENCED,
		optional_reward_id,
		"progression.reward_ids",
		"Explicit unreferenced reward",
	)


func _rejects_same_total_reward_swaps(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Same-value cross-group swap fixture",
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	var first_group: MainlineProgressionDefinitionScript = _find_mainline(
		catalog,
		&"progression.main.chapter.01",
	)
	var second_group: MainlineProgressionDefinitionScript = _find_mainline(
		catalog,
		&"progression.main.chapter.02",
	)
	var first_reward := &"progression.reward.main.chapter.01.maximum_health"
	var second_reward := &"progression.reward.main.chapter.02.maximum_health"
	var original_trace: Array[int] = _aggregate_trace(catalog)
	_replace_reward_id(first_group.reward_ids, first_reward, second_reward)
	_replace_reward_id(second_group.reward_ids, second_reward, first_reward)
	context.expect_equal(
		_aggregate_trace(catalog),
		original_trace,
		"Swapping equal-valued rewards across groups must preserve every aggregate total.",
	)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	_expect_issue(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		&"progression.main.chapter.01",
		"mainline_progression.reward_ids",
		"First equal-valued cross-group swap",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		&"progression.main.chapter.02",
		"mainline_progression.reward_ids",
		"Second equal-valued cross-group swap",
	)


func _rejects_null_wrong_and_derived_rewards(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Exact reward script fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var null_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_manifest.global_progression_catalog.permanent_growth_rewards[0] = null
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(null_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_ENTRY_NULL,
		&"",
		"global_progression_catalog.permanent_growth_rewards[0]",
		"Null reward entry",
	)

	var wrong_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var wrong_reward: Resource = (
		wrong_manifest.global_progression_catalog.permanent_growth_rewards[0] as Resource
	)
	wrong_reward.set_script(null)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(wrong_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.permanent_growth_rewards[0]",
		"Wrong reward script",
	)

	var derived_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var original: PermanentGrowthRewardDefinitionScript = (
		derived_manifest.global_progression_catalog.permanent_growth_rewards[0]
	)
	var derived: PermanentGrowthRewardDefinitionScript = (
		DerivedPermanentGrowthRewardDefinitionScript.new()
	)
	derived.reward_id = original.reward_id
	derived.stat_kind = original.stat_kind
	derived.increase = original.increase
	derived_manifest.global_progression_catalog.permanent_growth_rewards[0] = derived
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(derived_manifest),
		ContentValidationIssueScript.PROGRESSION_REWARD_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.permanent_growth_rewards[0]",
		"Derived reward entry",
	)


func _rejects_oversized_catalog_at_header(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Oversized H-4.4 catalog",
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.global_progression_catalog.mainline_progression.resize(4096)
	manifest.global_progression_catalog.optional_progression.resize(4096)
	manifest.global_progression_catalog.permanent_growth_rewards.resize(4096)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "An oversized H-4.4 catalog must fail.")
	context.expect_equal(result.registry(), null, "Oversized content must fail closed.")
	context.expect_equal(
		_issue_codes(result),
		[
			ContentValidationIssueScript.PROGRESSION_MAINLINE_COUNT_INVALID,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_COUNT_INVALID,
			ContentValidationIssueScript.PROGRESSION_REWARD_COUNT_INVALID,
		],
		"4096-entry top-level arrays must stop at bounded count validation.",
	)

	var mainline_nested_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	_find_mainline(
		mainline_nested_manifest.global_progression_catalog,
		&"progression.main.chapter.04",
	).reward_ids.resize(4096)
	var mainline_nested_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(mainline_nested_manifest)
	)
	context.expect_true(
		not mainline_nested_result.succeeded(),
		"A 4096-entry mainline reward_ids array must fail validation.",
	)
	context.expect_equal(
		mainline_nested_result.registry(),
		null,
		"Oversized mainline membership must fail closed.",
	)
	context.expect_equal(
		mainline_nested_result.validation_report().issue_count(),
		5,
		"Oversized mainline membership must emit one bounded-membership issue plus "
		+ "four fixed unreferenced-reward issues, never 4096 diagnostics.",
	)
	_expect_issue_tuple(
		context,
		mainline_nested_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		&"progression.main.chapter.04",
		"mainline_progression.reward_ids",
		"Oversized nested mainline membership",
	)

	var optional_nested_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	_find_optional(
		optional_nested_manifest.global_progression_catalog,
		&"progression.optional.m04",
	).reward_ids.resize(4096)
	var optional_nested_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(optional_nested_manifest)
	)
	context.expect_true(
		not optional_nested_result.succeeded(),
		"A 4096-entry optional reward_ids array must fail validation.",
	)
	context.expect_equal(
		optional_nested_result.registry(),
		null,
		"Oversized optional membership must fail closed.",
	)
	context.expect_equal(
		optional_nested_result.validation_report().issue_count(),
		3,
		"Oversized optional membership must emit one bounded-membership issue plus "
		+ "two fixed unreferenced-reward issues, never 4096 diagnostics.",
	)
	_expect_issue_tuple(
		context,
		optional_nested_result,
		ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
		&"progression.optional.m04",
		"optional_progression.reward_ids",
		"Oversized nested optional membership",
	)


func _orders_success_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Successful declaration reordering",
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_reverse_all_declarations(manifest)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(
		result.succeeded(),
		"Top-level and per-group declaration order must be irrelevant. %s"
		% _diagnostics(result),
	)
	if not result.succeeded():
		return
	context.expect_equal(
		result.registry().mainline_progression_ids(),
		_expected_mainline_ids(),
		"Reordered mainline groups must normalize lexically.",
	)
	context.expect_equal(
		result.registry().optional_progression_ids(),
		_expected_optional_ids(),
		"Reordered optional groups must normalize lexically.",
	)
	context.expect_equal(
		result.registry().permanent_growth_reward_ids(),
		_expected_reward_ids(),
		"Reordered rewards must normalize lexically.",
	)
	context.expect_true(
		result.registry().global_progression_catalog().is_equal_to(
			canonical.registry().global_progression_catalog()
		),
		"Reordered top arrays and reward_ids must publish an identical snapshot.",
	)
	context.expect_true(
		result.registry().enemy_profile_catalog().is_equal_to(
			canonical.registry().enemy_profile_catalog()
		),
		"Reordered enemy families, profiles, and traits must publish an identical snapshot.",
	)
	var canonical_registry: ContentRegistryScript = canonical.registry()
	var reordered_registry: ContentRegistryScript = result.registry()
	var reward_id := &"progression.reward.main.chapter.04.speed"
	var canonical_reward: GlobalProgressionQueryResultScript = (
		canonical_registry.lookup_permanent_growth_reward(reward_id)
	)
	var reordered_reward: GlobalProgressionQueryResultScript = (
		reordered_registry.lookup_permanent_growth_reward(reward_id)
	)
	context.expect_true(
		canonical_reward.succeeded() and reordered_reward.succeeded(),
		"Known reward lookup must succeed before and after declaration reordering.",
	)
	if canonical_reward.succeeded() and reordered_reward.succeeded():
		context.expect_true(
			reordered_reward.permanent_growth_reward().is_equal_to(
				canonical_reward.permanent_growth_reward()
			),
			"Known reward lookup must be value-identical after reordering.",
		)
	var mainline_id := &"progression.main.chapter.04"
	var canonical_mainline: GlobalProgressionQueryResultScript = (
		canonical_registry.lookup_mainline_progression(mainline_id)
	)
	var reordered_mainline: GlobalProgressionQueryResultScript = (
		reordered_registry.lookup_mainline_progression(mainline_id)
	)
	context.expect_true(
		canonical_mainline.succeeded() and reordered_mainline.succeeded(),
		"Known mainline lookup must succeed before and after declaration reordering.",
	)
	if canonical_mainline.succeeded() and reordered_mainline.succeeded():
		context.expect_true(
			reordered_mainline.mainline_progression().is_equal_to(
				canonical_mainline.mainline_progression()
			),
			"Known mainline lookup must be value-identical after reordering.",
		)
	var optional_id := &"progression.optional.m04"
	var canonical_optional: GlobalProgressionQueryResultScript = (
		canonical_registry.lookup_optional_progression(optional_id)
	)
	var reordered_optional: GlobalProgressionQueryResultScript = (
		reordered_registry.lookup_optional_progression(optional_id)
	)
	context.expect_true(
		canonical_optional.succeeded() and reordered_optional.succeeded(),
		"Known optional lookup must succeed before and after declaration reordering.",
	)
	if canonical_optional.succeeded() and reordered_optional.succeeded():
		context.expect_true(
			reordered_optional.optional_progression().is_equal_to(
				canonical_optional.optional_progression()
			),
			"Known optional lookup must be value-identical after reordering.",
		)
	for chapter: int in range(1, 10):
		var canonical_chapter: GlobalProgressionQueryResultScript = (
			canonical_registry.mainline_stats_after_chapter(chapter)
		)
		var reordered_chapter: GlobalProgressionQueryResultScript = (
			reordered_registry.mainline_stats_after_chapter(chapter)
		)
		context.expect_true(
			canonical_chapter.succeeded() and reordered_chapter.succeeded(),
			"Chapter %d stats must remain queryable after reordering." % chapter,
		)
		if canonical_chapter.succeeded() and reordered_chapter.succeeded():
			context.expect_equal(
				_profile_values(reordered_chapter.player_stats()),
				_profile_values(canonical_chapter.player_stats()),
				"Chapter %d stats must be identical after reordering." % chapter,
			)
	var canonical_completion: GlobalProgressionQueryResultScript = (
		canonical_registry.full_completion_player_stats()
	)
	var reordered_completion: GlobalProgressionQueryResultScript = (
		reordered_registry.full_completion_player_stats()
	)
	context.expect_true(
		canonical_completion.succeeded() and reordered_completion.succeeded(),
		"Full-completion stats must remain queryable after reordering.",
	)
	if canonical_completion.succeeded() and reordered_completion.succeeded():
		context.expect_equal(
			_profile_values(reordered_completion.player_stats()),
			_profile_values(canonical_completion.player_stats()),
			"Full-completion stats must be identical after reordering.",
		)


func _orders_errors_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Invalid declaration reordering",
	)
	if not canonical.succeeded():
		return
	var forward: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var reverse: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_corrupt_for_ordering(forward.global_progression_catalog)
	_corrupt_for_ordering(reverse.global_progression_catalog)
	_reverse_all_declarations(reverse)
	var forward_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(
		forward
	)
	var reverse_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(
		reverse
	)
	context.expect_true(not forward_result.succeeded(), "Forward invalid catalog must fail.")
	context.expect_true(not reverse_result.succeeded(), "Reverse invalid catalog must fail.")
	context.expect_equal(
		forward_result.validation_report().signatures(),
		reverse_result.validation_report().signatures(),
		"Issue order must not depend on top-level or reward membership declaration order.",
	)


func _reports_structured_reward_queries(
	context: HeadlessTestContextScript,
) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Structured permanent reward queries",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var reward_id := &"progression.reward.main.chapter.01.attack"
	var known: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(reward_id)
	)
	context.expect_true(known.succeeded(), "Known permanent reward lookup must succeed.")
	context.expect_equal(
		known.kind(),
		GlobalProgressionQueryResultScript.Kind.PERMANENT_GROWTH_REWARD,
		"Known reward lookup must retain reward result kind.",
	)
	context.expect_equal(known.player_stats(), null, "Reward result must not expose stats.")
	context.expect_equal(known.mainline_progression(), null, "Reward result must not expose mainline.")
	context.expect_equal(known.optional_progression(), null, "Reward result must not expose optional.")
	context.expect_true(
		known.permanent_growth_reward() != null,
		"Known reward result must expose its reward payload.",
	)

	var unknown_id := &"progression.reward.unknown"
	var unknown: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(unknown_id)
	)
	context.expect_true(not unknown.succeeded(), "Unknown reward lookup must fail.")
	context.expect_equal(
		unknown.kind(),
		GlobalProgressionQueryResultScript.Kind.PERMANENT_GROWTH_REWARD,
		"Unknown reward lookup must retain reward result kind.",
	)
	_expect_failed_query_payloads_null(context, unknown, "Unknown reward lookup")
	context.expect_equal(
		unknown.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_PERMANENT_GROWTH_REWARD_ID,
		"Unknown reward lookup must expose a stable code.",
	)
	context.expect_equal(unknown.issue().content_id(), unknown_id, "Unknown ID must be retained.")
	context.expect_equal(unknown.issue().field_path(), "reward_id", "Reward field must be named.")

	var bundle_as_reward: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(&"progression.main.chapter.01")
	)
	context.expect_true(
		not bundle_as_reward.succeeded(),
		"A bundle ID must not resolve in the reward namespace.",
	)
	context.expect_equal(
		bundle_as_reward.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_PERMANENT_GROWTH_REWARD_ID,
		"Bundle-as-reward failure must retain reward lookup semantics.",
	)
	var reward_as_bundle: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(reward_id)
	)
	context.expect_true(
		not reward_as_bundle.succeeded(),
		"A reward ID must not resolve in the bundle namespace.",
	)
	context.expect_equal(
		reward_as_bundle.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_MAINLINE_PROGRESSION_ID,
		"Reward-as-bundle failure must retain bundle lookup semantics.",
	)
	_expect_failed_query_payloads_null(context, reward_as_bundle, "Reward-as-bundle lookup")

	var known_mainline: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
	)
	context.expect_equal(
		known_mainline.permanent_growth_reward(),
		null,
		"Successful bundle queries must not expose a reward payload.",
	)

	var raw_registry := ContentRegistryScript.new()
	_expect_uninitialized_progression_query(
		context,
		raw_registry.lookup_permanent_growth_reward(reward_id),
		GlobalProgressionQueryResultScript.Kind.PERMANENT_GROWTH_REWARD,
		reward_id,
		"Uninitialized permanent reward lookup",
	)


func _reports_baseline_structured_queries(
	context: HeadlessTestContextScript,
) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Baseline H-4.4 structured queries",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()

	var initial_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	context.expect_true(initial_query.succeeded(), "Initial stats query must succeed.")
	context.expect_equal(
		initial_query.kind(),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		"Initial stats query must retain its kind.",
	)
	context.expect_true(
		initial_query.player_stats() != null,
		"Initial stats query must expose player stats.",
	)
	context.expect_equal(
		initial_query.mainline_progression(),
		null,
		"A player-stats result must not expose mainline content.",
	)
	context.expect_equal(
		initial_query.optional_progression(),
		null,
		"A player-stats result must not expose optional content.",
	)
	context.expect_equal(
		initial_query.permanent_growth_reward(),
		null,
		"A player-stats result must not expose permanent rewards.",
	)
	context.expect_equal(initial_query.issue(), null, "A successful initial query has no issue.")

	var mainline_query: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
	)
	context.expect_true(mainline_query.succeeded(), "Known mainline lookup must succeed.")
	context.expect_equal(
		mainline_query.kind(),
		GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
		"Known mainline lookup must retain its kind.",
	)
	context.expect_true(
		mainline_query.mainline_progression() != null,
		"Known mainline lookup must expose mainline content.",
	)
	context.expect_equal(
		mainline_query.player_stats(),
		null,
		"A mainline result must not expose player stats.",
	)
	context.expect_equal(
		mainline_query.optional_progression(),
		null,
		"A mainline result must not expose optional content.",
	)
	context.expect_equal(
		mainline_query.permanent_growth_reward(),
		null,
		"A mainline result must not expose permanent rewards.",
	)
	context.expect_equal(mainline_query.issue(), null, "A successful mainline query has no issue.")

	var optional_query: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.m01")
	)
	context.expect_true(optional_query.succeeded(), "Known optional lookup must succeed.")
	context.expect_equal(
		optional_query.kind(),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		"Known optional lookup must retain its kind.",
	)
	context.expect_true(
		optional_query.optional_progression() != null,
		"Known optional lookup must expose optional content.",
	)
	context.expect_equal(
		optional_query.player_stats(),
		null,
		"An optional result must not expose player stats.",
	)
	context.expect_equal(
		optional_query.mainline_progression(),
		null,
		"An optional result must not expose mainline content.",
	)
	context.expect_equal(
		optional_query.permanent_growth_reward(),
		null,
		"An optional result must not expose permanent rewards.",
	)
	context.expect_equal(optional_query.issue(), null, "A successful optional query has no issue.")

	var unknown_mainline_id := &"progression.main.unknown"
	var unknown_mainline: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(unknown_mainline_id)
	)
	context.expect_true(not unknown_mainline.succeeded(), "Unknown mainline lookup must fail.")
	context.expect_equal(
		unknown_mainline.kind(),
		GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
		"Unknown mainline lookup must retain its kind.",
	)
	_expect_failed_query_payloads_null(context, unknown_mainline, "Unknown mainline lookup")
	context.expect_equal(
		unknown_mainline.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_MAINLINE_PROGRESSION_ID,
		"Unknown mainline lookup must expose the frozen code.",
	)
	context.expect_equal(
		unknown_mainline.issue().content_id(),
		unknown_mainline_id,
		"Unknown mainline lookup must retain its requested ID.",
	)
	context.expect_equal(
		unknown_mainline.issue().field_path(),
		"content_id",
		"Unknown mainline lookup must identify content_id.",
	)

	var unknown_optional_id := &"progression.optional.unknown"
	var unknown_optional: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(unknown_optional_id)
	)
	context.expect_true(not unknown_optional.succeeded(), "Unknown optional lookup must fail.")
	context.expect_equal(
		unknown_optional.kind(),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		"Unknown optional lookup must retain its kind.",
	)
	_expect_failed_query_payloads_null(context, unknown_optional, "Unknown optional lookup")
	context.expect_equal(
		unknown_optional.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_OPTIONAL_PROGRESSION_ID,
		"Unknown optional lookup must expose the frozen code.",
	)
	context.expect_equal(
		unknown_optional.issue().content_id(),
		unknown_optional_id,
		"Unknown optional lookup must retain its requested ID.",
	)
	context.expect_equal(
		unknown_optional.issue().field_path(),
		"content_id",
		"Unknown optional lookup must identify content_id.",
	)

	for invalid_chapter: int in [0, 10]:
		var invalid_chapter_query: GlobalProgressionQueryResultScript = (
			registry.mainline_stats_after_chapter(invalid_chapter)
		)
		context.expect_true(
			not invalid_chapter_query.succeeded(),
			"Out-of-range chapter %d query must fail." % invalid_chapter,
		)
		_expect_failed_query_payloads_null(
			context,
			invalid_chapter_query,
			"Out-of-range chapter %d query" % invalid_chapter,
		)
		context.expect_equal(
			invalid_chapter_query.kind(),
			GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
			"Invalid chapter query must retain player-stats kind.",
		)
		context.expect_equal(
			invalid_chapter_query.issue().code(),
			ContentValidationIssueScript.LOOKUP_PROGRESSION_CHAPTER_INVALID,
			"Invalid chapter query must expose the frozen code.",
		)
		context.expect_equal(
			invalid_chapter_query.issue().content_id(),
			StringName(str(invalid_chapter)),
			"Invalid chapter query must retain its requested chapter.",
		)
		context.expect_equal(
			invalid_chapter_query.issue().field_path(),
			"chapter",
			"Invalid chapter query must identify chapter.",
		)

	var raw_registry := ContentRegistryScript.new()
	_expect_uninitialized_progression_query(
		context,
		raw_registry.initial_player_stats(),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		&"progression.player.loer",
		"Uninitialized initial-stats query",
	)
	_expect_uninitialized_progression_query(
		context,
		raw_registry.full_completion_player_stats(),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		&"progression.player.loer",
		"Uninitialized full-completion query",
	)
	_expect_uninitialized_progression_query(
		context,
		raw_registry.mainline_stats_after_chapter(4),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		&"4",
		"Uninitialized chapter query",
	)
	_expect_uninitialized_progression_query(
		context,
		raw_registry.lookup_mainline_progression(&"progression.main.chapter.01"),
		GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
		&"progression.main.chapter.01",
		"Uninitialized mainline bundle query",
	)
	_expect_uninitialized_progression_query(
		context,
		raw_registry.lookup_optional_progression(&"progression.optional.m01"),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		&"progression.optional.m01",
		"Uninitialized optional bundle query",
	)


func _isolates_input_and_returned_resources(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"H-4.4 input isolation",
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var source_catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	var source_profile: PlayerStatProfileScript = source_catalog.initial_stats
	var reward_id := &"progression.reward.main.chapter.01.attack"
	var mainline_group_id := &"progression.main.chapter.01"
	var optional_group_id := &"progression.optional.m04"
	var source_reward: PermanentGrowthRewardDefinitionScript = _find_reward(
		source_catalog,
		reward_id,
	)
	var source_mainline: MainlineProgressionDefinitionScript = _find_mainline(
		source_catalog,
		mainline_group_id,
	)
	var source_optional: OptionalProgressionDefinitionScript = _find_optional(
		source_catalog,
		optional_group_id,
	)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(
		result.succeeded(),
		"Copied H-4.4 input must build before mutation. %s" % _diagnostics(result),
	)
	if not result.succeeded():
		return

	source_catalog.catalog_id = &"progression.tampered"
	source_profile.profile_id = &"progression.player.tampered"
	source_profile.attack = 999
	source_reward.increase = 999
	source_mainline.reward_ids.clear()
	source_optional.reward_ids.clear()
	source_catalog.permanent_growth_rewards.clear()
	source_catalog.mainline_progression.clear()
	source_catalog.optional_progression.clear()
	manifest.global_progression_catalog = null
	context.expect_true(result.succeeded(), "Mutating input Resources must not alter stored state.")
	var stored_catalog: GlobalProgressionCatalogScript = (
		result.registry().global_progression_catalog()
	)
	context.expect_equal(
		stored_catalog.catalog_id,
		&"progression.global",
		"Mutating the input catalog ID must not alter the registry.",
	)
	context.expect_equal(
		result.registry().initial_player_stats().player_stats().profile_id,
		&"progression.player.loer",
		"Mutating the input profile ID must not alter the registry.",
	)
	context.expect_equal(
		_profile_values(result.registry().initial_player_stats().player_stats()),
		[100, 10, 5, 10],
		"Mutating the input profile must not alter the registry.",
	)
	context.expect_equal(
		result.registry().lookup_permanent_growth_reward(reward_id).permanent_growth_reward().increase,
		1,
		"Mutating an input reward must not alter the registry.",
	)
	context.expect_equal(
		result.registry()
		.lookup_mainline_progression(mainline_group_id)
		.mainline_progression()
		.reward_ids,
		[
			&"progression.reward.main.chapter.01.attack",
			&"progression.reward.main.chapter.01.maximum_health",
		],
		"Mutating input mainline membership must not alter the registry.",
	)
	context.expect_equal(
		result.registry()
		.lookup_optional_progression(optional_group_id)
		.optional_progression()
		.reward_ids,
		[
			&"progression.reward.optional.m04.attack",
			&"progression.reward.optional.m04.defense",
		],
		"Mutating input optional membership must not alter the registry.",
	)
	context.expect_equal(
		result.registry().mainline_progression_ids(),
		_expected_mainline_ids(),
		"Clearing the input mainline array must not alter the registry index.",
	)
	context.expect_equal(
		result.registry().optional_progression_ids(),
		_expected_optional_ids(),
		"Clearing the input optional array must not alter the registry index.",
	)
	context.expect_equal(
		stored_catalog.permanent_growth_rewards.size(),
		30,
		"Clearing the input reward array must not shrink the stored catalog.",
	)
	context.expect_equal(
		stored_catalog.mainline_progression.size(),
		9,
		"Clearing the input mainline array must not shrink the stored catalog.",
	)
	context.expect_equal(
		stored_catalog.optional_progression.size(),
		4,
		"Clearing the input optional array must not shrink the stored catalog.",
	)

	var returned_catalog: GlobalProgressionCatalogScript = (
		result.registry().global_progression_catalog()
	)
	returned_catalog.catalog_id = &"progression.tampered"
	returned_catalog.initial_stats.attack = 777
	_find_reward(returned_catalog, reward_id).increase = 777
	_find_mainline(returned_catalog, mainline_group_id).reward_ids.clear()
	_find_optional(returned_catalog, optional_group_id).reward_ids.clear()
	returned_catalog.permanent_growth_rewards.clear()
	returned_catalog.mainline_progression.clear()
	returned_catalog.optional_progression.clear()
	var fresh_catalog: GlobalProgressionCatalogScript = (
		result.registry().global_progression_catalog()
	)
	context.expect_equal(
		fresh_catalog.catalog_id,
		&"progression.global",
		"Mutating a returned catalog ID must not alter stored state.",
	)
	context.expect_equal(
		_profile_values(fresh_catalog.initial_stats),
		[100, 10, 5, 10],
		"Mutating a returned catalog profile must not alter stored state.",
	)
	context.expect_equal(
		result.registry().lookup_permanent_growth_reward(reward_id).permanent_growth_reward().increase,
		1,
		"Mutating a returned catalog reward must not alter stored state.",
	)
	context.expect_equal(
		result.registry()
		.lookup_mainline_progression(mainline_group_id)
		.mainline_progression()
		.reward_ids,
		[
			&"progression.reward.main.chapter.01.attack",
			&"progression.reward.main.chapter.01.maximum_health",
		],
		"Mutating returned mainline membership must not alter stored state.",
	)
	context.expect_equal(
		result.registry()
		.lookup_optional_progression(optional_group_id)
		.optional_progression()
		.reward_ids,
		[
			&"progression.reward.optional.m04.attack",
			&"progression.reward.optional.m04.defense",
		],
		"Mutating returned optional membership must not alter stored state.",
	)
	context.expect_equal(
		fresh_catalog.permanent_growth_rewards.size(),
		30,
		"Clearing a returned reward array must not alter stored state.",
	)
	context.expect_equal(
		fresh_catalog.mainline_progression.size(),
		9,
		"Clearing a returned mainline array must not alter stored state.",
	)
	context.expect_equal(
		fresh_catalog.optional_progression.size(),
		4,
		"Clearing a returned optional array must not alter stored state.",
	)

	var expected_reward_ids: Array[StringName] = _expected_reward_ids()
	var returned_reward_ids: Array[StringName] = result.registry().permanent_growth_reward_ids()
	returned_reward_ids[0] = &"progression.reward.tampered"
	returned_reward_ids.clear()
	context.expect_equal(
		result.registry().permanent_growth_reward_ids(),
		expected_reward_ids,
		"Mutating a returned reward ID array must not alter the registry index.",
	)
	var expected_mainline_ids: Array[StringName] = _expected_mainline_ids()
	var returned_mainline_ids: Array[StringName] = result.registry().mainline_progression_ids()
	returned_mainline_ids[0] = &"progression.main.tampered"
	returned_mainline_ids.clear()
	context.expect_equal(
		result.registry().mainline_progression_ids(),
		expected_mainline_ids,
		"Mutating a returned mainline ID array must not alter the registry index.",
	)
	var expected_optional_ids: Array[StringName] = _expected_optional_ids()
	var returned_optional_ids: Array[StringName] = result.registry().optional_progression_ids()
	returned_optional_ids[0] = &"progression.optional.tampered"
	returned_optional_ids.clear()
	context.expect_equal(
		result.registry().optional_progression_ids(),
		expected_optional_ids,
		"Mutating a returned optional ID array must not alter the registry index.",
	)

	var returned_rewards: Array[PermanentGrowthRewardDefinitionScript] = (
		result.registry().permanent_growth_reward_definitions()
	)
	var returned_reward_definition: PermanentGrowthRewardDefinitionScript
	for returned_reward: PermanentGrowthRewardDefinitionScript in returned_rewards:
		if returned_reward.reward_id == reward_id:
			returned_reward_definition = returned_reward
			break
	context.expect_true(
		returned_reward_definition != null,
		"Returned reward definitions must contain the mutation target.",
	)
	if returned_reward_definition != null:
		returned_reward_definition.increase = 555
	returned_rewards.clear()
	context.expect_equal(
		result.registry().permanent_growth_reward_count(),
		30,
		"Mutating a reward collection result must not alter stored state.",
	)
	context.expect_equal(
		result.registry().lookup_permanent_growth_reward(reward_id).permanent_growth_reward().increase,
		1,
		"Nested returned reward definitions must be deep snapshots.",
	)
	var returned_mainline_definitions: Array[MainlineProgressionDefinitionScript] = (
		result.registry().mainline_progression_definitions()
	)
	var returned_mainline_definition: MainlineProgressionDefinitionScript
	for returned_mainline: MainlineProgressionDefinitionScript in returned_mainline_definitions:
		if returned_mainline.content_id == mainline_group_id:
			returned_mainline_definition = returned_mainline
			break
	context.expect_true(
		returned_mainline_definition != null,
		"Returned mainline definitions must contain the mutation target.",
	)
	if returned_mainline_definition != null:
		returned_mainline_definition.content_id = &"progression.main.tampered"
		returned_mainline_definition.reward_ids.clear()
	returned_mainline_definitions.clear()
	context.expect_equal(
		result.registry().mainline_progression_definitions().size(),
		9,
		"Mutating a returned mainline definition array must not alter stored state.",
	)
	context.expect_equal(
		result.registry()
		.lookup_mainline_progression(mainline_group_id)
		.mainline_progression()
		.reward_ids.size(),
		2,
		"Nested returned mainline definitions must be deep snapshots.",
	)
	var returned_optional_definitions: Array[OptionalProgressionDefinitionScript] = (
		result.registry().optional_progression_definitions()
	)
	var returned_optional_definition: OptionalProgressionDefinitionScript
	for returned_optional: OptionalProgressionDefinitionScript in returned_optional_definitions:
		if returned_optional.content_id == optional_group_id:
			returned_optional_definition = returned_optional
			break
	context.expect_true(
		returned_optional_definition != null,
		"Returned optional definitions must contain the mutation target.",
	)
	if returned_optional_definition != null:
		returned_optional_definition.content_id = &"progression.optional.tampered"
		returned_optional_definition.reward_ids.clear()
	returned_optional_definitions.clear()
	context.expect_equal(
		result.registry().optional_progression_definitions().size(),
		4,
		"Mutating a returned optional definition array must not alter stored state.",
	)
	context.expect_equal(
		result.registry()
		.lookup_optional_progression(optional_group_id)
		.optional_progression()
		.reward_ids.size(),
		2,
		"Nested returned optional definitions must be deep snapshots.",
	)


func _isolates_query_results(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"H-4.4 query isolation",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var reward_id := &"progression.reward.main.chapter.01.attack"
	var reward_query: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(reward_id)
	)
	var returned_reward: PermanentGrowthRewardDefinitionScript = (
		reward_query.permanent_growth_reward()
	)
	returned_reward.reward_id = &"progression.reward.tampered"
	returned_reward.stat_kind = 4
	returned_reward.increase = 999
	context.expect_equal(
		reward_query.permanent_growth_reward().reward_id,
		reward_id,
		"Reward QueryResult getter must return a new snapshot every time.",
	)
	context.expect_equal(
		registry.lookup_permanent_growth_reward(reward_id).permanent_growth_reward().increase,
		1,
		"Mutating a lookup payload must not alter later lookups.",
	)

	var mainline_query: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
	)
	var returned_mainline: MainlineProgressionDefinitionScript = (
		mainline_query.mainline_progression()
	)
	returned_mainline.content_id = &"progression.main.tampered"
	returned_mainline.reward_ids.clear()
	context.expect_equal(
		mainline_query.mainline_progression().reward_ids,
		[
			&"progression.reward.main.chapter.01.attack",
			&"progression.reward.main.chapter.01.maximum_health",
		],
		"Mainline QueryResult membership must be deep-snapshotted.",
	)
	context.expect_equal(
		mainline_query.mainline_progression().content_id,
		&"progression.main.chapter.01",
		"Mainline QueryResult definitions must be deep-snapshotted.",
	)

	var optional_query: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.m04")
	)
	var returned_optional: OptionalProgressionDefinitionScript = (
		optional_query.optional_progression()
	)
	returned_optional.content_id = &"progression.optional.tampered"
	returned_optional.reward_ids.clear()
	context.expect_equal(
		optional_query.optional_progression().reward_ids,
		[
			&"progression.reward.optional.m04.attack",
			&"progression.reward.optional.m04.defense",
		],
		"Optional QueryResult membership must be deep-snapshotted.",
	)
	context.expect_equal(
		optional_query.optional_progression().content_id,
		&"progression.optional.m04",
		"Optional QueryResult definitions must be deep-snapshotted.",
	)

	var initial_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	var returned_initial_profile: PlayerStatProfileScript = initial_query.player_stats()
	returned_initial_profile.profile_id = &"progression.player.tampered"
	returned_initial_profile.attack = 999
	context.expect_equal(
		initial_query.player_stats().profile_id,
		&"progression.player.loer",
		"Initial-stats QueryResult profile IDs must be deep-snapshotted.",
	)
	context.expect_equal(
		initial_query.player_stats().attack,
		10,
		"Initial-stats QueryResult values must be deep-snapshotted.",
	)

	var completion_query: GlobalProgressionQueryResultScript = (
		registry.full_completion_player_stats()
	)
	var returned_profile: PlayerStatProfileScript = completion_query.player_stats()
	returned_profile.maximum_health = 1
	context.expect_equal(
		completion_query.player_stats().maximum_health,
		200,
		"Aggregate stats QueryResult must return a new snapshot every time.",
	)

	var unknown: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(&"progression.reward.unknown")
	)
	var returned_issue: ContentValidationIssueScript = unknown.issue()
	returned_issue._message = "tampered"
	context.expect_true(
		unknown.issue().message() != "tampered",
		"Failed reward QueryResult must snapshot its issue on every getter call.",
	)
	_expect_failed_query_payloads_null(context, unknown, "Isolated failed reward query")


func _isolates_resource_loader_cache(context: HeadlessTestContextScript) -> void:
	var loaded: Resource = ResourceLoader.load(
		ContentRegistryBuilderScript.CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_REUSE,
	)
	context.expect_true(loaded != null, "Cache isolation fixture must load the manifest.")
	if loaded == null or loaded.get_script() != ContentManifestScript:
		return
	var cached_manifest: ContentManifestScript = loaded as ContentManifestScript
	var cached_catalog: GlobalProgressionCatalogScript = cached_manifest.global_progression_catalog
	var reward_id := &"progression.reward.main.chapter.01.attack"
	var group_id := &"progression.main.chapter.01"
	var cached_reward: PermanentGrowthRewardDefinitionScript = _find_reward(
		cached_catalog,
		reward_id,
	)
	var cached_group: MainlineProgressionDefinitionScript = _find_mainline(
		cached_catalog,
		group_id,
	)
	var original_increase: int = cached_reward.increase
	var original_membership: Array[StringName] = _copy_ids(cached_group.reward_ids)
	cached_reward.increase = 999
	cached_group.reward_ids.clear()
	var isolated_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	cached_reward.increase = original_increase
	cached_group.reward_ids = original_membership
	context.expect_true(
		isolated_result.succeeded(),
		"Canonical load must ignore the mutated deep Resource cache. %s"
		% _diagnostics(isolated_result),
	)
	if not isolated_result.succeeded():
		return
	context.expect_equal(
		isolated_result.registry()
		.lookup_permanent_growth_reward(reward_id)
		.permanent_growth_reward()
		.increase,
		1,
		"Deep-ignore loading must restore the on-disk reward value.",
	)
	context.expect_equal(
		isolated_result.registry()
		.lookup_mainline_progression(group_id)
		.mainline_progression()
		.reward_ids.size(),
		2,
		"Deep-ignore loading must restore on-disk reward membership.",
	)


func _invalidates_tampered_registry_state(
	context: HeadlessTestContextScript,
) -> void:
	var reward_id := &"progression.reward.main.chapter.01.attack"

	var reward_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build reward tampering",
	)
	if reward_result.succeeded():
		var reward_registry: ContentRegistryScript = reward_result.registry()
		reward_registry._permanent_growth_rewards_by_id[reward_id].increase = 999
		_expect_tampering_rejected(
			context,
			reward_registry,
			reward_result,
			"reward definition",
		)

	var reward_id_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build reward ID tampering",
	)
	if reward_id_result.succeeded():
		var reward_id_registry: ContentRegistryScript = reward_id_result.registry()
		reward_id_registry._permanent_growth_rewards_by_id[reward_id].reward_id = (
			&"progression.reward.tampered"
		)
		_expect_tampering_rejected(
			context,
			reward_id_registry,
			reward_id_result,
			"reward ID",
		)

	var stat_kind_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build reward stat-kind tampering",
	)
	if stat_kind_result.succeeded():
		var stat_kind_registry: ContentRegistryScript = stat_kind_result.registry()
		stat_kind_registry._permanent_growth_rewards_by_id[reward_id].stat_kind = 3
		_expect_tampering_rejected(
			context,
			stat_kind_registry,
			stat_kind_result,
			"valid-but-wrong reward stat kind",
		)

	var membership_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build membership tampering",
	)
	if membership_result.succeeded():
		var membership_registry: ContentRegistryScript = membership_result.registry()
		membership_registry._mainline_progression_by_id[
			&"progression.main.chapter.01"
		].reward_ids.clear()
		_expect_tampering_rejected(
			context,
			membership_registry,
			membership_result,
			"mainline reward membership",
		)

	var optional_membership_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build optional membership tampering",
	)
	if optional_membership_result.succeeded():
		var optional_membership_registry: ContentRegistryScript = (
			optional_membership_result.registry()
		)
		optional_membership_registry._optional_progression_by_id[
			&"progression.optional.m04"
		].reward_ids.clear()
		_expect_tampering_rejected(
			context,
			optional_membership_registry,
			optional_membership_result,
			"optional reward membership",
		)

	var index_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build reward index tampering",
	)
	if index_result.succeeded():
		var index_registry: ContentRegistryScript = index_result.registry()
		var empty_index: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
		index_registry._permanent_growth_rewards_by_id = empty_index
		_expect_tampering_rejected(
			context,
			index_registry,
			index_result,
			"reward dictionary index",
		)

	var order_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build reward order tampering",
	)
	if order_result.succeeded():
		var order_registry: ContentRegistryScript = order_result.registry()
		var reversed_ids: Array[StringName] = order_registry.permanent_growth_reward_ids()
		reversed_ids.reverse()
		order_registry._permanent_growth_reward_ids = reversed_ids
		_expect_tampering_rejected(
			context,
			order_registry,
			order_result,
			"reward ID order",
		)

	var version_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build version tampering",
	)
	if version_result.succeeded():
		var version_registry: ContentRegistryScript = version_result.registry()
		version_registry._schema_version = 4
		version_registry._content_version = 4
		_expect_tampering_rejected(
			context,
			version_registry,
			version_result,
			"schema/content version",
		)


func _invalidates_baseline_metadata_tampering(
	context: HeadlessTestContextScript,
) -> void:
	var scalar_fields: Array[StringName] = [
		&"catalog.catalog_id",
		&"profile.profile_id",
		&"profile.maximum_health",
		&"profile.attack",
		&"profile.defense",
		&"profile.speed",
		&"mainline.content_id",
		&"mainline.chapter",
		&"optional.content_id",
		&"optional.optional_map_id",
		&"optional.available_after_chapter",
	]
	for scalar_field: StringName in scalar_fields:
		var scalar_result: ContentRegistryBuildResultScript = _canonical_result(
			context,
			"Post-build baseline scalar tampering '%s'" % String(scalar_field),
		)
		if not scalar_result.succeeded():
			continue
		var scalar_registry: ContentRegistryScript = scalar_result.registry()
		_tamper_baseline_progression_scalar(scalar_registry, scalar_field)
		_expect_tampering_rejected(
			context,
			scalar_registry,
			scalar_result,
			"baseline progression scalar '%s'" % String(scalar_field),
		)

	var mainline_order_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build mainline ID-order tampering",
	)
	if mainline_order_result.succeeded():
		var mainline_order_registry: ContentRegistryScript = mainline_order_result.registry()
		var reversed_mainline_ids: Array[StringName] = (
			mainline_order_registry.mainline_progression_ids()
		)
		reversed_mainline_ids.reverse()
		mainline_order_registry._mainline_progression_ids = reversed_mainline_ids
		_expect_tampering_rejected(
			context,
			mainline_order_registry,
			mainline_order_result,
			"mainline ID order",
		)

	var optional_order_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build optional ID-order tampering",
	)
	if optional_order_result.succeeded():
		var optional_order_registry: ContentRegistryScript = optional_order_result.registry()
		var reversed_optional_ids: Array[StringName] = (
			optional_order_registry.optional_progression_ids()
		)
		reversed_optional_ids.reverse()
		optional_order_registry._optional_progression_ids = reversed_optional_ids
		_expect_tampering_rejected(
			context,
			optional_order_registry,
			optional_order_result,
			"optional ID order",
		)

	var mainline_dictionary_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build mainline dictionary tampering",
	)
	if mainline_dictionary_result.succeeded():
		var mainline_dictionary_registry: ContentRegistryScript = (
			mainline_dictionary_result.registry()
		)
		var empty_mainline: Dictionary[StringName, MainlineProgressionDefinitionScript] = {}
		mainline_dictionary_registry._mainline_progression_by_id = empty_mainline
		_expect_tampering_rejected(
			context,
			mainline_dictionary_registry,
			mainline_dictionary_result,
			"mainline dictionary",
		)

	var optional_dictionary_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build optional dictionary tampering",
	)
	if optional_dictionary_result.succeeded():
		var optional_dictionary_registry: ContentRegistryScript = (
			optional_dictionary_result.registry()
		)
		var empty_optional: Dictionary[StringName, OptionalProgressionDefinitionScript] = {}
		optional_dictionary_registry._optional_progression_by_id = empty_optional
		_expect_tampering_rejected(
			context,
			optional_dictionary_registry,
			optional_dictionary_result,
			"optional dictionary",
		)

	var mainline_script_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build mainline exact-script tampering",
	)
	if mainline_script_result.succeeded():
		var mainline_script_registry: ContentRegistryScript = mainline_script_result.registry()
		var stored_mainline: Resource = (
			mainline_script_registry._mainline_progression_by_id[
				&"progression.main.chapter.01"
			] as Resource
		)
		stored_mainline.set_script(null)
		_expect_tampering_rejected(
			context,
			mainline_script_registry,
			mainline_script_result,
			"mainline exact script",
		)

	var optional_script_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build optional exact-script tampering",
	)
	if optional_script_result.succeeded():
		var optional_script_registry: ContentRegistryScript = optional_script_result.registry()
		var stored_optional: Resource = (
			optional_script_registry._optional_progression_by_id[
				&"progression.optional.m01"
			] as Resource
		)
		stored_optional.set_script(null)
		_expect_tampering_rejected(
			context,
			optional_script_registry,
			optional_script_result,
			"optional exact script",
		)

	var blueprint_cross_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Post-build blueprint-to-progression cross-domain tampering",
	)
	if blueprint_cross_result.succeeded():
		var blueprint_cross_registry: ContentRegistryScript = (
			blueprint_cross_result.registry()
		)
		blueprint_cross_registry._blueprints_by_id[&"blueprint.01"].unlock_chapter = 9
		var progression_query: GlobalProgressionQueryResultScript = (
			blueprint_cross_registry.initial_player_stats()
		)
		context.expect_true(
			not progression_query.succeeded(),
			"Blueprint tampering must disable progression queries through the shared seal.",
		)
		_expect_failed_query_payloads_null(
			context,
			progression_query,
			"Blueprint-tampered progression query",
		)
		context.expect_equal(
			progression_query.issue().code(),
			ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
			"Blueprint-to-progression failure must be structured.",
		)
		_expect_tampering_rejected(
			context,
			blueprint_cross_registry,
			blueprint_cross_result,
			"blueprint-to-progression cross-domain state",
		)


func _fingerprints_and_rebuilds_deterministically(
	context: HeadlessTestContextScript,
) -> void:
	var first: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"First deterministic H-4.4 rebuild",
	)
	var second: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Second deterministic H-4.4 rebuild",
	)
	if not first.succeeded() or not second.succeeded():
		return
	context.expect_true(first.registry() != second.registry(), "Rebuilds must isolate registries.")
	context.expect_true(
		first.registry().global_progression_catalog().is_equal_to(
			second.registry().global_progression_catalog()
		),
		"Rebuilds must expose value-equal catalogs.",
	)
	context.expect_true(
		first.registry().enemy_profile_catalog().is_equal_to(
			second.registry().enemy_profile_catalog()
		),
		"Rebuilds must expose value-equal enemy catalogs.",
	)
	context.expect_true(
		first.registry().permanent_growth_reward_definitions()[0]
		!= second.registry().permanent_growth_reward_definitions()[0],
		"Rebuilds must isolate nested reward Resources.",
	)
	context.expect_true(
		first.registry().mainline_progression_definitions()[0]
		!= second.registry().mainline_progression_definitions()[0],
		"Rebuilds must isolate nested membership Resources.",
	)

	var canonical_manifest: ContentManifestScript = _manifest_from_registry(first.registry())
	var canonical_fingerprint: String = _fingerprint(canonical_manifest)
	context.expect_equal(
		canonical_fingerprint,
		GlobalProgressionCatalogOracle.FROZEN_V6_FINGERPRINT,
		"Calculated schema/content v6 fingerprint must match the independent oracle.",
	)
	context.expect_equal(
		ContentContractFingerprintScript.EXPECTED_FINGERPRINT,
		GlobalProgressionCatalogOracle.FROZEN_V6_FINGERPRINT,
		"Production frozen fingerprint must independently match the oracle digest.",
	)
	context.expect_equal(
		canonical_fingerprint.length(),
		64,
		"Frozen v6 fingerprint must be a SHA-256 hex digest.",
	)
	context.expect_true(
		ContentContractFingerprintScript.matches(
			canonical_manifest.schema_version,
			canonical_manifest.content_version,
			canonical_manifest.blueprints,
			canonical_manifest.recipes,
			canonical_manifest.global_progression_catalog,
			canonical_manifest.representative_route_contract_catalog,
			canonical_manifest.enemy_profile_catalog,
			canonical_manifest.static_map_catalog,
		),
		"Canonical schema/content v6 must match the frozen fingerprint.",
	)

	var reordered_manifest: ContentManifestScript = _manifest_from_registry(first.registry())
	_reverse_all_declarations(reordered_manifest)
	context.expect_equal(
		_fingerprint(reordered_manifest),
		canonical_fingerprint,
		"Fingerprint v6 must ignore top-level and nested declaration order.",
	)

	var reward_id_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	_find_reward(
		reward_id_tamper.global_progression_catalog,
		&"progression.reward.main.chapter.01.attack",
	).reward_id = &"progression.reward.tampered"
	context.expect_true(
		_fingerprint(reward_id_tamper) != canonical_fingerprint,
		"Fingerprint v6 must cover reward identity.",
	)

	var stat_kind_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	_find_reward(
		stat_kind_tamper.global_progression_catalog,
		&"progression.reward.main.chapter.01.attack",
	).stat_kind = 3
	context.expect_true(
		_fingerprint(stat_kind_tamper) != canonical_fingerprint,
		"Fingerprint v6 must detect a valid-but-wrong reward stat kind.",
	)

	var reward_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	_find_reward(
		reward_tamper.global_progression_catalog,
		&"progression.reward.main.chapter.01.attack",
	).increase = 2
	context.expect_true(
		_fingerprint(reward_tamper) != canonical_fingerprint,
		"Fingerprint v6 must cover reward stat semantics.",
	)

	var membership_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	var first_group: MainlineProgressionDefinitionScript = _find_mainline(
		membership_tamper.global_progression_catalog,
		&"progression.main.chapter.01",
	)
	var second_group: MainlineProgressionDefinitionScript = _find_mainline(
		membership_tamper.global_progression_catalog,
		&"progression.main.chapter.02",
	)
	_replace_reward_id(
		first_group.reward_ids,
		&"progression.reward.main.chapter.01.maximum_health",
		&"progression.reward.main.chapter.02.maximum_health",
	)
	_replace_reward_id(
		second_group.reward_ids,
		&"progression.reward.main.chapter.02.maximum_health",
		&"progression.reward.main.chapter.01.maximum_health",
	)
	context.expect_equal(
		_aggregate_trace(membership_tamper.global_progression_catalog),
		_aggregate_trace(canonical_manifest.global_progression_catalog),
		"Fingerprint membership fixture must preserve aggregate totals.",
	)
	context.expect_true(
		_fingerprint(membership_tamper) != canonical_fingerprint,
		"Fingerprint v6 must detect equal-valued rewards exchanged across groups.",
	)

	var old_version_manifest: ContentManifestScript = _manifest_from_registry(first.registry())
	old_version_manifest.schema_version = 4
	old_version_manifest.content_version = 4
	context.expect_true(
		_fingerprint(old_version_manifest) != canonical_fingerprint,
		"The old v4 header must not share the schema/content v6 fingerprint.",
	)
	context.expect_true(
		not ContentContractFingerprintScript.matches(
			old_version_manifest.schema_version,
			old_version_manifest.content_version,
			old_version_manifest.blueprints,
			old_version_manifest.recipes,
			old_version_manifest.global_progression_catalog,
			old_version_manifest.representative_route_contract_catalog,
			old_version_manifest.enemy_profile_catalog,
			old_version_manifest.static_map_catalog,
		),
		"The old v4 header must not match the frozen v6 contract.",
	)


func _manifest_from_registry(registry: ContentRegistryScript) -> ContentManifestScript:
	var manifest := ContentManifestScript.new()
	manifest.schema_version = registry.schema_version()
	manifest.content_version = registry.content_version()
	manifest.blueprints = registry.blueprints()
	manifest.recipes = registry.recipes()
	manifest.global_progression_catalog = registry.global_progression_catalog()
	manifest.representative_route_contract_catalog = (
		registry.representative_route_contract_catalog()
	)
	manifest.enemy_profile_catalog = registry.enemy_profile_catalog()
	manifest.static_map_catalog = registry.static_map_catalog()
	return manifest


func _canonical_result(
	context: HeadlessTestContextScript,
	fixture_name: String,
) -> ContentRegistryBuildResultScript:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		result.succeeded(),
		"%s needs canonical input. %s" % [fixture_name, _diagnostics(result)],
	)
	return result


func _find_reward(
	catalog: GlobalProgressionCatalogScript,
	reward_id: StringName,
) -> PermanentGrowthRewardDefinitionScript:
	for reward: PermanentGrowthRewardDefinitionScript in catalog.permanent_growth_rewards:
		if reward != null and reward.reward_id == reward_id:
			return reward
	return null


func _find_mainline(
	catalog: GlobalProgressionCatalogScript,
	content_id: StringName,
) -> MainlineProgressionDefinitionScript:
	for definition: MainlineProgressionDefinitionScript in catalog.mainline_progression:
		if definition != null and definition.content_id == content_id:
			return definition
	return null


func _find_optional(
	catalog: GlobalProgressionCatalogScript,
	content_id: StringName,
) -> OptionalProgressionDefinitionScript:
	for definition: OptionalProgressionDefinitionScript in catalog.optional_progression:
		if definition != null and definition.content_id == content_id:
			return definition
	return null


func _replace_reward_id(
	reward_ids: Array[StringName],
	old_id: StringName,
	new_id: StringName,
) -> void:
	var index: int = reward_ids.find(old_id)
	if index >= 0:
		reward_ids[index] = new_id


func _aggregate_trace(catalog: GlobalProgressionCatalogScript) -> Array[int]:
	var rewards_by_id: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
	for reward: PermanentGrowthRewardDefinitionScript in catalog.permanent_growth_rewards:
		if reward != null:
			rewards_by_id[reward.reward_id] = reward
	var values: Array[int] = _profile_values(catalog.initial_stats)
	var trace: Array[int] = []
	var mainline: Array[MainlineProgressionDefinitionScript] = []
	for definition: MainlineProgressionDefinitionScript in catalog.mainline_progression:
		mainline.append(definition)
	mainline.sort_custom(_mainline_less_than)
	for definition: MainlineProgressionDefinitionScript in mainline:
		for reward_id: StringName in definition.reward_ids:
			var reward: PermanentGrowthRewardDefinitionScript = rewards_by_id[reward_id]
			values[reward.stat_kind - 1] += reward.increase
		trace.append_array(values)
	var optional: Array[OptionalProgressionDefinitionScript] = []
	for definition: OptionalProgressionDefinitionScript in catalog.optional_progression:
		optional.append(definition)
	optional.sort_custom(_optional_less_than)
	for definition: OptionalProgressionDefinitionScript in optional:
		for reward_id: StringName in definition.reward_ids:
			var reward: PermanentGrowthRewardDefinitionScript = rewards_by_id[reward_id]
			values[reward.stat_kind - 1] += reward.increase
	trace.append_array(values)
	return trace


func _reverse_all_declarations(manifest: ContentManifestScript) -> void:
	manifest.blueprints.reverse()
	manifest.recipes.reverse()
	var catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	catalog.mainline_progression.reverse()
	catalog.optional_progression.reverse()
	catalog.permanent_growth_rewards.reverse()
	for definition: MainlineProgressionDefinitionScript in catalog.mainline_progression:
		definition.reward_ids.reverse()
	for definition: OptionalProgressionDefinitionScript in catalog.optional_progression:
		definition.reward_ids.reverse()
	var enemy_catalog: EnemyProfileCatalogScript = manifest.enemy_profile_catalog
	enemy_catalog.families.reverse()
	enemy_catalog.profiles.reverse()
	for profile: EnemyProfileDefinitionScript in enemy_catalog.profiles:
		profile.combat_trait_ids.reverse()


func _corrupt_for_ordering(catalog: GlobalProgressionCatalogScript) -> void:
	catalog.catalog_id = &"progression.invalid"
	catalog.initial_stats.attack = 99
	_find_reward(
		catalog,
		&"progression.reward.main.chapter.01.attack",
	).increase = 2
	_find_mainline(
		catalog,
		&"progression.main.chapter.01",
	).reward_ids.append(&"progression.reward.main.chapter.01.attack")
	_find_optional(
		catalog,
		&"progression.optional.m01",
	).optional_map_id = &"M99"


func _fingerprint(manifest: ContentManifestScript) -> String:
	return ContentContractFingerprintScript.calculate(
		manifest.schema_version,
		manifest.content_version,
		manifest.blueprints,
		manifest.recipes,
		manifest.global_progression_catalog,
		manifest.representative_route_contract_catalog,
		manifest.enemy_profile_catalog,
		manifest.static_map_catalog,
	)


func _expect_uninitialized_progression_query(
	context: HeadlessTestContextScript,
	query: GlobalProgressionQueryResultScript,
	expected_kind: int,
	expected_subject: StringName,
	fixture_name: String,
) -> void:
	context.expect_true(not query.succeeded(), "%s must fail." % fixture_name)
	context.expect_equal(
		query.kind(),
		expected_kind,
		"%s must retain its result kind." % fixture_name,
	)
	_expect_failed_query_payloads_null(context, query, fixture_name)
	var issue: ContentValidationIssueScript = query.issue()
	context.expect_true(issue != null, "%s must expose an issue." % fixture_name)
	if issue == null:
		return
	context.expect_equal(
		issue.code(),
		ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
		"%s must use the progression uninitialized code." % fixture_name,
	)
	context.expect_equal(
		issue.content_id(),
		expected_subject,
		"%s must retain the requested subject." % fixture_name,
	)
	context.expect_equal(issue.field_path(), "registry", "%s must name registry." % fixture_name)


func _expect_failed_query_payloads_null(
	context: HeadlessTestContextScript,
	query: GlobalProgressionQueryResultScript,
	fixture_name: String,
) -> void:
	context.expect_equal(
		query.player_stats(),
		null,
		"%s must not expose player stats." % fixture_name,
	)
	context.expect_equal(
		query.mainline_progression(),
		null,
		"%s must not expose mainline payload." % fixture_name,
	)
	context.expect_equal(
		query.optional_progression(),
		null,
		"%s must not expose optional payload." % fixture_name,
	)
	context.expect_equal(
		query.permanent_growth_reward(),
		null,
		"%s must not expose reward payload." % fixture_name,
	)


func _tamper_baseline_progression_scalar(
	registry: ContentRegistryScript,
	field_name: StringName,
) -> void:
	var mainline: MainlineProgressionDefinitionScript = (
		registry._mainline_progression_by_id[&"progression.main.chapter.01"]
	)
	var optional: OptionalProgressionDefinitionScript = (
		registry._optional_progression_by_id[&"progression.optional.m01"]
	)
	match field_name:
		&"catalog.catalog_id":
			registry._progression_catalog_id = &"progression.tampered"
		&"profile.profile_id":
			registry._initial_player_stats.profile_id = &"progression.player.tampered"
		&"profile.maximum_health":
			registry._initial_player_stats.maximum_health = 999
		&"profile.attack":
			registry._initial_player_stats.attack = 999
		&"profile.defense":
			registry._initial_player_stats.defense = 999
		&"profile.speed":
			registry._initial_player_stats.speed = 999
		&"mainline.content_id":
			mainline.content_id = &"progression.main.tampered"
		&"mainline.chapter":
			mainline.chapter = 99
		&"optional.content_id":
			optional.content_id = &"progression.optional.tampered"
		&"optional.optional_map_id":
			optional.optional_map_id = &"M99"
		&"optional.available_after_chapter":
			optional.available_after_chapter = 99


func _expect_tampering_rejected(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	result: ContentRegistryBuildResultScript,
	tampered_surface: String,
) -> void:
	context.expect_true(
		not registry.is_initialized(),
		"Tampered %s must invalidate the registry seal." % tampered_surface,
	)
	context.expect_true(
		not result.succeeded(),
		"Tampered %s must invalidate its BuildResult." % tampered_surface,
	)
	context.expect_equal(
		result.registry(),
		null,
		"Tampered %s must not remain publishable." % tampered_surface,
	)
	var reward_query: GlobalProgressionQueryResultScript = (
		registry.lookup_permanent_growth_reward(
			&"progression.reward.main.chapter.01.attack"
		)
	)
	context.expect_true(
		not reward_query.succeeded(),
		"Tampered %s must fail closed for reward lookup." % tampered_surface,
	)
	_expect_failed_query_payloads_null(
		context,
		reward_query,
		"Tampered %s reward lookup" % tampered_surface,
	)
	context.expect_equal(
		reward_query.issue().code(),
		ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
		"Tampered %s must report an uninitialized progression registry."
		% tampered_surface,
	)
	var blueprint_query = registry.lookup_blueprint(&"blueprint.01")
	context.expect_true(
		not blueprint_query.succeeded(),
		"Tampered %s must fail closed across registry domains." % tampered_surface,
	)
	context.expect_equal(
		blueprint_query.issue().code(),
		ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
		"Tampered %s must invalidate non-progression lookups too." % tampered_surface,
	)


func _expect_issue(
	context: HeadlessTestContextScript,
	result: ContentRegistryBuildResultScript,
	code: StringName,
	content_id: StringName,
	field_path: String,
	fixture_name: String,
) -> void:
	context.expect_true(not result.succeeded(), "%s must fail validation." % fixture_name)
	context.expect_equal(result.registry(), null, "%s must fail closed." % fixture_name)
	_expect_issue_tuple(context, result, code, content_id, field_path, fixture_name)


func _expect_issue_tuple(
	context: HeadlessTestContextScript,
	result: ContentRegistryBuildResultScript,
	code: StringName,
	content_id: StringName,
	field_path: String,
	fixture_name: String,
) -> void:
	context.expect_true(
		_has_issue_tuple(result, code, content_id, field_path),
		"%s must emit code='%s', subject='%s', path='%s'. %s"
		% [
			fixture_name,
			String(code),
			String(content_id),
			field_path,
			_diagnostics(result),
		],
	)


func _has_issue_tuple(
	result: ContentRegistryBuildResultScript,
	code: StringName,
	content_id: StringName,
	field_path: String,
) -> bool:
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		if (
			issue.code() == code
			and issue.content_id() == content_id
			and issue.field_path() == field_path
		):
			return true
	return false


func _issue_codes(result: ContentRegistryBuildResultScript) -> Array[StringName]:
	var codes: Array[StringName] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		codes.append(issue.code())
	return codes


func _expected_reward_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: GlobalProgressionCatalogOracle.RewardRow in (
		GlobalProgressionCatalogOracle.reward_rows()
	):
		ids.append(row.reward_id)
	return ids


func _expected_mainline_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: GlobalProgressionCatalogOracle.GroupRow in (
		GlobalProgressionCatalogOracle.mainline_group_rows()
	):
		ids.append(row.content_id)
	return ids


func _expected_optional_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: GlobalProgressionCatalogOracle.GroupRow in (
		GlobalProgressionCatalogOracle.optional_group_rows()
	):
		ids.append(row.content_id)
	return ids


func _profile_values(profile: PlayerStatProfileScript) -> Array[int]:
	if profile == null:
		return []
	return [profile.maximum_health, profile.attack, profile.defense, profile.speed]


func _resource_has_property(resource: Resource, property_name: StringName) -> bool:
	for property: Dictionary in resource.get_property_list():
		if StringName(property.get("name", &"")) == property_name:
			return true
	return false


func _copy_ids(source: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: StringName in source:
		result.append(value)
	return result


func _diagnostics(result: ContentRegistryBuildResultScript) -> String:
	return "validation_signatures=%s" % str(result.validation_report().signatures())


func _mainline_less_than(
	left: MainlineProgressionDefinitionScript,
	right: MainlineProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


func _optional_less_than(
	left: OptionalProgressionDefinitionScript,
	right: OptionalProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)
