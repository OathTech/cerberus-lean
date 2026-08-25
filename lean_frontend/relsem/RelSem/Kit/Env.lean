/-
  RelSem.Kit.Env — arc-17 S2 (2026-08-25): THE ORDERED-MAP ENV ALGEBRA
  (charter S2 deliverable 2; the arc-16 S4-priced library).

  The lemma layer over the `symbol_compare`-keyed environment maps:
  lookup-through-insert under APARTNESS hypotheses — what every
  supply-reading program (the NEG/RMW store transform draws fresh
  symbols into comparison-keyed envs) needs before any ∀-seed
  statement can be proved. *Lineage (canon-first)*: ordered-map /
  finite-map reasoning as practiced in every mechanized-semantics
  library (HeapLang's gmap lemmas are the Iris-world instance); here
  instantiated against LemLib's tree-backed `Fmap` via Std.TreeMap's
  lemma suite.

  LAWFULNESS: the environment comparator (the generated closure
  `fun s1 s2 => ordCompare s1 s2` at `sym`) is a TOTAL PREORDER —
  `digest_compare` is honest String comparison and `ordCompare`'s
  equality arm resolves through the Eq0→BEq bridge to
  `symbolEquality` (digest+number, description-INSENSITIVE — the very
  property behind the arc-16 S4 collision falsifier). We prove it
  equal to a lexicographic model (`compareLex`/`compareOn` over
  String × Nat) and transfer core's `TransCmp` instances, which
  unlocks `Std.TreeMap.getElem?_insert` for the Fmap layer.

  HONESTY NOTE (rep-level commutation): two apartness-commuting
  inserts do NOT commute at the `Fmap` REPRESENTATION level — the
  implementation carries insertion sequence numbers (`counter`,
  `bySeq`), so swapped inserts give different (lookup-equivalent)
  representations. The "ordered-insert normal form" of the charter is
  therefore delivered at the LOOKUP level (`fmapLookupBy_addBy_*`
  fully characterize lookups through insert chains); a rep-level
  normal form would be false as stated.

  Import discipline (Kit design §6): no Iris, no fixtures (the
  proof-size gate scans this file exactly as the other Kit files).
  House rules: no sorry, no axioms declared here.
-/

import RelSem.Machine
import RelSem.Cerberus

set_option autoImplicit false

namespace RelSem.Kit

open Lem_Basic_classes (ordCompare)
open Std (TransCmp OrientedCmp)

/-! ## The comparator model and its lawfulness -/

/-- The environment comparator, as generated code spells it (the
    captured-closure form; `fmapAddBy (fun s1 s2 => ordCompare s1 s2)`
    everywhere in the Core evaluator's env updates). -/
def symEnvCmp : sym → sym → LemOrdering :=
  fun s1 s2 => ordCompare s1 s2

/-- The lexicographic MODEL: digest (String order) then number (Nat
    order); the description is not consulted (`symbolEquality`'s
    semantics — the S4 collision falsifier's mechanism, now load-
    bearing for lawfulness). -/
abbrev symCmpModel : sym → sym → Ordering :=
  compareLex
    (compareOn fun s : sym => match s with | .Symbol d _ _ => d)
    (compareOn fun s : sym => match s with | .Symbol _ n _ => n)

/-- The Eq0→BEq bridge at `sym`, reduced to its data content
    (digest-EQ and number-EQ; the description is NOT consulted, and
    the debug branch is dead at level 0 ≥ 5). -/
private theorem symEnvBeq_eq (d1 : String) (n1 : Nat)
    (sd1 : symbol_description) (d2 : String) (n2 : Nat)
    (sd2 : symbol_description) :
    (@BEq.beq sym (@Lem_Basic_classes.instBEqOfEq0 sym instEq0Sym_1)
        (Symbol d1 n1 sd1) (Symbol d2 n2 sd2))
      = ((CerberusFresh.digest_compare d1 d2 == 0) && (n1 == n2)) := by
  have hbody : (@BEq.beq sym
      (@Lem_Basic_classes.instBEqOfEq0 sym instEq0Sym_1)
      (Symbol d1 n1 sd1) (Symbol d2 n2 sd2))
      = (if (CerberusFresh.digest_compare d1 d2 == (0 : Int))
            && (n1 == n2) then
           if natGteb 0 5 && (sd1 != sd2) then
             match CerbDebug.print_debug_pure 5 []
                 (fun u => match u with
                   | () => String.append
                       "[Symbol.symbolEqual] suspicious equality ==> "
                       (String.append (show_symbol_description sd1)
                         (String.append " <-> "
                           (show_symbol_description sd2)))) with
             | () => true
           else true
         else false) := rfl
  rw [hbody]
  cases hC : ((CerberusFresh.digest_compare d1 d2 == (0 : Int))
      && (n1 == n2)) <;> simp [hC, natGteb]

/-- The comparator equals its model, pointwise. The `==` inside
    `ordCompare` resolves through the Eq0→BEq bridge to the sym Eq0
    instance (`symbolEquality` semantics — description-insensitive),
    which is what makes the comparator lawful at all. -/
theorem lemCmpToOrd_symEnvCmp_eq_model (a b : sym) :
    lemCmpToOrd symEnvCmp a b = symCmpModel a b := by
  rcases a with ⟨d1, n1, sd1⟩
  rcases b with ⟨d2, n2, sd2⟩
  have hsc : ∀ x y : String, Ord.compare x y = compareOfLessAndEq x y :=
    fun _ _ => rfl
  simp only [symEnvCmp, ordCompare, symCmpModel, compareLex, compareOn,
    lemCmpToOrd, Lem_Basic_classes.isLess, instOrd0Sym_1,
    symEnvBeq_eq, CerberusFresh.digest_compare, intLtb, natLtb,
    Lem_Basic_classes.instBEqOfEq0, Lem_Num.instEq0Nat_1,
    Lem_Num.instEq0Nat, Lem_Basic_classes.instBEqOfSetType,
    Lem_Basic_classes.instSetTypeOfOrd, Lem_Basic_classes.Eq0.isEqual,
    Lem_Basic_classes.SetType.setElemCompare, defaultCompare,
    hsc, compareOfLessAndEq]
  by_cases h1 : d1 < d2
  · simp [h1]
  · by_cases h2 : d1 = d2
    · subst h2
      have hbd : (@BEq.beq String
          (@instBEqOfDecidableEq String instDecidableEqString) d1 d1)
          = true := decide_eq_true rfl
      have hb : ∀ m1 m2 : Nat, (m1 == m2) = (match defaultCompare m1 m2 with
          | LemOrdering.EQ => true | _ => false) := fun _ _ => rfl
      rcases hc : compare n1 n2 with _ | _ | _
      · simp [h1, hbd, Nat.compare_eq_lt.mp hc]
      · rcases Nat.compare_eq_eq.mp hc with rfl
        simp [h1, hbd, hb, defaultCompare, hc, Nat.lt_irrefl]
      · simp [h1, hbd, hb, defaultCompare, hc,
          Nat.lt_asymm (Nat.compare_eq_gt.mp hc)]
    · have hbd : (@BEq.beq String
          (@instBEqOfDecidableEq String instDecidableEqString) d1 d2)
          = false := decide_eq_false h2
      simp [h1, h2, hbd]

/-- `TransCmp` transfer along a pointwise equality. -/
theorem transCmp_of_pointwise {α : Type} {f g : α → α → Ordering}
    (h : ∀ a b, f a b = g a b) [inst : TransCmp g] : TransCmp f where
  eq_swap {a b} := by rw [h, h]; exact inst.eq_swap
  isLE_trans {a b c} h1 h2 := by
    rw [h] at h1 h2 ⊢; exact inst.isLE_trans h1 h2

instance : TransCmp (lemCmpToOrd symEnvCmp) :=
  transCmp_of_pointwise lemCmpToOrd_symEnvCmp_eq_model

/-! ## LemOrdering bridges (inversion between the LemOrdering
    comparator and its Ordering image) -/

theorem lemCmpToOrd_eq_lt_iff {α : Type} {cmp : α → α → LemOrdering}
    {a b : α} : lemCmpToOrd cmp a b = .lt ↔ cmp a b = .LT := by
  cases h : cmp a b <;> simp [lemCmpToOrd, h]

theorem lemCmpToOrd_eq_eq_iff {α : Type} {cmp : α → α → LemOrdering}
    {a b : α} : lemCmpToOrd cmp a b = .eq ↔ cmp a b = .EQ := by
  cases h : cmp a b <;> simp [lemCmpToOrd, h]

theorem lemCmpToOrd_eq_gt_iff {α : Type} {cmp : α → α → LemOrdering}
    {a b : α} : lemCmpToOrd cmp a b = .gt ↔ cmp a b = .GT := by
  cases h : cmp a b <;> simp [lemCmpToOrd, h]

/-! ## The symbol apartness dischargers (what the seed-apartness
    hypothesis buys: same-digest symbols compare by NUMBER, and a
    number gap decides every env comparison the fresh draws force) -/

