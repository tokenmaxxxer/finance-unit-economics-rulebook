#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — checks ONLY that a
# finance-unit-economics phase-1 proposal names a concrete phase-2
# reflection plan and a "Decision requested" section. Does not check
# evidence sourcing (finance-evidence-chain's job).
#
# Kill switch: export FINANCE_PROPOSAL_SHAPE_GATE_OFF=1
set -uo pipefail
role="${CLAUDE_ROLE:-finance-unit-economics}"
deny() { echo "finance-proposal-shape: refused — $1" >&2; exit 2; }
case "${FINANCE_PROPOSAL_SHAPE_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
FP_PAYLOAD="$payload" FP_ROLE="$role" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-proposal-shape: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("FP_PAYLOAD", ""))
except Exception:
    sys.exit(0)
ti = event.get("tool_input") if isinstance(event, dict) else None
target = None
if isinstance(ti, dict):
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str) and v:
            target = v
            break
if not target:
    sys.exit(0)
rel = target.replace("\\", "/")
is_proposal = (
    os.environ.get("FP_ROLE") == "finance-unit-economics"
    and re.search(r'(^|/)docs/issue-[0-9]+/proposals/[^/]+\.md$', rel) is not None
)
if not is_proposal:
    sys.exit(0)

content = (ti.get("content") or ti.get("new_string") or "")
low = content.lower()
has = lambda *n: any(x in low for x in n)

missing = []
if not has("required_fields", "produces"):
    missing.append("phase-2-reflection-plan")
if not has("decision requested"):
    missing.append("decision-requested-section")
if missing:
    deny(
        "phase-1 proposal is missing: " + ", ".join(missing)
        + ". Per docs/handbooks/finance-unit-economics/methodology.md, a "
          "phase-1 proposal must give a concrete phase-2 reflection plan "
          "(produces string + REQUIRED_FIELDS) and name a Decision "
          "requested section."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
