/-
  RelSem.Kit.Map — arc-9 S3 (2026-08-20): L1 kit, the lawful-map
  lookup layer (design §11.2 — the P2 route GENERALIZED from bytemaps
  to environments, per decision-log D2 ruling 1).

  Contents:
  * `Std.TransCmp` for the sym comparator (`lemCmpToOrd symOrd`):
    the comparator is digest-then-id lexicographic with PURE String/
    Nat orders (CerberusFresh.digest_compare is plain String </==),
    proved via a funext bridge to `compareLex` of comparator
    precompositions and instance transport.
  * The `FmapCmpIs` shape invariant (an Fmap's captured comparator is
    `lemCmpToOrd cmp`; maintained by `fmapAddBy`) and the two lookup
    laws `fmapLookupBy_addBy_eq` / `fmapLookupBy_addBy_ne` — the
    engine for St-v2's recursive env-family lookups (F-T5-1).
  * `symOrd_eq_iff` — the comparator-EQ characterization the fixture
    dischargers feed with `decide`/`omega` facts.
  * Int-keyed `Std.TreeMap` get?/insert laws (the bytemap byte-fetch
    engine over `writeBytesTo` chains).

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here. Pins in Kit/Audit.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Tactics.AppEqAttr
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

open Std

/-! ## The sym comparator, and its lawfulness -/

/-- The comparator every generated env/map call site passes (the
    eta-expanded `ordCompare` closure, verbatim). -/
abbrev symOrd : sym → sym → LemOrdering :=
  fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2

