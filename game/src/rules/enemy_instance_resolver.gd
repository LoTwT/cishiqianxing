class_name EnemyInstanceResolver
extends RefCounted

const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyProfileQueryResultScript := preload(
	"res://src/content/enemy_profile_query_result.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")


static func create_initial(
	instance_id: StringName,
	profile_id: StringName,
	registry: RefCounted,
) -> EnemyInstanceResolutionResultScript:
	if (
		not EnemyInstanceStateScript.is_valid_instance_id(instance_id)
		or String(profile_id).is_empty()
	):
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE
		)
	var exact_registry: ContentRegistryScript = _exact_registry(registry)
	if exact_registry == null or not exact_registry.is_initialized():
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY
		)
	var profile: EnemyProfileDefinitionScript = _profile(
		exact_registry,
		profile_id,
	)
	if profile == null:
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID
		)
	var state: EnemyInstanceStateScript = EnemyInstanceStateScript.create(
		instance_id,
		profile_id,
		exact_registry.schema_version(),
		exact_registry.content_version(),
		profile.maximum_durability,
		EnemyInstanceStateScript.StateKind.PRIMARY,
		profile.combat_trait_ids.has(EnemyProfileDefinitionScript.SHIELD_TRAIT_ID),
	)
	return _resolve_exact(state, exact_registry, profile)


static func resolve(
	instance_state: RefCounted,
	registry: RefCounted,
) -> EnemyInstanceResolutionResultScript:
	var unchanged_state: EnemyInstanceStateScript = _copy_exact_state(instance_state)
	if (
		unchanged_state == null
		or not unchanged_state.is_initialized()
		or not EnemyInstanceStateScript.is_valid_instance_id(
			unchanged_state.instance_id()
		)
		or String(unchanged_state.profile_id()).is_empty()
		or unchanged_state.content_schema_version() <= 0
		or unchanged_state.content_version() <= 0
	):
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_INSTANCE_STATE
		)
	if (
		unchanged_state.state_kind() != EnemyInstanceStateScript.StateKind.PRIMARY
		and (
			unchanged_state.state_kind()
			!= EnemyInstanceStateScript.StateKind.ALTERNATE
		)
	):
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_STATE_KIND
		)
	var exact_registry: ContentRegistryScript = _exact_registry(registry)
	if exact_registry == null or not exact_registry.is_initialized():
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY
		)
	if unchanged_state.content_schema_version() != exact_registry.schema_version():
		return EnemyInstanceResolutionResultScript.failure(
			(
				EnemyInstanceResolutionResultScript
				.FailureReason
				.CONTENT_SCHEMA_VERSION_MISMATCH
			)
		)
	if unchanged_state.content_version() != exact_registry.content_version():
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.CONTENT_VERSION_MISMATCH
		)
	var profile: EnemyProfileDefinitionScript = _profile(
		exact_registry,
		unchanged_state.profile_id(),
	)
	if profile == null:
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.UNKNOWN_PROFILE_ID
		)
	return _resolve_exact(unchanged_state, exact_registry, profile)


static func _resolve_exact(
	state: EnemyInstanceStateScript,
	registry: ContentRegistryScript,
	profile: EnemyProfileDefinitionScript,
) -> EnemyInstanceResolutionResultScript:
	var maximum_durability: int = profile.maximum_durability
	if state.state_kind() == EnemyInstanceStateScript.StateKind.ALTERNATE:
		if not profile.has_alternate_state:
			return EnemyInstanceResolutionResultScript.failure(
				(
					EnemyInstanceResolutionResultScript
					.FailureReason
					.ALTERNATE_STATE_UNAVAILABLE
				)
			)
		maximum_durability = profile.alternate_maximum_durability
	if (
		state.current_durability() < 0
		or state.current_durability() > maximum_durability
	):
		return EnemyInstanceResolutionResultScript.failure(
			(
				EnemyInstanceResolutionResultScript
				.FailureReason
				.CURRENT_DURABILITY_OUT_OF_RANGE
			)
		)
	var profile_has_shield: bool = profile.combat_trait_ids.has(
		EnemyProfileDefinitionScript.SHIELD_TRAIT_ID
	)
	if state.shield_intact() and not profile_has_shield:
		return EnemyInstanceResolutionResultScript.failure(
			EnemyInstanceResolutionResultScript.FailureReason.SHIELD_STATE_INVALID
		)
	return EnemyInstanceResolutionResultScript.success(state, registry)


static func _copy_exact_state(state: RefCounted) -> EnemyInstanceStateScript:
	if (
		state == null
		or not is_instance_valid(state)
		or state.get_script() != EnemyInstanceStateScript
	):
		return null
	return (state as EnemyInstanceStateScript).copy()


static func _exact_registry(registry: RefCounted) -> ContentRegistryScript:
	if (
		registry == null
		or not is_instance_valid(registry)
		or registry.get_script() != ContentRegistryScript
	):
		return null
	return registry as ContentRegistryScript


static func _profile(
	registry: ContentRegistryScript,
	profile_id: StringName,
) -> EnemyProfileDefinitionScript:
	var query: EnemyProfileQueryResultScript = registry.lookup_enemy_profile(profile_id)
	if (
		query == null
		or not is_instance_valid(query)
		or query.get_script() != EnemyProfileQueryResultScript
		or not query.succeeded()
	):
		return null
	var profile: EnemyProfileDefinitionScript = query.profile()
	if (
		profile == null
		or not is_instance_valid(profile)
		or profile.get_script() != EnemyProfileDefinitionScript
	):
		return null
	return profile
