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
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)

const EXPECTED_FINGERPRINT: String = (
	"7fd9ffc1a99216dce18b21a4f756d2627feef84792291d62ff3e3e5558c61b56"
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
	ordered_blueprints.sort_custom(_blueprint_less_than)
	ordered_recipes.sort_custom(_recipe_less_than)
	ordered_mainline.sort_custom(_mainline_less_than)
	ordered_optional.sort_custom(_optional_less_than)

	var payload: String = "contract:v2;s%d;c%d;b%d;r%d;g%s;m%d;o%d;" % [
		schema_version,
		content_version,
		ordered_blueprints.size(),
		ordered_recipes.size(),
		_encode_string(String(progression_catalog.catalog_id)),
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
	for definition: MainlineProgressionDefinitionScript in ordered_mainline:
		payload += "M%s;i%d;i%d;i%d;i%d;i%d;" % [
			_encode_string(String(definition.content_id)),
			definition.chapter,
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
		]
	for definition: OptionalProgressionDefinitionScript in ordered_optional:
		payload += "O%s;%s;i%d;i%d;i%d;i%d;i%d;" % [
			_encode_string(String(definition.content_id)),
			_encode_string(String(definition.optional_map_id)),
			definition.available_after_chapter,
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
		]
	return payload.sha256_text()


static func _encode_string(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]


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
