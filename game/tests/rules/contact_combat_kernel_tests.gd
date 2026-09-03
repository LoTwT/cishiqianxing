extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContentRegistryBuildResultScript := preload(
	"res://src/content/content_registry_build_result.gd"
)
const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatEventScript := preload(
	"res://src/rules/contact_combat_event.gd"
)
const ContactCombatKernelScript := preload(
	"res://src/rules/contact_combat_kernel.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)
const ContactCombatPlayerStateCandidateScript := preload(
	"res://src/rules/contact_combat_player_state_candidate.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContactCombatResultScript := preload(
	"res://src/rules/contact_combat_result.gd"
)
const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionDerivationResultScript := preload(
	"res://src/rules/player_progression_derivation_result.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)
const PermanentGrowthClaimKernelScript := preload(
	"res://src/rules/permanent_growth_claim_kernel.gd"
)
const PermanentGrowthClaimCommandScript := preload(
	"res://src/rules/permanent_growth_claim_command.gd"
)
const PermanentGrowthClaimResultScript := preload(
	"res://src/rules/permanent_growth_claim_result.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)
const ContactCombatOracle := preload(
	"res://tests/rules/contact_combat_oracle.gd"
)
const ContactCombatTestDoubles := preload(
	"res://tests/support/contact_combat_test_doubles.gd"
)

const PROFILE_ID: StringName = &"progression.player.loer"
const CONTENT_SCHEMA_VERSION: int = 5
const CONTENT_VERSION: int = 5
const OPPONENT_ID: StringName = &"opponent.test.contact"
const BASE_MAXIMUM_HEALTH: int = 100
const BASE_ATTACK: int = 10
const BASE_DEFENSE: int = 5
const BASE_SPEED: int = 10
const MAX_INT: int = 9_223_372_036_854_775_807
const EXPECTED_SMALL_DOMAIN_CASES: int = 30_096
const KERNEL_SAMPLE_STRIDE: int = 29
const EXPECTED_KERNEL_SAMPLES: int = 1_038

const ATTACK_REWARD_IDS: Array[StringName] = [
	&"progression.reward.main.chapter.01.attack",
	&"progression.reward.main.chapter.03.attack",
]
const DEFENSE_REWARD_IDS: Array[StringName] = [
	&"progression.reward.main.chapter.02.defense",
	&"progression.reward.main.chapter.03.defense",
]
const SPEED_REWARD_IDS: Array[StringName] = [
	&"progression.reward.main.chapter.04.speed",
	&"progression.reward.main.chapter.06.speed",
]

var _cached_registry: ContentRegistryScript


func cases() -> Array[HeadlessTestCaseScript]:
	return [
		HeadlessTestCaseScript.new(
			"contact_combat.freezes_literal_oracle",
			_freezes_literal_oracle,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.matches_teaching_fixture",
			_matches_teaching_fixture,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.validates_30096_oracle_cells_and_kernel_samples",
			_matches_30096_small_domain_oracle,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.handles_zero_damage_matrix",
			_handles_zero_damage_matrix,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.applies_shield_once",
			_applies_shield_once,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.projects_temporary_effects_and_support",
			_projects_temporary_effects_and_support,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.rejects_invalid_input_matrices",
			_rejects_invalid_input_matrices,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.rejects_derived_inputs_without_reads",
			_rejects_derived_inputs_without_reads,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.rejects_overflow_and_keeps_counts_compact",
			_rejects_overflow_and_keeps_counts_compact,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.isolates_inputs_and_outputs",
			_isolates_inputs_and_outputs,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.rejects_malformed_public_results",
			_rejects_malformed_public_results,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.replays_deterministically",
			_replays_deterministically,
		),
		HeadlessTestCaseScript.new(
			"contact_combat.satisfies_metamorphic_invariants",
			_satisfies_metamorphic_invariants,
		),
	]


func _freezes_literal_oracle(context: HeadlessTestContextScript) -> void:
	var rows: Array[Array] = ContactCombatOracle.effect_rows()
	context.expect_equal(rows.size(), 6, "The oracle must freeze all six effect rows.")
	var seen_effects: Dictionary[int, bool] = {}
	for row: Array in rows:
		context.expect_equal(row.size(), 4, "Each effect row must contain four integers.")
		context.expect_true(
			row[0] >= ContactCombatOracle.EFFECT_NONE
			and row[0] <= ContactCombatOracle.EFFECT_ATTACK_DEFENSE_2,
			"Every effect row must use a literal oracle effect ID.",
		)
		context.expect_true(
			not seen_effects.has(row[0]),
			"Oracle effect IDs must be unique.",
		)
		seen_effects[row[0]] = true
		for index: int in range(1, 4):
			context.expect_true(
				row[index] == 0 or row[index] == 2,
				"Every oracle effect bonus must be the literal value zero or two.",
			)
		context.expect_equal(
			ContactCombatCommandScript.temporary_effect_bonuses(row[0]),
			[row[1], row[2], row[3]],
			"Production effect mapping must match the independent literal row.",
		)
	context.expect_equal(
		rows,
		[
			[0, 0, 0, 0],
			[1, 2, 0, 0],
			[2, 0, 2, 0],
			[3, 0, 0, 2],
			[4, 2, 0, 2],
			[5, 2, 2, 0],
		],
		"The six effect rows must retain their approved literal mapping.",
	)
	context.expect_equal(
		ContactCombatOracle.effect_bonuses(-1),
		[],
		"The oracle must reject a negative effect ID.",
	)
	context.expect_equal(
		ContactCombatOracle.effect_bonuses(6),
		[],
		"The oracle must reject an effect ID above the frozen range.",
	)


func _matches_teaching_fixture(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _state(100)
	var opponent_state: ContactCombatOpponentStateScript = _opponent(
		18, 7, 2, 8, false
	)
	var baseline: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		opponent_state,
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)
	var expected_baseline: ContactCombatOracle.CombatProjection = (
		ContactCombatOracle.evaluate(
			100, 10, 5, 10,
			18, 7, 2, 8,
			ContactCombatOracle.SIDE_PLAYER,
			ContactCombatOracle.EFFECT_NONE,
			0,
			false,
		)
	)
	context.expect_equal(
		_encode_result(baseline),
		expected_baseline.encode(),
		"The fixed first-combat fixture must match the independent oracle.",
	)
	var baseline_resolution: ContactCombatResolutionScript = baseline.resolution()
	context.expect_equal(
		baseline_resolution.player_damage_per_attack(),
		8,
		"The teaching opponent must take eight damage per player attack.",
	)
	context.expect_equal(
		baseline_resolution.player_attacks_required_to_clear(),
		3,
		"The teaching opponent must require three player attacks.",
	)
	context.expect_equal(
		baseline_resolution.opponent_attacks_executed(),
		2,
		"The teaching opponent must execute two counterattacks.",
	)
	context.expect_equal(
		baseline_resolution.player_health_loss(),
		4,
		"The teaching fixture must preview exactly four health loss.",
	)

	var boosted: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		opponent_state,
		ContactCombatCommandScript.evaluate(
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.TemporaryEffect.ATTACK_2,
		),
		registry,
	)
	var expected_boosted: ContactCombatOracle.CombatProjection = (
		ContactCombatOracle.evaluate(
			100, 10, 5, 10,
			18, 7, 2, 8,
			ContactCombatOracle.SIDE_PLAYER,
			ContactCombatOracle.EFFECT_ATTACK_2,
			0,
			false,
		)
	)
	context.expect_equal(
		_encode_result(boosted),
		expected_boosted.encode(),
		"The temporary-attack teaching fixture must match the independent oracle.",
	)
	var boosted_resolution: ContactCombatResolutionScript = boosted.resolution()
	context.expect_equal(
		boosted_resolution.player_damage_per_attack(),
		10,
		"Temporary attack must raise teaching damage to ten.",
	)
	context.expect_equal(
		boosted_resolution.player_attacks_required_to_clear(),
		2,
		"Temporary attack must reduce the teaching combat to two attacks.",
	)
	context.expect_equal(
		boosted_resolution.player_health_loss(),
		2,
		"Temporary attack must reduce the teaching loss to two.",
	)
	context.expect_true(
		boosted_resolution.temporary_effect_should_be_consumed(),
		"A resolved temporary projection must expose consume-on-resolution intent.",
	)
	var events: Array[ContactCombatEventScript] = boosted.domain_events()
	context.expect_equal(events.size(), 1, "A resolved candidate must emit one event.")
	context.expect_true(
		events[0].is_resolution_candidate(),
		"The teaching event must be a resolution candidate, not a commit claim.",
	)
	context.expect_true(
		not events[0].is_commit_boundary(),
		"A contact-resolution candidate must never claim to be a commit boundary.",
	)
	context.expect_true(
		events[0].resolution().is_equal_to(boosted_resolution),
		"The candidate event and preview must carry one canonical resolution.",
	)


func _matches_30096_small_domain_oracle(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var totals: Array[int] = [0, 0, 0, 0]
	var diagnostics: Array[String] = []
	_run_oracle_matrix(
		registry,
		[1, 2, 3],
		[1, 2, 3],
		[0, 1, 2],
		[0, 1, 2],
		[5, 6, 7],
		[10, 11, 12],
		[0, 1],
		[10, 11],
		[ContactCombatCommandScript.TemporaryEffect.NONE],
		[0],
		totals,
		diagnostics,
	)
	_run_oracle_matrix(
		registry,
		[1, 3],
		[1, 3],
		[0, 2],
		[0, 2],
		[5, 7],
		[10, 12],
		[0, 2],
		[10, 12],
		[0, 1, 2, 3, 4, 5],
		[0, 1, 2],
		totals,
		diagnostics,
	)
	context.expect_equal(
		totals[0],
		EXPECTED_SMALL_DOMAIN_CASES,
		"The bounded cross-product must execute exactly 30,096 cases.",
	)
	context.expect_equal(
		totals[1],
		0,
		"Every sampled kernel case must match the independent step oracle. First mismatches: %s"
		% str(diagnostics),
	)
	context.expect_equal(
		totals[2],
		EXPECTED_KERNEL_SAMPLES,
		"The deterministic prime-stride sample must execute exactly 1,038 full kernels.",
	)
	context.expect_equal(
		totals[3],
		0,
		(
			"Every one of the 30,096 oracle projections must satisfy production "
			+ "resolution invariants. First mismatches: %s"
		)
		% str(diagnostics),
	)


func _run_oracle_matrix(
	registry: ContentRegistryScript,
	player_healths: Array,
	opponent_durabilities: Array,
	player_attack_bonuses: Array,
	player_defense_bonuses: Array,
	opponent_attacks: Array,
	opponent_defenses: Array,
	player_speed_bonuses: Array,
	opponent_speeds: Array,
	temporary_effects: Array,
	support_counts: Array,
	totals: Array[int],
	diagnostics: Array[String],
) -> void:
	for player_health: int in player_healths:
		for player_attack_bonus: int in player_attack_bonuses:
			for player_defense_bonus: int in player_defense_bonuses:
				for player_speed_bonus: int in player_speed_bonuses:
					for opponent_durability: int in opponent_durabilities:
						for opponent_attack: int in opponent_attacks:
							for opponent_defense: int in opponent_defenses:
								for opponent_speed: int in opponent_speeds:
									for initiator_side: int in [1, 2]:
										for shield_intact: bool in [false, true]:
											for temporary_effect: int in temporary_effects:
												for support_count: int in support_counts:
													var expected := ContactCombatOracle.evaluate(
														player_health,
														BASE_ATTACK + player_attack_bonus,
														BASE_DEFENSE + player_defense_bonus,
														BASE_SPEED + player_speed_bonus,
														opponent_durability,
														opponent_attack,
														opponent_defense,
														opponent_speed,
														initiator_side,
														temporary_effect,
														support_count,
														shield_intact,
													)
													var scenario_index: int = totals[0]
													totals[0] += 1
													var projected_resolution := (
														_resolution_from_oracle(expected)
													)
													if not projected_resolution.is_valid():
														totals[3] += 1
														if diagnostics.size() < 12:
															diagnostics.append(
																"oracle projection rejected at cell %d: %s"
																% [scenario_index, str(expected.encode())]
															)
													if scenario_index % KERNEL_SAMPLE_STRIDE != 0:
														continue
													totals[2] += 1
													var player_state := _state_for_bonuses(
														player_health,
														player_attack_bonus,
														player_defense_bonus,
														player_speed_bonus,
													)
													var opponent_state := _opponent(
														opponent_durability,
														opponent_attack,
														opponent_defense,
														opponent_speed,
														shield_intact,
													)
													var command := ContactCombatCommandScript.evaluate(
														initiator_side,
														temporary_effect,
														support_count,
													)
													var result := ContactCombatKernelScript.evaluate(
														player_state,
														opponent_state,
														command,
														registry,
													)
													var actual_encoding: Array = _encode_result(result)
													var expected_encoding: Array = expected.encode()
													if actual_encoding != expected_encoding:
														totals[1] += 1
														if diagnostics.size() < 12:
															diagnostics.append(
																"hp=%d,dur=%d,p=%d/%d/%d,o=%d/%d/%d,i=%d,shield=%s,e=%d,s=%d expected=%s actual=%s"
																% [
																	player_health,
																	opponent_durability,
																	BASE_ATTACK + player_attack_bonus,
																	BASE_DEFENSE + player_defense_bonus,
																	BASE_SPEED + player_speed_bonus,
																	opponent_attack,
																	opponent_defense,
																	opponent_speed,
																	initiator_side,
																	str(shield_intact),
																	temporary_effect,
																	support_count,
																	str(expected_encoding),
																	str(actual_encoding),
																]
															)


func _handles_zero_damage_matrix(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _state(20)
	var blocked_command := ContactCombatCommandScript.evaluate(
		ContactCombatCommandScript.Side.PLAYER,
		ContactCombatCommandScript.TemporaryEffect.DEFENSE_2,
	)
	var player_zero: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		_opponent(10, 8, 10, 9, true),
		blocked_command,
		registry,
	)
	var player_zero_oracle := ContactCombatOracle.evaluate(
		20, 10, 5, 10,
		10, 8, 10, 9,
		ContactCombatOracle.SIDE_PLAYER,
		ContactCombatOracle.EFFECT_DEFENSE_2,
		0,
		true,
	)
	context.expect_equal(
		_encode_result(player_zero),
		player_zero_oracle.encode(),
		"Player-zero damage must match the blocked oracle projection.",
	)
	context.expect_true(player_zero.is_blocked(), "Player-zero damage must be blocked.")
	context.expect_true(
		not player_zero.is_resolution_candidate(),
		"A player-zero projection must not be a submit candidate.",
	)
	context.expect_equal(
		player_zero.domain_events().size(),
		0,
		"A player-zero projection must emit no candidate event.",
	)
	var player_zero_resolution: ContactCombatResolutionScript = player_zero.resolution()
	context.expect_true(
		not player_zero_resolution.has_finite_player_attack_requirement(),
		"Player-zero damage must expose no finite attack requirement.",
	)
	context.expect_equal(
		player_zero_resolution.player_attacks_executed(),
		0,
		"Player-zero damage must execute no attacks.",
	)
	context.expect_true(
		not player_zero_resolution.temporary_effect_should_be_consumed(),
		"A blocked temporary projection must not request consumption.",
	)
	context.expect_true(
		player_zero_resolution.opponent_shield_intact_after(),
		"A blocked projection must preserve an intact shield.",
	)

	var opponent_zero: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		_opponent(10, 5, 6, 9),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)
	var opponent_zero_oracle := ContactCombatOracle.evaluate(
		20, 10, 5, 10,
		10, 5, 6, 9,
		ContactCombatOracle.SIDE_PLAYER,
		ContactCombatOracle.EFFECT_NONE,
		0,
		false,
	)
	context.expect_equal(
		_encode_result(opponent_zero),
		opponent_zero_oracle.encode(),
		"Opponent-zero damage must remain resolvable and match the oracle.",
	)
	context.expect_true(opponent_zero.was_evaluated(), "Opponent-zero damage must evaluate.")
	context.expect_equal(
		opponent_zero.resolution().opponent_attacks_executed(),
		2,
		"Zero-damage opponent turns must still be counted.",
	)
	context.expect_equal(
		opponent_zero.resolution().player_health_loss(),
		0,
		"Zero-damage opponent attacks must cause no loss.",
	)

	var both_zero: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		_opponent(10, 5, 10, 10),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.OPPONENT),
		registry,
	)
	context.expect_true(both_zero.is_blocked(), "Both-zero damage must use the player block.")
	context.expect_equal(
		both_zero.rejection_reason(),
		ContactCombatResultScript.RejectionReason.PLAYER_DAMAGE_ZERO,
		"Both-zero damage must expose the stable player-zero reason.",
	)
	context.expect_equal(
		both_zero.resolution().first_attacker_side(),
		ContactCombatCommandScript.Side.OPPONENT,
		"A blocked equal-speed preview must still expose the initiator as first.",
	)


