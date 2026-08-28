# V3a record — mechanism C (probe → package) + loops (component D)

Date: 2026-08-28/29. Worker: V3a (PERF-2 folded into the loops slice;
brief: mechanism C probe-first per `notes/2026-08-28_proof-performance-
plan.md` §3.C/§5 with the review's tightened exit, then component D
loops, exits T5 + P11). Branch `arc/segment-ladder`. Measurements:
serial, capped CERB_MEM_MAX=48G, per-file probes via
`scripts/lean_probe.sh`; logs at the container `.v3a-logs/`.

## 1. PART 1 — the mechanism-C probe: **GO**

Commit `4edc12f47`. WHAT WAS BUILT (probe tranche):

- **RelSem/CStep.lean** — the construct characterization package:
  `cstep_tau` / `cstep_eval` / `cstep_rs_tau`, each the
  function→relation direction of the clocked definitional
  interpreter (functional big-step lineage, Owens–Myreen–Kumar–Tan
  ESOP 2016, cited in-file; Iris-native precedent: HeapLang's
  `PureExec`-class per-construct characterization). Premises = the
  ground DISCOVERY equation (per instance, via the PERF-1
  `seg_discover` kernel-pin device: `Lean.Kernel.whnf`-computed,
  certified as an ordinary hinted `rfl` the kernel re-checks at
  declaration add — no ofReduce*, no transparency steering) + the
  class's semantic payload (the eval verdict, discharged by the
  per-construct `runEU_*`/`se_*` crossings at owned env cells).
  Plus the PROGRAM-BLIND state family `stateAt` (control image ×
  pack → state) and ONE generic control inversion `stateAt_inv`
  (registered famInv) — replacing per-fixture fam/inversion pairs on
  the mint path.
- **SegStepper mint path** (`seg_run_c`): kernel-computes the
  discovery at the open pack, classifies the offered step's
  CONSTRUCTOR (committed choice — every unkeyed shape is a thrown,
  traced frontier, never an iteration), instantiates the construct
  lemma, and assembles the link through the standard premise
  dispatcher. Probe classes: pure-control tau (sequencing binds /
  bound-strips), closed pure-eval (binop/ctor at symbolic values —
  the whole verdict kernel-computes), env-read (1–2 owned cells via
  `runEU_aux2_sym`/`_ctor2`). Births, memory actions, guards,
  call-form convs, terminals fall back LOUDLY to the registered
  supply.

**THE PROBE QUESTION** — does a program-independent construct lemma
replace the generated per-round facts for its class; can the stepper
walk using ONLY construct lemmas + program syntax for the probed
classes? **YES (GO):**

| Measurement (RelSem/CStepProbe.lean, .v3a-logs/probe-run*.log) | Result |
|---|---|
| T1 body walk, mint-first | 8/8 rounds walked: **4 minted**, 4 supply-fallback (2 births, 1 load, 1 call-form conv) |
| P01 walk, mint-first | prefix 10 (7 minted) + then-arm 16 (9 minted) + else-arm 20 (10 minted) |
| Program-independence | the SAME three lemmas fired on T1 AND P01 rounds they were never generated from |
| End-to-end closure | `t1_body`'s and `p01_body`'s EXACT statements + supply codas close over the mint walk (incl. `by_cases` at the symbolic branch; the mint↔supply spelling crossing holds at `seg_done`) |
| Cones | both end-to-end probes exactly {propext, Classical.choice, Quot.sound} |
| Cost | ~0.35–0.6 s per minted round — inside the 0.1–1 s/anchor block-supply band (PERF-1 record §5). Tactic-time A/B per segment: mint 0.48/3.55/5.92/5.64 s vs supply-anchors 0.29/0.58/0.90/1.08 s (≈5×) — the supply's own generation+elaboration (which minting eliminates) is not in the right-hand column |
| GO criterion ("fire on rounds not generated from, ≤ block-supply cost") | **MET** |

Two engine findings fixed en route (both committed): (i)
`stub_defined`'s continuation implicit is not inferrable by `mkAppM`
(conclusion-side unification required); (ii) PERF-1's `ctlArenaKey?`
produced junk keys from mint-spelled successor contexts, wrongly
rejecting defeq cross-vocabulary supply candidates — keys now exist
only for fam-builder spellings (the key filter is an
under-approximation of "cannot match", as it must be).

## 2. PERF-2 TIGHTENED EXIT — PRE-REGISTRATION (written BEFORE any
construct-set extension, per review A1)

- **The never-seen scalar program**: `tests/verify/m1_sgn.c` —

  ```c
  int sgn(int x) {
    if (x < 0) { return -1; }
    if (x > 0) { return 1; }
    return 0;
  }
  ```

  Chosen because: never appears in any corpus/fixture (fresh
  program); contains BRANCHES (`if` — Eif/PEcase guard chains),
  a construct OUTSIDE the probe set {pure-control tau, closed
  pure-eval, env-read}, as the exit demands; three-way return makes
  a 2-branch cut-point structure with re-loads on the later arms.
- **The anchor bound, fixed in advance**: #anchors ≤
  k·(#branches + #loops + #calls + 1) with **k = 2** (the review's
  proposed value, adopted): sgn has 2 branches, 0 loops, 0 calls →
  **≤ 6 anchors**.
- **Anchor definition** (review A1, binding): a generated fact is an
  anchor iff it cites a cut-point reason drawn from the program's
  SYNTAX (branch / loop-head / call / terminal), is stated over V1
  fragments with quantified data values, and contains no ground
  successor state. Everything else must be MINTED — the m1 proof
  requires ZERO generated per-round facts.
- Statement shape: the house guarded-Cns canonical property,
  ∀ x ∈ intRange, outcomes = {Specified (sgn x)} with
  sgnSpec x = if x < 0 then −1 else if x > 0 then 1 else 0.

STATUS: registered here BEFORE the construct-set extension (this
section committed with the extension untouched); the proof lands at
Part 3(c).

## 3. Construct-set extension (GO ramp) — [IN PROGRESS]

What T5/P11/m1 need beyond the probe set (planned, measured against
the walk fallbacks): births (pattern binds — `link_birth1`/`_env1`/
`_env2` mint classes), memory actions in the walk (load/store/create/
kill — `link_load` exists; store/create/kill links to be added over
the existing `wpk_seq_ctl_sup_{alloc,store,kill}` state rules),
label jumps (`Erun` — `cstep_rs_tau`/`cstep_eval` + birth), guard
anchors at path conditions (the by_cases idiom; anchors per §2's
definition).

## 4. PART 2 — loops (component D) — [PENDING]

## 5. PART 3 — exits — [PENDING]
