# Prototype test/differential infrastructure — full inventory + migration dispositions

Date: 2026-08-20. READ-ONLY survey worker (write surface: this file only).
Sources surveyed: `cerberus-lean-prototype/` (scripts/, tests/, Makefile,
docs/, its `cerberus/` submodule's tests/ tree), `cerberus-lean/scripts/`
+ `cerberus-lean/tests/`, and the arc-4 records
(`cerberus-lean/lean_frontend/docs/2026-08-19_arc4-prototype-kit-disposition.md`
= the prior disposition table, `.../2026-08-19_arc4-s4b-corpus-scoreboard.md`,
`.../2026-08-19_arc6-s4-ci-scoreboard.md`). No scripts were executed; all
claims are from reading code and records. Operator tips addressed inline,
tagged [USER].

Effort pricing: **S** = <½ worker-day, **M** = 1–2 worker-days,
**L** = slice-scale or larger.

---

## 1. Headline answers

1. **The "big CI suite" runner the operator remembers is real, and it is
   two distinct things** (§3): (a) the prototype's own
   `scripts/test_interp.sh` in whole-tree directory mode
   (`./scripts/test_interp.sh cerberus/tests --nolibc` — a documented
   5,014-file, 1–2-hour differential sweep, results recorded in
   prototype `docs/2026-01-02_FULL_TEST_RESULTS.md`), and (b) the
   cerberus driver's own `tests/run-ci.sh` (expected-file CI runner,
   ci corpus only, oracle-only — no Lean side). Crucially, `run-ci.sh`
   and its whole family (`run.sh`, `run_tcc.sh`, `run-cheri.sh`,
   `run-core.sh`, `run-ocaml.sh`, `tests.sh`) **already exist verbatim in
   cerberus-lean's own `tests/`** (byte-identical to the prototype
   submodule's — verified `diff -q` clean for `run-ci.sh` and `tests.sh`),
   because cerberus-lean IS the cerberus fork. Nothing needs "porting"
   for the oracle side; what does not exist anywhere yet is a **Lean-side
   sweep of the big corpora** (gcc-torture 2,858 / tcc 70 / suite 144 —
   no cerberus-lean script references gcc-torture, run-ci, or tcc:
   grep verified empty).
2. **[USER] float suite** (§4.1): the 69-file corpus was copied verbatim
   (diff -r clean) but is **NOT wired into anything** — no
   `exec_float_baseline.txt`, no ladder entry, no script references
   `tests/float` (grep of `scripts/*.sh` + `LADDER.md`: zero hits), and
   no arc doc records a sweep. The arc-4 disposition was DEFER
   ("S4b, if they run") and the deferral was never picked up. This is the
   cheapest outstanding item (S).
