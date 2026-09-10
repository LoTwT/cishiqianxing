extends RefCounted

const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const EnemyFamilyDefinitionScript := preload(
	"res://src/content/definitions/enemy_family_definition_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
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
const ContentContractFingerprintScript := preload(
	"res://src/content/content_contract_fingerprint.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const EnemyProfileValidatorScript := preload(
	"res://src/content/enemy_profile_validator.gd"
)
const EnemyProfileQueryResultScript := preload(
	"res://src/content/enemy_profile_query_result.gd"
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
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const EnemyProfileCatalogOracle := preload(
	"res://tests/content/enemy_profile_catalog_oracle.gd"
)
const DerivedEnemyFamilyScript := preload(
	"res://tests/content/support/derived_enemy_family_definition_resource.gd"
)
const DerivedEnemyProfileScript := preload(
	"res://tests/content/support/derived_enemy_profile_definition_resource.gd"
)
const DerivedEnemyCatalogScript := preload(
	"res://tests/content/support/derived_enemy_profile_catalog_resource.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"enemy_profiles.builds_canonical_v6_catalog",
			_builds_canonical_v6_catalog,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.matches_all_literal_fields",
			_matches_all_literal_fields,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.matches_h43_combat_expectations",
			_matches_h43_combat_expectations,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.reports_structured_queries",
			_reports_structured_queries,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.isolates_inputs_queries_and_cache",
			_isolates_inputs_queries_and_cache,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.invalidates_tampered_registry",
			_invalidates_tampered_registry,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.rejects_null_and_polymorphic_resources",
			_rejects_null_and_polymorphic_resources,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.rejects_identity_pair_and_reference_errors",
			_rejects_identity_pair_and_reference_errors,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.rejects_invalid_stat_and_alternate_shapes",
			_rejects_invalid_stat_and_alternate_shapes,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.rejects_balance_boundary_regressions",
			_rejects_balance_boundary_regressions,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.orders_error_signatures_deterministically",
			_orders_error_signatures_deterministically,
		),
		HeadlessTestCaseScript.new(
			"enemy_profiles.fingerprint_covers_fields_and_ignores_set_order",
			_fingerprint_covers_fields_and_ignores_set_order,
		),
	]


func _builds_canonical_v6_catalog(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Canonical enemy-profile catalog",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	context.expect_equal(registry.schema_version(), 6, "Enemy schema must be v6.")
	context.expect_equal(registry.content_version(), 6, "Enemy content must be v6.")
	context.expect_equal(
		registry.enemy_family_count(),
		EnemyProfileCatalogOracle.EXPECTED_FAMILY_COUNT,
		"Exactly twelve enemy families must be registered.",
	)
	context.expect_equal(
		registry.enemy_profile_count(),
		EnemyProfileCatalogOracle.EXPECTED_PROFILE_COUNT,
		"Exactly twenty-four enemy profiles must be registered.",
	)
	context.expect_equal(
		registry.enemy_family_ids(),
		_expected_family_ids(),
		"Enemy family IDs must use stable lexical order.",
	)
	context.expect_equal(
		registry.enemy_profile_ids(),
		_expected_profile_ids(),
		"Enemy profile IDs must use stable lexical order.",
	)

	var catalog: EnemyProfileCatalogScript = registry.enemy_profile_catalog()
	context.expect_true(catalog != null, "Registry must expose an enemy catalog snapshot.")
	if catalog == null:
		return
	context.expect_equal(
		catalog.catalog_id,
		EnemyProfileCatalogOracle.CATALOG_ID,
		"Enemy catalog ID must be frozen.",
	)
	context.expect_equal(catalog.families.size(), 12, "Catalog must retain 12 families.")
	context.expect_equal(catalog.profiles.size(), 24, "Catalog must retain 24 profiles.")

	var family_source_counts: Dictionary[int, int] = {}
	for family: EnemyFamilyDefinitionScript in catalog.families:
		family_source_counts[family.source] = family_source_counts.get(family.source, 0) + 1
	var profile_source_counts: Dictionary[int, int] = {}
	var tier_counts: Dictionary[int, int] = {}
	var pair_counts: Dictionary[String, int] = {}
	var behavior_counts: Dictionary[StringName, int] = {}
	for profile: EnemyProfileDefinitionScript in catalog.profiles:
		profile_source_counts[profile.source] = profile_source_counts.get(profile.source, 0) + 1
		tier_counts[profile.tier] = tier_counts.get(profile.tier, 0) + 1
		var pair_key: String = "%s:%d" % [String(profile.family_id), profile.tier]
		pair_counts[pair_key] = pair_counts.get(pair_key, 0) + 1
		behavior_counts[profile.behavior_id] = behavior_counts.get(profile.behavior_id, 0) + 1

	for source: int in range(
		EnemyFamilyDefinitionScript.Source.LOCAL_FAUNA,
		EnemyFamilyDefinitionScript.Source.ANCIENT_EXECUTOR + 1,
	):
		context.expect_equal(
			family_source_counts.get(source, 0),
			EnemyProfileCatalogOracle.EXPECTED_SOURCE_FAMILY_COUNTS[source - 1],
			"Family source %d must keep its frozen distribution." % source,
		)
		context.expect_equal(
			profile_source_counts.get(source, 0),
			EnemyProfileCatalogOracle.EXPECTED_SOURCE_PROFILE_COUNTS[source - 1],
			"Profile source %d must keep its frozen distribution." % source,
		)
	context.expect_equal(
		tier_counts.get(EnemyProfileDefinitionScript.Tier.BASE, 0),
		EnemyProfileCatalogOracle.EXPECTED_BASE_PROFILE_COUNT,
		"Every family must have one base profile.",
	)
	context.expect_equal(
		tier_counts.get(EnemyProfileDefinitionScript.Tier.ENHANCED, 0),
		EnemyProfileCatalogOracle.EXPECTED_ENHANCED_PROFILE_COUNT,
		"Every family must have one enhanced profile.",
	)
	for family_id: StringName in _expected_family_ids():
		for tier: int in [
			EnemyProfileDefinitionScript.Tier.BASE,
			EnemyProfileDefinitionScript.Tier.ENHANCED,
		]:
			context.expect_equal(
				pair_counts.get("%s:%d" % [String(family_id), tier], 0),
				1,
				"Family/tier pair %s:%d must occur exactly once."
				% [String(family_id), tier],
			)
	for behavior_id: StringName in EnemyProfileCatalogOracle.EXPECTED_BEHAVIOR_IDS:
		context.expect_equal(
			behavior_counts.get(behavior_id, 0),
			EnemyProfileCatalogOracle.EXPECTED_PROFILES_PER_BEHAVIOR,
			"Behavior '%s' must bind four profiles." % String(behavior_id),
		)


func _matches_all_literal_fields(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Independent enemy literal oracle",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	for row in EnemyProfileCatalogOracle.family_rows():
		var query: EnemyProfileQueryResultScript = registry.lookup_enemy_family(
			row.family_id
		)
		context.expect_true(query.succeeded(), "%s must resolve." % row.family_id)
		if not query.succeeded():
			continue
		var family: EnemyFamilyDefinitionScript = query.family()
		context.expect_equal(family.family_id, row.family_id, "Family ID.")
		context.expect_equal(family.ordinal, row.ordinal, "%s ordinal." % row.family_id)
		context.expect_equal(family.source, row.source, "%s source." % row.family_id)
		context.expect_equal(
			family.numeric_archetype,
			row.numeric_archetype,
			"%s numeric archetype." % row.family_id,
		)
		context.expect_equal(
			family.display_name_text_id,
			row.display_name_text_id,
			"%s display-name text binding." % row.family_id,
		)
		context.expect_equal(
			family.regional_role_id,
			row.regional_role_id,
			"%s regional role." % row.family_id,
		)
		context.expect_equal(
			family.visual_family_id,
			row.visual_family_id,
			"%s visual family binding." % row.family_id,
		)

	for row in EnemyProfileCatalogOracle.profile_rows():
		var query: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(
			row.profile_id
		)
		context.expect_true(query.succeeded(), "%s must resolve." % row.profile_id)
		if not query.succeeded():
			continue
		var profile: EnemyProfileDefinitionScript = query.profile()
		context.expect_equal(profile.profile_id, row.profile_id, "Profile ID.")
		context.expect_equal(profile.family_id, row.family_id, "%s family." % row.profile_id)
		context.expect_equal(profile.tier, row.tier, "%s tier." % row.profile_id)
		context.expect_equal(profile.source, row.source, "%s source." % row.profile_id)
		context.expect_equal(
			profile.balance_contract_id,
			row.balance_contract_id,
			"%s balance contract." % row.profile_id,
		)
		context.expect_equal(
			profile.maximum_durability,
			row.maximum_durability,
			"%s durability." % row.profile_id,
		)
		context.expect_equal(profile.attack, row.attack, "%s attack." % row.profile_id)
		context.expect_equal(profile.defense, row.defense, "%s defense." % row.profile_id)
		context.expect_equal(profile.speed, row.speed, "%s speed." % row.profile_id)
		context.expect_equal(
			profile.has_alternate_state,
			row.has_alternate_state,
			"%s alternate-state flag." % row.profile_id,
		)
		context.expect_equal(
			profile.alternate_maximum_durability,
			row.alternate_maximum_durability,
			"%s alternate durability." % row.profile_id,
		)
		context.expect_equal(
			profile.alternate_attack,
			row.alternate_attack,
			"%s alternate attack." % row.profile_id,
		)
		context.expect_equal(
			profile.alternate_defense,
			row.alternate_defense,
			"%s alternate defense." % row.profile_id,
		)
		context.expect_equal(
			profile.alternate_speed,
			row.alternate_speed,
			"%s alternate speed." % row.profile_id,
		)
		context.expect_equal(
			profile.behavior_id,
			row.behavior_id,
			"%s behavior binding." % row.profile_id,
		)
		context.expect_equal(
			profile.combat_trait_ids,
			row.combat_trait_ids,
			"%s combat traits." % row.profile_id,
		)
		context.expect_equal(
			profile.visual_binding_id,
			row.visual_binding_id,
			"%s visual binding." % row.profile_id,
		)


func _matches_h43_combat_expectations(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"H4.3 combat expectations",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var expectation_count: int = 0
	for row in EnemyProfileCatalogOracle.profile_rows():
		var profile_query: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(
			row.profile_id
		)
		context.expect_true(profile_query.succeeded(), "%s must resolve." % row.profile_id)
		if not profile_query.succeeded():
			continue
		var profile: EnemyProfileDefinitionScript = profile_query.profile()
		var family_query: EnemyProfileQueryResultScript = registry.lookup_enemy_family(
			profile.family_id
		)
		var route_query = registry.lookup_representative_route_contract(
			profile.balance_contract_id
		)
		context.expect_true(family_query.succeeded(), "Combat family must resolve.")
		context.expect_true(route_query.succeeded(), "Combat route contract must resolve.")
		if not family_query.succeeded() or not route_query.succeeded():
			continue
		var player_stats = route_query.stage_end_minimum_player_stats()
		var player_state: PlayerProgressionStateScript = _player_state_for_route(
			registry,
			route_query.contract(),
			player_stats,
		)
		context.expect_true(player_state != null, "Combat player state must be derivable.")
		if player_state == null:
			continue
		context.expect_equal(
			_player_stat_values(player_stats),
			row.primary_expectation.player_stats,
			"%s must use the frozen route-end player stats." % row.profile_id,
		)
		_expect_combat_state(
			context,
			registry,
			player_state,
			player_stats,
			profile,
			family_query.family(),
			"primary",
			[
				profile.maximum_durability,
				profile.attack,
				profile.defense,
				profile.speed,
			],
			row.primary_expectation,
		)
		expectation_count += 1
		if row.has_alternate_state:
			context.expect_true(
				row.alternate_expectation != null,
				"Alternate state must provide a literal expectation.",
			)
			if row.alternate_expectation != null:
				context.expect_equal(
					_player_stat_values(player_stats),
					row.alternate_expectation.player_stats,
					"Alternate expectation must share route-end player stats.",
				)
				_expect_combat_state(
					context,
					registry,
					player_state,
					player_stats,
					profile,
					family_query.family(),
					"alternate",
					[
						profile.alternate_maximum_durability,
						profile.alternate_attack,
						profile.alternate_defense,
						profile.alternate_speed,
					],
					row.alternate_expectation,
				)
				expectation_count += 1
	context.expect_equal(
		expectation_count,
		28,
		"The kernel must check all 24 primary and 4 alternate literal expectations.",
	)


func _reports_structured_queries(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Structured enemy queries",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var family_id: StringName = _expected_family_ids()[0]
	var profile_id: StringName = _expected_profile_ids()[0]
	var found_family: EnemyProfileQueryResultScript = registry.lookup_enemy_family(
		family_id
	)
	context.expect_true(found_family.succeeded(), "Known family query must succeed.")
	context.expect_equal(
		found_family.kind(),
		EnemyProfileQueryResultScript.Kind.FAMILY,
		"Family query kind must be structured.",
	)
	context.expect_equal(found_family.family().family_id, family_id, "Family query payload.")
	context.expect_equal(found_family.profile(), null, "Family query must expose no profile.")
	context.expect_equal(found_family.issue(), null, "Successful family query has no issue.")

	var found_profile: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(
		profile_id
	)
	context.expect_true(found_profile.succeeded(), "Known profile query must succeed.")
	context.expect_equal(
		found_profile.kind(),
		EnemyProfileQueryResultScript.Kind.PROFILE,
		"Profile query kind must be structured.",
	)
	context.expect_equal(found_profile.profile().profile_id, profile_id, "Profile query payload.")
	context.expect_equal(found_profile.family(), null, "Profile query must expose no family.")
	context.expect_equal(found_profile.issue(), null, "Successful profile query has no issue.")

	_expect_query_failure(
		context,
		registry.lookup_enemy_family(&"enemy.family.unknown"),
		EnemyProfileQueryResultScript.Kind.FAMILY,
		ContentValidationIssueScript.LOOKUP_UNKNOWN_ENEMY_FAMILY_ID,
		&"enemy.family.unknown",
		"Unknown family",
	)
	_expect_query_failure(
		context,
		registry.lookup_enemy_profile(&"enemy.profile.unknown"),
		EnemyProfileQueryResultScript.Kind.PROFILE,
		ContentValidationIssueScript.LOOKUP_UNKNOWN_ENEMY_PROFILE_ID,
		&"enemy.profile.unknown",
		"Unknown profile",
	)
	var raw_registry := ContentRegistryScript.new()
	_expect_query_failure(
		context,
		raw_registry.lookup_enemy_family(family_id),
		EnemyProfileQueryResultScript.Kind.FAMILY,
		ContentValidationIssueScript.LOOKUP_ENEMY_REGISTRY_UNINITIALIZED,
		family_id,
		"Uninitialized family registry",
	)
	_expect_query_failure(
		context,
		raw_registry.lookup_enemy_profile(profile_id),
		EnemyProfileQueryResultScript.Kind.PROFILE,
		ContentValidationIssueScript.LOOKUP_ENEMY_REGISTRY_UNINITIALIZED,
		profile_id,
		"Uninitialized profile registry",
	)


func _isolates_inputs_queries_and_cache(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy isolation fixtures",
	)
	if not canonical.succeeded():
		return
	var source_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	var isolated_build: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(source_manifest)
	)
	context.expect_true(isolated_build.succeeded(), "Isolation manifest must build.")
	if not isolated_build.succeeded():
		return
	var registry: ContentRegistryScript = isolated_build.registry()
	var first_family_id: StringName = _expected_family_ids()[0]
	var first_profile_id: StringName = _expected_profile_ids()[0]
	source_manifest.enemy_profile_catalog.families[0].display_name_text_id = (
		&"text.enemy.tampered"
	)
	source_manifest.enemy_profile_catalog.profiles[0].attack = 999
	context.expect_equal(
		registry.lookup_enemy_family(first_family_id).family().display_name_text_id,
		&"text.enemy.family.f01.name",
		"Post-build input-family mutation must not alter Registry state.",
	)
	context.expect_equal(
		registry.lookup_enemy_profile(first_profile_id).profile().attack,
		9,
		"Post-build input-profile mutation must not alter Registry state.",
	)

	var returned_catalog: EnemyProfileCatalogScript = registry.enemy_profile_catalog()
	returned_catalog.catalog_id = &"enemy.profile.catalog.tampered"
	returned_catalog.families[0].ordinal = 999
	returned_catalog.profiles[0].defense = 999
	returned_catalog.families.clear()
	returned_catalog.profiles.clear()
	context.expect_equal(
		registry.enemy_profile_catalog().catalog_id,
		EnemyProfileCatalogOracle.CATALOG_ID,
		"Returned catalog must be a defensive deep snapshot.",
	)
	context.expect_equal(registry.enemy_family_count(), 12, "Returned family list is isolated.")
	context.expect_equal(registry.enemy_profile_count(), 24, "Returned profile list is isolated.")

	var returned_families: Array[EnemyFamilyDefinitionScript] = registry.enemy_families()
	var returned_profiles: Array[EnemyProfileDefinitionScript] = registry.enemy_profiles()
	returned_families[0].regional_role_id = &"enemy.role.tampered"
	returned_profiles[0].visual_binding_id = &"enemy.visual.tampered"
	returned_families.clear()
	returned_profiles.clear()
	context.expect_equal(
		registry.lookup_enemy_family(first_family_id).family().regional_role_id,
		&"enemy.role.hareno.signature_patrol",
		"Returned family resources must be isolated.",
	)
	context.expect_equal(
		registry.lookup_enemy_profile(first_profile_id).profile().visual_binding_id,
		&"enemy.visual.variant.f01.base",
		"Returned profile resources must be isolated.",
	)

	var family_query: EnemyProfileQueryResultScript = registry.lookup_enemy_family(
		first_family_id
	)
	var profile_query: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(
		first_profile_id
	)
	var returned_family: EnemyFamilyDefinitionScript = family_query.family()
	var returned_profile: EnemyProfileDefinitionScript = profile_query.profile()
	returned_family.ordinal = 999
	returned_profile.combat_trait_ids.append(&"enemy.trait.tampered")
	context.expect_equal(family_query.family().ordinal, 1, "Family query getter must copy.")
	context.expect_equal(
		profile_query.profile().combat_trait_ids,
		[],
		"Profile query getter must deep-copy trait IDs.",
	)
	var unknown: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(
		&"enemy.profile.unknown"
	)
	var returned_issue: ContentValidationIssueScript = unknown.issue()
	returned_issue._message = "tampered"
	context.expect_true(
		unknown.issue().message() != "tampered",
		"Enemy query issues must be returned as snapshots.",
	)

	var cached_resource: Resource = ResourceLoader.load(
		ContentRegistryBuilderScript.CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_REUSE,
	)
	context.expect_true(cached_resource != null, "Cache isolation fixture must load.")
	if cached_resource != null and cached_resource.get_script() == ContentManifestScript:
		var cached_manifest: ContentManifestScript = cached_resource as ContentManifestScript
		var cached_profile: EnemyProfileDefinitionScript = (
			cached_manifest.enemy_profile_catalog.profiles[0]
		)
		var original_attack: int = cached_profile.attack
		cached_profile.attack = 999
		var fresh_result: ContentRegistryBuildResultScript = (
			ContentRegistryBuilderScript.build_canonical()
		)
		cached_profile.attack = original_attack
		context.expect_true(
			fresh_result.succeeded(),
			"Canonical build must ignore a mutated ResourceLoader cache graph.",
		)
		if fresh_result.succeeded():
			context.expect_equal(
				fresh_result.registry().lookup_enemy_profile(first_profile_id).profile().attack,
				9,
				"Fresh build must retain the disk-backed enemy profile.",
			)


func _invalidates_tampered_registry(context: HeadlessTestContextScript) -> void:
	var profile_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy profile Registry tamper",
	)
	if not profile_result.succeeded():
		return
	var profile_registry: ContentRegistryScript = profile_result.registry()
	var profile_id: StringName = _expected_profile_ids()[0]
	profile_registry._enemy_profiles_by_id[profile_id].attack = 999
	context.expect_true(
		not profile_registry.is_initialized(),
		"Internal profile tampering must invalidate the shared Registry.",
	)
	context.expect_true(
		not profile_result.succeeded(),
		"Tampered build result must stop publishing its Registry.",
	)
	context.expect_equal(
		profile_result.registry(),
		null,
		"Tampered enemy Registry must fail closed without a partial result.",
	)
	context.expect_equal(
		profile_registry.enemy_profile_catalog(),
		null,
		"Tampered Registry must expose no enemy catalog.",
	)
	_expect_query_failure(
		context,
		profile_registry.lookup_enemy_profile(profile_id),
		EnemyProfileQueryResultScript.Kind.PROFILE,
		ContentValidationIssueScript.LOOKUP_ENEMY_REGISTRY_UNINITIALIZED,
		profile_id,
		"Tampered profile lookup",
	)
	context.expect_true(
		not profile_registry.lookup_blueprint(&"blueprint.01").succeeded(),
		"Enemy tampering must close blueprint queries too.",
	)

	var family_result: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy family Registry tamper",
	)
	if not family_result.succeeded():
		return
	var family_registry: ContentRegistryScript = family_result.registry()
	var family_id: StringName = _expected_family_ids()[0]
	family_registry._enemy_families_by_id[family_id].ordinal = 999
	context.expect_true(
		not family_registry.is_initialized(),
		"Internal family tampering must invalidate the shared Registry.",
	)
	_expect_query_failure(
		context,
		family_registry.lookup_enemy_family(family_id),
		EnemyProfileQueryResultScript.Kind.FAMILY,
		ContentValidationIssueScript.LOOKUP_ENEMY_REGISTRY_UNINITIALIZED,
		family_id,
		"Tampered family lookup",
	)


func _rejects_null_and_polymorphic_resources(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Exact-script enemy fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var null_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_catalog_manifest.enemy_profile_catalog = null
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(null_catalog_manifest),
		ContentValidationIssueScript.MANIFEST_ENEMY_PROFILE_CATALOG_NULL,
		"Null enemy catalog",
	)

	var derived_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var derived_catalog := DerivedEnemyCatalogScript.new()
	derived_catalog.catalog_id = derived_catalog_manifest.enemy_profile_catalog.catalog_id
	derived_catalog.families = derived_catalog_manifest.enemy_profile_catalog.families
	derived_catalog.profiles = derived_catalog_manifest.enemy_profile_catalog.profiles
	derived_catalog_manifest.enemy_profile_catalog = derived_catalog
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(derived_catalog_manifest),
		ContentValidationIssueScript.ENEMY_CATALOG_INVALID_SCRIPT,
		"Derived enemy catalog",
	)

	var null_family_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_family_manifest.enemy_profile_catalog.families[0] = null
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(null_family_manifest),
		ContentValidationIssueScript.ENEMY_FAMILY_ENTRY_NULL,
		"Null enemy family",
	)

	var derived_family_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var source_family: EnemyFamilyDefinitionScript = (
		derived_family_manifest.enemy_profile_catalog.families[0]
	)
	var derived_family := DerivedEnemyFamilyScript.new()
	_copy_family_fields(derived_family, source_family)
	derived_family_manifest.enemy_profile_catalog.families[0] = derived_family
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(derived_family_manifest),
		ContentValidationIssueScript.ENEMY_FAMILY_ENTRY_INVALID_SCRIPT,
		"Derived enemy family",
	)

	var null_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	null_profile_manifest.enemy_profile_catalog.profiles[0] = null
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(null_profile_manifest),
		ContentValidationIssueScript.ENEMY_PROFILE_ENTRY_NULL,
		"Null enemy profile",
	)

	var derived_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var source_profile: EnemyProfileDefinitionScript = (
		derived_profile_manifest.enemy_profile_catalog.profiles[0]
	)
	var derived_profile := DerivedEnemyProfileScript.new()
	_copy_profile_fields(derived_profile, source_profile)
	derived_profile_manifest.enemy_profile_catalog.profiles[0] = derived_profile
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(derived_profile_manifest),
		ContentValidationIssueScript.ENEMY_PROFILE_ENTRY_INVALID_SCRIPT,
		"Derived enemy profile",
	)


