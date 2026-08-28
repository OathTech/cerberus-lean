# V3a record — mechanism C (probe → package) + loops (component D)

Date: 2026-08-28/29. Worker: V3a (PERF-2 folded into the loops slice;
brief: mechanism C probe-first per `notes/2026-08-28_proof-performance-
plan.md` §3.C/§5 with the review's tightened exit, then component D
loops, exits T5 + P11). Branch `arc/segment-ladder`, commits
`4edc12f47..` (this slice). Measurements: serial, capped
CERB_MEM_MAX=48G (16G for isolated probes), per-file probes via
`scripts/lean_probe.sh`; logs at the container `.v3a-logs/`.

STATUS AT CLOSE: Part 1 **GO, landed and extended well beyond the
probe scope**; component D's once-proved loop rules **landed**; the
pre-registered exit program's walk runs **all-minted to the branch**;
T5/P11 **PARKED** at a precisely priced frontier (§6) — no wall of a
new KIND was hit; what remains is enumerated construction, not
mystery.

## 1. PART 1 — the mechanism-C probe: **GO**

Commit `4edc12f47`. WHAT WAS BUILT (probe tranche):

- **RelSem/CStep.lean** — the construct characterization package:
  `cstep_tau` / `cstep_eval` / `cstep_rs_tau`, each the
  function→relation direction of the clocked definitional
  interpreter (functional big-step lineage, Owens–Myreen–Kumar–Tan
  ESOP 2016, cited in-file; Iris-native precedent: HeapLang's
  `PureExec`-class per-construct step characterization). Premises =
  the ground DISCOVERY equation (per instance, via the PERF-1
  `seg_discover` kernel-pin device: `Lean.Kernel.whnf`-computed,
  certified as an ordinary hinted `rfl` the kernel re-checks at
  declaration add — no ofReduce*, no transparency steering) + the
  class's semantic payload (the eval verdict, discharged by the
  per-construct `runEU_*`/`se_*` crossings at owned env cells).
  Plus the PROGRAM-BLIND state family `stateAt` (control image ×
  pack → state) and ONE generic control inversion `stateAt_inv`
  (registered famInv) — replacing per-fixture fam/inversion pairs on
  the mint path.
- **The stepper mint path** (`seg_run_c`): kernel-computes the
  discovery at the open pack, classifies the offered step's
  CONSTRUCTOR (committed choice — every unkeyed shape is a thrown,
  traced frontier, never an iteration), instantiates the construct
  lemma, and assembles the link through the standard premise
  dispatcher.

**THE PROBE QUESTION** — does a program-independent construct lemma
replace the generated per-round facts for its class; can the stepper
walk using ONLY construct lemmas + program syntax for the probed
classes? **YES (GO):**

| Measurement (probe files + .v3a-logs/probe-run*.log) | Result |
|---|---|
| Probe classes (pure-control tau, closed pure-eval, env-read 1–2 cells) | fire via the stepper on T1 AND P01 rounds they were never generated from |
| End-to-end closure | `t1_body`'s and `p01_body`'s EXACT statements + supply codas close over the mint walk (incl. `by_cases` at the symbolic branch) |
| Cones | end-to-end probes exactly {propext, Classical.choice, Quot.sound} |
| Cost (probe tranche) | ~0.35–0.6 s per minted round — inside the 0.1–1 s/anchor block-supply band (PERF-1 §5); mint 0.48/3.55/5.92/5.64 s per segment vs 0.29/0.58/0.90/1.08 s consuming pre-elaborated anchors (the supply's own generation+elaboration, which minting removes, is not in the right column) |
| GO criterion ("fire on rounds not generated from, ≤ block-supply cost") | **MET** |

## 2. PERF-2 TIGHTENED EXIT — PRE-REGISTRATION (committed BEFORE any
construct-set extension, per review A1; commit `f2d7d42b1`)

- **The never-seen scalar program**: `tests/verify/m1_sgn.c` —

  ```c
  int sgn(int x) {
    if (x < 0) { return -1; }
    if (x > 0) { return 1; }
    return 0;
  }
  ```

  never appears in any corpus/fixture; contains BRANCHES — outside
  the probe set, as the exit demands.
