class_name ContentValidationIssue
extends RefCounted

const MANIFEST_LOAD_FAILED: StringName = &"manifest.load_failed"
const MANIFEST_INVALID_SCRIPT: StringName = &"manifest.invalid_script"
const MANIFEST_SCHEMA_VERSION_UNSUPPORTED: StringName = (
	&"manifest.schema_version.unsupported"
)
const MANIFEST_CONTENT_VERSION_UNSUPPORTED: StringName = (
	&"manifest.content_version.unsupported"
)
const MANIFEST_BLUEPRINT_COUNT_INVALID: StringName = &"manifest.blueprint_count.invalid"
const MANIFEST_RECIPE_COUNT_INVALID: StringName = &"manifest.recipe_count.invalid"
const MANIFEST_PROGRESSION_CATALOG_NULL: StringName = (
	&"manifest.global_progression_catalog.null"
)

const PROGRESSION_CATALOG_INVALID_SCRIPT: StringName = (
	&"progression.catalog.invalid_script"
)
const PROGRESSION_CATALOG_ID_INVALID: StringName = &"progression.catalog_id.invalid"
const PROGRESSION_MAINLINE_COUNT_INVALID: StringName = (
	&"progression.mainline_count.invalid"
)
const PROGRESSION_OPTIONAL_COUNT_INVALID: StringName = (
	&"progression.optional_count.invalid"
)
const PROGRESSION_REWARD_COUNT_INVALID: StringName = (
	&"progression.reward_count.invalid"
)
const PROGRESSION_INITIAL_STATS_NULL: StringName = &"progression.initial_stats.null"
const PROGRESSION_INITIAL_STATS_INVALID_SCRIPT: StringName = (
	&"progression.initial_stats.invalid_script"
)
const PROGRESSION_PROFILE_ID_INVALID: StringName = &"progression.profile_id.invalid"
const PROGRESSION_PROFILE_FIELD_MISMATCH: StringName = (
	&"progression.profile.field_mismatch"
)
const PROGRESSION_MAINLINE_ENTRY_NULL: StringName = (
	&"progression.mainline.entry.null"
)
const PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT: StringName = (
	&"progression.mainline.entry.invalid_script"
)
const PROGRESSION_MAINLINE_CONTENT_ID_EMPTY: StringName = (
	&"progression.mainline.content_id.empty"
)
const PROGRESSION_MAINLINE_CONTENT_ID_INVALID: StringName = (
	&"progression.mainline.content_id.invalid"
)
const PROGRESSION_MAINLINE_CONTENT_ID_DUPLICATE: StringName = (
	&"progression.mainline.content_id.duplicate"
)
const PROGRESSION_MAINLINE_CHAPTER_INVALID: StringName = (
	&"progression.mainline.chapter.invalid"
)
const PROGRESSION_MAINLINE_CHAPTER_DUPLICATE: StringName = (
	&"progression.mainline.chapter.duplicate"
)
const PROGRESSION_MAINLINE_CHAPTER_MISMATCH: StringName = (
	&"progression.mainline.chapter.mismatch"
)
const PROGRESSION_OPTIONAL_ENTRY_NULL: StringName = (
	&"progression.optional.entry.null"
)
const PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT: StringName = (
	&"progression.optional.entry.invalid_script"
)
const PROGRESSION_OPTIONAL_CONTENT_ID_EMPTY: StringName = (
	&"progression.optional.content_id.empty"
)
const PROGRESSION_OPTIONAL_CONTENT_ID_INVALID: StringName = (
	&"progression.optional.content_id.invalid"
)
const PROGRESSION_OPTIONAL_CONTENT_ID_DUPLICATE: StringName = (
	&"progression.optional.content_id.duplicate"
)
const PROGRESSION_OPTIONAL_MAP_ID_INVALID: StringName = (
	&"progression.optional.map_id.invalid"
)
const PROGRESSION_OPTIONAL_MAP_ID_DUPLICATE: StringName = (
	&"progression.optional.map_id.duplicate"
)
const PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID: StringName = (
	&"progression.optional.available_after_chapter.invalid"
)
const PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_MISMATCH: StringName = (
	&"progression.optional.available_after_chapter.mismatch"
)
const PROGRESSION_OPTIONAL_SPEED_FORBIDDEN: StringName = (
	&"progression.optional.speed.forbidden"
)
const PROGRESSION_GROUP_REWARD_ID_EMPTY: StringName = (
	&"progression.group.reward_id.empty"
)
const PROGRESSION_GROUP_REWARD_ID_DUPLICATE: StringName = (
	&"progression.group.reward_id.duplicate"
)
const PROGRESSION_GROUP_REWARD_ID_UNKNOWN: StringName = (
	&"progression.group.reward_id.unknown"
)
const PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH: StringName = (
	&"progression.group.reward_membership.mismatch"
)
const PROGRESSION_REWARD_ENTRY_NULL: StringName = (
	&"progression.reward.entry.null"
)
const PROGRESSION_REWARD_ENTRY_INVALID_SCRIPT: StringName = (
	&"progression.reward.entry.invalid_script"
)
const PROGRESSION_REWARD_ID_EMPTY: StringName = &"progression.reward_id.empty"
const PROGRESSION_REWARD_ID_INVALID: StringName = &"progression.reward_id.invalid"
const PROGRESSION_REWARD_ID_DUPLICATE: StringName = (
	&"progression.reward_id.duplicate"
)
const PROGRESSION_REWARD_ID_MISSING: StringName = &"progression.reward_id.missing"
const PROGRESSION_REWARD_STAT_KIND_INVALID: StringName = (
	&"progression.reward.stat_kind.invalid"
)
const PROGRESSION_REWARD_STAT_KIND_MISMATCH: StringName = (
	&"progression.reward.stat_kind.mismatch"
)
const PROGRESSION_REWARD_INCREASE_INVALID: StringName = (
	&"progression.reward.increase.invalid"
)
const PROGRESSION_REWARD_INCREASE_MISMATCH: StringName = (
	&"progression.reward.increase.mismatch"
)
const PROGRESSION_REWARD_UNREFERENCED: StringName = (
	&"progression.reward.unreferenced"
)
const PROGRESSION_REWARD_REFERENCED_MULTIPLE: StringName = (
	&"progression.reward.referenced_multiple"
)
const PROGRESSION_MAINLINE_ATOMIC_COUNT_MISMATCH: StringName = (
	&"progression.mainline.atomic_count.mismatch"
)
const PROGRESSION_OPTIONAL_ATOMIC_COUNT_MISMATCH: StringName = (
	&"progression.optional.atomic_count.mismatch"
)
const PROGRESSION_MAINLINE_CHAPTER_TOTAL_MISMATCH: StringName = (
	&"progression.mainline.chapter_total.mismatch"
)
const PROGRESSION_MAINLINE_FINAL_STATS_MISMATCH: StringName = (
	&"progression.mainline.final_stats.mismatch"
)
const PROGRESSION_FULL_COMPLETION_STATS_MISMATCH: StringName = (
	&"progression.full_completion_stats.mismatch"
)

