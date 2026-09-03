class_name EnemyProfileValidator
extends RefCounted

const EnemyFamilyDefinitionScript := preload(
	"res://src/content/definitions/enemy_family_definition_resource.gd"
)
const EnemyProfileDefinitionScript := preload(
	"res://src/content/definitions/enemy_profile_definition_resource.gd"
)
const EnemyProfileCatalogScript := preload(
	"res://src/content/definitions/enemy_profile_catalog_resource.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatKernelScript := preload(
	"res://src/rules/contact_combat_kernel.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)

const EXPECTED_CATALOG_ID: StringName = &"enemy.profile.catalog.main"
const EXPECTED_FAMILY_COUNT: int = 12
const EXPECTED_PROFILE_COUNT: int = 24
const EXPECTED_SOURCE_FAMILY_COUNTS: Array[int] = [4, 4, 2, 2]
const EXPECTED_PROFILES_PER_BEHAVIOR: int = 4
const ALLOWED_BEHAVIOR_IDS: Array[StringName] = [
	&"enemy.behavior.construct_response",
	&"enemy.behavior.environment_movement",
	&"enemy.behavior.patrol",
	&"enemy.behavior.phase_alternation",
	&"enemy.behavior.shield",
	&"enemy.behavior.support_link",
]
const ALLOWED_TRAIT_IDS: Array[StringName] = [
	&"enemy.trait.phase_alternation",
	&"enemy.trait.shield",
	&"enemy.trait.support_link",
]
const SHIELD_TRAIT_ID: StringName = EnemyProfileDefinitionScript.SHIELD_TRAIT_ID
const SUPPORT_LINK_TRAIT_ID: StringName = &"enemy.trait.support_link"
const PHASE_ALTERNATION_TRAIT_ID: StringName = (
	EnemyProfileDefinitionScript.PHASE_ALTERNATION_TRAIT_ID
)
const SHIELD_BEHAVIOR_ID: StringName = &"enemy.behavior.shield"
const SUPPORT_LINK_BEHAVIOR_ID: StringName = &"enemy.behavior.support_link"
const PHASE_ALTERNATION_BEHAVIOR_ID: StringName = &"enemy.behavior.phase_alternation"


static func snapshot_and_validate(
	raw_catalog: Resource,
	route_catalog: RepresentativeRouteCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> EnemyProfileCatalogScript:
	var issue_count_before: int = issues.size()
	if raw_catalog == null:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_ENEMY_PROFILE_CATALOG_NULL,
			&"",
			"enemy_profile_catalog",
			"Enemy profile catalog is null.",
		)
		return null
	if raw_catalog.get_script() != EnemyProfileCatalogScript:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_CATALOG_INVALID_SCRIPT,
			&"",
			"enemy_profile_catalog",
			"Enemy profile catalog must use the exact authoritative catalog script.",
		)
		return null

	var exact_catalog: EnemyProfileCatalogScript = raw_catalog as EnemyProfileCatalogScript
	if exact_catalog.families.size() != EXPECTED_FAMILY_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_FAMILY_COUNT_INVALID,
			exact_catalog.catalog_id,
			"families",
			"Expected %d enemy families, got %d."
			% [EXPECTED_FAMILY_COUNT, exact_catalog.families.size()],
		)
	if exact_catalog.profiles.size() != EXPECTED_PROFILE_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_COUNT_INVALID,
			exact_catalog.catalog_id,
			"profiles",
			"Expected %d enemy profiles, got %d."
			% [EXPECTED_PROFILE_COUNT, exact_catalog.profiles.size()],
		)
	if (
		exact_catalog.families.size() != EXPECTED_FAMILY_COUNT
		or exact_catalog.profiles.size() != EXPECTED_PROFILE_COUNT
	):
		return null
	if exact_catalog.catalog_id != EXPECTED_CATALOG_ID:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_CATALOG_ID_INVALID,
			exact_catalog.catalog_id,
			"catalog_id",
			"Expected enemy catalog ID '%s', got '%s'."
			% [String(EXPECTED_CATALOG_ID), String(exact_catalog.catalog_id)],
		)

	var families: Array[EnemyFamilyDefinitionScript] = []
	for index: int in range(exact_catalog.families.size()):
		var family: EnemyFamilyDefinitionScript = exact_catalog.families[index]
		var field_path: String = "families[%d]" % index
		if family == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_ENTRY_NULL,
				&"",
				field_path,
				"Enemy family entry is null.",
			)
			continue
		if family.get_script() != EnemyFamilyDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_ENTRY_INVALID_SCRIPT,
				family.family_id,
				field_path,
				"Enemy family must use the exact authoritative definition script.",
			)
			continue
		families.append(EnemyFamilyDefinitionScript.snapshot(family))

	var profiles: Array[EnemyProfileDefinitionScript] = []
	for index: int in range(exact_catalog.profiles.size()):
		var profile: EnemyProfileDefinitionScript = exact_catalog.profiles[index]
		var field_path: String = "profiles[%d]" % index
		if profile == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_ENTRY_NULL,
				&"",
				field_path,
				"Enemy profile entry is null.",
			)
			continue
		if profile.get_script() != EnemyProfileDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_ENTRY_INVALID_SCRIPT,
				profile.profile_id,
				field_path,
				"Enemy profile must use the exact authoritative definition script.",
			)
			continue
		var snapshot: EnemyProfileDefinitionScript = (
			EnemyProfileDefinitionScript.snapshot(profile)
		)
		snapshot.combat_trait_ids.sort_custom(_string_name_less_than)
		profiles.append(snapshot)

	families.sort_custom(_family_less_than)
	profiles.sort_custom(_profile_less_than)
	_validate_families(families, issues)
	_validate_profiles(profiles, families, route_catalog, issues)
	if issues.size() != issue_count_before:
		return null

	var result := EnemyProfileCatalogScript.new()
	result.catalog_id = exact_catalog.catalog_id
	for family: EnemyFamilyDefinitionScript in families:
		result.families.append(family)
	for profile: EnemyProfileDefinitionScript in profiles:
		result.profiles.append(profile)
	return result