func _applies_shield_once(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _state(20)
	var player_first: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		_opponent(10, 8, 6, 9, true),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)
	var player_first_resolution: ContactCombatResolutionScript = player_first.resolution()
	context.expect_equal(
		player_first_resolution.player_attacks_required_to_clear(),
		4,
		"A shield must add exactly one required player attack.",
	)
	context.expect_equal(
		player_first_resolution.player_attacks_executed(),
		4,
		"Player-first shield combat must execute four player attacks.",
	)
	context.expect_equal(
		player_first_resolution.opponent_attacks_executed(),
		3,
		"Player-first shield combat must execute three opponent attacks.",
	)
	context.expect_equal(
		player_first_resolution.next_player_health(),
		11,
		"Player-first shield combat must leave eleven health.",
	)
	context.expect_true(
		player_first_resolution.opponent_shield_absorbed_attack(),
		"The shield must absorb one effective player attack.",
	)
	context.expect_true(
		not player_first_resolution.opponent_shield_intact_after(),
		"The shield must be absent from the candidate opponent state.",
	)

	var opponent_first: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state,
		_opponent(10, 8, 6, 11, true),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)
	var opponent_first_resolution: ContactCombatResolutionScript = opponent_first.resolution()
	context.expect_equal(
		opponent_first_resolution.first_attacker_side(),
		ContactCombatCommandScript.Side.OPPONENT,
		"Higher opponent speed must take the first attack.",
	)
	context.expect_equal(
		opponent_first_resolution.player_attacks_executed(),
		4,
		"Opponent-first shield combat must execute four player attacks.",
	)
	context.expect_equal(
		opponent_first_resolution.opponent_attacks_executed(),
		4,
		"Opponent-first shield combat must execute four opponent attacks.",
	)
	context.expect_equal(
		opponent_first_resolution.next_player_health(),
		8,
		"Opponent-first shield combat must leave eight health.",
	)

	var killed_before_attack: ContactCombatResultScript = (
		ContactCombatKernelScript.evaluate(
			_state(2),
			_opponent(10, 8, 6, 11, true),
			ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
			registry,
		)
	)
	var killed_resolution: ContactCombatResolutionScript = killed_before_attack.resolution()
	context.expect_equal(
		killed_resolution.player_attacks_executed(),
		0,
		"A player killed by the opening hit must execute no attack.",
	)
	context.expect_equal(
		killed_resolution.opponent_attacks_executed(),
		1,
		"An opening lethal hit must count exactly once.",
	)
	context.expect_true(
		not killed_resolution.opponent_shield_absorbed_attack(),
		"A shield cannot absorb an attack that never happened.",
	)
	context.expect_true(
		killed_resolution.opponent_shield_intact_after(),
		"The shield must remain intact when the player never attacks.",
	)


