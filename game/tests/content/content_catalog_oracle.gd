extends RefCounted

class BlueprintRow extends RefCounted:
	var content_id: StringName
	var ordinal: int
	var category: int
	var tier: int
	var unlock_chapter: int
	var default_lifecycle: int
	var standard_recipe_id: StringName
	var mechanic_id: StringName
	var display_name_text_id: StringName
	var function_text_id: StringName

	func _init(
		row_content_id: StringName,
		row_ordinal: int,
		row_category: int,
		row_tier: int,
		row_unlock_chapter: int,
		row_default_lifecycle: int,
		row_standard_recipe_id: StringName,
		row_mechanic_id: StringName,
		row_display_name_text_id: StringName,
		row_function_text_id: StringName,
	) -> void:
		content_id = row_content_id
		ordinal = row_ordinal
		category = row_category
		tier = row_tier
		unlock_chapter = row_unlock_chapter
		default_lifecycle = row_default_lifecycle
		standard_recipe_id = row_standard_recipe_id
		mechanic_id = row_mechanic_id
		display_name_text_id = row_display_name_text_id
		function_text_id = row_function_text_id


class RecipeRow extends RefCounted:
	var recipe_id: StringName
	var output_blueprint_id: StringName
	var main_material_id: StringName
	var main_quantity: int
	var auxiliary_material_id: StringName
	var auxiliary_quantity: int

	func _init(
		row_recipe_id: StringName,
		row_output_blueprint_id: StringName,
		row_main_material_id: StringName,
		row_main_quantity: int,
		row_auxiliary_material_id: StringName,
		row_auxiliary_quantity: int,
	) -> void:
		recipe_id = row_recipe_id
		output_blueprint_id = row_output_blueprint_id
		main_material_id = row_main_material_id
		main_quantity = row_main_quantity
		auxiliary_material_id = row_auxiliary_material_id
		auxiliary_quantity = row_auxiliary_quantity


static func blueprint_rows() -> Array[BlueprintRow]:
	return [
		_blueprint(1, 1, 1, 1, 1, "support_surface"),
		_blueprint(2, 1, 1, 1, 1, "height_connector"),
		_blueprint(3, 1, 1, 2, 1, "platform_extension"),
		_blueprint(4, 1, 1, 3, 1, "blocking_wall"),
		_blueprint(5, 1, 1, 2, 1, "environment_anchor"),
		_blueprint(6, 1, 2, 4, 1, "climbable_scaffold"),
		_blueprint(7, 1, 2, 7, 1, "anchored_platform_extension"),
		_blueprint(8, 2, 1, 1, 1, "occupancy_signal"),
		_blueprint(9, 2, 1, 3, 1, "toggle_signal"),
		_blueprint(10, 2, 1, 2, 1, "signal_conduit"),
		_blueprint(11, 2, 1, 5, 1, "one_step_delay"),
		_blueprint(12, 2, 1, 3, 1, "directional_push"),
		_blueprint(13, 2, 2, 5, 1, "same_step_sync"),
		_blueprint(14, 2, 2, 6, 1, "reciprocating_push"),
		_blueprint(15, 3, 1, 1, 2, "restore_health"),
		_blueprint(16, 3, 1, 2, 1, "survey_reveal"),
		_blueprint(17, 3, 1, 3, 2, "repair_target"),
		_blueprint(18, 3, 2, 7, 2, "restore_health_and_repair"),
		_blueprint(19, 4, 2, 5, 1, "survey_and_remote_recover"),
		_blueprint(20, 5, 1, 4, 2, "next_battle_attack"),
		_blueprint(21, 5, 1, 6, 2, "next_battle_defense"),
		_blueprint(22, 5, 1, 6, 2, "next_battle_speed"),
		_blueprint(23, 5, 2, 8, 2, "next_battle_attack_speed"),
		_blueprint(24, 5, 2, 8, 2, "next_battle_attack_defense"),
	]


static func recipe_rows() -> Array[RecipeRow]:
	return [
		_recipe(1, &"material.building", 3),
		_recipe(2, &"material.building", 3),
		_recipe(3, &"material.building", 3),
		_recipe(4, &"material.building", 3),
		_recipe(5, &"material.building", 3),
		_recipe(6, &"material.building", 4, &"material.mechanism_part", 2),
		_recipe(7, &"material.building", 4, &"material.mechanism_part", 2),
		_recipe(8, &"material.mechanism_part", 3),
		_recipe(9, &"material.mechanism_part", 3),
		_recipe(10, &"material.mechanism_part", 3),
		_recipe(11, &"material.mechanism_part", 3),
		_recipe(12, &"material.mechanism_part", 3),
		_recipe(13, &"material.mechanism_part", 4, &"material.building", 2),
		_recipe(14, &"material.mechanism_part", 4, &"material.building", 2),
		_recipe(15, &"material.crystal_sand", 1),
		_recipe(16, &"material.mechanism_part", 3),
		_recipe(17, &"material.building", 1),
		_recipe(18, &"material.crystal_sand", 2, &"material.mechanism_part", 1),
		_recipe(19, &"material.mechanism_part", 4, &"material.crystal_sand", 2),
		_recipe(20, &"material.crystal_sand", 1),
		_recipe(21, &"material.crystal_sand", 1),
		_recipe(22, &"material.crystal_sand", 1),
		_recipe(23, &"material.crystal_sand", 2, &"material.mechanism_part", 1),
		_recipe(24, &"material.crystal_sand", 2, &"material.mechanism_part", 1),
	]


static func _blueprint(
	ordinal: int,
	category: int,
	tier: int,
	unlock_chapter: int,
	lifecycle: int,
	mechanic_suffix: String,
) -> BlueprintRow:
	return BlueprintRow.new(
		StringName("blueprint.%02d" % ordinal),
		ordinal,
		category,
		tier,
		unlock_chapter,
		lifecycle,
		StringName("recipe.standard.%02d" % ordinal),
		StringName("mechanic.blueprint.%s" % mechanic_suffix),
		StringName("blueprint.%02d.display_name" % ordinal),
		StringName("blueprint.%02d.function" % ordinal),
	)


static func _recipe(
	ordinal: int,
	main_material_id: StringName,
	main_quantity: int,
	auxiliary_material_id: StringName = &"",
	auxiliary_quantity: int = 0,
) -> RecipeRow:
	return RecipeRow.new(
		StringName("recipe.standard.%02d" % ordinal),
		StringName("blueprint.%02d" % ordinal),
		main_material_id,
		main_quantity,
		auxiliary_material_id,
		auxiliary_quantity,
	)
