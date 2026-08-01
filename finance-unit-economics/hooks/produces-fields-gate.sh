#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit) — thin, PRODUCES-only
# remainder of this role's former record-fields-gate.sh (issue-2 core canon
# reference transition). Core's own record-fields-gate.sh (core issue #66)
# covers contract §20's role-agnostic structural minimum globally; this
# copy checks ONLY this role's own PRODUCES fields (cac, ltv, ltv-cac-ratio,
# cac-payback-period, sensitivity-note — per issue-1 phase-2 proposal),
# which core's canon copy has no per-role configuration point for.
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72)
# instead of hand-rolled JSON parse / kill switch / path match / content
# extraction — closes malformed-JSON-silent-allow, MultiEdit-blindness, and
# un-normalized-path bugs the issue-13 audit found (survey.md §1/§2/§4).
# Field checks upgraded from flat substring/400-char-window to
# section-heading-scoped (survey.md §6, proposal §2 row 1): each required
# field must appear as its own markdown heading, and the numeric-content
# check is scoped to that heading's own section body, not a flat window
# that can spill into an adjacent field's section.
#
# Kill switch: export FINANCE_UNIT_ECONOMICS_CYCLE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "produces-fields-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-unit-economics: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_UNIT_ECONOMICS_CYCLE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "produces-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

FUE_PAYLOAD="$payload" FUE_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    ROLE = "finance-unit-economics"

    def deny(msg):
        sys.stderr.write("%s: refused — %s\n" % (ROLE, msg))
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("FUE_PAYLOAD", ""), deny)
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

    root = os.environ.get("FUE_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
    rel = gate_lib.gate_normalize_path(root, target)
    if rel is None:
        sys.exit(0)  # resolves outside the project root; not this gate's business

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
            "content from the tool input (tool=%r). Write the full record with "
            "Write, or use an Edit/MultiEdit whose old_string matches, so "
            "PRODUCES fields can be checked." % (rel, tool)
        )

    REQUIRED_FIELDS = ["cac", "ltv", "ltv-cac-ratio", "cac-payback-period", "sensitivity-note"]
    NUMERIC_REQUIRED_FIELDS = ["cac", "ltv", "cac-payback-period", "sensitivity-note"]
    NUMBER_RE = re.compile(r"[$₩%]|\d")

    def norm(s):
        return re.sub(r'[-_\s]+', ' ', s.strip().lower())

    def sections(text):
        heads = list(re.finditer(r'(?m)^(#{1,6})[ \t]*(.+?)[ \t]*$', text))
        out = []
        for i, m in enumerate(heads):
            level = len(m.group(1))
            title = m.group(2)
            start = m.end()
            end = len(text)
            for m2 in heads[i + 1:]:
                if len(m2.group(1)) <= level:
                    end = m2.start()
                    break
            out.append((title, text[start:end]))
        return out

    secs = sections(new_text)

    missing = []
    no_numbers = []
    for field in REQUIRED_FIELDS:
        nf = norm(field)
        body = None
        for title, btext in secs:
            if norm(title) == nf:
                body = btext
                break
        if body is None:
            missing.append(field)
            continue
        if field in NUMERIC_REQUIRED_FIELDS and not NUMBER_RE.search(body):
            no_numbers.append(field)

    if missing:
        deny("finance-unit-economics.md is missing required produces field(s) as their own heading: " + ", ".join(missing))
    if no_numbers:
        deny("finance-unit-economics.md field(s) present as heading only, with no numeric content in that section: " + ", ".join(no_numbers))
    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("produces-fields-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-unit-economics: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
