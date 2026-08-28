/-
  RelSem.CStep — V3a (2026-08-28): THE PER-CONSTRUCT
  STEP-CHARACTERIZATION PACKAGE (mechanism C, probe tranche —
  proof-performance plan §3.C, PERF-2).

  WHAT THIS IS: the derived relational presentation (introduction
  lemmas) of the clocked definitional interpreter — the
  function→relation direction of the functional big-step
  correspondence (Owens–Myreen–Kumar–Tan, ESOP 2016; adjacent:
  Danvy's functional correspondence, Leroy–Grall). Iris-native
  precedent, per the reuse discipline: HeapLang's `PureExec`-class
  per-construct step characterization, proved once and consumed by
  `wp_pure`-style tactics. Each `cstep_*` lemma characterizes ONE
  interpreter round CLASS as a theorem quantified over the V1
  fragments (the `Seg.Pack` state components); the GROUND side
  condition — "the discovery at this control point offers this
  step" — discharges per instance through the `seg_discover`
  kernel-pin device (PERF-1: `Lean.Kernel.whnf`-computed, re-checked
  by the kernel at declaration add; no ofReduce*, no transparency
  steering). Nothing here is trusted: every lemma is an ordinary
  theorem ABOUT the fuel opsem, and instance uses land as ordinary
  kernel-certified obligations.

  THE PROGRAM-BLIND STATE FAMILY (`stateAt`): the per-program
  `t1fam`/`p01fam`/`p02fam` builders exist only to rebuild a full
  driver state from (control image, pack). `stateAt` is that rebuild
  at an ARBITRARY control image — one definition, one inversion
  theorem (`stateAt_inv`, registered `famInv` supply), replacing the
  per-fixture family + inversion pair for every walk the stepper
  mints. With it, the stepper's per-program content is the program's
  pinned Core term (inside the control image) and NOTHING else.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.SegRun
import RelSem.Kit.Round
import RelSem.Kit.Eval
import RelSem.Kit.EvalStep

set_option autoImplicit false

namespace RelSem.Seg

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit

/-! ## §1 The program-blind state family -/

/-- Rebuild a thread from its (env-erased) control-image thread and a
    pack frame: the single-frame discipline (every walk fixture). -/
@[reducible] def threadAt (th : thread_state) (f₁ : Fmap sym value) :
    thread_state :=
  { th with env := [f₁] }

/-- THE PROGRAM-BLIND STATE FAMILY: rebuild a full driver state from a
    control image `c` (arena/stack/labels/…, env spine-erased,
    supplies zeroed, layout pinned — `ctlOf`'s co-image) and a pack
    `p` (env frame, four supplies, layout). This is the per-fixture
    `p01fam`-class builder with the fixture data abstracted into `c`:
    `stateAt (ctlOf σ) (packProj σ) = σ` at the single-thread
    single-frame shape (the inversion below). -/
@[reducible] def stateAt (c : driver_state) (p : Pack) : driver_state :=
  { c with
    core_state0 := { c.core_state0 with
      thread_states := match c.core_state0.thread_states with
        | (tid, (pp, th)) :: rest => (tid, (pp, threadAt th p.f₁)) :: rest
        | [] => [] },
    core_run_state0 := { c.core_run_state0 with
      tid_supply := p.tS, aid_supply := p.aS,
      excluded_supply := p.eS, sym_supply := p.sS },
    layout_state := p.ls }

/-- THE GENERIC CONTROL INVERSION (registered `famInv` supply): at any
    control image whose thread table is a single thread with a
    single-frame (erased) env spine, `ctlOf σ = c` determines σ up to
    a pack — `σ = stateAt c (packProj σ)`. One theorem replacing the
    per-fixture `t1_inv`/`p01_inv`/… family; the shape premises are
    `rfl` at every concrete control image. -/
@[seg_inv]
theorem stateAt_inv {σ c : driver_state}
    {ctid : Nat} {cpp : Option Nat} {cth : thread_state}
    (hc : ctlOf σ = c)
    (hcths : c.core_state0.thread_states = [(ctid, (cpp, cth))])
    (hcenv : cth.env = [fmapEmpty]) :
    ∃ p : Pack, σ = stateAt c p := by
  subst hc
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  simp only [ctlOf, eraseEnvs] at hcths
  cases ths with
  | nil => simp at hcths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.cons.injEq, Prod.mk.injEq,
      List.map_eq_nil_iff] at hcths
    obtain ⟨⟨htid, hpp, hth⟩, hrest⟩ := hcths
    subst htid hpp hrest
    subst hth
    simp only [eraseThreadEnv] at hcenv
    cases env' with
    | nil => simp at hcenv
    | cons f₁ fr =>
      simp only [List.map_cons, List.cons.injEq,
        List.map_eq_nil_iff] at hcenv
      obtain ⟨-, hfr⟩ := hcenv
      subst hfr
      exact ⟨⟨f₁, tS, aS, eS, sS, ls⟩, rfl⟩

/-! ## §2 The round characterizations (one per advance class)

    Each lemma turns the interpreter's round FUNCTION into an
    introduction rule of its step RELATION: premises = the ground
    discovery equation (kernel-pinned per instance) + the class's
    semantic payload (the eval verdict, where the per-construct
    `se_*` laws of Kit/EvalStep and the env cell facts enter);
    conclusion = the round-atom app equation the segment links
    consume. Strictly MORE quantified than the per-program round
    facts they replace (∀ state, not ∀ pack-at-a-pinned-arena). -/

/-- TAU-round characterization (sequencing/binding control moves —
    `Esseq`/`Ewseq`/`Ebound` strips, annotation removal: every
    `Step_tau2 TSK_Misc` discovery). The successor is COMPUTED
    (`dnmsBump`): counter bump + thread replacement. -/
@[step_law (kind := construct) (variant := ctau) (side := fed)
  (frontier := "cstep/tau")
  (trace := "{law := cstep_tau, joint := cstep/tau, hyps := [hfind : ground(kernel-pinned discovery)]}")
  (lineage := "derived relational presentation of the clocked interpreter (functional big-step, Owens–Myreen–Kumar–Tan ESOP 2016); HeapLang PureExec-class precedent")]
theorem cstep_tau
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {σ : driver_state} {dbg : String} {th' : thread_state}
    (hfind : find_can_advance (dnmsDiscover tagDefs tid σ)
      = some (Step_tau2 dbg TSK_Misc th')) :
    app (dnmsRoundM tagDefs tid) σ
      = (NDactive (Sum.inl NOWAKEUP), dnmsBump tid th' σ) :=
  dnmsRoundM_adv hfind advance_tau_misc

/-- EVAL-round characterization (`RSK_eval` discoveries: pure
    expression evaluation — env reads, operator applications, ctor
    packs, label-jump argument evaluation). The `hm` premise is the
    construct's SEMANTIC payload: the monadic step's Defined verdict,
    discharged by the per-construct eval laws (`se_sym_hit`,
    `runEU_aux2_*`, the stub crossings) at the walk's cell facts —
    or by `rfl` where the eval is closed at the fragments. -/
@[step_law (kind := construct) (variant := ceval) (side := fed)
  (frontier := "cstep/eval")
  (trace := "{law := cstep_eval, joint := cstep/eval, hyps := [hfind : ground(kernel-pinned discovery), hm : fed(eval verdict)]}")
  (lineage := "derived relational presentation of the clocked interpreter (functional big-step, Owens–Myreen–Kumar–Tan ESOP 2016); HeapLang PureExec-class precedent")]
theorem cstep_eval
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {σ : driver_state} {dbg : String}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hfind : find_can_advance (dnmsDiscover tagDefs tid σ)
      = some (Step_with_runstate2 (RSK_eval dbg) step_m))
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    app (dnmsRoundM tagDefs tid) σ
      = (NDactive (Sum.inl NOWAKEUP),
         dnmsBump tid th' { σ with core_run_state0 := rs' }) :=
  dnmsRoundM_adv hfind (advance_runstate_eval hm)

/-- RUNSTATE-TAU characterization (the `RSK_tau TSK_Misc` flavor —
    negative-action rewrites and Erun/Esave taus that evaluate in the
    run-state monad). Same shape as `cstep_eval`. -/
@[step_law (kind := construct) (variant := crstau) (side := fed)
  (frontier := "cstep/rstau")
  (trace := "{law := cstep_rs_tau, joint := cstep/rstau, hyps := [hfind : ground(kernel-pinned discovery), hm : fed(eval verdict)]}")
  (lineage := "derived relational presentation of the clocked interpreter (functional big-step, Owens–Myreen–Kumar–Tan ESOP 2016)")]
theorem cstep_rs_tau
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {σ : driver_state} {dbg : String}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hfind : find_can_advance (dnmsDiscover tagDefs tid σ)
      = some (Step_with_runstate2 (RSK_tau dbg TSK_Misc) step_m))
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    app (dnmsRoundM tagDefs tid) σ
      = (NDactive (Sum.inl NOWAKEUP),
         dnmsBump tid th' { σ with core_run_state0 := rs' }) :=
  dnmsRoundM_adv hfind (advance_runstate_tau_misc hm)

/-! ## §3 The per-construct eval crossings (MOVED from SegRoundTac at
    V3a — construct-package citizens: the `hm` payload of an
    `cstep_eval` instance is discharged by these, per redex
    construct, at the walk's cell facts). -/

/-- The `runEU`-level face of the one-hit sym read (stated so a
    `refine` UNIFIES the annotations/env/state before the side
    premises elaborate). -/
theorem runEU_aux2_sym {A : Type}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {a a' : List annot} {z : sym} {v : value} {st : A}
    (hpull : pull_constrained 0 (Pexpr a () (PEsym z))
      = Pexpr a' () (PEsym z))
    (hext : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) z ext
      = none)
    (hlk : lookup_env z env = some v) :
    runEU (eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
        (Pexpr a () (PEsym z))) st
      = runEU (Result (Defined (Sum.inr v))) st := by
  rw [aux2_sym_hit hpull hext hlk]

/-- The `runEU` face of the two-cell Ctuple scrutinee eval (the
    Ecase-pack round class; P01's `p01ctor2_eval` promoted generic). -/
theorem runEU_aux2_ctor2 {A : Type}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {a a₁ a₂ : List annot} {x₁ x₂ : sym} {v₁ v₂ : value} {st : A}
    (hpull : pull_constrained 0 (Pexpr a () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
      = Pexpr [] () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
    (hext₁ : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) x₁ ext
      = none)
    (hext₂ : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) x₂ ext
      = none)
    (hlk₁ : lookup_env x₁ env = some v₁)
    (hlk₂ : lookup_env x₂ env = some v₂) :
    runEU (eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
        (Pexpr a () (PEctor Ctuple
          [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))) st
      = runEU (Result (Defined (Sum.inr (Vtuple [v₁, v₂])))) st := by
  have h : eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
      (Pexpr a () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
      = Result (Defined (Sum.inr (Vtuple [v₁, v₂]))) :=
    aux2_done 999999 _ _ _ _ _ _ _ hpull
      (by intro a' xs h; simp at h)
      (se_ctor_tuple
        (pes' := [Pexpr [] () (PEval v₁), Pexpr [] () (PEval v₂)])
        (cvals := [v₁, v₂])
        (eumapM_cons (se_sym_hit (fuel := 999998) hext₁ hlk₁)
          (eumapM_cons (se_sym_hit (fuel := 999998) hext₂ hlk₂)
            eumapM_nil)) rfl)
      (by rfl)
  rw [h]

/-- `hnc` from the spine verdict. -/
theorem hnc_of_notConstrained {peP : generic_pexpr Unit sym}
    (h : notConstrained peP = true) :
    ∀ (a : List annot)
      (xs : List (mem_iv_constraint × generic_pexpr Unit sym)),
      peP ≠ Pexpr a () (PEconstrained xs) := by
  intro a xs he
  subst he
  simp [notConstrained] at h

/-- THE ONE-STEP-THEN-REST SKELETON: one aux2 iteration (the pull by
    the computable SPINE — assigns the pulled redex REDUCED; the step
    by a per-shape `se_*` law, where the cell reads enter), then the
    REST of the loop — which is a CLOSED computation once the read
    values are plugged, so `rfl` at instances. This is what makes the
    two-cell verdict/conv rounds statements-only. -/
theorem runEU_aux2_step_then {A : Type}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {pe peP pe' : generic_pexpr Unit sym}
    {z : Sum (generic_pexpr Unit sym) value} {st : A}
    (hspine : pullSpine 1000000 pe = some peP)
    (hstep : step_eval_pexpr tagDefs 0 loc cloc ext env memo file1
        false peP = Result (Defined pe'))
    (hnv : valueFromPexpr pe' = none)
    (hrest : eval_pexpr_aux2_lemFuel 999999 tagDefs loc cloc ext env
        memo file1 pe' = Result (Defined z)) :
    runEU (eval_pexpr_aux2 tagDefs loc cloc ext env memo file1 pe) st
      = runEU (Result (Defined z)) st := by
  have hpull : pull_constrained 0 pe = peP := by
    show pull_constrained_lemFuel 1000000 0 pe = peP
    exact pull_constrained_spine 1000000 pe peP 0 hspine
  have h : eval_pexpr_aux2 tagDefs loc cloc ext env memo file1 pe
      = Result (Defined z) := by
    show eval_pexpr_aux2_lemFuel (999999 + 1) tagDefs loc cloc ext env
      memo file1 pe = _
    exact (aux2_step 999999 _ _ _ _ _ _ _ hpull
      (hnc_of_notConstrained (pullSpine_notConstrained hspine))
      hstep hnv).trans hrest
  rw [h]

end RelSem.Seg