func _projects_temporary_effects_and_support(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	for row: Array in ContactCombatOracle.effect_rows():
		var effect: int = row[0]
		var result: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
			_state(20),
			_opponent(12, 6, 10, 10),
			ContactCombatCommandScript.evaluate(
				ContactCombatCommandScript.Side.OPPONENT,
				effect,
			),
			registry,
		)
		var expected := ContactCombatOracle.evaluate(
			20, 10, 5, 10,
			12, 6, 10, 10,
			ContactCombatOracle.SIDE_OPPONENT,
			effect,
			0,
			false,
		)
		context.expect_equal(
			_encode_result(result),
			expected.encode(),
			"Temporary effect %d must match its independent projection." % effect,
		)

	var expected_opponent_damages: Array[int] = [0, 0, 1]
	for support_count: int in range(3):
		var supported: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
			_state(20),
			_opponent(8, 4, 6, 9),
			ContactCombatCommandScript.evaluate(
				ContactCombatCommandScript.Side.PLAYER,
				ContactCombatCommandScript.TemporaryEffect.NONE,
				support_count,
			),
			registry,
		)
		var resolution: ContactCombatResolutionScript = supported.resolution()
		context.expect_equal(
			resolution.support_attack_bonus(),
			support_count,
			"Each living supporter must add exactly one attack, capped by input validation.",
		)
		context.expect_equal(
			resolution.opponent_damage_per_attack(),
			expected_opponent_damages[support_count],
			"Support count %d must cross the defense threshold correctly." % support_count,
		)


func _rejects_invalid_input_matrices(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var valid_state: PlayerProgressionStateScript = _state(20)
	var valid_opponent: ContactCombatOpponentStateScript = _opponent(8, 8, 6, 9)
	var valid_command := ContactCombatCommandScript.evaluate(
		ContactCombatCommandScript.Side.PLAYER
	)

	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(null, valid_opponent, valid_command, registry),
		ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE,
		"Null player state",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(RefCounted.new(), valid_opponent, valid_command, registry),
		ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE,
		"Wrong player state type",
	)
	for invalid_state: PlayerProgressionStateScript in [
		PlayerProgressionStateScript.new(),
		PlayerProgressionStateScript.create(&"", 5, 5, 20, []),
		PlayerProgressionStateScript.create(PROFILE_ID, 5, 5, -1, []),
	]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				invalid_state, valid_opponent, valid_command, registry
			),
			ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE,
			"Locally invalid player state",
		)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(_state(0), valid_opponent, valid_command, registry),
		ContactCombatResultScript.RejectionReason.PLAYER_INCAPACITATED,
		"Incapacitated player",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			PlayerProgressionStateScript.create(PROFILE_ID, 4, 5, 20, []),
			valid_opponent,
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.CONTENT_SCHEMA_VERSION_MISMATCH,
		"Player schema mismatch",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			PlayerProgressionStateScript.create(PROFILE_ID, 5, 4, 20, []),
			valid_opponent,
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.CONTENT_VERSION_MISMATCH,
		"Player content mismatch",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			PlayerProgressionStateScript.create(&"progression.player.other", 5, 5, 20, []),
			valid_opponent,
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.PROFILE_ID_MISMATCH,
		"Player profile mismatch",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			PlayerProgressionStateScript.create(
				PROFILE_ID, 5, 5, 20, [&"progression.reward.unknown"]
			),
			valid_opponent,
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.UNKNOWN_CLAIMED_REWARD_ID,
		"Unknown claimed reward",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			PlayerProgressionStateScript.create(PROFILE_ID, 5, 5, 101, []),
			valid_opponent,
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.CURRENT_HEALTH_OUT_OF_RANGE,
		"Player health above derived maximum",
	)
	for invalid_registry: RefCounted in [null, RefCounted.new()]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				valid_state, valid_opponent, valid_command, invalid_registry
			),
			ContactCombatResultScript.RejectionReason.INVALID_REGISTRY,
			"Null or wrong registry",
		)

	for invalid_opponent: RefCounted in [
		null,
		RefCounted.new(),
		ContactCombatOpponentStateScript.new(),
		_opponent(1, 1, 1, 1, false, 0),
		ContactCombatOpponentStateScript.create(&"", 1, 1, 1, 1, 1),
		ContactCombatOpponentStateScript.create(OPPONENT_ID, 1, -1, 1, 1, 1),
		ContactCombatOpponentStateScript.create(OPPONENT_ID, 1, 2, 1, 1, 1),
		ContactCombatOpponentStateScript.create(OPPONENT_ID, 1, 1, 0, 1, 1),
		ContactCombatOpponentStateScript.create(OPPONENT_ID, 1, 1, 1, 0, 1),
		ContactCombatOpponentStateScript.create(OPPONENT_ID, 1, 1, 1, 1, 0),
	]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				valid_state, invalid_opponent, valid_command, registry
			),
			ContactCombatResultScript.RejectionReason.INVALID_OPPONENT_STATE,
			"Invalid opponent matrix",
		)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state,
			_opponent(0, 8, 6, 9, false, 8),
			valid_command,
			registry,
		),
		ContactCombatResultScript.RejectionReason.OPPONENT_INACTIVE,
		"Inactive opponent",
	)

	for invalid_command: RefCounted in [null, RefCounted.new()]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				valid_state, valid_opponent, invalid_command, registry
			),
			ContactCombatResultScript.RejectionReason.INVALID_COMMAND,
			"Null or wrong command",
		)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state,
			valid_opponent,
			ContactCombatCommandScript.new(999, 0, -1, -1),
			registry,
		),
		ContactCombatResultScript.RejectionReason.INVALID_COMMAND,
		"Invalid kind before all dependent command fields",
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state,
			valid_opponent,
			ContactCombatCommandScript.new(1, 0, -1, -1),
			registry,
		),
		ContactCombatResultScript.RejectionReason.INVALID_INITIATOR,
		"Invalid initiator before effect and support",
	)
	for invalid_effect: int in [-1, 6, 999]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				valid_state,
				valid_opponent,
				ContactCombatCommandScript.new(1, 1, invalid_effect, -1),
				registry,
			),
			ContactCombatResultScript.RejectionReason.INVALID_TEMPORARY_EFFECT,
			"Invalid temporary effect before support count",
		)
	for invalid_support: int in [-1, 3, 999]:
		_expect_rejected(
			context,
			ContactCombatKernelScript.evaluate(
				valid_state,
				valid_opponent,
				ContactCombatCommandScript.new(1, 1, 0, invalid_support),
				registry,
			),
			ContactCombatResultScript.RejectionReason.INVALID_SUPPORT_COUNT,
			"Invalid support count",
		)


