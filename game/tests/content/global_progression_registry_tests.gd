extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const MainlineProgressionDefinitionScript := preload(
	"res://src/content/definitions/mainline_progression_definition_resource.gd"
)
const OptionalProgressionDefinitionScript := preload(
	"res://src/content/definitions/optional_progression_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
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
			"global_progression.rejects_malformed_catalog_atomically",
			_rejects_malformed_catalog_atomically,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_identity_and_position_collisions",
			_rejects_identity_and_position_collisions,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_same_total_field_swaps",
			_rejects_same_total_field_swaps,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rejects_null_and_polymorphic_resources",
			_rejects_null_and_polymorphic_resources,
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
			"global_progression.reports_structured_queries",
			_reports_structured_queries,
		),
		HeadlessTestCaseScript.new(
			"global_progression.isolates_input_resources",
			_isolates_input_resources,
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
			"global_progression.invalidates_complete_seal_and_cross_domain",
			_invalidates_complete_seal_and_cross_domain,
		),
		HeadlessTestCaseScript.new(
			"global_progression.rebuilds_deterministically",
			_rebuilds_deterministically,
		),
	]


func _builds_canonical_catalog(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		result.succeeded(),
		"The canonical H-3 catalog must build. %s" % _diagnostics(result),
	)
	context.expect_true(
		result.validation_report().is_valid(),
		"The canonical H-3 report must be empty. %s" % _diagnostics(result),
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	context.expect_equal(registry.schema_version(), 2, "H-3 schema version must be two.")
	context.expect_equal(registry.content_version(), 2, "H-3 content version must be two.")
	var catalog: GlobalProgressionCatalogScript = registry.global_progression_catalog()
	context.expect_true(catalog != null, "The registry must expose a progression snapshot.")
	if catalog == null:
		return
	context.expect_equal(
		catalog.catalog_id,
		&"progression.global",
		"The canonical progression catalog ID must be stable.",
	)
	context.expect_equal(
		catalog.mainline_progression.size(),
		9,
		"The canonical catalog must contain nine mainline bundles.",
	)
	context.expect_equal(
		catalog.optional_progression.size(),
		4,
		"The canonical catalog must contain four optional bundles.",
	)
	context.expect_equal(
		registry.mainline_progression_ids(),
		_expected_mainline_ids(),
		"Mainline IDs must use canonical lexical order.",
	)
	context.expect_equal(
		registry.optional_progression_ids(),
		_expected_optional_ids(),
		"Optional IDs must use canonical lexical order.",
	)
	var initial_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	context.expect_true(initial_query.succeeded(), "Initial player stats must be queryable.")
	context.expect_equal(
		initial_query.kind(),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		"Initial stats must retain the player-stats query kind.",
	)
	context.expect_equal(
		_profile_values(initial_query.player_stats()),
		[100, 10, 5, 10],
		"Initial stats must be 100/10/5/10.",
	)


func _matches_independent_oracle(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		result.succeeded(),
		"The independent H-3 oracle needs canonical input. %s" % _diagnostics(result),
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var initial_row: GlobalProgressionCatalogOracle.PlayerStatsRow = (
		GlobalProgressionCatalogOracle.initial_stats()
	)
	var initial_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	context.expect_true(initial_query.succeeded(), "The initial profile must be queryable.")
	if initial_query.succeeded():
		var initial_stats: PlayerStatProfileScript = initial_query.player_stats()
		context.expect_equal(initial_stats.profile_id, initial_row.profile_id, "Profile ID must match.")
		context.expect_equal(
			_profile_values(initial_stats),
			initial_row.values(),
			"Initial profile fields must match the literal oracle.",
		)

	var mainline_nonzero_counts: Array[int] = [0, 0, 0, 0]
	var mainline_rows: Array[GlobalProgressionCatalogOracle.MainlineRow] = (
		GlobalProgressionCatalogOracle.mainline_rows()
	)
	context.expect_equal(mainline_rows.size(), 9, "The literal mainline oracle must have nine rows.")
	for row: GlobalProgressionCatalogOracle.MainlineRow in mainline_rows:
		var lookup: GlobalProgressionQueryResultScript = (
			registry.lookup_mainline_progression(row.content_id)
		)
		context.expect_true(
			lookup.succeeded(),
			"Mainline progression '%s' must be queryable." % String(row.content_id),
		)
		if not lookup.succeeded():
			continue
		var definition: MainlineProgressionDefinitionScript = (
			lookup.mainline_progression()
		)
		context.expect_equal(definition.content_id, row.content_id, "Mainline ID must match.")
		context.expect_equal(definition.chapter, row.chapter, "Mainline chapter must match.")
		context.expect_equal(
			_mainline_delta(definition),
			row.delta_values(),
			"Mainline delta must match its literal row.",
		)
		_increment_nonzero_counts(
			mainline_nonzero_counts,
			_mainline_delta(definition),
		)
		var chapter_query: GlobalProgressionQueryResultScript = (
			registry.mainline_stats_after_chapter(row.chapter)
		)
		context.expect_true(
			chapter_query.succeeded(),
			"Chapter %d cumulative stats must be queryable." % row.chapter,
		)
		if chapter_query.succeeded():
			context.expect_equal(
				_profile_values(chapter_query.player_stats()),
				row.chapter_end_stats,
				"Chapter %d end stats must match the literal oracle." % row.chapter,
			)
	context.expect_equal(
		mainline_nonzero_counts,
		[8, 6, 6, 4],
		"Mainline atomic increases must be 8/6/6/4 (24 total).",
	)

	var optional_nonzero_counts: Array[int] = [0, 0, 0, 0]
	var optional_rows: Array[GlobalProgressionCatalogOracle.OptionalRow] = (
		GlobalProgressionCatalogOracle.optional_rows()
	)
	context.expect_equal(optional_rows.size(), 4, "The literal optional oracle must have four rows.")
	for row: GlobalProgressionCatalogOracle.OptionalRow in optional_rows:
		var lookup: GlobalProgressionQueryResultScript = (
			registry.lookup_optional_progression(row.content_id)
		)
		context.expect_true(
			lookup.succeeded(),
			"Optional progression '%s' must be queryable." % String(row.content_id),
		)
		if not lookup.succeeded():
			continue
		var definition: OptionalProgressionDefinitionScript = (
			lookup.optional_progression()
		)
		context.expect_equal(definition.content_id, row.content_id, "Optional ID must match.")
		context.expect_equal(
			definition.optional_map_id,
			row.optional_map_id,
			"Optional map ID must match.",
		)
		context.expect_equal(
			definition.available_after_chapter,
			row.available_after_chapter,
			"Optional availability chapter must match.",
		)
		context.expect_equal(
			_optional_delta(definition),
			row.delta_values(),
			"Optional delta must match its literal row.",
		)
		_increment_nonzero_counts(
			optional_nonzero_counts,
			_optional_delta(definition),
		)
	context.expect_equal(
		optional_nonzero_counts,
		[2, 2, 2, 0],
		"Optional atomic increases must be 2/2/2/0 (6 total).",
	)
	var mainline_final: GlobalProgressionQueryResultScript = (
		registry.mainline_stats_after_chapter(9)
	)
	context.expect_true(mainline_final.succeeded(), "Chapter-nine stats must be queryable.")
	if mainline_final.succeeded():
		context.expect_equal(
			_profile_values(mainline_final.player_stats()),
			[180, 16, 11, 14],
			"Mainline final stats must be 180/16/11/14.",
		)
	var full_completion: GlobalProgressionQueryResultScript = (
		registry.full_completion_player_stats()
	)
	context.expect_true(full_completion.succeeded(), "Full-completion stats must be queryable.")
	if full_completion.succeeded():
		context.expect_equal(
			_profile_values(full_completion.player_stats()),
			GlobalProgressionCatalogOracle.full_completion_stats(),
			"Full-completion stats must be 200/18/13/14.",
		)


func _rejects_malformed_catalog_atomically(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"Malformed H-3 fixtures need canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	catalog.catalog_id = &"progression.invalid"
	catalog.initial_stats.attack = 99
	catalog.mainline_progression[0].content_id = &"progression.main.unknown"
	catalog.mainline_progression[0].chapter = 0
	catalog.mainline_progression[0].maximum_health_increase = 20
	catalog.optional_progression[0].optional_map_id = &"M99"
	catalog.optional_progression[0].available_after_chapter = 0
	catalog.optional_progression[0].speed_increase = 1

	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "Malformed H-3 content must fail validation.")
	context.expect_equal(result.registry(), null, "Malformed H-3 content must fail closed.")
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_CATALOG_ID_INVALID,
		&"progression.invalid",
		"global_progression_catalog.catalog_id",
		"Malformed catalog ID",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
		&"progression.player.loer",
		"global_progression_catalog.initial_stats.attack",
		"Malformed initial attack",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_INVALID,
		&"progression.main.unknown",
		"mainline_progression.content_id",
		"Malformed mainline ID",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_INVALID,
		&"progression.main.unknown",
		"mainline_progression.chapter",
		"Malformed mainline chapter",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_DELTA_INVALID,
		&"progression.main.unknown",
		"mainline_progression.maximum_health_increase",
		"Malformed mainline delta",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_INVALID,
		&"progression.optional.m01",
		"optional_progression.optional_map_id",
		"Malformed optional map ID",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID,
		&"progression.optional.m01",
		"optional_progression.available_after_chapter",
		"Malformed optional availability",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_SPEED_FORBIDDEN,
		&"progression.optional.m01",
		"optional_progression.speed_increase",
		"Malformed optional speed",
	)


func _rejects_identity_and_position_collisions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Identity-collision fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	profile_manifest.global_progression_catalog.initial_stats.profile_id = (
		&"progression.player.invalid"
	)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(profile_manifest),
		ContentValidationIssueScript.PROGRESSION_PROFILE_ID_INVALID,
		&"progression.player.invalid",
		"global_progression_catalog.initial_stats.profile_id",
		"An invalid initial profile ID",
	)

	var empty_mainline_manifest: ContentManifestScript = _manifest_from_registry(registry)
	empty_mainline_manifest.global_progression_catalog.mainline_progression[0].content_id = &""
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(empty_mainline_manifest),
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_EMPTY,
		&"",
		"mainline_progression.content_id",
		"An empty mainline ID",
	)

	var duplicate_mainline_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_mainline_manifest.global_progression_catalog.mainline_progression[1].content_id = (
		&"progression.main.chapter.01"
	)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(duplicate_mainline_manifest),
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_DUPLICATE,
		&"progression.main.chapter.01",
		"mainline_progression.content_id",
		"A duplicate mainline ID",
	)

	var duplicate_chapter_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_chapter_manifest.global_progression_catalog.mainline_progression[1].chapter = 1
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(duplicate_chapter_manifest),
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_DUPLICATE,
		&"1",
		"mainline_progression.chapter",
		"A duplicate mainline chapter",
	)

	var empty_optional_manifest: ContentManifestScript = _manifest_from_registry(registry)
	empty_optional_manifest.global_progression_catalog.optional_progression[0].content_id = &""
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(empty_optional_manifest),
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_EMPTY,
		&"",
		"optional_progression.content_id",
		"An empty optional ID",
	)

	var duplicate_optional_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_optional_manifest.global_progression_catalog.optional_progression[1].content_id = (
		&"progression.optional.m01"
	)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(duplicate_optional_manifest),
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_DUPLICATE,
		&"progression.optional.m01",
		"optional_progression.content_id",
		"A duplicate optional ID",
	)

	var duplicate_map_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_map_manifest.global_progression_catalog.optional_progression[1].optional_map_id = (
		&"M01"
	)
	_expect_issue(
		context,
		ContentRegistryBuilderScript.build(duplicate_map_manifest),
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_DUPLICATE,
		&"M01",
		"optional_progression.optional_map_id",
		"A duplicate optional map ID",
	)


