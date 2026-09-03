class_name EnemyInstanceSnapshot
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyProfileQueryResultScript := preload(
	"res://src/content/enemy_profile_query_result.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")

const MAXIMUM_COMBAT_TRAIT_COUNT: int = (
	EnemyProfileDefinitionScript.MAXIMUM_COMBAT_TRAIT_COUNT
)

var _instance_state: EnemyInstanceStateScript
var _maximum_durability: int = 0
var _attack: int = 0
var _defense: int = 0
var _speed: int = 0
var _has_alternate_state: bool = false
var _behavior_id: StringName = &""
var _combat_trait_ids: Array[StringName] = []
var _visual_binding_id: StringName = &""
var _initialized: bool = false


func _init() -> void:
	_combat_trait_ids.make_read_only()


static func from_registry(
	instance_state_candidate: RefCounted,
	registry: RefCounted,
) -> EnemyInstanceSnapshot:
	var snapshot := new()
	if not (
		instance_state_candidate != null
		and is_instance_valid(instance_state_candidate)
		and instance_state_candidate.get_script() == EnemyInstanceStateScript
		and registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
	):
		return snapshot
	var instance_state: EnemyInstanceStateScript = (
		instance_state_candidate as EnemyInstanceStateScript
	)
	if not instance_state.is_valid():
		return snapshot
	var exact_registry: ContentRegistryScript = registry as ContentRegistryScript
	if not exact_registry.is_initialized():
		return snapshot
	if (
		instance_state.content_schema_version() != exact_registry.schema_version()
		or instance_state.content_version() != exact_registry.content_version()
	):
		return snapshot
	var query: EnemyProfileQueryResultScript = exact_registry.lookup_enemy_profile(
		instance_state.profile_id()
	)
	if not (
		query != null
		and is_instance_valid(query)
		and query.get_script() == EnemyProfileQueryResultScript
		and query.succeeded()
		and query.kind() == EnemyProfileQueryResultScript.Kind.PROFILE
	):
		return snapshot
	var exact_profile: EnemyProfileDefinitionScript = query.profile()
	if not (
		exact_profile != null
		and is_instance_valid(exact_profile)
		and exact_profile.get_script() == EnemyProfileDefinitionScript
		and exact_profile.profile_id == instance_state.profile_id()
	):
		return snapshot
	snapshot._instance_state = instance_state.copy()
	snapshot._maximum_durability = exact_profile.maximum_durability
	snapshot._attack = exact_profile.attack
	snapshot._defense = exact_profile.defense
	snapshot._speed = exact_profile.speed
	if instance_state.state_kind() == EnemyInstanceStateScript.StateKind.ALTERNATE:
		snapshot._maximum_durability = exact_profile.alternate_maximum_durability
		snapshot._attack = exact_profile.alternate_attack
		snapshot._defense = exact_profile.alternate_defense
		snapshot._speed = exact_profile.alternate_speed
	snapshot._has_alternate_state = exact_profile.has_alternate_state
	snapshot._behavior_id = exact_profile.behavior_id
	snapshot._combat_trait_ids = _copy_and_sort_ids(exact_profile.combat_trait_ids)
	snapshot._visual_binding_id = exact_profile.visual_binding_id
	snapshot._initialized = true
	snapshot._combat_trait_ids.make_read_only()
	return snapshot


func copy() -> EnemyInstanceSnapshot:
	var copied_snapshot := new()
	if (
		_instance_state != null
		and is_instance_valid(_instance_state)
		and _instance_state.get_script() == EnemyInstanceStateScript
	):
		copied_snapshot._instance_state = _instance_state.copy()
	copied_snapshot._maximum_durability = _maximum_durability
	copied_snapshot._attack = _attack
	copied_snapshot._defense = _defense
	copied_snapshot._speed = _speed
	copied_snapshot._has_alternate_state = _has_alternate_state
	copied_snapshot._behavior_id = _behavior_id
	copied_snapshot._combat_trait_ids = _copy_ids(_combat_trait_ids)
	copied_snapshot._visual_binding_id = _visual_binding_id
	copied_snapshot._initialized = _initialized
	copied_snapshot._combat_trait_ids.make_read_only()
	return copied_snapshot


