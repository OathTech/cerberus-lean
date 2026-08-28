/-
  RelSem.Kit.EvalStep — V2 (2026-08-28): PURE-EXPRESSION construct
  laws at SYMBOLIC operands — the one-step evaluator's env-consulting
  and value-branching arms, systematized (infrastructure plan
  component C(i): "pure-expression evaluation at symbolic operands").

  THE MEASURED SHAPE this exploits (the V1 F-trick, generalized): the
  generated one-step evaluator (`step_eval_pexpr_lemFuel`,
  generated/Core_eval.lean:142) consults the ENVIRONMENT only in the
  `PEsym` arm, and inspects VALUE payloads only at boolean-guard
  positions (`PEif`/`PEnot`) — every other arm matches CONSTRUCTORS
  (visible even at symbolic payloads) and computes. Consequences,
  each a law below:

  * `se_sym_hit` — the lookup arm, exposed once generically and
    rewritten closed by a cell fact (the per-position F-trick
    transcriptions of the V1 demo, systematized into ONE law);
  * `se_if_bool` — the boolean-guard arm FUSED over a symbolic
    `Bool`-indexed guard value (`if b then Vtrue else Vfalse`): the
    result carries the arm choice as an `if` at the OUTPUT — path
    stays single, the machine-level split happens once, at the
    `wpk_case_*` rules (RefinedC typed_if discipline);
  * `se_not_bool` — the same fusion at `PEnot`;
  * chain steps that consult NEITHER env nor payloads are `rfl` at
    a UNIVERSALLY QUANTIFIED environment (measured: the T1 conv-chain
    steps s1–s3 hold ∀ env by the same rfl that proved them at the
    concrete env) — no law needed, the instance states them ∀-env.

  Lineage: decompilation-into-logic (per-arm laws over the generated
  evaluator); symbolic-execution canon (the fused-guard form is the
  standard "ite-lifting" of symbolic evaluators).

  Import discipline: no Iris, no fixtures.
  House rules: no sorry, no axioms declared here.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Kit.Eval
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

open RelSem RelSem.Cerb
open Lem_Basic_classes (ordCompare)

/-! ## mapM glue (extends `eumapM_one`) -/

theorem eumapM_nil {A C M : Type} {f : C → exceptM (t0 A) M} :
    exception_undef_mapM f ([] : List C) = Result (Defined []) := rfl

