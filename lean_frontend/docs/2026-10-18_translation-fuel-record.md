# Translation fuel — work record (2026-10-18)

Branch `arc/translation-fuel`, base `b1c539c45`. All six translation workers
have kernel equations: four MEASURED, two AMBIENT with fatal recorded
exhaustion. The final full A+B run passed 42/42 commands; axiom audit and
kernel replay passed. The charter slice is complete. Release certification
and whole-frontend correctness are separate claims.

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
  fuel. Exhaustion records `CerbFuel.fuelExhaustedMsg`, preserving the
  existing fuel message, before returning `mk_skip_e` internally. The boundary
  uses `failwithI`; the final classifier recognizes its exact reserved-message
  PANIC envelope at exit 134 as fatal FUEL:panic (the full-tier finding and
  correction are recorded below).

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
and raw zero-worker boundary equations; Part 1 of `TotalityProofTest` compiles
the ambient equations. The four sufficiency theorems are unconditional and
proved by positive structural sizes and strict descent on every recursive
call. No zero-arm unreachability is claimed for the ambient pair.

### Focused validation

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

All exited 0 on the final implementation. Close-out kernel replay with Lean
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

### Exhaustion witnesses and regression plant

`bash scripts/test_translation_fuel.sh` generates two small C witnesses with
192 levels inside an uncalled function: expression nesting or statement
nesting. Their `main` is the same simple successful control. The restored
implementation reports:

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
kernel boundary equations prove the raw zero-worker result reaches that
failure leaf. The shared shell classifier returns FUEL:panic for this exact
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

## Completion and deviations

- All six former partial workers have their required forms and consumer
  equations. The two elaborators retain the charter-permitted AMBIENT form;
  their future measure work is in TODO.md. No pure/state helper is parked.
- Development checks and commits were consolidated under the operator's
  revised gate-scheduling instruction. D0's interrupted run is explicitly
  incomplete above; the final full run checks the existing baseline pins.
- The reporting-classifier correction was necessary for the existing B8.3
  contract. Its assertion and all previous classifier fixtures remain
  unchanged; the five new fixtures cover the added envelope.
- Final record text was added after the full run. Implementation, tests,
  manifests, dependency pins and baseline files did not change afterward.
- Raw runs, probe files and OCaml snapshots are ephemeral and are removed
  after recording these conclusions. The commands above regenerate them.
  The assigned worktree is retained for the orchestrator's review. No merge
  or push is performed by this worker.
