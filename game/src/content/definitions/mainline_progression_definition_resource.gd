class_name MainlineProgressionDefinitionResource
extends Resource

@export var content_id: StringName = &""
@export var chapter: int = 0
@export var reward_ids: Array[StringName] = []


static func snapshot(
	source: MainlineProgressionDefinitionResource,
) -> MainlineProgressionDefinitionResource:
	var copied_definition := MainlineProgressionDefinitionResource.new()
	copied_definition.content_id = source.content_id
	copied_definition.chapter = source.chapter
	for reward_id: StringName in source.reward_ids:
		copied_definition.reward_ids.append(reward_id)
	return copied_definition


func is_equal_to(other: MainlineProgressionDefinitionResource) -> bool:
	return (
		other != null
		and other.content_id == content_id
		and other.chapter == chapter
		and other.reward_ids == reward_ids
	)
