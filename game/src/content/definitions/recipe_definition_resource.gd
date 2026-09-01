class_name RecipeDefinitionResource
extends Resource

const BUILDING_MATERIAL_ID: StringName = &"material.building"
const MECHANISM_PART_MATERIAL_ID: StringName = &"material.mechanism_part"
const CRYSTAL_SAND_MATERIAL_ID: StringName = &"material.crystal_sand"

@export var recipe_id: StringName = &""
@export var output_blueprint_id: StringName = &""
@export var main_material_id: StringName = &""
@export var main_quantity: int = 0
@export var auxiliary_material_id: StringName = &""
@export var auxiliary_quantity: int = 0


static func snapshot(source: RecipeDefinitionResource) -> RecipeDefinitionResource:
	var copied_definition := RecipeDefinitionResource.new()
	copied_definition.recipe_id = source.recipe_id
	copied_definition.output_blueprint_id = source.output_blueprint_id
	copied_definition.main_material_id = source.main_material_id
	copied_definition.main_quantity = source.main_quantity
	copied_definition.auxiliary_material_id = source.auxiliary_material_id
	copied_definition.auxiliary_quantity = source.auxiliary_quantity
	return copied_definition


static func allowed_material_ids() -> Array[StringName]:
	return [
		BUILDING_MATERIAL_ID,
		CRYSTAL_SAND_MATERIAL_ID,
		MECHANISM_PART_MATERIAL_ID,
	]


func is_equal_to(other: RecipeDefinitionResource) -> bool:
	return (
		other != null
		and other.recipe_id == recipe_id
		and other.output_blueprint_id == output_blueprint_id
		and other.main_material_id == main_material_id
		and other.main_quantity == main_quantity
		and other.auxiliary_material_id == auxiliary_material_id
		and other.auxiliary_quantity == auxiliary_quantity
	)
