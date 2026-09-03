class_name ContactCombatPlayerStateCandidate
extends RefCounted

const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)

var _profile_id: StringName = &""
var _content_schema_version: int = 0
var _content_version: int = 0
var _current_health: int = 0
var _claimed_reward_ids: Array[StringName] = []
var _initialized: bool = false


func _init() -> void:
	_claimed_reward_ids.make_read_only()


static func from_progression_state(
	state: RefCounted,
) -> ContactCombatPlayerStateCandidate:
	var candidate := new()
	if (
		state == null
		or not is_instance_valid(state)
		or state.get_script() != PlayerProgressionStateScript
		or not (state as PlayerProgressionStateScript).is_valid()
	):
		return candidate
	var authoritative_state: PlayerProgressionStateScript = (
		state as PlayerProgressionStateScript
	)
	candidate._profile_id = authoritative_state.profile_id()
	candidate._content_schema_version = (
		authoritative_state.content_schema_version()
	)
	candidate._content_version = authoritative_state.content_version()
	candidate._current_health = authoritative_state.current_health()
	candidate._claimed_reward_ids = authoritative_state.claimed_reward_ids()
	candidate._claimed_reward_ids.make_read_only()
	candidate._initialized = true
	return candidate


func copy() -> ContactCombatPlayerStateCandidate:
	var copied_candidate := new()
	copied_candidate._profile_id = _profile_id
	copied_candidate._content_schema_version = _content_schema_version
	copied_candidate._content_version = _content_version
	copied_candidate._current_health = _current_health
	var copied_ids: Array[StringName] = _copy_ids(_claimed_reward_ids)
	copied_ids.make_read_only()
	copied_candidate._claimed_reward_ids = copied_ids
	copied_candidate._initialized = _initialized
	return copied_candidate


func is_valid() -> bool:
	return (
		_initialized
		and not String(_profile_id).is_empty()
		and _content_schema_version > 0
		and _content_version > 0
		and _current_health >= 0
		and _claimed_reward_ids.size()
		<= PlayerProgressionStateScript.MAX_CLAIMED_REWARD_COUNT
		and _ids_are_canonical_and_unique(_claimed_reward_ids)
	)


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


func is_equal_to(other: ContactCombatPlayerStateCandidate) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other._initialized == _initialized
		and other.profile_id() == _profile_id
		and other.content_schema_version() == _content_schema_version
		and other.content_version() == _content_version
		and other.current_health() == _current_health
		and other.claimed_reward_ids() == _claimed_reward_ids
	)


static func _ids_are_canonical_and_unique(ids: Array[StringName]) -> bool:
	var seen_ids: Dictionary[StringName, bool] = {}
	for index: int in range(ids.size()):
		var reward_id: StringName = ids[index]
		if String(reward_id).is_empty() or seen_ids.has(reward_id):
			return false
		seen_ids[reward_id] = true
		if index > 0 and String(reward_id) < String(ids[index - 1]):
			return false
	return true


static func _copy_ids(ids: Array[StringName]) -> Array[StringName]:
	var copied_ids: Array[StringName] = []
	for reward_id: StringName in ids:
		copied_ids.append(reward_id)
		if (
			copied_ids.size()
			>= PlayerProgressionStateScript.MAX_CLAIMED_REWARD_COUNT + 1
		):
			break
	return copied_ids
