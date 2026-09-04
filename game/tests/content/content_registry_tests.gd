extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
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
const ContentLookupResultScript := preload("res://src/content/content_lookup_result.gd")
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContentValidationReportScript := preload(
	"res://src/content/content_validation_report.gd"
)
const ContentCatalogOracle := preload("res://tests/content/content_catalog_oracle.gd")
const DerivedBlueprintDefinitionScript := preload(
	"res://tests/content/support/derived_blueprint_definition_resource.gd"
)
const DerivedContentManifestScript := preload(
	"res://tests/content/support/derived_content_manifest_resource.gd"
)
const DerivedRecipeDefinitionScript := preload(
	"res://tests/content/support/derived_recipe_definition_resource.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"content_registry.builds_canonical_manifest",
			_builds_canonical_manifest,
		),
		HeadlessTestCaseScript.new(
			"content_registry.invalidates_tampered_registry_state",
			_invalidates_tampered_registry_state,
		),
		HeadlessTestCaseScript.new(
			"content_registry.matches_blueprint_oracle",
			_matches_blueprint_oracle,
		),
		HeadlessTestCaseScript.new(
			"content_registry.matches_recipe_oracle",
			_matches_recipe_oracle,
		),
		HeadlessTestCaseScript.new(
			"content_registry.matches_aggregate_invariants",
			_matches_aggregate_invariants,
		),
		HeadlessTestCaseScript.new(
			"content_registry.rejects_malformed_manifest_atomically",
			_rejects_malformed_manifest_atomically,
		),
		HeadlessTestCaseScript.new(
			"content_registry.rejects_oversized_manifest_at_header",
			_rejects_oversized_manifest_at_header,
		),
		HeadlessTestCaseScript.new(
			"content_registry.rejects_swapped_frozen_fields",
			_rejects_swapped_frozen_fields,
		),
		HeadlessTestCaseScript.new(
			"content_registry.rejects_reference_and_profile_regressions",
			_rejects_reference_and_profile_regressions,
		),
		HeadlessTestCaseScript.new(
			"content_registry.rejects_polymorphic_resources",
			_rejects_polymorphic_resources,
		),
		HeadlessTestCaseScript.new(
			"content_registry.reports_unknown_lookups",
			_reports_unknown_lookups,
		),
		HeadlessTestCaseScript.new(
			"content_registry.orders_success_deterministically",
			_orders_success_deterministically,
		),
		HeadlessTestCaseScript.new(
			"content_registry.orders_errors_deterministically",
			_orders_errors_deterministically,
		),
		HeadlessTestCaseScript.new(
			"content_registry.orders_separator_bearing_issues",
			_orders_separator_bearing_issues,
		),
		HeadlessTestCaseScript.new(
			"content_registry.isolates_input_resources",
			_isolates_input_resources,
		),
		HeadlessTestCaseScript.new(
			"content_registry.isolates_resource_loader_cache",
			_isolates_resource_loader_cache,
		),
		HeadlessTestCaseScript.new(
			"content_registry.isolates_query_results",
			_isolates_query_results,
		),
		HeadlessTestCaseScript.new(
			"content_registry.revalidates_canonical_data_deterministically",
			_revalidates_canonical_data_deterministically,
		),
	]


func _builds_canonical_manifest(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "The canonical manifest must build successfully.")
	context.expect_true(
		result.validation_report().is_valid(),
		"The canonical manifest must have no validation issues.",
	)
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	context.expect_true(
		registry.is_initialized(),
		"A successful build must publish an initialized registry.",
	)
	context.expect_equal(registry.schema_version(), 5, "Schema version must be frozen at five.")
	context.expect_equal(registry.content_version(), 5, "Content version must be frozen at five.")
	context.expect_equal(registry.blueprint_count(), 24, "The registry must contain 24 blueprints.")
	context.expect_equal(registry.recipe_count(), 24, "The registry must contain 24 recipes.")
	context.expect_equal(registry.material_count(), 3, "The registry must expose three materials.")
	context.expect_equal(
		registry.material_ids(),
		[
			&"material.building",
			&"material.crystal_sand",
			&"material.mechanism_part",
		],
		"Material IDs must use deterministic lexical order.",
	)
	context.expect_true(
		registry.has_material(&"material.building"),
		"Building material must be registered.",
	)
	context.expect_true(
		not registry.has_material(&"material.unknown"),
		"A fourth material must not be registered.",
	)
	var raw_registry := ContentRegistryScript.new()
	context.expect_true(
		not raw_registry.is_initialized(),
		"Direct construction must not bypass manifest validation.",
	)
	var no_blueprints: Array[BlueprintDefinitionScript] = []
	var no_recipes: Array[RecipeDefinitionScript] = []
	raw_registry._initialize_validated(
		999,
		999,
		no_blueprints,
		no_recipes,
		null,
		null,
		null,
	)
	context.expect_true(
		not raw_registry.is_initialized(),
		"The internal initializer must reject an unsealed content contract.",
	)
	var exposes_initialized_trust_bit: bool = false
	for property: Dictionary in raw_registry.get_property_list():
		if StringName(property.get("name", &"")) == &"_initialized":
			exposes_initialized_trust_bit = true
			break
	context.expect_true(
		not exposes_initialized_trust_bit,
		"No externally writable initialized trust bit may exist.",
	)
	context.expect_true(
		not raw_registry.is_initialized(),
		"A forged trust-bit write must not initialize an empty registry.",
	)
	var no_issues: Array[ContentValidationIssueScript] = []
	var forged_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuildResultScript.success(
			raw_registry,
			ContentValidationReportScript.new(no_issues),
		)
	)
	context.expect_true(
		not forged_result.succeeded(),
		"An empty report must not make an unsealed registry usable.",
	)
	var raw_lookup: ContentLookupResultScript = raw_registry.lookup_blueprint(
		&"blueprint.01"
	)
	context.expect_true(not raw_lookup.succeeded(), "An uninitialized registry is unusable.")
	context.expect_equal(
		raw_lookup.issue().code(),
		ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
		"Direct construction failure must be structured.",
	)
	registry._schema_version = 999
	context.expect_true(
		not registry.is_initialized(),
		"Mutating stored state must invalidate the contract instead of preserving trust.",
	)
	context.expect_true(
		not result.succeeded(),
		"A build result must re-check registry integrity when queried.",
	)
	context.expect_equal(
		result.registry(),
		null,
		"A build result must not publish a registry after its contract is invalidated.",
	)


