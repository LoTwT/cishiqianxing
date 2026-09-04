class_name GlobalProgressionValidator
extends RefCounted

const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const MainlineProgressionDefinitionScript := preload(
	"res://src/content/definitions/mainline_progression_definition_resource.gd"
)
const OptionalProgressionDefinitionScript := preload(
	"res://src/content/definitions/optional_progression_definition_resource.gd"
)
const PermanentGrowthRewardDefinitionScript := preload(
	"res://src/content/definitions/permanent_growth_reward_definition_resource.gd"
)
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)
const ContentValidationSupportScript := preload(
	"res://src/content/content_validation_support.gd"
)
const PermanentGrowthArithmeticScript := preload(
	"res://src/rules/permanent_growth_arithmetic.gd"
)
const ContentContractConstantsScript := preload(
	"res://src/content/content_contract_constants.gd"
)

const EXPECTED_CATALOG_ID: StringName = &"progression.global"
const EXPECTED_PROFILE_ID: StringName = &"progression.player.loer"
# 冻结内容合同期望计数的再导出：权威数值只在 content_contract_constants.gd
# 定义一次，此处保留原常量名以维持调用点稳定。
const EXPECTED_MAINLINE_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_MAINLINE_PROGRESSION_COUNT
)
const EXPECTED_OPTIONAL_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_OPTIONAL_PROGRESSION_COUNT
)
const EXPECTED_REWARD_COUNT: int = (
	ContentContractConstantsScript.EXPECTED_PERMANENT_GROWTH_REWARD_COUNT
)
const EXPECTED_INITIAL_STATS: Array[int] = [100, 10, 5, 10]
const EXPECTED_MAINLINE_IDS: Array[StringName] = [
	&"progression.main.chapter.01",
	&"progression.main.chapter.02",
	&"progression.main.chapter.03",
	&"progression.main.chapter.04",
	&"progression.main.chapter.05",
	&"progression.main.chapter.06",
	&"progression.main.chapter.07",
	&"progression.main.chapter.08",
	&"progression.main.chapter.09",
]
# 逐章累计属性 oracle。与 EXPECTED_MAINLINE_FINAL_STATS（其值等于本表最后一行）
# 是刻意独立的双重编码：两处各自单独声明，一处改动而另一处不动时测试失败，
# 这是交叉校验强度而非冗余，不得改写为推导生成。
const EXPECTED_MAINLINE_TOTALS: Array[int] = [
	110, 11, 5, 10,
	120, 11, 6, 10,
	130, 12, 7, 10,
	140, 13, 8, 11,
	150, 14, 9, 11,
	160, 15, 9, 12,
	170, 15, 10, 13,
	180, 16, 11, 13,
	180, 16, 11, 14,
]
const EXPECTED_OPTIONAL_IDS: Array[StringName] = [
	&"progression.optional.m01",
	&"progression.optional.m02",
	&"progression.optional.m03",
	&"progression.optional.m04",
]
const EXPECTED_OPTIONAL_MAP_IDS: Array[StringName] = [&"M01", &"M02", &"M03", &"M04"]
const EXPECTED_OPTIONAL_AVAILABLE_CHAPTERS: Array[int] = [2, 4, 6, 8]
const EXPECTED_REWARD_IDS: Array[StringName] = [
	&"progression.reward.main.chapter.01.maximum_health",
	&"progression.reward.main.chapter.01.attack",
	&"progression.reward.main.chapter.02.maximum_health",
	&"progression.reward.main.chapter.02.defense",
	&"progression.reward.main.chapter.03.maximum_health",
	&"progression.reward.main.chapter.03.attack",
	&"progression.reward.main.chapter.03.defense",
	&"progression.reward.main.chapter.04.maximum_health",
	&"progression.reward.main.chapter.04.attack",
	&"progression.reward.main.chapter.04.defense",
	&"progression.reward.main.chapter.04.speed",
	&"progression.reward.main.chapter.05.maximum_health",
	&"progression.reward.main.chapter.05.attack",
	&"progression.reward.main.chapter.05.defense",
	&"progression.reward.main.chapter.06.maximum_health",
	&"progression.reward.main.chapter.06.attack",
	&"progression.reward.main.chapter.06.speed",
	&"progression.reward.main.chapter.07.maximum_health",
	&"progression.reward.main.chapter.07.defense",
	&"progression.reward.main.chapter.07.speed",
	&"progression.reward.main.chapter.08.maximum_health",
	&"progression.reward.main.chapter.08.attack",
	&"progression.reward.main.chapter.08.defense",
	&"progression.reward.main.chapter.09.speed",
	&"progression.reward.optional.m01.maximum_health",
	&"progression.reward.optional.m02.attack",
	&"progression.reward.optional.m03.maximum_health",
	&"progression.reward.optional.m03.defense",
	&"progression.reward.optional.m04.attack",
	&"progression.reward.optional.m04.defense",
]
const EXPECTED_REWARD_STAT_KINDS: Array[int] = [
	1, 2,
	1, 3,
	1, 2, 3,
	1, 2, 3, 4,
	1, 2, 3,
	1, 2, 4,
	1, 3, 4,
	1, 2, 3,
	4,
	1,
	2,
	1, 3,
	2, 3,
]
const EXPECTED_REWARD_INCREASES: Array[int] = [
	10, 1,
	10, 1,
	10, 1, 1,
	10, 1, 1, 1,
	10, 1, 1,
	10, 1, 1,
	10, 1, 1,
	10, 1, 1,
	1,
	10,
	1,
	10, 1,
	1, 1,
]
# 聚合合同交叉校验 oracle：奖励计数按 stat_kind 1-4（生命/攻击/防御/速度）
# 排序；终值为完成主线九章（不含支线）与全内容通关时的四维属性终值。
# EXPECTED_MAINLINE_FINAL_STATS 与上方 EXPECTED_MAINLINE_TOTALS 最后一行
# 刻意独立编码：一处改动而另一处不动时测试失败，这是交叉校验强度而非冗余。
const EXPECTED_MAINLINE_REWARD_COUNTS_BY_STAT_KIND: Array[int] = [8, 6, 6, 4]
const EXPECTED_MAINLINE_FINAL_STATS: Array[int] = [180, 16, 11, 14]
const EXPECTED_OPTIONAL_REWARD_COUNTS_BY_STAT_KIND: Array[int] = [2, 2, 2, 0]
const EXPECTED_FULL_COMPLETION_STATS: Array[int] = [200, 18, 13, 14]


