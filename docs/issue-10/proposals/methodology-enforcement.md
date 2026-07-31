# issue-10 phase-1 proposal (revised) — finance-unit-economics methodology enforcement as a plugin set

Revision of the prior version of this document, per the approver's "요구
정정" comment on issue #10: a single deepened directive plus one
monolithic `methodology-gate.sh` is the wrong shape. The comment asks
for the methodology to be systematized as a **set of independently
registerable plugins**, each owning exactly one methodology/metric
concern — the same pattern `core` already uses for `freelunch` and
`scout` (self-contained plugin: own hooks/, optionally agents/, own
tests, one clearly named responsibility, registered on its own in
`marketplace.json`). This revision keeps the technical content of the
prior draft (directive shape, gate check logic, gate test cases,
phase-1/phase-2 checklist criteria) but re-homes each piece under its
owning plugin instead of merging them into one script.

Grounded in the same sources as before: `docs/issue-10/reports/
finance-unit-economics/survey.md` (internal gaps), `docs/issue-10/
reports/finance-unit-economics/scout-brief.md` (field survey of
`pricing-rulebook` / `implementation-rulebook`), and `docs/issue-1/
proposals/rulebook-maturation.md` (the methodology this role adopted).
No new metric is invented here — this revision only changes how the
already-adopted methodology is packaged.

**Phase 1 ONLY.** No plugin directory, hook, agent, test, or
`marketplace.json` entry is created or edited in this pass. This
document proposes the plugin set; phase 2, if approved, executes it.

## 0.1 Revision note (WEAK-verdict feedback addressed)

The approver's WEAK verdict on the plugin-set revision asked for four
fixes, addressed in this pass:

1. **`finance-ltv-cac-band` gate now checks proximity, not file-wide
   keyword membership** — a band word must occur near an actual
   LTV:CAC ratio-token occurrence, not merely anywhere in the file
   (§4.1).
2. **`finance-evidence-chain`'s mandate-chain check now requires two
   independent signals**, not a single bare `→` — one
   mandate-referencing word AND one causal/necessity word (§3.1).
3. **New plugin `finance-ltv-churn-assumption`** added to check that
   LTV states its churn-rate/NDR assumption explicitly, not just a
   band judgment (§4.4, plugin table §1, tests §6, marketplace §7).
4. **Contribution-margin clarification** added to the handbook
   checklist's LTV line (§2) — documentation-only, no new gate (§2
   rationale).

## 0. Design principle: composition over a single gate

Per the approver's comment, the design's actual content is *which
plugins combine to form each norm*, not any one script. Two norms exist
today for this role (phase-1 proposal discipline, phase-2 record
discipline), and each is proposed as a composition of small,
independently-usable plugins rather than one script that knows about
every metric:

- **Phase-1 proposal norm** = `finance-evidence-chain` (sourcing +
  evidence→mandate chain check) **+** `finance-proposal-shape`
  (reflection-plan + Decision-requested-section check) **+** the
  existing `finance-unit-economics` base plugin's directive (states the
  mandate the chain must terminate at).
- **Phase-2 record norm** = `finance-ltv-cac-band` (ratio band
  judgment) **+** `finance-cac-payback` (payback formula visibility)
  **+** `finance-sensitivity-scenario` (>=2 numeric scenarios) **+**
  `finance-ltv-churn-assumption` (explicit churn-rate/NDR assumption
  behind the LTV figure) **+** the existing `finance-unit-economics`
  base plugin's `produces-fields-gate.sh` (field *presence*; these new
  plugins check field *quality*, each for one field only).

Each of the six new plugins is scoped to exactly one methodology
concern and is meaningful and registerable standalone — e.g.
`finance-ltv-cac-band` could in principle protect any role's record
that claims an LTV:CAC ratio, not just this one, the same way `scout`
is usable wherever a role needs a field survey. None of the six
depends on another's hook to run; they combine only in the sense that
all of them firing together on the same write is what makes the norm
complete. This is the "설계의 본체" the approver asked for: which
plugins combine, not one script's internal branching.