3. **[USER] coverage-focused suite** (§4.2): it is TWO things. The
   199-file `tests/coverage` corpus is ALREADY-PORTED (arc-4 S4b parity
   scoreboard, Tier A gate #3). The prototype additionally has a distinct
   **OCaml-coverage measurement instrument** (`test_coverage.sh` +
   bisect_ppx + dedicated `_opam-coverage` switch) which was SKIPped in
   arc 4 and remains un-ported — correctly, in my judgment, but with a
   revisit trigger (§4.2).

---

## 2. Inventory table — every prototype script/test asset

"Prior arc-4" cites `2026-08-19_arc4-prototype-kit-disposition.md` (D)
and `2026-08-19_arc4-s4b-corpus-scoreboard.md` (S4b).

### 2.1 scripts/

| Asset | What it does | Corpus + size | Comparison semantics | Prior arc-4 | Verdict |
|---|---|---|---|---|---|
| `test_interp.sh` (489 ln) | Differential exec: OCaml cerberus `--exec --batch` vs prototype Lean Core-JSON interpreter. Modes: single file / directory (recursive find) / `--list` / ci-list via cerberus `tests.sh`; `--nolibc`, `--mode=exhaustive\|deterministic`, `--sequentialise`, `--exclude=PAT`; 10 s per-side timeout | default `cerberus/tests/ci`; whole-tree mode = 5,014 files (excludes `*.syntax-only.c`, `*.exhaust.c`, `bmc/`, `cheri-ci/`, `csmith/`, `pnvi_testsuite/`) | return value / UB-code extraction from batch output; MATCH / UB_MATCH / UB_DIFF / DIFF / MISMATCH / TIMEOUT / CERB_SKIP; `.unsupported.c` convention | **PORTED** (D:16) → `scripts/test_exec.sh`, hardened (full-sequence comparison, LEAN_CRASH/LEAN_ERROR, baselines) | **ALREADY-PORTED** (cite D:16). Residual delta: dropped `--mode`/`--sequentialise`/`--nolibc` flags are deliberate + documented in test_exec.sh's header; the dropped **path-exclude list** for whole-tree mode is the one gap that matters for a big-suite sweep (§3.4) — S |
| `common.sh` (116 ln) | Paths, tmp mgmt, cleanup traps, build_lean, portable_hash | — | — | (implicit in port) | **ALREADY-PORTED** (cerberus-lean has its own `scripts/common.sh`) |
| `test_parser.sh` (249 ln) | Cerberus `--json_core_out` → prototype Lean JSON parser; parse-only robustness sweep; error-category top-10 rollup | default `cerberus/tests` whole tree ~5,500 files (~12 min per Makefile help) | parse ok/fail only, no semantics | outside S2 survey list; noted "parser testing is covered by our test_parse.sh/test_core.sh" (D:34-37) | **SUPERSEDED** for its stage (Cabs-JSON bridge + Core text parser have own harnesses at 100%) — but note our `test_parse.sh`/`test_core.sh` run minimal+ci only; whole-tree parse-robustness breadth (~5.5k files) has NO current equivalent. Fold into the big-suite lane (§3.4) rather than porting this script — S as a byproduct |
| `test_pp.sh` (246 ln) | Prototype Core pretty-printer vs `cerberus --pp=core --pp_core_compact`, via its `cerblean_pp --compare` (whitespace-normalizing) | whole tree ~5,500 | textual PP match/mismatch | **SKIP** (D:21) — role subsumed by `test_elab.sh` | **SKIP** (cite D:21). Revisit ONLY when a real Lean Core PP lands (the registered pp-placeholder mover); then this script's compare-tool design (normalizing comparator in the binary, not `diff`) is the model to copy |
| `test_pp_category.sh` (134 ln) | Re-runs PP compare over per-category problem lists (`tests/problem_tests/*.txt`: float_format, impl_brackets, long_double, fvfromint, null_type, flexible_array, other) | curated lists (dir not present in tests/ — generated) | as test_pp | **SKIP** (D:21) | **SKIP** (cite D:21); same revisit trigger. The categorized-known-failure-list *pattern* is worth stealing for any future PP arc |
| `find_pp_mismatches.sh` (150 ln) | Mines `gcc-torture/execute` for one representative file per PP-mismatch category → writes `tests/problem_tests/` | gcc-torture | as test_pp | **SKIP** (D:21) | **SKIP** (cite D:21) |
| `test_coverage.sh` (231 ln) | **OCaml line/expression coverage of the oracle**: builds cerberus with bisect_ppx in a dedicated `_opam-coverage` switch (OCaml 5.1.1, `dune-workspace.coverage`), runs test_interp over minimal/debug/float (+`--ci`), runs tests/coverage directly through the instrumented binary, emits HTML + per-file summary | corpora above; measures `impl_mem.ml` 38%, `core_eval.ml` 52%, `core_reduction.ml` 59% at last record (prototype docs/2026-02-15_COVERAGE_TEST_PLAN.md) | coverage %, not correctness | **SKIP** (D:18) — "orthogonal... needs switch-level setup we deliberately don't do" | **SKIP stands** (cite D:18), with a named revisit trigger: a full-CI-sweep arc that wants to *grow* corpora intelligently would use exactly this instrument to find unexercised oracle paths. Distinct row from the tests/coverage corpus [USER] — see §4.2. Effort if ever revived: M (switch creation is operator-run in this sandbox) |
| `fuzz_csmith.sh` (171 ln) + `gen_csmith.sh` (91 ln) | csmith generation (`--no-argc --no-bitfields`, small size caps, `csmith_cerberus.h` shim) + differential via test_interp; saves bugs/timeouts | random N (default 100) | any FAIL/MISMATCH/DIFF = BUG | **PORT** (D:22); ported + smoked N=25 (S4b) | **ALREADY-PORTED** (cite S4b "csmith smoke"; `cerberus-lean/scripts/fuzz_csmith.sh` header confirms). Scale run = arc-10 S4, already chartered |
| `creduce_interestingness.sh` (47 ln) | creduce predicate: interesting iff Cerberus returns `Specified(0)` but prototype Lean reports "out of bounds"; 10 s timeouts | single file under reduction | one hard-coded bug shape | **DEFER** (D:23) — creduce absent then | **MIGRATE (S)** — creduce is now installed (container CLAUDE.md: "csmith at scale (creduce installed)"). Re-create against test_exec.sh with a *parameterized* interestingness (status class + grep pattern as args, not hard-coded "out of bounds"). Fits arc-10 S0(b)/S4 triage muscle exactly (its charter write surface includes scripts/ csmith kit) |
| `strip_core_json.py` (174 ln) | Shrinks Core-JSON to main-reachable functions (+`--aggressive` location stripping) for the GenProof flow | per-file | n/a | **SKIP** (D:24) — no Core-JSON export in cerberus-lean | **SKIP** (cite D:24); our verification route (arc-7 pinned `--pp=core` dumps + `test_verify.sh`) supersedes the need |
| `test_genproof.sh` (232 ln) | C → Core JSON → strip → generated Lean proof-skeleton file → compiles; `native_decide` proofs | tests/minimal singles | compile-only | outside S2 list; "GenProof out of project scope" (D:34-37) | **SKIP / SUPERSEDED** by the arc-7 verification pipeline (T1-T4, `tests/verify`, statement-TCB gates). Also note its `native_decide` proof method is BANNED here (D14) — the flow is not adoptable as-is even in spirit |
| `test_cn.sh` (168 ln) | CN separation-logic typechecking tests (`.fail.c`/`.smt-fail.c` conventions) | `tests/cn` 46 files | expect-pass/expect-fail | outside S2 list; "CN out of project scope" (D:34-37) | **SKIP** — CN is not in this project's scope; corpus stays where it is |
| `docker_entrypoint.sh` (143 ln) | Docker packaging of the prototype pipeline | — | — | outside S2 list | **SKIP** (packaging, prototype-specific) |
| `scripts/cerberus` wrapper | opam-switch wrapper for the submodule's binary | — | — | — | **ALREADY-PORTED** (cerberus-lean has `scripts/cerberus`) |

### 2.2 Makefile targets (prototype)

Thin wrappers over the scripts above (`test-interp*`, `test-parser*`,
`test-pp*`, `test-cn*`, `test-coverage`, `fuzz`, `test-genproof`,
`test-unit`/`test-memory` = prototype Lean unit tests). Only
migration-relevant observations: `test-interp` runs
**minimal+debug+float+coverage** as the standing lane (i.e. float was a
first-class corpus in the prototype's every-day gate — reinforces §4.1),
and `test-interp-ci` is the big-suite entry point. No target contains
logic not already covered above. Verdict: nothing to port beyond what the
per-script rows say.

### 2.3 tests/ corpora (prototype's own)

| Corpus | Size | Prior arc-4 | Current state in cerberus-lean | Verdict |
|---|---|---|---|---|
| `tests/minimal` | 105 .c | ported pre-arc-4 | 106 (ours adds `106-sizeof-struct-array.c`); Tier A baseline | **ALREADY-PORTED** |
| `tests/debug` | 90 .c (pre-minimized reproducers: conv-, ptr-, unseq-, intfromptr-, float-, struct-…) | **PORT** (D:20) | verbatim (diff -r clean), `exec_debug_baseline.txt`, Tier A gate #4 | **ALREADY-PORTED** (cite S4b) |
| `tests/coverage` | 199 .c / 21 categories | **PORT** (D:17) | verbatim, `exec_coverage_baseline.txt`, Tier A gate #3 | **ALREADY-PORTED** (cite S4b) — see §4.2 |
| `tests/float` | 69 .c | **DEFER** (D:19) | corpus verbatim (diff -r clean) but zero wiring | **MIGRATE (S)** — see §4.1 [USER] |
| `tests/cn` | 46 .c | out of scope | absent | **SKIP** (CN) |
| `tests/csmith` | kit: `csmith_cerberus.h`, `safe_math.h`, `001-int-arith.c`, `interesting_cases/` | **PORT** (D:22) | headers ported (adapted `platform_main_end`, documented); kit lives in `cerberus-lean/tests/csmith/` alongside the upstream csmith corpus dirs | **ALREADY-PORTED except** `interesting_cases/union_unspecified_3014219861.c` — one saved fuzz reproducer never carried over. **MIGRATE (S, trivial)**: run it through test_exec.sh once; keep as a debug-corpus file if it still differentiates |
| `tests/problem_tests` | (generated, not present) | — | — | n/a |

### 2.4 The cerberus submodule's tests/ tree (referenced-not-owned by the prototype)

The prototype references these from its OWN submodule
(`cerberus-lean-prototype/cerberus/tests/…`); the identical tree exists
natively in `cerberus-lean/tests/`. Sizes (counted, prototype submodule ≡
cerberus-lean): gcc-torture 2,858 (execute/ 1,429 + breakdown/ 1,429
pre-triaged copies), csmith 1,669, ci 250, cheri-ci 247, bmc 201,
suite 144, tcc 70, pnvi_testsuite 44, bytes 14, hacl-star 10, examples 5,
freebsd 2. Dispositions in §3 (runners) and §5 (specialist suites).

---

## 3. The CI-runner section [USER tip: "a script that runs the big CI suite"]

### 3.1 What exists — three layers

**(a) Prototype big-suite differential:** `test_interp.sh` directory mode.
`test_interp.sh:168-178` — whole-tree find with exclusions:

```
    echo "Testing all .c files in $TEST_DIR..."
    while IFS= read -r f; do
        TEST_FILES+=("$f")
    done < <(find "$TEST_DIR" -name "*.c" \
        ! -name "*.syntax-only.c" \
        ! -name "*.exhaust.c" \
        ! -path "*/bmc/*" \
        ! -path "*/cheri-ci/*" \
        ! -path "*/csmith/*" \
        ! -path "*/pnvi_testsuite/*" \
        | sort)
```

Invocation (prototype CLAUDE.md): `./scripts/test_interp.sh
cerberus/tests --nolibc -v`, with the warning "Full suite is expensive
(1-2 hours) - only run when user explicitly requests it." Timeout
discipline: flat `TIMEOUT_SECS=10` per side (`test_interp.sh:215`); no
memory caps; no exclude-list file beyond the find patterns + `--exclude=`
basename grep; statuses as in §2.1. The documented full run is prototype
`docs/2026-01-02_FULL_TEST_RESULTS.md`: 5,014 tests, Cerberus itself
passed only 1,505 (the tree is majority oracle-unrunnable), 648 Lean
comparisons, 95% match — i.e. **the big tree's yield is oracle-limited,
~30%,** a fact any port should expect.

**(b) Prototype ci-list mode:** default corpus is `cerberus/tests/ci`
driven by the cerberus tree's `tests.sh` (`test_interp.sh:157-166`
sources it and iterates `citests`, skipping `.syntax-only.c`/`.exhaust.c`).

**(c) The cerberus driver runner:** `tests/run-ci.sh` (116 ln — the
operator's "driver tests/run-ci.sh"). Mechanics (read at
`cerberus-lean/tests/run-ci.sh`, byte-identical to the prototype
submodule copy): sources `tests.sh` (≈209 enabled `citests` + an 11-entry
annotated `skip` array, `tests.sh:212-227`, with reasons like "REAL
BUG(!) -- Desugaring of initializers"); per file runs
`$CERB --nolibc --typecheck-core --exec --batch ci/$file`
(`run-ci.sh:81-85`), then **byte-compares against
`ci/expected/$file.expected`** (result for normal tests, last-line-stripped
stderr for `.error.c`/`.syntax-only.c`; `.undef.c` inverted; `.unsup.c`
greps "feature not yet supported"); tallies `CI PASSED/FAILED`, exits
nonzero on any fail. **Oracle-only** — it tests the OCaml driver, no Lean
anywhere. Companions: `run.sh` (parsing suite + ci-vs-expected + tcc
`*.expect` + `gcc-torture/breakdown/success` with pass criterion
`grep -E "Specified.0.|EXIT"`, JUnit XML output), `run_tcc.sh` (tcc vs
`.expect`, one hard-coded skip: `24_math_library.c` "libc does not
currently implement most floating functions"), `run-cheri.sh`
(cheri-ci via `tests-cheri.sh`), `run-core.sh` (Core PP→re-parse
round-trip, oracle-only), `run-ocaml.sh` (the `cbuild` OCaml-backend
lane — not our backend, ignore). `gcc-torture/run.sh` is bit-rotted
macOS-era (`sed -i ''`, `cproto`) — but `gcc-torture/breakdown/` is a
**pre-triaged classification of all 1,429 execute tests**: success 923,
not_std_compliant 207, not_supported 210, fail 26, limbus 25, undefined
30, invalid 8, with per-class failure taxonomy in `tests/README`. That
breakdown is the ready-made exclude-list for any big sweep.

### 3.2 What is already covered in cerberus-lean

The **ci corpus** differential is DONE and better than the prototype's:
arc-6 S4 swept all 242 in-scope tests/ci files through `test_exec.sh`
(`exec_ci_baseline.txt`, 244 lines incl. header; comparable 114, agree
110, the 4 non-agreements classified — vs the prototype's historical ~13
ci failures; see `2026-08-19_arc6-s4-ci-scoreboard.md` incl. its
record-integrity correction). `run-ci.sh` itself needs no port: it's in
our tree and runs the oracle, which is not our test target.

### 3.3 What does NOT exist anywhere yet

A Lean-side sweep of **gcc-torture / tcc / suite / bytes / pnvi /
hacl-star** — zero references in `cerberus-lean/scripts/` (grep
verified). This is the container CLAUDE.md's queued "full-CI-sweep arc"
item, and it is real headroom: gcc-torture/breakdown/success alone is
923 oracle-vetted executable programs, ~9× our current largest exec
corpus.

### 3.4 What porting the big sweep onto test_exec.sh needs

`test_exec.sh` already has the load-bearing pieces: `--list FILE`,
`--exclude=PAT`, `TIMEOUT_SECS` env, `--write/check-baseline=FILE`,
fail-closed status taxonomy, and `*.syntax-only.c`/`*.exhaust.c`
excludes in its find (`test_exec.sh:245-247`). Missing vs the prototype's
whole-tree mode and needed for a sane sweep:

1. **Path excludes** (`bmc/`, `cheri-ci/`, `csmith/`, `pnvi_testsuite/`)
   — its find has none; pointing it at `tests/` root today would ingest
   everything. Cheapest fix: don't add flags — drive per-corpus via
   `--list` files generated from `gcc-torture/breakdown/` classes (S).
2. **Per-corpus baselines** (`exec_torture_baseline.txt` etc.) — the
   mechanism exists; just new Tier C entries in `LADDER.md` (S).
3. **Scale discipline**: 923–2,858 files × ≤30 s × 2 sides needs
   chunking (list-file shards), a lower per-file timeout for the sweep
   lane, and a decision on the known step-runner stack ceiling (~1.5k
   loop iterations, arc-6 S0 register) — torture loops WILL hit it;
   classify as a named bucket, never silent (same rule arc-10 S0 already
   sets for csmith). Memory: per-test caps would need a `capped`-style
   wrapper around the two binaries (the existing `scripts/capped` guards
   builds, not harness runs) (M total).
4. Optional but valuable: an **expected-file lane** (§6 item 4).

Total pricing for a first torture lane (breakdown/success via --list,
reporting mode, baseline committed): **M**.

---

## 4. The two [USER]-tip deep rows

### 4.1 [USER] The float suite — PARTIALLY MIGRATED (corpus only, dead)

* **Corpus**: 69 files, `tests/float/`, copied verbatim into
  cerberus-lean (verified `diff -rq` clean, exit 0). Categories (from
  filenames): literals (001-006), comparisons (010-013…), conversions,
  arithmetic, struct/float interplay (066-068), funcptr-float (069),
  compound assignment (070-073, 078), inc/dec (074-077), ternary (079),
  **nan-inf (080)**. Zero `.undef.c`, zero `.libc.c` — plain
  deterministic-return programs, fully test_exec.sh-shaped.
* **Prototype harness mode**: no specialist harness — it ran through
  `test_interp.sh` like every other corpus, BUT it sat in the prototype's
  standing `make test-interp` lane (Makefile:143-147: minimal, debug,
  float, coverage) and in `test_coverage.sh`'s default dirs — i.e. it was
  gate-grade there.
* **Current status here**: corpus present; **no baseline, no ladder
  entry, no script reference, no recorded sweep** (grep of scripts/,
  LADDER.md, and all arc docs for `tests/float`: only the arc-4 DEFER
  line). The DEFER's condition ("if they run") was never evaluated —
  this fell through the S4b crack while coverage/debug got baselines.
* **Expected-failure caveats for the first sweep** (so reds are read
  correctly): (1) the 078-float-special class is FIXED (arc-6; test_core
  106/106) — parser-level float issues should NOT recur; (2) the
  declared TEMPORAL boundary "upstream float bugs" —
  `lembugs/2026-08-19_upstream-float-mul.md`: upstream
  `Cerb_floating.mul` is addition; our CerbFloat deliberately mirrors
  correct semantics, so **any float-mul differential may show the ORACLE
  side wrong** — such hits are boundary-entry evidence, not Lean
  defects; 072-compound-mul.c is the likely trigger. Ditto the recorded
  float-size boundary entries.
* **Verdict: MIGRATE (S)** — one `test_exec.sh tests/float
  --write-baseline=scripts/exec_float_baseline.txt` run, classify the
  non-MATCHes against the float boundary entries, commit baseline +
  Tier A or Tier C ladder entry (Tier A if clean — it's 69 fast files).
  Fits arc-10 (write surface: corpora/baseline files; floats touch
  CerbFloat/CerbMem, both in-scope) — but note any float FIX beyond
  baseline-recording must respect arc-10's forbidden surfaces.

### 4.2 [USER] The coverage-focused suite — one half ported, one half correctly skipped

* **The corpus** (`tests/coverage`, 199 .c, 21 categories, written
  per prototype `docs/2026-02-15_COVERAGE_TEST_PLAN.md` to target
  specific uncovered oracle code paths in impl_mem/core_eval/
  core_reduction): **ALREADY-PORTED** — arc-4 S4b, verbatim, baselined
  (`exec_coverage_baseline.txt`), Tier A gate #3, currently 183/199
  comparable after arcs 5–6 closed the libc/varargs classes. This is
  the same object the operator remembers; nothing further to migrate.
* **The measurement machinery** (`test_coverage.sh` + bisect_ppx +
  `_opam-coverage` switch + the submodule's `dune-workspace.coverage`):
  a genuinely distinct instrument — it measures which ORACLE expressions
  our corpora exercise (last recorded: impl_mem 38%, core_eval 52%,
  core_reduction 59%, project 30%). Arc-4 SKIP (D:18) stands: it
  measures oracle coverage, not differential correctness, and needs an
  operator-run switch create. **Revisit trigger**: the full-CI-sweep arc
  — coverage-guided corpus growth is exactly how the prototype built
  tests/coverage in the first place (three COVERAGE_ROUND plan docs show
  the loop: measure → write targeted tests → re-measure). If revived: M.
* No third thing found: the prototype has no per-category generators or
  larger hidden coverage corpus (checked scripts/, tests/, Makefile,
  docs/ 2026-02-14/15 series).

---

## 5. Specialist tests — per-item verdicts

| Suite | Size | What it is | Verdict |
|---|---|---|---|
| `tests/float` (prototype-own) | 69 | §4.1 | **MIGRATE (S)** |
| `tests/debug` unseq/float/conv families | (in 90) | already baselined | ALREADY-PORTED |
| gcc-torture | 2,858 (923 pre-vetted "success") | real-program execution, `breakdown/` triage + `tests/README` failure taxonomy | **MIGRATE (M)** as the big-sweep first tranche (§3.4); breakdown/ classes are the exclude-list strategy |
| tcc | 70 + `.expect` files | TinyCC compiler testsuite; heavy libc/printf; `run_tcc.sh` byte-compares stdout vs `.expect` | **MIGRATE (M), post-big-sweep**: newly plausible since arc-6 libc loading + Formatted/printf work; needs a `test_libc_exec.sh`-mode lane and stdout capture comparison (different from batch-verdict comparison). One known oracle skip (24_math_library) |
| suite/ | 144 in 15 topic dirs (concurrency, fs, races, sequencing, memory, typing, …) | upstream by-topic tests | **PARTIAL/DEFER**: sequencing/memory/typing/pointers subdirs fit test_exec.sh today (S to add to a sweep list); concurrency/ + races/ are the declared concurrency boundary (forward-design: do NOT bake their exclusion into a shape that's hard to unwind — keep them list-excluded, not code-excluded); fs/ needs CerbFS parity (defer) |
| pnvi_testsuite | 44 | provenance-semantics (PNVI variants) tests | **SKIP for now**: exercises memory-model variant switches; our exec lane pins one model. Becomes relevant only with a provenance-variant arc. Prototype also excluded it |
| bytes | 14 (+ `.exec`/`.elab` expected files) | byte/uchar representation semantics with recorded expected outputs | **MIGRATE (S) as a micro-lane, low priority**: tiny, has oracle-independent expected files, probes CerbMem byte handling — cheap adversarial value. Prototype never ran it either (not excluded, just unexercised) |
| cheri-ci | 247 | CHERI-C semantics; needs CHERI-enabled build (`run-cheri.sh`/`tests-cheri.sh`) | **SKIP** (out of scope; prototype excluded it) |
| bmc | 201 | bounded-model-checking lane (SMT; `run_bmc_tests.ml`) | **SKIP** (BMC backend out of scope; prototype excluded it) |
| hacl-star | 10 | crypto-kernel real code | **DEFER** to full-CI-sweep arc; same class as libxml2 (which we already do better, gated) |
| freebsd | 2 | scraps | SKIP |
| examples, popl, core | 5 / 0 / 0 | demos/empty | SKIP |
| csmith (upstream corpus) | 1,669 | pre-generated csmith programs in-tree | **note for arc-10 S4**: a free deterministic csmith corpus — sweeping it complements fresh generation (no csmith invocation variance), same triage machinery. S to add as a list-file lane |
| CN (`tests/cn` + test_cn.sh) | 46 | CN typechecking | SKIP (out of scope) |
| PP/round-trip (test_pp*, run-core.sh) | — | §2.1 | SKIP / SUPERSEDED (test_elab.sh; revive with a real Core PP) |
| Sequentialise mode (`--sequentialise`, `make test-interp-seq`) | mode, not corpus | Eunseq-elimination lane | **SKIP for now** (deliberately dropped in the arc-4 port, documented in test_exec.sh header: no sequentialise wiring in the Lean pipeline). Revisit only if a determinization lane is ever wanted for perf; forward-design: nothing depends on its absence |
| GenProof/verified-programs | — | §2.1 | SUPERSEDED (arc-7 verification pipeline) |

---

## 6. Recommended migration slate (prioritized)

Fits-arc-10 = allowed by the arc-10 charter write surface (harness
scripts, csmith kit, corpora/baselines, CerbMem/CerbPP; FORBIDDEN:
relsem/, tests/verify/, CerbND.lean, iris pin).

1. **Float sweep + baseline** — S. Close the only dangling arc-4
   deferral; 69 files, minutes of runtime; classify against the float
   boundary entries (oracle-wrong-on-mul caveat). Fits arc-10 (S0
   triage-table adjacent or a standalone S-slice rider).
2. **creduce interestingness predicate, parameterized, against
   test_exec.sh** — S. Direct arc-10 S0(b)/S4 dependency ("creduce
   interestingness" is named in its shakedown); the prototype script is
   the 20-line template, hard-coded bug shape must become an argument.
3. **Prototype `interesting_cases/` reproducer + upstream in-tree csmith
   corpus as a deterministic list-lane** — S. Feeds arc-10 S4 triage with
   zero generation variance; one file (`union_unspecified_3014219861.c`)
   is a known-once-interesting seed.
4. **gcc-torture "success" lane (923 files) via `--list` +
   `exec_torture_baseline.txt`** — M. The actual "big CI suite" payoff;
   breakdown/-driven list files solve excludes; needs shard/timeout/
   stack-ceiling-bucket discipline (§3.4). This is the spine of the
   queued **full-CI-sweep arc**, not arc-10 (unchartered there, and
   triage volume would compete with csmith triage — but nothing in
   arc-10's forbidden list technically blocks a reporting-mode smoke).
5. **Expected-file lane: Lean `--batch` vs `tests/ci/expected/`** — M.
   Nobody has this: run the Lean pipeline against the driver CI's
   committed expected files (run-ci.sh semantics, §3.1c). It upgrades
   ~200 ci verdicts from "agrees with the oracle binary" to "agrees with
   the oracle's committed record" — an oracle-independent anchor the
   differential harness cannot provide by construction (the OCaml oracle
   is a PERMANENT boundary object; this lane partially routes around
   it). Full-CI-sweep arc material; prerequisite check: how many
   expected files assume libc vs `--nolibc` formatting.

Then, in the full-CI-sweep arc proper: tcc lane (M, libc+stdout
comparison), suite/ tractable subdirs + bytes micro-lane (S each),
whole-tree parse-robustness sweep (S, subsumes test_parser.sh's role),
and optionally the bisect_ppx coverage instrument (M, operator-assisted)
to close the loop on corpus growth.

**Explicitly NOT recommended**: re-porting run-ci.sh/run.sh (already in
our tree, oracle-only), PP suite before a real Core PP exists, CN,
GenProof, cheri/bmc/pnvi lanes, sequentialise mode.
