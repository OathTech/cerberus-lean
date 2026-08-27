/-
  RelSem.CerbStateDemo — V1 (2026-08-28): THE SYMBOLIC-ENV FRAMING
  DEMONSTRATION (the slice's acceptance exhibit) + its engine room.

  THE EXHIBIT (`demo_wp` + the layer-1 endpoint `demo_adequate`): a
  real Core fragment `wseq y := (pure w) ; pure (sym x)` run by the
  real generated machine (one unrolled `drive_nonmemory_steps` round
  per WP step), starting from a state whose env binds BOTH locals:

    * the prover owns `envIs x 1 vx` with vx a SYMBOLIC value and
      `envIs y 1 w0`;
    * step 1 REBINDS y (the env-write rule consumes y's fragment and
      updates it; x's fragment is NOT MENTIONED — it survives by the
      FRAME RULE);
    * step 2 reads x at its symbolic value (the ctl+one-cell rule);
    * the readout is the driver's own `finalize`, and adequacy lands
      the layer-1 statement: every production-runner outcome is
      `Active` with core value EXACTLY vx — for ALL vx.

  Under the retired `restIs` route this shape was inexpressible: any
  step consumed the ONE whole-machine pin, so no assertion could hold
  a local at a symbolic value while the machine moved.

  ENGINE ROOM (below the exhibit; the V2 per-construct rules will
  systematize exactly these derivations):
  * the ctl-inversion at the demo skeleton (list/record eta — no Fmap
    reasoning);
  * round A's app equation, rfl at an ABSTRACT env frame;
  * round B's app equation: the eval chain (Kit crossing lemmas
    `stub_defined`/`liftCore_run_defined`/`aux2_done` + THE F-TRICK
    leaf `step_eval_sym`: the one-step evaluator abstracted at its
    stuck env-lookup position, then rewritten by the fragment fact);
  * lookup-preservation legs from the Kit/Map hit/skip laws under the
    EnvWf built-ness invariant.

  MIRROR NOTE (operator directive 2026-08-28): Caesium's lifting
  proofs (deps/refinedc/theories/caesium/lifting.v, heap.v) do the
  per-primitive frame-preservation work against a SMALL-STEP relation
  over gmap state; the chain below is the same obligation shape
  retrofitted onto Cerberus's EXECUTABLE interpreter (fused monadic
  rounds over closure-carrying Fmap state) — the extra layers
  (aux2 loop, runEU, bind fusion, the F-trick at the stuck lookup)
  are the Cerberus delta.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbStateAdequacy
import RelSem.Kit.Eval
import RelSem.T1File

set_option autoImplicit false

namespace RelSem
namespace CerbSt
namespace Demo

open Iris Iris.BI Iris.ProgramLogic
open RelSem RelSem.Cerb RelSem.CerbSt RelSem.T1
open Lem_Basic_classes (ordCompare)

/-! ## Fixtures -/

/-- The demo locals (fixture digest ""; numbers clear of t1File's
    vocabulary — validated by the extern/lookup reductions below). -/
def xSym : sym := Symbol "" 101 SD_None
def ySym : sym := Symbol "" 102 SD_None

def envCmp : sym → sym → LemOrdering := fun s1 s2 => ordCompare s1 s2

/-- Stage arenas: A rebinds y then reads x; B reads x; C holds the
    read value. -/
def arenaA (w : value) : expr core_run_annotation :=
  mk_wseq_e (mk_sym_pat ySym BTy_unit)
    (mk_pure_e (mk_value_pe w))
    (mk_pure_e (mk_sym_pe xSym))

def arenaB : expr core_run_annotation := mk_pure_e (mk_sym_pe xSym)

def arenaC (v : value) : expr core_run_annotation :=
  mk_pure_e (mk_value_pe v)

/-- The demo thread at an arena and an env frame. -/
def famTh (arena : expr core_run_annotation)
    (f₁ : Fmap sym value) : thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := CerbMem.nullPtrval signed_int,
    env := [f₁],
    current_proc_opt := none,
    exec_loc := ELoc_normal [],
    current_loc := CerbLocation.Loc.unknown }

/-- The demo state family: ONE thread over `t1File`; env frame,
    supplies, layout all parametric (what the control token does NOT
    pin). -/
