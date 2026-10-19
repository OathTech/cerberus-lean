# Translation fuel — work record (2026-10-18)

Branch `arc/translation-fuel`, originally based on `b1c539c45`, rebased onto
`049eb9a0a` (hash map in the 2026-10-19 correction below). All six translation
workers have kernel equations: four MEASURED, two AMBIENT. The current
elaborator zero arms directly refuse through opaque `failwithI`; they have
no data-level error channel. The earlier recorded-error design was wrong
on the constant-expression path. Its green full A+B, axiom and kernel checks
did not detect that defect and did not justify the former completion claim.
Current correction and validation are recorded at the end of this document.
Release certification and whole-frontend correctness are separate claims.

## Decisions

- [USER 2026-10-18] Development may use focused checks and defer the full
  gates; all required gates must pass before completion is claimed.
- [AGENT 2026-10-18] Group the four structurally recursive helpers in one
  proof carrier. Use the backend-derived constant/statement sizes and opaque
  failure zero arms; prove stability by strict subtree descent without a
  well-formedness hypothesis.

- [AGENT 2026-10-18] Keep the expression/statement pair AMBIENT. The
  structural-size candidate fails: `&&`/`||` recurse on a larger desugared
  expression (`translation.lem:2304–2321`), and the statement-expression
  callback receives `self` without a contract on the expressions it passes
  back (`:3216–3222`). A joint sufficiency theorem would need a weighted
  desugaring measure and a callback contract; neither follows from raw Ail
  size. The permitted ambient form retains kernel equations with explicit
  fuel. The original zero arms recorded `CerbFuel.fuelExhaustedMsg` before
  returning `mk_skip_e`; this was wrong for Mini_pipeline's plain `runStateM`
  caller, which discarded the error and executed the placeholder. The
  2026-10-19 ruling below supersedes those zero arms with direct refusal.
  The classifier recognizes the exact reserved-message `failwithIImpl`
  PANIC envelope at exit 134 as fatal FUEL:panic.

## Base

The assigned worktree was clean. Its generated Translation module contained:

```text
217:partial def translate_constant (_lemReader_enum_definitions : Fmap sym integerType)
1997:partial def translate_expression [LemFuel] [CerbGlobal.Switches]
4349:partial def collect_cases_ (stmt : statement genTypeCategory) :
4420:partial def erase_loop_control_aux (stmt : statement genTypeCategory) :
4585:partial def collect_visibles_ (stmt : statement genTypeCategory) :
4940:partial def translate_stmt [LemFuel] [CerbGlobal.Switches]
```

The generated OCaml snapshot contains 86 files (derived count). Its sorted,
indented JSON mapping of relative names to SHA-256 values, with a terminal
newline, hashes to `d846b9045496a89ec7204b2ab2a0a9bda1d382776c4262b744c347f677a8f5f4`. The snapshot is
scratch evidence only; regenerate the base with `make prelude-src` to reproduce
it and compare with `diff -rq`.

The initial `python3 scripts/release.py --mode fast` was stopped deliberately
after the operator relaxed development-time gate scheduling. Its unit
executables reported `Total: 19 passed, 0 failed`; A1 as a whole did not finish.
The runner reported:

