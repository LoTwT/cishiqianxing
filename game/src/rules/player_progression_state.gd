class_name PlayerProgressionState
extends RefCounted

const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const MAX_CLAIMED_REWARD_COUNT: int = 30

var _profile_id: StringName = &""
var _content_schema_version: int = 0
var _content_version: int = 0
var _current_health: int = 0
var _claimed_reward_ids: Array[StringName] = []
var _initialized: bool = false


func _init() -> void:
	_claimed_reward_ids.make_read_only()


static func create(
	profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	current_health: int,
	claimed_reward_ids: Array[StringName],
) -> PlayerProgressionState:
	var state := new()
	state._profile_id = profile_id
	state._content_schema_version = content_schema_version
	state._content_version = content_version
	state._current_health = current_health
	state._claimed_reward_ids = _copy_and_sort_ids(claimed_reward_ids)
	state._initialized = true
	state._claimed_reward_ids.make_read_only()
	return state


func copy() -> PlayerProgressionState:
	var copied_state := new()
	copied_state._profile_id = _profile_id
	copied_state._content_schema_version = _content_schema_version
	copied_state._content_version = _content_version
	copied_state._current_health = _current_health
	copied_state._claimed_reward_ids = _copy_ids(
		_claimed_reward_ids,
		MAX_CLAIMED_REWARD_COUNT + 1,
	)
	copied_state._initialized = _initialized
	copied_state._claimed_reward_ids.make_read_only()
	return copied_state


func is_valid() -> bool:
	return validation_errors().is_empty()


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not _initialized:
		errors.append("PlayerProgressionState must be initialized through create().")
	if String(_profile_id).is_empty():
		errors.append("Player progression profile ID cannot be empty.")
	if _content_schema_version <= 0:
		errors.append("Player progression content schema version must be positive.")
	if _content_version <= 0:
		errors.append("Player progression content version must be positive.")
	if _current_health < 0:
		errors.append("Player progression current health cannot be negative.")
	if _claimed_reward_ids.size() > MAX_CLAIMED_REWARD_COUNT:
		errors.append(
			"Player progression cannot claim more than %d permanent rewards."
			% MAX_CLAIMED_REWARD_COUNT
		)
		return errors
	if not _ids_use_canonical_order(_claimed_reward_ids):
		errors.append("Claimed permanent reward IDs must use canonical order.")
	var seen_ids: Dictionary[StringName, bool] = {}
	for reward_id: StringName in _claimed_reward_ids:
		if String(reward_id).is_empty():
			errors.append("Claimed permanent reward IDs cannot be empty.")
		if seen_ids.has(reward_id):
			errors.append("Claimed permanent reward IDs must be unique.")
		else:
			seen_ids[reward_id] = true
	return errors


func profile_id() -> StringName:
	return _profile_id


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func current_health() -> int:
	return _current_health


func claimed_reward_ids() -> Array[StringName]:
	return _copy_ids(_claimed_reward_ids)


func has_claimed_reward(reward_id: StringName) -> bool:
	return _claimed_reward_ids.has(reward_id)


func is_equal_to(other: PlayerProgressionState) -> bool:
	return (
		other != null
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other.profile_id() == _profile_id
		and other.content_schema_version() == _content_schema_version
		and other.content_version() == _content_version
		and other.current_health() == _current_health
		and other.claimed_reward_ids() == _claimed_reward_ids
	)


static func _copy_and_sort_ids(ids: Array[StringName]) -> Array[StringName]:
	var copied_ids: Array[StringName] = _copy_ids(ids, MAX_CLAIMED_REWARD_COUNT + 1)
	copied_ids.sort_custom(ValidationSupportScript.id_less_than)
	return copied_ids


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


static func _ids_use_canonical_order(ids: Array[StringName]) -> bool:
	for index: int in range(1, ids.size()):
		if ValidationSupportScript.id_less_than(ids[index], ids[index - 1]):
			return false
	return true
