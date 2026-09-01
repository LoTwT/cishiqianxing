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
const GlobalProgressionCatalogScript := preload(
	"res://src/content/definitions/global_progression_catalog_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

const EXPECTED_CATALOG_ID: StringName = &"progression.global"
const EXPECTED_PROFILE_ID: StringName = &"progression.player.loer"
const EXPECTED_MAINLINE_COUNT: int = 9
const EXPECTED_OPTIONAL_COUNT: int = 4
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
const EXPECTED_MAINLINE_DELTAS: Array[int] = [
	10, 1, 0, 0,
	10, 0, 1, 0,
	10, 1, 1, 0,
	10, 1, 1, 1,
	10, 1, 1, 0,
	10, 1, 0, 1,
	10, 0, 1, 1,
	10, 1, 1, 0,
	0, 0, 0, 1,
]
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
const EXPECTED_OPTIONAL_DELTAS: Array[int] = [
	10, 0, 0, 0,
	0, 1, 0, 0,
	10, 0, 1, 0,
	0, 1, 1, 0,
]


static func snapshot_and_validate(
	catalog_resource: Resource,
	issues: Array[ContentValidationIssueScript],
) -> GlobalProgressionCatalogScript:
	var initial_issue_count: int = issues.size()
	if catalog_resource == null:
		_add_issue(
			issues,
			ContentValidationIssueScript.MANIFEST_PROGRESSION_CATALOG_NULL,
			&"",
			"global_progression_catalog",
			"Global progression catalog is null.",
		)
		return null
	if catalog_resource.get_script() != GlobalProgressionCatalogScript:
		_add_issue(
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
	if mainline_count != EXPECTED_MAINLINE_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_COUNT_INVALID,
			catalog.catalog_id,
			"global_progression_catalog.mainline_progression",
			"Expected %d mainline progression bundles, got %d."
			% [EXPECTED_MAINLINE_COUNT, mainline_count],
		)
	if optional_count != EXPECTED_OPTIONAL_COUNT:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_COUNT_INVALID,
			catalog.catalog_id,
			"global_progression_catalog.optional_progression",
			"Expected %d optional progression bundles, got %d."
			% [EXPECTED_OPTIONAL_COUNT, optional_count],
		)
	if mainline_count != EXPECTED_MAINLINE_COUNT or optional_count != EXPECTED_OPTIONAL_COUNT:
		return null

	if catalog.catalog_id != EXPECTED_CATALOG_ID:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_CATALOG_ID_INVALID,
			catalog.catalog_id,
			"global_progression_catalog.catalog_id",
			"Expected global progression catalog ID '%s', got '%s'."
			% [String(EXPECTED_CATALOG_ID), String(catalog.catalog_id)],
		)

	var initial_stats: PlayerStatProfileScript = _snapshot_initial_stats(
		catalog.initial_stats,
		issues,
	)
	var mainline_progression: Array[MainlineProgressionDefinitionScript] = (
		_snapshot_mainline_progression(catalog.mainline_progression, issues)
	)
	var optional_progression: Array[OptionalProgressionDefinitionScript] = (
		_snapshot_optional_progression(catalog.optional_progression, issues)
	)
	if initial_stats != null:
		_validate_initial_stats(initial_stats, issues)
	_validate_mainline_progression(mainline_progression, issues)
	_validate_optional_progression(optional_progression, issues)
	if issues.size() == initial_issue_count:
		_validate_aggregate_contract(
			initial_stats,
			mainline_progression,
			optional_progression,
			issues,
		)
	if issues.size() != initial_issue_count:
		return null

	mainline_progression.sort_custom(_mainline_less_than)
	optional_progression.sort_custom(_optional_less_than)
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
	return snapshot


