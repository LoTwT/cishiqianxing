class_name ContentValidationSupport
extends RefCounted

# 内容层共享的校验原语：StringName 规范排序、issue 构造、计数累加、重复项检测，
# 以及内容指纹合同使用的无歧义字符串编码。
# 本模块只依赖 ContentValidationIssue 值类型，供注册表构建器与各内容校验器引用。

const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)


static func string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


# 内容指纹合同的字符串编码（长度前缀 + 原文）。实现体必须与
# content_contract_fingerprint / content_validation_report 原先的本地副本逐字节等价，
# 否则内容指纹值会发生变化。
static func encode_string(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]


static func add_issue(
	issues: Array[ContentValidationIssueScript],
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> void:
	issues.append(
		ContentValidationIssueScript.new(code, content_id, field_path, message)
	)


static func increment_string_name_count(
	counts: Dictionary[StringName, int],
	value: StringName,
) -> void:
	counts[value] = counts.get(value, 0) + 1


static func increment_int_count(counts: Dictionary[int, int], value: int) -> void:
	counts[value] = counts.get(value, 0) + 1


# 整数转 StringName 形式的 issue content_id（如章节号 6 → &"6"）。
static func string_name_from_int(value: int) -> StringName:
	return StringName(str(value))


# 重复 StringName 检测。空 ID 不参与重复报告（空 ID 由各校验器自己的 EMPTY
# 规则单独报告），重复项按规范排序输出 "<label> '<id>' occurs <n> times."。
static func add_duplicate_string_name_issues(
	counts: Dictionary[StringName, int],
	code: StringName,
	field_path: String,
	label: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var sorted_ids: Array[StringName] = []
	for value: StringName in counts:
		if not value.is_empty() and counts[value] > 1:
			sorted_ids.append(value)
	sorted_ids.sort_custom(string_name_less_than)
	for value: StringName in sorted_ids:
		add_issue(
			issues,
			code,
			value,
			field_path,
			"%s '%s' occurs %d times." % [label, String(value), counts[value]],
		)


# 重复整数检测。issue 的 content_id 由调用方通过 formatter 提供：
# 构建器传蓝图序号的领域格式（_expected_blueprint_id），
# 其余校验器传 string_name_from_int（数值字符串形式）。
static func add_duplicate_int_issues(
	counts: Dictionary[int, int],
	code: StringName,
	field_path: String,
	label: String,
	content_id_formatter: Callable,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var sorted_values: Array[int] = []
	for value: int in counts:
		if counts[value] > 1:
			sorted_values.append(value)
	sorted_values.sort()
	for value: int in sorted_values:
		add_issue(
			issues,
			code,
			content_id_formatter.call(value),
			field_path,
			"%s %d occurs %d times." % [label, value, counts[value]],
		)
