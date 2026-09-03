extends SceneTree

const GridRuleKernelTests := preload("res://tests/rules/grid_rule_kernel_tests.gd")
const ContentRegistryTests := preload("res://tests/content/content_registry_tests.gd")
const GlobalProgressionRegistryTests := preload(
	"res://tests/content/global_progression_registry_tests.gd"
)
const RepresentativeRouteContractTests := preload(
	"res://tests/content/representative_route_contract_tests.gd"
)
const EnemyProfileRegistryTests := preload(
	"res://tests/content/enemy_profile_registry_tests.gd"
)
const EnemyInstanceResolverTests := preload(
	"res://tests/rules/enemy_instance_resolver_tests.gd"
)
const PermanentGrowthClaimKernelTests := preload(
	"res://tests/rules/permanent_growth_claim_kernel_tests.gd"
)
const ContactCombatKernelTests := preload(
	"res://tests/rules/contact_combat_kernel_tests.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")


func _initialize() -> void:
	var user_arguments := OS.get_cmdline_user_args()
	if not user_arguments.is_empty():
		print(
			"[TEST][FAIL] runner.arguments: Unexpected user arguments: %s"
			% str(user_arguments)
		)
		print("[TEST][SUMMARY] total=0 passed=0 failed=1 assertions=0")
		quit(1)
		return

	var grid_rule_kernel_test_suite: GridRuleKernelTests = GridRuleKernelTests.new()
	var grid_rule_kernel_test_cases: Array[HeadlessTestCaseScript] = (
		grid_rule_kernel_test_suite.cases()
	)
	if grid_rule_kernel_test_cases.is_empty():
		_fail_empty_suite("grid_rule_kernel")
		return

	var content_registry_test_suite: ContentRegistryTests = ContentRegistryTests.new()
	var content_registry_test_cases: Array[HeadlessTestCaseScript] = (
		content_registry_test_suite.cases()
	)
	if content_registry_test_cases.is_empty():
		_fail_empty_suite("content_registry")
		return

	var global_progression_test_suite: GlobalProgressionRegistryTests = (
		GlobalProgressionRegistryTests.new()
	)
	var global_progression_test_cases: Array[HeadlessTestCaseScript] = (
		global_progression_test_suite.cases()
	)
	if global_progression_test_cases.is_empty():
		_fail_empty_suite("global_progression")
		return

	var representative_route_test_suite: RepresentativeRouteContractTests = (
		RepresentativeRouteContractTests.new()
	)
	var representative_route_test_cases: Array[HeadlessTestCaseScript] = (
		representative_route_test_suite.cases()
	)
	if representative_route_test_cases.is_empty():
		_fail_empty_suite("representative_routes")
		return

	var enemy_profile_test_suite: EnemyProfileRegistryTests = (
		EnemyProfileRegistryTests.new()
	)
	var enemy_profile_test_cases: Array[HeadlessTestCaseScript] = (
		enemy_profile_test_suite.cases()
	)
	if enemy_profile_test_cases.is_empty():
		_fail_empty_suite("enemy_profiles")
		return

	var enemy_instance_test_suite: EnemyInstanceResolverTests = (
		EnemyInstanceResolverTests.new()
	)
	var enemy_instance_test_cases: Array[HeadlessTestCaseScript] = (
		enemy_instance_test_suite.cases()
	)
	if enemy_instance_test_cases.is_empty():
		_fail_empty_suite("enemy_instances")
		return

	var permanent_growth_claim_test_suite: PermanentGrowthClaimKernelTests = (
		PermanentGrowthClaimKernelTests.new()
	)
	var permanent_growth_claim_test_cases: Array[HeadlessTestCaseScript] = (
		permanent_growth_claim_test_suite.cases()
	)
	if permanent_growth_claim_test_cases.is_empty():
		_fail_empty_suite("permanent_growth_claim")
		return

	var contact_combat_test_suite: ContactCombatKernelTests = (
		ContactCombatKernelTests.new()
	)
	var contact_combat_test_cases: Array[HeadlessTestCaseScript] = (
		contact_combat_test_suite.cases()
	)
	if contact_combat_test_cases.is_empty():
		_fail_empty_suite("contact_combat")
		return

	var test_cases: Array[HeadlessTestCaseScript] = []
	test_cases.append_array(grid_rule_kernel_test_cases)
	test_cases.append_array(content_registry_test_cases)
	test_cases.append_array(global_progression_test_cases)
	test_cases.append_array(representative_route_test_cases)
	test_cases.append_array(enemy_profile_test_cases)
	test_cases.append_array(enemy_instance_test_cases)
	test_cases.append_array(permanent_growth_claim_test_cases)
	test_cases.append_array(contact_combat_test_cases)
	if test_cases.is_empty():
		print("[TEST][FAIL] runner.discovery: No tests were registered.")
		print("[TEST][SUMMARY] total=0 passed=0 failed=1 assertions=0")
		quit(1)
		return

	var names: Dictionary[String, bool] = {}
	var passed := 0
	var failed := 0
	var executed := 0
	var assertions := 0

	for test_case: HeadlessTestCaseScript in test_cases:
		executed += 1
		var context: HeadlessTestContextScript = HeadlessTestContextScript.new()
		if test_case.name.is_empty():
			context.record_runner_failure("Test names cannot be empty.")
		elif names.has(test_case.name):
			context.record_runner_failure("Duplicate test name: %s" % test_case.name)
		else:
			names[test_case.name] = true

		if not test_case.body.is_valid():
			context.record_runner_failure("Test callable is invalid.")
		else:
			test_case.body.call(context)

		if context.assertion_count() == 0:
			context.record_runner_failure("The test executed zero assertions.")
		assertions += context.assertion_count()
		var failures: Array[String] = context.failures()
		if failures.is_empty():
			passed += 1
			print("[TEST][PASS] %s" % test_case.name)
		else:
			failed += 1
			for failure: String in failures:
				print("[TEST][FAIL] %s: %s" % [test_case.name, failure])

	if executed != test_cases.size():
		failed += 1
		print(
			"[TEST][FAIL] runner.execution: Registered %d tests but executed %d."
			% [test_cases.size(), executed]
		)
	if assertions == 0:
		failed += 1
		print("[TEST][FAIL] runner.assertions: The suite executed zero assertions.")

	print(
		"[TEST][SUMMARY] total=%d passed=%d failed=%d assertions=%d"
		% [test_cases.size(), passed, failed, assertions]
	)
	quit(0 if failed == 0 else 1)


func _fail_empty_suite(suite_name: String) -> void:
	print(
		"[TEST][FAIL] runner.discovery: Registered suite '%s' contains no tests."
		% suite_name
	)
	print("[TEST][SUMMARY] total=0 passed=0 failed=1 assertions=0")
	quit(1)