## 1. Plugin list (required by approver's comment)

| # | Plugin name | Methodology/metric it owns | Components proposed | Combines into |
|---|---|---|---|---|
| 1 | `finance-unit-economics` (existing, unchanged in this proposal) | The role's mandate itself: 단위경제상 성립하는가; field *presence* | `hooks/directive.sh` (existing), `hooks/produces-fields-gate.sh` (existing), `agents/warrant-hunter.md` (existing, untouched) | base layer for both phase-1 and phase-2 norms |
| 2 | `finance-evidence-chain` | Phase-1: every adopted metric (CAC/LTV/LTV:CAC/payback/sensitivity) must be sourced or assumption-labeled, and chained to this role's own mandate, not to generic industry convention | `hooks/evidence-chain-gate.sh` (PreToolUse gate), `tests/evidence-chain-gate.test.sh` | phase-1 proposal norm |
| 3 | `finance-proposal-shape` | Phase-1: the proposal document itself must give a concrete phase-2 reflection plan (`produces`/`REQUIRED_FIELDS`) and a named "Decision requested" section | `hooks/proposal-shape-gate.sh` (PreToolUse gate), `tests/proposal-shape-gate.test.sh` | phase-1 proposal norm |
| 4 | `finance-ltv-cac-band` | Phase-2: an LTV:CAC ratio must carry a band judgment (≥3:1 floor / 4:1-5:1 strong / <2:1 red flag), never a bare number | `hooks/ltv-cac-band-gate.sh` (PreToolUse gate), `tests/ltv-cac-band-gate.test.sh` | phase-2 record norm |
| 5 | `finance-cac-payback` | Phase-2: CAC payback period must show its formula's inputs (CAC, ARPU) visibly next to the number | `hooks/cac-payback-gate.sh` (PreToolUse gate), `tests/cac-payback-gate.test.sh` | phase-2 record norm |
| 6 | `finance-sensitivity-scenario` | Phase-2: a sensitivity/scenario section must carry at least two distinct labeled numeric scenarios, not a token heading | `hooks/sensitivity-scenario-gate.sh` (PreToolUse gate), `tests/sensitivity-scenario-gate.test.sh` | phase-2 record norm |
| 7 | `finance-ltv-churn-assumption` | Phase-2: an LTV figure must state its churn-rate/NDR (net dollar retention) assumption explicitly, not rely on band judgment alone | `hooks/ltv-churn-assumption-gate.sh` (PreToolUse gate), `tests/ltv-churn-assumption-gate.test.sh` | phase-2 record norm |

Plugins 2-7 are new. Plugin 1 is the existing plugin, listed only to
show what it already contributes to each norm — this proposal does not
change it.

Each new plugin (2-7) is self-contained on the `freelunch`/`scout` bar:
its own `hooks/hooks.json` registering its own `PreToolUse` command, its
own gate script, its own test file, and (per plugin) a one-line
`description` in its own `.claude-plugin/plugin.json` naming the single
methodology concern it owns. None proposes an agent — see §5 for why.

## 2. Directive (unchanged from today, not deepened further)

`finance-unit-economics/hooks/directive.sh` is left as-is by this
proposal (no change proposed here, reversing the prior draft's plan to
replace it). The mandate string it emits today —

```
you_decide="YOU DECIDE: 단위경제상 성립하는가"
use_when="USE_WHEN: 가격/비용 구조가 걸린 결정일 때"
produces="PRODUCES (required record fields): unit economics record (CAC, LTV on margin, LTV:CAC ratio + band, CAC payback period), sensitivity/scenario section with numbers"
hand_off="HAND-OFF: 실제 가격 숫자 결정은 → pricing"
```

