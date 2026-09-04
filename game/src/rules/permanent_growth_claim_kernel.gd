class_name PermanentGrowthClaimKernel
extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const PlayerProgressionDerivationResultScript := preload(
	"res://src/rules/player_progression_derivation_result.gd"
)
const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PermanentGrowthClaimCommandScript := preload(
	"res://src/rules/permanent_growth_claim_command.gd"
)
const PermanentGrowthClaimEventScript := preload(
	"res://src/rules/permanent_growth_claim_event.gd"
)
const PermanentGrowthClaimResultScript := preload(
	"res://src/rules/permanent_growth_claim_result.gd"
)
const PermanentGrowthArithmeticScript := preload(
	"res://src/rules/permanent_growth_arithmetic.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")

const EXPECTED_PERMANENT_GROWTH_REWARD_COUNT: int = 30

# 投影记忆化：注册表投影是封印内容的纯函数，同一注册表实例在全进程内必然得到
# 完全相同的投影（RegistryProjection 冻结后只读，可安全共享）。缓存以实例身份
# 为键，且仅在注册表当前仍通过 is_initialized() 复验时命中——封印后被篡改的
# 注册表会绕过缓存、按原路径完整重算并失败，防篡改语义保持不变。
# 此前一次接触战事务 prepare 链路会触发 6+ 次全量投影重建。
static var _cached_projection_registry: RefCounted = null
static var _cached_projection: RegistryProjection = null


class RegistryProjection extends RefCounted:
	var failure_reason: int = 0
	var content_schema_version: int = 0
	var content_version: int = 0
	var profile_id: StringName = &""
	var initial_maximum_health: int = 0
	var initial_attack: int = 0
	var initial_defense: int = 0
	var initial_speed: int = 0
	var reward_ids: Array[StringName] = []
	var reward_stat_kinds: Dictionary[StringName, int] = {}
	var reward_increases: Dictionary[StringName, int] = {}

	func freeze() -> void:
		reward_ids.make_read_only()
		reward_stat_kinds.make_read_only()
		reward_increases.make_read_only()


static func derive_snapshot(
	state: RefCounted,
	registry: RefCounted,
) -> PlayerProgressionDerivationResultScript:
	if state == null or state.get_script() != PlayerProgressionStateScript:
		return PlayerProgressionDerivationResultScript.failure(
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE
		)
	var authoritative_state: PlayerProgressionStateScript = (
		state as PlayerProgressionStateScript
	).copy()
	if not authoritative_state.is_valid():
		return PlayerProgressionDerivationResultScript.failure(
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE
		)
	var projection: RegistryProjection = _capture_registry_projection(registry)
	if projection.failure_reason != PlayerProgressionDerivationResultScript.FailureReason.NONE:
		return PlayerProgressionDerivationResultScript.failure(projection.failure_reason)
	return _derive_snapshot_from_projection(authoritative_state, projection)