func _invalidates_tampered_registry_state(context: HeadlessTestContextScript) -> void:
	var blueprint_order_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		blueprint_order_result.succeeded(),
		"Blueprint-order tampering needs canonical input.",
	)
	if not blueprint_order_result.succeeded():
		return
	var blueprint_order_registry: ContentRegistryScript = blueprint_order_result.registry()
	var reversed_blueprint_ids: Array[StringName] = blueprint_order_registry.blueprint_ids()
	reversed_blueprint_ids.reverse()
	blueprint_order_registry._blueprint_ids = reversed_blueprint_ids
	context.expect_true(
		not blueprint_order_registry.is_initialized(),
		"A non-canonical blueprint ID order must invalidate the registry.",
	)
	context.expect_true(
		not blueprint_order_result.succeeded(),
		"A build result must reject a registry with reordered blueprint IDs.",
	)
	context.expect_equal(
		blueprint_order_result.registry(),
		null,
		"Reordered blueprint IDs must not remain publishable.",
	)

	var recipe_order_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		recipe_order_result.succeeded(),
		"Recipe-order tampering needs canonical input.",
	)
	if not recipe_order_result.succeeded():
		return
	var recipe_order_registry: ContentRegistryScript = recipe_order_result.registry()
	var reversed_recipe_ids: Array[StringName] = recipe_order_registry.recipe_ids()
	reversed_recipe_ids.reverse()
	recipe_order_registry._recipe_ids = reversed_recipe_ids
	context.expect_true(
		not recipe_order_registry.is_initialized(),
		"A non-canonical recipe ID order must invalidate the registry.",
	)
	context.expect_true(
		not recipe_order_result.succeeded(),
		"A build result must reject a registry with reordered recipe IDs.",
	)
	context.expect_equal(
		recipe_order_result.registry(),
		null,
		"Reordered recipe IDs must not remain publishable.",
	)

	var blueprint_script_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		blueprint_script_result.succeeded(),
		"Blueprint-script tampering needs canonical input.",
	)
	if not blueprint_script_result.succeeded():
		return
	var blueprint_script_registry: ContentRegistryScript = blueprint_script_result.registry()
	var stored_blueprint: Resource = (
		blueprint_script_registry._blueprints_by_id[&"blueprint.01"] as Resource
	)
	stored_blueprint.set_script(null)
	context.expect_true(
		not blueprint_script_registry.is_initialized(),
		"A definition without the authoritative blueprint script must invalidate the registry.",
	)
	context.expect_true(
		not blueprint_script_result.succeeded(),
		"A build result must reject a script-tampered blueprint registry.",
	)
	context.expect_equal(
		blueprint_script_result.registry(),
		null,
		"A script-tampered blueprint registry must not remain publishable.",
	)

	var recipe_script_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		recipe_script_result.succeeded(),
		"Recipe-script tampering needs canonical input.",
	)
	if not recipe_script_result.succeeded():
		return
	var recipe_script_registry: ContentRegistryScript = recipe_script_result.registry()
	var stored_recipe: Resource = (
		recipe_script_registry._recipes_by_id[&"recipe.standard.01"] as Resource
	)
	stored_recipe.set_script(null)
	context.expect_true(
		not recipe_script_registry.is_initialized(),
		"A definition without the authoritative recipe script must invalidate the registry.",
	)
	context.expect_true(
		not recipe_script_result.succeeded(),
		"A build result must reject a script-tampered recipe registry.",
	)
	context.expect_equal(
		recipe_script_result.registry(),
		null,
		"A script-tampered recipe registry must not remain publishable.",
	)

	var material_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(material_result.succeeded(), "Material tampering needs canonical input.")
	if not material_result.succeeded():
		return
	var material_registry: ContentRegistryScript = material_result.registry()
	var tampered_material_ids: Array[StringName] = [&"material.building"]
	material_registry._material_ids = tampered_material_ids
	_expect_tampering_rejected(
		context,
		material_registry,
		material_result,
		"material IDs",
	)

	var dictionary_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(dictionary_result.succeeded(), "Dictionary tampering needs canonical input.")
	if not dictionary_result.succeeded():
		return
	var dictionary_registry: ContentRegistryScript = dictionary_result.registry()
	var empty_blueprint_dictionary: Dictionary[StringName, BlueprintDefinitionScript] = {}
	dictionary_registry._blueprints_by_id = empty_blueprint_dictionary
	_expect_tampering_rejected(
		context,
		dictionary_registry,
		dictionary_result,
		"blueprint dictionary",
	)

	var blueprint_field_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		blueprint_field_result.succeeded(),
		"Blueprint-field tampering needs canonical input.",
	)
	if not blueprint_field_result.succeeded():
		return
	var blueprint_field_registry: ContentRegistryScript = blueprint_field_result.registry()
	blueprint_field_registry._blueprints_by_id[&"blueprint.01"].unlock_chapter = 9
	_expect_tampering_rejected(
		context,
		blueprint_field_registry,
		blueprint_field_result,
		"blueprint fields",
	)

	var recipe_field_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		recipe_field_result.succeeded(),
		"Recipe-field tampering needs canonical input.",
	)
	if not recipe_field_result.succeeded():
		return
	var recipe_field_registry: ContentRegistryScript = recipe_field_result.registry()
	recipe_field_registry._recipes_by_id[&"recipe.standard.01"].main_quantity = 999
	_expect_tampering_rejected(
		context,
		recipe_field_registry,
		recipe_field_result,
		"recipe fields",
	)


