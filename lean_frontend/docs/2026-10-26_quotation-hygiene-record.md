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
  runtime library directories"). Never classified by suffix alone (fail-closed). The oracle
  refuses WHEN THE LOCATION IS REACHED (it classifies lazily at execution); the port refuses
  the input at import (review P3-1, qualified 2026-10-27).
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
no module written — unless (a) the runtime was given on the command line with the value
`_build/install/default` (either `--runtime=` or `--runtime ` form; the value is checked —
review P3-2) and (b) every source label AND every lexing label of every input is portable:
relative and under the project root (no leading `/`, no `..` component) — the lexing labels
since the pre-merge fix P1-1 (2026-10-27), see the dispositions below. The refusal names
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
launching at load=7.82 20:34:01
PASSED A1 (844.7s)
PASSED A2 (42.4s)
PASSED A3 (98.6s)
PASSED A4 (37.9s)
PASSED A4b (38.2s)
PASSED A4c (3.5s)
PASSED A5 (112.2s)
PASSED A6 (4.2s)
PASSED A6b (3.9s)
PASSED A7 (10.6s)
PASSED A8 (8.9s)
PASSED A9 (17.6s)
PASSED A10 (26.8s)
PASSED A11 (72.2s)
PASSED A12.1 (9.3s)
PASSED A12.2 (6.0s)
PASSED A13 (2.2s)
PASSED A14.1 (172.2s)
PASSED A14.2 (298.2s)
PASSED A15 (625.5s)
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

(Evidence `.tmp/release/20261026T203401.092565Z`, deleted after reading; launched at load
7.82 once the anonymous-members slice's Tier A had finished, per the scheduling note; the
tree is exactly commit `ec136207e` — no working-tree edit between the commit and the run.)

Scheduling note 2 [AGENT 2026-10-26, orchestrator; relayed by the coordinator]: the
anonymous-members slice is at its final gate (its full battery, about two hours); after this
Tier A and its commit, this slice yields the runner until that battery has run — before the
next Tier A: no `release.py` on the box AND a `--mode full` evidence directory newer than this
Tier A's start (20:34:01) under that worktree's `.tmp/release/` (or its log showing
`release rc=`), polled every five minutes — doing the Q4–Q6 edits and focused checks
meanwhile and stacking the Tier As afterwards. Applied as: Q4, Q5 and Q6 are each committed
on green focused checks with "Tier A stacked" stated in the message; ONE Tier A then runs on
the Q6 tree (recorded under Q6 as covering Q4–Q6), followed by the close-out full battery.


Checkpoint commit: `ec136207e` (Tier A lines above were run on that exact tree and added here at the Q4 commit).

## Q4 — the bare-name census speedbump (inner_arg_temps review P2-3)

**What** (`scripts/libc_bare_name_census.py`, `tests/libc/bare_name_census.tsv`,
`scripts/libc_prep.sh --check`/`--selftest`; Tier B row 14 since the pre-merge review's P3-4, see
the dispositions — it was row 1 at this checkpoint): for each libc
transport (`libc`, `libc_inner_arg_temps`) `libc_prep.sh --check` now also prints the `.co`
at `-d5` (every symbol spelled `name{number}`), keeps the procs/funs whose names the pinned
text `tests/libc/<variant>.core` transports, and lists per proc every bare name that maps to
more than one symbol number; the set must equal the reviewed register (variant, proc, name,
count): a new row, a vanished row or a changed count fails loudly. `--selftest` plants three
doctored registers (a row deleted, a phantom row, a count changed), each of which must fail
the census, then runs the real check; `--selftest` is Tier B row 14 (was row 1 via `test_unit.sh`
at this checkpoint; moved at P3-4). A SPEEDBUMP
on the printed spelling, not transport fidelity (VALIDATION, the parameter-identity section);
the principled fix stays the queued transport item.

**The register, derived from the measurement** ([AGENT 2026-10-26]): six rows per variant,
the same six — `decfloat` `carry` (3) and `tmp` (3): block-local declarations in separate
blocks of one function; `div`/`ldiv`/`lldiv` (2 each): the function and the struct tag
`struct div` (different C namespaces) sharing the bare name inside the proc; `vfscanf` `tmp`
(2): two block-local declarations. None is a parameter rebinding (the loader's detector is
silent, correctly) and none was shown live together. The review's counts (7 procs in the
variant dump, 10 in Normal) included procs the `-d5` dump prints from the LINKED RUNTIME
LIBRARIES but the pinned text does not carry: std.core's `rev_listFromStr_aux` /
`rev_listFromArray_aux` (`shifted`), the `closedir_procy` / `readdir_proxy` /
`rewinddir_procy` `dir_ptr` pairs and `unspec_to_zero_proxy` (`n`, `ty`); both engines parse
std.core from its own text, so those are outside the transport the census guards and are
excluded by scoping to the pinned text's proc names (191 procs, 0 funs, per variant). The
unscoped census (every printed proc) gives 11 Normal / 8 variant proc occurrences, the
reviewer's 10 / 7 plus `unspec_to_zero_proxy`.

