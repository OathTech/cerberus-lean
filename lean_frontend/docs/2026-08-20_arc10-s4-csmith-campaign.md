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

<!-- phase 2 + 3 appended below as they land -->