static func snapshot_and_validate(
	catalog_resource: Resource,
	issues: Array[ContentValidationIssueScript],
) -> GlobalProgressionCatalogScript:
	var initial_issue_count: int = issues.size()
	if catalog_resource == null:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_PROGRESSION_CATALOG_NULL,
			&"",
			"global_progression_catalog",
			"Global progression catalog is null.",
		)
		return null
	if catalog_resource.get_script() != GlobalProgressionCatalogScript:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_CATALOG_INVALID_SCRIPT,
			&"",
			"global_progression_catalog",
			"Global progression catalog must use the exact authoritative script.",
		)
		return null

	var catalog: GlobalProgressionCatalogScript = (
		catalog_resource as GlobalProgressionCatalogScript
	)
	var mainline_count: int = catalog.mainline_progression.size()
	var optional_count: int = catalog.optional_progression.size()
	var reward_count: int = catalog.permanent_growth_rewards.size()
	_validate_bounded_counts(
		catalog.catalog_id,
		mainline_count,
		optional_count,
		reward_count,
		issues,
	)
	if (
		mainline_count != EXPECTED_MAINLINE_COUNT
		or optional_count != EXPECTED_OPTIONAL_COUNT
		or reward_count != EXPECTED_REWARD_COUNT
	):
		return null

	if catalog.catalog_id != EXPECTED_CATALOG_ID:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_CATALOG_ID_INVALID,
			catalog.catalog_id,
			"global_progression_catalog.catalog_id",
			"Expected global progression catalog ID '%s', got '%s'."
			% [String(EXPECTED_CATALOG_ID), String(catalog.catalog_id)],
		)

	var initial_stats: PlayerStatProfileScript = _snapshot_initial_stats(
		catalog.initial_stats as Resource,
		issues,
	)
	var mainline_progression: Array[MainlineProgressionDefinitionScript] = (
		_snapshot_mainline_progression(catalog.mainline_progression, issues)
	)
	var optional_progression: Array[OptionalProgressionDefinitionScript] = (
		_snapshot_optional_progression(catalog.optional_progression, issues)
	)
	var rewards: Array[PermanentGrowthRewardDefinitionScript] = (
		_snapshot_rewards(catalog.permanent_growth_rewards, issues)
	)
	if initial_stats != null:
		_validate_initial_stats(initial_stats, issues)
	_validate_mainline_progression(mainline_progression, issues)
	_validate_optional_progression(optional_progression, issues)
	_validate_rewards(rewards, issues)
	_validate_reward_references(
		mainline_progression,
		optional_progression,
		rewards,
		issues,
	)
	if issues.size() == initial_issue_count:
		_validate_aggregate_contract(
			initial_stats,
			mainline_progression,
			optional_progression,
			rewards,
			issues,
		)
	if issues.size() != initial_issue_count:
		return null

	mainline_progression.sort_custom(_mainline_less_than)
	optional_progression.sort_custom(_optional_less_than)
	rewards.sort_custom(_reward_less_than)
	for definition: MainlineProgressionDefinitionScript in mainline_progression:
		definition.reward_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	for definition: OptionalProgressionDefinitionScript in optional_progression:
		definition.reward_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	var snapshot := GlobalProgressionCatalogScript.new()
	snapshot.catalog_id = catalog.catalog_id
	snapshot.initial_stats = PlayerStatProfileScript.snapshot(initial_stats)
	for definition: MainlineProgressionDefinitionScript in mainline_progression:
		snapshot.mainline_progression.append(
			MainlineProgressionDefinitionScript.snapshot(definition)
		)
	for definition: OptionalProgressionDefinitionScript in optional_progression:
		snapshot.optional_progression.append(
			OptionalProgressionDefinitionScript.snapshot(definition)
		)
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		snapshot.permanent_growth_rewards.append(
			PermanentGrowthRewardDefinitionScript.snapshot(reward)
		)
	return snapshot


