# Fuel-parameter arc — the consumer's design review and the orchestrator's response (2026-09-04)

Review: refined-cerberus `docs/2026-09-04_review-of-fuel-parameter-design.md`
(ACCEPT; one requirement for the cerberus half; D2 recommendation).
Design note: lem-lean `arc/fuel-parameter` `doc/lean-backend/2026-09-03_fuel-parameter-design.md`;
record `2026-09-04_fuel-parameter-record.md`. Author of this response: the
orchestrator [AGENT]; decisions marked for the operator are open.

## 1. What the review requires (their §2), restated

Every fuel'd function reachable from `drive` must be one of:

- **(A) no fuel** — structural recursion on a data measure (the ctype
  AST for `sizeofCtype`/`alignofCtype`/`offsetsof`/`unqualifyAndUnatomic`;
  the value structure for `memValueToBytes`/`reconstructValue`/
  `typeofMval`; the expression for the pexpr evaluators except the Core
  pure-function-call recursion). Removes the fuel rather than
  parameterising it.
- **(B) absorbing typed exhaustion** — the function lives in a monad
  whose `bind` propagates an exhaustion outcome (`NDkilled
  fuelExhaustedKill`; a memory-monad failure the driver turns into that
  kill); its `_zero` lemma states that outcome. The driver family is
  already (B).
- **(C) not reachable from `drive`** — stated and gate-checked.

An exhaustion that returns the `Inhabited` default on the execution path
is a silent fail-open (their words and ours): at an insufficient fuel a
store proceeds at a wrong size and the run "completes" with a wrong
readout, so `∀ fuel` statements are FALSE and monotonicity unprovable.
They also ask that fuel monotonicity generation (record TODO row 13) be
scheduled WITH the cerberus half, and that the one silent value payload
the record found (`defacto_memory_aux.lem:469`) be classified.

## 2. Why this is the typed-failure pass, not a new item [AGENT]

`docs/2026-09-03_typed-failure-outcomes-ruling.md` scheduled a design
pass because `panic!`/`failwithI` sites DENOTE the `Inhabited` default in
process. An opaque fuel-exhaustion payload is the same defect at the 67
fuel'd points. The review's (A)/(B)/(C) is precisely that pass restricted
to the fuel sites, and the operator's ruling there ("consumers get
oracle conformance; fail-closed into the correct behavior") already
decides the direction. So the cerberus half of the fuel arc IS the first
tranche of the typed-failure pass, and the two should not be scheduled
separately.

## 3. The mechanism question for the operator

(A) needs a way to emit a fuel'd lem function as a Lean definition by
STRUCTURAL recursion when the recursion is structural on an argument
(most of the 67: equality on finite trees, size/alignment over the ctype
AST, byte serialisation over the value). Today the backend emits
`partial def` for every recursive definition unless fuel-declared. The
clean route [AGENT proposal]: a backend declare marking a definition as
structurally recursive (Lean's own termination checker proves it; the
result is an ordinary `def`, kernel-transparent, no fuel, no `[LemFuel]`),
fail-closed if Lean cannot prove termination (generation succeeds, the
Lean build refuses — loud). This is a lem-lean addition (S–M), and it
resolves **D2** exactly as the review recommends: `ctypeEqual`,
`Eq core_base_type`, `Eq mem_value` become structural defs and instance
methods again, with no fuel dependence. The alternative — hand-written
structural reps in cerberus for each (A) function — duplicates ~50
functions by hand and is rejected on the mirror doctrine.

## 4. Proposed scope of the cerberus half (for the operator)

1. lem-lean follow-up slice (before the pin bump): the structural
   declare (§3); the (B) generation of monotonicity for functions whose
   payload is a declared absorbing outcome of a declared monad (record
   TODO row 13, the consumer's ask); D4 as ruled.
2. cerberus half: classify each of the 67 fuel'd model functions and the
   hand-written `_lemFuel` consumers as (A)/(B)/(C) — a census row each,
   with the totality gate extended to enforce (C)'s "not reachable";
   apply the declares; `drive fuel` via `[LemFuel]`; delete `driverFuel`,
   `ndDefaultFuel`, the fixed wrappers; `--fuel` CLI default; the
   `defacto_memory_aux.lem:469` payload classified; full battery at
   `--fuel 100000000` with zero movement; the two csmith exhaustion rows
   re-run at a larger fuel.
3. Change manifest for refined-cerberus with the §6.7 restatement and
   the (A)/(B)/(C) table; their restatement slice follows their LemLib
   re-pin.

Sequencing: after Z2 merges (shared `CerbMem.lean`), before Z3/Z4.

## 5. Provenance

[AGENT] (refined-cerberus orchestrator): the review, quoted/restated in
§1. [AGENT] (this orchestrator): §2–§4. [USER]: the rulings cited. The
operator decides §3/§4.