static func validate_balance(
	registry: ContentRegistryScript,
	catalog: EnemyProfileCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if (
		registry == null
		or not is_instance_valid(registry)
		or registry.get_script() != ContentRegistryScript
		or not registry.is_initialized()
		or catalog == null
		or catalog.get_script() != EnemyProfileCatalogScript
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTEXT_INVALID,
			&"",
			"enemy_profile_catalog",
			"Enemy balance validation requires the complete sealed v5 Registry and catalog.",
		)
		return

	var families_by_id: Dictionary[StringName, EnemyFamilyDefinitionScript] = {}
	for family: EnemyFamilyDefinitionScript in catalog.families:
		families_by_id[family.family_id] = family
	for profile: EnemyProfileDefinitionScript in catalog.profiles:
		if not families_by_id.has(profile.family_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTEXT_INVALID,
				profile.profile_id,
				"family_id",
				"Enemy balance validation could not resolve the profile family.",
			)
			continue
		var route_query = registry.lookup_representative_route_contract(
			profile.balance_contract_id
		)
		if not route_query.succeeded():
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTEXT_INVALID,
				profile.profile_id,
				"balance_contract_id",
				"Enemy balance validation could not resolve its route contract.",
			)
			continue
		var contract = route_query.contract()
		var player_stats = route_query.stage_end_minimum_player_stats()
		if contract == null or player_stats == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTEXT_INVALID,
				profile.profile_id,
				"balance_contract_id",
				"Enemy balance contract did not provide its derived player state.",
			)
			continue
		var reward_ids: Array[StringName] = []
		var reward_lookup_failed: bool = false
		for progression_id: StringName in contract.mainline_progression_reference_ids:
			var progression_query = registry.lookup_mainline_progression(progression_id)
			if not progression_query.succeeded():
				reward_lookup_failed = true
				break
			var progression = progression_query.mainline_progression()
			if progression == null:
				reward_lookup_failed = true
				break
			for reward_id: StringName in progression.reward_ids:
				reward_ids.append(reward_id)
		if reward_lookup_failed:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTEXT_INVALID,
				profile.profile_id,
				"balance_contract_id",
				"Enemy balance contract contains an unresolved progression reference.",
			)
			continue
		var player_state := PlayerProgressionStateScript.create(
			player_stats.profile_id,
			registry.schema_version(),
			registry.content_version(),
			player_stats.maximum_health,
			reward_ids,
		)
		_validate_balance_state(
			profile,
			families_by_id[profile.family_id],
			"primary",
			profile.maximum_durability,
			profile.attack,
			profile.defense,
			profile.speed,
			player_state,
			player_stats.maximum_health,
			player_stats.speed,
			registry,
			issues,
		)
		if profile.has_alternate_state:
			_validate_balance_state(
				profile,
				families_by_id[profile.family_id],
				"alternate",
				profile.alternate_maximum_durability,
				profile.alternate_attack,
				profile.alternate_defense,
				profile.alternate_speed,
				player_state,
				player_stats.maximum_health,
				player_stats.speed,
				registry,
				issues,
			)


