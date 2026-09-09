extends RefCounted

const CanonicalRegistryFixtureScript := preload(
	"res://tests/support/canonical_registry_fixture.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const PermanentGrowthArithmeticScript := preload(
	"res://src/rules/permanent_growth_arithmetic.gd"
)
const PlayerProgressionDerivationResultScript := preload(
	"res://src/rules/player_progression_derivation_result.gd"
)
const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PermanentGrowthClaimCommandScript := preload(
	"res://src/rules/permanent_growth_claim_command.gd"
)
const PermanentGrowthClaimEventScript := preload(
	"res://src/rules/permanent_growth_claim_event.gd"
)
const PermanentGrowthClaimKernelScript := preload(
	"res://src/rules/permanent_growth_claim_kernel.gd"
)
const PermanentGrowthClaimResultScript := preload(
	"res://src/rules/permanent_growth_claim_result.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)
const PermanentGrowthClaimOracle := preload(
	"res://tests/rules/permanent_growth_claim_oracle.gd"
)
const StatefulPlayerProgressionStateScript := preload(
	"res://tests/support/stateful_player_progression_state.gd"
)
const StatefulPermanentGrowthClaimCommandScript := preload(
	"res://tests/support/stateful_permanent_growth_claim_command.gd"
)
const StatefulContentRegistryScript := preload(
	"res://tests/support/stateful_content_registry.gd"
)
const DerivedPermanentGrowthClaimEventScript := preload(
	"res://tests/support/derived_permanent_growth_claim_event.gd"
)

const MAX_INT: int = 9_223_372_036_854_775_807


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.freezes_literal_oracle",
			_freezes_literal_oracle,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.guards_arithmetic_boundaries",
			_guards_arithmetic_boundaries,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.derives_restored_state_without_replay",
			_derives_restored_state_without_replay,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.applies_every_reward_from_full_health",
			_applies_every_reward_from_full_health,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.applies_every_reward_from_damaged_health",
			_applies_every_reward_from_damaged_health,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.keeps_m03_and_m04_rewards_atomic",
			_keeps_m03_and_m04_rewards_atomic,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.is_idempotent_for_every_reward",
			_is_idempotent_for_every_reward,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_nonadjacent_duplicate",
			_rejects_nonadjacent_duplicate,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.distinguishes_equal_payload_ids",
			_distinguishes_equal_payload_ids,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.prioritizes_duplicate_over_incapacitated",
			_prioritizes_duplicate_over_incapacitated,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_every_new_reward_when_incapacitated",
			_rejects_every_new_reward_when_incapacitated,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_empty_unknown_and_group_ids",
			_rejects_empty_unknown_and_group_ids,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_invalid_state_matrix",
			_rejects_invalid_state_matrix,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_invalid_restored_ledger_matrix",
			_rejects_invalid_restored_ledger_matrix,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.fails_closed_for_registry_and_versions",
			_fails_closed_for_registry_and_versions,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_null_wrong_and_derived_inputs",
			_rejects_null_wrong_and_derived_inputs,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.applies_mainline_sequence",
			_applies_mainline_sequence,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.applies_optional_sequence",
			_applies_optional_sequence,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.applies_full_sequence",
			_applies_full_sequence,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.replays_deterministically",
			_replays_deterministically,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.isolates_inputs_and_result_snapshots",
			_isolates_inputs_and_result_snapshots,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.isolates_derivation_result_snapshot",
			_isolates_derivation_result_snapshot,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_malformed_public_result_events",
			_rejects_malformed_public_result_events,
		),
		HeadlessTestCaseScript.new(
			"permanent_growth_claim.rejects_inconsistent_public_result_deltas",
			_rejects_inconsistent_public_result_deltas,
		),
	]


func _guards_arithmetic_boundaries(context: HeadlessTestContextScript) -> void:
	# 直接验证算术边界，避免冻结内容的低数值上界遮住溢出守卫回归。
	# 四维顺序与字面成长 oracle 一致：生命上限、攻击、防御、速度。
	for stat_index: int in range(4):
		for increase: int in [1, 2, 10, MAX_INT]:
			var values: Array[int] = [100, 10, 5, 10]
			values[stat_index] = MAX_INT - increase
			var expected_values: Array[int] = values.duplicate()
			expected_values[stat_index] = MAX_INT
			context.expect_true(
				PermanentGrowthArithmeticScript.add_reward_increase_with_overflow_guard(
					values, stat_index + 1, increase,
				),
				"Stat %d must accept an increase ending exactly at MAX_INT." % stat_index,
			)
			context.expect_equal(values, expected_values, "Only the rewarded stat may change.")

			values[stat_index] = MAX_INT - increase + 1
			var previous_values: Array[int] = values.duplicate()
			context.expect_true(
				not PermanentGrowthArithmeticScript.add_reward_increase_with_overflow_guard(
					values, stat_index + 1, increase,
				),
				"Stat %d must reject an increase exceeding MAX_INT." % stat_index,
			)
			context.expect_equal(
				values, previous_values,
				"Rejected growth must leave every stat unchanged.",
			)


func _freezes_literal_oracle(context: HeadlessTestContextScript) -> void:
	var rows: Array[PermanentGrowthClaimOracle.RewardTransitionRow] = (
		PermanentGrowthClaimOracle.reward_rows()
	)
	var all_ids: Array[StringName] = PermanentGrowthClaimOracle.all_reward_ids()
	var seen_ids: Dictionary[StringName, bool] = {}
	var kind_counts: Dictionary[int, int] = {1: 0, 2: 0, 3: 0, 4: 0}
	var row_ids: Array[StringName] = []
	context.expect_equal(rows.size(), 30, "The oracle must contain exactly 30 reward rows.")
	context.expect_equal(all_ids.size(), 30, "The literal all-ID list must contain 30 IDs.")
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in rows:
		context.expect_true(
			not String(row.reward_id).is_empty(),
			"Every oracle reward ID must be nonempty.",
		)
		context.expect_true(
			not seen_ids.has(row.reward_id),
			"Every oracle reward ID must be unique: %s." % String(row.reward_id),
		)
		seen_ids[row.reward_id] = true
		row_ids.append(row.reward_id)
		context.expect_true(
			kind_counts.has(row.stat_kind),
			"Every oracle row must use one of the four literal stat kinds.",
		)
		kind_counts[row.stat_kind] += 1
		context.expect_equal(
			row.increase,
			10 if row.stat_kind == 1 else 1,
			"The literal increase must match the approved stat kind.",
		)
		context.expect_equal(
			row.expected_from_full_health.size(),
			5,
			"Each full-health transition must contain five values.",
		)
		context.expect_equal(
			row.expected_from_damaged_health.size(),
			5,
			"Each damaged-health transition must contain five values.",
		)
	context.expect_equal(row_ids, all_ids, "Reward rows and the literal ID list must agree.")
	context.expect_equal(kind_counts[1], 10, "The oracle must contain ten health rewards.")
	context.expect_equal(kind_counts[2], 8, "The oracle must contain eight attack rewards.")
	context.expect_equal(kind_counts[3], 8, "The oracle must contain eight defense rewards.")
	context.expect_equal(kind_counts[4], 4, "The oracle must contain four speed rewards.")
	context.expect_equal(
		PermanentGrowthClaimOracle.mainline_reward_ids().size(),
		24,
		"The mainline sequence must contain 24 atomic rewards.",
	)
	context.expect_equal(
		PermanentGrowthClaimOracle.optional_reward_ids().size(),
		6,
		"The optional sequence must contain six atomic rewards.",
	)
	context.expect_equal(
		PermanentGrowthClaimOracle.group_ids().size(),
		13,
		"The non-claimable group list must contain all thirteen group IDs.",
	)
	var group_ids: Array[StringName] = PermanentGrowthClaimOracle.group_ids()
	var seen_group_ids: Dictionary[StringName, bool] = {}
	var mainline_group_count: int = 0
	var optional_group_count: int = 0
	for group_id: StringName in group_ids:
		context.expect_true(
			not String(group_id).is_empty(),
			"Every literal group ID must be nonempty.",
		)
		context.expect_true(
			not seen_group_ids.has(group_id),
			"Every literal group ID must be unique: %s." % String(group_id),
		)
		seen_group_ids[group_id] = true
		if String(group_id).begins_with("progression.main.chapter."):
			mainline_group_count += 1
		elif String(group_id).begins_with("progression.optional."):
			optional_group_count += 1
		else:
			context.expect_true(false, "The literal group ID must use an approved namespace.")
	context.expect_equal(
		mainline_group_count,
		9,
		"The literal oracle must contain all nine mainline group IDs.",
	)
	context.expect_equal(
		optional_group_count,
		4,
		"The literal oracle must contain all four optional group IDs.",
	)
	var concatenated_ids: Array[StringName] = PermanentGrowthClaimOracle.mainline_reward_ids()
	concatenated_ids.append_array(PermanentGrowthClaimOracle.optional_reward_ids())
	context.expect_equal(
		concatenated_ids,
		all_ids,
		"The literal mainline and optional sequences must partition all reward IDs.",
	)


