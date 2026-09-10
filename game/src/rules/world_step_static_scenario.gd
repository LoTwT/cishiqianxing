class_name WorldStepStaticScenario
extends RefCounted

const EnemyProfileDefinitionScript := preload("res://src/content/definitions/enemy_profile_definition_resource.gd")


# 地图注册与世界步复验共用此判定；新增行为必须先有阶段执行器。
static func has_no_pending_enemy_effects(
	behavior_id: StringName,
	has_alternate_state: bool,
	combat_trait_ids: Array[StringName],
) -> bool:
	if behavior_id != &"enemy.behavior.shield" or has_alternate_state:
		return false
	for trait_id: StringName in combat_trait_ids:
		if trait_id != EnemyProfileDefinitionScript.SHIELD_TRAIT_ID:
			return false
	return true
