class_name ContentContractFingerprint
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
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

const StaticMapCatalogScript := preload("res://src/content/definitions/static_map_catalog_resource.gd")
const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")
const MapEnemyPlacementScript := preload("res://src/content/definitions/map_enemy_placement_resource.gd")

const EXPECTED_FINGERPRINT: String = (
	"fda9b0dd286340a6ff9eb4a523c2220e6fce7bf7d34f4743b77856d0fed2bc96"
)


static func matches(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	route_catalog: RepresentativeRouteCatalogScript,
	enemy_catalog: EnemyProfileCatalogScript,
	map_catalog: StaticMapCatalogScript,
) -> bool:
	return (
		not EXPECTED_FINGERPRINT.is_empty()
		and calculate(
			schema_version,
			content_version,
			blueprints,
			recipes,
			progression_catalog,
			route_catalog,
			enemy_catalog,
			map_catalog,
		)
		== EXPECTED_FINGERPRINT
	)


static func calculate(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	route_catalog: RepresentativeRouteCatalogScript,
	enemy_catalog: EnemyProfileCatalogScript,
	map_catalog: StaticMapCatalogScript,
) -> String:
	if not StaticMapCatalogScript.has_exact_entry_types(map_catalog):
		return ""
	var ordered_maps := StaticMapCatalogScript.snapshot(map_catalog)
	var ordered_blueprints: Array[BlueprintDefinitionScript] = []
	for blueprint: BlueprintDefinitionScript in blueprints:
		if blueprint == null or blueprint.get_script() != BlueprintDefinitionScript:
			return ""
		ordered_blueprints.append(blueprint)
	var ordered_recipes: Array[RecipeDefinitionScript] = []
	for recipe: RecipeDefinitionScript in recipes:
		if recipe == null or recipe.get_script() != RecipeDefinitionScript:
			return ""
		ordered_recipes.append(recipe)
	var catalog_resource: Resource = progression_catalog as Resource
	if (
		catalog_resource == null
		or catalog_resource.get_script() != GlobalProgressionCatalogScript
	):
		return ""
	var player_profile_resource: Resource = progression_catalog.initial_stats as Resource
	if (
		player_profile_resource == null
		or player_profile_resource.get_script() != PlayerStatProfileScript
	):
		return ""
	var route_catalog_resource: Resource = route_catalog as Resource
	if (
		route_catalog_resource == null
		or route_catalog_resource.get_script() != RepresentativeRouteCatalogScript
	):
		return ""
	var ordered_route_contracts: Array[RepresentativeRouteContractScript] = []
	for contract: RepresentativeRouteContractScript in route_catalog.contracts:
		var contract_resource: Resource = contract as Resource
		if (
			contract_resource == null
			or contract_resource.get_script() != RepresentativeRouteContractScript
		):
			return ""
		ordered_route_contracts.append(contract)
	var enemy_catalog_resource: Resource = enemy_catalog as Resource
	if (
		enemy_catalog_resource == null
		or enemy_catalog_resource.get_script() != EnemyProfileCatalogScript
	):
		return ""
	var ordered_enemy_families: Array[EnemyFamilyDefinitionScript] = []
	for family: EnemyFamilyDefinitionScript in enemy_catalog.families:
		var family_resource: Resource = family as Resource
		if (
			family_resource == null
			or family_resource.get_script() != EnemyFamilyDefinitionScript
		):
			return ""
		ordered_enemy_families.append(family)
	var ordered_enemy_profiles: Array[EnemyProfileDefinitionScript] = []
	for profile: EnemyProfileDefinitionScript in enemy_catalog.profiles:
		var profile_resource: Resource = profile as Resource
		if (
			profile_resource == null
			or profile_resource.get_script() != EnemyProfileDefinitionScript
		):
			return ""
		ordered_enemy_profiles.append(profile)
	var ordered_mainline: Array[MainlineProgressionDefinitionScript] = []
	for definition: MainlineProgressionDefinitionScript in (
		progression_catalog.mainline_progression
	):
		var definition_resource: Resource = definition as Resource
		if (
			definition_resource == null
			or definition_resource.get_script() != MainlineProgressionDefinitionScript
		):
			return ""
		ordered_mainline.append(definition)
	var ordered_optional: Array[OptionalProgressionDefinitionScript] = []
	for definition: OptionalProgressionDefinitionScript in (
		progression_catalog.optional_progression
	):
		var definition_resource: Resource = definition as Resource
		if (
			definition_resource == null
			or definition_resource.get_script() != OptionalProgressionDefinitionScript
		):
			return ""
		ordered_optional.append(definition)
	var ordered_rewards: Array[PermanentGrowthRewardDefinitionScript] = []
	for reward: PermanentGrowthRewardDefinitionScript in (
		progression_catalog.permanent_growth_rewards
	):
		var reward_resource: Resource = reward as Resource
		if (
			reward_resource == null
			or reward_resource.get_script() != PermanentGrowthRewardDefinitionScript
		):
			return ""
		ordered_rewards.append(reward)
	ordered_blueprints.sort_custom(_blueprint_less_than)
	ordered_recipes.sort_custom(_recipe_less_than)
	ordered_mainline.sort_custom(_mainline_less_than)
	ordered_optional.sort_custom(_optional_less_than)
	ordered_rewards.sort_custom(_reward_less_than)
	ordered_route_contracts.sort_custom(_route_contract_less_than)
	ordered_enemy_families.sort_custom(_enemy_family_less_than)
	ordered_enemy_profiles.sort_custom(_enemy_profile_less_than)

	var payload: String = "contract:v6;s%d;c%d;b%d;r%d;g%s;a%d;m%d;o%d;q%s;t%d;e%s;f%d;n%d;" % [
		schema_version,
		content_version,
		ordered_blueprints.size(),
		ordered_recipes.size(),
		ContentValidationSupportScript.encode_string(String(progression_catalog.catalog_id)),
		ordered_rewards.size(),
		ordered_mainline.size(),
		ordered_optional.size(),
		ContentValidationSupportScript.encode_string(String(route_catalog.catalog_id)),
		ordered_route_contracts.size(),
		ContentValidationSupportScript.encode_string(String(enemy_catalog.catalog_id)),
		ordered_enemy_families.size(),
		ordered_enemy_profiles.size(),
	]
	for blueprint: BlueprintDefinitionScript in ordered_blueprints:
		payload += "B%s;i%d;i%d;i%d;i%d;i%d;%s;%s;%s;%s;" % [
			ContentValidationSupportScript.encode_string(String(blueprint.content_id)),
			blueprint.ordinal,
			blueprint.category,
			blueprint.tier,
			blueprint.unlock_chapter,
			blueprint.default_lifecycle,
			ContentValidationSupportScript.encode_string(String(blueprint.standard_recipe_id)),
			ContentValidationSupportScript.encode_string(String(blueprint.mechanic_id)),
			ContentValidationSupportScript.encode_string(String(blueprint.display_name_text_id)),
			ContentValidationSupportScript.encode_string(String(blueprint.function_text_id)),
		]
	for recipe: RecipeDefinitionScript in ordered_recipes:
		payload += "R%s;%s;%s;i%d;%s;i%d;" % [
			ContentValidationSupportScript.encode_string(String(recipe.recipe_id)),
			ContentValidationSupportScript.encode_string(String(recipe.output_blueprint_id)),
			ContentValidationSupportScript.encode_string(String(recipe.main_material_id)),
			recipe.main_quantity,
			ContentValidationSupportScript.encode_string(String(recipe.auxiliary_material_id)),
			recipe.auxiliary_quantity,
		]
	var initial_stats: PlayerStatProfileScript = progression_catalog.initial_stats
	payload += "P%s;i%d;i%d;i%d;i%d;" % [
		ContentValidationSupportScript.encode_string(String(initial_stats.profile_id)),
		initial_stats.maximum_health,
		initial_stats.attack,
		initial_stats.defense,
		initial_stats.speed,
	]
	for reward: PermanentGrowthRewardDefinitionScript in ordered_rewards:
		payload += "A%s;i%d;i%d;" % [
			ContentValidationSupportScript.encode_string(String(reward.reward_id)),
			reward.stat_kind,
			reward.increase,
		]
	for definition: MainlineProgressionDefinitionScript in ordered_mainline:
		var ordered_reward_ids: Array[StringName] = _ordered_reward_ids(
			definition.reward_ids
		)
		payload += "M%s;i%d;a%d;" % [
			ContentValidationSupportScript.encode_string(String(definition.content_id)),
			definition.chapter,
			ordered_reward_ids.size(),
		]
		for reward_id: StringName in ordered_reward_ids:
			payload += "a%s;" % ContentValidationSupportScript.encode_string(String(reward_id))
	for definition: OptionalProgressionDefinitionScript in ordered_optional:
		var ordered_reward_ids: Array[StringName] = _ordered_reward_ids(
			definition.reward_ids
		)
		payload += "O%s;%s;i%d;a%d;" % [
			ContentValidationSupportScript.encode_string(String(definition.content_id)),
			ContentValidationSupportScript.encode_string(String(definition.optional_map_id)),
			definition.available_after_chapter,
			ordered_reward_ids.size(),
		]
		for reward_id: StringName in ordered_reward_ids:
			payload += "a%s;" % ContentValidationSupportScript.encode_string(String(reward_id))
	for contract: RepresentativeRouteContractScript in ordered_route_contracts:
		var ordered_progression_ids: Array[StringName] = _ordered_string_names(
			contract.mainline_progression_reference_ids
		)
		var ordered_blueprint_ids: Array[StringName] = _ordered_string_names(
			contract.available_blueprint_reference_ids
		)
		var ordered_tradeoff_ids: Array[StringName] = _ordered_string_names(
			contract.tradeoff_dimension_ids
		)
		payload += "T%s;i%d;i%d;%s;p%d;" % [
			ContentValidationSupportScript.encode_string(String(contract.contract_id)),
			contract.stage_start_chapter,
			contract.stage_end_chapter,
			ContentValidationSupportScript.encode_string(String(contract.player_profile_id)),
			ordered_progression_ids.size(),
		]
		for content_id: StringName in ordered_progression_ids:
			payload += "p%s;" % ContentValidationSupportScript.encode_string(String(content_id))
		payload += "b%d;" % ordered_blueprint_ids.size()
		for content_id: StringName in ordered_blueprint_ids:
			payload += "b%s;" % ContentValidationSupportScript.encode_string(String(content_id))
		payload += "d%d;" % ordered_tradeoff_ids.size()
		for dimension_id: StringName in ordered_tradeoff_ids:
			payload += "d%s;" % ContentValidationSupportScript.encode_string(String(dimension_id))
		payload += "i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;" % [
			contract.backpack_slot_capacity,
			contract.encounter_group_minimum,
			contract.encounter_group_maximum,
			contract.encounter_group_hard_cap,
			contract.low_loss_contact_minimum,
			contract.low_loss_contact_maximum,
			contract.intuitive_contact_minimum,
			contract.intuitive_contact_maximum,
			contract.low_loss_minimum_exit_health_percent,
			contract.intuitive_minimum_exit_health_percent,
			contract.minimum_fixed_recovery_points,
			contract.fixed_recovery_amount,
			contract.minimum_legal_route_count,
			contract.minimum_legal_loadout_count,
			contract.minimum_distinct_tradeoff_dimensions,
			1 if contract.requires_non_dominated_route_set else 0,
		]
	for family: EnemyFamilyDefinitionScript in ordered_enemy_families:
		payload += "F%s;i%d;i%d;i%d;%s;%s;%s;" % [
			ContentValidationSupportScript.encode_string(String(family.family_id)),
			family.ordinal,
			family.source,
			family.numeric_archetype,
			ContentValidationSupportScript.encode_string(String(family.display_name_text_id)),
			ContentValidationSupportScript.encode_string(String(family.regional_role_id)),
			ContentValidationSupportScript.encode_string(String(family.visual_family_id)),
		]
	for profile: EnemyProfileDefinitionScript in ordered_enemy_profiles:
		var ordered_trait_ids: Array[StringName] = _ordered_string_names(
			profile.combat_trait_ids
		)
		payload += "E%s;%s;i%d;i%d;%s;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;i%d;%s;x%d;" % [
			ContentValidationSupportScript.encode_string(String(profile.profile_id)),
			ContentValidationSupportScript.encode_string(String(profile.family_id)),
			profile.tier,
			profile.source,
			ContentValidationSupportScript.encode_string(String(profile.balance_contract_id)),
			profile.maximum_durability,
			profile.attack,
			profile.defense,
			profile.speed,
			1 if profile.has_alternate_state else 0,
			profile.alternate_maximum_durability,
			profile.alternate_attack,
			profile.alternate_defense,
			profile.alternate_speed,
			ContentValidationSupportScript.encode_string(String(profile.behavior_id)),
			ordered_trait_ids.size(),
		]
		for trait_id: StringName in ordered_trait_ids:
			payload += "x%s;" % ContentValidationSupportScript.encode_string(String(trait_id))
		payload += "v%s;" % ContentValidationSupportScript.encode_string(String(profile.visual_binding_id))
	payload += "K%s;k%d;" % [ContentValidationSupportScript.encode_string(String(ordered_maps.catalog_id)), ordered_maps.maps.size()]
	for definition: StaticMapDefinitionScript in ordered_maps.maps:
		if not definition.source_declarations_are_valid():
			return ""
		payload += "D%s;%s;i%d;" % [ContentValidationSupportScript.encode_string(String(definition.map_id)), ContentValidationSupportScript.encode_string(String(definition.space_id)), definition.chapter]
		payload += "g%d;" % definition.grid_cells.size()
		for cell: Vector3i in definition.grid_cells:
			payload += _encode_cell(cell)
		payload += "b%d;" % definition.blocked_cells.size()
		for cell: Vector3i in definition.blocked_cells:
			payload += _encode_cell(cell)
		payload += "p" + _encode_cell(definition.player_spawn_cell)
		payload += "e%d;" % definition.enemies.size()
		for placement: MapEnemyPlacementScript in definition.enemies:
			payload += "e%s;%s;" % [ContentValidationSupportScript.encode_string(String(placement.instance_id)), ContentValidationSupportScript.encode_string(String(placement.profile_id))]
			payload += _encode_cell(placement.cell)
		payload += _encode_sources(definition.terrain_effect_ids_snapshot())
		payload += _encode_sources(definition.dynamic_behavior_ids_snapshot())
		payload += _encode_sources(definition.other_entity_ids_snapshot())
	return payload.sha256_text()


