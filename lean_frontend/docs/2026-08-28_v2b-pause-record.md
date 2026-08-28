# V2b PAUSE RECORD — P02 build-out parked for the commissioned performance redesign

Date: 2026-08-28. Worker: V2b (segment/stepper slice). This is a
PLANNED PAUSE ([USER-directed] via orchestrator), not a failure park:
the operator is commissioning a performance redesign against donor
scaling designs before P02 completes. Companion docs: the slice
record `2026-08-28_v2b-segment-stepper.md` (the fusion design, T1/P01
retrofits, tactic contracts) — this record covers only the P02
frontier state and resume pointers.

## 1. Committed at the pause (standalone-green surface)

* `RelSem/SegRoundTac.lean` (extended): `runEU_aux2_step_then` — the
  ONE-STEP-THEN-REST skeleton (pull via the computable `pullSpine` +
  `pull_constrained_spine`, one `se_*` step where cell reads enter,
  closed rest by `rfl`), plus the per-shape solvers
  `seg_se_scrut`/`seg_se_step`/`seg_eumapM` (data implicits
  goal-ified, `refine`-deferred premises).
* `RelSem/P02Guard.lean` (NEW, builds green, ~1,290 lines): the whole
  CONDITIONED-ROUND engine, all value-generic, proved once —
  - the guard ladder (P01 R10 chain generalized over BOTH operand
    values and the op): `p02sLe1/2`, `p02sAnd`, `p02sIf`,
    `p02Guard{Gt,Lt}{T,F}`, step lemmas `gsA/gsB_{gt,lt}`,
    whole-loop faces `p02cmp_{gt,lt}_{T,F}`;
  - the checked-arith ARM ladder at the CALL-form conv (T2 sT2catch
    template): `armS/armB'/armC'`, `gsArm{A,B,C}_{sub,add}`,
    whole-arm faces `p02arm_{sub,add}`;
  - **`p02add_evalR`** — the checked-ADD whole loop at the two cells
    (T2 `t2add_eval` ported: the add arm is the PRIMITIVE
    `PEconv_int` form; `p02addArms/p02addRedexP/p02zAdd`,
    `p02convV`, `p02sAddCase`, `p02sAddCatch`). PROVED — this is the
    r127-class content;
  - **`p02conv_chainR`** — the ret-conv whole loop (T1 R6
    `convChain_eq` ported to p02File at the `p02s_a_657` cell; T1's
    `z0–z4` spellings reused verbatim). PROVED — the r130-class
    content;
  - 6 DETERMINISTIC per-variant class tactics
    `seg_round_guard_{gtT,gtF,ltT,ltF}`, `seg_round_arith_{sub,add}`
    (three-peel scaffold + single-variant leaf).
* `RelSem/P02Rounds.lean` (generated base: syms, 75 fragments, ~215
  arenas, T2-template families/protocol at p02File) + 
  `RelSem/P02RoundsA.lean` (chunk 1/4, 88 round statements) — both
  FULLY GREEN.
* `lakefile.toml`: roots include P02Guard + P02Rounds + P02RoundsA
  only (B/C/D withheld — red/unconfirmed, see §2).
* Generator (container-level instrument,
  `/home/dev/projects/cerberus-lean-proj/.v2b-logs/gen_p02.py`):
  guard/arith detection from the round's redex diff with
  PATH-CONDITION hypotheses (intersected across sharing paths) +
  operand-range hyps; per-VARIANT tactic dispatch (op from the diff
  OLD, verdict from the diff NEW); the SLOW register; two fixed
  generator defects (both caught by the machinery REFUSING, never by
  silent wrongness): second-load byte hyps taken from the wrong end
  of the trace (events cons at the FRONT), and the midC `0 + b`
  spelling (prefer the plain var; `0 + b` is not defeq to `b`).

