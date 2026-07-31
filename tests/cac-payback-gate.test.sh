#!/usr/bin/env bash
# Gate tests for finance-cac-payback/hooks/cac-payback-gate.sh
# Run: bash tests/cac-payback-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$here/finance-cac-payback/hooks/cac-payback-gate.sh"
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

with_inputs="CAC payback period is 9 months, computed as CAC / (Monthly ARPU x Gross Margin %)."
no_arpu="CAC payback period is 9 months."

assert_allow "cac and arpu both present near payback -> allow" \
    "docs/issue-10/reports/finance-unit-economics.md" "$with_inputs"

assert_deny "payback present but no arpu -> deny" \
    "docs/issue-10/reports/finance-unit-economics.md" "$no_arpu"

assert_allow "foreign path is a no-op regardless of content" \
    "docs/issue-10/reports/qa.md" "$no_arpu"

FINANCE_CAC_PAYBACK_GATE_OFF=1 bash -c '
python3 - "docs/issue-10/reports/finance-unit-economics.md" "payback with no arpu" <<PY | bash "'"$gate"'"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
' >"$outfile" 2>&1
if [ $? -eq 0 ]; then echo "PASS: kill switch allows would-be-denied write"; else echo "FAIL: kill switch"; cat "$outfile"; fail=1; fi

exit "$fail"
