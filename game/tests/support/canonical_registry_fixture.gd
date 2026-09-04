class_name CanonicalRegistryFixture
extends RefCounted

# 规则测试套件共享的 canonical Registry 夹具。
#
# 跨套件共享同一份缓存实例是安全的：ContentRegistryBuilderScript 的
# build_canonical() 构建过程是确定性的，封印后的 Registry 公开查询只返回
# 副本，任何套件都无法改动共享实例的内容，因此一次构建即可被全进程复用，
# 替代原先每个套件各自构建并缓存一份的做法。
#
# 带 context 的入口用 expect_true 断言构建成功与 Registry 初始化，失败信息
# 按套件标签参数化，可定位到具体套件；*_with_failure_messages 入口保留个别
# 套件的历史失败提示语文本。fresh_* 入口绕过缓存、每次构建全新实例，供需要
# 私用注册表的测试使用（例如对注册表内部做蓄意篡改的用例）。
# canonical_registry_for_helpers() 静默尽力构建、不做断言，供无 context 的
# 辅助函数使用；缓存已热时各入口都直接返回共享实例。

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const ContentRegistryBuilderScript := preload(
	"res://src/content/content_registry_builder.gd"
)
const ContentRegistryBuildResultScript := preload(
	"res://src/content/content_registry_build_result.gd"
)
const HeadlessTestContextScript := preload(
	"res://tests/support/headless_test_context.gd"
)

static var _cached_registry: ContentRegistryScript


static func canonical_registry(
	context: HeadlessTestContextScript,
	suite_label: String,
) -> ContentRegistryScript:
	if _cached_registry != null:
		return _cached_registry
	_cached_registry = _fresh_registry_with_assertions(
		context,
		"%s tests need the canonical sealed Registry." % suite_label,
		"%s test Registry must be initialized." % suite_label,
	)
	return _cached_registry


static func canonical_registry_with_failure_messages(
	context: HeadlessTestContextScript,
	build_failure_message: String,
	registry_failure_message: String,
) -> ContentRegistryScript:
	if _cached_registry != null:
		return _cached_registry
	_cached_registry = _fresh_registry_with_assertions(
		context,
		build_failure_message,
		registry_failure_message,
	)
	return _cached_registry


static func fresh_canonical_registry(
	context: HeadlessTestContextScript,
	suite_label: String,
) -> ContentRegistryScript:
	return _fresh_registry_with_assertions(
		context,
		"%s tests need the canonical sealed Registry." % suite_label,
		"%s test Registry must be initialized." % suite_label,
	)


static func fresh_canonical_registry_with_failure_messages(
	context: HeadlessTestContextScript,
	build_failure_message: String,
	registry_failure_message: String,
) -> ContentRegistryScript:
	return _fresh_registry_with_assertions(
		context,
		build_failure_message,
		registry_failure_message,
	)


static func canonical_registry_for_helpers() -> ContentRegistryScript:
	if _cached_registry == null:
		var build_result: ContentRegistryBuildResultScript = (
			ContentRegistryBuilderScript.build_canonical()
		)
		if build_result.succeeded():
			_cached_registry = build_result.registry()
	return _cached_registry


static func _fresh_registry_with_assertions(
	context: HeadlessTestContextScript,
	build_failure_message: String,
	registry_failure_message: String,
) -> ContentRegistryScript:
	var build_result: ContentRegistryBuildResultScript = (
		ContentRegistryBuilderScript.build_canonical()
	)
	context.expect_true(build_result.succeeded(), build_failure_message)
	var registry: ContentRegistryScript = build_result.registry()
	context.expect_true(
		registry != null and registry.is_initialized(),
		registry_failure_message,
	)
	return registry
