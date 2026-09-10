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
const MANIFEST_CONTRACT_FINGERPRINT_MISMATCH: StringName = (
	&"manifest.contract_fingerprint.mismatch"
)
const MANIFEST_BLUEPRINT_COUNT_INVALID: StringName = &"manifest.blueprint_count.invalid"
const MANIFEST_RECIPE_COUNT_INVALID: StringName = &"manifest.recipe_count.invalid"
const MANIFEST_PROGRESSION_CATALOG_NULL: StringName = (
	&"manifest.global_progression_catalog.null"
)
const MANIFEST_ROUTE_CONTRACT_CATALOG_NULL: StringName = (
	&"manifest.representative_route_contract_catalog.null"
)
const MANIFEST_ENEMY_PROFILE_CATALOG_NULL: StringName = (
	&"manifest.enemy_profile_catalog.null"
)

const ENEMY_CATALOG_INVALID_SCRIPT: StringName = &"enemy.catalog.invalid_script"
const ENEMY_CATALOG_ID_INVALID: StringName = &"enemy.catalog_id.invalid"
const ENEMY_FAMILY_COUNT_INVALID: StringName = &"enemy.family_count.invalid"
const ENEMY_PROFILE_COUNT_INVALID: StringName = &"enemy.profile_count.invalid"
const ENEMY_FAMILY_ENTRY_NULL: StringName = &"enemy.family.entry.null"
const ENEMY_FAMILY_ENTRY_INVALID_SCRIPT: StringName = (
	&"enemy.family.entry.invalid_script"
)
const ENEMY_PROFILE_ENTRY_NULL: StringName = &"enemy.profile.entry.null"
const ENEMY_PROFILE_ENTRY_INVALID_SCRIPT: StringName = (
	&"enemy.profile.entry.invalid_script"
)
const ENEMY_FAMILY_ID_INVALID: StringName = &"enemy.family_id.invalid"
const ENEMY_FAMILY_ID_DUPLICATE: StringName = &"enemy.family_id.duplicate"
const ENEMY_FAMILY_ORDINAL_DUPLICATE: StringName = (
	&"enemy.family.ordinal.duplicate"
)
const ENEMY_FAMILY_FIELD_MISMATCH: StringName = &"enemy.family.field_mismatch"
const ENEMY_FAMILY_VISUAL_ID_DUPLICATE: StringName = (
	&"enemy.family.visual_id.duplicate"
)
const ENEMY_FAMILY_SOURCE_DISTRIBUTION_INVALID: StringName = (
	&"enemy.family.source_distribution.invalid"
)
const ENEMY_PROFILE_ID_INVALID: StringName = &"enemy.profile_id.invalid"
const ENEMY_PROFILE_ID_DUPLICATE: StringName = &"enemy.profile_id.duplicate"
const ENEMY_PROFILE_FAMILY_REFERENCE_INVALID: StringName = (
	&"enemy.profile.family_reference.invalid"
)
const ENEMY_PROFILE_BALANCE_CONTRACT_REFERENCE_INVALID: StringName = (
	&"enemy.profile.balance_contract_reference.invalid"
)
const ENEMY_PROFILE_BEHAVIOR_ID_INVALID: StringName = (
	&"enemy.profile.behavior_id.invalid"
)
const ENEMY_PROFILE_TRAIT_ID_INVALID: StringName = &"enemy.profile.trait_id.invalid"
const ENEMY_PROFILE_TRAIT_ID_DUPLICATE: StringName = (
	&"enemy.profile.trait_id.duplicate"
)
const ENEMY_PROFILE_STATS_INVALID: StringName = &"enemy.profile.stats.invalid"
const ENEMY_PROFILE_ALTERNATE_STATE_INVALID: StringName = (
	&"enemy.profile.alternate_state.invalid"
)
const ENEMY_PROFILE_VISUAL_ID_DUPLICATE: StringName = (
	&"enemy.profile.visual_id.duplicate"
)
const ENEMY_PROFILE_FAMILY_TIER_PAIR_INVALID: StringName = (
	&"enemy.profile.family_tier_pair.invalid"
)
const ENEMY_PROFILE_FIELD_MISMATCH: StringName = &"enemy.profile.field_mismatch"
const ENEMY_PROFILE_BALANCE_CONTEXT_INVALID: StringName = (
	&"enemy.profile.balance_context.invalid"
)
const ENEMY_PROFILE_BALANCE_EVALUATION_FAILED: StringName = (
	&"enemy.profile.balance_evaluation.failed"
)
const ENEMY_PROFILE_PLAYER_DAMAGE_TOO_LOW: StringName = (
	&"enemy.profile.player_damage.too_low"
)
const ENEMY_PROFILE_ATTACK_COUNT_INVALID: StringName = (
	&"enemy.profile.attack_count.invalid"
)
const ENEMY_PROFILE_SHIELD_ATTACK_DELTA_INVALID: StringName = (
	&"enemy.profile.shield_attack_delta.invalid"
)
const ENEMY_PROFILE_NOT_CLEARABLE: StringName = &"enemy.profile.not_clearable"
const ENEMY_PROFILE_HEALTH_LOSS_INVALID: StringName = (
	&"enemy.profile.health_loss.invalid"
)
const ENEMY_PROFILE_SPEED_ARCHETYPE_INVALID: StringName = (
	&"enemy.profile.speed_archetype.invalid"
)

