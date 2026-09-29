# Pre-merge audit: the contract-enforcement range `d62f52121..3d85f64b1` (2026-09-28)

[AGENT: a fresh, skeptical pre-merge auditor (Claude subagent) with no prior context.] Scope approved by the operator, verbatim:
[USER 2026-09-28] "Go ahead with the audit as scoped". Branch `audit/contract-range-20260928` at `3d85f64b1`.
Read-only on the code. This file is the only change. No push.

**Range.** `git rev-list --count d62f52121..3d85f64b1` = **18** commits, not the 24 the brief stated. `d62f52121` is
an ancestor of `3d85f64b1`, so the fast-forward is well-formed. No `.ml`, `.lem`, `runtime/`, `frontend/` or
`backend/` file changes in the range (`git diff --stat` over those paths is empty), so the OCaml oracle at the
mainline is the oracle of the range.

## Verdict: MERGEABLE WITH FIXES (not mergeable as-is at `3d85f64b1`)

The code changes are correct and fail closed: CerbFS refuses all 25 operations, the `reconstructValue` wildcard now
fails where the OCaml asserts, `bounded_integer` fails loudly, `%f` of a NaN refuses, and the `intfromptr` code is net
unchanged. The problems are these:

- **The full ladder is RED at the proposed head** (F1). The range's own claim-point run failed Tier B row 7.
- **The contract's promise is false in one channel the range analysed** (F2): a NaN's bytes are SERVED and differ.
- **The documents that land with the contract contradict it or point at files that do not exist** (F3, F4, F5).

F1 blocks the merge. F2 needs an operator decision before `CONTRACT.md` becomes the public statement. F3–F5 are
document fixes. Everything else is LOW.

## Findings, ranked

### F1: BLOCKER. Full ladder red at `3d85f64b1`: the gcc second oracle rejects the new N1 witnesses

The orchestrator's full-ladder run on this head (log `worktrees/cerberus-lean-arc/contract-enforcement/.tmp/range-full.log`,
read-only) ends, verbatim:

```
FAILED B7 (1490.9s)
...
full: failed; 39/40 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== RELEASE EXIT=1 2026-09-29T01:30:51Z ===
```

B7 is `./scripts/test_gcc_oracle.sh --check-baseline`. Its stdout (release evidence `B7/stdout`), verbatim:

```
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-funptr-int-voidptr.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-funptr-bytes-deviation.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-funptr-int-direct.c DISAGREE/-

Baseline check: 3 regression(s), 0 improvement(s)
FAILED: 3 unresolved DISAGREE row(s) — triage per the design note before anything else
```

Cause: the gcc lane walks `tests/immaculate/nolibc/`. While the funptr-to-integer refusal stood (`440bfd6a2`), these
files crashed on Lean (`SKIP_LEAN_CRASH`, not fatal for a new file). After `8108790ad` they serve the symbol number,
and gcc prints a real address. `scripts/gcc_oracle_baseline.txt` is not touched in the range (last change
`e2fc391f2`, 2026-09-21). `8108790ad` was verified FAST-GATE (Tier A only). The range's last full-ladder pass was on
`835c230b1`, before N1.

Fix: triage the three rows in `scripts/gcc_oracle_baseline.txt` under the gcc design note's triage classes, citing
N1 (the baseline already carries `TRIAGED_ADDR` rows for address-valued programs, e.g. `tests/debug/intfromptr-08-full-addr.c`).
Then re-run the full ladder on the new head and record the verdict lines verbatim.

### F2: HIGH. A NaN's bytes are served and differ from the oracle, and CONTRACT §1/§3 says this cannot happen

Mechanism. The range itself established that `Float.toBits` canonicalizes every NaN (addendum D1 of
`docs/2026-09-28_thin-surface-tests-record.md`). I confirmed it independently in two ways:
- The disassembly of `lean_float_to_bits` in the v4.32.2 `libleanshared.so` is
  `ucomisd; movq; movabs $0x7ff8000000000000; cmovnp`.
