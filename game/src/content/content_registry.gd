class_name ContentRegistry
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const MainlineProgressionDefinitionScript := preload(
	"res://src/content/definitions/mainline_progression_definition_resource.gd"
)
const OptionalProgressionDefinitionScript := preload(
	"res://src/content/definitions/optional_progression_definition_resource.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const RepresentativeRouteContractScript := preload(
	"res://src/content/definitions/representative_route_contract_resource.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const EnemyFamilyDefinitionScript := preload(
	"res://src/content/definitions/enemy_family_definition_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
)
const ContentLookupResultScript := preload("res://src/content/content_lookup_result.gd")
const GlobalProgressionQueryResultScript := preload(
	"res://src/content/global_progression_query_result.gd"
)
const RepresentativeRouteQueryResultScript := preload(
	"res://src/content/representative_route_query_result.gd"
)
const EnemyProfileQueryResultScript := preload(
	"res://src/content/enemy_profile_query_result.gd"
)
const ContentContractFingerprintScript := preload(
	"res://src/content/content_contract_fingerprint.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const ContentContractConstantsScript := preload(
	"res://src/content/content_contract_constants.gd"
)
const PermanentGrowthArithmeticScript := preload(
	"res://src/rules/permanent_growth_arithmetic.gd"
)

# 冻结内容合同期望计数的再导出：权威数值只在 content_contract_constants.gd
# 定义一次，此处保留原常量名以维持调用点稳定。
const EXPECTED_MAINLINE_PROGRESSION_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_MAINLINE_PROGRESSION_COUNT
)
const EXPECTED_OPTIONAL_PROGRESSION_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_OPTIONAL_PROGRESSION_COUNT
)
const EXPECTED_PERMANENT_GROWTH_REWARD_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
)
const EXPECTED_REPRESENTATIVE_ROUTE_CONTRACT_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_REPRESENTATIVE_ROUTE_CONTRACT_COUNT
)
const EXPECTED_ENEMY_FAMILY_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_ENEMY_FAMILY_COUNT
)
const EXPECTED_ENEMY_PROFILE_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_ENEMY_PROFILE_COUNT
)

const StaticMapCatalogScript := preload("res://src/content/definitions/static_map_catalog_resource.gd")
const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")
const StaticMapQueryResultScript := preload("res://src/content/static_map_query_result.gd")

var _static_map_catalog: StaticMapCatalogScript
var _schema_version: int
var _content_version: int
var _material_ids: Array[StringName] = []
var _blueprint_ids: Array[StringName] = []
var _recipe_ids: Array[StringName] = []
var _blueprints_by_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
var _recipes_by_id: Dictionary[StringName, RecipeDefinitionScript] = {}
var _progression_catalog_id: StringName = &""
var _initial_player_stats: PlayerStatProfileScript
var _mainline_progression_ids: Array[StringName] = []
var _optional_progression_ids: Array[StringName] = []
var _permanent_growth_reward_ids: Array[StringName] = []
var _permanent_growth_rewards: Array[PermanentGrowthRewardDefinitionScript] = []
var _mainline_progression_by_id: Dictionary[StringName, MainlineProgressionDefinitionScript] = {}
var _optional_progression_by_id: Dictionary[StringName, OptionalProgressionDefinitionScript] = {}
var _permanent_growth_rewards_by_id: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
var _route_contract_catalog_id: StringName = &""
var _representative_route_contract_ids: Array[StringName] = []
var _representative_route_contracts: Array[RepresentativeRouteContractScript] = []
var _representative_route_contracts_by_id: Dictionary[StringName, RepresentativeRouteContractScript] = {}
var _enemy_profile_catalog_id: StringName = &""
var _enemy_family_ids: Array[StringName] = []
var _enemy_families: Array[EnemyFamilyDefinitionScript] = []
var _enemy_families_by_id: Dictionary[StringName, EnemyFamilyDefinitionScript] = {}
var _enemy_profile_ids: Array[StringName] = []
var _enemy_profiles: Array[EnemyProfileDefinitionScript] = []
var _enemy_profiles_by_id: Dictionary[StringName, EnemyProfileDefinitionScript] = {}
var _verified_read_scope: WeakRef


# 仅供同步规则事务使用。作用域独占深拷贝；副本只弱引用作用域，异常退出时
# 也不会因引用环把校验复用永久保留。不得跨 await、外部回调或结果发布边界。
class _VerifiedReadScope extends RefCounted:
	var _registry: ContentRegistry

	func _close() -> bool:
		var captured_registry := _registry
		_registry = null
		if captured_registry == null:
			return false
		captured_registry._verified_read_scope = null
		return captured_registry._has_valid_contract()


func _init() -> void:
	pass