UNCOMMITTED (work-in-progress for the resuming worker; left in the
worktree untracked): `RelSem/P02RoundsB/C/D.lean` (red — see §2),
`RelSem/P02Proof.lean` (the COMPLETE 5-path body text + caller
protocol + `p02_proved`/`p02_ubfree_proved` via `verify_fn`; one
`sorry`-free except the body assembly point — blocked only on the §2
rounds), `RelSem/V2Probe.lean` (transcript instrument, resurrected
from git 055a1834b with the 5-path #eval block).

## 2. The frontier (exact, per chunk)

349 generated round statements over 5 paths (hi 63 / midA 111 /
midB 117 / lo 112 / midC 90 rounds pre-dedup; shared 24-round
prefix). Chunk states at the pause (from the last full `lake build`
logs, `.v2b-logs/chunk*-r{3,4}.log`):

| Chunk | Rounds | State | Red rounds |
|---|---|---|---|
| base | families/protocol | GREEN | — |
| A | 88 | GREEN | — |
| B | ~87 | 2 red | `p02r127_mA` (checked-ADD), `p02r130_mA` (Erun ret-conv) |
| C | ~87 | unconfirmed | pre-fix census: r186–193 (8× SLOW timeouts, now registered), r204/r238 (guards, variant-dispatched since), r232/r235 (mB ADD + Erun-conv), r257 (case-at-cell timeout, undiagnosed) |
| D | ~87 | unconfirmed | pre-fix: r266/r303/r340 (SLOW loads), r271/r308 (guards), r343/r346 (mC ADD + Erun-conv) |

C/D were mid-rebuild under the variant-dispatch + SLOW-register regen
when the pause landed; their expected residual is exactly the
ADD/Erun-conv classes (now proved in P02Guard, tactics unwired) +
possibly r257.

Path completeness: hi and lo paths' round supply is FULLY green
(their ret values are literal clamps). midA/midB/midC block on the
ADD + ret-conv rounds only.

## 3. Measurements (the performance case the redesign should consume)

* Backtracking `first` class tactics on arena-sized goals are
  PATHOLOGICAL: guard round r12 (small arena, ctr 11)
  NON-TERMINATING at a 12M-heartbeat diagnostic budget under the
  4-variant backtracker; the same round as a deterministic
  single-variant refine chain: ~50 s wall, passes at 16M. r92 (big
  arena, ctr 66): 4-variant deterministic `first` still times out at
  16M; single-variant manual ~50 s.
* Plain rounds scale with arena size but stay feasible: r28/r29
  (composite-arena eval/tau) time out at the 2M file cap, pass at
  16M. NEIGHBOR rounds at the SAME arena size (r128/r129, ctr ~100)
  pass at 2M — the cost driver is the CHAIN SHAPE (extra
  refine-unifications), not arena size alone.
* r127 (checked-ADD, ctr 99): 16M insufficient under the
  skeleton+arm tactic; a 64M probe ran >20 min unresolved (killed by
  the worker's own shell timeout — 64M ≈ 21+ min wall at observed
  heartbeat rates). ROOT CAUSE found afterwards: the add arm is the
  primitive `PEconv_int` form — the call-form arm lemma could NEVER
  unify; the tactic was grinding toward failure (the wall-clock was
  the symptom, the wrong-shape refine the disease). The ported
  whole-loop lemma (`p02add_evalR`) type-checks in seconds inside
  P02Guard.
* SLOW register: 26 rounds carry per-round
  `set_option maxHeartbeats 16000000 in` (emitted by the generator;
  names in `SLOW_ROUNDS` in gen_p02.py) + all guard/arith rounds.
  Registered residual; remover = the commissioned redesign.
* Chunk build wall-times (serial, capped 48G): A ~13 min, B ~14 min,
  C 25+ min. Worker throughput measured build-bound at ~55k
  tokens/hour vs ~400k reasoning-bound (orchestrator's numbers);
  after switching discovery to per-file probes
  (`scripts/lean_probe.sh`, 1–50 s each) the loop tightened —
  chunk builds demoted to background confirmation only.

## 4. Resume pointers (the ~6-round completion path)

1. Wire two round-level tactics consuming the PROVED loops:
   - ADD rounds (`p02r127_mA`, `p02r232_mB`, `p02r343_mC`): the
     three-peel scaffold (as in `seg_round_guard_*`) with leaf
     `refine (p02add_evalR _ _ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_).trans ?_` +
     assumption/omega. Values per path: (a,b), (a,b), (0,b).
   - Erun ret-conv rounds (`p02r130_mA`, `p02r235_mB`,
     `p02r346_mC`): T1's `t1r6` scaffold (`dnmsRoundM_adv` →
     `app_bind_active rfl` → `app_bind_active (liftCore_run_defined
     ?hM)` → `RelSem.Laws.erun_jump_m` → three `stub_defined` →
     the full-eval face). Still to state: a ~15-line
     `p02fullEval_conv` face over `(ar, f₁)` wrapping
     `p02conv_chainR` (T1's `fullEval_conv` is the template,
     T1Rounds:1005). The successor env-write is
     `fmapAddBy … p02s_a_658` — defeq to the erun fold's
     `update_env_aux` (t2upd-style rfl).
2. Re-diagnose `p02r257_lo` (case at a single cell, timed out at 2M
   pre-SLOW; likely just SLOW-class, possibly conv-conditioned).
3. Regenerate (map the 6 rounds to the new tactics in gen_p02.py's
   dispatch), rebuild B/C/D, restore the lakefile roots.
4. `RelSem/P02Proof.lean`: body text complete (seg_run + by_cases
   tree: `0 < a`, then `2147483647 - a < b`; else `a < 0`, then
   `b < -2147483648 - a`; else `a = 0` subst residue; 5 `seg_done`
   exits with `unfold satAdd; split <;> omega` readouts). The
   `(f := …)` fuel literals per exit are ESTIMATES
   (999936/999888/999882/999887/999909) — fix from the first `hF`
   error per arm. Chunk imports wired.
5. Audit pins move same-commit when B/C/D land (census grows by the
   chunk registrations; sweep count; trio cones for
   `p02_proved`/`p02_ubfree_proved`); CorpusStatements honesty labels
   flip at the same commit; proof-size registration decision.
6. Scratch/instrument dispositions at final close: delete
   `SegProbe*.lean` (already removed), decide `V2Probe.lean`
   (currently untracked instrument), keep the generator at the
   container.