static func _snapshot_initial_stats(
	profile: PlayerStatProfileScript,
	issues: Array[ContentValidationIssueScript],
) -> PlayerStatProfileScript:
	var profile_resource: Resource = profile as Resource
	if profile_resource == null:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_NULL,
			&"",
			"global_progression_catalog.initial_stats",
			"Initial player stat profile is null.",
		)
		return null
	if profile_resource.get_script() != PlayerStatProfileScript:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_INITIAL_STATS_INVALID_SCRIPT,
			&"",
			"global_progression_catalog.initial_stats",
			"Initial player stat profile must use the exact authoritative script.",
		)
		return null
	return PlayerStatProfileScript.snapshot(profile)


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
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_NULL,
				&"",
				field_path,
				"Mainline progression entry is null.",
			)
			continue
		if definition_resource.get_script() != MainlineProgressionDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Mainline progression entry must use the exact authoritative script.",
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
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_NULL,
				&"",
				field_path,
				"Optional progression entry is null.",
			)
			continue
		if definition_resource.get_script() != OptionalProgressionDefinitionScript:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_ENTRY_INVALID_SCRIPT,
				&"",
				field_path,
				"Optional progression entry must use the exact authoritative script.",
			)
			continue
		snapshots.append(
			OptionalProgressionDefinitionScript.snapshot(definitions[index])
		)
	return snapshots


static func _validate_initial_stats(
	profile: PlayerStatProfileScript,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if profile.profile_id != EXPECTED_PROFILE_ID:
		_add_issue(
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
		_increment_string_name_count(content_id_counts, definition.content_id)
		_increment_int_count(chapter_counts, definition.chapter)
		var expected_index: int = EXPECTED_MAINLINE_IDS.find(definition.content_id)
		if definition.content_id == &"":
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_EMPTY,
				definition.content_id,
				"mainline_progression.content_id",
				"Mainline progression content ID cannot be empty.",
			)
		elif expected_index < 0:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_INVALID,
				definition.content_id,
				"mainline_progression.content_id",
				"Mainline progression content ID is not in the frozen whitelist.",
			)
		if definition.chapter < 1 or definition.chapter > 9:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_INVALID,
				definition.content_id,
				"mainline_progression.chapter",
				"Mainline progression chapter must be between 1 and 9.",
			)
		_validate_delta_domain(
			definition.content_id,
			"mainline_progression",
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_DELTA_INVALID,
			issues,
		)
		if expected_index >= 0:
			_validate_mainline_row(definition, expected_index, issues)
	_add_duplicate_string_name_issues(
		content_id_counts,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CONTENT_ID_DUPLICATE,
		"mainline_progression.content_id",
		issues,
	)
	_add_duplicate_int_issues(
		chapter_counts,
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_DUPLICATE,
		"mainline_progression.chapter",
		issues,
	)


static func _validate_mainline_row(
	definition: MainlineProgressionDefinitionScript,
	expected_index: int,
	issues: Array[ContentValidationIssueScript],
) -> void:
	_validate_exact_int(
		definition.chapter,
		expected_index + 1,
		definition.content_id,
		"mainline_progression.chapter",
		ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_MISMATCH,
		issues,
	)
	_validate_delta_row(
		definition.content_id,
		"mainline_progression",
		[
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
		],
		_quad_at(EXPECTED_MAINLINE_DELTAS, expected_index),
		ContentValidationIssueScript.PROGRESSION_MAINLINE_DELTA_MISMATCH,
		issues,
	)