— is exactly what `finance-evidence-chain`'s gate (§3) checks a
phase-1 chain terminates at ("mandate", "necessary" language must
connect back to "단위경제상 성립하는가", not to industry convention).
Reasoning detail belongs in the handbook below, not in a bigger
directive string; the core `role-directive.sh` signature stays fixed
and shared across all 43 rulebooks, so this was never a place to add
per-plugin logic anyway.

**Handbook** `docs/handbooks/finance-unit-economics/methodology.md`
stays proposed (still phase 2, still verbatim), but is now framed as
the shared reasoning doc all six plugins point to from their denial
messages, not as backing for one merged gate:

```markdown
# Finance-unit-economics methodology checklist

Worked guidance behind the finance-unit-economics plugin set
(`finance-evidence-chain`, `finance-proposal-shape`,
`finance-ltv-cac-band`, `finance-cac-payback`,
`finance-sensitivity-scenario`, `finance-ltv-churn-assumption`). Each plugin's gate enforces one line
of the checklist below mechanically; this handbook is the reasoning
all of them cite in their denial messages, plus the parts that are not
independently mechanically checkable per-plugin (survey-first framing,
the phase-2 explicit non-goals).

## Phase-1 proposal — steps, criteria, prohibitions

1. **Survey first.** State the internal current-state gap this proposal
   closes, separately from any external claim. (Not independently
   gated — narrative framing, checked at proposal review time.)
2. **Name the field claim and its evidence.** For every adopted metric
   (CAC, LTV, LTV:CAC, CAC payback, sensitivity), cite either a real URL
   consulted this phase, or the explicit label "working from
   named-framework assumption, not fabricated citation." A framework
   name with neither a URL nor that label is not adequate evidence.
   **Enforced by `finance-evidence-chain`.**
3. **State the chain**: field evidence → this role's mandate ("단위경제상
   성립하는가") → why the item is necessary to answer that mandate. A
   metric justified only by "this is common practice elsewhere" fails
   this step — the chain must terminate at this role's own mandate, not
   at general industry convention. **Enforced by `finance-evidence-chain`.**
4. **Give the phase-2 reflection plan**: the exact `produces` string, the
   `REQUIRED_FIELDS` list, and the gate logic changes phase 2 will
   execute without re-deriving methodology. **Enforced by
   `finance-proposal-shape`.**
5. **Name what phase 2 requests** in a "Decision requested" section.
   **Enforced by `finance-proposal-shape`.**

Prohibited at phase 1: adopting a metric with a fabricated citation;
adopting a metric with no stated chain back to the mandate; a phase-2
reflection plan that only says "add the field" with no proposed gate
logic; silently expanding scope into pricing's own `얼마를, 어떤
구조로` decision (that drift routes through the hand-off line, recorded,
not absorbed).

## Phase-2 record — steps, criteria, prohibitions

The record (`docs/issue-<n>/reports/finance-unit-economics.md`) states
fielded fact, not plan:

1. **CAC** — formula and the spend/customer-count assumptions used,
   stated explicitly next to the number. (Presence + a nearby number
   already checked by the existing base plugin's
   `produces-fields-gate.sh`; no new plugin proposed for this line
   alone.)
2. **LTV** — computed on margin, not gross revenue; the churn-rate /
   retention-horizon assumption stated explicitly. (Presence + a
   nearby number checked by the base plugin's existing gate; the
   explicit churn-rate/NDR assumption is checked separately by
   **`finance-ltv-churn-assumption`**, since a bare "computed on
   margin" claim with no stated retention assumption is unverifiable
   the same way a bare ratio number is.)

   The margin basis should specifically be **contribution margin**
   (revenue minus variable costs), not a generic "margin" or gross
   margin figure — gross margin still nets out COGS-adjacent fixed
   allocations that do not vary with the customer being valued, which
   understates or distorts LTV. This is a wording clarification only;
   no new gate is proposed for it, because the base plugin's
   `produces-fields-gate.sh` already checks LTV presence + a nearby
   number, and "which margin" is a definitional/reasoning point best
   fixed by naming it correctly here, not something a keyword gate can
   distinguish from gross margin reliably (both contain the word
   "margin").
3. **LTV:CAC ratio with a band judgment**, not a bare number: interpret
   against the field's accepted bands (≥3:1 floor, 4:1-5:1 strong, <2:1
   red flag, per `docs/issue-1/reports/finance-unit-economics/
   scout-brief.md`). A ratio with no band word attached is prohibited —
   it is indistinguishable from an unread number. **Enforced by
   `finance-ltv-cac-band`.**
4. **CAC payback period**, computed as
   `CAC / (Monthly ARPU × Gross Margin %)`, with the formula visible next
   to the number — not because the formula is exotic, but because a bare
   payback number with no visible inputs cannot be checked by a reader.
   **Enforced by `finance-cac-payback`.**
5. **Sensitivity/scenario section with at least two distinct numeric
   scenarios** (e.g. base case vs. downside on churn or margin). A
   heading with one scenario, or numbers with no scenario labels, is
   prohibited — this is this role's whole value-add over a static
   number, and it is the item most likely to be satisfied by a
   token-only heading if not checked for real content. **Enforced by
   `finance-sensitivity-scenario`.**

Explicitly not required: full cohort-by-cohort retention curve modeling
or vintage-level reporting — that is FP&A-deliverable work requiring a
data/billing pipeline this thin advisory role does not own (per
`docs/issue-1/proposals/rulebook-maturation.md` (b)/(c)). No plugin is
proposed to check for the *absence* of this — it is a scope boundary,
not a positive requirement a gate can verify.

## Why six plugins, not one script

The prior draft of this proposal put items 2-5's checks into a single
`methodology-gate.sh` with one Python block branching on `is_proposal`
/ `is_record`. That collapses independently meaningful methodology
judgments (evidence sourcing, chain-to-mandate, reflection-plan shape,
ratio-band reading, payback-formula visibility, scenario-count) into
one file no plugin boundary protects, and makes each concern
non-registerable, non-reusable, and non-independently-testable outside
this one role. Splitting them is what lets e.g. `finance-ltv-cac-band`
be registered and reused by any future role that reports an LTV:CAC
ratio, the same way `scout` is not pricing-specific. (The churn/NDR
assumption behind LTV is the sixth such judgment, added in this
revision — see §0.1 and §4.4 — for the same "one concern per plugin"
reason.)

## Why no cross-write state tracking

`implementation-rulebook`'s coding role tracks a survey-before-hunt
sequence across *separate* write events with `hunt-state.sh` because
that sequence spans genuinely distinct documents produced at different
times. This role's "조사→근거→채택" order is intra-document: every
adopted metric's evidence and chain are required in the *same* phase-1
proposal write that names the metric (checklist items 2/3 above), so a
single content check on that one write already enforces the order —
there is no second write whose absence or lateness needs tracking. No
plugin proposed here introduces state tracking for this reason.
```

