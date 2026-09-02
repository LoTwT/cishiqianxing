extends RefCounted

const FROZEN_V4_FINGERPRINT: String = (
	"bdbf394eb9e74a95eb5dc9fa789d99e0662a266a098706fc1d5f8a997687cad5"
)


class PlayerStatsRow extends RefCounted:
	var profile_id: StringName
	var maximum_health: int
	var attack: int
	var defense: int
	var speed: int

	func _init(
		row_profile_id: StringName,
		row_maximum_health: int,
		row_attack: int,
		row_defense: int,
		row_speed: int,
	) -> void:
		profile_id = row_profile_id
		maximum_health = row_maximum_health
		attack = row_attack
		defense = row_defense
		speed = row_speed

	func values() -> Array[int]:
		return [maximum_health, attack, defense, speed]


class RewardRow extends RefCounted:
	var reward_id: StringName
	var stat_kind: int
	var increase: int

	func _init(
		row_reward_id: StringName,
		row_stat_kind: int,
		row_increase: int,
	) -> void:
		reward_id = row_reward_id
		stat_kind = row_stat_kind
		increase = row_increase


class GroupRow extends RefCounted:
	var content_id: StringName
	var group_kind: int
	var chapter: int
	var optional_map_id: StringName
	var available_after_chapter: int
	var reward_ids: Array[StringName]
	var chapter_end_stats: Array[int]

	func _init(
		row_content_id: StringName,
		row_group_kind: int,
		row_chapter: int,
		row_optional_map_id: StringName,
		row_available_after_chapter: int,
		row_reward_ids: Array[StringName],
		row_chapter_end_stats: Array[int],
	) -> void:
		content_id = row_content_id
		group_kind = row_group_kind
		chapter = row_chapter
		optional_map_id = row_optional_map_id
		available_after_chapter = row_available_after_chapter
		reward_ids = []
		for reward_id: StringName in row_reward_ids:
			reward_ids.append(reward_id)
		chapter_end_stats = []
		for value: int in row_chapter_end_stats:
			chapter_end_stats.append(value)


static func initial_stats() -> PlayerStatsRow:
	return PlayerStatsRow.new(&"progression.player.loer", 100, 10, 5, 10)


static func reward_rows() -> Array[RewardRow]:
	return [
		RewardRow.new(&"progression.reward.main.chapter.01.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.01.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.02.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.02.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.03.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.03.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.03.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.04.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.04.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.04.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.04.speed", 4, 1),
		RewardRow.new(&"progression.reward.main.chapter.05.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.05.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.05.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.06.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.06.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.06.speed", 4, 1),
		RewardRow.new(&"progression.reward.main.chapter.07.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.07.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.07.speed", 4, 1),
		RewardRow.new(&"progression.reward.main.chapter.08.attack", 2, 1),
		RewardRow.new(&"progression.reward.main.chapter.08.defense", 3, 1),
		RewardRow.new(&"progression.reward.main.chapter.08.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.main.chapter.09.speed", 4, 1),
		RewardRow.new(&"progression.reward.optional.m01.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.optional.m02.attack", 2, 1),
		RewardRow.new(&"progression.reward.optional.m03.defense", 3, 1),
		RewardRow.new(&"progression.reward.optional.m03.maximum_health", 1, 10),
		RewardRow.new(&"progression.reward.optional.m04.attack", 2, 1),
		RewardRow.new(&"progression.reward.optional.m04.defense", 3, 1),
	]


static func group_rows() -> Array[GroupRow]:
	return [
		GroupRow.new(
			&"progression.main.chapter.01", 1, 1, &"", 0,
			[
				&"progression.reward.main.chapter.01.attack",
				&"progression.reward.main.chapter.01.maximum_health",
			],
			[110, 11, 5, 10],
		),
		GroupRow.new(
			&"progression.main.chapter.02", 1, 2, &"", 0,
			[
				&"progression.reward.main.chapter.02.defense",
				&"progression.reward.main.chapter.02.maximum_health",
			],
			[120, 11, 6, 10],
		),
		GroupRow.new(
			&"progression.main.chapter.03", 1, 3, &"", 0,
			[
				&"progression.reward.main.chapter.03.attack",
				&"progression.reward.main.chapter.03.defense",
				&"progression.reward.main.chapter.03.maximum_health",
			],
			[130, 12, 7, 10],
		),
		GroupRow.new(
			&"progression.main.chapter.04", 1, 4, &"", 0,
			[
				&"progression.reward.main.chapter.04.attack",
				&"progression.reward.main.chapter.04.defense",
				&"progression.reward.main.chapter.04.maximum_health",
				&"progression.reward.main.chapter.04.speed",
			],
			[140, 13, 8, 11],
		),
		GroupRow.new(
			&"progression.main.chapter.05", 1, 5, &"", 0,
			[
				&"progression.reward.main.chapter.05.attack",
				&"progression.reward.main.chapter.05.defense",
				&"progression.reward.main.chapter.05.maximum_health",
			],
			[150, 14, 9, 11],
		),
		GroupRow.new(
			&"progression.main.chapter.06", 1, 6, &"", 0,
			[
				&"progression.reward.main.chapter.06.attack",
				&"progression.reward.main.chapter.06.maximum_health",
				&"progression.reward.main.chapter.06.speed",
			],
			[160, 15, 9, 12],
		),
		GroupRow.new(
			&"progression.main.chapter.07", 1, 7, &"", 0,
			[
				&"progression.reward.main.chapter.07.defense",
				&"progression.reward.main.chapter.07.maximum_health",
				&"progression.reward.main.chapter.07.speed",
			],
			[170, 15, 10, 13],
		),
		GroupRow.new(
			&"progression.main.chapter.08", 1, 8, &"", 0,
			[
				&"progression.reward.main.chapter.08.attack",
				&"progression.reward.main.chapter.08.defense",
				&"progression.reward.main.chapter.08.maximum_health",
			],
			[180, 16, 11, 13],
		),
		GroupRow.new(
			&"progression.main.chapter.09", 1, 9, &"", 0,
			[&"progression.reward.main.chapter.09.speed"],
			[180, 16, 11, 14],
		),
		GroupRow.new(
			&"progression.optional.m01", 2, 0, &"M01", 2,
			[&"progression.reward.optional.m01.maximum_health"],
			[],
		),
		GroupRow.new(
			&"progression.optional.m02", 2, 0, &"M02", 4,
			[&"progression.reward.optional.m02.attack"],
			[],
		),
		GroupRow.new(
			&"progression.optional.m03", 2, 0, &"M03", 6,
			[
				&"progression.reward.optional.m03.defense",
				&"progression.reward.optional.m03.maximum_health",
			],
			[],
		),
		GroupRow.new(
			&"progression.optional.m04", 2, 0, &"M04", 8,
			[
				&"progression.reward.optional.m04.attack",
				&"progression.reward.optional.m04.defense",
			],
			[],
		),
	]


static func mainline_group_rows() -> Array[GroupRow]:
	var rows: Array[GroupRow] = []
	for row: GroupRow in group_rows():
		if row.group_kind == 1:
			rows.append(row)
	return rows


static func optional_group_rows() -> Array[GroupRow]:
	var rows: Array[GroupRow] = []
	for row: GroupRow in group_rows():
		if row.group_kind == 2:
			rows.append(row)
	return rows


static func full_completion_stats() -> Array[int]:
	return [200, 18, 13, 14]
