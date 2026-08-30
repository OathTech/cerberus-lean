# Parity detective — the frontier classified (2026-08-30)

Branch `probe/parity-detective` @ base mainline `a8f86112d`. Charge
([USER], verbatim): "look into all the examples that don't pass and
figure out what's happening, and whether there's something we could do
about it. I'm not totally convinced we actually are at Oracle parity
outside our testset - we probably should probe this carefully."

Method: fresh full run of the `scripts/test_ci_sweep.sh` instrument
(all 15 suites, 2,186 files) at this mainline, plus 52 hand-written
beyond-testset probes and three fresh-seed csmith shards, all
differential
(OCaml oracle vs Lean exec pipeline). Probe artifacts:
`tests/parity-probes/` (runner, probe programs, fresh sweep TSVs).
INVESTIGATION ONLY: no semantics, gate, or baseline was modified.

## 0. Verdict up front

**The Lean semantics is at oracle parity on everything the pipeline
can actually feed it, with one exception class: the declared-divergent
CerbFS file-I/O model, which produces silently WRONG ANSWERS (not just
failures) on seek/sequential-read programs.** Across 2,186 corpus
files and 52 targeted probes there is **not a single value or UB-tag
divergence** attributable to the ported semantics itself (sweep:
ub_diff=0, diff=0, mismatch=0). The gaps that do exist are: the fs
seam (3 corpus files + 3 minimized probes, wrong answers), a
libc-mode allocation-ordering divergence visible only through printed
addresses (6 files), a memory-representation scaling defect (2 OOMs),
and 2 exhaustive-mode timeout margins (verified to agree at 60-90s).
The ~870-file non-comparable remainder is entirely oracle-side or
bridge-side: the Lean semantics is never reached, so those files say
nothing about Lean parity — but 43 of them are a closable bridge gap.

Honest bounds: parity is DEMONSTRATED within {integer/pointer/struct
semantics, control flow, UB detection, malloc/free/realloc/calloc,
string.h, printf (non-float), qsort, varargs, argv, recursion,
designated inits, compound literals, FAM, anonymous members, _Generic,
long double}; KNOWN-DIVERGENT at {file I/O beyond one-shot
read/write, stat fields, address-observing programs under libc,
multi-MB objects / >64KB by-value aggregates}; UNKNOWN at {bitfields,
VLAs, wide strings, _Complex, setjmp, float printf — the oracle
front-end rejects all of these, so NO differential signal exists or
can exist until upstream supports them}.

## 1. Sweep provenance (and a trust finding about primed binaries)

[AGENT] Before sweeping, I verified binary freshness functionally and
found BOTH primed binaries in this worktree stale relative to
mainline sources (the primary checkout's Lean binary is the same
stale build; its oracle was not checked): the Lean driver lacked the
`--args` flag (Main.lean:1011, commit `8377161e1`) and predated the
pr44468 offsetof fix (`ba24da12e`); the oracle lacked
`--batch-alloc-census` (`8e23d1fa7`). A sweep against them would have
fabricated parity gaps. The sibling worktree
`worktrees/cerberus-lean-coherence` (same commit `a8f86112d`, clean
tree) had both binaries fresh (verified by flag-string presence and a
functional `--args` probe); I primed this worktree's binaries by
copying from it — no rebuild was run. Post-prime verification:
pr44468 runs MATCH (was: PANIC at CerbMem.offsetsof).

Process note for the record: "the worktree is primed" is not
evidence; primed artifacts can lag the commit they sit next to. A
cheap freshness stamp for the two driver binaries (analogous to the
lem-sync stamp) would close this hole. Priced S.

Committed prior results (`tests/ci_sweep/results/`, 2026-08-22-era
run in the ci-sweep worktree) were left untouched; fresh TSVs are at
`tests/parity-probes/sweep-2026-08-30/`. Row-level cross-check of the
two sweeps (derived): only two files moved —
`pr44468.c` LEAN_CRASH→MATCH (fix confirmed live) and `pr63209.c`
CERB_TIMEOUT→LEAN_TIMEOUT (both engines straddle the 15s margin;
verified AGREE at 90s). Everything else is bit-stable across a week
and two independently built binary pairs.