func _rejects_derived_inputs_without_reads(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var valid_state: PlayerProgressionStateScript = _state(20)
	var valid_opponent: ContactCombatOpponentStateScript = _opponent(8, 8, 6, 9)
	var valid_command := ContactCombatCommandScript.evaluate(1)

	var derived_player := ContactCombatTestDoubles.StatefulPlayerState.new()
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			derived_player, valid_opponent, valid_command, registry
		),
		ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE,
		"Derived player state",
	)
	context.expect_equal(
		derived_player.read_count(),
		0,
		"A derived player state must be rejected before any overridable read.",
	)

	var derived_registry := ContactCombatTestDoubles.StatefulRegistry.new()
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state, valid_opponent, valid_command, derived_registry
		),
		ContactCombatResultScript.RejectionReason.INVALID_REGISTRY,
		"Derived registry",
	)
	context.expect_equal(
		derived_registry.read_count(),
		0,
		"A derived registry must be rejected before any overridable read.",
	)

	var derived_opponent := ContactCombatTestDoubles.StatefulOpponentState.new()
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state, derived_opponent, valid_command, registry
		),
		ContactCombatResultScript.RejectionReason.INVALID_OPPONENT_STATE,
		"Derived opponent state",
	)
	context.expect_equal(
		derived_opponent.read_count(),
		0,
		"A derived opponent must be rejected before any overridable read.",
	)

	var derived_command := ContactCombatTestDoubles.StatefulCommand.new()
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			valid_state, valid_opponent, derived_command, registry
		),
		ContactCombatResultScript.RejectionReason.INVALID_COMMAND,
		"Derived command",
	)
	context.expect_equal(
		derived_command.read_count(),
		0,
		"A derived command must be rejected before any overridable read.",
	)

	var unread_opponent := ContactCombatTestDoubles.StatefulOpponentState.new()
	var unread_command := ContactCombatTestDoubles.StatefulCommand.new()
	var unread_registry := ContactCombatTestDoubles.StatefulRegistry.new()
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			null, unread_opponent, unread_command, unread_registry
		),
		ContactCombatResultScript.RejectionReason.INVALID_PLAYER_STATE,
		"Invalid player priority",
	)
	context.expect_equal(
		unread_opponent.read_count() + unread_command.read_count() + unread_registry.read_count(),
		0,
		"Invalid player state must preempt every later polymorphic input read.",
	)


func _rejects_overflow_and_keeps_counts_compact(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	context.expect_true(
		not ContactCombatKernelScript._would_add_overflow(MAX_INT - 2, 2),
		(
			"The exact +2 overflow guard must allow MAX-2 + 2. Canonical v5 "
			+ "player stats cannot reach this boundary through the public kernel."
		),
	)
	context.expect_equal(
		MAX_INT - 2 + 2,
		MAX_INT,
		"The allowed +2 boundary must produce MAX exactly.",
	)
	context.expect_true(
		ContactCombatKernelScript._would_add_overflow(MAX_INT - 1, 2),
		(
			"The exact +2 overflow guard must reject MAX-1 + 2 even though "
			+ "canonical v5 player derivation cannot currently reach it."
		),
	)
	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			_state(20),
			_opponent(8, MAX_INT, 6, 9),
			ContactCombatCommandScript.evaluate(1, 0, 1),
			registry,
		),
		ContactCombatResultScript.RejectionReason.INTEGER_OVERFLOW,
		"Opponent attack plus support overflow",
	)

	var extreme: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(100),
		_opponent(MAX_INT, 1, 9, 9),
		ContactCombatCommandScript.evaluate(1),
		registry,
	)
	context.expect_true(extreme.was_evaluated(), "MAX durability with unit damage must evaluate.")
	var extreme_resolution: ContactCombatResolutionScript = extreme.resolution()
	context.expect_equal(
		extreme_resolution.player_attacks_required_to_clear(),
		MAX_INT,
		"Unit damage against MAX durability must require exactly MAX attacks.",
	)
	context.expect_equal(
		extreme_resolution.player_attacks_executed(),
		MAX_INT,
		"The compact result must retain the exact MAX player attack count.",
	)
	context.expect_equal(
		extreme_resolution.opponent_attacks_executed(),
		MAX_INT - 1,
		"Player-first compact resolution must retain MAX-1 opponent turns.",
	)
	context.expect_equal(
		extreme.domain_events().size(),
		1,
		"Extreme attack counts must still produce one compact event.",
	)

	_expect_rejected(
		context,
		ContactCombatKernelScript.evaluate(
			_state(100),
			_opponent(MAX_INT, 1, 9, 9, true),
			ContactCombatCommandScript.evaluate(1),
			registry,
		),
		ContactCombatResultScript.RejectionReason.INTEGER_OVERFLOW,
		"Shield would add one beyond MAX required attacks",
	)

	var equal_max_blocked := ContactCombatResolutionScript.new(
		PROFILE_ID,
		4,
		4,
		OPPONENT_ID,
		1,
		1,
		0,
		false,
		0,
		0,
		MAX_INT,
		MAX_INT,
		1,
		MAX_INT,
		MAX_INT,
		1,
		0,
		0,
		false,
		0,
		0,
		0,
		1,
		1,
		1,
		1,
		false,
		false,
		false,
		false,
		ContactCombatResolutionScript.Outcome.NONE,
		ContactCombatResolutionScript.BlockReason.PLAYER_DAMAGE_ZERO,
	)
	context.expect_true(
		equal_max_blocked.is_valid(),
		"Equal MAX attack and defense must produce zero damage without overflow.",
	)


func _isolates_inputs_and_outputs(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var player_state: PlayerProgressionStateScript = _state(20)
	var opponent_state: ContactCombatOpponentStateScript = _opponent(8, 8, 6, 9)
	var command := ContactCombatCommandScript.evaluate(1)
	var result: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		player_state, opponent_state, command, registry
	)
	context.expect_true(result.was_evaluated(), "The isolation fixture must evaluate.")

	player_state._current_health = 1
	opponent_state._current_durability = 1
	command._initiator_side = ContactCombatCommandScript.Side.OPPONENT
	context.expect_equal(
		result.previous_player_state().current_health(),
		20,
		"Mutating the source player state must not alter the result snapshot.",
	)
	context.expect_equal(
		result.previous_opponent_state().current_durability(),
		8,
		"Mutating the source opponent must not alter the result snapshot.",
	)
	context.expect_equal(
		result.command().initiator_side(),
		ContactCombatCommandScript.Side.PLAYER,
		"Mutating the source command must not alter the stored command.",
	)

	var first_command: ContactCombatCommandScript = result.command()
	first_command._initiator_side = ContactCombatCommandScript.Side.OPPONENT
	context.expect_equal(
		result.command().initiator_side(),
		ContactCombatCommandScript.Side.PLAYER,
		"Every command getter must return an isolated copy.",
	)
	var first_previous_player_state: PlayerProgressionStateScript = (
		result.previous_player_state()
	)
	first_previous_player_state._current_health = 0
	context.expect_equal(
		result.previous_player_state().current_health(),
		20,
		"Every previous-player getter must return an isolated copy.",
	)
	var first_candidate: ContactCombatPlayerStateCandidateScript = (
		result.player_state_candidate()
	)
	context.expect_true(
		first_candidate != null and first_candidate.is_valid(),
		"An evaluated result must expose a valid player-state candidate.",
	)
	first_candidate._current_health = 0
	var second_candidate: ContactCombatPlayerStateCandidateScript = (
		result.player_state_candidate()
	)
	context.expect_equal(
		second_candidate.current_health(),
		17,
		"Every player-state candidate getter must return an isolated copy.",
	)
	var returned_claim_ids: Array[StringName] = second_candidate.claimed_reward_ids()
	returned_claim_ids.append(&"progression.reward.forged")
	context.expect_equal(
		result.player_state_candidate().claimed_reward_ids(),
		[],
		"Candidate claimed-reward getters must defensively copy their array.",
	)
	var candidate_derivation: PlayerProgressionDerivationResultScript = (
		PermanentGrowthClaimKernelScript.derive_snapshot(second_candidate, registry)
	)
	context.expect_true(
		not candidate_derivation.succeeded(),
		"A combat candidate must not cross into permanent-growth derivation.",
	)
	context.expect_equal(
		candidate_derivation.failure_reason(),
		PlayerProgressionDerivationResultScript.FailureReason.INVALID_STATE,
		"Permanent growth must exact-script reject the non-authoritative candidate.",
	)
	var candidate_claim: PermanentGrowthClaimResultScript = (
		PermanentGrowthClaimKernelScript.execute(
			second_candidate,
			PermanentGrowthClaimCommandScript.claim(ATTACK_REWARD_IDS[0]),
			registry,
		)
	)
	context.expect_true(
		candidate_claim.is_rejected(),
		"An uncommitted combat candidate must not become a growth commit boundary.",
	)
	context.expect_equal(
		candidate_claim.rejection_reason(),
		PermanentGrowthClaimResultScript.RejectionReason.INVALID_STATE,
		"The growth transaction must exact-script reject a combat candidate.",
	)
	context.expect_true(
		not candidate_claim.is_commit_boundary(),
		"A rejected candidate claim must never expose a commit boundary.",
	)
	var first_previous_snapshot: PlayerProgressionSnapshotScript = (
		result.previous_player_progression_snapshot()
	)
	first_previous_snapshot._current_health = 0
	context.expect_equal(
		result.previous_player_progression_snapshot().current_health(),
		20,
		"Every previous-snapshot getter must return an isolated copy.",
	)
	var first_snapshot: PlayerProgressionSnapshotScript = (
		result.player_progression_snapshot()
	)
	first_snapshot._current_health = 0
	context.expect_equal(
		result.player_progression_snapshot().current_health(),
		17,
		"Every next-snapshot getter must return an isolated copy.",
	)
	var first_previous_opponent: ContactCombatOpponentStateScript = (
		result.previous_opponent_state()
	)
	first_previous_opponent._current_durability = 1
	context.expect_equal(
		result.previous_opponent_state().current_durability(),
		8,
		"Every previous-opponent getter must return an isolated copy.",
	)
	var first_opponent: ContactCombatOpponentStateScript = result.opponent_state()
	first_opponent._current_durability = 7
	context.expect_equal(
		result.opponent_state().current_durability(),
		0,
		"Every opponent getter must return an isolated copy.",
	)
	var first_resolution: ContactCombatResolutionScript = result.resolution()
	first_resolution._next_player_health = 0
	context.expect_true(
		result.resolution().next_player_health() > 0,
		"Every resolution getter must return an isolated copy.",
	)
	var first_events: Array[ContactCombatEventScript] = result.domain_events()
	first_events[0]._kind = 999
	first_events.append(
		ContactCombatEventScript.contact_resolution_candidate(result.resolution())
	)
	var second_events: Array[ContactCombatEventScript] = result.domain_events()
	context.expect_equal(
		second_events.size(),
		1,
		"Mutating a returned event array must not alter stored cardinality.",
	)
	context.expect_true(
		second_events[0].is_valid(),
		"Mutating a returned event must not alter the stored event.",
	)
	var first_event_resolution: ContactCombatResolutionScript = (
		second_events[0].resolution()
	)
	first_event_resolution._next_player_health = 0
	context.expect_equal(
		second_events[0].resolution().next_player_health(),
		17,
		"Every event-resolution getter must return an isolated copy.",
	)
	var copied_event: ContactCombatEventScript = second_events[0].copy()
	copied_event._kind = 999
	context.expect_true(
		second_events[0].is_valid(),
		"Mutating an event copy must not alter the original returned event.",
	)
	context.expect_true(
		result.previous_player_state() != result.previous_player_state(),
		"Repeated previous-player getters must return distinct instances.",
	)
	context.expect_true(
		result.player_state_candidate() != result.player_state_candidate(),
		"Repeated candidate getters must return distinct instances.",
	)
	context.expect_true(
		result.previous_opponent_state() != result.opponent_state(),
		"Previous and next opponent getters must return distinct instances.",
	)


