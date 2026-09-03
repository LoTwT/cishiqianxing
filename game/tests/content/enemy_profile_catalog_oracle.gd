extends RefCounted

const CATALOG_ID: StringName = &"enemy.profile.catalog.main"

const EXPECTED_FAMILY_COUNT: int = 12
const EXPECTED_PROFILE_COUNT: int = 24
const EXPECTED_BASE_PROFILE_COUNT: int = 12
const EXPECTED_ENHANCED_PROFILE_COUNT: int = 12
const EXPECTED_SOURCE_FAMILY_COUNTS: Array[int] = [4, 4, 2, 2]
const EXPECTED_SOURCE_PROFILE_COUNTS: Array[int] = [8, 8, 4, 4]
const EXPECTED_BALANCE_CONTRACT_IDS: Array[StringName] = [
	&"route.contract.main.stage.01_02",
	&"route.contract.main.stage.03_04",
	&"route.contract.main.stage.05_06",
	&"route.contract.main.stage.07_08",
	&"route.contract.main.stage.09",
]
const EXPECTED_BALANCE_CONTRACT_PROFILE_COUNTS: Array[int] = [4, 8, 7, 3, 2]
const EXPECTED_BEHAVIOR_IDS: Array[StringName] = [
	&"enemy.behavior.construct_response",
	&"enemy.behavior.environment_movement",
	&"enemy.behavior.patrol",
	&"enemy.behavior.phase_alternation",
	&"enemy.behavior.shield",
	&"enemy.behavior.support_link",
]
const EXPECTED_PROFILES_PER_BEHAVIOR: int = 4
const EXPECTED_COMBAT_TRAIT_IDS: Array[StringName] = [
	&"enemy.trait.phase_alternation",
	&"enemy.trait.shield",
	&"enemy.trait.support_link",
]
const EXPECTED_NO_TRAIT_PROFILE_COUNT: int = 12
const EXPECTED_SHIELD_PROFILE_COUNT: int = 5
const EXPECTED_SUPPORT_PROFILE_COUNT: int = 4
const EXPECTED_PHASE_ALTERNATION_PROFILE_COUNT: int = 4
const EXPECTED_ALTERNATE_STATE_PROFILE_COUNT: int = 4
const EXPECTED_DOUBLE_TRAIT_PROFILE_COUNT: int = 1

const TIER_BASE: int = 1
const TIER_ENHANCED: int = 2
const SOURCE_LOCAL_FAUNA: int = 1
const SOURCE_RUNAWAY_CONSTRUCT: int = 2
const SOURCE_ANOMALY_AGGREGATE: int = 3
const SOURCE_ANCIENT_EXECUTOR: int = 4

const BASE_ATTACK_COUNT_MINIMUM: int = 2
const BASE_ATTACK_COUNT_MAXIMUM: int = 5
const ENHANCED_ATTACK_COUNT_MINIMUM: int = 3
const ENHANCED_ATTACK_COUNT_MAXIMUM: int = 6
const SHIELD_EXTRA_ATTACK_COUNT: int = 1
const MINIMUM_PLAYER_DAMAGE_PER_ATTACK: int = 3
const HIGH_SPEED_DELTA: int = 1
const MAXIMUM_SINGLE_TRAIT_LOSS_PERCENT: int = 25
const MAXIMUM_DOUBLE_TRAIT_LOSS_PERCENT: int = 30
const MAXIMUM_SUPPORTING_OPPONENTS: int = 2


class FamilyRow extends RefCounted:
	var family_id: StringName
	var ordinal: int
	var source: int
	var numeric_archetype: int
	var display_name_text_id: StringName
	var regional_role_id: StringName
	var visual_family_id: StringName

	func _init(
		row_family_id: StringName,
		row_ordinal: int,
		row_source: int,
		row_numeric_archetype: int,
		row_display_name_text_id: StringName,
		row_regional_role_id: StringName,
		row_visual_family_id: StringName,
	) -> void:
		family_id = row_family_id
		ordinal = row_ordinal
		source = row_source
		numeric_archetype = row_numeric_archetype
		display_name_text_id = row_display_name_text_id
		regional_role_id = row_regional_role_id
		visual_family_id = row_visual_family_id