## 2. The frontier, classified — every file accounted for

Fresh sweep, 2,186 rows, timeout 15s/side, ulimit 4GB/side. Derived
tally from the TSVs (per-suite summaries quoted in the TSV footers):

| Status | Count | Class | Meaning |
|---|---|---|---|
| MATCH | 1,197 | comparable | identical value sequences (+ stdout in libc mode) |
| UB_MATCH | 113 | comparable | identical UB verdict sequences |
| CERB_REJECT | 766 | (a) oracle | oracle front-end rejects; Lean never reached |
| CERB_INCONSISTENT | 43 | (d) bridge | **oracle exec verdict OK but `--cabs-json` fails** (all 43 rows carry that one detail string) |
| CERB_ERROR | 29 | (a)/(d) | 24 "no startup function" (library-shaped files) + 5 "calling an unknown procedure" (nolibc lane, libc-calling files) |
| CERB_TIMEOUT | 25 | (c) | oracle >15s (18 of them in torture_success); no oracle answer ⇒ no parity signal |
| STDOUT_DIFF | 7 | **(b)** | values equal, printed bytes differ — 6 pnvi (addresses) + suite/fs/stat.c (stat fields) |
| LEAN_TIMEOUT | 4 | **(b)** | 2 = fs-model infinite loop / OOM-in-disguise; 2 = perf margin, AGREE at 90s |
| LEAN_FAIL | 1 | **(b)** | freebsd/cat.c — fs model |
| LEAN_CRASH | 1 | **(b)** | suite/parsing/array.c — 13MB stack array OOM |
| total | 2,186 | | comparable = 1,310; class (b) = 13; unclassified = **0** |

(The charge's "1,316 comparable" reconciles exactly, derived:
prior-sweep MATCH 1,196 + UB_MATCH 113 + STDOUT_DIFF 7 = 1,316; the
fresh sweep moves pr44468 into MATCH and pr63209 out to
LEAN_TIMEOUT.)

CERB_REJECT sub-classification (frequency-ranked, message-normalized;
counts from the 2026-08-22 TSVs whose reject set is row-identical to
the fresh run): 136 `cerberus.h: No such file or directory`
(hacl-star/freebsd include setup), ~150 GNU-extension parse failures
(`__attribute__`, `__complex__`, `__extension__`, `__SIZE_TYPE__`,
nested functions, K&R defs), 38 `feature not yet supported:
bit-fields`, 10 VLAs, 23 `abort` undeclared (nolibc ci lane), ~230
constraint-violation rejections of deliberately-invalid tests
(torture fail/invalid/undefined/not_std_compliant suites are MOSTLY
THIS by design), plus a long tail of frontend `internal error`s
(≈12: Formatted.load_character_array, Desugaring_init, AilTypesAux,
break_at_sseq — upstream-tray material). All class (a): no Lean
statement is possible or implied.

The 43 CERB_INCONSISTENT files are the one *closable* non-Lean class:
`--cabs-json` (backend/driver/main.ml:254-262) calls `c_frontend`,
which runs desugaring; on files whose UB is detected at translation
time (e.g. tests/ci/0069-const_expr.c, UB084 redefinition) the exec
path emits a proper `Undefined` verdict but the export path dies
before printing JSON, so the Lean side never gets to classify the
same UB. Fix: emit the Cabs JSON before the desugar stage runs
(driver-only change). Priced S. Until then, Lean's translation-time
UB classification is untested on exactly this set.

## 3. Class (b) — the 13 divergence rows, root-caused (4 groups)

### RC-1: CerbFS minimal fs model — WRONG ANSWERS (headline)

`lean_frontend/CerbFS.lean` header declares it: "lseek maintains
offsets that read/write IGNORE (read from 0, write appends) … a
seek-then-read program gets silently wrong data" — a documented
divergence with a registered mover. This probe confirms the blast
radius is worse than "smoke tests only": on programs BOTH engines
accept and complete, Lean returns a DIFFERENT ANSWER:

