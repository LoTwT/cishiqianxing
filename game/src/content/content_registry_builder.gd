class_name ContentRegistryBuilder
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
const ContentRegistryBuildResultScript := preload(
	"res://src/content/content_registry_build_result.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContentValidationReportScript := preload(
	"res://src/content/content_validation_report.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const GlobalProgressionValidatorScript := preload(
	"res://src/content/global_progression_validator.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const RepresentativeRouteValidatorScript := preload(
	"res://src/content/representative_route_contract_validator.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
)
const EnemyProfileValidatorScript := preload(
	"res://src/content/enemy_profile_validator.gd"
)

const CANONICAL_MANIFEST_PATH: String = "res://content/content_manifest.tres"
const SUPPORTED_SCHEMA_VERSION: int = 5
const SUPPORTED_CONTENT_VERSION: int = 5
const EXPECTED_DEFINITION_COUNT: int = 24
const ADVANCED_ORDINALS: Array[int] = [6, 7, 13, 14, 18, 19, 23, 24]
const EXPECTED_CATEGORIES: Array[int] = [
	1, 1, 1, 1, 1, 1, 1,
	2, 2, 2, 2, 2, 2, 2,
	3, 3, 3, 3,
	4,
	5, 5, 5, 5, 5,
]
const EXPECTED_UNLOCK_CHAPTERS: Array[int] = [
	1, 1, 2, 3, 2, 4, 7,
	1, 3, 2, 5, 3, 5, 6,
	1, 2, 3, 7, 5, 4, 6, 6, 8, 8,
]
const EXPECTED_LIFECYCLES: Array[int] = [
	1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1,
	2, 1, 2, 2, 1, 2, 2, 2, 2, 2,
]
const EXPECTED_MECHANIC_IDS: Array[StringName] = [
	&"mechanic.blueprint.support_surface",
	&"mechanic.blueprint.height_connector",
	&"mechanic.blueprint.platform_extension",
	&"mechanic.blueprint.blocking_wall",
	&"mechanic.blueprint.environment_anchor",
	&"mechanic.blueprint.climbable_scaffold",
	&"mechanic.blueprint.anchored_platform_extension",
	&"mechanic.blueprint.occupancy_signal",
	&"mechanic.blueprint.toggle_signal",
	&"mechanic.blueprint.signal_conduit",
	&"mechanic.blueprint.one_step_delay",
	&"mechanic.blueprint.directional_push",
	&"mechanic.blueprint.same_step_sync",
	&"mechanic.blueprint.reciprocating_push",
	&"mechanic.blueprint.restore_health",
	&"mechanic.blueprint.survey_reveal",
	&"mechanic.blueprint.repair_target",
	&"mechanic.blueprint.restore_health_and_repair",
	&"mechanic.blueprint.survey_and_remote_recover",
	&"mechanic.blueprint.next_battle_attack",
	&"mechanic.blueprint.next_battle_defense",
	&"mechanic.blueprint.next_battle_speed",
	&"mechanic.blueprint.next_battle_attack_speed",
	&"mechanic.blueprint.next_battle_attack_defense",
]
const EXPECTED_MAIN_MATERIAL_IDS: Array[StringName] = [
	&"material.building", &"material.building", &"material.building",
	&"material.building", &"material.building", &"material.building",
	&"material.building",
	&"material.mechanism_part", &"material.mechanism_part",
	&"material.mechanism_part", &"material.mechanism_part",
	&"material.mechanism_part", &"material.mechanism_part",
	&"material.mechanism_part",
	&"material.crystal_sand", &"material.mechanism_part", &"material.building",
	&"material.crystal_sand", &"material.mechanism_part",
	&"material.crystal_sand", &"material.crystal_sand", &"material.crystal_sand",
	&"material.crystal_sand", &"material.crystal_sand",
]
const EXPECTED_AUXILIARY_MATERIAL_IDS: Array[StringName] = [
	&"", &"", &"", &"", &"",
	&"material.mechanism_part", &"material.mechanism_part",
	&"", &"", &"", &"", &"",
	&"material.building", &"material.building",
	&"", &"", &"",
	&"material.mechanism_part", &"material.crystal_sand",
	&"", &"", &"",
	&"material.mechanism_part", &"material.mechanism_part",
]