const BLUEPRINT_ENTRY_NULL: StringName = &"blueprint.entry.null"
const BLUEPRINT_ENTRY_INVALID_SCRIPT: StringName = &"blueprint.entry.invalid_script"
const BLUEPRINT_CONTENT_ID_EMPTY: StringName = &"blueprint.content_id.empty"
const BLUEPRINT_CONTENT_ID_INVALID: StringName = &"blueprint.content_id.invalid"
const BLUEPRINT_CONTENT_ID_DUPLICATE: StringName = &"blueprint.content_id.duplicate"
const BLUEPRINT_CONTENT_ID_ORDINAL_MISMATCH: StringName = (
	&"blueprint.content_id.ordinal_mismatch"
)
const BLUEPRINT_ORDINAL_OUT_OF_RANGE: StringName = &"blueprint.ordinal.out_of_range"
const BLUEPRINT_ORDINAL_DUPLICATE: StringName = &"blueprint.ordinal.duplicate"
const BLUEPRINT_ORDINAL_MISSING: StringName = &"blueprint.ordinal.missing"
const BLUEPRINT_CATEGORY_INVALID: StringName = &"blueprint.category.invalid"
const BLUEPRINT_CATEGORY_ORDINAL_MISMATCH: StringName = (
	&"blueprint.category.ordinal_mismatch"
)
const BLUEPRINT_CATEGORY_COUNT_MISMATCH: StringName = &"blueprint.category.count_mismatch"
const BLUEPRINT_TIER_INVALID: StringName = &"blueprint.tier.invalid"
const BLUEPRINT_TIER_ORDINAL_MISMATCH: StringName = (
	&"blueprint.tier.ordinal_mismatch"
)
const BLUEPRINT_TIER_COUNT_MISMATCH: StringName = &"blueprint.tier.count_mismatch"
const BLUEPRINT_UNLOCK_CHAPTER_INVALID: StringName = &"blueprint.unlock_chapter.invalid"
const BLUEPRINT_UNLOCK_CHAPTER_ORDINAL_MISMATCH: StringName = (
	&"blueprint.unlock_chapter.ordinal_mismatch"
)
const BLUEPRINT_UNLOCK_CHAPTER_COUNT_MISMATCH: StringName = (
	&"blueprint.unlock_chapter.count_mismatch"
)
const BLUEPRINT_LIFECYCLE_INVALID: StringName = &"blueprint.lifecycle.invalid"
const BLUEPRINT_LIFECYCLE_ORDINAL_MISMATCH: StringName = (
	&"blueprint.lifecycle.ordinal_mismatch"
)
const BLUEPRINT_LIFECYCLE_COUNT_MISMATCH: StringName = (
	&"blueprint.lifecycle.count_mismatch"
)
const BLUEPRINT_STANDARD_RECIPE_ID_EMPTY: StringName = (
	&"blueprint.standard_recipe_id.empty"
)
const BLUEPRINT_STANDARD_RECIPE_ID_INVALID: StringName = (
	&"blueprint.standard_recipe_id.invalid"
)
const BLUEPRINT_STANDARD_RECIPE_ID_DUPLICATE: StringName = (
	&"blueprint.standard_recipe_id.duplicate"
)
const BLUEPRINT_STANDARD_RECIPE_ID_ORDINAL_MISMATCH: StringName = (
	&"blueprint.standard_recipe_id.ordinal_mismatch"
)
const BLUEPRINT_MECHANIC_ID_EMPTY: StringName = &"blueprint.mechanic_id.empty"
const BLUEPRINT_MECHANIC_ID_INVALID: StringName = &"blueprint.mechanic_id.invalid"
const BLUEPRINT_MECHANIC_ID_ORDINAL_MISMATCH: StringName = (
	&"blueprint.mechanic_id.ordinal_mismatch"
)
const BLUEPRINT_MECHANIC_ID_DUPLICATE: StringName = &"blueprint.mechanic_id.duplicate"
const BLUEPRINT_DISPLAY_NAME_TEXT_ID_INVALID: StringName = (
	&"blueprint.display_name_text_id.invalid"
)
const BLUEPRINT_DISPLAY_NAME_TEXT_ID_DUPLICATE: StringName = (
	&"blueprint.display_name_text_id.duplicate"
)
const BLUEPRINT_FUNCTION_TEXT_ID_INVALID: StringName = (
	&"blueprint.function_text_id.invalid"
)
const BLUEPRINT_FUNCTION_TEXT_ID_DUPLICATE: StringName = (
	&"blueprint.function_text_id.duplicate"
)