static func _validate_families(
	families: Array[EnemyFamilyDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var id_counts: Dictionary[StringName, int] = {}
	var ordinal_counts: Dictionary[int, int] = {}
	var source_counts: Dictionary[int, int] = {}
	var visual_counts: Dictionary[StringName, int] = {}
	for family: EnemyFamilyDefinitionScript in families:
		_increment_string_name_count(id_counts, family.family_id)
		_increment_int_count(ordinal_counts, family.ordinal)
		_increment_string_name_count(visual_counts, family.visual_family_id)
		if not _is_valid_family_ordinal(family.ordinal):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_ID_INVALID,
				family.family_id,
				"ordinal",
				"Enemy family ordinal must be in the closed F01-F12 range.",
			)
		else:
			var expected_family_id: StringName = _expected_family_id(family.ordinal)
			if family.family_id != expected_family_id:
				_add_issue(
					issues,
					ContentValidationIssueScript.ENEMY_FAMILY_ID_INVALID,
					family.family_id,
					"family_id",
					"Family ordinal %d requires ID '%s'."
					% [family.ordinal, String(expected_family_id)],
				)
			_expect_family_field(
				issues,
				family,
				"display_name_text_id",
				family.display_name_text_id,
				_expected_family_text_id(family.ordinal),
			)
			_expect_family_field(
				issues,
				family,
				"visual_family_id",
				family.visual_family_id,
				_expected_family_visual_id(family.ordinal),
			)
		if _is_valid_source(family.source):
			_increment_int_count(source_counts, family.source)
		else:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_FIELD_MISMATCH,
				family.family_id,
				"source",
				"Enemy family source must use a declared source enum value.",
			)
		if not _is_valid_numeric_archetype(family.numeric_archetype):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_FIELD_MISMATCH,
				family.family_id,
				"numeric_archetype",
				"Enemy family numeric archetype must use a declared enum value.",
			)
		var regional_role: String = String(family.regional_role_id)
		if (
			not regional_role.begins_with("enemy.role.")
			or regional_role.length() <= "enemy.role.".length()
		):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_FIELD_MISMATCH,
				family.family_id,
				"regional_role_id",
				"Enemy family regional role must use the 'enemy.role.' namespace.",
			)

	_add_duplicate_string_name_issues(
		id_counts,
		ContentValidationIssueScript.ENEMY_FAMILY_ID_DUPLICATE,
		"family_id",
		"Enemy family ID",
		issues,
	)
	_add_duplicate_int_issues(
		ordinal_counts,
		ContentValidationIssueScript.ENEMY_FAMILY_ORDINAL_DUPLICATE,
		"ordinal",
		"Enemy family ordinal",
		issues,
	)
	_add_duplicate_string_name_issues(
		visual_counts,
		ContentValidationIssueScript.ENEMY_FAMILY_VISUAL_ID_DUPLICATE,
		"visual_family_id",
		"Enemy visual family ID",
		issues,
	)
	for source: int in range(
		EnemyFamilyDefinitionScript.Source.LOCAL_FAUNA,
		EnemyFamilyDefinitionScript.Source.ANCIENT_EXECUTOR + 1,
	):
		if source_counts.get(source, 0) != EXPECTED_SOURCE_FAMILY_COUNTS[source - 1]:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_FAMILY_SOURCE_DISTRIBUTION_INVALID,
				&"",
				"families.source",
				"Enemy source %d must have %d families; got %d."
				% [
					source,
					EXPECTED_SOURCE_FAMILY_COUNTS[source - 1],
					source_counts.get(source, 0),
				],
			)


