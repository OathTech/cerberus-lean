# Codex charter — diverging programs end in a resource outcome, never a native stack overflow (cerberus-caesium note 2 §B) (2026-10-18, rev 5: the acceptance set frozen from the consumer's identities)

**Branch:** `fix/stack-ceiling-outcome` · **worktree:** `worktrees/cerberus-lean-fix/stack-ceiling-outcome` (created primed at dispatch
from a mainline carrying this charter). **Worker:** one Codex worker. Never merges, never pushes, never edits lem-lean or `deps/`.
Rev 2 incorporates review findings 4, 5, 11, 13, 14, 16. **DECIDED 2026-10-18 by the consumer's stated need** (cerberus-caesium's answer, relayed by the operator; paraphrased): option (i) —
its comparison needs a classifiable fuel or resource record, never a signal, within a wall-time bound of 60 seconds per program per
execution mode; a lower default fuel is acceptable because its theorem quantifies over every budget and its differential already
classifies fuel exhaustion as an accepted outcome and can pass `--fuel` per program for the finite stress programs it wants to see
complete; `--fuel` stays available and the default's value and rationale are documented; the five programs that overflow today move
from its "driver crash, not comparable" class to "fuel", the honest classification. Finite programs completing at the default (option
ii) is the structural, lem-lean matter: a characterisation plus a proposal to lem-lean is the right shape for that part. So this
charter has a cerberus-side mechanism to deliver AND a proposal to write.

## 0. Goal and success condition

**Goal.** A C program that does not terminate — the consumer's `int main(void){while(1){}}` and its diverging-callee witness — ends
in the driver's fuel-exhaustion outcome or a declared resource outcome that every lane classifies, never in `Stack overflow detected`
(exit 134), never parked in the Lean runtime's stack-overflow handler (the HANG at exit 124 that `TODO.md` records), never a signal.
Finite programs that complete today keep completing with the oracle's observation AT THE SAME EXPLICIT BUDGET; at the new default some
may exhaust instead (the consumer accepts this and passes `--fuel` per program).

**Witness classes (review findings 5, S2, S4, R5) — the input set is FROZEN (cerberus-caesium supplied its five programs on
2026-10-18; paths verified in this tree; the `ci`/`cheri-ci` pair is byte-identical and counted once):**