class CombatExpectation extends RefCounted:
	var player_stats: Array[int]
	var shield_intact: bool
	var supporting_opponents_alive: int
	var player_first_attacker: bool
	var player_damage_per_attack: int
	var opponent_damage_per_attack: int
	var player_attacks_without_shield: int
	var player_attacks_with_traits: int
	var opponent_attacks_executed: int
	var player_health_loss: int

	func _init(
		row_player_stats: Array[int],
		row_shield_intact: bool,
		row_supporting_opponents_alive: int,
		row_player_first_attacker: bool,
		row_player_damage_per_attack: int,
		row_opponent_damage_per_attack: int,
		row_player_attacks_without_shield: int,
		row_player_attacks_with_traits: int,
		row_opponent_attacks_executed: int,
		row_player_health_loss: int,
	) -> void:
		player_stats = []
		for value: int in row_player_stats:
			player_stats.append(value)
		shield_intact = row_shield_intact
		supporting_opponents_alive = row_supporting_opponents_alive
		player_first_attacker = row_player_first_attacker
		player_damage_per_attack = row_player_damage_per_attack
		opponent_damage_per_attack = row_opponent_damage_per_attack
		player_attacks_without_shield = row_player_attacks_without_shield
		player_attacks_with_traits = row_player_attacks_with_traits
		opponent_attacks_executed = row_opponent_attacks_executed
		player_health_loss = row_player_health_loss


class ProfileRow extends RefCounted:
	var profile_id: StringName
	var family_id: StringName
	var tier: int
	var source: int
	var balance_contract_id: StringName
	var maximum_durability: int
	var attack: int
	var defense: int
	var speed: int
	var has_alternate_state: bool
	var alternate_maximum_durability: int
	var alternate_attack: int
	var alternate_defense: int
	var alternate_speed: int
	var behavior_id: StringName
	var combat_trait_ids: Array[StringName]
	var visual_binding_id: StringName
	var primary_expectation: CombatExpectation
	var alternate_expectation: CombatExpectation

	func _init(
		row_profile_id: StringName,
		row_family_id: StringName,
		row_tier: int,
		row_source: int,
		row_balance_contract_id: StringName,
		row_maximum_durability: int,
		row_attack: int,
		row_defense: int,
		row_speed: int,
		row_has_alternate_state: bool,
		row_alternate_maximum_durability: int,
		row_alternate_attack: int,
		row_alternate_defense: int,
		row_alternate_speed: int,
		row_behavior_id: StringName,
		row_combat_trait_ids: Array[StringName],
		row_visual_binding_id: StringName,
		row_primary_expectation: CombatExpectation,
		row_alternate_expectation: CombatExpectation,
	) -> void:
		profile_id = row_profile_id
		family_id = row_family_id
		tier = row_tier
		source = row_source
		balance_contract_id = row_balance_contract_id
		maximum_durability = row_maximum_durability
		attack = row_attack
		defense = row_defense
		speed = row_speed
		has_alternate_state = row_has_alternate_state
		alternate_maximum_durability = row_alternate_maximum_durability
		alternate_attack = row_alternate_attack
		alternate_defense = row_alternate_defense
		alternate_speed = row_alternate_speed
		behavior_id = row_behavior_id
		combat_trait_ids = []
		for trait_id: StringName in row_combat_trait_ids:
			combat_trait_ids.append(trait_id)
		visual_binding_id = row_visual_binding_id
		primary_expectation = row_primary_expectation
		alternate_expectation = row_alternate_expectation


static func family_rows() -> Array[FamilyRow]:
	return [
		FamilyRow.new(
			&"enemy.family.f01", 1, 1, 1,
			&"text.enemy.family.f01.name",
			&"enemy.role.hareno.signature_patrol",
			&"enemy.visual.family.f01",
		),
		FamilyRow.new(
			&"enemy.family.f02", 2, 1, 1,
			&"text.enemy.family.f02.name",
			&"enemy.role.shioori.signature_environment_movement",
			&"enemy.visual.family.f02",
		),
		FamilyRow.new(
			&"enemy.family.f03", 3, 2, 2,
			&"text.enemy.family.f03.name",
			&"enemy.role.kanade.signature_shield",
			&"enemy.visual.family.f03",
		),
		FamilyRow.new(
			&"enemy.family.f04", 4, 2, 2,
			&"text.enemy.family.f04.name",
			&"enemy.role.fukamine.signature_construct_response",
			&"enemy.visual.family.f04",
		),
		FamilyRow.new(
			&"enemy.family.f05", 5, 3, 3,
			&"text.enemy.family.f05.name",
			&"enemy.role.nagori.signature_support_link",
			&"enemy.visual.family.f05",
		),
		FamilyRow.new(
			&"enemy.family.f06", 6, 4, 3,
			&"text.enemy.family.f06.name",
			&"enemy.role.wanoniwa.signature_phase_alternation",
			&"enemy.visual.family.f06",
		),
		FamilyRow.new(
			&"enemy.family.f07", 7, 1, 4,
			&"text.enemy.family.f07.name",
			&"enemy.role.cross_region.patrol_direction",
			&"enemy.visual.family.f07",
		),
		FamilyRow.new(
			&"enemy.family.f08", 8, 1, 4,
			&"text.enemy.family.f08.name",
			&"enemy.role.cross_region.environment_movement",
			&"enemy.visual.family.f08",
		),
		FamilyRow.new(
			&"enemy.family.f09", 9, 2, 5,
			&"text.enemy.family.f09.name",
			&"enemy.role.public_facility.route_cost",
			&"enemy.visual.family.f09",
		),
		FamilyRow.new(
			&"enemy.family.f10", 10, 2, 5,
			&"text.enemy.family.f10.name",
			&"enemy.role.maintenance.route_cost",
			&"enemy.visual.family.f10",
		),
		FamilyRow.new(
			&"enemy.family.f11", 11, 3, 6,
			&"text.enemy.family.f11.name",
			&"enemy.role.mid_late.cross_region_crisis",
			&"enemy.visual.family.f11",
		),
		FamilyRow.new(
			&"enemy.family.f12", 12, 4, 7,
			&"text.enemy.family.f12.name",
			&"enemy.role.post_chapter_08.ancient_system",
			&"enemy.visual.family.f12",
		),
	]


