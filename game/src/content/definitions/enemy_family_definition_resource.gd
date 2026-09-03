class_name EnemyFamilyDefinitionResource
extends Resource

enum Source {
	LOCAL_FAUNA = 1,
	RUNAWAY_CONSTRUCT = 2,
	ANOMALY_AGGREGATE = 3,
	ANCIENT_EXECUTOR = 4,
}

enum NumericArchetype {
	BALANCED = 1,
	ATTACK = 2,
	DEFENSE = 3,
	SPEED = 4,
	DURABILITY = 5,
	BALANCED_TO_ATTACK = 6,
	DEFENSE_TO_SPEED = 7,
}

@export var family_id: StringName = &""
@export var ordinal: int = 0
@export var source: int = 0
@export var numeric_archetype: int = 0
@export var display_name_text_id: StringName = &""
@export var regional_role_id: StringName = &""
@export var visual_family_id: StringName = &""


static func snapshot(
	source_definition: EnemyFamilyDefinitionResource,
) -> EnemyFamilyDefinitionResource:
	var copied_definition := EnemyFamilyDefinitionResource.new()
	copied_definition.family_id = source_definition.family_id
	copied_definition.ordinal = source_definition.ordinal
	copied_definition.source = source_definition.source
	copied_definition.numeric_archetype = source_definition.numeric_archetype
	copied_definition.display_name_text_id = source_definition.display_name_text_id
	copied_definition.regional_role_id = source_definition.regional_role_id
	copied_definition.visual_family_id = source_definition.visual_family_id
	return copied_definition


func is_equal_to(other: EnemyFamilyDefinitionResource) -> bool:
	return (
		other != null
		and other.family_id == family_id
		and other.ordinal == ordinal
		and other.source == source
		and other.numeric_archetype == numeric_archetype
		and other.display_name_text_id == display_name_text_id
		and other.regional_role_id == regional_role_id
		and other.visual_family_id == visual_family_id
	)
