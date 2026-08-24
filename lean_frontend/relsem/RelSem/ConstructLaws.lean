/-
  RelSem.ConstructLaws — arc-17 S1 (2026-08-24): THE PER-CONSTRUCT LAW
  REGISTRY (charter S1 — the equation-supply frontier).

  ONE REGISTRATION POINT for fixture-independent construct laws: laws
  derived from the STEREOTYPED SHAPES Cerberus elaboration emits per C
  construct, proved once against the generated semantics, firing for
  every program that contains the shape. *Lineage (canon-first)*:
  decompilation-into-logic (Myreen) — the compiler's output shapes are
  finite and stereotyped, so one derived rule per shape replaces
  per-program equation chains; the dnms-round glue and advance-class
  laws this registry composes with live in Kit/Round.lean (arc-9 S2).

  REGISTRY DISCIPLINE (the arc-18 goal-directed search is the eventual
  consumer — Lithium-fragment shape: normal-form goals, ONE rule per
  goal form, no backtracking):
  * one law per construct shape, hypotheses in the order the engine
    will discharge them (structural side conditions first, semantic
    payload hypotheses last);
  * every law's docstring carries (a) the SHAPE it decompiles (which
    generated arm, cited file:line), (b) why the next program gets it
    free, (c) its TRACE-ATOM SCHEMA per the S0 automation-trace format
    spec (docs/2026-08-24_arc17-s0-discharge-substrate.md §3.6):
    `{lawName, joint, hypothesis slots}` — fed equations enter BY NAME,
    side conditions carry their disposition (`assumption|ground|rfl`);
  * NO fixture symbols in this file, ever (the mega-lemma counter of
    check_proof_size.sh scans this file exactly as it scans Kit/).

  House rules: no sorry, no axioms declared here; import discipline:
  no Iris, no fixtures. Cone pins in RelSem/Audit.lean.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Kit.Eval

set_option autoImplicit false

namespace RelSem.Laws

open RelSem RelSem.Cerb RelSem.Kit

/-! ## The state-read crossing -/

/-- CONSTRUCT LAW `seu_read_bind` — the run-state READ at the head of a
    with-runstate step.

    SHAPE: `stExceptUndef_bind (runSE (state_except_read f)) k` — the
    compiled form of every "consult the run state, then continue" step
    (generated/Core_reduction.lean:484, the Erun arm's label read is
    the canonical instance). The read is DEFINITIONALLY a Defined
    result at the unchanged state, so the bind crosses generically —
    at ANY run state, concrete or open. WHY THE NEXT PROGRAM GETS IT
    FREE: the law never mentions what is read or from which state; the
    read's VALUE is handled downstream (`erun_jump_m`'s `hres`).

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := seu_read_bind,
    joint := runstate-read, hyps := []}` — no hypothesis slots; the
    consumer recomputes `f st` (S0 §3.1 item 2). -/
theorem seu_read_bind {A B S E : Type}
    (f : S → A) (k : A → S → exceptM (t0 B × S) E) (st : S) :
    stExceptUndef_bind (runSE (state_except_read f)) k st = k (f st) st :=
  stub_defined rfl

/-! ## The Erun/Esave label jump -/

/-- CONSTRUCT LAW `erun_jump_m` — the label-jump M-computation
    (Erun/Esave: C `goto`, loop back-edges, and the save/run return
    encoding all elaborate to `Erun`).

    SHAPE: the `Erun` arm of `step_ctx`
    (generated/Core_reduction.lean:484): resolve the label in the
    run state's `labeled` map (`runSE (state_except_read …)`), match
    on the result (a missing label is a loud failure), then run the
    jump continuation (argument evaluation + env update + arena
    replacement). The law splits exactly there: `hres` carries the
    RESOLUTION (kernel-computable from a `labeled`-projection
    hypothesis — `simp only [mkDr-style projections, hlab]; rfl` at
    every fixture), `hk` carries the JUMP BODY (the args foldM, whose
    element evaluations are the fixture's ∀-run-state eval lemmas).

    WHY THE NEXT PROGRAM GETS IT FREE: this was THE round class that
    pinned fixtures to a concrete run state (the arc-16 S3/S4
    `round6_thr`/`round13_thr`/`round21_thr` twins existed only for
    it). With resolution as a hypothesis the round lemma is ∀-run-
    state: every state ladder — ambient, threaded ∀-seed, future cmm —
    instantiates the SAME lemma and discharges `hlab` by `rfl`.

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := erun_jump_m,
    joint := rsk-eval/label-jump, hyps := [hres : ground (labeled-map
    lookup; consumer recomputes), hk : fed-equation BY NAME (the
    fixture's eval-chain lemma)]}`. -/
theorem erun_jump_m {B : Type}
    {resolve : core_run_state →
      Option (List (sym × core_base_type) ×
        generic_expr core_run_annotation Unit sym)}
    {onFail : core_run_state →
      exceptM (t0 B × core_run_state) core_run_cause}
    {kJump : List (sym × core_base_type) →
      generic_expr core_run_annotation Unit sym →
      core_run_state → exceptM (t0 B × core_run_state) core_run_cause}
    {rs : core_run_state}
    {sbs : List (sym × core_base_type)}
    {ce : generic_expr core_run_annotation Unit sym}
    {r : exceptM (t0 B × core_run_state) core_run_cause}
    (hres : resolve rs = some (sbs, ce))
    (hk : kJump sbs ce rs = r) :
    stExceptUndef_bind (runSE (state_except_read resolve))
      (fun x => match x with
        | none => onFail
        | some (sbs', ce') => kJump sbs' ce') rs = r := by
  rw [seu_read_bind, hres]
  exact hk

end RelSem.Laws