func _rejects_identity_pair_and_reference_errors(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy identity and reference fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var wrong_catalog_manifest: ContentManifestScript = _manifest_from_registry(registry)
	wrong_catalog_manifest.enemy_profile_catalog.catalog_id = &"enemy.profile.catalog.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(wrong_catalog_manifest), ContentValidationIssueScript.ENEMY_CATALOG_ID_INVALID, "Unknown enemy catalog ID")

	var duplicate_family_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_family_manifest.enemy_profile_catalog.families[1].family_id = duplicate_family_manifest.enemy_profile_catalog.families[0].family_id
	_expect_failure_code(context, ContentRegistryBuilderScript.build(duplicate_family_manifest), ContentValidationIssueScript.ENEMY_FAMILY_ID_DUPLICATE, "Duplicate family ID")

	var duplicate_profile_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_profile_manifest.enemy_profile_catalog.profiles[1].profile_id = duplicate_profile_manifest.enemy_profile_catalog.profiles[0].profile_id
	_expect_failure_code(context, ContentRegistryBuilderScript.build(duplicate_profile_manifest), ContentValidationIssueScript.ENEMY_PROFILE_ID_DUPLICATE, "Duplicate profile ID")

	var duplicate_trait_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var shield_profile: EnemyProfileDefinitionScript = _find_profile(duplicate_trait_manifest.enemy_profile_catalog, &"enemy.profile.f03.base")
	shield_profile.combat_trait_ids.append(&"enemy.trait.shield")
	_expect_failure_code(context, ContentRegistryBuilderScript.build(duplicate_trait_manifest), ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_DUPLICATE, "Duplicate combat trait")

	var missing_pair_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(missing_pair_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").family_id = &"enemy.family.f02"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(missing_pair_manifest), ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_TIER_PAIR_INVALID, "Missing family/tier pair")

	var unknown_family_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(unknown_family_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").family_id = &"enemy.family.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_family_manifest), ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_REFERENCE_INVALID, "Unknown family reference")

	var unknown_route_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(unknown_route_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").balance_contract_id = &"route.contract.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_route_manifest), ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTRACT_REFERENCE_INVALID, "Unknown route reference")

	var unknown_behavior_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(unknown_behavior_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").behavior_id = &"enemy.behavior.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_behavior_manifest), ContentValidationIssueScript.ENEMY_PROFILE_BEHAVIOR_ID_INVALID, "Unknown behavior binding")

	var unknown_trait_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(unknown_trait_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").combat_trait_ids.append(&"enemy.trait.unknown")
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_trait_manifest), ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID, "Unknown trait binding")

	var unknown_visual_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(unknown_visual_manifest.enemy_profile_catalog, &"enemy.profile.f01.base").visual_binding_id = &"enemy.visual.variant.unknown"
	_expect_failure_code(context, ContentRegistryBuilderScript.build(unknown_visual_manifest), ContentValidationIssueScript.ENEMY_PROFILE_FIELD_MISMATCH, "Unknown visual binding")

	var duplicate_visual_manifest: ContentManifestScript = _manifest_from_registry(registry)
	duplicate_visual_manifest.enemy_profile_catalog.profiles[1].visual_binding_id = duplicate_visual_manifest.enemy_profile_catalog.profiles[0].visual_binding_id
	_expect_failure_code(context, ContentRegistryBuilderScript.build(duplicate_visual_manifest), ContentValidationIssueScript.ENEMY_PROFILE_VISUAL_ID_DUPLICATE, "Duplicate visual binding")