func _rejects_same_total_field_swaps(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"Same-total H-3 fixtures need canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	var original_mainline_totals: Array[int] = _mainline_totals(
		catalog.mainline_progression
	)
	var original_optional_totals: Array[int] = _optional_totals(
		catalog.optional_progression
	)
	catalog.mainline_progression[0].attack_increase = 0
	catalog.mainline_progression[1].attack_increase = 1
	catalog.optional_progression[0].maximum_health_increase = 0
	catalog.optional_progression[0].attack_increase = 1
	catalog.optional_progression[1].maximum_health_increase = 10
	catalog.optional_progression[1].attack_increase = 0
	context.expect_equal(
		_mainline_totals(catalog.mainline_progression),
		original_mainline_totals,
		"The mainline swap fixture must preserve aggregate totals.",
	)
	context.expect_equal(
		_optional_totals(catalog.optional_progression),
		original_optional_totals,
		"The optional swap fixture must preserve aggregate totals.",
	)

	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(
		not result.succeeded(),
		"Per-source H-3 validation must reject same-total field exchanges.",
	)
	context.expect_equal(result.registry(), null, "Same-total exchanges must fail closed.")
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_DELTA_MISMATCH,
		&"progression.main.chapter.01",
		"mainline_progression.attack_increase",
		"Same-total mainline exchange",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_DELTA_MISMATCH,
		&"progression.optional.m01",
		"optional_progression.maximum_health_increase",
		"Same-total optional exchange",
	)