- A probe printed `bits=9221120237041090560` for `Float.ofBits 0xfff8000000000000` and for `inf - inf`.
  `Float.toString` gives `NaN` and `toUInt64` gives `0`, so neither offers another route to the sign.

`CerbMem.memValueToBytes` stores a float as `fv.toBits` (`lean_frontend/CerbMem.lean:776`, `:898`). The OCaml stores
`Int64.bits_of_float fval` (`memory/concrete/impl_mem.ml:1190`), which keeps the sign and payload. Storing any NaN
therefore writes different bytes in the two engines.

Measured on the range's Lean binary against the mainline oracle:
- Program: `double inf = 1e309; double n = inf - inf; unsigned char *b = (unsigned char *)&n; return b[7];`
- Oracle `--nolibc --exec --batch --mode=exhaustive`, verbatim: `Defined {value: "Specified(255)", stdout: "", stderr: "", blocked: "false"}`
- Lean `--batch`, verbatim: `Defined {value: "Specified(127)", stdout: "", stderr: "", blocked: "false"}`
- `-(inf - inf)` gives the same pair.

This is a served, different answer: the fifth outcome. It is older than the range and not a regression. But three
places in the range make claims it contradicts:
- CONTRACT §1: "There is no fifth outcome."
- The CONTRACT §3 row "Integer/float/layout implementation choices": SUPPORTED, with only `%f` of a NaN REFUSED.
- The new `CerbFloat.formatFixed` docstring.

The same loss also hits union punning, `memcpy` of a double that has passed through a double load and store, and NaN
payloads, not only the sign. `%f` could never have printed `-nan` correctly in Lean anyway: the variable's store has
already lost the sign.

Suggested fix: an operator decision (the D-series), before `CONTRACT.md` is the public statement. Options:
1. Refuse storing a NaN in `memValueToBytes`, with a witness. This subsumes the `%f` refusal; measure the blast radius
   first.
2. Register the NaN representation as named deviation N2 ([USER]-ruled, class (e)), with a DIFF witness.

Either way, amend the CONTRACT §3 row and the `formatFixed` docstring.

### F3: MEDIUM. VALIDATION §5 still describes a SERVING CerbFS whose op table the range deleted

`lean_frontend/VALIDATION.md:383-392`, verbatim start: "*CerbFS*: an in-memory file-system model that SERVES exactly
the operations it can answer as SibylFS does and REFUSES every other … the op-by-op served/refused table for all 25
`fs_*` entry points is the `CerbFS.lean` header". That table no longer exists (D2 removed it), and every operation
now refuses. Other stale descriptions:
- `lean_frontend/TODO.md:642-652`: the "CerbFS real-fs mover + served-pattern probe family" item, about a served
  subset.
- `lean_frontend/CLAUDE.md:260`: "`CerbFS.lean` | In-memory filesystem model".
- The docstring on `CerbFS`'s `Inhabited (Sum FsError α)` instance still says "`panic!` needs an inhabitant"; the
  sites are `failwithI` now.

Fix: restate these as "refused in full (D2)", with a pointer to `docs/2026-09-28_cerbfs-refuse-all-record.md`.

### F4: MEDIUM. The contract and two records cite a served-surface audit that is not in the range

These three places cite `docs/2026-09-28_served-surface-audit.md` as if it were in the tree:
- `CONTRACT.md:140` (D3: "the served-surface audit (§4.2) ran (`docs/2026-09-28_served-surface-audit.md`)")
- `docs/2026-09-28_funptr-int-refusal-record.md:6`
- `docs/2026-09-28_contract-enforcement-builtins-record.md:5`

The file is not in `3d85f64b1`. It exists only on branch `audit/served-surface-20260928` (`1a69ebdb8`). After the
merge, the public contract's D3 evidence link is dead. (`test-depth-map.md:19` cites it by worktree path, which is
also not durable.)

