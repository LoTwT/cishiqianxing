class_name WorldStepStageInputs
extends RefCounted

# 完整清单是调用方对当前空间的封闭输入合同；缺省构造不代表没有效果。

var _construct_sources: Array[StringName] = []
var _integrity_construct_sources: Array[StringName] = []
var _environment_sources: Array[StringName] = []
var _integrity_environment_sources: Array[StringName] = []
var _patrol_sources: Array[StringName] = []
var _integrity_patrol_sources: Array[StringName] = []
var _periodic_sources: Array[StringName] = []
var _integrity_periodic_sources: Array[StringName] = []
var _support_sources: Array[StringName] = []
var _integrity_support_sources: Array[StringName] = []
var _complete: bool = false
var _integrity_complete: bool = false
var _initialized: bool = false
var _integrity_initialized: bool = false


static func create(
	construct_sources_value: Array[StringName],
	environment_sources_value: Array[StringName],
	patrol_sources_value: Array[StringName],
	periodic_sources_value: Array[StringName],
	support_sources_value: Array[StringName],
	complete_value: bool,
) -> WorldStepStageInputs:
	var result := new()
	result._construct_sources = construct_sources_value.duplicate()
	result._environment_sources = environment_sources_value.duplicate()
	result._patrol_sources = patrol_sources_value.duplicate()
	result._periodic_sources = periodic_sources_value.duplicate()
	result._support_sources = support_sources_value.duplicate()
	result._complete = complete_value
	result._initialized = true
	result._capture_integrity()
	return result


func copy() -> WorldStepStageInputs:
	var result := new()
	if not is_valid():
		return result
	result._construct_sources = _construct_sources.duplicate()
	result._environment_sources = _environment_sources.duplicate()
	result._patrol_sources = _patrol_sources.duplicate()
	result._periodic_sources = _periodic_sources.duplicate()
	result._support_sources = _support_sources.duplicate()
	result._complete = _complete
	result._initialized = true
	result._capture_integrity()
	return result


func is_valid() -> bool:
	return (
		_initialized and _integrity_initialized
		and _construct_sources == _integrity_construct_sources
		and _environment_sources == _integrity_environment_sources
		and _patrol_sources == _integrity_patrol_sources
		and _periodic_sources == _integrity_periodic_sources
		and _support_sources == _integrity_support_sources
		and _complete == _integrity_complete
	)


func construct_sources() -> Array[StringName]:
	return _construct_sources.duplicate()


func environment_sources() -> Array[StringName]:
	return _environment_sources.duplicate()


func patrol_sources() -> Array[StringName]:
	return _patrol_sources.duplicate()


func periodic_sources() -> Array[StringName]:
	return _periodic_sources.duplicate()


func support_sources() -> Array[StringName]:
	return _support_sources.duplicate()


func complete() -> bool:
	return _complete


func is_equal_to(other: WorldStepStageInputs) -> bool:
	return (
		other != null and other.get_script() == get_script()
		and is_valid() and other.is_valid()
		and _construct_sources == other._construct_sources
		and _environment_sources == other._environment_sources
		and _patrol_sources == other._patrol_sources
		and _periodic_sources == other._periodic_sources
		and _support_sources == other._support_sources
		and _complete == other._complete
	)


func _capture_integrity() -> void:
	_integrity_construct_sources = _construct_sources.duplicate()
	_construct_sources.make_read_only()
	_integrity_construct_sources.make_read_only()
	_integrity_environment_sources = _environment_sources.duplicate()
	_environment_sources.make_read_only()
	_integrity_environment_sources.make_read_only()
	_integrity_patrol_sources = _patrol_sources.duplicate()
	_patrol_sources.make_read_only()
	_integrity_patrol_sources.make_read_only()
	_integrity_periodic_sources = _periodic_sources.duplicate()
	_periodic_sources.make_read_only()
	_integrity_periodic_sources.make_read_only()
	_integrity_support_sources = _support_sources.duplicate()
	_support_sources.make_read_only()
	_integrity_support_sources.make_read_only()
	_integrity_complete = _complete
	_integrity_initialized = _initialized
