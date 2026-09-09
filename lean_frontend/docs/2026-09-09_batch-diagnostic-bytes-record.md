# Batch diagnostics — byte/text boundary

[USER 2026-09-09] approved the proposed next slice and requested a worktree
and implementation. Base: `679181d1bbe0ae709ef2c91647d74ab20885edaf`;
branch: `arc/batch-diagnostic-bytes`. Full validation and adversarial audit
precede the external-review handoff. No merge or push is authorized.

## Problem and scope

[AGENT] HEAD-before bridge probes reproduce the bug: a Unicode diagnostic
containing `é` emits `\233` rather than its UTF-8 bytes `\195\169`, and `λ`
emits the invalid byte escape `\955`. The ordinary stderr diagnostic still
contains UTF-8 text. Both commands refuse with exit 1. The ASCII control
also refuses with exit 1 and has correctly escaped text.

Model stdout/stderr have a different representation: one Char per program
byte. Re-encoding these as UTF-8 would corrupt the already-correct C3 A9/FF
fixtures. The prior C-TF1 TODO instruction to unify on UTF-8 conflicts with
the producer trace and VF-07 correction. This slice reconciles that guidance.

## Implementation

`CerbEscape` shares the byte-class escaping primitive from OCaml 5.4.0
`Bytes.unsafe_escape` (`lib/ocaml/bytes.ml:170-212`) and supplies separate
adapters for actual bytes, byte-carrier Chars, and Unicode text. It introduces
no runtime atom, native implementation, axiom, or fuel parameter.

| Producer | Representation | Adapter |
|---|---|---|
| Defined stdout/stderr | Model bytes carried in Chars | `CerbEscape.byteChars`, through existing `Main.batchEscape` |
| Killed-state stderr | Model bytes carried in Chars | Same byte-carrier adapter |
| Cabs JSON parse failure | Unicode diagnostic text | `CerbEscape.text` |
| Libc loading `bail` (parser, metadata, linking/stitch diagnostics) | Unicode diagnostic text | `CerbEscape.text` |
| ModelFailure payload | Unicode diagnostic text | Same text adapter, through existing `CerbFail.escapeMessage` |

The byte-carrier adapter preserves the former printer's behavior, including
outside its intended 0..255 domain; it does not silently truncate an invalid
carrier or reinterpret it as UTF-8. Establishing every model producer's byte
invariant and the generic Lem String/Char migration remain separate work.
Ordinary model Error/Other rendering follows its existing oracle contract.
The observation decoder and baseline rows are unchanged.

## Acceptance and evidence

- All 256 actual bytes and carrier Chars must equal an independently recorded
  OCaml `String.escaped (String.init 256 Char.chr)` transcript.
- Kernel witnesses distinguish FF from U+00FF and cover Unicode/invalid-UTF-8
  boundaries; unit checks cover empty strings, controls, quotes, backslashes,
  NUL, and embedded verdict text. They run through the existing `pp-test`.
- `test_parse.sh` exercises the actual bridge and libc diagnostic producers
  after `build_lean`; UTF-8 bytes must survive exact escaped-record checking.
- Existing stdout/stderr byte fixtures and all baseline rows stay unchanged;
  the full Tier A+B battery must report zero regressions. Improvements remain
  reported, nonfatal outcomes under the standing user ruling.
- Run an adversarial audit at the candidate and pause for external review.

The starting snapshot contains 63 tracked baseline paths and 213 generated
Lean files. Reconstructible scratch evidence lives under
`.tmp/batch-diagnostic-bytes/` in this worktree; raw captures are not committed.

### Development checks

[AGENT] Both generated trees were re-derived; the OCaml build used
`DUNE_CACHE=disabled` and `dune build --force`, and the capped full Lake build
passed (388 jobs). Of the 213 starting generated Lean files, only the copied
`Main` and `CerbFail` changed; `CerbEscape` is the new copied root. The 63
baseline paths remain unchanged. No Lem pin or model body changed.

`pp-test` passed, including ten new checks and four kernel boundary witnesses.
The initial singleton-Char proof could not reduce String's opaque iterator;
rewriting with `String.foldl_eq_foldl_toList` discharged it without option
increases or non-kernel proof methods. The actual producer script reports
`batch diagnostic producers: 8/8 passed`. Against the unchanged HEAD-before
binary it fails at the `é` case, observing `\233` where the UTF-8 encoding is
required. This is the intended regression, not a skipped input.

The independent all-byte oracle transcript is reproducible with:

```ocaml
print_endline (String.escaped (String.init 256 Char.chr));;
```

It is the output of the project switch's OCaml 5.4.0. Including its final
newline, the 734-byte transcript SHA-256 is
`047d50892cbddefe48ca0395953bdaa804f81bdea3e7c4921ca8153dd803a7a7`.
The test embeds that transcript without its final newline. The native tests
compare observations to this oracle output; the four small Lean witnesses
are separately kernel-checked.