Fix: land the audit record, from its commit, in this range, or cite it commit-qualified.

### F5: LOW-MEDIUM. CONTRACT §3.2 counts were not re-counted after the final fixes

The section says it was re-counted "after the edge-case tests … and the four rows added with the fixes that followed
them". I re-ran the committed census script (`test-depth-map.md` §A.5, verbatim, from the worktree root) on
`3d85f64b1`, plus two extra patterns (`\bexit\s*\(`, `\batexit\s*\(`). Derived comparison:

| §3.2 claim | Measured at `3d85f64b1` |
|---|---|
| `printf("%f")` 0 → **15** (derived) | census `f` 14 hits, less the `uri` false positive = **13** agreement programs. The +2 appear to be `fmt-007`/`fmt-007b`, which are `UNSUPPORTED` refusal pins, not agreement programs; the §3.2 table header says "Counts are gated agreement programs" |
| libc mode "59 single-trace + 2 exhaustive" | **61** libc-first agreement programs (`040`/`041` added later) + 2 exhaustive |
| "61 of the 188 libc functions" | **62** (`atexit` now called directly) |
| `exit` "3" | **4** (`001-exit`, `030`, `031`, `040-atexit-order`) |
| "about 973 (derived: 969 measured plus those four)" | census total **970** (`nolibc-exh` 864, `nolibc-first` 45, `libc-first` 61) + 2 exhaustive = **972** (derived). The record's 969 was itself 967 measured + 2 derived |

These rows match exactly: `realloc`/`memcpy`/`memcmp`/`memset` 16/15/7/5; `%c`/`%x`/`%X`/`%o` 6/8/2/3;
`snprintf` 6; `errno` 4 + 1 = 5; width/precision 23 − 1 = 22; `atexit` 2. The §3.1 "11 files call printf" also
matches (immaculate `printf` 11/6).

Fix: re-count and restate. Do not count refusal pins as agreement.

### F6: LOW. Stale or wrong text left behind by the refusal-then-withdrawal of the funptr-to-integer conversion

- `docs/upstream-tray/46-function-pointer-number-is-a-fresh-supply-artefact.md`, final sentence: "Our port refuses
  the integer cast and registers the byte and `%p` channels". The refusal was withdrawn, so this upstream-facing
  draft is wrong.
- `tests/immaculate/baseline.txt:115-119` still says the conversion "is REFUSED … int-direct/int-voidptr are the
  pinned refusals, DIFF | L=CRASH". The correction comes later, at `:124-126`.
- `tests/immaculate/nolibc/zd-funptr-bytes-deviation.c` says "Pinned DIFF with both values". Only the Lean value is
  pinned.
- N1 (VALIDATION §2b), the byte test's comment and tray 46 cite `impl_mem.ml:1168-1185` for function-pointer bytes.
  Those lines are `repr`'s `MVunspecified`/`MVinteger` arms; the `PVfunction` arm is at `:1203-1215` (the
  served-surface audit had `:1203-1210`).

### F7: LOW. The records cite pre-rebase commits that are not ancestors of the head

`835c230b1` (the D2 full-ladder run), `45a53c421` (the refusal) and `23ee2d23f` are cited in:
- `cerbfs-refuse-all-record.md`
- `funptr-int-refusal-record.md`
- `test-depth-map.md`
- `thin-surface-tests-record.md`
- `scripts/exec_coverage_baseline.txt:348`

None of these commits is an ancestor of `3d85f64b1`. They are reachable only from the local branch
`audit/test-depth-20260928`. `git diff --stat 835c230b1 324aa977c` shows only the mainline docs commits
(`lean_frontend/CLAUDE.md`, `scripts/LADDER.md`), so the D2 gate evidence is content-equivalent. But the mapping is not
recorded, and pruning that branch would orphan the citations.

