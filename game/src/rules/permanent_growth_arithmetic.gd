class_name PermanentGrowthArithmetic
extends RefCounted

# 「应用永久成长奖励到玩家属性」的唯一权威算术。此前注册表（按章节/满完成推导
# 终值）、全局进度校验器（终值 oracle）与永久成长领取内核（运行期领取）各持
# 一份 stat_kind 分派实现。三个入口对应三种调用形态：
# - apply_reward_to_player_stats：注册表的 PlayerStatProfile 载体。无溢出守卫
#   （内容在构建期经指纹与计数校验，增量有界）。
# - apply_reward_to_stat_values：校验器的 Array[int] 载体，保持其既有的
#   stat_kind 序数索引语义（由调用方保证 stat_kind 先经 _is_valid_stat_kind）。
# - add_reward_increase_with_overflow_guard：领取内核的失败关闭形态，溢出或
#   （与旧实现一致地）未匹配的 stat_kind 不做任何加法。
# stat_values 的顺序固定为 [maximum_health, attack, defense, speed]，与
# StatKind 的 1..4 一一对应。

const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")


static func apply_reward_to_player_stats(
	stats: PlayerStatProfileScript,
	reward: PermanentGrowthRewardDefinitionScript,
) -> void:
	match reward.stat_kind:
		PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH:
			stats.maximum_health += reward.increase
		PermanentGrowthRewardDefinitionScript.StatKind.ATTACK:
			stats.attack += reward.increase
		PermanentGrowthRewardDefinitionScript.StatKind.DEFENSE:
			stats.defense += reward.increase
		PermanentGrowthRewardDefinitionScript.StatKind.SPEED:
			stats.speed += reward.increase


static func apply_reward_to_stat_values(
	values: Array[int],
	reward: PermanentGrowthRewardDefinitionScript,
) -> void:
	values[reward.stat_kind - 1] += reward.increase


static func add_reward_increase_with_overflow_guard(
	stat_values: Array[int],
	stat_kind: int,
	increase: int,
) -> bool:
	match stat_kind:
		PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH:
			if ValidationSupportScript.would_add_overflow(stat_values[0], increase):
				return false
			stat_values[0] += increase
		PermanentGrowthRewardDefinitionScript.StatKind.ATTACK:
			if ValidationSupportScript.would_add_overflow(stat_values[1], increase):
				return false
			stat_values[1] += increase
		PermanentGrowthRewardDefinitionScript.StatKind.DEFENSE:
			if ValidationSupportScript.would_add_overflow(stat_values[2], increase):
				return false
			stat_values[2] += increase
		PermanentGrowthRewardDefinitionScript.StatKind.SPEED:
			if ValidationSupportScript.would_add_overflow(stat_values[3], increase):
				return false
			stat_values[3] += increase
	return true
