class_name ContentLookupResult
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

enum Kind {
	BLUEPRINT = 1,
	RECIPE = 2,
}

var _kind: int
var _blueprint: BlueprintDefinitionScript
var _recipe: RecipeDefinitionScript
var _issue: ContentValidationIssueScript


func _init(
	kind: int,
	blueprint: BlueprintDefinitionScript,
	recipe: RecipeDefinitionScript,
	issue: ContentValidationIssueScript,
) -> void:
	# 审计 INCR-10：字段私有且读取边界统一做单次快照；传入资源由封印注册表
	# 保证不可变（注册表封印时已快照至私有只读存储），构造时直接持有引用，
	# 不再做构造期防御拷贝，避免与读取边界构成双重快照。
	_kind = kind
	_blueprint = blueprint
	_recipe = recipe
	_issue = issue


static func found_blueprint(
	definition: BlueprintDefinitionScript,
) -> ContentLookupResult:
	return ContentLookupResult.new(Kind.BLUEPRINT, definition, null, null)


static func found_recipe(definition: RecipeDefinitionScript) -> ContentLookupResult:
	return ContentLookupResult.new(Kind.RECIPE, null, definition, null)


static func failed(kind: int, issue: ContentValidationIssueScript) -> ContentLookupResult:
	return ContentLookupResult.new(kind, null, null, issue)


func succeeded() -> bool:
	return _issue == null


func kind() -> int:
	return _kind


func blueprint() -> BlueprintDefinitionScript:
	if _blueprint == null:
		return null
	return BlueprintDefinitionScript.snapshot(_blueprint)


func recipe() -> RecipeDefinitionScript:
	if _recipe == null:
		return null
	return RecipeDefinitionScript.snapshot(_recipe)


func issue() -> ContentValidationIssueScript:
	if _issue == null:
		return null
	return _issue.snapshot()
