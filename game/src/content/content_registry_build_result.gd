class_name ContentRegistryBuildResult
extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentValidationReportScript := preload(
	"res://src/content/content_validation_report.gd"
)

var _registry: ContentRegistryScript
var _report: ContentValidationReportScript


func _init(
	registry: ContentRegistryScript,
	report: ContentValidationReportScript,
) -> void:
	_registry = registry
	_report = ContentValidationReportScript.new(report.issues())


static func success(
	registry: ContentRegistryScript,
	report: ContentValidationReportScript,
) -> ContentRegistryBuildResult:
	return ContentRegistryBuildResult.new(registry, report)


static func failure(report: ContentValidationReportScript) -> ContentRegistryBuildResult:
	return ContentRegistryBuildResult.new(null, report)


func succeeded() -> bool:
	return _registry != null and _registry.is_initialized() and _report.is_valid()


func registry() -> ContentRegistryScript:
	return _registry if succeeded() else null


func validation_report() -> ContentValidationReportScript:
	return ContentValidationReportScript.new(_report.issues())
