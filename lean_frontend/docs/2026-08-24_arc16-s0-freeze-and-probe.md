# Arc 16 S0 — the chase freeze gate + the IPM perf probe (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc16-iris-refounding-charter.md`, slice S0 (a) the freeze
gate and (b) the perf probe. Branch `iris-refounding` off mainline
`5014fc4ae`. Companion context: `2026-08-24_chase-era-postmortem.md`.
[AGENT] decisions below are marked as such; measurement numbers are
VERBATIM from the probe logs (single fresh measurement session — an
earlier partial session was interrupted by an operator-side auth
outage; per resumption discipline every number here was re-measured
after it, none quoted from memory).

## 1. The freeze gate (S0a)

`scripts/check_chase_freeze.sh`, wired into `scripts/test_unit.sh` as
one additive line after the proof-size gate. Design:

- **Frozen surfaces**: imports of `RelSem.Tactics.AppWalk` /
  `RelSem.Tactics.WalkTrace` (regex tolerates `public import`), and
  the tactic tokens `app_walk` / `app_walk_norm` / `app_walk_rec` /
  `app_walk_replay` (word-bounded — `app_walk_step`/`app_walk_finish`
  only elaborate under the banned import, so the import check covers
  them).
- **Scan surface**: every `.lean` file that is git-tracked OR
  untracked-but-not-ignored (`git ls-files` + `--others
  --exclude-standard`). [AGENT] This is deliberately STRICTER than
  the proof-size gate's committed-files-only policy: during the
  freeze even session scratch must not grow new chase dependence; a
  new file is caught before it is ever committed. `.lake` trees and
  other ignored artifacts are out of scope.
- **Fail-closed**: a hit outside the allowlist is fatal (file:line
  printed); an empty scan list or git failure is fatal; an
  allowlisted file that has DISAPPEARED is fine (the purge in part 2
  empties the list).

### The legacy allowlist (grep-verified 2026-08-24 — also the purge's work inventory)

Direct importers of `RelSem.Tactics.{AppWalk,WalkTrace}`:

| File | Import |
|------|--------|
| `relsem/RelSemAll.lean` | AppWalk (lib aggregator) |
| `relsem/RelSem/T1AppEq.lean` | AppWalk (round-chain proofs walk-driven) |
| `relsem/RelSem/T5Prefix.lean` | AppWalk (T5 prefix walks) |
| `relsem/RelSem/Tactics/AppWalk.lean` | WalkTrace (the walker itself) |
| `relsem/test/Unit/AppWalkTest.lean` | AppWalk (E1–E10 contract table) |

Tactic-token users beyond those: `relsem/bench/WalkBench.lean`
(`app_walk_rec`/`app_walk_replay`), `relsem/RelSem/Tactics/
AppEqAttr.lean` (docstring mentions ONLY — the `@[app_eq]` law table
itself survives the purge; the charter's primitive-law layer consumes
it), and `relsem/RelSem/Tactics/WalkTrace.lean` (defines them).

**Verified negative** (the brief's expectation list corrected by
grep): `T2AppEq`/`T3AppEq`/`T4AppEq`/`T4Defs`/`T5Fixture`/`T5Iter`
have NO direct chase import and NO tactic token — they consume
T1AppEq's proved lemmas, not the walker. The purge's true direct
surface is the 8 files above.

### Plant transcripts (fresh, post-resumption; verbatim)

Plant 1a — doctored import into a non-allowlisted tracked file:

```
--- PLANT 1a: doctored chase import into non-allowlisted tracked file (T4AppEq.lean)
check_chase_freeze: NEW chase-surface IMPORT in non-allowlisted file:
  lean_frontend/relsem/RelSem/T4AppEq.lean:13:import RelSem.Tactics.AppWalk
check_chase_freeze: FAILED — the chase is FROZEN (arc-16 S0a);
  new proof work goes through the Iris machinery. If a legacy
  file was legitimately renamed, update the allowlist here in
  the same commit (operator-visible).
exit=1
revert verified byte-clean (git diff empty)
```

Plant 1b — brand-new untracked file using a walker tactic token
(exercises the untracked-file path):

```
--- PLANT 1b: NEW untracked file using a walker tactic token
check_chase_freeze: chase tactic surface used in non-allowlisted file:
  lean_frontend/relsem/PlantNewChaseUser.lean:2:example : True := by app_walk_norm
check_chase_freeze: FAILED — the chase is FROZEN (arc-16 S0a);
  ...
exit=1
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
exit-after-revert=0
```

Plant 2 — allowlist-entry removal must go red on the EXISTING
importer (fail-closed direction):