The pristine upstream oracle was built from git archives into the worktree's
own `.validation-foundations/independent-oracle-v2/` using
`scripts/build_independent_oracle.py` and the existing project repository
paths. No shared installation or pin was changed.

### Initial full run and integration repair

[AGENT] The initial full run (`.tmp/batch-diagnostic-bytes/full/`) exposed
a test-placement regression in B8.3. The new producer probe initially ran
before `test_parse.sh` classified its requested C inputs, so a deliberately
crashing override caused that probe to fail before the lane emitted its
required `LEAN_FAILURE` counter and fatal summary. The old fuel plant
correctly rejected the missing classification evidence. This was a test
integration defect, not a fuel or interpreter result regression.

The producer probe now runs in the success arm after the existing parse
failure accounting and before `ALL PASSED`. Every successful real parse
lane must still pass all eight diagnostic cases; a crashing input still
reaches the original fatal classification. No skip or bypass was added,
and `test_fuel_plant.sh` is unchanged. The repaired fuel-plant suite passed,
including both parse/abort checks, and a real `test_parse.sh --max 1` run
reported all eight diagnostic cases passing before `ALL PASSED`.

The initial run was stopped during B9 after diagnosis; its report records
`status = incomplete`, signal 15, unchanged sources, and cleaned containment
for the interrupted lane. Earlier results, including GCC's zero regression
summary and the unchanged C3 A9/FF fixtures, remain historical evidence.
They do not certify the repaired candidate. The fresh full fixed-source run
below supplies that receipt.

### Full boundary battery on the repaired candidate

[AGENT 2026-09-09] All 35 required Tier A+B commands passed, exit 0, with
`containment_cleaned = true` for every command. The run started at
21:54:59 UTC and finished at 23:08:51 UTC on September 9. It used the
already re-derived trees and worktree-local independent oracle:

```sh
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py \
  --mode full --lane-timeout 3300 \
  --out .tmp/batch-diagnostic-bytes/full-repaired
```

The schema-2 report has `status = passed`, `selection_complete = true`,
`source_unchanged = true`, and `artifact_issues = []`. Both source identities
and both external-input inventories compare equal. The orchestrator checked
every lane's exit, containment flag, and stdout/stderr hash against the raw
captures. Report SHA-256:
`194d5e2d08a06e47a9a1c5174fbd1707aaf3709cd5549195c4d1008b7a11526a`.
LADDER membership SHA-256:
`3716f5fe1e17fa856ac0eaa1114a1d31c1d3056763100126a2f8f5f8bd4dfcd0`.
The A7 description changed to name its producer probes; command membership
did not change. This is a complete Tier A+B receipt. Whole-project reporting
and adoption exits, and external review, remain separate.

| Command ID | Seconds | Exit / containment |
|---|---:|---|
| A1 | 149.395 | 0 / cleaned |
| A2 | 27.865 | 0 / cleaned |
| A3 | 52.973 | 0 / cleaned |
| A4 | 23.469 | 0 / cleaned |
| A4b | 18.911 | 0 / cleaned |
| A4c | 3.133 | 0 / cleaned |
| A5 | 23.109 | 0 / cleaned |
| A6 | 2.230 | 0 / cleaned |
| A7 | 10.140 | 0 / cleaned |
| A8 | 8.689 | 0 / cleaned |
| A9 | 16.198 | 0 / cleaned |
| A10 | 17.201 | 0 / cleaned |
| A11 | 66.135 | 0 / cleaned |
| B1 | 704.744 | 0 / cleaned |
| B2 | 23.565 | 0 / cleaned |
| B3 | 15.603 | 0 / cleaned |
| B4 | 46.312 | 0 / cleaned |
| B5 | 64.897 | 0 / cleaned |
| B6.1 | 2.332 | 0 / cleaned |
| B6.2 | 2.332 | 0 / cleaned |
| B6.3 | 2.632 | 0 / cleaned |
| B6.4 | 2.933 | 0 / cleaned |
| B6.5 | 3.333 | 0 / cleaned |
| B6.6 | 3.934 | 0 / cleaned |
| B6.7 | 2.781 | 0 / cleaned |
| B7 | 1415.816 | 0 / cleaned |
| B8.1 | 13.512 | 0 / cleaned |
| B8.2 | 219.500 | 0 / cleaned |
| B8.3 | 6.586 | 0 / cleaned |
| B8.4 | 16.405 | 0 / cleaned |
| B9 | 1377.651 | 0 / cleaned |
| B10.1 | 63.986 | 0 / cleaned |
| B10.2 | 1.330 | 0 / cleaned |
| B11.1 | 14.800 | 0 / cleaned |
| B11.2 | 6.887 | 0 / cleaned |

