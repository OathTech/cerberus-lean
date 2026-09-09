# Batch diagnostic bytes — adversarial audit

[AGENT 2026-09-09] Independent adversarial review of candidate
`9f947a425cad942daa93a4f2a53e3940f2e1aa51` on
`arc/batch-diagnostic-bytes`, against base
`679181d1bbe0ae709ef2c91647d74ab20885edaf`.

**Verdict: PASS within the stated slice. Severity: no new blocking or
nonblocking defect found.** External review and explicit merge approval
remain pending. This audit does not authorize a merge or push.

The reviewer read the container, worktree, and frontend `CLAUDE.md` files;
no applicable `AGENTS.md` was found. All 14 changed files were reviewed:
`CerbEscape.lean`, `CerbFail.lean`, `Main.lean`, frontend `CLAUDE.md` and
`TODO.md`, both changed dated documents, `handwritten_copy.manifest`,
`lakefile.toml`, `Unit/BatchEscapeTest.lean`, `Unit/PPTest.lean`,
`scripts/LADDER.md`, `scripts/test_batch_diagnostics.py`, and
`scripts/test_parse.sh`. Relevant model, bridge, parser, OCaml printer,
build, and test producers were also inspected.

**Producer and representation findings**

- `CerbEscape.lean:14` mirrors the six short escapes, printable ASCII,
  and three decimal digits in the local OCaml 5.4.0
  `lib/ocaml/bytes.ml:170` implementation. `bytes` consumes UInt8 values
  (`:28`); `text` encodes UTF-8 exactly once (`:37`); `byteChars` consumes
  the original character codes (`:33`). No truncating UInt8 conversion
  was introduced on the carrier path.
- `Main.lean:354` preserves the carrier adapter for Defined output
  (`:1059`) and killed-state stderr (`:1067`). The actual source chain is
  `frontend/model/driver.lem:254` / `:267` through `String.toString`
  (generated `Driver.lean:300` / `:301`: `String.ofList`), then concatenation
  at `driver.lem:1497`. The OCaml batch printer uses `String.escaped`
  for these fields (`backend/common/driver_ocaml.ml:101`, `:127`).
- The changed bridge call (`Main.lean:1377`) receives the text errors of
  `CabsImport.parseJson` (`CabsImport.lean:782`). The shared libc `bail`
  (`Main.lean:607`) receives parser/path, metadata, linking, and stitch
  text errors. Actual Core and metadata failure branches (`:619`, `:636`)
  were exercised independently with unusual Unicode and control-containing
  paths. `CerbFail.escapeMessage` (`CerbFail.lean:21`) retains its existing
  UTF-8 contract through the shared adapter.
- Out-of-domain carrier behavior is deliberately still invalid as byte
  protocol data: for example, U+03BB produces `\955`, and U+03E8 produces
  `\:00`. Fresh kernel witnesses and a bounded runtime comparison confirm
  preservation, not validation or normalization. The explicit residual at
  `CerbEscape.lean:10` and the narrowed TODO/observation-contract claims are
  accurate. Generic Lem String migration and every producer's byte-domain
  invariant remain open. Existing raw model Error/Other rendering
  (`Main.lean:1079`, `:1081`) is unchanged and follows its old oracle
  contract (`backend/common/driver_ocaml.ml:138`).

**Build reachability and nonvacuity**

`handwritten_copy.manifest:30` adds the new module to the actual Makefile
copy set (`Makefile:321`, `:358`), and `lakefile.toml:144` makes it a library
root. Source/generated copies match. The unit import and return-value chain
is live: `PPTest.lean:155` calls `BatchEscapeTest.run`, and `:156` requires
its result for success; `BatchEscapeTest.lean:38` checks every row.

`test_parse.sh:236` preserves existing fatal accounting. Its success arm
executes the new script at `:244`, before `ALL PASSED`, under `set -e`.
The producer script requires exit 1 and exact bytes (`:27`, `:32`), checks
that the input survives in the message (`:54`, `:69`), and checks the
strict byte decoder (`:37`). The shared Python codec is not its only
independent reference: this audit compared fresh driver output directly
with an OCaml executable calling `String.escaped`.

A fresh forwarding wrapper observed one successful real `--pp-core` call
followed by all nine producer subprocesses for the eight cases: seven
bridge calls and libc human/batch calls. A second wrapper restored only
the `é` regression (`\195\169` to `\233`) after the successful parse.
The lane refused with `wrong batch bytes`, nonzero exit, and no
`ALL PASSED`. Separately, the unchanged crash plant
(`test_fuel_plant.sh:126`) still printed the required `LEAN_FAILURE`
counter and fatal summary. The repaired placement neither bypasses the
new probes on successful lanes nor weakens crash classification.

**Fresh verification**

All builds/probes sourced the container's `scripts/env.sh`, with
`CERB_MEM_MAX=48G` and `DUNE_CACHE=disabled`; one heavy job ran at a time.
Every Lean/Lake invocation, including probe setup, was inside
`scripts/capped`. No proof option was increased and no non-kernel proof
method was used.

