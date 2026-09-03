class_name ContentManifestResource
extends Resource

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
)

@export var schema_version: int = 5
@export var content_version: int = 5
@export var blueprints: Array[BlueprintDefinitionScript] = []
@export var recipes: Array[RecipeDefinitionScript] = []
@export var global_progression_catalog: GlobalProgressionCatalogScript
@export var representative_route_contract_catalog: RepresentativeRouteCatalogScript
@export var enemy_profile_catalog: EnemyProfileCatalogScript
