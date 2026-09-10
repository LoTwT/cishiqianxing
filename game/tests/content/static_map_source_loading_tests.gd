extends RefCounted

const Builder := preload("res://src/content/content_registry_builder.gd")
const Manifest := preload("res://src/content/definitions/content_manifest_resource.gd")
const MapDefinition := preload("res://src/content/definitions/static_map_definition_resource.gd")
const Issue := preload("res://src/content/content_validation_issue.gd")
const Initializer := preload("res://src/rules/static_map_initializer.gd")
const Player := preload("res://src/rules/player_progression_state.gd")
const Inventory := preload("res://src/rules/portable_inventory_state.gd")
const Oracle := preload("res://tests/content/static_map_catalog_oracle.gd")
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")

const MAP_PATH: String = "res://content/maps/static_initialization_acceptance.tres"
const CATALOG_PATH: String = "res://content/maps/static_map_catalog.tres"
const SOURCE_FIELDS: Array[StringName] = [&"terrain_effect_ids", &"dynamic_behavior_ids", &"other_entity_ids"]


func cases() -> Array[Case]:
	return [
		Case.new("static_map_sources.loads_explicit_empty_declarations", _loads_explicit_empty_declarations),
		Case.new("static_map_sources.rejects_loaded_scalar_declarations", _rejects_loaded_scalar_declarations),
		Case.new("static_map_sources.rejects_loaded_array_types", _rejects_loaded_array_types),
		Case.new("static_map_sources.rejects_missing_and_repeated_declarations", _rejects_missing_and_repeated_declarations),
		Case.new("static_map_sources.rejects_well_typed_unsupported_ids", _rejects_well_typed_unsupported_ids),
		Case.new("static_map_sources.preserves_roundtrip_and_cache_isolation", _preserves_roundtrip_and_cache_isolation),
		Case.new("static_map_sources.seals_declaration_validity", _seals_declaration_validity),
	]


func _loads_explicit_empty_declarations(context: Context) -> void:
	_with_map_text(context, FileAccess.get_file_as_string(MAP_PATH), _expect_accepted)


func _rejects_loaded_scalar_declarations(context: Context) -> void:
	for field: StringName in SOURCE_FIELDS:
		for literal: String in ["42", "&\"enemy.behavior.patrol\""]:
			var original: String = "%s = Array[StringName]([])" % field
			var replacement: String = "%s = %s" % [field, literal]
			var text: String = FileAccess.get_file_as_string(MAP_PATH).replace(original, replacement)
			_with_map_text(context, text, _expect_rejected.bind(field, literal))


func _rejects_loaded_array_types(context: Context) -> void:
	for field: StringName in SOURCE_FIELDS:
		for literal: String in ["null", "{}", "Array[int]([])", "Array[String]([])", "[&\"unsupported.source\", 42]", "[\"unsupported.source\"]"]:
			var original: String = "%s = Array[StringName]([])" % field
			var text: String = FileAccess.get_file_as_string(MAP_PATH).replace(original, "%s = %s" % [field, literal])
			_with_map_text(context, text, _expect_rejected.bind(field, literal))


func _rejects_missing_and_repeated_declarations(context: Context) -> void:
	for field: StringName in SOURCE_FIELDS:
		var original: String = "%s = Array[StringName]([])" % field
		var malformed: String = "%s = &\"enemy.behavior.patrol\"" % field
		for replacement: String in ["", original + "\n" + malformed, malformed + "\n" + original, original + "\n" + original]:
			var text: String = FileAccess.get_file_as_string(MAP_PATH).replace(original, replacement)
			_with_map_text(context, text, _expect_rejected.bind(field, replacement))


func _rejects_well_typed_unsupported_ids(context: Context) -> void:
	for field: StringName in SOURCE_FIELDS:
		var original: String = "%s = Array[StringName]([])" % field
		var text: String = FileAccess.get_file_as_string(MAP_PATH).replace(original, "%s = Array[StringName]([&\"enemy.behavior.patrol\"])" % field)
		_with_map_text(context, text, _expect_unsupported)


