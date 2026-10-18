import Translation_auxiliary

set_option autoImplicit false

namespace TranslationFuelTest

-- The measured wrappers use data-derived fuel, with no ambient instance.
example (enums : Fmap sym integerType)
    (tags : Fmap sym (CerbLocation.Loc × tag_definition)) (c : constant) :
    translate_constant enums tags c =
      translate_constant_lemFuel (constant.lemSize c) enums tags c := rfl

example (s : statement genTypeCategory) :
    collect_cases_ s = collect_cases__lemFuel (statement.lemSize s) s := rfl

example (s : statement genTypeCategory) :
    erase_loop_control_aux s = erase_loop_control_aux_lemFuel (statement.lemSize s) s := rfl

example (s : statement genTypeCategory) :
    collect_visibles_ s = collect_visibles__lemFuel (statement.lemSize s) s := rfl

-- Pin the boundary behavior independently of the generated zero equations.
-- Even with no pre-existing error, an exhausted worker cannot return a Core
-- result through runStateM_errors. The shell witnesses exercise the binary.
theorem statement_zero_boundary [LemFuel] [CerbGlobal.Switches]
    (enums : Fmap sym integerType)
    (tags coreTags : Fmap sym (CerbLocation.Loc × tag_definition))
    (stdlib : translation_stdlib) (f : sym) (env : translate_stmt_env)
    (s : statement genTypeCategory) (supply : Nat) (cc : calling_convention) :
    runStateM_errors (translate_stmt_lemFuel 0 enums tags stdlib coreTags f env s)
      (elab_init supply cc) = failwithI CerbFuel.fuelExhaustedMsg := rfl

theorem expression_zero_boundary [LemFuel] [CerbGlobal.Switches]
    (enums : Fmap sym integerType)
    (tags coreTags : Fmap sym (CerbLocation.Loc × tag_definition))
    (stdlib : translation_stdlib) (used : Bool) (ctx : expr_ctx)
    (variadic : Option sym × Option sym) (e : expression genTypeCategory)
    (supply : Nat) (cc : calling_convention) :
    runStateM_errors (translate_expression_lemFuel 0 enums tags none used ctx variadic stdlib coreTags e)
      (elab_init supply cc) = failwithI CerbFuel.fuelExhaustedMsg := rfl

end TranslationFuelTest
