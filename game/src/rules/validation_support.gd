class_name ValidationSupport
extends RefCounted

# 规则层共享的确定性校验原语：整数上界、标识符校验、规范排序、溢出谓词，
# 以及值对象镜像字段（_integrity_*）的声明式捕获/比对/复制 walker。
# 本模块零依赖（不 preload 任何业务类型），可被所有规则内核与内容校验器引用。

const MAX_INT: int = 9_223_372_036_854_775_807
const MAX_WORLD_STEP: int = MAX_INT
const VECTOR3I_COMPONENT_MIN: int = -2_147_483_648
const VECTOR3I_COMPONENT_MAX: int = 2_147_483_647


static func would_add_overflow(left: int, right: int) -> bool:
	return right > 0 and left > MAX_INT - right


static func id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


static func ids_are_canonical_and_unique(ids: Array[StringName]) -> bool:
	var seen_ids: Dictionary[StringName, bool] = {}
	for index: int in range(ids.size()):
		var content_id: StringName = ids[index]
		if String(content_id).is_empty() or seen_ids.has(content_id):
			return false
		seen_ids[content_id] = true
		if index > 0 and String(content_id) < String(ids[index - 1]):
			return false
	return true


# 标识符必须非空、长度受限，至少含一个字母数字字符，其余字符只能是
# 连字符（45）、句点（46）、冒号（58）与下划线（95）。
static func is_valid_identifier(identifier: StringName, maximum_length: int) -> bool:
	var value: String = String(identifier)
	if value.is_empty() or value.length() > maximum_length:
		return false
	var has_alphanumeric: bool = false
	for index: int in range(value.length()):
		var codepoint: int = value.unicode_at(index)
		var is_alphanumeric: bool = (
			(codepoint >= 48 and codepoint <= 57)
			or (codepoint >= 65 and codepoint <= 90)
			or (codepoint >= 97 and codepoint <= 122)
		)
		if is_alphanumeric:
			has_alphanumeric = true
			continue
		if codepoint not in [45, 46, 58, 95]:
			return false
	return has_alphanumeric


static func is_horizontal_unit_direction(direction: Vector3i) -> bool:
	return direction.y == 0 and absi(direction.x) + absi(direction.z) == 1


static func would_overflow_target(from_cell: Vector3i, direction: Vector3i) -> bool:
	return (
		(direction.x > 0 and from_cell.x == VECTOR3I_COMPONENT_MAX)
		or (direction.x < 0 and from_cell.x == VECTOR3I_COMPONENT_MIN)
		or (direction.z > 0 and from_cell.z == VECTOR3I_COMPONENT_MAX)
		or (direction.z < 0 and from_cell.z == VECTOR3I_COMPONENT_MIN)
	)


# 镜像字段 walker：以「基础字段名」列表（如 [&"space_id"]）为单一声明点，
# 驱动值对象的 _<name> 与 _integrity_<name> 镜像对的捕获、比对与复制。
# 比对使用 Variant ==，与既有手写镜像比对语义一致。


# 把 field_names 对应的 _<name> 当前值写入 _integrity_<name>（捕获镜像）。
static func capture_field_integrity(
	object: Object,
	field_names: Array[StringName],
) -> void:
	for field_name: StringName in field_names:
		object.set(
			StringName("_integrity_" + String(field_name)),
			object.get(StringName("_" + String(field_name))),
		)


# 逐字段比较 _<name> 与 _integrity_<name>，任一字段不等即返回 false。
static func field_integrity_matches(
	object: Object,
	field_names: Array[StringName],
) -> bool:
	for field_name: StringName in field_names:
		if object.get(StringName("_" + String(field_name))) != object.get(
			StringName("_integrity_" + String(field_name))
		):
			return false
	return true


# 把 source 的 _integrity_<name> 复制到 destination 的同名镜像（供 copy() 用）。
static func copy_field_integrity(
	source: Object,
	destination: Object,
	field_names: Array[StringName],
) -> void:
	for field_name: StringName in field_names:
		destination.set(
			StringName("_integrity_" + String(field_name)),
			source.get(StringName("_integrity_" + String(field_name))),
		)
