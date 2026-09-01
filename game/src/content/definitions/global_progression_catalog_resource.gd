class_name GlobalProgressionCatalogResource
extends Resource

const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const MainlineProgressionDefinitionScript := preload(
	"res://src/content/definitions/mainline_progression_definition_resource.gd"
)
const OptionalProgressionDefinitionScript := preload(
	"res://src/content/definitions/optional_progression_definition_resource.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)

@export var catalog_id: StringName = &""
@export var initial_stats: PlayerStatProfileScript
@export var mainline_progression: Array[MainlineProgressionDefinitionScript] = []
@export var optional_progression: Array[OptionalProgressionDefinitionScript] = []
@export var permanent_growth_rewards: Array[PermanentGrowthRewardDefinitionScript] = []


static func snapshot(
	source: GlobalProgressionCatalogResource,
) -> GlobalProgressionCatalogResource:
	var copied_catalog := GlobalProgressionCatalogResource.new()
	copied_catalog.catalog_id = source.catalog_id
	if source.initial_stats != null:
		copied_catalog.initial_stats = PlayerStatProfileScript.snapshot(
			source.initial_stats
		)
	for definition: MainlineProgressionDefinitionScript in source.mainline_progression:
		copied_catalog.mainline_progression.append(
			MainlineProgressionDefinitionScript.snapshot(definition)
		)
	for definition: OptionalProgressionDefinitionScript in source.optional_progression:
		copied_catalog.optional_progression.append(
			OptionalProgressionDefinitionScript.snapshot(definition)
		)
	for reward: PermanentGrowthRewardDefinitionScript in (
		source.permanent_growth_rewards
	):
		copied_catalog.permanent_growth_rewards.append(
			PermanentGrowthRewardDefinitionScript.snapshot(reward)
		)
	return copied_catalog


func is_equal_to(other: GlobalProgressionCatalogResource) -> bool:
	if (
		other == null
		or other.catalog_id != catalog_id
		or (initial_stats == null) != (other.initial_stats == null)
		or other.mainline_progression.size() != mainline_progression.size()
		or other.optional_progression.size() != optional_progression.size()
		or other.permanent_growth_rewards.size() != permanent_growth_rewards.size()
	):
		return false
	if initial_stats != null and not initial_stats.is_equal_to(other.initial_stats):
		return false
	for index: int in range(mainline_progression.size()):
		if not mainline_progression[index].is_equal_to(
			other.mainline_progression[index]
		):
			return false
	for index: int in range(optional_progression.size()):
		if not optional_progression[index].is_equal_to(
			other.optional_progression[index]
		):
			return false
	for index: int in range(permanent_growth_rewards.size()):
		if not permanent_growth_rewards[index].is_equal_to(
			other.permanent_growth_rewards[index]
		):
			return false
	return true
