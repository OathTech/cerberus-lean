# V2 — THE HEART: per-construct symbolic rules + the case-splitting stepper (slice record)

Date: 2026-08-28. Worker: V2 (orchestrated slice, arc-18 segment-ladder
infrastructure plan). Worktree `cerberus-lean-coherence`, branch
`arc/segment-ladder`. Commits: `3bf679384` (T3 rules), `055a1834b`
(T3 proved), `22fbc4d0a` (verify_fn revival), plus the earlier V2
commits (T1 engine/proof, P01 engine/proof, T2 engine/proof) on this
branch.

## 1. What landed (exits)

| Exit | Status |
|------|--------|
| (a) P01Threaded proved at its registered Cns statement, cone trio | **DONE** — `p01_proved : P01Statement`, `p01_ubfree_proved : P01UBFreeStatement` (P01Proof.lean); cones exactly {propext, Classical.choice, Quot.sound}, exact-pinned in Audit.lean |
| (b) P02 proved | **PARKED WITH MEASUREMENT** (§5 — the grind-shape finding; 63–117 rounds × 4 paths measured by the probe) |
| (c) P03 proved (park allowed) | **PARKED** (park-with-price pre-authorized; bodyK multi-iteration + stack frames — a new round class, priced §5) |
| (d) T1/T2/T3 re-proved through the per-round layer | **DONE** — `t1_threaded_proved`, `t2_threaded_proved`+UB, `t3_threaded_proved`+UB; all trio-pinned |
| (e) retirement tranche | **CHECKED, EMPTY** — the killed-by-registration register holds one row (`LemLib.runEffectful`, lem-side); its mover is effect-state threading, not this slice's registrations. No row triggered. |
| (f) FnSpec re-target Thr→Cns + verify_fn revival | **DONE** (§4) |

The case-split DELIVERABLE (1) landed as a proof idiom, not a new wpk
lemma: P01's branch enters at the R10 verdict round as a meta-level
`by_cases hlt : x < 0` whose two sides each get a complete arm chain —
the path condition is an ordinary pure hypothesis consumed by the
per-side eval laws (`p01cmp_eval_T/F`, `p01eq_eval_T/F`) and by the
terminal (`rw [show max x 0 = _ from by omega]`). No dedicated
`wpk_if_split` was needed because rounds are deterministic given the
path condition; the split lives where Hoare's if-rule puts it — over
the two straight-line segments.

## 2. The engine (what exists now)

One WP proof per program = caller protocol (globals / resolve /
inject / errno / setup-birth) + one `wpk_*` rule application per
`dnmsRoundM` round + terminal. Rules (all `@[step_law]`, census 99):

- Control/tau: `wpk_seq_ctl` (+`_fam`), `ctl_env1(_fam)`,
  `ctl_env2(_fam)` (two env cells read, e.g. the checked add),
  `ctl_sup`, `ctl_sup_lk`, `ctl_sup_mem`.
- Births: `birth1(_fam)`, `birth1_env1(_fam)`, `birth2(_fam)` — env
  cell + domain-ledger extension in one step.
