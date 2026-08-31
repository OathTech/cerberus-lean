# C1 adoption slice record — effect retirement (STOPPED-AND-REPORTED at the rebaseline)

Date: 2026-08-31/09-01. Branch `arc/effect-retirement`, worktree
`worktrees/cerberus-lean-arc/effect-retirement`, base `64dd6efeb`
(charter R3.1). Worker: C1. Provenance [AGENT] throughout unless
marked; quoted outputs verbatim; derived tallies labeled.

**Disposition up front.** Steps 0-2 (pin materialization,
accommodations, adoption) are DONE and committed green; the per-slice
gate items that stand independent of the pins are DISCHARGED (b, O7,
the fuel decision, the axiom spot census, the S0 base-drift re-scan);
the change manifest is shipped. **Step 4 (the one-time adjudicated
rebaseline) is STOPPED-AND-REPORTED on finding C1-F1**: the measured
oracle renumbering reaches artifacts OUTSIDE the S0 row enumeration —
including `tests/verify` pins, which O6(v) declares a finding, never a
rebaseline — so per the brief's named stop conditions the per-family
instrument commits and the close-out battery are NOT executed pending
operator adjudication. No baseline or pin was modified.

## 1. Commits (each green at its boundary)

| Step | Commit | Content |
|---|---|---|
| 0 | `90c82505d` | lem pin materialization: LemLib → `af5df71` (lakefile rev + both lake manifests) |
| 1+2 | `61170b4c8` | model accommodations + adoption (the .lem m1/m1b/m2/S1/tagDefs/debug changes, hand-written Lean, gates, fork-drift manifest re-pin) |
| 3/5 | (this record's commit) | S0 re-scan record + change manifest + this record |

Pin state at close: `deps/lem-pinned` @ `af5df71` (reset from
`861ed81`; the shared opam switch's lem rebuilt — [AGENT]-sanctioned
in-arc shared-state mutation per the brief; RESTORE EXPECTATION: the
arc-close pin dance re-points deps/lem-pinned and the switch to the
merged lem head). Lake pins: `lean_frontend/lake-manifest.json` and
`speclab/lake-manifest.json` both at `af5df7116525…`.

## 2. Step 0 — pin bump alone (green)

- OCaml generated tree: cleaned + re-derived under lem `af5df71` —
  byte-identical (`diff -qr` exit 0; sibylfs likewise). §6.4 layer 1
  holds. (First attempt was a make no-op — the byte-compare was rerun
  after `clean-prelude-src`, fail-closed.)
- Lean generated tree: exactly ONE hunk —
  `Core_linking.lean:89` `setChoose s` → `setChoose setElemCompare s`
  (L0 M4). Zero tuple-let sites in this tree. Within the briefed
  expected class.
- Full lake build green (367 jobs, capped 32G); `test_unit.sh` full
  pass at the bump (verbatim tail in commit `90c82505d`'s message).

## 3. Steps 1-2 — accommodations + adoption (green)

Content per commit `61170b4c8`'s message (the authoritative list).
Key measured facts:

- Applied `runEffectful` sites in `generated/`: **0** (S0: 9).
- Supply-lifted generated set: exactly 10 defs, all `Fun_def`s
  (`Symbol.fresh*` ×8, `initial_core_run_state`,
  `initial_driver_state`).
- Generated-OCaml text moved in exactly the 9 accommodated modules;
  `mem.ml` (the reader_consumer declares) is OCaml-invariant.
- Oracle behavior probe (verbatim class signature): two-`while` TU —
  pre-C1 (S0 record §1) `while_517`/`while_519` adjacent (eager
  batch); post-C1 `ret_512 … while_518 … while_541` (dispersed to
  source order); exec verdict unmoved (`Specified(2)` both sides).
- One G-λ guard firing during bring-up (`Symbol.fresh_fancy`'s
  `function` sugar) — resolved by eta-expansion; the guard behaved
  exactly as specified (fail-closed, named site).
- `test_unit.sh` FULL GREEN at `61170b4c8` including the re-pinned
  fork-drift gate (verbatim):
  `check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)`

## 4. O2 base-drift duty: the S0 re-scan (gate item e)

The branch never rebased (merge-base with mainline = `58ec50779`, the
S0 base). The scanner was nevertheless re-run at the C1 tree over the
identical 102-file corpus (same detectors, the accommodated oracle —
the scan reads desugared structure, insensitive to numbering):

    diff <(sort docs/2026-08-31_S0-scan-results.tsv) <(sort rescan) → identical
    S0-RESCAN-IDENTICAL

No corpus growth; the enumeration's INPUT set stands unchanged. (The
finding below is about the DETECTORS' coverage, not the input set.)

## 5. FINDING C1-F1 — the movement class exceeds the S0 row enumeration (STOP trigger)

Running `test_verify.sh` at `61170b4c8` (the Step-4(v) tripwire):

    test_verify: 90 passed, 27 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)

ALL 27 failures are **pin-provenance** rows (the pinned oracle Core
dumps differ from a fresh derivation); **zero** main-mode or
call-point differential failures — oracle-vs-Lean behavior agrees
everywhere.

Moved artifacts (derived from the FAIL rows):

- `tests/verify` (**expected UNMOVED — the finding**): 7 pins —
  c3a_accguard, c4_hexval, c5_pcthi, m1_sgn, t2_add, t5_sum,
  t6_branch. (S0 predicted all verify pins clean, D1=D2=0. Note the
  S0 record's aside that t5_sum "has no .core pin" is also wrong —
  it has one, and it moved.)
- `tests/corpus`: 13 families moved — the 7 S0-predicted
  (p04-p08, p14, p15) **plus 6 outside the enumeration**: p02_sat_add,
  p03_swap_mayalias, p09_call_contract, p10_gcd_rec, p11_gcd_iter,
  p12_pt_midpoint. Unmoved: p01_clamp, p10alt_rsum_rec, p13_cell_alloc.
- `tests/libc/libc.core` content hash: moved (S0-predicted;
  `libc_prep.sh` refuses — surfaced in the immaculate lane's libc leg).
- speclab dumps: not re-derived (stopped before family (i)); the S0
  prediction (34/39) is presumed a floor by the same mechanism.

**Characterization (measured, not guessed).** The movement is pure
RENUMBERING: same draw count (c4_hexval: 144 distinct ids in both
pinned and fresh dumps), identical structure, ids permuted. The
mechanism is the SAME S0-F1 eager-batch dispersal, at syntactic
positions the D1/D2 detectors did not model. The clean witness is
`t2_add` (one call, two args, no loops, no const):

    <           let strong a_517: pointer =      (pinned: first funarg temp = 517)
    >           let strong a_516: pointer =      (fresh:  first funarg temp = 516)
    ...
    <             ccall(…, a_511, a_517, a_516)
    >             ccall(…, a_511, a_516, a_517)

Pre-C1 the funarg mints (`translation.lem:876`, the `mapi` batch) drew
in the generated OCaml's `List.map` cons order — RIGHT-TO-LEFT — so a
2-argument call minted (arg1, arg0); post-m1 the monadic map draws in
LIST order (arg0, arg1). The within-batch REVERSAL of every eager
batch (exactly S0 §1's "the construct batch fires in REVERSE statement
order" phenomenon) applies to call-argument batches, bind-head
`wrapped_fresh_symbol` prefixes under eager HOFs, and cross-definition
elaboration prefixes — none of which the D1/D2 detectors counted (they
were calibrated on `while`/`do` STATEMENT batching only). The charter's
§8.1 row for :876 ("batch stays contiguous; list order kept") is true
of the batch's position and list order but the PRE-transform draw
order was reverse-list, so the site moves anyway.

**Why this is a stop, verbatim from the brief:** "tests/verify
EXPECTED UNMOVED — any movement there is a FINDING, stop-and-report";
"a moved artifact NOT in the S0 list (post base-drift re-scan) =
finding, stop-and-report". Both fired. The movement is conceptually
inside the Q1b-TOLERATED class (same-count renumbering from eager-batch
dispersal, zero verdict movement anywhere), but the one-time
adjudicated rebaseline's ROW BASIS (the S0 measurement) is proven
incomplete, and re-scoping that basis — including whether the verify
pins rebaseline or the O6(v) clause is re-ruled — is an OPERATOR
decision, not a worker call. No pin was touched.

**What adjudication needs (proposed, [AGENT]):** extend the
enumeration from "S0 D1/D2 rows" to "every pinned oracle dump that
moves under re-derivation, each verified same-draw-count/
permutation-only" (the two checks above are mechanical), then execute
the O6 per-family procedure over that verified set — verify pins
included if the O6(v) clause is re-ruled to match the corrected class.

## 6. Gate items

- **(a) order-sensitive observables** — PARTIAL (the pin-independent
  legs): multi-TU link lane green (`multitu=0`, all corpus entries);
  exhaustive-mode verdict sets agree oracle-vs-Lean in every
  differential run (the 90 passing test_verify rows include all
  main-mode + call-point comparisons; exec lanes below); the bytes
  lane (oracle-INDEPENDENT committed expecteds) green — Lean behavior
  itself is unmoved. Two-source separation (renumbering vs L0
  `setChoose`): the setChoose change is Lean-side only and landed
  ALONE at Step 0 with test_unit green; at HEAD every verdict lane
  (incl. multi-TU and elab signature-dump) is at baseline, so
  neither source produces an order-dependent OUTPUT change in any
  gated lane. The dump-level topo_order permutation review over the
  rebaselined artifacts is BLOCKED with the rebaseline. No
  numbering-beyond-binding output dependency was observed in any
  gated lane (nothing to register under the §9 principle so far).
- **(b) Let_def-value cone check** — PASS: supply-lifted set = 10
  defs, all function defs; zero `lemLetRhs_*` in `generated/`.
- **(c) upstream-divergence enumeration** — SHIPPED (first cut): the
  fork-drift manifest header now carries the C1 note enumerating the
  9 text-moved modules + the renumbering-class statement; VALIDATION.md
  finalization deferred to C2 per the charter (and now also pending
  the C1-F1 adjudication which fixes the class's artifact scope).
- **(d) fuel budget-sizing decision** — DECIDED: RECORD-AND-DEFER.
  Sizing: 10^8 on the whole coupled family (driver quartet + nd_bind
  + CerbND.ndDefaultFuel), justified against the stack-ceiling note's
  coupling analysis (§4: raising one member is vacuous) and its
  derived grind-horizon edge (§6b: 10^8 ≈ 7-50 min loud edge; 10^9+
  is past it). Application deferred because the apply-condition fails
  in the improving direction: zero fuel-exhaustion rows exist in any
  lane baseline (measured — grep over every baseline/expectations
  file), so application moves no lane row oracle-ward while re-stating
  the consumer's exported `lemDefaultFuel` side conditions. Full
  statement: change manifest §8.
- **(e) O7/O1 + S0 re-scan** — O7 DISCHARGED: the arc diffs contain
  4 `+`/4 `-` paired `nd_bind` lines (argument-only edits); zero new
  ND node/branch-builder applications in the migrated cone. O1 is
  lem-side (L1, pinned; MAJOR-1 fixed at `4bff8b7`) — unchanged here.
  S0 re-scan: §4 above (identical).
- Axiom spot census (the §1.3 entry set), verbatim:

      'driver2' depends on axioms: [propext, Classical.choice, Quot.sound]
      'drive' depends on axioms: [propext, Classical.choice, Quot.sound]
      'initial_driver_state' depends on axioms: [propext, Classical.choice, Quot.sound]
      'desugar' depends on axioms: [propext, Classical.choice, Quot.sound]
      'annotate_program' depends on axioms: [propext, Classical.choice, Quot.sound]
      'translate' depends on axioms: [propext, Classical.choice, Quot.sound]
      'convert_file' depends on axioms: [propext, Classical.choice, Quot.sound]
      'link' depends on axioms: [propext, Classical.choice, Quot.sound]

  The two S0-dirty entries (`initial_driver_state`, `translate`) are
  clean. (`RelSem.Cerb.callND` was clean at S0 and its cone only
  gained the supply parameter; not re-probed here.)

## 7. Lane scoreboard at `61170b4c8` (verbatim exits; run under capped/ce)

| Lane | Exit | Note |
|---|---|---|
| `test_unit.sh` | 0 | full gate set incl. re-pinned fork-drift |
| `test_exec.sh --check-baseline` (minimal) | 0 | `BASELINE OK` |
| coverage baseline | 0 | `Baseline check: 0 regression(s), 0 improvement(s)` |
| debug baseline | 0 | same |
| float baseline | 0 | |
| `test_bytes.sh` | 0 | oracle-independent committed expecteds |
| `test_multi_tu.sh` | 0 | link-order observable green |
| `test_gcc_oracle.sh` | 0 | `SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 …` — **baseline UNMOVED** (as briefed: never sees symbol numbers) |
| `test_parse.sh` | 0 | ALL PASSED |
| `test_core.sh` | 0 | ALL PASSED |
| `test_elab.sh` | 0 | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` (recorded state) |
| `test_immaculate.sh` | 1 | 21/21 comparison rows MATCH incl. the union-arm witness `MATCH offsetof-union-member O[CRASH] L[CRASH]` (risk R5 green); the libc leg fail-stops at `libc_prep.sh --jsons` on the MOVED libc.core pin — rebaseline family (iii), blocked by the stop |
| `test_verify.sh` | 1 | §5 — the finding (all failures pin-provenance; 0 behavioral) |
| speclab gates, libc_exec, libxml2 lanes, csmith shards | not run | consume moved pins / Tier B-C close-out — blocked behind the C1-F1 adjudication |

## 8. Blocked / remaining work (post-adjudication)

1. Step 4 per-family instrument commits (speclab dumps + SpecLab
   re-emission; corpus pins + fixture-freeze manifest; libc.core hash;
   goldens; verify pins IF re-ruled) over the corrected enumeration.
2. Gate (a) dump-level permutation review at the rebaselined
   artifacts; VALIDATION.md divergence text (with C2).
3. Close-out FULL battery (Tier A+B+C incl. libxml2, csmith) on fresh
   stamped binaries.
4. C2 consumes: `scripts/unsafebaseio_allowlist.txt` still lists the
   now-DELETED CerbTags ×4 / CerbDebug ×2 rows (S0 wrote it as the
   C2 ratchet input; shrinking it is C2's job with the ratchet).

## 9. Ephemera

`.c1-scratch/` (container scratch: pre/post generated-tree snapshots,
build/lane logs, probe TUs, the re-scan TSV) is ephemeral and deleted
at slice end; every load-bearing output is quoted verbatim above or
committed (the re-scan equality is reproducible from the committed
scanner + TSV).