```text
INCOMPLETE A1 (350.8s)
fast: incomplete; 0/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

This is an incomplete baseline run, not a green Tier A result. No baseline
pin was edited. Final certification remains required.

## Implementation and consumer contract

[AGENT 2026-10-18] Keep the implementation, pins, regression checks and consumer
contract in one final commit, after the full tier run. Development checks were
focused under the operator's revised gate-scheduling instruction.

Only Lean declarations and comments were added to `translation.lem`; no Lem
body, type, dependency pin, baseline or gate policy was changed.
The generated Translation module contains zero `partial def` occurrences.

| Function | Final form | Measure / budget | Hypothesis and production discharge |
|---|---|---|---|
| `translate_constant` | MEASURED | `constant.lemSize cst` | none |
| `collect_cases_` | MEASURED | `statement.lemSize stmt` | none |
| `erase_loop_control_aux` | MEASURED | `statement.lemSize stmt` | none |
| `collect_visibles_` | MEASURED | `statement.lemSize stmt` | none |
| `translate_expression` | AMBIENT, outside drive closure | caller's `LemFuel.fuel` | no sufficiency claim |
| `translate_stmt` | AMBIENT, outside drive closure | caller's `LemFuel.fuel` | no sufficiency claim |

The [consumer note](2026-10-18_consumer-note-cerberus-caesium-translation-fuel.md)
states all six wrapper equations, with both instance arguments explicit for
the ambient pair. `Unit.TranslationFuelTest` compiles the measured equations
and direct raw zero-worker refusal equations; Part 1 of `TotalityProofTest` compiles
the ambient equations. The four sufficiency theorems are unconditional and
proved by positive structural sizes and strict descent on every recursive
call. No zero-arm unreachability is claimed for the ambient pair.

### Focused validation (2026-10-18, before the correction)

Reproduction commands (from the project root, with its documented build
environment and `CERB_MEM_MAX=48G`):

```sh
make prelude-src lean-prelude-src
bash scripts/test_translation_fuel.sh
bash scripts/check_fuel_forms.sh
python3 scripts/gen_fuel_parametricity.py --check
bash scripts/check_fork_drift.sh
(cd lean_frontend && ../scripts/capped lake build totality-proof-test)
(cd lean_frontend && ../scripts/capped lake env leanchecker Translation Translation_lemMeasureProofs Translation_auxiliary Unit.TranslationFuelTest Unit.TotalityProofTest)
```

All exited 0 on the original recorded-error implementation. These checks did
not cover the plain `runStateM` constant-expression path. Kernel replay with Lean
4.32.2 checked the five modules named in the command and returned exit 0.
The close-out axiom probe also returned exit 0. The fork-drift gate and
OCaml comparison returned exit 0.

`diff -rq` against D0's generated OCaml snapshot produced no output and exited
0; its 86 files remain byte-identical. Fork-drift layer 2 and every dependency
pin are unchanged. The source-content manifest re-pins only `translation.lem`,
with a dated note.

The axiom probe imports `Unit.TranslationFuelTest` and runs `#print axioms` on
all 13 named carrier theorems, the four generated sufficiency theorems, the
six generated zero equations and the two boundary equations (25 total,
derived count). All cones are subsets of `propext`, `Classical.choice`,
`Quot.sound`; no new axiom, `sorry`, non-kernel proof method or runtime override
was introduced. Reproduce the names with `rg '^theorem ' \
lean_frontend/Translation_lemMeasureProofs.lean` (carrier namespace prefix),
then the four/six names in generated `Translation_auxiliary.lean` /
`Translation.lean` and `TranslationFuelTest.{statement,expression}_zero_boundary`.
Run the probe through the documented capped `scripts/lean_probe.sh` recipe.
The new proof files compile without warnings. Builds also replay inherited
warnings in generated code, existing seams and pinned LemLib; those predate
this slice and are not suppressed or changed here.

Fuel-form tool rows, verbatim (trailing empty hypothesis columns omitted):

```text
FUEL_FORM	collect_cases__lemFuel	MEASURED	no/front	obligation=collect_cases__measure_sufficient axioms=ok proof=Translation_lemMeasureProofs.collect_cases__measure_sufficient:ok args=positional measure=syntactic
FUEL_FORM	collect_visibles__lemFuel	MEASURED	no/front	obligation=collect_visibles__measure_sufficient axioms=ok proof=Translation_lemMeasureProofs.collect_visibles__measure_sufficient:ok args=positional measure=syntactic
FUEL_FORM	erase_loop_control_aux_lemFuel	MEASURED	no/front	obligation=erase_loop_control_aux_measure_sufficient axioms=ok proof=Translation_lemMeasureProofs.erase_loop_control_aux_measure_sufficient:ok args=positional measure=syntactic
FUEL_FORM	translate_constant_lemFuel	MEASURED	no/front	obligation=translate_constant_measure_sufficient axioms=ok proof=Translation_lemMeasureProofs.translate_constant_measure_sufficient:ok args=positional measure=syntactic
FUEL_FORM	translate_expression_lemFuel	AMBIENT	no/front	zero=translate_expression_lemFuel_zero rhs-consts=[bind1, Unit, generic_expr, sym, elab_state, record_error, CerbFuel.fuelExhaustedMsg, return0, mk_skip_e]
FUEL_FORM	translate_stmt_lemFuel	AMBIENT	no/front	zero=translate_stmt_lemFuel_zero rhs-consts=[bind1, Unit, generic_expr, sym, elab_state, record_error, CerbFuel.fuelExhaustedMsg, return0, mk_skip_e]
FUEL_FORMS_SUMMARY	workers=87	measured=67	measured_under_hyp=13	absorbing=13	ambient_reachable=0	ambient_unreachable=7	closure_size=10723
```