func _rejects_invalid_stat_and_alternate_shapes(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy structural-invalid fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	var structurally_valid_variant: EnemyProfileCatalogScript = (
		registry.enemy_profile_catalog()
	)
	_find_profile(
		structurally_valid_variant,
		&"enemy.profile.f01.base",
	).attack = 10
	var structural_issues: Array[ContentValidationIssueScript] = []
	var structural_snapshot: EnemyProfileCatalogScript = (
		EnemyProfileValidatorScript.snapshot_and_validate(
			structurally_valid_variant,
			registry.representative_route_contract_catalog(),
			structural_issues,
		)
	)
	context.expect_true(
		structural_snapshot != null,
		"Structural validation must not duplicate the sealed 24-profile value table.",
	)
	context.expect_equal(
		structural_issues,
		[],
		"A structurally valid noncanonical stat must reach the separate seal boundary.",
	)
	if structural_snapshot != null:
		context.expect_equal(
			_find_profile(
				structural_snapshot,
				&"enemy.profile.f01.base",
			).attack,
			10,
			"Structural validation must preserve the candidate stat for later balance and fingerprint checks.",
		)

	var invalid_stats_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(
		invalid_stats_manifest.enemy_profile_catalog,
		&"enemy.profile.f01.base",
	).maximum_durability = 0
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(invalid_stats_manifest),
		ContentValidationIssueScript.ENEMY_PROFILE_STATS_INVALID,
		"Non-positive primary enemy stat",
	)

	var invalid_alternate_manifest: ContentManifestScript = _manifest_from_registry(registry)
	_find_profile(
		invalid_alternate_manifest.enemy_profile_catalog,
		&"enemy.profile.f06.base",
	).alternate_attack = 0
	_expect_failure_code(
		context,
		ContentRegistryBuilderScript.build(invalid_alternate_manifest),
		ContentValidationIssueScript.ENEMY_PROFILE_ALTERNATE_STATE_INVALID,
		"Incomplete enabled alternate enemy state",
	)


