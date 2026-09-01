class_name PermanentGrowthRewardDefinitionResource
extends Resource

enum StatKind {
	MAXIMUM_HEALTH = 1,
	ATTACK = 2,
	DEFENSE = 3,
	SPEED = 4,
}

@export var reward_id: StringName = &""
@export var stat_kind: int = 0
@export var increase: int = 0


static func snapshot(
	source: PermanentGrowthRewardDefinitionResource,
) -> PermanentGrowthRewardDefinitionResource:
	var copied_definition := PermanentGrowthRewardDefinitionResource.new()
	copied_definition.reward_id = source.reward_id
	copied_definition.stat_kind = source.stat_kind
	copied_definition.increase = source.increase
	return copied_definition


func is_equal_to(other: PermanentGrowthRewardDefinitionResource) -> bool:
	return (
		other != null
		and other.reward_id == reward_id
		and other.stat_kind == stat_kind
		and other.increase == increase
	)