static func build_canonical() -> ContentRegistryBuildResultScript:
	if not ResourceLoader.exists(CANONICAL_MANIFEST_PATH, "Resource"):
		return _failure_with_single_issue(
			ContentValidationIssueScript.MANIFEST_LOAD_FAILED,
			&"",
			"manifest",
			"Canonical content manifest is missing at '%s'."
			% CANONICAL_MANIFEST_PATH,
		)
	var loaded_manifest: Resource = ResourceLoader.load(
		CANONICAL_MANIFEST_PATH,
		"Resource",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP,
	)
	if loaded_manifest == null:
		return _failure_with_single_issue(
			ContentValidationIssueScript.MANIFEST_LOAD_FAILED,
			&"",
			"manifest",
			"Canonical content manifest could not be loaded from '%s'."
			% CANONICAL_MANIFEST_PATH,
		)
	return build(loaded_manifest)


static func build(manifest: Resource) -> ContentRegistryBuildResultScript:
	var issues: Array[ContentValidationIssueScript] = []
	if manifest == null:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_LOAD_FAILED,
			&"",
			"manifest",
			"Content manifest is null.",
		)
		return _failure(issues)
	if manifest.get_script() != ContentManifestScript:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_INVALID_SCRIPT,
			&"",
			"manifest",
			"Content manifest must use the exact authoritative manifest script.",
		)
		return _failure(issues)

	var exact_manifest: ContentManifestScript = manifest as ContentManifestScript
	var schema_version: int = exact_manifest.schema_version
	var content_version: int = exact_manifest.content_version
	_validate_manifest_header(
		schema_version,
		content_version,
		exact_manifest.blueprints.size(),
		exact_manifest.recipes.size(),
		issues,
	)
	if (
		exact_manifest.blueprints.size() != EXPECTED_DEFINITION_COUNT
		or exact_manifest.recipes.size() != EXPECTED_DEFINITION_COUNT
	):
		return _failure(issues)
	var raw_blueprints: Array[BlueprintDefinitionScript] = []
	var raw_recipes: Array[RecipeDefinitionScript] = []
	for blueprint: BlueprintDefinitionScript in exact_manifest.blueprints:
		raw_blueprints.append(blueprint)
	for recipe: RecipeDefinitionScript in exact_manifest.recipes:
		raw_recipes.append(recipe)

	var blueprints: Array[BlueprintDefinitionScript] = _snapshot_blueprints(
		raw_blueprints,
		issues,
	)
	var recipes: Array[RecipeDefinitionScript] = _snapshot_recipes(
		raw_recipes,
		issues,
	)
	var progression_catalog: GlobalProgressionCatalogScript = (
		GlobalProgressionValidatorScript.snapshot_and_validate(
			exact_manifest.global_progression_catalog as Resource,
			issues,
		)
	)
	_validate_blueprints(blueprints, issues)
	_validate_recipes(recipes, blueprints, issues)
	var route_catalog: RepresentativeRouteCatalogScript = (
		RepresentativeRouteValidatorScript.snapshot_and_validate(
			exact_manifest.representative_route_contract_catalog as Resource,
			blueprints,
			progression_catalog,
			issues,
		)
	)
	var enemy_catalog: EnemyProfileCatalogScript = (
		EnemyProfileValidatorScript.snapshot_and_validate(
			exact_manifest.enemy_profile_catalog as Resource,
			route_catalog,
			issues,
		)
	)
	if not issues.is_empty():
		return _failure(issues)

	var report := ContentValidationReportScript.new(issues)
	var registry := ContentRegistryScript.new()
	registry._initialize_validated(
		schema_version,
		content_version,
		blueprints,
		recipes,
		progression_catalog,
		route_catalog,
		enemy_catalog,
	)
	if not registry.is_initialized():
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_CONTRACT_FINGERPRINT_MISMATCH,
			&"",
			"manifest",
			"Content manifest does not match the frozen v5 contract fingerprint.",
		)
		return _failure(issues)
	EnemyProfileValidatorScript.validate_balance(registry, enemy_catalog, issues)
	if not issues.is_empty():
		return _failure(issues)
	return ContentRegistryBuildResultScript.success(registry, report)


static func _validate_manifest_header(
	schema_version: int,
	content_version: int,
	blueprint_count: int,
	recipe_count: int,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if schema_version != SUPPORTED_SCHEMA_VERSION:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_SCHEMA_VERSION_UNSUPPORTED,
			&"",
			"schema_version",
			"Expected schema version %d, got %d."
			% [SUPPORTED_SCHEMA_VERSION, schema_version],
		)
	if content_version != SUPPORTED_CONTENT_VERSION:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_CONTENT_VERSION_UNSUPPORTED,
			&"",
			"content_version",
			"Expected content version %d, got %d."
			% [SUPPORTED_CONTENT_VERSION, content_version],
		)
	if blueprint_count != EXPECTED_DEFINITION_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_BLUEPRINT_COUNT_INVALID,
			&"",
			"blueprints",
			"Expected %d blueprint entries, got %d."
			% [EXPECTED_DEFINITION_COUNT, blueprint_count],
		)
	if recipe_count != EXPECTED_DEFINITION_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_RECIPE_COUNT_INVALID,
			&"",
			"recipes",
			"Expected %d recipe entries, got %d."
			% [EXPECTED_DEFINITION_COUNT, recipe_count],
		)


