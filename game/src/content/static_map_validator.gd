class_name StaticMapValidator
extends RefCounted

const StaticMapCatalogScript := preload("res://src/content/definitions/static_map_catalog_resource.gd")
const StaticMapDefinitionScript := preload("res://src/content/definitions/static_map_definition_resource.gd")
const MapEnemyPlacementScript := preload("res://src/content/definitions/map_enemy_placement_resource.gd")
const EnemyProfileCatalogScript := preload("res://src/content/definitions/enemy_profile_catalog_resource.gd")
const EnemyProfileDefinitionScript := preload("res://src/content/definitions/enemy_profile_definition_resource.gd")
const RepresentativeRouteCatalogScript := preload("res://src/content/definitions/representative_route_contract_catalog_resource.gd")
const RepresentativeRouteContractScript := preload("res://src/content/definitions/representative_route_contract_resource.gd")
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentValidationIssueScript := preload("res://src/content/content_validation_issue.gd")
const ContentValidationSupportScript := preload("res://src/content/content_validation_support.gd")
const EnemyProfileValidatorScript := preload("res://src/content/enemy_profile_validator.gd")
const WorldStepStaticScenarioScript := preload("res://src/rules/world_step_static_scenario.gd")
const WorldStepContactCommandScript := preload("res://src/rules/world_step_contact_command.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const EnemyWorldAddressScript := preload("res://src/rules/enemy_world_address.gd")
const EnemyInstanceStateScript := preload("res://src/rules/enemy_instance_state.gd")

const ContentContractConstantsScript := preload("res://src/content/content_contract_constants.gd")

const EXPECTED_CATALOG_ID: StringName = &"map.catalog.static"
const PLAYER_ID: StringName = WorldStepContactCommandScript.AUTHORITATIVE_PLAYER_ACTOR_ID


static func snapshot_and_validate(
	raw_catalog: Resource,
	enemy_catalog: EnemyProfileCatalogScript,
	route_catalog: RepresentativeRouteCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> StaticMapCatalogScript:
	var before: int = issues.size()
	if not StaticMapCatalogScript.has_exact_entry_types(raw_catalog):
		_issue(issues, ContentValidationIssueScript.MAP_INVALID_RESOURCE, &"", "static_map_catalog", "Catalog, maps and placements must use non-null exact authoritative scripts.")
		return null
	var catalog := StaticMapCatalogScript.snapshot(raw_catalog as StaticMapCatalogScript)
	if catalog.catalog_id != EXPECTED_CATALOG_ID or catalog.maps.is_empty():
		_issue(issues, ContentValidationIssueScript.MAP_CATALOG_INVALID, catalog.catalog_id, "static_map_catalog", "A static map catalog needs the declared catalog ID and at least one map.")
	if enemy_catalog == null or route_catalog == null:
		_issue(issues, ContentValidationIssueScript.MAP_REFERENCE_INVALID, catalog.catalog_id, "static_map_catalog", "Map validation requires validated central enemy and chapter catalogs.")
		return null
	var profiles: Dictionary[StringName, EnemyProfileDefinitionScript] = {}
	for profile: EnemyProfileDefinitionScript in enemy_catalog.profiles:
		profiles[profile.profile_id] = profile
	var contracts: Dictionary[StringName, RepresentativeRouteContractScript] = {}
	for contract: RepresentativeRouteContractScript in route_catalog.contracts:
		contracts[contract.contract_id] = contract
	var map_ids: Dictionary[StringName, bool] = {}
	var space_ids: Dictionary[StringName, bool] = {}
	var instance_ids: Dictionary[StringName, bool] = {}
	for definition: StaticMapDefinitionScript in catalog.maps:
		if not ValidationSupportScript.is_valid_identifier(definition.map_id, StaticMapDefinitionScript.MAXIMUM_MAP_ID_LENGTH) or map_ids.has(definition.map_id):
			_issue(issues, ContentValidationIssueScript.MAP_ID_INVALID, definition.map_id, "map_id", "Map IDs must be valid and unique in the catalog.")
		map_ids[definition.map_id] = true
		if not EnemyWorldAddressScript.is_valid_space_id(definition.space_id) or space_ids.has(definition.space_id):
			_issue(issues, ContentValidationIssueScript.MAP_SPACE_ID_INVALID, definition.map_id, "space_id", "Each map declares one valid, globally unique space ID.")
		space_ids[definition.space_id] = true
		if definition.chapter < 1 or definition.chapter > ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER:
			_issue(issues, ContentValidationIssueScript.MAP_CHAPTER_INVALID, definition.map_id, "chapter", "Map chapter must be between 1 and 9.")
		for field: StringName in definition.invalid_source_declaration_fields():
			_issue(issues, ContentValidationIssueScript.MAP_SOURCE_DECLARATION_INVALID, definition.map_id, String(field), "Source declarations must each occur once as an array of StringName IDs; missing, repeated or malformed declarations are invalid.")
		if not (definition.terrain_effect_ids_snapshot().is_empty() and definition.dynamic_behavior_ids_snapshot().is_empty() and definition.other_entity_ids_snapshot().is_empty()):
			_issue(issues, ContentValidationIssueScript.MAP_UNSUPPORTED_CONTENT, definition.map_id, "sources", "Terrain effects, dynamic behaviors and other entities have no v1 executor.")
		var positions: Dictionary[StringName, Vector3i] = {PLAYER_ID: definition.player_spawn_cell}
		for placement: MapEnemyPlacementScript in definition.enemies:
			var field: String = "enemies.%s" % String(placement.instance_id)
			if not EnemyInstanceStateScript.is_valid_instance_id(placement.instance_id) or instance_ids.has(placement.instance_id) or placement.instance_id == PLAYER_ID:
				_issue(issues, ContentValidationIssueScript.MAP_INSTANCE_ID_INVALID, definition.map_id, field, "Enemy IDs must be valid, globally unique and distinct from the authoritative player.")
			instance_ids[placement.instance_id] = true
			positions[placement.instance_id] = placement.cell
			if not profiles.has(placement.profile_id):
				_issue(issues, ContentValidationIssueScript.MAP_REFERENCE_INVALID, definition.map_id, field, "Enemy placement references an unknown central profile.")
				continue
			var profile: EnemyProfileDefinitionScript = profiles[placement.profile_id]
			if not contracts.has(profile.balance_contract_id) or definition.chapter < contracts[profile.balance_contract_id].stage_start_chapter:
				_issue(issues, ContentValidationIssueScript.MAP_CHAPTER_INVALID, definition.map_id, field, "Enemy placement precedes its balance contract stage group.")
			if not WorldStepStaticScenarioScript.has_no_pending_enemy_effects(profile.behavior_id, profile.has_alternate_state, profile.combat_trait_ids):
				_issue(issues, ContentValidationIssueScript.MAP_UNSUPPORTED_CONTENT, definition.map_id, field, "Enemy profile requires unsupported world-step effects.")
		# 复用整数格网的边界、重复格、阻挡和占格规则，保留具体诊断消息。
		var grid := GridRuleStateScript.create(definition.grid_cells, definition.blocked_cells, positions)
		for error: String in grid.validation_errors():
			_issue(issues, ContentValidationIssueScript.MAP_GEOMETRY_INVALID, definition.map_id, "grid", error)
		for cell: Vector3i in definition.grid_cells:
			if cell.y != definition.player_spawn_cell.y:
				_issue(issues, ContentValidationIssueScript.MAP_GEOMETRY_INVALID, definition.map_id, "grid_cells", "Every grid cell must lie on the player's horizontal plane.")
				break
	return catalog if before == issues.size() else null


static func validate_balance(
	registry: ContentRegistryScript,
	catalog: StaticMapCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if not ContentRegistryScript.is_exact_initialized_instance(registry) or not StaticMapCatalogScript.has_exact_entry_types(catalog):
		_issue(issues, ContentValidationIssueScript.MAP_BALANCE_INVALID, &"", "static_map_catalog", "Map balance requires sealed content and exact definitions.")
		return
	for definition: StaticMapDefinitionScript in catalog.maps:
		var checked: Dictionary[StringName, bool] = {}
		for placement: MapEnemyPlacementScript in definition.enemies:
			if checked.has(placement.profile_id):
				continue
			checked[placement.profile_id] = true
			var profile_issues: Array[ContentValidationIssueScript] = []
			EnemyProfileValidatorScript.validate_profile_at_chapter(registry, placement.profile_id, definition.chapter, profile_issues)
			for issue: ContentValidationIssueScript in profile_issues:
				_issue(issues, ContentValidationIssueScript.MAP_BALANCE_INVALID, definition.map_id, "enemies.%s.%s" % [String(placement.profile_id), issue.field_path()], "%s: %s" % [String(issue.code()), issue.message()])


static func _issue(issues: Array[ContentValidationIssueScript], code: StringName, map_id: StringName, field: String, message: String) -> void:
	ContentValidationSupportScript.add_issue(issues, code, map_id, field, message)