func _derives_restored_state_without_replay(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var claimed_ids: Array[StringName] = [
		&"progression.reward.main.chapter.01.attack",
	]
	var restored_state: PlayerProgressionStateScript = _state(80, claimed_ids)
	claimed_ids.append(&"progression.reward.main.chapter.01.maximum_health")
	_assert_state(
		context,
		restored_state,
		80,
		[&"progression.reward.main.chapter.01.attack"],
		"Restored state",
	)
	var derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(restored_state, registry)
	)
	context.expect_true(derivation.succeeded(), "A valid restored state must derive.")
	context.expect_equal(
		derivation.failure_reason(),
		PlayerProgressionDerivationResultScript.FailureReason.NONE,
		"A successful derivation must not expose a failure reason.",
	)
	_assert_snapshot(
		context,
		derivation.snapshot(),
		[80, 100, 11, 5, 10],
		[&"progression.reward.main.chapter.01.attack"],
		"Restored attack state",
	)
	var health_reward_state: PlayerProgressionStateScript = _state(
		100,
		[&"progression.reward.main.chapter.01.maximum_health"],
	)
	var health_derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(health_reward_state, registry)
	)
	context.expect_true(
		health_derivation.succeeded(),
		"A restored maximum-health reward must derive without replaying its heal.",
	)
	_assert_snapshot(
		context,
		health_derivation.snapshot(),
		[100, 110, 10, 5, 10],
		[&"progression.reward.main.chapter.01.maximum_health"],
		"Restored maximum-health state",
	)


func _applies_every_reward_from_full_health(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in (
		PermanentGrowthClaimOracle.reward_rows()
	):
		var state: PlayerProgressionStateScript = _state(100)
		var before: PlayerProgressionStateScript = state.copy()
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				state,
				PermanentGrowthClaimCommandScript.claim(row.reward_id),
				registry,
			)
		)
		_expect_applied(
			context,
			result,
			row,
			row.expected_from_full_health,
			[row.reward_id],
			100,
		)
		_assert_state(context, state, 100, [], "Input state")
		context.expect_true(
			state.is_equal_to(before),
			"Applying %s must not mutate the input state." % String(row.reward_id),
		)


func _applies_every_reward_from_damaged_health(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in (
		PermanentGrowthClaimOracle.reward_rows()
	):
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				_state(80),
				PermanentGrowthClaimCommandScript.claim(row.reward_id),
				registry,
			)
		)
		_expect_applied(
			context,
			result,
			row,
			row.expected_from_damaged_health,
			[row.reward_id],
			80,
		)


func _keeps_m03_and_m04_rewards_atomic(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var m03_defense: StringName = &"progression.reward.optional.m03.defense"
	var m03_health: StringName = &"progression.reward.optional.m03.maximum_health"
	var m04_attack: StringName = &"progression.reward.optional.m04.attack"
	var m04_defense: StringName = &"progression.reward.optional.m04.defense"
	for reward_id: StringName in [m03_defense, m03_health, m04_attack, m04_defense]:
		var row: PermanentGrowthClaimOracle.RewardTransitionRow = _oracle_row(reward_id)
		var single_result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				_state(100),
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			)
		)
		_expect_applied(
			context,
			single_result,
			row,
			row.expected_from_full_health,
			[reward_id],
			100,
		)
	var m03_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, [m03_defense, m03_health], 100
	)
	_assert_derived_state(
		context,
		registry,
		m03_state,
		[110, 110, 10, 6, 10],
		[m03_defense, m03_health],
		"M03",
	)
	var m04_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, [m04_attack, m04_defense], 100
	)
	_assert_derived_state(
		context,
		registry,
		m04_state,
		[100, 100, 11, 6, 10],
		[m04_attack, m04_defense],
		"M04",
	)


func _is_idempotent_for_every_reward(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in (
		PermanentGrowthClaimOracle.reward_rows()
	):
		var state: PlayerProgressionStateScript = _state(
			row.expected_from_full_health[0],
			[row.reward_id],
		)
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				state,
				PermanentGrowthClaimCommandScript.claim(row.reward_id),
				registry,
			)
		)
		_expect_already_claimed(
			context,
			result,
			state,
			row.expected_from_full_health,
			[row.reward_id],
			row.reward_id,
		)


func _rejects_nonadjacent_duplicate(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var attack_id: StringName = &"progression.reward.main.chapter.01.attack"
	var health_id: StringName = &"progression.reward.main.chapter.01.maximum_health"
	var state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, [attack_id, health_id], 100
	)
	var result: PermanentGrowthClaimResultScript = (
		PermanentGrowthClaimKernelScript.execute(
			state,
			PermanentGrowthClaimCommandScript.claim(attack_id),
			registry,
		)
	)
	_expect_already_claimed(
		context,
		result,
		state,
		[110, 110, 11, 5, 10],
		[attack_id, health_id],
		attack_id,
	)


func _distinguishes_equal_payload_ids(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var first_id: StringName = &"progression.reward.main.chapter.01.maximum_health"
	var second_id: StringName = &"progression.reward.main.chapter.02.maximum_health"
	var state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, [first_id, second_id], 100
	)
	_assert_derived_state(
		context,
		registry,
		state,
		[120, 120, 10, 5, 10],
		[first_id, second_id],
		"Equal-payload distinct-ID",
	)


func _prioritizes_duplicate_over_incapacitated(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in (
		PermanentGrowthClaimOracle.reward_rows()
	):
		var expected_values: Array[int] = row.expected_from_damaged_health.duplicate()
		expected_values[0] = 0
		var state: PlayerProgressionStateScript = _state(0, [row.reward_id])
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				state,
				PermanentGrowthClaimCommandScript.claim(row.reward_id),
				registry,
			)
		)
		_expect_already_claimed(
			context,
			result,
			state,
			expected_values,
			[row.reward_id],
			row.reward_id,
		)


func _rejects_every_new_reward_when_incapacitated(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var zero_state: PlayerProgressionStateScript = _state(0)
	for reward_id: StringName in PermanentGrowthClaimOracle.all_reward_ids():
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				zero_state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			)
		)
		_expect_rejected(
			context,
			result,
			PermanentGrowthClaimResultScript.RejectionReason.PLAYER_INCAPACITATED,
			reward_id,
			zero_state,
			"Zero-health new reward",
		)