- **Anchor bound, fixed in advance**: #anchors ≤
  k·(#branches + #loops + #calls + 1) with **k = 2** → sgn: **≤ 6**.
- Anchor definition (review A1) restated in §2 of the committed
  pre-registration; the m1 proof must use ZERO generated per-round
  facts.
- EXIT STATUS AT CLOSE: fixture + statement + protocol + walk landed
  (§4); the walk reaches the branch ALL-MINTED; the ≤ 6 path-
  conditioned guard anchors and the arm/terminal assembly are the
  priced remainder (§6). The exit is NOT claimed.

## 3. The GO ramp — construct-set extension (commits `adcf5e34a`,
`cb8c3da90`)

- **BIRTH classes** (pattern binds; 1–2 fresh locals; with/without a
  cell read → link_birth1/_env1/_birth2), minted by committed
  env-shape classification preserving the ins/fmapAddBy spelling.
- **LOAD class** (ACTION[LoadRequest]): request draw kernel-pinned (a
  return — state-preserving), perform composed through the
  loc-generic int-load block (`intLoad_facts_loc`) at `link_load`'s
  own footprint premises.
- **Three engineering findings, each measured, fixed, and now
  doctrine for this engine:**
  1. **The kernel-evaluation guard** (the r127 lesson at the mint
     path): `Lean.Kernel.whnf` is unbounded and uninterruptible; an
     eval ENTRY whose redex cases on symbolic data (guard/conv/case
     chains) runs the interpreter's fuel loop away (measured 16–48G
     OOM at P01's verdict round). The atomic unit's redex is
     classified BEFORE any kernel or unfold attempt (safe PE* set =
     {PEsym, PEval, PEctor, PEop}); constructor-headed RESULT units
     are exempt (program syntax as DATA is harmless); unsafe entries
     are an immediate loud fallback, never single-stepped.
  2. **Flattened successors**: a minted successor spelled
     `ctlOf (dnmsBump … (stateAt cPrev …))` makes every later
     computation re-reduce the walk's whole chain from round 0
     (measured OOM). Each minted control image is flattened to a
     record literal (pure whnf/committed unfolds — defeq-preserving,
     work bounded by program size — the generated supply's own
     normal form). One residual: the flatten still leaves some
     projection nests (noted; costs currently fine).
  3. **Named states** (the S3 giant-terms ruling applied mid-walk):
     each flat image becomes an fvar-closed, uncompiled AUXILIARY
     DEFINITION (`<theorem>.segCtl_i_j`); goals and chains carry
     small constants; whnf caching keys on them. The compaction's
     "already small" test initially treated `ctlOf (giant)` as small
     (1-arg const app) so it never ran — the measured chain-growth
     hole, closed.
- MEASURED after extension: T1 7/8 rounds minted (only the call-form
  conv rides supply); P01 26/46 (guards/convs from supply); both
  end-to-end at 16G, trio cones (.v3a-logs/probe-t1-load7,
  probe-p01-load).

## 4. m1_sgn — fixture, protocol, the all-minted walk (commit
`63be552f9`)

- Fixture through the slate pipeline (emit plan row; SlateCore
  regenerated; m1File; PriorCensus-validated m1Prior — 20 pins;
  oracle .core pinned; 4 oracle-differential harness points on the
  TEST ledger — test_verify 118/118).
- RelSem/M1Proof.lean: M1Statement (house Cns canonical shape,
  fuel-opsem-only), the FULL callND caller protocol at m1File —
  with the entry arena and parameter symbol BY PROJECTION from the
  emitted decl (zero hand transcription; the P01-era transcription
  burden is gone), `m1_wp` parameterized over the body obligation.
- **THE WALK: m1's body walks 8/8 rounds ALL MINTED — zero generated
  per-round facts, zero supply — to the first guard** (the branch
  cut point), where it stops with the honest branch message. The
  walk-persisted named states (`…segCtl_1_1..1_8`, functions of x)
  are exactly the spellings the guard anchors will be stated at —
  the anchor-spelling problem is SOLVED by the walk itself.

## 5. PART 2 — loops (component D): the once-proved rules LANDED
(commit `cb8c3da90`)

- **RelSem/SegLoop.lean**: `SegStep.iter` / `SegStep.iter_from` —
  the VALUE-CARRYING invariant iteration at the round-exact segment
  sequent (`St : Nat → Ctx`, the declared invariant family; never a
  walk-endpoint readback — the professor's improvement 2); lineage
  Floyd–Hoare, BRiCk `wp_while_inv`, RefinedC `typed_block`,
  mirroring the once-proved `Seg.iter`/`Seg.while_inv` (R2) on the
  V1/V2 substrate.
- **THE VARIANT RULE's mathematical core**: `first_exit` — a value
  family whose Nat measure strictly decreases under the (decidable)
  guard reaches a FIRST guard-false index (Dijkstra bound functions;
  total-correctness while; the F2c gap P11 forces). The ∃-trip-count
  is DERIVED from descent; the loop then discharges through
  `SegStep.iter` at that index. P11's instance (μ = b.natAbs,
  step = (b, a % b)) is a direct application.