func _rejects_malformed_public_results(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var base: ContactCombatResultScript = _valid_candidate(registry)
	context.expect_true(base.was_evaluated(), "The malformed-result base must evaluate.")
	var base_resolution: ContactCombatResolutionScript = base.resolution()
	var base_events: Array[ContactCombatEventScript] = base.domain_events()
	var no_events: Array[ContactCombatEventScript] = []
	var two_events: Array[ContactCombatEventScript] = [
		base_events[0],
		base_events[0].copy(),
	]

	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base_resolution,
			no_events,
		),
		"Evaluated result without its one candidate event",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base_resolution,
			two_events,
		),
		"Evaluated result with two candidate events",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.PLAYER_DAMAGE_ZERO,
			base_resolution,
			base_events,
		),
		"Evaluated result with a rejection reason",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.BLOCKED,
			ContactCombatResultScript.RejectionReason.PLAYER_DAMAGE_ZERO,
			base_resolution,
			no_events,
		),
		"Blocked status with a submit-capable resolution",
	)
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.REJECTED,
			ContactCombatResultScript.RejectionReason.NONE,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			no_events,
		),
		"Rejected result without a reason",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			999,
			ContactCombatResultScript.RejectionReason.NONE,
			base_resolution,
			base_events,
		),
		"Unknown public result status",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			null,
			base_events,
		),
		"Evaluated result without a resolution",
	)

	var derived_resolution: ContactCombatResolutionScript = (
		ContactCombatTestDoubles.DerivedResolution.new()
	)
	context.expect_true(
		derived_resolution.is_valid(),
		"The derived resolution fixture must otherwise be valid.",
	)
	context.expect_true(
		derived_resolution.get_script() != ContactCombatResolutionScript,
		"The derived resolution fixture must remain non-exact.",
	)
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			derived_resolution,
			base_events,
		),
		"Evaluated result with a derived resolution",
	)

	var derived_event: ContactCombatEventScript = (
		ContactCombatTestDoubles.DerivedEvent.new()
	)
	context.expect_true(
		derived_event.is_valid(),
		"The derived event fixture must otherwise be valid.",
	)
	context.expect_true(
		derived_event.get_script() != ContactCombatEventScript,
		"The derived event fixture must remain non-exact.",
	)
	var derived_events: Array[ContactCombatEventScript] = [derived_event]
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base_resolution,
			derived_events,
		),
		"Evaluated result with a derived candidate event",
	)

	var mismatched_next_state: PlayerProgressionStateScript = (
		_authoritative_state_from_candidate(base.player_state_candidate())
	)
	mismatched_next_state._current_health += 1
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base.command(),
			base.previous_player_state(),
			mismatched_next_state,
			base.previous_player_progression_snapshot(),
			base.player_progression_snapshot(),
			base.previous_opponent_state(),
			base.opponent_state(),
			base_resolution,
			base_events,
			registry,
		),
		"Next player state that disagrees with its snapshot",
	)

	var derived_snapshot: PlayerProgressionSnapshotScript = (
		ContactCombatTestDoubles.DerivedPlayerSnapshot.new()
	)
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base.command(),
			base.previous_player_state(),
			_authoritative_state_from_candidate(base.player_state_candidate()),
			derived_snapshot,
			base.player_progression_snapshot(),
			base.previous_opponent_state(),
			base.opponent_state(),
			base_resolution,
			base_events,
			registry,
		),
		"Evaluated result with a derived previous snapshot",
	)
	context.expect_equal(
		derived_snapshot.read_count(),
		0,
		"A derived previous snapshot must be rejected before overridable reads.",
	)
	_expect_derived_public_result_parts_rejected(context, base, registry)

	var alternate: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 9),
		ContactCombatCommandScript.evaluate(1, 1),
		registry,
	)
	var mismatched_event: Array[ContactCombatEventScript] = alternate.domain_events()
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			base_resolution,
			mismatched_event,
		),
		"Candidate event whose resolution differs from the result",
	)

	var forged_resolution := ContactCombatResolutionScript.new(
		PROFILE_ID,
		4,
		4,
		OPPONENT_ID,
		1,
		1,
		0,
		false,
		0,
		0,
		11,
		5,
		10,
		8,
		6,
		9,
		5,
		3,
		true,
		2,
		2,
		1,
		20,
		17,
		8,
		0,
		false,
		false,
		false,
		true,
		ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
		ContactCombatResolutionScript.BlockReason.NONE,
	)
	context.expect_true(
		forged_resolution.is_valid(),
		"The forged resolution must be internally self-consistent.",
	)
	var forged_event := ContactCombatEventScript.contact_resolution_candidate(
		forged_resolution
	)
	var forged_events: Array[ContactCombatEventScript] = [forged_event]
	_expect_invalid_public_result(
		context,
		_public_result_from_base(
			base,
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			forged_resolution,
			forged_events,
		),
		"Internally coherent scalar result not derived from the previous attack",
	)

	var forged_previous_state: PlayerProgressionStateScript = _state(20)
	var forged_next_state: PlayerProgressionStateScript = _state(18)
	var forged_previous_snapshot := PlayerProgressionSnapshotScript.create(
		PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		20,
		101,
		11,
		6,
		11,
		[],
	)
	var forged_next_snapshot := PlayerProgressionSnapshotScript.create(
		PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		18,
		101,
		11,
		6,
		11,
		[],
	)
	var forged_previous_opponent := _opponent(8, 8, 6, 9)
	var forged_next_opponent := _opponent(0, 8, 6, 9, false, 8)
	var coherent_forged_resolution := ContactCombatResolutionScript.new(
		PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		OPPONENT_ID,
		ContactCombatCommandScript.Side.PLAYER,
		ContactCombatCommandScript.Side.PLAYER,
		ContactCombatCommandScript.TemporaryEffect.NONE,
		false,
		0,
		0,
		11,
		6,
		11,
		8,
		6,
		9,
		5,
		2,
		true,
		2,
		2,
		1,
		20,
		18,
		8,
		0,
		false,
		false,
		false,
		true,
		ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
		ContactCombatResolutionScript.BlockReason.NONE,
	)
	context.expect_true(
		forged_previous_snapshot.is_valid()
		and forged_next_snapshot.is_valid()
		and coherent_forged_resolution.is_valid(),
		"The all-four-stat forgery must be internally self-consistent.",
	)
	var coherent_forged_event := (
		ContactCombatEventScript.contact_resolution_candidate(
			coherent_forged_resolution
		)
	)
	context.expect_true(
		coherent_forged_event.is_valid(),
		"The all-four-stat forged event must be internally self-consistent.",
	)
	var coherent_forged_events: Array[ContactCombatEventScript] = [
		coherent_forged_event,
	]
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			ContactCombatCommandScript.evaluate(
				ContactCombatCommandScript.Side.PLAYER
			),
			forged_previous_state,
			forged_next_state,
			forged_previous_snapshot,
			forged_next_snapshot,
			forged_previous_opponent,
			forged_next_opponent,
			coherent_forged_resolution,
			coherent_forged_events,
			registry,
		),
		(
			"A structurally coherent forged max-health/attack/defense/speed "
			+ "projection that disagrees with canonical registry derivation"
		),
	)

	var overflow_snapshot := PlayerProgressionSnapshotScript.create(
		PROFILE_ID,
		4,
		4,
		20,
		100,
		MAX_INT - 1,
		5,
		10,
		[],
	)
	var overflow_next_snapshot := PlayerProgressionSnapshotScript.create(
		PROFILE_ID,
		4,
		4,
		17,
		100,
		MAX_INT - 1,
		5,
		10,
		[],
	)
	var attack_effect_command := ContactCombatCommandScript.evaluate(1, 1)
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			attack_effect_command,
			_state(20),
			_state(17),
			overflow_snapshot,
			overflow_next_snapshot,
			base.previous_opponent_state(),
			base.opponent_state(),
			base_resolution,
			base_events,
			registry,
		),
		"Previous player attack plus temporary bonus would overflow",
	)