func _rejects_null_and_polymorphic_resources(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"Exact-script H-3 fixtures need canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var null_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_catalog_manifest.global_progression_catalog = null
	var null_catalog_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null_catalog_manifest)
	)
	_expect_issue(
		context,
		null_catalog_result,
		ContentValidationIssueScript.MANIFEST_PROGRESSION_CATALOG_NULL,
		&"",
		"global_progression_catalog",
		"A null progression catalog",
	)

	var derived_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_catalog: GlobalProgressionCatalogScript = (
		DerivedGlobalProgressionCatalogScript.new()
	)
	derived_catalog_manifest.global_progression_catalog = derived_catalog
	var derived_catalog_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_catalog_manifest)
	)
	_expect_issue(
		context,
		derived_catalog_result,
		ContentValidationIssueScript.PROGRESSION_CATALOG_INVALID_SCRIPT,
		&"",
		"global_progression_catalog",
		"A derived progression catalog",
	)

	var null_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_profile_manifest.global_progression_catalog.initial_stats = null
	var null_profile_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null_profile_manifest)
	)
	_expect_issue(
		context,
		null_profile_result,
		ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_NULL,
		&"",
		"global_progression_catalog.initial_stats",
		"A null initial profile",
	)

	var derived_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_profile: PlayerStatProfileScript = DerivedPlayerStatProfileScript.new()
	derived_profile_manifest.global_progression_catalog.initial_stats = derived_profile
	var derived_profile_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_profile_manifest)
	)
	_expect_issue(
		context,
		derived_profile_result,
		ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.initial_stats",
		"A derived initial profile",
	)

	var derived_mainline_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_mainline: MainlineProgressionDefinitionScript = (
		DerivedMainlineProgressionDefinitionScript.new()
	)
	derived_mainline_manifest.global_progression_catalog.mainline_progression[0] = (
		derived_mainline
	)
	var derived_mainline_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_mainline_manifest)
	)
	_expect_issue(
		context,
		derived_mainline_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.mainline_progression[0]",
		"A derived mainline entry",
	)

	var derived_optional_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_optional: OptionalProgressionDefinitionScript = (
		DerivedOptionalProgressionDefinitionScript.new()
	)
	derived_optional_manifest.global_progression_catalog.optional_progression[0] = (
		derived_optional
	)
	var derived_optional_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_optional_manifest)
	)
	_expect_issue(
		context,
		derived_optional_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT,
		&"",
		"global_progression_catalog.optional_progression[0]",
		"A derived optional entry",
	)

	var null_entries_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_entries_manifest.global_progression_catalog.mainline_progression[0] = null
	null_entries_manifest.global_progression_catalog.optional_progression[0] = null
	var null_entries_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null_entries_manifest)
	)
	_expect_issue(
		context,
		null_entries_result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_NULL,
		&"",
		"global_progression_catalog.mainline_progression[0]",
		"A null mainline entry",
	)
	_expect_issue(
		context,
		null_entries_result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_NULL,
		&"",
		"global_progression_catalog.optional_progression[0]",
		"A null optional entry",
	)


func _rejects_oversized_catalog_at_header(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"Oversized H-3 fixtures need canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.global_progression_catalog.mainline_progression.resize(4096)
	manifest.global_progression_catalog.optional_progression.resize(4096)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "An oversized H-3 catalog must fail.")
	context.expect_equal(result.registry(), null, "Oversized H-3 content must fail closed.")
	context.expect_equal(
		_issue_codes(result),
		[
			ContentValidationIssueScript.PROGRESSION_MAINLINE_COUNT_INVALID,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_COUNT_INVALID,
		],
		"Oversized H-3 input must stop at bounded count validation.",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_COUNT_INVALID,
		&"progression.global",
		"global_progression_catalog.mainline_progression",
		"Oversized mainline header",
	)
	_expect_issue_tuple(
		context,
		result,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_COUNT_INVALID,
		&"progression.global",
		"global_progression_catalog.optional_progression",
		"Oversized optional header",
	)


