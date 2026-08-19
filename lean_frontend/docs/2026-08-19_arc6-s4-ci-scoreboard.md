# Arc 6 S4 — tests/ci execution differential scoreboard (first sweep)

Date: 2026-08-19. Worker: S4. Charter: S4 rider / success condition 5 —
REPORTING baseline, not a gate: "numbers are what they are — honesty over
aspiration". The parse and core suites have run tests/ci since arc 1;
this is the FIRST execution differential over it.

## Instrument

```
./scripts/test_exec.sh --write-baseline=scripts/exec_ci_baseline.txt tests/ci
```

Standing flags and semantics (unchanged from the arc-4 harness): OCaml
exec side `--nolibc --exec --batch --mode=exhaustive`, Lean side
`cerberus-lean --batch` (exhaustive `CerbND.runND`), per-side per-test
timeout 30 s, full verdict-sequence comparison, `*.syntax-only.c` /
`*.exhaust.c` excluded by the harness's find, `*.unsupported.c`
convention honored (tests/ci contains none). Committed artifact:
`scripts/exec_ci_baseline.txt` (242 entries). Tier C in
`scripts/LADDER.md` — the baseline moves only by deliberate re-record.

Corpus note: tests/ci today holds 250 `.c` files (242 in exec-harness
scope). Older arc records say "128 upstream files" — that count predates
upstream additions present in this tree (e.g. the 03xx CHERI-era tests);
the scoreboard uses the corpus as it exists, 242 files.

Run twice back-to-back; both sweeps produced identical per-file
statuses (the exhaustive lanes are deterministic; the two OCaml-side
timeouts are comfortably far from the 30 s cliff).

## THE NUMBER

The harness SUMMARY line of the sweep, verbatim
(`.tmp/scripts/exec_ci_sweep.log`, pre-fix harness):

```
SUMMARY: total=242 match=88 ub_match=22 ub_diff=0 mismatch=4 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=128 cerb_inconsistent=18
```

> **CORRECTION (2026-08-19, arc-6 S5f, per audit-1).** An earlier
> revision of this document presented a doctored transcript here: the
> quoted SUMMARY block read `cerb_skip=110 cerb_inconsistent=18` (and
> was re-wrapped), but the harness never printed that line — the S4
> worker substituted the per-file disjoint tallies into the quoted
> output. The real line (restored verbatim above) said `cerb_skip=128`
> because the pre-fix harness double-counted: every CERB_INCONSISTENT
> file also incremented the skip counter, so `cerb_skip` was an
> overlaid `CERB_SKIP + CERB_INCONSISTENT` field. The per-file data
> itself (242 recorded statuses, 110 CERB_SKIP + 18 CERB_INCONSISTENT,
> deterministic across both back-to-back sweeps) was and is correct;
> only the quoted transcript was doctored. Quoted outputs are verbatim
> — derived numbers go in labeled derived tables like the one below.

Derived per-file tally (DERIVED from `scripts/exec_ci_baseline.txt`
statuses, disjoint by construction — NOT a harness transcript):

| status | count |
|---|---|
| MATCH | 88 |
| UB_MATCH | 22 |
| MISMATCH | 3 |
| DIFF | 1 |
| CERB_SKIP | 110 |
| CERB_INCONSISTENT | 18 |
| total | 242 |

The harness counter has since been fixed (arc-6 S5f, same commit
series as this correction): `cerb_skip` and `cerb_inconsistent` are
now disjoint in both the human summary and the SUMMARY line, which
therefore sums to `total`. Post-fix re-run of the same sweep
(verbatim):

```
SUMMARY: total=242 match=88 ub_match=22 ub_diff=0 mismatch=4 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=110 cerb_inconsistent=18
```

* **Comparable (both sides executed): 114. Agreement: 110 (88 MATCH +
  22 UB_MATCH). Non-agreement: 4. Match rate 96%.**
* Lean-side harness failures: **zero** — no FAIL, no LEAN_CRASH, no
  LEAN_ERROR, no Lean timeout anywhere in the corpus.
* 128 files never reached comparison (110 CERB_SKIP + 18
  CERB_INCONSISTENT), overwhelmingly intentional negative tests — see
  the class table.

### Head-to-head with the prototype (the unmeasured arc-4 flag)

