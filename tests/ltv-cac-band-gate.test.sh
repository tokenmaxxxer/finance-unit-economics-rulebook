#!/usr/bin/env bash
# Gate tests for finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh
# Run: bash tests/ltv-cac-band-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$here/finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh"
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

with_band="LTV:CAC ratio is 4.5, a 3:1 floor easily cleared."
no_band="LTV:CAC ratio is 4.5, computed from the model."
band_far_away="LTV:CAC ratio is 4.5. $(python3 -c "print('x' * 300)") elsewhere this quarter is strong for other reasons."

assert_allow "band word near ratio -> allow" \
    "docs/issue-10/reports/finance-unit-economics.md" "$with_band"

assert_deny "ratio present, no band word -> deny" \
    "docs/issue-10/reports/finance-unit-economics.md" "$no_band"

assert_deny "band word present but outside proximity window -> deny" \
    "docs/issue-10/reports/finance-unit-economics.md" "$band_far_away"

assert_allow "foreign path is a no-op regardless of content" \
    "docs/issue-10/reports/qa.md" "$no_band"

FINANCE_LTV_CAC_BAND_GATE_OFF=1 bash -c '
python3 - "docs/issue-10/reports/finance-unit-economics.md" "ltv:cac ratio with no band" <<PY | bash "'"$gate"'"
import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
' >"$outfile" 2>&1
if [ $? -eq 0 ]; then echo "PASS: kill switch allows would-be-denied write"; else echo "FAIL: kill switch"; cat "$outfile"; fail=1; fi

exit "$fail"
