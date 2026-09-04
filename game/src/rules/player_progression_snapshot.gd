class_name PlayerProgressionSnapshot
extends RefCounted

const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const MAX_CLAIMED_REWARD_COUNT: int = 30

var _profile_id: StringName = &""
var _content_schema_version: int = 0
var _content_version: int = 0
var _current_health: int = 0
var _maximum_health: int = 0
var _attack: int = 0
var _defense: int = 0
var _speed: int = 0
var _claimed_reward_ids: Array[StringName] = []
var _initialized: bool = false


func _init() -> void:
	_claimed_reward_ids.make_read_only()


static func create(
	profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	current_health: int,
	maximum_health: int,
	attack: int,
	defense: int,
	speed: int,
	claimed_reward_ids: Array[StringName],
) -> PlayerProgressionSnapshot:
	var snapshot := new()
	snapshot._profile_id = profile_id
	snapshot._content_schema_version = content_schema_version
	snapshot._content_version = content_version
	snapshot._current_health = current_health
	snapshot._maximum_health = maximum_health
	snapshot._attack = attack
	snapshot._defense = defense
	snapshot._speed = speed
	snapshot._claimed_reward_ids = _copy_ids(
		claimed_reward_ids,
		MAX_CLAIMED_REWARD_COUNT + 1,
	)
	snapshot._initialized = true
	snapshot._claimed_reward_ids.make_read_only()
	return snapshot


func copy() -> PlayerProgressionSnapshot:
	var copied_snapshot := new()
	copied_snapshot._profile_id = _profile_id
	copied_snapshot._content_schema_version = _content_schema_version
	copied_snapshot._content_version = _content_version
	copied_snapshot._current_health = _current_health
	copied_snapshot._maximum_health = _maximum_health
	copied_snapshot._attack = _attack
	copied_snapshot._defense = _defense
	copied_snapshot._speed = _speed
	copied_snapshot._claimed_reward_ids = _copy_ids(
		_claimed_reward_ids,
		MAX_CLAIMED_REWARD_COUNT + 1,
	)
	copied_snapshot._initialized = _initialized
	copied_snapshot._claimed_reward_ids.make_read_only()
	return copied_snapshot


func is_valid() -> bool:
	return (
		_initialized
		and not String(_profile_id).is_empty()
		and _content_schema_version > 0
		and _content_version > 0
		and _current_health >= 0
		and _maximum_health > 0
		and _current_health <= _maximum_health
		and _attack > 0
		and _defense > 0
		and _speed > 0
		and _claimed_reward_ids.size() <= MAX_CLAIMED_REWARD_COUNT
		and ValidationSupportScript.ids_are_canonical_and_unique(_claimed_reward_ids)
	)


func profile_id() -> StringName:
	return _profile_id


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func current_health() -> int:
	return _current_health


func maximum_health() -> int:
	return _maximum_health


func attack() -> int:
	return _attack


func defense() -> int:
	return _defense


func speed() -> int:
	return _speed


func claimed_reward_ids() -> Array[StringName]:
	return _copy_ids(_claimed_reward_ids)


func is_equal_to(other: PlayerProgressionSnapshot) -> bool:
	return (
		other != null
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other.profile_id() == _profile_id
		and other.content_schema_version() == _content_schema_version
		and other.content_version() == _content_version
		and other.current_health() == _current_health
		and other.maximum_health() == _maximum_health
		and other.attack() == _attack
		and other.defense() == _defense
		and other.speed() == _speed
		and other.claimed_reward_ids() == _claimed_reward_ids
	)


static func _copy_ids(
	ids: Array[StringName],
	maximum_count: int = MAX_CLAIMED_REWARD_COUNT + 1,
) -> Array[StringName]:
	var copied_ids: Array[StringName] = []
	for content_id: StringName in ids:
		copied_ids.append(content_id)
		if copied_ids.size() >= maximum_count:
			break
	return copied_ids