## 6. T5 + P11 — PARKED, priced (the park record; no new-KIND wall)

Neither proof exists; neither statement moved (both FROZEN, still
honest-UNPROVED). The park is a construction frontier, not a
falsification: every remaining item is an enumerated instance of
machinery this slice landed or its direct sibling.

| Remaining item | For | Price | Notes |
|---|---|---|---|
| Guard-anchor machinery (path-conditioned rounds: the conv-compare chains at symbolic data under `by_cases` hypotheses) | m1, T5, P11 | M-S | The P01Rounds/P02Guard sub-eval chain pattern, stated at the walk-persisted `segCtl` names; kernel evaluation is IMPOSSIBLE here by measurement (fuel runaway at symbolic guards) — hypothesis-fed laws are the only route, as the P02 hard rounds already established. m1 needs ≤ 6; T5/P11 need the ∀-iteration-quantified analogues |
| Arm walks + terminal codas at mint spelling | m1 | S | seg_run_c after by_cases (the P01 pattern); seg_done at stateAt/stateAt_inv |
| link_store / link_create / link_kill | T5, P11 | M | Iris plumbing over the EXISTING wpk_seq_ctl_sup_{store,alloc,kill} state rules, mirroring link_load |
| store/create mint classes | T5, P11 | M | the tryMintLoad pattern at the other request ctors |
| The NEG-transform round class (fresh excluded/sym draws — supply-bumping links) | T5 | M | a supply-bumping link variant + eval-mint allowing rs' supply deltas; T5's loop body stores are NEG-wrapped |
| Loop assembly: value-carrying St, body segment ∀ i by seg_run_c, fall-in vs stored spelling at the loop head ([F3]) | T5, P11 | S-M | rides SegStep.iter/iter_from + the walk; fuel arithmetic at symbolic n by omega through SegStep.consume's hF |
| The %-conv chain at b ≠ 0 | P11 | S-M | the checked-op hand-chain class (P02's catch_exceptional pattern) |
| first_exit instance (b.natAbs decrease) | P11 | S | landed rule, direct application |

Honest hazards on the T5 path (anticipated, not measured): the NEG
rounds draw fresh symbols at open supplies (the arc-16 spike's
threading territory); the loop-head twin spelling is the C3b
measured seam (the [F3] normalizer design exists at the Seg level).

## 7. Timing lane (this slice's numbers)

| Item | Number |
|---|---|
| T1 probe file (3 theorems: mint walk + supply walk + end-to-end), 16G | ~13–23 s |
| P01 mint end-to-end file, 16G | 14–32 s (runs varied with engine iterations) |
| P01 supply baseline file, 16G | ~4 s |
| m1 walk probe file (protocol closure imports + 8-round all-mint walk) | ~30 s class |
| Full relsem package build (in-build gates incl. audits) | green, ~80–150 s class throughout |
| Census motion | step_law 483→487 (construct 9→12, famInv 6→7); audit sweep 4965→5056; PriorCensus pins 19→20 |
| Cones | every probe/end-to-end theorem exactly {propext, Classical.choice, Quot.sound} |

## 8. Catechism self-check (§VI, at close)

1. ∀-statements served: the construct lemmas are strictly MORE
   quantified than the round facts they replace; m1/T5/P11
   statements are full-range canonical properties.
2. Amortization: the same three cstep lemmas + crossings walked T1,
   P01, and m1 — the next program pays its syntax walk only.
3. Names: functional big-step (OMKT), PureExec, Floyd–Hoare,
   Dijkstra bound functions, derive_state/named-states, committed
   choice, opacity-bounded failure — all cited in-file.
4. The professor: the m1 proof shape is protocol → minted walk →
   by_cases → anchors → readout; the walks are engine-room.
5. No enumeration: minting is per-construct; the kernel guard
   explicitly REFUSES to grind symbolic guards.
6. Failures loud: every mint skip is a traced, classified fallback;
   the walk stops AT cut points by construction.
7. Trust surface: unchanged — no new axioms, statements fuel-opsem
   only, kernel re-checks every pinned equation.