static func profile_rows() -> Array[ProfileRow]:
	return [
		_profile(
			&"enemy.profile.f01.base", &"enemy.family.f01", 1, 1,
			&"route.contract.main.stage.01_02", [12, 9, 7, 10], [],
			&"enemy.behavior.patrol", [], &"enemy.visual.variant.f01.base",
			_combat([120, 11, 6, 10], false, 0, true, 4, 3, 3, 3, 2, 6),
		),
		_profile(
			&"enemy.profile.f01.enhanced", &"enemy.family.f01", 2, 1,
			&"route.contract.main.stage.03_04", [20, 12, 8, 11], [],
			&"enemy.behavior.patrol", [], &"enemy.visual.variant.f01.enhanced",
			_combat([140, 13, 8, 11], false, 0, true, 5, 4, 4, 4, 3, 12),
		),
		_profile(
			&"enemy.profile.f02.base", &"enemy.family.f02", 1, 1,
			&"route.contract.main.stage.01_02", [15, 10, 6, 9], [],
			&"enemy.behavior.environment_movement", [],
			&"enemy.visual.variant.f02.base",
			_combat([120, 11, 6, 10], false, 0, true, 5, 4, 3, 3, 2, 8),
		),
		_profile(
			&"enemy.profile.f02.enhanced", &"enemy.family.f02", 2, 1,
			&"route.contract.main.stage.03_04", [18, 11, 9, 10], [],
			&"enemy.behavior.environment_movement", [],
			&"enemy.visual.variant.f02.enhanced",
			_combat([140, 13, 8, 11], false, 0, true, 4, 3, 5, 5, 4, 12),
		),
		_profile(
			&"enemy.profile.f03.base", &"enemy.family.f03", 1, 2,
			&"route.contract.main.stage.03_04", [12, 13, 9, 11], [],
			&"enemy.behavior.shield", [&"enemy.trait.shield"],
			&"enemy.visual.variant.f03.base",
			_combat([140, 13, 8, 11], true, 0, true, 4, 5, 3, 4, 3, 15),
		),
		_profile(
			&"enemy.profile.f03.enhanced", &"enemy.family.f03", 2, 2,
			&"route.contract.main.stage.05_06", [24, 14, 10, 12], [],
			&"enemy.behavior.shield", [&"enemy.trait.shield"],
			&"enemy.visual.variant.f03.enhanced",
			_combat([160, 15, 9, 12], true, 0, true, 5, 5, 5, 6, 5, 25),
		),
		_profile(
			&"enemy.profile.f04.base", &"enemy.family.f04", 1, 2,
			&"route.contract.main.stage.03_04", [15, 13, 8, 11], [],
			&"enemy.behavior.construct_response", [],
			&"enemy.visual.variant.f04.base",
			_combat([140, 13, 8, 11], false, 0, true, 5, 5, 3, 3, 2, 10),
		),
		_profile(
			&"enemy.profile.f04.enhanced", &"enemy.family.f04", 2, 2,
			&"route.contract.main.stage.05_06", [24, 15, 10, 12], [],
			&"enemy.behavior.construct_response", [],
			&"enemy.visual.variant.f04.enhanced",
			_combat([160, 15, 9, 12], false, 0, true, 5, 6, 5, 5, 4, 24),
		),
		_profile(
			&"enemy.profile.f05.base", &"enemy.family.f05", 1, 3,
			&"route.contract.main.stage.05_06", [14, 10, 11, 12], [],
			&"enemy.behavior.support_link", [&"enemy.trait.support_link"],
			&"enemy.visual.variant.f05.base",
			_combat([160, 15, 9, 12], false, 2, true, 4, 3, 4, 4, 3, 9),
		),
		_profile(
			&"enemy.profile.f05.enhanced", &"enemy.family.f05", 2, 3,
			&"route.contract.main.stage.07_08", [20, 13, 12, 13], [],
			&"enemy.behavior.support_link", [&"enemy.trait.support_link"],
			&"enemy.visual.variant.f05.enhanced",
			_combat([180, 16, 11, 13], false, 2, true, 4, 4, 5, 5, 4, 16),
		),
		_profile(
			&"enemy.profile.f06.base", &"enemy.family.f06", 1, 4,
			&"route.contract.main.stage.05_06", [12, 12, 12, 11], [12, 13, 11, 12],
			&"enemy.behavior.phase_alternation", [&"enemy.trait.phase_alternation"],
			&"enemy.visual.variant.f06.base",
			_combat([160, 15, 9, 12], false, 0, true, 3, 3, 4, 4, 3, 9),
			_combat([160, 15, 9, 12], false, 0, true, 4, 4, 3, 3, 2, 8),
		),
		_profile(
			&"enemy.profile.f06.enhanced", &"enemy.family.f06", 2, 4,
			&"route.contract.main.stage.07_08", [18, 14, 13, 12], [18, 15, 12, 13],
			&"enemy.behavior.phase_alternation", [&"enemy.trait.phase_alternation"],
			&"enemy.visual.variant.f06.enhanced",
			_combat([180, 16, 11, 13], false, 0, true, 3, 3, 6, 6, 5, 15),
			_combat([180, 16, 11, 13], false, 0, true, 4, 4, 5, 5, 4, 16),
		),
		_profile(
			&"enemy.profile.f07.base", &"enemy.family.f07", 1, 1,
			&"route.contract.main.stage.01_02", [9, 9, 8, 11], [],
			&"enemy.behavior.patrol", [], &"enemy.visual.variant.f07.base",
			_combat([120, 11, 6, 10], false, 0, false, 3, 3, 3, 3, 3, 9),
		),
		_profile(
			&"enemy.profile.f07.enhanced", &"enemy.family.f07", 2, 1,
			&"route.contract.main.stage.03_04", [18, 12, 9, 12], [],
			&"enemy.behavior.patrol", [], &"enemy.visual.variant.f07.enhanced",
			_combat([140, 13, 8, 11], false, 0, false, 4, 4, 5, 5, 5, 20),
		),
		_profile(
			&"enemy.profile.f08.base", &"enemy.family.f08", 1, 1,
			&"route.contract.main.stage.01_02", [10, 8, 8, 11], [],
			&"enemy.behavior.environment_movement", [],
			&"enemy.visual.variant.f08.base",
			_combat([120, 11, 6, 10], false, 0, false, 3, 2, 4, 4, 4, 8),
		),
		_profile(
			&"enemy.profile.f08.enhanced", &"enemy.family.f08", 2, 1,
			&"route.contract.main.stage.03_04", [18, 11, 10, 12], [],
			&"enemy.behavior.environment_movement", [],
			&"enemy.visual.variant.f08.enhanced",
			_combat([140, 13, 8, 11], false, 0, false, 3, 3, 6, 6, 6, 18),
		),
		_profile(
			&"enemy.profile.f09.base", &"enemy.family.f09", 1, 2,
			&"route.contract.main.stage.03_04", [24, 10, 8, 10], [],
			&"enemy.behavior.shield", [&"enemy.trait.shield"],
			&"enemy.visual.variant.f09.base",
			_combat([140, 13, 8, 11], true, 0, true, 5, 2, 5, 6, 5, 10),
		),
		_profile(
			&"enemy.profile.f09.enhanced", &"enemy.family.f09", 2, 2,
			&"route.contract.main.stage.05_06", [30, 13, 9, 11], [],
			&"enemy.behavior.shield", [&"enemy.trait.shield"],
			&"enemy.visual.variant.f09.enhanced",
			_combat([160, 15, 9, 12], true, 0, true, 6, 4, 5, 6, 5, 20),
		),
		_profile(
			&"enemy.profile.f10.base", &"enemy.family.f10", 1, 2,
			&"route.contract.main.stage.03_04", [20, 11, 9, 10], [],
			&"enemy.behavior.construct_response", [],
			&"enemy.visual.variant.f10.base",
			_combat([140, 13, 8, 11], false, 0, true, 4, 3, 5, 5, 4, 12),
		),
		_profile(
			&"enemy.profile.f10.enhanced", &"enemy.family.f10", 2, 2,
			&"route.contract.main.stage.05_06", [30, 13, 10, 11], [],
			&"enemy.behavior.construct_response", [],
			&"enemy.visual.variant.f10.enhanced",
			_combat([160, 15, 9, 12], false, 0, true, 5, 4, 6, 6, 5, 20),
		),
		_profile(
			&"enemy.profile.f11.base", &"enemy.family.f11", 1, 3,
			&"route.contract.main.stage.05_06", [16, 12, 11, 11], [],
			&"enemy.behavior.support_link", [&"enemy.trait.support_link"],
			&"enemy.visual.variant.f11.base",
			_combat([160, 15, 9, 12], false, 2, true, 4, 5, 4, 4, 3, 15),
		),
		_profile(
			&"enemy.profile.f11.enhanced", &"enemy.family.f11", 2, 3,
			&"route.contract.main.stage.07_08", [24, 16, 11, 13], [],
			&"enemy.behavior.support_link", [&"enemy.trait.support_link"],
			&"enemy.visual.variant.f11.enhanced",
			_combat([180, 16, 11, 13], false, 2, true, 5, 7, 5, 5, 4, 28),
		),
		_profile(
			&"enemy.profile.f12.base", &"enemy.family.f12", 1, 4,
			&"route.contract.main.stage.09", [15, 14, 13, 13], [15, 14, 12, 14],
			&"enemy.behavior.phase_alternation", [&"enemy.trait.phase_alternation"],
			&"enemy.visual.variant.f12.base",
			_combat([180, 16, 11, 14], false, 0, true, 3, 3, 5, 5, 4, 12),
			_combat([180, 16, 11, 14], false, 0, true, 4, 3, 4, 4, 3, 9),
		),
		_profile(
			&"enemy.profile.f12.enhanced", &"enemy.family.f12", 2, 4,
			&"route.contract.main.stage.09", [18, 16, 12, 15], [18, 17, 11, 15],
			&"enemy.behavior.phase_alternation",
			[&"enemy.trait.phase_alternation", &"enemy.trait.shield"],
			&"enemy.visual.variant.f12.enhanced",
			_combat([180, 16, 11, 14], true, 0, false, 4, 5, 5, 6, 6, 30),
			_combat([180, 16, 11, 14], true, 0, false, 5, 6, 4, 5, 5, 30),
		),
	]