func _rejects_balance_boundary_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy balance-invalid fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()

	_expect_balance_clean(
		context, registry, &"enemy.profile.f07.base", &"defense", 8,
		"Player damage floor of three",
	)
	_expect_balance_issue(
		context, registry, &"enemy.profile.f07.base", &"defense", 9,
		ContentValidationIssueScript.ENEMY_PROFILE_PLAYER_DAMAGE_TOO_LOW,
		"Player damage below three",
	)

	_expect_balance_issue(
		context, registry, &"enemy.profile.f07.base", &"maximum_durability", 3,
		ContentValidationIssueScript.ENEMY_PROFILE_ATTACK_COUNT_INVALID,
		"Base profile below two attacks",
	)
	_expect_balance_issue(
		context, registry, &"enemy.profile.f07.base", &"maximum_durability", 16,
		ContentValidationIssueScript.ENEMY_PROFILE_ATTACK_COUNT_INVALID,
		"Base profile above five attacks",
	)
	_expect_balance_issue(
		context, registry, &"enemy.profile.f08.enhanced", &"maximum_durability", 6,
		ContentValidationIssueScript.ENEMY_PROFILE_ATTACK_COUNT_INVALID,
		"Enhanced profile below three attacks",
	)
	_expect_balance_clean(
		context, registry, &"enemy.profile.f08.enhanced", &"maximum_durability", 18,
		"Enhanced profile upper boundary of six attacks",
	)
	_expect_balance_issue(
		context, registry, &"enemy.profile.f08.enhanced", &"maximum_durability", 19,
		ContentValidationIssueScript.ENEMY_PROFILE_ATTACK_COUNT_INVALID,
		"Enhanced profile above six attacks",
	)

	_expect_loss_boundary(
		context, registry, &"enemy.profile.f01.base", 12, 13, 15,
	)
	_expect_loss_boundary(
		context, registry, &"enemy.profile.f01.enhanced", 15, 16, 20,
	)
	_expect_loss_boundary(
		context, registry, &"enemy.profile.f03.base", 16, 17, 25,
	)
	_expect_loss_boundary(
		context, registry, &"enemy.profile.f12.enhanced", 20, 21, 30,
	)

	_expect_balance_issue(
		context, registry, &"enemy.profile.f08.enhanced", &"attack", 32,
		ContentValidationIssueScript.ENEMY_PROFILE_NOT_CLEARABLE,
		"Enemy state that defeats the minimum player",
	)
	_expect_balance_clean(
		context, registry, &"enemy.profile.f07.base", &"speed", 11,
		"High-speed archetype at player speed plus one",
	)
	_expect_balance_issue(
		context, registry, &"enemy.profile.f07.base", &"speed", 12,
		ContentValidationIssueScript.ENEMY_PROFILE_SPEED_ARCHETYPE_INVALID,
		"High-speed archetype above player speed plus one",
	)


