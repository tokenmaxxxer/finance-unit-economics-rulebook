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
revision — see the phase-1 proposal §0.1 and §4.4 — for the same "one
concern per plugin" reason.)

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