func _orders_success_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"H-3 ordering needs canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.global_progression_catalog.mainline_progression.reverse()
	manifest.global_progression_catalog.optional_progression.reverse()
	var reversed_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(manifest)
	)
	context.expect_true(
		reversed_result.succeeded(),
		"Reversed H-3 declarations must remain valid. %s" % _diagnostics(reversed_result),
	)
	if not reversed_result.succeeded():
		return
	context.expect_equal(
		reversed_result.registry().mainline_progression_ids(),
		canonical.registry().mainline_progression_ids(),
		"Mainline query order must not depend on declaration order.",
	)
	context.expect_equal(
		reversed_result.registry().optional_progression_ids(),
		canonical.registry().optional_progression_ids(),
		"Optional query order must not depend on declaration order.",
	)
	context.expect_true(
		reversed_result.registry().global_progression_catalog().is_equal_to(
			canonical.registry().global_progression_catalog()
		),
		"Canonicalized catalog snapshots must be value-equal.",
	)


func _orders_errors_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"H-3 error ordering needs canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var forward_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	var reverse_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	_corrupt_for_ordering(forward_manifest.global_progression_catalog)
	_corrupt_for_ordering(reverse_manifest.global_progression_catalog)
	reverse_manifest.global_progression_catalog.mainline_progression.reverse()
	reverse_manifest.global_progression_catalog.optional_progression.reverse()
	var forward_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(forward_manifest)
	)
	var reverse_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(reverse_manifest)
	)
	context.expect_true(not forward_result.succeeded(), "Forward corrupt H-3 input must fail.")
	context.expect_true(not reverse_result.succeeded(), "Reverse corrupt H-3 input must fail.")
	context.expect_equal(forward_result.registry(), null, "Forward H-3 failure must be atomic.")
	context.expect_equal(reverse_result.registry(), null, "Reverse H-3 failure must be atomic.")
	context.expect_true(
		not forward_result.validation_report().signatures().is_empty(),
		"The H-3 ordering fixture must emit structured issues.",
	)
	context.expect_equal(
		forward_result.validation_report().signatures(),
		reverse_result.validation_report().signatures(),
		"H-3 issue order must not depend on declaration order.",
	)


func _reports_structured_queries(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		result.succeeded(),
		"Structured H-3 queries need canonical input. %s" % _diagnostics(result),
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

	var mainline_query: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
	)
	context.expect_true(mainline_query.succeeded(), "Known mainline lookup must succeed.")
	context.expect_equal(
		mainline_query.kind(),
		GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
		"Known mainline lookup must retain its kind.",
	)
	context.expect_equal(
		mainline_query.player_stats(),
		null,
		"A mainline result must not expose player stats.",
	)

	var optional_query: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.m01")
	)
	context.expect_true(optional_query.succeeded(), "Known optional lookup must succeed.")
	context.expect_equal(
		optional_query.kind(),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		"Known optional lookup must retain its kind.",
	)
	context.expect_equal(
		optional_query.mainline_progression(),
		null,
		"An optional result must not expose mainline content.",
	)

	var unknown_mainline: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.unknown")
	)
	context.expect_true(not unknown_mainline.succeeded(), "Unknown mainline lookup must fail.")
	_expect_failed_query_payloads_null(context, unknown_mainline, "Unknown mainline lookup")
	context.expect_equal(
		unknown_mainline.kind(),
		GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
		"Unknown mainline lookup must retain its kind.",
	)
	context.expect_equal(
		unknown_mainline.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_MAINLINE_PROGRESSION_ID,
		"Unknown mainline lookup must expose a stable code.",
	)
	context.expect_equal(
		unknown_mainline.issue().content_id(),
		&"progression.main.unknown",
		"Unknown mainline lookup must retain the requested ID.",
	)
	context.expect_equal(
		unknown_mainline.issue().field_path(),
		"content_id",
		"Unknown mainline lookup must identify its field.",
	)

	var unknown_optional: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.unknown")
	)
	context.expect_true(not unknown_optional.succeeded(), "Unknown optional lookup must fail.")
	_expect_failed_query_payloads_null(context, unknown_optional, "Unknown optional lookup")
	context.expect_equal(
		unknown_optional.kind(),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		"Unknown optional lookup must retain its kind.",
	)
	context.expect_equal(
		unknown_optional.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_OPTIONAL_PROGRESSION_ID,
		"Unknown optional lookup must expose a stable code.",
	)
	context.expect_equal(
		unknown_optional.issue().content_id(),
		&"progression.optional.unknown",
		"Unknown optional lookup must retain the requested ID.",
	)
	context.expect_equal(
		unknown_optional.issue().field_path(),
		"content_id",
		"Unknown optional lookup must identify its field.",
	)

	var invalid_chapter: GlobalProgressionQueryResultScript = (
		registry.mainline_stats_after_chapter(0)
	)
	context.expect_true(not invalid_chapter.succeeded(), "Chapter zero query must fail.")
	_expect_failed_query_payloads_null(context, invalid_chapter, "Invalid chapter lookup")
	context.expect_equal(
		invalid_chapter.kind(),
		GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
		"Invalid chapter lookup must retain its kind.",
	)
	context.expect_equal(
		invalid_chapter.issue().code(),
		ContentValidationIssueScript.LOOKUP_PROGRESSION_CHAPTER_INVALID,
		"Invalid chapter query must expose a stable code.",
	)
	context.expect_equal(
		invalid_chapter.issue().content_id(),
		&"0",
		"Invalid chapter query must retain the requested chapter.",
	)
	context.expect_equal(
		invalid_chapter.issue().field_path(),
		"chapter",
		"Invalid chapter query must identify its field.",
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
		"Uninitialized mainline lookup",
	)
	_expect_uninitialized_progression_query(
		context,
		raw_registry.lookup_optional_progression(&"progression.optional.m01"),
		GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
		&"progression.optional.m01",
		"Uninitialized optional lookup",
	)


