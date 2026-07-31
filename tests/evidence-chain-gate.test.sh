#!/usr/bin/env bash
# Gate tests for finance-evidence-chain/hooks/evidence-chain-gate.sh
# Run: bash tests/evidence-chain-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$here/finance-evidence-chain/hooks/evidence-chain-gate.sh"
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
    rm -f "$outfile"
}

assert_deny() {
    local name="$1" path="$2" content="$3"
    if run_gate "$path" "$content" >"$outfile" 2>&1; then
        echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
    else
        echo "PASS: $name"
    fi
    rm -f "$outfile"
}

sourced_chained="CAC https://example.com/cac-guide — mandate: 단위경제상 성립 chain, this metric is necessary 따라서 adopted."
sourced_no_chain="CAC https://example.com/cac-guide — adopted for this quarter."
no_source="CAC and LTV are adopted per common wisdom."
bare_arrow="CAC https://example.com/cac-guide — adopted → done."

assert_allow "sourced + two-signal chain -> allow" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$sourced_chained"

assert_deny "sourced but no chain language -> deny" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$sourced_no_chain"

assert_deny "cac/ltv named with no URL and no assumption-label -> deny" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$no_source"

assert_deny "bare arrow only, no mandate word -> deny" \
    "docs/issue-10/proposals/methodology-enforcement.md" "$bare_arrow"

assert_allow "foreign path is a no-op regardless of content" \
    "docs/issue-10/reports/qa.md" "$no_source"

FINANCE_EVIDENCE_CHAIN_GATE_OFF=1 CLAUDE_ROLE=finance-unit-economics bash -c '
python3 - "docs/issue-10/proposals/methodology-enforcement.md" "no source no chain" <<PY | bash "'"$gate"'"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
' >"$outfile" 2>&1
if [ $? -eq 0 ]; then echo "PASS: kill switch allows would-be-denied write"; else echo "FAIL: kill switch"; cat "$outfile"; fail=1; fi
rm -f "$outfile"

exit "$fail"
