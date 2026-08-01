#!/usr/bin/env bash
# Gate tests for finance-proposal-shape/hooks/proposal-shape-gate.sh
# Run: bash tests/proposal-shape-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-proposal-shape/hooks/proposal-shape-gate.sh"
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

full=$'PRODUCES (required record fields): cac, ltv. REQUIRED_FIELDS: [cac, ltv].\n\n## Decision requested\nApprove phase 2.'
no_decision="PRODUCES (required record fields): cac, ltv. REQUIRED_FIELDS: [cac, ltv]."
no_plan=$'## Decision requested\nApprove phase 2.'
phrase_not_heading="we have not written a Decision requested section yet, but here is the plan: PRODUCES (required record fields): cac, ltv. REQUIRED_FIELDS: [cac, ltv]."

assert_allow "reflection plan + Decision requested heading -> allow" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$full")" CLAUDE_ROLE=finance-unit-economics

assert_deny "Decision requested heading removed -> deny" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_decision")" CLAUDE_ROLE=finance-unit-economics

assert_deny "no reflection-plan language -> deny" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan")" CLAUDE_ROLE=finance-unit-economics

assert_deny "'decision requested' as body phrase, not a heading -> deny (heading-anchored upgrade)" \
  "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$phrase_not_heading")" CLAUDE_ROLE=finance-unit-economics

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$no_plan")" CLAUDE_ROLE=finance-unit-economics

# --- mandatory: CLAUDE_ROLE genuinely unset -> gate still evaluates -------
if env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT_CORE="$CLAUDE_PLUGIN_ROOT_CORE" bash -c \
    "printf '%s' '$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan")' | bash '$gate'" \
    >"$outfile" 2>&1; then
  echo "FAIL: CLAUDE_ROLE unset must not silently no-op this gate"; cat "$outfile"; fail=1
else
  echo "PASS: CLAUDE_ROLE genuinely unset -> gate still evaluates (denies)"
fi

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"' CLAUDE_ROLE=finance-unit-economics

mkdir -p "$proj/docs/issue-10/proposals"
printf '%s' "$no_plan" > "$proj/docs/issue-10/proposals/methodology-enforcement.md"
assert_deny "MultiEdit introducing no-plan content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan" "$no_plan still bare")" CLAUDE_ROLE=finance-unit-economics
rm -f "$proj/docs/issue-10/proposals/methodology-enforcement.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan")" \
    CLAUDE_ROLE=finance-unit-economics FINANCE_PROPOSAL_SHAPE_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/proposals/methodology-enforcement.md" "$no_plan")" \
    CLAUDE_ROLE=finance-unit-economics FINANCE_PROPOSAL_SHAPE_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/proposals/methodology-enforcement.md" "$no_plan")" CLAUDE_ROLE=finance-unit-economics

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/proposals/../../elsewhere/methodology-enforcement.md" "$no_plan")" CLAUDE_ROLE=finance-unit-economics

missing_core="$(mktemp -d)/no-such-core"
printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/x.md","content":"x"}}' \
  | env CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT_CORE="$missing_core" bash "$gate" >"$outfile" 2>&1
rc=$?
if [ "$rc" = 2 ]; then echo "PASS: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies (exit 2), not silent-allow"
else echo "FAIL: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere must deny (exit 2), got exit $rc"; cat "$outfile"; fail=1; fi

exit "$fail"