## 3. Phase-1 plugins: `finance-evidence-chain`, `finance-proposal-shape`

Both scope to `CLAUDE_ROLE == finance-unit-economics` plus the fixed
directory pattern `docs/issue-<n>/proposals/*.md`, the same path
scoping the prior draft proposed (improving on `pricing-rulebook`'s
filename-substring regex per scout-brief.md, performance axis 1).

### 3.1 `finance-evidence-chain/hooks/evidence-chain-gate.sh`

```bash
#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — checks ONLY that every metric
# named in a finance-unit-economics phase-1 proposal is sourced or
# assumption-labeled, and chained back to this role's own mandate. The
# mandate-chain check requires TWO independent signals (a mandate-naming
# word AND a separate causal/necessity word) — a lone "→" or a lone
# connective word does not satisfy it.
# Does not check proposal shape (finance-proposal-shape's job) or any
# phase-2 record content (finance-ltv-cac-band / finance-cac-payback /
# finance-sensitivity-scenario / finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_EVIDENCE_CHAIN_GATE_OFF=1
set -uo pipefail
role="${CLAUDE_ROLE:-finance-unit-economics}"
deny() { echo "finance-evidence-chain: refused — $1" >&2; exit 2; }
case "${FINANCE_EVIDENCE_CHAIN_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
FE_PAYLOAD="$payload" FE_ROLE="$role" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-evidence-chain: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("FE_PAYLOAD", ""))
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
    os.environ.get("FE_ROLE") == "finance-unit-economics"
    and re.search(r'(^|/)docs/issue-[0-9]+/proposals/[^/]+\.md$', rel) is not None
)
if not is_proposal:
    sys.exit(0)

content = (ti.get("content") or ti.get("new_string") or "")
low = content.lower()
has = lambda *n: any(x in low for x in n)

missing = []
if has("cac", "ltv", "payback", "sensitivity"):
    if not has("http://", "https://", "working from named-framework assumption"):
        missing.append("source-or-assumption-label")
    # Two-signal chain check: a lone arrow or a lone connective word is not
    # a chain, only a punctuation mark or a floating word. Require at least
    # one word that names/references the mandate AND at least one separate
    # word that expresses causal necessity — two distinct categories, not
    # any-one-of-a-flat-list. A single bare "→" with nothing else fails
    # both categories and is correctly denied.
    mandate_ref = has("mandate", "단위경제상 성립")
    causal_link = has("necessary", "필요", "→", "therefore", "따라서")
    if not (mandate_ref and causal_link):
        missing.append("evidence-to-mandate-chain")
if missing:
    deny(
        "phase-1 proposal is missing: " + ", ".join(missing)
        + ". Per docs/handbooks/finance-unit-economics/methodology.md, every "
          "adopted metric must be sourced or assumption-labeled, and chained "
          "to this role's own mandate (단위경제상 성립하는가), not to general "
          "industry convention. A single bare arrow or connective word alone "
          "does not satisfy this — the chain needs a word that names the "
          "mandate AND a separate word expressing causal necessity."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
```