check_fuel_forms: forms partition OK (67 MEASURED + 13 ABSORBING + 0 ambient-reachable + 7 ambient-unreachable = 87 fuel'd workers)

### Exhaustion witnesses and regression plant (2026-10-18)

`bash scripts/test_translation_fuel.sh` generates two small C witnesses with
192 levels inside an uncalled function: expression nesting or statement
nesting. Their `main` is the same simple successful control. The original
recorded-error implementation reported:

```text
translation-fuel: control fuel=128 exit=0 Defined Specified(0)
translation-fuel: control fuel=100000 exit=0 Defined Specified(0)
translation-fuel: expression fuel=128 exit=134 class=FUEL:panic (translation boundary)
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
translation-fuel: expression fuel=100000 exit=0 Defined Specified(0)
translation-fuel: statement fuel=128 exit=134 class=FUEL:panic (translation boundary)
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
translation-fuel: statement fuel=100000 exit=0 Defined Specified(0)
translation-fuel: PASS (two dead-code exhaustion witnesses, four successful controls)
```

The low-fuel failures are the translation boundary's `failwithI`, not a
frontend rejection or a later execution of the dead function. The separate
kernel boundary equations covered only a fresh `runStateM_errors` run, not
Mini_pipeline's plain `runStateM` run. The shared shell classifier returns FUEL:panic for this exact
PANIC envelope at exit 134. The exec lane reports FUEL, a fatal outcome that
is never agreement. The original classifier did not recognize this envelope;
B8.3 caught that integration failure, as recorded below.

For the negative plant, replace only the two new elaborator `fuel val`
payloads with `return0 mk_skip_e`, regenerate both trees, rebuild, and run the
same script. Both low-fuel witnesses then incorrectly produce `Specified(0)`;
the test rejects them:

```text
translation-fuel: FAIL expression fuel=128 exit=0 class=
translation-fuel: FAIL statement fuel=128 exit=0 class=
translation-fuel: FAIL (see rejected witnesses above)
```

The plant exited 1. Both original declarations were restored, both trees
regenerated, both drivers rebuilt, and the positive transcript above rerun
successfully. Plant build artifacts are not used for certification.

## Full-tier certification

The first full-tier attempt failed A1: `gen_fuel_parametricity.py --selftest`
had two positive controls hard-coded to the former 14-wrapper inventory.
The real-tree pin check and emitter both correctly reported 16. A2 passed;
A3 was stopped before completion. This attempt is not certification.
[AGENT 2026-10-18] Update the two control expectations to 16 alongside the
regenerated pin list. The classifier and refusal conditions are unchanged.

The second attempt failed A1's failure-reach selftest. The four measured
helpers initially used `failwithI CerbFuel.fuelExhaustedMsg`; their generated
zero-equation theorem RHSs appeared as four unresolved-owner failure sites.
A2, A3, A4 and A4b passed; A4c was stopped. This was not certification.
[AGENT 2026-10-18] Use the existing opaque `fuelExhausted` sentinel for these
four measured helpers, with type witnesses for their result types. Their
structural sufficiency proofs make the zero arms unreachable through the
wrappers. This follows the established measured-worker mechanism and leaves
the failure-reach gate and register unchanged. The two elaborators continue
to record an error before returning their internal placeholder.

The third attempt passed all 19 Tier A commands and 16 Tier B commands,
but FAILED B8.3. Its unchanged real-driver plant at `--fuel 1` expected a
FUEL row; the recorded-error translation boundary exhausted before the old
execution exhaustion point and was classified as LEAN_CRASH:

```text
[1/1] LEAN_CRASH 001-return-literal (exit 134): PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
FAILED: 1 Lean crash(es)
test_fuel_plant: PLANT FAILURES
full: incomplete; 35/42 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

B8.4 passed; B9 was stopped. The normal-fuel execution and GCC baseline
checks reported zero regressions and zero improvements; no baseline row
was edited. This failed attempt is not certification.

[AGENT 2026-10-18] Correct the shared reporting classifier to recognize the
exact LemLib `failwithIImpl` PANIC envelope, reserved fuel message and exit
134. In the exec lane both the old LEAN_CRASH classification and the
corrected FUEL class are fatal; no failure is admitted as agreement, no baseline is re-recorded,
and B8.3's expectation is unchanged. This fixes the integration with the
existing fuel contract without relaxing a gate. The charter prohibits gate
widening/weakening; it does not prohibit this classification correction.
The classifier's 18 existing fixtures are unchanged; five added fixtures
cover the real envelope, a non-abort exit, another error, a message suffix,
and an envelope embedded in program output. All 23 fixtures pass, as do the
unchanged `test_fuel_plant.sh` and the two translation witnesses. The record's
earlier LEAN_CRASH-only result was insufficient to satisfy the full tier.

The final `python3 scripts/release.py --mode full` run completed on the
unchanged implementation from 18:52:33 to 20:48:44 UTC (116.2 minutes,
derived). All 19 Tier A and 23 Tier B commands exited 0, with no artifact
issues. The runner reported:

```text
PASSED B8.3 (8.0s)
PASSED B9 (2309.0s)
PASSED B12 (428.4s)
full: passed; 42/42 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The last line is the runner's release-scope limitation; this mission claims
the required A+B tier result and its translation-specific checks, not a
customer release. Selected lane summaries:

```text
Baseline check: 0 regression(s), 0 improvement(s)
observation lane plants: 93/93 passed
Independent oracle scope: tier-b; 1000 rows in 197.8s; source unchanged: True
```

The baseline line is identical in A2, A3, A4, A4b and B7; those logs also
contain no same-rank verdict changes or new-file deviations. Every other
baseline-enforcing lane passed its own exact check. No baseline file was
changed. B7 compared its full 2030-row baseline; B10's existing reviewed
differences and matching failures retain their declared classes. B12's four
pristine-versus-fork libxml2 slices all reported semantic agreement.

## Original completion assessment and deviations (superseded 2026-10-19)

- All six former partial workers had the required forms and consumer
  equations, but the recorded-error exhaustion contract was false on the
  constant-expression path. The pre-merge audit invalidated the original
  completion assessment. The two elaborators retain AMBIENT form; their
  future measure work is in TODO.md. No pure/state helper is parked.
- Development checks and commits were consolidated under the operator's
  revised gate-scheduling instruction. D0's interrupted run is explicitly
  incomplete above; the final full run checks the existing baseline pins.
- The reporting-classifier correction was necessary for the existing B8.3
  contract. At `f12d9645a`, its assertion and all previous classifier fixtures
  were unchanged; the five new fixtures cover the added envelope.
- Final record text was added after the full run. Implementation, tests,
  manifests, dependency pins and baseline files did not change between that
  run and `f12d9645a`.
- Raw runs, probe files and OCaml snapshots are ephemeral and are removed
  after recording these conclusions. The commands above regenerate them.
  The assigned worktree is retained for the orchestrator's review. No merge
  or push is performed by this worker.

## Orchestrator review follow-up (2026-10-18)

[AGENT 2026-10-18] Orchestrator review findings on `f12d9645a`, relayed to
the worker by the operator: resolve P2 (restore the real-driver
execution-exhaustion witness) and P3 (cite this record in the translation
manifest NOTE) in one follow-up commit, with Tier A passing before the
commit. The orchestrator retains responsibility for landing.

P2 is confirmed: fixture 001 at fuel 1 now fails during translation, so
the original B8.3 real-driver row did not witness execution exhaustion.
The row remains, with its comment corrected and its assertion narrowed to
`FUEL:panic, exit 134`. A second real-driver row uses this finite loop:

```c
int main(void) { int i = 0; while (i < 100) { i = i + 1; } return 0; }
```

[AGENT 2026-10-18] Use fuel 128 for the loop's execution witness: translation
already succeeds at 8, while execution still exhausts at 512 and completes
at 100000. Thus 128 has margin above the measured sufficient translation
budget and below the execution requirement. Fuel 1 lies below the
translation requirement for fixture 001. Both selected budgets are caller
parameters; no driver default changes. Keep a default-fuel MATCH control
for each program, so the finite loop also has a successful oracle comparison.

Measurements used the unchanged real driver from `f12d9645a`, with
`LEAN_ABORT_ON_PANIC=1`, `scripts/capped timeout 30`, and
`CERB_MEM_MAX=48G`. Export each fixture using
`cerberus --runtime=_build/install/default --cabs-json <file.c>`; run
`cerberus-lean <mode> --fuel <N> --runtime=_build/install/default <file.json>`.
The probe printed the command parameters and exit status, then the relevant
output lines verbatim (`--pp-core` returns after translation):

```text
001-return-literal: --pp-core --fuel 1, exit 134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
execution-loop: --pp-core --fuel 8, exit 0
proc main arity=0
execution-loop: --pp-core --fuel 128, exit 0
proc main arity=0
execution-loop: --batch --fuel 128, exit 1
Error {msg: "lem: fuel exhausted"}
execution-loop: --batch --fuel 512, exit 1
Error {msg: "lem: fuel exhausted"}
execution-loop: --batch --fuel 100000, exit 0
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

The new B8.3 row requires exactly `FUEL:kill, exit 1` and a nonzero lane
exit; translation exhaustion cannot satisfy it. The finite loop is created
in the plant's temporary directory and removed by its existing cleanup.
P3 adds the record path to the dated `translation.lem` NOTE in
`scripts/fork_drift_manifest.txt`; the source-content pin is unchanged.

Focused check: `bash -n scripts/test_fuel_plant.sh` and
`bash scripts/test_fuel_plant.sh` both exited 0. Selected plant output:

```text
PLANT OK   [exec/real driver at --fuel 1 -> translation FUEL:panic]: [1/1] FUEL 001-return-literal (FUEL:panic, exit 134): lem: fuel exhausted
PLANT OK   [exec/real driver at the default fuel -> MATCH]: [1/1] MATCH 001-return-literal: VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
PLANT OK   [exec/real loop at --fuel 128 -> execution FUEL:kill]: [1/1] FUEL execution-loop (FUEL:kill, exit 1): lem: fuel exhausted
PLANT OK   [exec/real loop at the default fuel -> MATCH]: [1/1] MATCH execution-loop: VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; real translation at --fuel 1 reads FUEL:panic, real execution at --fuel 128 reads FUEL:kill, both at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
```

Before the follow-up commit, `CERB_MEM_MAX=48G python3 scripts/release.py
--mode fast` in the documented build environment passed from 23:23:53 to
23:42:56 UTC on 2026-10-18 (19.0 minutes, derived). All 19 Tier A commands
exited 0, with no artifact issues. The runner reported:

```text
PASSED A14.2 (172.1s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

This is the requested Tier A result plus the focused B8.3 result above;
the earlier full A+B result belongs to `f12d9645a`. No semantics, proof,
dependency pin or baseline file changes are part of this follow-up.
Only this final gate-result text was added after the Tier A run; the tested
script and manifest NOTE stayed unchanged through the commit.

## Correction after pre-merge audit (2026-10-19)

The [pre-merge audit](2026-10-19_translation-fuel-premerge-audit.md), committed
at `b69db5d87`, found a real semantic regression. `Mini_pipeline.toCore`
calls `translate_expression`, then `mini_pipeline.lem:157` runs it with
plain `runStateM`. The recorded error was discarded; the placeholder was
executed and reported as UB036. `runStateM_errors` did not guard this run
point. The earlier claim of refusal for every translation exhaustion, and
the original commit message's general claim, were wrong. The historical
logs above are retained as measurements of their stated cases, not evidence
that the old implementation was mergeable.

[USER 2026-10-19, operator ruling relayed by the orchestrator] Replace both
elaborator zero arms with direct `failwithI CerbFuel.fuelExhaustedMsg`
refusals. This explicitly overrides the charter's recorded-error payload
requirement; leave Mini_pipeline and shared Lem bodies unchanged.
[AGENT 2026-10-19, orchestrator direction relayed to the worker] Address the
audit findings in one commit after Tier A, with raw panic-envelope coverage,
the constant-expression witness and corrected consumer claims. Keep the
mini-run's own execution-exhaustion classification as a TODO for another slice.

The orchestrator rebased this branch from `b1c539c45` onto `049eb9a0a`:

| Original commit | Rebased commit | Change |
|---|---|---|
| `f12d9645a` | `17eeb7708` | translation implementation and original full-tier record |
| `89f3b9683` | `5c17dcb28` | first review's execution witness and manifest citation |

`git diff --name-only` for each old/new pair lists only
`lean_frontend/docs/2026-10-18_codex-charters-review.md`, the landing's review
document. Each pair therefore has the same implementation tree, but the
historical gate runs remain attributed to the original hashes.
`aecdd8708` subsequently corrected the first review instruction's provenance;
this correction starts from the clean audited head `b69db5d87`.

Both zero arms now equal the opaque refusal leaf at `elabM (expr Unit)`;
there is no Core placeholder or data-level error channel. The two
`TranslationFuelTest.*_zero_boundary` theorems now pin these direct equations
by `rfl`, without a state runner or clean-state assumption. The workers remain
AMBIENT and reachable from frontend entry points; being outside the
fuel-forms gate's drive closure is not a whole-binary unreachability claim.
These kernel equations identify the opaque leaf; runtime refusal is checked
by the driver witnesses. The existing LemLib leaf has an `implemented_by`
override to private unsafe `failwithIImpl` (the native panic boundary), not
a kernel theorem of a process exit. No new override or unsafe definition
is added by this correction.

Before changing the zero arms, the expanded `test_translation_fuel.sh`
failed on the existing binary (exit 1). Its enum constant contains 192
nested additions and `main` returns that constant. Selected output:

```text
translation-fuel: FAIL constant-expression mode=--batch fuel=128 exit=1 class=
Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:646--1:1039>"}
translation-fuel: FAIL constant-expression mode=--pp-core fuel=128 exit=1 class=
Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:646--1:1039>"}
[1/1] MATCH constant-expression: VAL:{value: "Specified(192)", stdout: "", stderr: "", blocked: "false"}
translation-fuel: FAIL (see rejected witnesses above)
```

The test requires exit 134, `FUEL:panic`, the exact `failwithIImpl` envelope
on stderr and empty stdout at fuel 128 under both modes. Its default-fuel
control requires the exec lane's exact MATCH with `Specified(192)`.
The existing dead-code witnesses remain. B8.3 now also runs the real binary
directly on `min.json` at fuel 1 and checks stderr with
`FUEL_ELAB_PANIC_LINE_RE`; the identical predicate must reject a bare
sentinel at exit 134 even though the shared classifier calls it FUEL:panic.
Thus the test no longer infers the envelope from the exec lane's fixed suffix.

After the correction, the same translation test and B8.3 both exited 0.
The two new refusal cases and default-fuel oracle control reported:

```text
translation-fuel: constant-expression mode=--batch fuel=128 exit=134 class=FUEL:panic
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
translation-fuel: constant-expression mode=--pp-core fuel=128 exit=134 class=FUEL:panic
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
[1/1] MATCH constant-expression: VAL:{value: "Specified(192)", stdout: "", stderr: "", blocked: "false"}
translation-fuel: PASS (two dead-code witnesses, constant-expression refusal in batch and pp-core, five successful controls)
```

B8.3's raw-stderr check and its negative control reported:

```text
PLANT OK   [real --fuel 1 stderr: failwithIImpl envelope, exit 134]
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
PLANT OK   [negative: bare FUEL:panic exit 134 rejected by envelope predicate]
```

Reproduction (documented build environment, `CERB_MEM_MAX=48G`):

```sh
make prelude-src lean-prelude-src
bash scripts/test_translation_fuel.sh
bash scripts/test_fuel_plant.sh
bash scripts/check_fuel_forms.sh
bash scripts/check_fork_drift.sh
(cd lean_frontend && ../scripts/capped lake build totality-proof-test)
(cd lean_frontend && ../scripts/capped lake env leanchecker Translation Translation_lemMeasureProofs Translation_auxiliary Unit.TranslationFuelTest Unit.TotalityProofTest)
```

All commands exited 0. The two drivers were rebuilt after regeneration.
`diff -rq` against the pre-correction generated OCaml snapshot exited 0 with
no output: all 86 files are byte-identical (derived count). Mini_pipeline,
all shared Lem bodies, dependency pins and baselines are unchanged. The
single source-content manifest row for `translation.lem` was emitted with
`check_fork_content.py --emit` and re-pinned to
`5d960f4e69f759c86ad811f2d776673340619cbd37f96da0fad8495fa2026466`, with a
dated NOTE citing this record. Fork-drift layer 2 remains unchanged.

The fuel-forms gate passed; the pair remains AMBIENT and outside its drive
closure. Fresh tool rows (trailing empty hypothesis columns omitted):

```text
FUEL_FORM	translate_expression_lemFuel	AMBIENT	no/front	zero=translate_expression_lemFuel_zero rhs-consts=[failwithI, elab_state, Prod, generic_expr, Unit, sym, Pi.instInhabited, instInhabitedProd, instInhabitedGeneric_expr, instInhabitedElab_state, CerbFuel.fuelExhaustedMsg]
FUEL_FORM	translate_stmt_lemFuel	AMBIENT	no/front	zero=translate_stmt_lemFuel_zero rhs-consts=[failwithI, elabM, expr, Unit, Pi.instInhabited, elab_state, Prod, instInhabitedProd, instInhabitedGeneric_expr, sym, instInhabitedElab_state, CerbFuel.fuelExhaustedMsg]
FUEL_FORMS_SUMMARY	workers=87	measured=67	measured_under_hyp=13	absorbing=13	ambient_reachable=0	ambient_unreachable=7	closure_size=10723
check_fuel_forms: forms partition OK (67 MEASURED + 13 ABSORBING + 0 ambient-reachable + 7 ambient-unreachable = 87 fuel'd workers)
```

Lean 4.32.2 kernel replay of all five modules in the command above exited 0.
The axiom probe described earlier was rerun over the same 25 named theorems
(derived count): every cone is a subset of `propext`, `Classical.choice`,
`Quot.sound`. In particular, the changed equations reported:

```text
'translate_expression_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'translate_stmt_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'TranslationFuelTest.statement_zero_boundary' depends on axioms: [propext, Classical.choice, Quot.sound]
'TranslationFuelTest.expression_zero_boundary' depends on axioms: [propext, Classical.choice, Quot.sound]
```

The changed unit module compiled without warnings. The builds still replay
inherited warnings in unchanged code; none was suppressed by this fix.

The first Tier A attempt FAILED A1's failure-reach selftest. The census
reported the `failwithI` occurrences in both generated zero-equation theorem
statements as unresolved owners. Its Lean instrument emitted ranges for
definitions and opaques only, omitting theorems. The existing fail-closed
policy therefore required register rows for these unresolved sites:

```text
NEW pure exec-closure site (no register row — review it): lean_frontend/generated/Translation.lean:4467 <unresolved compiler declaration> failwithI «CerbFuel.fuelExhaustedMsg) := rfl structure collect_cases_st» position=OTHER scope=UNRESOLVED-OWNER
NEW pure exec-closure site (no register row — review it): lean_frontend/generated/Translation.lean:5859 <unresolved compiler declaration> failwithI «CerbFuel.fuelExhaustedMsg) := rfl def translate_tag_definiti» position=OTHER scope=UNRESOLVED-OWNER
FAILED A1 (427.4s)
INCOMPLETE A3 (43.2s)
fast: incomplete; 1/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

A2 passed; the owned runner was stopped during A3 after the A1 failure.
This run is not certification. Dirty worktrees were snapshotted to refs
before further edits, without moving branches or their indexes.

[AGENT 2026-10-19] Include theorem declarations in `FailureReach.lean`'s
compiler range and dependency output. This repairs missing ownership
evidence for the zero equations rather than adding register exceptions.
The gate's register and rejection policy are unchanged. Add a focused
selftest witness for the two actual theorem owners and their workers:
the theorem sites are identified with neither dependency bit set; both
worker refusal sites remain identified frontend dependencies. Existing
plants must still reject new execution sites and discarded failures.

`bash scripts/check_failure_reach.sh --selftest` then exited 0: all eight
existing negative plants, seven classifier witnesses, the key-group witness
and the new ownership witness passed. The register was not edited:

```text
WITNESS OK   [R1 theorem statements have compiler owners; both worker refusal sites remain frontend dependencies]
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
```

The final pre-commit `CERB_MEM_MAX=48G python3 scripts/release.py --mode fast`
run, in the documented build environment, passed from 05:12:08 to 05:30:46
UTC on 2026-10-19 (18.6 minutes, derived). All 19 selected commands exited 0;
the report has no artifact issues. The runner reported:

```text
PASSED A1 (453.4s)
PASSED A14.2 (161.8s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The new constant-expression test and the corrected failure-reach selftest
also passed within A1. Existing baseline rows are unchanged. This correction
reports the requested Tier A result, focused B8.3, fuel-forms/fork-drift
checks, axiom audit and kernel replay; the earlier full A+B runs are
historical results on the pre-correction implementation, not a full-tier
claim for this tree. Only this final result text was added after the green
run; code, tests, manifests and baselines stayed unchanged through the commit.