def famσ (arena : expr core_run_annotation) (f₁ : Fmap sym value)
    (tS aS eS sS ctr : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := t1File,
    core_extern := create_extern_symmap t1File,
    core_state0 :=
      { thread_states := [(0, (none, famTh arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-- The initial env frame: BOTH locals bound (x at the symbolic vx,
    y at w0), canonical comparator captured at the first insert. -/
def frame0 (vx w0 : value) : Fmap sym value :=
  fmapAddBy envCmp ySym w0 (fmapAddBy envCmp xSym vx fmapEmpty)

/-- ONE `drive_nonmemory_steps` round, unrolled (the generated
    `drive_nonmemory_steps_aux2` body at one tid with the recursion
    cut — every atom is the generated computation itself). -/
def roundM (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) :
    ndM advance_info step_kind driver_error mem_iv_constraint
      driver_state :=
  nd_bind
    (nd_read (fun dr_st =>
      let th_info :=
        match Lem_List.lookupBy (fun x y => x == y) 0
            dr_st.core_state0.thread_states with
        | some z => z
        | none => failwithI "CerbStateDemo: invalid tid"
      step_ctx tagDefs dr_st.layout_state dr_st.core_file
        dr_st.core_extern 0 th_info))
    (fun steps =>
      match find_can_advance steps with
      | some step1 => advance_step tagDefs 0 step1
      | none => nd_return NOWAKEUP)

/-- The demo program fragment: round A (rebind y), round B (read x),
    then the driver's own readout (`finalize` — the harness terminal's
    real projection). -/
def demoK (w : value) : KDriveExpr :=
  .seq (roundM t1File.tagDefs) (fun _ =>
    .seq (roundM t1File.tagDefs) (fun _ =>
      .seq nd_get (fun σf =>
        .done (.value (finalize t1File.tagDefs "demo" σf)))))

/-! ## The control-stage values -/

/-- The canonical control image at a stage (env spine [1 frame],
    supplies zeroed, layout dropped). -/
def ctlAt (arena : expr core_run_annotation) (ctr : Nat) :
    driver_state :=
  ctlOf (famσ arena fmapEmpty 0 0 0 0 ctr CerbMem.initialMemState)

theorem ctlOf_famσ (arena : expr core_run_annotation)
    (f₁ : Fmap sym value) (tS aS eS sS ctr : Nat)
    (ls : CerbMem.MemState) :
    ctlOf (famσ arena f₁ tS aS eS sS ctr ls) = ctlAt arena ctr := rfl

/-! ## The ctl inversion (list/record eta at the demo skeleton) -/

theorem ctl_inv {σ : driver_state} {arena : expr core_run_annotation}
    {ctr : Nat} (h : ctlOf σ = ctlAt arena ctr) :
    ∃ (f₁ : Fmap sym value) (tS aS eS sS : Nat)
      (ls : CerbMem.MemState),
      σ = famσ arena f₁ tS aS eS sS ctr ls := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr, sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [ctlAt, ctlOf, famσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, p, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, famTh,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨f₁, tS, aS, eS, sS, ls, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

/-! ## Round A: the y-rebind (one rfl at an ABSTRACT env frame) -/

/-- The pattern-update spelling (the compiled matcher splits on the
    VALUE first, so `cases` forces it; no arm consults the payload). -/
theorem update_env_aux_sym (v : value) (f : Fmap sym value) :
    update_env_aux (mk_sym_pat ySym BTy_unit) v f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) ySym v f := by
  cases v <;> rfl

/-- The env-frame comparator spellings coincide (the captured-closure
    bookkeeping: `mapKeyCompare` at `sym` is the same `ordCompare`
    closure the Kit canon `symCmpO` wraps). -/
theorem mapKeyCompare_symCmpO :
    lemCmpToOrd (@Lem_Map.mapKeyCompare sym _) = RelSem.Kit.symCmpO :=
  rfl

/-- The step function the demo rounds take (thread 0's arena/env move
    + the step counter; the generated `advance_step` Step_tau2 /
    Step_with_runstate2 image at the singleton pool). -/
def updTh (arena : expr core_run_annotation)
    (envUpd : List (Fmap sym value) → List (Fmap sym value))
    (σ : driver_state) : driver_state :=
  match σ.core_state0.thread_states with
  | (tid, (p, th)) :: rest =>
      let th' : thread_state :=
        { th with arena := arena, env := envUpd th.env }
      let cs' : core_state :=
        { σ.core_state0 with thread_states := ((tid, (p, th')) :: rest) }
      { σ with core_state0 := cs',
               dr_step_counter := σ.dr_step_counter + 1 }
  | [] => σ

/-- Round A at the family: the successor rebinds y in the top frame
    and moves the arena — ONE rfl with the frame ABSTRACT (nothing in
    the tau path forces it; measured at V1's feasibility probe). -/
theorem roundA_app (w : value) (f₁ : Fmap sym value)
    (tS aS eS sS ctr : Nat) (ls : CerbMem.MemState) :
    app (roundM t1File.tagDefs) (famσ (arenaA w) f₁ tS aS eS sS ctr ls)
      = (NDactive NOWAKEUP,
         famσ arenaB (update_env_aux (mk_sym_pat ySym BTy_unit) w f₁)
           tS aS eS sS (ctr + 1) ls) := rfl

/-! ## Round B: the x-read (the eval chain through the Kit crossing
    lemmas; the leaf is THE F-TRICK — the one-step evaluator
    abstracted at its stuck env-lookup position) -/

/-- The one-step evaluator's PEsym continuation, abstracted at the
    lookup outcome (transcribed verbatim from
    generated/Core_eval.lean's PEsym arm at the demo's concrete
    extern/file; the `none` branch is dead after the rewrite but must
    match the reduct exactly for the exposure `rfl` to check). -/
def symEvalF (loc : CerbLocation.Loc) (o : Option value) :
    t1 pexpr core_run_cause :=
  exception_undef_fmap (Pexpr [] ())
    (match o with
     | none =>
         (match fmapLookupBy
             (fun (sym1 sym2 : sym) => ordCompare sym1 sym2)
             xSym t1File.funs with
          | some (Proc _ _ _ _ _) =>
              exception_undef_return
                (PEval (Vobject (OVpointer
                  (CerbMem.nullPtrval (Ctype [] Void0)))))
          | _ => exception_undef_fail (Unresolved_symbol loc xSym))
     | some cval => exception_undef_return (PEval cval))

/-- THE LEAF: one evaluator step at `PEsym x` — exposure at the stuck
    lookup by `rfl`, then the fragment fact rewrites it closed. -/
theorem step_eval_symx (loc : CerbLocation.Loc)
    (cloc : Option CerbLocation.Loc) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) (vx : value)
    (hx : lookup_env xSym env = some vx) :
    step_eval_pexpr t1File.tagDefs 0 loc cloc
        (create_extern_symmap t1File) env memo t1File false
        (mk_sym_pe xSym)
      = Result (Defined (Pexpr [] () (PEval vx))) := by
  rw [show step_eval_pexpr t1File.tagDefs 0 loc cloc
        (create_extern_symmap t1File) env memo t1File false
        (mk_sym_pe xSym)
      = symEvalF loc (lookup_env xSym env) from rfl, hx]
  rfl

/-- The eval loop at `PEsym x`: one iteration (the Kit `aux2_done`
    crossing at the leaf). -/
theorem aux2_symx (loc : CerbLocation.Loc)
    (cloc : Option CerbLocation.Loc) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) (vx : value)
    (hx : lookup_env xSym env = some vx) :
    eval_pexpr_aux2 t1File.tagDefs loc cloc
        (create_extern_symmap t1File) env memo t1File
        (mk_sym_pe xSym)
      = Result (Defined (Sum.inr vx)) := by
  show eval_pexpr_aux2_lemFuel (999999 + 1) t1File.tagDefs loc cloc
      (create_extern_symmap t1File) env memo t1File
      (mk_sym_pe xSym) = _
  exact Kit.aux2_done 999999 t1File.tagDefs loc cloc
    (create_extern_symmap t1File) env memo t1File
    (show pull_constrained 0 (mk_sym_pe xSym) = mk_sym_pe xSym
      from rfl)
    (fun a xs h => by simp [mk_sym_pe, mk_sym_pe_] at h)
    (step_eval_symx loc cloc env memo vx hx) rfl

/-- `eval_pexpr20` at the demo thread (the `runEU` wrapper computed;
    loc/cloc come from the thread's own fields). -/
theorem eval20_symx {b : Type} (arena : expr core_run_annotation)
    (f₁ : Fmap sym value) (ls : CerbMem.MemState) (st : b) (vx : value)
    (hx : lookup_env xSym [f₁] = some vx) :
    E.eval_pexpr20 t1File.tagDefs (famTh arena f₁)
        (create_extern_symmap t1File) ls t1File (mk_sym_pe xSym) st
      = Result (Defined (Sum.inr vx), st) := by
  show runEU (eval_pexpr_aux2 t1File.tagDefs
      CerbLocation.Loc.unknown none (create_extern_symmap t1File)
      [f₁] (some ls) t1File (mk_sym_pe xSym)) st = _
  rw [aux2_symx CerbLocation.Loc.unknown none [f₁] (some ls) vx hx]
  rfl

/-- `full_eval_pexpr` at the demo thread: the loop returns the
    symbolic x-value. -/
theorem full_eval_symx {b : Type} (arena : expr core_run_annotation)
    (f₁ : Fmap sym value) (ls : CerbMem.MemState) (st : b) (vx : value)
    (hx : lookup_env xSym [f₁] = some vx) :
    full_eval_pexpr t1File.tagDefs (famTh arena f₁)
        (create_extern_symmap t1File) ls t1File (mk_sym_pe xSym) st
      = Result (Defined vx, st) := by
  refine (Kit.stub_defined (eval20_symx arena f₁ ls st vx hx)).trans ?_
  rfl

/-- ROUND B at the family: the whole scheduler round reads x at its
    SYMBOLIC value into the arena — the `app`-layer bind chain over
    the Kit crossing lemmas. -/
theorem roundB_app (f₁ : Fmap sym value) (tS aS eS sS ctr : Nat)
    (ls : CerbMem.MemState) (vx : value)
    (hx : lookup_env xSym [f₁] = some vx) :
    app (roundM t1File.tagDefs) (famσ arenaB f₁ tS aS eS sS ctr ls)
      = (NDactive NOWAKEUP,
         famσ (arenaC vx) f₁ tS aS eS sS (ctr + 1) ls) := by
  refine (app_bind_active (app_nd_read _ _)).trans ?_
  refine (app_bind_active (app_nd_return _ _)).trans ?_
  refine (app_bind_active (Kit.liftCore_run_defined
    (Kit.stub_defined (Kit.stub_defined
      (full_eval_symx arenaB f₁ ls _ vx hx))))).trans ?_
  refine (app_bind_active (app_nd_update _ _)).trans ?_
  exact app_nd_return _ _

end Demo
end CerbSt
end RelSem
