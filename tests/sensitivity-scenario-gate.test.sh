#!/usr/bin/env bash
# Gate tests for finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh
# Run: bash tests/sensitivity-scenario-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$here/finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh"
fail=0
outfile="$(mktemp)"
trap 'rm -f "$outfile"' EXIT

run_gate() {
    local path="$1" content="$2"
    python3 - "$path" "$content" <<'PY' | bash "$gate"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
}

assert_allow() {
    local name="$1" path="$2" content="$3"
    if run_gate "$path" "$content" >"$outfile" 2>&1; then
        echo "PASS: $name"
    else
        echo "FAIL (expected allow): $name"; cat "$outfile"; fail=1
    fi
}

assert_deny() {
    local name="$1" path="$2" content="$3"
    if run_gate "$path" "$content" >"$outfile" 2>&1; then
        echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
    else
        echo "PASS: $name"
    fi
}

two_scenarios="Sensitivity: base case LTV:CAC 4.2, downside LTV:CAC 2.8."
one_scenario="Sensitivity: base case LTV:CAC 4.2."

assert_allow "two labeled scenarios -> allow" \
    "docs/issue-10/reports/finance-unit-economics.md" "$two_scenarios"

assert_deny "only one scenario label -> deny" \
    "docs/issue-10/reports/finance-unit-economics.md" "$one_scenario"

assert_allow "foreign path is a no-op regardless of content" \
    "docs/issue-10/reports/qa.md" "$one_scenario"

FINANCE_SENSITIVITY_SCENARIO_GATE_OFF=1 bash -c '
python3 - "docs/issue-10/reports/finance-unit-economics.md" "sensitivity with one scenario" <<PY | bash "'"$gate"'"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
' >"$outfile" 2>&1
if [ $? -eq 0 ]; then echo "PASS: kill switch allows would-be-denied write"; else echo "FAIL: kill switch"; cat "$outfile"; fail=1; fi

exit "$fail"