static func _profile(
	profile_id: StringName,
	family_id: StringName,
	tier: int,
	source: int,
	balance_contract_id: StringName,
	primary_stats: Array[int],
	alternate_stats: Array[int],
	behavior_id: StringName,
	combat_trait_ids: Array[StringName],
	visual_binding_id: StringName,
	primary_expectation: CombatExpectation,
	alternate_expectation: CombatExpectation = null,
) -> ProfileRow:
	var has_alternate_state: bool = not alternate_stats.is_empty()
	var copied_alternate_stats: Array[int] = [0, 0, 0, 0]
	if has_alternate_state:
		copied_alternate_stats = alternate_stats
	return ProfileRow.new(
		profile_id,
		family_id,
		tier,
		source,
		balance_contract_id,
		primary_stats[0],
		primary_stats[1],
		primary_stats[2],
		primary_stats[3],
		has_alternate_state,
		copied_alternate_stats[0],
		copied_alternate_stats[1],
		copied_alternate_stats[2],
		copied_alternate_stats[3],
		behavior_id,
		combat_trait_ids,
		visual_binding_id,
		primary_expectation,
		alternate_expectation,
	)


static func _combat(
	player_stats: Array[int],
	shield_intact: bool,
	supporting_opponents_alive: int,
	player_first_attacker: bool,
	player_damage_per_attack: int,
	opponent_damage_per_attack: int,
	player_attacks_without_shield: int,
	player_attacks_with_traits: int,
	opponent_attacks_executed: int,
	player_health_loss: int,
) -> CombatExpectation:
	return CombatExpectation.new(
		player_stats,
		shield_intact,
		supporting_opponents_alive,
		player_first_attacker,
		player_damage_per_attack,
		opponent_damage_per_attack,
		player_attacks_without_shield,
		player_attacks_with_traits,
		opponent_attacks_executed,
		player_health_loss,
	)