func _isolates_input_resources(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		canonical.succeeded(),
		"H-3 input isolation needs canonical input. %s" % _diagnostics(canonical),
	)
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var source_catalog: GlobalProgressionCatalogScript = manifest.global_progression_catalog
	var source_profile: PlayerStatProfileScript = source_catalog.initial_stats
	var source_mainline: MainlineProgressionDefinitionScript = (
		source_catalog.mainline_progression[0]
	)
	var source_optional: OptionalProgressionDefinitionScript = (
		source_catalog.optional_progression[0]
	)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(
		result.succeeded(),
		"A copied H-3 manifest must build before mutation. %s" % _diagnostics(result),
	)
	if not result.succeeded():
		return

	source_catalog.catalog_id = &"progression.tampered"
	source_profile.attack = 999
	source_mainline.attack_increase = 999
	source_optional.maximum_health_increase = 999
	source_catalog.mainline_progression.clear()
	source_catalog.optional_progression.clear()
	manifest.global_progression_catalog = null

	context.expect_true(
		result.succeeded(),
		"Mutating H-3 source Resources must not invalidate the stored snapshot.",
	)
	var stored_catalog: GlobalProgressionCatalogScript = (
		result.registry().global_progression_catalog()
	)
	context.expect_equal(
		stored_catalog.catalog_id,
		&"progression.global",
		"Mutating the source catalog ID must not alter the registry.",
	)
	context.expect_equal(
		_profile_values(result.registry().initial_player_stats().player_stats()),
		[100, 10, 5, 10],
		"Mutating the source profile must not alter the registry.",
	)
	context.expect_equal(
		result.registry()
		.lookup_mainline_progression(&"progression.main.chapter.01")
		.mainline_progression()
		.attack_increase,
		1,
		"Mutating a source mainline entry must not alter the registry.",
	)
	context.expect_equal(
		result.registry()
		.lookup_optional_progression(&"progression.optional.m01")
		.optional_progression()
		.maximum_health_increase,
		10,
		"Mutating a source optional entry must not alter the registry.",
	)
	context.expect_equal(
		result.registry().mainline_progression_ids().size(),
		9,
		"Clearing the source mainline array must not shrink the registry.",
	)
	context.expect_equal(
		result.registry().optional_progression_ids().size(),
		4,
		"Clearing the source optional array must not shrink the registry.",
	)


func _isolates_query_results(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		result.succeeded(),
		"H-3 query isolation needs canonical input. %s" % _diagnostics(result),
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()

	var mainline_ids: Array[StringName] = registry.mainline_progression_ids()
	var optional_ids: Array[StringName] = registry.optional_progression_ids()
	mainline_ids.append(&"progression.main.tampered")
	optional_ids.clear()
	context.expect_equal(registry.mainline_progression_ids().size(), 9, "Mainline IDs must be copied.")
	context.expect_equal(registry.optional_progression_ids().size(), 4, "Optional IDs must be copied.")

	var mainline_definitions: Array[MainlineProgressionDefinitionScript] = (
		registry.mainline_progression_definitions()
	)
	var optional_definitions: Array[OptionalProgressionDefinitionScript] = (
		registry.optional_progression_definitions()
	)
	mainline_definitions[0].attack_increase = 999
	optional_definitions[0].maximum_health_increase = 999
	mainline_definitions.clear()
	optional_definitions.clear()
	context.expect_equal(
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
		.mainline_progression()
		.attack_increase,
		1,
		"Mutating a mainline collection snapshot must not alter the registry.",
	)
	context.expect_equal(
		registry.lookup_optional_progression(&"progression.optional.m01")
		.optional_progression()
		.maximum_health_increase,
		10,
		"Mutating an optional collection snapshot must not alter the registry.",
	)

	var catalog: GlobalProgressionCatalogScript = registry.global_progression_catalog()
	catalog.catalog_id = &"progression.tampered"
	catalog.initial_stats.attack = 999
	catalog.mainline_progression[0].chapter = 9
	catalog.optional_progression[0].speed_increase = 1
	catalog.mainline_progression.clear()
	catalog.optional_progression.clear()
	var fresh_catalog: GlobalProgressionCatalogScript = registry.global_progression_catalog()
	context.expect_equal(
		fresh_catalog.catalog_id,
		&"progression.global",
		"Catalog getters must return a fresh snapshot.",
	)
	context.expect_equal(
		_profile_values(fresh_catalog.initial_stats),
		[100, 10, 5, 10],
		"Catalog profile snapshots must be isolated.",
	)
	context.expect_equal(fresh_catalog.mainline_progression.size(), 9, "Catalog mainline data must be isolated.")
	context.expect_equal(fresh_catalog.optional_progression.size(), 4, "Catalog optional data must be isolated.")

	var mainline_query: GlobalProgressionQueryResultScript = (
		registry.lookup_mainline_progression(&"progression.main.chapter.01")
	)
	var returned_mainline: MainlineProgressionDefinitionScript = (
		mainline_query.mainline_progression()
	)
	returned_mainline.attack_increase = 999
	context.expect_equal(
		mainline_query.mainline_progression().attack_increase,
		1,
		"A mainline QueryResult must snapshot every getter call.",
	)
	var optional_query: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.m01")
	)
	var returned_optional: OptionalProgressionDefinitionScript = (
		optional_query.optional_progression()
	)
	returned_optional.maximum_health_increase = 999
	context.expect_equal(
		optional_query.optional_progression().maximum_health_increase,
		10,
		"An optional QueryResult must snapshot every getter call.",
	)
	var stats_query: GlobalProgressionQueryResultScript = registry.initial_player_stats()
	var returned_stats: PlayerStatProfileScript = stats_query.player_stats()
	returned_stats.attack = 999
	context.expect_equal(
		stats_query.player_stats().attack,
		10,
		"A player-stats QueryResult must snapshot every getter call.",
	)
	var full_stats_query: GlobalProgressionQueryResultScript = (
		registry.full_completion_player_stats()
	)
	var returned_full_stats: PlayerStatProfileScript = full_stats_query.player_stats()
	returned_full_stats.maximum_health = 999
	context.expect_equal(
		full_stats_query.player_stats().maximum_health,
		200,
		"Derived full-completion stats must be isolated snapshots.",
	)

	var unknown_query: GlobalProgressionQueryResultScript = (
		registry.lookup_optional_progression(&"progression.optional.unknown")
	)
	context.expect_true(
		not unknown_query.succeeded(),
		"Unknown optional issue-isolation lookup must fail.",
	)
	_expect_failed_query_payloads_null(
		context,
		unknown_query,
		"Unknown optional issue-isolation lookup",
	)
	var returned_issue: ContentValidationIssueScript = unknown_query.issue()
	returned_issue._message = "tampered"
	context.expect_true(
		unknown_query.issue().message() != "tampered",
		"A progression QueryResult must snapshot issues on every getter call.",
	)