# 构建器与内容测试专用的封印构造协议：仅接受与冻结 v6 内容合同指纹完全一致的
# 输入，成功封印返回 true；已初始化或指纹不匹配时不做任何改动并返回 false，
# 调用方可据此区分「封印成功」与「无操作」。通用调用方应通过
# ContentRegistryBuilder.build() 获得注册表，不应直接调用本方法。
func initialize_validated(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	route_catalog: RepresentativeRouteCatalogScript,
	enemy_catalog: EnemyProfileCatalogScript,
	map_catalog: StaticMapCatalogScript,
) -> bool:
	if is_initialized():
		return false
	if not ContentContractFingerprintScript.matches(
		schema_version,
		content_version,
		blueprints,
		recipes,
		progression_catalog,
		route_catalog,
		enemy_catalog,
		map_catalog,
	):
		return false
	var stored_material_ids: Array[StringName] = (
		RecipeDefinitionScript.allowed_material_ids()
	)
	var stored_blueprint_ids: Array[StringName] = []
	var stored_recipe_ids: Array[StringName] = []
	var stored_blueprints_by_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
	var stored_recipes_by_id: Dictionary[StringName, RecipeDefinitionScript] = {}
	var stored_mainline_ids: Array[StringName] = []
	var stored_optional_ids: Array[StringName] = []
	var stored_reward_ids: Array[StringName] = []
	var stored_rewards: Array[PermanentGrowthRewardDefinitionScript] = []
	var stored_mainline_by_id: Dictionary[StringName, MainlineProgressionDefinitionScript] = {}
	var stored_optional_by_id: Dictionary[StringName, OptionalProgressionDefinitionScript] = {}
	var stored_rewards_by_id: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
	var stored_route_contract_ids: Array[StringName] = []
	var stored_route_contracts: Array[RepresentativeRouteContractScript] = []
	var stored_route_contracts_by_id: Dictionary[StringName, RepresentativeRouteContractScript] = {}
	var stored_enemy_family_ids: Array[StringName] = []
	var stored_enemy_families: Array[EnemyFamilyDefinitionScript] = []
	var stored_enemy_families_by_id: Dictionary[StringName, EnemyFamilyDefinitionScript] = {}
	var stored_enemy_profile_ids: Array[StringName] = []
	var stored_enemy_profiles: Array[EnemyProfileDefinitionScript] = []
	var stored_enemy_profiles_by_id: Dictionary[StringName, EnemyProfileDefinitionScript] = {}
	for blueprint: BlueprintDefinitionScript in blueprints:
		var stored_blueprint: BlueprintDefinitionScript = (
			BlueprintDefinitionScript.snapshot(blueprint)
		)
		stored_blueprint_ids.append(stored_blueprint.content_id)
		stored_blueprints_by_id[stored_blueprint.content_id] = stored_blueprint
	for recipe: RecipeDefinitionScript in recipes:
		var stored_recipe: RecipeDefinitionScript = RecipeDefinitionScript.snapshot(recipe)
		stored_recipe_ids.append(stored_recipe.recipe_id)
		stored_recipes_by_id[stored_recipe.recipe_id] = stored_recipe
	for definition: MainlineProgressionDefinitionScript in (
		progression_catalog.mainline_progression
	):
		var stored_definition: MainlineProgressionDefinitionScript = (
			MainlineProgressionDefinitionScript.snapshot(definition)
		)
		stored_mainline_ids.append(stored_definition.content_id)
		stored_mainline_by_id[stored_definition.content_id] = stored_definition
	for definition: OptionalProgressionDefinitionScript in (
		progression_catalog.optional_progression
	):
		var stored_definition: OptionalProgressionDefinitionScript = (
			OptionalProgressionDefinitionScript.snapshot(definition)
		)
		stored_optional_ids.append(stored_definition.content_id)
		stored_optional_by_id[stored_definition.content_id] = stored_definition
	for reward: PermanentGrowthRewardDefinitionScript in (
		progression_catalog.permanent_growth_rewards
	):
		var stored_reward: PermanentGrowthRewardDefinitionScript = (
			PermanentGrowthRewardDefinitionScript.snapshot(reward)
		)
		stored_reward_ids.append(stored_reward.reward_id)
		stored_rewards.append(stored_reward)
		stored_rewards_by_id[stored_reward.reward_id] = stored_reward
	for contract: RepresentativeRouteContractScript in route_catalog.contracts:
		var stored_contract: RepresentativeRouteContractScript = (
			RepresentativeRouteContractScript.snapshot(contract)
		)
		stored_contract.mainline_progression_reference_ids.sort_custom(
			ContentValidationSupportScript.string_name_less_than
		)
		stored_contract.available_blueprint_reference_ids.sort_custom(
			ContentValidationSupportScript.string_name_less_than
		)
		stored_contract.tradeoff_dimension_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		stored_route_contract_ids.append(stored_contract.contract_id)
		stored_route_contracts.append(stored_contract)
		stored_route_contracts_by_id[stored_contract.contract_id] = stored_contract
	for family: EnemyFamilyDefinitionScript in enemy_catalog.families:
		var stored_family: EnemyFamilyDefinitionScript = (
			EnemyFamilyDefinitionScript.snapshot(family)
		)
		stored_enemy_family_ids.append(stored_family.family_id)
		stored_enemy_families.append(stored_family)
		stored_enemy_families_by_id[stored_family.family_id] = stored_family
	for profile: EnemyProfileDefinitionScript in enemy_catalog.profiles:
		var stored_enemy_profile: EnemyProfileDefinitionScript = (
			EnemyProfileDefinitionScript.snapshot(profile)
		)
		stored_enemy_profile.combat_trait_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		stored_enemy_profile_ids.append(stored_enemy_profile.profile_id)
		stored_enemy_profiles.append(stored_enemy_profile)
		stored_enemy_profiles_by_id[stored_enemy_profile.profile_id] = stored_enemy_profile
	stored_blueprint_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_recipe_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_mainline_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_optional_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_reward_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_rewards.sort_custom(_permanent_growth_reward_less_than)
	stored_route_contract_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_route_contracts.sort_custom(_representative_route_contract_less_than)
	stored_enemy_family_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_enemy_families.sort_custom(_enemy_family_less_than)
	stored_enemy_profile_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_enemy_profiles.sort_custom(_enemy_profile_less_than)
	stored_material_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	stored_material_ids.make_read_only()
	stored_blueprint_ids.make_read_only()
	stored_recipe_ids.make_read_only()
	stored_mainline_ids.make_read_only()
	stored_optional_ids.make_read_only()
	stored_reward_ids.make_read_only()
	stored_rewards.make_read_only()
	stored_route_contract_ids.make_read_only()
	stored_route_contracts.make_read_only()
	stored_enemy_family_ids.make_read_only()
	stored_enemy_families.make_read_only()
	stored_enemy_profile_ids.make_read_only()
	stored_enemy_profiles.make_read_only()
	stored_blueprints_by_id.make_read_only()
	stored_recipes_by_id.make_read_only()
	stored_mainline_by_id.make_read_only()
	stored_optional_by_id.make_read_only()
	stored_rewards_by_id.make_read_only()
	stored_route_contracts_by_id.make_read_only()
	stored_enemy_families_by_id.make_read_only()
	stored_enemy_profiles_by_id.make_read_only()
	_static_map_catalog = StaticMapCatalogScript.snapshot(map_catalog)
	_schema_version = schema_version
	_content_version = content_version
	_material_ids = stored_material_ids
	_blueprint_ids = stored_blueprint_ids
	_recipe_ids = stored_recipe_ids
	_blueprints_by_id = stored_blueprints_by_id
	_recipes_by_id = stored_recipes_by_id
	_progression_catalog_id = progression_catalog.catalog_id
	_initial_player_stats = PlayerStatProfileScript.snapshot(
		progression_catalog.initial_stats
	)
	_mainline_progression_ids = stored_mainline_ids
	_optional_progression_ids = stored_optional_ids
	_permanent_growth_reward_ids = stored_reward_ids
	_permanent_growth_rewards = stored_rewards
	_mainline_progression_by_id = stored_mainline_by_id
	_optional_progression_by_id = stored_optional_by_id
	_permanent_growth_rewards_by_id = stored_rewards_by_id
	_route_contract_catalog_id = route_catalog.catalog_id
	_representative_route_contract_ids = stored_route_contract_ids
	_representative_route_contracts = stored_route_contracts
	_representative_route_contracts_by_id = stored_route_contracts_by_id
	_enemy_profile_catalog_id = enemy_catalog.catalog_id
	_enemy_family_ids = stored_enemy_family_ids
	_enemy_families = stored_enemy_families
	_enemy_families_by_id = stored_enemy_families_by_id
	_enemy_profile_ids = stored_enemy_profile_ids
	_enemy_profiles = stored_enemy_profiles
	_enemy_profiles_by_id = stored_enemy_profiles_by_id
	return true


