/-
  RelSem.Call — THE FUNCTION-CALL ENTRY POINT (born arc-7 S3,
  2026-08-20).

  Given a compiled Core file and a designated function `f`, `callND`
  builds the driver computation that calls `f` with caller-supplied
  Core VALUES as arguments. This is the engine behind the driver
  executable's `--call <f> [--call-args <ints>]` mode (Main.lean runs
  `CerbND.runND` on this same `callND` — one artifact), which the
  differential test lanes use to exercise individual functions at
  concrete argument points (scripts/test_verify.sh).

  DESIGN ([AGENT:S3], the drive-generalization):
  * `callND` mirrors the generated `drive` (Driver.lean:500) exactly,
    with two substitutions: (a) the startup symbol is resolved from the
    designated NAME over `file.funs` instead of `file.main`; (b) the
    argc/argv preparation (`prepare_main_args`) is replaced by the
    general caller protocol for the designated function's parameters.
  * THE CALLER PROTOCOL: under the Normal calling convention the
    elaborator compiles a C function `int f(int x)` to a Core proc
    whose parameter is a POINTER; the CALL SITE allocates an object of
    the parameter's C type, stores the (converted) argument value, and
    passes the pointer (see the `create`/`store` pair in any elaborated
    caller, e.g. tests/verify/t1_id.c's main). `injectArg` reproduces
    exactly that: for a `BTy_object OTy_pointer` parameter it allocates
    at the funinfo-declared C type (`CerbMem.allocateObject`), stores
    the injected value (`memValueFromValue` + `CerbMem.storeM`), and
    binds the parameter to the pointer; any non-pointer parameter is
    bound to the injected value directly (Core-level `fun`s /
    Inner_arg-style params). Fidelity note: the call-site `conv_int`
    range conversion is NOT reproduced — an injected integer must fit
    the parameter type (out-of-range injections are the caller's
    responsibility); `memValueFromValue` returning `none`
    (ill-typed value) is an explicit `kill`, never a silent coercion.

  House rules: no sorry, no axioms.
-/

import Driver
import Core_aux
import CerbND
import RelSem.Machine
import RelSem.RunND
import RelSem.ExecModel
import RelSem.Cerberus

set_option autoImplicit false

open Lem_Basic_classes (ordCompare)

namespace RelSem
namespace Cerb

/-! ## Argument injection helpers (the Lean-value → Core-value boundary) -/

/-- A C `int`-shaped Core argument value: the loaded specified integer
    carrying `n` — the injection point for integer arguments. -/
def intValue (n : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.integerIval n)))

/-- All function symbols of `file1.funs` carrying the C-level name
    `fname` (the `SD_Id` description). Mirrors the generated driver's
    name-based symbol lookup (Driver.lean `struct_sym` pattern), total
    (non-`SD_Id` symbols simply don't match). -/
def funSymsNamed (file1 : file core_run_annotation) (fname : String) :
    List sym :=
  let dom := fmapDomainBy (fun (s1 s2 : sym) => ordCompare s1 s2) file1.funs
  setToList (Lem_Set.filter (fun (s : sym) =>
    match s with
    | Symbol _ _ (SD_Id n) => n == fname
    | _ => false) dom)

/-- Inject ONE argument per the caller protocol (design note above):
    pointer-typed parameters get a fresh object of the declared C type
    holding the injected value; everything else is passed through. -/
def injectArg (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (bty : core_base_type) (ty : ctype) (v : value) :
    driverM value :=
  match bty with
  | BTy_object OTy_pointer =>
    match memValueFromValue tagDefs ty v with
    | none => kill (Other (DErr_other
        "callND: argument value does not fit the parameter type"))
    | some mval =>
      liftMem (nd_bind
        (CerbMem.allocateObject tid0 (PrefOther "callND arg")
          (CerbMem.alignofIval ty) ty none none)
        (fun (ptr : CerbMem.PointerValue) => nd_bind
        (CerbMem.storeM (CerbLocation.other "callND arg init") ty false
          ptr mval)
        (fun (_ : CerbMem.Footprint) =>
        nd_return (Vobject (OVpointer ptr)))))
  | _ => nd_return v

/-- Inject a list of arguments against the parameter list (Core decl
    params, zipped with the funinfo C types), producing the
    (parameter-symbol, bound-value) environment entries. -/
def injectArgs (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) :
    List (sym × core_base_type) → List ctype → List value →
    driverM (List (sym × value))
  | [], [], [] => nd_return []
  | (psym, bty) :: params, ty :: tys, v :: vs =>
    nd_bind (injectArg tagDefs tid0 bty ty v) (fun (cval : value) =>
    nd_bind (injectArgs tagDefs tid0 params tys vs)
      (fun (rest : List (sym × value)) =>
    nd_return ((psym, cval) :: rest)))
  | _, _, _ => kill (Other (DErr_other "callND: argument count mismatch"))

/-! ## The call computation, in named stages -/

/-- Stage: resolve the designated name to its unique function symbol
    (no match / ambiguity are explicit `kill`s, never silent picks). -/
def resolveFunSym (file1 : file core_run_annotation) (fname : String) :
    driverM sym :=
  match funSymsNamed file1 fname with
  | [fsym] => nd_return fsym
  | [] => kill (Other (DErr_other
      (String.append "callND: no function named " fname)))
  | _ :: _ :: _ => kill (Other (DErr_other
      (String.append "callND: ambiguous function name " fname)))

/-- Stage: the designated function's parameter list and body (drive's
    startup-decl dispatch, verbatim semantics). -/
def lookupFunBody (file1 : file core_run_annotation) (fsym : sym) :
    driverM (List (sym × core_base_type) ×
      generic_expr core_run_annotation Unit sym) :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) fsym
      file1.funs with
  | some (Fun _ params pe) => nd_return (params, Expr [] (Epure pe))
  | some (Proc _ _ _ params e) => nd_return (params, e)
  | some (ProcDecl _ _ _) => kill (Other (DErr_other
      "callND: the designated function has no definition"))
  | some (BuiltinDecl _ _ _) => kill (Other (DErr_other
      "callND: the designated function has no definition"))
  | none => kill (Other (DErr_other
      "callND: designated function not found"))