/-- Same-digest symbols compare by their numbers (descriptions never
    consulted). -/
theorem lemCmpToOrd_symEnvCmp_same_digest {d : String} {n1 n2 : Nat}
    {sd1 sd2 : symbol_description} :
    lemCmpToOrd symEnvCmp (Symbol d n1 sd1) (Symbol d n2 sd2)
      = compare n1 n2 := by
  rw [lemCmpToOrd_symEnvCmp_eq_model]
  simp [symCmpModel, compareLex, compareOn, Std.ReflCmp.compare_self,
    Ordering.then]

theorem symEnvCmp_LT_of_num_lt {d : String} {n1 n2 : Nat}
    {sd1 sd2 : symbol_description} (h : n1 < n2) :
    symEnvCmp (Symbol d n1 sd1) (Symbol d n2 sd2) = .LT :=
  lemCmpToOrd_eq_lt_iff.mp
    (lemCmpToOrd_symEnvCmp_same_digest.trans (Nat.compare_eq_lt.mpr h))

theorem symEnvCmp_GT_of_num_gt {d : String} {n1 n2 : Nat}
    {sd1 sd2 : symbol_description} (h : n2 < n1) :
    symEnvCmp (Symbol d n1 sd1) (Symbol d n2 sd2) = .GT :=
  lemCmpToOrd_eq_gt_iff.mp
    (lemCmpToOrd_symEnvCmp_same_digest.trans (Nat.compare_eq_gt.mpr h))

