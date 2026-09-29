# SC response to next-phase coordination (2026-09-28)

Status: **[AGENT] SC response and counterproposal, for operator relay and
joint agreement.** The user supplied the coordination branch on September
28. This response does not record operator approval, reserve shared files,
or authorize a merge. SC scope and acceptance remain governed by
[SC-CONCURRENCY.md](../../SC-CONCURRENCY.md).

## Inputs and current state

- Incoming proposal: `docs/sc-coordination-20260927` at `49c3162af`,
  `lean_frontend/docs/2026-09-27_note-to-sc-track-next-phase-coordination.md`.
- Next-phase sequence: `docs/next-phase-plan-20260925` at `e509cab92`,
  `lean_frontend/docs/2026-09-25_next-phase-plan.md`, §11.
- WP1 decision/evidence: `arc/sc-wp1` at
  `af1342d32da0f47844c3856057ed1dd38ec4a164`,
  `lean_frontend/docs/2026-09-27_sc-wp1-execution-decision.md`. Complete as a
  decision/evidence package, ready for independent review; no public SC mode.
- Mainline observed for this response: `mdd/cerberus-lean` at `d62f52121`,
  including WP0 (`5ecc0aa33`) and the September 28 CerbFS path hotfix. WP1's
  validation remains evidence for its recorded tree, not this newer mainline.
  New runtime slices start from the then-current mainline and run its gates.
- Newer contract input: `docs/contract-draft-20260928` at `9c30a0017`,
  `lean_frontend/CONTRACT.md`. Its §5 records [USER, September 28] adoption of
  D1/D2/D3/D5; D4 remains a proposal. The incoming note predates this input.

These are Git object references, not files expected to coexist on this
branch. For example, read the incoming proposal with:

```sh
git show 49c3162af:lean_frontend/docs/2026-09-27_note-to-sc-track-next-phase-coordination.md
```

## Response by surface

**Agree with coordination at concrete slice boundaries.** Keep early,
independently auditable landings. A shared interface needs an agreed contract;
it does not require holding every fix until the whole of S1 is complete.

| Surface | SC response [AGENT] |
|---|---|
| Core driver, run loop and reductions | **Agree to joint design; amend file ownership and ordering.** SC owns the S1 transition/lifecycle contract. Identify overlapping functions and changes before implementation. A compatible scale fix can land as an independently audited prerequisite or S1 sub-slice, including before the rest of S1. Do not create a second competing runner or promote the WP1 experiment wholesale. |
| Outcome / kill-reason types | **Agree to one joint taxonomy note**, hosted by the next-phase track, using the newer contract below. Agree the affected shared types and observations before overlapping implementation. Existing-contract defect fixes need not wait for a complete future taxonomy. Consumer feedback can inform compatibility; an Iris integration or external-consumer adoption gate is outside the SC MVP. |
| `global.lem` / `CerbGlobal` | **Agree to an early joint interface decision.** SC drafts the concurrency portion before a reader-lifting implementation changes it; this need not wait for S5. Distinguish the semantic model from schedule-selection/exploration policy and diagnostic capture. Preserve current sequential defaults; capture must not determine allowed behavior. This response does not choose the final record shape or enable a public switch. |
| Memory model / handwritten seams | **Agree to announce before starting and serialize overlapping landings.** Claims name functions, behavior and evidence, not an indefinite lock on three entire files. The later slice rebases and checks the changed contract, including receipts, failure-time state and resource/refusal classification. |
| `Main.lean` / pipeline extraction | **Agree to the proposed near-term CLI-first order.** S5 builds on landed CLI work. Pipeline extraction also touches S1's initialization, finalization, state transport and observations: coordinate those contracts before that extraction, even if the textual edits are outside `driver.lem`. |
| Lem compiler / LemLib pin | **Agree: one active pin change at a time. SC requests no pin reservation now.** Editing Cerberus `.lem` sources and regenerating both targets does not inherently change the Lem compiler or LemLib. The first fork/wait repairs are intended to use the current pin. If a compiler/runtime change proves necessary, announce a separate, bounded two-repository slice before starting it. |
| Upstream re-sync | **Agree to joint scheduling**, outside a frozen validation/landing window. Prefer an early opportunity, but do not make it a new prerequisite that holds independent S1 fixes. Preserve WP1's pinned reference evidence; a new upstream reference requires an explicit predicate/domain comparison and renewed relevant checks. |