func _replays_deterministically(context: HeadlessTestContextScript) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var first_trace: Array = _replay_trace(context, registry, "First replay")
	var second_trace: Array = _replay_trace(context, registry, "Second replay")
	context.expect_equal(
		first_trace,
		second_trace,
		"Repeating the same candidate sequence must reproduce the complete trace.",
	)
	context.expect_equal(
		first_trace,
		[
			[1, true, 1, 96, 0, 3, 2, 1, 1, 0, 0, false],
			[1, true, 1, 88, 0, 3, 2, 1, 1, 3, 1, false],
			[1, true, 1, 86, 0, 3, 2, 1, 1, 5, 2, false],
		],
		"The three-step replay trace and final health must remain literally frozen.",
	)

	var first: ContactCombatResultScript = _valid_candidate(registry)
	var second: ContactCombatResultScript = _valid_candidate(registry)
	context.expect_equal(
		_encode_public_result(first),
		_encode_public_result(second),
		"Repeated evaluation must reproduce the complete public candidate surface.",
	)
	context.expect_true(first != second, "Repeated evaluation must return a new result.")
	context.expect_true(
		first.resolution() != second.resolution(),
		"Repeated evaluation must return distinct resolution snapshots.",
	)
	context.expect_true(
		first.player_state_candidate() != second.player_state_candidate(),
		"Repeated evaluation must return distinct player-state candidates.",
	)
	context.expect_true(
		first.opponent_state() != second.opponent_state(),
		"Repeated evaluation must return distinct opponent snapshots.",
	)
	context.expect_true(
		first.domain_events()[0] != second.domain_events()[0],
		"Repeated evaluation must return distinct event snapshots.",
	)


func _satisfies_metamorphic_invariants(
	context: HeadlessTestContextScript,
) -> void:
	var registry: ContentRegistryScript = _canonical_registry(context)
	var attack_base := _evaluate_fixture(registry, 20, 0, 0, 0, 8, 8, 6, 9)
	var attack_shifted := _evaluate_fixture(registry, 20, 1, 0, 0, 8, 8, 7, 9)
	context.expect_equal(
		_resolution_outcome_signature(attack_base.resolution()),
		_resolution_outcome_signature(attack_shifted.resolution()),
		"Adding one to player attack and opponent defense must preserve the combat result.",
	)

	var defense_base := _evaluate_fixture(registry, 20, 0, 0, 0, 8, 8, 6, 9)
	var defense_shifted := _evaluate_fixture(registry, 20, 0, 1, 0, 8, 9, 6, 9)
	context.expect_equal(
		defense_base.resolution().opponent_damage_per_attack(),
		defense_shifted.resolution().opponent_damage_per_attack(),
		"Adding one to opponent attack and player defense must preserve opponent damage.",
	)
	context.expect_equal(
		defense_base.resolution().player_health_loss(),
		defense_shifted.resolution().player_health_loss(),
		"The paired defense translation must preserve player loss.",
	)

	var speed_base := _evaluate_fixture(registry, 20, 0, 0, 0, 8, 8, 6, 9)
	var speed_shifted := _evaluate_fixture(registry, 20, 0, 0, 1, 8, 8, 6, 10)
	context.expect_equal(
		speed_base.resolution().first_attacker_side(),
		speed_shifted.resolution().first_attacker_side(),
		"Adding one to both speeds must preserve the first attacker.",
	)

	var stronger_attack := _evaluate_fixture(registry, 20, 2, 0, 0, 8, 8, 6, 9)
	context.expect_true(
		stronger_attack.resolution().player_attacks_required_to_clear()
		<= attack_base.resolution().player_attacks_required_to_clear(),
		"Increasing player attack must not increase the required attack count.",
	)
	context.expect_true(
		stronger_attack.resolution().player_health_loss()
		<= attack_base.resolution().player_health_loss(),
		"Increasing player attack must not increase player loss.",
	)
	var stronger_defense := _evaluate_fixture(registry, 20, 0, 2, 0, 8, 8, 6, 9)
	context.expect_true(
		stronger_defense.resolution().opponent_damage_per_attack()
		<= defense_base.resolution().opponent_damage_per_attack(),
		"Increasing player defense must not increase opponent damage.",
	)
	context.expect_true(
		stronger_defense.resolution().player_health_loss()
		<= defense_base.resolution().player_health_loss(),
		"Increasing player defense must not increase player loss.",
	)

	var player_initiates: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 10),
		ContactCombatCommandScript.evaluate(1),
		registry,
	)
	var opponent_initiates: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 10),
		ContactCombatCommandScript.evaluate(2),
		registry,
	)
	context.expect_equal(
		player_initiates.resolution().first_attacker_side(),
		1,
		"Equal speed must choose the player initiator.",
	)
	context.expect_equal(
		opponent_initiates.resolution().first_attacker_side(),
		2,
		"Equal speed must choose the opponent initiator.",
	)
	context.expect_equal(
		opponent_initiates.resolution().opponent_attacks_executed(),
		player_initiates.resolution().opponent_attacks_executed() + 1,
		"Flipping equal-speed initiative must add exactly one opponent opportunity.",
	)

	var without_shield := _evaluate_fixture(registry, 20, 0, 0, 0, 8, 8, 6, 9)
	var with_shield: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 9, true),
		ContactCombatCommandScript.evaluate(1),
		registry,
	)
	context.expect_equal(
		with_shield.resolution().player_attacks_executed(),
		without_shield.resolution().player_attacks_executed() + 1,
		"A shield in a survivor fixture must add exactly one player attack.",
	)
	context.expect_equal(
		with_shield.resolution().opponent_attacks_executed(),
		without_shield.resolution().opponent_attacks_executed() + 1,
		"A shield in a survivor fixture must add exactly one opponent opportunity.",
	)

	var effect_projection: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 9),
		ContactCombatCommandScript.evaluate(1, 1),
		registry,
	)
	var permanent_projection := _evaluate_fixture(
		registry, 20, 2, 0, 0, 8, 8, 6, 9
	)
	context.expect_equal(
		_resolution_formula_signature(effect_projection.resolution()),
		_resolution_formula_signature(permanent_projection.resolution()),
		"Attack projection must equal the same already-derived effective attack.",
	)

	var supported: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 6, 6, 9),
		ContactCombatCommandScript.evaluate(1, 0, 2),
		registry,
	)
	var manually_raised: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 9),
		ContactCombatCommandScript.evaluate(1, 0, 0),
		registry,
	)
	context.expect_equal(
		_resolution_formula_signature(supported.resolution()),
		_resolution_formula_signature(manually_raised.resolution()),
		"Two supporters must equal a literal two-point opponent attack increase.",
	)