```
--- PLANT 2: remove real allowlist entry (T1AppEq.lean) -> gate must go red on the EXISTING importer
check_chase_freeze: NEW chase-surface IMPORT in non-allowlisted file:
  lean_frontend/relsem/RelSem/T1AppEq.lean:34:import RelSem.Tactics.AppWalk
check_chase_freeze: chase tactic surface used in non-allowlisted file:
  lean_frontend/relsem/RelSem/T1AppEq.lean:782:    mechanical seven through `app_walk` (arc-9 S2 calibration; the
  lean_frontend/relsem/RelSem/T1AppEq.lean:790:  app_walk
  lean_frontend/relsem/RelSem/T1AppEq.lean:792:  app_walk
  lean_frontend/relsem/RelSem/T1AppEq.lean:794:  app_walk
check_chase_freeze: FAILED — the chase is FROZEN (arc-16 S0a);
  ...
exit=1
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
exit-after-restore=0
```

Rebuild-after-revert: the closing `./scripts/test_unit.sh` run (§4)
rebuilds the relsem package from the reverted sources and re-runs the
gate green — the plants left no residue (gate is source-text-only; the
doctored files were reverted byte-clean via `git checkout` before any
build).

## 2. The IPM perf probe (S0b) — methodology

Question (charter S0b): what does iris-lean's proof mode cost at OUR
state sizes? Measurement only; no production code; no design decision
taken here.

- iris pin: `34390a013398` (Lake manifest; 281-module dep). Toolchain
  Lean 4.32.2 (relsem `lean-toolchain`).
- Probes are THROWAWAY SCRATCH in `lean_frontend/relsem/` (deleted
  before commit; this section preserves the content): `ProbeA_
  IpmBasics.lean` (IPM vocabulary on generic-BI + IProp entailments),
  `ProbeB_GenHeap.lean` (GenHeap points-to on a toy heap),
  `ProbeC_<n>.lean` for n ∈ {10,30,100,150,200,250,300,1000}
  (generated by a scratch script `gen_probeC.sh`), `Probe0_
  Baseline.lean` (imports only — the import-load floor), plus
  `ProbeHB150_<hb>.lean` maxHeartbeats-LOWERED variants of n=150
  (lowering is measurement, not a bump; nothing was ever raised).
- Run recipe (per lean_frontend/CLAUDE.md PROBE-RECIPE WARNING —
  workspace-aware `lake lean`, never `lake env lean`):
  `cd lean_frontend/relsem && ../../scripts/capped lake lean <file>`
  under `scripts/ce`; wall time via `date +%s.%N` around the
  invocation; per-file `set_option profiler true` +
  `set_option profiler.threshold 1` (the profiler exposes a dedicated
  cumulative bucket `typeclass inference IPM` — the IPM-specific
  cost, reported below).
- Each ProbeC file contains three shapes over `X : Nat → IProp GF`
  (and `genHeapGS Nat Nat GF (Std.ExtTreeMap Nat · compare)` for the
  heap shape), statements written as flat right-nested `∗`-chains:
  1. `frame_rev_n`: `X 0 ∗ … ∗ X (n-1) ⊢ X (n-1) ∗ … ∗ X 0`, by
     `iintro ⟨H0,…,H(n-1)⟩; iframe` (whole-context framing —
     worst-case matching).
  2. `pick_one_n`: same LHS `⊢ X (n-1)`, by `iintro ⟨…⟩; iexact
     H(n-1)` (context lookup + affine drop).
  3. `heap_rev_n`: `(0 ↦ 0) ∗ … ∗ ((n-1) ↦ (n-1))` reversed, by
     `iintro ⟨…⟩; iframe` (GenHeap points-to framing).
- Default budgets throughout: maxHeartbeats 200000, maxRecDepth 512.
  NO bumps anywhere (heartbeat doctrine); every budget hit below is
  reported as a design input.

## 3. Numbers (verbatim)