/-- Stage: the funinfo-declared parameter C types (the caller protocol
    allocates pointer-passed parameters at these types). -/
def lookupParamTys (file1 : file core_run_annotation) (fsym : sym) :
    driverM (List ctype) :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) fsym
      file1.funinfo with
  | some (_, _, _, ptys, _, _) => nd_return (List.map Prod.snd ptys)
  | none => kill (Other (DErr_other
      "callND: no funinfo for the designated function"))

/-- Stage: with the arguments injected, bind the parameters into thread
    0's Core symbol environment (drive's argc/argv env move,
    generalized), allocate errno (verbatim from drive), point the arena
    at the designated function's body, run the driver loop, finalize. -/
def callFinish (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value)) : driverM driver_result :=
  nd_bind get_thread_states
    (fun (ths : List (Nat × (Option thread_id × thread_state))) =>
    match ths with
    | [(_, (_, th_st))] =>
        let env' : List (Fmap sym value) :=
          match th_st.env with
          | [] => [Lem_Map.fromList bound]
          | xs :: xs' =>
            (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
              fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2)
                pv.1 pv.2 m) xs bound) :: xs'
        nd_bind
          (liftMem (nd_bind
            (CerbMem.allocateObject tid0 (PrefOther "errno")
              (CerbMem.alignofIval signed_int) signed_int none none)
            (fun (ptr_val : CerbMem.PointerValue) =>
              let zero := CerbMem.integerValueMval (Signed Int_)
                (CerbMem.integerIval (0 : Int))
              nd_bind
                (CerbMem.storeM (CerbLocation.other "errno init")
                  signed_int false ptr_val zero)
                (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
          (fun (errno_ptr_val : CerbMem.PointerValue) =>
        nd_bind (driver_update_thread_state tid0
          ({ arena := expr1,
             stack0 := Stack_empty,
             errno := errno_ptr_val,
             current_loc := CerbLocation.other "RelSem.callND",
             exec_loc := ELoc_normal
               [(fsym, CerbLocation.other "RelSem.callND")],
             env := env',
             current_proc_opt := some fsym } : thread_state))
          (fun (_ : Unit) =>
        nd_bind (driver2 tagDefs false) (fun (_ : Unit) =>
        nd_bind nd_get (fun (dr_st' : driver_state) =>
        nd_return (finalize tagDefs "callND" dr_st')))))
    | _ => kill (Other (DErr_other
        "callND: not exactly one thread after globals")))

/-- THE FUNCTION-CALL ENTRY POINT at the ND-computation level: run the
    globals, resolve `fname`, inject `args` per the caller protocol,
    set thread 0's arena to the designated function's body with the
    parameters bound, run the driver loop, finalize. Structure is
    `drive` (Driver.lean:500) with the two documented substitutions —
    every combinator is the generated driver's own. -/
def callND (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) : driverM driver_result :=
  nd_bind (driver_globals tagDefs false file1) (fun (tid0 : Nat) =>
  nd_bind nd_get (fun (post_globals_dr_st : driver_state) =>
  nd_bind (resolveFunSym post_globals_dr_st.core_file fname)
    (fun (fsym : sym) =>
  nd_bind (lookupFunBody post_globals_dr_st.core_file fsym)
    (fun (pb : List (sym × core_base_type) ×
          generic_expr core_run_annotation Unit sym) =>
  nd_bind (lookupParamTys post_globals_dr_st.core_file fsym)
    (fun (ptys : List ctype) =>
  nd_bind (injectArgs tagDefs tid0 pb.1 ptys args)
    (fun (bound : List (sym × value)) =>
  callFinish tagDefs tid0 fsym pb.2 bound))))))
end Cerb
end RelSem