static func _snapshot_blueprints(
	raw_blueprints: Array[BlueprintDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> Array[BlueprintDefinitionScript]:
	var snapshots: Array[BlueprintDefinitionScript] = []
	for index: int in range(raw_blueprints.size()):
		var blueprint: BlueprintDefinitionScript = raw_blueprints[index]
		var field_path: String = "blueprints[%d]" % index
		if blueprint == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_ENTRY_NULL,
				&"",
				field_path,
				"Blueprint manifest entry is null.",
			)
			continue
		if blueprint.get_script() != BlueprintDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Blueprint entry must use the exact authoritative definition script.",
			)
			continue
		snapshots.append(BlueprintDefinitionScript.snapshot(blueprint))
	return snapshots


static func _snapshot_recipes(
	raw_recipes: Array[RecipeDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> Array[RecipeDefinitionScript]:
	var snapshots: Array[RecipeDefinitionScript] = []
	for index: int in range(raw_recipes.size()):
		var recipe: RecipeDefinitionScript = raw_recipes[index]
		var field_path: String = "recipes[%d]" % index
		if recipe == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_ENTRY_NULL,
				&"",
				field_path,
				"Recipe manifest entry is null.",
			)
			continue
		if recipe.get_script() != RecipeDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Recipe entry must use the exact authoritative definition script.",
			)
			continue
		snapshots.append(RecipeDefinitionScript.snapshot(recipe))
	return snapshots