static func _derive_snapshot_from_projection(
	authoritative_state: PlayerProgressionStateScript,
	projection: RegistryProjection,
) -> PlayerProgressionDerivationResultScript:
	if (
		authoritative_state.content_schema_version()
		!= projection.content_schema_version
	):
		return PlayerProgressionDerivationResultScript.failure(
			(
				PlayerProgressionDerivationResultScript
				.FailureReason
				.CONTENT_SCHEMA_VERSION_MISMATCH
			)
		)
	if authoritative_state.content_version() != projection.content_version:
		return PlayerProgressionDerivationResultScript.failure(
			(
				PlayerProgressionDerivationResultScript
				.FailureReason
				.CONTENT_VERSION_MISMATCH
			)
		)
	if authoritative_state.profile_id() != projection.profile_id:
		return PlayerProgressionDerivationResultScript.failure(
			PlayerProgressionDerivationResultScript.FailureReason.PROFILE_ID_MISMATCH
		)

	var stat_values: Array[int] = [
		projection.initial_maximum_health,
		projection.initial_attack,
		projection.initial_defense,
		projection.initial_speed,
	]
	for reward_id: StringName in authoritative_state.claimed_reward_ids():
		if not projection.reward_stat_kinds.has(reward_id):
			return PlayerProgressionDerivationResultScript.failure(
				(
					PlayerProgressionDerivationResultScript
					.FailureReason
					.UNKNOWN_CLAIMED_REWARD_ID
				)
			)
		if not PermanentGrowthArithmeticScript.add_reward_increase_with_overflow_guard(
			stat_values,
			projection.reward_stat_kinds[reward_id],
			projection.reward_increases[reward_id],
		):
			return PlayerProgressionDerivationResultScript.failure(
				(
					PlayerProgressionDerivationResultScript
					.FailureReason
					.INTEGER_OVERFLOW
				)
			)
	var maximum_health: int = stat_values[0]
	var attack: int = stat_values[1]
	var defense: int = stat_values[2]
	var speed: int = stat_values[3]
	if authoritative_state.current_health() > maximum_health:
		return PlayerProgressionDerivationResultScript.failure(
			(
				PlayerProgressionDerivationResultScript
				.FailureReason
				.CURRENT_HEALTH_OUT_OF_RANGE
			)
		)
	var snapshot: PlayerProgressionSnapshotScript = (
		PlayerProgressionSnapshotScript.create(
			authoritative_state.profile_id(),
			authoritative_state.content_schema_version(),
			authoritative_state.content_version(),
			authoritative_state.current_health(),
			maximum_health,
			attack,
			defense,
			speed,
			authoritative_state.claimed_reward_ids(),
		)
	)
	if not snapshot.is_valid():
		return PlayerProgressionDerivationResultScript.failure(
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE
		)
	return PlayerProgressionDerivationResultScript.success(snapshot)


static func execute(
	state: RefCounted,
	command: RefCounted,
	registry: RefCounted,
) -> PermanentGrowthClaimResultScript:
	var unchanged_state: PlayerProgressionStateScript = _copy_exact_state(state)
	var requested_reward_id: StringName = &""
	if unchanged_state == null or not unchanged_state.is_valid():
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
		)
	var projection: RegistryProjection = _capture_registry_projection(registry)
	if projection.failure_reason != PlayerProgressionDerivationResultScript.FailureReason.NONE:
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			_map_derivation_failure(projection.failure_reason),
		)
	var current_derivation: PlayerProgressionDerivationResultScript = (
		_derive_snapshot_from_projection(unchanged_state, projection)
	)
	if not current_derivation.succeeded():
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			_map_derivation_failure(current_derivation.failure_reason()),
		)
	var current_snapshot: PlayerProgressionSnapshotScript = (
		current_derivation.snapshot()
	)
	if (
		command == null
		or command.get_script() != PermanentGrowthClaimCommandScript
	):
		return PermanentGrowthClaimResultScript.rejected(
			&"",
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
		)
	var authoritative_command: PermanentGrowthClaimCommandScript = (
		command as PermanentGrowthClaimCommandScript
	).copy()
	requested_reward_id = authoritative_command.reward_id()
	if authoritative_command.kind() != PermanentGrowthClaimCommandScript.Kind.CLAIM:
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
		)
	if String(requested_reward_id).is_empty():
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.EMPTY_REWARD_ID,
		)
	if not projection.reward_stat_kinds.has(requested_reward_id):
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_REWARD_ID,
		)
	var reward_stat_kind: int = projection.reward_stat_kinds[requested_reward_id]
	var reward_increase: int = projection.reward_increases[requested_reward_id]
	if unchanged_state.has_claimed_reward(requested_reward_id):
		return PermanentGrowthClaimResultScript.already_claimed(
			requested_reward_id,
			unchanged_state,
			current_snapshot,
		)
	if current_snapshot.current_health() == 0:
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			PermanentGrowthClaimResultScript.RejectionReason.PLAYER_INCAPACITATED,
		)
	var next_current_health: int = unchanged_state.current_health()
	if (
		reward_stat_kind
		== PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH
	):
		if ValidationSupportScript.would_add_overflow(next_current_health, reward_increase):
			return PermanentGrowthClaimResultScript.rejected(
				requested_reward_id,
				unchanged_state,
				PermanentGrowthClaimResultScript.RejectionReason.INTEGER_OVERFLOW,
			)
		next_current_health += reward_increase
	var next_claimed_reward_ids: Array[StringName] = (
		unchanged_state.claimed_reward_ids()
	)
	next_claimed_reward_ids.append(requested_reward_id)
	var next_state: PlayerProgressionStateScript = PlayerProgressionStateScript.create(
		unchanged_state.profile_id(),
		unchanged_state.content_schema_version(),
		unchanged_state.content_version(),
		next_current_health,
		next_claimed_reward_ids,
	)
	var next_derivation: PlayerProgressionDerivationResultScript = (
		_derive_snapshot_from_projection(
			next_state,
			projection,
		)
	)
	if not next_derivation.succeeded():
		return PermanentGrowthClaimResultScript.rejected(
			requested_reward_id,
			unchanged_state,
			_map_derivation_failure(next_derivation.failure_reason()),
		)
	var next_snapshot: PlayerProgressionSnapshotScript = next_derivation.snapshot()
	var domain_event: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			next_state.profile_id(),
			next_state.content_schema_version(),
			next_state.content_version(),
			requested_reward_id,
			reward_stat_kind,
			reward_increase,
			unchanged_state.current_health(),
			next_state.current_health(),
		)
	)
	return PermanentGrowthClaimResultScript.applied(
		requested_reward_id,
		current_snapshot,
		next_state,
		next_snapshot,
		domain_event,
	)


