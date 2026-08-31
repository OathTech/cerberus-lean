# Effect-retirement S0 record: order-movement corpus scan + survivor allowlist

Date: 2026-08-31. Branch `arc/effect-retirement` (charter:
`2026-08-31_effect-retirement-design.md` @ 913ee31d1; base mainline
`58ec50779`). Slice: S0 per charter §8.1 — measurement and
enumeration only; no semantics, gate, lane, or baseline changed.
Provenance: [AGENT] throughout unless marked; quoted outputs are
verbatim; derived tallies are labeled derived.

Deliverables in this commit:

- `scripts/s0_order_scan.py` — the Q1b scanner (§2 below; calibration
  probes recorded in §1-§2).
- `lean_frontend/docs/2026-08-31_S0-scan-results.tsv` — raw scan rows
  (102 files, the symbol-visible-pin corpora).
- `scripts/unsafebaseio_allowlist.txt` — the §7.2 ratchet input
  (Q4 inventory, finalized; §4 below).
- This record.

**Bottom line first:** the Q1b verdict is **NONTRIVIAL** (§3.4) — 25
pinned speclab Core dumps trigger even the charter's NARROW movement
pattern, so per the Q1b ruling the tolerated route escalates to the
staged pre-slice decision. AND the scan surfaced a design-level
finding (**S0-F1**, §1) that the movement class is strictly BROADER
than the charter's single site — the charter's §3.6 non-decoupler
claim for `mapM` is false — which reaches past Q1b into the O2/§3.6
adjacency analysis itself. Both are operator decision points before
C1 is briefed.

## 1. Finding S0-F1: the movement class is broader than the charter's one site

**Claim being tested** (charter §3.6, "Non-decouplers checked"):
"`mapM`/`foldlM` construct their per-element computations during
their own run (lambda applications) — adjacent", leaving
`with_block_objects`' const-alias mint as the ONE moved site.

**The claim is false for `E.mapM self ss`** — the elaboration of
every multi-statement block (`translation.lem:3714`,
`A.AilSblock binds ss → E.with_block_objects decls (E.mapM self ss)`).
`mapM` is `mapM f = listM (List.map f)`
(`frontend/model/state.lem:58-59`): the `List.map` applies `self` to
EVERY statement eagerly, so every statement's construct-time
(arm-prefix / bind-head) draws fire in one batch at block
CONSTRUCTION, decoupled from each statement's run. Monadification
(m1) maps all draws to run order, so the batch disperses — movement
with **no const declaration anywhere**.

Empirical witness (verbatim; oracle @ this tree,
`./scripts/cerberus --nolibc --pp=core` on a two-while `main`,
symbols extracted and sorted by draw id):

```
512 ret_512
513 continue_513
514 break_514
515 continue_515
516 break_516
517 while_517
518 a_518
519 while_519
520 a_520
521 a_521
```

Reading: `ret` + the erase-pass `continue/break` mints (both loops,
contiguous), then the CONSTRUCT batch — while#1's `sym_loop` (517) and
`do_loop_wrp` head (518), while#2's pair (519, 520) — then the
run-phase draws (521+). Sequential (post-m1) elaboration would place
all of while#1's run draws (test/case wrappers, expression
temporaries — a dozen-plus ids) between 518 and while#2's `sym_loop`;
the gap of exactly 2 is the eager-batch signature. Post-m1 the
oracle's dump renumbers (`while_519` becomes `while_~531`).

