# Codex charter: the `inner_arg_temps` elaboration mode (2026-10-21)

Branch `feature/inner-arg-temps`, worktree `worktrees/cerberus-lean-feature/inner-arg-temps`,
based on mainline `e32c16709` (Core quoting landed 2026-10-21). Worker: Codex #1.
Status: **PARKED after the 2026-10-23 full-battery B10.1 failure**. The
[park record](2026-10-23_inner-arg-temps-oracle-park.md) identifies a Normal
diagnostic change caused by I0b; no comparison rule or existing baseline
has been changed. Branch work awaits disposition. Matched
engine sequences remain exact within each mode. The oracle cross-mode
sanity check compares sets of distinct complete observations, ignoring
order and multiplicity. The [completion record](2026-10-23_inner-arg-temps-closeout-record.md#multiplicity-park-disposition)
records the correction and validation. Blanket containment is lifted for
the repaired transport; the per-dump detector remains. I1b stays deferred.

## Amendment — 2026-10-23

The disposition linked above supersedes the earlier cross-mode sequence
premise. Argument allocation in the caller adds unsequenced interleavings
in Normal mode; callee allocation under the switch yields fewer paths.
The exhaustive libc witness has two distinct outcomes, 80 Normal
observations and 4 switched observations, with exact engine agreement
within each mode. Counts are informational and are not pinned. Keep exact
per-mode engine comparisons as gates; oracle cross-mode set equality is
a sanity instrument. Finish the lane, selftest, fuzzing and full battery
under this corrected contract.

## Amendment — 2026-10-21

[USER 2026-10-21] Include upstream `3230aa494` as checkpoint I0b after
the PR 1020 backport, I0 (`56ac1e5ae`). Adopt the fractional-float-to-`_Bool`
fix in `translation_aux.lem` and both runtime variants, its upstream CI
witness, and the corresponding source/runtime/generated-delta pins. Change
the Normal libc dump pin only if regeneration shifts symbol numbering,
with that diff accounted for. Mark tray report 15 as fixed upstream and
backported after validation.

[USER 2026-10-21] Approve mirroring the resolved-path library-location rule
into the OCaml oracle and refusing quotation with non-canonical runtime
spellings.

[AGENT 2026-10-21, relayed by the operator] Move quotation hygiene out of
this slice to protect delivery of the consumer's elaboration mode. The
same worker receives that follow-up charter at this slice's close; I1b
remains below as approved work deferred to that slice, not work to perform
here.

I0–I2 and the park record preceded the I0b ruling; I0b is committed as
`08fb2d156`. The subsequent park disposition resumes I3/I4. Upstream's
recursive-main guard is dead on the driver's active reduction path:
recursion into main executes, and the lane must witness that behavior.
The [slice record](2026-10-21_inner-arg-temps-record.md#park-resolution)
records the disposition and its provenance. No recursive-main refusal is added.

Both recursive-main witnesses (with and without arguments) must agree
across both engines and both modes, with GCC results recorded alongside.
Any disagreement is a finding, never a baselined difference. Draft tray
64 reports the bypassed guard; the consumer note explicitly corrects the
orchestrator's earlier claim of refusal. I1b remains deferred.

A committed park stops branch work until an explicit park disposition.
The separate I0b authorization was the accepted exception for this park;
a new ruling by itself does not authorize working past a future park.

The second park disproved the original text-transport premise: loaded
parameters and local object addresses collapsed to the same printed name.
It temporarily contained switched libc execution and quotation. The
[transport record](2026-10-22_inner-arg-temps-transport-record.md) records
the authorized printer repair and the subsequent acceptance-criterion
park. The row-039 disposition resolves that park and requires four-way complete
libc observations. The subsequent full production sweep exposed the separate exhaustive
multiplicity conflict, resolved by the 2026-10-23 amendment. The earlier
recursive-main disposition stands.

## Why

cerberus-caesium (consumer; its certificate generator targets Cerberus's
`inner_arg_temps` calling convention, the one CN uses) asked for the Lean driver
to run that mode. [USER 2026-10-20] accepted the ask; [AGENT 2026-10-20]
scheduled it as its own slice immediately after Core quoting (the mode builds on
the quotation header and Core quoting is in its final battery). The consumer
confirmed (relayed by the operator, 2026-10-20): the whole switch set is exactly
`[.inner_arg_temps]`, no PNVI combination; `--call` is not used under the switch.

## Scope: one sentence

Make `--switches=inner_arg_temps` a supported whole switch set of the Lean driver,
mirroring upstream's three configuration points, validated by a matched-mode
differential lane, with the switch set reported in the outputs and the variant
libc quoted and pinned.

## What exists (verified 2026-10-20 at mainline `3ac3ff336` + `feature/core-quote`)

The model carries the mode end to end; nothing semantic is written in this slice.

| Where | What | Status |
|---|---|---|
| `frontend/model/translation.lem:4330-4344, 4412-4486` | callee-allocated parameter temporaries: params are `loaded T` values; prelude `create`s (`PrefFunArg`) + stores, epilogue kills (`with_block_objects`) | in generated `Translation.lean` (11 sites) |
| `frontend/model/core_run.lem:967-980` | call sites pass values (`ty`, not `pointer ty`); a separate recursive-main guard returns `Step_error` | that guard is bypassed by the active `core_reduction.lem` Eccall → `Core_run.call_proc` path; recursion executes |
| `frontend/model/driver.lem:1725-1728` | `Inner_arg_callconv`: argc/argv handed to `main` as values | generated |
| `frontend/model/mini_pipeline.lem:152` | const-expr mini-run picks the convention from the switch | generated |
| `lean_frontend/CerbGlobal.lean:113, 285` | `CerbSwitch.inner_arg_temps`; `has_switch_inner_arg_temps_default` | present |
| `runtime/libcore/std_inner_arg_temps.core` | the std variant (783 lines vs 864; proxies take loaded values) | shipped by `dune build cerberus.install` |
| `runtime/libc/dune:21-27, 150-171` | `libc_inner_arg_temps.co` built beside `libc.co` from the same 12 sources with `--switches=inner_arg_temps` | staged under `_build/install/default/lib/cerberus-lib/runtime/libc/` |
| oracle `backend/common/pipeline.ml:34` | std variant selection by switch | the mirror target of the first driver arm |
| oracle `backend/common/pipeline.ml:271` | `Inner_arg_callconv` when the switch is on | the mirror target of the second driver arm |
| oracle `backend/driver/main.ml:62` | `c_inner_arg_temps` library name | the mirror target of the libc pairing |

The Lean driver pins Normal mode in exactly two places, plus the refusal:

- `lean_frontend/Main.lean` `frontendTU` (~:739): `let callconv := Normal_callconv`.
- `lean_frontend/Main.lean` `resolveRuntime` (~:599): `std.core` hard-coded.
- `lean_frontend/Main.lean` `switchRefusalReason` (~:1419) refuses `inner_arg_temps`;
  `judgeSwitches` (~:1477) accepts `PNVI_ae_udi` alone.
- `scripts/libc_prep.sh` pins only the Normal dump (`tests/libc/libc.core`, content
  hash `tests/libc/libc.core.sha256`); `scripts/test_libc_exec.sh:88` passes it.
- The quotation module (`CerbQuote.moduleSource`: `import Core_run_aux` + helpers +
  `def quotedCore`) carries no switch-set line.

Measured 2026-10-20 (orchestrator, primary checkout): the oracle runs the mode on a
nolibc call sample and a printf sample with the same verdicts as Normal mode; the
variant libc dump pretty-prints with or without the switch to the same text
(87,260 lines; the Normal dump is 89,609), so the second pin uses the existing
mechanism.

**I3 correction:** identical printed dumps do not establish preservation
of the binary library's symbol identities. The printer drops the numbers
that distinguish `SD_FunArgValue` from `SD_ObjectAddress` of the same name.
I2's calling-convention check and literal quotation comparisons missed this
loss; the matched-mode execution sweep exposes crashes and wrong answers.
This premise is false and caused the second park. The 2026-10-22
disposition above authorizes a printer repair and requires matched-mode
execution evidence before lifting containment; discrepancies remain findings.

## Upstream context (relayed by the operator, 2026-10-20; paraphrased)

- The Cerberus team recommends this mode for program logics (CN requires it) and
  has discussed making it upstream's DEFAULT. This slice keeps the port's default
  at Normal (agreed with the consumer); a default flip is a plausible follow-up
  once the lane is green, and the record should say so.
- Upstream fixed a defect in this mode AFTER our merge-base b9aeedcb4:
  rems-project/cerberus PR 1020, commit f10329b44287ab79ed5017ff68431d5c5953ebd7
  (not in the local mirrors as of 2026-10-20; the operator refreshes
  `deps/mirrors/cerberus.git` and `git fetch upstream` outside the sandbox).
  CHECKPOINT I0 (before I1): read that commit; decide whether the fork's lem at
  the merge-base carries the defect; if it does, BACKPORT it as a fork-ahead
  delta (one shared-lem edit, both engines by generation; `[source-content]`
  and `[expected-semantic]` re-pins with a dated NOTE; tray entry recording it
  as an upstream backport, not a filing). An upstream fix is the clearest case
  of a mistake upstream recognises (container CLAUDE.md bullet).
- A FUZZING ROUND under the switch was suggested upstream and is in scope:
  `scripts/fuzz_csmith.sh` / the csmith corpus lane with both engines at
  `--switches=inner_arg_temps` (matched mode, a measurement sweep: document
  size, seeds and time; the grind tripwire applies, >1 h needs written
  justification), PLUS a cross-mode comparison on the ORACLE alone (the same
  program at Normal and at inner_arg_temps must agree); every discrepancy is documented in the record and,
  where upstream does not know it, drafted for the tray. Discrepancies are
  findings, never silently baselined.

## Upstream-judgement items (container CLAUDE.md, [USER 2026-10-20])

- The comment at `translation.lem:4331` says `main` is excluded from the mode; the
  code at 4330-4333 does not exclude it. The code is the model. Pin it with a
  differential witness (a `main(int argc, char **argv)` program under the switch,
  both engines). Report the comment/code mismatch in the upstream tray (report
  only). Do NOT "fix" the comment's reading into the fork.
- Upstream's recursive-main guard in `core_run.lem:967-970` is dead on
  the driver's active `core_reduction.lem:1386-1405` path. Recursion into
  main executes. Pin two bounded witnesses, including argc/argv recursion,
  in both modes on both engines, with GCC results in the record. Report
  the dead guard in tray draft 64; do not change the shared model.

## Deliverables (checkpoints; commit each on green focused checks, Tier A at
## each boundary; the full battery at close-out)

### I0 — the PR 1020 backport (see Upstream context)
- CONFIRMED 2026-10-20 (orchestrator): upstream's CI witness
  tests/ci/0344-ptr-to-_Bool-param.c fails on the fork's oracle under the switch
  (`Error {msg: "ill-formed program: PEctor … Civfromfloat('_Bool', 0) …"}`) and
  passes in Normal mode; `git apply --check` of f10329b44's translation.lem hunk
  against mainline succeeds. Backport it, adopt the witness into tests/ci (+ the
  lane baselines), cite the commit.
- A merge-base bump is being scoped separately; these two backports are expected
  to merge trivially into it (identical content).

### I0b — fractional floating values converted to _Bool

Approved by the amendment above. Backport `3230aa494`:
`translation_aux.lem`'s `conv_arith` and `loaded_ivfromfloat` in BOTH std
variants; adopt `tests/ci/0343-subzero-floating-to-_Bool.c` and its expected
output. Re-pin the affected manifest rows and mark tray 15 as fixed upstream,
backported. If the std change shifts libc dump symbol numbering, explain
the diff before re-pinning the Normal dump.

### I1 — the switch set and the two driver arms
- `judgeSwitches`: `inner_arg_temps` alone is a second supported WHOLE set
  (`[.inner_arg_temps]`); the per-element refusal reasons stay for every other
  value; `PNVI_ae_udi,inner_arg_temps` is refused with a reason (not asked for).
- `resolveRuntime`: std variant by `has_switch` (mirror pipeline.ml:34, cite).
- `frontendTU` (and any other `translate` call): convention by `has_switch`
  (mirror pipeline.ml:271, cite). `CerbCall` (`--call`) is Normal-only: REFUSE
  `--call` under the switch, loud and attributed.
- Kernel pins in `opaque-failure-test` (or the test that holds the PNVI ones):
  `@has_switch ⟨[.inner_arg_temps]⟩ .inner_arg_temps = true` by `rfl`, and the
  convention selector at both instances.
- The switch set is REPORTED: in the Core quotation header (a comment line in
  `moduleSource`, fixed prefix, listing the set, `[]` for default) and in the
  driver's run output on a fixed-prefix line. CONSTRAINT: the matched-mode
  lanes compare verdict tokens byte-for-byte with the oracle (test_exec.sh
  reads only `Defined`/`Undefined`/`Error` lines; `observations.py` likewise);
  the report line must change NO compared token and must be ignored by every
  lane and by `observations.py` — choose the channel accordingly and plant-test
  that it is ignored. Say in the record where it goes and why.

### I1b — quotation hygiene carried over from the Core-quoting D5 re-review
(READY WITH NOTES, 2026-10-20; review file committed with the Core-quoting landing)
Status: ruled yes; deferred to the quotation-hygiene slice (amendment above).
Do not implement this section in the inner_arg_temps slice.

- Approved, deferred: mirror
  the resolved-path library-location rule into the fork's OCaml oracle
  (`util/cerb_location.ml`, the remedy tray 58 already drafts) so both engines
  agree and the served-UB-location divergence class disappears; fork-drift
  `[source-content]` re-pin + dated NOTE; the D5 witness pair becomes an
  agreement check. Under the standing rule an override is mirrored in both engines.
- Approved, deferred (review P3-1): under
  `--quote-core`/`--quote-libc` the driver REFUSES (loud, attributed, exit 2)
  when the runtime spelling is not the canonical relative form or when any
  emitted source label would be non-portable (absolute/machine-specific);
  today it emits silently and only the test census catches it (fail-open).
- Review P3-2: the linked round-trip population is one trivial TU; add a linked
  case that populates enumDefs and the other read-only-asserted comparator
  positions (a multi-TU fixture with an enum and a cross-TU extern).

### I2 — the variant libc
- `scripts/libc_prep.sh` pins `tests/libc/libc_inner_arg_temps.core` (content
  hash beside the Normal pin; `--check` covers both; `--record` records both).
  The 12 metadata cabs-jsons are parse-only and shared.
- `loadLibc` under the switch: the dump/mode pairing must FAIL CLOSED. A Normal
  dump paired with the switch (or the reverse) is refused loudly at the stitch,
  with a plant in the lane. Say which invariant catches it (the metadata's
  `calling_convention0` vs the dump's proc parameter shapes, or whatever is
  cheapest and sound) and cite the oracle's `IncompatibleCallingConvention`.
- `--quote-libc` under the switch quotes the variant with its own sha256 pin
  (`core-quote-libc-inner-arg-temps.sha256` or the branch's naming) and the
  Tier B libc row covers both variants.

### I3 — the matched-mode lane (Tier A row; a TRUST SURFACE like row 14)
- `scripts/test_inner_arg_temps.sh` modelled on `scripts/test_pnvi.sh`: BOTH
  engines at `--switches=inner_arg_temps`; corpora: `tests/minimal`, the
  fixtures (`tests/fixtures`, `corpus/`), `tests/libc_exec` with the variant
  dump, the main-with-args witness, both recursive-main execution witnesses, the
  dump/mode-mismatch plant; a committed baseline; `--selftest` plants (incl.
  the switch-stripped stub pattern of test_pnvi.sh:107/141 so a lane that
  silently drops the switch is RED).
- LADDER.md row + VALIDATION.md entry + `release.py` lane.

### I4 — docs and record
- `SUPPORTED.md` (the mode and its limits), `README.md` flags, `Main.lean`
  header, `VALIDATION.md`, `TODO.md` (anything deferred), fork-drift manifest
  re-pin rows (single-row edits + dated NOTE) for any pinned script touched.
- Record `lean_frontend/docs/<date>_inner-arg-temps-record.md`: what was
  verified, verbatim gate outputs, the pin hashes, the main comment/code
  finding, the refusal classes, the kernel pins.
- Consumer note `lean_frontend/docs/<date>_consumer-note-cerberus-caesium-inner-arg-temps.md`:
  the flag, the header line, the variant pin hash, the lane, the limits
  (`--call` refused; recursive main executes because the driver bypasses the
  upstream guard, witnessed in the lane; PNVI combination refused).
- Upstream tray draft: the translation.lem:4331 comment/code mismatch.

## Non-goals
- No change to the default mode or its battery.
- No PNVI combination. No `--call` under the switch. No semantic edits to the
  lem model. No fix of upstream's recursive-main TODO.

## Gates
- Focused checks during development; Tier A (`python3 scripts/release.py
  --mode fast`) at every checkpoint commit; the full battery at close-out.
- Kernel replay (`lake env leanchecker`) is NOT triggered unless a proof module
  changes (the kernel pins are `rfl` in a test exe); if one does, quote the
  modules and exit status in the record.
- Every lake/lean call through `scripts/capped`; one heavy job at a time.

## Working practices reminders
- Commit per checkpoint on green; the message states what was verified.
- Provenance: [USER] only for the operator's own rulings; orchestrator text
  relayed by the operator is `[AGENT …, relayed by the operator]`; consumer
  statements are `[consumer cerberus-caesium, relayed by the operator]`.
- Never quote the operator's messages verbatim in files or commit messages.
- Never `pgrep -f`/`pkill`; kill only PIDs you started.
- Park (a committed park record) on any baseline movement outside the new lane.
