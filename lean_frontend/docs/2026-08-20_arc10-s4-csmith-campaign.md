# Arc-10 S4: the csmith campaign — configuration exploration, sweep, triage

Date: 2026-08-20/21. Worker slice S4 of the robustness arc
(`2026-08-20_arc10-robustness-charter.md`, ADDENDUM: the [USER]
configuration-exploration directive opens the slice; [AGENT] additions:
in-tree-corpus list-lane + the prototype union_unspecified reproducer).
Worktree CERB `arc/robustness`; base f7ea03e7d; LEM untouched (no
lem-scoped fix was needed). Everything quoted as harness/tool output is
verbatim; derived tallies are labeled derived. All seeds deterministic
and recorded; no wall-clock or randomness anywhere in this record.

**Session note:** the campaign was interrupted once by a machine-level
crash (OOM/Zellij, whole session died — orchestrator-diagnosed as two
concurrent 64G-capped lanes exceeding the box; not a harness defect).
Commits fb36810a8 (infrastructure) + bdb9f1967 (fix-batch 1) landed
clean BEFORE the crash; the exploration scratch data survived and was
resumed. Standing mitigation from the orchestrator, applied from resume
onward: builds capped `CERB_MEM_MAX=40G`; sweep batches keep 8G caps and
run strictly sequentially (no parallel batch fan-out while the arc-9
lane is live). Post-crash re-verification at bdb9f1967: capped
default-target build green (593 jobs), `test_unit.sh` rc 0, minimal
`BASELINE OK` (verbatim tails banked in the phase-3 gate section).

## Phase 1 — configuration exploration

### Instruments (commit fb36810a8)

