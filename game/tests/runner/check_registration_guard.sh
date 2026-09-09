#!/usr/bin/env bash

# 由唯一正式入口调用；用微型项目回归实际运行器与 bash 门面的失败检测。
set -euo pipefail

game_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
godot_binary="${GODOT_BIN:-godot}"
fixture_directory="$(mktemp -d "${TMPDIR:-/tmp}/cishiqianxing-runner-check.XXXXXX")"
cleanup() {
  rm -f -- "${fixture_directory}/project.godot" \
    "${fixture_directory}/tests/run_tests.gd" \
    "${fixture_directory}/tests/passing_tests.gd" \
    "${fixture_directory}/tests/nested/other_tests.gd" \
    "${fixture_directory}/tests/support/headless_test_case.gd" \
    "${fixture_directory}/tests/support/headless_test_context.gd" \
    "${fixture_directory}/tests/run_tests.gd.uid" \
    "${fixture_directory}/tests/passing_tests.gd.uid" \
    "${fixture_directory}/tests/nested/other_tests.gd.uid" \
    "${fixture_directory}/tests/support/headless_test_case.gd.uid" \
    "${fixture_directory}/tests/support/headless_test_context.gd.uid" \
    "${fixture_directory}/tests/runner/check_registration_guard.sh" \
    "${fixture_directory}/tools/run_headless_tests.sh" \
    "${fixture_directory}/output.log" "${fixture_directory}/engine.log"
  # 正式门面的 --import 只在这个 mktemp 微项目中生成导入缓存。
  rm -rf -- "${fixture_directory}/.godot"
  rmdir -- "${fixture_directory}/tests/support" \
    "${fixture_directory}/tests/nested" "${fixture_directory}/tests/runner" \
    "${fixture_directory}/tests" "${fixture_directory}/tools" \
    "${fixture_directory}"
}
trap cleanup EXIT
mkdir -p -- "${fixture_directory}/tests/support" "${fixture_directory}/tests/nested" \
  "${fixture_directory}/tests/runner" "${fixture_directory}/tools"
cp -- "${game_directory}/tests/support/headless_test_case.gd" \
  "${game_directory}/tests/support/headless_test_context.gd" \
  "${fixture_directory}/tests/support/"
cat > "${fixture_directory}/project.godot" <<'PROJECT'
config_version=5
[application]
config/name="RegistrationGuardFixture"
[debug]
gdscript/warnings/treat_warnings_as_errors=true
PROJECT

write_suite() {
  local suite_path="$1" test_name="$2" passes="$3"
  cat > "${suite_path}" <<SUITE
extends RefCounted
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")
func cases() -> Array[Case]:
	return [Case.new("${test_name}", _run)]
func _run(context: Context) -> void:
	context.expect_true(${passes}, "registered fixture assertion")
SUITE
}

write_runner() {
  local registered_suites="$1"
  cat > "${fixture_directory}/tests/run_tests.gd" <<RUNNER
extends SceneTree
const PassingSuite := preload("res://tests/passing_tests.gd")
const OtherSuite := preload("res://tests/nested/other_tests.gd")
const HeadlessTestCaseScript := preload("res://tests/support/headless_test_case.gd")
const HeadlessTestContextScript := preload("res://tests/support/headless_test_context.gd")
const REGISTERED_SUITES: Array[Script] = [${registered_suites}]
RUNNER
  # 只替换项目套件清单；初始化、注册守卫和执行逻辑直接取自受测入口。
  sed -n '/^var _runner_abort_triggered/,$p' "${game_directory}/tests/run_tests.gd" \
    >> "${fixture_directory}/tests/run_tests.gd"
}

check_run() {
  local label="$1" expected_exit="$2" expected_line="$3" actual_exit=0
  "${godot_binary}" --headless --path "${fixture_directory}" \
    --log-file "${fixture_directory}/engine.log" \
    --script res://tests/run_tests.gd > "${fixture_directory}/output.log" 2>&1 \
    || actual_exit=$?
  if (( actual_exit != expected_exit )) \
    || grep -Fq 'ERROR:' "${fixture_directory}/output.log" \
    || ! grep -Fq "${expected_line}" "${fixture_directory}/output.log"; then
    echo "[RUNNER-CHECK][FAIL] ${label}: expected exit ${expected_exit}, got ${actual_exit}." >&2
    cat -- "${fixture_directory}/output.log" >&2
    exit 1
  fi
  if [[ "${expected_line}" == '[TEST][FAIL] runner.registration:' ]] \
    && grep -Fq '[TEST][PASS]' "${fixture_directory}/output.log"; then
    echo "[RUNNER-CHECK][FAIL] ${label}: a suite ran before registration was validated." >&2
    cat -- "${fixture_directory}/output.log" >&2
    exit 1
  fi
  echo "[RUNNER-CHECK][PASS] ${label}"
}