func _orders_error_signatures_deterministically(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy error ordering",
	)
	if not canonical.succeeded():
		return
	var forward: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var reverse: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_corrupt_for_ordering(forward)
	_corrupt_for_ordering(reverse)
	_reverse_enemy_declarations(reverse)
	var forward_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(forward)
	)
	var reverse_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(reverse)
	)
	context.expect_true(not forward_result.succeeded(), "Forward corruption must fail.")
	context.expect_true(not reverse_result.succeeded(), "Reverse corruption must fail.")
	context.expect_equal(
		reverse_result.validation_report().signatures(),
		forward_result.validation_report().signatures(),
		"Enemy error signatures must not depend on declaration or trait order.",
	)
	var repeated_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(forward)
	)
	context.expect_equal(
		repeated_result.validation_report().signatures(),
		forward_result.validation_report().signatures(),
		"Repeated enemy validation must emit identical ordered signatures.",
	)


func _fingerprint_covers_fields_and_ignores_set_order(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = _canonical_result(
		context,
		"Enemy fingerprint fixtures",
	)
	if not canonical.succeeded():
		return
	var registry: ContentRegistryScript = canonical.registry()
	var baseline_manifest: ContentManifestScript = _manifest_from_registry(registry)
	var baseline: String = _fingerprint(baseline_manifest)
	context.expect_equal(baseline.length(), 64, "v6 fingerprint must be a SHA-256 digest.")
	context.expect_equal(
		baseline,
		ContentContractFingerprintScript.EXPECTED_FINGERPRINT,
		"Canonical calculated fingerprint must match the production seal.",
	)

	var catalog_tamper: ContentManifestScript = _manifest_from_registry(registry)
	catalog_tamper.enemy_profile_catalog.catalog_id = &"enemy.profile.catalog.tampered"
	_expect_fingerprint_changed(context, baseline, catalog_tamper, "enemy catalog ID")

	var family_mutations: Array[Array] = [
		[&"family_id", &"enemy.family.tampered"],
		[&"ordinal", 99],
		[&"source", 4],
		[&"numeric_archetype", 7],
		[&"display_name_text_id", &"text.enemy.family.tampered"],
		[&"regional_role_id", &"enemy.role.tampered"],
		[&"visual_family_id", &"enemy.visual.family.tampered"],
	]
	for mutation: Array in family_mutations:
		var manifest: ContentManifestScript = _manifest_from_registry(registry)
		manifest.enemy_profile_catalog.families[0].set(mutation[0], mutation[1])
		_expect_fingerprint_changed(
			context,
			baseline,
			manifest,
			"enemy family field '%s'" % String(mutation[0]),
		)

	var profile_mutations: Array[Array] = [
		[&"profile_id", &"enemy.profile.tampered"],
		[&"family_id", &"enemy.family.f12"],
		[&"tier", 2],
		[&"source", 4],
		[&"balance_contract_id", &"route.contract.main.stage.09"],
		[&"maximum_durability", 13],
		[&"attack", 10],
		[&"defense", 8],
		[&"speed", 11],
		[&"has_alternate_state", true],
		[&"alternate_maximum_durability", 1],
		[&"alternate_attack", 1],
		[&"alternate_defense", 1],
		[&"alternate_speed", 1],
		[&"behavior_id", &"enemy.behavior.shield"],
		[&"visual_binding_id", &"enemy.visual.variant.tampered"],
	]
	for mutation: Array in profile_mutations:
		var manifest: ContentManifestScript = _manifest_from_registry(registry)
		manifest.enemy_profile_catalog.profiles[0].set(mutation[0], mutation[1])
		_expect_fingerprint_changed(
			context,
			baseline,
			manifest,
			"enemy profile field '%s'" % String(mutation[0]),
		)
	var trait_tamper: ContentManifestScript = _manifest_from_registry(registry)
	trait_tamper.enemy_profile_catalog.profiles[0].combat_trait_ids.append(
		&"enemy.trait.shield"
	)
	_expect_fingerprint_changed(context, baseline, trait_tamper, "enemy combat traits")

	var reordered: ContentManifestScript = _manifest_from_registry(registry)
	_reverse_enemy_declarations(reordered)
	context.expect_equal(
		_fingerprint(reordered),
		baseline,
		"Family, profile and trait declaration order must not affect the fingerprint.",
	)
	var reordered_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(reordered)
	)
	context.expect_true(reordered_result.succeeded(), "Reordered enemy declarations must build.")
	if reordered_result.succeeded():
		context.expect_equal(
			reordered_result.registry().enemy_family_ids(),
			registry.enemy_family_ids(),
			"Reordered families must publish canonical query order.",
		)
		context.expect_equal(
			reordered_result.registry().enemy_profile_ids(),
			registry.enemy_profile_ids(),
			"Reordered profiles must publish canonical query order.",
		)