| Check | Result | Wall seconds |
|---|---|---:|
| Complete `scripts/capped scripts/test_unit.sh` | Exit 0; 7 unit executables and all attached gates/plants passed | 144.79 |
| `scripts/capped python3 scripts/test_batch_diagnostics.py --lean-bin lean_frontend/.lake/build/bin/cerberus-lean` | Exit 0; 8/8 cases | 0.44 |
| Complete `scripts/capped scripts/test_fuel_plant.sh` | Exit 0; all plants, including parse/abort, passed | 12.20 |
| Fresh `Boundary.lean` through outer-capped `lean_probe.sh` | Exit 0; five small kernel witnesses and bounded runtime comparison passed | 4.39 |
| Fresh OCaml-backed producer probe | Exit 0; 11 bridge values plus libc Core and metadata error branches | 0.73 |
| Fresh parse placement forwarding/corruption probes | Exit 0; both expected lane outcomes observed | 4.31 |

The runtime comparison checked the old source-extracted printer against
the compiled carrier adapter for all 1,114,112 `Char.ofNat` inputs,
including every Unicode scalar. This is an exhaustive singleton runtime
observation, not a universal kernel equivalence theorem. The five fresh
kernel witnesses cover adapter identity, U+03BB/U+03E8 carrier preservation,
NUL/U+00FF/newline text, and U+10FFFF UTF-8.

Fresh OCaml 5.4.0 output for
`String.escaped (String.init 256 Char.chr)` exactly equals all three
independently obtained Lean outputs: actual-byte adapter, carrier adapter,
and the unit test's embedded expectation. Including LF, all are 734 bytes
with SHA-256
`047d50892cbddefe48ca0395953bdaa804f81bdea3e7c4921ca8153dd803a7a7`.

Additional actual-producer values cover all C0 controls, DEL, C1 values,
U+00FF, already byte-shaped `Ã©` text, UTF-8 width boundaries, U+10FFFF,
combining marks, line separators, literal escape syntax, and embedded
Error/Defined records. The libc path probes include tabs, CR/LF, quotes,
backslashes, a C0 control, and non-BMP text. Every batch result was exactly
the OCaml escape of the observed producer message, ASCII, and one physical
line.

**Independent receipt and scope checks**

The existing repaired full Tier A+B battery was inspected, not rerun.
The reviewer independently verified its report SHA-256
`194d5e2d08a06e47a9a1c5174fbd1707aaf3709cd5549195c4d1008b7a11526a`,
all 35 selected lane receipts and recorded durations, all 70 raw
stdout/stderr hashes, source identity equality, external-input inventory
equality, and the reported absence of artifact issues. Every receipt says
exit 0 and containment cleaned; every recorded command cgroup is absent
now. All nine implementation/test/wiring hashes in the slice record match
current files. The currently tested native binary also matches the report:
`4beced12a48eec89dc1aa9c88ea40aa8777b65097d520ed892a0f711ebfa7df6`.

All 63 baseline snapshot hashes independently match both git base and
current files. Of the 213 starting generated Lean files, only copied
`Main` and `CerbFail` changed; copied `CerbEscape` alone is new. The 14-file
git diff contains no model body, pin, baseline, or observation-decoder edit.
Mainline remains at the base commit and the Lem pin remains `f6542f8`.

Raw captures confirm zero regressions in A2/A3/A4/A4b/B7; both B5 C3 A9/FF
stdout/stderr fixtures read `MATCH`; A7/B2 report 8/8 diagnostic cases;
B8.3 has the parse/abort classifications; B9 reports 93/93 plants.
B7 compares 1885/1963 rows: 1873 agree, 12 triaged, zero disagree.
The B7 rows for `sa_csmith_369.c` and `sa_csmith_371.c` are `AGREE`;
the separate unchanged csmith-corpus baseline pins them as `MATCH`.
There is no new 15-second measurement claim. Independently derived from
the 723 B10.1 row lines: 709 semantic agreements, one reviewed difference,
11 matching failures, and two interface agreements.

The first full attempt remains historical incomplete evidence: its report
says signal 15 and unchanged source; B8.3 failed and the interrupted B9
receipt is incomplete. Its raw capture hashes were checked separately.
It is not counted as certification of the repaired source.

**Reproduction and limits**

Ignored, reconstructible evidence is in
`.tmp/batch-diagnostic-bytes/adversarial-audit/`: `verify_evidence.py`,
`evidence.log`, `unit.log`, `diagnostics.log`, `fuel-plant.log`,
`Boundary.lean`/`boundary.log`, `all256.ml`, `escape.ml`, the four all-byte
transcripts, `producer_probe.py`/`producer-probe.log` and raw captures,
plus `parse_wrapper.py`, `parse_placement_probe.py`, and placement logs.
The identical final Lean probe is also at
`lean_frontend/.tmp/batch-diagnostic-audit/Boundary.lean`; its command from
`lean_frontend/` was
`../scripts/capped ../scripts/lean_probe.sh .tmp/batch-diagnostic-audit/Boundary.lean`.
The standalone Python probes run from the worktree root through
`scripts/capped`; compile `escape.ml` with the scoped OCaml compiler before
the producer probe. No raw archive is committed.

Two initial audit setups were corrected: `Main` is an executable module
outside Lake's library import map, so the final kernel probe imports
`CerbEscape`; an empty Core file is deliberately rejected, so the metadata
probe uses the accepted declaration `proc __builtin_exit (pointer)`.
Neither failed setup is treated as a candidate regression or a passed test.

This is a review and targeted revalidation of the byte/text diagnostic
slice, not proof of all model byte invariants, all libc error branches,
the generic Lem String representation, whole-project correspondence, or
new corpus timing. No implementation or existing documentation was changed
by the reviewer. Only this report is committed; external review remains
the next gate.
