class_name RepresentativeRouteContractValidator
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const RepresentativeRouteContractScript := preload(
	"res://src/content/definitions/representative_route_contract_resource.gd"
)
const RepresentativeRouteCatalogScript := preload(
	"res://src/content/definitions/representative_route_contract_catalog_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const ContentContractConstantsScript := preload(
	"res://src/content/content_contract_constants.gd"
)

const EXPECTED_CATALOG_ID: StringName = &"route.contract.catalog.main"
const EXPECTED_CONTRACT_IDS: Array[StringName] = [
	&"route.contract.main.stage.01_02",
	&"route.contract.main.stage.03_04",
	&"route.contract.main.stage.05_06",
	&"route.contract.main.stage.07_08",
	&"route.contract.main.stage.09",
]
const EXPECTED_STAGE_STARTS: Array[int] = [1, 3, 5, 7, 9]
const EXPECTED_STAGE_ENDS: Array[int] = [2, 4, 6, 8, 9]
const EXPECTED_BACKPACK_CAPACITIES: Array[int] = [12, 16, 20, 24, 24]
const EXPECTED_TRADEOFF_DIMENSION_IDS: Array[StringName] = [
	&"route.cost.block",
	&"route.cost.consumable",
	&"route.cost.detour",
	&"route.cost.health",
	&"route.cost.one_time_node",
	&"route.cost.optional_reward",
]
# 冻结的代表性路线合同参数值（每个合同资源必须声明的硬性数值边界）：
# - 主线遇敌组目标 8-12 个、硬上限 14 个；
# - 低损路线接触 3-5 次、直觉路线接触 5-7 次；
# - 出图血量下限：低损 40%、直觉 25%；
# - 固定恢复点恰好 2 个、每个恢复 50 点生命；
# - 合同声明的合法路线与配装数量下限各 2 个、至少 2 个独立取舍维度。
const EXPECTED_ENCOUNTER_GROUP_MINIMUM: int = 8
const EXPECTED_ENCOUNTER_GROUP_MAXIMUM: int = 12
const EXPECTED_ENCOUNTER_GROUP_HARD_CAP: int = 14
const EXPECTED_LOW_LOSS_CONTACT_MINIMUM: int = 3
const EXPECTED_LOW_LOSS_CONTACT_MAXIMUM: int = 5
const EXPECTED_INTUITIVE_CONTACT_MINIMUM: int = 5
const EXPECTED_INTUITIVE_CONTACT_MAXIMUM: int = 7
const EXPECTED_LOW_LOSS_MINIMUM_EXIT_HEALTH_PERCENT: int = 40
const EXPECTED_INTUITIVE_MINIMUM_EXIT_HEALTH_PERCENT: int = 25
const EXPECTED_FIXED_RECOVERY_POINT_COUNT: int = 2
const EXPECTED_FIXED_RECOVERY_HEALTH_AMOUNT: int = 50
const EXPECTED_MINIMUM_LEGAL_ROUTE_COUNT: int = 2
const EXPECTED_MINIMUM_LEGAL_LOADOUT_COUNT: int = 2
const EXPECTED_MINIMUM_DISTINCT_TRADEOFF_DIMENSIONS: int = 2


static func snapshot_and_validate(
	raw_catalog: Resource,
	blueprints: Array[BlueprintDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> RepresentativeRouteCatalogScript:
	var issue_count_before: int = issues.size()
	if raw_catalog == null:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_ROUTE_CONTRACT_CATALOG_NULL,
			&"",
			"representative_route_contract_catalog",
			"Representative route contract catalog is null.",
		)
		return null
	if raw_catalog.get_script() != RepresentativeRouteCatalogScript:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CATALOG_INVALID_SCRIPT,
			&"",
			"representative_route_contract_catalog",
			"Route catalog must use the exact authoritative catalog script.",
		)
		return null

	var exact_catalog: RepresentativeRouteCatalogScript = (
		raw_catalog as RepresentativeRouteCatalogScript
	)
	if exact_catalog.contracts.size() != EXPECTED_CONTRACT_IDS.size():
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CONTRACT_COUNT_INVALID,
			exact_catalog.catalog_id,
			"contracts",
			"Expected %d representative route contracts, got %d."
			% [EXPECTED_CONTRACT_IDS.size(), exact_catalog.contracts.size()],
		)
		return null
	if exact_catalog.catalog_id != EXPECTED_CATALOG_ID:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CATALOG_ID_INVALID,
			exact_catalog.catalog_id,
			"catalog_id",
			"Expected route catalog ID '%s', got '%s'."
			% [String(EXPECTED_CATALOG_ID), String(exact_catalog.catalog_id)],
		)

	var snapshots: Array[RepresentativeRouteContractScript] = []
	for index: int in range(exact_catalog.contracts.size()):
		var contract: RepresentativeRouteContractScript = exact_catalog.contracts[index]
		var field_path: String = "contracts[%d]" % index
		if contract == null:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.ROUTE_CONTRACT_ENTRY_NULL,
				&"",
				field_path,
				"Representative route contract entry is null.",
			)
			continue
		if contract.get_script() != RepresentativeRouteContractScript:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.ROUTE_CONTRACT_ENTRY_INVALID_SCRIPT,
				contract.contract_id,
				field_path,
				"Route contract must use the exact authoritative definition script.",
			)
			continue
		var snapshot: RepresentativeRouteContractScript = (
			RepresentativeRouteContractScript.snapshot(contract)
		)
		snapshot.mainline_progression_reference_ids.sort_custom(
			ContentValidationSupportScript.string_name_less_than
		)
		snapshot.available_blueprint_reference_ids.sort_custom(
			ContentValidationSupportScript.string_name_less_than
		)
		snapshot.tradeoff_dimension_ids.sort_custom(
			ContentValidationSupportScript.string_name_less_than
		)
		snapshots.append(snapshot)

	_validate_contracts(snapshots, blueprints, progression_catalog, issues)
	if issues.size() != issue_count_before:
		return null
	snapshots.sort_custom(_contract_less_than)
	var result := RepresentativeRouteCatalogScript.new()
	result.catalog_id = exact_catalog.catalog_id
	for contract: RepresentativeRouteContractScript in snapshots:
		result.contracts.append(contract)
	return result