func _canonical_registry(context: HeadlessTestContextScript) -> ContentRegistryScript:
	if _cached_registry != null:
		return _cached_registry
	var build_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(
		build_result.succeeded(),
		"The contact-combat canonical registry fixture must build.",
	)
	_cached_registry = build_result.registry()
	context.expect_true(
		_cached_registry != null and _cached_registry.is_initialized(),
		"The contact-combat registry fixture must be initialized and sealed.",
	)
	return _cached_registry


func _state(
	current_health: int,
	claimed_reward_ids: Array[StringName] = [],
) -> PlayerProgressionStateScript:
	return PlayerProgressionStateScript.create(
		PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		current_health,
		claimed_reward_ids,
	)


func _authoritative_state_from_candidate(
	candidate: ContactCombatPlayerStateCandidateScript,
) -> PlayerProgressionStateScript:
	return PlayerProgressionStateScript.create(
		candidate.profile_id(),
		candidate.content_schema_version(),
		candidate.content_version(),
		candidate.current_health(),
		candidate.claimed_reward_ids(),
	)


func _state_for_bonuses(
	current_health: int,
	attack_bonus: int,
	defense_bonus: int,
	speed_bonus: int,
) -> PlayerProgressionStateScript:
	var reward_ids: Array[StringName] = []
	for index: int in range(attack_bonus):
		reward_ids.append(ATTACK_REWARD_IDS[index])
	for index: int in range(defense_bonus):
		reward_ids.append(DEFENSE_REWARD_IDS[index])
	for index: int in range(speed_bonus):
		reward_ids.append(SPEED_REWARD_IDS[index])
	return _state(current_health, reward_ids)


func _opponent(
	current_durability: int,
	attack: int,
	defense: int,
	speed: int,
	shield_intact: bool = false,
	maximum_durability: int = -1,
) -> ContactCombatOpponentStateScript:
	var maximum: int = maximum_durability
	if maximum_durability < 0:
		maximum = max(current_durability, 1)
	return ContactCombatOpponentStateScript.create(
		OPPONENT_ID,
		maximum,
		current_durability,
		attack,
		defense,
		speed,
		shield_intact,
	)


func _encode_result(result: ContactCombatResultScript) -> Array:
	var status: int = result.status()
	var rejection_reason: int = result.rejection_reason()
	var resolution: ContactCombatResolutionScript = result.resolution()
	if resolution == null:
		return [status, rejection_reason]
	return [
		status,
		rejection_reason,
		resolution.initiator_side(),
		resolution.first_attacker_side(),
		resolution.temporary_effect(),
		resolution.temporary_effect_should_be_consumed(),
		resolution.supporting_opponents_alive(),
		resolution.support_attack_bonus(),
		resolution.effective_player_attack(),
		resolution.effective_player_defense(),
		resolution.effective_player_speed(),
		resolution.effective_opponent_attack(),
		resolution.effective_opponent_defense(),
		resolution.effective_opponent_speed(),
		resolution.player_damage_per_attack(),
		resolution.opponent_damage_per_attack(),
		resolution.has_finite_player_attack_requirement(),
		resolution.player_attacks_required_to_clear(),
		resolution.player_attacks_executed(),
		resolution.opponent_attacks_executed(),
		resolution.previous_player_health(),
		resolution.next_player_health(),
		resolution.previous_opponent_durability(),
		resolution.next_opponent_durability(),
		resolution.opponent_shield_intact_before(),
		resolution.opponent_shield_absorbed_attack(),
		resolution.opponent_shield_intact_after(),
		resolution.is_resolution_candidate(),
		resolution.outcome(),
		resolution.block_reason(),
		result.domain_events().size(),
	]


func _encode_public_result(result: ContactCombatResultScript) -> Array:
	var candidate: ContactCombatPlayerStateCandidateScript = (
		result.player_state_candidate()
	)
	var candidate_encoding: Array = []
	if candidate != null:
		candidate_encoding = [
			candidate.profile_id(),
			candidate.content_schema_version(),
			candidate.content_version(),
			candidate.current_health(),
			candidate.claimed_reward_ids(),
		]
	var events: Array[ContactCombatEventScript] = result.domain_events()
	var event_encoding: Array = []
	if events.size() == 1:
		var event_resolution: ContactCombatResolutionScript = events[0].resolution()
		event_encoding = [
			events[0].kind(),
			events[0].is_resolution_candidate(),
			events[0].is_commit_boundary(),
			event_resolution.next_player_health(),
			event_resolution.next_opponent_durability(),
			event_resolution.outcome(),
		]
	return [
		_encode_result(result),
		result.is_resolution_candidate(),
		result.is_commit_boundary(),
		candidate_encoding,
		event_encoding,
	]


func _resolution_from_oracle(
	projection: ContactCombatOracle.CombatProjection,
) -> ContactCombatResolutionScript:
	return ContactCombatResolutionScript.new(
		PROFILE_ID,
		CONTENT_SCHEMA_VERSION,
		CONTENT_VERSION,
		OPPONENT_ID,
		projection.initiator_side,
		projection.first_attacker_side,
		projection.temporary_effect,
		projection.temporary_effect_should_be_consumed,
		projection.supporting_opponents_alive,
		projection.support_attack_bonus,
		projection.effective_player_attack,
		projection.effective_player_defense,
		projection.effective_player_speed,
		projection.effective_opponent_attack,
		projection.effective_opponent_defense,
		projection.effective_opponent_speed,
		projection.player_damage_per_attack,
		projection.opponent_damage_per_attack,
		projection.has_finite_player_attack_requirement,
		projection.player_attacks_required_to_clear,
		projection.player_attacks_executed,
		projection.opponent_attacks_executed,
		projection.previous_player_health,
		projection.next_player_health,
		projection.previous_opponent_durability,
		projection.next_opponent_durability,
		projection.opponent_shield_intact_before,
		projection.opponent_shield_absorbed_attack,
		projection.opponent_shield_intact_after,
		projection.is_resolution_candidate,
		projection.outcome,
		projection.block_reason,
	)


func _expect_rejected(
	context: HeadlessTestContextScript,
	result: ContactCombatResultScript,
	expected_reason: int,
	label: String,
) -> void:
	context.expect_equal(
		result.status(),
		ContactCombatResultScript.Status.REJECTED,
		"%s must be rejected." % label,
	)
	context.expect_equal(
		result.rejection_reason(),
		expected_reason,
		"%s must expose the expected rejection reason." % label,
	)
	context.expect_true(result.is_rejected(), "%s must report is_rejected." % label)
	context.expect_true(
		not result.is_resolution_candidate(),
		"%s must not be a resolution candidate." % label,
	)
	context.expect_true(result.resolution() == null, "%s must expose no resolution." % label)
	context.expect_equal(
		result.domain_events().size(),
		0,
		"%s must expose no candidate events." % label,
	)


func _valid_candidate(
	registry: ContentRegistryScript,
) -> ContactCombatResultScript:
	return ContactCombatKernelScript.evaluate(
		_state(20),
		_opponent(8, 8, 6, 9),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)


func _public_result_from_base(
	base: ContactCombatResultScript,
	status: int,
	rejection_reason: int,
	resolution: ContactCombatResolutionScript,
	events: Array[ContactCombatEventScript],
) -> ContactCombatResultScript:
	return ContactCombatResultScript.new(
		status,
		rejection_reason,
		base.command(),
		base.previous_player_state(),
		_authoritative_state_from_candidate(base.player_state_candidate()),
		base.previous_player_progression_snapshot(),
		base.player_progression_snapshot(),
		base.previous_opponent_state(),
		base.opponent_state(),
		resolution,
		events,
		_cached_registry,
	)