Fix: add the rebase mapping (`835c230b1`→`324aa977c`, `45a53c421`→`440bfd6a2`, `23ee2d23f`→`d96e121b1`) to the
records, or keep the branch as a record.

### F8: LOW. The exhaustive libc rows fail closed, but a recorded VACUOUS row passes the gate

`scripts/test_libc_exec.sh` compares statuses to the baseline with `diff -u`, and `--record-baseline` writes
whatever status occurred. Plant P6 (below) recorded `VACUOUS` for both exhaustive rows and doctored the plant run. The
lane then printed, verbatim:

```
  VACUOUS exhaustive/001-unseq-order-libc: the Lean --first observation equals the exhaustive one
  VACUOUS exhaustive/002-errno-basic: the Lean --first observation equals the exhaustive one
SUMMARY: match=0 diff=2
ALL MATCH RECORDED BASELINE
```

It exited 0. LADDER row 5 ("else VACUOUS (never MATCH)") is literally true, but the lane passes and says "ALL MATCH".
The same holds for recorded DIFF rows (an older pattern).

Fix: fail on any `VACUOUS` status whatever the baseline says, and have record mode refuse to write one.

### F9: LOW. Refusal witnesses pin the crash class, not the refusal; justification notes are not durable

- The immaculate lane's `L=CRASH` covers any `MODEL_FAILURE`/`INTERNAL_ERROR` (`scripts/test_immaculate.sh:106-116`).
  So `zd-fs-*`, `zd-fs-stdin-read` and `zd-any-bounded-int-crash` stay green if Lean fail-stops on these programs for
  an unrelated reason. CONTRACT §4.1's "a return to a silent answer turns a gate red" is accurate. "Pins the refusal"
  overstates it. The same applies to `fmt-007*.unsupported.c`.
- `test_immaculate.sh --record-baseline` rebuilds the header from the script's `echo` lines (`:245-357`). The
  hand-added notes that justify the new DIFF pins (`baseline.txt:111-135`) would be silently dropped at the next
  re-record.
- The lane's OK line still names only the ISO-fix pins, not the 12 DIFF rows.

### F10: LOW. Provenance: agent-called dispositions carry no [AGENT] label

The `%f`-NaN refusal (commit `8108790ad`; thin-surface record, addendum D1) was decided by the agent. So were the
addendum's D3/D4 ("class (a), no action"), D5 ("class (b) permits …") and D6 dispositions. None is labelled [AGENT].
D5 is a resource-direction ruling that the worker explicitly left as "the orchestrator's to apply".

All [USER 2026-09-28] quotes across the range's commit messages and files are consistent, full or trimmed substrings
of one wording each (derived: I extracted and grouped them):
- "D2 refuse FS for now, this seems safer" (28 uses)
- "agree on atexit as you propose"
- "Yeah, (1) is fine"
- "yes, re the decision, agree with (1). Named deviations are okay …"
- "P1-1 - let's measure, then refuse if the blast radius isn't too big."
- D1/D3/D5

### F11: LOW. CONTRACT still presents itself as a draft

- The header reads "DRAFT for operator review", the table column is "State (proposed)", and one "[DECIDE]" remains
  open ("other ABIs OUT OF SCOPE [DECIDE]").
- §4.2 says the audit is "Proposed as a fresh-reviewer pass … before the contract is adopted", although D3 records
  that it ran.
- §4.3/§4.4 are proposals written under "How the contract is enforced".
- Meanwhile D5 makes the document the public statement, linked from both READMEs.

The operator should decide whether it lands as a draft, and tidy the text accordingly.

### INFO

- `tests/libc_exec/exhaustive/001-unseq-order-libc.c` calls `set(1) + set(2)` "unsequenced function calls". Function
  calls are indeterminately sequenced (C11 6.5.2.2p10). The row is still valid.
- The brief's range size (24) does not match the range (18).

## What I verified, and how