static func _validate_bounded_counts(
	catalog_id: StringName,
	mainline_count: int,
	optional_count: int,
	reward_count: int,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if mainline_count != EXPECTED_MAINLINE_COUNT:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_COUNT_INVALID,
			catalog_id,
			"global_progression_catalog.mainline_progression",
			"Expected %d mainline progression bundles, got %d."
			% [EXPECTED_MAINLINE_COUNT, mainline_count],
		)
	if optional_count != EXPECTED_OPTIONAL_COUNT:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_COUNT_INVALID,
			catalog_id,
			"global_progression_catalog.optional_progression",
			"Expected %d optional progression bundles, got %d."
			% [EXPECTED_OPTIONAL_COUNT, optional_count],
		)
	if reward_count != EXPECTED_REWARD_COUNT:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_REWARD_COUNT_INVALID,
			catalog_id,
			"global_progression_catalog.permanent_growth_rewards",
			"Expected %d permanent growth rewards, got %d."
			% [EXPECTED_REWARD_COUNT, reward_count],
		)


static func _snapshot_initial_stats(
	profile_resource: Resource,
	issues: Array[ContentValidationIssueScript],
) -> PlayerStatProfileScript:
	if profile_resource == null:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_NULL,
			&"",
			"global_progression_catalog.initial_stats",
			"Initial player stat profile is null.",
		)
		return null
	if profile_resource.get_script() != PlayerStatProfileScript:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_INVALID_SCRIPT,
			&"",
			"global_progression_catalog.initial_stats",
			"Initial player stat profile must use the exact authoritative script.",
		)
		return null
	return PlayerStatProfileScript.snapshot(
		profile_resource as PlayerStatProfileScript
	)


static func _snapshot_mainline_progression(
	definitions: Array[MainlineProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> Array[MainlineProgressionDefinitionScript]:
	var snapshots: Array[MainlineProgressionDefinitionScript] = []
	for index: int in range(definitions.size()):
		var definition_resource: Resource = definitions[index] as Resource
		var field_path: String = (
			"global_progression_catalog.mainline_progression[%d]" % index
		)
		if definition_resource == null:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_NULL,
				&"",
				field_path,
				"Mainline progression entry is null.",
			)
			continue
		if definition_resource.get_script() != MainlineProgressionDefinitionScript:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Mainline progression entry must use the exact authoritative script.",
			)
			continue
		if definitions[index].reward_ids.size() > 8:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
				definitions[index].content_id,
				"mainline_progression.reward_ids",
				"Mainline reward membership exceeds the bounded contract.",
			)
			continue
		snapshots.append(
			MainlineProgressionDefinitionScript.snapshot(definitions[index])
		)
	return snapshots