static func _capture_registry_projection(registry: RefCounted) -> RegistryProjection:
	if (
		_cached_projection != null
		and registry != null
		and registry.get_script() == ContentRegistryScript
		and registry == _cached_projection_registry
		and (registry as ContentRegistryScript).is_initialized()
	):
		return _cached_projection
	var projection := RegistryProjection.new()
	if registry == null or registry.get_script() != ContentRegistryScript:
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	var sealed_registry: ContentRegistryScript = registry as ContentRegistryScript
	var catalog_resource: Resource = sealed_registry.global_progression_catalog() as Resource
	if (
		catalog_resource == null
		or catalog_resource.get_script() != GlobalProgressionCatalogScript
	):
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	var content_schema_version: int = sealed_registry.schema_version()
	if content_schema_version <= 0:
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	var content_version: int = sealed_registry.content_version()
	if content_version <= 0:
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	var catalog: GlobalProgressionCatalogScript = (
		catalog_resource as GlobalProgressionCatalogScript
	)
	var initial_stats_resource: Resource = catalog.initial_stats as Resource
	if not _is_valid_initial_stats(initial_stats_resource):
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript
			.FailureReason
			.INVALID_INITIAL_PLAYER_STATS
		)
		return projection
	if catalog.permanent_growth_rewards.size() != EXPECTED_PERMANENT_GROWTH_REWARD_COUNT:
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	for reward_resource: Resource in catalog.permanent_growth_rewards:
		if (
			reward_resource == null
			or reward_resource.get_script() != PermanentGrowthRewardDefinitionScript
		):
			projection.failure_reason = (
				PlayerProgressionDerivationResultScript
				.FailureReason
				.INVALID_REWARD_DEFINITION
			)
			return projection
		var reward: PermanentGrowthRewardDefinitionScript = (
			reward_resource as PermanentGrowthRewardDefinitionScript
		)
		if (
			String(reward.reward_id).is_empty()
			or projection.reward_stat_kinds.has(reward.reward_id)
		):
			projection.failure_reason = (
				PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
			)
			return projection
		if not _is_valid_reward(reward, reward.reward_id):
			projection.failure_reason = (
				PlayerProgressionDerivationResultScript
				.FailureReason
				.INVALID_REWARD_DEFINITION
			)
			return projection
		projection.reward_ids.append(reward.reward_id)
		projection.reward_stat_kinds[reward.reward_id] = reward.stat_kind
		projection.reward_increases[reward.reward_id] = reward.increase
	if (
		projection.reward_ids.size() != EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
		or not ValidationSupportScript.ids_are_canonical_and_unique(projection.reward_ids)
		or projection.reward_stat_kinds.size() != EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
		or projection.reward_increases.size() != EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
	):
		projection.failure_reason = (
			PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY
		)
		return projection
	var initial_stats: PlayerStatProfileScript = (
		initial_stats_resource as PlayerStatProfileScript
	)
	projection.content_schema_version = content_schema_version
	projection.content_version = content_version
	projection.profile_id = initial_stats.profile_id
	projection.initial_maximum_health = initial_stats.maximum_health
	projection.initial_attack = initial_stats.attack
	projection.initial_defense = initial_stats.defense
	projection.initial_speed = initial_stats.speed
	projection.failure_reason = PlayerProgressionDerivationResultScript.FailureReason.NONE
	projection.freeze()
	_cached_projection_registry = registry
	_cached_projection = projection
	return projection