func _rejects_empty_unknown_and_group_ids(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var healthy_state: PlayerProgressionStateScript = _state(100)
	var empty_result: PermanentGrowthClaimResultScript = (
		PermanentGrowthClaimKernelScript.execute(
			healthy_state,
			PermanentGrowthClaimCommandScript.claim(&""),
			registry,
		)
	)
	_expect_rejected(
		context,
		empty_result,
		PermanentGrowthClaimResultScript.RejectionReason.EMPTY_REWARD_ID,
		&"",
		healthy_state,
		"Empty reward ID",
	)
	for reward_id: StringName in PermanentGrowthClaimOracle.group_ids():
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				healthy_state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			)
		)
		_expect_rejected(
			context,
			result,
			PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_REWARD_ID,
			reward_id,
			healthy_state,
			"Group reward ID",
		)
	var unknown_id: StringName = &"progression.reward.unknown"
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			healthy_state,
			PermanentGrowthClaimCommandScript.claim(unknown_id),
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_REWARD_ID,
		unknown_id,
		healthy_state,
		"Unknown reward ID",
	)
	var zero_state: PlayerProgressionStateScript = _state(0)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			zero_state,
			PermanentGrowthClaimCommandScript.claim(&""),
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.EMPTY_REWARD_ID,
		&"",
		zero_state,
		"Empty reward ID at zero health",
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			zero_state,
			PermanentGrowthClaimCommandScript.claim(unknown_id),
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_REWARD_ID,
		unknown_id,
		zero_state,
		"Unknown reward ID at zero health",
	)
	for reward_id: StringName in PermanentGrowthClaimOracle.group_ids():
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(
				zero_state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			),
			PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_REWARD_ID,
			reward_id,
			zero_state,
			"Group reward ID at zero health",
		)


func _rejects_invalid_state_matrix(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var reward_id: StringName = &"progression.reward.main.chapter.01.attack"
	var oversized_ids: Array[StringName] = []
	for index: int in range(31):
		oversized_ids.append(StringName("test.reward.%02d" % index))
	var noncanonical_state: PlayerProgressionStateScript = _state(
		100,
		[
			&"progression.reward.main.chapter.01.attack",
			&"progression.reward.main.chapter.01.maximum_health",
		],
	)
	noncanonical_state._claimed_reward_ids = [
		&"progression.reward.main.chapter.01.maximum_health",
		&"progression.reward.main.chapter.01.attack",
	]
	var invalid_states: Array[PlayerProgressionStateScript] = [
		PlayerProgressionStateScript.new(),
		PlayerProgressionStateScript.create(&"", 5, 5, 100, []),
		PlayerProgressionStateScript.create(
			PermanentGrowthClaimOracle.PROFILE_ID, 0, 5, 100, []
		),
		PlayerProgressionStateScript.create(
			PermanentGrowthClaimOracle.PROFILE_ID, 5, 0, 100, []
		),
		PlayerProgressionStateScript.create(
			PermanentGrowthClaimOracle.PROFILE_ID, 5, 5, -1, []
		),
		_state(100, [reward_id, reward_id]),
		_state(100, [&""]),
		_state(100, oversized_ids),
		noncanonical_state,
	]
	for invalid_state: PlayerProgressionStateScript in invalid_states:
		context.expect_true(not invalid_state.is_valid(), "The matrix state must be invalid.")
		context.expect_true(
			not invalid_state.validation_errors().is_empty(),
			"Each invalid state must expose a validation error.",
		)
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(
				invalid_state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			),
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
			&"",
			invalid_state,
			"Invalid state",
		)


func _rejects_invalid_restored_ledger_matrix(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var command: PermanentGrowthClaimCommandScript = PermanentGrowthClaimCommandScript.claim(
		&"progression.reward.main.chapter.01.attack"
	)
	var wrong_profile: PlayerProgressionStateScript = PlayerProgressionStateScript.create(
		&"progression.player.impostor", 5, 5, 100,
		[&"progression.reward.unknown"],
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(wrong_profile, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.PROFILE_ID_MISMATCH,
		&"",
		wrong_profile,
		"Wrong profile before unknown ledger entry",
	)
	for claimed_id: StringName in [
		&"progression.reward.unknown",
		&"progression.main.chapter.01",
		&"progression.optional.m03",
	]:
		var invalid_ledger: PlayerProgressionStateScript = _state(100, [claimed_id])
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(invalid_ledger, command, registry),
			PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_CLAIMED_REWARD_ID,
			&"",
			invalid_ledger,
			"Unknown restored ledger entry",
		)
	var unknown_claimed_and_excessive_health: PlayerProgressionStateScript = _state(
		101,
		[&"progression.reward.unknown"],
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			unknown_claimed_and_excessive_health,
			command,
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.UNKNOWN_CLAIMED_REWARD_ID,
		&"",
		unknown_claimed_and_excessive_health,
		"Unknown restored ledger entry before current-health range",
	)
	var excessive_health: PlayerProgressionStateScript = _state(101)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(excessive_health, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.CURRENT_HEALTH_OUT_OF_RANGE,
		&"",
		excessive_health,
		"Restored current health above derived maximum",
	)
	var invalid_kind_command := PermanentGrowthClaimCommandScript.new()
	invalid_kind_command._kind = 999
	invalid_kind_command._reward_id = &"progression.reward.main.chapter.01.attack"
	invalid_kind_command._initialized = true
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			excessive_health,
			invalid_kind_command,
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.CURRENT_HEALTH_OUT_OF_RANGE,
		&"",
		excessive_health,
		"Current-health range before invalid command",
	)


func _fails_closed_for_registry_and_versions(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var reward_id: StringName = &"progression.reward.main.chapter.01.attack"
	var command: PermanentGrowthClaimCommandScript = PermanentGrowthClaimCommandScript.claim(
		reward_id
	)
	var schema_mismatch: PlayerProgressionStateScript = PlayerProgressionStateScript.create(
		PermanentGrowthClaimOracle.PROFILE_ID, 4, 5, 0, [reward_id]
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(schema_mismatch, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.CONTENT_SCHEMA_VERSION_MISMATCH,
		&"",
		schema_mismatch,
		"Schema mismatch before duplicate and zero health",
	)
	var content_mismatch: PlayerProgressionStateScript = PlayerProgressionStateScript.create(
		PermanentGrowthClaimOracle.PROFILE_ID, 5, 4, 0, [reward_id]
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(content_mismatch, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.CONTENT_VERSION_MISMATCH,
		&"",
		content_mismatch,
		"Content mismatch before duplicate and zero health",
	)
	var content_and_profile_mismatch: PlayerProgressionStateScript = (
		PlayerProgressionStateScript.create(
			&"progression.player.impostor",
			5,
			4,
			100,
			[],
		)
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			content_and_profile_mismatch,
			command,
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.CONTENT_VERSION_MISMATCH,
		&"",
		content_and_profile_mismatch,
		"Content mismatch before profile mismatch",
	)
	var both_mismatch: PlayerProgressionStateScript = PlayerProgressionStateScript.create(
		PermanentGrowthClaimOracle.PROFILE_ID, 4, 4, 100, []
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(both_mismatch, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.CONTENT_SCHEMA_VERSION_MISMATCH,
		&"",
		both_mismatch,
		"Schema mismatch priority",
	)
	var uninitialized_registry := ContentRegistryScript.new()
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(_state(100), command, uninitialized_registry),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
		&"",
		_state(100),
		"Uninitialized registry",
	)
	var tampered_registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	tampered_registry._permanent_growth_rewards[0].increase = 99
	context.expect_true(
		not tampered_registry.is_initialized(),
		"A post-build reward mutation must invalidate the registry seal.",
	)
	var invalid_kind_command := PermanentGrowthClaimCommandScript.new()
	invalid_kind_command._kind = 999
	invalid_kind_command._reward_id = reward_id
	invalid_kind_command._initialized = true
	var healthy_state: PlayerProgressionStateScript = _state(100)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			healthy_state,
			invalid_kind_command,
			tampered_registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
		&"",
		healthy_state,
		"Tampered registry before invalid command",
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			schema_mismatch,
			command,
			tampered_registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
		&"",
		schema_mismatch,
		"Tampered registry before schema mismatch",
	)
	var duplicate_at_zero: PlayerProgressionStateScript = _state(0, [reward_id])
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			duplicate_at_zero, command, tampered_registry
		),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
		&"",
		duplicate_at_zero,
		"Tampered registry before duplicate and zero health",
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(
			duplicate_at_zero,
			invalid_kind_command,
			registry,
		),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
		reward_id,
		duplicate_at_zero,
		"Invalid command before duplicate and zero health",
	)