static func _snapshot_optional_progression(
	definitions: Array[OptionalProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> Array[OptionalProgressionDefinitionScript]:
	var snapshots: Array[OptionalProgressionDefinitionScript] = []
	for index: int in range(definitions.size()):
		var definition_resource: Resource = definitions[index] as Resource
		var field_path: String = (
			"global_progression_catalog.optional_progression[%d]" % index
		)
		if definition_resource == null:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_NULL,
				&"",
				field_path,
				"Optional progression entry is null.",
			)
			continue
		if definition_resource.get_script() != OptionalProgressionDefinitionScript:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Optional progression entry must use the exact authoritative script.",
			)
			continue
		if definitions[index].reward_ids.size() > 8:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
				definitions[index].content_id,
				"optional_progression.reward_ids",
				"Optional reward membership exceeds the bounded contract.",
			)
			continue
		snapshots.append(
			OptionalProgressionDefinitionScript.snapshot(definitions[index])
		)
	return snapshots


static func _snapshot_rewards(
	rewards: Array[PermanentGrowthRewardDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> Array[PermanentGrowthRewardDefinitionScript]:
	var snapshots: Array[PermanentGrowthRewardDefinitionScript] = []
	for index: int in range(rewards.size()):
		var reward_resource: Resource = rewards[index] as Resource
		var field_path: String = (
			"global_progression_catalog.permanent_growth_rewards[%d]" % index
		)
		if reward_resource == null:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_ENTRY_NULL,
				&"",
				field_path,
				"Permanent growth reward entry is null.",
			)
			continue
		if reward_resource.get_script() != PermanentGrowthRewardDefinitionScript:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Permanent growth reward must use the exact authoritative script.",
			)
			continue
		snapshots.append(
			PermanentGrowthRewardDefinitionScript.snapshot(rewards[index])
		)
	return snapshots


static func _validate_initial_stats(
	profile: PlayerStatProfileScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if profile.profile_id != EXPECTED_PROFILE_ID:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_PROFILE_ID_INVALID,
			profile.profile_id,
			"global_progression_catalog.initial_stats.profile_id",
			"Expected initial profile ID '%s', got '%s'."
			% [String(EXPECTED_PROFILE_ID), String(profile.profile_id)],
		)
	_validate_exact_int(
		profile.maximum_health,
		EXPECTED_INITIAL_STATS[0],
		profile.profile_id,
		"global_progression_catalog.initial_stats.maximum_health",
		ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
		issues,
	)
	_validate_exact_int(
		profile.attack,
		EXPECTED_INITIAL_STATS[1],
		profile.profile_id,
		"global_progression_catalog.initial_stats.attack",
		ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
		issues,
	)
	_validate_exact_int(
		profile.defense,
		EXPECTED_INITIAL_STATS[2],
		profile.profile_id,
		"global_progression_catalog.initial_stats.defense",
		ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
		issues,
	)
	_validate_exact_int(
		profile.speed,
		EXPECTED_INITIAL_STATS[3],
		profile.profile_id,
		"global_progression_catalog.initial_stats.speed",
		ContentValidationIssueScript.PROGRESSION_PROFILE_FIELD_MISMATCH,
		issues,
	)


static func _validate_mainline_progression(
	definitions: Array[MainlineProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var content_id_counts: Dictionary[StringName, int] = {}
	var chapter_counts: Dictionary[int, int] = {}
	for definition: MainlineProgressionDefinitionScript in definitions:
		ContentValidationSupportScript.increment_string_name_count(content_id_counts, definition.content_id)
		ContentValidationSupportScript.increment_int_count(chapter_counts, definition.chapter)
		var expected_index: int = EXPECTED_MAINLINE_IDS.find(definition.content_id)
		if definition.content_id == &"":
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_EMPTY,
				definition.content_id,
				"mainline_progression.content_id",
				"Mainline progression content ID cannot be empty.",
			)
		elif expected_index < 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_INVALID,
				definition.content_id,
				"mainline_progression.content_id",
				"Mainline progression content ID is not in the frozen whitelist.",
			)
		if (
			definition.chapter < 1
			or definition.chapter
			> ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER
		):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_INVALID,
				definition.content_id,
				"mainline_progression.chapter",
				"Mainline progression chapter must be between 1 and 9.",
			)
		if expected_index >= 0:
			_validate_exact_int(
				definition.chapter,
				expected_index + 1,
				definition.content_id,
				"mainline_progression.chapter",
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_MISMATCH,
				issues,
			)
		_validate_group_reward_ids(
			definition.content_id,
			"mainline_progression.reward_ids",
			definition.reward_ids,
			_expected_reward_ids_for_group(definition.content_id),
			issues,
		)
	ContentValidationSupportScript.add_duplicate_string_name_issues(
		content_id_counts,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_DUPLICATE,
		"mainline_progression.content_id",
		"Mainline content ID",
		issues,
	)
	ContentValidationSupportScript.add_duplicate_int_issues(
		chapter_counts,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_DUPLICATE,
		"mainline_progression.chapter",
		"Mainline chapter",
		ContentValidationSupportScript.string_name_from_int,
		issues,
	)