- `tests/parity-probes/probes/fgetc_eof.c` (minimized): fgetc-until-
  EOF over a 2-byte file. Oracle `Specified(2)`, **Lean
  `Specified(10)`** (loop cap) — a non-advancing read never hits EOF.
  Uncapped, it loops forever: that is exactly `tests/tcc/40_stdio.c`
  LEAN_TIMEOUT (oracle finishes in 0.36s; Lean still running at 60s).
- `probes/fseek_read.c`: seek(2)+fgetc. Oracle `Specified(42)`,
  **Lean `Specified(119)`** ('w', the byte at offset 0).
- `probes/fread_seq.c`: two sequential freads. Oracle
  `Specified(22)`, **Lean `Specified(1)`**.
- Corpus casualties: `tests/tcc/40_stdio.c` (timeout),
  `tests/freebsd/cat.c` (program's assert fires under Lean, oracle
  returns Specified(1)), `tests/suite/fs/stat.c` (STDOUT_DIFF: Lean
  prints zeroed stat fields, oracle prints SibylFS values).

This is the only mechanism found anywhere by which the Lean pipeline
gives a different answer on an accepted-and-terminating program.
Priced M: per-fd offsets in `CerbFS.FdEntry` (the field exists,
line ~20) honored by read/write/pread/pwrite + O_TRUNC/append modes
≈ a focused rewrite of one leaf module against impl_mem's fs hooks;
alternatively S for the fail-closed half-fix the header itself names
(loud enosys on seek/second-read instead of silently wrong data).
The S fix converts wrong-answers into loud LEAN_FAILs — worth doing
immediately even if the M fix waits.

### RC-2: libc-mode global allocation ordering (addresses only)

All 6 pnvi STDOUT_DIFFs. Minimized (`.tmp` probe, reproduced in
report only — addr_layout.c): a program printing `&global` and
`&local` under libc mode. Verbatim key line:

    Lean:   g1=(@69, 0xffffffffede4) ... l1=(@72, 0xffffffffedd8)
    oracle: g1=(@54, 0xfffffffff1d8) ... l1=(@72, 0xffffffffedd8)

Locals: allocation-id AND address identical. Program globals: the
oracle interleaves them among the libc TUs' globals (id 54); the Lean
driver allocates all libc TU globals first, program globals after
(id 69). Same probe under `--nolibc`: an address-derived return value
agrees exactly (AGREE Specified(32)) — nolibc layout is
byte-identical, so this is purely TU-ordering of globals in the
libc-linking seam, not the allocator (which mirrors impl_mem.ml:1252
faithfully — CerbMem.lean:1511 computes the same aligned-down
addresses). Observable only by printing/inspecting addresses; every
value comparison in the corpus agrees. Fix: mirror the oracle's TU
ordering when merging libc TUs + program TU in the Lean driver.
Priced S-M (find the ordering point in Main.lean's multi-TU link;
the comparison harness gives an exact oracle trace to match).

### RC-3: per-byte boxed-list memory representation — resource gap

- `tests/suite/parsing/array.c` = `int b[3333333];` (13.3MB): oracle
  answers immediately; **Lean: INTERNAL PANIC out of memory** at the
  4GB cap.
- `tests/gcc-torture/breakdown/not_supported/bitfields/pr20621-1.c`:
  a 64KB struct passed BY VALUE twice: Lean OOMs after ~35s. 64KB of
  object blowing a 4GB cap implies super-linear space somewhere in
  the byte path, not just a big constant.
- Scaling probe (derived): `int b[N]` agrees at N=10k (1.5s), 100k
  (2.0s), 1M (7.5s), OOM ~3.3M — linear time, ~1KB+ resident per
  object byte.

Root cause: allocation materializes `List.replicate size
{prov, copyOffset, value}` — one boxed struct + cons cell per byte
(`lean_frontend/CerbMem.lean:1530`, `:1550`; same shape at `:589`,
`:663-670`), and by-value copies re-materialize lists. The OCaml
side pays a far smaller constant. This is the "giant terms /
representation smell" case from the working practices, in exec
clothing. Fix directions (profile before optimizing, per doctrine):
chunked byte arrays or a sparse map keyed by offset with a compact
unspecified-region representation. Priced M (exec-only module,
differential harness is the safety net) — but it gates "Linux-scale"
ambitions, where 13MB objects are ordinary.

### RC-4: exhaustive-mode timeout margins — NOT divergences