func is_initialized() -> bool:
	if _verified_read_scope != null:
		var scope := _verified_read_scope.get_ref() as _VerifiedReadScope
		if scope != null and scope._registry == self:
			return true
	return _has_valid_contract()


# 不在来源实例开启快速路径。复用公开快照和唯一封印构造协议，确保所有
# Resource、嵌套集合与索引属于副本；副本本身验封后才交给局部作用域持有。
func _begin_verified_read_scope() -> _VerifiedReadScope:
	if get_script() != ContentRegistry or not _has_valid_contract():
		return null
	var copied_registry := ContentRegistry.new()
	if not copied_registry.initialize_validated(
		_schema_version,
		_content_version,
		blueprints(),
		recipes(),
		global_progression_catalog(),
		representative_route_contract_catalog(),
		enemy_profile_catalog(),
		static_map_catalog(),
	):
		return null
	if not copied_registry._has_valid_contract():
		return null
	var scope := _VerifiedReadScope.new()
	scope._registry = copied_registry
	copied_registry._verified_read_scope = weakref(scope)
	return scope


# 规则层各内核原先各自复制的注册表身份检查（精确脚本 + 已初始化状态），
# 统一收敛到注册表自身的权威实现，供 portable_inventory / contact_combat /
# world_step_contact 等消费者直接调用。
static func is_exact_initialized_instance(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == ContentRegistry
		and (candidate as ContentRegistry).is_initialized()
	)


func schema_version() -> int:
	return _schema_version if is_initialized() else 0


func content_version() -> int:
	return _content_version if is_initialized() else 0


func blueprint_count() -> int:
	return _blueprint_ids.size() if is_initialized() else 0


func recipe_count() -> int:
	return _recipe_ids.size() if is_initialized() else 0


func material_count() -> int:
	return _material_ids.size() if is_initialized() else 0


func material_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_material_ids)


func has_material(material_id: StringName) -> bool:
	return is_initialized() and _material_ids.has(material_id)


func blueprint_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_blueprint_ids)


func recipe_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_recipe_ids)


func blueprints() -> Array[BlueprintDefinitionScript]:
	var result: Array[BlueprintDefinitionScript] = []
	if not is_initialized():
		return result
	for content_id: StringName in _blueprint_ids:
		result.append(BlueprintDefinitionScript.snapshot(_blueprints_by_id[content_id]))
	return result


func recipes() -> Array[RecipeDefinitionScript]:
	var result: Array[RecipeDefinitionScript] = []
	if not is_initialized():
		return result
	for recipe_id: StringName in _recipe_ids:
		result.append(RecipeDefinitionScript.snapshot(_recipes_by_id[recipe_id]))
	return result


func static_map_catalog() -> StaticMapCatalogScript:
	return StaticMapCatalogScript.snapshot(_static_map_catalog) if is_initialized() else null


func static_map_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if is_initialized():
		for definition: StaticMapDefinitionScript in _static_map_catalog.maps:
			result.append(definition.map_id)
		result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


func lookup_static_map(map_id: StringName) -> StaticMapQueryResultScript:
	if not is_initialized():
		return StaticMapQueryResultScript.new(null, ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED, map_id, "registry", "Map queries require sealed content.",
		))
	for definition: StaticMapDefinitionScript in _static_map_catalog.maps:
		if definition.map_id == map_id:
			return StaticMapQueryResultScript.new(definition, null)
	return StaticMapQueryResultScript.new(null, ContentValidationIssueScript.new(
		ContentValidationIssueScript.LOOKUP_UNKNOWN_MAP_ID, map_id, "map_id", "No static map is registered for this ID.",
	))


func global_progression_catalog() -> GlobalProgressionCatalogScript:
	if not is_initialized():
		return null
	var result := GlobalProgressionCatalogScript.new()
	result.catalog_id = _progression_catalog_id
	result.initial_stats = PlayerStatProfileScript.snapshot(_initial_player_stats)
	for content_id: StringName in _mainline_progression_ids:
		result.mainline_progression.append(
			MainlineProgressionDefinitionScript.snapshot(
				_mainline_progression_by_id[content_id]
			)
		)
	for content_id: StringName in _optional_progression_ids:
		result.optional_progression.append(
			OptionalProgressionDefinitionScript.snapshot(
				_optional_progression_by_id[content_id]
			)
		)
	for reward: PermanentGrowthRewardDefinitionScript in _permanent_growth_rewards:
		result.permanent_growth_rewards.append(
			PermanentGrowthRewardDefinitionScript.snapshot(reward)
		)
	return result