static func _validate_optional_progression(
	definitions: Array[OptionalProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var content_id_counts: Dictionary[StringName, int] = {}
	var map_id_counts: Dictionary[StringName, int] = {}
	for definition: OptionalProgressionDefinitionScript in definitions:
		ContentValidationSupportScript.increment_string_name_count(content_id_counts, definition.content_id)
		ContentValidationSupportScript.increment_string_name_count(map_id_counts, definition.optional_map_id)
		var expected_index: int = EXPECTED_OPTIONAL_IDS.find(definition.content_id)
		if definition.content_id == &"":
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_EMPTY,
				definition.content_id,
				"optional_progression.content_id",
				"Optional progression content ID cannot be empty.",
			)
		elif expected_index < 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_INVALID,
				definition.content_id,
				"optional_progression.content_id",
				"Optional progression content ID is not in the frozen whitelist.",
			)
		if not EXPECTED_OPTIONAL_MAP_IDS.has(definition.optional_map_id):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_INVALID,
				definition.content_id,
				"optional_progression.optional_map_id",
				"Optional map ID must be one of M01 through M04.",
			)
		if (
			definition.available_after_chapter < 1
			or definition.available_after_chapter
			> ContentContractConstantsScript.MAXIMUM_MAINLINE_CHAPTER
		):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID,
				definition.content_id,
				"optional_progression.available_after_chapter",
				"Optional progression availability chapter must be between 1 and 9.",
			)
		if expected_index >= 0:
			if definition.optional_map_id != EXPECTED_OPTIONAL_MAP_IDS[expected_index]:
				ContentValidationSupportScript.add_issue(
					issues,
					ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_INVALID,
					definition.content_id,
					"optional_progression.optional_map_id",
					"Optional map ID does not match its frozen progression source.",
				)
			_validate_exact_int(
				definition.available_after_chapter,
				EXPECTED_OPTIONAL_AVAILABLE_CHAPTERS[expected_index],
				definition.content_id,
				"optional_progression.available_after_chapter",
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_MISMATCH,
				issues,
			)
		_validate_group_reward_ids(
			definition.content_id,
			"optional_progression.reward_ids",
			definition.reward_ids,
			_expected_reward_ids_for_group(definition.content_id),
			issues,
		)
	ContentValidationSupportScript.add_duplicate_string_name_issues(
		content_id_counts,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_DUPLICATE,
		"optional_progression.content_id",
		"Optional content ID",
		issues,
	)
	ContentValidationSupportScript.add_duplicate_string_name_issues(
		map_id_counts,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_DUPLICATE,
		"optional_progression.optional_map_id",
		"Optional map ID",
		issues,
	)


static func _validate_group_reward_ids(
	group_id: StringName,
	field_path: String,
	reward_ids: Array[StringName],
	expected_reward_ids: Array[StringName],
	issues: Array[ContentValidationIssueScript],
) -> void:
	# Frozen groups contain at most four rewards. Reject hostile oversized arrays
	# before walking them so invalid input cannot create unbounded diagnostics.
	if reward_ids.size() > 8:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
			group_id,
			field_path,
			"Progression group reward membership exceeds the bounded contract.",
		)
		return
	var counts: Dictionary[StringName, int] = {}
	for reward_id: StringName in reward_ids:
		ContentValidationSupportScript.increment_string_name_count(counts, reward_id)
		if reward_id.is_empty():
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_EMPTY,
				group_id,
				field_path,
				"Progression group reward IDs cannot be empty.",
			)
		elif not EXPECTED_REWARD_IDS.has(reward_id):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_UNKNOWN,
				reward_id,
				field_path,
				"Progression group references an unknown permanent growth reward.",
			)
	var duplicated_ids: Array[StringName] = counts.keys()
	duplicated_ids.sort_custom(ContentValidationSupportScript.string_name_less_than)
	for reward_id: StringName in duplicated_ids:
		if not reward_id.is_empty() and counts[reward_id] > 1:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_ID_DUPLICATE,
				reward_id,
				field_path,
				"Reward ID '%s' appears %d times in group '%s'."
				% [String(reward_id), counts[reward_id], String(group_id)],
			)
	var ordered_actual: Array[StringName] = _copy_ids(reward_ids)
	var ordered_expected: Array[StringName] = _copy_ids(expected_reward_ids)
	ordered_actual.sort_custom(ContentValidationSupportScript.string_name_less_than)
	ordered_expected.sort_custom(ContentValidationSupportScript.string_name_less_than)
	if ordered_actual != ordered_expected:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_GROUP_REWARD_MEMBERSHIP_MISMATCH,
			group_id,
			field_path,
			"Progression group reward membership does not match the frozen mapping.",
		)


