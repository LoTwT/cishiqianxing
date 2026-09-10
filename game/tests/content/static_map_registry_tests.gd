extends RefCounted

const Builder := preload("res://src/content/content_registry_builder.gd")
const Registry := preload("res://src/content/content_registry.gd")
const Manifest := preload("res://src/content/definitions/content_manifest_resource.gd")
const MapCatalog := preload("res://src/content/definitions/static_map_catalog_resource.gd")
const MapDefinition := preload("res://src/content/definitions/static_map_definition_resource.gd")
const Placement := preload("res://src/content/definitions/map_enemy_placement_resource.gd")
const MapValidator := preload("res://src/content/static_map_validator.gd")
const Issue := preload("res://src/content/content_validation_issue.gd")
const BuildResult := preload("res://src/content/content_registry_build_result.gd")
const Fingerprint := preload("res://src/content/content_contract_fingerprint.gd")
const Fixture := preload("res://tests/support/canonical_registry_fixture.gd")
const Oracle := preload("res://tests/content/static_map_catalog_oracle.gd")
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")

class DerivedCatalog extends MapCatalog:
	pass

class DerivedMap extends MapDefinition:
	pass

class DerivedPlacement extends Placement:
	pass


func cases() -> Array[Case]:
	return [
		Case.new("static_maps.loads_literal_catalog", _loads_literal_catalog),
		Case.new("static_maps.rejects_resource_types", _rejects_resource_types),
		Case.new("static_maps.rejects_identifiers", _rejects_identifiers),
		Case.new("static_maps.rejects_geometry_and_occupancy", _rejects_geometry_and_occupancy),
		Case.new("static_maps.rejects_references_and_chapters", _rejects_references_and_chapters),
		Case.new("static_maps.rechecks_actual_chapter_balance", _rechecks_actual_chapter_balance),
		Case.new("static_maps.rejects_unsupported_content", _rejects_unsupported_content),
		Case.new("static_maps.fingerprints_every_map_field", _fingerprints_every_map_field),
		Case.new("static_maps.orders_maps_cells_and_issues", _orders_maps_cells_and_issues),
		Case.new("static_maps.isolates_snapshots_and_resource_cache", _isolates_snapshots_and_resource_cache),
		Case.new("static_maps.rejects_v5_and_content_drift", _rejects_v5_and_content_drift),
		Case.new("static_maps.accepts_empty_enemy_set_and_integer_bounds", _accepts_empty_enemy_set_and_integer_bounds),
	]