/-- The captured Ordering-form comparator (what an `fmapAddBy`-built
    sym-keyed Fmap's trees are keyed by). -/
abbrev symCmpO : sym → sym → Ordering := lemCmpToOrd symOrd

def symDg : sym → String | Symbol d _ _ => d
def symId : sym → Nat | Symbol _ n _ => n

/-- The lawful composite the bridge targets: digest lexicographically
    before id, both through the standard `compare`. -/
def symCmpAlt : sym → sym → Ordering :=
  compareLex (fun a b => Ord.compare (symDg a) (symDg b))
             (fun a b => Ord.compare (symId a) (symId b))

/-- `symCmpAlt` at constructors (rfl-grade). -/
theorem symCmpAlt_eval (d1 d2 : String) (n1 n2 : Nat)
    (sd1 sd2 : symbol_description) :
    symCmpAlt (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
    = (Ord.compare d1 d2).then (Ord.compare n1 n2) := rfl

/-- String `Ord.compare` (= compareOfLessAndEq), branch facts. -/
theorem strCompare_lt {d1 d2 : String} (h : d1 < d2) :
    Ord.compare d1 d2 = .lt := by
  show (if d1 < d2 then Ordering.lt
        else if d1 = d2 then Ordering.eq else Ordering.gt) = _
  rw [if_pos h]

theorem strCompare_self (d : String) : Ord.compare d d = .eq := by
  show (if d < d then Ordering.lt
        else if d = d then Ordering.eq else Ordering.gt) = _
  rw [if_neg (String.lt_irrefl d), if_pos rfl]

theorem strCompare_gt {d1 d2 : String} (hlt : ¬ d1 < d2) (hne : d1 ≠ d2) :
    Ord.compare d1 d2 = .gt := by
  show (if d1 < d2 then Ordering.lt
        else if d1 = d2 then Ordering.eq else Ordering.gt) = _
  rw [if_neg hlt, if_neg hne]

/-- Comparator precomposition preserves `TransCmp`. -/
theorem transCmpPre {α β : Type} (f : α → β) (cmp : β → β → Ordering)
    [Std.TransCmp cmp] : Std.TransCmp (fun a b => cmp (f a) (f b)) where
  eq_swap := Std.OrientedCmp.eq_swap (cmp := cmp)
  isLE_trans := Std.TransCmp.isLE_trans (cmp := cmp)

instance instTransCmpSymAlt : Std.TransCmp symCmpAlt :=
  @instTransCmpCompareLex sym _ _
    (transCmpPre symDg (compare : String → String → Ordering))
    (transCmpPre symId (compare : Nat → Nat → Ordering))

/-- `ordCompare` at sym constructors, in isLess/isEqual-free form
    (the custom Ord0/Eq0 sym instances of generated Symbol.lean; the
    debug arm of `isEqual` is statically dead). -/
theorem symOrd_eval (d1 d2 : String) (n1 n2 : Nat)
    (sd1 sd2 : symbol_description) :
    Lem_Basic_classes.ordCompare (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
    = (if (intLtb (CerberusFresh.digest_compare d1 d2) 0
          || ((CerberusFresh.digest_compare d1 d2 == 0) && natLtb n1 n2))
       then LemOrdering.LT
       else if ((CerberusFresh.digest_compare d1 d2 == 0) && (n1 == n2))
       then LemOrdering.EQ
       else LemOrdering.GT) := by
  have hEq : Lem_Basic_classes.Eq0.isEqual (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
      = ((CerberusFresh.digest_compare d1 d2 == 0) && (n1 == n2)) := by
    show (if ((CerberusFresh.digest_compare d1 d2 == 0) && (n1 == n2)) = true then
            (if (natGteb 0 5 && (sd1 != sd2)) = true then true else true)
          else false) = _
    split
    · next h => rw [h]; split <;> rfl
    · next h => simp only [Bool.not_eq_true] at h; rw [h]
  show (if Lem_Basic_classes.Ord0.isLess (Symbol d1 n1 sd1) (Symbol d2 n2 sd2) = true
        then LemOrdering.LT
        else if Lem_Basic_classes.Eq0.isEqual (Symbol d1 n1 sd1) (Symbol d2 n2 sd2) = true
        then LemOrdering.EQ
        else LemOrdering.GT) = _
  rw [hEq]; rfl

/-- digest_compare below/at/above (its `==` is the CORE String BEq —
    CerberusFresh is a leaf module). -/
theorem digest_compare_lt {x y : String} (h : x < y) :
    CerberusFresh.digest_compare x y = -1 := by
  unfold CerberusFresh.digest_compare; rw [if_pos h]

theorem digest_compare_self (x : String) :
    CerberusFresh.digest_compare x x = 0 := by
  unfold CerberusFresh.digest_compare
  rw [if_neg (String.lt_irrefl x)]
  show (if decide (x = x) = true then (0 : Int) else 1) = 0
  simp

theorem digest_compare_gt {x y : String} (hlt : ¬ x < y) (hne : x ≠ y) :
    CerberusFresh.digest_compare x y = 1 := by
  unfold CerberusFresh.digest_compare
  rw [if_neg hlt]
  show (if decide (x = y) = true then (0 : Int) else 1) = 1
  simp [hne]

/-- THE BRIDGE: the captured sym comparator IS the lawful composite. -/
theorem symCmp_bridge : symCmpO = symCmpAlt := by
  funext a b
  obtain ⟨d1, n1, sd1⟩ := a
  obtain ⟨d2, n2, sd2⟩ := b
  show lemCmpToOrd symOrd (Symbol d1 n1 sd1) (Symbol d2 n2 sd2) = _
  unfold lemCmpToOrd
  rw [show symOrd (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
      = Lem_Basic_classes.ordCompare (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
      from rfl, symOrd_eval, symCmpAlt_eval]
  by_cases hlt : d1 < d2
  · rw [digest_compare_lt hlt, strCompare_lt hlt]; rfl
  · by_cases heq : d1 = d2
    · subst heq
      rw [digest_compare_self d1, strCompare_self d1]
      rcases Nat.lt_trichotomy n1 n2 with h | h | h
      · rw [show natLtb n1 n2 = true from decide_eq_true h,
          Nat.compare_eq_lt.mpr h]
        rfl
      · subst h
        rw [show natLtb n1 n1 = false from
            decide_eq_false (Nat.lt_irrefl n1),
          Nat.compare_eq_eq.mpr rfl]
        have hbeq : (n1 == n1) = true := by
          show (match Lem_Map.mapKeyCompare n1 n1 with
                | LemOrdering.EQ => true | _ => false) = true
          show (match defaultCompare n1 n1 with
                | LemOrdering.EQ => true | _ => false) = true
          unfold defaultCompare
          rw [Nat.compare_eq_eq.mpr rfl]
        rw [hbeq]; rfl
      · rw [show natLtb n1 n2 = false from
            decide_eq_false (Nat.not_lt.mpr (Nat.le_of_lt h)),
          Nat.compare_eq_gt.mpr h]
        have hbeq : (n1 == n2) = false := by
          show (match Lem_Map.mapKeyCompare n1 n2 with
                | LemOrdering.EQ => true | _ => false) = false
          show (match defaultCompare n1 n2 with
                | LemOrdering.EQ => true | _ => false) = false
          unfold defaultCompare
          rw [Nat.compare_eq_gt.mpr h]
        rw [hbeq]; rfl
    · rw [digest_compare_gt hlt heq, strCompare_gt hlt heq]; rfl

/-- The sym comparator is lawful (the env-lookup engine's licence). -/
instance instTransCmpSymCmpO : Std.TransCmp symCmpO :=
  symCmp_bridge ▸ instTransCmpSymAlt

/-- Comparator-EQ characterization: digest and id agree (description-
    INSENSITIVE — the discharger's `decide`/`omega` surface). -/
theorem symCmpO_eq_iff (d1 d2 : String) (n1 n2 : Nat)
    (sd1 sd2 : symbol_description) :
    symCmpO (Symbol d1 n1 sd1) (Symbol d2 n2 sd2) = .eq ↔ (d1 = d2 ∧ n1 = n2) := by
  rw [symCmp_bridge, symCmpAlt_eval]
  constructor
  · intro h
    by_cases h1 : d1 < d2
    · rw [strCompare_lt h1] at h
      exact absurd h (by intro hc; cases hc)
    · by_cases h2 : d1 = d2
      · subst h2
        rw [strCompare_self d1] at h
        exact ⟨rfl, Nat.compare_eq_eq.mp
          ((show (Ordering.eq.then (Ord.compare n1 n2))
              = Ord.compare n1 n2 from rfl) ▸ h)⟩
      · rw [strCompare_gt h1 h2] at h
        exact absurd h (by intro hc; cases hc)
  · rintro ⟨rfl, rfl⟩
    rw [strCompare_self d1, Nat.compare_eq_eq.mpr rfl]
    rfl

/-! ## The Fmap shape invariant + lookup laws.

    TWO comparators are in play at a generated env map: the CAPTURED
    tree comparator (fixed at the first insert — for envs, the
    hand-written callFinish/injectArgs `ordCompare` closure) and the
    comparators PASSED by later call sites (`update_env_aux`/
    `lookup_env` pass `@mapKeyCompare` — a DIFFERENT function).
    `fmapAddBy`/`fmapLookupBy` IGNORE the passed comparator on `.mk`
    maps (LemLib: the tree is searched with the captured one), so the
    laws below quantify over arbitrary passed comparators and demand
    only the captured-comparator invariant `FmapBuilt`. -/

/-- The map is non-empty-built with captured comparator `c`. -/
def FmapBuilt {α β : Type} (c : α → α → Ordering) :
    Fmap α β → Prop
  | .empty => False
  | .mk c' _ _ _ => c' = c

/-- First insert on the empty map captures the passed comparator. -/
theorem fmapAddBy_built_empty {α β : Type} [BEq α]
    {pcmp : α → α → LemOrdering} {k : α} {v : β} :
    FmapBuilt (lemCmpToOrd pcmp)
      (fmapAddBy pcmp k v (fmapEmpty : Fmap α β)) := rfl

/-- Inserts (under ANY passed comparator) keep the captured one. -/
@[step_law (kind := envMap) (variant := built) (side := rfl)
  (frontier := "env/built")
  (trace := "{law := fmapAddBy_built, joint := env/built, hyps := [h : fed]}")
  (lineage := "comparator-capture invariant: inserts keep the captured comparator (arc-17 S3 env lane)")]
theorem fmapAddBy_built {α β : Type} [BEq α]
    {c : α → α → Ordering} {pcmp : α → α → LemOrdering}
    {k : α} {v : β} {m : Fmap α β}
    (h : FmapBuilt c m) : FmapBuilt c (fmapAddBy pcmp k v m) := by
  cases m with
  | empty => exact absurd h (by simp [FmapBuilt])
  | mk c' byKey bySeq n => exact h

/-- Lookup after insert, captured-comparator-EQ key: the just-inserted
    value (passed comparators arbitrary). -/
@[step_law (kind := envMap) (variant := hit) (side := ground)
  (frontier := "env/lookup-hit")
  (trace := "{law := fmapLookupBy_addBy_eq, joint := env/lookup, hyps := [hm : fed, hk : ground]}")
  (lineage := "lookup-over-insert hit at the captured comparator (Pset parity; the env-lookup lane)")]
theorem fmapLookupBy_addBy_eq {α β : Type} [BEq α]
    {c : α → α → Ordering} [Std.TransCmp c]
    {pcmp pcmp' : α → α → LemOrdering}
    {k a : α} {v : β} {m : Fmap α β}
    (hm : FmapBuilt c m) (hk : c k a = .eq) :
    fmapLookupBy pcmp' a (fmapAddBy pcmp k v m) = some v := by
  cases m with
  | empty => exact absurd hm (by simp [FmapBuilt])
  | mk c' byKey bySeq n =>
    have hc : c' = c := hm
    subst hc
    simp only [fmapAddBy, fmapLookupBy]
    rw [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert,
      if_pos hk]

/-- Lookup after insert, captured-comparator-NE key: the underlying
    map's verdict (the skip law — St-v2's induction engine). -/
@[step_law (kind := envMap) (variant := skip) (side := omega)
  (frontier := "env/lookup-skip")
  (trace := "{law := fmapLookupBy_addBy_ne, joint := env/lookup, hyps := [hm : fed, hk : omega]}")
  (lineage := "lookup-over-insert skip: apartness makes the insert invisible (the induction engine of env walks)")]
theorem fmapLookupBy_addBy_ne {α β : Type} [BEq α]
    {c : α → α → Ordering} [Std.TransCmp c]
    {pcmp pcmp' : α → α → LemOrdering}
    {k a : α} {v : β} {m : Fmap α β}
    (hm : FmapBuilt c m) (hk : ¬ c k a = .eq) :
    fmapLookupBy pcmp' a (fmapAddBy pcmp k v m)
      = fmapLookupBy pcmp' a m := by
  cases m with
  | empty => exact absurd hm (by simp [FmapBuilt])
  | mk c' byKey bySeq n =>
    have hc : c' = c := hm
    subst hc
    simp only [fmapAddBy, fmapLookupBy]
    rw [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert,
      if_neg hk, ← Std.TreeMap.get?_eq_getElem?]

/-! ## Int-keyed TreeMap get?/insert laws (the bytemap engine) -/

theorem tmInt_get?_insert_self {β : Type}
    (t : Std.TreeMap Int β) (a : Int) (b : β) :
    (t.insert a b).get? a = some b := by
  rw [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert,
    if_pos (Std.LawfulEqCmp.compare_eq_iff_eq.mpr rfl)]

theorem tmInt_get?_insert_ne {β : Type}
    (t : Std.TreeMap Int β) {a a' : Int} (b : β) (h : a ≠ a') :
    (t.insert a b).get? a' = t.get? a' := by
  rw [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert,
    if_neg (fun hc => h (Std.LawfulEqCmp.eq_of_compare hc)),
    ← Std.TreeMap.get?_eq_getElem?]

end RelSem.Kit