const ROUTE_CATALOG_INVALID_SCRIPT: StringName = &"route.catalog.invalid_script"
const ROUTE_CATALOG_ID_INVALID: StringName = &"route.catalog_id.invalid"
const ROUTE_CONTRACT_COUNT_INVALID: StringName = &"route.contract_count.invalid"
const ROUTE_CONTRACT_ENTRY_NULL: StringName = &"route.contract.entry.null"
const ROUTE_CONTRACT_ENTRY_INVALID_SCRIPT: StringName = (
	&"route.contract.entry.invalid_script"
)
const ROUTE_CONTRACT_ID_EMPTY: StringName = &"route.contract_id.empty"
const ROUTE_CONTRACT_ID_INVALID: StringName = &"route.contract_id.invalid"
const ROUTE_CONTRACT_ID_DUPLICATE: StringName = &"route.contract_id.duplicate"
const ROUTE_CONTRACT_ID_STAGE_MISMATCH: StringName = (
	&"route.contract_id.stage_mismatch"
)
const ROUTE_STAGE_RANGE_INVALID: StringName = &"route.stage_range.invalid"
const ROUTE_CHAPTER_COVERAGE_INVALID: StringName = &"route.chapter_coverage.invalid"
const ROUTE_PLAYER_PROFILE_REFERENCE_INVALID: StringName = (
	&"route.player_profile_reference.invalid"
)
const ROUTE_PROGRESSION_REFERENCE_INVALID: StringName = (
	&"route.progression_reference.invalid"
)
const ROUTE_BLUEPRINT_REFERENCE_INVALID: StringName = (
	&"route.blueprint_reference.invalid"
)
const ROUTE_BACKPACK_CAPACITY_INVALID: StringName = (
	&"route.backpack_capacity.invalid"
)
const ROUTE_ENCOUNTER_RANGE_INVALID: StringName = &"route.encounter_range.invalid"
const ROUTE_CONTACT_RANGE_INVALID: StringName = &"route.contact_range.invalid"
const ROUTE_EXIT_HEALTH_THRESHOLD_INVALID: StringName = (
	&"route.exit_health_threshold.invalid"
)
const ROUTE_RECOVERY_POINT_COUNT_INVALID: StringName = (
	&"route.recovery_point_count.invalid"
)
const ROUTE_LEGAL_ALTERNATIVE_COUNT_INVALID: StringName = (
	&"route.legal_alternative_count.invalid"
)
const ROUTE_TRADEOFF_DIMENSION_INVALID: StringName = (
	&"route.tradeoff_dimension.invalid"
)
const ROUTE_DOMINANCE_POLICY_INVALID: StringName = (
	&"route.dominance_policy.invalid"
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
const LOOKUP_UNKNOWN_ROUTE_CONTRACT_ID: StringName = (
	&"lookup.route_contract_id.unknown"
)
const LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED: StringName = (
	&"lookup.route_contract.registry.uninitialized"
)
const LOOKUP_UNKNOWN_ENEMY_FAMILY_ID: StringName = (
	&"lookup.enemy_family_id.unknown"
)
const LOOKUP_UNKNOWN_ENEMY_PROFILE_ID: StringName = (
	&"lookup.enemy_profile_id.unknown"
)
const LOOKUP_ENEMY_REGISTRY_UNINITIALIZED: StringName = (
	&"lookup.enemy.registry.uninitialized"
)

const MAP_INVALID_RESOURCE: StringName = &"map.resource.invalid"
const MAP_SOURCE_DECLARATION_INVALID: StringName = &"map.sources.invalid"
const MAP_CATALOG_INVALID: StringName = &"map.catalog.invalid"
const MAP_ID_INVALID: StringName = &"map.id.invalid"
const MAP_SPACE_ID_INVALID: StringName = &"map.space_id.invalid"
const MAP_INSTANCE_ID_INVALID: StringName = &"map.instance_id.invalid"
const MAP_REFERENCE_INVALID: StringName = &"map.reference.invalid"
const MAP_CHAPTER_INVALID: StringName = &"map.chapter.invalid"
const MAP_UNSUPPORTED_CONTENT: StringName = &"map.content.unsupported"
const MAP_GEOMETRY_INVALID: StringName = &"map.geometry.invalid"
const MAP_BALANCE_INVALID: StringName = &"map.balance.invalid"
const LOOKUP_UNKNOWN_MAP_ID: StringName = &"lookup.map_id.unknown"

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