func _expect_combat_state(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	player_state: PlayerProgressionStateScript,
	player_stats,
	profile: EnemyProfileDefinitionScript,
	family: EnemyFamilyDefinitionScript,
	state_name: String,
	state_values: Array,
	expectation,
) -> void:
	var shield_intact: bool = expectation.shield_intact
	var support_count: int = expectation.supporting_opponents_alive
	var literal_no_shield: ContactCombatResolutionScript = _evaluate_resolution(
		registry,
		player_state,
		profile.profile_id,
		state_name,
		state_values,
		false,
		support_count,
		ContactCombatCommandScript.Side.PLAYER,
	)
	var literal_actual: ContactCombatResolutionScript = _evaluate_resolution(
		registry,
		player_state,
		profile.profile_id,
		state_name,
		state_values,
		shield_intact,
		support_count,
		ContactCombatCommandScript.Side.PLAYER,
	)
	context.expect_true(literal_no_shield != null, "%s no-shield evaluation." % profile.profile_id)
	context.expect_true(literal_actual != null, "%s trait evaluation." % profile.profile_id)
	if literal_no_shield == null or literal_actual == null:
		return
	context.expect_equal(
		literal_actual.first_attacker_side() == ContactCombatCommandScript.Side.PLAYER,
		expectation.player_first_attacker,
		"%s %s first attacker." % [profile.profile_id, state_name],
	)
	context.expect_equal(literal_actual.player_damage_per_attack(), expectation.player_damage_per_attack, "%s %s player damage." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.opponent_damage_per_attack(), expectation.opponent_damage_per_attack, "%s %s opponent damage." % [profile.profile_id, state_name])
	context.expect_equal(literal_no_shield.player_attacks_required_to_clear(), expectation.player_attacks_without_shield, "%s %s no-shield attack count." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.player_attacks_required_to_clear(), expectation.player_attacks_with_traits, "%s %s trait attack count." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.player_attacks_executed(), expectation.player_attacks_with_traits, "%s %s executed player attacks." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.opponent_attacks_executed(), expectation.opponent_attacks_executed, "%s %s opponent attacks." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.player_health_loss(), expectation.player_health_loss, "%s %s player health loss." % [profile.profile_id, state_name])
	context.expect_equal(literal_actual.outcome(), ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED, "%s %s must be clearable." % [profile.profile_id, state_name])

	var minimum_attacks: int = EnemyProfileCatalogOracle.BASE_ATTACK_COUNT_MINIMUM
	var maximum_attacks: int = EnemyProfileCatalogOracle.BASE_ATTACK_COUNT_MAXIMUM
	if profile.tier == EnemyProfileDefinitionScript.Tier.ENHANCED:
		minimum_attacks = EnemyProfileCatalogOracle.ENHANCED_ATTACK_COUNT_MINIMUM
		maximum_attacks = EnemyProfileCatalogOracle.ENHANCED_ATTACK_COUNT_MAXIMUM
	var worst_loss: int = 0
	for initiator_side: int in [
		ContactCombatCommandScript.Side.PLAYER,
		ContactCombatCommandScript.Side.OPPONENT,
	]:
		var no_shield: ContactCombatResolutionScript = _evaluate_resolution(
			registry, player_state, profile.profile_id, state_name, state_values,
			false, support_count, initiator_side,
		)
		var actual: ContactCombatResolutionScript = _evaluate_resolution(
			registry, player_state, profile.profile_id, state_name, state_values,
			shield_intact, support_count, initiator_side,
		)
		context.expect_true(no_shield != null, "Both initiators need no-shield resolution.")
		context.expect_true(actual != null, "Both initiators need trait resolution.")
		if no_shield == null or actual == null:
			continue
		context.expect_true(
			no_shield.player_damage_per_attack() >= EnemyProfileCatalogOracle.MINIMUM_PLAYER_DAMAGE_PER_ATTACK,
			"Player damage per attack must remain at least three.",
		)
		context.expect_true(
			no_shield.player_attacks_required_to_clear() >= minimum_attacks
			and no_shield.player_attacks_required_to_clear() <= maximum_attacks,
			"%s %s no-shield attack count must remain in its tier band."
			% [profile.profile_id, state_name],
		)
		var expected_delta: int = EnemyProfileCatalogOracle.SHIELD_EXTRA_ATTACK_COUNT if shield_intact else 0
		context.expect_equal(
			actual.player_attacks_required_to_clear(),
			no_shield.player_attacks_required_to_clear() + expected_delta,
			"Shield must add exactly one attack and non-shield traits must add none.",
		)
		context.expect_equal(
			actual.outcome(),
			ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
			"Mainline-minimum player must clear for either initiator.",
		)
		worst_loss = max(worst_loss, actual.player_health_loss())
	var loss_cap_percent: int = _loss_cap_percent(profile)
	context.expect_true(
		worst_loss * 100 <= player_stats.maximum_health * loss_cap_percent,
		"%s %s loss %d/%d must remain within %d percent."
		% [profile.profile_id, state_name, worst_loss, player_stats.maximum_health, loss_cap_percent],
	)
	if _requires_speed_plus_one(family, profile):
		context.expect_equal(
			state_values[3],
			player_stats.speed + EnemyProfileCatalogOracle.HIGH_SPEED_DELTA,
			"High-speed archetype must remain player speed plus one.",
		)