const RECIPE_ENTRY_NULL: StringName = &"recipe.entry.null"
const RECIPE_ENTRY_INVALID_SCRIPT: StringName = &"recipe.entry.invalid_script"
const RECIPE_ID_EMPTY: StringName = &"recipe.recipe_id.empty"
const RECIPE_ID_INVALID: StringName = &"recipe.recipe_id.invalid"
const RECIPE_ID_DUPLICATE: StringName = &"recipe.recipe_id.duplicate"
const RECIPE_ID_MISSING: StringName = &"recipe.recipe_id.missing"
const RECIPE_OUTPUT_BLUEPRINT_ID_EMPTY: StringName = &"recipe.output_blueprint_id.empty"
const RECIPE_OUTPUT_BLUEPRINT_ID_INVALID: StringName = &"recipe.output_blueprint_id.invalid"
const RECIPE_OUTPUT_BLUEPRINT_ID_DUPLICATE: StringName = (
	&"recipe.output_blueprint_id.duplicate"
)
const RECIPE_OUTPUT_BLUEPRINT_ID_UNKNOWN: StringName = (
	&"recipe.output_blueprint_id.unknown"
)
const RECIPE_OUTPUT_BLUEPRINT_ID_MISMATCH: StringName = (
	&"recipe.output_blueprint_id.mismatch"
)
const RECIPE_MAIN_MATERIAL_ID_INVALID: StringName = &"recipe.main_material_id.invalid"
const RECIPE_MAIN_QUANTITY_INVALID: StringName = &"recipe.main_quantity.invalid"
const RECIPE_AUXILIARY_MATERIAL_ID_INVALID: StringName = (
	&"recipe.auxiliary_material_id.invalid"
)
const RECIPE_AUXILIARY_QUANTITY_INVALID: StringName = (
	&"recipe.auxiliary_quantity.invalid"
)
const RECIPE_MATERIALS_MUST_DIFFER: StringName = &"recipe.materials.must_differ"
const RECIPE_PROFILE_MISMATCH: StringName = &"recipe.profile.mismatch"
const RECIPE_MATERIAL_MAPPING_MISMATCH: StringName = (
	&"recipe.material_mapping.mismatch"
)
const RECIPE_BLUEPRINT_REFERENCE_MISSING: StringName = (
	&"recipe.blueprint_reference.missing"
)
const RECIPE_BLUEPRINT_REFERENCE_MISMATCH: StringName = (
	&"recipe.blueprint_reference.mismatch"
)