func _rejects_null_wrong_and_derived_inputs(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var state: PlayerProgressionStateScript = _state(100)
	var command: PermanentGrowthClaimCommandScript = PermanentGrowthClaimCommandScript.claim(
		&"progression.reward.main.chapter.01.attack"
	)
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(null, null, null),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
		&"",
		null,
		"Invalid state priority over registry and command",
	)
	for invalid_state: RefCounted in [null, RefCounted.new()]:
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(invalid_state, command, registry),
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
			&"",
			null,
			"Null or wrong state",
		)
	var derived_state := StatefulPlayerProgressionStateScript.new()
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(derived_state, command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
		&"",
		null,
		"Derived state",
	)
	context.expect_equal(
		derived_state.read_count(),
		0,
		"A derived state must be rejected before any overridable getter is read.",
	)
	for invalid_registry: RefCounted in [null, RefCounted.new()]:
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(state, command, invalid_registry),
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
			&"",
			state,
			"Null or wrong registry",
		)
	var derived_registry := StatefulContentRegistryScript.new()
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(state, command, derived_registry),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_REGISTRY,
		&"",
		state,
		"Derived registry",
	)
	context.expect_equal(
		derived_registry.read_count(),
		0,
		"A derived registry must be rejected before any overridable getter is read.",
	)
	for invalid_command: RefCounted in [null, RefCounted.new()]:
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(state, invalid_command, registry),
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
			&"",
			state,
			"Null or wrong command",
		)
	var invalid_kind_command := PermanentGrowthClaimCommandScript.new()
	invalid_kind_command._kind = 999
	invalid_kind_command._reward_id = &"progression.reward.main.chapter.01.attack"
	invalid_kind_command._initialized = true
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(state, invalid_kind_command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
		&"progression.reward.main.chapter.01.attack",
		state,
		"Exact command with an invalid kind",
	)
	for invalid_reward_id: StringName in [
		&"",
		&"progression.reward.unknown",
	]:
		var invalid_kind_and_id_command := PermanentGrowthClaimCommandScript.new()
		invalid_kind_and_id_command._kind = 999
		invalid_kind_and_id_command._reward_id = invalid_reward_id
		invalid_kind_and_id_command._initialized = true
		_expect_rejected(
			context,
			PermanentGrowthClaimKernelScript.execute(
				state,
				invalid_kind_and_id_command,
				registry,
			),
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
			invalid_reward_id,
			state,
			"Invalid command before empty or unknown reward ID",
		)
	var derived_command := StatefulPermanentGrowthClaimCommandScript.new()
	_expect_rejected(
		context,
		PermanentGrowthClaimKernelScript.execute(state, derived_command, registry),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
		&"",
		state,
		"Derived command",
	)
	context.expect_equal(
		derived_command.read_count(),
		0,
		"A derived command must be rejected before any overridable getter is read.",
	)


func _applies_mainline_sequence(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var expected_ids: Array[StringName] = PermanentGrowthClaimOracle.mainline_reward_ids()
	var state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, expected_ids, 100
	)
	_assert_derived_state(
		context,
		registry,
		state,
		[180, 180, 16, 11, 14],
		expected_ids,
		"Mainline completion",
	)


func _applies_optional_sequence(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var expected_ids: Array[StringName] = PermanentGrowthClaimOracle.optional_reward_ids()
	var state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, expected_ids, 100
	)
	_assert_derived_state(
		context,
		registry,
		state,
		[120, 120, 12, 7, 10],
		expected_ids,
		"Optional completion",
	)


func _applies_full_sequence(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var expected_ids: Array[StringName] = PermanentGrowthClaimOracle.all_reward_ids()
	var full_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, expected_ids, 100
	)
	_assert_derived_state(
		context,
		registry,
		full_state,
		[200, 200, 18, 13, 14],
		expected_ids,
		"Full completion",
	)
	var damaged_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, expected_ids, 80
	)
	_assert_derived_state(
		context,
		registry,
		damaged_state,
		[180, 200, 18, 13, 14],
		expected_ids,
		"Damaged full completion",
	)


func _replays_deterministically(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var forward_ids: Array[StringName] = PermanentGrowthClaimOracle.all_reward_ids()
	var reverse_ids: Array[StringName] = forward_ids.duplicate()
	reverse_ids.reverse()
	var first_trace: Array[Variant] = _replay_trace(registry, forward_ids)
	var second_trace: Array[Variant] = _replay_trace(registry, forward_ids)
	context.expect_equal(
		first_trace,
		second_trace,
		"Identical command sequences must produce identical state and event traces.",
	)
	var forward_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, forward_ids, 100
	)
	var reverse_state: PlayerProgressionStateScript = _apply_sequence(
		context, registry, reverse_ids, 100
	)
	_assert_state(context, forward_state, 200, forward_ids, "Forward final state")
	_assert_state(context, reverse_state, 200, forward_ids, "Reverse final state")
	context.expect_true(
		forward_state.is_equal_to(reverse_state),
		"Forward and reverse claims must converge on one canonical authoritative state.",
	)
	_assert_derived_state(
		context,
		registry,
		reverse_state,
		[200, 200, 18, 13, 14],
		forward_ids,
		"Reverse completion",
	)