func _expect_derived_public_result_parts_rejected(
	context: HeadlessTestContextScript,
	base: ContactCombatResultScript,
	registry: ContentRegistryScript,
) -> void:
	var exact_command: ContactCombatCommandScript = base.command()
	var exact_previous_state: PlayerProgressionStateScript = (
		base.previous_player_state()
	)
	var exact_next_state: PlayerProgressionStateScript = (
		_authoritative_state_from_candidate(base.player_state_candidate())
	)
	var exact_previous_snapshot: PlayerProgressionSnapshotScript = (
		base.previous_player_progression_snapshot()
	)
	var exact_next_snapshot: PlayerProgressionSnapshotScript = (
		base.player_progression_snapshot()
	)
	var exact_previous_opponent: ContactCombatOpponentStateScript = (
		base.previous_opponent_state()
	)
	var exact_next_opponent: ContactCombatOpponentStateScript = (
		base.opponent_state()
	)
	var exact_resolution: ContactCombatResolutionScript = base.resolution()
	var exact_events: Array[ContactCombatEventScript] = base.domain_events()

	var derived_command := ContactCombatTestDoubles.StatefulCommand.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			derived_command,
			exact_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			exact_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived command",
	)
	context.expect_equal(
		derived_command.read_count(),
		0,
		"A derived result command must be rejected before overridable reads.",
	)

	var derived_previous_state := ContactCombatTestDoubles.StatefulPlayerState.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			derived_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			exact_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived previous player state",
	)
	context.expect_equal(
		derived_previous_state.read_count(),
		0,
		"A derived previous state must be rejected before overridable reads.",
	)

	var derived_next_state := ContactCombatTestDoubles.StatefulPlayerState.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			exact_previous_state,
			derived_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			exact_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived next player state",
	)
	context.expect_equal(
		derived_next_state.read_count(),
		0,
		"A derived next state must be rejected before overridable reads.",
	)

	var derived_next_snapshot := ContactCombatTestDoubles.DerivedPlayerSnapshot.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			exact_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			derived_next_snapshot,
			exact_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived next snapshot",
	)
	context.expect_equal(
		derived_next_snapshot.read_count(),
		0,
		"A derived next snapshot must be rejected before overridable reads.",
	)

	var derived_previous_opponent := (
		ContactCombatTestDoubles.StatefulOpponentState.new()
	)
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			exact_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			derived_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived previous opponent",
	)
	context.expect_equal(
		derived_previous_opponent.read_count(),
		0,
		"A derived previous opponent must be rejected before overridable reads.",
	)

	var derived_next_opponent := ContactCombatTestDoubles.StatefulOpponentState.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			exact_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			exact_previous_opponent,
			derived_next_opponent,
			exact_resolution,
			exact_events,
			registry,
		),
		"Evaluated result with a derived next opponent",
	)
	context.expect_equal(
		derived_next_opponent.read_count(),
		0,
		"A derived next opponent must be rejected before overridable reads.",
	)

	var derived_registry := ContactCombatTestDoubles.StatefulRegistry.new()
	_expect_invalid_public_result(
		context,
		ContactCombatResultScript.new(
			ContactCombatResultScript.Status.EVALUATED,
			ContactCombatResultScript.RejectionReason.NONE,
			exact_command,
			exact_previous_state,
			exact_next_state,
			exact_previous_snapshot,
			exact_next_snapshot,
			exact_previous_opponent,
			exact_next_opponent,
			exact_resolution,
			exact_events,
			derived_registry,
		),
		"Evaluated result with a derived registry",
	)
	context.expect_equal(
		derived_registry.read_count(),
		0,
		"A derived result registry must be rejected before overridable reads.",
	)


func _expect_invalid_public_result(
	context: HeadlessTestContextScript,
	result: ContactCombatResultScript,
	label: String,
) -> void:
	context.expect_equal(
		result.status(),
		ContactCombatResultScript.Status.REJECTED,
		"%s must fail closed to REJECTED." % label,
	)
	context.expect_equal(
		result.rejection_reason(),
		ContactCombatResultScript.RejectionReason.INVALID_RESULT,
		"%s must fail closed with INVALID_RESULT." % label,
	)
	context.expect_true(
		not result.is_resolution_candidate(),
		"%s must not be a resolution candidate." % label,
	)
	context.expect_true(result.command() == null, "%s must expose no partial command." % label)
	context.expect_true(
		result.previous_player_state() == null,
		"%s must expose no partial previous player state." % label,
	)
	context.expect_true(
		result.player_state_candidate() == null,
		"%s must expose no partial player-state candidate." % label,
	)
	context.expect_true(
		result.previous_player_progression_snapshot() == null,
		"%s must expose no partial previous snapshot." % label,
	)
	context.expect_true(
		result.player_progression_snapshot() == null,
		"%s must expose no partial next snapshot." % label,
	)
	context.expect_true(
		result.previous_opponent_state() == null,
		"%s must expose no partial previous opponent." % label,
	)
	context.expect_true(
		result.opponent_state() == null,
		"%s must expose no partial next opponent." % label,
	)
	context.expect_true(result.resolution() == null, "%s must expose no resolution." % label)
	context.expect_equal(
		result.domain_events().size(),
		0,
		"%s must expose no partial candidate event." % label,
	)


func _replay_trace(
	context: HeadlessTestContextScript,
	registry: ContentRegistryScript,
	label: String,
) -> Array:
	var player_state: PlayerProgressionStateScript = _state(100)
	var trace: Array = []
	var contacts: Array[Array] = [
		[18, 7, 2, 8, false, 1, 0, 0],
		[10, 8, 6, 11, false, 1, 3, 1],
		[8, 6, 6, 9, true, 2, 5, 2],
	]
	for index: int in range(contacts.size()):
		var row: Array = contacts[index]
		var result: ContactCombatResultScript = ContactCombatKernelScript.evaluate(
			player_state,
			_opponent(row[0], row[1], row[2], row[3], row[4]),
			ContactCombatCommandScript.evaluate(row[5], row[6], row[7]),
			registry,
		)
		var step_label := "%s step %d" % [label, index + 1]
		context.expect_equal(
			result.status(),
			ContactCombatResultScript.Status.EVALUATED,
			"%s must evaluate." % step_label,
		)
		context.expect_true(
			result.was_evaluated(),
			"%s must report was_evaluated." % step_label,
		)
		context.expect_true(
			result.is_resolution_candidate(),
			"%s must expose a resolution candidate." % step_label,
		)
		context.expect_true(
			not result.is_commit_boundary(),
			"%s must not claim to be a commit boundary." % step_label,
		)
		var events: Array[ContactCombatEventScript] = result.domain_events()
		context.expect_equal(
			events.size(),
			1,
			"%s must contain exactly one compact candidate event." % step_label,
		)
		var resolution: ContactCombatResolutionScript = result.resolution()
		context.expect_true(
			resolution != null and resolution.is_resolution_candidate(),
			"%s must expose a candidate resolution." % step_label,
		)
		if resolution == null or events.size() != 1:
			trace.append([result.status(), false, events.size()])
			continue
		var event: ContactCombatEventScript = events[0]
		context.expect_true(
			event.is_resolution_candidate(),
			"%s event must be a resolution candidate." % step_label,
		)
		context.expect_true(
			not event.is_commit_boundary(),
			"%s event must not claim to be a commit boundary." % step_label,
		)
		context.expect_true(
			event.resolution().is_equal_to(resolution),
			"%s event must freeze the same resolution." % step_label,
		)
		trace.append(
			[
				result.status(),
				result.is_resolution_candidate(),
				events.size(),
				resolution.next_player_health(),
				resolution.next_opponent_durability(),
				resolution.player_attacks_executed(),
				resolution.opponent_attacks_executed(),
				resolution.first_attacker_side(),
				resolution.outcome(),
				resolution.temporary_effect(),
				resolution.supporting_opponents_alive(),
				resolution.opponent_shield_intact_after(),
			]
		)
		player_state = _authoritative_state_from_candidate(
			result.player_state_candidate()
		)
	context.expect_equal(
		player_state.current_health(),
		86,
		"%s must finish at the frozen final player health." % label,
	)
	return trace


func _evaluate_fixture(
	registry: ContentRegistryScript,
	player_health: int,
	player_attack_bonus: int,
	player_defense_bonus: int,
	player_speed_bonus: int,
	opponent_durability: int,
	opponent_attack: int,
	opponent_defense: int,
	opponent_speed: int,
) -> ContactCombatResultScript:
	return ContactCombatKernelScript.evaluate(
		_state_for_bonuses(
			player_health,
			player_attack_bonus,
			player_defense_bonus,
			player_speed_bonus,
		),
		_opponent(
			opponent_durability,
			opponent_attack,
			opponent_defense,
			opponent_speed,
		),
		ContactCombatCommandScript.evaluate(ContactCombatCommandScript.Side.PLAYER),
		registry,
	)


func _resolution_outcome_signature(
	resolution: ContactCombatResolutionScript,
) -> Array:
	return [
		resolution.player_damage_per_attack(),
		resolution.opponent_damage_per_attack(),
		resolution.first_attacker_side(),
		resolution.player_attacks_required_to_clear(),
		resolution.player_attacks_executed(),
		resolution.opponent_attacks_executed(),
		resolution.next_player_health(),
		resolution.next_opponent_durability(),
		resolution.outcome(),
	]


func _resolution_formula_signature(
	resolution: ContactCombatResolutionScript,
) -> Array:
	return [
		resolution.effective_player_attack(),
		resolution.effective_player_defense(),
		resolution.effective_player_speed(),
		resolution.effective_opponent_attack(),
		resolution.effective_opponent_defense(),
		resolution.effective_opponent_speed(),
		resolution.player_damage_per_attack(),
		resolution.opponent_damage_per_attack(),
		resolution.first_attacker_side(),
		resolution.player_attacks_required_to_clear(),
		resolution.player_attacks_executed(),
		resolution.opponent_attacks_executed(),
		resolution.next_player_health(),
		resolution.next_opponent_durability(),
		resolution.opponent_shield_absorbed_attack(),
		resolution.opponent_shield_intact_after(),
		resolution.outcome(),
	]