`pr63209.c`, `pr69320-4.c` (and the pr63209 CERB_TIMEOUT flip):
exhaustive interleaving sets with 100+ executions; verified AGREE on
the full verdict sequence with raised timeouts (pr69320-4 at 60s,
pr63209 at 90s). The Lean interpreter is roughly
15-20x slower than the oracle on recursion-heavy shapes (probe:
50k-deep recursion, oracle ~2s vs Lean ~35s, same answer). Perf
constant, no semantic content. No fix needed for parity; the constant
matters for corpus economics (priced L to chase seriously, don't).

## 4. Beyond the testset — 52 probe programs

All in `tests/parity-probes/probes/`, run via `run_probe.sh`
(libc mode unless noted). Verbatim one-line verdicts from the runner.

**AGREE (both engines, same answer/UB):** anonymous struct+union in
struct (42), comma-heavy sequencing (21), compound literals incl.
struct literal argument (12), designated initializers nested +
array-index form (27), enum INT_MAX/negative (3), flexible array
member via malloc (6), _Generic (321), string-literal array inits +
sizeof (7), long double arithmetic (6), one-past-end pointer loop
(14), 50k recursion (42), unsequenced `i=i++ +1` → **both**
UB035_unsequenced_race, struct-by-value return (42), Duff's device
(10), varargs int/double/pointer (37), va_copy (42), volatile +
restrict qualifiers (9), goto into loop body (23), static locals
(42), `INT_MIN/-1` → both UB045c, `1<<32` → both UB51b, `x<<-1` →
both UB051a, unsigned wraparound (2), union type punning (5),
memmove overlapping both directions (15), calloc zeroing (42), char
signedness via CHAR_MIN (42), uintptr_t roundtrip (42), _Bool
conversions (see suspect below), function-pointer decay/deref/call
matrix — sequenced (37), snprintf truncation (9 — see suspect),
strtol simple (42), qsort with callback (53), sprintf %d%x%05d →
both die with the SAME `TODO: snprintf()` message (oracle failwith =
Lean panic; message-level parity even in the crash), argv via the
new `--args` flag on both drivers (226), printf `%.2f`/`%g` → both
`Undefined {ub: Invalid_format[...]}`.

**PARITY GAP (Lean wrong):** fgetc_eof (10 vs 2), fseek_read (119
vs 42), fread_seq (1 vs 22) — all RC-1. **No non-fs parity gap was
found by any probe.**

**Both-reject (oracle front-end; UNKNOWN territory, not parity):**
bitfields ×3 ("feature not yet supported: bit-fields"), VLA ×3
("variable length array type"), wide strings (parser state 597),
`_Complex` (parser state 716), setjmp.h (`#error … not currently
supported`).

**Both-timeout (exhaustive-mode explosion, both engines
symmetrically):** 4 unsequenced calls in one expression;
3-call strtol probe. Not gaps.

**Oracle-wrong suspects (Lean faithfully mirrors; upstream-tray
candidates):**
1. `_Bool b = 0.5;` yields 0 on BOTH engines (minimized: probe
   returning `b1*10+b2` → `AGREE VAL:Specified(1)`). ISO C 6.3.1.2:
   any scalar comparing unequal to 0 converts to 1. Both engines
   truncate float→int first. Wrong answer, jointly.
2. `snprintf(b,4,"%d",123456)` returns 3 on both; ISO 7.21.6.5
   requires the would-have-been length (6).
3. `0.0/0.0` and `1.0/0.0` → both `UB045a_division_by_zero`; under
   Annex F semantics these are NaN/±inf. Known Cerberus stance
   (Annex-F-agnostic), recorded for completeness.

**Harness fragility found (recorded, not fixed — additive rule):**
a ub string containing a newline (`Invalid_format[%d %.2f\n]`)
defeats `extract_verdict_seq`'s single-line grep in both
`test_ci_sweep.sh:146-152` and `test_exec.sh:322-334`; in the sweep
this would trip the fail-closed "verdict matched but no tokens"
HARNESS ERROR and abort the suite. No current corpus file triggers
it (both sweeps completed); the first float-printf test added to a
lane will. Priced S.

## 5. Csmith, fresh seeds — 320 programs, 0 bugs, and a blast-radius measurement

Three `scripts/fuzz_csmith.sh` lanes with fresh sequential seeds
(disjoint from the in-tree corpus, which is a materialized upstream
corpus, not seed-generated), SKIP_BUILD=1, fresh binaries:

| Lane | Seeds | Flags | Comparable | Match | Bugs |
|---|---|---|---|---|---|
| 1 | 20260831+80 | kit defaults | 12 | 12 | 0 |
| 2 | 20270001+160 | kit defaults | 25 | 25 | 0 |
| 3 | 20280001+80 | kit + --no-unions | 17 | 17 | 0 |

Verbatim summary line (lane 2): `SUMMARY: total=160 match=25
ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0
cerb_skip=135 cerb_floor=0 cerb_inconsistent=0`. Derived total: 320
fresh programs, 54 comparable, 54 match, zero Lean-side findings.

The startling number is the ORACLE skip rate: 83% (266/320, derived),
of which 58% (186/320, derived: 46+95+45 exit-125 rows) are one
oracle frontend crash, `internal error:
Translation called on Ail program with an invalid node` (exit 125).
This is upstream-tray item 08 (nested braced initializers) with a
bigger blast radius than the tray records: the tray's 2-D scalar
control works, but 2-D **struct** arrays crash. Minimized here to 3
lines (`probes/oracle_2d_struct_init.c`):

```c
struct S { unsigned f0; signed char f1; };
static struct S g[1][1] = {{{1,2}}};
int main(void) { return g[0][0].f0; }
```

Fed through the bridge anyway (cabs-json exports fine), the Lean
pipeline dies with the IDENTICAL message (`PANIC …: Translation
called on Ail program with an invalid node`) — the shared .lem
lineage gives message-level parity even inside the defect. Csmith
therefore currently fuzzes the oracle's init desugaring more than the
Lean semantics; fixing tray-08 upstream (or in the fork) would raise
fresh-seed comparable coverage from ~17% to a majority. Recorded as
an addendum candidate for tray item 08.

## 6. Priced, prioritized fix list

| # | Fix | Class | Size | Payoff |
|---|---|---|---|---|
| 1 | CerbFS fail-closed half-fix: loud enosys on any offset-sensitive read path (the header's own registered mover, first half) | RC-1 | S | converts the ONLY wrong-answer channel into loud failures |
| 2 | `--cabs-json` export before desugar (backend/driver/main.ml:254) | bridge | S | unlocks 43 files of translation-time-UB differential coverage |
| 3 | Driver-binary freshness stamp (lem-sync-gate pattern) | trust | S | kills the stale-primed-binary hazard found in §1 |
| 4 | Verdict-extraction newline hardening in the two harnesses | harness | S | removes a fail-closed landmine |
| 5 | CerbFS per-fd offsets honored by read/write (full fix) | RC-1 | M | real file-I/O parity; unblocks tcc/freebsd/suite-fs rows |
| 6 | libc-link TU/global ordering mirrored from oracle | RC-2 | S-M | clears all 6 pnvi STDOUT_DIFFs; address-printing programs align |
| 7 | Chunked/sparse byte representation in CerbMem | RC-3 | M | multi-MB objects; prerequisite for Linux-scale targets |
| 8 | Interpreter perf constant (profile first, per doctrine) | RC-4 | L | corpus economics only; NOT a parity issue — don't start here |

Non-actions, deliberately: bitfields/VLA/wide/complex/setjmp are
upstream front-end features — nothing Lean-side to fix and no
differential signal obtainable until the oracle accepts them;
the oracle-wrong suspects belong in the upstream tray, not in
Lean-side divergence.

## 7. Provenance

- [AGENT] binary re-prime from the coherence worktree (§1); running
  the fresh sweep into `tests/parity-probes/sweep-2026-08-30/`
  instead of overwriting committed results; probe/repro selection;
  all pricing estimates. Derived tallies are labeled derived; quoted
  runner/sweep lines are verbatim.
- [USER] the charge itself (top of report).
- Prior-sweep TSVs (`tests/ci_sweep/results/`, commit `406560515`)
  used only for cross-checking; untouched.