func _isolates_inputs_and_result_snapshots(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var input_ids: Array[StringName] = []
	var state: PlayerProgressionStateScript = _state(100, input_ids)
	input_ids.append(&"progression.reward.optional.m04.defense")
	var result: PermanentGrowthClaimResultScript = (
		PermanentGrowthClaimKernelScript.execute(
			state,
			PermanentGrowthClaimCommandScript.claim(
				&"progression.reward.main.chapter.01.attack"
			),
			registry,
		)
	)
	context.expect_equal(
		result.status(),
		PermanentGrowthClaimResultScript.Status.APPLIED,
		"The isolation fixture must apply successfully.",
	)
	state._current_health = 0
	state._claimed_reward_ids = [&"progression.reward.optional.m04.attack"]
	var first_previous_snapshot: PlayerProgressionSnapshotScript = (
		result.previous_player_progression_snapshot()
	)
	_assert_snapshot(
		context,
		first_previous_snapshot,
		[100, 100, 10, 5, 10],
		[],
		"First returned previous snapshot",
	)
	if first_previous_snapshot != null:
		var first_previous_ids: Array[StringName] = (
			first_previous_snapshot.claimed_reward_ids()
		)
		first_previous_ids.append(&"tampered.returned.previous.id")
		context.expect_equal(
			first_previous_snapshot.claimed_reward_ids(),
			[],
			"Mutating a previous snapshot's returned ID list must not alter it.",
		)
		first_previous_snapshot._current_health = 1
		first_previous_snapshot._maximum_health = 1
		first_previous_snapshot._attack = 999
		first_previous_snapshot._claimed_reward_ids = first_previous_ids
	_assert_snapshot(
		context,
		result.previous_player_progression_snapshot(),
		[100, 100, 10, 5, 10],
		[],
		"Second returned previous snapshot",
	)
	var first_state: PlayerProgressionStateScript = result.next_state()
	first_state._current_health = 1
	first_state._claimed_reward_ids = [&"tampered.returned.state"]
	var second_state: PlayerProgressionStateScript = result.next_state()
	_assert_state(
		context,
		second_state,
		100,
		[&"progression.reward.main.chapter.01.attack"],
		"Second returned state",
	)
	var first_state_ids: Array[StringName] = second_state.claimed_reward_ids()
	first_state_ids.append(&"tampered.returned.id.list")
	context.expect_equal(
		second_state.claimed_reward_ids(),
		[&"progression.reward.main.chapter.01.attack"],
		"Mutating a returned claimed-ID list must not alter the returned state.",
	)
	var first_snapshot: PlayerProgressionSnapshotScript = (
		result.player_progression_snapshot()
	)
	first_snapshot._attack = 999
	first_snapshot._claimed_reward_ids = [&"tampered.returned.snapshot"]
	_assert_snapshot(
		context,
		result.player_progression_snapshot(),
		[100, 100, 11, 5, 10],
		[&"progression.reward.main.chapter.01.attack"],
		"Second returned snapshot",
	)
	var first_events: Array[PermanentGrowthClaimEventScript] = result.domain_events()
	first_events[0]._reward_id = &"tampered.returned.event"
	first_events.append(first_events[0])
	var second_events: Array[PermanentGrowthClaimEventScript] = result.domain_events()
	context.expect_equal(second_events.size(), 1, "Event arrays must be returned by value.")
	context.expect_equal(
		second_events[0].reward_id(),
		&"progression.reward.main.chapter.01.attack",
		"Events must be returned as deep snapshots.",
	)
	context.expect_true(
		second_events[0].is_commit_boundary(),
		"A freshly returned applied event must retain the commit boundary.",
	)


func _isolates_derivation_result_snapshot(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _fresh_canonical_registry_with_legacy_messages(context)
	var claimed_ids: Array[StringName] = [
		&"progression.reward.main.chapter.01.attack",
		&"progression.reward.main.chapter.01.maximum_health",
	]
	var state: PlayerProgressionStateScript = _state(100, claimed_ids)
	var derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(state, registry)
	)
	context.expect_true(
		derivation.succeeded(),
		"The derivation isolation fixture must succeed.",
	)
	var first_snapshot: PlayerProgressionSnapshotScript = derivation.snapshot()
	context.expect_true(first_snapshot != null, "The first derived snapshot must exist.")
	if first_snapshot == null:
		return
	var first_ids: Array[StringName] = first_snapshot.claimed_reward_ids()
	first_ids.append(&"tampered.returned.derivation.id")
	context.expect_equal(
		first_ids.size(),
		3,
		"The caller must be able to mutate its returned claimed-ID copy.",
	)
	first_snapshot._current_health = 1
	first_snapshot._maximum_health = 1
	first_snapshot._attack = 999
	first_snapshot._claimed_reward_ids = first_ids
	_assert_snapshot(
		context,
		derivation.snapshot(),
		[100, 110, 11, 5, 10],
		claimed_ids,
		"Second derivation-result snapshot",
	)


func _rejects_malformed_public_result_events(
	context: HeadlessTestContextScript,
) -> void:
	var reward_id: StringName = &"progression.reward.main.chapter.01.attack"
	var previous_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 10, 5, 10],
		[],
	)
	var next_state: PlayerProgressionStateScript = _state(100, [reward_id])
	var next_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 11, 5, 10],
		[reward_id],
	)
	var valid_event: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			reward_id,
			2,
			1,
			100,
			100,
		)
	)
	_expect_locally_valid_public_result_inputs(
		context,
		previous_snapshot,
		next_state,
		next_snapshot,
		valid_event,
		"Malformed-event base fixture",
	)
	var valid_and_null: Array[PermanentGrowthClaimEventScript] = [valid_event, null]
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.APPLIED,
			PermanentGrowthClaimResultScript.RejectionReason.NONE,
			reward_id,
			next_state,
			previous_snapshot,
			next_snapshot,
			valid_and_null,
		),
		"APPLIED with a valid and null event",
	)
	var two_valid_events: Array[PermanentGrowthClaimEventScript] = [
		valid_event,
		valid_event.copy(),
	]
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.APPLIED,
			PermanentGrowthClaimResultScript.RejectionReason.NONE,
			reward_id,
			next_state,
			previous_snapshot,
			next_snapshot,
			two_valid_events,
		),
		"APPLIED with two valid events",
	)
	var derived_event: PermanentGrowthClaimEventScript = (
		DerivedPermanentGrowthClaimEventScript.new()
	)
	context.expect_true(
		derived_event.is_valid(),
		"The derived-event fixture must have an otherwise valid payload.",
	)
	context.expect_true(
		derived_event.get_script() != PermanentGrowthClaimEventScript,
		"The derived-event fixture must remain a non-exact script.",
	)
	var derived_events: Array[PermanentGrowthClaimEventScript] = [derived_event]
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.APPLIED,
			PermanentGrowthClaimResultScript.RejectionReason.NONE,
			reward_id,
			next_state,
			previous_snapshot,
			next_snapshot,
			derived_events,
		),
		"APPLIED with a single derived event",
	)
	var valid_and_derived: Array[PermanentGrowthClaimEventScript] = [
		valid_event,
		derived_event,
	]
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.APPLIED,
			PermanentGrowthClaimResultScript.RejectionReason.NONE,
			reward_id,
			next_state,
			previous_snapshot,
			next_snapshot,
			valid_and_derived,
		),
		"APPLIED with a valid and derived event",
	)
	var one_valid_event: Array[PermanentGrowthClaimEventScript] = [valid_event]
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.ALREADY_CLAIMED,
			PermanentGrowthClaimResultScript.RejectionReason.NONE,
			reward_id,
			next_state,
			null,
			next_snapshot,
			one_valid_event,
		),
		"ALREADY_CLAIMED carrying an event",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.new(
			PermanentGrowthClaimResultScript.Status.REJECTED,
			PermanentGrowthClaimResultScript.RejectionReason.INVALID_COMMAND,
			reward_id,
			_state(100),
			null,
			null,
			one_valid_event,
		),
		"REJECTED carrying an event",
	)