- **Code, line by line against the OCaml.**
  - CerbFS: 25 operations (every `val fs_*` operation of `frontend/model/fs.lem`), each an unconditional `failwithI`
    with the `CerbFS refusal (fail-closed fs-model boundary):` prefix. The pure accessors are kept.
  - Driver routing (`frontend/model/driver.lem:355-434`): `write`/`vprintf` fds 1/2 go to stdout/stderr, fd 0 to the
    driver's error, everything else to CerbFS.
  - `reconstructValue` (both forms): the wildcard catches exactly Void, `Array0 _ none`, Function and
    FunctionNoParams. Every other Ctype constructor has an arm, matching `impl_mem.ml:978-983` `assert false`.
  - `bounded_integer`: called only from `core_run.lem:1076-1086` (dead `core_thread_step2`). The live
    `core_reduction.lem:1012-1013` fails. It is absent from the exec-closure register, consistent with that.
  - `formatFixed`: NaN refuses; inf unchanged.
  - **`intfromptr` net diff over the range is comment-only.** `git diff d62f52121..3d85f64b1 -- lean_frontend/CerbMem.lean`
    with comment lines removed leaves only the two `reconstructValue` arms and two cite refreshes in doc comments.
  - Cites checked: `impl_mem.ml:2487-2488`, `:2600-2606`, `:598`, `stdlib.c:192-200`, `core_reduction.lem:1012-1013`,
    `core_run.lem:1076-1086`, and the 36 `builtin` declarations of `std.core` against CONTRACT §3.1 (25 filesystem +
    3 printf + exit + errno + 5 bit builtins + `any_bounded_int` = 36).
- **Registers.** Failure-reach tally recomputed from both register versions (derived):

  | | FS rows (all REACHABLE) | other REACHABLE | other UNREACHABLE | total |
  |---|---|---|---|---|
  | before | 41 | 12 | 170 | 244 |
  | after | 25 | 14 | 170 | 230 |

  This agrees with the records (−41 + 25 FS; `any_bounded_int` UNREACHABLE→REACHABLE; `reconstructValue` +1
  UNREACHABLE; `formatFixed` +1 REACHABLE). The ladder's B11.2 line, verbatim, starts "check_failure_reach: OK (230
  pure failure sites = the 230 register rows exactly". The opaque-census and allowlist edits are consistent (10 → 9;
  1 KEEP + 3 PIN retired).
- **Targeted runs on the range's Lean binary** (the contract-enforcement worktree's
  `lean_frontend/.lake/build/bin/cerberus-lean`, run read-only after the ladder finished), against the mainline
  oracle. All verbatim:
  - `zd-fs-stdin-read`: oracle `Specified(7)`; Lean `PANIC … CerbFS refusal (fail-closed fs-model boundary): read fd 0 count 1024 — …`, rc 134. This reproduces the test-depth-actions record.
  - `fmt-007`: oracle `stdout: "[-nan|-nan| -nan]\n"`; Lean `PANIC … CerbFloat.formatFixed: refused — printing a NaN with %f is not supported…`, rc 134.
  - `zd-any-bounded-int-crash`: oracle `internal error: TODO Core_reduction ==> any_bounded_int()` rc 125; Lean `PANIC … TODO Core_reduction ==> any_bounded_int()` rc 134.
  - `zd-funptr-int-direct`: oracle `Specified(530)`, Lean `Specified(47)`. The N1 offset of 483 holds on all three
    witness pairs (derived: 530−47, 502−19, 0x283−0xa0).
  - The NaN byte probe of F2.
- **`check_cli_refusals.sh` plants** (driver = the mainline binary; `Main.lean` is unchanged in the range), via
  `CERB_LEAN_BIN_OVERRIDE`:
  - real driver: OK line, identical to the ladder's A1 line;
  - `/bin/false`: 3 FAIL lines, rc 1;
  - a refuse-everything stub: "control refused without a refused flag", rc 1;
  - a wrapper that silently drops `--concurrency`: FAIL for `--concurrency`, rc 1;
  - a wrong-message stub for `--switches`: 2 FAIL lines, rc 1;
  - a missing binary: "driver not built", rc 1.

  Every plant turned it red. It is fail-closed.