| # | program | shape | class |
|---|---|---|---|
| 1 | consumer `w08_loop_forever.c` (`int main(void){while(1){}}`), committed under `tests/` | infinite by design | diverging witness |
| 2 | consumer W5 diverging callee `int f(void){for(;;){}} int main(void){int *p=0; return f()+*p;}` (`cerberus-caesium/scripts/check-w4-m0-witnesses.py:40-43`), committed verbatim under `tests/` | infinite by design; its low-fuel runs yield one UB043 leaf beside fuel leaves (`cerberus-caesium/docs/2026-10-17_W4-M0-witnesses.md:54-63`) | diverging witness; EVERY leaf a mode emits is kept; `--first` follows one branch (`CerbND.lean:222-236`), so the exhaustive leaf set is not expected of it |
| 3 | `tests/ci/0014-labels_scopes_bug.syntax-only.c` (`l2: goto l2;`; `tests/cheri-ci/0014-…` is its byte-identical copy, noted, not a second input) | infinite by design | diverging witness |
| 4 | `tests/sc-recovery/prefix/race-before-loop.c` (a `{-{ … ||| … }-}` race, then `while (1) {}`) | infinite by design; the race's leaves precede the loop | diverging witness; the race's nondeterministic leaves are kept beside the fuel record, mode-appropriately |
| 5 | `tests/sc-recovery/prefix/member-before-race-loop.c` (two stores, the same race, then `while (1) {}`) | infinite by design | as 4 |
| 6 | `tests/mem-scale-probes/probes/d_loop_1000000.c` (a million-iteration loop; the consumer's fifth program, a duplicate of this probe) | FINITE; overflows today at 10^8 (`TODO.md`: exit 134 after 44.6 s) | default-budget resource witness: exhausts at the default (the consumer accepts this; it completes only with `--fuel` or the structural fix) |
| 7 | `tests/mem-scale-probes/probes/e_memcpy_1000000.c` | FINITE; overflows today at 10^8 (99.8 s) | default-budget resource witness, as 6 |

All seven MUST end through the declared resource channel at the chosen default. A default change cannot make 6 and 7 complete —
supplying a higher explicit fuel bypasses the change and does not shorten the continuation chain; with an explicit high fuel they
still expose the structural limit, which the record states and the proposal (success item 3) addresses.

- POSITIVE CONTROLS (a separate check): `tests/mem-scale-probes/probes/d_loop_100000.c` and `e_memcpy_100000.c`, which complete today
  with the oracle's values (`TODO.md`): same explicit `--fuel`, same observation, before and after.

**THE ACCEPTANCE SET (one set, used by the fuel selection, the table and the stop rule):** programs 1–7 above. Each must produce an
admitted record (FUEL, never a signal, timeout or panic-only label) within 60 s wall, pipeline included, in BOTH modes, at the chosen
default. The completing finite programs are the separate positive check. D0 writes this set out verbatim; no other wording of the set
("four programs", "the five") stands anywhere in the charter's deliverables.

**Success condition:**
1. **Characterisation (always required, D0–D1):** for every named program, at the default fuel and at 10^6/10^7/10^8 (`--fuel`), the
   exit code, first stderr line, wall time INCLUDING the pipeline and `ulimit -s` sensitivity, quoted; `addr2line` on one backtrace; and a written
   determination of WHERE the stack grows — in the production of ND actions / `nd_bind` continuations inside the step worker, or in the
   outer runner's traversal of returned nodes — with the evidence.
2. **The mechanism (D2/D3): the driver's default fuel binds before the process stack.** A bounded, stated fuel search over D1's
   measurements: the LARGEST candidate default at which EVERY program of the acceptance set ends in the FUEL outcome, exhaustive AND
   `--first`, within 60 s wall (pipeline included) on the reference box, with an empirically justified safety margin below the measured
   stack onset (quote the onset, the margin and the search); set it as the CLI default in `Main.lean` with its rationale in the code comment
   and in `VALIDATION.md`; `--fuel` stays. **The table (success item 1's shape) for every named input in each mode at the chosen
   default:** full invocation, wall time, process status, outcome channel, and ALL emitted leaves — a timeout, a signal, a panic-only
   FUEL label or a missing result fails the no-signal requirement. Positive controls: the completing finite programs match their
   before/after observation at the same explicit fuel. The overflowing finite programs end in FUEL at the default. Every lane classifies
   the outcome as FUEL (the existing text; no classifier change); plant batteries green; the only moved rows are the ones inventoried
   at D0 plus the named witnesses' own, re-recorded in a dedicated instrument commit; fresh measurements kept separate from the historical
   records. If NO default satisfies both bounds (fuel before stack AND under 60 s for every program of the acceptance set in both
   modes), stop and report with the table.
3. **The structural proposal (always required):** the record proposes the lem-lean slice that would let finite programs complete at any
   budget — a change to the ND bind or to the fuel'd worker's emission in the backend or LemLib, or a shared-model restructuring of the
   driver loop — with its repository boundary and correspondence obligations named; and it checks whether the hand-written runner
   (`CerbND.lean`) or any seam offers a control point on this side (D2), reporting the evidence either way.
4. Tier A green before every commit; Tier B (`python3 scripts/release.py --mode full`) at close-out.
5. The consumer note `docs/2026-10-18_consumer-note-cerberus-caesium-stack-ceiling.md`: the new default and its rationale, the table
   for all seven programs in both modes, the moved rows, the structural limit that remains for 6 and 7 at explicit high budgets, the
   proposal's pointer.

**The resource wire contract (review finding 11):** the mechanism is a fuel budget, so this slice uses the EXISTING fuel-exhaustion
outcome text and channel and changes no lane classifier.

Rulings, paraphrased: [USER 2026-10-17] charter it (the consumer's M0 witness died with a signal where an outcome was needed);
[USER 2026-09-03] no magic values — any new bound is a parameter with a CLI default, never a constant buried in the semantics;
[USER 2026-09-01] prefer high leverage with low trust impact, keep the trust surface obviously right relative to upstream; standing:
profile before optimizing, fail-closed, the tripwire, no doctored generated artifacts, no verbatim quotes of the operator.

## 1. What is known (verify what you touch)

| Fact | Where |
|---|---|
| The exhausting recursion and its layers | `drive_nonmemory_steps_aux2`, `frontend/model/driver.lem:1066-1095` (one recursive call per advanced step); fuel'd by `driver.lem:1915`; its generated worker `generated/Driver.lean:1313-1338` recurses THROUGH `nd_bind` continuations (`generated/Nondeterminism.lean:338-351` runs the continuation immediately inside the action) |
| Why an outer guard cannot reach it (review finding 4) | the hand-written runner `CerbND.lean:117-130` calls `m_act st0` and regains control only when the whole inner computation returns; a depth budget or continuation structure in the RUNNER never sees the inner recursion |
| Why the stack binds now | `TODO.md` ("Stack overflow vs fuel (C4 audit F-A7)" and the "Step-runner execution ceiling — SURFACING NOTE"): at the FUEL arc's 10^8 budget the 8 MB process stack is reached first; at 10^6 the 2026-08-31 design measured clean fuel exhaustion and parked |
| The design space already priced | `docs/2026-08-31_stack-ceiling-design.md` §6: (a) per-declaration budgets — lem-lean; (b) move the default budget — lem-lean; (c) trampolined/iterative runner — judged for the OUTER runner, which finding 4 shows is the wrong layer; (d) splicing generated code — REJECTED; (e) guard only |
| A cerberus-side candidate the design did not price, for D2 to evaluate honestly | lowering the driver's `--fuel` DEFAULT so fuel binds before the stack (a CLI default is permitted; it moves finite-stress outcomes). Whether that trade is acceptable is decided by what the consumer's comparison needs — cerberus-caesium is asked before dispatch (its wall-time bound; whether finite stress programs must complete) and the answer is recorded here — not by the worker |
| The Lean runtime hazard | `docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`: any solution keeps the process off the guard page |
| The oracle at the same point | design §5: the oracle's runner recurses non-tail too and fails loudly under `OCAMLRUNPARAM`; the oracle is not changed |
| CLI flags | the Lean driver has no `--mode=exhaustive`: exhaustive is its default, `--first` is single-trace (`Main.lean:1391-1394, :1520-1535`); the oracle takes `--exec --batch --mode=exhaustive` |

## 2. Deliverables (ordered)

**D0 — Inventory and base.** Tier A on the untouched worktree; the acceptance set (1–7) and the completing-control set written out;
the rows in `scripts/exec_*_baseline.txt`, `scripts/exec_ci_baseline.txt`, `tests/immaculate/baseline.txt`, the sc-recovery and mem-scale
records that name any program of either set (there are none for the two consumer witnesses — then there is nothing to re-record, only
the new regression witnesses to add); commit programs 1 and 2 under `tests/`.
**D1 — Characterise** (success item 1). Quote everything. If the premise does not reproduce at the current mainline, stop and report.
**D2 — Design checkpoint [AGENT, bounded to one day].** From D1, determine where the stack grows and the fuel-per-step figures; choose
the default per success item 2 with its margin; and record whether the hand-written runner or any seam offers a structural control
point (success item 3's evidence).
**D3 — Implement the default**, a plant that previously overflowed and now yields the FUEL outcome within 60 s (`test_fuel_plant.sh`
or a sibling), the table of success item 2, the positive controls on the completing finite programs, the instrument commit for moved
rows, Tier A.
**D4 — Documents.** The record `docs/2026-10-18_stack-ceiling-outcome-record.md` (the default and its rationale; the measurements;
the moved rows; the structural proposal in PL terms; what stays open); `TODO.md` retargeted; `VALIDATION.md`'s resource-outcome and
fuel-default text; the tray draft's status; the consumer note.

## 3. Flex — what you decide, and when to stop instead

- Yours: the probe design in D2, the mechanism within D2's demonstrated bounds, the parameter's name (recorded), commit splits.
- Not yours: lem-lean, `deps/`, generated code, the oracle, any baseline row outside D0's inventory plus the acceptance set's own, any
  classifier.
- **Stop and report when:** D1 does not reproduce; no default meets both bounds for all seven; a lane classifier would have to be
  weakened; a row outside the inventory moves; the tripwire; you are done.

## 4. Rules (binding)

Environment, hand-written-copy synchronisation (`make lean-prelude-src` after any `lean_frontend/*.lean` edit — `Main.lean`, `CerbND.lean`
and `CerbFuel.lean` are manifest-copied seams — before every capped `lake build`), checks (Tier A before every commit, per
`scripts/LADDER.md`'s rule for commits and worker-boundary claims; Tier B at close-out; the orchestrator re-runs Tier A at the boundary
and Tier B before landing), provenance, no trust gaps — as the translation charter §4 states them, EXCEPT its `.lem` regeneration,
oracle-rebuild and manifest instructions, which do not apply here. File fence: `lean_frontend/CerbND.lean`, `lean_frontend/Main.lean`,
`lean_frontend/CerbFuel.lean`, the plant scripts, `tests/` (new witnesses), the inventoried baseline files (instrument commit only),
`scripts/LADDER.md`, `lean_frontend/{TODO,VALIDATION,CLAUDE}.md`, `lean_frontend/docs/`. No classifier file is in the fence (the
existing FUEL text is used).

## 5. Reading list

Container `CLAUDE.md` · `lean_frontend/CLAUDE.md` · `docs/2026-08-31_stack-ceiling-design.md` · `TODO.md` (the two stack items) ·
`lean_frontend/CerbND.lean` · `generated/Driver.lean:1313-1338`, `generated/Nondeterminism.lean:338-351` · `frontend/model/driver.lem:1066-1095,
:1914-1916` · `scripts/common.sh` (FUEL/KILL/HANG classes) · the plant scripts · `docs/upstream-tray/lean4/01-…` ·
`docs/2026-10-17_outcome-protocol-design.md` §1 (resource forms) · `docs/2026-10-18_codex-charters-review.md` (findings 4, 5, 11) ·
the consumer's ask: note 2 §B and its agent's list, item 4.
