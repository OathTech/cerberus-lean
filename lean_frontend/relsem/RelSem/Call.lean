/-
  RelSem.Call — arc-7 S3 (2026-08-20): THE SYMBOLIC-ARGUMENT HARNESS.

  The verification slate's quantification vehicle (charter
  docs/2026-08-19_arc7-layer2-charter.md, "Verification-target slate",
  operator ruling (1): theorems are QUANTIFIED over all possible inputs
  to the function). The slate statement template

    ∀ args, P args → every outcome of run(compile(f), inject args)
                      is Specified (s args)

  needs a Core-level function-call entry point: given a compiled Core
  file and a designated function `f`, an initial configuration that
  calls `f` with caller-supplied Core VALUES as arguments. Lean-level
  universal quantification then enters by quantifying the `args` list
  (e.g. `∀ x : Int, … callConfig … [intValue x] …`) — the arguments are
  data of the statement, never constants of the program.

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
    the parameter type, which is exactly the slate's range
    precondition (`P args`); `memValueFromValue` returning `none`
    (ill-typed value) is an explicit `kill`, never a silent coercion.
  * PARAMETRICITY: the harness produces a `DriveConfig` — the `Config`
    of THE sequential `ExecModel` instance (`seqModel`,
    RelSem/Cerberus.lean) — and every statement shape below speaks
    through the interface (`seqModel.Adequate`/`.UBFree`); Layer 3
    consumes `callConfig` as an ExecModel configuration, never the
    driver types directly. Nothing here is driver-executable-specific:
    Main.lean's `--call` mode runs `CerbND.runND` on this same `callND`
    (one artifact, arc-7 S2 doctrine).

  House rules: no sorry, no axioms declared here (the generated
  substrate's declared boundary enters through the quoted code);
  no Iris imports. Under the in-build audit (RelSem/Audit.lean).
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

/-! ## Argument injection helpers (the Lean-∀ → Core-value boundary) -/

/-- A C `int`-shaped Core argument value: the loaded specified integer
    carrying `n`. This is the injection point for integer-typed
    universally-quantified arguments (`∀ n : Int, … [intValue n] …`). -/
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

/-! ## The harness computation, in named stages (each stage a small
    def: proof units for the S4/S5 walk stay combinator-sized) -/

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

/-- THE SYMBOLIC-ARGUMENT HARNESS at the ND-computation level: run the
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

/-- THE HARNESS CONFIGURATION — the `initConfig` generalization the
    slate quantifies over: the initial `seqModel` configuration whose
    run calls `fname` on `args`. Universally-quantified Lean values
    enter as `args` entries (e.g. `[intValue x]` under `∀ x`). -/
def callConfig (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState) : DriveConfig :=
  ⟨.running (callND tagDefs file1 fname args),
   initial_driver_state file1 fs⟩

/-! ## Reachability + adequacy corollaries at the harness configuration
    (shapes [AGENT:S3] — the callConfig-specialized plumbing S5's
    adequacy discharge consumes; all proved, all through the interface). -/

/-- Relation-level reachability of a result from a harness call (proof
    infrastructure — never a headline statement, statement-TCB
    doctrine as for `DriveReaches`). -/
def CallReaches (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (r : driver_result) (st' : driver_state) : Prop :=
  DSteps (callConfig tagDefs file1 fname args fs) ⟨.done (.value r), st'⟩

/-- PROVED: every `Active` verdict the production runner enumerates for
    a harness call is `CallReaches`-reachable (the `runNDActiveSound`
    corollary at `callConfig`). -/
theorem callReaches
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    {r : driver_result} {tr : List String} {st' : driver_state}
    (h : (Active r, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs)) :
    CallReaches tagDefs file1 fname args fs r st' :=
  runND_sound _ _ _ _ _ h

/-- PROVED: every observable behavior the sequential model extracts
    from a harness configuration is `Steps`-reachable (instance
    coherence, specialized to `callConfig`). -/
theorem callOutcomes_sound
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState} {b : DriveBehavior}
    (h : seqModel.behavior (callConfig tagDefs file1 fname args fs) b) :
    DSteps (callConfig tagDefs file1 fname args fs) ⟨.done b.1, b.2⟩ :=
  seqModel_behavior_sound h

/-- Model-parametric adequacy of a harness call: every observable
    behavior of the call configuration satisfies `spec`. THE slate
    statements are instances of this shape (with `spec` pinning the
    `Specified` result and `¬ isUB`). -/
def CallAdequate (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : DriveBehavior → Prop) : Prop :=
  seqModel.Adequate (callConfig tagDefs file1 fname args fs) spec

/-- Model-parametric UB-freedom of a harness call. -/
def CallUBFree (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState) : Prop :=
  seqModel.UBFree (callConfig tagDefs file1 fname args fs)

/-- PROVED: Layer-2 → adequacy discharge at the harness configuration —
    a relational proof covering every reachable terminal configuration
    of the call discharges into `CallAdequate` (the exit ramp of the
    S4/S5 Iris chain: WP ⇒ iris adequacy ⇒ per-trace fact ⇒ this). -/
theorem callAdequate_of_reach
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : DriveBehavior → Prop)
    (h : ∀ b : DriveBehavior,
      DSteps (callConfig tagDefs file1 fname args fs) ⟨.done b.1, b.2⟩ →
      spec b) :
    CallAdequate tagDefs file1 fname args fs spec :=
  seqModel_adequate_of_reach _ spec h

/-! ## The CerbND-shaped headline form (statement-TCB: fuel opsem only) -/

/-- HEADLINE SHAPE for a harness call (the `HarnessAdequate` analogue):
    quantifies the production runner's outcome set only — no Iris, no
    `Step`, no `seqModel`. The slate theorems' statements are instances
    of this with `spec r` = "r's value is the specified image of the
    quantified arguments". -/
def CallHarnessAdequate
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) →
    ∃ r : driver_result, out = Active r ∧ spec r