const LOOKUP_UNKNOWN_BLUEPRINT_ID: StringName = &"lookup.blueprint_id.unknown"
const LOOKUP_UNKNOWN_RECIPE_ID: StringName = &"lookup.recipe_id.unknown"
const LOOKUP_REGISTRY_UNINITIALIZED: StringName = &"lookup.registry.uninitialized"
const LOOKUP_UNKNOWN_MAINLINE_PROGRESSION_ID: StringName = (
	&"lookup.progression.mainline_id.unknown"
)
const LOOKUP_UNKNOWN_OPTIONAL_PROGRESSION_ID: StringName = (
	&"lookup.progression.optional_id.unknown"
)
const LOOKUP_UNKNOWN_PERMANENT_GROWTH_REWARD_ID: StringName = (
	&"lookup.progression.permanent_growth_reward_id.unknown"
)
const LOOKUP_PROGRESSION_CHAPTER_INVALID: StringName = (
	&"lookup.progression.chapter.invalid"
)
const LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED: StringName = (
	&"lookup.progression.registry.uninitialized"
)

var _code: StringName
var _content_id: StringName
var _field_path: String
var _message: String


func _init(
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> void:
	_code = code
	_content_id = content_id
	_field_path = field_path
	_message = message


func code() -> StringName:
	return _code


func content_id() -> StringName:
	return _content_id


func field_path() -> String:
	return _field_path


func message() -> String:
	return _message


func snapshot() -> ContentValidationIssue:
	return ContentValidationIssue.new(_code, _content_id, _field_path, _message)


func is_equal_to(other: ContentValidationIssue) -> bool:
	return (
		other != null
		and other.code() == _code
		and other.content_id() == _content_id
		and other.field_path() == _field_path
		and other.message() == _message
	)
