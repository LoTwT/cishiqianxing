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
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const BlueprintRecipeValidatorScript := preload(
	"res://src/content/blueprint_recipe_validator.gd"
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

const StaticMapValidatorScript := preload("res://src/content/static_map_validator.gd")

const CANONICAL_MANIFEST_PATH: String = "res://content/content_manifest.tres"
const SUPPORTED_SCHEMA_VERSION: int = 6
const SUPPORTED_CONTENT_VERSION: int = 6
const EXPECTED_DEFINITION_COUNT: int = 24


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
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_LOAD_FAILED,
			&"",
			"manifest",
			"Content manifest is null.",
		)
		return _failure(issues)
	if manifest.get_script() != ContentManifestScript:
		ContentValidationSupportScript.add_issue(
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

	var blueprints: Array[BlueprintDefinitionScript] = (
		BlueprintRecipeValidatorScript.snapshot_blueprints(
			raw_blueprints,
			issues,
		)
	)
	var recipes: Array[RecipeDefinitionScript] = (
		BlueprintRecipeValidatorScript.snapshot_recipes(
			raw_recipes,
			issues,
		)
	)
	var progression_catalog: GlobalProgressionCatalogScript = (
		GlobalProgressionValidatorScript.snapshot_and_validate(
			exact_manifest.global_progression_catalog as Resource,
			issues,
		)
	)
	BlueprintRecipeValidatorScript.validate_blueprints(blueprints, issues)
	BlueprintRecipeValidatorScript.validate_recipes(recipes, blueprints, issues)
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
	var map_catalog := StaticMapValidatorScript.snapshot_and_validate(
		exact_manifest.static_map_catalog, enemy_catalog, route_catalog, issues,
	)
	if not issues.is_empty():
		return _failure(issues)

	var report := ContentValidationReportScript.new(issues)
	var registry := ContentRegistryScript.new()
	if not registry.initialize_validated(
		schema_version,
		content_version,
		blueprints,
		recipes,
		progression_catalog,
		route_catalog,
		enemy_catalog,
		map_catalog,
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_CONTRACT_FINGERPRINT_MISMATCH,
			&"",
			"manifest",
			"Content manifest does not match the frozen v6 contract fingerprint.",
		)
		return _failure(issues)
	EnemyProfileValidatorScript.validate_balance(registry, enemy_catalog, issues)
	StaticMapValidatorScript.validate_balance(registry, map_catalog, issues)
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
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_SCHEMA_VERSION_UNSUPPORTED,
			&"",
			"schema_version",
			"Expected schema version %d, got %d."
			% [SUPPORTED_SCHEMA_VERSION, schema_version],
		)
	if content_version != SUPPORTED_CONTENT_VERSION:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_CONTENT_VERSION_UNSUPPORTED,
			&"",
			"content_version",
			"Expected content version %d, got %d."
			% [SUPPORTED_CONTENT_VERSION, content_version],
		)
	if blueprint_count != EXPECTED_DEFINITION_COUNT:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_BLUEPRINT_COUNT_INVALID,
			&"",
			"blueprints",
			"Expected %d blueprint entries, got %d."
			% [EXPECTED_DEFINITION_COUNT, blueprint_count],
		)
	if recipe_count != EXPECTED_DEFINITION_COUNT:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_RECIPE_COUNT_INVALID,
			&"",
			"recipes",
			"Expected %d recipe entries, got %d."
			% [EXPECTED_DEFINITION_COUNT, recipe_count],
		)


static func _failure_with_single_issue(
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> ContentRegistryBuildResultScript:
	var issues: Array[ContentValidationIssueScript] = []
	ContentValidationSupportScript.add_issue(issues, code, content_id, field_path, message)
	return _failure(issues)


static func _failure(
	issues: Array[ContentValidationIssueScript],
) -> ContentRegistryBuildResultScript:
	_sort_issues(issues)
	return ContentRegistryBuildResultScript.failure(
		ContentValidationReportScript.new(issues)
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