func representative_route_contract_catalog() -> RepresentativeRouteCatalogScript:
	if not is_initialized():
		return null
	var result := RepresentativeRouteCatalogScript.new()
	result.catalog_id = _route_contract_catalog_id
	for contract: RepresentativeRouteContractScript in _representative_route_contracts:
		result.contracts.append(RepresentativeRouteContractScript.snapshot(contract))
	return result


func representative_route_contract_count() -> int:
	return _representative_route_contract_ids.size() if is_initialized() else 0


func representative_route_contract_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_representative_route_contract_ids)


func representative_route_contracts() -> Array[RepresentativeRouteContractScript]:
	var result: Array[RepresentativeRouteContractScript] = []
	if not is_initialized():
		return result
	for contract: RepresentativeRouteContractScript in _representative_route_contracts:
		result.append(RepresentativeRouteContractScript.snapshot(contract))
	return result


func lookup_representative_route_contract(
	contract_id: StringName,
) -> RepresentativeRouteQueryResultScript:
	if not is_initialized():
		return _uninitialized_route_contract_query(contract_id)
	if not _representative_route_contracts_by_id.has(contract_id):
		return RepresentativeRouteQueryResultScript.failed(
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_ROUTE_CONTRACT_ID,
				contract_id,
				"contract_id",
				"No representative route contract is registered for ID '%s'."
				% String(contract_id),
			)
		)
	return _route_contract_query(
		_representative_route_contracts_by_id[contract_id]
	)


func enemy_profile_catalog() -> EnemyProfileCatalogScript:
	if not is_initialized():
		return null
	var result := EnemyProfileCatalogScript.new()
	result.catalog_id = _enemy_profile_catalog_id
	for family: EnemyFamilyDefinitionScript in _enemy_families:
		result.families.append(EnemyFamilyDefinitionScript.snapshot(family))
	for profile: EnemyProfileDefinitionScript in _enemy_profiles:
		result.profiles.append(EnemyProfileDefinitionScript.snapshot(profile))
	return result


func enemy_family_count() -> int:
	return _enemy_family_ids.size() if is_initialized() else 0


func enemy_family_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_enemy_family_ids)


func enemy_families() -> Array[EnemyFamilyDefinitionScript]:
	var result: Array[EnemyFamilyDefinitionScript] = []
	if not is_initialized():
		return result
	for family: EnemyFamilyDefinitionScript in _enemy_families:
		result.append(EnemyFamilyDefinitionScript.snapshot(family))
	return result


func enemy_profile_count() -> int:
	return _enemy_profile_ids.size() if is_initialized() else 0


func enemy_profile_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_enemy_profile_ids)


func enemy_profiles() -> Array[EnemyProfileDefinitionScript]:
	var result: Array[EnemyProfileDefinitionScript] = []
	if not is_initialized():
		return result
	for profile: EnemyProfileDefinitionScript in _enemy_profiles:
		result.append(EnemyProfileDefinitionScript.snapshot(profile))
	return result


func lookup_enemy_family(
	family_id: StringName,
) -> EnemyProfileQueryResultScript:
	if not is_initialized():
		return _uninitialized_enemy_query(
			EnemyProfileQueryResultScript.Kind.FAMILY,
			family_id,
			"family_id",
		)
	if not _enemy_families_by_id.has(family_id):
		return EnemyProfileQueryResultScript.failed(
			EnemyProfileQueryResultScript.Kind.FAMILY,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_ENEMY_FAMILY_ID,
				family_id,
				"family_id",
				"No enemy family is registered for ID '%s'." % String(family_id),
			)
		)
	return EnemyProfileQueryResultScript.found_family(
		_enemy_families_by_id[family_id]
	)


func lookup_enemy_profile(
	profile_id: StringName,
) -> EnemyProfileQueryResultScript:
	if not is_initialized():
		return _uninitialized_enemy_query(
			EnemyProfileQueryResultScript.Kind.PROFILE,
			profile_id,
			"profile_id",
		)
	if not _enemy_profiles_by_id.has(profile_id):
		return EnemyProfileQueryResultScript.failed(
			EnemyProfileQueryResultScript.Kind.PROFILE,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_ENEMY_PROFILE_ID,
				profile_id,
				"profile_id",
				"No enemy profile is registered for ID '%s'." % String(profile_id),
			)
		)
	return EnemyProfileQueryResultScript.found_profile(
		_enemy_profiles_by_id[profile_id]
	)


func initial_player_stats() -> GlobalProgressionQueryResultScript:
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
			&"progression.player.loer",
		)
	return GlobalProgressionQueryResultScript.found_player_stats(
		_initial_player_stats
	)


func mainline_progression_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_mainline_progression_ids)


func optional_progression_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_optional_progression_ids)


func permanent_growth_reward_count() -> int:
	return _permanent_growth_reward_ids.size() if is_initialized() else 0


func permanent_growth_reward_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_permanent_growth_reward_ids)


func mainline_progression_definitions() -> Array[MainlineProgressionDefinitionScript]:
	var result: Array[MainlineProgressionDefinitionScript] = []
	if not is_initialized():
		return result
	for content_id: StringName in _mainline_progression_ids:
		result.append(
			MainlineProgressionDefinitionScript.snapshot(
				_mainline_progression_by_id[content_id]
			)
		)
	return result


func optional_progression_definitions() -> Array[OptionalProgressionDefinitionScript]:
	var result: Array[OptionalProgressionDefinitionScript] = []
	if not is_initialized():
		return result
	for content_id: StringName in _optional_progression_ids:
		result.append(
			OptionalProgressionDefinitionScript.snapshot(
				_optional_progression_by_id[content_id]
			)
		)
	return result


