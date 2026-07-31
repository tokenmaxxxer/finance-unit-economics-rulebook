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
# below (cac, ltv, ltv-cac-ratio, cac-payback-period, sensitivity-note —
# per issue-1 phase-2 proposal (b)/(d)). Missing any => refuse. For
# cac/ltv/cac-payback-period/sensitivity-note, also require an actual
# numeric token near the field label — a heading with no numbers still
# fails. Field-presence checks remain substring/heading-match placeholders
# beyond that — harden further before treating as load-bearing.
set -uo pipefail

case "${FINANCE_UNIT_ECONOMICS_CYCLE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac

deny() { echo "finance-unit-economics: refused — $*" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "produces-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

FINANCE_UNIT_ECONOMICS_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

REQUIRED_FIELDS = ["cac", "ltv", "ltv-cac-ratio", "cac-payback-period", "sensitivity-note"]
# fields whose section must carry an actual numeric token, not just a heading
# (issue-1 phase-2: closes the gap survey.md/scout-brief.md both flag —
# label-only sections previously satisfied this gate)
NUMERIC_REQUIRED_FIELDS = ["cac", "ltv", "cac-payback-period", "sensitivity-note"]
NUMBER_RE = re.compile(r"[$₩%]|\d")
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

lower = content.lower()

def find_field(field):
    for needle in (field.replace("-", " "), field):
        idx = lower.find(needle)
        if idx != -1:
            return idx
    return -1

missing = []
no_numbers = []
for field in REQUIRED_FIELDS:
    idx = find_field(field)
    if idx == -1:
        missing.append(field)
        continue
    if field in NUMERIC_REQUIRED_FIELDS:
        window = content[idx:idx + 400]
        if not NUMBER_RE.search(window):
            no_numbers.append(field)

if missing:
    deny("finance-unit-economics.md is missing required produces field(s): " + ", ".join(missing))
if no_numbers:
    deny("finance-unit-economics.md field(s) present as heading only, with no numeric content nearby: " + ", ".join(no_numbers))
sys.exit(0)
PY