static func _copy_exact_state(state: RefCounted) -> PlayerProgressionStateScript:
	if state == null or state.get_script() != PlayerProgressionStateScript:
		return null
	return (state as PlayerProgressionStateScript).copy()


static func _map_derivation_failure(failure_reason: int) -> int:
	match failure_reason:
		PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE:
			return PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE
		PlayerProgressionDerivationResultScript.FailureReason.INVALID_REGISTRY:
			return PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.CONTENT_SCHEMA_VERSION_MISMATCH
		):
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.CONTENT_SCHEMA_VERSION_MISMATCH
			)
		PlayerProgressionDerivationResultScript.FailureReason.CONTENT_VERSION_MISMATCH:
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.CONTENT_VERSION_MISMATCH
			)
		PlayerProgressionDerivationResultScript.FailureReason.PROFILE_ID_MISMATCH:
			return PermanentGrowthClaimResultScript.RejectionReason.PROFILE_ID_MISMATCH
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.UNKNOWN_CLAIMED_REWARD_ID
		):
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.UNKNOWN_CLAIMED_REWARD_ID
			)
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.INVALID_REWARD_DEFINITION
		):
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.INVALID_REWARD_DEFINITION
			)
		PlayerProgressionDerivationResultScript.FailureReason.INTEGER_OVERFLOW:
			return PermanentGrowthClaimResultScript.RejectionReason.INTEGER_OVERFLOW
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.CURRENT_HEALTH_OUT_OF_RANGE
		):
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.CURRENT_HEALTH_OUT_OF_RANGE
			)
		(
			PlayerProgressionDerivationResultScript
			.FailureReason
			.INVALID_INITIAL_PLAYER_STATS
		):
			return (
				PermanentGrowthClaimResultScript
				.RejectionReason
				.INVALID_INITIAL_PLAYER_STATS
			)
		_:
			return PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE


static func _is_valid_initial_stats(profile: Resource) -> bool:
	if profile == null or profile.get_script() != PlayerStatProfileScript:
		return false
	var exact_profile: PlayerStatProfileScript = profile as PlayerStatProfileScript
	return (
		not String(exact_profile.profile_id).is_empty()
		and exact_profile.maximum_health > 0
		and exact_profile.attack > 0
		and exact_profile.defense > 0
		and exact_profile.speed > 0
	)


static func _is_valid_reward(
	reward: Resource,
	expected_reward_id: StringName,
) -> bool:
	if (
		reward == null
		or reward.get_script() != PermanentGrowthRewardDefinitionScript
	):
		return false
	var exact_reward: PermanentGrowthRewardDefinitionScript = (
		reward as PermanentGrowthRewardDefinitionScript
	)
	return (
		exact_reward.reward_id == expected_reward_id
		and (
			exact_reward.stat_kind
			>= PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH
		)
		and exact_reward.stat_kind <= PermanentGrowthRewardDefinitionScript.StatKind.SPEED
		and exact_reward.increase > 0
	)
