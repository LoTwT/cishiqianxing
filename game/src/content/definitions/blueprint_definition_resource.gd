class_name BlueprintDefinitionResource
extends Resource

enum Category {
	STRUCTURE = 1,
	MECHANISM = 2,
	SUPPORT = 3,
	EXTENSION = 4,
	ATTRIBUTE = 5,
}

enum Tier {
	BASIC = 1,
	ADVANCED = 2,
}

enum Lifecycle {
	RECOVERABLE = 1,
	CONSUMABLE = 2,
}

@export var content_id: StringName = &""
@export var ordinal: int = 0
@export var category: int = 0
@export var tier: int = 0
@export var unlock_chapter: int = 0
@export var default_lifecycle: int = 0
@export var standard_recipe_id: StringName = &""
@export var mechanic_id: StringName = &""
@export var display_name_text_id: StringName = &""
@export var function_text_id: StringName = &""


static func snapshot(
	source: BlueprintDefinitionResource,
) -> BlueprintDefinitionResource:
	var copied_definition := BlueprintDefinitionResource.new()
	copied_definition.content_id = source.content_id
	copied_definition.ordinal = source.ordinal
	copied_definition.category = source.category
	copied_definition.tier = source.tier
	copied_definition.unlock_chapter = source.unlock_chapter
	copied_definition.default_lifecycle = source.default_lifecycle
	copied_definition.standard_recipe_id = source.standard_recipe_id
	copied_definition.mechanic_id = source.mechanic_id
	copied_definition.display_name_text_id = source.display_name_text_id
	copied_definition.function_text_id = source.function_text_id
	return copied_definition


func is_equal_to(other: BlueprintDefinitionResource) -> bool:
	return (
		other != null
		and other.content_id == content_id
		and other.ordinal == ordinal
		and other.category == category
		and other.tier == tier
		and other.unlock_chapter == unlock_chapter
		and other.default_lifecycle == default_lifecycle
		and other.standard_recipe_id == standard_recipe_id
		and other.mechanic_id == mechanic_id
		and other.display_name_text_id == display_name_text_id
		and other.function_text_id == function_text_id
	)
