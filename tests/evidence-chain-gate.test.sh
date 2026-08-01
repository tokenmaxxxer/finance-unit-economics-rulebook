#!/usr/bin/env bash
# Gate tests for finance-evidence-chain/hooks/evidence-chain-gate.sh
# Run: bash tests/evidence-chain-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-evidence-chain/hooks/evidence-chain-gate.sh"
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
  local name="$1" payload="$2"; shift 2
  if run_gate "$gate" "$proj" "$payload" "$@" >"$outfile" 2>&1; then echo "PASS: $name"
  else echo "FAIL (expected allow): $name"; cat "$outfile"; fail=1; fi
}
assert_deny() {
  local name="$1" payload="$2"; shift 2
  if run_gate "$gate" "$proj" "$payload" "$@" >"$outfile" 2>&1; then echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
  else echo "PASS: $name"; fi
}

sourced_same_para="CAC https://example.com/cac-guide — mandate: 단위경제상 성립 chain, this metric is necessary 따라서 adopted."
sourced_split_para=$'CAC https://example.com/cac-guide — mandate 단위경제상 성립하는가 is named here.\n\nSomething unrelated. It is necessary 따라서 we move on to other topics.'
sourced_no_chain="CAC https://example.com/cac-guide — adopted for this quarter."
no_source="CAC and LTV are adopted per common wisdom."
bare_arrow="CAC https://example.com/cac-guide — adopted → done."

assert_allow "sourced + two-signal chain in same paragraph -> allow" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$sourced_same_para")" CLAUDE_ROLE=finance-unit-economics

assert_deny "mandate word and causal word in DIFFERENT paragraphs -> deny (paragraph-adjacency upgrade)" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$sourced_split_para")" CLAUDE_ROLE=finance-unit-economics

assert_deny "sourced but no chain language -> deny" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$sourced_no_chain")" CLAUDE_ROLE=finance-unit-economics

assert_deny "cac/ltv named with no URL and no assumption-label -> deny" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_source")" CLAUDE_ROLE=finance-unit-economics

assert_deny "bare arrow only, no mandate word -> deny" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$bare_arrow")" CLAUDE_ROLE=finance-unit-economics

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$no_source")" CLAUDE_ROLE=finance-unit-economics

# --- mandatory: CLAUDE_ROLE genuinely unset -> gate still evaluates -------
if env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT_CORE="$CLAUDE_PLUGIN_ROOT_CORE" bash -c \
    "printf '%s' '$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_source")' | bash '$gate'" \
    >"$outfile" 2>&1; then
  echo "FAIL: CLAUDE_ROLE unset must not silently no-op this gate"; cat "$outfile"; fail=1
else
  echo "PASS: CLAUDE_ROLE genuinely unset -> gate still evaluates (denies)"
fi

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"' CLAUDE_ROLE=finance-unit-economics

mkdir -p "$proj/docs/issue-10/proposals"
printf '%s' "$no_source" > "$proj/docs/issue-10/proposals/methodology-enforcement.md"
assert_deny "MultiEdit introducing no-source content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_source" "$no_source still no source")" CLAUDE_ROLE=finance-unit-economics
rm -f "$proj/docs/issue-10/proposals/methodology-enforcement.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_source")" \
    CLAUDE_ROLE=finance-unit-economics FINANCE_EVIDENCE_CHAIN_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_source")" \
    CLAUDE_ROLE=finance-unit-economics FINANCE_EVIDENCE_CHAIN_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/proposals/methodology-enforcement.md" "$no_source")" CLAUDE_ROLE=finance-unit-economics

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/proposals/../../elsewhere/methodology-enforcement.md" "$no_source")" CLAUDE_ROLE=finance-unit-economics

exit "$fail"