func is_valid() -> bool:
	return (
		_initialized
		and _instance_state != null
		and is_instance_valid(_instance_state)
		and _instance_state.get_script() == EnemyInstanceStateScript
		and _instance_state.is_valid()
		and _maximum_durability > 0
		and _instance_state.current_durability() <= _maximum_durability
		and _attack > 0
		and _defense > 0
		and _speed > 0
		and not String(_behavior_id).is_empty()
		and _ids_are_canonical_and_unique(_combat_trait_ids)
		and not String(_visual_binding_id).is_empty()
		and (
			_has_alternate_state
			== _combat_trait_ids.has(
				EnemyProfileDefinitionScript.PHASE_ALTERNATION_TRAIT_ID
			)
		)
		and (
			_instance_state.state_kind() != EnemyInstanceStateScript.StateKind.ALTERNATE
			or _has_alternate_state
		)
		and (
			not _instance_state.shield_intact()
			or _combat_trait_ids.has(EnemyProfileDefinitionScript.SHIELD_TRAIT_ID)
		)
	)


func instance_state() -> EnemyInstanceStateScript:
	if not is_valid():
		return null
	return _instance_state.copy()


func instance_id() -> StringName:
	return _instance_state.instance_id() if is_valid() else &""


func profile_id() -> StringName:
	return _instance_state.profile_id() if is_valid() else &""


func content_schema_version() -> int:
	return _instance_state.content_schema_version() if is_valid() else 0


func content_version() -> int:
	return _instance_state.content_version() if is_valid() else 0


func current_durability() -> int:
	return _instance_state.current_durability() if is_valid() else 0


func state_kind() -> int:
	return _instance_state.state_kind() if is_valid() else 0


func shield_intact() -> bool:
	return _instance_state.shield_intact() if is_valid() else false


func maximum_durability() -> int:
	return _maximum_durability if is_valid() else 0


func attack() -> int:
	return _attack if is_valid() else 0


func defense() -> int:
	return _defense if is_valid() else 0


func speed() -> int:
	return _speed if is_valid() else 0


func has_alternate_state() -> bool:
	return _has_alternate_state if is_valid() else false


func behavior_id() -> StringName:
	return _behavior_id if is_valid() else &""


func combat_trait_ids() -> Array[StringName]:
	if not is_valid():
		return []
	return _copy_ids(_combat_trait_ids)


func visual_binding_id() -> StringName:
	return _visual_binding_id if is_valid() else &""


func is_equal_to(other: EnemyInstanceSnapshot) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other._initialized == _initialized
		and _instance_state != null
		and other._instance_state != null
		and _instance_state.is_equal_to(other._instance_state)
		and other._maximum_durability == _maximum_durability
		and other._attack == _attack
		and other._defense == _defense
		and other._speed == _speed
		and other._has_alternate_state == _has_alternate_state
		and other._behavior_id == _behavior_id
		and other._combat_trait_ids == _combat_trait_ids
		and other._visual_binding_id == _visual_binding_id
	)


static func _copy_and_sort_ids(ids: Array[StringName]) -> Array[StringName]:
	var copied_ids: Array[StringName] = _copy_ids(ids)
	copied_ids.sort_custom(_id_less_than)
	return copied_ids


static func _copy_ids(ids: Array[StringName]) -> Array[StringName]:
	var copied_ids: Array[StringName] = []
	for content_id: StringName in ids:
		copied_ids.append(content_id)
		if copied_ids.size() > MAXIMUM_COMBAT_TRAIT_COUNT:
			break
	return copied_ids


static func _ids_are_canonical_and_unique(ids: Array[StringName]) -> bool:
	if ids.size() > MAXIMUM_COMBAT_TRAIT_COUNT:
		return false
	var seen_ids: Dictionary[StringName, bool] = {}
	for index: int in range(ids.size()):
		var content_id: StringName = ids[index]
		if String(content_id).is_empty() or seen_ids.has(content_id):
			return false
		seen_ids[content_id] = true
		if index > 0 and String(content_id) < String(ids[index - 1]):
			return false
	return true


static func _id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
