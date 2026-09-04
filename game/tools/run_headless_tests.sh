#!/usr/bin/env bash

# 《此世千形》唯一项目级 headless 测试入口。
#
# 错误检测的三个关键事实（Godot 4.7.2 已实证，不得移除任何一道闸门）：
#
# 1. `--check-only` 在脚本存在解析错误时退出码仍为 0，因此静态阶段的可靠闸门
#    是对本阶段输出的 grep，而不是退出码。
# 2. GDScript 运行期脚本错误只会中止被调函数自己的帧，调用链不会中断；套件
#    构造与 cases() 若直接写在 _initialize 里，错误会让 _initialize 中止、
#    进程永不退出。run_tests.gd 已对二者做 Callable 间接调用并 fail-fast，
#    但测试体内部的错误仍可能被计为通过，运行阶段的可靠闸门同样是对输出
#    的 grep。
# 3. 所有阶段统一使用非锚定匹配 'ERROR:'：同时覆盖 `ERROR:`、`SCRIPT ERROR:`
#    与续行中的错误标记，宁误报不漏报（fail-closed）；与
#    .github/workflows/baseline.yml 的 import 检查保持同一标准。
#
# 直接执行 `godot --script res://tests/run_tests.gd` 会绕过本脚本的全部保护。

set -euo pipefail

if (( $# != 0 )); then
  echo '[TEST][FAIL] runner.arguments: This command does not accept arguments.' >&2
  exit 2
fi

runner_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
game_directory="$(cd -- "${runner_directory}/.." && pwd -P)"
godot_binary="${GODOT_BIN:-godot}"

required_godot_version_prefix='4.7.2.stable.official'
set +e
godot_version="$("${godot_binary}" --version 2>/dev/null)"
godot_version_probe_exit=$?
set -e
if (( godot_version_probe_exit != 0 )) || [[ "${godot_version}" != "${required_godot_version_prefix}"* ]]; then
  echo "[TEST][FAIL] runner.environment: Godot ${required_godot_version_prefix} Standard is required, but '${godot_version:-unavailable}' was found. Set GODOT_BIN to the full path of the matching build." >&2
  exit 1
fi

# 注册完备性守卫：game/tests 下每个 *_tests.gd 套件文件都必须在 run_tests.gd
# 中显式注册；support/、oracle 与 fixtures 不以 *_tests.gd 命名，天然不在比对
# 范围内。忘注册的套件会被静默跳过，此守卫把该风险变成显式失败。
present_suite_paths="$(
  find "${game_directory}/tests" -type f -name '*_tests.gd' ! -name 'run_tests.gd' \
    | sed "s|^${game_directory}/|res://|" \
    | sort --unique
)"
registered_suite_paths="$(
  grep --only-matching --extended-regexp 'res://tests/[[:alnum:]_/]+_tests\.gd' \
    "${game_directory}/tests/run_tests.gd" \
    | sort --unique \
  || true
)"
unregistered_suite_paths="$(
  comm -23 \
    <(printf '%s\n' "${present_suite_paths}") \
    <(printf '%s\n' "${registered_suite_paths}")
)"
unavailable_suite_paths="$(
  comm -13 \
    <(printf '%s\n' "${present_suite_paths}") \
    <(printf '%s\n' "${registered_suite_paths}")
)"
if [[ -n "${unregistered_suite_paths}" || -n "${unavailable_suite_paths}" ]]; then
  echo '[TEST][FAIL] runner.registration: Registered suites do not match the *_tests.gd files under game/tests.' >&2
  if [[ -n "${unregistered_suite_paths}" ]]; then
    echo '  Not registered in run_tests.gd:' >&2
    printf '%s\n' "${unregistered_suite_paths}" | sed 's/^/    /' >&2
  fi
  if [[ -n "${unavailable_suite_paths}" ]]; then
    echo '  Registered but no such file:' >&2
    printf '%s\n' "${unavailable_suite_paths}" | sed 's/^/    /' >&2
  fi
  exit 1
fi

import_log="$(mktemp "${TMPDIR:-/tmp}/cishiqianxing-import.XXXXXX")"
static_log="$(mktemp "${TMPDIR:-/tmp}/cishiqianxing-static-tests.XXXXXX")"
test_log="$(mktemp "${TMPDIR:-/tmp}/cishiqianxing-tests.XXXXXX")"
cleanup() {
  rm -f -- "${import_log}" "${static_log}" "${test_log}"
}
trap cleanup EXIT

# 先重建导入缓存：本地 clone 或拉取后未开过编辑器时，.godot 类缓存可能过期，
# 直接静态检查会报与源码无关的编译错误。CI 的 import 步骤做同一件事。
set +e
"${godot_binary}" \
  --headless \
  --path "${game_directory}" \
  --import \
  2>&1 | tee "${import_log}"
import_exit="${PIPESTATUS[0]}"
set -e

if (( import_exit != 0 )); then
  exit "${import_exit}"
fi

if grep --fixed-strings --quiet 'ERROR:' "${import_log}"; then
  echo '[TEST][FAIL] runner.import_errors: Godot reported one or more resource import errors.' >&2
  exit 1
fi

set +e
"${godot_binary}" \
  --headless \
  --path "${game_directory}" \
  --script res://tests/run_tests.gd \
  --check-only \
  2>&1 | tee "${static_log}"
static_exit="${PIPESTATUS[0]}"
set -e

if (( static_exit != 0 )); then
  exit "${static_exit}"
fi

if grep --fixed-strings --quiet 'ERROR:' "${static_log}"; then
  echo '[TEST][FAIL] runner.static_errors: Godot reported a static-check error.' >&2
  exit 1
fi

set +e
"${godot_binary}" \
  --headless \
  --path "${game_directory}" \
  --script res://tests/run_tests.gd \
  2>&1 | tee "${test_log}"
runner_exit="${PIPESTATUS[0]}"
set -e

if (( runner_exit != 0 )); then
  exit "${runner_exit}"
fi

if grep --fixed-strings --quiet 'ERROR:' "${test_log}"; then
  echo '[TEST][FAIL] runner.godot_errors: Godot reported an unhandled error.' >&2
  exit 1
fi

summary_count="$(grep --extended-regexp --count '^\[TEST\]\[SUMMARY\] ' "${test_log}" || true)"
if [[ "${summary_count}" != "1" ]]; then
  echo '[TEST][FAIL] runner.summary: Expected exactly one summary line.' >&2
  exit 1
fi

summary_line="$(grep --extended-regexp '^\[TEST\]\[SUMMARY\] ' "${test_log}")"
summary_line="${summary_line%$'\r'}"
summary_pattern='^\[TEST\]\[SUMMARY\] total=([0-9]+) passed=([0-9]+) failed=([0-9]+) assertions=([0-9]+)$'
if [[ ! "${summary_line}" =~ ${summary_pattern} ]]; then
  echo '[TEST][FAIL] runner.summary: Summary fields are malformed.' >&2
  exit 1
fi

total="${BASH_REMATCH[1]}"
passed="${BASH_REMATCH[2]}"
failed="${BASH_REMATCH[3]}"
assertions="${BASH_REMATCH[4]}"
if (( total == 0 || passed != total || failed != 0 || assertions == 0 )); then
  echo '[TEST][FAIL] runner.summary: Summary does not describe a complete passing run.' >&2
  exit 1
fi
