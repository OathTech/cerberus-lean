# Ail-to-Core translation fuel for cerberus-caesium (2026-10-18)

Implementation on `arc/translation-fuel`, rebased from `b1c539c45` onto
`049eb9a0a`; the 2026-10-19 correction below supersedes the recorded-error
zero-arm design.
Certification status and reproducible checks are in the
[work record](2026-10-18_translation-fuel-record.md). No release or landing
is implied by this branch note.

The six former `partial def`s in generated `Translation.lean` now have
kernel equations. The public `translate` signature and the OCaml translation
are unchanged. Import `Translation_auxiliary` for the four generated
sufficiency theorems; its proof carrier is `Translation_lemMeasureProofs`.

| Worker | Wrapper equation, by `rfl` | Sufficiency theorem |
|---|---|---|
| `translate_constant` | `translate_constant enums tags c = translate_constant_lemFuel (constant.lemSize c) enums tags c` | `translate_constant_measure_sufficient` |
| `collect_cases_` | `collect_cases_ s = collect_cases__lemFuel (statement.lemSize s) s` | `collect_cases__measure_sufficient` |
| `erase_loop_control_aux` | `erase_loop_control_aux s = erase_loop_control_aux_lemFuel (statement.lemSize s) s` | `erase_loop_control_aux_measure_sufficient` |
| `collect_visibles_` | `collect_visibles_ s = collect_visibles__lemFuel (statement.lemSize s) s` | `collect_visibles__measure_sufficient` |

These four are MEASURED. Each theorem says that the raw worker at any
`lemFuel` at least the displayed measure equals its wrapper, on the same
arguments. There is no well-formedness hypothesis and no ambient fuel
instance. Production calls therefore have no premise to discharge. The
proofs use positive sizes and strictly smaller children at every recursive
call, including list elements, so the measured calls do not reach their
opaque failure zero arms. This establishes the fuel bound, not correctness
of translation or absence of other model errors.

The expression and statement workers are AMBIENT. Their equations spell
out both instance arguments; all explicit reader and syntax arguments are
still universally quantified by the function equality:

```lean
import Translation

example (n : Nat) (sws : CerbGlobal.Switches) :
    @translate_expression ⟨n⟩ sws =
      @translate_expression_lemFuel ⟨n⟩ sws n := rfl

example (n : Nat) (sws : CerbGlobal.Switches) :
    @translate_stmt ⟨n⟩ sws =
      @translate_stmt_lemFuel ⟨n⟩ sws n := rfl
```

The explicit reader order remains enum definitions, then tag definitions;
the later explicit `tagDefs` argument is separate. The raw worker's first
explicit argument is its counter. Its `[LemFuel]` instance supplies ambient
fuel to other workers it calls. Recursive self calls decrease the explicit
counter; do not identify that counter with every callee's budget.

Both zero arms are `failwithI CerbFuel.fuelExhaustedMsg`, an opaque refusal
leaf at type `elabM (expr Unit)`. There is no data-level error channel or
Core placeholder in these arms. The 2026-10-19 pre-merge audit found that
the earlier recorded-error design was wrong: `Mini_pipeline` evaluates
constant-expression translation with plain `runStateM`, discarding errors
and executing the placeholder as a false UB036 verdict. Direct refusal
does not rely on `runStateM_errors` or a caller inspecting the state.
`elabM` remains a state monad; this is not a typed absorbing-monad result.
The direct zero equations are pinned by `rfl`; their opaque right-hand side
does not expose an accepted Core result to kernel reduction. No sufficiency
or exhaustion-unreachability claim is made for these two workers. The API's
arbitrary callback and logical-operator
desugaring prevent the simple subtree-size argument used for the helpers.

`bash scripts/test_translation_fuel.sh` exercises two uncalled functions:
one with a deep expression, one with deeply nested statements. At CLI fuel
128 both fail at the translation boundary; at 100000 both translate and run
`main` to `Specified(0)`. A simple `main` succeeds at both budgets. The
same script also puts a 192-deep expression in an enum constant, exercising
`Mini_pipeline`. At fuel 128 both `--batch` and `--pp-core` must refuse with
the envelope and exit 134; at default fuel the exec lane must MATCH the
oracle's `Specified(192)`. The shell classifier recognizes the exact
`failwithI` envelope as
`FUEL:panic` (exit 134), with `lem: fuel exhausted` in its PANIC line. The
exec lane reports fatal `FUEL`, never agreement. Unrelated panics and
messages embedded in program output remain outside this classification.

`Unit.TranslationFuelTest`, imported by the existing totality test, pins
the four measured equations and the two direct raw zero-worker equations.
This extends the available equations for translation; it does not prove a
whole-frontend totality or C-to-Core correctness theorem, nor remove the
frontend digest's existing declared native boundary.
