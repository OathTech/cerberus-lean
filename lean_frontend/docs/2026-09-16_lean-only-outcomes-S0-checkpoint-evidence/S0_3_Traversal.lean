/-
  S0.3 — the traversal prototype on the PRODUCTION combinators (charter S0.3;
  review §5). Imports the generated State_exception_undefined (SEU) and
  Exception_undefined (EU) modules as built on this branch (configuration
  (a), all 13 propagation arms present). Nothing here changes the `.lem`.

  (a) the current layering's behaviour on a stop in element k followed by a
      state update / an outer exception in element k+1 — and the SAME
      behaviour for a legacy `Undef` in element k (upstream's semantics,
      which the mirror keeps);
  (b) a candidate stop-aware traversal `mapM'` = the SAME outer-collect /
      inner-fold layering, except that collection HALTS at the first
      `Stopped` (later elements are not run) — with the conservativity law
      (no element stops → mapM' = mapM, as functions) and the stop theorems.
-/
import State_exception_undefined
set_option autoImplicit false

namespace S0_3

/-! ### (a) counterexamples on the production `stExceptUndef_mapM` / `exception_undef_mapM` -/

def stopThenWrite : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, s => Result (Stopped Exhausted, s)
  | x, s => Result (Defined x, s + 1)

def stopThenRaise : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, s => Result (Stopped Exhausted, s)
  | _, _ => Exception "later"

def undefThenWrite : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, s => Result (Undef CerbLocation.Loc.unknown [], s)
  | x, s => Result (Defined x, s + 1)

def undefThenRaise : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, _ => Result (Undef CerbLocation.Loc.unknown [], 0)
  | _, _ => Exception "later"

-- SEU, production: the stop in element 0 does NOT prevent element 1 from
-- running; the eventual stop carries the LATER state (1, not 0).
theorem seu_state_changes_after_stop :
    stExceptUndef_mapM stopThenWrite [0, 1] 0 = Result (Stopped Exhausted, 1) := by
  simp [stExceptUndef_mapM, stExpect_mapM, lemListFoldr, List.foldr_toArray, stExpect_bind,
    stExpect_return, except_bind, except_return, stopThenWrite, mapM1, sequence0, bind2, return1]

-- SEU, production: a later outer exception REPLACES the stop.
theorem seu_stop_replaced_by_later_exception :
    stExceptUndef_mapM stopThenRaise [0, 1] 0 = Exception "later" := by
  simp [stExceptUndef_mapM, stExpect_mapM, lemListFoldr, List.foldr_toArray, stExpect_bind,
    stExpect_return, except_bind, except_return, stopThenRaise, mapM1, sequence0, bind2, return1]

-- The SAME two facts for a legacy `Undef` in element 0 — upstream's own
-- semantics for UB/error in a mapM (run all, then fold); the mirror keeps it.
theorem seu_state_changes_after_undef :
    stExceptUndef_mapM undefThenWrite [0, 1] 0 = Result (Undef CerbLocation.Loc.unknown [], 1) := by
  simp [stExceptUndef_mapM, stExpect_mapM, lemListFoldr, List.foldr_toArray, stExpect_bind,
    stExpect_return, except_bind, except_return, undefThenWrite, mapM1, sequence0, bind2, return1]

theorem seu_undef_replaced_by_later_exception :
    stExceptUndef_mapM undefThenRaise [0, 1] 0 = Exception "later" := by
  simp [stExceptUndef_mapM, stExpect_mapM, lemListFoldr, List.foldr_toArray, stExpect_bind,
    stExpect_return, except_bind, except_return, undefThenRaise, mapM1, sequence0, bind2, return1]

-- EU, production (stateless): the later exception replaces the stop.
def euStopThenRaise : Nat → exceptM (t0 Nat) String
  | 0 => Result (Stopped Exhausted)
  | _ => Exception "later"

theorem eu_stop_replaced_by_later_exception :
    exception_undef_mapM euStopThenRaise [0, 1] = Exception "later" := by
  simp [exception_undef_mapM, except_mapM, except_sequence, lemListFoldr, List.foldr_toArray,
    except_bind, except_return, euStopThenRaise, mapM1, sequence0, bind2, return1]

/-! ### (b) the candidate: halt collection at the first `Stopped`, keep everything else -/

/-- Left-to-right, state-threading collection of the element outcomes — the
    production `stExpect_mapM f` — except that a `Stopped` HALTS it: the
    stop is the last collected outcome, the state is the state right after
    it, and no later element is run. -/
def collectS {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg) :
    List d → s → exceptM (List (t0 a) × s) msg
  | [], st => Result ([], st)
  | x :: xs, st =>
    match f x st with
    | Exception e => Exception e
    | Result (Stopped sp, st') => Result ([Stopped sp], st')
    | Result (u, st') =>
      match collectS f xs st' with
      | Exception e => Exception e
      | Result (us, st'') => Result (u :: us, st'')

/-- The candidate traversal: the production layering with `collectS` in place
    of `stExpect_mapM`. The inner fold (`mapM1 id` = the production one) is
    UNCHANGED, so the legacy precedence (first non-`Defined` wins) is kept. -/
def mapM' {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg) (xs : List d) :
    s → exceptM (t0 (List a) × s) msg :=
  stExpect_bind (collectS f xs) (fun us => stExpect_return (mapM1 (fun x => x) us))

/-- "The element result is not a stop." -/
def NoStopS {a s msg : Type} (r : exceptM (t0 a × s) msg) : Prop :=
  ∀ sp st', r ≠ Result (Stopped sp, st')

theorem stExpect_mapM_nil {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg) :
    stExpect_mapM f [] = stExpect_return [] := by
  simp [stExpect_mapM, lemListFoldr, List.foldr_toArray]

theorem stExpect_mapM_cons {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg) (x : d) (xs : List d) :
    stExpect_mapM f (x :: xs) =
      stExpect_bind (f x) (fun y => stExpect_bind (stExpect_mapM f xs) (fun ys => stExpect_return (y :: ys))) := by
  simp [stExpect_mapM, lemListFoldr, List.foldr_toArray]

/-- CONSERVATIVITY of the collection: when no element result is a stop (at any
    state), the halting collection IS the production collection. -/
theorem collectS_eq_stExpect_mapM {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg)
    (h : ∀ x st, NoStopS (f x st)) (xs : List d) :
    collectS f xs = stExpect_mapM f xs := by
  induction xs with
  | nil => funext st; simp [collectS, stExpect_mapM_nil, stExpect_return, except_return]
  | cons x xs ih =>
    funext st
    rw [stExpect_mapM_cons, ← ih]
    simp only [collectS, stExpect_bind, stExpect_return, except_return]
    cases hx : f x st with
    | Exception e => simp [except_bind]
    | Result p =>
      obtain ⟨u, st'⟩ := p
      cases u with
      | Stopped sp => exact absurd hx (h x st sp st')
      | Defined v => simp [except_bind]; cases collectS f xs st' <;> simp [except_bind]
      | Undef l ubs => simp [except_bind]; cases collectS f xs st' <;> simp [except_bind]
      | Error l m => simp [except_bind]; cases collectS f xs st' <;> simp [except_bind]

/-- THE CONSERVATIVITY LAW: on every traversal whose element results are all
    in the legacy fragment, `mapM'` IS the production `stExceptUndef_mapM`
    (as a function of the initial state). -/
theorem mapM'_eq_mapM {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg)
    (h : ∀ x st, NoStopS (f x st)) (xs : List d) :
    mapM' f xs = stExceptUndef_mapM f xs := by
  unfold mapM' stExceptUndef_mapM
  rw [collectS_eq_stExpect_mapM f h xs]

/-- Collection appends across a prefix that produced no stop. -/
theorem collectS_append {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg)
    (xs zs : List d) (st st1 : s) (us : List (t0 a))
    (hpre : collectS f xs st = Result (us, st1))
    (hns : ∀ u ∈ us, ∀ sp, u ≠ Stopped sp) :
    collectS f (xs ++ zs) st =
      match collectS f zs st1 with
      | Exception e => Exception e
      | Result (vs, st2) => Result (us ++ vs, st2) := by
  induction xs generalizing st us with
  | nil =>
    simp only [collectS] at hpre
    injection hpre with h
    injection h with h1 h2
    subst h1; subst h2
    simp only [List.nil_append]
    cases hc : collectS f zs st with
    | Exception e => rfl
    | Result q => obtain ⟨vs, st2⟩ := q; simp
  | cons x xs ih =>
    simp only [List.cons_append, collectS] at hpre ⊢
    cases hx : f x st with
    | Exception e => simp [hx] at hpre
    | Result p =>
      obtain ⟨u, st'⟩ := p
      cases u with
      | Stopped sp =>
        simp [hx] at hpre
        obtain ⟨rfl, rfl⟩ := hpre
        exact absurd rfl (hns (Stopped sp) (by simp) sp)
      | Defined v =>
        simp [hx] at hpre ⊢
        cases hc : collectS f xs st' with
        | Exception e => simp [hc] at hpre
        | Result q =>
          obtain ⟨us', st1'⟩ := q
          simp [hc] at hpre
          obtain ⟨rfl, rfl⟩ := hpre
          rw [ih st' us' hc (fun u hu sp => hns u (by simp [hu]) sp)]
          cases collectS f zs st1' <;> simp
      | Undef l ubs =>
        simp [hx] at hpre ⊢
        cases hc : collectS f xs st' with
        | Exception e => simp [hc] at hpre
        | Result q =>
          obtain ⟨us', st1'⟩ := q
          simp [hc] at hpre
          obtain ⟨rfl, rfl⟩ := hpre
          rw [ih st' us' hc (fun u hu sp => hns u (by simp [hu]) sp)]
          cases collectS f zs st1' <;> simp
      | Error l m =>
        simp [hx] at hpre ⊢
        cases hc : collectS f xs st' with
        | Exception e => simp [hc] at hpre
        | Result q =>
          obtain ⟨us', st1'⟩ := q
          simp [hc] at hpre
          obtain ⟨rfl, rfl⟩ := hpre
          rw [ih st' us' hc (fun u hu sp => hns u (by simp [hu]) sp)]
          cases collectS f zs st1' <;> simp

/-- The inner fold on an all-`Defined` prefix followed by a stop yields the stop. -/
theorem sequence0_defined_then_stop {a : Type} (us : List (t0 a)) (sp : interp_stop)
    (hall : ∀ u ∈ us, ∃ v, u = Defined v) :
    sequence0 (us ++ [Stopped sp]) = (Stopped sp : t0 (List a)) := by
  induction us with
  | nil => simp [sequence0, lemListFoldr, List.foldr_toArray, bind2, return1]
  | cons u us ih =>
    obtain ⟨v, rfl⟩ := hall u (by simp)
    have ih' := ih (fun u hu => hall u (by simp [hu]))
    simp only [sequence0, lemListFoldr, List.foldr_toArray, List.cons_append, List.foldr] at ih' ⊢
    rw [ih']; simp [bind2]

/-- THE STOP THEOREM: a stop in element k (after an all-`Defined` prefix) ENDS
    the traversal — the result is that stop with the state right after element
    k, for EVERY continuation `ys` (so no later element is run, no later state
    update reaches the result, and no later outer exception replaces it). -/
theorem mapM'_stops {a d msg s : Type} (f : d → s → exceptM (t0 a × s) msg)
    (xs ys : List d) (x : d) (st st1 st2 : s) (us : List (t0 a)) (sp : interp_stop)
    (hpre : collectS f xs st = Result (us, st1))
    (hall : ∀ u ∈ us, ∃ v, u = Defined v)
    (hx : f x st1 = Result (Stopped sp, st2)) :
    mapM' f (xs ++ x :: ys) st = Result (Stopped sp, st2) := by
  have hns : ∀ u ∈ us, ∀ sp', u ≠ Stopped sp' := by
    intro u hu sp' heq; obtain ⟨v, hv⟩ := hall u hu; simp [hv] at heq
  unfold mapM'
  simp only [stExpect_bind, stExpect_return, except_return]
  rw [collectS_append f xs (x :: ys) st st1 us hpre hns]
  simp only [collectS, hx]
  simp [except_bind, mapM1, sequence0_defined_then_stop us sp hall]

-- Concrete corollaries on the (a) examples, by the same simp set: the candidate
-- keeps the state AT the stop and is not replaced by the later exception.
theorem mapM'_stopThenWrite : mapM' stopThenWrite [0, 1] 0 = Result (Stopped Exhausted, 0) := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return, stopThenWrite,
    mapM1, sequence0, lemListFoldr, List.foldr_toArray, bind2, return1]

theorem mapM'_stopThenRaise : mapM' stopThenRaise [0, 1] 0 = Result (Stopped Exhausted, 0) := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return, stopThenRaise,
    mapM1, sequence0, lemListFoldr, List.foldr_toArray, bind2, return1]

-- Legacy precedence is untouched by the candidate: an `Undef` in element 0 still
-- lets element 1 run (state 1) and wins the fold, exactly as production does.
theorem mapM'_undefThenWrite : mapM' undefThenWrite [0, 1] 0 = Result (Undef CerbLocation.Loc.unknown [], 1) := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return, undefThenWrite,
    mapM1, sequence0, lemListFoldr, List.foldr_toArray, bind2, return1]

theorem mapM'_undefThenRaise : mapM' undefThenRaise [0, 1] 0 = Exception "later" := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return, undefThenRaise,
    mapM1, sequence0, lemListFoldr, List.foldr_toArray, bind2, return1]

end S0_3

#print axioms S0_3.seu_state_changes_after_stop
#print axioms S0_3.seu_stop_replaced_by_later_exception
#print axioms S0_3.seu_state_changes_after_undef
#print axioms S0_3.seu_undef_replaced_by_later_exception
#print axioms S0_3.eu_stop_replaced_by_later_exception
#print axioms S0_3.collectS_eq_stExpect_mapM
#print axioms S0_3.mapM'_eq_mapM
#print axioms S0_3.collectS_append
#print axioms S0_3.sequence0_defined_then_stop
#print axioms S0_3.mapM'_stops
#print axioms S0_3.mapM'_stopThenWrite
#print axioms S0_3.mapM'_stopThenRaise
#print axioms S0_3.mapM'_undefThenWrite
#print axioms S0_3.mapM'_undefThenRaise