static func _validate_profiles(
	profiles: Array[EnemyProfileDefinitionScript],
	families: Array[EnemyFamilyDefinitionScript],
	route_catalog: RepresentativeRouteCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var families_by_id: Dictionary[StringName, EnemyFamilyDefinitionScript] = {}
	for family: EnemyFamilyDefinitionScript in families:
		families_by_id[family.family_id] = family
	var route_ids: Dictionary[StringName, bool] = {}
	if route_catalog != null:
		for contract in route_catalog.contracts:
			if contract != null:
				route_ids[contract.contract_id] = true

	var id_counts: Dictionary[StringName, int] = {}
	var pair_counts: Dictionary[String, int] = {}
	var visual_counts: Dictionary[StringName, int] = {}
	var behavior_counts: Dictionary[StringName, int] = {}
	var behaviors_by_family: Dictionary[StringName, Dictionary] = {}
	for profile: EnemyProfileDefinitionScript in profiles:
		_increment_string_name_count(id_counts, profile.profile_id)
		_increment_string_name_count(visual_counts, profile.visual_binding_id)
		var pair_key: String = "%s:%d" % [String(profile.family_id), profile.tier]
		pair_counts[pair_key] = pair_counts.get(pair_key, 0) + 1
		var family: EnemyFamilyDefinitionScript = families_by_id.get(
			profile.family_id,
			null,
		)
		if family == null:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_REFERENCE_INVALID,
				profile.profile_id,
				"family_id",
				"Enemy profile references an unknown family.",
			)
		elif not _is_valid_tier(profile.tier):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_ID_INVALID,
				profile.profile_id,
				"tier",
				"Enemy profile tier must be base or enhanced.",
			)
		else:
			var expected_profile_id: StringName = _expected_profile_id(
				family.ordinal,
				profile.tier,
			)
			if profile.profile_id != expected_profile_id:
				_add_issue(
					issues,
					ContentValidationIssueScript.ENEMY_PROFILE_ID_INVALID,
					profile.profile_id,
					"profile_id",
					"Family '%s' tier %d requires profile ID '%s'."
					% [
						String(profile.family_id),
						profile.tier,
						String(expected_profile_id),
					],
				)
			_expect_profile_field(
				issues,
				profile,
				"visual_binding_id",
				profile.visual_binding_id,
				_expected_visual_binding_id(family.ordinal, profile.tier),
			)
			if not behaviors_by_family.has(profile.family_id):
				behaviors_by_family[profile.family_id] = {}
			behaviors_by_family[profile.family_id][profile.behavior_id] = true

		if not _is_valid_source(profile.source):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_REFERENCE_INVALID,
				profile.profile_id,
				"source",
				"Enemy profile source must use a declared source enum value.",
			)
		elif family != null and profile.source != family.source:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_REFERENCE_INVALID,
				profile.profile_id,
				"source",
				"Enemy profile source must match its family source.",
			)
		if not route_ids.has(profile.balance_contract_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_CONTRACT_REFERENCE_INVALID,
				profile.profile_id,
				"balance_contract_id",
				"Enemy profile references an unknown balance route contract.",
			)
		if not ALLOWED_BEHAVIOR_IDS.has(profile.behavior_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BEHAVIOR_ID_INVALID,
				profile.profile_id,
				"behavior_id",
				"Enemy profile uses an unknown behavior binding.",
			)
		else:
			_increment_string_name_count(behavior_counts, profile.behavior_id)
		_validate_profile_traits(profile, issues)
		_validate_profile_state_shape(profile, issues)

	_add_duplicate_string_name_issues(
		id_counts,
		ContentValidationIssueScript.ENEMY_PROFILE_ID_DUPLICATE,
		"profile_id",
		"Enemy profile ID",
		issues,
	)
	_add_duplicate_string_name_issues(
		visual_counts,
		ContentValidationIssueScript.ENEMY_PROFILE_VISUAL_ID_DUPLICATE,
		"visual_binding_id",
		"Enemy visual binding ID",
		issues,
	)
	for behavior_id: StringName in ALLOWED_BEHAVIOR_IDS:
		if behavior_counts.get(behavior_id, 0) != EXPECTED_PROFILES_PER_BEHAVIOR:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BEHAVIOR_ID_INVALID,
				behavior_id,
				"profiles.behavior_id",
				"Behavior '%s' must bind exactly %d profiles; got %d."
				% [
					String(behavior_id),
					EXPECTED_PROFILES_PER_BEHAVIOR,
					behavior_counts.get(behavior_id, 0),
				],
			)
	for ordinal: int in range(1, EXPECTED_FAMILY_COUNT + 1):
		var family_id: StringName = _expected_family_id(ordinal)
		for tier: int in [
			EnemyProfileDefinitionScript.Tier.BASE,
			EnemyProfileDefinitionScript.Tier.ENHANCED,
		]:
			var pair_key: String = "%s:%d" % [String(family_id), tier]
			if pair_counts.get(pair_key, 0) != 1:
				_add_issue(
					issues,
					ContentValidationIssueScript.ENEMY_PROFILE_FAMILY_TIER_PAIR_INVALID,
					family_id,
					"profiles.family_tier",
					"Enemy family '%s' tier %d must have exactly one profile; got %d."
					% [String(family_id), tier, pair_counts.get(pair_key, 0)],
				)
		var family_behaviors: Dictionary = behaviors_by_family.get(family_id, {})
		if family_behaviors.size() != 1:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_BEHAVIOR_ID_INVALID,
				family_id,
				"profiles.behavior_id",
				"A family's base and enhanced profiles must share one behavior binding.",
			)