func _matches_blueprint_oracle(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "The blueprint oracle needs a valid registry.")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var expected_ids: Array[StringName] = []
	var rows: Array[ContentCatalogOracle.BlueprintRow] = (
		ContentCatalogOracle.blueprint_rows()
	)
	context.expect_equal(rows.size(), 24, "The independent blueprint oracle must have 24 rows.")
	for row: ContentCatalogOracle.BlueprintRow in rows:
		expected_ids.append(row.content_id)
		var lookup: ContentLookupResultScript = registry.lookup_blueprint(row.content_id)
		context.expect_true(
			lookup.succeeded(),
			"Oracle blueprint '%s' must be queryable." % String(row.content_id),
		)
		if not lookup.succeeded():
			continue
		var blueprint: BlueprintDefinitionScript = lookup.blueprint()
		context.expect_equal(blueprint.content_id, row.content_id, "Blueprint ID must match.")
		context.expect_equal(blueprint.ordinal, row.ordinal, "Blueprint ordinal must match.")
		context.expect_equal(blueprint.category, row.category, "Blueprint category must match.")
		context.expect_equal(blueprint.tier, row.tier, "Blueprint tier must match.")
		context.expect_equal(
			blueprint.unlock_chapter,
			row.unlock_chapter,
			"Blueprint unlock chapter must match.",
		)
		context.expect_equal(
			blueprint.default_lifecycle,
			row.default_lifecycle,
			"Blueprint lifecycle must match.",
		)
		context.expect_equal(
			blueprint.standard_recipe_id,
			row.standard_recipe_id,
			"Blueprint standard recipe ID must match.",
		)
		context.expect_equal(
			blueprint.mechanic_id,
			row.mechanic_id,
			"Blueprint mechanic ID must match.",
		)
		context.expect_equal(
			blueprint.display_name_text_id,
			row.display_name_text_id,
			"Blueprint display-name text ID must match.",
		)
		context.expect_equal(
			blueprint.function_text_id,
			row.function_text_id,
			"Blueprint function text ID must match.",
		)
	context.expect_equal(
		registry.blueprint_ids(),
		expected_ids,
		"Blueprint IDs must follow the independent canonical order.",
	)


func _matches_recipe_oracle(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "The recipe oracle needs a valid registry.")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var expected_ids: Array[StringName] = []
	var rows: Array[ContentCatalogOracle.RecipeRow] = ContentCatalogOracle.recipe_rows()
	context.expect_equal(rows.size(), 24, "The independent recipe oracle must have 24 rows.")
	for row: ContentCatalogOracle.RecipeRow in rows:
		expected_ids.append(row.recipe_id)
		var lookup: ContentLookupResultScript = registry.lookup_recipe(row.recipe_id)
		context.expect_true(
			lookup.succeeded(),
			"Oracle recipe '%s' must be queryable." % String(row.recipe_id),
		)
		if not lookup.succeeded():
			continue
		var recipe: RecipeDefinitionScript = lookup.recipe()
		context.expect_equal(recipe.recipe_id, row.recipe_id, "Recipe ID must match.")
		context.expect_equal(
			recipe.output_blueprint_id,
			row.output_blueprint_id,
			"Recipe output blueprint ID must match.",
		)
		context.expect_equal(
			recipe.main_material_id,
			row.main_material_id,
			"Recipe main material must match.",
		)
		context.expect_equal(
			recipe.main_quantity,
			row.main_quantity,
			"Recipe main quantity must match.",
		)
		context.expect_equal(
			recipe.auxiliary_material_id,
			row.auxiliary_material_id,
			"Recipe auxiliary material must match.",
		)
		context.expect_equal(
			recipe.auxiliary_quantity,
			row.auxiliary_quantity,
			"Recipe auxiliary quantity must match.",
		)
	context.expect_equal(
		registry.recipe_ids(),
		expected_ids,
		"Recipe IDs must follow the independent canonical order.",
	)


func _matches_aggregate_invariants(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "Aggregate checks need a valid registry.")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var category_counts: Dictionary[int, int] = {}
	var tier_counts: Dictionary[int, int] = {}
	var lifecycle_counts: Dictionary[int, int] = {}
	var unlock_counts: Dictionary[int, int] = {}
	var advanced_ordinals: Array[int] = []
	var profile_counts: Dictionary[String, int] = {}
	for blueprint: BlueprintDefinitionScript in registry.blueprints():
		ContentValidationSupportScript.increment_int_count(category_counts, blueprint.category)
		ContentValidationSupportScript.increment_int_count(tier_counts, blueprint.tier)
		ContentValidationSupportScript.increment_int_count(lifecycle_counts, blueprint.default_lifecycle)
		ContentValidationSupportScript.increment_int_count(unlock_counts, blueprint.unlock_chapter)
		if blueprint.tier == BlueprintDefinitionScript.Tier.ADVANCED:
			advanced_ordinals.append(blueprint.ordinal)
		var profile_key: String = "%d:%d" % [blueprint.tier, blueprint.default_lifecycle]
		profile_counts[profile_key] = profile_counts.get(profile_key, 0) + 1
	context.expect_equal(
		category_counts,
		{1: 7, 2: 7, 3: 4, 4: 1, 5: 5},
		"Category counts must match the frozen product contract.",
	)
	context.expect_equal(tier_counts, {1: 16, 2: 8}, "Tier counts must be 16 and 8.")
	context.expect_equal(
		lifecycle_counts,
		{1: 16, 2: 8},
		"Lifecycle counts must be 16 recoverable and 8 consumable.",
	)
	context.expect_equal(
		unlock_counts,
		{1: 4, 2: 4, 3: 4, 4: 2, 5: 3, 6: 3, 7: 2, 8: 2},
		"Unlock counts must match chapters one through eight; chapter nine has zero.",
	)
	context.expect_equal(
		advanced_ordinals,
		[6, 7, 13, 14, 18, 19, 23, 24],
		"Advanced ordinals must match the fixed set.",
	)
	context.expect_equal(
		profile_counts,
		{"1:1": 11, "1:2": 5, "2:1": 5, "2:2": 3},
		"The four recipe profiles must have their fixed counts.",
	)

	var material_totals: Dictionary[StringName, int] = {
		&"material.building": 0,
		&"material.mechanism_part": 0,
		&"material.crystal_sand": 0,
	}
	for recipe: RecipeDefinitionScript in registry.recipes():
		context.expect_true(
			registry.has_material(recipe.main_material_id),
			"Every main material must be on the whitelist.",
		)
		material_totals[recipe.main_material_id] += recipe.main_quantity
		if recipe.auxiliary_material_id.is_empty():
			context.expect_equal(
				recipe.auxiliary_quantity,
				0,
				"A missing auxiliary material must have quantity zero.",
			)
		else:
			context.expect_true(
				registry.has_material(recipe.auxiliary_material_id),
				"Every auxiliary material must be on the whitelist.",
			)
			context.expect_true(
				recipe.main_material_id != recipe.auxiliary_material_id,
				"Main and auxiliary materials must differ.",
			)
			material_totals[recipe.auxiliary_material_id] += recipe.auxiliary_quantity
	context.expect_equal(
		material_totals,
		{
			&"material.building": 28,
			&"material.mechanism_part": 37,
			&"material.crystal_sand": 12,
		},
		"One copy of every recipe must total the frozen material oracle.",
	)