func permanent_growth_reward_definitions() -> Array[PermanentGrowthRewardDefinitionScript]:
	var result: Array[PermanentGrowthRewardDefinitionScript] = []
	if not is_initialized():
		return result
	for reward: PermanentGrowthRewardDefinitionScript in _permanent_growth_rewards:
		result.append(PermanentGrowthRewardDefinitionScript.snapshot(reward))
	return result


func lookup_mainline_progression(
	content_id: StringName,
) -> GlobalProgressionQueryResultScript:
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
			content_id,
		)
	if not _mainline_progression_by_id.has(content_id):
		return GlobalProgressionQueryResultScript.failed(
			GlobalProgressionQueryResultScript.Kind.MAINLINE_PROGRESSION,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_MAINLINE_PROGRESSION_ID,
				content_id,
				"content_id",
				"No mainline progression is registered for ID '%s'."
				% String(content_id),
			),
		)
	return GlobalProgressionQueryResultScript.found_mainline_progression(
		_mainline_progression_by_id[content_id]
	)


func lookup_optional_progression(
	content_id: StringName,
) -> GlobalProgressionQueryResultScript:
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
			content_id,
		)
	if not _optional_progression_by_id.has(content_id):
		return GlobalProgressionQueryResultScript.failed(
			GlobalProgressionQueryResultScript.Kind.OPTIONAL_PROGRESSION,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_OPTIONAL_PROGRESSION_ID,
				content_id,
				"content_id",
				"No optional progression is registered for ID '%s'."
				% String(content_id),
			),
		)
	return GlobalProgressionQueryResultScript.found_optional_progression(
		_optional_progression_by_id[content_id]
	)


func lookup_permanent_growth_reward(
	reward_id: StringName,
) -> GlobalProgressionQueryResultScript:
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.PERMANENT_GROWTH_REWARD,
			reward_id,
		)
	if not _permanent_growth_rewards_by_id.has(reward_id):
		return GlobalProgressionQueryResultScript.failed(
			GlobalProgressionQueryResultScript.Kind.PERMANENT_GROWTH_REWARD,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_PERMANENT_GROWTH_REWARD_ID,
				reward_id,
				"reward_id",
				"No permanent growth reward is registered for ID '%s'."
				% String(reward_id),
			),
		)
	return GlobalProgressionQueryResultScript.found_permanent_growth_reward(
		_permanent_growth_rewards_by_id[reward_id]
	)


func mainline_stats_after_chapter(
	chapter: int,
) -> GlobalProgressionQueryResultScript:
	var requested_chapter_id := StringName(str(chapter))
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
			requested_chapter_id,
		)
	if chapter < 1 or chapter > ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER:
		return GlobalProgressionQueryResultScript.failed(
			GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_PROGRESSION_CHAPTER_INVALID,
				requested_chapter_id,
				"chapter",
				"Mainline chapter query must be between 1 and 9; got %d."
				% chapter,
			),
		)
	var result_stats: PlayerStatProfileScript = (
		PlayerStatProfileScript.snapshot(_initial_player_stats)
	)
	for content_id: StringName in _mainline_progression_ids:
		var definition: MainlineProgressionDefinitionScript = (
			_mainline_progression_by_id[content_id]
		)
		if definition.chapter <= chapter:
			_apply_permanent_growth_rewards(result_stats, definition.reward_ids)
	return GlobalProgressionQueryResultScript.found_player_stats(result_stats)


func full_completion_player_stats() -> GlobalProgressionQueryResultScript:
	if not is_initialized():
		return _uninitialized_progression_query(
			GlobalProgressionQueryResultScript.Kind.PLAYER_STATS,
			&"progression.player.loer",
		)
	var result_stats: PlayerStatProfileScript = (
		PlayerStatProfileScript.snapshot(_initial_player_stats)
	)
	for content_id: StringName in _mainline_progression_ids:
		_apply_permanent_growth_rewards(
			result_stats,
			_mainline_progression_by_id[content_id].reward_ids,
		)
	for content_id: StringName in _optional_progression_ids:
		_apply_permanent_growth_rewards(
			result_stats,
			_optional_progression_by_id[content_id].reward_ids,
		)
	return GlobalProgressionQueryResultScript.found_player_stats(result_stats)


func lookup_blueprint(content_id: StringName) -> ContentLookupResultScript:
	if not is_initialized():
		return _uninitialized_lookup(ContentLookupResultScript.Kind.BLUEPRINT, content_id)
	if not _blueprints_by_id.has(content_id):
		return ContentLookupResultScript.failed(
			ContentLookupResultScript.Kind.BLUEPRINT,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_BLUEPRINT_ID,
				content_id,
				"content_id",
				"No blueprint is registered for ID '%s'." % String(content_id),
			),
		)
	return ContentLookupResultScript.found_blueprint(_blueprints_by_id[content_id])


func lookup_recipe(recipe_id: StringName) -> ContentLookupResultScript:
	if not is_initialized():
		return _uninitialized_lookup(ContentLookupResultScript.Kind.RECIPE, recipe_id)
	if not _recipes_by_id.has(recipe_id):
		return ContentLookupResultScript.failed(
			ContentLookupResultScript.Kind.RECIPE,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_RECIPE_ID,
				recipe_id,
				"recipe_id",
				"No standard recipe is registered for ID '%s'." % String(recipe_id),
			),
		)
	return ContentLookupResultScript.found_recipe(_recipes_by_id[recipe_id])


func _uninitialized_lookup(kind: int, requested_id: StringName) -> ContentLookupResultScript:
	return ContentLookupResultScript.failed(
		kind,
		ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
			requested_id,
			"registry",
			"Content registry has not passed manifest validation and initialization.",
		),
	)


func _uninitialized_progression_query(
	kind: int,
	requested_id: StringName,
) -> GlobalProgressionQueryResultScript:
	return GlobalProgressionQueryResultScript.failed(
		kind,
		ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_PROGRESSION_REGISTRY_UNINITIALIZED,
			requested_id,
			"registry",
			"Content registry has not passed complete progression validation.",
		),
		)