func _isolates_resource_loader_cache(context: HeadlessTestContextScript) -> void:
	var loaded_resource: Resource = ResourceLoader.load(
		ContentRegistryBuilderScript.CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_REUSE,
	)
	context.expect_true(loaded_resource != null, "The H-3 cache fixture must load the manifest.")
	if loaded_resource == null:
		return
	context.expect_true(
		loaded_resource.get_script() == ContentManifestScript,
		"The H-3 cache fixture must load the exact manifest script.",
	)
	if loaded_resource.get_script() != ContentManifestScript:
		return
	var cached_manifest: ContentManifestScript = loaded_resource as ContentManifestScript
	var cached_catalog: GlobalProgressionCatalogScript = (
		cached_manifest.global_progression_catalog
	)
	context.expect_true(cached_catalog != null, "The cache fixture must contain H-3 content.")
	if cached_catalog == null:
		return
	var original_attack: int = cached_catalog.initial_stats.attack
	var original_mainline_attack: int = cached_catalog.mainline_progression[0].attack_increase
	var original_optional_speed: int = cached_catalog.optional_progression[3].speed_increase
	cached_catalog.initial_stats.attack = 999
	cached_catalog.mainline_progression[0].attack_increase = 999
	cached_catalog.optional_progression[3].speed_increase = 1
	var isolated_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	cached_catalog.initial_stats.attack = original_attack
	cached_catalog.mainline_progression[0].attack_increase = original_mainline_attack
	cached_catalog.optional_progression[3].speed_increase = original_optional_speed
	context.expect_true(
		isolated_result.succeeded(),
		"Canonical H-3 loading must ignore a mutated deep Resource cache. %s"
		% _diagnostics(isolated_result),
	)
	if not isolated_result.succeeded():
		return
	context.expect_equal(
		_profile_values(isolated_result.registry().initial_player_stats().player_stats()),
		[100, 10, 5, 10],
		"Deep-ignore loading must preserve on-disk initial stats.",
	)
	context.expect_equal(
		isolated_result.registry()
		.lookup_mainline_progression(&"progression.main.chapter.01")
		.mainline_progression()
		.attack_increase,
		1,
		"Deep-ignore loading must preserve on-disk mainline data.",
	)
	context.expect_equal(
		isolated_result.registry()
		.lookup_optional_progression(&"progression.optional.m04")
		.optional_progression()
		.speed_increase,
		0,
		"Deep-ignore loading must preserve on-disk optional data.",
	)


func _invalidates_complete_seal_and_cross_domain(
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
		&"mainline.maximum_health_increase",
		&"mainline.attack_increase",
		&"mainline.defense_increase",
		&"mainline.speed_increase",
		&"optional.content_id",
		&"optional.optional_map_id",
		&"optional.available_after_chapter",
		&"optional.maximum_health_increase",
		&"optional.attack_increase",
		&"optional.defense_increase",
		&"optional.speed_increase",
	]
	for scalar_field: StringName in scalar_fields:
		var scalar_result: ContentRegistryBuildResultScript = _canonical_result(
			context,
			"Scalar tampering '%s'" % String(scalar_field),
		)
		if not scalar_result.succeeded():
			continue
		var scalar_registry: ContentRegistryScript = scalar_result.registry()
		_tamper_progression_scalar(scalar_registry, scalar_field)
		_expect_tampering_rejected(
			context,
			scalar_registry,
			scalar_result,
			"progression scalar '%s'" % String(scalar_field),
		)

	var mainline_order_result: ContentRegistryBuildResultScript = _canonical_result(
		context, "Mainline-order tampering"
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
		context, "Optional-order tampering"
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
		context, "Mainline-dictionary tampering"
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
		context, "Optional-dictionary tampering"
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
		context, "Mainline-script tampering"
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
			"mainline script",
		)

	var optional_script_result: ContentRegistryBuildResultScript = _canonical_result(
		context, "Optional-script tampering"
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
			"optional script",
		)

	var blueprint_cross_result: ContentRegistryBuildResultScript = _canonical_result(
		context, "Blueprint-to-progression cross-domain tampering"
	)
	if blueprint_cross_result.succeeded():
		var blueprint_cross_registry: ContentRegistryScript = blueprint_cross_result.registry()
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
			"Cross-domain progression failure must be structured.",
		)
		_expect_tampering_rejected(
			context,
			blueprint_cross_registry,
			blueprint_cross_result,
			"blueprint-to-progression cross-domain state",
		)

	var progression_cross_result: ContentRegistryBuildResultScript = _canonical_result(
		context, "Progression-to-blueprint cross-domain tampering"
	)
	if progression_cross_result.succeeded():
		var progression_cross_registry: ContentRegistryScript = (
			progression_cross_result.registry()
		)
		progression_cross_registry._mainline_progression_by_id[
			&"progression.main.chapter.01"
		].attack_increase = 999
		var blueprint_query = progression_cross_registry.lookup_blueprint(&"blueprint.01")
		context.expect_true(
			not blueprint_query.succeeded(),
			"Progression tampering must disable blueprint queries through the shared seal.",
		)
		context.expect_equal(
			blueprint_query.issue().code(),
			ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
			"Cross-domain blueprint failure must be structured.",
		)
		_expect_tampering_rejected(
			context,
			progression_cross_registry,
			progression_cross_result,
			"progression-to-blueprint cross-domain state",
		)


