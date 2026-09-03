class_name EnemyInstanceState
extends RefCounted

const MAXIMUM_INSTANCE_ID_LENGTH: int = 128

enum StateKind {
	PRIMARY = 1,
	ALTERNATE = 2,
}

var _instance_id: StringName = &""
var _profile_id: StringName = &""
var _content_schema_version: int = 0
var _content_version: int = 0
var _current_durability: int = 0
var _state_kind: int = 0
var _shield_intact: bool = false
var _initialized: bool = false


static func create(
	instance_id: StringName,
	profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	current_durability: int,
	state_kind: int,
	shield_intact: bool,
) -> EnemyInstanceState:
	var state := new()
	state._instance_id = instance_id
	state._profile_id = profile_id
	state._content_schema_version = content_schema_version
	state._content_version = content_version
	state._current_durability = current_durability
	state._state_kind = state_kind
	state._shield_intact = shield_intact
	state._initialized = true
	return state


func copy() -> EnemyInstanceState:
	var copied_state := new()
	copied_state._instance_id = _instance_id
	copied_state._profile_id = _profile_id
	copied_state._content_schema_version = _content_schema_version
	copied_state._content_version = _content_version
	copied_state._current_durability = _current_durability
	copied_state._state_kind = _state_kind
	copied_state._shield_intact = _shield_intact
	copied_state._initialized = _initialized
	return copied_state


func is_valid() -> bool:
	return (
		_initialized
		and is_valid_instance_id(_instance_id)
		and not String(_profile_id).is_empty()
		and _content_schema_version > 0
		and _content_version > 0
		and _current_durability >= 0
		and (
			_state_kind == StateKind.PRIMARY
			or _state_kind == StateKind.ALTERNATE
		)
	)


static func is_valid_instance_id(instance_id: StringName) -> bool:
	var value: String = String(instance_id)
	if value.is_empty() or value.length() > MAXIMUM_INSTANCE_ID_LENGTH:
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


func is_initialized() -> bool:
	return _initialized


func instance_id() -> StringName:
	return _instance_id


func profile_id() -> StringName:
	return _profile_id


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func current_durability() -> int:
	return _current_durability


func state_kind() -> int:
	return _state_kind


func shield_intact() -> bool:
	return _shield_intact


func is_equal_to(other: EnemyInstanceState) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other._initialized == _initialized
		and other.instance_id() == _instance_id
		and other.profile_id() == _profile_id
		and other.content_schema_version() == _content_schema_version
		and other.content_version() == _content_version
		and other.current_durability() == _current_durability
		and other.state_kind() == _state_kind
		and other.shield_intact() == _shield_intact
	)