static func _validate_rewards(
	rewards: Array[PermanentGrowthRewardDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var reward_id_counts: Dictionary[StringName, int] = {}
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		ContentValidationSupportScript.increment_string_name_count(reward_id_counts, reward.reward_id)
		var expected_index: int = EXPECTED_REWARD_IDS.find(reward.reward_id)
		if reward.reward_id.is_empty():
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_ID_EMPTY,
				reward.reward_id,
				"permanent_growth_rewards.reward_id",
				"Permanent growth reward ID cannot be empty.",
			)
		elif expected_index < 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_ID_INVALID,
				reward.reward_id,
				"permanent_growth_rewards.reward_id",
				"Permanent growth reward ID is not in the frozen whitelist.",
			)
		if not _is_valid_stat_kind(reward.stat_kind):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_STAT_KIND_INVALID,
				reward.reward_id,
				"permanent_growth_rewards.stat_kind",
				"Permanent growth reward stat kind must be one of the four supported values.",
			)
		if reward.increase <= 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_INCREASE_INVALID,
				reward.reward_id,
				"permanent_growth_rewards.increase",
				"Permanent growth reward increase must be positive.",
			)
		if expected_index >= 0:
			_validate_exact_int(
				reward.stat_kind,
				EXPECTED_REWARD_STAT_KINDS[expected_index],
				reward.reward_id,
				"permanent_growth_rewards.stat_kind",
				ContentValidationIssueScript.PROGRESSION_REWARD_STAT_KIND_MISMATCH,
				issues,
			)
			_validate_exact_int(
				reward.increase,
				EXPECTED_REWARD_INCREASES[expected_index],
				reward.reward_id,
				"permanent_growth_rewards.increase",
				ContentValidationIssueScript.PROGRESSION_REWARD_INCREASE_MISMATCH,
				issues,
			)
	ContentValidationSupportScript.add_duplicate_string_name_issues(
		reward_id_counts,
		ContentValidationIssueScript.PROGRESSION_REWARD_ID_DUPLICATE,
		"permanent_growth_rewards.reward_id",
		"Permanent growth reward ID",
		issues,
	)
	for reward_id: StringName in EXPECTED_REWARD_IDS:
		if reward_id_counts.get(reward_id, 0) == 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_ID_MISSING,
				reward_id,
				"permanent_growth_rewards.reward_id",
				"Required permanent growth reward is missing.",
			)


static func _validate_reward_references(
	mainline_progression: Array[MainlineProgressionDefinitionScript],
	optional_progression: Array[OptionalProgressionDefinitionScript],
	rewards: Array[PermanentGrowthRewardDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var reward_counts: Dictionary[StringName, int] = {}
	var rewards_by_id: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		ContentValidationSupportScript.increment_string_name_count(reward_counts, reward.reward_id)
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		if reward_counts.get(reward.reward_id, 0) == 1:
			rewards_by_id[reward.reward_id] = reward

	var reference_group_counts: Dictionary[StringName, int] = {}
	for definition: MainlineProgressionDefinitionScript in mainline_progression:
		var seen_in_group: Dictionary[StringName, bool] = {}
		for reward_id: StringName in definition.reward_ids:
			if not seen_in_group.has(reward_id):
				seen_in_group[reward_id] = true
				ContentValidationSupportScript.increment_string_name_count(reference_group_counts, reward_id)
	for definition: OptionalProgressionDefinitionScript in optional_progression:
		var seen_in_group: Dictionary[StringName, bool] = {}
		for reward_id: StringName in definition.reward_ids:
			if seen_in_group.has(reward_id):
				continue
			seen_in_group[reward_id] = true
			ContentValidationSupportScript.increment_string_name_count(reference_group_counts, reward_id)
			if not rewards_by_id.has(reward_id):
				continue
			if (
				rewards_by_id[reward_id].stat_kind
				== PermanentGrowthRewardDefinitionScript.StatKind.SPEED
			):
				ContentValidationSupportScript.add_issue(
					issues,
					ContentValidationIssueScript.PROGRESSION_OPTIONAL_SPEED_FORBIDDEN,
					reward_id,
					"optional_progression.reward_ids",
					"Optional progression cannot reference a speed reward.",
				)
	for reward_id: StringName in EXPECTED_REWARD_IDS:
		var reference_count: int = reference_group_counts.get(reward_id, 0)
		if reference_count == 0:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_UNREFERENCED,
				reward_id,
				"progression.reward_ids",
				"Permanent growth reward must be referenced by exactly one group.",
			)
		elif reference_count > 1:
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_REWARD_REFERENCED_MULTIPLE,
				reward_id,
				"progression.reward_ids",
				"Permanent growth reward is referenced %d times; expected one."
				% reference_count,
			)


