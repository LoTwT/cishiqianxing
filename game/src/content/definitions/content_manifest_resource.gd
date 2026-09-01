class_name ContentManifestResource
extends Resource

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)

@export var schema_version: int = 1
@export var content_version: int = 1
@export var blueprints: Array[BlueprintDefinitionScript] = []
@export var recipes: Array[RecipeDefinitionScript] = []