static func _validate_contracts(
	contracts: Array[RepresentativeRouteContractScript],
	blueprints: Array[BlueprintDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var id_counts: Dictionary[StringName, int] = {}
	var chapter_counts: Dictionary[int, int] = {}
	for contract: RepresentativeRouteContractScript in contracts:
		ContentValidationSupportScript.increment_string_name_count(
			id_counts, contract.contract_id
		)
		_validate_contract_fields(contract, blueprints, progression_catalog, issues)
		if (
			contract.stage_start_chapter >= 1
			and contract.stage_end_chapter
			<= ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER
			and contract.stage_start_chapter <= contract.stage_end_chapter
		):
			for chapter: int in range(
				contract.stage_start_chapter,
				contract.stage_end_chapter + 1,
			):
				chapter_counts[chapter] = chapter_counts.get(chapter, 0) + 1

	ContentValidationSupportScript.add_duplicate_string_name_issues(
		id_counts,
		ContentValidationIssueScript.ROUTE_CONTRACT_ID_DUPLICATE,
		"contract_id",
		"Route contract ID",
		issues,
	)
	for chapter: int in range(
		1, ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER + 1
	):
		if chapter_counts.get(chapter, 0) != 1:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.ROUTE_CHAPTER_COVERAGE_INVALID,
				StringName(str(chapter)),
				"contracts.chapter_coverage",
				"Chapter %d must be covered exactly once; got %d."
				% [chapter, chapter_counts.get(chapter, 0)],
			)


static func _validate_contract_fields(
	contract: RepresentativeRouteContractScript,
	blueprints: Array[BlueprintDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var contract_id: StringName = contract.contract_id
	if contract_id == &"":
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CONTRACT_ID_EMPTY,
			contract_id,
			"contract_id",
			"Route contract ID cannot be empty.",
		)
	var expected_index: int = EXPECTED_CONTRACT_IDS.find(contract_id)
	if expected_index < 0:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CONTRACT_ID_INVALID,
			contract_id,
			"contract_id",
			"Route contract ID '%s' is not in the frozen v1 catalog."
			% String(contract_id),
		)
	if (
		contract.stage_start_chapter < 1
		or contract.stage_end_chapter
		> ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER
		or contract.stage_start_chapter > contract.stage_end_chapter
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_STAGE_RANGE_INVALID,
			contract_id,
			"stage_start_chapter",
			"Route stage must be an inclusive non-empty range within chapters 1 through 9.",
		)
	if expected_index >= 0:
		if (
			contract.stage_start_chapter != EXPECTED_STAGE_STARTS[expected_index]
			or contract.stage_end_chapter != EXPECTED_STAGE_ENDS[expected_index]
		):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.ROUTE_CONTRACT_ID_STAGE_MISMATCH,
				contract_id,
				"stage_end_chapter",
				"Route contract ID does not match its frozen inclusive stage range.",
			)
		if contract.backpack_slot_capacity != EXPECTED_BACKPACK_CAPACITIES[expected_index]:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.ROUTE_BACKPACK_CAPACITY_INVALID,
				contract_id,
				"backpack_slot_capacity",
				"Expected backpack capacity %d at this stage boundary, got %d."
				% [
					EXPECTED_BACKPACK_CAPACITIES[expected_index],
					contract.backpack_slot_capacity,
				],
			)

	_validate_cross_domain_references(contract, blueprints, progression_catalog, issues)
	if (
		contract.encounter_group_minimum != EXPECTED_ENCOUNTER_GROUP_MINIMUM
		or contract.encounter_group_maximum != EXPECTED_ENCOUNTER_GROUP_MAXIMUM
		or contract.encounter_group_hard_cap != EXPECTED_ENCOUNTER_GROUP_HARD_CAP
		or contract.encounter_group_minimum > contract.encounter_group_maximum
		or contract.encounter_group_maximum > contract.encounter_group_hard_cap
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_ENCOUNTER_RANGE_INVALID,
			contract_id,
			"encounter_group_minimum",
			"Mainline route encounter targets must be 8 through 12 with hard cap 14.",
		)
	if (
		contract.low_loss_contact_minimum != EXPECTED_LOW_LOSS_CONTACT_MINIMUM
		or contract.low_loss_contact_maximum != EXPECTED_LOW_LOSS_CONTACT_MAXIMUM
		or contract.intuitive_contact_minimum
		!= EXPECTED_INTUITIVE_CONTACT_MINIMUM
		or contract.intuitive_contact_maximum
		!= EXPECTED_INTUITIVE_CONTACT_MAXIMUM
		or contract.low_loss_contact_minimum > contract.low_loss_contact_maximum
		or contract.intuitive_contact_minimum > contract.intuitive_contact_maximum
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_CONTACT_RANGE_INVALID,
			contract_id,
			"low_loss_contact_minimum",
			"Low-loss contacts must be 3 through 5 and intuitive contacts 5 through 7.",
		)
	if (
		contract.low_loss_minimum_exit_health_percent
		!= EXPECTED_LOW_LOSS_MINIMUM_EXIT_HEALTH_PERCENT
		or contract.intuitive_minimum_exit_health_percent
		!= EXPECTED_INTUITIVE_MINIMUM_EXIT_HEALTH_PERCENT
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_EXIT_HEALTH_THRESHOLD_INVALID,
			contract_id,
			"low_loss_minimum_exit_health_percent",
			"Minimum exit health must be 40 percent for low-loss and 25 percent for intuitive routes.",
		)
	if (
		contract.minimum_fixed_recovery_points
		!= EXPECTED_FIXED_RECOVERY_POINT_COUNT
		or contract.fixed_recovery_amount
		!= EXPECTED_FIXED_RECOVERY_HEALTH_AMOUNT
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_RECOVERY_POINT_COUNT_INVALID,
			contract_id,
			"minimum_fixed_recovery_points",
			"Mainline route contracts require at least two fixed 50-health recovery points.",
		)
	if (
		contract.minimum_legal_route_count != EXPECTED_MINIMUM_LEGAL_ROUTE_COUNT
		or contract.minimum_legal_loadout_count
		!= EXPECTED_MINIMUM_LEGAL_LOADOUT_COUNT
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_LEGAL_ALTERNATIVE_COUNT_INVALID,
			contract_id,
			"minimum_legal_route_count",
			"Each contract requires at least two legal routes and two legal loadouts.",
		)
	if (
		contract.tradeoff_dimension_ids != EXPECTED_TRADEOFF_DIMENSION_IDS
		or contract.minimum_distinct_tradeoff_dimensions
		!= EXPECTED_MINIMUM_DISTINCT_TRADEOFF_DIMENSIONS
	):
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_TRADEOFF_DIMENSION_INVALID,
			contract_id,
			"tradeoff_dimension_ids",
			"Route tradeoffs must use all six frozen dimensions and require at least two distinct dimensions.",
		)
	if not contract.requires_non_dominated_route_set:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_DOMINANCE_POLICY_INVALID,
			contract_id,
			"requires_non_dominated_route_set",
			"The contract must prohibit a globally dominant route.",
		)


