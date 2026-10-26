# Quotation hygiene and the stop-vocabulary amendment — slice record (2026-10-26)

Branch `feature/quotation-hygiene`, worktree `worktrees/cerberus-lean-feature/quotation-hygiene`,
based on mainline `mdd/cerberus-lean` = `704c4e697` (Lean 4.35.0, lem `e6d8db5`). Charter:
`docs/2026-10-26_worker-charter-quotation-hygiene.md` (committed `1616d46ad`). Worker: a Fable
subagent [AGENT]. Every judgement below that no operator ruling covers is [AGENT 2026-10-26];
the operator's rulings are [USER 2026-10-21] B and C (the Core-quoting D5 re-review,
`docs/2026-10-20_core-quote-d5-rereview.md`) and the standing rules of the container's
working-practices doc. Checkpoints Q1–Q6 each close with a commit; the close-out section
carries the full battery. Quoted machine output is verbatim; derived tallies are labelled.

Build in the worktree before any change (from the repository root, through the container's
`scripts/ce`): `dune build backend/driver/main.exe cerberus-lib.install`, `dune install
--prefix "$PWD/_build/local-install" cerberus-lib`, `dune build cerberus.install`,
`CERB_MEM_MAX=32G ./scripts/capped make lean-native-obj`, `capped lake build CerberusLean
cerberus-lean` (`Build completed successfully (408 jobs).`), speclab `capped lake build`
(`Build completed successfully (150 jobs).`). Clean tree at `1616d46ad`.

## Q1 — the resolved-path library-location rule mirrored into the oracle (ruling B)