static func _encode_cell(cell: Vector3i) -> String:
	return "(%d,%d,%d);" % [cell.x, cell.y, cell.z]


static func _encode_sources(ids: Array[StringName]) -> String:
	var payload: String = "s%d;" % ids.size()
	for source_id: StringName in ids:
		payload += ContentValidationSupportScript.encode_string(String(source_id)) + ";"
	return payload


static func _ordered_reward_ids(reward_ids: Array[StringName]) -> Array[StringName]:
	var ordered_reward_ids: Array[StringName] = []
	for reward_id: StringName in reward_ids:
		ordered_reward_ids.append(reward_id)
	ordered_reward_ids.sort_custom(
		ContentValidationSupportScript.string_name_less_than
	)
	return ordered_reward_ids


static func _ordered_string_names(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: StringName in values:
		result.append(value)
	result.sort_custom(ContentValidationSupportScript.string_name_less_than)
	return result


static func _blueprint_less_than(
	left: BlueprintDefinitionScript,
	right: BlueprintDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _recipe_less_than(
	left: RecipeDefinitionScript,
	right: RecipeDefinitionScript,
) -> bool:
	return String(left.recipe_id) < String(right.recipe_id)


static func _mainline_less_than(
	left: MainlineProgressionDefinitionScript,
	right: MainlineProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _optional_less_than(
	left: OptionalProgressionDefinitionScript,
	right: OptionalProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _reward_less_than(
	left: PermanentGrowthRewardDefinitionScript,
	right: PermanentGrowthRewardDefinitionScript,
) -> bool:
	var left_id := String(left.reward_id)
	var right_id := String(right.reward_id)
	if left_id != right_id:
		return left_id < right_id
	if left.stat_kind != right.stat_kind:
		return left.stat_kind < right.stat_kind
	return left.increase < right.increase


static func _route_contract_less_than(
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