static func _validate_profile_traits(
	profile: EnemyProfileDefinitionScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var seen: Dictionary[StringName, bool] = {}
	if (
		profile.combat_trait_ids.size()
		> EnemyProfileDefinitionScript.MAXIMUM_COMBAT_TRAIT_COUNT
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID,
			profile.profile_id,
			"combat_trait_ids",
			"Enemy profile may bind at most two combat traits.",
		)
	for trait_id: StringName in profile.combat_trait_ids:
		if not ALLOWED_TRAIT_IDS.has(trait_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID,
				profile.profile_id,
				"combat_trait_ids",
				"Enemy profile uses unknown combat trait '%s'." % String(trait_id),
			)
		if seen.has(trait_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_DUPLICATE,
				profile.profile_id,
				"combat_trait_ids",
				"Enemy combat trait '%s' occurs more than once." % String(trait_id),
			)
		seen[trait_id] = true
	var has_phase_trait: bool = profile.combat_trait_ids.has(
		PHASE_ALTERNATION_TRAIT_ID
	)
	var has_support_trait: bool = profile.combat_trait_ids.has(
		SUPPORT_LINK_TRAIT_ID
	)
	var has_shield_trait: bool = profile.combat_trait_ids.has(SHIELD_TRAIT_ID)
	if (
		(profile.behavior_id == PHASE_ALTERNATION_BEHAVIOR_ID)
		!= has_phase_trait
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID,
			profile.profile_id,
			"combat_trait_ids",
			"Phase-alternation behavior and trait must be bound together.",
		)
	if (profile.behavior_id == SUPPORT_LINK_BEHAVIOR_ID) != has_support_trait:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID,
			profile.profile_id,
			"combat_trait_ids",
			"Support-link behavior and trait must be bound together.",
		)
	if (
		(profile.behavior_id == SHIELD_BEHAVIOR_ID and not has_shield_trait)
		or (
			has_shield_trait
			and profile.behavior_id != SHIELD_BEHAVIOR_ID
			and profile.behavior_id != PHASE_ALTERNATION_BEHAVIOR_ID
		)
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_TRAIT_ID_INVALID,
			profile.profile_id,
			"combat_trait_ids",
			"Shield behavior requires the shield trait; the shield trait is only legal on shield or phase behavior.",
		)