static func _validate_blueprints(
	blueprints: Array[BlueprintDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var content_id_counts: Dictionary[StringName, int] = {}
	var ordinal_counts: Dictionary[int, int] = {}
	var recipe_id_counts: Dictionary[StringName, int] = {}
	var mechanic_id_counts: Dictionary[StringName, int] = {}
	var display_name_id_counts: Dictionary[StringName, int] = {}
	var function_id_counts: Dictionary[StringName, int] = {}
	var category_counts: Dictionary[int, int] = {}
	var tier_counts: Dictionary[int, int] = {}
	var lifecycle_counts: Dictionary[int, int] = {}
	var unlock_counts: Dictionary[int, int] = {}

	for blueprint: BlueprintDefinitionScript in blueprints:
		_validate_blueprint_fields(blueprint, issues)
		_increment_string_name_count(content_id_counts, blueprint.content_id)
		_increment_int_count(ordinal_counts, blueprint.ordinal)
		_increment_string_name_count(recipe_id_counts, blueprint.standard_recipe_id)
		_increment_string_name_count(mechanic_id_counts, blueprint.mechanic_id)
		_increment_string_name_count(
			display_name_id_counts,
			blueprint.display_name_text_id,
		)
		_increment_string_name_count(function_id_counts, blueprint.function_text_id)
		if _is_valid_category(blueprint.category):
			_increment_int_count(category_counts, blueprint.category)
		if _is_valid_tier(blueprint.tier):
			_increment_int_count(tier_counts, blueprint.tier)
		if _is_valid_lifecycle(blueprint.default_lifecycle):
			_increment_int_count(lifecycle_counts, blueprint.default_lifecycle)
		if blueprint.unlock_chapter >= 1 and blueprint.unlock_chapter <= 9:
			_increment_int_count(unlock_counts, blueprint.unlock_chapter)

	_add_duplicate_string_name_issues(
		content_id_counts,
		ContentValidationIssueScript.BLUEPRINT_CONTENT_ID_DUPLICATE,
		"content_id",
		"Blueprint content ID",
		issues,
	)
	_add_duplicate_int_issues(
		ordinal_counts,
		ContentValidationIssueScript.BLUEPRINT_ORDINAL_DUPLICATE,
		"ordinal",
		"Blueprint ordinal",
		issues,
	)
	_add_duplicate_string_name_issues(
		recipe_id_counts,
		ContentValidationIssueScript.BLUEPRINT_STANDARD_RECIPE_ID_DUPLICATE,
		"standard_recipe_id",
		"Blueprint standard recipe ID",
		issues,
	)
	_add_duplicate_string_name_issues(
		mechanic_id_counts,
		ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_DUPLICATE,
		"mechanic_id",
		"Blueprint mechanic ID",
		issues,
	)
	_add_duplicate_string_name_issues(
		display_name_id_counts,
		ContentValidationIssueScript.BLUEPRINT_DISPLAY_NAME_TEXT_ID_DUPLICATE,
		"display_name_text_id",
		"Blueprint display-name text ID",
		issues,
	)
	_add_duplicate_string_name_issues(
		function_id_counts,
		ContentValidationIssueScript.BLUEPRINT_FUNCTION_TEXT_ID_DUPLICATE,
		"function_text_id",
		"Blueprint function text ID",
		issues,
	)

	for ordinal: int in range(1, EXPECTED_DEFINITION_COUNT + 1):
		if not ordinal_counts.has(ordinal):
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_ORDINAL_MISSING,
				_expected_blueprint_id(ordinal),
				"ordinal",
				"Blueprint ordinal %d is missing." % ordinal,
			)
	_validate_count(
		category_counts,
		BlueprintDefinitionScript.Category.STRUCTURE,
		7,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_COUNT_MISMATCH,
		"category.structure",
		issues,
	)
	_validate_count(
		category_counts,
		BlueprintDefinitionScript.Category.MECHANISM,
		7,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_COUNT_MISMATCH,
		"category.mechanism",
		issues,
	)
	_validate_count(
		category_counts,
		BlueprintDefinitionScript.Category.SUPPORT,
		4,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_COUNT_MISMATCH,
		"category.support",
		issues,
	)
	_validate_count(
		category_counts,
		BlueprintDefinitionScript.Category.EXTENSION,
		1,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_COUNT_MISMATCH,
		"category.extension",
		issues,
	)
	_validate_count(
		category_counts,
		BlueprintDefinitionScript.Category.ATTRIBUTE,
		5,
		ContentValidationIssueScript.BLUEPRINT_CATEGORY_COUNT_MISMATCH,
		"category.attribute",
		issues,
	)
	_validate_count(
		tier_counts,
		BlueprintDefinitionScript.Tier.BASIC,
		16,
		ContentValidationIssueScript.BLUEPRINT_TIER_COUNT_MISMATCH,
		"tier.basic",
		issues,
	)
	_validate_count(
		tier_counts,
		BlueprintDefinitionScript.Tier.ADVANCED,
		8,
		ContentValidationIssueScript.BLUEPRINT_TIER_COUNT_MISMATCH,
		"tier.advanced",
		issues,
	)
	_validate_count(
		lifecycle_counts,
		BlueprintDefinitionScript.Lifecycle.RECOVERABLE,
		16,
		ContentValidationIssueScript.BLUEPRINT_LIFECYCLE_COUNT_MISMATCH,
		"default_lifecycle.recoverable",
		issues,
	)
	_validate_count(
		lifecycle_counts,
		BlueprintDefinitionScript.Lifecycle.CONSUMABLE,
		8,
		ContentValidationIssueScript.BLUEPRINT_LIFECYCLE_COUNT_MISMATCH,
		"default_lifecycle.consumable",
		issues,
	)
	var expected_unlock_counts: Array[int] = [4, 4, 4, 2, 3, 3, 2, 2, 0]
	for chapter_index: int in range(expected_unlock_counts.size()):
		_validate_count(
			unlock_counts,
			chapter_index + 1,
			expected_unlock_counts[chapter_index],
			ContentValidationIssueScript.BLUEPRINT_UNLOCK_CHAPTER_COUNT_MISMATCH,
			"unlock_chapter.%d" % (chapter_index + 1),
			issues,
		)


static func _validate_blueprint_fields(
	blueprint: BlueprintDefinitionScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var content_id: StringName = blueprint.content_id
	var issue_subject: StringName = content_id
	if content_id.is_empty():
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_CONTENT_ID_EMPTY,
			issue_subject,
			"content_id",
			"Blueprint content ID must not be empty.",
		)
	if blueprint.ordinal < 1 or blueprint.ordinal > EXPECTED_DEFINITION_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_ORDINAL_OUT_OF_RANGE,
			issue_subject,
			"ordinal",
			"Blueprint ordinal must be in the inclusive range 1 through %d."
			% EXPECTED_DEFINITION_COUNT,
		)
	else:
		var expected_index: int = blueprint.ordinal - 1
		var expected_content_id: StringName = _expected_blueprint_id(blueprint.ordinal)
		if content_id != expected_content_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_CONTENT_ID_ORDINAL_MISMATCH,
				issue_subject,
				"content_id",
				"Ordinal %d requires content ID '%s'."
				% [blueprint.ordinal, String(expected_content_id)],
			)
		var expected_recipe_id: StringName = _expected_recipe_id(blueprint.ordinal)
		if blueprint.standard_recipe_id != expected_recipe_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_STANDARD_RECIPE_ID_ORDINAL_MISMATCH,
				issue_subject,
				"standard_recipe_id",
				"Ordinal %d requires standard recipe ID '%s'."
				% [blueprint.ordinal, String(expected_recipe_id)],
			)
		var expected_display_name_id := StringName(
			"blueprint.%02d.display_name" % blueprint.ordinal
		)
		if blueprint.display_name_text_id != expected_display_name_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_DISPLAY_NAME_TEXT_ID_INVALID,
				issue_subject,
				"display_name_text_id",
				"Ordinal %d requires display-name text ID '%s'."
				% [blueprint.ordinal, String(expected_display_name_id)],
			)
		var expected_function_id := StringName(
			"blueprint.%02d.function" % blueprint.ordinal
		)
		if blueprint.function_text_id != expected_function_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_FUNCTION_TEXT_ID_INVALID,
				issue_subject,
				"function_text_id",
				"Ordinal %d requires function text ID '%s'."
				% [blueprint.ordinal, String(expected_function_id)],
			)
		if blueprint.category != EXPECTED_CATEGORIES[expected_index]:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_CATEGORY_ORDINAL_MISMATCH,
				issue_subject,
				"category",
				"Blueprint ordinal %d requires category %d."
				% [blueprint.ordinal, EXPECTED_CATEGORIES[expected_index]],
			)
		if blueprint.unlock_chapter != EXPECTED_UNLOCK_CHAPTERS[expected_index]:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_UNLOCK_CHAPTER_ORDINAL_MISMATCH,
				issue_subject,
				"unlock_chapter",
				"Blueprint ordinal %d requires unlock chapter %d."
				% [blueprint.ordinal, EXPECTED_UNLOCK_CHAPTERS[expected_index]],
			)
		if blueprint.default_lifecycle != EXPECTED_LIFECYCLES[expected_index]:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_LIFECYCLE_ORDINAL_MISMATCH,
				issue_subject,
				"default_lifecycle",
				"Blueprint ordinal %d requires lifecycle %d."
				% [blueprint.ordinal, EXPECTED_LIFECYCLES[expected_index]],
			)
		if blueprint.mechanic_id != EXPECTED_MECHANIC_IDS[expected_index]:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_ORDINAL_MISMATCH,
				issue_subject,
				"mechanic_id",
				"Blueprint ordinal %d requires mechanic ID '%s'."
				% [blueprint.ordinal, String(EXPECTED_MECHANIC_IDS[expected_index])],
			)
	if not content_id.is_empty() and not String(content_id).begins_with("blueprint."):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_CONTENT_ID_INVALID,
			issue_subject,
			"content_id",
			"Blueprint content ID must use the 'blueprint.NN' namespace.",
		)
	if not _is_valid_category(blueprint.category):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_CATEGORY_INVALID,
			issue_subject,
			"category",
			"Blueprint category is not one of the five supported values.",
		)
	if not _is_valid_tier(blueprint.tier):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_TIER_INVALID,
			issue_subject,
			"tier",
			"Blueprint tier is not basic or advanced.",
		)
	elif blueprint.ordinal >= 1 and blueprint.ordinal <= EXPECTED_DEFINITION_COUNT:
		var expected_tier: int = BlueprintDefinitionScript.Tier.BASIC
		if ADVANCED_ORDINALS.has(blueprint.ordinal):
			expected_tier = BlueprintDefinitionScript.Tier.ADVANCED
		if blueprint.tier != expected_tier:
			_add_issue(
				issues,
				ContentValidationIssueScript.BLUEPRINT_TIER_ORDINAL_MISMATCH,
				issue_subject,
				"tier",
				"Blueprint ordinal %d has the wrong tier." % blueprint.ordinal,
			)
	if blueprint.unlock_chapter < 1 or blueprint.unlock_chapter > 9:
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_UNLOCK_CHAPTER_INVALID,
			issue_subject,
			"unlock_chapter",
			"Blueprint unlock chapter must be in the inclusive range 1 through 9.",
		)
	if not _is_valid_lifecycle(blueprint.default_lifecycle):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_LIFECYCLE_INVALID,
			issue_subject,
			"default_lifecycle",
			"Blueprint lifecycle must be recoverable or consumable.",
		)
	if blueprint.standard_recipe_id.is_empty():
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_STANDARD_RECIPE_ID_EMPTY,
			issue_subject,
			"standard_recipe_id",
			"Blueprint standard recipe ID must not be empty.",
		)
	elif not String(blueprint.standard_recipe_id).begins_with("recipe.standard."):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_STANDARD_RECIPE_ID_INVALID,
			issue_subject,
			"standard_recipe_id",
			"Blueprint standard recipe ID must use the 'recipe.standard.NN' namespace.",
		)
	if blueprint.mechanic_id.is_empty():
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_EMPTY,
			issue_subject,
			"mechanic_id",
			"Blueprint mechanic ID must not be empty.",
		)
	elif (
		not String(blueprint.mechanic_id).begins_with("mechanic.blueprint.")
		or String(blueprint.mechanic_id).trim_prefix("mechanic.blueprint.").is_empty()
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.BLUEPRINT_MECHANIC_ID_INVALID,
			issue_subject,
			"mechanic_id",
			"Blueprint mechanic ID must use the 'mechanic.blueprint.*' namespace.",
		)


