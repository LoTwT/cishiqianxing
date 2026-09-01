class_name OptionalProgressionDefinitionResource
extends Resource

@export var content_id: StringName = &""
@export var optional_map_id: StringName = &""
@export var available_after_chapter: int = 0
@export var reward_ids: Array[StringName] = []


static func snapshot(
	source: OptionalProgressionDefinitionResource,
) -> OptionalProgressionDefinitionResource:
	var copied_definition := OptionalProgressionDefinitionResource.new()
	copied_definition.content_id = source.content_id
	copied_definition.optional_map_id = source.optional_map_id
	copied_definition.available_after_chapter = source.available_after_chapter
	for reward_id: StringName in source.reward_ids:
		copied_definition.reward_ids.append(reward_id)
	return copied_definition


func is_equal_to(other: OptionalProgressionDefinitionResource) -> bool:
	return (
		other != null
		and other.content_id == content_id
		and other.optional_map_id == optional_map_id
		and other.available_after_chapter == available_after_chapter
		and other.reward_ids == reward_ids
	)