func _rejects_inconsistent_public_result_deltas(
	context: HeadlessTestContextScript,
) -> void:
	var attack_id: StringName = &"progression.reward.main.chapter.01.attack"
	var defense_id: StringName = &"progression.reward.main.chapter.02.defense"
	var health_id: StringName = (
		&"progression.reward.main.chapter.01.maximum_health"
	)
	var base_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 10, 5, 10],
		[],
	)
	var attack_state: PlayerProgressionStateScript = _state(100, [attack_id])
	var valid_attack_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 11, 5, 10],
		[attack_id],
	)
	var valid_attack_event: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			attack_id,
			2,
			1,
			100,
			100,
		)
	)
	_expect_locally_valid_public_result_inputs(
		context,
		base_snapshot,
		attack_state,
		valid_attack_snapshot,
		valid_attack_event,
		"Valid attack fixture",
	)
	var unchanged_attack_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 10, 5, 10],
		[attack_id],
	)
	_expect_locally_valid_public_result_inputs(
		context,
		base_snapshot,
		attack_state,
		unchanged_attack_snapshot,
		valid_attack_event,
		"Attack ledger without stat delta fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			attack_id,
			base_snapshot,
			attack_state,
			unchanged_attack_snapshot,
			valid_attack_event,
		),
		"Attack ledger addition without an attack increase",
	)
	var wrong_kind_event: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			attack_id,
			3,
			1,
			100,
			100,
		)
	)
	_expect_locally_valid_public_result_inputs(
		context,
		base_snapshot,
		attack_state,
		valid_attack_snapshot,
		wrong_kind_event,
		"Wrong event stat-kind fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			attack_id,
			base_snapshot,
			attack_state,
			valid_attack_snapshot,
			wrong_kind_event,
		),
		"Event stat kind inconsistent with the actual attack delta",
	)
	var wrong_increase_event: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			attack_id,
			2,
			2,
			100,
			100,
		)
	)
	_expect_locally_valid_public_result_inputs(
		context,
		base_snapshot,
		attack_state,
		valid_attack_snapshot,
		wrong_increase_event,
		"Wrong event increase fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			attack_id,
			base_snapshot,
			attack_state,
			valid_attack_snapshot,
			wrong_increase_event,
		),
		"Event increase inconsistent with the actual attack delta",
	)
	var health_event_with_wrong_maximum_delta: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			health_id,
			1,
			10,
			80,
			90,
		)
	)
	var damaged_health_state_with_wrong_maximum_delta: PlayerProgressionStateScript = (
		_state(90, [health_id])
	)
	var health_snapshot_with_wrong_maximum_delta: PlayerProgressionSnapshotScript = (
		_snapshot([90, 120, 10, 5, 10], [health_id])
	)
	var damaged_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[80, 100, 10, 5, 10],
		[],
	)
	_expect_locally_valid_public_result_inputs(
		context,
		damaged_snapshot,
		damaged_health_state_with_wrong_maximum_delta,
		health_snapshot_with_wrong_maximum_delta,
		health_event_with_wrong_maximum_delta,
		"Health maximum-delta mismatch fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			health_id,
			damaged_snapshot,
			damaged_health_state_with_wrong_maximum_delta,
			health_snapshot_with_wrong_maximum_delta,
			health_event_with_wrong_maximum_delta,
		),
		"Health reward increasing maximum health by the wrong delta",
	)
	var health_event_from_damaged: PermanentGrowthClaimEventScript = (
		PermanentGrowthClaimEventScript.applied(
			PermanentGrowthClaimOracle.PROFILE_ID,
			PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
			PermanentGrowthClaimOracle.CONTENT_VERSION,
			health_id,
			1,
			10,
			80,
			90,
		)
	)
	var current_only_health_state: PlayerProgressionStateScript = _state(90, [health_id])
	var current_only_health_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[90, 100, 10, 5, 10],
		[health_id],
	)
	_expect_locally_valid_public_result_inputs(
		context,
		damaged_snapshot,
		current_only_health_state,
		current_only_health_snapshot,
		health_event_from_damaged,
		"Health current-only delta fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			health_id,
			damaged_snapshot,
			current_only_health_state,
			current_only_health_snapshot,
			health_event_from_damaged,
		),
		"Health reward increasing current health without maximum health",
	)
	var extra_ledger_ids: Array[StringName] = [attack_id, defense_id]
	var extra_ledger_state: PlayerProgressionStateScript = _state(100, extra_ledger_ids)
	var extra_ledger_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 11, 5, 10],
		extra_ledger_ids,
	)
	_expect_locally_valid_public_result_inputs(
		context,
		base_snapshot,
		extra_ledger_state,
		extra_ledger_snapshot,
		valid_attack_event,
		"Extra ledger addition fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			attack_id,
			base_snapshot,
			extra_ledger_state,
			extra_ledger_snapshot,
			valid_attack_event,
		),
		"Claim ledger adding the requested ID and an extra ID",
	)
	var already_claimed_snapshot: PlayerProgressionSnapshotScript = _snapshot(
		[100, 100, 10, 5, 10],
		[attack_id],
	)
	_expect_locally_valid_public_result_inputs(
		context,
		already_claimed_snapshot,
		attack_state,
		valid_attack_snapshot,
		valid_attack_event,
		"No ledger addition fixture",
	)
	_expect_invalid_public_result(
		context,
		PermanentGrowthClaimResultScript.applied(
			attack_id,
			already_claimed_snapshot,
			attack_state,
			valid_attack_snapshot,
			valid_attack_event,
		),
		"Claim ledger that already contained the requested ID",
	)


func _fresh_canonical_registry_with_legacy_messages(context: HeadlessTestContextScript) -> ContentRegistryScript:
	return CanonicalRegistryFixtureScript.fresh_canonical_registry_with_failure_messages(
		context,
		"The canonical registry fixture must build.",
		"The canonical registry fixture must be initialized and sealed.",
	)


func _state(
	current_health: int,
	claimed_reward_ids: Array[StringName] = [],
) -> PlayerProgressionStateScript:
	return PlayerProgressionStateScript.create(
		PermanentGrowthClaimOracle.PROFILE_ID,
		PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
		PermanentGrowthClaimOracle.CONTENT_VERSION,
		current_health,
		claimed_reward_ids,
	)


func _snapshot(
	values: Array[int],
	claimed_reward_ids: Array[StringName],
) -> PlayerProgressionSnapshotScript:
	return PlayerProgressionSnapshotScript.create(
		PermanentGrowthClaimOracle.PROFILE_ID,
		PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
		PermanentGrowthClaimOracle.CONTENT_VERSION,
		values[0],
		values[1],
		values[2],
		values[3],
		values[4],
		claimed_reward_ids,
	)


func _oracle_row(
	reward_id: StringName,
) -> PermanentGrowthClaimOracle.RewardTransitionRow:
	for row: PermanentGrowthClaimOracle.RewardTransitionRow in (
		PermanentGrowthClaimOracle.reward_rows()
	):
		if row.reward_id == reward_id:
			return row
	return null


func _expect_applied(
	context: HeadlessTestContextScript,
	result: PermanentGrowthClaimResultScript,
	row: PermanentGrowthClaimOracle.RewardTransitionRow,
	expected_values: Array[int],
	expected_claimed_ids: Array[StringName],
	previous_current_health: int,
) -> void:
	context.expect_equal(
		result.status(),
		PermanentGrowthClaimResultScript.Status.APPLIED,
		"%s must be applied." % String(row.reward_id),
	)
	context.expect_equal(
		result.rejection_reason(),
		PermanentGrowthClaimResultScript.RejectionReason.NONE,
		"An applied result must not expose a rejection reason.",
	)
	context.expect_equal(
		result.requested_reward_id(),
		row.reward_id,
		"The applied result must preserve the requested reward ID.",
	)
	context.expect_true(result.succeeded(), "An applied result must succeed.")
	context.expect_true(result.was_applied(), "An applied result must report was_applied.")
	context.expect_true(
		not result.was_already_claimed(),
		"An applied result must not report already claimed.",
	)
	context.expect_true(not result.was_rejected(), "An applied result must not be rejected.")
	context.expect_true(result.is_commit_boundary(), "APPLIED must be a commit boundary.")
	_assert_state(
		context,
		result.next_state(),
		expected_values[0],
		expected_claimed_ids,
		"Applied next state",
	)
	_assert_snapshot(
		context,
		result.player_progression_snapshot(),
		expected_values,
		expected_claimed_ids,
		"Applied snapshot",
	)
	var previous_values: Array[int] = expected_values.duplicate()
	previous_values[0] = previous_current_health
	match row.stat_kind:
		1:
			previous_values[1] -= row.increase
		2:
			previous_values[2] -= row.increase
		3:
			previous_values[3] -= row.increase
		4:
			previous_values[4] -= row.increase
	var previous_claimed_ids: Array[StringName] = expected_claimed_ids.duplicate()
	previous_claimed_ids.erase(row.reward_id)
	_assert_snapshot(
		context,
		result.previous_player_progression_snapshot(),
		previous_values,
		previous_claimed_ids,
		"Applied previous snapshot",
	)
	var events: Array[PermanentGrowthClaimEventScript] = result.domain_events()
	context.expect_equal(events.size(), 1, "APPLIED must emit exactly one domain event.")
	if events.is_empty():
		return
	var event: PermanentGrowthClaimEventScript = events[0]
	context.expect_true(event.is_valid(), "The applied domain event must be valid.")
	context.expect_true(event.is_commit_boundary(), "The applied event must commit.")
	context.expect_equal(
		event.kind(),
		PermanentGrowthClaimEventScript.Kind.APPLIED,
		"The event kind must be APPLIED.",
	)
	context.expect_equal(event.profile_id(), PermanentGrowthClaimOracle.PROFILE_ID, "Event profile.")
	context.expect_equal(
		event.content_schema_version(),
		PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
		"Event schema version.",
	)
	context.expect_equal(
		event.content_version(),
		PermanentGrowthClaimOracle.CONTENT_VERSION,
		"Event content version.",
	)
	context.expect_equal(event.reward_id(), row.reward_id, "Event reward ID.")
	context.expect_equal(event.stat_kind(), row.stat_kind, "Event stat kind.")
	context.expect_equal(event.increase(), row.increase, "Event increase.")
	context.expect_equal(
		event.previous_current_health(),
		previous_current_health,
		"Event previous current health.",
	)
	context.expect_equal(
		event.next_current_health(),
		expected_values[0],
		"Event next current health.",
	)