static func _validate_recipes(
	recipes: Array[RecipeDefinitionScript],
	blueprints: Array[BlueprintDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var recipe_id_counts: Dictionary[StringName, int] = {}
	var output_id_counts: Dictionary[StringName, int] = {}
	var recipes_by_id: Dictionary[StringName, RecipeDefinitionScript] = {}
	var blueprints_by_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
	for blueprint: BlueprintDefinitionScript in blueprints:
		_increment_string_name_count(output_id_counts, blueprint.content_id)
	for recipe: RecipeDefinitionScript in recipes:
		_validate_recipe_fields(recipe, issues)
		_increment_string_name_count(recipe_id_counts, recipe.recipe_id)
	var blueprint_id_counts: Dictionary[StringName, int] = output_id_counts
	output_id_counts = {}
	for recipe: RecipeDefinitionScript in recipes:
		_increment_string_name_count(output_id_counts, recipe.output_blueprint_id)
	for blueprint: BlueprintDefinitionScript in blueprints:
		if blueprint_id_counts.get(blueprint.content_id, 0) == 1:
			blueprints_by_id[blueprint.content_id] = blueprint
	for recipe: RecipeDefinitionScript in recipes:
		if recipe_id_counts.get(recipe.recipe_id, 0) == 1:
			recipes_by_id[recipe.recipe_id] = recipe

	_add_duplicate_string_name_issues(
		recipe_id_counts,
		ContentValidationIssueScript.RECIPE_ID_DUPLICATE,
		"recipe_id",
		"Recipe ID",
		issues,
	)
	_add_duplicate_string_name_issues(
		output_id_counts,
		ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_DUPLICATE,
		"output_blueprint_id",
		"Recipe output blueprint ID",
		issues,
	)
	for ordinal: int in range(1, EXPECTED_DEFINITION_COUNT + 1):
		var expected_recipe_id: StringName = _expected_recipe_id(ordinal)
		if not recipe_id_counts.has(expected_recipe_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_ID_MISSING,
				expected_recipe_id,
				"recipe_id",
				"Standard recipe ID '%s' is missing." % String(expected_recipe_id),
			)

	for recipe: RecipeDefinitionScript in recipes:
		var recipe_subject: StringName = recipe.recipe_id
		if recipe.output_blueprint_id.is_empty():
			continue
		if not blueprints_by_id.has(recipe.output_blueprint_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_UNKNOWN,
				recipe_subject,
				"output_blueprint_id",
				"Recipe output blueprint ID '%s' is not registered."
				% String(recipe.output_blueprint_id),
			)
			continue
		var output_blueprint: BlueprintDefinitionScript = blueprints_by_id[
			recipe.output_blueprint_id
		]
		var expected_recipe_id: StringName = _expected_recipe_id(output_blueprint.ordinal)
		if recipe.recipe_id != expected_recipe_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_MISMATCH,
				recipe_subject,
				"output_blueprint_id",
				"Output blueprint '%s' requires recipe ID '%s'."
				% [String(output_blueprint.content_id), String(expected_recipe_id)],
			)
		if output_blueprint.standard_recipe_id != recipe.recipe_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_BLUEPRINT_REFERENCE_MISMATCH,
				recipe_subject,
				"output_blueprint_id",
				"Output blueprint refers to standard recipe '%s'."
				% String(output_blueprint.standard_recipe_id),
			)
		_validate_recipe_profile(recipe, output_blueprint, issues)

	for blueprint: BlueprintDefinitionScript in blueprints:
		if blueprint.standard_recipe_id.is_empty():
			continue
		if not recipes_by_id.has(blueprint.standard_recipe_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_BLUEPRINT_REFERENCE_MISSING,
				blueprint.content_id,
				"standard_recipe_id",
				"Blueprint standard recipe '%s' is not registered."
				% String(blueprint.standard_recipe_id),
			)