static func _validate_profile_state_shape(
	profile: EnemyProfileDefinitionScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if (
		profile.maximum_durability <= 0
		or profile.attack <= 0
		or profile.defense <= 0
		or profile.speed <= 0
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_STATS_INVALID,
			profile.profile_id,
			"maximum_durability",
			"Enemy primary durability, attack, defense and speed must be positive.",
		)
	var has_phase_trait: bool = profile.combat_trait_ids.has(
		PHASE_ALTERNATION_TRAIT_ID
	)
	if profile.has_alternate_state != has_phase_trait:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_ALTERNATE_STATE_INVALID,
			profile.profile_id,
			"has_alternate_state",
			"Only phase-alternation profiles must define an alternate state.",
		)
	if profile.has_alternate_state:
		if (
			profile.alternate_maximum_durability <= 0
			or profile.alternate_attack <= 0
			or profile.alternate_defense <= 0
			or profile.alternate_speed <= 0
		):
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_ALTERNATE_STATE_INVALID,
				profile.profile_id,
				"alternate_maximum_durability",
				"Enabled alternate durability, attack, defense and speed must be positive.",
			)
	elif (
		profile.alternate_maximum_durability != 0
		or profile.alternate_attack != 0
		or profile.alternate_defense != 0
		or profile.alternate_speed != 0
	):
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_ALTERNATE_STATE_INVALID,
			profile.profile_id,
			"alternate_maximum_durability",
			"Disabled alternate-state fields must remain zero.",
		)


static func _validate_balance_state(
	profile: EnemyProfileDefinitionScript,
	family: EnemyFamilyDefinitionScript,
	state_name: String,
	maximum_durability: int,
	attack: int,
	defense: int,
	speed: int,
	player_state: PlayerProgressionStateScript,
	player_maximum_health: int,
	player_speed: int,
	registry: ContentRegistryScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var has_shield: bool = profile.combat_trait_ids.has(SHIELD_TRAIT_ID)
	var support_count: int = 2 if profile.combat_trait_ids.has(
		SUPPORT_LINK_TRAIT_ID
	) else 0
	var minimum_attack_count: int = 2 if (
		profile.tier == EnemyProfileDefinitionScript.Tier.BASE
	) else 3
	var maximum_attack_count: int = 5 if (
		profile.tier == EnemyProfileDefinitionScript.Tier.BASE
	) else 6
	var worst_health_loss: int = 0
	var evaluated_initiator_count: int = 0
	for initiator_side: int in [
		ContactCombatCommandScript.Side.PLAYER,
		ContactCombatCommandScript.Side.OPPONENT,
	]:
		var no_shield_resolution: ContactCombatResolutionScript = _evaluate_resolution(
			profile,
			state_name,
			maximum_durability,
			attack,
			defense,
			speed,
			false,
			support_count,
			initiator_side,
			player_state,
			registry,
			issues,
		)
		if no_shield_resolution == null:
			continue
		evaluated_initiator_count += 1
		if no_shield_resolution.player_damage_per_attack() < 3:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_PLAYER_DAMAGE_TOO_LOW,
				profile.profile_id,
				"%s.defense" % state_name,
				"Player damage per attack must be at least 3; got %d."
				% no_shield_resolution.player_damage_per_attack(),
			)
		var attack_count: int = no_shield_resolution.player_attacks_required_to_clear()
		if attack_count < minimum_attack_count or attack_count > maximum_attack_count:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_ATTACK_COUNT_INVALID,
				profile.profile_id,
				"%s.maximum_durability" % state_name,
				"Tier requires %d-%d damaging attacks; got %d."
				% [minimum_attack_count, maximum_attack_count, attack_count],
			)

		var actual_resolution: ContactCombatResolutionScript = no_shield_resolution
		if has_shield:
			actual_resolution = _evaluate_resolution(
				profile,
				state_name,
				maximum_durability,
				attack,
				defense,
				speed,
				true,
				support_count,
				initiator_side,
				player_state,
				registry,
				issues,
			)
			if actual_resolution == null:
				continue
			if (
				actual_resolution.player_attacks_required_to_clear()
				!= attack_count + 1
			):
				_add_issue(
					issues,
					ContentValidationIssueScript.ENEMY_PROFILE_SHIELD_ATTACK_DELTA_INVALID,
					profile.profile_id,
					"combat_trait_ids",
					"Shield must add exactly one required player attack.",
				)
		if actual_resolution.outcome() != ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED:
			_add_issue(
				issues,
				ContentValidationIssueScript.ENEMY_PROFILE_NOT_CLEARABLE,
				profile.profile_id,
				"%s.attack" % state_name,
				"The mainline-minimum player must clear this state for either initiator.",
			)
		worst_health_loss = max(
			worst_health_loss,
			actual_resolution.player_health_loss(),
		)

	if evaluated_initiator_count == 0:
		return
	var maximum_loss_percent: int
	if (
		profile.combat_trait_ids.size()
		>= EnemyProfileDefinitionScript.MAXIMUM_COMBAT_TRAIT_COUNT
	):
		maximum_loss_percent = 30
	elif not profile.combat_trait_ids.is_empty():
		maximum_loss_percent = 25
	elif profile.tier == EnemyProfileDefinitionScript.Tier.ENHANCED:
		maximum_loss_percent = 20
	else:
		maximum_loss_percent = 15
	if worst_health_loss * 100 > player_maximum_health * maximum_loss_percent:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_HEALTH_LOSS_INVALID,
			profile.profile_id,
			"%s.attack" % state_name,
			"Worst-case loss %d/%d exceeds the %d-percent profile cap."
			% [worst_health_loss, player_maximum_health, maximum_loss_percent],
		)

	var requires_speed_plus_one: bool = (
		family.numeric_archetype == EnemyFamilyDefinitionScript.NumericArchetype.SPEED
		or (
			family.numeric_archetype
			== EnemyFamilyDefinitionScript.NumericArchetype.DEFENSE_TO_SPEED
			and profile.tier == EnemyProfileDefinitionScript.Tier.ENHANCED
		)
	)
	if requires_speed_plus_one and speed != player_speed + 1:
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_SPEED_ARCHETYPE_INVALID,
			profile.profile_id,
			"%s.speed" % state_name,
			"High-speed state must equal mainline-minimum speed plus one; expected %d, got %d."
			% [player_speed + 1, speed],
		)


