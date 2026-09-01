extends RefCounted


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


class MainlineRow extends RefCounted:
	var content_id: StringName
	var chapter: int
	var maximum_health_increase: int
	var attack_increase: int
	var defense_increase: int
	var speed_increase: int
	var chapter_end_stats: Array[int]

	func _init(
		row_content_id: StringName,
		row_chapter: int,
		row_maximum_health_increase: int,
		row_attack_increase: int,
		row_defense_increase: int,
		row_speed_increase: int,
		row_chapter_end_stats: Array[int],
	) -> void:
		content_id = row_content_id
		chapter = row_chapter
		maximum_health_increase = row_maximum_health_increase
		attack_increase = row_attack_increase
		defense_increase = row_defense_increase
		speed_increase = row_speed_increase
		chapter_end_stats = []
		for value: int in row_chapter_end_stats:
			chapter_end_stats.append(value)

	func delta_values() -> Array[int]:
		return [
			maximum_health_increase,
			attack_increase,
			defense_increase,
			speed_increase,
		]


class OptionalRow extends RefCounted:
	var content_id: StringName
	var optional_map_id: StringName
	var available_after_chapter: int
	var maximum_health_increase: int
	var attack_increase: int
	var defense_increase: int
	var speed_increase: int

	func _init(
		row_content_id: StringName,
		row_optional_map_id: StringName,
		row_available_after_chapter: int,
		row_maximum_health_increase: int,
		row_attack_increase: int,
		row_defense_increase: int,
		row_speed_increase: int,
	) -> void:
		content_id = row_content_id
		optional_map_id = row_optional_map_id
		available_after_chapter = row_available_after_chapter
		maximum_health_increase = row_maximum_health_increase
		attack_increase = row_attack_increase
		defense_increase = row_defense_increase
		speed_increase = row_speed_increase

	func delta_values() -> Array[int]:
		return [
			maximum_health_increase,
			attack_increase,
			defense_increase,
			speed_increase,
		]


static func initial_stats() -> PlayerStatsRow:
	return PlayerStatsRow.new(&"progression.player.loer", 100, 10, 5, 10)


static func mainline_rows() -> Array[MainlineRow]:
	return [
		_mainline(1, 10, 1, 0, 0, [110, 11, 5, 10]),
		_mainline(2, 10, 0, 1, 0, [120, 11, 6, 10]),
		_mainline(3, 10, 1, 1, 0, [130, 12, 7, 10]),
		_mainline(4, 10, 1, 1, 1, [140, 13, 8, 11]),
		_mainline(5, 10, 1, 1, 0, [150, 14, 9, 11]),
		_mainline(6, 10, 1, 0, 1, [160, 15, 9, 12]),
		_mainline(7, 10, 0, 1, 1, [170, 15, 10, 13]),
		_mainline(8, 10, 1, 1, 0, [180, 16, 11, 13]),
		_mainline(9, 0, 0, 0, 1, [180, 16, 11, 14]),
	]


static func optional_rows() -> Array[OptionalRow]:
	return [
		_optional(1, 2, 10, 0, 0, 0),
		_optional(2, 4, 0, 1, 0, 0),
		_optional(3, 6, 10, 0, 1, 0),
		_optional(4, 8, 0, 1, 1, 0),
	]


static func full_completion_stats() -> Array[int]:
	return [200, 18, 13, 14]


static func _mainline(
	chapter: int,
	maximum_health_increase: int,
	attack_increase: int,
	defense_increase: int,
	speed_increase: int,
	chapter_end_stats: Array[int],
) -> MainlineRow:
	return MainlineRow.new(
		StringName("progression.main.chapter.%02d" % chapter),
		chapter,
		maximum_health_increase,
		attack_increase,
		defense_increase,
		speed_increase,
		chapter_end_stats,
	)


static func _optional(
	ordinal: int,
	available_after_chapter: int,
	maximum_health_increase: int,
	attack_increase: int,
	defense_increase: int,
	speed_increase: int,
) -> OptionalRow:
	return OptionalRow.new(
		StringName("progression.optional.m%02d" % ordinal),
		StringName("M%02d" % ordinal),
		available_after_chapter,
		maximum_health_increase,
		attack_increase,
		defense_increase,
		speed_increase,
	)