static func _validate_recipe_fields(
	recipe: RecipeDefinitionScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var recipe_subject: StringName = recipe.recipe_id
	if recipe.recipe_id.is_empty():
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_ID_EMPTY,
			recipe_subject,
			"recipe_id",
			"Recipe ID must not be empty.",
		)
	elif not String(recipe.recipe_id).begins_with("recipe.standard."):
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_ID_INVALID,
			recipe_subject,
			"recipe_id",
			"Recipe ID must use the 'recipe.standard.NN' namespace.",
		)
	if recipe.output_blueprint_id.is_empty():
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_EMPTY,
			recipe_subject,
			"output_blueprint_id",
			"Recipe output blueprint ID must not be empty.",
		)
	elif not String(recipe.output_blueprint_id).begins_with("blueprint."):
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_OUTPUT_BLUEPRINT_ID_INVALID,
			recipe_subject,
			"output_blueprint_id",
			"Recipe output blueprint ID must use the 'blueprint.NN' namespace.",
		)
	if not _is_allowed_material_id(recipe.main_material_id):
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_MAIN_MATERIAL_ID_INVALID,
			recipe_subject,
			"main_material_id",
			"Recipe main material must be one of the three allowed material IDs.",
		)
	if recipe.main_quantity <= 0:
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_MAIN_QUANTITY_INVALID,
			recipe_subject,
			"main_quantity",
			"Recipe main quantity must be positive.",
		)
	if recipe.auxiliary_material_id.is_empty():
		if recipe.auxiliary_quantity != 0:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_AUXILIARY_QUANTITY_INVALID,
				recipe_subject,
				"auxiliary_quantity",
				"Recipe without an auxiliary material must have quantity zero.",
			)
	else:
		if not _is_allowed_material_id(recipe.auxiliary_material_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_AUXILIARY_MATERIAL_ID_INVALID,
				recipe_subject,
				"auxiliary_material_id",
				"Recipe auxiliary material must be one of the three allowed material IDs.",
			)
		if recipe.auxiliary_quantity <= 0:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_AUXILIARY_QUANTITY_INVALID,
				recipe_subject,
				"auxiliary_quantity",
				"Recipe auxiliary quantity must be positive when present.",
			)
		if recipe.main_material_id == recipe.auxiliary_material_id:
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_MATERIALS_MUST_DIFFER,
				recipe_subject,
				"auxiliary_material_id",
				"Recipe main and auxiliary materials must differ.",
			)


