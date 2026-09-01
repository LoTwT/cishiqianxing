class_name ContentContractFingerprint
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
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)

const EXPECTED_FINGERPRINT: String = (
	"e213f5a2f75fb3744c68c3046422df2ead4891dfd1b470f452f0c9facd210adc"
)


static func matches(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
) -> bool:
	return (
		not EXPECTED_FINGERPRINT.is_empty()
		and calculate(
			schema_version,
			content_version,
			blueprints,
			recipes,
			progression_catalog,
		)
		== EXPECTED_FINGERPRINT
	)


static func calculate(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
) -> String:
	var ordered_blueprints: Array[BlueprintDefinitionScript] = []
	for blueprint: BlueprintDefinitionScript in blueprints:
		if blueprint == null or blueprint.get_script() != BlueprintDefinitionScript:
			return ""
		ordered_blueprints.append(blueprint)
	var ordered_recipes: Array[RecipeDefinitionScript] = []
	for recipe: RecipeDefinitionScript in recipes:
		if recipe == null or recipe.get_script() != RecipeDefinitionScript:
			return ""
		ordered_recipes.append(recipe)
	var catalog_resource: Resource = progression_catalog as Resource
	if (
		catalog_resource == null
		or catalog_resource.get_script() != GlobalProgressionCatalogScript
	):
		return ""
	var profile_resource: Resource = progression_catalog.initial_stats as Resource
	if (
		profile_resource == null
		or profile_resource.get_script() != PlayerStatProfileScript
	):
		return ""
	var ordered_mainline: Array[MainlineProgressionDefinitionScript] = []
	for definition: MainlineProgressionDefinitionScript in (
		progression_catalog.mainline_progression
	):
		var definition_resource: Resource = definition as Resource
		if (
			definition_resource == null
			or definition_resource.get_script() != MainlineProgressionDefinitionScript
		):
			return ""
		ordered_mainline.append(definition)
	var ordered_optional: Array[OptionalProgressionDefinitionScript] = []
	for definition: OptionalProgressionDefinitionScript in (
		progression_catalog.optional_progression
	):
		var definition_resource: Resource = definition as Resource
		if (
			definition_resource == null
			or definition_resource.get_script() != OptionalProgressionDefinitionScript
		):
			return ""
		ordered_optional.append(definition)
	var ordered_rewards: Array[PermanentGrowthRewardDefinitionScript] = []
	for reward: PermanentGrowthRewardDefinitionScript in (
		progression_catalog.permanent_growth_rewards
	):
		var reward_resource: Resource = reward as Resource
		if (
			reward_resource == null
			or reward_resource.get_script() != PermanentGrowthRewardDefinitionScript
		):
			return ""
		ordered_rewards.append(reward)
	ordered_blueprints.sort_custom(_blueprint_less_than)
	ordered_recipes.sort_custom(_recipe_less_than)
	ordered_mainline.sort_custom(_mainline_less_than)
	ordered_optional.sort_custom(_optional_less_than)
	ordered_rewards.sort_custom(_reward_less_than)

	var payload: String = "contract:v3;s%d;c%d;b%d;r%d;g%s;a%d;m%d;o%d;" % [
		schema_version,
		content_version,
		ordered_blueprints.size(),
		ordered_recipes.size(),
		_encode_string(String(progression_catalog.catalog_id)),
		ordered_rewards.size(),
		ordered_mainline.size(),
		ordered_optional.size(),
	]
	for blueprint: BlueprintDefinitionScript in ordered_blueprints:
		payload += "B%s;i%d;i%d;i%d;i%d;i%d;%s;%s;%s;%s;" % [
			_encode_string(String(blueprint.content_id)),
			blueprint.ordinal,
			blueprint.category,
			blueprint.tier,
			blueprint.unlock_chapter,
			blueprint.default_lifecycle,
			_encode_string(String(blueprint.standard_recipe_id)),
			_encode_string(String(blueprint.mechanic_id)),
			_encode_string(String(blueprint.display_name_text_id)),
			_encode_string(String(blueprint.function_text_id)),
		]
	for recipe: RecipeDefinitionScript in ordered_recipes:
		payload += "R%s;%s;%s;i%d;%s;i%d;" % [
			_encode_string(String(recipe.recipe_id)),
			_encode_string(String(recipe.output_blueprint_id)),
			_encode_string(String(recipe.main_material_id)),
			recipe.main_quantity,
			_encode_string(String(recipe.auxiliary_material_id)),
			recipe.auxiliary_quantity,
		]
	var initial_stats: PlayerStatProfileScript = progression_catalog.initial_stats
	payload += "P%s;i%d;i%d;i%d;i%d;" % [
		_encode_string(String(initial_stats.profile_id)),
		initial_stats.maximum_health,
		initial_stats.attack,
		initial_stats.defense,
		initial_stats.speed,
	]
	for reward: PermanentGrowthRewardDefinitionScript in ordered_rewards:
		payload += "A%s;i%d;i%d;" % [
			_encode_string(String(reward.reward_id)),
			reward.stat_kind,
			reward.increase,
		]
	for definition: MainlineProgressionDefinitionScript in ordered_mainline:
		var ordered_reward_ids: Array[StringName] = _ordered_reward_ids(
			definition.reward_ids
		)
		payload += "M%s;i%d;a%d;" % [
			_encode_string(String(definition.content_id)),
			definition.chapter,
			ordered_reward_ids.size(),
		]
		for reward_id: StringName in ordered_reward_ids:
			payload += "a%s;" % _encode_string(String(reward_id))
	for definition: OptionalProgressionDefinitionScript in ordered_optional:
		var ordered_reward_ids: Array[StringName] = _ordered_reward_ids(
			definition.reward_ids
		)
		payload += "O%s;%s;i%d;a%d;" % [
			_encode_string(String(definition.content_id)),
			_encode_string(String(definition.optional_map_id)),
			definition.available_after_chapter,
			ordered_reward_ids.size(),
		]
		for reward_id: StringName in ordered_reward_ids:
			payload += "a%s;" % _encode_string(String(reward_id))
	return payload.sha256_text()


static func _encode_string(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]


static func _ordered_reward_ids(reward_ids: Array[StringName]) -> Array[StringName]:
	var ordered_reward_ids: Array[StringName] = []
	for reward_id: StringName in reward_ids:
		ordered_reward_ids.append(reward_id)
	ordered_reward_ids.sort_custom(_string_name_less_than)
	return ordered_reward_ids


static func _blueprint_less_than(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _recipe_less_than(
	left: RecipeDefinitionScript,
	right: RecipeDefinitionScript,
) -> bool:
	return String(left.recipe_id) < String(right.recipe_id)


static func _mainline_less_than(
	left: MainlineProgressionDefinitionScript,
	right: MainlineProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _optional_less_than(
	left: OptionalProgressionDefinitionScript,
	right: OptionalProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _reward_less_than(
	left: PermanentGrowthRewardDefinitionScript,
	right: PermanentGrowthRewardDefinitionScript,
) -> bool:
	var left_id := String(left.reward_id)
	var right_id := String(right.reward_id)
	if left_id != right_id:
		return left_id < right_id
	if left.stat_kind != right.stat_kind:
		return left.stat_kind < right.stat_kind
	return left.increase < right.increase


static func _string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