static func _evaluate_resolution(
	profile: EnemyProfileDefinitionScript,
	state_name: String,
	maximum_durability: int,
	attack: int,
	defense: int,
	speed: int,
	shield_intact: bool,
	support_count: int,
	initiator_side: int,
	player_state: PlayerProgressionStateScript,
	registry: ContentRegistryScript,
	issues: Array[ContentValidationIssueScript],
) -> ContactCombatResolutionScript:
	var opponent_state := ContactCombatOpponentStateScript.create(
		StringName("%s.%s" % [String(profile.profile_id), state_name]),
		maximum_durability,
		maximum_durability,
		attack,
		defense,
		speed,
		shield_intact,
	)
	var command := ContactCombatCommandScript.evaluate(
		initiator_side,
		ContactCombatCommandScript.TemporaryEffect.NONE,
		support_count,
	)
	var result = ContactCombatKernelScript.evaluate(
		player_state,
		opponent_state,
		command,
		registry,
	)
	if not result.is_resolution_candidate():
		_add_issue(
			issues,
			ContentValidationIssueScript.ENEMY_PROFILE_BALANCE_EVALUATION_FAILED,
			profile.profile_id,
			"%s" % state_name,
			"Contact-combat kernel could not evaluate enemy state '%s' for initiator %d."
			% [state_name, initiator_side],
		)
		return null
	return result.resolution()


static func _expect_family_field(
	issues: Array[ContentValidationIssueScript],
	family: EnemyFamilyDefinitionScript,
	field_path: String,
	actual: Variant,
	expected: Variant,
) -> void:
	if actual == expected:
		return
	_add_issue(
		issues,
		ContentValidationIssueScript.ENEMY_FAMILY_FIELD_MISMATCH,
		family.family_id,
		field_path,
		"Enemy family structural field '%s' expected %s, got %s."
		% [field_path, str(expected), str(actual)],
	)