/-- Status-injection inversion for the discharge below. -/
theorem ofStatus_value_inv {A E S : Type}
    {out : nd_status A E S} {r : A}
    (h : Outcome.ofStatus out = Outcome.value r) : out = Active r := by
  cases out with
  | Active a => injection h with h; exact h ▸ rfl
  | Killed st k => cases h

/-- PROVED DISCHARGE: model-parametric adequacy (at the value-shaped
    spec) yields the CerbND-shaped headline. This is the last plumbing
    step of the S5 chain: the ∃-fuel behavior extraction subsumes the
    default budget (`runND = runNDFuel ndDefaultFuel` by rfl), so an
    `Adequate` fact instantiates on every production-runner outcome. -/
theorem callHarnessAdequate_of_adequate
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : CallAdequate tagDefs file1 fname args fs
      (fun b => ∃ r : driver_result, b.1 = .value r ∧ spec r)) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  have hb : seqModel.behavior (callConfig tagDefs file1 fname args fs)
      (Outcome.ofStatus out, st') :=
    ⟨CerbND.ndDefaultFuel, (out, tr, st'), hmem, rfl⟩
  obtain ⟨r, hr, hs⟩ := h _ hb
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- CerbND-shaped UB-FREEDOM headline (arc-7 S5c, audit-1 F2): no
    outcome the production runner enumerates for the harness call is an
    `Undef0` kill. This is the statement-TCB twin of `CallUBFree`
    (which is `seqModel.UBFree` — a relational-layer object): the slate
    `T?_ubFree` theorems STATE this form, so their statements mention
    the fuel opsem only; the seqModel form remains the proof route's
    intermediate (WP ⇒ `CallUBFree` ⇒ this, `callHarnessUBFree_of_ubFree`). -/
def CallHarnessUBFree
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) →
    ∀ (stk : driver_state) (loc : CerbLocation.Loc)
      (ubs : List undefined_behaviour),
      out ≠ Killed stk (Undef0 loc ubs)

/-- PROVED DISCHARGE (the UB face of `callHarnessAdequate_of_adequate`):
    model-parametric UB-freedom yields the CerbND-shaped headline — a
    runner-enumerated `Undef0` kill would be a behavior `seqModel.isUB`
    classifies as UB. -/
theorem callHarnessUBFree_of_ubFree
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    (h : CallUBFree tagDefs file1 fname args fs) :
    CallHarnessUBFree tagDefs file1 fname args fs := by
  intro out tr st' hmem stk loc ubs hout
  have hb : seqModel.behavior (callConfig tagDefs file1 fname args fs)
      (Outcome.ofStatus out, st') :=
    ⟨CerbND.ndDefaultFuel, (out, tr, st'), hmem, rfl⟩
  exact h _ hb ⟨loc, ubs, by rw [hout]; rfl⟩

/-! ## The app-equation route to the slate conclusions (arc-7 S3).
    On the slate corpus every harness run is ONE bind-collapsed `app`
    computation (trace evidence, RelSem/Machine.lean § Coverage-by-
    need), so a single ∀-quantified `app` equation determines the whole
    behavior/outcome set. The corollaries below are the last mile from
    that equation to every statement shape the slate uses — S5 proves
    the equation (by WP or by direct computation) and cites these. -/

/-- One active `app` equation ⇒ model-parametric adequacy at any spec
    the terminal behavior satisfies. -/
theorem callAdequate_of_app_active
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st'))
    {spec : DriveBehavior → Prop} (hs : spec (.value r, st')) :
    CallAdequate tagDefs file1 fname args fs spec := by
  intro b hb
  have hb' : seqModel.behavior
      (⟨.running (callND tagDefs file1 fname args),
        initial_driver_state file1 fs⟩ : DriveConfig) b := hb
  rw [seqModel_behavior_running_active_iff h b] at hb'
  subst hb'
  exact hs

/-- One active `app` equation ⇒ UB-freedom of the call (a value
    behavior is never classified UB). -/
theorem callUBFree_of_app_active
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st')) :
    CallUBFree tagDefs file1 fname args fs :=
  callAdequate_of_app_active h
    (fun hub => match hub with | ⟨_, _, hh⟩ => nomatch hh)

/-- One active `app` equation ⇒ the CerbND-shaped UB-freedom HEADLINE
    (direct route; arc-7 S5c): the runner's outcome set is the `Active`
    singleton, which is no `Undef0` kill. -/
theorem callHarnessUBFree_of_app_active
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st')) :
    CallHarnessUBFree tagDefs file1 fname args fs := by
  intro out tr st'' hmem stk loc ubs hout
  rw [runND_active h] at hmem
  cases hmem with
  | head => cases hout
  | tail _ h' => cases h'

/-- One active `app` equation ⇒ the CerbND-shaped HEADLINE: the
    production runner's outcome set is exactly the `Active r`
    singleton, so every outcome is `Active` and satisfies any spec `r`
    does (statement-TCB shape: fuel opsem only). -/
theorem callHarnessAdequate_of_app_active
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st'))
    {spec : driver_result → Prop} (hs : spec r) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st'' hmem
  rw [runND_active h] at hmem
  cases hmem with
  | head => exact ⟨r, rfl, hs⟩
  | tail _ h' => cases h'

end Cerb
end RelSem
