extends RefCounted

# 独立字面量期望；技术验收几何不代表正式章节地图冻结。
const MAP_ID: StringName = &"map.technical.static_initialization"
const SPACE_ID: StringName = &"space.technical.static_initialization"
const CATALOG_ID: StringName = &"map.catalog.static"
const CHAPTER: int = 6
const PLAYER_ID: StringName = &"actor.loer"
const INSTANCE_IDS: Array[StringName] = [&"enemy.instance.static.first", &"enemy.instance.static.second"]
const PROFILE_IDS: Array[StringName] = [&"enemy.profile.f03.enhanced", &"enemy.profile.f09.enhanced"]
const ENEMY_CELLS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
const DURABILITIES: Array[int] = [24, 30]
const GRID_CELLS: Array[Vector3i] = [Vector3i(-1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)]
const BLOCKED_CELLS: Array[Vector3i] = [Vector3i(0, 0, -1)]
const PLAYER_SPAWN: Vector3i = Vector3i.ZERO


static func mainline_rewards() -> Array[StringName]:
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
	]
