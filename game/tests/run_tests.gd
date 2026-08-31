extends SceneTree

const GridRuleKernelTests := preload("res://tests/rules/grid_rule_kernel_tests.gd")
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

	var test_suite: GridRuleKernelTests = GridRuleKernelTests.new()
	var test_cases: Array[HeadlessTestCaseScript] = test_suite.cases()
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