func _manifest() -> Manifest:
	return ResourceLoader.load(Builder.CANONICAL_MANIFEST_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Manifest


func _registry(context: Context) -> Registry:
	var result := Fixture.canonical_registry(context, "Static map catalog")
	context.expect_true(result != null and result.is_initialized(), "Content tests require the actual sealed manifest.")
	return result


func _loads_literal_catalog(context: Context) -> void:
	var built := Builder.build_canonical()
	context.expect_true(built.succeeded(), "Actual .tres manifest must build.")
	if not built.succeeded():
		return
	var registry := built.registry()
	context.expect_equal(registry.schema_version(), 6, "Schema v6.")
	context.expect_equal(registry.content_version(), 6, "Content v6.")
	context.expect_equal(registry.static_map_ids(), [Oracle.MAP_ID], "Explicit manifest map membership.")
	context.expect_equal(registry.static_map_catalog().catalog_id, Oracle.CATALOG_ID, "Catalog ID.")
	var query := registry.lookup_static_map(Oracle.MAP_ID)
	context.expect_true(query.succeeded(), "Canonical map query must succeed.")
	if not query.succeeded():
		return
	var definition := query.definition()
	context.expect_equal(definition.map_id, Oracle.MAP_ID, "Map ID.")
	context.expect_equal(definition.space_id, Oracle.SPACE_ID, "Space ID.")
	context.expect_equal(definition.chapter, 6, "Technical sample chapter.")
	context.expect_equal(definition.grid_cells, Oracle.GRID_CELLS, "Independent grid literal.")
	context.expect_equal(definition.blocked_cells, Oracle.BLOCKED_CELLS, "Independent blocker literal.")
	context.expect_equal(definition.player_spawn_cell, Oracle.PLAYER_SPAWN, "Player spawn literal.")
	context.expect_equal(definition.enemies.size(), 2, "Two explicit enemy placements.")
	for index: int in range(mini(2, definition.enemies.size())):
		var placement: Placement = definition.enemies[index]
		context.expect_equal(placement.instance_id, Oracle.INSTANCE_IDS[index], "Instance ID literal.")
		context.expect_equal(placement.profile_id, Oracle.PROFILE_IDS[index], "Central profile reference literal.")
		context.expect_equal(placement.cell, Oracle.ENEMY_CELLS[index], "Placement literal.")
		for property: Dictionary in placement.get_property_list():
			context.expect_true(not String(property.name) in ["attack", "defense", "speed", "maximum_durability", "behavior_id", "combat_trait_ids", "shield_intact"], "Placements expose no enemy overrides.")
	var missing := registry.lookup_static_map(&"map.unknown")
	context.expect_true(not missing.succeeded(), "Unknown map is structured failure.")
	context.expect_equal(missing.definition(), null, "Unknown map has no definition.")
	context.expect_equal(missing.issue().code(), Issue.LOOKUP_UNKNOWN_MAP_ID, "Unknown map issue.")
	var unsealed := Registry.new().lookup_static_map(Oracle.MAP_ID)
	context.expect_equal(unsealed.issue().code(), Issue.LOOKUP_REGISTRY_UNINITIALIZED, "Unsealed query fails.")


func _rejects_resource_types(context: Context) -> void:
	var manifest := _manifest()
	var issues: Array[Issue] = []
	context.expect_equal(MapValidator.snapshot_and_validate(Resource.new(), manifest.enemy_profile_catalog, manifest.representative_route_contract_catalog, issues), null, "Wrong catalog type fails structurally.")
	context.expect_true(_codes(issues).has(Issue.MAP_INVALID_RESOURCE), "Wrong type reports issue.")
	context.expect_true(not MapDefinition.has_exact_entry_types(Resource.new()), "Wrong map type rejected without reading.")
	for variant: int in range(7):
		manifest = _manifest()
		match variant:
			0: manifest.static_map_catalog = null
			1: manifest.static_map_catalog = DerivedCatalog.new()
			2: manifest.static_map_catalog.maps[0] = null
			3: manifest.static_map_catalog.maps[0] = DerivedMap.new()
			4: manifest.static_map_catalog.maps[0].enemies[0] = null
			5: manifest.static_map_catalog.maps[0].enemies[0] = DerivedPlacement.new()
			6: manifest.static_map_catalog.maps[0].enemies.append(null)
		_expect_failure(context, manifest, Issue.MAP_INVALID_RESOURCE, "Exact resource variant %d" % variant)
	manifest = _manifest()
	manifest.static_map_catalog.maps.clear()
	_expect_failure(context, manifest, Issue.MAP_CATALOG_INVALID, "Empty catalog")
	manifest = _manifest()
	manifest.static_map_catalog.catalog_id = &"unknown"
	_expect_failure(context, manifest, Issue.MAP_CATALOG_INVALID, "Unknown catalog identity")


func _rejects_identifiers(context: Context) -> void:
	for invalid_id: StringName in [&"", &" ", &"中文", &"---", &"a/b", StringName("a".repeat(129))]:
		for field: StringName in [&"map_id", &"space_id", &"instance_id"]:
			var manifest := _manifest()
			var definition: MapDefinition = manifest.static_map_catalog.maps[0]
			if field == &"instance_id":
				definition.enemies[0].instance_id = invalid_id
			else:
				definition.set(field, invalid_id)
			var code: StringName = Issue.MAP_INSTANCE_ID_INVALID if field == &"instance_id" else (Issue.MAP_ID_INVALID if field == &"map_id" else Issue.MAP_SPACE_ID_INVALID)
			_expect_failure(context, manifest, code, "Invalid %s: %s" % [field, invalid_id])
	for variant: int in range(5):
		var manifest := _manifest()
		var definition: MapDefinition = manifest.static_map_catalog.maps[0]
		var duplicate := MapDefinition.snapshot(definition)
		var code: StringName = Issue.MAP_INSTANCE_ID_INVALID
		match variant:
			0:
				manifest.static_map_catalog.maps.append(duplicate)
				code = Issue.MAP_ID_INVALID
			1:
				duplicate.map_id = &"map.another"
				manifest.static_map_catalog.maps.append(duplicate)
				code = Issue.MAP_SPACE_ID_INVALID
			2: definition.enemies[1].instance_id = definition.enemies[0].instance_id
			3: definition.enemies[0].instance_id = Oracle.PLAYER_ID
			4:
				duplicate.map_id = &"map.another"
				duplicate.space_id = &"space.another"
				manifest.static_map_catalog.maps.append(duplicate)
		_expect_failure(context, manifest, code, "Duplicate or player-conflicting ID %d" % variant)


func _rejects_geometry_and_occupancy(context: Context) -> void:
	for variant: int in range(12):
		var manifest := _manifest()
		var definition: MapDefinition = manifest.static_map_catalog.maps[0]
		match variant:
			0: definition.grid_cells.clear()
			1: definition.grid_cells.append(definition.grid_cells[0])
			2: definition.grid_cells.append(Vector3i(0, 1, 0))
			3: definition.blocked_cells.append(Vector3i(99, 0, 0))
			4: definition.blocked_cells.append(definition.blocked_cells[0])
			5: definition.player_spawn_cell = Vector3i(99, 0, 0)
			6: definition.player_spawn_cell = definition.blocked_cells[0]
			7: definition.enemies[0].cell = Vector3i(99, 0, 0)
			8: definition.enemies[0].cell = definition.blocked_cells[0]
			9: definition.enemies[0].cell = definition.player_spawn_cell
			10: definition.enemies[1].cell = definition.enemies[0].cell
			11: definition.player_spawn_cell = Vector3i(0, 1, 0)
		_expect_failure(context, manifest, Issue.MAP_GEOMETRY_INVALID, "Geometry / occupancy %d" % variant)


func _rejects_references_and_chapters(context: Context) -> void:
	for profile_id: StringName in [&"", &"enemy.profile.unknown"]:
		var manifest := _manifest()
		manifest.static_map_catalog.maps[0].enemies[0].profile_id = profile_id
		_expect_failure(context, manifest, Issue.MAP_REFERENCE_INVALID, "Unknown profile")
	for chapter: int in [0, -1, 10, 4]:
		var manifest := _manifest()
		manifest.static_map_catalog.maps[0].chapter = chapter
		_expect_failure(context, manifest, Issue.MAP_CHAPTER_INVALID, "Invalid / too early chapter %d" % chapter)


func _rechecks_actual_chapter_balance(context: Context) -> void:
	var registry := _registry(context)
	if registry == null:
		return
	var catalog := registry.static_map_catalog()
	var issues: Array[Issue] = []
	MapValidator.validate_balance(registry, catalog, issues)
	context.expect_equal(issues.size(), 0, "Chapter 6 actual profiles satisfy all balance checks.")
	catalog.maps[0].chapter = 5
	issues.clear()
	# F03 enhanced at chapter 5: enemy first, seven hits cost 35 / 150, still legal.
	# F09 enhanced: 30 / (14-9) = 6 damaging attacks, still legal.
	MapValidator.validate_balance(registry, catalog, issues)
	context.expect_equal(issues.size(), 0, "Legal first chapter of stage group remains supported.")
	catalog.maps[0].chapter = 3
	catalog.maps[0].enemies[0].profile_id = &"enemy.profile.f09.base"
	catalog.maps[0].enemies.resize(1)
	issues.clear()
	# Chapter 3 attack 12 vs defense 8 needs 6 damaging attacks; base maximum is 5.
	MapValidator.validate_balance(registry, catalog, issues)
	context.expect_true(_codes(issues).has(Issue.MAP_BALANCE_INVALID), "Actual chapter must reject six damaging attacks for a base profile.")
	context.expect_true(issues.any(func(issue: Issue) -> bool: return issue.message().contains("enemy.profile.attack_count")), "Rejection comes from the reused combat balance rule.")
	catalog.maps[0].chapter = 4
	issues.clear()
	MapValidator.validate_balance(registry, catalog, issues)
	context.expect_equal(issues.size(), 0, "Same central profile becomes legal in chapter 4.")


func _rejects_unsupported_content(context: Context) -> void:
	for field: StringName in [&"terrain_effect_ids", &"dynamic_behavior_ids", &"other_entity_ids"]:
		var manifest := _manifest()
		var sources: Array[StringName] = [&"unsupported.source"]
		manifest.static_map_catalog.maps[0].set("_" + String(field), sources)
		_expect_failure(context, manifest, Issue.MAP_UNSUPPORTED_CONTENT, "Unsupported " + String(field))
	for profile_id: StringName in [&"enemy.profile.f01.base", &"enemy.profile.f02.base", &"enemy.profile.f04.base", &"enemy.profile.f05.base", &"enemy.profile.f06.base"]:
		var manifest := _manifest()
		manifest.static_map_catalog.maps[0].enemies[0].profile_id = profile_id
		_expect_failure(context, manifest, Issue.MAP_UNSUPPORTED_CONTENT, "Dynamic profile " + String(profile_id))


func _fingerprints_every_map_field(context: Context) -> void:
	var baseline := _fingerprint(_manifest())
	context.expect_equal(baseline, "fda9b0dd286340a6ff9eb4a523c2220e6fce7bf7d34f4743b77856d0fed2bc96", "Independent v6 digest.")
	for variant: int in range(14):
		var manifest := _manifest()
		var definition: MapDefinition = manifest.static_map_catalog.maps[0]
		match variant:
			0: manifest.static_map_catalog.catalog_id = &"map.changed"
			1: definition.map_id = &"map.changed"
			2: definition.space_id = &"space.changed"
			3: definition.chapter = 5
			4: definition.grid_cells.append(Vector3i(4, 0, 0))
			5: definition.blocked_cells.append(Vector3i(3, 0, 0))
			6: definition.player_spawn_cell = Vector3i(-1, 0, 0)
			7: definition.enemies[0].instance_id = &"enemy.changed"
			8: definition.enemies[0].profile_id = &"enemy.profile.f09.enhanced"
			9: definition.enemies[0].cell = Vector3i(3, 0, 0)
			10: definition._terrain_effect_ids.append(&"terrain.unknown")
			11: definition._dynamic_behavior_ids.append(&"behavior.unknown")
			12: definition._other_entity_ids.append(&"entity.unknown")
			13: manifest.static_map_catalog.maps.append(MapDefinition.snapshot(definition))
		context.expect_true(_fingerprint(manifest) != baseline, "Fingerprint covers map field %d." % variant)


func _orders_maps_cells_and_issues(context: Context) -> void:
	var manifest := _manifest()
	var baseline := _fingerprint(manifest)
	manifest.static_map_catalog.maps[0].grid_cells.reverse()
	manifest.static_map_catalog.maps[0].blocked_cells.reverse()
	manifest.static_map_catalog.maps[0].enemies.reverse()
	context.expect_equal(_fingerprint(manifest), baseline, "Cell / enemy sets have deterministic seal.")
	var built := Builder.build(manifest)
	context.expect_true(built.succeeded(), "Reordered actual resources must build.")
	if built.succeeded():
		context.expect_equal(built.registry().lookup_static_map(Oracle.MAP_ID).definition().grid_cells, Oracle.GRID_CELLS, "Published grid is canonical.")
	var second := MapDefinition.snapshot(manifest.static_map_catalog.maps[0])
	second.map_id = &"map.a"
	second.space_id = &"space.a"
	second.enemies.clear()
	manifest.static_map_catalog.maps.append(second)
	var forward := _fingerprint(manifest)
	manifest.static_map_catalog.maps.reverse()
	context.expect_equal(_fingerprint(manifest), forward, "Map catalog order is not content.")
	var issues: Array[Issue] = []
	var captured := MapValidator.snapshot_and_validate(manifest.static_map_catalog, manifest.enemy_profile_catalog, manifest.representative_route_contract_catalog, issues)
	context.expect_true(captured != null, "Valid multiple definitions pass structural checks.")
	context.expect_equal(issues.size(), 0, "No structural errors in reordered catalog.")
	if captured != null:
		context.expect_equal(captured.maps[0].map_id, &"map.a", "Snapshots sort maps by stable ID.")
	manifest.static_map_catalog.maps[0].chapter = 0
	manifest.static_map_catalog.maps[1].space_id = &""
	var before := Builder.build(manifest).validation_report().issues()
	manifest.static_map_catalog.maps.reverse()
	var after := Builder.build(manifest).validation_report().issues()
	context.expect_true(not before.is_empty(), "Error ordering comparison has real failures.")
	context.expect_equal(before.size(), after.size(), "Error count ignores declaration order.")
	for index: int in range(mini(before.size(), after.size())):
		context.expect_true(before[index].is_equal_to(after[index]), "Stable structured error ordering.")


func _isolates_snapshots_and_resource_cache(context: Context) -> void:
	var manifest := _manifest()
	var built := Builder.build(manifest)
	context.expect_true(built.succeeded(), "Snapshot fixture must build.")
	if not built.succeeded():
		return
	var registry := built.registry()
	var query := registry.lookup_static_map(Oracle.MAP_ID)
	manifest.static_map_catalog.maps[0].enemies[0].profile_id = &"enemy.unknown"
	manifest.static_map_catalog.maps[0].grid_cells.clear()
	var definition := query.definition()
	definition.enemies[0].cell = Vector3i(77, 0, 0)
	definition.grid_cells.clear()
	var catalog := registry.static_map_catalog()
	catalog.maps[0].enemies.clear()
	var ids := registry.static_map_ids()
	ids.clear()
	context.expect_true(registry.is_initialized(), "Input and query mutations leave registry sealed.")
	context.expect_equal(query.definition().grid_cells, Oracle.GRID_CELLS, "Existing query owns its own snapshot.")
	context.expect_equal(query.definition().enemies[0].cell, Oracle.ENEMY_CELLS[0], "Nested query snapshots are isolated.")
	context.expect_equal(registry.static_map_ids(), [Oracle.MAP_ID], "ID output is defensive.")
	var scope := registry._begin_verified_read_scope()
	context.expect_true(scope != null, "Map content enters an independent verified read scope.")
	if scope != null:
		registry._static_map_catalog.maps[0].grid_cells.clear()
		context.expect_true(not registry.is_initialized(), "Source map drift invalidates only the source seal.")
		context.expect_equal(scope._registry.lookup_static_map(Oracle.MAP_ID).definition().grid_cells, Oracle.GRID_CELLS, "Scope owns independent nested map Resources.")
		context.expect_true(scope._close(), "Untouched captured map passes closing validation.")
		context.expect_equal(query.definition().grid_cells, Oracle.GRID_CELLS, "Already published map query remains isolated from source drift.")
	var cached := ResourceLoader.load(Builder.CANONICAL_MANIFEST_PATH) as Manifest
	var original_cell: Vector3i = cached.static_map_catalog.maps[0].enemies[0].cell
	cached.static_map_catalog.maps[0].enemies[0].cell = Vector3i(88, 0, 0)
	var fresh := Builder.build_canonical()
	cached.static_map_catalog.maps[0].enemies[0].cell = original_cell
	context.expect_true(fresh.succeeded(), "Canonical loader ignores mutable Resource cache deeply.")
	if fresh.succeeded():
		context.expect_equal(fresh.registry().lookup_static_map(Oracle.MAP_ID).definition().enemies[0].cell, Oracle.ENEMY_CELLS[0], "Disk placement survives cache poisoning.")


func _rejects_v5_and_content_drift(context: Context) -> void:
	for field: StringName in [&"schema_version", &"content_version"]:
		var manifest := _manifest()
		manifest.set(field, 5)
		_expect_failure(context, manifest, Issue.MANIFEST_SCHEMA_VERSION_UNSUPPORTED if field == &"schema_version" else Issue.MANIFEST_CONTENT_VERSION_UNSUPPORTED, "Old v5 " + String(field))
	var drifted := _manifest()
	drifted.static_map_catalog.maps[0].player_spawn_cell = Vector3i(-1, 0, 0)
	_expect_failure(context, drifted, Issue.MANIFEST_CONTRACT_FINGERPRINT_MISMATCH, "Structurally legal content drift")
	var built := Builder.build_canonical()
	context.expect_true(built.succeeded(), "Registry drift fixture must build.")
	if not built.succeeded():
		return
	var registry := built.registry()
	registry._static_map_catalog.maps[0].enemies[0].cell = Vector3i(3, 0, 0)
	context.expect_true(not registry.is_initialized(), "Internal placement drift invalidates the full seal.")
	context.expect_true(not built.succeeded(), "Build result observes content drift.")
	context.expect_equal(registry.lookup_static_map(Oracle.MAP_ID).definition(), null, "No map leaks from drifted content.")
	context.expect_equal(registry.static_map_catalog(), null, "No partial catalog on drift.")


func _accepts_empty_enemy_set_and_integer_bounds(context: Context) -> void:
	var manifest := _manifest()
	var definition: MapDefinition = manifest.static_map_catalog.maps[0]
	definition.enemies.clear()
	definition.map_id = StringName("m".repeat(128))
	definition.space_id = StringName("s".repeat(128))
	definition.player_spawn_cell = Vector3i(-2147483648, 17, 2147483647)
	definition.grid_cells = [definition.player_spawn_cell]
	definition.blocked_cells.clear()
	var issues: Array[Issue] = []
	var captured := MapValidator.snapshot_and_validate(manifest.static_map_catalog, manifest.enemy_profile_catalog, manifest.representative_route_contract_catalog, issues)
	context.expect_true(captured != null, "Empty enemies, 128-character IDs and Vector3i extremes are valid static structure.")
	context.expect_equal(issues.size(), 0, "No artificial origin or coordinate limits.")
	if captured != null:
		context.expect_equal(captured.maps[0].player_spawn_cell, definition.player_spawn_cell, "Integer coordinates remain exact.")


func _expect_failure(context: Context, manifest: Manifest, code: StringName, label: String) -> void:
	var result: BuildResult = Builder.build(manifest)
	context.expect_true(not result.succeeded(), label + " must fail.")
	context.expect_equal(result.registry(), null, label + " must publish no partial registry.")
	context.expect_true(_codes(result.validation_report().issues()).has(code), "%s must report %s; got %s." % [label, code, str(_codes(result.validation_report().issues()))])


func _codes(issues: Array[Issue]) -> Array[StringName]:
	var result: Array[StringName] = []
	for issue: Issue in issues:
		result.append(issue.code())
	return result


func _fingerprint(manifest: Manifest) -> String:
	return Fingerprint.calculate(manifest.schema_version, manifest.content_version, manifest.blueprints, manifest.recipes, manifest.global_progression_catalog, manifest.representative_route_contract_catalog, manifest.enemy_profile_catalog, manifest.static_map_catalog)