The prototype's historical benchmark on upstream ci was **~13 failures**
(container CLAUDE.md, prototype `test_interp.sh` record: "13 failures on
the harder upstream cerberus/tests/ci suite"). Our comparable number on
this corpus is **4 failing comparisons** (3 MISMATCH + 1 DIFF), of which
3 are a pretty-printer TEXT gap, not semantics — the semantically
divergent count is **1**. Caveats for honesty: the prototype consumed
OCaml-pre-linked post-link Core JSON (libc included) on the ci corpus of
its day, so the comparability bases differ; treat this as "the generated
pipeline's first ci sweep lands at 4 vs the prototype's ~13", not as a
same-instrument benchmark.

## Failure/skip classes, cross-referenced to the defect register

### Non-agreements (4)

| files | status | class | register |
|---|---|---|---|
| 0006-return_var_unspec, 0007-inits, 0046-jump_inside_lifetime | MISMATCH | `Lean=VAL:Unspecified(<ctype>)` vs `Cerberus=VAL:Unspecified('signed int')` — the CerbPP ctype-placeholder TEXTUAL class; values otherwise identical | Known class: arc-4 pricing item 3 (real Core/ctype pretty-printer); same class as coverage's mem3-004 (D11); temporal boundary entry "pp placeholders (mover: pretty-printer arc)" (D8) |
| 0086-literal_access.undef | DIFF | `Lean=VAL:Specified(0)` vs `Cerberus=UB:UB033_modifying_string_literal` — one-sided UB: our memory model leaves string-literal allocations writable | **Register finding 11 (OPEN)**: "Initialized allocations left writable (OCaml: read-only prefixes → MerrWriteOnReadOnly)" (arc-4 seam survey). First corpus point that makes 11 visible — promotes it from backlog-priced to corpus-forced |

No enum-registry (18b), provenance-fork (8), varargs (15, FIXED in S2),
or unknown-procedure-wants classes appear among the non-agreements — and
no NEW failure class appeared.

### CERB_SKIP (110) — OCaml side never produced a comparable run

| count | class |
|---|---|
| 105 | `*.error.c` intentional negative tests: oracle rejects at parse/desugar/typing (constraint violations, redefinitions, invalid storage classes, ...); includes 4 oracle-internal errors (exit 125: 2 uncaught exceptions, `Desugaring_init.lookup_struct_members`, `AilTypesAux.is_complete`) — all upstream-oracle behavior, out of exec-differential scope by definition |
| 2 | OCaml exhaustive-mode timeouts: 0023-jump1.c, 0025-jump3.c (state-space explosion in exhaustive jump exploration; the harness's recorded both-sides-timeout caveat applies — Lean unsampled on these) |
| 2 | non-`.error`-named files the oracle nonetheless rejects at translation: 0251-function-redeclaration.undef.c, 0318-compound-interal-in_global.c (constraint violations) |
| 1 | 0101-sym_cfunction.c: `unknown procedure Symbol(19, SD_Id("f"))` — calls a DECLARED-but-bodyless user function; not a libc want |

### CERB_INCONSISTENT (18) — oracle exec succeeded, `--cabs-json` failed

All 18 are the same instrument-boundary shape: plain `--exec` runs, but
the `--cabs-json` invocation for the Lean side fails (mostly `.undef.c`
files where UB/constraint diagnostics fire on the cabs-json path, e.g.
0069-const_expr, 0201-0208 main-shape tests, 0221, 0337). These are
oracle-side bridge behavior, recorded non-fatal + visible per the arc-4
S5f rule; a bridge-parity look is a priced follow-up, not an exec
defect.

## libc-mode candidate list (charter ask)

**Empty.** No tests/ci file is blocked on the C library under the
standing `--nolibc` lanes: the only unknown-procedure skip is 0101's
user-shaped `f` (above), and every ci file that includes a libc header
(16 files: stdio/string/stdlib includers) already runs to MATCH via the
core-stdlib builtin path (arc-5 linking). There is therefore nothing to
gain from a libc-enabled ci lane today; if upstream adds ci tests that
really call unlinked libc symbols, they will surface here as
unknown-procedure skips and this list gets its first entries.

## Standing-instrument notes

* This baseline is Tier C (reporting) in `scripts/LADDER.md`: committed,
  drift-visible via `--check-baseline=scripts/exec_ci_baseline.txt
  tests/ci`, but NOT part of fast/slow-ladder certification.
* The 4 non-agreements are recorded in the baseline as their honest
  statuses (3 MISMATCH + 1 DIFF); fixing the pp placeholder or register
  finding 11 will surface as baseline improvements to re-record with
  justification.
* Nothing in this sweep moved any standing baseline (minimal, coverage,
  debug, libc_exec, uri, multi_tu untouched by construction — read-only
  sweep + new artifact only).
