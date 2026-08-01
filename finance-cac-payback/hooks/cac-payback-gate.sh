#!/usr/bin/env bash
# PreToolUse gate — checks ONLY that a CAC payback period in the
# finance-unit-economics record shows its formula inputs (CAC, ARPU)
# visibly next to the number. Per issue-13 A+ upgrade, "visibly next to
# the number" is now a WINDOWED ADJACENCY check around each "payback"
# occurrence (150 chars either side, survey.md §6, proposal §2 row 4),
# not a file-wide "cac in low and arpu in low" — cac/arpu defined in an
# unrelated glossary far from the payback number no longer passes.
# Does not check the LTV:CAC band (finance-ltv-cac-band's job),
# sensitivity scenarios (finance-sensitivity-scenario's job), or the
# churn/NDR assumption behind LTV (finance-ltv-churn-assumption's job).
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72) for
# JSON parsing, path normalization, and Write/Edit/MultiEdit content
# reconstruction, closing malformed-JSON-silent-allow and
# MultiEdit-blindness (survey.md §1/§2).
#
# Kill switch: export FINANCE_CAC_PAYBACK_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-cac-payback: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_CAC_PAYBACK_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

CP_PAYLOAD="$payload" CP_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    def deny(msg):
        sys.stderr.write("finance-cac-payback: refused — %s\n" % msg)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("CP_PAYLOAD", ""), deny)
    tool = event.get("tool_name") or ""
    ti = event.get("tool_input")
    if not isinstance(ti, dict):
        sys.exit(0)

    target = None
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str) and v:
            target = v
            break
    if target is None:
        sys.exit(0)

    root = os.environ.get("CP_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
    rel = gate_lib.gate_normalize_path(root, target)
    if rel is None:
        sys.exit(0)

    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/finance-unit-economics\.md$')
    if not RECORD_RE.match(rel):
        sys.exit(0)

    current = None
    p = os.path.join(root, rel)
    if os.path.isfile(p):
        try:
            with open(p, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok or new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting "
            "content from the tool input (tool=%r)." % (rel, tool)
        )

    low = new_text.lower()
    WINDOW = 150

    if "payback" in low:
        ok_nearby = False
        for m in re.finditer("payback", low):
            s, e = max(0, m.start() - WINDOW), min(len(low), m.end() + WINDOW)
            window = low[s:e]
            if "cac" in window and "arpu" in window:
                ok_nearby = True
                break
        if not ok_nearby:
            deny(
                "CAC payback period present with its formula inputs not visible "
                "within " + str(WINDOW) + " characters of the 'payback' occurrence. "
                "Per docs/handbooks/finance-unit-economics/methodology.md, show "
                "CAC / (Monthly ARPU x Gross Margin %) inputs next to the number "
                "— cac/arpu defined only in a distant glossary section does not "
                "satisfy this."
            )
    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("cac-payback-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-cac-payback: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