Ladder summary (`wall` includes ~1.0–1.1 s import-load floor, see
Probe0; `cumul-IPM-tc` = the profiler's cumulative `typeclass
inference IPM` bucket for the whole file, all three shapes):

```
Probe0_Baseline | exit=0 | wall=1.08s | cumul-elab=0.545ms | cumul-IPM-tc=n/a | errors=0
ProbeA_IpmBasics | exit=0 | wall=1.18s | cumul-elab=19.4ms | cumul-IPM-tc=14.9ms | errors=0
ProbeB_GenHeap | exit=0 | wall=1.22s | cumul-elab=26.4ms | cumul-IPM-tc=29ms | errors=0
ProbeC_10 | exit=0 | wall=1.23s | cumul-elab=48.6ms | cumul-IPM-tc=57.8ms | errors=0
ProbeC_30 | exit=0 | wall=1.54s | cumul-elab=126ms | cumul-IPM-tc=399ms | errors=0
ProbeC_100 | exit=0 | wall=5.10s | cumul-elab=551ms | cumul-IPM-tc=5.15s | errors=0
ProbeC_150 | exit=0 | wall=10.56s | cumul-elab=999ms | cumul-IPM-tc=13s | errors=0
ProbeC_200 | exit=1 | wall=18.28s | cumul-elab=893ms | cumul-IPM-tc=25.9s | errors=2
ProbeC_250 | exit=1 | wall=21.25s | cumul-elab=801ms | cumul-IPM-tc=18.6s | errors=2
ProbeC_300 | exit=1 | wall=1.82s | cumul-elab=542ms | cumul-IPM-tc=n/a | errors=5
ProbeC_1000 | exit=1 | wall=2.00s | cumul-elab=566ms | cumul-IPM-tc=n/a | errors=5
```

Per-decl `elaboration took` lines at the two largest all-green sizes
(two lines per theorem, declaration order frame_rev, pick_one,
heap_rev — note per-decl elaboration stays sub-second even where the
file's IPM typeclass bucket is seconds; the tc work is accounted
separately):

```
== ProbeC_100: 113ms / 72.5ms / 60.1ms / 1.36ms / 209ms / 93.4ms
== ProbeC_150: 171ms / 174ms / 92.9ms / 2.03ms / 317ms / 240ms
```

Failure signatures (verbatim, sorted unique):

```
ProbeC_200.lean:17:2: error: (deterministic) timeout at `isDefEq`, maximum number of heartbeats (200000) has been reached   [frame_rev iframe]
ProbeC_200.lean:27:2: error: (deterministic) timeout at `isDefEq`, maximum number of heartbeats (200000) has been reached   [heap_rev iframe]
ProbeC_250.lean:17:2: error: (deterministic) timeout at `isDefEq`, maximum number of heartbeats (200000) has been reached   [frame_rev iframe]
ProbeC_250.lean:25:3244: error: maximum recursion depth has been reached                                                    [heap_rev STATEMENT]
ProbeC_300.lean:15:1904: error: failed to synthesize (OfNat Nat 251) / maximum recursion depth has been reached             [frame_rev STATEMENT]
ProbeC_300.lean:20:1904: error: failed to synthesize / maximum recursion depth has been reached                             [pick_one STATEMENT]
ProbeC_300.lean:25:3244: error: maximum recursion depth has been reached                                                    [heap_rev STATEMENT]
ProbeC_1000.lean: identical signature to 300 at the SAME columns (15:1904 / 20:1904 / 25:3244)
```

(The `[...]` attributions are derived labels from the generated files'
line numbers; the error text is literal.) `pick_one` PASSES at n=200
and n=250 — only the statements die at 300.

Heartbeat bracket at n=150 (maxHeartbeats LOWERED in scratch
variants; failing lines are the two `iframe`s, shifted +1 by the
inserted set_option):

```
n=150 maxHeartbeats=100000: exit=1  — frame_rev iframe + heap_rev iframe both: (deterministic) timeout at `isDefEq`, maximum number of heartbeats (100000) has been reached
n=150 maxHeartbeats=50000:  exit=1  — same two
n=150 maxHeartbeats=20000:  exit=1  — same two; pick_one still passes
```

So at n=150: `iframe` shapes each cost in (100000, 200000] heartbeats
(they pass only at the 200000 default); `pick_one` costs ≤ 20000.

### The curve and the cliffs

- **Growth**: cumulative IPM-tc 57.8 ms → 399 ms → 5.15 s → 13 s at
  n = 10 → 30 → 100 → 150. Successive ratios 6.9× / 12.9× / 2.5×
  against n-ratios 3× / 3.3× / 1.5× — consistent with roughly
  QUADRATIC cost in context size for whole-context `iframe`;
  `pick_one` (lookup + drop) stays trivially cheap throughout
  (1.36–3.35 ms per-decl at n=100–250).
- **Cliff 1 (heartbeats)**: whole-context `iframe` crosses the
  200000-heartbeat default between n=150 (passes, >100000) and n=200
  (fails), identically for plain atoms and GenHeap points-to.
- **Cliff 2 (recursion, the harder one)**: flat right-nested
  `∗`-chain STATEMENTS die at default maxRecDepth 512 during TERM
  ELABORATION, before any tactic runs — at conjunct ~251 for the
  plain form (same char offset 1904 at n=300 and n=1000: the failure
  depth, not the total length, is what matters) and between 200 and
  250 for the parenthesized `(i ↦ i)` form (deeper per-conjunct
  syntax). Statements of this SHAPE are simply unwritable past ~250
  cells, independent of tactic budgets.

## 4. iris-lean proofmode findings

- **IPM tactic vocabulary** (discovered in `.lake/packages/iris/Iris/
  Iris/ProofMode/Tactics/`, names verified from the elab/syntax
  declarations + exercised examples in `IrisTest/Tactics.lean`):
  `istart istop iintro icases iexact iassumption iapply ispecialize
  ihave iframe isplit isplitl isplitr ileft iright iexists iclear
  icombine irename irevert irewrite iinduction iloeb iinv imod
  imodintro inext ipure ipureintro iintuitionistic ispatial isimp
  ieval iunfold iaccu iempintro iexfalso itrivial` (+ internal
  surfaces `ipm_backtrack`/`ipm_class`/`ipm_tactic_instance`).
  Destructuring intro patterns `⟨H1, …, Hn⟩` (incl. `#H` persistent,
  `%h` pure, `|` disjunction) work n-ary — a 150-ary flat pattern
  elaborates fine.