/-- The apartness face: a number gap refutes comparator-EQ (the side
    condition every lookup-past-insert application discharges). -/
theorem lemCmpToOrd_symEnvCmp_ne_eq_of_num_ne {d : String}
    {n1 n2 : Nat} {sd1 sd2 : symbol_description} (h : n1 ≠ n2) :
    lemCmpToOrd symEnvCmp (Symbol d n1 sd1) (Symbol d n2 sd2)
      ≠ .eq := by
  rw [lemCmpToOrd_symEnvCmp_same_digest]
  intro hc
  exact h (Nat.compare_eq_eq.mp hc)

/-! ## The Fmap layer: lookup through insert chains

    Stated at maps whose representation carries the canonical
    captured comparator (`Fmap.mk (lemCmpToOrd cmp) …` — every map
    built by `fmapAddBy cmp` chains from `fmapEmpty` has this shape,
    exposed by the rfl-grade unfold lemmas below). This is where the
    S4-diagnosed "kernel-stuck comparison" dissolves: a lookup walks
    PAST a symbolic-key insert by the apartness side condition instead
    of by computation. -/

/-- `fmapAddBy` at an empty map, unfolded (rfl; captures the
    comparator). -/
theorem fmapAddBy_empty {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) (k : α) (v : β) :
    fmapAddBy cmp k v (.empty : Fmap α β)
      = .mk (lemCmpToOrd cmp) (Std.TreeMap.empty.insert k [(0, k, v)])
          (Std.TreeMap.empty.insert 0 (k, v)) 1 := rfl

/-- `fmapAddBy` at a materialized map, unfolded (rfl — the rewrite
    handle that keeps symbolic-key insert chains in constructor
    form). -/
theorem fmapAddBy_mk {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) (k : α) (v : β)
    (c : α → α → Ordering)
    (bk : Std.TreeMap α (List (Nat × α × β)) c)
    (bs : Std.TreeMap Nat (α × β)) (n : Nat) :
    fmapAddBy cmp k v (.mk c bk bs n)
      = .mk c (bk.insert k ((n, k, v) ::
            ((bk.get? k).getD []).filter (fun e => !(e.2.1 == k))))
          (((((bk.get? k).getD []).filter (fun e => e.2.1 == k)).foldl
              (fun t e => t.erase e.1) bs).insert n (k, v))
          (n + 1) := rfl

