# WP1 independent review response (2026-09-28)

> **Mainline copy — decision record only (landed with the SC plan, L0).**
> [USER 2026-09-29] ruled that WP1's code does not land: this record lands as
> documentation, and S1 starts fresh from mainline with a single stepper in
> Lem. The code, tests, probes and `sc-wp1-evidence/` files this record cites
> are **not on mainline**; they remain at `arc/sc-wp1` `186392a53` (read them
> with `git show 186392a53:<path>`). M2 is resolved by not landing the shared-Lem factoring; M1 is resolved by mirroring upstream. The text below is unchanged from
> `arc/sc-wp1` `186392a53` except that links to files not on mainline are shown as plain paths.
> Current state and the 2026-09-29 rulings:
> [SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) and
> [the 2026-09-29 assessment record](2026-09-29_sc-assessment-and-rulings.md).

[AGENT] Response to the Fable review committed at `1c7e52fad` on
`review/sc-wp1-20260928`,
`lean_frontend/docs/2026-09-28_sc-wp1-independent-review.md`. It reviewed
WP1 `5ecc0aa33..af1342d32` and master-plan update `8730055b7`.
The user delivered that review on September 28. The verdicts are **decision:
ACCEPT; code/evidence and plan: ACCEPT-WITH-FIXES; no BLOCKER**. These are
reviewer judgments, not operator landing approval.

## Disposition

| Finding | Response |
|---|---|
| **M1 — upstream fork/wait behaviors** | Accepted. The master plan, technical-design S1 row, next-phase coordination response, WP1 entry and decision record now name upstream's explicit `subst_wait_stack ==> Stack_cons2` refusal. Before implementation, the proposed shared-model deviations need Core and C-par-block observability evidence, a tray draft, a proposed `shared-model-fix` register row and explicit [USER] adjudication. These are extension semantics; an ISO-C argument alone cannot decide them. No production fork/wait behavior changes in this response. |
| **M2 — experimental Lem placement / prior ruling** | **Open before landing the factoring.** Reconciliation and alternatives below; experiment placement is not approved by updating the fork-drift manifest. The feasibility decision remains usable independently of landing this code. |
| **S1 — debug stderr movement** | Recorded in the bounded-stepping note: constructing one reusable `driver2` ND value changes the number of `ENTERING Driver.driver2` messages at debug levels ≥2. Semantic/default-output evidence does not establish diagnostic identity. A production extraction must explicitly accept this movement or preserve it with a thunk. No silent claim of identical debug output. |
| **S2 — orphaned timeout** | All three harnesses now place GNU `timeout --kill-after=5 170` inside `capped`, with a 200-second outer backstop. Recorded commands include that wrapper. A selected-fault negative control rejects timeout/kill statuses even if it printed the expected error first. A real sleeping Lean probe exercises the timeout and cleanup path below. |
| **S3 — line counts instead of transcripts** | The decision harness compares all six outputs against committed transcripts. Only numeric `elapsed-ms=` fields in retention are normalized. Printed counts and schedule multiplicities are checked; the expected transcripts are included in recorded source hashes. The existing in-probe semantic assertions remain. |
| **S4 — orphaned boundary probe** | Added `SCWP1Boundary.lean` to the paired harness, checked byte-for-byte against the historical transcript after removing its separately captured environment-wrapper banner. Record the current probe and expected transcript hashes; preserve historical `boundary-identities.json`. |
| **S5 — summary/source overclaim** | The master plan now says WP1 *states* the contracts. Matrix laws concern an abstract relation; the production unseq/exclusion lemmas are Core-internal. Neither proves Core-to-reference source order or the production monitor invariant. Those remain S1/S2/WP-C obligations. |
| **N1 / N2 — provisioning / attribution** | Checked generated-tree freshness before re-runs; no stale copied artifacts accepted. Label the two paraphrases of the user's WP1 instruction as paraphrases. The decision record's quotation matches this conversation. |
| **N3 / N6 — pre-existing stderr suppression / web build** | Retained as limitations: this slice does not change `lean_probe.sh` or validate `backend/web`. Their treatment belongs to their own implementation or landing scope. N4/N5/N7 require no corrective change; test bounds, experimental adapters and streamed-output exclusions remain explicit. |

## M2: scope reconciliation, not an inferred exception

The prior instruction is recorded in
[the September 5 design](2026-09-05_typed-failure-outcomes-design.md), §0:
[USER, September 4, relayed] “we don't change the lem structure for ocaml”.
That design applies it to Lean typed-failure work: preserve Lem bodies and
OCaml output while improving the Lean representation. WP1 instead investigates
a target-symmetric bounded execution boundary for the later SC direction.
Both targets exercise the same candidate definitions, the normal runner does
not call `experiment_*`, and the reducer's ordinary consumer is checked for
preservation. That explains why shared factoring was technically relevant;
it does **not** turn experiment co-location into approved production design.
S1's debug difference also limits a blanket preservation argument.

Before a concrete factoring landing, choose one of the review's alternatives:

1. Present its exact production consumer, necessary shared changes and
   observation contract for explicit operator confirmation of this scoped
   reconciliation. Separate dispensable instrument code from the API.
2. Isolate the experiment in its own Lem module, deliberately update the
   module-set manifest through its documented review path, and revalidate both
   targets. Separately justify any remaining production factoring/constructor.

The current response does neither implementation and claims no M2 closure.
The reviewed `af1342d32` tree remains identifiable. Future production work
starts in a small branch from current mainline; this experiment is not an
implicit prerequisite to merge wholesale. No new permission is requested
here: M2 is a condition on a future concrete landing, not a reason to delay
these reversible harness and documentation corrections.

## Validation scope

This response changes diagnostic harnesses and documentation only; shared
Lem, handwritten seams, Lean semantic/proof probes and historical transcripts
are unchanged. Full A+B and the three-engine report remain historical evidence
for `af1342d32`, not a fresh landing certification. The review itself used
targeted re-runs. The focused response results and process/mutation controls
are recorded in `sc-wp1-evidence/review-response-validation.json`; fresh full
applicable gates remain required for a production landing.

- Freshness/handwritten-copy/fork-drift checks passed before execution.
- All three focused harnesses passed: decision probes and ten axiom cones;
  paired native/Lean stepping, selected-fault controls, RMW counterexamples
  and the boundary probe; seven real-C fixtures at both tested fuels.
- Changing only the printed `next-tid=16385` expectation to `16386` made the
  decision harness fail. Restoring it and rerunning passed.
- A Lean evaluation wrote a start marker and slept; the five-second inner
  timeout returned 124 with no remaining session processes or setup JSON.
  Initial checks used an unobservable stdout marker and then caught a transient
  defunct process; the record preserves those attempts. The final check uses
  a file marker and permits a bounded wait for reaping.
- A selected-fault command that printed the expected error and then timed out
  was rejected. Timeout is not accepted as the intended semantic fail-stop.