- **HeapLang wp-tactic template** (`Iris/HeapLang/Tactic.lean` +
  `ProofMode.lean` — the model for S3): `wp_pure wp_pures wp_bind
  wp_lam wp_let wp_seq wp_rec wp_if wp_op wp_load wp_store wp_alloc
  wp_free wp_cmpxchg wp_faa wp_xchg …` (32 surfaces).
- **GenHeap present and usable** (`Iris/BI/Lib/GenHeap.lean`):
  `genHeapGS L V GF H` keyed on `Std.LawfulFiniteMap H L`; `pointsTo`
  with notation `l ↦{dq} v` / `l ↦ v`; `genHeapInterp σ` owns ONE
  authoritative map (`↪●MAP σ`); Fractional/Timeless instances;
  `pointsTo_agree`/`pointsTo_combine` consumed directly in Probe B.
  All Probe A/B exercises succeeded with zero workarounds.
- **Findings/limitations** (reported, not worked around silently):
  1. `#count_heartbeats` DOES NOT EXIST in this toolchain (core Lean
     4.32.2, no Mathlib): `unexpected token '#'; expected command`.
     Heartbeat costs were bracketed by LOWERING maxHeartbeats in
     scratch variants instead; the profiler's `typeclass inference
     IPM` bucket is the primary instrument.
  2. `iassumption` in a GENERIC BI fails with `context is not affine
     or goal is not absorbing` when unused hypotheses remain —
     correct linear-logic semantics, not a defect; it works on IProp
     (affine). Probe A's generic-BI examples reassemble with
     `iframe` instead.
  3. `ipureintro` requires the pure goal to have no spatial premises
     in front (again correct; noted for tactic-authoring in S3).

## 5. What this implies for S2's CerbMem heap RA pricing (flag, not a decision)

At footprint sizes — tens of hypotheses/cells per goal — the IPM is
comfortably cheap: per-goal costs are single-digit-to-low-hundreds of
milliseconds, and GenHeap points-to costs the same as plain atoms.
The pressure is entirely in CONTEXT WIDTH: whole-context `iframe` is
~quadratic and crosses the default heartbeat budget at ~150–200
simultaneous sep-conjuncts, and flat `∗`-chain STATEMENTS become
unwritable at ~250 conjuncts (recursion-depth cliff during term
elaboration — no tactic budget reaches it). FLAG for S2: the CerbMem
state interpretation must follow GenHeap's own shape — one
authoritative map assertion with per-allocation/per-byte `↦`
fragments materialized only for the FOOTPRINT under proof — and must
never surface allocation inventories as flat `∗`-chains in
statements or goals; if typed views or byte-granularity decomposition
ever want >~100 simultaneous points-to facts in one goal, that is a
design smell to meet with aggregation (big-ops over maps), not
budgets. Likewise S3's wp-tactics should frame selectively (named
hypotheses) rather than sweep the whole context once contexts grow.
These are observations for the S2/S3 designers; no design is decided
here.

## 6. Validation

- `./scripts/test_unit.sh` (full, with the new gate wired): `Total: 7
  passed, 0 failed`, and the gate's line verbatim:
  `check_chase_freeze: OK — no chase-surface imports/uses outside the
  legacy allowlist (8/8 allowlisted files present)` — exit 0.
- Both plant tests demonstrated (§1 transcripts).
- Probe scratch (`Probe*.lean`, `gen_probeC.sh`, `.probe-logs/`)
  deleted before commit; this record preserves the content.
- No new axioms/sorries; no heartbeat/maxRecDepth raises anywhere;
  full battery not run — [AGENT, per worker brief] no shared-surface
  changes beyond the one test_unit.sh line + the new script.
