class_name EnemyProfileDefinitionResource
extends Resource

const MAXIMUM_COMBAT_TRAIT_COUNT: int = 2
const PHASE_ALTERNATION_TRAIT_ID: StringName = &"enemy.trait.phase_alternation"
const SHIELD_TRAIT_ID: StringName = &"enemy.trait.shield"
const SUPPORT_LINK_TRAIT_ID: StringName = &"enemy.trait.support_link"

enum Tier {
	BASE = 1,
	ENHANCED = 2,
}

@export var profile_id: StringName = &""
@export var family_id: StringName = &""
@export var tier: int = 0
@export var source: int = 0
@export var balance_contract_id: StringName = &""
@export var maximum_durability: int = 0
@export var attack: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var has_alternate_state: bool = false
@export var alternate_maximum_durability: int = 0
@export var alternate_attack: int = 0
@export var alternate_defense: int = 0
@export var alternate_speed: int = 0
@export var behavior_id: StringName = &""
@export var combat_trait_ids: Array[StringName] = []
@export var visual_binding_id: StringName = &""


static func snapshot(
	source_definition: EnemyProfileDefinitionResource,
) -> EnemyProfileDefinitionResource:
	var copied_definition := EnemyProfileDefinitionResource.new()
	copied_definition.profile_id = source_definition.profile_id
	copied_definition.family_id = source_definition.family_id
	copied_definition.tier = source_definition.tier
	copied_definition.source = source_definition.source
	copied_definition.balance_contract_id = source_definition.balance_contract_id
	copied_definition.maximum_durability = source_definition.maximum_durability
	copied_definition.attack = source_definition.attack
	copied_definition.defense = source_definition.defense
	copied_definition.speed = source_definition.speed
	copied_definition.has_alternate_state = source_definition.has_alternate_state
	copied_definition.alternate_maximum_durability = (
		source_definition.alternate_maximum_durability
	)
	copied_definition.alternate_attack = source_definition.alternate_attack
	copied_definition.alternate_defense = source_definition.alternate_defense
	copied_definition.alternate_speed = source_definition.alternate_speed
	copied_definition.behavior_id = source_definition.behavior_id
	for trait_id: StringName in source_definition.combat_trait_ids:
		copied_definition.combat_trait_ids.append(trait_id)
	copied_definition.visual_binding_id = source_definition.visual_binding_id
	return copied_definition


func is_equal_to(other: EnemyProfileDefinitionResource) -> bool:
	return (
		other != null
		and other.profile_id == profile_id
		and other.family_id == family_id
		and other.tier == tier
		and other.source == source
		and other.balance_contract_id == balance_contract_id
		and other.maximum_durability == maximum_durability
		and other.attack == attack
		and other.defense == defense
		and other.speed == speed
		and other.has_alternate_state == has_alternate_state
		and (
			other.alternate_maximum_durability
			== alternate_maximum_durability
		)
		and other.alternate_attack == alternate_attack
		and other.alternate_defense == alternate_defense
		and other.alternate_speed == alternate_speed
		and other.behavior_id == behavior_id
		and other.combat_trait_ids == combat_trait_ids
		and other.visual_binding_id == visual_binding_id
	)
