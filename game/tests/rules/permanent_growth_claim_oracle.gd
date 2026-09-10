extends RefCounted

const PROFILE_ID: StringName = &"progression.player.loer"
const CONTENT_SCHEMA_VERSION: int = 6
const CONTENT_VERSION: int = 6


class RewardTransitionRow extends RefCounted:
	var reward_id: StringName
	var stat_kind: int
	var increase: int
	var expected_from_full_health: Array[int]
	var expected_from_damaged_health: Array[int]

	func _init(
		row_reward_id: StringName,
		row_stat_kind: int,
		row_increase: int,
		row_expected_from_full_health: Array[int],
		row_expected_from_damaged_health: Array[int],
	) -> void:
		reward_id = row_reward_id
		stat_kind = row_stat_kind
		increase = row_increase
		expected_from_full_health = row_expected_from_full_health.duplicate()
		expected_from_damaged_health = row_expected_from_damaged_health.duplicate()


static func reward_rows() -> Array[RewardTransitionRow]:
	return [
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.01.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.01.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.02.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.02.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.03.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.03.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.03.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.04.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.04.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.04.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.04.speed", 4, 1,
			[100, 100, 10, 5, 11], [80, 100, 10, 5, 11],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.05.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.05.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.05.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.06.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.06.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.06.speed", 4, 1,
			[100, 100, 10, 5, 11], [80, 100, 10, 5, 11],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.07.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.07.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.07.speed", 4, 1,
			[100, 100, 10, 5, 11], [80, 100, 10, 5, 11],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.08.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.08.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.08.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.main.chapter.09.speed", 4, 1,
			[100, 100, 10, 5, 11], [80, 100, 10, 5, 11],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m01.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m02.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m03.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m03.maximum_health", 1, 10,
			[110, 110, 10, 5, 10], [90, 110, 10, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m04.attack", 2, 1,
			[100, 100, 11, 5, 10], [80, 100, 11, 5, 10],
		),
		RewardTransitionRow.new(
			&"progression.reward.optional.m04.defense", 3, 1,
			[100, 100, 10, 6, 10], [80, 100, 10, 6, 10],
		),
	]


static func all_reward_ids() -> Array[StringName]:
	return [
		&"progression.reward.main.chapter.01.attack",
		&"progression.reward.main.chapter.01.maximum_health",
		&"progression.reward.main.chapter.02.defense",
		&"progression.reward.main.chapter.02.maximum_health",
		&"progression.reward.main.chapter.03.attack",
		&"progression.reward.main.chapter.03.defense",
		&"progression.reward.main.chapter.03.maximum_health",
		&"progression.reward.main.chapter.04.attack",
		&"progression.reward.main.chapter.04.defense",
		&"progression.reward.main.chapter.04.maximum_health",
		&"progression.reward.main.chapter.04.speed",
		&"progression.reward.main.chapter.05.attack",
		&"progression.reward.main.chapter.05.defense",
		&"progression.reward.main.chapter.05.maximum_health",
		&"progression.reward.main.chapter.06.attack",
		&"progression.reward.main.chapter.06.maximum_health",
		&"progression.reward.main.chapter.06.speed",
		&"progression.reward.main.chapter.07.defense",
		&"progression.reward.main.chapter.07.maximum_health",
		&"progression.reward.main.chapter.07.speed",
		&"progression.reward.main.chapter.08.attack",
		&"progression.reward.main.chapter.08.defense",
		&"progression.reward.main.chapter.08.maximum_health",
		&"progression.reward.main.chapter.09.speed",
		&"progression.reward.optional.m01.maximum_health",
		&"progression.reward.optional.m02.attack",
		&"progression.reward.optional.m03.defense",
		&"progression.reward.optional.m03.maximum_health",
		&"progression.reward.optional.m04.attack",
		&"progression.reward.optional.m04.defense",
	]


static func mainline_reward_ids() -> Array[StringName]:
	return [
		&"progression.reward.main.chapter.01.attack",
		&"progression.reward.main.chapter.01.maximum_health",
		&"progression.reward.main.chapter.02.defense",
		&"progression.reward.main.chapter.02.maximum_health",
		&"progression.reward.main.chapter.03.attack",
		&"progression.reward.main.chapter.03.defense",
		&"progression.reward.main.chapter.03.maximum_health",
		&"progression.reward.main.chapter.04.attack",
		&"progression.reward.main.chapter.04.defense",
		&"progression.reward.main.chapter.04.maximum_health",
		&"progression.reward.main.chapter.04.speed",
		&"progression.reward.main.chapter.05.attack",
		&"progression.reward.main.chapter.05.defense",
		&"progression.reward.main.chapter.05.maximum_health",
		&"progression.reward.main.chapter.06.attack",
		&"progression.reward.main.chapter.06.maximum_health",
		&"progression.reward.main.chapter.06.speed",
		&"progression.reward.main.chapter.07.defense",
		&"progression.reward.main.chapter.07.maximum_health",
		&"progression.reward.main.chapter.07.speed",
		&"progression.reward.main.chapter.08.attack",
		&"progression.reward.main.chapter.08.defense",
		&"progression.reward.main.chapter.08.maximum_health",
		&"progression.reward.main.chapter.09.speed",
	]


static func optional_reward_ids() -> Array[StringName]:
	return [
		&"progression.reward.optional.m01.maximum_health",
		&"progression.reward.optional.m02.attack",
		&"progression.reward.optional.m03.defense",
		&"progression.reward.optional.m03.maximum_health",
		&"progression.reward.optional.m04.attack",
		&"progression.reward.optional.m04.defense",
	]


static func group_ids() -> Array[StringName]:
	return [
		&"progression.main.chapter.01",
		&"progression.main.chapter.02",
		&"progression.main.chapter.03",
		&"progression.main.chapter.04",
		&"progression.main.chapter.05",
		&"progression.main.chapter.06",
		&"progression.main.chapter.07",
		&"progression.main.chapter.08",
		&"progression.main.chapter.09",
		&"progression.optional.m01",
		&"progression.optional.m02",
		&"progression.optional.m03",
		&"progression.optional.m04",
	]
