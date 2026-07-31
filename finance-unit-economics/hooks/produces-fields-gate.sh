#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — thin, PRODUCES-only remainder of
# this role's former record-fields-gate.sh (issue-2 core canon reference
# transition). Core's own record-fields-gate.sh (core issue #66) now covers
# contract §20's role-agnostic structural minimum (what/why/upstream/
# loop_state/open-findings) globally; this copy no longer duplicates that
# logic. It checks ONLY this role's own PRODUCES fields (adapted per
# issue-170 from roles/finance-unit-economics.json's `produces`), which core's
# canon copy has no per-role configuration point for (survey.md, "Gap
# found"; proposal task 4, option (b)).
#
# On a write whose resolved target is this role's own record
# docs/issue-<n>/reports/finance-unit-economics.md, require a section per required field
# below. Missing any => refuse. Skeleton: field-presence checks are a
# placeholder (substring/heading match) — harden before treating as
# load-bearing.
set -uo pipefail

case "${FINANCE_UNIT_ECONOMICS_CYCLE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac

deny() { echo "finance-unit-economics: refused — $*" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "produces-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

FINANCE_UNIT_ECONOMICS_PAYLOAD="$payload" python3 <<'PY'
import json, os, sys

REQUIRED_FIELDS = ["unit-economics-model", "sensitivity-note"]
RECORD_SUFFIX = "docs/issue-" # + "<n>/reports/finance-unit-economics.md"

def deny(msg):
    sys.stderr.write("finance-unit-economics: refused — %s\n" % msg)
    sys.exit(2)

payload = os.environ.get("FINANCE_UNIT_ECONOMICS_PAYLOAD", "")
try:
    event = json.loads(payload)
except Exception:
    sys.exit(0)

ti = event.get("tool_input") if isinstance(event, dict) else None
target = None
if isinstance(ti, dict):
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str):
            target = v
            break
if not target or not target.replace("\\", "/").endswith("/reports/finance-unit-economics.md"):
    sys.exit(0)

content = ""
if isinstance(ti, dict):
    content = ti.get("content") or ti.get("new_string") or ""

missing = [f for f in REQUIRED_FIELDS if f.replace("-", " ") not in content.lower() and f not in content.lower()]
if missing:
    deny("finance-unit-economics.md is missing required produces field(s): " + ", ".join(missing))
sys.exit(0)
PY