Verbatim (`libc_prep.sh --selftest`):

```text
libc_prep: OK (libc: pin + regenerated dump == d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a, 4188542 bytes)
libc_prep: OK (libc: lane-loaded staging byte-matches build-tree object)
libc_prep: libc.co version (informational): ocaml:5.4.0+cerb:git-cerberus-lean-v0.1.0-alpha.1-245-gec136207e+mem:concrete
libc_prep: census OK (libc: 191 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
libc_prep: census selftest plant 'deleted' caught (libc)
libc_prep: census selftest plant 'phantom' caught (libc)
libc_prep: census selftest plant 'count' caught (libc)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == 56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac, 4044363 bytes)
libc_prep: OK (libc_inner_arg_temps: lane-loaded staging byte-matches build-tree object)
libc_prep: libc_inner_arg_temps.co version (informational): ocaml:5.4.0+cerb:git-cerberus-lean-v0.1.0-alpha.1-245-gec136207e+mem:concrete
libc_prep: census OK (libc_inner_arg_temps: 191 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
libc_prep: census selftest plant 'deleted' caught (libc_inner_arg_temps)
libc_prep: census selftest plant 'phantom' caught (libc_inner_arg_temps)
libc_prep: census selftest plant 'count' caught (libc_inner_arg_temps)
```

(`libc_prep.sh --selftest` exit 0; the `-d5` dump's debug chatter and `Pp_core` warnings go to
a per-dump stderr log shown only on failure; `libc_prep.sh --jsons` unchanged: 12 metadata
files. The register's provenance paragraph is the file's header.)


Tier A: stacked after the anonymous-members slice's full battery (scheduling note 2); see Q6.

Checkpoint commit: `6e04adad8`.

## Q5 — the csmith-corpus Tier C row for inner_arg_temps (review P2-4)

**What** (`scripts/inner_arg_temps_lane.py --csmith-corpus [--shard K/M]`, through
`scripts/test_inner_arg_temps.sh`; LADDER Tier C row; VALIDATION lane section; TODO): the
lane's fuzz logic over the committed 1669-file csmith corpus — `test_csmith_corpus.sh`'s
materialisation (prefixed copies `sia_`/`sa_`/`smx_` with the `csmith_cerberus.h` shim),
rows single-trace (`--first`), 30 s and 4G per run — every row the switched engine pair on
complete sequences (`same_sequence`) and the oracle's Normal-vs-switched distinct-observation
SET check; both-fail rows re-checked against Normal (`same_failure`). No baseline: a
disagreement fails the row and the run and is a FINDING, never re-baselined. `--shard K/M`
slices the staged names in codepoint order. The corpus size is asserted (1669).