Further calibration probes (same method, one variant per statement
form; full C sources reproducible from §2's rules — derived summary):

- Expression, assignment, call, `if`, `return`, and cast statements
  contribute ZERO construct-time draws (the `while` id is invariant
  when they are prepended). Declarations shift ids by their DESUGAR
  draw only.
- `do` contributes construct-time draws (its `sym_loop`/`sym_case`/
  `sym_e` prefix); `switch`'s case/default mints fire at RUN
  (charter's classification of :3954-3955 confirmed).
- Plain nested blocks are TRANSPARENT (their whiles join the outer
  construct batch); blocks under `if`/`while`/`do`/`switch` are
  BARRIERS (constructed at their parent's run — adjacent).
- The construct batch fires in REVERSE statement order (lem's
  generated OCaml evaluates the `List.map` cons right-to-left; a
  source-first `do` drew AFTER a source-second `while`), and
  top-level definitions elaborate in reverse order too — so post-m1
  source-order sequencing reorders even single-E-statement regions
  relative to each other.
- The const-alias mint itself (charter's site): CONFIRMED — a
  const-qualified scalar, array, or `* const` pointer block object
  consumes one run-time draw; pointee-const (`const T *p`) does NOT
  (matches `qs.Ctype.const` on the bind).

**Consequence.** The O2 adjacency obligation fails not at 1 site but
at every eager-`mapM`/eager-HOF construction whose element
computations have construct-time draws — i.e., every block statement
list containing a non-initial `while`/`do` (and sibling/exterior
reorderings besides). The charter's "18 of 19 sites preserved" is a
correct per-STATIC-site table but the per-CALL-position adjacency
argument behind rows :3800/:3836-3838 (and the §3.6 non-decoupler
paragraph) does not hold in eager list positions. Q1b's premise
("the one order-moved site") therefore under-scopes the oracle
renumbering that m1 will cause. This is a stop-and-report charter
conflict: the [AGENT] S0 worker reports it; re-scoping O2/Q1b (or a
draw-order-preserving redesign of m1, e.g. explicit construct-time
pre-minting mirroring today's two-phase order) is an OPERATOR
decision, not taken here.

## 2. The Q1b scanner (`scripts/s0_order_scan.py`)

Method: run the ORACLE's own post-desugar print (`--pp=ail`) per TU
and analyze block structure. Ail pp is typedef-resolved and
macro-expanded (raw-C scanning would UNDERapproximate via
typedef/macro-carried `const` — forbidden), prints `for` already
lowered to block+while, and hoists static locals (which do not mint).

Detectors, per eager region (function body or control-substatement
block, extended through plain nested blocks):

- **D1 (charter-narrow trigger, Q1b as ruled):** ≥1 const-qualified
  OBJECT declaration (scalar/array/`* const`; pointee-const excluded
  — calibration-matched to the mint condition) co-resident with ≥1
  `while`/`do`.
- **D2 (witnessed lower bound of the S0-F1 broader class):** ≥1
  `while`/`do` preceded by any other statement in its region, or ≥2
  loops in one region.

Precision (honest, per the S0 charge): D1/D2 overapproximate (no
relative-position check inside a region; `*const` may hit inner
pointer levels; strings containing `while (` could count).
Underapproximation guards: analysis on the oracle's own desugared
output; cpp runs with `-P` because the Ail printer SUPPRESSES
definitions whose declarations originate in `#include`d files
(discovered on `runtime/libc/src/ctype.c` — 15 functions silently
dropped without `-P`; with `-P` all tokens are main-file-local and
nothing is dropped). Failures are loud (`ERROR` rows), never skipped.
Validation: the scanner reproduces every §1 calibration ground truth
(constwhile D1=1; twowhile D1=0/D2=1; nested-if barrier vs
nested-block transparency; the 4-const declaration matrix).

## 3. Q1b scan results

### 3.1 Symbol-visible pinned-artifact corpora (the load-bearing set; 102 files, full rows in the .tsv)

| corpus (files) | D1 hits | D2 hits | notes |
|---|---|---|---|
| `lean_frontend/corpus` (16) | 0 | 7 | p04, p05, p06, p07, p08, p14, p15 |
| `tests/verify` (23) | 0 | 1 | t5_sum (has no .core pin; the 5 pinned dumps c3a/c3b/c4/c5/c9 are all D1=0, D2=0) |
| `tests/speclab` (39) | **25** | 34 | applist×7, getarr×3, lookup×5, memcpy×5, pairswap×5 — every one backs a pinned `.core` dump |
| `runtime/libc/src` (14) | 0 | 9 | internal, math, stat, stdio, stdlib, string, uio, unistd, vfscanf |
| `tests/fixtures` w/ goldens (10) | 0 | 1 | 014-while-simple |

The D1 mechanism in the speclab 25: `mkHarness` renders
`const unsigned char choices[] = …; const unsigned char expected[] = …;`
into the same function as the codec `for`-loops (verified on
`lookup_a.c:40-41,50-60`) — const-array mints co-resident with loop
draws.

Scan-quality notes: `runtime/libc/src/locale.c` = ERROR (it is NOT a
libc.co TU — absent from `runtime/libc/dune`'s libc.co deps — out of
the pin cone); `ctype.c` scans clean and was additionally
hand-verified (no loops, no `const` anywhere in the TU).

### 3.2 Which pinned artifacts move (the deliverable-c reasoning)

Symbol-visible artifact classes (these SEE oracle draw numbers):

1. **`tests/speclab/*.core`** — pinned oracle `--pp=core` dumps.
   D1: the 25 dumps named above move under the charter-narrow
   trigger alone. D2: 34 of 39 move under the broader class
   (+ rotate×9, which are D1-clean).
2. **`SpecLab/*Core.lean` pinned terms** (generated from the dumps by
   `speclab-emit-*`, drift-gated; symbol ids baked in as
   `SD_Id "a_NNNN"` + name-hash pairs — verified in
   `TreeRotCore.lean:53`) — every family whose backing dump moves
   must be re-emitted: at least ListAppend (applist), ByteArr
   (getarr/memcpy), CnSeed (lookup), the pairswap family module, and
   under D2 also TreeRot (rotate) and DivMod stays clean (divmod
   harnesses: no loops).
3. **`tests/corpus/*.core[.sha256]` + `*_funs.core`** (via
   `check_fixture_freeze.sh` + `test_verify.sh` pin provenance).
   D1: none. D2: the 7 fixture families p04/p05/p06/p07/p08/p14/p15 —
   i.e. 14 of the 21 pin files (each family pins a `.core` or
   `.core.sha256` plus a `_funs.core`).
4. **`tests/libc/libc.core` + `.sha256`** (content-hash pin of the
   oracle libc dump). D1: no. D2: YES — 8 of the 12 libc.co TUs are
   D2-hit, so the single libc.core pin moves under the broader class.
   (`math.c` is D2-hit too but backs libm.co, which has no pin.)
5. **`tests/verify/*.core`** (5): unaffected under both detectors.
6. **`tests/fixtures/*/core.txt`, `ail.txt`** (10 fixture goldens):
   committed oracle dumps but NOT gate-compared (test_golden.sh reads
   only `expected.txt`; gen_goldens.sh regenerates) — 014-while-simple
   moves under D2; re-generation, not adjudication.

Verdict-only artifacts (do NOT see symbol numbers; reasoned, with the
enumeration-order caveat that symbol-keyed `Fmap` iteration can in
principle surface order changes in exhaustive-mode verdict SETS —
single-verdict rows are insensitive): all `test_exec.sh`-family
baselines (`exec_csmith_corpus_baseline.txt`, float, gcc-torture,
immaculate, libxml2 chvalid/uri, bytes `.exec`), `.elab` reject
records (front-end error text, no sym ids — verified), multi_tu
baselines, `expectations.txt` verdicts. The main-mode differential
lanes are additionally id-canonicalized on the Lean side (the
standing "ids compared only for equality within a run" discipline,
`Main.lean` sym floor comment) and compare oracle-vs-Lean IN THE SAME
RUN, so coordinated two-sided movement is invisible to them.

### 3.3 Verdict-only corpora, coarse tallies (derived, raw-text grep, file-level, overapproximate; recorded for O3/O6 sizing only)

| corpus | total .c | contains loop kw | contains `const` | both |
|---|---|---|---|---|
| tests/minimal | 106 | 16 | 2 | 1 |
| tests/ci | 250 | 17 | 12 | 1 |
| tests/csmith/small_arrays | 470 | 411 | 470 | 411 |
| tests/csmith/small_int_arith | 1192 | 566 | 814 | 367 |
| tests/bytes | 14 | 1 | 0 | 0 |
| tests/float | 69 | 0 | 0 | 0 |
| tests/immaculate (nolibc+libc) | 26 | 3 | 2 | 0 |
| tests/libc_exec | 7 | 0 | 1 | 0 |
| tests/multi_tu | 4 | 0 | 0 | 0 |

### 3.4 Q1b verdict

**NONTRIVIAL.** Churn tally under the charter's OWN narrow trigger:
**25 pinned oracle Core dumps** (tests/speclab) **plus their derived
`SpecLab/*Core.lean` pinned terms and family gate expectations** —
not the "possibly zero" the tolerated route hoped for. Per the Q1b
ruling ("tolerated-with-scan, escalating to a staged pre-slice iff
the scan shows nontrivial fixture churn") this ESCALATES to the
staged pre-slice — but S0-F1 (§1) means the staged pre-slice as
specified (move the ONE site's minting) would no longer make m1
order-preserving; the broader class adds the 14 tests/corpus pin
files, the libc.core pin, and the remaining speclab dumps. Operator
decision point: re-scope Q1b/O2 in light of S0-F1 before C1.

## 4. unsafeBaseIO survivor allowlist (S0 item ii — Q4 inventory finalized)

Committed as `scripts/unsafebaseio_allowlist.txt` (the §7.2 ratchet's
input at C2). Census result: the re-verified enumeration **matches
the charter's Q4 table exactly — zero out-of-table sites** (no
findings). Code sites (hand-written, mirrored in `generated/` by the
sync gate): CerbUtils ×4 (`timingStackRef`, `logRef`, `STD_impl`,
`boundedIntegerImpl` — permanent-declared; note `boundedIntegerImpl`
is a deterministic `pure lo` stub with its own in-file mover note,
not a timing/log ref), CerbGlobal ×4 (`confRef`, `switchesRef`,
`getConf`, `has_switch_impl` — temporal, post-arc plumbing),
CerberusImpl ×2 (`typeof_enum_impl`, `register_enum_impl` — temporal,
follow-up slice), CerberusFresh ×1 (`digest_impl` — C2
opaque-conversion deliverable), CerbTags ×4 (in-arc delete, §4),
CerbDebug ×2 (in-arc delete, §5), LemLib ×1 (`runEffectful_impl` —
L2 delete). Comment-only mentions for the grep leg's design:
`CerbGlobal.lean:51`, `CerbTags.lean:28`, `LemLib.lean:36`. LemLib as
consumed (33 files, recursive) declares exactly ONE axiom
(`runEffectful`, `LemLib.lean:54`) and no other `unsafeBaseIO`.

## 5. Entry-set axiom census (charter §1.3/§8.1 — measured, not assumed)

Probe: `#print axioms` over the §1.3 entry set, elaborated against
the worktree's built tree (probe recipe, capped). Verbatim:

```
'driver2' depends on axioms: [propext, Classical.choice, Quot.sound]
'drive' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.callND' depends on axioms: [propext, Classical.choice, Quot.sound]
'initial_driver_state' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'desugar' depends on axioms: [propext, Classical.choice, Quot.sound]
'annotate_program' depends on axioms: [propext, Classical.choice, Quot.sound]
'translate' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'convert_file' depends on axioms: [propext, Classical.choice, Quot.sound]
'link' depends on axioms: [propext, Classical.choice, Quot.sound]
```

(The charter's `Core_linking.link` is the top-level `link` in the
generated module — no namespaced constant exists.)

Dirty TODAY: `initial_driver_state`, `translate`. Clean: the seven
others — **with one measured caveat the C2 gate design must carry**:
`desugar`'s KERNEL cone is clean because the Cabs_to_ail chain is
built of `partial def`s, which are kernel-opaque — yet its COMPILED
path reaches `runEffectful` (probed:
`evalConstantExpressionAux`/`evalIntegerConstantExpression` are
runEffectful-dirty, and `cabs_to_ail.lem:1128-1132` calls them from
the desugar cone through the `Desugaring_init` function-record).
`#print axioms` therefore UNDERREPORTS impurity across
partial-def/opaque boundaries; the §7.2 exact-allowlist probes remain
correct as end-to-end spot checks of the KERNEL claim (which is what
the customer contract needs), but "which entries carry the axiom" is
not the same question as "which entries execute the effect" — the
charter's expectation that desugar measures dirty was wrong for the
kernel-cone reading, right for the compiled-path reading.

## 6. Site-census re-verification (charter §2, F2/F3 — confirmed)

- `declare {lean} effectful`: exactly 3 (repo grep) — unchanged.
- Applied generated `runEffectful` sites: exactly 9 —
  `generated/Symbol.lean:299,303,307,311,323,326,329`,
  `generated/Translation_effect.lean:178`,
  `generated/Core_run_aux.lean:395`; plus the 4 doc-comment mentions
  in the hand-written support copies. Matches F2 verbatim.
- `with_block_objects` mint condition and callers re-verified against
  the tree (`translation_effect.lem:102-111`;
  live draw-bearing callers `translation.lem:3556,3698,3714`).

## 7. Operational notes

- **Base drift:** the orchestrator brief named base `df63018e3`; the
  branch's actual merge-base with `mdd/cerberus-lean` is `58ec50779`
  (= the charter's stated base). Mainline has since advanced to
  `df63018e3` (trust-basket arc: CerbFS/gcc-lane/bytes changes + one
  new parity probe). This scan ran at the branch tree; the mainline
  delta adds no new symbol-visible pin class (gcc/bytes baselines are
  verdict/error-text records), but the S0 numbers should be re-read
  against the rebased tree when the arc rebases.
- Scratch (`.s0-scratch/`, calibration TUs + raw Ail) was ephemeral
  and is deleted with this commit; every load-bearing probe output is
  quoted above verbatim or reproducible from the scanner + §1 rules.
- Nothing in this slice changed semantics, gates, lanes, baselines,
  or pins.
