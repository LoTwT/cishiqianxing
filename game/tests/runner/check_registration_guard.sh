#!/usr/bin/env bash

# 由唯一正式入口调用；用微型项目执行实际运行器，验证漏注册不会产生假绿。
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
    "${fixture_directory}/output.log" "${fixture_directory}/engine.log"
  rmdir -- "${fixture_directory}/tests/support" \
    "${fixture_directory}/tests/nested" "${fixture_directory}/tests" \
    "${fixture_directory}"
}
trap cleanup EXIT
mkdir -p -- "${fixture_directory}/tests/support" "${fixture_directory}/tests/nested"
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
