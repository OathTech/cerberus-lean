# Ail-to-Core translation fuel for cerberus-caesium (2026-10-18)

Implementation on `arc/translation-fuel`, based on `b1c539c45`.
Certification status and reproducible checks are in the
[work record](2026-10-18_translation-fuel-record.md). No release or landing
is implied by this branch note.

The six former `partial def`s in generated `Translation.lean` now have
kernel equations. The public `translate` entry and the OCaml translation
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

Both zero arms are
`bind1 (record_error CerbFuel.fuelExhaustedMsg) (fun _ => return0 mk_skip_e)`.
`elabM` remains a state monad: the intermediate Core placeholder is not an
absorbing result. `translate` finishes through `runStateM_errors`, which
rejects the accumulated error. Callers using the raw state computation must
also check its errors; a raw `(Core, state)` pair is not an accepted
translation. No sufficiency or exhaustion-unreachability claim is made for
these two workers. The API's arbitrary callback and logical-operator
desugaring prevent the simple subtree-size argument used for the helpers.

`bash scripts/test_translation_fuel.sh` exercises two uncalled functions:
one with a deep expression, one with deeply nested statements. At CLI fuel
128 both fail at the translation boundary; at 100000 both translate and run
`main` to `Specified(0)`. A simple `main` succeeds at both budgets. The
shell classifier recognizes the boundary's exact `failwithI` envelope as
`FUEL:panic` (exit 134), with `lem: fuel exhausted` in its PANIC line. The
exec lane reports fatal `FUEL`, never agreement. Unrelated panics and
messages embedded in program output remain outside this classification.

`Unit.TranslationFuelTest`, imported by the existing totality test, pins
the four measured equations and the two raw zero-worker boundary failures.
This extends the available equations for translation; it does not prove a
whole-frontend totality or C-to-Core correctness theorem, nor remove the
frontend digest's existing declared native boundary.