func _uninitialized_enemy_query(
	kind: int,
	requested_id: StringName,
	field_path: String,
) -> EnemyProfileQueryResultScript:
	return EnemyProfileQueryResultScript.failed(
		kind,
		ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_ENEMY_REGISTRY_UNINITIALIZED,
			requested_id,
			field_path,
			"Content registry has not passed complete enemy-profile validation.",
		)
	)


func _uninitialized_route_contract_query(
	requested_id: StringName,
) -> RepresentativeRouteQueryResultScript:
	return RepresentativeRouteQueryResultScript.failed(
		ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_ROUTE_CONTRACT_REGISTRY_UNINITIALIZED,
			requested_id,
			"registry",
			"Content registry has not passed complete route-contract validation.",
		)
	)


func _route_contract_query(
	contract: RepresentativeRouteContractScript,
) -> RepresentativeRouteQueryResultScript:
	var stage_end_minimum_stats: PlayerStatProfileScript = PlayerStatProfileScript.snapshot(
		_initial_player_stats
	)
	for progression_id: StringName in contract.mainline_progression_reference_ids:
		_apply_permanent_growth_rewards(
			stage_end_minimum_stats,
			_mainline_progression_by_id[progression_id].reward_ids,
		)
	var available_blueprints: Array[BlueprintDefinitionScript] = []
	for blueprint_id: StringName in contract.available_blueprint_reference_ids:
		available_blueprints.append(_blueprints_by_id[blueprint_id])
	return RepresentativeRouteQueryResultScript.found(
		contract,
		stage_end_minimum_stats,
		available_blueprints,
	)


