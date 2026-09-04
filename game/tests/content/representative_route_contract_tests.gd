extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const ContentManifestScript := preload(
	"res://src/content/definitions/content_manifest_resource.gd"
)
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const RepresentativeRouteContractScript := preload(
	"res://src/content/definitions/representative_route_contract_resource.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContentRegistryBuildResultScript := preload(
	"res://src/content/content_registry_build_result.gd"
)
const ContentContractFingerprintScript := preload(
	"res://src/content/content_contract_fingerprint.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const RepresentativeRouteQueryResultScript := preload(
	"res://src/content/representative_route_query_result.gd"
)
const ContentCatalogOracle := preload(
	"res://tests/content/content_catalog_oracle.gd"
)
const RepresentativeRouteContractOracle := preload(
	"res://tests/content/representative_route_contract_oracle.gd"
)
const DerivedRouteContractScript := preload(
	"res://tests/content/support/derived_representative_route_contract_resource.gd"
)
const DerivedRouteCatalogScript := preload(
	"res://tests/content/support/derived_representative_route_contract_catalog_resource.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"representative_routes.builds_canonical_v5_catalog",
			_builds_canonical_v5_catalog,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.matches_independent_literal_oracle",
			_matches_independent_literal_oracle,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.covers_chapters_exactly_once",
			_covers_chapters_exactly_once,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.rejects_catalog_headers_and_scripts",
			_rejects_catalog_headers_and_scripts,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.rejects_identity_and_stage_regressions",
			_rejects_identity_and_stage_regressions,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.rejects_cross_domain_regressions",
			_rejects_cross_domain_regressions,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.rejects_threshold_matrix",
			_rejects_threshold_matrix,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.reports_structured_queries",
			_reports_structured_queries,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.orders_success_deterministically",
			_orders_success_deterministically,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.orders_errors_deterministically",
			_orders_errors_deterministically,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.isolates_inputs_and_query_snapshots",
			_isolates_inputs_and_query_snapshots,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.invalidates_tampered_shared_registry",
			_invalidates_tampered_shared_registry,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.fingerprints_and_rebuilds_deterministically",
			_fingerprints_and_rebuilds_deterministically,
		),
		HeadlessTestCaseScript.new(
			"representative_routes.rejects_v4_without_compatibility",
			_rejects_v4_without_compatibility,
		),
	]