func _rejects_malformed_manifest_atomically(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "The malformed fixture needs canonical input.")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.schema_version = 4
	manifest.content_version = 4
	manifest.blueprints[0].content_id = manifest.blueprints[1].content_id
	manifest.blueprints[0].category = 99
	manifest.blueprints[0].unlock_chapter = 0
	manifest.blueprints[0].mechanic_id = manifest.blueprints[1].mechanic_id
	manifest.recipes[0].output_blueprint_id = &"blueprint.unknown"
	manifest.recipes[0].main_material_id = &"material.fourth"
	manifest.recipes[0].main_quantity = 0
	manifest.recipes[0].auxiliary_material_id = &"material.fourth"
	manifest.recipes[0].auxiliary_quantity = -1

	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "Malformed content must fail validation.")
	context.expect_equal(
		result.registry(),
		null,
		"A failed build must not expose a partially usable registry.",
	)
	var expected_codes: Array[StringName] = [
		ContentValidationIssueScript.MANIFEST_SCHEMA_VERSION_UNSUPPORTED,
		ContentValidationIssueScript.MANIFEST_CONTENT_VERSION_UNSUPPORTED,
		ContentValidationIssueScript.BLUEPRINT_CONTENT_ID_DUPLICATE,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_INVALID,
		ContentValidationIssueScript.BLUEPRINT_UNLOCK_CHAPTER_INVALID,
		ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_DUPLICATE,
		ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_UNKNOWN,
		ContentValidationIssueScript.RECIPE_MAIN_MATERIAL_ID_INVALID,
		ContentValidationIssueScript.RECIPE_MAIN_QUANTITY_INVALID,
		ContentValidationIssueScript.RECIPE_AUXILIARY_MATERIAL_ID_INVALID,
		ContentValidationIssueScript.RECIPE_AUXILIARY_QUANTITY_INVALID,
	]
	var actual_codes: Array[StringName] = _issue_codes(result)
	for expected_code: StringName in expected_codes:
		context.expect_true(
			actual_codes.has(expected_code),
			"Aggregated validation must include '%s'." % String(expected_code),
		)
	context.expect_true(
		result.validation_report().issue_count() >= expected_codes.size(),
		"Validation must aggregate independent errors instead of failing fast.",
	)


func _rejects_oversized_manifest_at_header(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "The oversized fixture needs canonical input.")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.blueprints.resize(4096)
	manifest.recipes.resize(4096)
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(not result.succeeded(), "An oversized manifest must fail validation.")
	context.expect_equal(result.registry(), null, "Oversized input must fail closed.")
	context.expect_equal(
		_issue_codes(result),
		[
			ContentValidationIssueScript.MANIFEST_BLUEPRINT_COUNT_INVALID,
			ContentValidationIssueScript.MANIFEST_RECIPE_COUNT_INVALID,
		],
		"Count-invalid input must stop at the bounded manifest-header validation.",
	)


func _rejects_swapped_frozen_fields(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "The swap fixture needs canonical input.")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	_swap_blueprint_category(manifest.blueprints[0], manifest.blueprints[7])
	_swap_blueprint_unlock(manifest.blueprints[0], manifest.blueprints[2])
	_swap_blueprint_lifecycle(manifest.blueprints[14], manifest.blueprints[15])
	_swap_blueprint_mechanic(manifest.blueprints[0], manifest.blueprints[1])
	_swap_recipe_main_material(manifest.recipes[14], manifest.recipes[16])
	_swap_recipe_auxiliary_material(manifest.recipes[5], manifest.recipes[12])

	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(
		not result.succeeded(),
		"Swapping equal-count frozen values between ordinals must still fail.",
	)
	context.expect_equal(result.registry(), null, "Swapped content must fail closed.")
	var actual_codes: Array[StringName] = _issue_codes(result)
	var expected_codes: Array[StringName] = [
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_ORDINAL_MISMATCH,
		ContentValidationIssueScript.BLUEPRINT_UNLOCK_CHAPTER_ORDINAL_MISMATCH,
		ContentValidationIssueScript.BLUEPRINT_LIFECYCLE_ORDINAL_MISMATCH,
		ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_ORDINAL_MISMATCH,
		ContentValidationIssueScript.RECIPE_MATERIAL_MAPPING_MISMATCH,
	]
	for expected_code: StringName in expected_codes:
		context.expect_true(
			actual_codes.has(expected_code),
			"Frozen per-ordinal validation must include '%s'." % String(expected_code),
		)


