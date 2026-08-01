#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — checks ONLY that a
# finance-unit-economics phase-1 proposal names a concrete phase-2
# reflection plan and a "Decision requested" section. Per issue-13 A+
# upgrade, "Decision requested" must appear as a markdown HEADING
# (survey.md §6, proposal §2 row 3), not as a phrase floating in body text
# (e.g. inside a quoted counter-example or a "not yet decided" sentence).
# Does not check evidence sourcing (finance-evidence-chain's job).
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72) for
# JSON parsing, path normalization, and Write/Edit/MultiEdit content
# reconstruction, closing malformed-JSON-silent-allow and
# MultiEdit-blindness (survey.md §1/§2).
#
# Kill switch: export FINANCE_PROPOSAL_SHAPE_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-proposal-shape: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_PROPOSAL_SHAPE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

FP_PAYLOAD="$payload" FP_ROOT="$root" FP_ROLE="${CLAUDE_ROLE:-finance-unit-economics}" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    def deny(msg):
        sys.stderr.write("finance-proposal-shape: refused — %s\n" % msg)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("FP_PAYLOAD", ""), deny)
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

    root = os.environ.get("FP_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
    rel = gate_lib.gate_normalize_path(root, target)
    if rel is None:
        sys.exit(0)

    role = os.environ.get("FP_ROLE", "finance-unit-economics")
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/[^/]+\.md$')
    is_proposal = role == "finance-unit-economics" and PROPOSAL_RE.match(rel) is not None
    if not is_proposal:
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
    has = lambda *n: any(x in low for x in n)
    DECISION_HEADING_RE = re.compile(r'(?im)^#{1,6}[ \t]*decision requested[ \t]*$')

    missing = []
    if not has("required_fields", "produces"):
        missing.append("phase-2-reflection-plan")
    if not DECISION_HEADING_RE.search(new_text):
        missing.append("decision-requested-section")
    if missing:
        deny(
            "phase-1 proposal is missing: " + ", ".join(missing)
            + ". Per docs/handbooks/finance-unit-economics/methodology.md, a "
              "phase-1 proposal must give a concrete phase-2 reflection plan "
              "(produces string + REQUIRED_FIELDS) and name a 'Decision "
              "requested' section AS A HEADING (## Decision requested), not "
              "merely as a phrase in body text."
        )
    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("proposal-shape-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-proposal-shape: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
