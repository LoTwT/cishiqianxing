class_name ContentValidationReport
extends RefCounted

const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

var _issues: Array[ContentValidationIssueScript] = []


func _init(issues: Array[ContentValidationIssueScript]) -> void:
	for issue: ContentValidationIssueScript in issues:
		_issues.append(issue.snapshot())
	_issues.make_read_only()


func is_valid() -> bool:
	return _issues.is_empty()


func issue_count() -> int:
	return _issues.size()


func issues() -> Array[ContentValidationIssueScript]:
	var copied_issues: Array[ContentValidationIssueScript] = []
	for issue: ContentValidationIssueScript in _issues:
		copied_issues.append(issue.snapshot())
	return copied_issues


func signatures() -> Array[String]:
	var result: Array[String] = []
	for issue: ContentValidationIssueScript in _issues:
		result.append(
			"%s%s%s%s"
			% [
				_encode_string(String(issue.code())),
				_encode_string(String(issue.content_id())),
				_encode_string(issue.field_path()),
				_encode_string(issue.message()),
			]
		)
	return result


static func _encode_string(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]