func _builds_canonical_v5_catalog(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Canonical representative-route catalog",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	context.expect_equal(registry.schema_version(), 5, "Schema version must be v5.")
	context.expect_equal(registry.content_version(), 5, "Content version must be v5.")
	context.expect_equal(
		registry.representative_route_contract_count(),
		5,
		"Exactly five stage contracts must be registered.",
	)
	context.expect_equal(
		registry.representative_route_contract_ids(),
		_expected_contract_ids(),
		"Contract IDs must use stable lexical order.",
	)
	var catalog: RepresentativeRouteCatalogScript = (
		registry.representative_route_contract_catalog()
	)
	context.expect_true(catalog != null, "A defensive route catalog must be exposed.")
	if catalog == null:
		return
	context.expect_equal(
		catalog.catalog_id,
		&"route.contract.catalog.main",
		"The route catalog ID must be frozen.",
	)
	context.expect_equal(catalog.contracts.size(), 5, "Catalog must retain five contracts.")


func _matches_independent_literal_oracle(
	context: HeadlessTestContextScript,
) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Literal route oracle",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var rows: Array = RepresentativeRouteContractOracle.rows()
	var expected_blueprint_counts: Array[int] = [8, 14, 20, 24, 24]
	for index: int in range(rows.size()):
		var row = rows[index]
		var query: RepresentativeRouteQueryResultScript = (
			registry.lookup_representative_route_contract(row.contract_id)
		)
		context.expect_true(query.succeeded(), "%s must resolve." % row.contract_id)
		if not query.succeeded():
			continue
		var contract: RepresentativeRouteContractScript = query.contract()
		context.expect_equal(contract.stage_start_chapter, row.stage_start_chapter, "Stage start.")
		context.expect_equal(contract.stage_end_chapter, row.stage_end_chapter, "Stage end.")
		context.expect_equal(contract.player_profile_id, RepresentativeRouteContractOracle.PLAYER_PROFILE_ID, "Player profile reference.")
		context.expect_equal(
			contract.mainline_progression_reference_ids,
			RepresentativeRouteContractOracle.mainline_progression_ids_through(
				row.stage_end_chapter
			),
			"Progression references must be cumulative through the stage end.",
		)
		var expected_blueprint_ids: Array[StringName] = _blueprint_ids_through(
			row.stage_end_chapter
		)
		context.expect_equal(
			contract.available_blueprint_reference_ids,
			expected_blueprint_ids,
			"Blueprint references must be derived from the independent blueprint oracle.",
		)
		context.expect_equal(
			expected_blueprint_ids.size(),
			expected_blueprint_counts[index],
			"Stage blueprint count must be frozen.",
		)
		context.expect_equal(query.stage_end_available_blueprint_ids(), expected_blueprint_ids, "Query stage-end blueprint IDs.")
		context.expect_equal(_profile_values(query.stage_end_minimum_player_stats()), row.minimum_player_stats, "Derived stage-end minimum mainline stats.")
		context.expect_equal(contract.backpack_slot_capacity, row.backpack_slot_capacity, "Backpack capacity.")
		_expect_common_contract(context, contract, String(row.contract_id))
		for forbidden_field: StringName in [
			&"maximum_health", &"attack", &"defense", &"speed",
		]:
			context.expect_true(
				not _resource_has_property(contract, forbidden_field),
				"Route contracts must reference, not copy, stat field '%s'."
				% String(forbidden_field),
			)


func _covers_chapters_exactly_once(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(context, "Chapter coverage")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var expanded: Array[int] = []
	for contract: RepresentativeRouteContractScript in registry.representative_route_contracts():
		for chapter: int in range(
			contract.stage_start_chapter,
			contract.stage_end_chapter + 1,
		):
			expanded.append(chapter)
	context.expect_equal(expanded, [1, 2, 3, 4, 5, 6, 7, 8, 9], "Chapters 1 through 9 must each appear once.")


func _rejects_catalog_headers_and_scripts(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Header fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var null_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_manifest.representative_route_contract_catalog = null
	_expect_failure_code(context, ContentRegistryBuilderScript.build(null_manifest), ContentValidationIssueScript.MANIFEST_ROUTE_CONTRACT_CATALOG_NULL, "Null catalog")

	var derived_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_catalog := DerivedRouteCatalogScript.new()
	derived_catalog.catalog_id = derived_manifest.representative_route_contract_catalog.catalog_id
	derived_catalog.contracts = derived_manifest.representative_route_contract_catalog.contracts
	derived_manifest.representative_route_contract_catalog = derived_catalog
	_expect_failure_code(context, ContentRegistryBuilderScript.build(derived_manifest), ContentValidationIssueScript.ROUTE_CATALOG_INVALID_SCRIPT, "Derived catalog")

	var catalog_id_manifest: ContentManifestScript = _manifest_from_registry(registry)
	catalog_id_manifest.representative_route_contract_catalog.catalog_id = (
		&"route.contract.catalog.unknown"
	)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(catalog_id_manifest), ContentValidationIssueScript.ROUTE_CATALOG_ID_INVALID, "Wrong catalog ID")

	var oversized_manifest: ContentManifestScript = _manifest_from_registry(registry)
	oversized_manifest.representative_route_contract_catalog.contracts.resize(4096)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(oversized_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_COUNT_INVALID, "Oversized catalog")

	var undersized_manifest: ContentManifestScript = _manifest_from_registry(registry)
	undersized_manifest.representative_route_contract_catalog.contracts.resize(4)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(undersized_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_COUNT_INVALID, "Undersized catalog")

	var null_entry_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_entry_manifest.representative_route_contract_catalog.contracts[0] = null
	_expect_failure_code(context, ContentRegistryBuilderScript.build(null_entry_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ENTRY_NULL, "Null contract")

	var derived_entry_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var source: RepresentativeRouteContractScript = derived_entry_manifest.representative_route_contract_catalog.contracts[0]
	var derived_contract := DerivedRouteContractScript.new()
	_copy_contract_fields(derived_contract, source)
	derived_entry_manifest.representative_route_contract_catalog.contracts[0] = derived_contract
	_expect_failure_code(context, ContentRegistryBuilderScript.build(derived_entry_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ENTRY_INVALID_SCRIPT, "Derived contract")


func _rejects_identity_and_stage_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Identity fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var empty_id_manifest: ContentManifestScript = _manifest_from_registry(registry)
	empty_id_manifest.representative_route_contract_catalog.contracts[0].contract_id = &""
	_expect_failure_code(context, ContentRegistryBuilderScript.build(empty_id_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ID_EMPTY, "Empty contract ID")

	var unknown_id_manifest: ContentManifestScript = _manifest_from_registry(registry)
	unknown_id_manifest.representative_route_contract_catalog.contracts[0].contract_id = (
		&"route.contract.main.stage.unknown"
	)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_id_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ID_INVALID, "Unknown contract ID")

	var duplicate_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_manifest.representative_route_contract_catalog.contracts[1].contract_id = (
		duplicate_manifest.representative_route_contract_catalog.contracts[0].contract_id
	)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(duplicate_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ID_DUPLICATE, "Duplicate ID")

	var swapped_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var first_id: StringName = swapped_manifest.representative_route_contract_catalog.contracts[0].contract_id
	swapped_manifest.representative_route_contract_catalog.contracts[0].contract_id = swapped_manifest.representative_route_contract_catalog.contracts[1].contract_id
	swapped_manifest.representative_route_contract_catalog.contracts[1].contract_id = first_id
	_expect_failure_code(context, ContentRegistryBuilderScript.build(swapped_manifest), ContentValidationIssueScript.ROUTE_CONTRACT_ID_STAGE_MISMATCH, "ID-stage swap")

	var gap_manifest: ContentManifestScript = _manifest_from_registry(registry)
	gap_manifest.representative_route_contract_catalog.contracts[1].stage_start_chapter = 4
	_expect_failure_code(context, ContentRegistryBuilderScript.build(gap_manifest), ContentValidationIssueScript.ROUTE_CHAPTER_COVERAGE_INVALID, "Coverage gap")

	var overlap_manifest: ContentManifestScript = _manifest_from_registry(registry)
	overlap_manifest.representative_route_contract_catalog.contracts[1].stage_start_chapter = 2
	_expect_failure_code(context, ContentRegistryBuilderScript.build(overlap_manifest), ContentValidationIssueScript.ROUTE_CHAPTER_COVERAGE_INVALID, "Coverage overlap")

	var invalid_range_manifest: ContentManifestScript = _manifest_from_registry(registry)
	invalid_range_manifest.representative_route_contract_catalog.contracts[0].stage_start_chapter = 3
	invalid_range_manifest.representative_route_contract_catalog.contracts[0].stage_end_chapter = 2
	_expect_failure_code(context, ContentRegistryBuilderScript.build(invalid_range_manifest), ContentValidationIssueScript.ROUTE_STAGE_RANGE_INVALID, "Invalid range")

	var chapter_zero_manifest: ContentManifestScript = _manifest_from_registry(registry)
	chapter_zero_manifest.representative_route_contract_catalog.contracts[0].stage_start_chapter = 0
	_expect_failure_code(context, ContentRegistryBuilderScript.build(chapter_zero_manifest), ContentValidationIssueScript.ROUTE_STAGE_RANGE_INVALID, "Stage starts at chapter zero")

	var chapter_ten_manifest: ContentManifestScript = _manifest_from_registry(registry)
	chapter_ten_manifest.representative_route_contract_catalog.contracts[4].stage_end_chapter = 10
	_expect_failure_code(context, ContentRegistryBuilderScript.build(chapter_ten_manifest), ContentValidationIssueScript.ROUTE_STAGE_RANGE_INVALID, "Stage ends at chapter ten")


func _rejects_cross_domain_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Cross-domain fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	profile_manifest.representative_route_contract_catalog.contracts[0].player_profile_id = &"progression.player.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(profile_manifest), ContentValidationIssueScript.ROUTE_PLAYER_PROFILE_REFERENCE_INVALID, "Wrong profile")

	var progression_manifest: ContentManifestScript = _manifest_from_registry(registry)
	progression_manifest.representative_route_contract_catalog.contracts[0].mainline_progression_reference_ids[1] = &"progression.main.chapter.03"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(progression_manifest), ContentValidationIssueScript.ROUTE_PROGRESSION_REFERENCE_INVALID, "Wrong progression reference")

	var blueprint_manifest: ContentManifestScript = _manifest_from_registry(registry)
	blueprint_manifest.representative_route_contract_catalog.contracts[0].available_blueprint_reference_ids.remove_at(0)
	_expect_failure_code(context, ContentRegistryBuilderScript.build(blueprint_manifest), ContentValidationIssueScript.ROUTE_BLUEPRINT_REFERENCE_INVALID, "Missing blueprint reference")

	var capacity_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var first_capacity: int = capacity_manifest.representative_route_contract_catalog.contracts[0].backpack_slot_capacity
	capacity_manifest.representative_route_contract_catalog.contracts[0].backpack_slot_capacity = capacity_manifest.representative_route_contract_catalog.contracts[1].backpack_slot_capacity
	capacity_manifest.representative_route_contract_catalog.contracts[1].backpack_slot_capacity = first_capacity
	_expect_failure_code(context, ContentRegistryBuilderScript.build(capacity_manifest), ContentValidationIssueScript.ROUTE_BACKPACK_CAPACITY_INVALID, "Capacity multiset swap")


func _rejects_threshold_matrix(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Threshold fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var mutations: Array[Array] = [
		[&"encounter_group_minimum", 9, ContentValidationIssueScript.ROUTE_ENCOUNTER_RANGE_INVALID],
		[&"encounter_group_maximum", 11, ContentValidationIssueScript.ROUTE_ENCOUNTER_RANGE_INVALID],
		[&"encounter_group_hard_cap", 13, ContentValidationIssueScript.ROUTE_ENCOUNTER_RANGE_INVALID],
		[&"low_loss_contact_minimum", 4, ContentValidationIssueScript.ROUTE_CONTACT_RANGE_INVALID],
		[&"low_loss_contact_maximum", 4, ContentValidationIssueScript.ROUTE_CONTACT_RANGE_INVALID],
		[&"intuitive_contact_minimum", 6, ContentValidationIssueScript.ROUTE_CONTACT_RANGE_INVALID],
		[&"intuitive_contact_maximum", 6, ContentValidationIssueScript.ROUTE_CONTACT_RANGE_INVALID],
		[&"low_loss_minimum_exit_health_percent", 39, ContentValidationIssueScript.ROUTE_EXIT_HEALTH_THRESHOLD_INVALID],
		[&"intuitive_minimum_exit_health_percent", 24, ContentValidationIssueScript.ROUTE_EXIT_HEALTH_THRESHOLD_INVALID],
		[&"minimum_fixed_recovery_points", 1, ContentValidationIssueScript.ROUTE_RECOVERY_POINT_COUNT_INVALID],
		[&"fixed_recovery_amount", 49, ContentValidationIssueScript.ROUTE_RECOVERY_POINT_COUNT_INVALID],
		[&"minimum_legal_route_count", 1, ContentValidationIssueScript.ROUTE_LEGAL_ALTERNATIVE_COUNT_INVALID],
		[&"minimum_legal_loadout_count", 1, ContentValidationIssueScript.ROUTE_LEGAL_ALTERNATIVE_COUNT_INVALID],
		[&"minimum_distinct_tradeoff_dimensions", 1, ContentValidationIssueScript.ROUTE_TRADEOFF_DIMENSION_INVALID],
		[&"requires_non_dominated_route_set", false, ContentValidationIssueScript.ROUTE_DOMINANCE_POLICY_INVALID],
	]
	for mutation: Array in mutations:
		var manifest: ContentManifestScript = _manifest_from_registry(registry)
		manifest.representative_route_contract_catalog.contracts[0].set(mutation[0], mutation[1])
		_expect_failure_code(context, ContentRegistryBuilderScript.build(manifest), mutation[2], "Threshold %s" % String(mutation[0]))

	var raw_dimension_mutations: Array[Array] = [
		[&"route.cost.health"],
		[&"route.cost.health", &"route.cost.health", &"route.cost.detour", &"route.cost.block", &"route.cost.consumable", &"route.cost.optional_reward"],
		[&"route.cost.health", &"route.cost.unknown", &"route.cost.detour", &"route.cost.block", &"route.cost.consumable", &"route.cost.optional_reward"],
	]
	for raw_dimensions: Array in raw_dimension_mutations:
		var dimensions: Array[StringName] = []
		for dimension_id: StringName in raw_dimensions:
			dimensions.append(dimension_id)
		var manifest: ContentManifestScript = _manifest_from_registry(registry)
		manifest.representative_route_contract_catalog.contracts[0].tradeoff_dimension_ids = dimensions
		_expect_failure_code(context, ContentRegistryBuilderScript.build(manifest), ContentValidationIssueScript.ROUTE_TRADEOFF_DIMENSION_INVALID, "Tradeoff dimensions")


func _reports_structured_queries(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Query fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var found: RepresentativeRouteQueryResultScript = registry.lookup_representative_route_contract(_expected_contract_ids()[0])
	context.expect_true(found.succeeded(), "Known route ID must succeed.")
	context.expect_true(found.contract() != null, "Known route query must include a contract.")
	context.expect_true(found.stage_end_minimum_player_stats() != null, "Known route query must include derived stage-end stats.")
	context.expect_equal(found.stage_end_available_blueprint_ids().size(), 8, "Known route query must include derived stage-end blueprints.")
	context.expect_equal(found.issue(), null, "Successful route query must not include an issue.")

	var unknown: RepresentativeRouteQueryResultScript = registry.lookup_representative_route_contract(&"route.contract.unknown")
	_expect_query_failure(context, unknown, ContentValidationIssueScript.LOOKUP_UNKNOWN_ROUTE_CONTRACT_ID, &"route.contract.unknown", "Unknown route")
	var raw_registry := ContentRegistryScript.new()
	var uninitialized: RepresentativeRouteQueryResultScript = raw_registry.lookup_representative_route_contract(&"route.contract.main.stage.01_02")
	_expect_query_failure(context, uninitialized, ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED, &"route.contract.main.stage.01_02", "Uninitialized registry")


func _orders_success_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Success ordering")
	if not canonical.succeeded():
		return
	var forward: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var reverse: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_reverse_route_declarations(reverse)
	var forward_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(forward)
	var reverse_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(reverse)
	context.expect_true(forward_result.succeeded(), "Forward declaration must build.")
	context.expect_true(reverse_result.succeeded(), "Reversed declaration must build.")
	if forward_result.succeeded() and reverse_result.succeeded():
		context.expect_equal(reverse_result.registry().representative_route_contract_ids(), forward_result.registry().representative_route_contract_ids(), "Success order must be stable.")
	context.expect_equal(_fingerprint(reverse), _fingerprint(forward), "Set-like declaration order must not affect v5 fingerprint.")


func _orders_errors_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Error ordering")
	if not canonical.succeeded():
		return
	var forward: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var reverse: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_corrupt_for_ordering(forward)
	_corrupt_for_ordering(reverse)
	_reverse_route_declarations(reverse)
	var forward_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(forward)
	var reverse_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(reverse)
	context.expect_true(not forward_result.succeeded(), "Forward corruption must fail.")
	context.expect_true(not reverse_result.succeeded(), "Reverse corruption must fail.")
	context.expect_equal(reverse_result.validation_report().signatures(), forward_result.validation_report().signatures(), "Error signatures must not depend on declaration order.")


func _isolates_inputs_and_query_snapshots(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "Isolation fixtures")
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var source_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var isolated_build: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(source_manifest)
	context.expect_true(isolated_build.succeeded(), "Isolation source must build.")
	if not isolated_build.succeeded():
		return
	var isolated_registry: ContentRegistryScript = isolated_build.registry()
	source_manifest.representative_route_contract_catalog.contracts[0].backpack_slot_capacity = 999
	context.expect_equal(isolated_registry.representative_route_contracts()[0].backpack_slot_capacity, 12, "Input mutation must not alter registry.")

	var returned_contracts: Array[RepresentativeRouteContractScript] = isolated_registry.representative_route_contracts()
	returned_contracts[0].backpack_slot_capacity = 998
	returned_contracts.clear()
	context.expect_equal(isolated_registry.representative_route_contracts()[0].backpack_slot_capacity, 12, "Returned list and contract must be defensive.")

	var query: RepresentativeRouteQueryResultScript = isolated_registry.lookup_representative_route_contract(_expected_contract_ids()[0])
	var first_contract: RepresentativeRouteContractScript = query.contract()
	first_contract.available_blueprint_reference_ids.clear()
	query.stage_end_minimum_player_stats().attack = 999
	var blueprints: Array[BlueprintDefinitionScript] = query.stage_end_available_blueprints()
	blueprints[0].content_id = &"blueprint.tampered"
	context.expect_equal(query.contract().available_blueprint_reference_ids.size(), 8, "Query contract getter must deep-copy.")
	context.expect_equal(query.stage_end_minimum_player_stats().attack, 11, "Query stage-end stats getter must deep-copy.")
	context.expect_equal(query.stage_end_available_blueprint_ids()[0], &"blueprint.01", "Query stage-end blueprint getter must deep-copy.")

	var cached_resource: Resource = ResourceLoader.load(
		ContentRegistryBuilderScript.CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_REUSE,
	)
	context.expect_true(cached_resource != null, "Route cache-isolation fixture must load.")
	if cached_resource != null and cached_resource.get_script() == ContentManifestScript:
		var cached_manifest: ContentManifestScript = cached_resource as ContentManifestScript
		cached_manifest.representative_route_contract_catalog.contracts[0].backpack_slot_capacity = 997
		var fresh_result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build_canonical()
		context.expect_true(fresh_result.succeeded(), "Canonical build must ignore a mutated ResourceLoader cache graph.")
		if fresh_result.succeeded():
			context.expect_equal(fresh_result.registry().representative_route_contracts()[0].backpack_slot_capacity, 12, "Fresh canonical build must retain the disk-backed route contract.")


func _invalidates_tampered_shared_registry(context: HeadlessTestContextScript) -> void:
	var route_result: ContentRegistryBuildResultScript = _canonical_result(context, "Route tamper")
	if not route_result.succeeded():
		return
	var route_registry: ContentRegistryScript = route_result.registry()
	route_registry._representative_route_contracts[0].backpack_slot_capacity = 999
	context.expect_true(not route_registry.is_initialized(), "Route tampering must invalidate the shared registry.")
	context.expect_true(not route_result.succeeded(), "Tampered build result must stop publishing the registry.")
	context.expect_equal(route_result.registry(), null, "Tampered build result must return no partial registry.")
	_expect_query_failure(
		context,
		route_registry.lookup_representative_route_contract(_expected_contract_ids()[0]),
		ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED,
		_expected_contract_ids()[0],
		"Route tamper lookup",
	)
	context.expect_true(not route_registry.lookup_blueprint(&"blueprint.01").succeeded(), "Route tamper must close blueprint queries too.")
	context.expect_true(not route_registry.lookup_recipe(&"recipe.standard.01").succeeded(), "Route tamper must close recipe queries too.")
	context.expect_true(not route_registry.initial_player_stats().succeeded(), "Route tamper must close progression queries too.")

	var blueprint_result: ContentRegistryBuildResultScript = _canonical_result(context, "Cross-domain tamper")
	if not blueprint_result.succeeded():
		return
	var blueprint_registry: ContentRegistryScript = blueprint_result.registry()
	blueprint_registry._blueprints_by_id[&"blueprint.01"].unlock_chapter = 9
	context.expect_true(not blueprint_registry.is_initialized(), "Blueprint tampering must invalidate the shared registry.")
	_expect_query_failure(
		context,
		blueprint_registry.lookup_representative_route_contract(_expected_contract_ids()[0]),
		ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED,
		_expected_contract_ids()[0],
		"Blueprint tamper route lookup",
	)

	var progression_result: ContentRegistryBuildResultScript = _canonical_result(context, "Progression tamper")
	if not progression_result.succeeded():
		return
	var progression_registry: ContentRegistryScript = progression_result.registry()
	progression_registry._initial_player_stats.attack = 999
	context.expect_true(not progression_registry.is_initialized(), "Progression tampering must invalidate the shared registry.")
	_expect_query_failure(
		context,
		progression_registry.lookup_representative_route_contract(_expected_contract_ids()[0]),
		ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED,
		_expected_contract_ids()[0],
		"Progression tamper route lookup",
	)

	var recipe_result: ContentRegistryBuildResultScript = _canonical_result(context, "Recipe tamper")
	if not recipe_result.succeeded():
		return
	var recipe_registry: ContentRegistryScript = recipe_result.registry()
	recipe_registry._recipes_by_id[&"recipe.standard.01"].main_quantity = 999
	context.expect_true(not recipe_registry.is_initialized(), "Recipe tampering must invalidate the shared registry.")
	_expect_query_failure(
		context,
		recipe_registry.lookup_representative_route_contract(_expected_contract_ids()[0]),
		ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED,
		_expected_contract_ids()[0],
		"Recipe tamper route lookup",
	)


func _fingerprints_and_rebuilds_deterministically(
	context: HeadlessTestContextScript,
) -> void:
	var first: ContentRegistryBuildResultScript = _canonical_result(context, "First fingerprint build")
	var second: ContentRegistryBuildResultScript = _canonical_result(context, "Second fingerprint build")
	if not first.succeeded() or not second.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(first.registry())
	var fingerprint: String = _fingerprint(manifest)
	context.expect_equal(fingerprint, RepresentativeRouteContractOracle.FROZEN_V5_FINGERPRINT, "v5 digest must match independent route oracle.")
	context.expect_equal(ContentContractFingerprintScript.EXPECTED_FINGERPRINT, RepresentativeRouteContractOracle.FROZEN_V5_FINGERPRINT, "Production seal must match independent route oracle.")
	context.expect_equal(fingerprint.length(), 64, "v5 seal must be a SHA-256 digest.")
	context.expect_true(first.registry() != second.registry(), "Repeated builds must isolate Registry identity.")
	context.expect_true(first.registry().representative_route_contract_catalog().is_equal_to(second.registry().representative_route_contract_catalog()), "Repeated builds must be value-equal.")
	context.expect_true(first.registry().representative_route_contracts()[0] != second.registry().representative_route_contracts()[0], "Repeated builds must isolate route Resource identity.")

	var catalog_id_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	catalog_id_tamper.representative_route_contract_catalog.catalog_id = (
		&"route.contract.catalog.tampered"
	)
	context.expect_true(
		_fingerprint(catalog_id_tamper) != fingerprint,
		"Seal must cover the route catalog ID.",
	)

	var scalar_mutations: Array[Array] = [
		[&"contract_id", &"route.contract.main.stage.tampered"],
		[&"stage_start_chapter", 2],
		[&"stage_end_chapter", 3],
		[&"player_profile_id", &"progression.player.tampered"],
		[&"backpack_slot_capacity", 13],
		[&"encounter_group_minimum", 9],
		[&"encounter_group_maximum", 11],
		[&"encounter_group_hard_cap", 13],
		[&"low_loss_contact_minimum", 4],
		[&"low_loss_contact_maximum", 4],
		[&"intuitive_contact_minimum", 6],
		[&"intuitive_contact_maximum", 6],
		[&"low_loss_minimum_exit_health_percent", 39],
		[&"intuitive_minimum_exit_health_percent", 24],
		[&"minimum_fixed_recovery_points", 1],
		[&"fixed_recovery_amount", 49],
		[&"minimum_legal_route_count", 1],
		[&"minimum_legal_loadout_count", 1],
		[&"minimum_distinct_tradeoff_dimensions", 1],
		[&"requires_non_dominated_route_set", false],
	]
	for mutation: Array in scalar_mutations:
		var scalar_tamper: ContentManifestScript = _manifest_from_registry(
			first.registry()
		)
		scalar_tamper.representative_route_contract_catalog.contracts[0].set(
			mutation[0],
			mutation[1],
		)
		context.expect_true(
			_fingerprint(scalar_tamper) != fingerprint,
			"Seal must cover route field '%s'." % String(mutation[0]),
		)

	var progression_reference_tamper: ContentManifestScript = _manifest_from_registry(
		first.registry()
	)
	progression_reference_tamper.representative_route_contract_catalog.contracts[0].mainline_progression_reference_ids[0] = &"progression.main.chapter.09"
	context.expect_true(
		_fingerprint(progression_reference_tamper) != fingerprint,
		"Seal must cover mainline progression references.",
	)

	var blueprint_reference_tamper: ContentManifestScript = _manifest_from_registry(
		first.registry()
	)
	blueprint_reference_tamper.representative_route_contract_catalog.contracts[0].available_blueprint_reference_ids[0] = &"blueprint.24"
	context.expect_true(
		_fingerprint(blueprint_reference_tamper) != fingerprint,
		"Seal must cover available blueprint references.",
	)

	var tradeoff_tamper: ContentManifestScript = _manifest_from_registry(first.registry())
	tradeoff_tamper.representative_route_contract_catalog.contracts[0].tradeoff_dimension_ids[0] = &"route.cost.unknown"
	context.expect_true(
		_fingerprint(tradeoff_tamper) != fingerprint,
		"Seal must cover tradeoff dimensions.",
	)


func _rejects_v4_without_compatibility(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(context, "v4 rejection")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.schema_version = 4
	manifest.content_version = 4
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "v4 manifest must fail closed.")
	context.expect_equal(result.registry(), null, "No v4 compatibility Registry may be returned.")
	var codes: Array[StringName] = _issue_codes(result)
	context.expect_true(codes.has(ContentValidationIssueScript.MANIFEST_SCHEMA_VERSION_UNSUPPORTED), "v4 schema must be rejected.")
	context.expect_true(codes.has(ContentValidationIssueScript.MANIFEST_CONTENT_VERSION_UNSUPPORTED), "v4 content must be rejected.")
	context.expect_true(
		not ContentContractFingerprintScript.matches(
			manifest.schema_version,
			manifest.content_version,
			manifest.blueprints,
			manifest.recipes,
			manifest.global_progression_catalog,
			manifest.representative_route_contract_catalog,
			manifest.enemy_profile_catalog,
		),
		"v4 header must not match the v5 seal.",
	)


func _expect_common_contract(
	context: HeadlessTestContextScript,
	contract: RepresentativeRouteContractScript,
	label: String,
) -> void:
	context.expect_equal([contract.encounter_group_minimum, contract.encounter_group_maximum, contract.encounter_group_hard_cap], [8, 12, 14], "%s encounter thresholds." % label)
	context.expect_equal([contract.low_loss_contact_minimum, contract.low_loss_contact_maximum], [3, 5], "%s low-loss contacts." % label)
	context.expect_equal([contract.intuitive_contact_minimum, contract.intuitive_contact_maximum], [5, 7], "%s intuitive contacts." % label)
	context.expect_equal(contract.low_loss_minimum_exit_health_percent, 40, "%s low-loss exit health." % label)
	context.expect_equal(contract.intuitive_minimum_exit_health_percent, 25, "%s intuitive exit health." % label)
	context.expect_equal(contract.minimum_fixed_recovery_points, 2, "%s recovery-point count." % label)
	context.expect_equal(contract.fixed_recovery_amount, 50, "%s fixed recovery amount." % label)
	context.expect_equal(contract.minimum_legal_route_count, 2, "%s legal routes." % label)
	context.expect_equal(contract.minimum_legal_loadout_count, 2, "%s legal loadouts." % label)
	context.expect_equal(contract.tradeoff_dimension_ids, RepresentativeRouteContractOracle.TRADEOFF_DIMENSION_IDS, "%s tradeoff dimensions." % label)
	context.expect_equal(contract.minimum_distinct_tradeoff_dimensions, 2, "%s minimum tradeoff dimensions." % label)
	context.expect_true(contract.requires_non_dominated_route_set, "%s must prohibit a globally dominant route." % label)


func _canonical_result(
	context: HeadlessTestContextScript,
	fixture_name: String,
) -> ContentRegistryBuildResultScript:
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build_canonical()
	context.expect_true(result.succeeded(), "%s needs canonical input. %s" % [fixture_name, _diagnostics(result)])
	return result


func _manifest_from_registry(registry: ContentRegistryScript) -> ContentManifestScript:
	var manifest := ContentManifestScript.new()
	manifest.schema_version = registry.schema_version()
	manifest.content_version = registry.content_version()
	manifest.blueprints = registry.blueprints()
	manifest.recipes = registry.recipes()
	manifest.global_progression_catalog = registry.global_progression_catalog()
	manifest.representative_route_contract_catalog = registry.representative_route_contract_catalog()
	manifest.enemy_profile_catalog = registry.enemy_profile_catalog()
	return manifest


func _expected_contract_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for row in RepresentativeRouteContractOracle.rows():
		result.append(row.contract_id)
	result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


func _blueprint_ids_through(chapter: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for row in ContentCatalogOracle.blueprint_rows():
		if row.unlock_chapter <= chapter:
			result.append(row.content_id)
	result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


func _profile_values(profile) -> Array[int]:
	if profile == null:
		return []
	return [profile.maximum_health, profile.attack, profile.defense, profile.speed]


func _expect_failure_code(
	context: HeadlessTestContextScript,
	result: ContentRegistryBuildResultScript,
	code: StringName,
	label: String,
) -> void:
	context.expect_true(not result.succeeded(), "%s must fail." % label)
	context.expect_equal(result.registry(), null, "%s must publish no partial Registry." % label)
	context.expect_true(_issue_codes(result).has(code), "%s must report code '%s'. Got %s" % [label, String(code), str(_issue_codes(result))])


func _expect_query_failure(
	context: HeadlessTestContextScript,
	query: RepresentativeRouteQueryResultScript,
	code: StringName,
	content_id: StringName,
	label: String,
) -> void:
	context.expect_true(not query.succeeded(), "%s must fail." % label)
	context.expect_equal(query.contract(), null, "%s must expose no contract." % label)
	context.expect_equal(query.stage_end_minimum_player_stats(), null, "%s must expose no stats." % label)
	context.expect_equal(query.stage_end_available_blueprints(), [], "%s must expose no blueprints." % label)
	var issue: ContentValidationIssueScript = query.issue()
	context.expect_true(issue != null, "%s must expose an issue." % label)
	if issue != null:
		context.expect_equal(issue.code(), code, "%s issue code." % label)
		context.expect_equal(issue.content_id(), content_id, "%s issue subject." % label)


func _issue_codes(result: ContentRegistryBuildResultScript) -> Array[StringName]:
	var result_codes: Array[StringName] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		result_codes.append(issue.code())
	return result_codes


func _copy_contract_fields(target, source: RepresentativeRouteContractScript) -> void:
	for property: Dictionary in source.get_property_list():
		var property_name: StringName = property.get("name", &"")
		if property_name in [
			&"resource_local_to_scene", &"resource_path", &"resource_name", &"resource_scene_unique_id", &"script",
		]:
			continue
		if target.get(property_name) != null or source.get(property_name) != null:
			target.set(property_name, source.get(property_name))


func _reverse_route_declarations(manifest: ContentManifestScript) -> void:
	manifest.representative_route_contract_catalog.contracts.reverse()
	for contract: RepresentativeRouteContractScript in manifest.representative_route_contract_catalog.contracts:
		contract.mainline_progression_reference_ids.reverse()
		contract.available_blueprint_reference_ids.reverse()
		contract.tradeoff_dimension_ids.reverse()


func _corrupt_for_ordering(manifest: ContentManifestScript) -> void:
	var contract: RepresentativeRouteContractScript = _find_contract(
		manifest.representative_route_contract_catalog,
		&"route.contract.main.stage.01_02",
	)
	contract.backpack_slot_capacity = 99
	contract.mainline_progression_reference_ids[0] = &"progression.main.chapter.09"
	contract.tradeoff_dimension_ids[0] = &"route.cost.unknown"


func _find_contract(
	catalog: RepresentativeRouteCatalogScript,
	contract_id: StringName,
) -> RepresentativeRouteContractScript:
	for contract: RepresentativeRouteContractScript in catalog.contracts:
		if contract != null and contract.contract_id == contract_id:
			return contract
	return null


func _fingerprint(manifest: ContentManifestScript) -> String:
	return ContentContractFingerprintScript.calculate(
		manifest.schema_version,
		manifest.content_version,
		manifest.blueprints,
		manifest.recipes,
		manifest.global_progression_catalog,
		manifest.representative_route_contract_catalog,
		manifest.enemy_profile_catalog,
	)


func _resource_has_property(resource: Resource, property_name: StringName) -> bool:
	for property: Dictionary in resource.get_property_list():
		if StringName(property.get("name", &"")) == property_name:
			return true
	return false


func _diagnostics(result: ContentRegistryBuildResultScript) -> String:
	if result == null:
		return "Build result is null."
	return "issues=%s" % str(result.validation_report().signatures())
