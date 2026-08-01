#!/usr/bin/env bash
# Gate tests for finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh
# Run: bash tests/sensitivity-scenario-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh"
fail=0
outfile="$(mktemp)"
proj="$(mk_project)"
git init -q "$proj"
trap 'rm -f "$outfile"; rm -rf "$proj"' EXIT

write_payload() {
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
}
multiedit_payload() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": sys.argv[1], "edits": [{"old_string": sys.argv[2], "new_string": sys.argv[3]}]}}))
PY
}
assert_allow() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then echo "PASS: $name"
  else echo "FAIL (expected allow): $name"; cat "$outfile"; fail=1; fi
}
assert_deny() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
  else echo "PASS: $name"; fi
}

two_scenarios=$'## Sensitivity\nbase case LTV:CAC 4.2, downside LTV:CAC 2.8.'
one_scenario=$'## Sensitivity\nbase case LTV:CAC 4.2.'
labels_under_wrong_heading=$'## Risks\nbase case and downside both discussed here.\n\n## Sensitivity\nbase case LTV:CAC 4.2.'

assert_allow "two labeled scenarios inside sensitivity section -> allow" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$two_scenarios")"

assert_deny "only one scenario label -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$one_scenario")"

assert_deny "two scenario labels under unrelated heading, real section under-specified -> deny (section-scope upgrade)" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$labels_under_wrong_heading")"

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$one_scenario")"

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"'

mkdir -p "$proj/docs/issue-10/reports"
printf '%s' "$one_scenario" > "$proj/docs/issue-10/reports/finance-unit-economics.md"
assert_deny "MultiEdit introducing one-scenario content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/reports/finance-unit-economics.md" "$one_scenario" "$one_scenario still one")"
rm -f "$proj/docs/issue-10/reports/finance-unit-economics.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$one_scenario")" \
    FINANCE_SENSITIVITY_SCENARIO_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$one_scenario")" \
    FINANCE_SENSITIVITY_SCENARIO_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/reports/finance-unit-economics.md" "$one_scenario")"

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/reports/../../elsewhere/finance-unit-economics.md" "$one_scenario")"

exit "$fail"