check_entrypoint_run() {
  local label="$1" expected_exit="$2" expected_line="$3" actual_exit=0
  bash "${fixture_directory}/tools/run_headless_tests.sh" \
    > "${fixture_directory}/output.log" 2>&1 || actual_exit=$?
  if (( actual_exit != expected_exit )) \
    || ! grep -Fxq '[TEST][SUMMARY] total=2 passed=2 failed=0 assertions=2' \
      "${fixture_directory}/output.log" \
    || ! grep -Fq "${expected_line}" "${fixture_directory}/output.log"; then
    echo "[RUNNER-CHECK][FAIL] ${label}: expected exit ${expected_exit}, got ${actual_exit}." >&2
    cat -- "${fixture_directory}/output.log" >&2
    exit 1
  fi
  if (( expected_exit == 0 )) && grep -Fq 'ERROR:' "${fixture_directory}/output.log"; then
    echo "[RUNNER-CHECK][FAIL] ${label}: passing control reported a Godot error." >&2
    cat -- "${fixture_directory}/output.log" >&2
    exit 1
  fi
  echo "[RUNNER-CHECK][PASS] ${label}"
}

write_suite "${fixture_directory}/tests/passing_tests.gd" 'fixture.passing' true
write_suite "${fixture_directory}/tests/nested/other_tests.gd" 'fixture.other' false
write_runner 'PassingSuite'
check_run 'preloaded but omitted suite fails before execution' 1 \
  '[TEST][FAIL] runner.registration:'

write_runner 'PassingSuite, OtherSuite, OtherSuite'
check_run 'duplicate registered suite fails before execution' 1 \
  '[TEST][FAIL] runner.registration:'

write_runner 'PassingSuite, OtherSuite'
check_run 'registered failing suite executes' 1 \
  '[TEST][SUMMARY] total=2 passed=1 failed=1 assertions=2'

write_suite "${fixture_directory}/tests/nested/other_tests.gd" 'fixture.other' true
check_run 'complete registration passes' 0 \
  '[TEST][SUMMARY] total=2 passed=2 failed=0 assertions=2'

# 正常套件保留一个断言，避免整体零断言守卫掩盖单项守卫的回归。
cat > "${fixture_directory}/tests/nested/other_tests.gd" <<'SUITE'
extends RefCounted
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")
func cases() -> Array[Case]:
	return [Case.new("fixture.zero_assertions", _run)]
func _run(_context: Context) -> void:
	pass
SUITE
check_run 'one zero-assertion test fails among passing tests' 1 \
  '[TEST][SUMMARY] total=2 passed=1 failed=1 assertions=1'

# 复制完整正式门面，保留实际导入、静态检查、错误扫描与汇总校验。
# 仅将微项目里的自检入口替换为空操作，防止门面递归调用本脚本；
# 生产入口没有跳过自检的参数或环境开关。
cp -- "${game_directory}/tools/run_headless_tests.sh" \
  "${fixture_directory}/tools/run_headless_tests.sh"
printf '#!/usr/bin/env bash\nexit 0\n' \
  > "${fixture_directory}/tests/runner/check_registration_guard.sh"

write_suite "${fixture_directory}/tests/nested/other_tests.gd" 'fixture.other' true
check_entrypoint_run 'formal entrypoint accepts passing tests' 0 \
  '[TEST][SUMMARY] total=2 passed=2 failed=0 assertions=2'

cat > "${fixture_directory}/tests/nested/other_tests.gd" <<'SUITE'
extends RefCounted
const Case := preload("res://tests/support/headless_test_case.gd")
const Context := preload("res://tests/support/headless_test_context.gd")
func cases() -> Array[Case]:
	return [Case.new("fixture.runtime_error_after_assertion", _run)]
func _run(context: Context) -> void:
	context.expect_true(true, "An assertion precedes the runtime error.")
	var missing: Variant = null
	missing.call("missing_method")
SUITE
check_entrypoint_run 'formal entrypoint rejects runtime errors after assertions' 1 \
  '[TEST][FAIL] runner.godot_errors: Godot reported an unhandled error.'
