#!/usr/bin/env bash
# Gate tests for finance-proposal-shape/hooks/proposal-shape-gate.sh
# Run: bash tests/proposal-shape-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$here/finance-proposal-shape/hooks/proposal-shape-gate.sh"
fail=0
outfile="$(mktemp)"
trap 'rm -f "$outfile"' EXIT

run_gate() {
    local path="$1" content="$2"
    CLAUDE_ROLE=finance-unit-economics python3 - "$path" "$content" <<'PY' | bash "$gate"
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

full="PRODUCES (required record fields): cac, ltv. REQUIRED_FIELDS: [cac, ltv]. ## Decision requested\nApprove phase 2."
no_decision="PRODUCES (required record fields): cac, ltv. REQUIRED_FIELDS: [cac, ltv]."
no_plan="## Decision requested\nApprove phase 2."

assert_allow "reflection plan + Decision requested -> allow" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$full"

assert_deny "Decision requested heading removed -> deny" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$no_decision"

assert_deny "no reflection-plan language -> deny" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan"

assert_allow "foreign path is a no-op regardless of content" \
    "docs/issue-10/reports/qa.md" "$no_plan"

FINANCE_PROPOSAL_SHAPE_GATE_OFF=1 CLAUDE_ROLE=finance-unit-economics bash -c '
python3 - "docs/issue-10/proposals/methodology-enforcement.md" "no plan no decision" <<PY | bash "'"$gate"'"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
' >"$outfile" 2>&1
if [ $? -eq 0 ]; then echo "PASS: kill switch allows would-be-denied write"; else echo "FAIL: kill switch"; cat "$outfile"; fail=1; fi

exit "$fail"