A2, A3, A4, A4b, and B7 each print the verbatim baseline summary
`Baseline check: 0 regression(s), 0 improvement(s)`. Zero regressions is the
gate; improvements would remain reported and nonfatal. No baseline row was
re-recorded. The 63 starting baseline paths are byte-identical. B5's
`zd-z2p01-stderr_escape` and `zd-z2p01-stdout_escape` rows both read `MATCH`,
preserving the FF and C3 A9 payloads. B7 compares 1885 of 1963 rows: 1873
agree, 12 existing triaged cases, zero disagreements. Its `sa_csmith_369.c`
and `sa_csmith_371.c` rows read `AGREE`; this slice makes no new 15-second
timing claim for either row.

A7 and B2 each report `batch diagnostic producers: 8/8 passed`. B4 reports
`test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)`.
B8.3 now includes both expected parse/abort classification checks and
`test_fuel_plant: ALL PLANTS OK` in its longer success line. B9 reports
`observation lane plants: 93/93 passed`. B10.1 passes all 723 rows: 709
semantic agreements, one reviewed difference, 11 matching failures, and
two interface agreements.

Only copied `Main` and `CerbFail` differ among the 213 starting generated
Lean files; the new generated file is copied `CerbEscape`. No generated
model body changed. Main remains at the base commit, and the Lem pin remains
`f6542f8e6860d12d4655e6648bc4c45dabd1d798`.

The fixed-source run preceded the commit. Its tracked-diff SHA-256 is
`4a32634580025492cf396c730a59f47ce76bfd53e9b77f11f5fd121b5a82657f`;
the report also records all four then-untracked file hashes. The following
hashes identify every implementation, test, and build-wiring file in this
slice. After the run, edits are confined to this record and the TODO status;
the adversarial audit will be recorded separately.

| Path | SHA-256 |
|---|---|
| `lean_frontend/CerbEscape.lean` | `603454b13ad49cea3d59905dde44df06b39b8828860f388158525d080e5fc7ad` |
| `lean_frontend/CerbFail.lean` | `c25b756ddb179e31badbfdeeccfbf82aab45c1af05a930d5a4a0f8f517074467` |
| `lean_frontend/Main.lean` | `c4e48a31be7b68287952131861c669501cba9f395c218b62f9bf70265e26e366` |
| `lean_frontend/handwritten_copy.manifest` | `4b023746b3278b078b5953f798250c153e6a70a354924574c2c7df19e204559b` |
| `lean_frontend/lakefile.toml` | `8cfccddd09053cccb3b4a3345e6a6aa8197bb147743694e667b22f1c35356102` |
| `lean_frontend/test/Unit/BatchEscapeTest.lean` | `20df25e6d30ed12a241866226ed554adcac7cbe3eb0b357633bb8ac6c5066000` |
| `lean_frontend/test/Unit/PPTest.lean` | `c2fdcab547d1a00519edc8d684c340ad3c53b52979334c81a8d37b0d66b03e88` |
| `scripts/test_batch_diagnostics.py` | `8da797db8685d2dfd4924d2ca80038e2aa07844d9611e24de087fa2f69db3187` |
| `scripts/test_parse.sh` | `b18c0a95772f3c9ee46467b85c376c61189450c266b490a9ebd9060fcebe0691` |

### Adversarial audit and external-review handoff

[AGENT 2026-09-09] Implementation candidate
`9f947a425cad942daa93a4f2a53e3940f2e1aa51` received a fresh independent
adversarial audit. The [audit report](2026-09-09_batch-diagnostic-bytes-adversarial-audit.md),
committed as `da26e96081a0ab26a6cd3ccc905b578b4a54dd27`, gives **PASS
within the slice, with no blocking or nonblocking findings**.

The auditor reran the complete unit suite, all eight diagnostic cases,
and the unchanged fuel plants; independently checked the full-run receipts,
log hashes, nine implementation/test/wiring hashes, and baseline/generated
snapshots; and ran fresh boundary and actual-producer probes. The old
carrier printer agrees with the compiled adapter for every Unicode scalar
in a bounded runtime check. Five small kernel witnesses separately check
adapter and out-of-domain boundaries. Fresh OCaml escaping agrees with both
all-byte adapters and additional bridge/libc Core/metadata diagnostics.

A forwarding wrapper confirms that a successful real parse is followed by
all nine subprocesses for the eight diagnostic cases. Restoring just the
old `é` encoding defect makes that same lane fail before `ALL PASSED`.
The existing fuel plant still checks the original crashing-parse summary.
These controls address both sides of the repaired test placement.

The orchestrator independently read the audit report, probe sources and
outputs, rechecked the four 734-byte all-byte transcript hashes, and
confirmed the forwarding/corruption outcomes. No implementation revision
was required. After the full fixed-source run, only this record, the TODO
status, and the new audit report changed; the nine recorded implementation,
test, and build-wiring hashes still identify the candidate exactly.

The branch is ready for external review. The user's requested pause remains
in force: no merge or push has occurred. Generic Lem String/Char migration,
model producer byte-domain invariants, and broader correspondence/reporting
work remain outside this completed slice.