- **Exhaustive libc rows: control and plants.** Run on a scratch `git archive` copy of `3d85f64b1`, restricted to
  the two exhaustive rows, with builds disabled, the mainline OCaml `_build` symlinked read-only, and the range's
  Lean binary.
  - Control: `PLANT exhaustive/001-unseq-order-libc: exhaustive 80 verdicts; Lean --first 1 verdict(s) — differs, as required`, the same for `002` (5 verdicts), `SUMMARY: match=2 diff=0`, `ALL MATCH RECORDED BASELINE`, rc 0. This matches the thin-surface record's line.
  - P1 (oracle not exhaustive): `DIFF` ×2, rc 1.
  - P2 (oracle default + Lean `--first`): `VACUOUS` ×2 (`… 1 execution(s) (< 2)`), rc 1. The record shows `DIFF` for
    `001`; the random oracle draw differs from run to run.
  - P3 (the vacuity check's Lean run without `--first`): `VACUOUS … equals the exhaustive one` ×2, rc 1.
  - P4 (empty exhaustive directory): `FAIL: empty exhaustive corpus: …`, rc 1.
  - P5 (Lean `--first` on the exhaustive row): `DIFF` ×2, rc 1.
  - P7 (exhaustive directory absent): `DRIFT` with both rows missing, rc 1.
  - P6 (VACUOUS recorded): passes, which is F8.

  The `test_upstream_oracle.py` change mirrors the flags for `libc_exec/exhaustive/*` correctly (read; the ladder's
  B10.1 passed with 987 rows).
- **Lanes at the head** (from the orchestrator's ladder run, verbatim):
  - A5 `SUMMARY: match=43 diff=0` / `ALL MATCH RECORDED BASELINE`
  - A3 `Baseline check: 0 regression(s), 0 improvement(s)`
  - A6 `SUMMARY: total=8 match=8 fail=0`
  - B5 "OK: lane matches the committed baseline …"
  - B10.1 `Independent oracle: passed; {'semantic_agreement': 945, 'matching_failure': 33, 'reviewed_difference': 7, 'interface_agreement': 2}`
  - B7 failed (F1).

  I did not re-run the ladder myself (box discipline). These are the orchestrator's evidence, read, not an
  independent re-verification.
- **Baseline rows.** Every moved or added immaculate row has a dated note:
  - D2 moved three rows MATCH→DIFF|CRASH.
  - N1 has four DIFF-with-Lean-value rows plus the MATCH control.
  - `zd-any-bounded-int-crash`, `zd-fs-stdin-read` and the four `ts-*` both-crash pins are new.

  Coverage (+62 plus two `.unsupported` rows), libc_exec (+31) and multi_tu (+6) are justified by the thin-surface
  record and `8108790ad`. No DIFF is pinned without a named reason (N1 or D2). The gcc baseline was never updated (F1).
- **README health warnings.** Both say what they claim: prototype, differential testing samples behaviour, uneven
  depth, a pointer to CONTRACT. They inherit F2's inaccuracy only through the contract link.

## What I could not verify

- The D2 full-ladder verdict tail quoted for `835c230b1`. Its log is gone; I checked only that its tree equals
  `324aa977c` modulo the two mainline docs commits.
- The thin-surface record's historic lane outputs and disagreement probes, other than those I re-ran above.
- The served-surface audit's 58 probes.
- Tier C.
- The orchestrator's gcc-lane re-run, in progress in the other worktree when I finished.
- Whether refusing NaN stores (F2 option 1) has an acceptable blast radius. That needs a measured run.

Scratch (`.tmp/`: the census copy, the probes, the shadow tree and the plant logs) was deleted before this commit.