func _preserves_roundtrip_and_cache_isolation(context: Context) -> void:
	_with_map_text(context, FileAccess.get_file_as_string(MAP_PATH), _check_roundtrip_and_cache)


func _seals_declaration_validity(context: Context) -> void:
	for field: StringName in SOURCE_FIELDS:
		var built := Builder.build_canonical()
		context.expect_true(built.succeeded(), "Validity drift starts from real sealed resources.")
		if not built.succeeded():
			continue
		var registry := built.registry()
		var published := registry.lookup_static_map(Oracle.MAP_ID)
		registry._static_map_catalog.maps[0].set(field, 42)
		context.expect_true(not registry.is_initialized(), "Malformed redeclaration invalidates the seal even when ID values are still empty.")
		context.expect_equal(registry.lookup_static_map(Oracle.MAP_ID).definition(), null, "Invalid declaration publishes no map.")
		context.expect_true(published.definition().source_declarations_are_valid(), "Earlier query snapshot is isolated from declaration validity drift.")


func _with_map_text(context: Context, map_text: String, check: Callable) -> void:
	# 只写本次进程独占的系统缓存目录；不写规范资源或正式 user://。
	var directory: String = OS.get_cache_dir().path_join("cishiqianxing-map-sources-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	var created: Error = DirAccess.make_dir_absolute(directory)
	context.expect_equal(created, OK, "Create isolated native Resource fixture directory.")
	if created != OK:
		return
	var map_path: String = directory.path_join("map.tres")
	var catalog_path: String = directory.path_join("catalog.tres")
	var manifest_path: String = directory.path_join("manifest.tres")
	var catalog_text: String = FileAccess.get_file_as_string(CATALOG_PATH).replace(MAP_PATH, map_path)
	var manifest_text: String = FileAccess.get_file_as_string(Builder.CANONICAL_MANIFEST_PATH).replace(CATALOG_PATH, catalog_path)
	var wrote_map: bool = _write_fixture(context, map_path, map_text)
	var wrote_catalog: bool = _write_fixture(context, catalog_path, catalog_text)
	var wrote_manifest: bool = _write_fixture(context, manifest_path, manifest_text)
	if wrote_map and wrote_catalog and wrote_manifest:
		var manifest := ResourceLoader.load(manifest_path, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Manifest
		context.expect_true(manifest != null, "The actual .tres manifest must load through native ResourceLoader.")
		if manifest != null:
			check.call(context, manifest)
	for path: String in [manifest_path, catalog_path, map_path, directory.path_join("roundtrip.tres")]:
		if FileAccess.file_exists(path):
			context.expect_equal(DirAccess.remove_absolute(path), OK, "Remove only this fixture's file.")
	context.expect_equal(DirAccess.remove_absolute(directory), OK, "Remove empty fixture directory.")


func _write_fixture(context: Context, path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	context.expect_true(file != null, "Write native Resource fixture.")
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _expect_accepted(context: Context, manifest: Manifest) -> void:
	var built := Builder.build(manifest)
	context.expect_true(built.succeeded(), "Explicit empty declarations must register with the unchanged v6 seal.")
	if not built.succeeded():
		return
	var initialized := Initializer.initialize(Oracle.MAP_ID, Player.create(&"progression.player.loer", 6, 6, 149, Oracle.mainline_rewards()), Inventory.create(6, 6, 20, 0, []), built.registry())
	context.expect_true(initialized.succeeded(), "Explicit empty declarations must initialize.")
	if initialized.succeeded():
		context.expect_true(initialized.world_state().stage_inputs().complete(), "Valid declaration proves complete stages.")
		context.expect_equal(initialized.world_state().grid_state().world_step(), 0, "Loading does not advance the world.")


func _expect_rejected(context: Context, manifest: Manifest, field: StringName, literal: String) -> void:
	var label: String = "%s = %s" % [field, literal]
	var built := Builder.build(manifest)
	context.expect_true(not built.succeeded(), label + " must reject before publication.")
	context.expect_equal(built.registry(), null, label + " exposes no registry.")
	var matching_issue: bool = false
	for issue: Issue in built.validation_report().issues():
		if issue.code() == &"map.sources.invalid" and issue.field_path() == String(field):
			matching_issue = true
	context.expect_true(matching_issue, label + " reports the invalid declaration field.")
	var initialized := Initializer.initialize(Oracle.MAP_ID, Player.create(&"progression.player.loer", 6, 6, 149, Oracle.mainline_rewards()), Inventory.create(6, 6, 20, 0, []), built.registry())
	context.expect_true(not initialized.succeeded(), label + " cannot initialize a world.")
	context.expect_equal(initialized.world_state(), null, label + " exposes no partial world.")
	context.expect_equal(initialized.domain_events(), [], label + " emits no event.")
	var snapshot := MapDefinition.snapshot(manifest.static_map_catalog.maps[0])
	context.expect_true(not snapshot.source_declarations_are_valid(), label + " cannot be laundered by a defensive snapshot.")
	var fields := snapshot.invalid_source_declaration_fields()
	context.expect_equal(fields, [field], label + " identifies exactly one invalid source field.")
	fields.clear()
	context.expect_equal(snapshot.invalid_source_declaration_fields(), [field], label + " owns its diagnostics.")
	var path: String = manifest.resource_path.get_base_dir().path_join("roundtrip.tres")
	context.expect_equal(ResourceSaver.save(snapshot, path), OK, "Native saver can preserve an invalid declaration for rejection.")
	var reloaded := ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as MapDefinition
	context.expect_true(reloaded != null, "Invalid saved definition loads as a Resource without engine errors.")
	if reloaded != null:
		context.expect_true(not reloaded.source_declarations_are_valid(), "Saving and reloading cannot turn an invalid declaration into a valid empty list.")


func _expect_unsupported(context: Context, manifest: Manifest) -> void:
	var definition: MapDefinition = manifest.static_map_catalog.maps[0]
	context.expect_true(definition.source_declarations_are_valid(), "Well-typed arrays are valid declarations before unsupported-effect checks.")
	var built := Builder.build(manifest)
	context.expect_true(not built.succeeded(), "Well-typed unsupported IDs must reject.")
	context.expect_equal(built.registry(), null, "Unsupported IDs publish no registry.")
	var found: bool = false
	for issue: Issue in built.validation_report().issues():
		if issue.code() == &"map.content.unsupported":
			found = true
	context.expect_true(found, "Well-typed patrol ID receives the existing unsupported-content diagnostic.")


func _check_roundtrip_and_cache(context: Context, manifest: Manifest) -> void:
	_expect_accepted(context, manifest)
	var definition: MapDefinition = manifest.static_map_catalog.maps[0]
	definition.terrain_effect_ids_snapshot().append(&"unsupported.terrain")
	definition.dynamic_behavior_ids_snapshot().append(&"unsupported.behavior")
	definition.other_entity_ids_snapshot().append(&"unsupported.entity")
	for field: StringName in SOURCE_FIELDS:
		var serialized: Array = definition.get(field)
		serialized.append(&"unsupported.alias")
	_expect_accepted(context, manifest)
	var path: String = manifest.resource_path.get_base_dir().path_join("roundtrip.tres")
	context.expect_equal(ResourceSaver.save(definition, path), OK, "Save explicit empty lists through native ResourceSaver.")
	var reloaded := ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as MapDefinition
	context.expect_true(reloaded != null, "Native roundtrip reloads.")
	if reloaded != null:
		manifest.static_map_catalog.maps[0] = reloaded
		_expect_accepted(context, manifest)
	var cached := ResourceLoader.load(definition.resource_path) as MapDefinition
	context.expect_true(cached != null, "Cache fixture loads.")
	if cached != null:
		cached.set(&"terrain_effect_ids", 42)
		context.expect_true(not cached.source_declarations_are_valid(), "Cache is poisoned with an invalid declaration.")
	var fresh := ResourceLoader.load(manifest.resource_path, "Resource", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Manifest
	context.expect_true(fresh != null, "Deep cache bypass reloads actual manifest references.")
	if fresh != null:
		_expect_accepted(context, fresh)