static func _validate_aggregate_contract(
	initial_stats: PlayerStatProfileScript,
	mainline_progression: Array[MainlineProgressionDefinitionScript],
	optional_progression: Array[OptionalProgressionDefinitionScript],
	rewards: Array[PermanentGrowthRewardDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	# 审计 I-5：下方序数索引（stat_kind - 1）的安全性原先依赖 _validate_rewards
	# 先行拒绝非法 stat_kind 的执行顺序约定。此处改为函数内先行断言：非法值
	# 在本地拒绝并提前返回，不再依赖任何上游校验顺序；合法值 1-4 行为不变。
	var has_invalid_stat_kind: bool = false
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		if _is_valid_stat_kind(reward.stat_kind):
			continue
		has_invalid_stat_kind = true
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_REWARD_STAT_KIND_INVALID,
			reward.reward_id,
			"permanent_growth_rewards.stat_kind",
			"Permanent growth reward stat kind must be one of the four supported values.",
		)
	if has_invalid_stat_kind:
		return
	var rewards_by_id: Dictionary[StringName, PermanentGrowthRewardDefinitionScript] = {}
	for reward: PermanentGrowthRewardDefinitionScript in rewards:
		rewards_by_id[reward.reward_id] = reward
	var ordered_mainline: Array[MainlineProgressionDefinitionScript] = []
	for definition: MainlineProgressionDefinitionScript in mainline_progression:
		ordered_mainline.append(definition)
	ordered_mainline.sort_custom(_mainline_less_than)
	var current: Array[int] = [
		initial_stats.maximum_health,
		initial_stats.attack,
		initial_stats.defense,
		initial_stats.speed,
	]
	var mainline_counts: Array[int] = [0, 0, 0, 0]
	for index: int in range(ordered_mainline.size()):
		for reward_id: StringName in ordered_mainline[index].reward_ids:
			var reward: PermanentGrowthRewardDefinitionScript = rewards_by_id[reward_id]
			PermanentGrowthArithmeticScript.apply_reward_to_stat_values(current, reward)
			mainline_counts[reward.stat_kind - 1] += 1
		if current != _quad_at(EXPECTED_MAINLINE_TOTALS, index):
			ContentValidationSupportScript.add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_TOTAL_MISMATCH,
				ordered_mainline[index].content_id,
				"mainline_progression.chapter_total",
				"Mainline cumulative stats do not match the frozen chapter total.",
			)
	if mainline_counts != EXPECTED_MAINLINE_REWARD_COUNTS_BY_STAT_KIND:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_ATOMIC_COUNT_MISMATCH,
			EXPECTED_CATALOG_ID,
			"mainline_progression.atomic_counts",
			"Expected mainline reward counts 8/6/6/4 (24 total).",
		)
	if current != EXPECTED_MAINLINE_FINAL_STATS:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_FINAL_STATS_MISMATCH,
			EXPECTED_PROFILE_ID,
			"mainline_progression.final_stats",
			"Expected mainline final stats 180/16/11/14.",
		)

	var ordered_optional: Array[OptionalProgressionDefinitionScript] = []
	for definition: OptionalProgressionDefinitionScript in optional_progression:
		ordered_optional.append(definition)
	ordered_optional.sort_custom(_optional_less_than)
	var optional_counts: Array[int] = [0, 0, 0, 0]
	for definition: OptionalProgressionDefinitionScript in ordered_optional:
		for reward_id: StringName in definition.reward_ids:
			var reward: PermanentGrowthRewardDefinitionScript = rewards_by_id[reward_id]
			PermanentGrowthArithmeticScript.apply_reward_to_stat_values(current, reward)
			optional_counts[reward.stat_kind - 1] += 1
	if optional_counts != EXPECTED_OPTIONAL_REWARD_COUNTS_BY_STAT_KIND:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_ATOMIC_COUNT_MISMATCH,
			EXPECTED_CATALOG_ID,
			"optional_progression.atomic_counts",
			"Expected optional reward counts 2/2/2/0 (6 total).",
		)
	if current != EXPECTED_FULL_COMPLETION_STATS:
		ContentValidationSupportScript.add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_FULL_COMPLETION_STATS_MISMATCH,
			EXPECTED_PROFILE_ID,
			"global_progression_catalog.full_completion_stats",
			"Expected full-completion stats 200/18/13/14.",
		)