theorem eumapM_cons {A C M : Type} {f : C → exceptM (t0 A) M}
    {a : C} {as' : List C} {b : A} {bs : List A}
    (h : f a = Result (Defined b))
    (hs : exception_undef_mapM f as' = Result (Defined bs)) :
    exception_undef_mapM f (a :: as') = Result (Defined (b :: bs)) := by
  -- peel the sequenced tail out of `hs`
  rcases hres : except_mapM f as' with us | e
  · have hus : mapM1 (fun (x : t0 A) => x) us = Defined bs := by
      have := hs
      unfold exception_undef_mapM at this
      rw [hres] at this
      injection this with h2
    show except_bind (except_sequence (List.map f (a :: as')))
        (fun us => except_return (mapM1 (fun (x : t0 A) => x) us)) = _
    have hseq : except_sequence (List.map f (a :: as'))
        = except_bind (f a) (fun x =>
            except_bind (except_sequence (List.map f as')) (fun xs =>
              except_return (x :: xs))) := rfl
    rw [hseq, h]
    show except_bind (except_bind (except_mapM f as') _) _ = _
    rw [hres]
    show except_return (mapM1 (fun (x : t0 A) => x) (Defined b :: us))
      = _
    have : mapM1 (fun (x : t0 A) => x) (Defined b :: us)
        = bind2 (Defined b) (fun x => bind2
            (mapM1 (fun (x : t0 A) => x) us)
            (fun xs => return1 (x :: xs))) := rfl
    rw [this, hus]
    rfl
  · exfalso
    have := hs
    unfold exception_undef_mapM at this
    rw [hres] at this
    exact absurd this (by simp [except_bind])

/-! ## THE LOOKUP LAW (`se_sym_hit`) -/

/-- CONSTRUCT LAW `se_sym_hit` — the one-step evaluator at `PEsym z`
    with a HIT: the extern remap misses (`hext` — ground per program:
    the extern map is concrete fixture data) and the environment
    lookup is a CELL FACT (`hlk` — what an `envIs` fragment yields).
    Generic over the ENVIRONMENT and every other argument: this is
    the V1 demo's per-position `symEvalF` transcription, systematized
    into one registered law. -/
@[step_law (kind := evalPull) (variant := symHit) (side := fed)
  (frontier := "eval/sym-hit")
  (trace := "{law := se_sym_hit, joint := eval/sym, hyps := [hext : ground, hlk : fed(cell fact)]}")
  (lineage := "the F-trick at the evaluator's one env-consulting arm, proved once (V1 CerbStateDemo symEvalF, generalized)")]
theorem se_sym_hit {fuel : Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {n : Nat} {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation} {b : Bool}
    {a : List annot} {z : sym} {v : value}
    (hext : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) z ext = none)
    (hlk : lookup_env z env = some v) :
    step_eval_pexpr_lemFuel (fuel + 1) tagDefs n loc cloc ext env memo
        file1 b (Pexpr a () (PEsym z))
      = Result (Defined (Pexpr [] () (PEval v))) := by
  show exception_undef_fmap (Pexpr [] ())
      (let z' := match fmapLookupBy
          (fun (s1 s2 : sym) => ordCompare s1 s2) z ext with
        | some s => s
        | none => z
       match lookup_env z' env with
       | none =>
         (match fmapLookupBy
             (fun (s1 s2 : sym) => ordCompare s1 s2) z' file1.funs with
          | some (Proc _ _ _ _ _) =>
              exception_undef_return
                (PEval (Vobject (OVpointer
                  (CerbMem.nullPtrval (Ctype [] Void0)))))
          | _ => exception_undef_fail (Unresolved_symbol loc z'))
       | some cval => exception_undef_return (PEval cval))
      = Result (Defined (Pexpr [] () (PEval v)))
  rw [hext]
  show exception_undef_fmap (Pexpr [] ())
      (match lookup_env z env with
       | none =>
         (match fmapLookupBy
             (fun (s1 s2 : sym) => ordCompare s1 s2) z file1.funs with
          | some (Proc _ _ _ _ _) =>
              exception_undef_return
                (PEval (Vobject (OVpointer
                  (CerbMem.nullPtrval (Ctype [] Void0)))))
          | _ => exception_undef_fail (Unresolved_symbol loc z))
       | some cval => exception_undef_return (PEval cval))
      = Result (Defined (Pexpr [] () (PEval v)))
  rw [hlk]
  rfl

/-! ## THE BOOLEAN-GUARD FUSIONS -/

/-- CONSTRUCT LAW `se_if_bool` — `PEif` at a SYMBOLIC boolean guard:
    the guard evaluates (`hg`, fed) to the Bool-indexed value
    `if b then Vtrue else Vfalse`; both arms evaluate (`h2`, `h3`,
    fed); the result carries the choice as an output-level `if`. The
    path stays single — the machine-level split happens ONCE at the
    `wpk_case_*` rules. -/
@[step_law (kind := evalPull) (variant := ifBool) (side := fed)
  (frontier := "eval/if-bool")
  (trace := "{law := se_if_bool, joint := eval/if, hyps := [hg : fed, h2 : fed, h3 : fed]}")
  (lineage := "ite-lifting at the evaluator's boolean-guard arm (symbolic-execution canon); RefinedC typed_if consumes the output-level if at the split")]
theorem se_if_bool {fuel : Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {n : Nat} {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation} {hc : Bool}
    {a : List annot} {pe1 pe2 pe3 : generic_pexpr Unit sym}
    {b : Bool} {a1 : List annot}
    {z2 z3 : generic_pexpr_ Unit sym}
    (hg : step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext env
        memo file1 false pe1
      = Result (Defined (Pexpr a1 ()
          (PEval (if b then Vtrue else Vfalse)))))
    (h2 : b = true →
      step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext env
        memo file1 false pe2 = Result (Defined (Pexpr [] () z2)))
    (h3 : b = false →
      step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext env
        memo file1 false pe3 = Result (Defined (Pexpr [] () z3))) :
    step_eval_pexpr_lemFuel (fuel + 1) tagDefs n loc cloc ext env memo
        file1 hc (Pexpr a () (PEif pe1 pe2 pe3))
      = Result (Defined (Pexpr [] () (if b then z2 else z3))) := by
  cases b with
  | true =>
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_bind
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false pe1) _) = _
    rw [eubind_defined hg]
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_fmap _
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false pe2)) = _
    rw [h2 rfl]
    rfl
  | false =>
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_bind
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false pe1) _) = _
    rw [eubind_defined hg]
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_fmap _
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false pe3)) = _
    rw [h3 rfl]
    rfl

/-- CONSTRUCT LAW `se_not_bool` — `PEnot` at a symbolic boolean
    operand (fused). -/
@[step_law (kind := evalPull) (variant := notBool) (side := fed)
  (frontier := "eval/not-bool")
  (trace := "{law := se_not_bool, joint := eval/not, hyps := [hg : fed]}")
  (lineage := "ite-lifting at the PEnot arm")]
theorem se_not_bool {fuel : Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {n : Nat} {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation} {hc : Bool}
    {a a0 : List annot} {pe0 : generic_pexpr_ Unit sym}
    {b : Bool} {a1 : List annot}
    (hg : step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext env
        memo file1 false (Pexpr a0 () pe0)
      = Result (Defined (Pexpr a1 ()
          (PEval (if b then Vtrue else Vfalse))))) :
    step_eval_pexpr_lemFuel (fuel + 1) tagDefs n loc cloc ext env memo
        file1 hc (Pexpr a () (PEnot (Pexpr a0 () pe0)))
      = Result (Defined (Pexpr [] ()
          (PEval (if b then Vfalse else Vtrue)))) := by
  cases b with
  | true =>
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_bind
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false _) _) = _
    rw [eubind_defined hg]
    rfl
  | false =>
    show exception_undef_fmap (Pexpr [] ())
        (exception_undef_bind
          (step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc cloc ext
            env memo file1 false _) _) = _
    rw [eubind_defined hg]
    rfl

/-! ## THE CALL LAW (`se_call`) -/

/-- CONSTRUCT LAW `se_call` — the one-step evaluator at `PEcall`:
    arguments evaluate (`hmap`, fed — the chain of se laws through
    `eumapM_cons`), values extract (`hvals`, ground), the callee
    inlines by substitution (`hcall`, ground: `call_function` walks
    the CONCRETE file and substitutes — it never branches on the
    symbolic payloads), the result pulls (`hpull`, ground). -/
@[step_law (kind := evalPull) (variant := call) (side := fed)
  (frontier := "eval/call")
  (trace := "{law := se_call, joint := eval/call, hyps := [hmap : fed, hvals : ground, hcall : ground, hpull : ground]}")
  (lineage := "decompilation of the PEcall arm: mapM + call_function + pull, once")]
theorem se_call {fuel : Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {n : Nat} {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation} {b : Bool}
    {a a2 : List annot} {nm : generic_name sym}
    {pes pes' : List (generic_pexpr Unit sym)} {cvals : List value}
    {peA : List annot} {pe_' pe'' : generic_pexpr_ Unit sym}
    (hmap : exception_undef_mapM
        (fun pe => step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc
          cloc ext env memo file1 false pe) pes
      = Result (Defined pes'))
    (hvals : valueFromPexprs pes' = some cvals)
    (hcall : call_function file1 nm cvals = Result (Pexpr peA () pe_'))
    (hpull : pull_constrained 0 (Pexpr [] () pe_')
      = Pexpr a2 () pe'') :
    step_eval_pexpr_lemFuel (fuel + 1) tagDefs n loc cloc ext env memo
        file1 b (Pexpr a () (PEcall nm pes))
      = Result (Defined (Pexpr [] () pe'')) := by
  show exception_undef_fmap (Pexpr [] ())
      (exception_undef_bind
        (exception_undef_mapM
          (fun pe => step_eval_pexpr_lemFuel fuel tagDefs (n + 1) loc
            cloc ext env memo file1 false pe) pes) _) = _
  rw [eubind_defined hmap]
  show exception_undef_fmap (Pexpr [] ())
      (match valueFromPexprs pes' with
       | some cvals => exception_undef_bind
           (except_bind (call_function file1 nm cvals)
             (fun g => match g with
               | Pexpr _ _ pe_ => exception_undef_return pe_))
           (fun pe_x =>
             match pull_constrained 0 (Pexpr [] () pe_x) with
             | Pexpr _ _ pe_y => exception_undef_return pe_y)
       | none => exception_undef_return (PEcall nm pes')) = _
  rw [hvals]
  show exception_undef_fmap (Pexpr [] ())
      (exception_undef_bind
        (except_bind (call_function file1 nm cvals)
          (fun g => match g with
            | Pexpr _ _ pe_ => exception_undef_return pe_)) _) = _
  rw [show (except_bind (call_function file1 nm cvals)
      (fun g => match g with
        | Pexpr _ _ pe_ => exception_undef_return pe_))
      = Result (Defined pe_') from by rw [hcall]; rfl]
  show exception_undef_fmap (Pexpr [] ())
      (match pull_constrained 0 (Pexpr [] () pe_') with
       | Pexpr _ _ pe_y => exception_undef_return pe_y) = _
  rw [hpull]
  rfl

/-! ## The whole-loop face at a symbol (the aux2 loop completes in one
    iteration on a PEsym hit) -/

/-- CONSTRUCT LAW `aux2_sym_hit` — the full eval loop at `PEsym z`
    with a cell-fact hit: one iteration, value out. -/
@[step_law (kind := evalPull) (variant := aux2Sym) (side := fed)
  (frontier := "eval/aux2-sym")
  (trace := "{law := aux2_sym_hit, joint := eval/aux2, hyps := [hpull : ground, hext : ground, hlk : fed(cell fact)]}")
  (lineage := "the loop face of se_sym_hit (aux2_done at the sym-hit leaf)")]
theorem aux2_sym_hit
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {a a' : List annot} {z : sym} {v : value}
    (hpull : pull_constrained 0 (Pexpr a () (PEsym z))
      = Pexpr a' () (PEsym z))
    (hext : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) z ext = none)
    (hlk : lookup_env z env = some v) :
    eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
        (Pexpr a () (PEsym z))
      = Result (Defined (Sum.inr v)) := by
  show eval_pexpr_aux2_lemFuel (999999 + 1) tagDefs loc cloc ext env
    memo file1 (Pexpr a () (PEsym z)) = _
  exact aux2_done 999999 tagDefs loc cloc ext env memo file1 hpull
    (by intro a' xs h; injection h with h1 h2 h3; cases h3)
    (se_sym_hit (fuel := 999999) hext hlk) rfl

end RelSem.Kit
