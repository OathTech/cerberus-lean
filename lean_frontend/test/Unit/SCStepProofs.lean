/-
  SCStepProofs — the kernel laws L1–L6 of the SC S1a bounded step API
  (lean_frontend/docs/2026-09-29_sc-s1-charter.md §3.9), stated over the GENERATED
  definitions of frontend/model/driver.lem's "SC concurrency S1a" section (Driver.lean:
  sc_start / sc_step / sc_run / sc_explore / sc_perform / sc_events), for every fuel
  instance, every reader parameter and every configuration.

  Kernel-only tactics (none of the D14-banned non-kernel proof methods, no option bumps);
  the axiom cones are pinned by scripts/check_theorem_axioms.sh's entry set.

  What is proved here (each law names its theorem(s)):
    L1 budget accounting   sc_run_zero, sc_run_exhausted_transitions,
                           sc_run_reductions_le_transitions (relative form),
                           sc_run_reductions_le_transitions_from_start (the absolute corollary)
    L2 step/run            sc_run_succ (definitional), sc_step_transitions
    L3 terminal absorption sc_step_final, sc_run_stable
    L4 chosen alternative  sc_step_bad_choice_core / _lifecycle, sc_step_choice_required_*,
                           sc_step_no_alternatives_*, sc_step_chosen_core / _lifecycle (the
                           result is built from ONE application of the chosen branch to the
                           stored state: sc_step_chosen_core_state)
    L5 same handlers       sc_perform_advance, sc_perform_pick
    L6 events              TraceGrows, sc_events_append (concatenation along a run),
                           sc_step_trace_grows (a transition grows the trace iff the action
                           it ran did: the machine adds nothing), and the hereditary
                           trace-monotonicity toolbox + its instances for the S1a closures
                           (section L6Handlers; the residual, if any, is named there).

  Not proved (charter §3.9): runND (drive …) = sc_explore — differential evidence
  (scripts/test_sc_step.py) and a WP-C obligation.
-/
import Driver

set_option autoImplicit false

namespace SCStepProofs

/-! ## Notation -/

abbrev Enums := Fmap sym integerType
abbrev Tags := Fmap sym (CerbLocation.Loc × tag_definition)
abbrev DriverAction (a : Type) := ndM a step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state
abbrev ActionResult (a : Type) :=
  nd_action a step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state × driver_state

/-! ## The interpreters' bookkeeping (used by L1, L2, L4, L6) -/

theorem sc_advance_transitions (cfg : sc_config) (st : driver_state) :
    (sc_advance cfg st).sc_transitions = cfg.sc_transitions + 1 := rfl

theorem sc_advance_state (cfg : sc_config) (st : driver_state) :
    (sc_advance cfg st).sc_state = st := rfl

theorem sc_interpret_lifecycle_transitions (cfg : sc_config) (p : ActionResult driver_result) :
    (sc_interpret_lifecycle cfg p).sc_transitions = cfg.sc_transitions + 1 := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_lifecycle, sc_advance] <;> (try split) <;> rfl

theorem sc_interpret_lifecycle_state (cfg : sc_config) (p : ActionResult driver_result) :
    (sc_interpret_lifecycle cfg p).sc_state = p.2 := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_lifecycle, sc_advance] <;> (try split) <;> rfl

theorem sc_interpret_lifecycle_reductions (cfg : sc_config) (p : ActionResult driver_result) :
    (sc_interpret_lifecycle cfg p).sc_core_reductions = cfg.sc_core_reductions := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_lifecycle, sc_advance] <;> (try split) <;> rfl

theorem sc_interpret_core_transitions (cfg : sc_config) (k : DriverAction driver_result)
    (counts is_exit : Bool) (p : ActionResult Unit) :
    (sc_interpret_core cfg k counts is_exit p).sc_transitions = cfg.sc_transitions + 1 := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_core, sc_advance] <;> (try split) <;> rfl

theorem sc_interpret_core_state (cfg : sc_config) (k : DriverAction driver_result)
    (counts is_exit : Bool) (p : ActionResult Unit) :
    (sc_interpret_core cfg k counts is_exit p).sc_state = p.2 := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_core, sc_advance] <;> (try split) <;> rfl

