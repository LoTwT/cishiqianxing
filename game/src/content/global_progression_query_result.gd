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
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

enum Kind {
	PLAYER_STATS = 1,
	MAINLINE_PROGRESSION = 2,
	OPTIONAL_PROGRESSION = 3,
}

var _kind: int
var _player_stats: PlayerStatProfileScript
var _mainline_progression: MainlineProgressionDefinitionScript
var _optional_progression: OptionalProgressionDefinitionScript
var _issue: ContentValidationIssueScript


func _init(
	kind: int,
	player_stats: PlayerStatProfileScript,
	mainline_progression: MainlineProgressionDefinitionScript,
	optional_progression: OptionalProgressionDefinitionScript,
	issue: ContentValidationIssueScript,
) -> void:
	_kind = kind
	if player_stats != null:
		_player_stats = PlayerStatProfileScript.snapshot(player_stats)
	if mainline_progression != null:
		_mainline_progression = MainlineProgressionDefinitionScript.snapshot(
			mainline_progression
		)
	if optional_progression != null:
		_optional_progression = OptionalProgressionDefinitionScript.snapshot(
			optional_progression
		)
	if issue != null:
		_issue = issue.snapshot()


static func found_player_stats(
	profile: PlayerStatProfileScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(
		Kind.PLAYER_STATS,
		profile,
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
	)


static func failed(
	kind: int,
	issue: ContentValidationIssueScript,
) -> GlobalProgressionQueryResult:
	return GlobalProgressionQueryResult.new(kind, null, null, null, issue)


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


func issue() -> ContentValidationIssueScript:
	if _issue == null:
		return null
	return _issue.snapshot()
