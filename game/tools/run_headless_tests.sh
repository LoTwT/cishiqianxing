#!/usr/bin/env bash

set -euo pipefail

if (( $# != 0 )); then
  echo '[TEST][FAIL] runner.arguments: This command does not accept arguments.' >&2
  exit 2
fi

runner_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
game_directory="$(cd -- "${runner_directory}/.." && pwd -P)"
godot_binary="${GODOT_BIN:-godot}"

static_log="$(mktemp "${TMPDIR:-/tmp}/cishiqianxing-static-tests.XXXXXX")"
test_log="$(mktemp "${TMPDIR:-/tmp}/cishiqianxing-tests.XXXXXX")"
cleanup() {
  rm -f -- "${static_log}" "${test_log}"
}
trap cleanup EXIT

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

if grep --extended-regexp --quiet '^(SCRIPT ERROR|ERROR):' "${static_log}"; then
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

if grep --extended-regexp --quiet '^(SCRIPT ERROR|ERROR):' "${test_log}"; then
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
