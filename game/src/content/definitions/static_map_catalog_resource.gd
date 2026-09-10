class_name StaticMapCatalogResource
extends Resource

const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")

@export var catalog_id: StringName = &""
@export var maps: Array[StaticMapDefinitionScript] = []


static func has_exact_entry_types(source: Resource) -> bool:
	if source == null or source.get_script() != StaticMapCatalogResource:
		return false
	for definition: StaticMapDefinitionScript in (source as StaticMapCatalogResource).maps:
		if not StaticMapDefinitionScript.has_exact_entry_types(definition):
			return false
	return true


static func snapshot(source: StaticMapCatalogResource) -> StaticMapCatalogResource:
	var result := StaticMapCatalogResource.new()
	result.catalog_id = source.catalog_id
	for definition: StaticMapDefinitionScript in source.maps:
		result.maps.append(StaticMapDefinitionScript.snapshot(definition))
	result.maps.sort_custom(map_less_than)
	return result


static func map_less_than(left: StaticMapDefinitionScript, right: StaticMapDefinitionScript) -> bool:
	return String(left.map_id) < String(right.map_id)