func _has_valid_contract() -> bool:
	if not StaticMapCatalogScript.has_exact_entry_types(_static_map_catalog):
		return false
	var expected_material_ids: Array[StringName] = (
		RecipeDefinitionScript.allowed_material_ids()
	)
	expected_material_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	if _material_ids != expected_material_ids:
		return false
	if (
		_blueprint_ids.size() != _blueprints_by_id.size()
		or _recipe_ids.size() != _recipes_by_id.size()
		or _mainline_progression_ids.size() != EXPECTED_MAINLINE_PROGRESSION_COUNT
		or _mainline_progression_ids.size() != _mainline_progression_by_id.size()
		or _optional_progression_ids.size() != EXPECTED_OPTIONAL_PROGRESSION_COUNT
		or _optional_progression_ids.size() != _optional_progression_by_id.size()
		or (
			_permanent_growth_reward_ids.size()
			!= EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
		)
		or _permanent_growth_rewards.size() != EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
		or (
			_permanent_growth_reward_ids.size()
			!= _permanent_growth_rewards_by_id.size()
		)
		or (
			_representative_route_contract_ids.size()
			!= EXPECTED_REPRESENTATIVE_ROUTE_CONTRACT_COUNT
		)
		or (
			_representative_route_contract_ids.size()
			!= _representative_route_contracts.size()
		)
		or (
			_representative_route_contract_ids.size()
			!= _representative_route_contracts_by_id.size()
		)
		or _enemy_family_ids.size() != EXPECTED_ENEMY_FAMILY_COUNT
		or _enemy_families.size() != EXPECTED_ENEMY_FAMILY_COUNT
		or _enemy_family_ids.size() != _enemy_families_by_id.size()
		or _enemy_profile_ids.size() != EXPECTED_ENEMY_PROFILE_COUNT
		or _enemy_profiles.size() != EXPECTED_ENEMY_PROFILE_COUNT
		or _enemy_profile_ids.size() != _enemy_profiles_by_id.size()
	):
		return false
	var ordered_blueprint_ids: Array[StringName] = _copy_ids(_blueprint_ids)
	var ordered_recipe_ids: Array[StringName] = _copy_ids(_recipe_ids)
	var ordered_mainline_ids: Array[StringName] = _copy_ids(
		_mainline_progression_ids
	)
	var ordered_optional_ids: Array[StringName] = _copy_ids(
		_optional_progression_ids
	)
	var ordered_reward_ids: Array[StringName] = _copy_ids(
		_permanent_growth_reward_ids
	)
	var ordered_route_contract_ids: Array[StringName] = _copy_ids(
		_representative_route_contract_ids
	)
	var ordered_enemy_family_ids: Array[StringName] = _copy_ids(
		_enemy_family_ids
	)
	var ordered_enemy_profile_ids: Array[StringName] = _copy_ids(
		_enemy_profile_ids
	)
	ordered_blueprint_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_recipe_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_mainline_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_optional_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_reward_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_route_contract_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_enemy_family_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_enemy_profile_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	if (
		_blueprint_ids != ordered_blueprint_ids
		or _recipe_ids != ordered_recipe_ids
		or _mainline_progression_ids != ordered_mainline_ids
		or _optional_progression_ids != ordered_optional_ids
		or _permanent_growth_reward_ids != ordered_reward_ids
		or _representative_route_contract_ids != ordered_route_contract_ids
		or _enemy_family_ids != ordered_enemy_family_ids
		or _enemy_profile_ids != ordered_enemy_profile_ids
	):
		return false
	var blueprints: Array[BlueprintDefinitionScript] = []
	for content_id: StringName in _blueprint_ids:
		if not _blueprints_by_id.has(content_id):
			return false
		var blueprint_resource: Resource = _blueprints_by_id[content_id] as Resource
		if (
			blueprint_resource == null
			or blueprint_resource.get_script() != BlueprintDefinitionScript
		):
			return false
		var blueprint: BlueprintDefinitionScript = (
			blueprint_resource as BlueprintDefinitionScript
		)
		if blueprint.content_id != content_id:
			return false
		blueprints.append(blueprint)
	var recipes: Array[RecipeDefinitionScript] = []
	for recipe_id: StringName in _recipe_ids:
		if not _recipes_by_id.has(recipe_id):
			return false
		var recipe_resource: Resource = _recipes_by_id[recipe_id] as Resource
		if (
			recipe_resource == null
			or recipe_resource.get_script() != RecipeDefinitionScript
		):
			return false
		var recipe: RecipeDefinitionScript = recipe_resource as RecipeDefinitionScript
		if recipe.recipe_id != recipe_id:
			return false
		recipes.append(recipe)
	var profile_resource: Resource = _initial_player_stats as Resource
	if (
		profile_resource == null
		or profile_resource.get_script() != PlayerStatProfileScript
	):
		return false
	var referenced_reward_ids: Array[StringName] = []
	var mainline_progression: Array[MainlineProgressionDefinitionScript] = []
	for content_id: StringName in _mainline_progression_ids:
		if not _mainline_progression_by_id.has(content_id):
			return false
		var definition_resource: Resource = (
			_mainline_progression_by_id[content_id] as Resource
		)
		if (
			definition_resource == null
			or definition_resource.get_script() != MainlineProgressionDefinitionScript
		):
			return false
		var definition: MainlineProgressionDefinitionScript = (
			definition_resource as MainlineProgressionDefinitionScript
		)
		if definition.content_id != content_id:
			return false
		var ordered_membership_ids: Array[StringName] = _copy_ids(
			definition.reward_ids
		)
		ordered_membership_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		if definition.reward_ids != ordered_membership_ids:
			return false
		for reward_id: StringName in definition.reward_ids:
			if not _permanent_growth_rewards_by_id.has(reward_id):
				return false
			referenced_reward_ids.append(reward_id)
		mainline_progression.append(definition)
	var optional_progression: Array[OptionalProgressionDefinitionScript] = []
	for content_id: StringName in _optional_progression_ids:
		if not _optional_progression_by_id.has(content_id):
			return false
		var definition_resource: Resource = (
			_optional_progression_by_id[content_id] as Resource
		)
		if (
			definition_resource == null
			or definition_resource.get_script() != OptionalProgressionDefinitionScript
		):
			return false
		var definition: OptionalProgressionDefinitionScript = (
			definition_resource as OptionalProgressionDefinitionScript
		)
		if definition.content_id != content_id:
			return false
		var ordered_membership_ids: Array[StringName] = _copy_ids(
			definition.reward_ids
		)
		ordered_membership_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		if definition.reward_ids != ordered_membership_ids:
			return false
		for reward_id: StringName in definition.reward_ids:
			if not _permanent_growth_rewards_by_id.has(reward_id):
				return false
			referenced_reward_ids.append(reward_id)
		optional_progression.append(definition)
	referenced_reward_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	if referenced_reward_ids != _permanent_growth_reward_ids:
		return false
	var rewards: Array[PermanentGrowthRewardDefinitionScript] = []
	for index: int in range(_permanent_growth_reward_ids.size()):
		var reward_id: StringName = _permanent_growth_reward_ids[index]
		var listed_reward_resource: Resource = (
			_permanent_growth_rewards[index] as Resource
		)
		if (
			listed_reward_resource == null
			or (
				listed_reward_resource.get_script()
				!= PermanentGrowthRewardDefinitionScript
			)
		):
			return false
		var listed_reward: PermanentGrowthRewardDefinitionScript = (
			listed_reward_resource as PermanentGrowthRewardDefinitionScript
		)
		if listed_reward.reward_id != reward_id:
			return false
		if not _permanent_growth_rewards_by_id.has(reward_id):
			return false
		var mapped_reward_resource: Resource = (
			_permanent_growth_rewards_by_id[reward_id] as Resource
		)
		if (
			mapped_reward_resource == null
			or (
				mapped_reward_resource.get_script()
				!= PermanentGrowthRewardDefinitionScript
			)
		):
			return false
		var mapped_reward: PermanentGrowthRewardDefinitionScript = (
			mapped_reward_resource as PermanentGrowthRewardDefinitionScript
		)
		if (
			mapped_reward.reward_id != reward_id
			or not listed_reward.is_equal_to(mapped_reward)
		):
			return false
		rewards.append(listed_reward)
	var route_contracts: Array[RepresentativeRouteContractScript] = []
	for index: int in range(_representative_route_contract_ids.size()):
		var contract_id: StringName = _representative_route_contract_ids[index]
		var listed_contract_resource: Resource = (
			_representative_route_contracts[index] as Resource
		)
		if (
			listed_contract_resource == null
			or (
				listed_contract_resource.get_script()
				!= RepresentativeRouteContractScript
			)
			or not _representative_route_contracts_by_id.has(contract_id)
		):
			return false
		var listed_contract: RepresentativeRouteContractScript = (
			listed_contract_resource as RepresentativeRouteContractScript
		)
		var mapped_contract_resource: Resource = (
			_representative_route_contracts_by_id[contract_id] as Resource
		)
		if (
			mapped_contract_resource == null
			or (
				mapped_contract_resource.get_script()
				!= RepresentativeRouteContractScript
			)
		):
			return false
		var mapped_contract: RepresentativeRouteContractScript = (
			mapped_contract_resource as RepresentativeRouteContractScript
		)
		if (
			listed_contract.contract_id != contract_id
			or not listed_contract.is_equal_to(mapped_contract)
		):
			return false
		var ordered_progression_refs: Array[StringName] = _copy_ids(
			listed_contract.mainline_progression_reference_ids
		)
		var ordered_blueprint_refs: Array[StringName] = _copy_ids(
			listed_contract.available_blueprint_reference_ids
		)
		var ordered_tradeoff_ids: Array[StringName] = _copy_ids(
			listed_contract.tradeoff_dimension_ids
		)
		ordered_progression_refs.sort_custom(ContentValidationSupportScript.string_name_less_than)
		ordered_blueprint_refs.sort_custom(ContentValidationSupportScript.string_name_less_than)
		ordered_tradeoff_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		if (
			listed_contract.mainline_progression_reference_ids
			!= ordered_progression_refs
			or (
				listed_contract.available_blueprint_reference_ids
				!= ordered_blueprint_refs
			)
			or listed_contract.tradeoff_dimension_ids != ordered_tradeoff_ids
		):
			return false
		for progression_id: StringName in ordered_progression_refs:
			if not _mainline_progression_by_id.has(progression_id):
				return false
		for blueprint_id: StringName in ordered_blueprint_refs:
			if not _blueprints_by_id.has(blueprint_id):
				return false
		route_contracts.append(listed_contract)
	var enemy_families: Array[EnemyFamilyDefinitionScript] = []
	for index: int in range(_enemy_family_ids.size()):
		var family_id: StringName = _enemy_family_ids[index]
		var listed_family_resource: Resource = _enemy_families[index] as Resource
		if (
			listed_family_resource == null
			or listed_family_resource.get_script() != EnemyFamilyDefinitionScript
			or not _enemy_families_by_id.has(family_id)
		):
			return false
		var listed_family: EnemyFamilyDefinitionScript = (
			listed_family_resource as EnemyFamilyDefinitionScript
		)
		var mapped_family_resource: Resource = (
			_enemy_families_by_id[family_id] as Resource
		)
		if (
			mapped_family_resource == null
			or mapped_family_resource.get_script() != EnemyFamilyDefinitionScript
		):
			return false
		var mapped_family: EnemyFamilyDefinitionScript = (
			mapped_family_resource as EnemyFamilyDefinitionScript
		)
		if (
			listed_family.family_id != family_id
			or not listed_family.is_equal_to(mapped_family)
		):
			return false
		enemy_families.append(listed_family)
	var enemy_profiles: Array[EnemyProfileDefinitionScript] = []
	for index: int in range(_enemy_profile_ids.size()):
		var enemy_profile_id: StringName = _enemy_profile_ids[index]
		var listed_enemy_profile_resource: Resource = _enemy_profiles[index] as Resource
		if (
			listed_enemy_profile_resource == null
			or (
				listed_enemy_profile_resource.get_script()
				!= EnemyProfileDefinitionScript
			)
			or not _enemy_profiles_by_id.has(enemy_profile_id)
		):
			return false
		var listed_enemy_profile: EnemyProfileDefinitionScript = (
			listed_enemy_profile_resource as EnemyProfileDefinitionScript
		)
		var mapped_enemy_profile_resource: Resource = (
			_enemy_profiles_by_id[enemy_profile_id] as Resource
		)
		if (
			mapped_enemy_profile_resource == null
			or (
				mapped_enemy_profile_resource.get_script()
				!= EnemyProfileDefinitionScript
			)
		):
			return false
		var mapped_enemy_profile: EnemyProfileDefinitionScript = (
			mapped_enemy_profile_resource as EnemyProfileDefinitionScript
		)
		if (
			listed_enemy_profile.profile_id != enemy_profile_id
			or not listed_enemy_profile.is_equal_to(mapped_enemy_profile)
			or not _enemy_families_by_id.has(listed_enemy_profile.family_id)
			or not _representative_route_contracts_by_id.has(
				listed_enemy_profile.balance_contract_id
			)
		):
			return false
		var ordered_trait_ids: Array[StringName] = _copy_ids(
			listed_enemy_profile.combat_trait_ids
		)
		ordered_trait_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
		if listed_enemy_profile.combat_trait_ids != ordered_trait_ids:
			return false
		enemy_profiles.append(listed_enemy_profile)
	var progression_catalog := GlobalProgressionCatalogScript.new()
	progression_catalog.catalog_id = _progression_catalog_id
	progression_catalog.initial_stats = _initial_player_stats
	for definition: MainlineProgressionDefinitionScript in mainline_progression:
		progression_catalog.mainline_progression.append(definition)
	for definition: OptionalProgressionDefinitionScript in optional_progression:
		progression_catalog.optional_progression.append(definition)
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		progression_catalog.permanent_growth_rewards.append(reward)
	var route_catalog := RepresentativeRouteCatalogScript.new()
	route_catalog.catalog_id = _route_contract_catalog_id
	for contract: RepresentativeRouteContractScript in route_contracts:
		route_catalog.contracts.append(contract)
	var enemy_catalog := EnemyProfileCatalogScript.new()
	enemy_catalog.catalog_id = _enemy_profile_catalog_id
	for family: EnemyFamilyDefinitionScript in enemy_families:
		enemy_catalog.families.append(family)
	for enemy_profile: EnemyProfileDefinitionScript in enemy_profiles:
		enemy_catalog.profiles.append(enemy_profile)
	return ContentContractFingerprintScript.matches(
		_schema_version,
		_content_version,
		blueprints,
		recipes,
		progression_catalog,
		route_catalog,
		enemy_catalog,
		_static_map_catalog,
	)


func _apply_permanent_growth_rewards(
	stats: PlayerStatProfileScript,
	reward_ids: Array[StringName],
) -> void:
	for reward_id: StringName in reward_ids:
		PermanentGrowthArithmeticScript.apply_reward_to_player_stats(
			stats,
			_permanent_growth_rewards_by_id[reward_id],
		)


static func _copy_ids(source: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for content_id: StringName in source:
		result.append(content_id)
	return result


static func _permanent_growth_reward_less_than(
	left: PermanentGrowthRewardDefinitionScript,
	right: PermanentGrowthRewardDefinitionScript,
) -> bool:
	return String(left.reward_id) < String(right.reward_id)


static func _representative_route_contract_less_than(
	left: RepresentativeRouteContractScript,
	right: RepresentativeRouteContractScript,
) -> bool:
	return String(left.contract_id) < String(right.contract_id)


static func _enemy_family_less_than(
	left: EnemyFamilyDefinitionScript,
	right: EnemyFamilyDefinitionScript,
) -> bool:
	return String(left.family_id) < String(right.family_id)


static func _enemy_profile_less_than(
	left: EnemyProfileDefinitionScript,
	right: EnemyProfileDefinitionScript,
) -> bool:
	return String(left.profile_id) < String(right.profile_id)