/-- `fmapLookupBy` at a materialized map, unfolded (rfl). -/
theorem fmapLookupBy_mk {α β : Type}
    (cmp : α → α → LemOrdering) (k : α)
    (c : α → α → Ordering)
    (bk : Std.TreeMap α (List (Nat × α × β)) c)
    (bs : Std.TreeMap Nat (α × β)) (n : Nat) :
    fmapLookupBy cmp k (.mk c bk bs n)
      = (match bk.get? k with
         | some ((_, _, v) :: _) => some v
         | _ => none) := rfl

/-- THE PAYOFF: lookup through an insert, decided by the comparator
    verdict on the two keys — never by computing the tree. -/
theorem fmapLookupBy_addBy_mk {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) [TransCmp (lemCmpToOrd cmp)]
    (k k' : α) (v : β)
    (bk : Std.TreeMap α (List (Nat × α × β)) (lemCmpToOrd cmp))
    (bs : Std.TreeMap Nat (α × β)) (n : Nat) :
    fmapLookupBy cmp k (fmapAddBy cmp k' v (.mk (lemCmpToOrd cmp) bk bs n))
      = if lemCmpToOrd cmp k' k = .eq then some v
        else fmapLookupBy cmp k (.mk (lemCmpToOrd cmp) bk bs n) := by
  rw [fmapAddBy_mk, fmapLookupBy_mk, fmapLookupBy_mk]
  rw [show (bk.insert k' ((n, k', v) ::
        ((bk.get? k').getD []).filter (fun e => !(e.2.1 == k')))).get? k
      = (bk.insert k' ((n, k', v) ::
        ((bk.get? k').getD []).filter (fun e => !(e.2.1 == k'))))[k]?
      from rfl]
  rw [Std.TreeMap.getElem?_insert]
  by_cases hcm : lemCmpToOrd cmp k' k = .eq <;>
    simp [hcm, Std.TreeMap.get?_eq_getElem?]

/-- Lookup through an insert at the empty map. -/
theorem fmapLookupBy_addBy_empty {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) [TransCmp (lemCmpToOrd cmp)]
    (k k' : α) (v : β) :
    fmapLookupBy cmp k (fmapAddBy cmp k' v (.empty : Fmap α β))
      = if lemCmpToOrd cmp k' k = .eq then some v else none := by
  rw [fmapAddBy_empty, fmapLookupBy_mk]
  rw [show (Std.TreeMap.empty.insert k' [(0, k', v)]).get? k
      = (Std.TreeMap.empty.insert k' [(0, k', v)])[k]? from rfl]
  rw [Std.TreeMap.getElem?_insert]
  by_cases hcm : lemCmpToOrd cmp k' k = .eq <;> simp [hcm]

/-- Consumer face: an APART insert is invisible to the lookup. -/
theorem fmapLookupBy_addBy_apart {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) [TransCmp (lemCmpToOrd cmp)]
    {k k' : α} (v : β)
    (bk : Std.TreeMap α (List (Nat × α × β)) (lemCmpToOrd cmp))
    (bs : Std.TreeMap Nat (α × β)) (n : Nat)
    (h : lemCmpToOrd cmp k' k ≠ .eq) :
    fmapLookupBy cmp k (fmapAddBy cmp k' v (.mk (lemCmpToOrd cmp) bk bs n))
      = fmapLookupBy cmp k (.mk (lemCmpToOrd cmp) bk bs n) := by
  rw [fmapLookupBy_addBy_mk, if_neg h]

/-- Consumer face: the freshly inserted key reads back its value. -/
theorem fmapLookupBy_addBy_self {α β : Type} [BEq α]
    (cmp : α → α → LemOrdering) [TransCmp (lemCmpToOrd cmp)]
    {k k' : α} (v : β)
    (bk : Std.TreeMap α (List (Nat × α × β)) (lemCmpToOrd cmp))
    (bs : Std.TreeMap Nat (α × β)) (n : Nat)
    (h : lemCmpToOrd cmp k' k = .eq) :
    fmapLookupBy cmp k (fmapAddBy cmp k' v (.mk (lemCmpToOrd cmp) bk bs n))
      = some v := by
  rw [fmapLookupBy_addBy_mk, if_pos h]

end RelSem.Kit
