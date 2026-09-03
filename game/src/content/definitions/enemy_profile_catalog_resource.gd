class_name EnemyProfileCatalogResource
extends Resource

const EnemyFamilyDefinitionScript := preload(
	"res://src/content/definitions/enemy_family_definition_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)

@export var catalog_id: StringName = &""
@export var families: Array[EnemyFamilyDefinitionScript] = []
@export var profiles: Array[EnemyProfileDefinitionScript] = []


static func snapshot(
	source_catalog: EnemyProfileCatalogResource,
) -> EnemyProfileCatalogResource:
	var copied_catalog := EnemyProfileCatalogResource.new()
	copied_catalog.catalog_id = source_catalog.catalog_id
	for family: EnemyFamilyDefinitionScript in source_catalog.families:
		copied_catalog.families.append(
			EnemyFamilyDefinitionScript.snapshot(family)
		)
	for profile: EnemyProfileDefinitionScript in source_catalog.profiles:
		copied_catalog.profiles.append(
			EnemyProfileDefinitionScript.snapshot(profile)
		)
	return copied_catalog


func is_equal_to(other: EnemyProfileCatalogResource) -> bool:
	if (
		other == null
		or other.catalog_id != catalog_id
		or other.families.size() != families.size()
		or other.profiles.size() != profiles.size()
	):
		return false
	for index: int in range(families.size()):
		if not families[index].is_equal_to(other.families[index]):
			return false
	for index: int in range(profiles.size()):
		if not profiles[index].is_equal_to(other.profiles[index]):
			return false
	return true
