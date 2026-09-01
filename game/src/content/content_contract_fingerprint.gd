class_name ContentContractFingerprint
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)

const EXPECTED_FINGERPRINT: String = (
	"f6c215fc6341040c613f04be1f66d1d232c15ade155f520c46a9c560e92ca0ad"
)


static func matches(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
) -> bool:
	return (
		not EXPECTED_FINGERPRINT.is_empty()
		and calculate(schema_version, content_version, blueprints, recipes)
		== EXPECTED_FINGERPRINT
	)


static func calculate(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
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
	ordered_blueprints.sort_custom(_blueprint_less_than)
	ordered_recipes.sort_custom(_recipe_less_than)

	var payload: String = "contract:v1;s%d;c%d;b%d;r%d;" % [
		schema_version,
		content_version,
		ordered_blueprints.size(),
		ordered_recipes.size(),
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