static func _expected_reward_ids_for_group(group_id: StringName) -> Array[StringName]:
	match group_id:
		&"progression.main.chapter.01":
			return [&"progression.reward.main.chapter.01.maximum_health", &"progression.reward.main.chapter.01.attack"]
		&"progression.main.chapter.02":
			return [&"progression.reward.main.chapter.02.maximum_health", &"progression.reward.main.chapter.02.defense"]
		&"progression.main.chapter.03":
			return [&"progression.reward.main.chapter.03.maximum_health", &"progression.reward.main.chapter.03.attack", &"progression.reward.main.chapter.03.defense"]
		&"progression.main.chapter.04":
			return [&"progression.reward.main.chapter.04.maximum_health", &"progression.reward.main.chapter.04.attack", &"progression.reward.main.chapter.04.defense", &"progression.reward.main.chapter.04.speed"]
		&"progression.main.chapter.05":
			return [&"progression.reward.main.chapter.05.maximum_health", &"progression.reward.main.chapter.05.attack", &"progression.reward.main.chapter.05.defense"]
		&"progression.main.chapter.06":
			return [&"progression.reward.main.chapter.06.maximum_health", &"progression.reward.main.chapter.06.attack", &"progression.reward.main.chapter.06.speed"]
		&"progression.main.chapter.07":
			return [&"progression.reward.main.chapter.07.maximum_health", &"progression.reward.main.chapter.07.defense", &"progression.reward.main.chapter.07.speed"]
		&"progression.main.chapter.08":
			return [&"progression.reward.main.chapter.08.maximum_health", &"progression.reward.main.chapter.08.attack", &"progression.reward.main.chapter.08.defense"]
		&"progression.main.chapter.09":
			return [&"progression.reward.main.chapter.09.speed"]
		&"progression.optional.m01":
			return [&"progression.reward.optional.m01.maximum_health"]
		&"progression.optional.m02":
			return [&"progression.reward.optional.m02.attack"]
		&"progression.optional.m03":
			return [&"progression.reward.optional.m03.maximum_health", &"progression.reward.optional.m03.defense"]
		&"progression.optional.m04":
			return [&"progression.reward.optional.m04.attack", &"progression.reward.optional.m04.defense"]
	return []


static func _is_valid_stat_kind(value: int) -> bool:
	return (
		value == PermanentGrowthRewardDefinitionScript.StatKind.MAXIMUM_HEALTH
		or value == PermanentGrowthRewardDefinitionScript.StatKind.ATTACK
		or value == PermanentGrowthRewardDefinitionScript.StatKind.DEFENSE
		or value == PermanentGrowthRewardDefinitionScript.StatKind.SPEED
	)


static func _quad_at(source: Array[int], index: int) -> Array[int]:
	var offset: int = index * 4
	return [
		source[offset],
		source[offset + 1],
		source[offset + 2],
		source[offset + 3],
	]


static func _validate_exact_int(
	actual: int,
	expected: int,
	content_id: StringName,
	field_path: String,
	issue_code: StringName,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if actual == expected:
		return
	ContentValidationSupportScript.add_issue(
		issues,
		issue_code,
		content_id,
		field_path,
		"Expected %d, got %d." % [expected, actual],
	)


static func _copy_ids(source: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: StringName in source:
		result.append(value)
	return result


static func _mainline_less_than(
	left: MainlineProgressionDefinitionScript,
	right: MainlineProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _optional_less_than(
	left: OptionalProgressionDefinitionScript,
	right: OptionalProgressionDefinitionScript,
) -> bool:
	return String(left.content_id) < String(right.content_id)


static func _reward_less_than(
	left: PermanentGrowthRewardDefinitionScript,
	right: PermanentGrowthRewardDefinitionScript,
) -> bool:
	return String(left.reward_id) < String(right.reward_id)