static func _validate_recipe_profile(
	recipe: RecipeDefinitionScript,
	blueprint: BlueprintDefinitionScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if blueprint.ordinal >= 1 and blueprint.ordinal <= EXPECTED_DEFINITION_COUNT:
		var expected_index: int = blueprint.ordinal - 1
		if (
			recipe.main_material_id != EXPECTED_MAIN_MATERIAL_IDS[expected_index]
			or recipe.auxiliary_material_id
			!= EXPECTED_AUXILIARY_MATERIAL_IDS[expected_index]
		):
			_add_issue(
				issues,
				ContentValidationIssueScript.RECIPE_MATERIAL_MAPPING_MISMATCH,
				recipe.recipe_id,
				"material_mapping",
				"Recipe materials do not match the frozen content-version mapping for blueprint ordinal %d."
				% blueprint.ordinal,
			)
	if not _is_valid_tier(blueprint.tier):
		return
	if not _is_valid_lifecycle(blueprint.default_lifecycle):
		return
	var expected_main_quantity: int = 0
	var expected_auxiliary_quantity: int = 0
	if blueprint.tier == BlueprintDefinitionScript.Tier.BASIC:
		if blueprint.default_lifecycle == BlueprintDefinitionScript.Lifecycle.RECOVERABLE:
			expected_main_quantity = 3
		else:
			expected_main_quantity = 1
	else:
		expected_main_quantity = 4
		expected_auxiliary_quantity = 2
		if blueprint.default_lifecycle == BlueprintDefinitionScript.Lifecycle.CONSUMABLE:
			expected_main_quantity = 2
			expected_auxiliary_quantity = 1
	var auxiliary_presence_matches: bool = (
		(recipe.auxiliary_material_id.is_empty() and expected_auxiliary_quantity == 0)
		or (
			not recipe.auxiliary_material_id.is_empty()
			and expected_auxiliary_quantity > 0
		)
	)
	if (
		recipe.main_quantity != expected_main_quantity
		or recipe.auxiliary_quantity != expected_auxiliary_quantity
		or not auxiliary_presence_matches
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.RECIPE_PROFILE_MISMATCH,
			recipe.recipe_id,
			"material_profile",
			"Recipe quantities or auxiliary-material presence do not match its blueprint tier and lifecycle.",
		)


static func _add_duplicate_string_name_issues(
	counts: Dictionary[StringName, int],
	code: StringName,
	field_path: String,
	label: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var sorted_ids: Array[StringName] = []
	for value: StringName in counts:
		if not value.is_empty() and counts[value] > 1:
			sorted_ids.append(value)
	sorted_ids.sort_custom(_string_name_less_than)
	for value: StringName in sorted_ids:
		_add_issue(
			issues,
			code,
			value,
			field_path,
			"%s '%s' occurs %d times." % [label, String(value), counts[value]],
		)


static func _add_duplicate_int_issues(
	counts: Dictionary[int, int],
	code: StringName,
	field_path: String,
	label: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var sorted_values: Array[int] = []
	for value: int in counts:
		if counts[value] > 1:
			sorted_values.append(value)
	sorted_values.sort()
	for value: int in sorted_values:
		_add_issue(
			issues,
			code,
			_expected_blueprint_id(value),
			field_path,
			"%s %d occurs %d times." % [label, value, counts[value]],
		)


static func _validate_count(
	counts: Dictionary[int, int],
	value: int,
	expected_count: int,
	code: StringName,
	field_path: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var actual_count: int = counts.get(value, 0)
	if actual_count == expected_count:
		return
	_add_issue(
		issues,
		code,
		&"",
		field_path,
		"Expected %d entries for %s, got %d."
		% [expected_count, field_path, actual_count],
	)


static func _increment_string_name_count(
	counts: Dictionary[StringName, int],
	value: StringName,
) -> void:
	counts[value] = counts.get(value, 0) + 1


static func _increment_int_count(counts: Dictionary[int, int], value: int) -> void:
	counts[value] = counts.get(value, 0) + 1


static func _is_valid_category(value: int) -> bool:
	return (
		value == BlueprintDefinitionScript.Category.STRUCTURE
		or value == BlueprintDefinitionScript.Category.MECHANISM
		or value == BlueprintDefinitionScript.Category.SUPPORT
		or value == BlueprintDefinitionScript.Category.EXTENSION
		or value == BlueprintDefinitionScript.Category.ATTRIBUTE
	)


static func _is_valid_tier(value: int) -> bool:
	return (
		value == BlueprintDefinitionScript.Tier.BASIC
		or value == BlueprintDefinitionScript.Tier.ADVANCED
	)


static func _is_valid_lifecycle(value: int) -> bool:
	return (
		value == BlueprintDefinitionScript.Lifecycle.RECOVERABLE
		or value == BlueprintDefinitionScript.Lifecycle.CONSUMABLE
	)


static func _is_allowed_material_id(value: StringName) -> bool:
	return (
		value == RecipeDefinitionScript.BUILDING_MATERIAL_ID
		or value == RecipeDefinitionScript.MECHANISM_PART_MATERIAL_ID
		or value == RecipeDefinitionScript.CRYSTAL_SAND_MATERIAL_ID
	)


static func _expected_blueprint_id(ordinal: int) -> StringName:
	return StringName("blueprint.%02d" % ordinal)


static func _expected_recipe_id(ordinal: int) -> StringName:
	return StringName("recipe.standard.%02d" % ordinal)


static func _failure_with_single_issue(
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> ContentRegistryBuildResultScript:
	var issues: Array[ContentValidationIssueScript] = []
	_add_issue(issues, code, content_id, field_path, message)
	return _failure(issues)


static func _failure(
	issues: Array[ContentValidationIssueScript],
) -> ContentRegistryBuildResultScript:
	_sort_issues(issues)
	return ContentRegistryBuildResultScript.failure(
		ContentValidationReportScript.new(issues)
	)


static func _add_issue(
	issues: Array[ContentValidationIssueScript],
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> void:
	issues.append(
		ContentValidationIssueScript.new(code, content_id, field_path, message)
	)


static func _sort_issues(issues: Array[ContentValidationIssueScript]) -> void:
	issues.sort_custom(_issue_less_than)


static func _issue_less_than(
	left: ContentValidationIssueScript,
	right: ContentValidationIssueScript,
) -> bool:
	var left_code: String = String(left.code())
	var right_code: String = String(right.code())
	if left_code != right_code:
		return left_code < right_code
	var left_content_id: String = String(left.content_id())
	var right_content_id: String = String(right.content_id())
	if left_content_id != right_content_id:
		return left_content_id < right_content_id
	if left.field_path() != right.field_path():
		return left.field_path() < right.field_path()
	return left.message() < right.message()


static func _string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