**Wall-time justification, written before the run** ([AGENT 2026-10-26], grind tripwire): a
25-file prefixed sample (12 `small_int_arith`, 12 `small_arrays`, 1 `small_mix`, every 40th
file) of the four runs per file (bridge, oracle switched, Lean switched single-trace, oracle
Normal) took 20.9 s on this box at load ~12 — 3.8 s bridge, 4.4 s oracle switched, 8.1 s Lean,
4.6 s oracle Normal; all 100 runs exit 0 — i.e. ~0.84 s per file. Extrapolated: 1669 × ~1 s
≈ 28 min, plus the lane's fixed overhead (libc metadata export, two dump plants, two mode
probes: ~1-2 min) and the Normal re-runs both-fail rows trigger (the corpus lane records
499 oracle-side `CERB_SKIP` rows: ~500 extra oracle+Lean Normal runs, ~5 min): 35-45 min
sequential, near the one-hour tripwire, so the sweep runs as TWO shards (`--shard 1/2`,
`--shard 2/2`), each ~20 min, run one after the other under the box rule. This is a
measurement sweep over a differential corpus (the practice's named exception), not a grind.

**Two lane refinements found by the sweep** ([AGENT 2026-10-26], both scoped so the row-15
gate is unchanged):
- `cross_mode` (replaces the bare set rule on the cross-mode leg): two complete observation
  sequences compare as SETS as before; two FAILED oracle outcomes compare by `same_failure`
  (resource by class, Error by failure-class token, crash by message) and are reported
  `SAME_FAILURE`, never agreement; complete-in-one-mode/failed-in-the-other is a
  disagreement. The corpus holds rows the oracle fails identically in both modes before
  execution (`Translation called on Ail program with an invalid node`, the corpus lane's
  `CERB_SKIP` class); the set rule alone called those disagreements (the 1/400 smoke shard:
  3 of 5 rows). Gate rows (`four_way`) pin `cross_mode` in the baseline, so a gate row
  changing from `SAME_SET` to `SAME_FAILURE` is a baseline mismatch, red.
- Report-only classification in `--csmith-corpus` mode (`Runner(report_only=True)`,
  `classify(…, report_only)`): a Lean resource outcome where the oracle completed is
  `RESOURCE lean:<kind>` (the Lean Normal control must fail the same way — a switched-only
  slowdown would differ), and an oracle capture that is not a batch observation is
  `INVALID oracle`; both reported by name in the pass line, never agreement, never a
  baseline, and the run does not fail on them. In the gate both still FAIL the row
  (`report_only=False`), and a Lean INVALID capture fails everywhere (a protocol problem on
  the port is a defect regardless of the oracle).

**First full run** (before the second refinement; shard 1 at load ~19.8, shard 2 at ~10;
verbatim `SUMMARY`/`FAIL` lines, evidence 19 G + 11 G of bridge captures, deleted):

```text
=== shard 1/2 start 21:18:42 load=19.75 … exit=1 end 21:49:59
SUMMARY: inner_arg_temps rows=835 AGREE-FIRST=824 BOTH_FAIL=3 RESOURCE oracle:TIMEOUT=6 failures=2
inner_arg_temps: FAIL — failed rows: ['csmith/sa_csmith_70', 'csmith/sia_csmith_1058']
=== shard 2/2 start 21:49:59 load=9.95 … exit=1 end 22:03:40
SUMMARY: inner_arg_temps rows=834 AGREE-FIRST=830 RESOURCE oracle:TIMEOUT=1 failures=3
inner_arg_temps: FAIL — failed rows: ['csmith/sia_csmith_306', 'csmith/sia_csmith_865', 'csmith/smx_csmith_6']
```

The five failed rows, each `CERB_SKIP` in `scripts/exec_csmith_corpus_baseline.txt` (at that
lane's 15 s bound the ORACLE does not finish them; "Lean not reached"), examined:
- `sa_csmith_70`, `sia_csmith_1058`, `sia_csmith_306`: "Lean TIMEOUT where oracle completed"
  — the oracle finished in 23.8 / 18.3 s (switched; Normal 25.6 / 18.5 s) and Lean's
  single-trace run exceeded 30 s; re-run by hand at load ~15: Lean 124 at 30.1 s on all
  three. A resource difference (VALIDATION class (b): never agreement, not a semantic
  finding; both engines are near or over the corpus lane's budget on these rows), not a
  discrepancy of the mode. Reported as `RESOURCE lean:TIMEOUT` by the refinement.
- `sia_csmith_865`: the oracle's SWITCHED run timed out at 30 s where its Normal run
  completed (`Specified(248)`) — a load artefact: re-run by hand, 20.0 s, `Specified(248)`.
- `smx_csmith_6`: oracle exit 1, empty stdout, in BOTH modes the diagnostic
  `smx_csmith_6.c:191:16: error: constraint violation: incompatible pointer types assigning
  to 'signed int*' from 'unsigned int*'` on stderr (outside the batch grammar, hence an
  undecodable capture, `INVALID`); Lean `Error {msg: "typechecking failed at …:191:16-21
  (cursor: 191:14)"}`, exit 1 — the same constraint violation reported by both engines in
  their own formats (the corpus lane's oracle-side `CERB_SKIP`, the gcc lane's
  `SKIP_LEAN_FAIL`). Reported as `INVALID oracle` by the refinement; not a switch finding.

No row disagreed on a served verdict in either mode: every row where both engines completed
within the mode AGREED on the complete single-trace observation (824 + 830 = 1654 rows), and
every oracle cross-mode pair that completed in both modes had the SAME observation set.

**Second full run** (the final figures; after the refinements; verbatim):

```text
=== shard 1/2 start 22:08:27 load=16.15
CSMITH CORPUS PLAN: files=835 of 1669 shard=1/2; single-trace; switched engine pair and cross-mode oracle; no baseline
  RESOURCE lean:TIMEOUT     csmith/sa_csmith_70 cross-mode=SAME_SET
  RESOURCE lean:TIMEOUT     csmith/sia_csmith_1058 cross-mode=SAME_SET
SUMMARY: inner_arg_temps rows=835 AGREE-FIRST=824 BOTH_FAIL=3 RESOURCE lean:TIMEOUT=2 RESOURCE oracle:TIMEOUT=6 failures=0
CSMITH CORPUS PASS: 835 files; no row failed: every switched engine pair matched within its class and every oracle cross-mode pair was SAME_SET or SAME_FAILURE (BOTH_FAIL, RESOURCE and INVALID-oracle rows are never agreement); classes AGREE-FIRST=824 BOTH_FAIL=3 RESOURCE lean:TIMEOUT=2 RESOURCE oracle:TIMEOUT=6; cross-mode SAME_FAILURE=9 SAME_SET=826; report-only rows: ['csmith/sa_csmith_70', 'csmith/sia_csmith_1058']; 1746.83s
=== shard 1/2 exit=0 end 22:37:37 load=19.06
(shard 2 first attempt: SUMMARY as below, then a TypeError in the pass line — an INVALID-oracle row has no cross-mode key and sorted() compared None with str; fixed, shard 2 re-run on the fixed script, evidence of the attempt (11 G) deleted after cross-checking its results.json: the same classes)
=== shard 2/2 rerun start 22:52:03 load=8.43
=== shard 2/2 rerun exit=0 end 23:05:05 load=6.93
CSMITH CORPUS PLAN: files=834 of 1669 shard=2/2; single-trace; switched engine pair and cross-mode oracle; no baseline
  RESOURCE lean:TIMEOUT     csmith/sia_csmith_306 cross-mode=SAME_SET
  RESOURCE lean:TIMEOUT     csmith/sia_csmith_865 cross-mode=SAME_SET
  INVALID oracle            csmith/smx_csmith_6
SUMMARY: inner_arg_temps rows=834 AGREE-FIRST=830 INVALID oracle=1 RESOURCE lean:TIMEOUT=2 RESOURCE oracle:TIMEOUT=1 failures=0
CSMITH CORPUS PASS: 834 files; no row failed: every switched engine pair matched within its class and every oracle cross-mode pair was SAME_SET or SAME_FAILURE (BOTH_FAIL, RESOURCE and INVALID-oracle rows are never agreement); classes AGREE-FIRST=830 INVALID oracle=1 RESOURCE lean:TIMEOUT=2 RESOURCE oracle:TIMEOUT=1; cross-mode SAME_FAILURE=1 SAME_SET=832 none=1; report-only rows: ['csmith/sia_csmith_306', 'csmith/sia_csmith_865', 'csmith/smx_csmith_6']; 779.09s
```

**Figures, derived** (both shards of the second run; 1669 files, every file ran): AGREE-FIRST
1654 (824 + 830: both engines completed the switched single trace and agreed on the complete
observation), BOTH_FAIL 3 (oracle `Translation called on Ail program with an invalid node`
in both modes, Lean a legacy panic; the corpus lane's `CERB_SKIP` class), RESOURCE
oracle:TIMEOUT 7 (the oracle past 30 s in both modes; Lean not compared), RESOURCE
lean:TIMEOUT 4 (`sa_csmith_70`, `sia_csmith_1058`, `sia_csmith_306`, `sia_csmith_865`: the
oracle completed in 18-25 s, Lean past 30 s, in both modes), INVALID oracle 1
(`smx_csmith_6`). Oracle cross-mode: SAME_SET 1658, SAME_FAILURE 10, no leg 1. Zero
disagreements. Wall time: shard 1 1746.8 s at load 16-19, shard 2 779.1 s at load 7-8 (the
first full run: 31 + 14 min) — within the justification above; no shard approached an hour.
Discrepancy findings: NONE (the five report-only rows are resource/format classes, examined
above, and pre-existing `CERB_SKIP` rows of the corpus lane, so no tray draft). Disk:
each sweep's bridge captures are ~16 MB per file; the lane deletes its evidence on success and
I deleted the two retained failure runs (30 G and 11 G) after reading them.

Tier A: stacked after the anonymous-members slice's full battery (scheduling note 2); see Q6.

Checkpoint commit: `61e300f99`.

## Q6 — a richer linked quotation population (Core-quoting re-review P3-2)

**What** (`lean_frontend/test/CoreQuote/inputs/linked/tu1.c`, `tu2.c`;
`test/CoreQuote/CoreQuoteRoundTrip.py`; LADDER row 1; the caesium Core-quotation consumer
note): a two-TU case carrying an enum definition in each TU (`colour`, `shape`), a cross-TU
extern object (`shared_counter`), statics with initializers (`local_init`, `table`) and a
`for` loop, so the libc-linked comparator positions for `enumDefs`, visible objects and loop
attributes carry TU-side values where fixture 001 left them `.empty` on both sides. It joins
row 1 as the user-only multi-TU round trip `MultiRich` (beside `Multi`,
`tests/multi_tu/basic`) and Tier B row 13 as the libc-linked `LinkedRich` round trip with its
own `leanchecker LinkedRichLiteral` replay. Both engines answer `Specified(32)` on the pair
(oracle linked, Lean exhaustive: 8 traces, all 32) — a sanity check, not the test's claim;
the round trip compares the quoted file with a rebuilt original.

Verbatim (row 1's `core-quote-test`; Tier B row 13's `--core-quote-libc`):

```text
core-quote-test --fuel 1000000 (row 1; exit 0; 28 inputs, up from 27):
Rich1-export: exit 0, 0.06s
Rich2-export: exit 0, 0.06s
MultiRich-quote: exit 0, 0.08s
MultiRich-elaborate: exit 0, 2.17s
MultiRich-compare: exit 0, 1.10s
MultiRich round trip: 3.36s
CORE_QUOTE_TOTAL inputs=28; model constructors=216; floating=0; NaN=0; memory-values=0; positions=8514122; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
core-quote-test --fuel 1000000 --libc [--switches=inner_arg_temps] (Tier B row 13; both exit 0; the LinkedRich round trip costs ~130 s per mode, the review's estimate):
=== --libc 
libc sha256: c165410918073f7c01762238e12ff4ec6d527141ec06bc81c7c5508d41fd4873
LinkedLiteral leanchecker: 1.92 seconds; 838948 KB peak RSS; exit 0
Rich1-export: exit 0, 0.05s
Rich2-export: exit 0, 0.06s
LinkedRich-quote: exit 0, 3.07s
LinkedRich-elaborate: exit 0, 127.11s
LinkedRich-elaborate resources: 127.05 seconds; 14423404 KB peak RSS; exit 0
LinkedRich-compare: exit 0, 4.82s
LinkedRich round trip: 135.08s
LinkedRich-kernel-replay: exit 0, 1.99s
LinkedRichLiteral leanchecker: 1.94 seconds; 839100 KB peak RSS; exit 0
CORE_QUOTE_TOTAL inputs=3; model constructors=245; floating=84; NaN=0; memory-values=0; positions=47364; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
exit=0
=== --libc --switches=inner_arg_temps
libc sha256: 6f2514217b637cedd4109b7c9698942a63b07e59f126ef257cabcf1fe10db0ca
LinkedLiteral leanchecker: 1.87 seconds; 837852 KB peak RSS; exit 0
Rich1-export: exit 0, 0.06s
Rich2-export: exit 0, 0.06s
LinkedRich-quote: exit 0, 2.46s
LinkedRich-elaborate: exit 0, 119.62s
LinkedRich-elaborate resources: 119.59 seconds; 13913512 KB peak RSS; exit 0
LinkedRich-compare: exit 0, 4.51s
LinkedRich round trip: 126.66s
LinkedRich-kernel-replay: exit 0, 1.89s
LinkedRichLiteral leanchecker: 1.86 seconds; 838412 KB peak RSS; exit 0
CORE_QUOTE_TOTAL inputs=3; model constructors=245; floating=84; NaN=0; memory-values=0; positions=44454; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
exit=0
```

Tier A — the STACKED run covering Q4, Q5 and Q6 on this tree (scheduling note 2), verbatim:

```text
TIERA_Q6_PLACEHOLDER
```


Checkpoint commit: `9816de840`.

## Close-out

**Commits on `feature/quotation-hygiene`** (base `704c4e697`; charter `1616d46ad`): Q1
`1a521248b`, Q2 `5cd761172`, Q3 `ec136207e`, Q4 `6e04adad8`, Q5 `61e300f99`, Q6
`9816de840`, close-out `CLOSEOUT_COMMIT_PLACEHOLDER`.

**Every change, by file** (file:line references are to the close-out tree):
- `util/cerb_location.ml` `is_library_location` + `library_suffixes` / `has_library_suffix` /
  `realpath_opt` / `resolved_library_dirs` / `library_dir_cache` (Q1).
- `lean_frontend/Main.lean`: `canonicalRuntimeSpelling`, `refuseQuotationRuntime`,
  `portableLabel`, `refuseNonPortableLabels`; `loadLibc (… quiet portableLabels …)` and its two
  `libc`-boundary refusals; `main`'s quoting checks; the `refuseLibraryLocations` docstring (Q1–Q3).
- `lean_frontend/CerbLocation.lean` docstring (Q1). `lean_frontend/CerbStop.lean` `Boundary`
  (Q3). `lean_frontend/CerbStopSites.lean` `memoryRefusal`, `memcpyOverlapTodo`,
  `allocatorAlignmentTodo` (Q3). `lean_frontend/CerbMem.lean` `allocator`'s refusal arm and
  `memcpyM`'s refusal leaf (Q3). `lean_frontend/test/CoreQuote/CoreQuoteCompare.lean`
  `original` (Q2). `lean_frontend/test/CoreQuote/CoreQuoteRoundTrip.py` `export`/`rich_inputs`,
  `MultiRich`, `LinkedRich` (Q6). `lean_frontend/test/CoreQuote/inputs/linked/tu{1,2}.c` (Q6).
- `scripts/check_runtime_resolution.sh` (Q1, Q2); `scripts/check_item_g_refusals.sh` (Q3);
  `scripts/observations.py`, `scripts/test_stops.py`, `scripts/test_observation_lanes.py` (Q3);
  `scripts/libc_bare_name_census.py`, `tests/libc/bare_name_census.tsv`, `scripts/libc_prep.sh`,
  `scripts/test_unit.sh` (Q4); `scripts/inner_arg_temps_lane.py` `csmith_corpus`, `cross_mode`
  (Q5); `scripts/fork_drift_manifest.txt` (Q1); `scripts/LADDER.md` (Q1, Q3–Q6).
- Documents: VALIDATION, README, CONTRACT, TODO, SUPPORTED (unchanged), the design v2 §10
  amendment, the migration TSV, the protocol record's superseded note, tray 58 + INDEX, the
  consumer notes below, this record.

**The amendment, verbatim** (design v2 §10; proposed by the worker, to be ratified at landing):

```markdown
## 10. Amendment — model-level boundaries `libc` and `memory` (2026-10-26)

**Status: proposed by the quotation-hygiene worker [AGENT 2026-10-26]; the operator
ratifies at landing.** Charter `2026-10-26_worker-charter-quotation-hygiene.md` Q3;
record `2026-10-26_quotation-hygiene-record.md`. Implemented on `feature/quotation-hygiene`
together with the migrations below, so that ratification and landing coincide.

§2.2's thirteen boundary literals describe admission (`cli`, `runtime`, `library-location`,
`cabs-json-utf8`, `batch-ub-payload`, `abort-flag`, `fuel-arg`, `address-space-arg`),
configuration (`switches`, `concurrency`, `float-format`) and two model seams (`fs`,
`pnvi`). Two kinds of declared refusal had no honest member. (a) Library-transport
refusals: the inner_arg_temps libc loader's `R-IAT-LIBC-SYMBOL-LOSS` (a procedure of the
dump rebinds a parameter name) and the dump/mode calling-convention mismatch carried
boundary `cli`, item `--libc`, as a stopgap (consumer note
`2026-10-21_consumer-note-cerberus-caesium-inner-arg-temps.md`). (b) The item-G refusals
of the concrete memory model — `memcpy` on overlapping objects and an allocation with an
invalid alignment (CONTRACT D10, [USER 2026-10-20]) — stayed envelope-less legacy panics,
because, as the checkpoint record's integration section found, "none honestly describes
these two semantic-operation refusals" and inventing one would change the schema.

This amendment adds two literals to §2.2's list, which becomes fifteen:

```text
libc memory
```

- `libc` — library transport: a refusal raised while loading, checking or stitching a C
  library dump (`--libc` / `--libc-tu`) in the Lean loader — the text transport's symbol
  identity check and the calling-convention check. Item: the refusal's code
  (`R-IAT-LIBC-SYMBOL-LOSS`, `IncompatibleCallingConvention`). Channel: CLI (one stderr
  envelope, empty stdout, exit 2) — the loader runs before execution. The stopgap spelling
  `cli`/`--libc` is retired; no producer emits it.
- `memory` — a declared refusal in the concrete memory model where upstream left the case
  to a TODO and the fork refuses rather than decides (D10): `memcpy` on overlapping objects
  (item `Concrete.memcpy`) and an allocation with an invalid alignment (item
  `Concrete.allocator`). The item is the operation, `detail.takeWhile (· != ':')` after the
  fixed `Refused: ` prefix — the `pnviRefusal` rule. Channel: the runtime panic boundary
  (the exact LemLib frame, exit 134 under `LEAN_ABORT_ON_PANIC=1`; the oracle's uncaught
  `Failure`, exit 125, beside it). `upstream` cites the TODO (`impl_mem.ml:2636` for the
  copy, `:1253` for the allocator's `quomod`, at `b9aeedcb4`); `see` names D10 and the
  item-G record. The `detail` is `Refused: ` followed by the oracle's exact text, so the
  two engines' texts remain comparable byte for byte through the envelope (the witness
  `scripts/check_item_g_refusals.sh` decodes the envelope and compares).

Not added: a boundary for the union-initializer refusal (D11) — a generated Lem `error`
in the shared desugarer; it stays legacy/unattributed with its named mover
(shared-desugarer refusal mapping, structural-outcome WP2).

Schema consequences. The wire version stays `"1"`: a boundary literal is an enumeration
member, and §2.1 already makes an unknown member a protocol error, so an older decoder
reports the new envelopes as malformed (RED) rather than misreading them, and the new
decoder reads every older capture unchanged. `CerbStop.Boundary` (`text`/`parse`) and
`observations.STOP_BOUNDARIES` both carry the two names; `test_stops.py`'s schema corpus
generates one valid refusal per `STOP_BOUNDARIES` member and drives the Lean parser over
the corpus, so the two sides cannot diverge silently. Producers: `Main.loadLibc` (two
sites), `CerbMem.memcpyM` and `CerbMem.allocator` (through `CerbStopSites.memoryRefusal`;
each leaf keeps its opaque `failwithI` face and its ND node shape — the allocator's
`NDkilled (CerbFail.failStopKill (failwithI …))`, `memcpyM`'s whole-monad `failwithI`
at `memM`; only the rendered text changes, so `CerbMemAllocatorProofs`,
`CerbMemAccessFacts` and `Unit.MemoryAccessProofs` keep every statement — kernel replay
in the record).

Lane policy: unchanged. `pnvi_lane.classify_side` classes a single refusal panic whose
boundary is not `pnvi` INVALID ("unregistered PNVI refusal metadata"), so a `memory`
refusal on a PNVI or inner_arg_temps row is RED, never agreement; immaculate keeps its
coarse `CRASH` token for an attributed refusal panic (no "legacy" note: it is attributed).
Both are planted in `test_observation_lanes.py --stop-policy-only`. No walked corpus holds
an item-G program (both controls were retired with D10), so no baseline moves.
```

**Consumer notes updated** (each with a dated `[AGENT 2026-10-26]` paragraph): caesium
Core-quotation (`2026-10-18_consumer-note-cerberus-caesium-core-quote.md`: Q1 agreement, Q2
enforcement, Q6 population), caesium item-G (`…item-g-refusals.md`: the envelope form),
caesium outcome-protocol (`…outcome-protocol.md`: family table rows), cerberus-sl
outcome-protocol (the two leaves' kernel faces unchanged), caesium inner_arg_temps (boundary
`libc`). Upstream tray 58: remedy implemented in the fork (INDEX row and summary). TODO.md:
the quotation-hygiene follow-up, the `libc` boundary question, the bare-name census and the
csmith fuzzing entries closed. CONTRACT: §1 (one unmigrated D11 site), §3 item-G row, D10
(the envelope form) — no new contract decision: the `libc`/`memory` boundaries are reporting
vocabulary, not a new permitted outcome.

**Kernel replay** (Q3; `lake env leanchecker` from `lean_frontend` under `capped`): `CerbStop`,
`CerbStopSites`, `CerbMem`, `CerbMemAccessFacts`, `CerbMemAllocatorProofs`,
`Unit.MemoryAccessProofs` — each exit 0, no diagnostics. No proof statement changed in this
slice; the arms' message Strings changed under unchanged node shapes and opaque faces.

**The census register** (Q4): `tests/libc/bare_name_census.tsv`, six rows per variant.
**The csmith sweep figures** (Q5): in the Q5 section.

**Full battery** (`python3 scripts/release.py --mode full`, after the stacked Tier A and
after the anonymous-members slice's own battery; `CERB_MEM_MAX=32G`; box rule as amended),
verbatim:

```text
BATTERY_PLACEHOLDER
```

**What broke beyond the charter / what I could not do**: see the report to the orchestrator
(repeated here at close-out): 
- Beyond the charter, found and fixed on the way (each in its checkpoint's section): the
  test rebuild `CoreQuoteCompare.lean` called `loadLibc` with the old arity after Q2 (fixed,
  mirrors the quoting admission); the item-G `refuse-all` plant's Lean stub had to emit ONE
  envelope per run (two PANIC frames are a protocol problem to the codec); the `-d5` dump's
  stderr chatter (Q4) goes to a failure-only log; the bare-name census is scoped to the
  pinned transport text (the review's 7/10 counts included std.core's and other linked
  runtime procs); the sweep (Q5) needed the `cross_mode` same-failure rule and the
  report-only classes to classify the corpus honestly (the row-15 gate is unchanged).
- Box-rule incidents, all recorded in the gate sections: one Q2 Tier A launch at load 12.69
  without the gate check (stopped by PID after about a minute; evidence deleted; re-run
  gated); a stale threshold-8 waiter stopped by PID; my first Q3 build chain masked `lake`'s
  failure behind `tail` (every check against that tree discarded; chain re-run with
  `pipefail`).
- Not done / not possible here: the operator's ratification of the §10 amendment (at
  landing, by design); `test_stops.py --consumer-demo` (needs a caesium checkout; not run);
  `test_upstream_oracle.py --plant` was not run separately at Q1 (row 10's gate passed;
  `--plant` runs in the full battery's row 10); no push (not authorised); the union-initializer
  refusal (D11) stays envelope-less with its WP2 mover, as the charter states.


## Pre-merge review dispositions (2026-10-27)

Review: `/home/dev/projects/cerberus-lean-proj/.tmp/review-qh/2026-10-27_quotation-hygiene-premerge-review.md`
(a fresh reviewer, [AGENT 2026-10-27, reviewer]; verdict MERGEABLE WITH FIXES, on `5b7109e61`).
Each finding, one by one; the fixes form one commit (below), re-verified when the orchestrator
sends the go (the other slice's battery owns the box until then — no build or run before it).

- **P1-1 (Q2; lexing labels unchecked) — FIXED.** `CabsImport.positionLexingFiles` +
  `parseJsonWithAllLabels` (the `lexing_file` field of every position object, sorted);
  `Main.refuseNonPortableLabels (source) (files lexingFiles)` walks source labels, then
  lexing labels, naming the first offending one as "the label" / "the lexing label"; both
  admission sites (`main`'s user TUs, `loadLibc`'s metadata TUs) and the test rebuild
  `CoreQuoteCompare.original` pass both arrays; `refuseLibraryLocations` keeps source labels
  only (the oracle classifies by `Cerb_position.file`). Witness: an input exported from an
  ABSOLUTE source path under the relative runtime with `#line 1 "rel_lx.c"` (its `file`
  labels relative, asserted; its `lexing_file` labels absolute, asserted) — `--quote-core`
  refuses naming the lexing label, no module; `--batch` serves it and agrees with the
  oracle's verdict. The four documents' claim ("every source and lexing label") is now true
  and says so, with the history (VALIDATION §3, README, the caesium note, this record).
- **P2-1 (Q1; `n > m`) — FIXED.** `has_library_suffix` is `String.equal dir d ||
  String.ends_with ~suffix:("/" ^ d) dir` — equality included, the exact mirror of
  `CerbLocation.isLibraryPathSuffix`. Witness: a root-level plant `#line 1
  "/runtime/libcore/plant.h"` — both engines' suffix tests accept it, it cannot be resolved
  (`/runtime` is absent on this box, asserted loudly rather than skipped), so the oracle
  REFUSES when reached (exit 125, the `Failure` naming the label) and the port refuses at
  import. Manifest: the `[source-content]` row of `util/cerb_location.ml` re-pinned
  `776d942e… → 90c87a67…` with a dated NOTE, no `--refresh`. Re-verification at the go:
  the witness, `check_fork_drift.sh`, Tier B row 10.
- **P3-1 (Q1; "both refuse") — FIXED (wording).** The oracle refuses an unresolvable
  suffix-bearing directory when the location is REACHED (lazy, at execution); the port
  refuses the input at import; a refinement in the tolerated direction. Qualified at the
  site comment, VALIDATION §3(c) and in Q1 above.
- **P3-2 (Q2; `--runtime <dir>` accepted) — FIXED (docs match the code).** [AGENT
  2026-10-27] the check is on the VALUE: both CLI forms store it, and the convention's
  intent is the relative runtime, not a token spelling; README, VALIDATION, the caesium
  note, the `refuseQuotationRuntime` docstring and Q2 above now say "the value
  `_build/install/default` in either `--runtime` form".
- **P3-3 (stale cites) — FIXED.** The eight hand-written cites to the old literal rule
  (`CerbLocation.lean` ×3, `CabsImport.lean`, `CoreParser.lean`, `Main.lean` ×3) now say
  "pristine b9aeedcb4 util/cerb_location.ml:512-523" and name the fork's functions
  (`has_library_suffix`, `resolved_library_dirs`, `is_library_location`) rather than moving
  line numbers.
- **P3-4 (Q4; a speedbump wired as a blocking row-1 check) — FIXED (moved).** [AGENT
  2026-10-27, orchestrator; relayed by the coordinator] under the working practices a
  discipline point gets a claim-point report, not a gate: `libc_prep.sh --selftest` moves out
  of `test_unit.sh` (row 1) to Tier B row 14, where a red result is a report at claim points;
  LADDER, VALIDATION and TODO say so. The orchestrator puts the move to the operator at the
  merge ask. I see no reason it must stay in row 1: the transport text pins it guards are
  already content-hashed by every lane that loads them, so the census adds review signal, not
  trust.
- **P3-5 (Q5; the four Lean-timeout rows unmeasured on a quiet box) — TO DO at the go:**
  re-measure `sa_csmith_70`, `sia_csmith_1058`, `sia_csmith_306`, `sia_csmith_865` (Lean
  switched single trace, 30 s, 4G) on the quiet box before the battery; a surviving timeout is
  recorded as a finding (a Lean-vs-oracle resource difference near the budget), never a
  baselined row. Result: P3-5_PLACEHOLDER
- **P3-6 (record skeleton; no Tier A on Q4–Q6) — TO DO at the go:** the stacked Tier A and
  the full battery run on the FIXED tree (this commit), their verbatim lines fill the
  placeholders, and the §10 amendment stays marked proposed until the operator ratifies.
- **Residual (44 vs 41 refuse-all plant count):** the count is not an assertion (the selftest
  requires only that the plant FAILS; the script prints how many witnesses it failed under
  the stub). The record's 41 is from the Q2 tree, the reviewer's 44 from the Q6 tree; the
  witness script did not change between them, so the difference is unexplained at this
  point; on the fixed tree (four more witnesses) the plants catch 37 / 48. The counts are
  not pinned and the plant is caught in every run; left as an observation.

**Re-verification of the fix (2026-10-27, after the orchestrator's first-stage go; load
below 1 at start; OCaml rebuilt and stamped, `make lean-prelude-src`, `capped lake build`
`Build completed successfully (548 jobs).`, Lean stamp recorded), verbatim:**

```text
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 37 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 48 failing witness(es)
check_runtime_resolution: root-level /runtime/libcore plant: oracle refuses when reached (rc 125), port refuses at import
check_runtime_resolution: quotation hygiene: absolute --runtime, CERB_INSTALL_PREFIX-only, absolute-label and absolute-LEXING-label quotations refused (runtime/--runtime); canonical control written (393889 bytes)
check_runtime_resolution: OK (35 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classifier agreement (both engines: suffix AND resolved membership) and execution control, 4 served UB-location agreement pins (./, unprefixed, absolute, libcore), a root-level /runtime/libcore plant refused by both engines, 4 quotation-convention refusals (absolute --runtime, CERB_INSTALL_PREFIX only, absolute source label, absolute lexing label) with the #line-renamed input served by --batch, and the canonical quotation control)
check_fork_content: OK — 93 source files content/mode-pinned
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
scripts/test_stops.py --lean-bin stop-test: Ran 26 tests in 2.501s / OK
core-quote-test --fuel 1000000 (row 1; exit 0):
MultiRich round trip: 3.32s
CORE_QUOTE_TOTAL inputs=28; model constructors=216; floating=0; NaN=0; memory-values=0; positions=8514122; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Independent oracle: passed; {'semantic_agreement': 950, 'matching_failure': 36, 'reviewed_difference': 9, 'interface_agreement': 2}; <worktree>/.tmp/upstream-oracle-ms977iyd/report.json
```

(Row 10: 997 cases, no row moved. A first run of row 10 on this tree reported `failed` with the
SAME class tallies because its `source_unchanged` check saw the working tree change: I edited
this record while the lane was running — my mistake; the lane was re-run on the untouched
tree, quoted above, and both report directories deleted. The P3-5 re-measure, the stacked
Tier A and the full battery wait for the orchestrator's second go.)