func _rejects_reference_and_profile_regressions(
	context: HeadlessTestContextScript,
) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "Reference fixtures need canonical input.")
	if not canonical.succeeded():
		return

	var mismatch_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	mismatch_manifest.recipes[0].output_blueprint_id = &"blueprint.02"
	var mismatch_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(mismatch_manifest)
	)
	context.expect_true(not mismatch_result.succeeded(), "A mismatched output must fail.")
	context.expect_equal(mismatch_result.registry(), null, "Reference mismatch must fail closed.")
	var mismatch_codes: Array[StringName] = _issue_codes(mismatch_result)
	context.expect_true(
		mismatch_codes.has(
			ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_MISMATCH
		),
		"Output-to-recipe ordinal mismatch must remain validated.",
	)
	context.expect_true(
		mismatch_codes.has(
			ContentValidationIssueScript.RECIPE_BLUEPRINT_REFERENCE_MISMATCH
		),
		"Recipe-to-blueprint reverse mismatch must remain validated.",
	)

	var missing_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	missing_manifest.recipes[0].recipe_id = &"recipe.standard.25"
	var missing_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(missing_manifest)
	)
	context.expect_true(not missing_result.succeeded(), "A missing standard recipe must fail.")
	context.expect_equal(missing_result.registry(), null, "Missing reverse reference must fail closed.")
	var missing_codes: Array[StringName] = _issue_codes(missing_result)
	context.expect_true(
		missing_codes.has(ContentValidationIssueScript.RECIPE_ID_MISSING),
		"Missing frozen recipe ID must remain validated.",
	)
	context.expect_true(
		missing_codes.has(
			ContentValidationIssueScript.RECIPE_BLUEPRINT_REFERENCE_MISSING
		),
		"Blueprint-to-recipe missing reference must remain validated.",
	)

	var profile_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	profile_manifest.recipes[0].main_quantity = 4
	profile_manifest.recipes[14].main_quantity = 2
	profile_manifest.recipes[5].main_quantity = 5
	profile_manifest.recipes[17].main_quantity = 3
	var profile_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(profile_manifest)
	)
	context.expect_true(
		not profile_result.succeeded(),
		"Positive but wrong quantities in all four profiles must fail.",
	)
	context.expect_equal(profile_result.registry(), null, "Wrong profiles must fail closed.")
	context.expect_equal(
		_issue_content_ids(
			profile_result,
			ContentValidationIssueScript.RECIPE_PROFILE_MISMATCH,
		),
		[
			&"recipe.standard.01",
			&"recipe.standard.06",
			&"recipe.standard.15",
			&"recipe.standard.18",
		],
		"Each of the four quantity profiles must emit a structured mismatch.",
	)


func _rejects_polymorphic_resources(context: HeadlessTestContextScript) -> void:
	var null_manifest_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null)
	)
	context.expect_true(not null_manifest_result.succeeded(), "A null manifest must fail.")
	context.expect_true(
		_issue_codes(null_manifest_result).has(
			ContentValidationIssueScript.MANIFEST_LOAD_FAILED
		),
		"Null manifest rejection must be structured.",
	)
	var derived_manifest: Resource = DerivedContentManifestScript.new()
	var derived_manifest_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(derived_manifest)
	)
	context.expect_true(
		not derived_manifest_result.succeeded(),
		"A manifest subclass must be rejected.",
	)
	context.expect_true(
		_issue_codes(derived_manifest_result).has(
			ContentValidationIssueScript.MANIFEST_INVALID_SCRIPT
		),
		"Manifest subclass rejection must be structured.",
	)

	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "Entry subclass checks need canonical input.")
	if not canonical.succeeded():
		return
	var blueprint_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	var derived_blueprint: BlueprintDefinitionScript = (
		DerivedBlueprintDefinitionScript.new()
	)
	blueprint_manifest.blueprints[0] = derived_blueprint
	var blueprint_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(blueprint_manifest)
	)
	context.expect_true(not blueprint_result.succeeded(), "A blueprint subclass must fail.")
	context.expect_true(
		_issue_codes(blueprint_result).has(
			ContentValidationIssueScript.BLUEPRINT_ENTRY_INVALID_SCRIPT
		),
		"Blueprint subclass rejection must be structured.",
	)
	context.expect_equal(
		_issue_field_paths(
			blueprint_result,
			ContentValidationIssueScript.BLUEPRINT_ENTRY_INVALID_SCRIPT,
		),
		["blueprints[0]"],
		"A rejected blueprint subclass must identify its manifest index.",
	)

	var recipe_manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var derived_recipe: RecipeDefinitionScript = DerivedRecipeDefinitionScript.new()
	recipe_manifest.recipes[0] = derived_recipe
	var recipe_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(recipe_manifest)
	)
	context.expect_true(not recipe_result.succeeded(), "A recipe subclass must fail.")
	context.expect_true(
		_issue_codes(recipe_result).has(
			ContentValidationIssueScript.RECIPE_ENTRY_INVALID_SCRIPT
		),
		"Recipe subclass rejection must be structured.",
	)
	context.expect_equal(
		_issue_field_paths(
			recipe_result,
			ContentValidationIssueScript.RECIPE_ENTRY_INVALID_SCRIPT,
		),
		["recipes[0]"],
		"A rejected recipe subclass must identify its manifest index.",
	)

	var null_entry_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	null_entry_manifest.blueprints[0] = null
	null_entry_manifest.blueprints[1] = null
	null_entry_manifest.recipes[0] = null
	null_entry_manifest.recipes[1] = null
	var null_entry_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(null_entry_manifest)
	)
	context.expect_true(not null_entry_result.succeeded(), "Null entries must fail.")
	var null_entry_codes: Array[StringName] = _issue_codes(null_entry_result)
	context.expect_true(
		null_entry_codes.has(ContentValidationIssueScript.BLUEPRINT_ENTRY_NULL),
		"Null blueprint rejection must be structured.",
	)
	context.expect_true(
		null_entry_codes.has(ContentValidationIssueScript.RECIPE_ENTRY_NULL),
		"Null recipe rejection must be structured.",
	)
	var null_blueprint_paths: Array[String] = []
	var null_recipe_paths: Array[String] = []
	for issue: ContentValidationIssueScript in null_entry_result.validation_report().issues():
		if issue.code() == ContentValidationIssueScript.BLUEPRINT_ENTRY_NULL:
			null_blueprint_paths.append(issue.field_path())
		elif issue.code() == ContentValidationIssueScript.RECIPE_ENTRY_NULL:
			null_recipe_paths.append(issue.field_path())
	context.expect_equal(
		null_blueprint_paths,
		["blueprints[0]", "blueprints[1]"],
		"Each null blueprint issue must identify its manifest index.",
	)
	context.expect_equal(
		null_recipe_paths,
		["recipes[0]", "recipes[1]"],
		"Each null recipe issue must identify its manifest index.",
	)