func _expect_already_claimed(
	context: HeadlessTestContextScript,
	result: PermanentGrowthClaimResultScript,
	expected_state: PlayerProgressionStateScript,
	expected_values: Array[int],
	expected_claimed_ids: Array[StringName],
	reward_id: StringName,
) -> void:
	context.expect_equal(
		result.status(),
		PermanentGrowthClaimResultScript.Status.ALREADY_CLAIMED,
		"A duplicate reward must be idempotent.",
	)
	context.expect_equal(
		result.rejection_reason(),
		PermanentGrowthClaimResultScript.RejectionReason.NONE,
		"ALREADY_CLAIMED must not expose a rejection reason.",
	)
	context.expect_equal(result.requested_reward_id(), reward_id, "Duplicate requested ID.")
	context.expect_true(result.was_already_claimed(), "Duplicate status flag.")
	context.expect_true(not result.was_applied(), "A duplicate must not be applied.")
	context.expect_true(not result.was_rejected(), "A duplicate must not be rejected.")
	context.expect_true(not result.is_commit_boundary(), "A duplicate must not commit.")
	context.expect_equal(result.domain_events().size(), 0, "A duplicate must emit no event.")
	context.expect_equal(
		result.previous_player_progression_snapshot(),
		null,
		"ALREADY_CLAIMED must not expose a previous snapshot.",
	)
	_assert_state(
		context,
		result.next_state(),
		expected_state.current_health(),
		expected_claimed_ids,
		"Duplicate next state",
	)
	_assert_snapshot(
		context,
		result.player_progression_snapshot(),
		expected_values,
		expected_claimed_ids,
		"Duplicate snapshot",
	)
	var returned_state: PlayerProgressionStateScript = result.next_state()
	context.expect_true(
		returned_state != null and returned_state.is_equal_to(expected_state),
		"A duplicate must return the exact unchanged authoritative values.",
	)


func _expect_rejected(
	context: HeadlessTestContextScript,
	result: PermanentGrowthClaimResultScript,
	expected_reason: int,
	expected_requested_id: StringName,
	expected_state: PlayerProgressionStateScript,
	label: String,
) -> void:
	context.expect_equal(
		result.status(),
		PermanentGrowthClaimResultScript.Status.REJECTED,
		"%s must be rejected." % label,
	)
	context.expect_equal(
		result.rejection_reason(),
		expected_reason,
		"%s must expose the expected rejection reason." % label,
	)
	context.expect_equal(
		result.requested_reward_id(),
		expected_requested_id,
		"%s must expose the expected requested ID." % label,
	)
	context.expect_true(result.was_rejected(), "%s rejection flag." % label)
	context.expect_true(not result.was_applied(), "%s must not be applied." % label)
	context.expect_true(
		not result.was_already_claimed(),
		"%s must not be already claimed." % label,
	)
	context.expect_true(not result.is_commit_boundary(), "%s must not commit." % label)
	context.expect_equal(result.domain_events().size(), 0, "%s must emit no events." % label)
	context.expect_equal(
		result.previous_player_progression_snapshot(),
		null,
		"%s must not expose a previous snapshot." % label,
	)
	context.expect_equal(
		result.player_progression_snapshot(),
		null,
		"%s must not expose a derived snapshot." % label,
	)
	var returned_state: PlayerProgressionStateScript = result.next_state()
	if expected_state == null:
		context.expect_equal(returned_state, null, "%s must not invent a state." % label)
		return
	context.expect_true(returned_state != null, "%s must return the unchanged state." % label)
	if returned_state == null:
		return
	context.expect_equal(
		returned_state.profile_id(),
		expected_state.profile_id(),
		"%s returned profile." % label,
	)
	context.expect_equal(
		returned_state.content_schema_version(),
		expected_state.content_schema_version(),
		"%s returned schema version." % label,
	)
	context.expect_equal(
		returned_state.content_version(),
		expected_state.content_version(),
		"%s returned content version." % label,
	)
	context.expect_equal(
		returned_state.current_health(),
		expected_state.current_health(),
		"%s returned current health." % label,
	)
	context.expect_equal(
		returned_state.claimed_reward_ids(),
		expected_state.claimed_reward_ids(),
		"%s returned claimed IDs." % label,
	)


func _expect_invalid_public_result(
	context: HeadlessTestContextScript,
	result: PermanentGrowthClaimResultScript,
	label: String,
) -> void:
	context.expect_equal(
		result.status(),
		PermanentGrowthClaimResultScript.Status.REJECTED,
		"%s must fail closed as REJECTED." % label,
	)
	context.expect_equal(
		result.rejection_reason(),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_RESULT,
		"%s must expose INVALID_RESULT." % label,
	)
	context.expect_true(not result.succeeded(), "%s must not succeed." % label)
	context.expect_true(not result.was_applied(), "%s must not be applied." % label)
	context.expect_true(
		not result.was_already_claimed(),
		"%s must not be already claimed." % label,
	)
	context.expect_true(result.was_rejected(), "%s must report rejected." % label)
	context.expect_true(not result.is_commit_boundary(), "%s must not commit." % label)
	context.expect_equal(result.next_state(), null, "%s must not expose next state." % label)
	context.expect_equal(
		result.previous_player_progression_snapshot(),
		null,
		"%s must not expose a previous snapshot." % label,
	)
	context.expect_equal(
		result.player_progression_snapshot(),
		null,
		"%s must not expose a next snapshot." % label,
	)
	context.expect_equal(
		result.domain_events().size(),
		0,
		"%s must not expose domain events." % label,
	)