static func _validate_optional_progression(
	definitions: Array[OptionalProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
	var content_id_counts: Dictionary[StringName, int] = {}
	var map_id_counts: Dictionary[StringName, int] = {}
	for definition: OptionalProgressionDefinitionScript in definitions:
		_increment_string_name_count(content_id_counts, definition.content_id)
		_increment_string_name_count(map_id_counts, definition.optional_map_id)
		var expected_index: int = EXPECTED_OPTIONAL_IDS.find(definition.content_id)
		if definition.content_id == &"":
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_EMPTY,
				definition.content_id,
				"optional_progression.content_id",
				"Optional progression content ID cannot be empty.",
			)
		elif expected_index < 0:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_INVALID,
				definition.content_id,
				"optional_progression.content_id",
				"Optional progression content ID is not in the frozen whitelist.",
			)
		if not EXPECTED_OPTIONAL_MAP_IDS.has(definition.optional_map_id):
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_INVALID,
				definition.content_id,
				"optional_progression.optional_map_id",
				"Optional map ID must be one of M01 through M04.",
			)
		if (
			definition.available_after_chapter < 1
			or definition.available_after_chapter > 9
		):
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_AVAILABLE_CHAPTER_INVALID,
				definition.content_id,
				"optional_progression.available_after_chapter",
				"Optional progression availability chapter must be between 1 and 9.",
			)
		_validate_delta_domain(
			definition.content_id,
			"optional_progression",
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_DELTA_INVALID,
			issues,
		)
		if definition.speed_increase != 0:
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_OPTIONAL_SPEED_FORBIDDEN,
				definition.content_id,
				"optional_progression.speed_increase",
				"Optional progression cannot increase speed.",
			)
		if expected_index >= 0:
			_validate_optional_row(definition, expected_index, issues)
	_add_duplicate_string_name_issues(
		content_id_counts,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_CONTENT_ID_DUPLICATE,
		"optional_progression.content_id",
		issues,
	)
	_add_duplicate_string_name_issues(
		map_id_counts,
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_MAP_ID_DUPLICATE,
		"optional_progression.optional_map_id",
		issues,
	)