func _reports_unknown_lookups(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "Unknown lookup checks need a valid registry.")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var blueprint_lookup: ContentLookupResultScript = registry.lookup_blueprint(
		&"blueprint.unknown"
	)
	context.expect_true(not blueprint_lookup.succeeded(), "Unknown blueprint lookup must fail.")
	context.expect_equal(
		blueprint_lookup.kind(),
		ContentLookupResultScript.Kind.BLUEPRINT,
		"Unknown blueprint lookup must retain its query kind.",
	)
	context.expect_equal(blueprint_lookup.blueprint(), null, "Unknown lookup has no blueprint.")
	context.expect_equal(
		blueprint_lookup.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_BLUEPRINT_ID,
		"Unknown blueprint lookup must expose a stable code.",
	)
	context.expect_equal(
		blueprint_lookup.issue().content_id(),
		&"blueprint.unknown",
		"Unknown blueprint lookup must retain the requested ID.",
	)
	context.expect_equal(
		blueprint_lookup.issue().field_path(),
		"content_id",
		"Unknown blueprint lookup must identify the field.",
	)

	var recipe_lookup: ContentLookupResultScript = registry.lookup_recipe(
		&"recipe.standard.unknown"
	)
	context.expect_true(not recipe_lookup.succeeded(), "Unknown recipe lookup must fail.")
	context.expect_equal(recipe_lookup.recipe(), null, "Unknown lookup has no recipe.")
	context.expect_equal(
		recipe_lookup.issue().code(),
		ContentValidationIssueScript.LOOKUP_UNKNOWN_RECIPE_ID,
		"Unknown recipe lookup must expose a stable code.",
	)
	context.expect_equal(
		recipe_lookup.issue().content_id(),
		&"recipe.standard.unknown",
		"Unknown recipe lookup must retain the requested ID.",
	)
	context.expect_equal(
		recipe_lookup.issue().field_path(),
		"recipe_id",
		"Unknown recipe lookup must identify the field.",
	)


func _orders_success_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "Ordering checks need canonical input.")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	manifest.blueprints.reverse()
	manifest.recipes.reverse()
	var reversed_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(manifest)
	)
	context.expect_true(
		reversed_result.succeeded(),
		"Reversing manifest declarations must not invalidate content.",
	)
	if not reversed_result.succeeded():
		return
	context.expect_equal(
		reversed_result.registry().blueprint_ids(),
		canonical.registry().blueprint_ids(),
		"Blueprint query order must not depend on manifest order.",
	)
	context.expect_equal(
		reversed_result.registry().recipe_ids(),
		canonical.registry().recipe_ids(),
		"Recipe query order must not depend on manifest order.",
	)
	context.expect_equal(
		reversed_result.registry().material_ids(),
		canonical.registry().material_ids(),
		"Material query order must be stable.",
	)


func _orders_errors_deterministically(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "Error ordering checks need canonical input.")
	if not canonical.succeeded():
		return
	var forward_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	var reverse_manifest: ContentManifestScript = _manifest_from_registry(
		canonical.registry()
	)
	_corrupt_for_ordering(forward_manifest)
	_corrupt_for_ordering(reverse_manifest)
	reverse_manifest.blueprints.reverse()
	reverse_manifest.recipes.reverse()
	var forward_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(forward_manifest)
	)
	var reverse_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(reverse_manifest)
	)
	context.expect_true(not forward_result.succeeded(), "Forward corrupt input must fail.")
	context.expect_true(not reverse_result.succeeded(), "Reverse corrupt input must fail.")
	context.expect_equal(forward_result.registry(), null, "Forward failure must be atomic.")
	context.expect_equal(reverse_result.registry(), null, "Reverse failure must be atomic.")
	context.expect_equal(
		forward_result.validation_report().signatures(),
		reverse_result.validation_report().signatures(),
		"Validation issue order must not depend on manifest order.",
	)


func _orders_separator_bearing_issues(context: HeadlessTestContextScript) -> void:
	var separator: String = String.chr(31)
	var left_issue := ContentValidationIssueScript.new(
		&"sort.code",
		&"sort.subject",
		"field%smessage" % separator,
		"tail",
	)
	var right_issue := ContentValidationIssueScript.new(
		&"sort.code",
		&"sort.subject",
		"field",
		"message%stail" % separator,
	)
	context.expect_true(
		ContentRegistryBuilderScript._issue_less_than(right_issue, left_issue),
		"Field-wise ordering must distinguish values that collide when separator-joined.",
	)
	context.expect_true(
		not ContentRegistryBuilderScript._issue_less_than(left_issue, right_issue),
		"The deterministic issue comparator must remain asymmetric.",
	)
	var signature_collision_candidates: Array[ContentValidationIssueScript] = [
		ContentValidationIssueScript.new(
			&"signature.code",
			&"signature.subject",
			"field|message",
			"tail",
		),
		ContentValidationIssueScript.new(
			&"signature.code",
			&"signature.subject",
			"field",
			"message|tail",
		),
	]
	var signatures: Array[String] = (
		ContentValidationReportScript.new(signature_collision_candidates).signatures()
	)
	context.expect_true(
		signatures[0] != signatures[1],
		"Structured issue signatures must remain unambiguous with embedded separators.",
	)


