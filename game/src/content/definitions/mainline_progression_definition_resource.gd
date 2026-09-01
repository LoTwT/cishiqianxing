class_name MainlineProgressionDefinitionResource
extends Resource

@export var content_id: StringName = &""
@export var chapter: int = 0
@export var maximum_health_increase: int = 0
@export var attack_increase: int = 0
@export var defense_increase: int = 0
@export var speed_increase: int = 0


static func snapshot(
	source: MainlineProgressionDefinitionResource,
) -> MainlineProgressionDefinitionResource:
	var copied_definition := MainlineProgressionDefinitionResource.new()
	copied_definition.content_id = source.content_id
	copied_definition.chapter = source.chapter
	copied_definition.maximum_health_increase = source.maximum_health_increase
	copied_definition.attack_increase = source.attack_increase
	copied_definition.defense_increase = source.defense_increase
	copied_definition.speed_increase = source.speed_increase
	return copied_definition


func is_equal_to(other: MainlineProgressionDefinitionResource) -> bool:
	return (
		other != null
		and other.content_id == content_id
		and other.chapter == chapter
		and other.maximum_health_increase == maximum_health_increase
		and other.attack_increase == attack_increase
		and other.defense_increase == defense_increase
		and other.speed_increase == speed_increase
	)