func _rebuilds_deterministically(context: HeadlessTestContextScript) -> void:
	var first: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build_canonical()
	var second: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build_canonical()
	context.expect_true(
		first.succeeded(),
		"The first canonical H-3 build must succeed. %s" % _diagnostics(first),
	)
	context.expect_true(
		second.succeeded(),
		"The second canonical H-3 build must succeed. %s" % _diagnostics(second),
	)
	if not first.succeeded() or not second.succeeded():
		return
	context.expect_true(
		first.registry() != second.registry(),
		"Repeated H-3 builds must create isolated registry instances.",
	)
	var first_catalog: GlobalProgressionCatalogScript = (
		first.registry().global_progression_catalog()
	)
	var second_catalog: GlobalProgressionCatalogScript = (
		second.registry().global_progression_catalog()
	)
	context.expect_true(
		first_catalog != second_catalog,
		"Repeated H-3 builds must expose distinct catalog snapshots.",
	)
	context.expect_true(
		first_catalog.is_equal_to(second_catalog),
		"Repeated H-3 builds must expose value-equal catalog snapshots.",
	)
	context.expect_true(
		first_catalog.mainline_progression[0] != second_catalog.mainline_progression[0],
		"Repeated H-3 builds must isolate nested mainline Resources.",
	)
	context.expect_true(
		first_catalog.optional_progression[0] != second_catalog.optional_progression[0],
		"Repeated H-3 builds must isolate nested optional Resources.",
	)
	context.expect_equal(
		first.registry().mainline_progression_ids(),
		second.registry().mainline_progression_ids(),
		"Repeated H-3 builds must preserve mainline order.",
	)
	context.expect_equal(
		first.registry().optional_progression_ids(),
		second.registry().optional_progression_ids(),
		"Repeated H-3 builds must preserve optional order.",
	)
	context.expect_equal(
		first.validation_report().signatures(),
		second.validation_report().signatures(),
		"Repeated H-3 validation must return identical reports.",
	)


func _manifest_from_registry(registry: ContentRegistryScript) -> ContentManifestScript:
	var manifest := ContentManifestScript.new()
	manifest.schema_version = registry.schema_version()
	manifest.content_version = registry.content_version()
	manifest.blueprints = registry.blueprints()
	manifest.recipes = registry.recipes()
	manifest.global_progression_catalog = registry.global_progression_catalog()
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
		"%s needs canonical H-3 input. %s" % [fixture_name, _diagnostics(result)],
	)
	return result


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
		"%s must retain its requested result kind." % fixture_name,
	)
	_expect_failed_query_payloads_null(context, query, fixture_name)
	var issue: ContentValidationIssueScript = query.issue()
	context.expect_true(issue != null, "%s must expose a structured issue." % fixture_name)
	if issue == null:
		return
	context.expect_equal(
		issue.code(),
		ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
		"%s must expose the uninitialized-registry code." % fixture_name,
	)
	context.expect_equal(
		issue.content_id(),
		expected_subject,
		"%s must retain its requested subject." % fixture_name,
	)
	context.expect_equal(
		issue.field_path(),
		"registry",
		"%s must identify the registry path." % fixture_name,
	)


func _expect_failed_query_payloads_null(
	context: HeadlessTestContextScript,
	query: GlobalProgressionQueryResultScript,
	fixture_name: String,
) -> void:
	context.expect_equal(
		query.player_stats(),
		null,
		"%s must not expose a player-stats payload." % fixture_name,
	)
	context.expect_equal(
		query.mainline_progression(),
		null,
		"%s must not expose a mainline payload." % fixture_name,
	)
	context.expect_equal(
		query.optional_progression(),
		null,
		"%s must not expose an optional payload." % fixture_name,
	)


