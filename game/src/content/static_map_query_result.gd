class_name StaticMapQueryResult
extends RefCounted

const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")
const ContentValidationIssueScript := preload("res://src/content/content_validation_issue.gd")

var _definition: StaticMapDefinitionScript
var _issue: ContentValidationIssueScript


func _init(definition: StaticMapDefinitionScript, issue: ContentValidationIssueScript) -> void:
	_definition = StaticMapDefinitionScript.snapshot(definition) if StaticMapDefinitionScript.has_exact_entry_types(definition) else null
	_issue = issue.snapshot() if issue != null else null


func succeeded() -> bool:
	return _definition != null and _issue == null


func definition() -> StaticMapDefinitionScript:
	return StaticMapDefinitionScript.snapshot(_definition) if succeeded() else null


func issue() -> ContentValidationIssueScript:
	return _issue.snapshot() if _issue != null else null