theorem sc_interpret_core_reductions (cfg : sc_config) (k : DriverAction driver_result)
    (counts is_exit : Bool) (p : ActionResult Unit) :
    (sc_interpret_core cfg k counts is_exit p).sc_core_reductions
      = cfg.sc_core_reductions + (if counts then 1 else 0) := by
  obtain ⟨act, st'⟩ := p
  cases act <;> simp only [sc_interpret_core, sc_advance] <;> (repeat' split) <;> rfl

theorem sc_refuse_transitions (cfg : sc_config) (msg : String) :
    (sc_refuse cfg msg).sc_transitions = cfg.sc_transitions + 1 := rfl
theorem sc_refuse_state (cfg : sc_config) (msg : String) : (sc_refuse cfg msg).sc_state = cfg.sc_state := rfl
theorem sc_refuse_reductions (cfg : sc_config) (msg : String) :
    (sc_refuse cfg msg).sc_core_reductions = cfg.sc_core_reductions := rfl
theorem sc_chose_transitions (cfg : sc_config) : (sc_chose cfg).sc_transitions = cfg.sc_transitions := rfl
theorem sc_chose_state (cfg : sc_config) : (sc_chose cfg).sc_state = cfg.sc_state := rfl
theorem sc_chose_reductions (cfg : sc_config) : (sc_chose cfg).sc_core_reductions = cfg.sc_core_reductions := rfl

section Readers
variable [LemFuel] (e : Enums) (t : Tags)

theorem sc_core_transition_transitions (cfg : sc_config) (k : DriverAction driver_result) :
    (sc_core_transition e t cfg k).sc_transitions = cfg.sc_transitions + 1 := by
  unfold sc_core_transition
  split
  · dsimp only
    split
    · exact sc_refuse_transitions _ _
    · exact sc_interpret_core_transitions _ _ _ _ _
  · exact sc_refuse_transitions _ _

theorem sc_core_transition_reductions (cfg : sc_config) (k : DriverAction driver_result) :
    (sc_core_transition e t cfg k).sc_core_reductions ≤ cfg.sc_core_reductions + 1 ∧
    cfg.sc_core_reductions ≤ (sc_core_transition e t cfg k).sc_core_reductions := by
  unfold sc_core_transition
  split
  · dsimp only
    split
    · rw [sc_refuse_reductions]; omega
    · rw [sc_interpret_core_reductions]; split <;> omega
  · rw [sc_refuse_reductions]; omega

/-! ## L2 — one step adds exactly one transition -/

/-- The shape of every successful step: which interpreter built the result. -/
theorem sc_step_inr_shape (cfg cfg' : sc_config) (c : Option sc_choice)
    (h : sc_step e t cfg c = .inr cfg') :
    (∃ p, cfg' = sc_interpret_lifecycle cfg p) ∨
    (∃ p, cfg' = sc_interpret_lifecycle (sc_chose cfg) p) ∨
    (∃ k, cfg' = sc_core_transition e t cfg k) ∨
    (∃ k b p, cfg' = sc_interpret_core (sc_chose cfg) k b false p) := by
  unfold sc_step at h
  split at h
  · cases h
  · split at h
    · cases h
    · exact Or.inl ⟨_, (Sum.inr.inj h).symm⟩
  · split at h
    · cases h
    · exact Or.inr (Or.inr (Or.inl ⟨_, (Sum.inr.inj h).symm⟩))
  · split at h
    · cases h
    · split at h
      · cases h
      · exact Or.inr (Or.inl ⟨_, (Sum.inr.inj h).symm⟩)
  · split at h
    · cases h
    · split at h
      · cases h
      · exact Or.inr (Or.inr (Or.inr ⟨_, _, _, (Sum.inr.inj h).symm⟩))

theorem sc_step_transitions (cfg cfg' : sc_config) (c : Option sc_choice)
    (h : sc_step e t cfg c = .inr cfg') :
    cfg'.sc_transitions = cfg.sc_transitions + 1 := by
  rcases sc_step_inr_shape e t cfg cfg' c h with ⟨p, rfl⟩ | ⟨p, rfl⟩ | ⟨k, rfl⟩ | ⟨k, b, p, rfl⟩
  · exact sc_interpret_lifecycle_transitions _ _
  · rw [sc_interpret_lifecycle_transitions, sc_chose_transitions]
  · exact sc_core_transition_transitions _ _ _ _
  · rw [sc_interpret_core_transitions, sc_chose_transitions]

/-- One step adds at most one reduction and never removes one. -/
theorem sc_step_reductions (cfg cfg' : sc_config) (c : Option sc_choice)
    (h : sc_step e t cfg c = .inr cfg') :
    cfg'.sc_core_reductions ≤ cfg.sc_core_reductions + 1 ∧
    cfg.sc_core_reductions ≤ cfg'.sc_core_reductions := by
  rcases sc_step_inr_shape e t cfg cfg' c h with ⟨p, rfl⟩ | ⟨p, rfl⟩ | ⟨k, rfl⟩ | ⟨k, b, p, rfl⟩
  · rw [sc_interpret_lifecycle_reductions]; omega
  · rw [sc_interpret_lifecycle_reductions, sc_chose_reductions]; omega
  · exact sc_core_transition_reductions _ _ _ _
  · rw [sc_interpret_core_reductions, sc_chose_reductions]; split <;> omega

/-! ## L1/L2 — the runner over the budget -/

theorem sc_run_zero (pol : sc_policy) (cfg : sc_config) :
    sc_run e t 0 pol cfg = (if sc_final cfg then SC_stopped cfg else SC_exhausted cfg) := rfl

/-- L2 (definitional): `sc_run (n+1)` is one `sc_step` followed by `sc_run n` on its
    result (the budget list `List.replicate (n+1) ()` is `() :: List.replicate n ()`). -/
theorem sc_run_succ (n : Nat) (pol : sc_policy) (cfg : sc_config) :
    sc_run e t (n + 1) pol cfg =
      (if sc_final cfg then SC_stopped cfg
       else match sc_step e t cfg (pol cfg (sc_alternatives cfg)) with
         | .inl SC_choice_required => SC_needs_choice cfg
         | .inl err => SC_run_error err cfg
         | .inr cfg' => sc_run e t n pol cfg') := rfl

/-- L1: an exhausted run spent exactly its budget. -/
theorem sc_run_exhausted_transitions (n : Nat) (pol : sc_policy) (cfg cfg' : sc_config)
    (h : sc_run e t n pol cfg = SC_exhausted cfg') :
    cfg'.sc_transitions = cfg.sc_transitions + n := by
  induction n generalizing cfg with
  | zero =>
    rw [sc_run_zero] at h
    split at h
    · cases h
    · cases h; rfl
  | succ n ih =>
    rw [sc_run_succ] at h
    split at h
    · cases h
    · split at h
      · cases h
      · cases h
      · rename_i cfg₁ hstep
        have := ih cfg₁ h
        rw [this, sc_step_transitions e t cfg cfg₁ _ hstep]; omega

/-- L1 (relative form): along any run both counters are monotone and the reductions grow
    by at most the transitions. -/
theorem sc_run_reductions_le_transitions (n : Nat) (pol : sc_policy) (cfg cfg' : sc_config)
    (h : sc_run e t n pol cfg = SC_exhausted cfg' ∨ sc_run e t n pol cfg = SC_stopped cfg') :
    cfg.sc_core_reductions ≤ cfg'.sc_core_reductions ∧ cfg.sc_transitions ≤ cfg'.sc_transitions ∧
    cfg'.sc_core_reductions - cfg.sc_core_reductions ≤ cfg'.sc_transitions - cfg.sc_transitions := by
  induction n generalizing cfg with
  | zero =>
    rw [sc_run_zero] at h
    rcases h with h | h <;> split at h <;> cases h <;> omega
  | succ n ih =>
    rw [sc_run_succ] at h
    rcases h with h | h <;> split at h
    · cases h
    · split at h
      · cases h
      · cases h
      · rename_i cfg₁ hstep
        have h1 := ih cfg₁ (Or.inl h)
        have h2 := sc_step_transitions e t cfg cfg₁ _ hstep
        have h3 := sc_step_reductions e t cfg cfg₁ _ hstep
        omega
    · cases h; omega
    · split at h
      · cases h
      · cases h
      · rename_i cfg₁ hstep
        have h1 := ih cfg₁ (Or.inr h)
        have h2 := sc_step_transitions e t cfg cfg₁ _ hstep
        have h3 := sc_step_reductions e t cfg cfg₁ _ hstep
        omega

theorem sc_start_counters (file : generic_file Unit core_run_annotation) (args : List String)
    (st : driver_state) :
    (sc_start e t file args st).sc_transitions = 0 ∧ (sc_start e t file args st).sc_core_reductions = 0 :=
  ⟨rfl, rfl⟩

/-- L1 (absolute corollary): from `sc_start`, reductions never exceed transitions. -/
theorem sc_run_reductions_le_transitions_from_start (n : Nat) (pol : sc_policy)
    (file : generic_file Unit core_run_annotation) (args : List String) (st : driver_state) (cfg' : sc_config)
    (h : sc_run e t n pol (sc_start e t file args st) = SC_exhausted cfg' ∨
         sc_run e t n pol (sc_start e t file args st) = SC_stopped cfg') :
    cfg'.sc_core_reductions ≤ cfg'.sc_transitions := by
  have := sc_run_reductions_le_transitions e t n pol _ cfg' h
  have hc := sc_start_counters e t file args st
  omega

/-! ## L3 — terminal configurations are absorbing; stopped runs are stable -/

theorem sc_step_final (cfg : sc_config) (c : Option sc_choice) (h : sc_final cfg = true) :
    sc_step e t cfg c = .inl SC_terminal := by
  unfold sc_final at h
  unfold sc_step
  split <;> simp_all

theorem sc_run_stable (n : Nat) (pol : sc_policy) (cfg fin : sc_config)
    (h : sc_run e t n pol cfg = SC_stopped fin) :
    ∀ m, n ≤ m → sc_run e t m pol cfg = SC_stopped fin := by
  induction n generalizing cfg with
  | zero =>
    intro m _
    rw [sc_run_zero] at h
    split at h
    · cases h
      cases m with
      | zero => rw [sc_run_zero]; simp_all
      | succ m => rw [sc_run_succ]; simp_all
    · cases h
  | succ n ih =>
    intro m hm
    obtain ⟨m, rfl⟩ : ∃ m', m = m' + 1 := ⟨m - 1, by omega⟩
    rw [sc_run_succ] at h ⊢
    split at h
    · cases h; simp_all
    · rename_i hfin
      simp only [hfin, Bool.false_eq_true, ↓reduceIte]
      split at h
      · cases h
      · cases h
      · rename_i cfg₁ hstep
        exact ih cfg₁ h m (by omega)

/-! ## L4 — exactly the chosen alternative -/

theorem sc_step_bad_choice_core (cfg : sc_config) (b : Bool) (alts : List (step_kind × DriverAction Unit))
    (k : DriverAction driver_result) (i : Nat)
    (hph : cfg.sc_phase0 = SC_core_choosing b alts k) (hi : alts.length ≤ i) :
    sc_step e t cfg (some (SC_alt i)) = .inl (SC_bad_choice i alts.length) := by
  unfold sc_step
  rw [hph]
  have : listGetOpt alts i = none := by
    simp only [listGetOpt]; exact List.getElem?_eq_none hi
  simp [this]

theorem sc_step_bad_choice_lifecycle (cfg : sc_config) (alts : List (step_kind × DriverAction driver_result))
    (i : Nat) (hph : cfg.sc_phase0 = SC_lifecycle_choosing alts) (hi : alts.length ≤ i) :
    sc_step e t cfg (some (SC_alt i)) = .inl (SC_bad_choice i alts.length) := by
  unfold sc_step
  rw [hph]
  have : listGetOpt alts i = none := by
    simp only [listGetOpt]; exact List.getElem?_eq_none hi
  simp [this]

theorem sc_step_choice_required_core (cfg : sc_config) (b : Bool) (alts : List (step_kind × DriverAction Unit))
    (k : DriverAction driver_result) (hph : cfg.sc_phase0 = SC_core_choosing b alts k) :
    sc_step e t cfg none = .inl SC_choice_required := by
  unfold sc_step; rw [hph]

theorem sc_step_choice_required_lifecycle (cfg : sc_config) (alts : List (step_kind × DriverAction driver_result))
    (hph : cfg.sc_phase0 = SC_lifecycle_choosing alts) :
    sc_step e t cfg none = .inl SC_choice_required := by
  unfold sc_step; rw [hph]

/-- A choice where no alternative is offered is refused against 0 alternatives. -/
theorem sc_step_no_alternatives_lifecycle (cfg : sc_config) (k : DriverAction driver_result) (i : Nat)
    (hph : cfg.sc_phase0 = SC_lifecycle k) :
    sc_step e t cfg (some (SC_alt i)) = .inl (SC_bad_choice i 0) := by
  unfold sc_step; rw [hph]

theorem sc_step_no_alternatives_core (cfg : sc_config) (k : DriverAction driver_result) (i : Nat)
    (hph : cfg.sc_phase0 = SC_core k) :
    sc_step e t cfg (some (SC_alt i)) = .inl (SC_bad_choice i 0) := by
  unfold sc_step; rw [hph]

/-- L4: at a Core choosing phase the chosen branch, and only it, is applied to the
    stored state — the result is `sc_interpret_core` of that ONE application (the other
    elements of `alts` do not occur in the right-hand side). -/
theorem sc_step_chosen_core (cfg : sc_config) (b : Bool) (alts : List (step_kind × DriverAction Unit))
    (k : DriverAction driver_result) (i : Nat) (info : step_kind) (m : DriverAction Unit)
    (hph : cfg.sc_phase0 = SC_core_choosing b alts k) (hi : listGetOpt alts i = some (info, m)) :
    sc_step e t cfg (some (SC_alt i))
      = .inr (sc_interpret_core (sc_chose cfg) k b false (sc_run_action m cfg.sc_state)) := by
  unfold sc_step; rw [hph]; simp [hi]

theorem sc_step_chosen_lifecycle (cfg : sc_config) (alts : List (step_kind × DriverAction driver_result))
    (i : Nat) (info : step_kind) (k : DriverAction driver_result)
    (hph : cfg.sc_phase0 = SC_lifecycle_choosing alts) (hi : listGetOpt alts i = some (info, k)) :
    sc_step e t cfg (some (SC_alt i))
      = .inr (sc_interpret_lifecycle (sc_chose cfg) (sc_run_action k cfg.sc_state)) := by
  unfold sc_step; rw [hph]; simp [hi]

/-- The state of the result is the state that one application returned. -/
theorem sc_step_chosen_core_state (cfg cfg' : sc_config) (b : Bool) (alts : List (step_kind × DriverAction Unit))
    (k : DriverAction driver_result) (i : Nat) (info : step_kind) (m : DriverAction Unit)
    (hph : cfg.sc_phase0 = SC_core_choosing b alts k) (hi : listGetOpt alts i = some (info, m))
    (h : sc_step e t cfg (some (SC_alt i)) = .inr cfg') :
    cfg'.sc_state = (sc_run_action m cfg.sc_state).2 := by
  rw [sc_step_chosen_core e t cfg b alts k i info m hph hi] at h
  cases h
  exact sc_interpret_core_state _ _ _ _ _

/-! ## L5 — the same handlers as `drive` -/

theorem sc_perform_advance (tid : Nat) (steps : List core_step2) (s : core_step2)
    (h : find_can_advance steps = some s) :
    sc_perform e t tid steps = nd_bind (advance_step e t tid s) (fun (_ : advance_info) => nd_return ()) := by
  unfold sc_perform; rw [h]

theorem sc_perform_pick (tid : Nat) (steps : List core_step2)
    (h : find_can_advance steps = none) :
    sc_perform e t tid steps
      = nd_bind (pick (SK_misc ["new_drive_core_threads"]) steps)
          (process_core_step2 e t false (fun (_ : Bool) => nd_return ())) := by
  unfold sc_perform; rw [h]

end Readers

/-- `sc_run_action` is application of the stored closure to the given state, nothing else. -/
theorem sc_run_action_eq {a : Type} (f : driver_state → ActionResult a) (st : driver_state) :
    sc_run_action (ND f) st = f st := rfl

/-! ## L6 — events -/

/-- The earlier trace is a suffix of the later one (the trace is consed at the front). -/
def TraceGrows (cfg cfg' : sc_config) : Prop :=
  cfg.sc_state.trace <:+ cfg'.sc_state.trace

theorem TraceGrows.refl (cfg : sc_config) : TraceGrows cfg cfg := List.suffix_refl _

theorem TraceGrows.trans {c₀ c₁ c₂ : sc_config} (h₁ : TraceGrows c₀ c₁) (h₂ : TraceGrows c₁ c₂) :
    TraceGrows c₀ c₂ := List.IsSuffix.trans h₁ h₂

theorem sc_events_of_suffix (cfg cfg' : sc_config) (xs : List trace_event)
    (h : cfg'.sc_state.trace = xs ++ cfg.sc_state.trace) : sc_events cfg cfg' = xs := by
  unfold sc_events
  rw [h, List.length_append]
  dsimp only
  have hle : natLteb cfg.sc_state.trace.length (xs.length + cfg.sc_state.trace.length) = true := by
    simp [natLteb]
  rw [hle]
  simp

/-- L6: along a run, the events concatenate (newest first). -/
theorem sc_events_append (c₀ c₁ c₂ : sc_config) (h₁ : TraceGrows c₀ c₁) (h₂ : TraceGrows c₁ c₂) :
    sc_events c₀ c₂ = sc_events c₁ c₂ ++ sc_events c₀ c₁ := by
  obtain ⟨xs, hxs⟩ := h₁
  obtain ⟨ys, hys⟩ := h₂
  rw [sc_events_of_suffix c₀ c₁ xs hxs.symm, sc_events_of_suffix c₁ c₂ ys hys.symm,
      sc_events_of_suffix c₀ c₂ (ys ++ xs) (by rw [← hys, ← hxs, List.append_assoc])]

/-! A transition's state is exactly what the action it ran returned (the machine adds
    nothing to the trace), so TraceGrows holds for the transition iff the action grew the
    trace at the stored state. -/
section MachineTrace
variable [LemFuel] (e : Enums) (t : Tags)

theorem sc_step_state_from_action (cfg cfg' : sc_config) (c : Option sc_choice)
    (h : sc_step e t cfg c = .inr cfg') :
    (∃ p : ActionResult driver_result, cfg'.sc_state = p.2 ∧
        (cfg' = sc_interpret_lifecycle cfg p ∨ cfg' = sc_interpret_lifecycle (sc_chose cfg) p)) ∨
    (∃ k, cfg' = sc_core_transition e t cfg k) ∨
    (∃ p : ActionResult Unit, cfg'.sc_state = p.2 ∧ ∃ k b, cfg' = sc_interpret_core (sc_chose cfg) k b false p) := by
  rcases sc_step_inr_shape e t cfg cfg' c h with ⟨p, rfl⟩ | ⟨p, rfl⟩ | ⟨k, rfl⟩ | ⟨k, b, p, rfl⟩
  · exact Or.inl ⟨p, sc_interpret_lifecycle_state _ _, Or.inl rfl⟩
  · exact Or.inl ⟨p, sc_interpret_lifecycle_state _ _, Or.inr rfl⟩
  · exact Or.inr (Or.inl ⟨k, rfl⟩)
  · exact Or.inr (Or.inr ⟨p, sc_interpret_core_state _ _ _ _ _, k, b, rfl⟩)

theorem sc_core_transition_state (cfg : sc_config) (k : DriverAction driver_result) :
    (sc_core_transition e t cfg k).sc_state = cfg.sc_state ∨
    ∃ tid th_info,
      cfg.sc_state.core_state0.thread_states = [(tid, th_info)] ∧
      (sc_core_transition e t cfg k).sc_state
        = (sc_run_action (sc_perform e t tid
            (step_ctx e t cfg.sc_state.layout_state cfg.sc_state.core_file cfg.sc_state.core_extern tid th_info))
            cfg.sc_state).2 := by
  unfold sc_core_transition
  split
  · rename_i tid th_info hts
    dsimp only
    split
    · exact Or.inl (sc_refuse_state _ _)
    · exact Or.inr ⟨tid, th_info, hts, sc_interpret_core_state _ _ _ _ _⟩
  · exact Or.inl (sc_refuse_state _ _)

end MachineTrace

/-! ## L6 handlers — hereditary trace monotonicity of the S1a closures

`HMono m`: running `m` from any state returns a state whose trace extends the input's,
and every branch of a node it returns is again `HMono`. Closed under the ND combinators
the driver is written with; the S1a closures are instances. Stated for the concrete
`driverM`; `LemFuel` is quantified through the fuel'd `nd_bind`/`liftND` workers. -/
section L6Handlers

def Grows (st st' : driver_state) : Prop := st.trace <:+ st'.trace

/-- Hereditary trace monotonicity, by recursion on the ND-tree depth `d` (a node's
    branches are closures, so the property is stated depth-indexed and `HMono` is its
    intersection over all depths). -/
def HMonoD {a : Type} : Nat → DriverAction a → Prop
  | 0, _ => True
  | d + 1, m => ∀ st, Grows st (sc_run_action m st).2 ∧
      (match (sc_run_action m st).1 with
       | NDnd _ bs => ∀ b ∈ bs, HMonoD d b.2
       | NDstep _ bs => ∀ b ∈ bs, HMonoD d b.2
       | NDguard _ _ m' => HMonoD d m'
       | NDbranch _ _ m₁ m₂ => HMonoD d m₁ ∧ HMonoD d m₂
       | _ => True)

def HMono {a : Type} (m : DriverAction a) : Prop := ∀ d, HMonoD d m

theorem Grows.refl (st : driver_state) : Grows st st := List.suffix_refl _
theorem Grows.trans {s₀ s₁ s₂ : driver_state} (h₁ : Grows s₀ s₁) (h₂ : Grows s₁ s₂) : Grows s₀ s₂ :=
  List.IsSuffix.trans h₁ h₂

theorem HMonoD_grows {a : Type} {m : DriverAction a} {d : Nat} (h : HMonoD (d + 1) m) (st : driver_state) :
    Grows st (sc_run_action m st).2 := (h st).1

theorem HMono_grows {a : Type} {m : DriverAction a} (h : HMono m) (st : driver_state) :
    Grows st (sc_run_action m st).2 := (h 1 st).1

/-- `nd_return` -/
theorem HMono_return {a : Type} (x : a) : HMono (nd_return x : DriverAction a) := by
  intro d; cases d with
  | zero => trivial
  | succ d => intro st; exact ⟨Grows.refl _, trivial⟩

theorem HMono_get : HMono (nd_get : DriverAction driver_state) := by
  intro d; cases d with
  | zero => trivial
  | succ d => intro st; exact ⟨Grows.refl _, trivial⟩

theorem HMono_read {a : Type} (f : driver_state → a) : HMono (nd_read f : DriverAction a) := by
  intro d; cases d with
  | zero => trivial
  | succ d => intro st; exact ⟨Grows.refl _, trivial⟩

theorem HMono_kill {a : Type} (r : kill_reason driver_error) : HMono (kill r : DriverAction a) := by
  intro d; cases d with
  | zero => trivial
  | succ d => intro st; exact ⟨Grows.refl _, trivial⟩

/-- `nd_update f` when `f` only grows the trace. -/
theorem HMono_update (f : driver_state → driver_state) (hf : ∀ st, Grows st (f st)) :
    HMono (nd_update f : DriverAction Unit) := by
  intro d; cases d with
  | zero => trivial
  | succ d => intro st; exact ⟨hf st, trivial⟩

theorem Grows_cons (st : driver_state) (ev : trace_event) :
    Grows st { st with trace := ev :: st.trace } := ⟨[ev], rfl⟩

/-- A record update that leaves `trace` alone grows it (reflexively): the caller states the
    unchanged trace as the hypothesis. -/
theorem Grows_of_trace_eq {st st' : driver_state} (h : st'.trace = st.trace) : Grows st st' := by
  unfold Grows; rw [h]; exact List.suffix_refl _

theorem HMonoD_succ {a : Type} (d : Nat) (m : DriverAction a) :
    HMonoD (d + 1) m = ∀ st, Grows st (sc_run_action m st).2 ∧
      (match (sc_run_action m st).1 with
       | NDnd _ bs => ∀ b ∈ bs, HMonoD d b.2
       | NDstep _ bs => ∀ b ∈ bs, HMonoD d b.2
       | NDguard _ _ m' => HMonoD d m'
       | NDbranch _ _ m₁ m₂ => HMonoD d m₁ ∧ HMonoD d m₂
       | _ => True) := rfl

/-! ### The monad's combinators are hereditarily trace-monotone -/

/-- `nd_bind` (every fuel): the state grows through both halves; a node's branches are
    the bound branches, monotone by induction on the depth. -/
theorem HMonoD_bind {a b : Type} (d : Nat) :
    ∀ (fuel : Nat) (m : DriverAction a) (f : a → DriverAction b),
      HMonoD d m → (∀ x, HMono (f x)) → HMonoD d (nd_bind_lemFuel fuel m f) := by
  induction d with
  | zero => intros; trivial
  | succ d ih =>
    intro fuel m f hm hf
    cases fuel with
    | zero => intro st; exact ⟨Grows.refl _, trivial⟩
    | succ fuel =>
      obtain ⟨g⟩ := m
      intro st
      have hm1 := hm st
      simp only [sc_run_action] at hm1 ⊢
      simp only [nd_bind_lemFuel]
      revert hm1
      generalize g st = r
      rcases r with ⟨act, st'⟩
      intro hm1
      cases act with
      | NDactive z =>
        have hz := hf z (d + 1) st'
        simp only [sc_run_action] at hm1 hz ⊢
        generalize f z = fz at hz ⊢
        rcases fz with ⟨h⟩
        simp only at hz ⊢
        exact ⟨hm1.1.trans hz.1, hz.2⟩
      | NDkilled r => exact ⟨hm1.1, trivial⟩
      | NDnd i bs =>
        refine ⟨hm1.1, ?_⟩
        intro b hb
        simp only [List.mem_map] at hb
        obtain ⟨⟨s, m'⟩, hm', rfl⟩ := hb
        exact ih fuel m' f (hm1.2 _ hm') hf
      | NDguard i c m' => exact ⟨hm1.1, ih fuel m' f hm1.2 hf⟩
      | NDbranch i c m₁ m₂ => exact ⟨hm1.1, ih fuel m₁ f hm1.2.1 hf, ih fuel m₂ f hm1.2.2 hf⟩
      | NDstep i bs =>
        refine ⟨hm1.1, ?_⟩
        intro b hb
        simp only [List.mem_map] at hb
        obtain ⟨⟨s, m'⟩, hm', rfl⟩ := hb
        exact ih fuel m' f (hm1.2 _ hm') hf

theorem HMono_bind [LemFuel] {a b : Type} (m : DriverAction a) (f : a → DriverAction b)
    (hm : HMono m) (hf : ∀ x, HMono (f x)) : HMono (nd_bind m f) :=
  fun d => HMonoD_bind d LemFuel.fuel m f (hm d) hf

/-- `liftND` (every fuel) of ANY inner action whose `put` keeps the trace: the returned
    state is `put st …`, and the lifted node's branches are lifted actions again. The
    inner action may be opaque — the trace lives outside the lifted state. -/
theorem HMonoD_liftND {a st1 info1 err1 : Type} (d : Nat)
    (get : driver_state → st1) (put : driver_state → st1 → driver_state)
    (li : info1 → step_kind) (le : err1 → driver_error)
    (hput : ∀ dr x, (put dr x).trace = dr.trace) :
    ∀ (fuel : Nat) (m : ndM a info1 err1 (mem_constraint CerbMem.IntegerValue) st1),
      HMonoD d (liftND_lemFuel fuel get put li le m) := by
  induction d with
  | zero => intros; trivial
  | succ d ih =>
    intro fuel m
    cases fuel with
    | zero => intro st; exact ⟨Grows.refl _, trivial⟩
    | succ fuel =>
      obtain ⟨g⟩ := m
      intro st
      simp only [sc_run_action, liftND_lemFuel]
      generalize g (get st) = r
      rcases r with ⟨act, st1'⟩
      refine ⟨Grows_of_trace_eq (hput _ _), ?_⟩
      cases fuel with
      | zero => trivial
      | succ fuel =>
        cases act with
        | NDactive z => trivial
        | NDkilled r => trivial
        | NDnd i bs =>
          intro b hb
          simp only [List.mem_map] at hb
          obtain ⟨⟨s, m'⟩, _, rfl⟩ := hb
          exact ih fuel m'
        | NDguard i c m' => exact ih fuel m'
        | NDbranch i c m₁ m₂ => exact ⟨ih fuel m₁, ih fuel m₂⟩
        | NDstep i bs =>
          intro b hb
          simp only [List.mem_map] at hb
          obtain ⟨⟨s, m'⟩, _, rfl⟩ := hb
          exact ih fuel m'

theorem HMono_liftMem [LemFuel] {a : Type}
    (m : ndM a String mem_error (mem_constraint CerbMem.IntegerValue) CerbMem.MemState) :
    HMono (liftMem m) := by
  intro d
  unfold liftMem liftND
  apply HMonoD_liftND
  intros; rfl

/-- `liftCore_run` of ANY core_run action: `get`, then an update that keeps the trace,
    then a return or a kill — whatever the (possibly opaque) inner run produced. -/
theorem HMono_liftCore_run [LemFuel] {a : Type}
    (m : core_run_state → exceptM (t0 a × core_run_state) core_run_cause) :
    HMono (liftCore_run m) := by
  unfold liftCore_run
  apply HMono_bind _ _ HMono_get
  intro dr
  split
  · apply HMono_bind
    · exact HMono_update _ (fun _ => Grows_of_trace_eq rfl)
    · intro _
      split
      · exact HMono_return _
      · exact HMono_kill _
      · exact HMono_kill _
  · exact HMono_kill _

theorem HMono_print_debug (level : Nat) (doms : List domain) (msg : Unit → String) :
    HMono (print_debug level doms msg : DriverAction Unit) := by
  unfold print_debug; exact HMono_return _

/-- `pick` on a NON-EMPTY list: a leaf or a node of returns. (`pick info []` is the opaque
    fail-stop `failwithI`, about which the kernel has no equation.) -/
theorem HMono_pick {a : Type} (info : step_kind) (x : a) (xs : List a) :
    HMono (pick info (x :: xs) : DriverAction a) := by
  intro d
  cases d with
  | zero => trivial
  | succ d =>
    intro st
    cases xs with
    | nil => exact ⟨Grows.refl _, trivial⟩
    | cons y ys =>
      refine ⟨Grows.refl _, ?_⟩
      intro b hb
      simp only [List.mem_cons, List.mem_map] at hb
      rcases hb with rfl | ⟨z, _, rfl⟩
      · exact HMono_return _ d
      · exact HMono_return _ d

theorem HMono_mk_step {a : Type} (info : step_kind) (xs : List (step_kind × DriverAction a))
    (hxs : ∀ b ∈ xs, HMono b.2) : HMono (mk_step info xs) := by
  intro d
  cases d with
  | zero => trivial
  | succ d =>
    intro st
    exact ⟨Grows.refl _, fun b hb => hxs b hb d⟩

theorem HMono_sc_boundary : HMono (sc_boundary ()) :=
  HMono_mk_step _ _ (by
    intro b hb
    simp only [List.mem_singleton] at hb
    subst hb
    exact HMono_return _)

theorem HMono_get_thread_states [LemFuel] : HMono get_thread_states := by
  unfold get_thread_states
  exact HMono_bind _ _ HMono_get (fun _ => HMono_return _)

theorem HMono_spawn_thread [LemFuel] (p : Option thread_id) (th : thread_state) :
    HMono (driver_spawn_thread p th : DriverAction Nat) := by
  unfold driver_spawn_thread
  apply HMono_bind _ _ HMono_get
  intro dr
  split
  apply HMono_bind
  · exact HMono_update _ (fun _ => Grows_of_trace_eq rfl)
  · intro _
    exact HMono_return _

theorem HMono_update_thread_state (tid : Nat) (th : thread_state) :
    HMono (driver_update_thread_state tid th : DriverAction Unit) :=
  HMono_update _ (fun _ => Grows_of_trace_eq rfl)

/-- A record update that conses one event onto the trace (the §3.8 sites). -/
theorem HMono_update_cons (f : driver_state → driver_state)
    (hf : ∀ st, ∃ ev, (f st).trace = ev :: st.trace) : HMono (nd_update f : DriverAction Unit) :=
  HMono_update f (fun st => by obtain ⟨ev, h⟩ := hf st; exact ⟨[ev], by rw [h]; rfl⟩)

/-- The arm tactic: closes `HMono …` goals built from the combinators above, splitting the
    handlers' `match`/`if` and introducing bound variables. -/
macro "hmono_step" : tactic => `(tactic| first
  | exact HMono_return _
  | exact HMono_get
  | exact HMono_read _
  | exact HMono_kill _
  | exact HMono_liftMem _
  | exact HMono_liftCore_run _
  | exact HMono_print_debug _ _ _
  | exact HMono_get_thread_states
  | exact HMono_spawn_thread _ _
  | exact HMono_update_thread_state _ _
  | exact HMono_pick _ _ _
  | (apply HMono_update; intro st; exact Grows_of_trace_eq rfl)
  | (apply HMono_update_cons; intro st; exact ⟨_, rfl⟩)
  | (refine HMono_bind _ _ ?_ (fun _ => ?_))
  | split)

macro "hmono" : tactic => `(tactic| repeat' hmono_step)

/-! ### The S1a handlers, arm by arm

Every arm without an opaque fail-stop leaf is hereditarily trace-monotone. The arms that
ARE fail-stops (`failwithI`, the register's monadic sites: `Step_error2`, `Step_fs2` in
`advance_step`; `RMWRequest2`; the INVALID memop; `process_core_step2`'s WRONG STEP) have
no kernel equation and no next configuration at run time — they are excluded by
hypothesis, never proved around. -/
section Handlers
variable [LemFuel] (e : Enums) (t : Tags)

/-- Every action request handler arm (alloc/create/load/store/seq-RMW/kill: a memory
    operation through `liftMem`, then the trace cons of §3.8) is monotone. -/
theorem HMono_action_request_sequential2 (loc : CerbLocation.Loc) (tid aid : Nat)
    (req : action_request2 thread_state) :
    HMono (action_request_sequential2 e t loc tid aid req) := by
  cases req <;> (unfold action_request_sequential2; hmono)

theorem HMono_perform_action_request2 (loc : CerbLocation.Loc) (tid : Nat)
    (req : action_request2 thread_state) :
    HMono (perform_action_request2 e t false loc tid req) := by
  unfold perform_action_request2
  simp only [Bool.false_eq_true, ↓reduceIte]
  apply HMono_bind _ _ (HMono_liftCore_run _)
  intro aid
  exact HMono_action_request_sequential2 e t loc tid aid req

/-! `advance_step`, arm by arm. The action-request arm is monotone outright
(`HMono_perform_action_request2`, every request); the memop arm takes the monotonicity of
the memop handler AT THIS CALL as a hypothesis (`HMono_perform_memop_request2_served`
discharges it for every served memop; the INVALID memop is the opaque fail-stop leaf). -/

theorem HMono_advance_step_ccall (tid tid' : Nat) (m : core_run_state → exceptM (t0 thread_state × core_run_state) core_run_cause) :
    HMono (advance_step e t tid (Step_ccall2 tid' m)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_with_runstate (tid : Nat) (rsk : runstate_step_kind)
    (m : core_run_state → exceptM (t0 thread_state × core_run_state) core_run_cause) :
    HMono (advance_step e t tid (Step_with_runstate2 rsk m)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_tau (tid : Nat) (dbg : String) (tsk : core_tau_step_kind) (th : thread_state) :
    HMono (advance_step e t tid (Step_tau2 dbg tsk th)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_action_request (tid : Nat) (dbg : String) (loc : CerbLocation.Loc) (tid' : Nat) (u : Bool)
    (m : core_run_state → exceptM (t0 (action_request2 thread_state) × core_run_state) core_run_cause) :
    HMono (advance_step e t tid (Step_action_request2 dbg loc tid' u m)) := by
  unfold advance_step
  apply HMono_bind
  · split
    · exact HMono_return _
    · exact HMono_bind _ _ (HMono_liftCore_run _) (fun req => HMono_perform_action_request2 e t loc tid' req)
  · intro _; hmono

theorem HMono_advance_step_blocked (tid : Nat) : HMono (advance_step e t tid Step_blocked2) := by
  unfold advance_step; hmono

theorem HMono_advance_step_thread_done (tid parent : Nat) (cval : value) :
    HMono (advance_step e t tid (Step_thread_done2 parent cval)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_done (tid : Nat) (cval : value) :
    HMono (advance_step e t tid (Step_done2 cval)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_memop_request (tid : Nat) (loc : CerbLocation.Loc) (memop : generic_memop sym)
    (cvals : List value) (tid' : Nat) (u : Bool) (mk : value → thread_state)
    (hmemop : HMono (perform_memop_request2 e t loc memop cvals tid' mk)) :
    HMono (advance_step e t tid (Step_memop_request2 loc memop cvals tid' u mk)) := by
  unfold advance_step
  apply HMono_bind
  · split
    · exact HMono_return _
    · exact hmemop
  · intro _; hmono

theorem HMono_advance_step_spawn_threads (tid : Nat) (mk : List thread_id → thread_state) (sts : List thread_state) :
    HMono (advance_step e t tid (Step_spawn_threads2 mk sts)) := by
  unfold advance_step; hmono

theorem HMono_advance_step_nd (tid : Nat) (th : thread_state) (ths : List thread_state) :
    HMono (advance_step e t tid (Step_nd2 (th :: ths))) := by
  unfold advance_step; hmono

/-! `process_core_step2 false k`, arm by arm (the continuation `k false` is the SC no-op,
hypothesised monotone; `Step_fs2`'s `drive_fs_step` (filesystem, refused since 2026-09-28)
and the WRONG STEP arm are not stated). -/

theorem HMono_process_core_step2_action_request (k : Bool → DriverAction Unit) (hk : HMono (k false))
    (dbg : String) (loc : CerbLocation.Loc) (tid : Nat) (u : Bool)
    (m : core_run_state → exceptM (t0 (action_request2 thread_state) × core_run_state) core_run_cause) :
    HMono (process_core_step2 e t false k (Step_action_request2 dbg loc tid u m)) := by
  unfold process_core_step2
  apply HMono_bind _ _ (HMono_liftCore_run _)
  intro req
  apply HMono_bind _ _ (HMono_perform_action_request2 e t loc tid req)
  intro _; exact hk

theorem HMono_process_core_step2_memop_request (k : Bool → DriverAction Unit) (hk : HMono (k false))
    (loc : CerbLocation.Loc) (memop : generic_memop sym) (cvals : List value) (tid : Nat) (u : Bool)
    (mk : value → thread_state) (hmemop : HMono (perform_memop_request2 e t loc memop cvals tid mk)) :
    HMono (process_core_step2 e t false k (Step_memop_request2 loc memop cvals tid u mk)) := by
  unfold process_core_step2
  apply HMono_bind _ _ hmemop
  intro _; exact hk

theorem HMono_process_core_step2_done (k : Bool → DriverAction Unit) (cval : value) :
    HMono (process_core_step2 e t false k (Step_done2 cval)) := by
  unfold process_core_step2; hmono

theorem HMono_process_core_step2_ccall (k : Bool → DriverAction Unit) (hk : HMono (k false))
    (tid : Nat) (m : core_run_state → exceptM (t0 thread_state × core_run_state) core_run_cause) :
    HMono (process_core_step2 e t false k (Step_ccall2 tid m)) := by
  unfold process_core_step2
  apply HMono_bind _ _ (HMono_liftCore_run _)
  intro _
  refine HMono_bind _ _ ?_ (fun _ => hk)
  exact HMono_update _ (fun _ => Grows_of_trace_eq rfl)

/-- `perform_memop_request2`: every SERVED arm is monotone; the only other arm is the
    INVALID-memop fail-stop, the opaque `failwithI` leaf bound to the thread-state update
    (driver.lem's `match … end >>= fun th_st' -> ND.update …`). -/
theorem HMono_perform_memop_request2_served (loc : CerbLocation.Loc) (memop : generic_memop sym)
    (cvals : List value) (tid : Nat) (mk : value → thread_state) :
    HMono (perform_memop_request2 e t loc memop cvals tid mk) ∨
    ∃ msg, perform_memop_request2 e t loc memop cvals tid mk
      = nd_bind (failwithI msg : DriverAction thread_state)
          (fun th_st' => nd_update (fun dr_st => update_core_state (update_thread_state tid th_st' dr_st.core_state0) dr_st)) := by
  unfold perform_memop_request2
  split <;> first
    | (left; hmono; done)
    | (right; exact ⟨_, rfl⟩)

/-! ### The S1a transition, given monotone handlers -/

/-- `sc_perform` when a step can advance: monotone iff `advance_step` on that step is. -/
theorem HMono_sc_perform_advance (tid : Nat) (steps : List core_step2) (s : core_step2)
    (h : find_can_advance steps = some s) (hs : HMono (advance_step e t tid s)) :
    HMono (sc_perform e t tid steps) := by
  rw [sc_perform_advance e t tid steps s h]
  exact HMono_bind _ _ hs (fun _ => HMono_return _)

/-- `sc_perform` on `drive`'s saved-step pick (non-empty): monotone iff processing each
    saved step with the SC no-op continuation is. -/
theorem HMono_sc_perform_pick (tid : Nat) (x : core_step2) (xs : List core_step2)
    (h : find_can_advance (x :: xs) = none)
    (hp : ∀ s, HMono (process_core_step2 e t false (fun (_ : Bool) => nd_return ()) s)) :
    HMono (sc_perform e t tid (x :: xs)) := by
  rw [sc_perform_pick e t tid (x :: xs) h]
  exact HMono_bind _ _ (HMono_pick _ _ _) hp

/-- L6 for a Core transition: the trace grows whenever the local transition's action is
    monotone at the stored state (`sc_core_transition` adds nothing itself). -/
theorem TraceGrows_core_transition (cfg : sc_config) (k : DriverAction driver_result)
    (h : ∀ tid th_info, cfg.sc_state.core_state0.thread_states = [(tid, th_info)] →
      HMono (sc_perform e t tid (step_ctx e t cfg.sc_state.layout_state cfg.sc_state.core_file cfg.sc_state.core_extern tid th_info))) :
    TraceGrows cfg (sc_core_transition e t cfg k) := by
  rcases sc_core_transition_state e t cfg k with hst | ⟨tid, th_info, hts, hst⟩
  · unfold TraceGrows; rw [hst]; exact List.suffix_refl _
  · unfold TraceGrows; rw [hst]; exact HMono_grows (h tid th_info hts) _

/-- L6 for a choosing-phase transition: the trace grows whenever the chosen branch is
    monotone. -/
theorem TraceGrows_chosen_core (cfg cfg' : sc_config) (b : Bool) (alts : List (step_kind × DriverAction Unit))
    (k : DriverAction driver_result) (i : Nat) (info : step_kind) (m : DriverAction Unit)
    (hph : cfg.sc_phase0 = SC_core_choosing b alts k) (hi : listGetOpt alts i = some (info, m))
    (hm : HMono m) (h : sc_step e t cfg (some (SC_alt i)) = .inr cfg') : TraceGrows cfg cfg' := by
  unfold TraceGrows
  rw [sc_step_chosen_core_state e t cfg cfg' b alts k i info m hph hi h]
  exact HMono_grows hm _

theorem TraceGrows_lifecycle (cfg cfg' : sc_config) (k : DriverAction driver_result)
    (hph : cfg.sc_phase0 = SC_lifecycle k) (hk : HMono k)
    (h : sc_step e t cfg none = .inr cfg') : TraceGrows cfg cfg' := by
  unfold sc_step at h
  rw [hph] at h
  simp only at h
  cases h
  unfold TraceGrows
  rw [sc_interpret_lifecycle_state]
  exact HMono_grows hk _

end Handlers

end L6Handlers

/-! Axiom cones of the laws (all ⊆ the standard three; the entry-level pin is
scripts/check_theorem_axioms.sh's `sc_*` census). -/
#print axioms sc_run_exhausted_transitions
#print axioms sc_run_stable
#print axioms sc_step_chosen_core
#print axioms sc_perform_advance
#print axioms sc_events_append
#print axioms HMonoD_bind
#print axioms HMono_advance_step_action_request
#print axioms HMono_perform_memop_request2_served

end SCStepProofs