- Memory writers (NEW this slice, the T3 tranche —
  HeapLang wp_alloc/wp_store/wp_free at round granularity):
  `wpk_seq_ctl_sup_alloc` (create: mints `allocIs` + `pointsToBytes`
  out of the round's frame-preserving update),
  `wpk_seq_ctl_sup_store` (rewrites an OWNED byte range; carries
  `mrestIs`+`allocIs` context resources whose get?/funptrmap facts
  feed the round equation), `wpk_seq_ctl_sup_kill` (retires the
  footprint into `mrKill`); plus `wpk_seq_alloc_store`,
  `wpk_seq_alloc_store2` (arg inject), composed from the factored
  `interp_alloc_store_bupd`/`interp_kill_update` ghost updates and
  layout-blind token casts (`ctlIs_layout_cast`/`supIs_layout_cast`).
- Reads: `read_ctl(_dom)`, `env_write`, `get_done_ctl` + terminal
  glue (done offer, `dnms_nil`, `ndctPick_one`, `driver2Rest_done`).

Round-equation supply per program (`{T1,T2,T3,P01}Rounds.lean`):
generated arenas + `update_env_aux` pattern lemmas + family/inversion
pairs + the per-round `app (dnmsRoundM …) (fam …) = (NDactive …, fam' …)`
equations, produced by the PRODUCTION LINE — `V2Probe` (a Lean-source
printer emitting per-round ARENA/ENV/TRACE as Lean text, deleted at
slice close per plan) → python generators → template-stamped proof
blocks. T3 (24 rounds, create/store/kill) compiled with five defects
on first REAL probe (§6), all shape-level, none semantic.

## 3. Findings (design-relevant)

- **STAGE-0**: harness setup writes `current_loc := other
  "RelSem.callND"`; the first eval round resets it to `Loc.unknown` —
  every program needs a stage-0 family + inversion + a stage-0 round.
- **Instance-spelling divergence**: the harness env-fold inserts at
  `instBEqSym`/`ordCompare`; the machine binds at
  `instBEqOfMapKeyType`/`mapKeyCompare` — not cheaply defeq (the
  `envCmp_insert_eq` rfl hits the kernel's fixed 200k whnf budget).
  Fix: instance-GENERIC birth legs (`birth_new'`/… with
  `hpc : lemCmpToOrd pcmp = symCmpO`), and P01's `clsNone` (ledger +
  freshness ⇒ the whole comparator class unbound) killing per-birth
  boilerplate.
- **The grind-shape observation** (motivates the Hoare/segment
  layer, [USER 2026-08-26] ruling): the per-round idiom is
  O(rounds × paths) generated text — P01's branch DOUBLED the
  post-split supply (arms T21–26 / F21–30). P02 measures 63–117
  rounds × 4 paths before any lemma is written. These proofs are
  engine-room equation supply, exactly what the ruling says should be
  consumed ONCE per derived SEGMENT RULE and never appear in user
  proofs. The per-fixture proof files are deliberately NOT registered
  at the proof-size gate's slate list: they are the mega-proof shape
  that gate exists to catch, and the honest disposition is this
  finding, not a registration exemption.

## 4. verify_fn revived (FnSpec Thr→Cns)

`Segment.lean` role 1 gains the Cns faces: `FnSpec.VerifiedCns` /
`VerifiedUBCns` / `WpObCns` (the ledger-carrying `callK2` sequent) +
`dischargeCns`/`dischargeUBCns` proved once through
`kCallHarness{Adequate,UBFree}CnsSt_of_wp2`. `verify_fn` classifies
the Cns statement shapes (param Ints immediately after the EnvHyp vs
the Thr seed binder) and leaves the RAW ∀-seed sequent so the
per-round layer's whole-function WP lemma plugs by `exact`:

```
theorem p01_proved : P01Statement := by
  verify_fn p01FnSpec
  exact p01_wp a ha.1 ha.2 seed
```

— the registered statement discharged in two lines over the factored
`p01_wp`. (Hygiene note: the closing intro must `mkIdent` its names.)

## 5. Parked frontiers (priced)

- **P02 (sat_add)**: 4 paths (both-guards-false / hi / lo / mid),
  63–117 rounds each, shared 24-round prefix; every mechanism needed
  already exists (inject2, checked-add chains, by_cases splits). Cost
  at the current idiom ≈ 4× P01's post-split volume — the wrong
  abstraction level to pay at (§3). First segment-rule slice should
  reprice it to ~4 segment obligations.
- **P03 (internal ccall)**: needs bodyK re-entry (a second in-flight
  body continuation) — a new round class (call/return frames), not a
  variation of the existing ones. Priced M; charter pre-authorized
  the park.

## 6. Instrument incident (record-integrity)

T3's initial "zero probe errors" was FALSE: the file-header doc
comment contained the literal `7/-4`, whose `/-` opens a NESTED block
comment — the header's closer closed the nested one and the whole
file became a comment; `lean_probe`'s error grep (`^RelSem.*error`)
missed the lake-level failure — a fail-open instrument reading.
Fixed (header text + exit-code checking habit); the real probe then
surfaced 5 shape-level defects, all fixed same-day (commit
`055a1834b` lists them). Lesson registered here per fail-closed
doctrine: probe verdicts must check exit codes, not just grep
matches.

## 7. Gates at close

- relsem `lake build` green (in-build Audit: statement gate 31 rows,
  trio cone pins for t1/t2/t3/p01 + UB twins, step_law census 99
  [stateWP 22], sweep 3769, runEffectful no-cone gate, PriorCensus 19).
- Tier A at close: see the close report (test_unit + verify lanes run
  after this record's commit; results quoted verbatim there).