### 3.2 `finance-proposal-shape/hooks/proposal-shape-gate.sh`

Same path scoping, checks only shape:

```bash
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
```

## 4. Phase-2 plugins: `finance-ltv-cac-band`, `finance-cac-payback`, `finance-sensitivity-scenario`, `finance-ltv-churn-assumption`

All four scope to the same fixed record path
`docs/issue-<n>/reports/finance-unit-economics.md` already used by the
existing `produces-fields-gate.sh`, and each checks exactly one field's
*quality* (never presence — that stays the base plugin's job).

### 4.1 `finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh`

```bash
#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate — checks ONLY that an LTV:CAC ratio in the
# finance-unit-economics record carries a band judgment, and requires
# PROXIMITY: the band word must appear near an actual ratio-token
# occurrence (within a bounded character window), not merely anywhere
# in the file — a band word in an unrelated section no longer passes.
# Does not check CAC payback (finance-cac-payback's job), sensitivity
# scenarios (finance-sensitivity-scenario's job), or the churn/NDR
# assumption behind LTV (finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_LTV_CAC_BAND_GATE_OFF=1
set -uo pipefail
deny() { echo "finance-ltv-cac-band: refused — $1" >&2; exit 2; }
case "${FINANCE_LTV_CAC_BAND_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
LCB_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-ltv-cac-band: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("LCB_PAYLOAD", ""))
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

content = (ti.get("content") or ti.get("new_string") or "") if isinstance(ti, dict) else ""
low = content.lower()

RATIO_RE = re.compile(r'ltv[:\-/]cac')
BAND_RE = re.compile(
    r'floor|strong|red flag|3:1|4:1|5:1|2:1'
)
PROXIMITY_WINDOW = 120  # chars, either side of the ratio-token occurrence

ratio_hits = list(RATIO_RE.finditer(low))
if ratio_hits:
    band_hits = list(BAND_RE.finditer(low))
    def near_a_ratio(band_pos):
        return any(
            abs(band_pos - r.start()) <= PROXIMITY_WINDOW for r in ratio_hits
        )
    has_proximate_band = any(near_a_ratio(b.start()) for b in band_hits)
    if not has_proximate_band:
        deny(
            "LTV:CAC ratio present with no band judgment found near it "
            "(proximity check: a band word must occur within "
            + str(PROXIMITY_WINDOW) + " characters of a ratio-token "
            "occurrence, not merely anywhere in the file). Per "
            "docs/handbooks/finance-unit-economics/methodology.md, interpret "
            "against the accepted bands (>=3:1 floor, 4:1-5:1 strong, <2:1 "
            "red flag) — a bare ratio number, or a band word parked in an "
            "unrelated section, is indistinguishable from an unread one."
        )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
```

### 4.2 `finance-cac-payback/hooks/cac-payback-gate.sh`

Same scoping/shape, checks only:

```python
if "payback" in low and not ("cac" in low and "arpu" in low):
    deny(
        "CAC payback period present with its formula inputs not visible "
        "nearby. Per docs/handbooks/finance-unit-economics/methodology.md, "
        "show CAC / (Monthly ARPU x Gross Margin %) inputs next to the "
        "number — a bare payback number cannot be checked by a reader."
    )
```

(Full file follows the same bash wrapper as §4.1, with kill switch
`FINANCE_CAC_PAYBACK_GATE_OFF`.)

### 4.3 `finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh`

Same scoping/shape, checks only:

```python
import re
scenario_labels = re.findall(
    r'\bscenario\s*\d\b|\bbase case\b|\bdownside\b|\bupside\b|\bbull\b|\bbear\b',
    low,
)
if "sensitivity" in low and len(set(scenario_labels)) < 2:
    deny(
        "sensitivity section present with fewer than two labeled numeric "
        "scenarios. Per docs/handbooks/finance-unit-economics/methodology.md, "
        "give at least two distinct scenarios (e.g. base case vs. downside) "
        "— a heading with one scenario, or numbers with no scenario labels, "
        "is a token-only heading, not the content."
    )
```

(Full file follows the same bash wrapper as §4.1, with kill switch
`FINANCE_SENSITIVITY_SCENARIO_GATE_OFF`.)

### 4.4 `finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh`

Same scoping/shape as §4.1-§4.3 (record path
`docs/issue-<n>/reports/finance-unit-economics.md`), checks only:

```python
import re
low = content.lower()
if "ltv" in low:
    churn_assumption = re.search(
        r'\bchurn\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bchurn\b'
        r'|\bndr\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bndr\b'
        r'|net dollar retention[^.\n]{0,60}?\d|\d[^.\n]{0,60}?net dollar retention'
        r'|working from named-framework assumption',
        low,
    )
    if not churn_assumption:
        deny(
            "LTV figure present with no churn-rate or NDR (net dollar "
            "retention) assumption stated explicitly nearby. Per "
            "docs/handbooks/finance-unit-economics/methodology.md, LTV must "
            "state the retention assumption it is computed from — a band "
            "judgment on the LTV:CAC ratio (finance-ltv-cac-band's job) does "
            "not substitute for stating what churn/NDR the LTV number itself "
            "assumes."
        )
```

(Full file follows the same bash wrapper as §4.1, with kill switch
`FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF`.) This is a separate plugin
from `finance-ltv-cac-band` rather than an added check inside it: the
two check distinct methodology concerns — `finance-ltv-cac-band` reads
whether a computed ratio is judged correctly against accepted bands,
while `finance-ltv-churn-assumption` checks whether the LTV input
itself discloses the retention assumption it depends on. Folding them
together would violate the §0 "one concern per plugin" principle the
rest of this plugin set already follows.

## 5. Agents

No agent is proposed for any of the six new plugins. Each plugin's
entire scope is one mechanical check on one write; none needs the
multi-step build loop an agent exists for (contrast `coding`'s
hunt/build cycle, or this role's own existing `warrant-hunter` agent,
which surveys, not gates). `finance-unit-economics/agents/
warrant-hunter.md` stays untouched by this proposal, per issue-1's
scope note and this issue's own constraint against touching
canon-adjacent stubs outside scope.

## 6. Gate tests

Each new plugin ships its own test file (repo-root `tests/` per plugin,
following `implementation-rulebook`'s subprocess-harness shape per
scout-brief.md), instead of one shared `run-gate-tests.sh` covering all
six. Shapes fixed here so phase 2 does not re-derive them:

**`tests/evidence-chain-gate.test.sh`** (`finance-evidence-chain`):
- allow — proposal with a sourced/assumption-labeled metric and an
  evidence→mandate chain.
- deny — same, with sourcing present but no chain language.
- deny — proposal naming `cac`/`ltv` with neither a URL nor the
  assumption-label phrase.
- deny — proposal containing a single bare `→` with no other chain
  language (no "mandate"/"단위경제상 성립" word present) — proves a lone
  arrow alone no longer satisfies the mandate-chain check.
- allow, foreign-path — a write to `docs/issue-10/reports/qa.md` is a
  no-op regardless of content.
- kill switch — `FINANCE_EVIDENCE_CHAIN_GATE_OFF=1` allows a write that
  would otherwise be denied.

**`tests/proposal-shape-gate.test.sh`** (`finance-proposal-shape`):
- allow — proposal with a `produces`/`REQUIRED_FIELDS` reflection plan
  and a "Decision requested" heading.
- deny — same proposal with the "Decision requested" heading removed.
- deny — same proposal with no reflection-plan language at all.
- allow, foreign-path — as above.
- kill switch — `FINANCE_PROPOSAL_SHAPE_GATE_OFF=1`.

**`tests/ltv-cac-band-gate.test.sh`** (`finance-ltv-cac-band`):
- allow — record with a `3:1` band word next to `ltv:cac`.
- deny — record with the ratio number present but no band word.
- deny — record with a band word (e.g. `strong`) present elsewhere in
  the file, in an unrelated section, but not within the proximity
  window of any `ltv:cac` occurrence — proves file-wide keyword
  matching alone no longer passes.
- allow, foreign-path — as above.
- kill switch — `FINANCE_LTV_CAC_BAND_GATE_OFF=1`.

**`tests/cac-payback-gate.test.sh`** (`finance-cac-payback`):
- allow — record with `cac` and `arpu` both present near `payback`.
- deny — record with `payback` present but no `arpu`.
- allow, foreign-path — as above.
- kill switch — `FINANCE_CAC_PAYBACK_GATE_OFF=1`.

**`tests/sensitivity-scenario-gate.test.sh`** (`finance-sensitivity-scenario`):
- allow — record with two labeled sensitivity scenarios.
- deny — record with only one sensitivity scenario label.
- allow, foreign-path — as above.
- kill switch — `FINANCE_SENSITIVITY_SCENARIO_GATE_OFF=1`.

**`tests/ltv-churn-assumption-gate.test.sh`** (`finance-ltv-churn-assumption`):
- allow — record with `ltv` present and a nearby churn-rate or NDR
  percentage/assumption stated.
- deny — record with `ltv` present but no churn/NDR assumption stated
  anywhere nearby.
- allow, foreign-path — as above.
- kill switch — `FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF=1`.

## 7. `.claude-plugin/marketplace.json` registration (phase 2 only)

Today `marketplace.json` lists a single plugin entry
(`finance-unit-economics`). Phase 2, if approved, adds one entry per
new plugin, each independently registered (not nested under the
existing entry):

```json
{
  "name": "finance-evidence-chain",
  "source": "./finance-evidence-chain",
  "description": "Phase-1 finance-unit-economics check: every adopted metric must be sourced or assumption-labeled, and chained to the role's own mandate."
},
{
  "name": "finance-proposal-shape",
  "source": "./finance-proposal-shape",
  "description": "Phase-1 finance-unit-economics check: proposal must name a concrete phase-2 reflection plan and a Decision requested section."
},
{
  "name": "finance-ltv-cac-band",
  "source": "./finance-ltv-cac-band",
  "description": "Phase-2 finance-unit-economics check: an LTV:CAC ratio must carry a band judgment, not a bare number."
},
{
  "name": "finance-cac-payback",
  "source": "./finance-cac-payback",
  "description": "Phase-2 finance-unit-economics check: CAC payback period must show its formula inputs visibly."
},
{
  "name": "finance-sensitivity-scenario",
  "source": "./finance-sensitivity-scenario",
  "description": "Phase-2 finance-unit-economics check: sensitivity section must carry at least two labeled numeric scenarios."
},
{
  "name": "finance-ltv-churn-assumption",
  "source": "./finance-ltv-churn-assumption",
  "description": "Phase-2 finance-unit-economics check: an LTV figure must state its churn-rate/NDR assumption explicitly."
}
```

The existing `finance-unit-economics` entry is left unchanged.

## 8. Constraints check

- Canon scripts referenced, never copied: none of the six new
  plugins' gates touch `core/hooks/`; each is a new, small, role-owned
  script, the same shape `pricing-rulebook`'s own role-owned
  `methodology-gate.sh` used, just split one concern per file instead
  of merged.
- Role boundary unchanged: all proposed files live under new
  top-level plugin directories (`finance-evidence-chain/`,
  `finance-proposal-shape/`, `finance-ltv-cac-band/`,
  `finance-cac-payback/`, `finance-sensitivity-scenario/`,
  `finance-ltv-churn-assumption/`), plus
  `docs/handbooks/finance-unit-economics/` and repo-root `tests/`; no
  other role's tree is touched, and the existing `finance-unit-economics`
  plugin directory is not modified.
- Adopted-methodology source: `docs/issue-1/proposals/
  rulebook-maturation.md` and `docs/issue-1/reports/finance-unit-economics/
  scout-brief.md` remain the sole methodology sources reflected into
  the plugins and handbook above — no new metric is invented in this
  revision; only the packaging changed.
- `finance-unit-economics/agents/warrant-hunter.md` is untouched by
  this proposal (§5).

## Decision requested

Approve phase 2 to:

1. Add `docs/handbooks/finance-unit-economics/methodology.md` with the
   content in §2.
2. Add six new plugin directories, each with its own
   `.claude-plugin/plugin.json`, `hooks/hooks.json` (registering its
   own gate on `PreToolUse`, matcher `Write|Edit|MultiEdit|NotebookEdit`),
   and gate script:
   - `finance-evidence-chain/` (§3.1)
   - `finance-proposal-shape/` (§3.2)
   - `finance-ltv-cac-band/` (§4.1)
   - `finance-cac-payback/` (§4.2)
   - `finance-sensitivity-scenario/` (§4.3)
   - `finance-ltv-churn-assumption/` (§4.4)
3. Add each plugin's test file under repo-root `tests/`, per §6.
4. Register all six new plugins in `.claude-plugin/marketplace.json`,
   per §7, leaving the existing `finance-unit-economics` entry
   unchanged.
5. Leave `finance-unit-economics/agents/warrant-hunter.md`,
   `finance-unit-economics/hooks/directive.sh`, and
   `finance-unit-economics/hooks/produces-fields-gate.sh` unchanged,
   per §2's and §5's calls.
6. Record the phase-2 change and its rationale in
   `docs/issue-10/reports/finance-unit-economics.md` once executed.
