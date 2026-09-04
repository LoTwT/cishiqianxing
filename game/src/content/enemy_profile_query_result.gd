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
	# 审计 INCR-10：字段私有且读取边界统一做单次快照；传入资源由封印注册表
	# 保证不可变（注册表封印时已快照至私有只读存储），构造时直接持有引用，
	# 不再做构造期防御拷贝，避免与读取边界构成双重快照。
	_kind = kind
	_family = family
	_profile = profile
	_issue = issue


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