func _evaluate_resolution(
	registry: ContentRegistryScript,
	player_state: PlayerProgressionStateScript,
	profile_id: StringName,
	state_name: String,
	state_values: Array,
	shield_intact: bool,
	support_count: int,
	initiator_side: int,
) -> ContactCombatResolutionScript:
	var opponent := ContactCombatOpponentStateScript.create(
		StringName("%s.%s" % [String(profile_id), state_name]),
		state_values[0],
		state_values[0],
		state_values[1],
		state_values[2],
		state_values[3],
		shield_intact,
	)
	var command := ContactCombatCommandScript.evaluate(
		initiator_side,
		ContactCombatCommandScript.TemporaryEffect.NONE,
		support_count,
	)
	var result = ContactCombatKernelScript.evaluate(
		player_state,
		opponent,
		command,
		registry,
	)
	if not result.is_resolution_candidate():
		return null
	return result.resolution()


func _player_state_for_route(registry: ContentRegistryScript, contract, player_stats):
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


func _loss_cap_percent(profile: EnemyProfileDefinitionScript) -> int:
	if profile.combat_trait_ids.size() >= 2:
		return EnemyProfileCatalogOracle.MAXIMUM_DOUBLE_TRAIT_LOSS_PERCENT
	if not profile.combat_trait_ids.is_empty():
		return EnemyProfileCatalogOracle.MAXIMUM_SINGLE_TRAIT_LOSS_PERCENT
	return 20 if profile.tier == EnemyProfileDefinitionScript.Tier.ENHANCED else 15


func _requires_speed_plus_one(
	family: EnemyFamilyDefinitionScript,
	profile: EnemyProfileDefinitionScript,
) -> bool:
	return (
		family.numeric_archetype == EnemyFamilyDefinitionScript.NumericArchetype.SPEED
		or (
			family.numeric_archetype
			== EnemyFamilyDefinitionScript.NumericArchetype.DEFENSE_TO_SPEED
			and profile.tier == EnemyProfileDefinitionScript.Tier.ENHANCED
		)
	)


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


func _expected_family_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for row in EnemyProfileCatalogOracle.family_rows():
		result.append(row.family_id)
	result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


func _expected_profile_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for row in EnemyProfileCatalogOracle.profile_rows():
		result.append(row.profile_id)
	result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


func _player_stat_values(profile) -> Array[int]:
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
	context.expect_equal(
		result.registry(),
		null,
		"%s must publish no partial Registry." % label,
	)
	context.expect_true(
		_issue_codes(result).has(code),
		"%s must report '%s'. Got %s"
		% [label, String(code), str(_issue_codes(result))],
	)


func _expect_query_failure(
	context: HeadlessTestContextScript,
	query: EnemyProfileQueryResultScript,
	kind: int,
	code: StringName,
	content_id: StringName,
	label: String,
) -> void:
	context.expect_true(not query.succeeded(), "%s must fail." % label)
	context.expect_equal(query.kind(), kind, "%s query kind." % label)
	context.expect_equal(query.family(), null, "%s must expose no family." % label)
	context.expect_equal(query.profile(), null, "%s must expose no profile." % label)
	var issue: ContentValidationIssueScript = query.issue()
	context.expect_true(issue != null, "%s must expose an issue." % label)
	if issue != null:
		context.expect_equal(issue.code(), code, "%s issue code." % label)
		context.expect_equal(issue.content_id(), content_id, "%s issue subject." % label)