static func _validate_optional_row(
	definition: OptionalProgressionDefinitionScript,
	expected_index: int,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if definition.optional_map_id != EXPECTED_OPTIONAL_MAP_IDS[expected_index]:
		_add_issue(
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
	_validate_delta_row(
		definition.content_id,
		"optional_progression",
		[
			definition.maximum_health_increase,
			definition.attack_increase,
			definition.defense_increase,
			definition.speed_increase,
		],
		_quad_at(EXPECTED_OPTIONAL_DELTAS, expected_index),
		ContentValidationIssueScript.PROGRESSION_OPTIONAL_DELTA_MISMATCH,
		issues,
	)


static func _validate_delta_domain(
	content_id: StringName,
	field_prefix: String,
	maximum_health_increase: int,
	attack_increase: int,
	defense_increase: int,
	speed_increase: int,
	issue_code: StringName,
	issues: Array[ContentValidationIssueScript],
) -> void:
	if maximum_health_increase != 0 and maximum_health_increase != 10:
		_add_delta_issue(
			issues, issue_code, content_id, field_prefix, "maximum_health_increase"
		)
	if attack_increase != 0 and attack_increase != 1:
		_add_delta_issue(
			issues, issue_code, content_id, field_prefix, "attack_increase"
		)
	if defense_increase != 0 and defense_increase != 1:
		_add_delta_issue(
			issues, issue_code, content_id, field_prefix, "defense_increase"
		)
	if speed_increase != 0 and speed_increase != 1:
		_add_delta_issue(
			issues, issue_code, content_id, field_prefix, "speed_increase"
		)
	if (
		maximum_health_increase == 0
		and attack_increase == 0
		and defense_increase == 0
		and speed_increase == 0
	):
		_add_issue(
			issues,
			issue_code,
			content_id,
			"%s.delta" % field_prefix,
			"Progression bundle must contain at least one nonzero stat increase.",
		)


static func _validate_delta_row(
	content_id: StringName,
	field_prefix: String,
	actual: Array[int],
	expected: Array[int],
	issue_code: StringName,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var field_names: Array[String] = [
		"maximum_health_increase",
		"attack_increase",
		"defense_increase",
		"speed_increase",
	]
	for index: int in range(field_names.size()):
		_validate_exact_int(
			actual[index],
			expected[index],
			content_id,
			"%s.%s" % [field_prefix, field_names[index]],
			issue_code,
			issues,
		)


static func _validate_aggregate_contract(
	initial_stats: PlayerStatProfileScript,
	mainline_progression: Array[MainlineProgressionDefinitionScript],
	optional_progression: Array[OptionalProgressionDefinitionScript],
	issues: Array[ContentValidationIssueScript],
) -> void:
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
	var mainline_nonzero_counts: Array[int] = [0, 0, 0, 0]
	for index: int in range(ordered_mainline.size()):
		var delta: Array[int] = _mainline_delta(ordered_mainline[index])
		for stat_index: int in range(delta.size()):
			current[stat_index] += delta[stat_index]
			if delta[stat_index] != 0:
				mainline_nonzero_counts[stat_index] += 1
		if current != _quad_at(EXPECTED_MAINLINE_TOTALS, index):
			_add_issue(
				issues,
				ContentValidationIssueScript.PROGRESSION_MAINLINE_CHAPTER_TOTAL_MISMATCH,
				ordered_mainline[index].content_id,
				"mainline_progression.chapter_total",
				"Mainline cumulative stats do not match the frozen chapter total.",
			)
	if mainline_nonzero_counts != [8, 6, 6, 4]:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_MAINLINE_ATOMIC_COUNT_MISMATCH,
			EXPECTED_CATALOG_ID,
			"mainline_progression.atomic_counts",
			"Expected mainline nonzero stat counts 8/6/6/4 (24 total).",
		)
	if current != [180, 16, 11, 14]:
		_add_issue(
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
	var optional_nonzero_counts: Array[int] = [0, 0, 0, 0]
	for definition: OptionalProgressionDefinitionScript in ordered_optional:
		var delta: Array[int] = _optional_delta(definition)
		for stat_index: int in range(delta.size()):
			current[stat_index] += delta[stat_index]
			if delta[stat_index] != 0:
				optional_nonzero_counts[stat_index] += 1
	if optional_nonzero_counts != [2, 2, 2, 0]:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_OPTIONAL_ATOMIC_COUNT_MISMATCH,
			EXPECTED_CATALOG_ID,
			"optional_progression.atomic_counts",
			"Expected optional nonzero stat counts 2/2/2/0 (6 total).",
		)
	if current != [200, 18, 13, 14]:
		_add_issue(
			issues,
			ContentValidationIssueScript.PROGRESSION_FULL_COMPLETION_STATS_MISMATCH,
			EXPECTED_PROFILE_ID,
			"global_progression_catalog.full_completion_stats",
			"Expected full-completion stats 200/18/13/14.",
		)


static func _mainline_delta(
	definition: MainlineProgressionDefinitionScript,
) -> Array[int]:
	return [
		definition.maximum_health_increase,
		definition.attack_increase,
		definition.defense_increase,
		definition.speed_increase,
	]


static func _optional_delta(
	definition: OptionalProgressionDefinitionScript,
) -> Array[int]:
	return [
		definition.maximum_health_increase,
		definition.attack_increase,
		definition.defense_increase,
		definition.speed_increase,
	]


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
	_add_issue(
		issues,
		issue_code,
		content_id,
		field_path,
		"Expected %d, got %d." % [expected, actual],
	)


static func _add_delta_issue(
	issues: Array[ContentValidationIssueScript],
	issue_code: StringName,
	content_id: StringName,
	field_prefix: String,
	field_name: String,
) -> void:
	_add_issue(
		issues,
		issue_code,
		content_id,
		"%s.%s" % [field_prefix, field_name],
		"Progression stat increases must use the frozen 0/1 or 0/10 domain.",
	)


static func _add_duplicate_string_name_issues(
	counts: Dictionary[StringName, int],
	issue_code: StringName,
	field_path: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var values: Array[StringName] = counts.keys()
	values.sort_custom(_string_name_less_than)
	for value: StringName in values:
		if counts[value] > 1:
			_add_issue(
				issues,
				issue_code,
				value,
				field_path,
				"Value '%s' appears %d times." % [String(value), counts[value]],
			)


static func _add_duplicate_int_issues(
	counts: Dictionary[int, int],
	issue_code: StringName,
	field_path: String,
	issues: Array[ContentValidationIssueScript],
) -> void:
	var values: Array[int] = counts.keys()
	values.sort()
	for value: int in values:
		if counts[value] > 1:
			_add_issue(
				issues,
				issue_code,
				StringName(str(value)),
				field_path,
				"Value %d appears %d times." % [value, counts[value]],
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


static func _string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
