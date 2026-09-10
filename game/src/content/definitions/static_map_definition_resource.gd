class_name StaticMapDefinitionResource
extends Resource

const MapEnemyPlacementScript := preload("res://src/content/definitions/map_enemy_placement_resource.gd")

const MAXIMUM_MAP_ID_LENGTH: int = 128
const SOURCE_FIELDS: Array[StringName] = [&"terrain_effect_ids", &"dynamic_behavior_ids", &"other_entity_ids"]

@export var map_id: StringName = &""
@export var space_id: StringName = &""
@export var chapter: int = 0
@export var grid_cells: Array[Vector3i] = []
@export var blocked_cells: Array[Vector3i] = []
@export var player_spawn_cell: Vector3i = Vector3i.ZERO
@export var enemies: Array[MapEnemyPlacementScript] = []
# Variant 仅用于原生序列化边界；规则和快照始终使用强类型 ID 数组。
var _terrain_effect_ids: Array[StringName] = []
var _dynamic_behavior_ids: Array[StringName] = []
var _other_entity_ids: Array[StringName] = []
var _declared_source_fields: int = 0
var _invalid_source_fields: int = 0


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for field: StringName in SOURCE_FIELDS:
		properties.append({"name": field, "type": TYPE_NIL, "usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_NIL_IS_VARIANT})
	return properties


func _get(property: StringName) -> Variant:
	var index: int = SOURCE_FIELDS.find(property)
	if index < 0 or ((_declared_source_fields & ~_invalid_source_fields) & (1 << index)) == 0:
		return null
	# ResourceLoader 会按当前 getter 的数组类型提前转换输入。此处必须返回
	# 无类型的序列化副本，让 _set 先检查原始值，避免引擎丢弃非法元素。
	var serialized_ids: Array = []
	match property:
		&"terrain_effect_ids": serialized_ids.assign(_terrain_effect_ids)
		&"dynamic_behavior_ids": serialized_ids.assign(_dynamic_behavior_ids)
		&"other_entity_ids": serialized_ids.assign(_other_entity_ids)
	return serialized_ids


func _set(property: StringName, value: Variant) -> bool:
	var index: int = SOURCE_FIELDS.find(property)
	if index < 0:
		return false
	var bit: int = 1 << index
	if (_declared_source_fields & bit) != 0:
		# 重复声明不能掩盖前一次错误；新定义必须从新的 Resource 加载。
		_invalid_source_fields |= bit
		return true
	_declared_source_fields |= bit
	if not _is_source_id_array(value):
		_invalid_source_fields |= bit
		return true
	match property:
		&"terrain_effect_ids": _terrain_effect_ids.assign(value)
		&"dynamic_behavior_ids": _dynamic_behavior_ids.assign(value)
		&"other_entity_ids": _other_entity_ids.assign(value)
	return true


static func _is_source_id_array(value: Variant) -> bool:
	if not value is Array:
		return false
	var values: Array = value
	if values.is_typed() and values.get_typed_builtin() != TYPE_STRING_NAME:
		return false
	for entry: Variant in values:
		if not entry is StringName:
			return false
	return true


func source_declarations_are_valid() -> bool:
	return _declared_source_fields == (1 << SOURCE_FIELDS.size()) - 1 and _invalid_source_fields == 0


func invalid_source_declaration_fields() -> Array[StringName]:
	var fields: Array[StringName] = []
	for index: int in range(SOURCE_FIELDS.size()):
		if (_declared_source_fields & (1 << index)) == 0 or (_invalid_source_fields & (1 << index)) != 0:
			fields.append(SOURCE_FIELDS[index])
	return fields


func terrain_effect_ids_snapshot() -> Array[StringName]:
	return _terrain_effect_ids.duplicate()


func dynamic_behavior_ids_snapshot() -> Array[StringName]:
	return _dynamic_behavior_ids.duplicate()


func other_entity_ids_snapshot() -> Array[StringName]:
	return _other_entity_ids.duplicate()


static func has_exact_entry_types(source: Resource) -> bool:
	if source == null or source.get_script() != StaticMapDefinitionResource:
		return false
	for placement: MapEnemyPlacementScript in (source as StaticMapDefinitionResource).enemies:
		if placement == null or placement.get_script() != MapEnemyPlacementScript:
			return false
	return true


static func snapshot(source: StaticMapDefinitionResource) -> StaticMapDefinitionResource:
	var result := StaticMapDefinitionResource.new()
	result.map_id = source.map_id
	result.space_id = source.space_id
	result.chapter = source.chapter
	result.grid_cells = source.grid_cells.duplicate()
	result.blocked_cells = source.blocked_cells.duplicate()
	result.grid_cells.sort_custom(cell_less_than)
	result.blocked_cells.sort_custom(cell_less_than)
	result.player_spawn_cell = source.player_spawn_cell
	for placement: MapEnemyPlacementScript in source.enemies:
		result.enemies.append(MapEnemyPlacementScript.snapshot(placement))
	result.enemies.sort_custom(placement_less_than)
	result._terrain_effect_ids = source._terrain_effect_ids.duplicate()
	result._dynamic_behavior_ids = source._dynamic_behavior_ids.duplicate()
	result._other_entity_ids = source._other_entity_ids.duplicate()
	result._terrain_effect_ids.sort()
	result._dynamic_behavior_ids.sort()
	result._other_entity_ids.sort()
	result._declared_source_fields = source._declared_source_fields
	result._invalid_source_fields = source._invalid_source_fields
	return result


static func cell_less_than(left: Vector3i, right: Vector3i) -> bool:
	if left.x != right.x:
		return left.x < right.x
	if left.y != right.y:
		return left.y < right.y
	return left.z < right.z


static func placement_less_than(left: MapEnemyPlacementScript, right: MapEnemyPlacementScript) -> bool:
	return String(left.instance_id) < String(right.instance_id)