func _tamper_progression_scalar(
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
		&"mainline.maximum_health_increase":
			mainline.maximum_health_increase = 999
		&"mainline.attack_increase":
			mainline.attack_increase = 999
		&"mainline.defense_increase":
			mainline.defense_increase = 999
		&"mainline.speed_increase":
			mainline.speed_increase = 999
		&"optional.content_id":
			optional.content_id = &"progression.optional.tampered"
		&"optional.optional_map_id":
			optional.optional_map_id = &"M99"
		&"optional.available_after_chapter":
			optional.available_after_chapter = 99
		&"optional.maximum_health_increase":
			optional.maximum_health_increase = 999
		&"optional.attack_increase":
			optional.attack_increase = 999
		&"optional.defense_increase":
			optional.defense_increase = 999
		&"optional.speed_increase":
			optional.speed_increase = 999


func _expect_tampering_rejected(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	result: ContentRegistryBuildResultScript,
	tampered_surface: String,
) -> void:
	context.expect_true(
		not registry.is_initialized(),
		"Tampered %s must invalidate the complete registry seal." % tampered_surface,
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
	var progression_query: GlobalProgressionQueryResultScript = (
		registry.initial_player_stats()
	)
	context.expect_true(
		not progression_query.succeeded(),
		"Tampered %s must fail closed for progression queries." % tampered_surface,
	)
	_expect_failed_query_payloads_null(
		context,
		progression_query,
		"Tampered %s progression query" % tampered_surface,
	)
	var progression_issue: ContentValidationIssueScript = progression_query.issue()
	context.expect_true(
		progression_issue != null,
		"Tampered %s progression query must expose an issue." % tampered_surface,
	)
	if progression_issue != null:
		context.expect_equal(
			progression_issue.code(),
			ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
			"Tampered %s progression query must use the uninitialized code."
			% tampered_surface,
		)
		context.expect_equal(
			progression_issue.content_id(),
			&"progression.player.loer",
			"Tampered %s progression query must retain its subject."
			% tampered_surface,
		)
		context.expect_equal(
			progression_issue.field_path(),
			"registry",
			"Tampered %s progression query must identify the registry path."
			% tampered_surface,
		)

	var blueprint_query = registry.lookup_blueprint(&"blueprint.01")
	context.expect_true(
		not blueprint_query.succeeded(),
		"Tampered %s must fail closed for blueprint queries." % tampered_surface,
	)
	context.expect_equal(
		blueprint_query.blueprint(),
		null,
		"Tampered %s must not expose a blueprint payload." % tampered_surface,
	)
	context.expect_equal(
		blueprint_query.recipe(),
		null,
		"Tampered %s must not expose a recipe payload." % tampered_surface,
	)
	var blueprint_issue: ContentValidationIssueScript = blueprint_query.issue()
	context.expect_true(
		blueprint_issue != null,
		"Tampered %s blueprint query must expose an issue." % tampered_surface,
	)
	if blueprint_issue != null:
		context.expect_equal(
			blueprint_issue.code(),
			ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
			"Tampered %s blueprint query must use the uninitialized code."
			% tampered_surface,
		)
		context.expect_equal(
			blueprint_issue.content_id(),
			&"blueprint.01",
			"Tampered %s blueprint query must retain its subject." % tampered_surface,
		)
		context.expect_equal(
			blueprint_issue.field_path(),
			"registry",
			"Tampered %s blueprint query must identify the registry path."
			% tampered_surface,
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
	_expect_issue_tuple(
		context,
		result,
		code,
		content_id,
		field_path,
		fixture_name,
	)


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


func _issue_field_paths(
	result: ContentRegistryBuildResultScript,
	code: StringName,
) -> Array[String]:
	var paths: Array[String] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		if issue.code() == code:
			paths.append(issue.field_path())
	return paths


func _diagnostics(result: ContentRegistryBuildResultScript) -> String:
	return "validation_signatures=%s" % str(result.validation_report().signatures())


func _expected_mainline_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: GlobalProgressionCatalogOracle.MainlineRow in (
		GlobalProgressionCatalogOracle.mainline_rows()
	):
		ids.append(row.content_id)
	return ids


func _expected_optional_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: GlobalProgressionCatalogOracle.OptionalRow in (
		GlobalProgressionCatalogOracle.optional_rows()
	):
		ids.append(row.content_id)
	return ids


func _profile_values(profile: PlayerStatProfileScript) -> Array[int]:
	if profile == null:
		return []
	return [profile.maximum_health, profile.attack, profile.defense, profile.speed]


func _mainline_delta(
	definition: MainlineProgressionDefinitionScript,
) -> Array[int]:
	return [
		definition.maximum_health_increase,
		definition.attack_increase,
		definition.defense_increase,
		definition.speed_increase,
	]


func _optional_delta(
	definition: OptionalProgressionDefinitionScript,
) -> Array[int]:
	return [
		definition.maximum_health_increase,
		definition.attack_increase,
		definition.defense_increase,
		definition.speed_increase,
	]


func _increment_nonzero_counts(counts: Array[int], delta: Array[int]) -> void:
	for index: int in range(delta.size()):
		if delta[index] != 0:
			counts[index] += 1


func _mainline_totals(
	definitions: Array[MainlineProgressionDefinitionScript],
) -> Array[int]:
	var totals: Array[int] = [0, 0, 0, 0]
	for definition: MainlineProgressionDefinitionScript in definitions:
		var delta: Array[int] = _mainline_delta(definition)
		for index: int in range(delta.size()):
			totals[index] += delta[index]
	return totals


func _optional_totals(
	definitions: Array[OptionalProgressionDefinitionScript],
) -> Array[int]:
	var totals: Array[int] = [0, 0, 0, 0]
	for definition: OptionalProgressionDefinitionScript in definitions:
		var delta: Array[int] = _optional_delta(definition)
		for index: int in range(delta.size()):
			totals[index] += delta[index]
	return totals


func _corrupt_for_ordering(catalog: GlobalProgressionCatalogScript) -> void:
	catalog.catalog_id = &"progression.invalid"
	catalog.initial_stats.attack = 99
	catalog.mainline_progression[0].chapter = 9
	catalog.optional_progression[0].optional_map_id = &"M04"
	catalog.optional_progression[0].speed_increase = 1