`scripts/csmith_explore.sh NAME SEED_START N OUTDIR -- <flags>`:
oracle-only per-configuration measurement over deterministic seed
blocks. Statuses: OK (verdict extracted + exit consistent — exactly
test_exec.sh's oracle-side acceptance), OK_INCONS, SKIP_INTERNAL
(oracle "internal error"), SKIP_ERROR, SKIP_TIMEOUT (124), SKIP_CRASH
(134/137/139), SKIP_OTHER (mostly frontend constraint-violation
rejections).

**Yield metric (i):** ok/200 — the fraction of generated programs the
oracle can execute (`--nolibc --exec --batch --mode=exhaustive`,
TIMEOUT_SECS=15). Only oracle-runnable programs reach the Lean side of
the differential, so yield bounds differential throughput per generated
program.

**Construct-coverage metric (ii), defined:** (a) source-level feature
markers — fixed egrep classes (volatile, union, struct, `#pragma pack`,
ptr-deref `\*[gl]_[0-9]|\*\*`, addr-of `&[gl]_[0-9]`, 2-D+ array
indexing, 1-D array indexing, goto, u?int64_t, bitfield decl, div/mod,
safe_math calls, ++/--, compound assignment, const, inline, float,
argc, function-pointer call — full patterns in csmith_explore.sh)
counted as files-exercising-class over the ORACLE-RUNNABLE subset (= the
programs the Lean side actually consumes), on comment-stripped source
(the csmith banner + trailing `XXX` stats block are comments and
false-positive otherwise — an early marker table had exactly that bug;
recomputed before any decision was taken). No marker for
comma-operators/embedded-assignments: no grep-reliable signature exists;
those axes are flag-controlled, not measured. (b) a Core-level census —
distinct `memop(...)`/create/store/load/kill classes in `--pp=core`
output over ≤30 runnable files per config.

**Mismatch/finding rate (iii)** is measured on the shortlist only, via
full test_exec.sh differential batches (phase 2's first batches double
as the measurement — the Lean side is too expensive to run for all 21
exploration configs).

### A-round: 15 configs × 200 seeds (oracle-only)

Shared base ("kit flags + array cap", the S0 lane-V parameters):
`--no-argc --no-bitfields --max-funcs 3 --max-block-depth 3
--max-block-size 4 --max-expr-complexity 3 --max-array-len-per-dim 8`.
Seed blocks 3001001-3015200 (200 per config, disjoint, recorded in each
summary line). Verbatim EXPLORE SUMMARY lines
(.tmp/csmith_explore/*/summary.txt):

```
EXPLORE SUMMARY: name=A0_kitV seeds=3001001-3001200 n=200 ok=40 ok_incons=0 skip_internal=105 skip_error=0 skip_timeout=2 skip_crash=0 skip_other=53
EXPLORE SUMMARY: name=A1_NV seeds=3002001-3002200 n=200 ok=30 ok_incons=0 skip_internal=118 skip_error=0 skip_timeout=12 skip_crash=0 skip_other=40
EXPLORE SUMMARY: name=A2_NP seeds=3003001-3003200 n=200 ok=35 ok_incons=0 skip_internal=99 skip_error=0 skip_timeout=5 skip_crash=0 skip_other=61
EXPLORE SUMMARY: name=A3_NU seeds=3004001-3004200 n=200 ok=29 ok_incons=0 skip_internal=112 skip_error=0 skip_timeout=3 skip_crash=0 skip_other=56
EXPLORE SUMMARY: name=A4_NC seeds=3005001-3005200 n=200 ok=45 ok_incons=0 skip_internal=114 skip_error=0 skip_timeout=7 skip_crash=0 skip_other=34
EXPLORE SUMMARY: name=A5_NVPU seeds=3006001-3006200 n=200 ok=38 ok_incons=0 skip_internal=114 skip_error=0 skip_timeout=4 skip_crash=0 skip_other=44
EXPLORE SUMMARY: name=A6_NUC seeds=3007001-3007200 n=200 ok=41 ok_incons=0 skip_internal=113 skip_error=0 skip_timeout=8 skip_crash=0 skip_other=38
EXPLORE SUMMARY: name=A7_maxyield seeds=3008001-3008200 n=200 ok=37 ok_incons=0 skip_internal=124 skip_error=0 skip_timeout=5 skip_crash=0 skip_other=34
EXPLORE SUMMARY: name=A8_argc seeds=3009001-3009200 n=200 ok=38 ok_incons=0 skip_internal=104 skip_error=0 skip_timeout=5 skip_crash=0 skip_other=53
EXPLORE SUMMARY: name=A9_bitfields seeds=3010001-3010200 n=200 ok=38 ok_incons=0 skip_internal=50 skip_error=0 skip_timeout=6 skip_crash=0 skip_other=106
EXPLORE SUMMARY: name=A10_float seeds=3011001-3011200 n=200 ok=21 ok_incons=0 skip_internal=24 skip_error=0 skip_timeout=0 skip_crash=0 skip_other=155
EXPLORE SUMMARY: name=A11_nosafe seeds=3012001-3012200 n=200 ok=33 ok_incons=0 skip_internal=110 skip_error=0 skip_timeout=1 skip_crash=0 skip_other=56
EXPLORE SUMMARY: name=A12_big seeds=3013001-3013200 n=200 ok=19 ok_incons=0 skip_internal=3 skip_error=0 skip_timeout=0 skip_crash=0 skip_other=178
EXPLORE SUMMARY: name=A13_noptr seeds=3014001-3014200 n=200 ok=50 ok_incons=0 skip_internal=143 skip_error=0 skip_timeout=7 skip_crash=0 skip_other=0
EXPLORE SUMMARY: name=A14_nosu seeds=3015001-3015200 n=200 ok=36 ok_incons=0 skip_internal=110 skip_error=0 skip_timeout=12 skip_crash=0 skip_other=42
```

Config deltas from base (derived, labeled): A1 +`--no-volatiles
--no-volatile-pointers`; A2 +`--no-packed-struct`; A3 +`--no-unions`;
A4 +`--no-consts --no-const-pointers`; A5 = A1+A2+A3; A6 = A3+A4;
A7 = A2+A3+A4; A8 = base minus `--no-argc` (argc ON); A9 = base minus
`--no-bitfields` (bitfields ON); A10 +`--float`; A11 +`--no-safe-math`;
A12 = bigger size caps (`--max-funcs 8 --max-block-size 6
--max-expr-complexity 8`); A13 +`--no-pointers`; A14 +`--no-structs
--no-unions`.

Marker coverage over the runnable subsets (recomputed with the fixed
comment stripper; per-config MARKERS lines in the per-config
summary.txt files; derived highlights):

- A0 (ok=40): volatile 22, union 2, struct 7, packed 5, ptr_deref 21,
  addr_of 20, 2D-array 5, 1D-array 17, int64 19, goto 1.
- A13 noptr (ok=50): ptr_deref/addr_of 0 (as designed), everything else
  strong (int64 33, arrays 23, div_mod 21) — a value-semantics lane.
- A8 argc (ok=38): argc_use 38/38; otherwise A0-like.
- A9 bitfields (ok=38): bitfield markers 0/38 among RUNNABLE files —
  every generated bitfield struct dies frontend-side (skip_other 106,
  incl. verbatim class `error: feature not yet supported: bit-fields`
  78×). Bitfields ON adds zero Lean-side coverage; stays off.
- A10 float (ok=21): float_use 21/21 but weak elsewhere; excluded from
  the portfolio anyway (doc-delib: upstream float-mul divergence would
  indict the ORACLE, cf. the float-lane classification rule in D5).
- A12 big (ok=19): worst yield — bigger expressions multiply frontend
  constraint-violation rejections (skip_other 178). Small stays right.
- Core census: all runnable configs show
  create/kill/load/store/memop(PtrValidForDeref); pointer-comparison
  configs add memop(PtrEq)/memop(PtrNe). (Sample-30 census; ptr
  memops absent from A13/A10/A12 samples as expected.)

### Skip-cause analysis (the yield structure)

Verbatim top skip classes (status.tsv diagnostic lines, counts derived
by class normalization):

- A0: 105× `internal error: Translation called on Ail program with an
  invalid node`; 40× `error: constraint violation: invalid operands to
  binary expression`; 6× `error: constraint violation: initializer
  element is not a compile-time constant`; 5× incompatible-pointer-type
  assignment rejections.
- **The AilEinvalid class is 3-D array initializers**: in A0, 105/105
  SKIP_INTERNAL files contain a `[i][j][k] = {` initializer and 0/40 OK
  files do (exhaustive grep over the seed block). Minimal reproducer
  (NEW oracle finding, upstream tray — §oracle-findings F-A below).
  csmith's default `--max-array-dim 3` therefore wastes ~52% of
  generated programs; `--max-array-dim 2` recovers them (B-round).
- The `invalid operands to binary expression` class is csmith emitting
  ISO-constraint-violating qualified-pointer comparisons (e.g. verbatim
  `('signed int**' and 'const signed int**')`) — a known csmith wart;
  the oracle is CORRECTLY strict (gcc merely warns). Mitigated by
  `--no-consts --no-const-pointers` (A4: skip_other 53→34, ok 40→45)
  and by small expressions; not fully removable with pointers on.
- The `initializer element is not a compile-time constant` class
  rejects ISO-legal address-constant initializers (verbatim example:
  `static struct S0 *g_1169 = &g_475[4][3][0].f3;`) — oracle
  strictness defect family (libxml2 probe #1 / wireguard edit-2), §F-B.

### B-round: `--max-array-dim 2` + combinations (200 seeds each)

Verbatim summaries:

```
EXPLORE SUMMARY: name=B1_dim2 seeds=3016001-3016200 n=200 ok=48 ok_incons=0 skip_internal=45 skip_error=0 skip_timeout=49 skip_crash=0 skip_other=58
EXPLORE SUMMARY: name=B2_dim2_nc seeds=3017001-3017200 n=200 ok=60 ok_incons=0 skip_internal=47 skip_error=0 skip_timeout=58 skip_crash=0 skip_other=35
EXPLORE SUMMARY: name=B3_dim2_noptr seeds=3018001-3018200 n=200 ok=69 ok_incons=0 skip_internal=58 skip_error=0 skip_timeout=73 skip_crash=0 skip_other=0
EXPLORE SUMMARY: name=B4_dim2_nosafe seeds=3019001-3019200 n=200 ok=95 ok_incons=0 skip_internal=26 skip_error=0 skip_timeout=24 skip_crash=0 skip_other=55
```

(B1 = A0 + `--max-array-dim 2`; B2 = B1 + no-consts/no-const-pointers;
B3 = B1 + no-pointers; B4 = B1 + no-safe-math. B5-B8 below.)

Readings (derived): dim-2 kills the AilEinvalid-3D class as predicted
(105 → residual ~45, now union-initializer/constructValue and
exec-driver classes, §F-C/F-D) but EXPOSES oracle exhaustive-mode
TIMEOUTs (49-73/200): with real 2-D array state reachable, volatile
loads fork the oracle's exhaustive tree until the 15 s cap. B4
(no-safe-math) is the yield champion at 95/200 = 47.5%: most programs
hit UB quickly (short traces, few timeouts) — an intentionally UB-rich
lane. The volatile-timeout hypothesis is tested by B7/B8 (dim2 + NV).

```
EXPLORE SUMMARY: name=B5_dim2_argc seeds=3020001-3020200 n=200 ok=65 ok_incons=0 skip_internal=36 skip_error=0 skip_timeout=47 skip_crash=0 skip_other=52
EXPLORE SUMMARY: name=B6_dim2_np seeds=3021001-3021200 n=200 ok=64 ok_incons=0 skip_internal=35 skip_error=0 skip_timeout=49 skip_crash=0 skip_other=52
EXPLORE SUMMARY: name=B7_dim2_nv seeds=3022001-3022200 n=200 ok=64 ok_incons=0 skip_internal=39 skip_error=0 skip_timeout=57 skip_crash=0 skip_other=40
EXPLORE SUMMARY: name=B8_dim2_nv_nc seeds=3023001-3023200 n=200 ok=70 ok_incons=0 skip_internal=50 skip_error=0 skip_timeout=56 skip_crash=0 skip_other=24
```

(B5 = dim2 with argc ON; B6 = dim2 + no-packed-struct; B7 = dim2 + NV;
B8 = dim2 + NV + no-consts/no-const-pointers.)

Further readings (derived): B7 falsifies the volatile-timeout
hypothesis — 57/200 oracle timeouts WITHOUT volatiles. The exhaustive
oracle interpreter is simply slow on real 2-D-array loop nests (up to
8×8 products per nest) + unsequenced-order exploration; timeouts are a
throughput cost of array state, not a fork artifact. B8 is the best
deterministic-lane yield (70/200 = 35%, and the lowest wart-skip count:
skip_other 24). Marker coverage in the dim-2 runnable subsets is
DRAMATICALLY richer than A0's (e.g. B4: 2-D arrays 70/95, unions 26/95,
ptr_deref 78/95 vs A0's 5/40, 2/40, 21/40) — the dim-2 change not only
recovers yield, it recovers construct density, because the big
initializer-heavy programs that previously died are exactly the
construct-rich ones. Full MARKERS lines per config in
`.tmp/csmith_explore/<cfg>/summary.txt` (scratch; regenerable from the
recorded seeds + flags via scripts/csmith_explore.sh).

### The lane PORTFOLIO (decision)

Five lanes, chosen to maximize the union of construct coverage within
the stack-ceiling rule (loop-nest products ≤ 8² = 64 iterations ≪ the
re-measured ~16-24k onset; `--max-array-dim 2`, `--max-block-depth 3`
everywhere; `--float` stays OFF per the doc-delib float-mul boundary;
`--bitfields` OFF — measured zero runnable coverage, A9):

| lane | flags (full) | evidence basis | axis it owns |
|---|---|---|---|
| **P1_full** | `--no-argc --no-bitfields --max-funcs 3 --max-block-depth 3 --max-block-size 4 --max-expr-complexity 3 --max-array-len-per-dim 8 --max-array-dim 2` | B1: ok 48/200, volatile 37/48, union 10/48, packed 6/48 | volatiles + full feature surface + provenance/volatile ND forks |
| **P2_value** | P1 + `--no-volatiles --no-volatile-pointers --no-consts --no-const-pointers` | B8: ok 70/200, skip_other 24 (lowest) | deterministic value semantics, highest clean-comparable rate |
| **P3_ub** | P1 + `--no-safe-math` | B4: ok 95/200 (yield champion) | UB-code differential coverage (unwrapped arithmetic) |
| **P4_argc** | P1 minus `--no-argc` | B5: ok 65/200, argc_use 65/65 | main(argc,argv) entry convention (matches the in-tree corpus) |
| **P5_noptr** | P1 + `--no-pointers` | B3: ok 69/200, skip_other 0 | pure-value lane; zero csmith qual-pointer warts |

Sweep seed ranges (deterministic, disjoint from the burned exploration
blocks 3000001-3023200 and the S0 blocks): P1 from 1000001, P2 from
2000001, P3 from 4000001, P4 from 5000001, P5 from 6000001; batches of
100 (batch k of lane L = seeds L_base+(k-1)*100+1 .. L_base+k*100).
Runtime parameters per S0 (confirmed): TIMEOUT_SECS=15 both sides,
whole batch under `scripts/capped` CERB_MEM_MAX=8G, sequential batches
only (post-crash constraint).

## Phase 2 — the sweep

### Generated lanes, round 1 (batch 1 of each lane, 100 seeds)

Verbatim SUMMARY lines (.tmp/sweep/round1_log.txt; per-lane seed blocks
as in the portfolio table):

```
P1_full  : SUMMARY: total=100 match=33 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=65 cerb_inconsistent=2
P2_value : SUMMARY: total=100 match=32 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=68 cerb_inconsistent=0
P3_ub    : SUMMARY: total=100 match=34 ub_match=9 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=1 cerb_skip=56 cerb_inconsistent=0
P4_argc  : SUMMARY: total=100 match=33 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=67 cerb_inconsistent=0
P5_noptr : SUMMARY: total=100 match=34 ub_match=0 ub_diff=0 mismatch=2 fail=0 crash=0 lean_error=0 timeout=1 cerb_skip=63 cerb_inconsistent=0
```

(The lane label prefixes are derived annotations; each SUMMARY line is
verbatim from its lane run.) Comparable-agreement: P1-P4 batch 1 =
100% agreement (141 comparisons, 0 mismatch; the P3 timeout resolved
below). P5's three non-agreements triaged below — ALL THREE are
oracle-side, none is a Lean defect.

### Round-1 triage (every non-MATCH classified)

- **P1 `[11/100] CERB_INCONSISTENT csmith_1000011: exec succeeded but
  cabs-json failed`** (and the identical [42/100] csmith_1000042):
  oracle MODE INCONSISTENCY — `--exec` accepts the program but
  `--cabs-json` rejects it, verbatim: `error: undefined behaviour: the
  initializer for a scalar shall be a single expression` on a
  `static volatile struct S2 g_43[7][5] = {...}` nested initializer.
  Oracle finding F-E (§findings); counted, visible, not hidden.
- **P3 `[25/100] TIMEOUT csmith_4000025 (Lean >15s)`**: perf-gap, not
  semantic — uncapped rerun: oracle 11.3s, Lean 30.5s, and the two
  130-line verdict sequences are IDENTICAL (65× UB51b_shift_too_large
  each, diff clean). Bucket TIMEOUT_LEAN_PERF.
- **P5 `[18/100] DIFF csmith_6000018: Lean=VAL:Specified(100)
  Cerberus=UB:UB_CERB002b_out_of_bound_store`**: gcc -O0 native run
  returns 100 (= Lean). Declaration-morph fingerprint: adding ONE
  unused declaration (`int __extra_decl(int);`) morphs the oracle
  verdict to verbatim `internal error: can_advance: Step_error2 ==>
  Store`. Bucket ORACLE_DEFECT (F-D family).
- **P5 `[98/100] MISMATCH csmith_6000098: Lean=VAL:Specified(117)
  Cerberus=VAL:Specified(187)`**: gcc returns 117 (= Lean).
  Morph fingerprint: oracle 187 → **Specified(138)** with one added
  declaration; Lean stays 117 on both variants. The oracle's DEFINED
  RESULT VALUE is a function of top-level declaration count — silent
  value corruption, the most dangerous F-D manifestation (extends the
  wireguard §2a characterization, which saw only internal errors and
  spurious UB). Bucket ORACLE_DEFECT.
- **P5 `[38/100] TIMEOUT csmith_6000038 (Lean >15s)`**: uncapped rerun
  — oracle 6.2s/2240 executions all Specified(218); Lean 86s/2240
  executions all Specified(13); gcc returns 13 (= Lean); morph
  fingerprint: oracle 218 → 134. Bucket ORACLE_DEFECT (value
  corruption) + a Lean perf-gap note (14× on this fork-heavy case;
  perf register).

## Root-cause poking ([USER] directive, 2026-08-21, timeboxed)

### F-D — the can_advance / spurious-UB / silent-value-corruption family: **REATTRIBUTED — a cerberus-lean FORK regression, upstream is clean**

The decisive experiment: the same reproducers against the PROTOTYPE's
un-forked upstream cerberus (`cerberus-lean-prototype/cerberus` @
866be5254, its own switch/build):

- csmith_6000098: upstream verbatim `Defined {value: "Specified(117)",
  ...}` — the gcc/Lean value. Our fork's oracle: 187 (and 138 with one
  added declaration).
- csmith_6000018: upstream `Specified(100)` (= gcc/Lean); fork:
  spurious `UB_CERB002b_out_of_bound_store`.
- sa_csmith_168 (in-tree corpus): upstream `Specified(28)`; fork:
  spurious `UB010_pointer_to_dead_object`.

So the entire F-D family — including the wireguard scoping survey's
"oracle exec-driver defect" (§2a addendum, same fingerprint), which
must be RE-ATTRIBUTED accordingly — is a regression OUR fork
introduced, not an upstream defect. It does NOT go in the upstream
tray; it is a cerberus-lean register item.

**Mechanism evidence (all verbatim outputs banked in scratch, recipes
deterministic):**

1. Elaboration is NOT the divergence: `--pp core` of the
   csmith_6000098 morph pair, alpha-canonicalized
   (scripts/canonicalize_ids.py), differs in exactly one line — the
   added `proc __extra_decl (pointer)`. 23,155-line dumps otherwise
   identical.
2. ND scheduling is NOT the divergence: the program is single-trace
   (exhaustive mode = 1 execution) and random-mode runs are stable.
3. The memory-action trace (`--exec --trace`, both variants,
   line-number-normalized) is IDENTICAL for the first ~397 actions —
   same allocation ids, same addresses, same values — then diverges
   inside main's checksum for-loops: the unmodified variant executes a
   spurious extra `seq_rmw` of the inner loop counter (j 6→7 with no
   body between) and skips whole rows of the `transparent_crc` nest
   (subsequently reading `g_282[2]` where the +1-decl variant is still
   correctly iterating `g_7[1]`) — i.e. a WRONG-CONTINUATION jump in
   the Core Esave/Erun label machinery, which then yields the wrong
   checksum (and, in other layouts, ill-typed actions =
   `can_advance: Step_error2 ==> Load/Store`, spurious
   DeadPtr/OutOfBound UB, etc.).
4. Since the interpreter diverges on alpha-equivalent Core, it is not
   alpha-invariant in symbol ids: something keys on RAW symbol
   numbers. The fork's suspect surface (file:line): the arc-2 S1
   threaded symbol supply — `core_run_state.sym_supply`
   (core_run_aux.lem:233-247, seeded at :287 from the ambient
   `Symbol.fresh_int ()`), consumed by `fresh_symbol'`
   (core_run.lem:115-119, minting `Symbol (digest()) n SD_None`), with
   sibling threaded supplies in cabs_to_ail_effect.lem:568/622. The
   in-code invariant comment ITSELF concedes the hole: "A run's
   threaded range can overlap ambient ids drawn AFTER init …
   latent-safe because run-created symbols do not escape their run …
   a Phase-2 differential obligation asserts non-escape" — an
   obligation that was never discharged; this finding is that
   obligation firing. Collisions become misbehavior through
   description-INSENSITIVE symbol equality (Symbol.symbolEquality:
   digest+number only — it even carries a "suspicious equality" debug
   print) feeding the env/label/substitution machinery
   (core_run.lem:1502-1541 Esave substitution + Erun label lookup).
5. Tested predictions: a declaration inserted at the HEAD (shifts the
   27 later globals' symbol numbers, observed via the -d6 global-eval
   trace: first 43 ids identical, last 27 shifted +1) changes the
   result/failure mode on every witness; a declaration appended at the
   TAIL (program symbol numbers unchanged) does NOT change the result
   (still 187) — the corruption keys on program-symbol numbering, not
   on the final counter value alone.

Not root-caused to the exact colliding pair within the timebox (the
precise first wrong lookup needs an instrumented build, out of scope
here). Ruled out: elaboration, ND scheduling, memory-model state.
Register disposition: fork-side OCaml/lem repair in the arc-2
threading region (frontend/model/core_run_aux.lem + friends) — NOT
S4's write surface, PARKED with this analysis; priced M (needs
probe-first lem work + the full validation ladder; the Lean side is
unaffected — its supply threading is pure and collision-free, which is
WHY the differential caught this at all).

**Impact note:** standing green baselines are structurally unaffected
(a corrupted oracle verdict against an independent correct Lean
verdict surfaces as a visible MISMATCH/DIFF, never as a silent MATCH),
but F-D suppresses differential VALUE on affected files (they sit as
oracle-side noise) until the fork regression is repaired.

### F-E — cabs-json vs exec disagreement: DISSOLVED into two small precise findings

Bisection (seed-1000011 witness): `--nolibc` is not the axis. The
frontends do not disagree semantically; the differences are
stage/channel:

- (a) The oracle desugar flags the nested `static volatile struct S2
  g_43[7][5] = {...}` initializer as
  `UB081_scalar_initializer_not_single_expression` (gcc: accepts,
  rc 0). In `--exec` mode this surfaces as a legitimate-looking
  EXECUTION verdict (`Undefined {ub: UB081...}` — which the harness
  counts as an oracle UB verdict), while the fork's `--cabs-json`
  exporter treats the same desugar UB as a HARD frontend error (exit
  1, no JSON) → harness CERB_INCONSISTENT. UPSTREAM shows the
  identical UB081 verdict, so the UB081 class itself is
  upstream-shared (upstream-tray as a question: probably a
  Desugaring_init false-positive — F-A's neighborhood); the
  hard-vs-deferred CHANNEL inconsistency is fork-side (our exporter),
  cosmetic, register-noted.
- (b) The reverse direction (my minimal `cabsjson_vs_exec_init.c`:
  exec-rejected, cabs-json-accepted) is trivial once seen: the F-A
  AilEinvalid only explodes at TRANSLATION, a stage the cabs-json
  export never runs. Not a checker disagreement.

### F-A / F-B — upstream attribution confirmed

Upstream cerberus reproduces both verbatim: `init_array_3d.c` /
`init_struct_depth3.c` → `internal error: Translation called on Ail
program with an invalid node`; `init_addr_const.c` → `error:
constraint violation: initializer element is not a compile-time
constant`. Both genuinely upstream (shared Desugaring_init /
constant-expression checker). Upstream-tray: YES for both.

## Phase 2 — the in-tree corpus lane ([AGENT] addition)

`scripts/test_csmith_corpus.sh` (commit fb36810a8): all 1669 in-tree
upstream csmith programs (small_int_arith 1192 + small_arrays 470 +
small_mix 7), prefixed materialization + kit header substitution,
TIMEOUT_SECS=15, capped 8G, SKIP_BUILD=1. Run as one full pass (killed
externally at 962/1669 — an infrastructure stop, not a harness
failure; the partial log's positions 1-837 are complete) + shards 4-6
covering positions 838-1669. Verbatim shard SUMMARY lines:

```
SUMMARY: total=279 match=223 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=56 cerb_inconsistent=0
SUMMARY: total=279 match=267 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=1 lean_error=0 timeout=0 cerb_skip=11 cerb_inconsistent=0
SUMMARY: total=274 match=225 ub_match=0 ub_diff=0 mismatch=1 fail=0 crash=1 lean_error=0 timeout=2 cerb_skip=45 cerb_inconsistent=0
```

Combined per-file tally (derived from the verbatim per-file lines,
1669 rows, banked as `scripts/exec_csmith_corpus_baseline.txt` with
the assembly note in its header): **MATCH 1070, CERB_SKIP 573, DIFF
15, TIMEOUT 9, LEAN_CRASH 2.**

Triage — 100% of the 26 non-agreements classified:

- **15 DIFF — ALL F-D** (oracle spurious UB010_pointer_to_dead_object
  / UB009_outside_lifetime vs Lean values): sa_csmith_19/28/95/120/
  149/168/218/317/350/369/371, sia_csmith_081/136/1168/897. Verified:
  upstream cerberus returns the Lean-agreeing value on the two
  spot-checked witnesses (sa_csmith_168 → 28, sia_csmith_897 → 157);
  the declaration-morph fingerprint on sa_csmith_168 morphs UB010 into
  verbatim `internal error: can_advance: Step_error2 ==> Load`. The
  in-tree corpus provides these as plain deterministic single-file
  reproducers (better than the wireguard shim recipe).
- **9 TIMEOUT (Lean >15s)** — uncapped reruns, every one: sequences
  vs the oracle for sia_csmith_041/072/139/161/169/976/996 +
  sa_csmith_435 are IDENTICAL (diff clean; oracle 4.3-10.8s vs Lean
  11.1-26.4s — a 2.4-3x interpreter perf-gap, register); sa_csmith_190
  is F-D-on-top-of-perf (oracle spuriously `UB_CERB002a_out_of_
  bound_load` in 1.3s; Lean 66s → Specified(123) = gcc; morph →
  can_advance). Bucket TIMEOUT_LEAN_PERF (+1 F-D).
- **2 LEAN_CRASH — CEILING_FUEL**: sia_csmith_477/769 abort loudly
  with verbatim `lem: fuel exhausted` (goto-loops iterating ≥tens of
  thousands of times; oracle finishes in ~6-7s). The bounded-fuel
  ceiling bucket — registered, not chased (fuel policy sits in the
  CerbND/driver seam, a forbidden surface this arc). Harness
  improvement landed: test_exec.sh crash-kind capture now also
  extracts the fuel-exhaustion marker (previously "(no PANIC line
  captured)").
- 573 CERB_SKIP: oracle-side, the F-A/constraint-strictness/oracle-
  timeout classes (same taxonomy as the exploration rounds).

**Zero Lean-side semantic defects in 1669 in-tree programs.** The
seeded prototype reproducer (union_unspecified_3014219861.c, [AGENT]
addition): oracle times out in exhaustive mode even at 180s (volatile
trace explosion — the prototype ran it in single-trace mode) → the
current harness envelope records it CERB_SKIP; noted, not hidden.

<!-- further rounds + ledger + gates appended below -->
