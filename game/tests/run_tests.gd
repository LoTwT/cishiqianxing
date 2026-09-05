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
const EnemyWorldResolverTests := preload(
	"res://tests/rules/enemy_world_resolver_tests.gd"
)
const PermanentGrowthClaimKernelTests := preload(
	"res://tests/rules/permanent_growth_claim_kernel_tests.gd"
)
const ContactCombatKernelTests := preload(
	"res://tests/rules/contact_combat_kernel_tests.gd"
)
const ContactCombatTransactionTests := preload(
	"res://tests/rules/contact_combat_transaction_tests.gd"
)
const WorldStepContactKernelTests := preload(
	"res://tests/rules/world_step_contact_kernel_tests.gd"
)
const PortableInventoryTests := preload(
	"res://tests/rules/portable_inventory_tests.gd"
)
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")

const REGISTERED_SUITES: Array[Script] = [
	GridRuleKernelTests,
	ContentRegistryTests,
	GlobalProgressionRegistryTests,
	RepresentativeRouteContractTests,
	EnemyProfileRegistryTests,
	EnemyInstanceResolverTests,
	EnemyWorldResolverTests,
	PermanentGrowthClaimKernelTests,
	ContactCombatKernelTests,
	ContactCombatTransactionTests,
	WorldStepContactKernelTests,
	PortableInventoryTests,
]

var _runner_abort_triggered := false

# 测试体 Callable 绑定在各套件实例上，而 Callable 不会延长 RefCounted 的生命
# 周期（Godot 4.7.2 已实证：实例被释放后全部测试体变为 invalid），必须把套件
# 实例保活到执行结束。
var _live_suite_instances: Array[RefCounted] = []


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

	if not _validate_suite_registration():
		return
	var test_cases := _collect_registered_test_cases()
	if _runner_abort_triggered:
		return
	if test_cases.is_empty():
		print("[TEST][FAIL] runner.discovery: No tests were registered.")
		print("[TEST][SUMMARY] total=0 passed=0 failed=1 assertions=0")
		quit(1)
		return

	var names: Dictionary[String, bool] = {}
	var passed := 0
	var failed := 0
	var assertions := 0

	for test_case: HeadlessTestCaseScript in test_cases:
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

	if assertions == 0:
		failed += 1
		print("[TEST][FAIL] runner.assertions: The suite executed zero assertions.")

	print(
		"[TEST][SUMMARY] total=%d passed=%d failed=%d assertions=%d"
		% [test_cases.size(), passed, failed, assertions]
	)
	quit(0 if failed == 0 else 1)


# 目录遍历只核对元数据；实际构造与执行仍严格使用 REGISTERED_SUITES。
# preload、注释和字符串中提到套件，都不等于把套件加入执行清单。
func _validate_suite_registration() -> bool:
	var present_paths: Array[String] = []
	_collect_present_suite_paths("res://tests", present_paths)
	if _runner_abort_triggered:
		return false
	var registered_paths: Array[String] = []
	for suite_script: Script in REGISTERED_SUITES:
		if suite_script == null or registered_paths.has(suite_script.resource_path):
			_fail_suite("runner.registration", "Null or duplicate suite in REGISTERED_SUITES.")
			return false
		registered_paths.append(suite_script.resource_path)
	present_paths.sort()
	registered_paths.sort()
	if present_paths != registered_paths:
		_fail_suite(
			"runner.registration",
			"Suite files %s do not match REGISTERED_SUITES %s."
			% [str(present_paths), str(registered_paths)],
		)
		return false
	return true


func _collect_present_suite_paths(directory_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_fail_suite("runner.registration", "Cannot open suite directory: %s" % directory_path)
		return
	directory.include_hidden = true
	if directory.list_dir_begin() != OK:
		_fail_suite("runner.registration", "Cannot list suite directory: %s" % directory_path)
		return
	var entry := directory.get_next()
	while not entry.is_empty():
		var entry_path := directory_path.path_join(entry)
		if directory.is_link(entry):
			_fail_suite("runner.registration", "Suite tree contains a symbolic link: %s" % entry_path)
		elif directory.current_is_dir():
			_collect_present_suite_paths(entry_path, paths)
		elif entry.ends_with("_tests.gd") and entry_path != "res://tests/run_tests.gd":
			paths.append(entry_path)
		if _runner_abort_triggered:
			break
		entry = directory.get_next()
	directory.list_dir_end()


func _collect_registered_test_cases() -> Array[HeadlessTestCaseScript]:
	var collected: Array[HeadlessTestCaseScript] = []
	for suite_script: Script in REGISTERED_SUITES:
		_collect_suite_cases(suite_script, collected)
		if _runner_abort_triggered:
			return []
	return collected


func _collect_suite_cases(
	suite_script: Script,
	collected: Array[HeadlessTestCaseScript],
) -> void:
	var suite_label := suite_script.resource_path
	var suite_instance: Variant = _constructed_suite(suite_script)
	if not suite_instance is RefCounted:
		_fail_suite(
			"runner.construction",
			"Suite '%s' could not be constructed." % suite_label
		)
		return
	var suite: RefCounted = suite_instance as RefCounted
	var cases_result: Variant = _discovered_cases(suite)
	if not cases_result is Array:
		_fail_suite(
			"runner.discovery",
			"Suite '%s' did not return an array of test cases." % suite_label
		)
		return
	var typed_cases: Array[HeadlessTestCaseScript] = []
	for case_candidate: Variant in cases_result as Array:
		if not is_instance_of(case_candidate, HeadlessTestCaseScript):
			_fail_suite(
				"runner.discovery",
				"Suite '%s' returned an entry that is not a headless test case."
				% suite_label
			)
			return
		typed_cases.append(case_candidate)
	if typed_cases.is_empty():
		_fail_suite(
			"runner.discovery",
			"Registered suite '%s' contains no tests." % suite_label
		)
		return
	_live_suite_instances.append(suite)
	collected.append_array(typed_cases)


# 经 Callable 间接构造套件：_init() 中的运行期脚本错误会中止被调帧，调用链
# 继续执行而不是中止 _initialize 导致进程永不退出（Godot 4.7.2 已实证）。
# 注意：此时 Script.new() 可能返回一个部分初始化的实例（而非 null），后续
# cases()/空套件守卫与脚本层的 SCRIPT ERROR grep 共同保证 fail-closed。
func _constructed_suite(suite_script: Script) -> Variant:
	var constructor := func() -> Variant:
		return suite_script.new()
	return constructor.call()


# 经 Callable 间接调用 cases()，理由同 _constructed_suite。已实证：带类型
# 签名的函数（如 `-> Array`）中止时，Godot 以声明类型的默认值（空数组）返回
# 而非 null——下方 is-Array 检查与空套件守卫共同保证 fail-closed。
func _discovered_cases(suite_instance: RefCounted) -> Variant:
	var discovery := func() -> Variant:
		return suite_instance.call(&"cases")
	return discovery.call()


func _fail_suite(stage: String, detail: String) -> void:
	print("[TEST][FAIL] %s: %s" % [stage, detail])
	print("[TEST][SUMMARY] total=0 passed=0 failed=1 assertions=0")
	quit(1)
	_runner_abort_triggered = true