The claimed disjoint set needs one correction: `core_aux.lem` contains
`subst_wait`, and S1's wait/context and lexical-support work can overlap that
file and `core_run_aux.lem`. Union-twin and alignment fixes can still proceed
on independent functions; name the touched functions in their claims. Likewise,
generated-surface, gate and packaging work coordinates when it changes an
SC-used interface or its validation assumptions. No blanket delay is proposed
for measurements, diagnostics, documentation or unrelated defect fixes.

## Joint notes and their first authors

**Step-runner note: yes, jointly.** The next-phase track can assemble the
first P1f-3 draft. SC supplies the bounded transition, pending-operation
ownership, lifecycle, budget and observation contracts from WP1. The next-phase
track supplies the stack-ceiling measurements and rendering analysis,
including whether `lean_apply_*` frames defeat a Lean-level trampoline.
Separate a semantics-preserving rendering repair from a change to scheduling
boundaries. State which actual definitions the equivalence and scale claims
cover. S1's deterministic-loop yield, pure choice discovery and step/run laws
remain required; a stack optimization alone does not establish them.

**Outcome note: on the next-phase documentation branch**, linked from both
plans once agreed. Reconcile it with `CONTRACT.md` rather than creating another
public promise. That contract's four compatibility classes are not a proposed
four-constructor runtime datatype: UB can agree with the oracle, for example,
but still needs its own semantic observation. The joint note should specify:

- Normal completion, semantic UB, unsupported operations, genuine blocking,
  and resource exhaustion, with typed reasons where semantic claims need them.
  Interpreter defects, invalid API choices and host/process failures must not
  be relabelled as C UB or a normal result.
- Per-call fuel, selected-execution budgets and exploration limits, with
  distinct causes and incompleteness. A timeout cannot witness blocking or an
  empty set of permitted results.
- Failure-time state and completed effects, receipts and output; per-execution
  observations versus a claim about all executions. Stopped branches must
  remain visible when a runner aggregates results.

The new [USER] filesystem refusal decision applies to SC's inherited runtime
surface too. S1 must preserve the eventual landed refusal, not resurrect the
old behavior. The served-surface audit, especially concurrency stubs, can
proceed now; announce overlapping repairs. D4's proposed sequential libc
classification does not establish concurrent helper atomicity or protection.
Those remain the existing S1/S4 obligations. Likewise, the sequential
compatibility contract does not discharge SC's separate axiomatic-reference
soundness, coverage and object-composition obligations.

## Claims, pin timing and the next SC landing

Use the incoming note's claims register as the single shared register once
the coordination rule is agreed; link to it rather than maintaining two
mutable copies. Each claim identifies its branch, functions/interfaces and
next landing boundary. Record landing, withdrawal or replacement explicitly.
The operator can relay claims; this response changes no other track's branch.

SC has **no active S1 implementation or Lem pin claim in this response**.
The current mainline pin is `c2a68e79b6369e19f099dfa48767319c1daf19b3`;
no SC pin move or date is scheduled. The anticipated first S1 work is the
positional fork-result and modern-stack wait investigation using WP1's
counterexamples. **September 28 review correction (M1):** these behaviors are
inherited from upstream, including its explicit `Stack_cons2` refusal. Before
implementation, prepare C-par-block observability evidence, a tray draft and
proposed `shared-model-fix` register row for explicit [USER] adjudication,
under the corrected master plan. The earlier coordination proposal did not
supply that adjudication.
Declare their exact surface on a fresh branch before implementation; land
each separately if its contract can be validated independently. The later
supported transition API still owes pending primitive alternatives, child
runtime initialization, lifecycle, output/resource handling and sound lexical
temporary reclamation. A fork/wait repair does not claim S1 completion.

Validation of this response: documentation/reference and whitespace checks
only. WP1's tests and immutable evidence are unchanged. No new runtime test,
independent audit, mainline merge or push is claimed here. Following operator
relay and agreement, copy only the agreed coordination rules into both plans.
