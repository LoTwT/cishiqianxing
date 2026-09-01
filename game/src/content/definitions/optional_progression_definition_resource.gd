class_name OptionalProgressionDefinitionResource
extends Resource

@export var content_id: StringName = &""
@export var optional_map_id: StringName = &""
@export var available_after_chapter: int = 0
@export var maximum_health_increase: int = 0
@export var attack_increase: int = 0
@export var defense_increase: int = 0
@export var speed_increase: int = 0


static func snapshot(
	source: OptionalProgressionDefinitionResource,
) -> OptionalProgressionDefinitionResource:
	var copied_definition := OptionalProgressionDefinitionResource.new()
	copied_definition.content_id = source.content_id
	copied_definition.optional_map_id = source.optional_map_id
	copied_definition.available_after_chapter = source.available_after_chapter
	copied_definition.maximum_health_increase = source.maximum_health_increase
	copied_definition.attack_increase = source.attack_increase
	copied_definition.defense_increase = source.defense_increase
	copied_definition.speed_increase = source.speed_increase
	return copied_definition


func is_equal_to(other: OptionalProgressionDefinitionResource) -> bool:
	return (
		other != null
		and other.content_id == content_id
		and other.optional_map_id == optional_map_id
		and other.available_after_chapter == available_after_chapter
		and other.maximum_health_increase == maximum_health_increase
		and other.attack_increase == attack_increase
		and other.defense_increase == defense_increase
		and other.speed_increase == speed_increase
	)
