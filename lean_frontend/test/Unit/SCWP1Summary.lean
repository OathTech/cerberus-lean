import Std

/-! An exact, materialized live-endpoint summary for WP1. This is a feasibility
    baseline, not a recommended large-memory matrix implementation. No event
    history, function-valued relation, or retired-thread map is retained.
    Proof-only roots interpret rows as causal snapshots; they are not stored
    by the executable summary. -/
namespace SCWP1Summary

abbrev Matrix (n : Nat) := Vector (Vector Bool n) n

def lookup {n : Nat} (m : Matrix n) (i j : Fin n) : Bool := (m.get i).get j
@[simp] theorem get_ofFn {α : Type} {n : Nat} (f : Fin n → α) (i : Fin n) :
    (Vector.ofFn f).get i = f i := by simp [Vector.get]
@[simp] theorem lookup_ofFn {n : Nat} (f : Fin n → Fin n → Bool) (i j : Fin n) :
    lookup (Vector.ofFn (fun i => Vector.ofFn (f i))) i j = f i j := by simp [lookup]

def project {n k : Nat} (m : Matrix n) (keep : Vector (Fin n) k) : Matrix k :=
  Vector.ofFn fun i => Vector.ofFn fun j => lookup m (keep.get i) (keep.get j)

/-- A new event inherits exactly its predecessor endpoints. Old endpoints
    cannot acquire a new ancestor. The final diagonal is reflexive. -/
def extend {n : Nat} (m : Matrix n) (parents : List (Fin n)) : Matrix (n+1) :=
  Vector.ofFn fun i => Vector.ofFn fun j =>
    if hi : i.val < n then
      if hj : j.val < n then lookup m ⟨i.val,hi⟩ ⟨j.val,hj⟩
      else parents.any (fun p => lookup m ⟨i.val,hi⟩ p)
    else decide (j.val = n)

def Correct {α : Type} {n : Nat} (R : α → α → Prop)
    (roots : Vector α n) (m : Matrix n) : Prop :=
  ∀ i j : Fin n, lookup m i j = true ↔ R (roots.get i) (roots.get j)

/-- Projection preserves all comparisons among survivors, including relations
    through arbitrarily many forgotten events. Projection of *edges* would
    fail here; the representation is the induced reachability relation. -/
theorem project_correct {α : Type} {n k : Nat} (R : α → α → Prop)
    (roots : Vector α n) (m : Matrix n) (keep : Vector (Fin n) k)
    (h : Correct R roots m) :
    Correct R (Vector.ofFn (fun i => roots.get (keep.get i))) (project m keep) := by
  intro i j
  simpa [project] using h (keep.get i) (keep.get j)

def Extended {α : Type} (R : α → α → Prop) (parents : List α) :
    Option α → Option α → Prop
  | some a, some b => R a b
  | some a, none => ∃ p ∈ parents, R a p
  | none, some _ => False
  | none, none => True

def extendedRoots {α : Type} {n : Nat} (roots : Vector α n) : Vector (Option α) (n+1) :=
  Vector.ofFn fun i => if h : i.val < n then some (roots.get ⟨i.val,h⟩) else none

theorem extend_correct {α : Type} {n : Nat} (R : α → α → Prop)
    (roots : Vector α n) (m : Matrix n) (parents : List (Fin n))
    (h : Correct R roots m) :
    Correct (Extended R (parents.map (fun i => roots.get i)))
      (extendedRoots roots) (extend m parents) := by
  intro i j
  by_cases hi : i.val < n <;> by_cases hj : j.val < n
  · simpa [extend, extendedRoots, hi, hj, Extended] using h ⟨i.val,hi⟩ ⟨j.val,hj⟩
  · simp only [extend, extendedRoots, lookup_ofFn, get_ofFn, hi, hj, dite_true, dite_false, Extended, List.any_eq_true, List.mem_map]
    constructor
    · rintro ⟨p,hp,hm⟩
      exact ⟨roots.get p, ⟨p,hp,rfl⟩, (h ⟨i.val,hi⟩ p).mp hm⟩
    · rintro ⟨_, ⟨p,hp,rfl⟩, hr⟩
      exact ⟨p,hp,(h ⟨i.val,hi⟩ p).mpr hr⟩
  · have : j.val ≠ n := by omega
    simp [extend, extendedRoots, hi, hj, Extended, this]
  · have : j.val = n := by omega
    simp [extend, extendedRoots, hi, Extended, this]

/-- The extension is already transitively closed if the incoming relation is.
    Thus extending and projecting needs no reconstruction of the past graph. -/
theorem extended_transitive {α : Type} (R : α → α → Prop) (ps : List α)
    (h : ∀ a b c, R a b → R b c → R a c) :
    ∀ a b c, Extended R ps a b → Extended R ps b c → Extended R ps a c := by
  intro a b c hab hbc
  cases a <;> cases b <;> cases c <;> simp only [Extended] at *
  all_goals try contradiction
  all_goals try trivial
  · obtain ⟨p,hp,hbp⟩ := hbc
    exact ⟨p,hp,h _ _ _ hab hbp⟩
  · exact h _ _ _ hab hbc

/-- Removing an older same-location read from a maximal-read antichain
    preserves existence of a conflicting predecessor, not just a clock test.
    `R` is reflexive reachability; runtime event identities remain distinct. -/
theorem dominated_read {α : Type} (R : α → α → Prop)
    (h : ∀ a b c, R a b → R b c → R a c) (a b c : α) (hab : R a b) :
    (¬ R a c ∨ ¬ R b c) ↔ ¬ R b c := by
  constructor
  · rintro (ha | hb)
    · intro hbc; exact ha (h a b c hab hbc)
    · exact hb
  · exact Or.inr

#print axioms project_correct
#print axioms extend_correct
#print axioms extended_transitive
#print axioms dominated_read
end SCWP1Summary
