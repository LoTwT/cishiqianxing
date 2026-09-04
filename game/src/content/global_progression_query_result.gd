class_name GlobalProgressionQueryResult
extends RefCounted

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
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

enum Kind {
	PLAYER_STATS = 1,
	MAINLINE_PROGRESSION = 2,
	OPTIONAL_PROGRESSION = 3,
	PERMANENT_GROWTH_REWARD = 4,
}

var _kind: int
var _player_stats: PlayerStatProfileScript
var _mainline_progression: MainlineProgressionDefinitionScript
var _optional_progression: OptionalProgressionDefinitionScript
var _permanent_growth_reward: PermanentGrowthRewardDefinitionScript
var _issue: ContentValidationIssueScript


func _init(
	kind: int,
	player_stats: PlayerStatProfileScript,
	mainline_progression: MainlineProgressionDefinitionScript,
	optional_progression: OptionalProgressionDefinitionScript,
	permanent_growth_reward: PermanentGrowthRewardDefinitionScript,
	issue: ContentValidationIssueScript,
) -> void:
	# 审计 INCR-10：字段私有且读取边界统一做单次快照；传入资源由封印注册表
	# 保证不可变（注册表封印时已快照至私有只读存储；章节/全通属性为注册表
	# 每次查询新建的局部快照），构造时直接持有引用，不再做构造期防御拷贝，
	# 避免与读取边界构成双重快照。
	_kind = kind
	_player_stats = player_stats
	_mainline_progression = mainline_progression
	_optional_progression = optional_progression
	_permanent_growth_reward = permanent_growth_reward
	_issue = issue


static func found_player_stats(
	profile: PlayerStatProfileScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(
		Kind.PLAYER_STATS,
		profile,
		null,
		null,
		null,
		null,
	)


static func found_mainline_progression(
	definition: MainlineProgressionDefinitionScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(
		Kind.MAINLINE_PROGRESSION,
		null,
		definition,
		null,
		null,
		null,
	)


static func found_optional_progression(
	definition: OptionalProgressionDefinitionScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(
		Kind.OPTIONAL_PROGRESSION,
		null,
		null,
		definition,
		null,
		null,
	)


static func found_permanent_growth_reward(
	definition: PermanentGrowthRewardDefinitionScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(
		Kind.PERMANENT_GROWTH_REWARD,
		null,
		null,
		null,
		definition,
		null,
	)


static func failed(
	kind: int,
	issue: ContentValidationIssueScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(kind, null, null, null, null, issue)


func succeeded() -> bool:
	return _issue == null


func kind() -> int:
	return _kind


func player_stats() -> PlayerStatProfileScript:
	if _player_stats == null:
		return null
	return PlayerStatProfileScript.snapshot(_player_stats)


func mainline_progression() -> MainlineProgressionDefinitionScript:
	if _mainline_progression == null:
		return null
	return MainlineProgressionDefinitionScript.snapshot(_mainline_progression)


func optional_progression() -> OptionalProgressionDefinitionScript:
	if _optional_progression == null:
		return null
	return OptionalProgressionDefinitionScript.snapshot(_optional_progression)


func permanent_growth_reward() -> PermanentGrowthRewardDefinitionScript:
	if _permanent_growth_reward == null:
		return null
	return PermanentGrowthRewardDefinitionScript.snapshot(_permanent_growth_reward)


func issue() -> ContentValidationIssueScript:
	if _issue == null:
		return null
	return _issue.snapshot()
