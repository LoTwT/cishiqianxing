class_name EnemyProfileQueryResult
extends RefCounted

const EnemyFamilyDefinitionScript := preload(
	"res://src/content/definitions/enemy_family_definition_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

enum Kind {
	FAMILY = 1,
	PROFILE = 2,
}

var _kind: int
var _family: EnemyFamilyDefinitionScript
var _profile: EnemyProfileDefinitionScript
var _issue: ContentValidationIssueScript


func _init(
	kind: int,
	family: EnemyFamilyDefinitionScript,
	profile: EnemyProfileDefinitionScript,
	issue: ContentValidationIssueScript,
) -> void:
	_kind = kind
	if family != null:
		_family = EnemyFamilyDefinitionScript.snapshot(family)
	if profile != null:
		_profile = EnemyProfileDefinitionScript.snapshot(profile)
	if issue != null:
		_issue = issue.snapshot()


static func found_family(
	family: EnemyFamilyDefinitionScript,
) -> EnemyProfileQueryResult:
	return EnemyProfileQueryResult.new(Kind.FAMILY, family, null, null)


static func found_profile(
	profile: EnemyProfileDefinitionScript,
) -> EnemyProfileQueryResult:
	return EnemyProfileQueryResult.new(Kind.PROFILE, null, profile, null)


static func failed(
	kind: int,
	issue: ContentValidationIssueScript,
) -> EnemyProfileQueryResult:
	return EnemyProfileQueryResult.new(kind, null, null, issue)


func succeeded() -> bool:
	return _issue == null


func kind() -> int:
	return _kind


func family() -> EnemyFamilyDefinitionScript:
	if _family == null:
		return null
	return EnemyFamilyDefinitionScript.snapshot(_family)


func profile() -> EnemyProfileDefinitionScript:
	if _profile == null:
		return null
	return EnemyProfileDefinitionScript.snapshot(_profile)


func issue() -> ContentValidationIssueScript:
	if _issue == null:
		return null
	return _issue.snapshot()