static func _validate_cross_domain_references(
	contract: RepresentativeRouteContractScript,
	blueprints: Array[BlueprintDefinitionScript],
	progression_catalog: GlobalProgressionCatalogScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if progression_catalog == null:
		return
	if contract.player_profile_id != progression_catalog.initial_stats.profile_id:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_PLAYER_PROFILE_REFERENCE_INVALID,
			contract.contract_id,
			"player_profile_id",
			"Route contract must reference the authoritative player profile.",
		)
	var expected_progression_ids: Array[StringName] = []
	for definition in progression_catalog.mainline_progression:
		if definition != null and definition.chapter <= contract.stage_end_chapter:
			expected_progression_ids.append(definition.content_id)
	expected_progression_ids.sort_custom(
		ContentValidationSupportScript.string_name_less_than
	)
	if contract.mainline_progression_reference_ids != expected_progression_ids:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_PROGRESSION_REFERENCE_INVALID,
			contract.contract_id,
			"mainline_progression_reference_ids",
			"Mainline progression references must exactly match the stage-end derivation.",
		)
	var expected_blueprint_ids: Array[StringName] = []
	for blueprint: BlueprintDefinitionScript in blueprints:
		if blueprint != null and blueprint.unlock_chapter <= contract.stage_end_chapter:
			expected_blueprint_ids.append(blueprint.content_id)
	expected_blueprint_ids.sort_custom(
		ContentValidationSupportScript.string_name_less_than
	)
	if contract.available_blueprint_reference_ids != expected_blueprint_ids:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.ROUTE_BLUEPRINT_REFERENCE_INVALID,
			contract.contract_id,
			"available_blueprint_reference_ids",
			"Available blueprint references must exactly match the stage-end derivation.",
		)


static func _contract_less_than(
	left: RepresentativeRouteContractScript,
	right: RepresentativeRouteContractScript,
) -> bool:
	return String(left.contract_id) < String(right.contract_id)
