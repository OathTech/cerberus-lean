# Full upstream CI sweep — scoreboard results

Date: 2026-08-22. Stream: `ci-sweep` (third parallel stream alongside
arc-15's two lanes), worktree `worktrees/cerberus-lean-ci-sweep`, based
on mainline `db7c82f49`. Charter: execute the priced slate of
`notes/2026-08-20_prototype-test-migration-survey.md` (§3.4, §6) — a
Lean-side differential sweep of the big heterogeneous corpora under
`tests/` that no harness had ever run. **This stream is a measurement
instrument: every divergence below is a FINDING to record, none was
fixed here.** Non-gating: no baseline is enforced by the sweep.

## 1. Headline

**2,186 files swept, 1,316 differentially comparable, ZERO semantic
mismatches.** Every file where both the oracle and the Lean pipeline
produced verdicts agreed on the full verdict sequence (values + UB codes
+ ND branch structure), except 7 STDOUT_DIFF rows (§5.1-5.2: 6 are
benign allocation-identity printing, 1 is the known fs-parity gap). The
Lean side failed where the oracle succeeded on exactly 6 files
(2 crashes, 1 error, 3 timeouts — §5.3-5.5), all fail-stop, none
silently wrong. The gcc-torture "success" lane — the survey's spine —
came in at 889/889 comparable agreement.

Two survey items were found ALREADY CLOSED before this stream ran:
`tests/float` and `tests/bytes` were wired in arc-10 S3b (post-survey,
commits `57fe96ab4` / `65f77606c`) as gate-grade Tier-A lanes. This
stream re-ran both (§4, green) instead of re-wiring them.

## 2. Methodology

Instrument: **`scripts/test_ci_sweep.sh`** (new, additive; committed
`4b487ea45`; no existing lane script modified). Design:

* Comparison semantics REPLICATED from `scripts/test_exec.sh` (citations
  in the script header): full verdict-sequence extraction
  (`UB:<code>` / `VAL:<value>` tokens, ordered, both sides),
  exit-code-vs-verdict consistency both sides, fail-closed
  classification. Statuses are the test_exec.sh taxonomy with the
  oracle-failure bucket SUBDIVIDED (CERB_REJECT front-end rejection /
  CERB_ERROR Error-verdict / CERB_TIMEOUT / CERB_CRASH / CERB_SKIP) and
  one new bucket, STDOUT_DIFF (below).
* **libc mode** (all suites except `ci`): oracle runs WITHOUT `--nolibc`
  (loads `runtime/libc/libc.co`); Lean side gets
  `--libc tests/libc/libc.core` + the 12 `--libc-tu` metadata jsons via
  `scripts/libc_prep.sh --jsons` (the test_libc_exec.sh mechanism,
  pin-verified fail-closed at sweep start). Rationale (measured): the
  torture corpus calls libc (`abort`/`exit`/`printf`); under `--nolibc`
  only 2 of the first 10 breakdown/success files were comparable vs
  10/10 under libc mode. `ci` ran `--nolibc` to stay commensurable with
  the committed `exec_ci_baseline.txt`.
* **STDOUT_DIFF** (libc mode only): value-sequences equal but the full
  `Defined {...}` lines (value + stdout + stderr + blocked; loc-free by
  format) differ byte-wise. The `--nolibc` lanes never needed this
  channel (programs there cannot write to stdout); with libc it is a
  real divergence channel. Undefined lines are still compared by ub code
  only (loc strings deliberately differ across the pipelines).
* Discipline: per-test `timeout` 15 s PER SIDE + `ulimit -v` 4 GB per
  test on oracle, cabs-json and Lean invocations; `SKIP_BUILD=1`
  (binaries pre-verified via the full unit gate: `scripts/ce
  ./scripts/test_unit.sh` = "Total: 7 passed, 0 failed" before any
  sweeping); one TSV row appended per file (checkpointed, `--resume`
  verified mid-sweep); exhaustive ND mode both sides.
* Per-file rows: `tests/ci_sweep/results/<suite>.tsv`
  (`suite<TAB>relpath<TAB>status<TAB>detail`), with the machine-grepable
  `SWEEP SUMMARY` line appended as a trailing comment. Console logs kept
  in the worktree `.tmp/ci-sweep-logs/` (uncommitted).
* gcc-torture was swept via `breakdown/` — verified NOT byte-identical
  copies of `execute/`: the breakdown files are the cerberus-ADAPTED
  versions (K&R→ANSI, `#include "cerberus.h"`), so `breakdown/`'s 1,429
  files are the runnable form of all 1,429 execute tests and
  `execute/` itself is skipped (reason recorded in §6).

## 3. Per-suite scoreboard

The `SWEEP SUMMARY` lines below are VERBATIM harness output (also
committed as the trailing comment of each TSV). Zero-count buckets are
present in the lines; the table is a derived condensation (LABELED
derived).

```
SWEEP SUMMARY suite=torture_success mode=libc total=923 match=884 ub_match=5 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=1 lean_error=0 lean_timeout=1 cerb_reject=13 cerb_error=0 cerb_timeout=19 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=ci mode=nolibc total=242 match=91 ub_match=23 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=106 cerb_error=2 cerb_timeout=2 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=18
SWEEP SUMMARY suite=tcc mode=libc total=70 match=62 ub_match=2 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=1 cerb_reject=3 cerb_error=1 cerb_timeout=1 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=suite mode=libc total=144 match=38 ub_match=27 ub_diff=0 stdout_diff=1 diff=0 mismatch=0 lean_fail=0 lean_crash=1 lean_error=0 lean_timeout=0 cerb_reject=50 cerb_error=20 cerb_timeout=2 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=5
SWEEP SUMMARY suite=pnvi mode=libc total=44 match=12 ub_match=26 ub_diff=0 stdout_diff=6 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=hacl_star mode=libc total=10 match=0 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=10 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=freebsd mode=libc total=2 match=1 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=1 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=examples mode=libc total=5 match=0 ub_match=3 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=0 cerb_error=2 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=torture_fail mode=libc total=26 match=0 ub_match=1 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=25 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=torture_limbus mode=libc total=25 match=0 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=25 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=torture_undefined mode=libc total=30 match=0 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=30 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=torture_invalid mode=libc total=8 match=0 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=8 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=torture_not_std_compliant mode=libc total=207 match=8 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=196 cerb_error=0 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=3
SWEEP SUMMARY suite=torture_not_supported mode=libc total=210 match=12 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=1 cerb_reject=195 cerb_error=2 cerb_timeout=0 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=cheri_smoke mode=libc total=240 match=88 ub_match=26 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 cerb_reject=105 cerb_error=2 cerb_timeout=2 cerb_crash=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=17
```

(`cheri_smoke` is the FULL 240-file cheri-ci sweep — it started as a
12-file smoke to verify the planned skip reason, came back 12/12 MATCH,
and was promoted to a full run under the same suite name/TSV; the name
is historical.)

Derived condensation (comparable = match+ub_match+ub_diff+stdout_diff+
diff+mismatch; agree = match+ub_match):

| suite | total | comparable | agree | stdout_diff | Lean-side fail | oracle-limited |
|---|---|---|---|---|---|---|
| torture_success | 923 | 889 | 889 | 0 | 2 (1 crash, 1 timeout) | 32 |
| ci (nolibc) | 242 | 114 | 114 | 0 | 0 | 128 |
| tcc | 70 | 64 | 64 | 0 | 1 (timeout) | 5 |
| suite | 144 | 66 | 65 | 1 | 1 (crash/OOM) | 77 |
| pnvi_testsuite | 44 | 44 | 38 | 6 | 0 | 0 |
| hacl-star | 10 | 0 | 0 | 0 | 0 | 10 |
| freebsd | 2 | 1 | 1 | 0 | 1 (fail) | 0 |
| examples | 5 | 3 | 3 | 0 | 0 | 2 |
| torture_fail | 26 | 1 | 1 | 0 | 0 | 25 |
| torture_limbus | 25 | 0 | 0 | 0 | 0 | 25 |
| torture_undefined | 30 | 0 | 0 | 0 | 0 | 30 |
| torture_invalid | 8 | 0 | 0 | 0 | 0 | 8 |
| torture_not_std_compliant | 207 | 8 | 8 | 0 | 0 | 199 |
| torture_not_supported | 210 | 12 | 12 | 0 | 1 (timeout) | 197 |
| cheri-ci | 240 | 114 | 114 | 0 | 0 | 126 |
| **TOTAL** | **2,186** | **1,316** | **1,309** | **7** | **6** | **864** |

Cross-checks (derived): the `ci` row REPRODUCES the committed
`exec_ci_baseline.txt` exactly — baseline 91 MATCH + 23 UB_MATCH +
18 CERB_INCONSISTENT + 110 CERB_SKIP; the sweep's subdivided buckets
sum back: 106 reject + 2 error + 2 timeout = 110. Oracle-limited =
cerb_reject 766 + cerb_error 29 + cerb_timeout 26 + cerb_inconsistent 43
= 864; 1,316 + 6 + 864 = 2,186. cerb_skip = cerb_floor = cerb_crash =
lean_error = ub_diff = diff = mismatch = **0 in every suite**.

## 4. The two formerly-dead lanes (survey items, found already wired)

Both were wired by arc-10 S3b after the survey was written; this stream
verified them green rather than re-wiring (the charter's "wire the dead
lanes" item dissolves into verification):

* **tests/float** — `./scripts/test_exec.sh
  --check-baseline=scripts/exec_float_baseline.txt tests/float`,
  verbatim tail:
  ```
  SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```
* **tests/bytes** — `./scripts/test_bytes.sh`, verbatim tail:
  ```
  SUMMARY: exec_match=9 neg_pinned=5 fail=0
  ALL AT COMMITTED EXPECTEDS
  ```

## 5. Triaged divergence list

Every non-agreement row where the Lean side was actually observed.
KNOWN = matches a registered class; NEW = first observation.

### 5.1 STDOUT_DIFF: allocation-identity printing — 6 files, pnvi (KNOWN-CLASS, benign)

`pointer_from_integer_2g.c`, `provenance_equality_auto_yx.c`,
`provenance_equality_global_fn_yx.c`, `provenance_equality_global_yx.c`,
`provenance_equality_uintptr_t_global_yx.c`,
`provenance_lost_escape_1.c`. These print pointers with `%p`, which
renders the concrete memory model's internal identities. Verbatim
reproduction (`provenance_equality_global_yx.c`), oracle then Lean:

```
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = false\n", stderr: "", blocked: "false"}
```
```
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@73, 0xffffffffedd0) q=(@72, 0xffffffffedd0)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@73, 0xffffffffedd0) q=(@72, 0xffffffffedd0)\n(p==q) = false\n", stderr: "", blocked: "false"}
```

Return values, ND branch structure (the provenance-equality
nondeterminism: both sides produce exactly the true AND false
executions), and relative address relationships all agree; only the
allocation ids (@69/@68 vs @73/@72) and absolute stack addresses
differ — the two pipelines create different numbers of allocations
before `main` (libc processing differs by construction, the documented
D5 two-artifact libc split). Class: implementation-identity printing,
same nature as the loc-string divergence the harness already excludes.
NOT a semantic finding. Notable positive: **the pnvi suite — excluded
by the prototype and priced SKIP in the survey — is 44/44 observable
with full ND-structure agreement** under the default memory model.

### 5.2 STDOUT_DIFF: `suite/fs/stat.c` — 1 file (KNOWN class: fs parity)

Lean stdout `"0 0 420 1 0 0 0 10\n"` vs oracle
`"2049 1 33261 1 0 0 0 10\n"` (detail row, TSV): `stat()` metadata
fields (st_dev, st_ino, st_mode) — the oracle's sibylfs/CerbFS layer
reports host-like values, our port zeroes them. The survey already
priced `suite/fs` as "needs CerbFS parity (defer)"; this row makes the
gap concrete and cheap to find again. Return values agree.

### 5.3 LEAN_CRASH — 2 files

* **`torture_success/pr44468.c` — NEW FINDING (top of the slate).**
  TSV detail verbatim: `exit 134: PANIC at CerbMem.offsetsof_lemFuel
  CerbMem:327:14: CerbMem.offsetsof: unknown tag (OCaml: Pmap.find
  Not_found)`. The program takes `offsetof(struct R, a)` /
  `offsetof(struct Q, a)` on tags that are otherwise used only through
  pointer casts; the oracle resolves them, our tagDefs lookup does not
  — a tag-environment population gap on the Lean side. Fail-stop (the
  arc-8 loud-failure discipline working as designed), not silently
  wrong. Priced S-M: reproduce via `--cabs-json` + `--batch`, diff the
  tagDefs set both sides for this TU, thread the missing registration.
* **`suite/parsing/array.c`** — `exit 134: INTERNAL PANIC: out of
  memory`: the Lean side exceeded the sweep's 4 GB `ulimit -v` where
  the oracle finished within it. Memory-footprint divergence under
  equal caps, adjacent to the known step-runner scaling register
  (arc-6). Priced S to characterize (re-run uncapped/16G, measure).

### 5.4 LEAN_FAIL — 1 file

* **`freebsd/cat.c`** — Lean `Error {msg: "assert() failure"}` where
  the oracle ran to completion. Real BSD `cat` source; suspected same
  fs-parity family as §5.2 (asserts on file-system state the port
  stubs). KNOWN-class suspected, not confirmed — one-file probe priced
  S.

### 5.5 LEAN_TIMEOUT — 3 files (perf family)

`torture_success/pr69320-4.c`, `tcc/40_stdio.c`,
`torture_not_supported/bitfields/pr20621-1.c`: oracle finished within
15 s, Lean did not. Known family (step-runner throughput, arc-6
register); these three are the corpus's concrete probe points. §7 has
the 60 s refinement.

### 5.6 Oracle-limited buckets (not Lean findings; recorded for the map)

* **CERB_REJECT 766** — oracle front-end rejections: constraint
  violations on pre-C11 idioms, `cerberus.h` gaps (`INT_MAX`,
  `INT64_MIN`, `NULL` redefinitions), GNU extensions. In the breakdown
  pre-triaged classes this is the EXPECTED outcome (fail/limbus/
  undefined/invalid/not_* are 195-30 files of exactly this); in
  torture_success it is 13 files (1.4% pre-triage drift).
* **CERB_ERROR 29** — mostly `"no startup function was declared"`
  (main-less parsing/desugaring tests; 20 in suite/, 2 examples, 1
  tcc) + 2 `va_start`-family unknown-procedure (not_supported, as
  triaged) + 1 `suite/libc/string.c` unknown procedure.
* **CERB_TIMEOUT 26** — oracle >15 s (heavy loops). §7 refines at 60 s.
* **CERB_INCONSISTENT 43** — all of one shape: `exec succeeded but
  cabs-json failed` on `.undef.c`/`.error.c` files (18 ci + 17
  cheri-ci + 5 suite + 3 torture_not_std) — the oracle's exec path is
  more lenient than its own cabs-json export on ill-formed TUs. Known
  from the arc-6 ci scoreboard; the ci-18 are baselined as exactly
  this status.
* **tcc notes**: `24_math_library.c` CERB_REJECT (undeclared `sin`) is
  the upstream runner's own hard-coded skip ("libc does not currently
  implement most floating functions", run_tcc.sh); `60_errors...` is
  main-less by design.

### 5.7 Corpus-growth byproduct: the breakdown taxonomy is stale in our favor

20 files pre-triaged as unrunnable now fully MATCH: 12 in
not_supported — mostly the varargs family (`stdarg-1/2/3.c`,
`va-arg-7/8/24.c`, `va-arg-trap-1.c`, `vfprintf-1.c`, ...) closed by
the arc-6 S2 varargs memops — and 8 in not_std_compliant (6 asm/*, 2
GNU/*). A future re-triage of breakdown/ against OUR pipeline would
promote these into the success lane.

## 6. Not run, and why (no silent caps)

| corpus | size | reason |
|---|---|---|
| `gcc-torture/execute/` | 1,429 | NOT copies: the unadapted K&R-era originals of the same 1,429 tests; `breakdown/` (all classes swept, 1,429 files) is the cerberus-adapted form. Sweeping execute/ would measure the C parser against pre-ANSI syntax, not the semantics. |
| `bmc/` | 201 | BMC backend out of project scope (survey SKIP; prototype excluded it too). |
| `csmith/` in-tree corpus | 1,669 | Already covered by the existing gated lane (`test_csmith_corpus.sh` + `exec_csmith_corpus_baseline.txt`, arc-10). Not re-swept. |
| minimal/debug/coverage/libc_exec/multi_tu/libxml2/uri/cn_coverage/verify | — | Existing gate-grade Tier A/B lanes; out of the sweep's charter. |
| `popl/`, `core/` | 0 | Empty dirs. |

The whole slate fit inside the wall-clock budget; nothing was dropped
for time.

## 7. Timeout refinement (60 s / 120 s re-probes)

All 26 CERB_TIMEOUT files re-probed at 60 s (oracle side, same 4 GB
ulimit), all 3 LEAN_TIMEOUT files at 120 s. Derived tallies (raw lines
in the stream log):

* Oracle: **22 still time out at 60 s** (incl. `ci/0023-jump1.c` +
  `0025-jump3.c` and their cheri-ci twins — consistent, and matching
  their historical exclusion), **2 abort under the 4 GB cap**
  (`suite/parsing/function_argument.c` at 37 s,
  `torture_success/cvt-1.c` at 56 s — oracle-side memory blowups, worth
  noting these are ORACLE resource failures, not Lean's), and **2
  terminate**: `pr63209.c` 14.7 s, `pr65215-2.c` 25.5 s.
* Lean: `pr69320-4.c` terminates at 31.5 s; `bitfields/pr20621-1.c`
  aborts `PANIC: out of memory` under the 4 GB cap at 24 s (joins the
  §5.3 memory family); **`tcc/40_stdio.c` still runs at 120 s** where
  the oracle finishes in well under a second — the sharpest perf probe
  point of the sweep.
* The three loop-heavy terminators were then re-compared with full
  verdict sequences at extended timeouts: `pr69320-4.c`, `pr63209.c`,
  `pr65215-2.c` all **FULL-SEQ EQUAL** (thousands of ND executions,
  byte-equal token sequences; Lean/oracle wall ratio ≈ 3x on
  `pr63209`/`pr65215-2`). Folding these in, comparable agreement rises
  to 1,312/1,319 with still zero semantic mismatches; the residual
  Lean-side rows are exactly: pr44468 (tag gap), array.c + pr20621-1
  (memory), cat.c (fs-suspected), 40_stdio.c (perf).

## 8. Priced follow-up slate (a fix arc's shopping list)

1. **pr44468 offsetsof tag gap** — S-M. The only new hard Lean-side
   defect candidate of the sweep. Reproducer in hand; fix is
   tag-environment population, surface CerbMem/desugar seam.
2. **Lean perf probes** — M. Three concrete LEAN_TIMEOUT files + the
   4 GB-OOM `array.c` as measured step-runner scaling targets; feeds
   the standing stack-ceiling/throughput register (arc-6). Any fix is
   perf work, not semantics.
3. **fs-parity micro-lane** — S to record, M to close. `stat.c` +
   `cat.c` (+ the rest of suite/fs) as a named non-gating lane with
   documented-divergence stat fields; closing it means CerbFS field
   parity.
4. **Baseline the sweep** — S. The TSVs in `tests/ci_sweep/results/`
   are commit-pinned; a follow-up arc can promote per-suite baselines
   (`--check-baseline` mode in test_ci_sweep.sh, ~30 lines) and a
   LADDER Tier C entry, making torture/cheri/pnvi regression-gated.
   Recommended after the perf rows are classified.
5. **breakdown re-triage** — S. Promote the 20 §5.7 files (and demote
   the 13 torture_success CERB_REJECTs) in a fork-local triage list;
   do NOT edit upstream's breakdown/ in place.
6. **Expected-file lane** (survey §6.5) — M. Unchanged: Lean `--batch`
   vs `tests/ci/expected/` records; still nobody has it; still the
   only oracle-independent anchor for the ci corpus. This sweep's
   infrastructure (libc-mode runner) removes one of its prerequisites.
7. **hacl-star** — blocked on include-path/harness work (10/10
   CERB_REJECT at the oracle front-end), same class as the libxml2
   prep scripts; M if wanted, low priority given libxml2 already
   covers the real-code niche.

## 9. Record integrity

* All `SWEEP SUMMARY` blocks and quoted outputs above are VERBATIM
  harness/console output; the condensed tables and totals are DERIVED
  and labeled as such.
* Raw per-file rows: `tests/ci_sweep/results/*.tsv` (committed, one
  row per file + trailing verbatim summary comment).
* Build state verified before sweeping: `scripts/ce ./scripts/test_unit.sh`
  → `Total: 7 passed, 0 failed` on `db7c82f49` + the sweep-script
  commit. No semantics, seam, or gate files were modified in this
  stream; the only writes are the new sweep script, the results TSVs,
  and this document.

## 10. Wall clock (derived from stream logs, UTC)

| phase | span | wall |
|---|---|---|
| build verification (test_unit.sh 7/7) + harness smokes | — | ~10 min |
| batch 1: torture_success / ci / tcc | 21:10:43–21:43:29 | 32 m 46 s (torture_success alone 29 m 43 s) |
| float + bytes lanes + batch 2 (11 suites) | 21:44–21:54:08 | ~10 min |
| cheri-ci full run | — | ~8 min |
| timeout re-probes (60 s / 120 s) + full-seq confirms | — | ~35 min |
| **total measurement wall clock** | | **~1 h 35 m** (budget was 4-5 h; nothing dropped) |