func _expect_locally_valid_public_result_inputs(
	context: HeadlessTestContextScript,
	previous_snapshot: PlayerProgressionSnapshotScript,
	next_state: PlayerProgressionStateScript,
	next_snapshot: PlayerProgressionSnapshotScript,
	domain_event: PermanentGrowthClaimEventScript,
	label: String,
) -> void:
	context.expect_true(
		previous_snapshot != null and previous_snapshot.is_valid(),
		"%s previous snapshot must be locally valid." % label,
	)
	context.expect_true(
		previous_snapshot != null
		and previous_snapshot.get_script() == PlayerProgressionSnapshotScript,
		"%s previous snapshot must use the exact public script." % label,
	)
	context.expect_true(
		next_state != null and next_state.is_valid(),
		"%s next state must be locally valid." % label,
	)
	context.expect_true(
		next_state != null and next_state.get_script() == PlayerProgressionStateScript,
		"%s next state must use the exact public script." % label,
	)
	context.expect_true(
		next_snapshot != null and next_snapshot.is_valid(),
		"%s next snapshot must be locally valid." % label,
	)
	context.expect_true(
		next_snapshot != null
		and next_snapshot.get_script() == PlayerProgressionSnapshotScript,
		"%s next snapshot must use the exact public script." % label,
	)
	context.expect_true(
		domain_event != null and domain_event.is_valid(),
		"%s domain event must be locally valid." % label,
	)
	context.expect_true(
		domain_event != null
		and domain_event.get_script() == PermanentGrowthClaimEventScript,
		"%s domain event must use the exact public script." % label,
	)
	if next_state == null or next_snapshot == null or domain_event == null:
		return
	context.expect_equal(
		next_state.profile_id(),
		next_snapshot.profile_id(),
		"%s state and next snapshot profiles must agree." % label,
	)
	context.expect_equal(
		next_state.content_schema_version(),
		next_snapshot.content_schema_version(),
		"%s state and next snapshot schema versions must agree." % label,
	)
	context.expect_equal(
		next_state.content_version(),
		next_snapshot.content_version(),
		"%s state and next snapshot content versions must agree." % label,
	)
	context.expect_equal(
		next_state.current_health(),
		next_snapshot.current_health(),
		"%s state and next snapshot current health must agree." % label,
	)
	context.expect_equal(
		next_state.claimed_reward_ids(),
		next_snapshot.claimed_reward_ids(),
		"%s state and next snapshot ledgers must agree." % label,
	)
	context.expect_equal(
		domain_event.profile_id(),
		next_state.profile_id(),
		"%s event and state profiles must agree." % label,
	)
	context.expect_equal(
		domain_event.content_schema_version(),
		next_state.content_schema_version(),
		"%s event and state schema versions must agree." % label,
	)
	context.expect_equal(
		domain_event.content_version(),
		next_state.content_version(),
		"%s event and state content versions must agree." % label,
	)
	context.expect_equal(
		domain_event.next_current_health(),
		next_state.current_health(),
		"%s event and state next health must agree." % label,
	)
	context.expect_true(
		next_state.has_claimed_reward(domain_event.reward_id()),
		"%s state must contain the event reward ID." % label,
	)


func _apply_sequence(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	reward_ids: Array[StringName],
	initial_current_health: int,
) -> PlayerProgressionStateScript:
	var state: PlayerProgressionStateScript = _state(initial_current_health)
	for reward_id: StringName in reward_ids:
		var previous_state: PlayerProgressionStateScript = state
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			)
		)
		context.expect_equal(
			result.status(),
			PermanentGrowthClaimResultScript.Status.APPLIED,
			"Sequence reward %s must apply." % String(reward_id),
		)
		context.expect_true(
			result.is_commit_boundary(),
			"Each successful sequence reward must be a commit boundary.",
		)
		context.expect_equal(
			result.domain_events().size(),
			1,
			"Each successful sequence reward must emit one event.",
		)
		context.expect_equal(
			result.domain_events()[0].reward_id(),
			reward_id,
			"Sequence event order must match command order.",
		)
		context.expect_true(
			not previous_state.has_claimed_reward(reward_id),
			"The sequence input must remain unchanged after execution.",
		)
		var next_state: PlayerProgressionStateScript = result.next_state()
		context.expect_true(next_state != null, "A successful sequence step needs next state.")
		if next_state == null:
			return state
		state = next_state
	return state


func _assert_derived_state(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	state: PlayerProgressionStateScript,
	expected_values: Array[int],
	expected_claimed_ids: Array[StringName],
	label: String,
) -> void:
	_assert_state(
		context,
		state,
		expected_values[0],
		expected_claimed_ids,
		"%s state" % label,
	)
	var derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(state, registry)
	)
	context.expect_true(derivation.succeeded(), "%s must derive." % label)
	context.expect_equal(
		derivation.failure_reason(),
		PlayerProgressionDerivationResultScript.FailureReason.NONE,
		"%s derivation must not fail." % label,
	)
	_assert_snapshot(
		context,
		derivation.snapshot(),
		expected_values,
		expected_claimed_ids,
		"%s snapshot" % label,
	)


func _assert_state(
	context: HeadlessTestContextScript,
	state: PlayerProgressionStateScript,
	expected_current_health: int,
	expected_claimed_ids: Array[StringName],
	label: String,
) -> void:
	context.expect_true(state != null, "%s must exist." % label)
	if state == null:
		return
	context.expect_equal(state.profile_id(), PermanentGrowthClaimOracle.PROFILE_ID, "%s profile." % label)
	context.expect_equal(
		state.content_schema_version(),
		PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
		"%s schema version." % label,
	)
	context.expect_equal(
		state.content_version(),
		PermanentGrowthClaimOracle.CONTENT_VERSION,
		"%s content version." % label,
	)
	context.expect_equal(state.current_health(), expected_current_health, "%s health." % label)
	context.expect_equal(state.claimed_reward_ids(), expected_claimed_ids, "%s claimed IDs." % label)


func _assert_snapshot(
	context: HeadlessTestContextScript,
	snapshot: PlayerProgressionSnapshotScript,
	expected_values: Array[int],
	expected_claimed_ids: Array[StringName],
	label: String,
) -> void:
	context.expect_true(snapshot != null, "%s must exist." % label)
	if snapshot == null:
		return
	context.expect_true(snapshot.is_valid(), "%s must be valid." % label)
	context.expect_equal(snapshot.profile_id(), PermanentGrowthClaimOracle.PROFILE_ID, "%s profile." % label)
	context.expect_equal(
		snapshot.content_schema_version(),
		PermanentGrowthClaimOracle.CONTENT_SCHEMA_VERSION,
		"%s schema version." % label,
	)
	context.expect_equal(
		snapshot.content_version(),
		PermanentGrowthClaimOracle.CONTENT_VERSION,
		"%s content version." % label,
	)
	context.expect_equal(snapshot.current_health(), expected_values[0], "%s current health." % label)
	context.expect_equal(snapshot.maximum_health(), expected_values[1], "%s maximum health." % label)
	context.expect_equal(snapshot.attack(), expected_values[2], "%s attack." % label)
	context.expect_equal(snapshot.defense(), expected_values[3], "%s defense." % label)
	context.expect_equal(snapshot.speed(), expected_values[4], "%s speed." % label)
	context.expect_equal(snapshot.claimed_reward_ids(), expected_claimed_ids, "%s claimed IDs." % label)


func _replay_trace(
	registry: ContentRegistryScript,
	reward_ids: Array[StringName],
) -> Array[Variant]:
	var trace: Array[Variant] = []
	var state: PlayerProgressionStateScript = _state(100)
	for reward_id: StringName in reward_ids:
		var result: PermanentGrowthClaimResultScript = (
			PermanentGrowthClaimKernelScript.execute(
				state,
				PermanentGrowthClaimCommandScript.claim(reward_id),
				registry,
			)
		)
		var snapshot: PlayerProgressionSnapshotScript = result.player_progression_snapshot()
		var events: Array[PermanentGrowthClaimEventScript] = result.domain_events()
		trace.append([
			result.status(),
			result.rejection_reason(),
			result.requested_reward_id(),
			result.is_commit_boundary(),
			snapshot.current_health(),
			snapshot.maximum_health(),
			snapshot.attack(),
			snapshot.defense(),
			snapshot.speed(),
			snapshot.claimed_reward_ids(),
			events[0].reward_id(),
			events[0].stat_kind(),
			events[0].increase(),
			events[0].previous_current_health(),
			events[0].next_current_health(),
		])
		state = result.next_state()
	return trace