static func _expect_profile_field(
	issues: Array[ContentValidationIssueScript],
	profile: EnemyProfileDefinitionScript,
	field_path: String,
	actual: Variant,
	expected: Variant,
) -> void:
	if actual == expected:
		return
	_add_issue(
		issues,
		ContentValidationIssueScript.ENEMY_PROFILE_FIELD_MISMATCH,
		profile.profile_id,
		field_path,
		"Enemy profile structural field '%s' expected %s, got %s."
		% [field_path, str(expected), str(actual)],
	)


static func _expected_family_id(ordinal: int) -> StringName:
	return StringName("enemy.family.f%02d" % ordinal)


static func _expected_family_text_id(ordinal: int) -> StringName:
	return StringName("text.enemy.family.f%02d.name" % ordinal)


static func _expected_family_visual_id(ordinal: int) -> StringName:
	return StringName("enemy.visual.family.f%02d" % ordinal)


static func _expected_profile_id(ordinal: int, tier: int) -> StringName:
	return StringName(
		"enemy.profile.f%02d.%s" % [ordinal, _tier_name(tier)]
	)


static func _expected_visual_binding_id(ordinal: int, tier: int) -> StringName:
	return StringName(
		"enemy.visual.variant.f%02d.%s" % [ordinal, _tier_name(tier)]
	)


static func _tier_name(tier: int) -> String:
	return (
		"base"
		if tier == EnemyProfileDefinitionScript.Tier.BASE
		else "enhanced"
	)


static func _is_valid_family_ordinal(ordinal: int) -> bool:
	return ordinal >= 1 and ordinal <= EXPECTED_FAMILY_COUNT


static func _is_valid_source(source: int) -> bool:
	return (
		source >= EnemyFamilyDefinitionScript.Source.LOCAL_FAUNA
		and source <= EnemyFamilyDefinitionScript.Source.ANCIENT_EXECUTOR
	)


static func _is_valid_numeric_archetype(archetype: int) -> bool:
	return (
		archetype >= EnemyFamilyDefinitionScript.NumericArchetype.BALANCED
		and archetype <= EnemyFamilyDefinitionScript.NumericArchetype.DEFENSE_TO_SPEED
	)


static func _is_valid_tier(tier: int) -> bool:
	return (
		tier == EnemyProfileDefinitionScript.Tier.BASE
		or tier == EnemyProfileDefinitionScript.Tier.ENHANCED
	)


static func _add_duplicate_string_name_issues(
	counts: Dictionary[StringName, int],
	code: StringName,
	field_path: String,
	label: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var values: Array[StringName] = []
	for value: StringName in counts:
		if not String(value).is_empty() and counts[value] > 1:
			values.append(value)
	values.sort_custom(_string_name_less_than)
	for value: StringName in values:
		_add_issue(
			issues,
			code,
			value,
			field_path,
			"%s '%s' occurs %d times." % [label, String(value), counts[value]],
		)


static func _add_duplicate_int_issues(
	counts: Dictionary[int, int],
	code: StringName,
	field_path: String,
	label: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var values: Array[int] = []
	for value: int in counts:
		if counts[value] > 1:
			values.append(value)
	values.sort()
	for value: int in values:
		_add_issue(
			issues,
			code,
			StringName(str(value)),
			field_path,
			"%s %d occurs %d times." % [label, value, counts[value]],
		)


static func _increment_string_name_count(
	counts: Dictionary[StringName, int],
	value: StringName,
) -> void:
	counts[value] = counts.get(value, 0) + 1


static func _increment_int_count(counts: Dictionary[int, int], value: int) -> void:
	counts[value] = counts.get(value, 0) + 1


static func _add_issue(
	issues: Array[ContentValidationIssueScript],
	code: StringName,
	content_id: StringName,
	field_path: String,
	message: String,
) -> void:
	issues.append(
		ContentValidationIssueScript.new(code, content_id, field_path, message)
	)


static func _family_less_than(
	left: EnemyFamilyDefinitionScript,
	right: EnemyFamilyDefinitionScript,
) -> bool:
	return String(left.family_id) < String(right.family_id)


static func _profile_less_than(
	left: EnemyProfileDefinitionScript,
	right: EnemyProfileDefinitionScript,
) -> bool:
	return String(left.profile_id) < String(right.profile_id)


static func _string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