func _isolates_input_resources(context: HeadlessTestContextScript) -> void:
	var canonical: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(canonical.succeeded(), "Input isolation needs canonical input.")
	if not canonical.succeeded():
		return
	var manifest: ContentManifestScript = _manifest_from_registry(canonical.registry())
	var source_blueprint: BlueprintDefinitionScript = manifest.blueprints[0]
	var source_recipe: RecipeDefinitionScript = manifest.recipes[0]
	var result: ContentRegistryBuildResultScript = ContentRegistryBuilderScript.build(manifest)
	context.expect_true(result.succeeded(), "Copied input must build before mutation.")
	if not result.succeeded():
		return
	source_blueprint.mechanic_id = &"mechanic.blueprint.tampered"
	source_blueprint.unlock_chapter = 9
	source_recipe.main_material_id = &"material.tampered"
	source_recipe.main_quantity = 999
	manifest.blueprints.clear()
	manifest.recipes.clear()

	var blueprint_lookup: ContentLookupResultScript = result.registry().lookup_blueprint(
		&"blueprint.01"
	)
	var recipe_lookup: ContentLookupResultScript = result.registry().lookup_recipe(
		&"recipe.standard.01"
	)
	context.expect_true(blueprint_lookup.succeeded(), "Stored blueprint must remain queryable.")
	context.expect_true(recipe_lookup.succeeded(), "Stored recipe must remain queryable.")
	context.expect_equal(
		blueprint_lookup.blueprint().mechanic_id,
		&"mechanic.blueprint.support_surface",
		"Mutating the source blueprint must not alter the registry snapshot.",
	)
	context.expect_equal(
		blueprint_lookup.blueprint().unlock_chapter,
		1,
		"Mutating source metadata must not alter the registry snapshot.",
	)
	context.expect_equal(
		recipe_lookup.recipe().main_material_id,
		&"material.building",
		"Mutating the source recipe must not alter the registry snapshot.",
	)
	context.expect_equal(
		recipe_lookup.recipe().main_quantity,
		3,
		"Mutating source quantities must not alter the registry snapshot.",
	)
	context.expect_equal(result.registry().blueprint_count(), 24, "Clearing input must not shrink registry.")
	context.expect_equal(result.registry().recipe_count(), 24, "Clearing input must not shrink registry.")


func _isolates_resource_loader_cache(context: HeadlessTestContextScript) -> void:
	var loaded_resource: Resource = ResourceLoader.load(
		ContentRegistryBuilderScript.CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_REUSE,
	)
	context.expect_true(loaded_resource != null, "The cache fixture must load the manifest.")
	if loaded_resource == null:
		return
	context.expect_true(
		loaded_resource.get_script() == ContentManifestScript,
		"The cache fixture must load the exact manifest script.",
	)
	if loaded_resource.get_script() != ContentManifestScript:
		return
	var cached_manifest: ContentManifestScript = loaded_resource as ContentManifestScript
	var original_category: int = cached_manifest.blueprints[0].category
	cached_manifest.blueprints[0].category = 99
	var isolated_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	cached_manifest.blueprints[0].category = original_category
	context.expect_true(
		isolated_result.succeeded(),
		"Canonical loading must ignore a mutated shared ResourceLoader cache.",
	)
	if not isolated_result.succeeded():
		return
	context.expect_equal(
		isolated_result.registry().lookup_blueprint(&"blueprint.01").blueprint().category,
		BlueprintDefinitionScript.Category.STRUCTURE,
		"Canonical deep-ignore loading must preserve the on-disk category.",
	)