**What stood.** The oracle's `util/cerb_location.ml` `is_library_location` (pristine
`b9aeedcb4` :512-523, byte-identical in the fork until this slice) looked
`Filename.dirname path` up LITERALLY in the three keys `Cerb_runtime.in_runtime "libc/include"`
/ `"libcore"` / `"libcore/impls"` — the runtime argument as spelled plus the suffix. The port
(`CerbLocation.isLibraryLocation`, a suffix test; `Main.refuseLibraryLocations`, the import-time
resolved-membership guard, D2b [USER 2026-10-19]) accepted any spelling resolving to a library
directory. So cpp's own `./_build/...` header positions under `--runtime=_build/install/default`
were library on the port and not on the oracle, and the served UB location differed
(`core_eval.lem:602`'s substitution): the D5 pin, oracle `<2:10--2:15>` vs port `<11:10--11:23>`.

**The change** (`util/cerb_location.ml`, `is_library_location` and the four helpers above it;
comment at the site cites the port's rule): the fork oracle classifies a location as library iff
(1) `Filename.dirname path` ends with one of `runtime/libc/include`, `runtime/libcore`,
`runtime/libcore/impls` (`has_library_suffix`, the mirror of `CerbLocation.isLibraryPathSuffix`:
`dir == d || dir.endsWith ("/" ++ d)`) AND (2) `Unix.realpath dir` is one of the realpaths of
this run's three runtime library directories (`resolved_library_dirs`, lazily from
`Cerb_runtime.in_runtime`, the mirror of `Main.refuseLibraryLocations`'s `exact` list).

[AGENT 2026-10-26] decisions, with reasons:
- Suffix AND resolved membership, not resolved membership alone (the charter's wording): the
  port's served rule IS the suffix test, under a guard that refuses suffix-without-membership; so
  on every served input the port = suffix = suffix ∧ member. Membership alone would classify a
  foreign-named symlink to a library directory as library where the port's suffix test says
  not — a divergence in the other direction. With both conjuncts the two engines classify every
  served input identically.
- The suffix is tested first, so user files and `<internal>` (`Loc_other`, `dirname` = `.`)
  never touch the filesystem.
- A suffix-bearing directory that cannot be resolved (`ENOENT`) is REFUSED on the oracle
  (`failwith "Cerb_location.is_library_location: refused - source location ... cannot be resolved
  ..."`, the fork's oracle refusal shape: uncaught `Failure`, exit 125): that is exactly the
  input the port refuses at import ("cannot resolve the source directory"); an unresolvable
  runtime library directory is refused likewise (the port refuses "cannot resolve this run's
  runtime library directories"). Never classified by suffix alone (fail-closed).
- Memoised per directory string (`library_dir_cache`) and the three runtime directories resolved
  once: `core_run.lem:782` tests the location of EVERY thread step; without the cache every step
  would cost realpath syscalls. The lazy forces after `Cerb_runtime.specified_runtime` is set at
  the CLI (the witness's probe sets it explicitly, as before).
- Paths resolve from the process working directory, as the port's do; no label is rewritten.

Probed by hand on the rebuilt oracle (`.tmp`, deleted): the `./`, unprefixed, absolute and
`libcore` `#line` plants all answer `<11:10--11:23>` (the port: the same four); the ghost plant
`#line 1 "./lib/runtime/libcore/plant.h"` is refused (`Failure("Cerb_location.is_library_location:
refused - source location `./lib/runtime/libcore/plant.h' names a directory with a runtime
library suffix that cannot be resolved (`./lib/runtime/libcore'); ...")`); a user file under a
directory merely named `runtime/libcore` stays non-library (`<2:10--2:15>`; the port refuses
that input at import, the Z-67 witness `l1`), so nothing is served divergently.

**The witness** (`scripts/check_runtime_resolution.sh`): the fixture-001 classifier probe now
expects the oracle's actual `is_library_location` TRUE on the `./`-prefixed label (was FALSE),
TRUE on the unprefixed control, and a NEW probe FALSE on the foreign `runtime/libcore` user
directory; the served-divergence pin is now a served AGREEMENT pin over FOUR plants (`dot`,
`nodot`, `abs` = the absolute spelling under the relative runtime, `core` = `libcore`): both
engines must report `<11:10--11:23>`, a plant whose engines disagree is red. The two selftest
plants (`ignore-runtime`, `refuse-all`) catch 30 and 40 failing witnesses. Verbatim:

```text
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 30 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 40 failing witness(es)
check_runtime_resolution: fixture-001 --runtime=_build/install/default: 154 ./-prefixed header positions; oracle library=true; port library=true; oracle without ./=true; oracle on a foreign runtime/libcore directory=false (both engines agree: suffix AND resolved membership)
check_runtime_resolution: served agreement pin (dot): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (nodot): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (abs): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (core): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: OK (27 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classifier agreement (both engines: suffix AND resolved membership) and execution control, 4 served UB-location agreement pins (./, unprefixed, absolute, libcore))
```

**The fork-ahead delta.** `util/cerb_location.ml` was byte-identical to upstream, so the
fork-drift manifest gains a NEW `[files]` row and a NEW `[source-content]` row
(`100644 776d942e10023b990787ba0f302c2b9f810f90a9bf2af3e0d48f119e0616d116 util/cerb_location.ml`)
with a dated header NOTE ("quotation hygiene Q1"), no `--refresh`; `[expected-semantic]`
untouched (no generated-model change). Gate and selftest, verbatim:

```text
check_fork_content: OK — 93 source files content/mode-pinned
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
```

Tray 58 (`docs/upstream-tray/58-relative-runtime-library-location.md`): state line and remedy
section mark the remedy IMPLEMENTED IN THE FORK (the report stands for upstream's literal
rule); INDEX row and summary line updated. VALIDATION §3 gains a "Fork-ahead rule —
library-location classification by resolved directory" inventory entry (0 register rows; the
B10 re-run below); its §3(c) library-location bullet, the in-process-consumers bullet and the
§6 gate-table row now state the mirrored rule and that the admitted divergence class no longer
exists; README's convention bullet, `CerbLocation.lean`'s and `Main.refuseLibraryLocations`'s
docstrings, the caesium Core-quotation consumer note (a dated update paragraph), and LADDER
row 1 likewise.

**The pristine lanes (B10, row 10 of Tier B)** — the pristine binary keeps the literal rule;
every walked corpus runs both engines under one absolute runtime spelling on real files, so no
row was expected to move. Re-run after the change (`python3 scripts/test_upstream_oracle.py`,
through the container's `scripts/ce`, `CERB_MEM_MAX=32G`; the first attempt failed closed on the
oracle freshness stamp because the oracle had been rebuilt by plain `dune build` — re-recorded
with `tools/check_driver_fresh.sh --record-oracle`, then run), verbatim last lines:

```text
Independent oracle: passed; {'semantic_agreement': 950, 'matching_failure': 36, 'reviewed_difference': 9, 'interface_agreement': 2}; <worktree>/.tmp/upstream-oracle-zhsrlqw4/report.json
```

(997 cases; no `difference`/`incomplete` row, i.e. no walked case moved against pristine; the
report directory is ephemeral and deleted. Derived: the register is the 9 reviewed rows the
lane loaded.)


Lean side: `make lean-prelude-src` (sync gate OK), `capped lake build CerberusLean
cerberus-lean` (docstring-only changes to `CerbLocation.lean`/`Main.lean`, both hand-written
copies byte-identical to `generated/`), `tools/check_driver_fresh.sh --record-lean`.

Tier A (`python3 scripts/release.py --mode fast`, `CERB_MEM_MAX=32G`, box load 2.9, no other
`release.py`; evidence `.tmp/release/20261026T182630.780631Z`, deleted after reading), verbatim:

```text
PASSED A1 (820.4s)
PASSED A2 (31.4s)
PASSED A3 (82.1s)
PASSED A4 (30.9s)
PASSED A4b (27.1s)
PASSED A4c (3.2s)
PASSED A5 (108.7s)
PASSED A6 (4.5s)
PASSED A6b (4.0s)
PASSED A7 (11.6s)
PASSED A8 (9.5s)
PASSED A9 (17.6s)
PASSED A10 (18.7s)
PASSED A11 (64.6s)
PASSED A12.1 (5.2s)
PASSED A12.2 (4.7s)
PASSED A13 (1.7s)
PASSED A14.1 (119.6s)
PASSED A14.2 (168.9s)
PASSED A15 (404.6s)
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Checkpoint commit: `1a521248b`.

## Q2 — quotation under non-canonical runtime spellings is refused (ruling C)

**What stood** (the re-review's P3-1): the driver documented the canonical Core quotation
convention (`--runtime=_build/install/default` from the project root) but did not enforce
it: a quotation under an absolute `--runtime`, or of an input exported under one, succeeded
with exit 0 and wrote a literal carrying machine-specific absolute labels (86 and 568 in the
re-review's probes) — a faithful quotation, a non-portable artifact, produced silently. The
only check was `core-quote-test`'s absolute-position census, which a consumer running only
the driver never sees.

**The change** (`lean_frontend/Main.lean`: `canonicalRuntimeSpelling`,
`refuseQuotationRuntime`, `portableLabel`, `refuseNonPortableLabels`; `loadLibc` gains the
`portableLabels : Bool` parameter, passed `quoting`; `main` calls `refuseQuotationRuntime
runtimeArg` right after `resolveRuntime` when quoting, and `refuseNonPortableLabels` before
`refuseLibraryLocations` for every user TU when quoting; `loadLibc` does the same for every
metadata TU). With `--quote-core` or `--quote-libc` the driver REFUSES — a REFUSAL envelope
through `CerbStop.exitRefusals`, boundary `runtime`, item `--runtime`, exit 2, empty stdout,
no module written — unless (a) the runtime was given on the command line as exactly
`_build/install/default` and (b) every source/lexing label of every input is portable:
relative and under the project root (no leading `/`, no `..` component). The refusal names
the offending spelling (`the given spelling is `…``; `the runtime came from
CERB_INSTALL_PREFIX=`…`, not from --runtime`) or the first offending label (the label array
is sorted, so "first" is deterministic). [AGENT 2026-10-26] decisions: the item is
`--runtime` for both halves, as the charter states — the labels an input carries are the
runtime spelling its export ran under; the runtime-spelling check runs before any input is
read, so the round trip's wrong-cwd control (`../_build/install/default` from
`lean_frontend/`) now meets this refusal, whose detail names the convention as the
library-location refusal's did; `./`-prefixed labels (cpp's canonical spelling) and
`<built-in>`-style names are portable; execution (`--batch`) is unaffected and accepts every
spelling under Q1's mirrored classification.

**Witnesses** (`scripts/check_runtime_resolution.sh`, after the agreement pins; the refusal
helper now also checks the item list): an absolute `--runtime` with `--quote-core`; the
runtime from `CERB_INSTALL_PREFIX` only; an input exported under the absolute prefix from an
absolute source path (its labels absolute; the refusal names `…/ub2.c`); each must leave no
module; the canonical control (fixture 001 under `--runtime=_build/install/default` from the
root) must exit 0, silent, with a module beginning `import Core_run_aux`. VALIDATION §3
gains the "Non-canonical quotation invocations" bullet; README's convention bullet and the
caesium Core-quotation consumer note state the rule (a dated update paragraph; the
consumer's recipe already satisfies it).

The test rebuild `test/CoreQuote/CoreQuoteCompare.lean` (`original`, the comparator's
pipeline mirror) takes the new `loadLibc` parameter as `true` and applies
`refuseNonPortableLabels` per user TU, i.e. the quoting driver's admission — its inputs are
canonical exports, and a consumer's `--module --input` pair was admitted by the driver under
the same rule (the first run after the Main change failed to BUILD that module on the old
arity: `Some required targets logged failures: - CoreQuoteCompare`; fixed, re-run).
`scripts/test_stops.py --lean-bin … stop-test`: `Ran 25 tests … OK`.

Verbatim (the witness with its plants — the two plant counts grew from 30/40 to 34/41 with
the four new witnesses; the Core quotation round trip, row 1's `core-quote-test`, whose
wrong-cwd control now meets the Q2 refusal):

```text
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 34 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 41 failing witness(es)
check_runtime_resolution: quotation hygiene: absolute --runtime, CERB_INSTALL_PREFIX-only and absolute-label quotations refused (runtime/--runtime); canonical control written (393889 bytes)
check_runtime_resolution: OK (31 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classifier agreement (both engines: suffix AND resolved membership) and execution control, 4 served UB-location agreement pins (./, unprefixed, absolute, libcore), 3 quotation-convention refusals (absolute --runtime, CERB_INSTALL_PREFIX only, absolute label) and the canonical quotation control)
=== core-quote-test ===
tu-alias-quote: exit 0, 0.08s
tu-wrong-cwd-refusal: exit 2, 0.03s
CORE_QUOTE_TOTAL inputs=27; model constructors=214; floating=0; NaN=0; memory-values=0; positions=8509616; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test PASSED
```

Tier A. Box rule as applied from this run on: the 1-minute load threshold is 12 (the load
on this box is partly external — cerberus-caesium's Lean and Rocq jobs — so a threshold of 8
can stall indefinitely); the other half stands: no other `release.py` on the box
[AGENT 2026-10-26, orchestrator; relayed by the coordinator]. Before that amendment the
first Q2 launch had gone out at load 12.69 without the gate check — above both thresholds;
it was stopped by PID (`release.py` 3599449, cwd verified as this worktree, no child left)
after about a minute and its evidence directory deleted; the run below is the gated re-run
(the waiter re-checks every two minutes). Noted here because it started above 8. Verbatim:

```text
launching at load=8.45 19:19:42
PASSED A1 (846.7s)
PASSED A2 (31.5s)
PASSED A3 (78.2s)
PASSED A4 (25.0s)
PASSED A4b (28.3s)
PASSED A4c (3.3s)
PASSED A5 (110.9s)
PASSED A6 (5.1s)
PASSED A6b (3.9s)
PASSED A7 (16.1s)
PASSED A8 (12.3s)
PASSED A9 (17.6s)
PASSED A10 (19.2s)
PASSED A11 (62.4s)
PASSED A12.1 (5.0s)
PASSED A12.2 (4.8s)
PASSED A13 (1.6s)
PASSED A14.1 (121.1s)
PASSED A14.2 (163.2s)
PASSED A15 (408.7s)
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

(Launched at load 8.45, above 8 and below 12 — noted per the amendment; evidence
`.tmp/release/20261026T191942.154047Z`, deleted after reading. The stale threshold-8 waiter
wrote one interleaved `waiting: load=8.33 others=1` line before it was stopped by PID.)

Scheduling [AGENT 2026-10-26, orchestrator; relayed by the coordinator]: the
anonymous-members slice's runner has been queued behind this slice's; after the Q2 commit
no Tier A of this slice is launched until that worktree's runner has run and finished (no
`release.py` on the box AND a fresh evidence directory under its `.tmp/release/` newer than
the Q2 commit, or at least 30 minutes after the Q2 commit before polling for a free runner);
the Q3 edits and focused checks proceed meanwhile; the rest of the box rule stands.


Checkpoint commit: `5cd761172`.

## Q3 — the stop-vocabulary amendment: boundaries `libc` and `memory`

**The amendment** is §10 of `docs/2026-10-20_outcome-protocol-design-v2.md`, dated
2026-10-26, marked **proposed by the worker [AGENT 2026-10-26]; the operator ratifies at
landing**; its text is reproduced verbatim in the close-out section of this record. In one
sentence: §2.2's thirteen boundary literals gain `libc` (library-transport refusals of the
Lean loader, CLI channel, item the refusal's code) and `memory` (declared refusals of the
concrete memory model where upstream left a TODO, D10; panic channel; item the operation;
`detail` = `Refused: ` + the oracle's exact text; `upstream` the TODO citation); the wire
version stays `"1"` because an unknown member is already a protocol error on every decoder
(an older decoder reports the new envelopes malformed, never misreads them); the
union-initializer refusal (D11) stays legacy with its WP2 mover; lane policy is unchanged.

**Implementation.**
- `CerbStop.lean`: `Boundary` gains `libc | memory`, `Boundary.text`/`parse` the two names.
- `CerbStopSites.lean`: `memoryRefusal (detail) (upstream) : Refusal` (boundary `memory`,
  item `detail.takeWhile (· != ':')` — the `pnviRefusal` rule — mover "upstream's decision on
  the TODO, mirrored in both engines", `see` D10 + the item-G record, `upstream` the given
  citation) and the two citations `memcpyOverlapTodo` (`impl_mem.ml:2636`, the TODO comment)
  and `allocatorAlignmentTodo` (`:1253`, the `quomod`). [AGENT] the first version's mover
  literal was ~120 characters and its `by decide` nonemptiness proof hit `maxRecDepth`
  (kernel evaluation of `String.isEmpty` recurses per character); shortened, no option bump.
- `CerbMem.lean`: `allocator`'s arm is `NDkilled (CerbFail.failStopKill (failwithI
  (CerbStop.render (.refusal (CerbStopSites.memoryRefusal (alignmentRefusal align sz)
  allocatorAlignmentTodo)))))` — the SAME node shape and opaque face, only the String
  differs; `memcpyM`'s leaf `failwithI (CerbStop.render (.refusal (memoryRefusal
  (memcpyOverlapRefusal …) memcpyOverlapTodo)))`, the same whole-monad `failwithI` at `memM`.
  `alignmentRefusal`/`memcpyOverlapRefusal` (the oracle-identical texts) are unchanged.
  TRUST SURFACE: `CerbMemAllocatorProofs` (`allocator_active_sound`,
  `allocator_below_request_kills`), `CerbMemAccessFacts` and `Unit.MemoryAccessProofs` keep
  every statement and proof (no edit; the arm's `simp at h` closes on a kill whatever its
  message); `test/Unit/FuelExemplar.lean`'s `allocator_errno` unchanged.
- `Main.lean`: `loadLibc`'s two refusals are `driverRefusal .libc (some
  "R-IAT-LIBC-SYMBOL-LOSS")` and `.libc (some "IncompatibleCallingConvention")` (were
  `.cli (some "--libc")`); detail texts unchanged.
- `scripts/observations.py`: `STOP_BOUNDARIES` gains the two names. `scripts/test_stops.py`:
  `test_memory_and_libc_boundaries_decode` (a `memory` refusal panic decodes as REFUSAL with
  boundary/item, its detail after `Refused: ` is the oracle's text; a `libc` CLI refusal
  decodes; three misspelt boundaries are malformed); the schema corpus already generates one
  valid refusal per `STOP_BOUNDARIES` member and drives the Lean parser over it, so the two
  sides cannot diverge; the bare-text test (`test_unmigrated_refusal_text_is_unattributed`)
  stands: an envelope-less text is still unattributed.
- `scripts/test_observation_lanes.py --stop-policy-only`: a `memory` refusal panic →
  `pnvi_lane.classify_side` `('INVALID', 'unregistered PNVI refusal metadata …')` and
  `classify_row` INVALID against both an observation and an oracle crash (RED in the PNVI
  and inner_arg_temps lanes, never agreement); immaculate's shell verdict → `CRASH` with no
  stderr note (coarse pin only; `MATCH` against an oracle `CRASH` token, `DIFF` against a
  value) — lane policy unchanged, as the amendment states.
- `scripts/check_item_g_refusals.sh`: the Lean side now captures stdout/stderr separately
  and decodes the capture with the shared codec (`lean_refusal_text`): exactly one REFUSAL
  of boundary `memory` with the expected item, no problem, no legacy panic; the detail after
  `Refused: ` must start with the pinned head and end with the pinned tail, and is compared
  byte for byte with the oracle's `Failure` text (the `*_HEAD`/`*_TAIL` pins are unchanged:
  they are the oracle's text, which did not move). The `refuse-all` plant's Lean stub now
  emits the envelope form, exactly one frame per run (the alignment envelope for `w_alloc_*`
  inputs, the overlap envelope otherwise — a second PANIC frame is a protocol problem to the
  codec, which the first stub version tripped over). The `lean-other-text` plant alters the
  text inside the envelope and is still caught by the byte comparison; `lean-no-abort` by
  the exit check. [AGENT] why the pinned texts moved to the envelope form: the witness's job
  is "one text on both engines"; with the Lean text inside a JSON envelope the comparison
  must decode, not substring-match, or an envelope that merely CONTAINS the text in another
  field would pass.
- `docs/2026-10-20_outcome-protocol-register-migration.tsv` header: the two CerbMem lines
  are MIGRATED (boundary `memory`; `monadic_ascribed`, no register row), the D11 line stays
  UNMIGRATED. CONTRACT §1 (one unmigrated D11 site), §3 item-G row, D10. VALIDATION §3(c)
  item-G passage, the gate-table row, the libc-refusal paragraph. LADDER row 1. TODO.md's
  "dedicated `libc` boundary" entry closed. Consumer notes: caesium item-G (a dated update
  paragraph; the 10-21 clarification marked superseded), caesium outcome-protocol (family
  table rows for D10, D11 and libc; the migration paragraph), cerberus-sl outcome-protocol
  (the two leaves' kernel faces unchanged), caesium inner_arg_temps (boundary `libc`, items
  the codes). The protocol record's integration paragraph carries a dated superseded note.
- `scripts/failure_reach_register.txt`: no change — both leaves sit in `memM`-typed
  declarations (`monadic_ascribed`), outside the pure-site register, as the item-G record
  found; the gate re-run below confirms the pure census unchanged.

**Focused checks** (verbatim; the first Q3 rebuild had failed on the `maxRecDepth` literal
and my build chain masked `lake`'s status behind `tail` — every check run against that
stale tree was discarded and the chain re-run with `pipefail`):

```text
scripts/test_stops.py --lean-bin lean_frontend/.lake/build/bin/stop-test: Ran 26 tests in 2.606s / OK
check_item_g_refusals: selftest plant 'answer' caught: 18 failing witness(es) (= expected 18; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-answer' caught: 19 failing witness(es) (= expected 19; incl. the required witnesses)
check_item_g_refusals: selftest plant 'refuse-all' caught: 10 failing witness(es) (= expected 10; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-no-abort' caught: 12 failing witness(es) (= expected 12; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-other-text' caught: 9 failing witness(es) (= expected 9; incl. the required witnesses)
check_item_g_refusals: OK (19 cases: 6 overlapping memcpy programs (4 in allocations, 2 in device memory) and 3 invalid-alignment allocations refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134, one REFUSAL envelope of boundary memory) with byte-identical texts; 9 controls agree with the oracle (6 non-overlapping copies incl. realloc, an out-of-bounds UB and device memory, aligned_alloc(16, 32), one allocation at each alignment the lanes use, the unchanged size-clause UB); the zero-alignment crash is unchanged on both)
check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly (238 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
check_cli_refusals: OK (unsupported switch sets, mixtures, duplicates, unknown names, placement and repeated options refused; PNVI_ae_udi and inner_arg_temps accepted alone in both forms and agree with their matched-mode oracle witnesses; --call refused under inner_arg_temps; completed runs report the complete switch set on stderr without changing verdict stdout; default control not refused)
test_observation_lanes.py --stop-policy-only: STOP POLICY: memory-boundary refusal panic -> PNVI/inner_arg_temps INVALID (unregistered), immaculate coarse CRASH with no legacy note
test_observation_lanes.py --stop-policy-only: STOP POLICY: 40 invariant/oracle and 15 malformed/oracle pairs RED in both classifiers; ordinary/resource/legacy controls passed
lake build CerberusLean cerberus-lean stop-test memory-access-test allocator-soundness-test: Build completed successfully (422 jobs).
```

**Kernel replay** (`lake env leanchecker <module>` from `lean_frontend`, under `capped`):

```text
leanchecker CerbStop: exit=0 diagnostics-lines=0
leanchecker CerbStopSites: exit=0 diagnostics-lines=0
leanchecker CerbMem: exit=0 diagnostics-lines=0
leanchecker CerbMemAccessFacts: exit=0 diagnostics-lines=0
leanchecker CerbMemAllocatorProofs: exit=0 diagnostics-lines=0
leanchecker Unit.MemoryAccessProofs: exit=0 diagnostics-lines=0
```

Tier A (launched only after the anonymous-members slice's runner, per the scheduling note),
verbatim:

```text
TIERA_Q3_PLACEHOLDER
```
