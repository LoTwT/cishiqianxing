class_name PermanentGrowthClaimEvent
extends RefCounted

const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const MAX_INT: int = 9_223_372_036_854_775_807

enum Kind {
	APPLIED = 1,
}

var _kind: int
var _profile_id: StringName
var _content_schema_version: int
var _content_version: int
var _reward_id: StringName
var _stat_kind: int
var _increase: int
var _previous_current_health: int
var _next_current_health: int


func _init(
	kind: int,
	profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	reward_id: StringName,
	stat_kind: int,
	increase: int,
	previous_current_health: int,
	next_current_health: int,
) -> void:
	_kind = kind
	_profile_id = profile_id
	_content_schema_version = content_schema_version
	_content_version = content_version
	_reward_id = reward_id
	_stat_kind = stat_kind
	_increase = increase
	_previous_current_health = previous_current_health
	_next_current_health = next_current_health


static func applied(
	profile_id: StringName,
	content_schema_version: int,
	content_version: int,
	reward_id: StringName,
	stat_kind: int,
	increase: int,
	previous_current_health: int,
	next_current_health: int,
) -> PermanentGrowthClaimEvent:
	return new(
		Kind.APPLIED,
		profile_id,
		content_schema_version,
		content_version,
		reward_id,
		stat_kind,
		increase,
		previous_current_health,
		next_current_health,
	)


func kind() -> int:
	return _kind


func profile_id() -> StringName:
	return _profile_id


func content_schema_version() -> int:
	return _content_schema_version


func content_version() -> int:
	return _content_version


func reward_id() -> StringName:
	return _reward_id


func stat_kind() -> int:
	return _stat_kind


func increase() -> int:
	return _increase


func previous_current_health() -> int:
	return _previous_current_health


func next_current_health() -> int:
	return _next_current_health


func is_valid() -> bool:
	if (
		_kind != Kind.APPLIED
		or String(_profile_id).is_empty()
		or _content_schema_version <= 0
		or _content_version <= 0
		or String(_reward_id).is_empty()
		or (
			_stat_kind
			< PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH
		)
		or _stat_kind > PermanentGrowthRewardDefinitionScript.StatKind.SPEED
		or _increase <= 0
		or _previous_current_health < 0
		or _next_current_health < 0
	):
		return false
	if (
		_stat_kind
		== PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH
	):
		return (
			_previous_current_health <= MAX_INT - _increase
			and _next_current_health == _previous_current_health + _increase
		)
	return _next_current_health == _previous_current_health


func is_commit_boundary() -> bool:
	return _kind == Kind.APPLIED and is_valid()


func copy() -> PermanentGrowthClaimEvent:
	return new(
		_kind,
		_profile_id,
		_content_schema_version,
		_content_version,
		_reward_id,
		_stat_kind,
		_increase,
		_previous_current_health,
		_next_current_health,
	)


func is_equal_to(other: PermanentGrowthClaimEvent) -> bool:
	return (
		other != null
		and other.kind() == _kind
		and other.profile_id() == _profile_id
		and other.content_schema_version() == _content_schema_version
		and other.content_version() == _content_version
		and other.reward_id() == _reward_id
		and other.stat_kind() == _stat_kind
		and other.increase() == _increase
		and other.previous_current_health() == _previous_current_health
		and other.next_current_health() == _next_current_health
	)