func _isolates_query_results(context: HeadlessTestContextScript) -> void:
	var result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(result.succeeded(), "Query isolation needs a valid registry.")
	if not result.succeeded():
		return
	var registry: ContentRegistryScript = result.registry()
	var blueprint_ids: Array[StringName] = registry.blueprint_ids()
	var recipe_ids: Array[StringName] = registry.recipe_ids()
	var material_ids: Array[StringName] = registry.material_ids()
	blueprint_ids.append(&"blueprint.tampered")
	recipe_ids.clear()
	material_ids.append(&"material.tampered")
	context.expect_equal(registry.blueprint_ids().size(), 24, "Blueprint IDs must be copied.")
	context.expect_equal(registry.recipe_ids().size(), 24, "Recipe IDs must be copied.")
	context.expect_equal(registry.material_ids().size(), 3, "Material IDs must be copied.")

	var blueprints: Array[BlueprintDefinitionScript] = registry.blueprints()
	var recipes: Array[RecipeDefinitionScript] = registry.recipes()
	blueprints[0].mechanic_id = &"mechanic.blueprint.tampered"
	recipes[0].main_quantity = 999
	blueprints.clear()
	recipes.clear()
	var blueprint_lookup: ContentLookupResultScript = registry.lookup_blueprint(&"blueprint.01")
	var recipe_lookup: ContentLookupResultScript = registry.lookup_recipe(
		&"recipe.standard.01"
	)
	context.expect_equal(
		blueprint_lookup.blueprint().mechanic_id,
		&"mechanic.blueprint.support_surface",
		"Mutating a collection result must not alter stored blueprints.",
	)
	context.expect_equal(
		recipe_lookup.recipe().main_quantity,
		3,
		"Mutating a collection result must not alter stored recipes.",
	)
	var returned_blueprint: BlueprintDefinitionScript = blueprint_lookup.blueprint()
	var returned_recipe: RecipeDefinitionScript = recipe_lookup.recipe()
	returned_blueprint.unlock_chapter = 9
	returned_recipe.main_material_id = &"material.tampered"
	context.expect_equal(
		blueprint_lookup.blueprint().unlock_chapter,
		1,
		"A lookup result must return a new blueprint snapshot on every getter call.",
	)
	context.expect_equal(
		recipe_lookup.recipe().main_material_id,
		&"material.building",
		"A lookup result must return a new recipe snapshot on every getter call.",
	)
	context.expect_equal(
		registry.lookup_blueprint(&"blueprint.01").blueprint().unlock_chapter,
		1,
		"Mutating a lookup blueprint must not alter later lookups.",
	)
	context.expect_equal(
		registry.lookup_recipe(&"recipe.standard.01").recipe().main_material_id,
		&"material.building",
		"Mutating a lookup recipe must not alter later lookups.",
	)

	var unknown_lookup: ContentLookupResultScript = registry.lookup_blueprint(&"unknown")
	var returned_issue: ContentValidationIssueScript = unknown_lookup.issue()
	returned_issue._message = "tampered"
	context.expect_true(
		unknown_lookup.issue().message() != "tampered",
		"A lookup result must return a new issue snapshot on every getter call.",
	)
	context.expect_true(
		registry.lookup_blueprint(&"unknown").issue().message() != "tampered",
		"Lookup issues must be returned as snapshots.",
	)

	var invalid_manifest: ContentManifestScript = _manifest_from_registry(registry)
	invalid_manifest.schema_version = 4
	var invalid_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build(invalid_manifest)
	)
	var original_signatures: Array[String] = (
		invalid_result.validation_report().signatures()
	)
	var returned_issues: Array[ContentValidationIssueScript] = (
		invalid_result.validation_report().issues()
	)
	returned_issues[0]._message = "tampered"
	returned_issues.clear()
	context.expect_equal(
		invalid_result.validation_report().signatures(),
		original_signatures,
		"Validation reports must return defensive issue snapshots.",
	)


func _revalidates_canonical_data_deterministically(
	context: HeadlessTestContextScript,
) -> void:
	var first: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	var second: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(first.succeeded(), "The first canonical build must succeed.")
	context.expect_true(second.succeeded(), "The second canonical build must succeed.")
	if not first.succeeded() or not second.succeeded():
		return
	context.expect_true(
		first.registry() != second.registry(),
		"Repeated canonical builds must create isolated registry instances.",
	)
	context.expect_equal(
		first.registry().blueprint_ids(),
		second.registry().blueprint_ids(),
		"Repeated builds must return identical blueprint order.",
	)
	context.expect_equal(
		first.registry().recipe_ids(),
		second.registry().recipe_ids(),
		"Repeated builds must return identical recipe order.",
	)
	context.expect_equal(
		first.validation_report().signatures(),
		second.validation_report().signatures(),
		"Repeated validation must return identical reports.",
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
	return manifest


func _expect_tampering_rejected(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	result: ContentRegistryBuildResultScript,
	tampered_surface: String,
) -> void:
	context.expect_true(
		not registry.is_initialized(),
		"Tampered %s must invalidate the registry." % tampered_surface,
	)
	context.expect_true(
		not result.succeeded(),
		"Tampered %s must invalidate the build result." % tampered_surface,
	)
	context.expect_equal(
		result.registry(),
		null,
		"Tampered %s must not remain publishable." % tampered_surface,
	)


func _issue_codes(result: ContentRegistryBuildResultScript) -> Array[StringName]:
	var codes: Array[StringName] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		codes.append(issue.code())
	return codes


func _issue_content_ids(
	result: ContentRegistryBuildResultScript,
	code: StringName,
) -> Array[StringName]:
	var content_ids: Array[StringName] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		if issue.code() == code:
			content_ids.append(issue.content_id())
	return content_ids


func _issue_field_paths(
	result: ContentRegistryBuildResultScript,
	code: StringName,
) -> Array[String]:
	var field_paths: Array[String] = []
	for issue: ContentValidationIssueScript in result.validation_report().issues():
		if issue.code() == code:
			field_paths.append(issue.field_path())
	return field_paths


func _corrupt_for_ordering(manifest: ContentManifestScript) -> void:
	manifest.blueprints[4].category = 99
	manifest.blueprints[1].mechanic_id = manifest.blueprints[0].mechanic_id
	manifest.recipes[7].main_quantity = 0
	manifest.recipes[8].output_blueprint_id = &"blueprint.unknown"


func _swap_blueprint_category(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> void:
	var temporary: int = left.category
	left.category = right.category
	right.category = temporary


func _swap_blueprint_unlock(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> void:
	var temporary: int = left.unlock_chapter
	left.unlock_chapter = right.unlock_chapter
	right.unlock_chapter = temporary


func _swap_blueprint_lifecycle(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> void:
	var temporary: int = left.default_lifecycle
	left.default_lifecycle = right.default_lifecycle
	right.default_lifecycle = temporary


func _swap_blueprint_mechanic(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> void:
	var temporary: StringName = left.mechanic_id
	left.mechanic_id = right.mechanic_id
	right.mechanic_id = temporary


func _swap_recipe_main_material(
	left: RecipeDefinitionScript,
	right: RecipeDefinitionScript,
) -> void:
	var temporary: StringName = left.main_material_id
	left.main_material_id = right.main_material_id
	right.main_material_id = temporary


func _swap_recipe_auxiliary_material(
	left: RecipeDefinitionScript,
	right: RecipeDefinitionScript,
) -> void:
	var temporary: StringName = left.auxiliary_material_id
	left.auxiliary_material_id = right.auxiliary_material_id
	right.auxiliary_material_id = temporary
