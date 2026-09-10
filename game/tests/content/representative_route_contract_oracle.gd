extends RefCounted

# v6 digest reconstructed from independent literal domain oracles, including the technical map.
const FROZEN_V6_FINGERPRINT: String = (
	"fda9b0dd286340a6ff9eb4a523c2220e6fce7bf7d34f4743b77856d0fed2bc96"
)
const PLAYER_PROFILE_ID: StringName = &"progression.player.loer"
const TRADEOFF_DIMENSION_IDS: Array[StringName] = [
	&"route.cost.block",
	&"route.cost.consumable",
	&"route.cost.detour",
	&"route.cost.health",
	&"route.cost.one_time_node",
	&"route.cost.optional_reward",
]


class RouteRow extends RefCounted:
	var contract_id: StringName
	var stage_start_chapter: int
	var stage_end_chapter: int
	var backpack_slot_capacity: int
	var minimum_player_stats: Array[int]

	func _init(
		row_contract_id: StringName,
		row_stage_start_chapter: int,
		row_stage_end_chapter: int,
		row_backpack_slot_capacity: int,
		row_minimum_player_stats: Array[int],
	) -> void:
		contract_id = row_contract_id
		stage_start_chapter = row_stage_start_chapter
		stage_end_chapter = row_stage_end_chapter
		backpack_slot_capacity = row_backpack_slot_capacity
		minimum_player_stats = []
		for value: int in row_minimum_player_stats:
			minimum_player_stats.append(value)


static func rows() -> Array[RouteRow]:
	return [
		RouteRow.new(
			&"route.contract.main.stage.01_02", 1, 2, 12,
			[120, 11, 6, 10],
		),
		RouteRow.new(
			&"route.contract.main.stage.03_04", 3, 4, 16,
			[140, 13, 8, 11],
		),
		RouteRow.new(
			&"route.contract.main.stage.05_06", 5, 6, 20,
			[160, 15, 9, 12],
		),
		RouteRow.new(
			&"route.contract.main.stage.07_08", 7, 8, 24,
			[180, 16, 11, 13],
		),
		RouteRow.new(
			&"route.contract.main.stage.09", 9, 9, 24,
			[180, 16, 11, 14],
		),
	]


static func mainline_progression_ids_through(chapter: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for current_chapter: int in range(1, chapter + 1):
		result.append(
			StringName("progression.main.chapter.%02d" % current_chapter)
		)
	return result