func _expect_balance_clean(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	profile_id: StringName,
	field_name: StringName,
	value: Variant,
	label: String,
) -> void:
	var codes: Array[StringName] = _balance_issue_codes(
		registry,
		profile_id,
		field_name,
		value,
	)
	context.expect_equal(
		codes,
		[],
		"%s must remain legal. Got %s" % [label, str(codes)],
	)


func _expect_balance_issue(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	profile_id: StringName,
	field_name: StringName,
	value: Variant,
	expected_code: StringName,
	label: String,
) -> void:
	var codes: Array[StringName] = _balance_issue_codes(
		registry,
		profile_id,
		field_name,
		value,
	)
	context.expect_true(
		codes.has(expected_code),
		"%s must report '%s'. Got %s"
		% [label, String(expected_code), str(codes)],
	)


func _expect_loss_boundary(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	profile_id: StringName,
	last_legal_attack: int,
	first_illegal_attack: int,
	cap_percent: int,
) -> void:
	_expect_balance_clean(
		context,
		registry,
		profile_id,
		&"attack",
		last_legal_attack,
		"%s at the last legal %d-percent loss step" % [profile_id, cap_percent],
	)
	_expect_balance_issue(
		context,
		registry,
		profile_id,
		&"attack",
		first_illegal_attack,
		ContentValidationIssueScript.ENEMY_PROFILE_HEALTH_LOSS_INVALID,
		"%s above the %d-percent loss cap" % [profile_id, cap_percent],
	)


func _balance_issue_codes(
	registry: ContentRegistryScript,
	profile_id: StringName,
	field_name: StringName,
	value: Variant,
) -> Array[StringName]:
	var catalog: EnemyProfileCatalogScript = _isolated_balance_catalog(
		registry,
		profile_id,
	)
	var profile: EnemyProfileDefinitionScript = _find_profile(catalog, profile_id)
	if profile == null:
		return [&"test.enemy_profile_missing"]
	profile.set(field_name, value)
	var issues: Array[ContentValidationIssueScript] = []
	EnemyProfileValidatorScript.validate_balance(registry, catalog, issues)
	var codes: Array[StringName] = []
	for issue: ContentValidationIssueScript in issues:
		codes.append(issue.code())
	return codes


func _isolated_balance_catalog(
	registry: ContentRegistryScript,
	profile_id: StringName,
) -> EnemyProfileCatalogScript:
	var source_catalog: EnemyProfileCatalogScript = registry.enemy_profile_catalog()
	var source_profile: EnemyProfileDefinitionScript = _find_profile(
		source_catalog,
		profile_id,
	)
	var result := EnemyProfileCatalogScript.new()
	result.catalog_id = source_catalog.catalog_id
	if source_profile == null:
		return result
	var source_family: EnemyFamilyDefinitionScript = _find_family(
		source_catalog,
		source_profile.family_id,
	)
	if source_family != null:
		result.families.append(EnemyFamilyDefinitionScript.snapshot(source_family))
	result.profiles.append(EnemyProfileDefinitionScript.snapshot(source_profile))
	return result


func _issue_codes(result: ContentRegistryBuildResultScript) -> Array[StringName]:
	var codes: Array[StringName] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		codes.append(issue.code())
	return codes


func _copy_family_fields(target, source: EnemyFamilyDefinitionScript) -> void:
	target.family_id = source.family_id
	target.ordinal = source.ordinal
	target.source = source.source
	target.numeric_archetype = source.numeric_archetype
	target.display_name_text_id = source.display_name_text_id
	target.regional_role_id = source.regional_role_id
	target.visual_family_id = source.visual_family_id


func _copy_profile_fields(target, source: EnemyProfileDefinitionScript) -> void:
	target.profile_id = source.profile_id
	target.family_id = source.family_id
	target.tier = source.tier
	target.source = source.source
	target.balance_contract_id = source.balance_contract_id
	target.maximum_durability = source.maximum_durability
	target.attack = source.attack
	target.defense = source.defense
	target.speed = source.speed
	target.has_alternate_state = source.has_alternate_state
	target.alternate_maximum_durability = source.alternate_maximum_durability
	target.alternate_attack = source.alternate_attack
	target.alternate_defense = source.alternate_defense
	target.alternate_speed = source.alternate_speed
	target.behavior_id = source.behavior_id
	for trait_id: StringName in source.combat_trait_ids:
		target.combat_trait_ids.append(trait_id)
	target.visual_binding_id = source.visual_binding_id


func _find_profile(
	catalog: EnemyProfileCatalogScript,
	profile_id: StringName,
) -> EnemyProfileDefinitionScript:
	for profile: EnemyProfileDefinitionScript in catalog.profiles:
		if profile != null and profile.profile_id == profile_id:
			return profile
	return null


func _find_family(
	catalog: EnemyProfileCatalogScript,
	family_id: StringName,
) -> EnemyFamilyDefinitionScript:
	for family: EnemyFamilyDefinitionScript in catalog.families:
		if family != null and family.family_id == family_id:
			return family
	return null


func _reverse_enemy_declarations(manifest: ContentManifestScript) -> void:
	manifest.enemy_profile_catalog.families.reverse()
	manifest.enemy_profile_catalog.profiles.reverse()
	for profile: EnemyProfileDefinitionScript in manifest.enemy_profile_catalog.profiles:
		profile.combat_trait_ids.reverse()


func _corrupt_for_ordering(manifest: ContentManifestScript) -> void:
	manifest.enemy_profile_catalog.families[0].display_name_text_id = (
		&"text.enemy.family.unknown"
	)
	var profile: EnemyProfileDefinitionScript = _find_profile(
		manifest.enemy_profile_catalog,
		&"enemy.profile.f12.enhanced",
	)
	profile.behavior_id = &"enemy.behavior.unknown"
	profile.combat_trait_ids.append(&"enemy.trait.unknown")


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


func _expect_fingerprint_changed(
	context: HeadlessTestContextScript,
	baseline: String,
	manifest: ContentManifestScript,
	label: String,
) -> void:
	context.expect_true(
		_fingerprint(manifest) != baseline,
		"Fingerprint must cover %s." % label,
	)


func _diagnostics(result: ContentRegistryBuildResultScript) -> String:
	if result == null:
		return "Build result is null."
	return "issues=%s" % str(result.validation_report().signatures())
