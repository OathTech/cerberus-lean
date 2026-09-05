/-
  CerbMem_lemMeasureProofs — the sufficiency theorems of the hand-written
  MEASURED wrappers of CerbMem.lean (fuel-parameter arc C2, 2026-09-04): the
  seam twins of the generated `fuel_measure` obligations, stated in the same
  shape (`<f>_measure_sufficient : <measure> ≤ lemFuel → f_lemFuel lemFuel … =
  f …`) and in the `CerbMem` namespace so scripts/check_fuel_forms.sh
  classifies the workers MEASURED by the same rule as the generated ones.

    typeofMval             measure `memValueSize mval`   (the MVarray head)
    unqualifyAndUnatomic   measure `ctype.lemSize cty`   (structural on the ctype)
    memValueToBytes        measure `memValueSize val_`   (MVarray/MVstruct/MVunion components;
                           the statement keeps `[LemFuel]` for the ambient layout oracle)

  Shape = the C2 template (Core_run_aux_lemMeasureProofs.lean): strong
  induction on the size bound; `key` rewrites the direct children; the list
  folds by membership-relative congruence (`to_congr`). Kernel-only tactics;
  no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import CerbMem
import CerbMeasureLemmas
import Ctype_lemMeasureProofs
import CerbTagsWf

set_option autoImplicit false

open CerbMeasureLemmas

namespace CerbMem

theorem typeofMval_stable_aux (k : Nat) : ∀ (v : MemValue) (f g : Nat),
    memValueSize v ≤ k → memValueSize v ≤ f → memValueSize v ≤ g →
    typeofMval_lemFuel f v = typeofMval_lemFuel g v := by
  induction k with
  | zero => intro v f g hk _ _; have := memValueSize_pos v; omega
  | succ k ih =>
    intro v f g hk hf hg
    cases f with
    | zero => have := memValueSize_pos v; omega
    | succ f =>
      cases g with
      | zero => have := memValueSize_pos v; omega
      | succ g =>
        have key : ∀ (y : MemValue), memValueSize y < memValueSize v →
            typeofMval_lemFuel f y = typeofMval_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        cases v <;> simp only [typeofMval_lemFuel]
        case MVunspecified c => obtain ⟨an, ty⟩ := c; rfl
        case MVarray vals =>
          cases vals <;> simp (disch := size_lt) only [key]

/-- THE OBLIGATION (the seam twin of the generated shape). -/
theorem typeofMval_measure_sufficient (mval : MemValue) (lemFuel : Nat)
    (lemMeasureLe : memValueSize mval ≤ lemFuel) :
    typeofMval_lemFuel lemFuel mval = typeofMval mval :=
  typeofMval_stable_aux (memValueSize mval) mval lemFuel (memValueSize mval) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem unqualifyAndUnatomic_stable_aux (k : Nat) : ∀ (c : ctype) (f g : Nat),
    ctype.lemSize c ≤ k → ctype.lemSize c ≤ f → ctype.lemSize c ≤ g →
    unqualifyAndUnatomic_lemFuel f c = unqualifyAndUnatomic_lemFuel g c := by
  induction k with
  | zero => intro c f g hk _ _; have := ctype_lemSize_pos c; omega
  | succ k ih =>
    intro c f g hk hf hg
    cases f with
    | zero => have := ctype_lemSize_pos c; omega
    | succ f =>
      cases g with
      | zero => have := ctype_lemSize_pos c; omega
      | succ g =>
        have key : ∀ (y : ctype), ctype.lemSize y < ctype.lemSize c →
            unqualifyAndUnatomic_lemFuel f y = unqualifyAndUnatomic_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        obtain ⟨an, ty⟩ := c
        cases ty <;> simp (disch := size_lt) only [unqualifyAndUnatomic_lemFuel, key]
        case Function qr params variadic =>
          to_congr
          all_goals
            intro p hp
            obtain ⟨q', t', b'⟩ := p
            dsimp only
            rw [key t' (by have := Ctype_lemMeasureProofs.ctype_param_lt t' q' b' _ hp; size_lt)]

/-- THE OBLIGATION (the seam twin of the generated shape). -/
theorem unqualifyAndUnatomic_measure_sufficient (cty : ctype) (lemFuel : Nat)
    (lemMeasureLe : ctype.lemSize cty ≤ lemFuel) :
    unqualifyAndUnatomic_lemFuel lemFuel cty = unqualifyAndUnatomic cty :=
  unqualifyAndUnatomic_stable_aux (ctype.lemSize cty) cty lemFuel (ctype.lemSize cty) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem memValueToBytes_stable_aux [LemFuel] (k : Nat) :
    ∀ (ambient : CerbTags.TagDefsMap) (funptrmap : Funptrmap) (v : MemValue) (f g : Nat),
    memValueSize v ≤ k → memValueSize v ≤ f → memValueSize v ≤ g →
    memValueToBytes_lemFuel f ambient funptrmap v = memValueToBytes_lemFuel g ambient funptrmap v := by
  induction k with
  | zero => intro ambient funptrmap v f g hk _ _; have := memValueSize_pos v; omega
  | succ k ih =>
    intro ambient funptrmap v f g hk hf hg
    cases f with
    | zero => have := memValueSize_pos v; omega
    | succ f =>
      cases g with
      | zero => have := memValueSize_pos v; omega
      | succ g =>
        have key : ∀ (fpm : Funptrmap) (y : MemValue), memValueSize y < memValueSize v →
            memValueToBytes_lemFuel f ambient fpm y = memValueToBytes_lemFuel g ambient fpm y :=
          fun fpm y hy => ih ambient fpm y f g (by omega) (by omega) (by omega)
        cases v <;> simp (disch := size_lt) only [memValueToBytes_lemFuel, key]
        case MVarray elems =>
          to_congr
          all_goals
            intro acc mval hm
            obtain ⟨fpm, bss⟩ := acc
            dsimp only
            rw [key fpm mval (by have := memValue_mem_lt_list mval _ hm; size_lt)]
        case MVstruct tagSym members =>
          to_congr
          all_goals
            intro acc p hp
            obtain ⟨fpm, lastOff, revChunks⟩ := acc
            obtain ⟨⟨i1, ty, off⟩, ⟨i2, t2, mval⟩⟩ := p
            have hm := (List.of_mem_zip hp).2
            dsimp only
            rw [key fpm mval (by have := memValue_mem_lt_members i2 t2 mval _ hm; size_lt)]

/-- THE OBLIGATION (the seam twin of the generated shape; `[LemFuel]` for the
    ambient layout oracle the body reads). -/
theorem memValueToBytes_measure_sufficient [LemFuel] (ambient : CerbTags.TagDefsMap) (funptrmap : Funptrmap)
    (val_ : MemValue) (lemFuel : Nat) (lemMeasureLe : memValueSize val_ ≤ lemFuel) :
    memValueToBytes_lemFuel lemFuel ambient funptrmap val_ = memValueToBytes ambient funptrmap val_ :=
  memValueToBytes_stable_aux (memValueSize val_) ambient funptrmap val_ lemFuel (memValueSize val_)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)


/-! ## C4: the layout oracle under the acyclicity hypothesis

    The five layout workers (memberAlign / offsetsofMembers / offsetsof /
    sizeofCtype / alignofCtype) recurse through tag lookups; the hypothesis
    `CerbTagsWf.Acyclic`/`AcyclicPair` supplies a rank `R` on entries that
    descends along every by-value reference. The proof's POTENTIAL of a ctype
    is its structural size plus, when its head (through arrays/atomics) is a
    tag that resolves, the WEIGHT `W v` of the entries ranked at most that
    entry — so a member's potential is smaller than its struct's by at least
    that struct's own weight term, which is the fuel the hop costs. The five
    measures are then `pot`, `pot + 1`, `mPot + 1`, `membersPot + 2`,
    `oPot`; stability above them is one joint strong induction (the C2/C3
    template); the wrappers' concrete measures (CerbTagsWf.envBound & co.)
    dominate the potentials because every filtered weight is at most the
    whole environment's weight. -/

section Layout
open CerbTagsWf

variable (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry)

/-- The weight of the entries of `L` ranked at most `v`. -/
def W (v : Entry) : Nat :=
  ((L.filter (fun v' => decide (R v' ≤ R v))).map (fun v' => defSize v'.2 + 2)).sum

/-- The tag potential of a ctype: the weight of the entry its head tag
    resolves to (struct tags in `tagDefs`, union tags in `ambient`). -/
def tp : ctype → Nat
  | Ctype _ (.Struct t) => match lookup tagDefs t with | some v => W R L v | none => 0
  | Ctype _ (.Union0 t) => match lookup ambient t with | some v => W R L v | none => 0
  | Ctype _ (.Array0 c _) => tp c
  | Ctype _ (.Atomic c) => tp c
  | Ctype _ _ => 0

def pot (ty : ctype) : Nat := ctype.lemSize ty + tp ambient tagDefs R L ty

def alignPot : Option alignment → Nat
  | some (AlignType a) => pot ambient tagDefs R L a
  | _ => 0

def mPot (al : Option alignment) (ty : ctype) : Nat :=
  max (pot ambient tagDefs R L ty) (alignPot ambient tagDefs R L al)

def membersPot : List Member → Nat
  | [] => 0
  | mb :: rest => max (mPot ambient tagDefs R L mb.2.2.1 mb.2.2.2.2) (membersPot rest)

/-- The member list `offsetsof` folds over (its `let membrs := …`). -/
def structMembers (membrs : List Member) (flex : Option flexible_array_member) (ignoreFlexible : Bool) : List Member :=
  match flex with
  | none => membrs
  | some (FlexibleArrayMember attrs ident qs ty) =>
    if ignoreFlexible then membrs else membrs ++ [(ident, (attrs, none, qs, ty))]

def oPot (t : sym) (ignoreFlexible : Bool) : Nat :=
  match lookup tagDefs t with
  | some (_, StructDef membrs flex) => membersPot ambient tagDefs R L (structMembers membrs flex ignoreFlexible) + 3
  | _ => 1

/-! ### Weight lemmas -/

theorem W_nil (v : Entry) : W R [] v = 0 := rfl

theorem W_cons (x : Entry) (xs : List Entry) (v : Entry) :
    W R (x :: xs) v = (if R x ≤ R v then defSize x.2 + 2 else 0) + W R xs v := by
  simp only [W, List.filter_cons]
  by_cases h : R x ≤ R v
  · simp [h]
  · simp [h]

theorem W_le_total (v : Entry) : W R L v ≤ (L.map (fun v' => defSize v'.2 + 2)).sum := by
  induction L with
  | nil => simp [W_nil]
  | cons x xs ih =>
    rw [W_cons]; simp only [List.map_cons, List.sum_cons]
    split <;> omega

theorem W_mono {v v' : Entry} (h : R v' ≤ R v) : W R L v' ≤ W R L v := by
  induction L with
  | nil => simp [W_nil]
  | cons x xs ih =>
    rw [W_cons, W_cons]
    by_cases h1 : R x ≤ R v'
    · have h2 : R x ≤ R v := Nat.le_trans h1 h
      simp only [h1, h2, ↓reduceIte]; omega
    · simp only [h1, ↓reduceIte]; split <;> omega

theorem W_self {v : Entry} (hv : v ∈ L) : defSize v.2 + 2 ≤ W R L v := by
  induction L with
  | nil => cases hv
  | cons x xs ih =>
    rw [W_cons]
    rcases List.mem_cons.mp hv with h | hv'
    · rw [h]; simp only [Nat.le_refl, ↓reduceIte]; omega
    · have := ih hv'; split <;> omega

/-- The hop inequality: an entry ranked below `v ∈ L` weighs at least `v`'s own term less. -/
theorem W_step {v v' : Entry} (hv : v ∈ L) (h : R v' < R v) : W R L v' + (defSize v.2 + 2) ≤ W R L v := by
  induction L with
  | nil => cases hv
  | cons x xs ih =>
    rw [W_cons, W_cons]
    rcases List.mem_cons.mp hv with hx | hv'
    · rw [hx] at h ⊢
      have h1 : ¬ (R x ≤ R v') := by omega
      simp only [h1, Nat.le_refl, ↓reduceIte]
      have := W_mono R xs (Nat.le_of_lt h)
      omega
    · have := ih hv'
      by_cases h1 : R x ≤ R v'
      · have h2 : R x ≤ R v := by omega
        simp only [h1, h2, ↓reduceIte]; omega
      · simp only [h1, ↓reduceIte]; split <;> omega

/-! ### Potential lemmas -/

theorem pot_pos (ty : ctype) : 1 ≤ pot ambient tagDefs R L ty := by
  unfold pot; have := CerbMeasureLemmas.ctype_lemSize_pos ty; omega

theorem pot_array (an : List annot) (c : ctype) (n : Option Int) :
    pot ambient tagDefs R L (Ctype an (.Array0 c n)) = pot ambient tagDefs R L c + 2 := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize]; omega

theorem pot_atomic (an : List annot) (c : ctype) :
    pot ambient tagDefs R L (Ctype an (.Atomic c)) = pot ambient tagDefs R L c + 2 := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize]; omega

theorem pot_struct (an : List annot) (t : sym) (v : Entry) (h : lookup tagDefs t = some v) :
    pot ambient tagDefs R L (Ctype an (.Struct t)) = 2 + W R L v := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize, h]

theorem pot_struct_none (an : List annot) (t : sym) (h : lookup tagDefs t = none) :
    pot ambient tagDefs R L (Ctype an (.Struct t)) = 2 := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize, h]

theorem pot_union (an : List annot) (t : sym) (v : Entry) (h : lookup ambient t = some v) :
    pot ambient tagDefs R L (Ctype an (.Union0 t)) = 2 + W R L v := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize, h]

theorem pot_union_none (an : List annot) (t : sym) (h : lookup ambient t = none) :
    pot ambient tagDefs R L (Ctype an (.Union0 t)) = 2 := by
  simp only [pot, tp, ctype.lemSize, ctype_.lemSize, h]

/-- A ctype's tag potential is 0 or the weight of an entry one of its by-value
    references resolves to. -/
theorem tp_spec : ∀ (y : ctype), tp ambient tagDefs R L y = 0 ∨
    ∃ t' ∈ refsOf y, ∃ v' : Entry, (lookup tagDefs t' = some v' ∨ lookup ambient t' = some v') ∧
      tp ambient tagDefs R L y = W R L v'
  | Ctype _ (.Struct t) => by
    simp only [tp, refsOf]
    cases h : lookup tagDefs t with
    | none => exact Or.inl rfl
    | some v => exact Or.inr ⟨t, List.mem_singleton_self t, v, Or.inl h, rfl⟩
  | Ctype _ (.Union0 t) => by
    simp only [tp, refsOf]
    cases h : lookup ambient t with
    | none => exact Or.inl rfl
    | some v => exact Or.inr ⟨t, List.mem_singleton_self t, v, Or.inr h, rfl⟩
  | Ctype _ (.Array0 c _) => by simp only [tp, refsOf]; exact tp_spec c
  | Ctype _ (.Atomic c) => by simp only [tp, refsOf]; exact tp_spec c
  | Ctype _ .Void0 => Or.inl rfl
  | Ctype _ (.Basic _) => Or.inl rfl
  | Ctype _ (.Function _ _ _) => Or.inl rfl
  | Ctype _ (.FunctionNoParams _) => Or.inl rfl
  | Ctype _ (.Pointer _ _) => Or.inl rfl
  | Ctype _ .Byte => Or.inl rfl

theorem le_sum_of_mem {α : Type} (f : α → Nat) {x : α} {l : List α} (h : x ∈ l) : f x ≤ (l.map f).sum := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    simp only [List.map_cons, List.sum_cons]
    rcases List.mem_cons.mp h with rfl | h'
    · omega
    · have := ih h'; omega

/-- The hypothesis at work: a type a definition makes the recursion enter has
    potential at least two below its entry's weight. -/
theorem pot_member (hR : Ranked (lookup tagDefs) (lookup ambient) R)
    (hLS : ∀ t v, lookup tagDefs t = some v → v ∈ L) (hLU : ∀ t v, lookup ambient t = some v → v ∈ L)
    {t : sym} {v : Entry} (hv : lookup tagDefs t = some v ∨ lookup ambient t = some v)
    {y : ctype} (hy : y ∈ memberTypes v.2) : pot ambient tagDefs R L y + 2 ≤ W R L v := by
  have hvL : v ∈ L := by rcases hv with h | h; exact hLS _ _ h; exact hLU _ _ h
  have hsize : ctype.lemSize y ≤ defSize v.2 := le_sum_of_mem ctype.lemSize hy
  unfold pot
  rcases tp_spec ambient tagDefs R L y with h0 | ⟨t', ht', v', hv', htp⟩
  · have := W_self R L hvL; omega
  · have hmem : t' ∈ refsOfDef v.2 := List.mem_flatMap.mpr ⟨y, hy, ht'⟩
    have hlt := hR t v hv t' hmem v' hv'
    have := W_step R L hvL hlt
    omega

theorem mem_memberTypes1_ty (mb : Member) : mb.2.2.2.2 ∈ memberTypes1 mb := by
  obtain ⟨i, at_, al, q, ty⟩ := mb; simp [memberTypes1]

theorem mem_memberTypes1_align (mb : Member) (a : ctype) (h : mb.2.2.1 = some (AlignType a)) : a ∈ memberTypes1 mb := by
  obtain ⟨i, at_, al, q, ty⟩ := mb; simp only at h; subst h; simp [memberTypes1, alignTypes]

theorem mem_memberTypes_of_struct (membrs : List Member) (flex : Option flexible_array_member) {y : ctype}
    (h : ∃ mb ∈ membrs, y ∈ memberTypes1 mb) : y ∈ memberTypes (StructDef membrs flex) := by
  cases flex with
  | none => simp only [memberTypes]; exact List.mem_flatMap.mpr h
  | some fl => obtain ⟨_, _, _, _⟩ := fl; simp only [memberTypes]; exact List.mem_append.mpr (Or.inl (List.mem_flatMap.mpr h))

theorem mem_memberTypes_of_union (membrs : List Member) {y : ctype}
    (h : ∃ mb ∈ membrs, y ∈ memberTypes1 mb) : y ∈ memberTypes (UnionDef membrs) := by
  simp only [memberTypes]; exact List.mem_flatMap.mpr h

theorem mem_memberTypes_flex (membrs : List Member) (attrs : attributes) (ident : identifier) (qs : qualifiers) (elemTy : ctype) :
    elemTy ∈ memberTypes (StructDef membrs (some (FlexibleArrayMember attrs ident qs elemTy))) := by
  simp [memberTypes]

/-- The alignment potential of a member is bounded like its type's. -/
theorem alignPot_le (hR : Ranked (lookup tagDefs) (lookup ambient) R)
    (hLS : ∀ t v, lookup tagDefs t = some v → v ∈ L) (hLU : ∀ t v, lookup ambient t = some v → v ∈ L)
    {t : sym} {v : Entry} (hv : lookup tagDefs t = some v ∨ lookup ambient t = some v)
    {mb : Member} (hmb : ∀ y ∈ memberTypes1 mb, y ∈ memberTypes v.2) :
    alignPot ambient tagDefs R L mb.2.2.1 + 2 ≤ W R L v := by
  have hvL : v ∈ L := by rcases hv with h | h; exact hLS _ _ h; exact hLU _ _ h
  cases hal : mb.2.2.1 with
  | none => simp only [alignPot]; have := W_self R L hvL; omega
  | some al =>
    cases al with
    | AlignInteger _ => simp only [alignPot]; have := W_self R L hvL; omega
    | AlignType a =>
      simp only [alignPot]
      exact pot_member ambient tagDefs R L hR hLS hLU hv (hmb a (mem_memberTypes1_align mb a hal))

theorem mPot_le (hR : Ranked (lookup tagDefs) (lookup ambient) R)
    (hLS : ∀ t v, lookup tagDefs t = some v → v ∈ L) (hLU : ∀ t v, lookup ambient t = some v → v ∈ L)
    {t : sym} {v : Entry} (hv : lookup tagDefs t = some v ∨ lookup ambient t = some v)
    {mb : Member} (hmb : ∀ y ∈ memberTypes1 mb, y ∈ memberTypes v.2) :
    mPot ambient tagDefs R L mb.2.2.1 mb.2.2.2.2 + 2 ≤ W R L v := by
  have h1 := pot_member ambient tagDefs R L hR hLS hLU hv (hmb _ (mem_memberTypes1_ty mb))
  have h2 := alignPot_le ambient tagDefs R L hR hLS hLU hv hmb
  unfold mPot; omega

theorem mPot_le_membersPot {mb : Member} {members : List Member} (h : mb ∈ members) :
    mPot ambient tagDefs R L mb.2.2.1 mb.2.2.2.2 ≤ membersPot ambient tagDefs R L members := by
  induction members with
  | nil => cases h
  | cons x xs ih =>
    simp only [membersPot]
    rcases List.mem_cons.mp h with rfl | h'
    · omega
    · have := ih h'; omega

theorem membersPot_le (members : List Member) (bound : Nat) (hb : 2 ≤ bound)
    (h : ∀ mb ∈ members, mPot ambient tagDefs R L mb.2.2.1 mb.2.2.2.2 + 2 ≤ bound) :
    membersPot ambient tagDefs R L members + 2 ≤ bound := by
  induction members with
  | nil => simp only [membersPot]; omega
  | cons x xs ih =>
    simp only [membersPot]
    have := h x (List.mem_cons_self ..)
    have := ih (fun mb hmb => h mb (List.mem_cons_of_mem _ hmb))
    omega

/-- Every member the struct fold visits (flexible member appended or not)
    has its types among the definition's `memberTypes`. -/
theorem structMembers_types (membrs : List Member) (flex : Option flexible_array_member) (flag : Bool)
    {mb : Member} (h : mb ∈ structMembers membrs flex flag) :
    ∀ y ∈ memberTypes1 mb, y ∈ memberTypes (StructDef membrs flex) := by
  intro y hy
  cases flex with
  | none => exact mem_memberTypes_of_struct membrs none ⟨mb, h, hy⟩
  | some fl =>
    obtain ⟨attrs, ident, qs, elemTy⟩ := fl
    simp only [structMembers] at h
    split at h
    · exact mem_memberTypes_of_struct membrs _ ⟨mb, h, hy⟩
    · rcases List.mem_append.mp h with h' | h'
      · exact mem_memberTypes_of_struct membrs _ ⟨mb, h', hy⟩
      · simp only [List.mem_singleton] at h'
        subst h'
        simp only [memberTypes1, alignTypes, List.mem_cons, List.not_mem_nil, or_false] at hy
        rw [hy]
        exact mem_memberTypes_flex membrs attrs ident qs elemTy

end Layout

section LayoutStable
open CerbTagsWf

variable (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry)

theorem lookup_of_entry {m : CerbTags.TagDefsMap} {t s : sym} {v : Entry}
    (h : lookupEntry m t = some (s, v)) : lookup m t = some v := by
  simp [lookup, h]

theorem oPot_of_struct {t : sym} {l : CerbLocation.Loc} {membrs : List Member} {flex : Option flexible_array_member}
    (h : lookup tagDefs t = some (l, StructDef membrs flex)) (flag : Bool) :
    oPot ambient tagDefs R L t flag = membersPot ambient tagDefs R L (structMembers membrs flex flag) + 3 := by
  simp [oPot, h]

theorem oPot_of_union {t : sym} {l : CerbLocation.Loc} {membrs : List Member}
    (h : lookup tagDefs t = some (l, UnionDef membrs)) (flag : Bool) : oPot ambient tagDefs R L t flag = 1 := by
  simp [oPot, h]

theorem oPot_of_none {t : sym} (h : lookup tagDefs t = none) (flag : Bool) : oPot ambient tagDefs R L t flag = 1 := by
  simp [oPot, h]

theorem oPot_pos (t : sym) (flag : Bool) : 1 ≤ oPot ambient tagDefs R L t flag := by
  unfold oPot; split <;> omega

theorem pot_mkArray (c : ctype) :
    pot ambient tagDefs R L (mkCtype (.Array0 c none)) = pot ambient tagDefs R L c + 2 := by
  unfold mkCtype; exact pot_array ambient tagDefs R L [] c none

/-- Stability of the five layout workers above their potentials: one joint
    strong induction on the bound `k` (the C2/C3 template, five parts). -/
theorem layout_stable_aux
    (hR : Ranked (lookup tagDefs) (lookup ambient) R)
    (hLS : ∀ t v, lookup tagDefs t = some v → v ∈ L) (hLU : ∀ t v, lookup ambient t = some v → v ∈ L)
    (k : Nat) :
    (∀ (ty : ctype) (f g : Nat), pot ambient tagDefs R L ty ≤ k →
        pot ambient tagDefs R L ty ≤ f → pot ambient tagDefs R L ty ≤ g →
        alignofCtype_lemFuel f ambient tagDefs ty = alignofCtype_lemFuel g ambient tagDefs ty) ∧
    (∀ (ty : ctype) (f g : Nat), pot ambient tagDefs R L ty + 1 ≤ k →
        pot ambient tagDefs R L ty + 1 ≤ f → pot ambient tagDefs R L ty + 1 ≤ g →
        sizeofCtype_lemFuel f ambient tagDefs ty = sizeofCtype_lemFuel g ambient tagDefs ty) ∧
    (∀ (al : Option alignment) (ty : ctype) (f g : Nat), mPot ambient tagDefs R L al ty + 1 ≤ k →
        mPot ambient tagDefs R L al ty + 1 ≤ f → mPot ambient tagDefs R L al ty + 1 ≤ g →
        memberAlign_lemFuel f ambient tagDefs al ty = memberAlign_lemFuel g ambient tagDefs al ty) ∧
    (∀ (members : List Member) (f g : Nat), membersPot ambient tagDefs R L members + 2 ≤ k →
        membersPot ambient tagDefs R L members + 2 ≤ f → membersPot ambient tagDefs R L members + 2 ≤ g →
        offsetsofMembers_lemFuel f ambient tagDefs members = offsetsofMembers_lemFuel g ambient tagDefs members) ∧
    (∀ (t : sym) (flag : Bool) (f g : Nat), oPot ambient tagDefs R L t flag ≤ k →
        oPot ambient tagDefs R L t flag ≤ f → oPot ambient tagDefs R L t flag ≤ g →
        offsetsof_lemFuel f ambient tagDefs t flag = offsetsof_lemFuel g ambient tagDefs t flag) := by
  induction k with
  | zero =>
    refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · intro ty f g hk _ _; have := pot_pos ambient tagDefs R L ty; omega
    · intro ty f g hk _ _; omega
    · intro al ty f g hk _ _; omega
    · intro members f g hk _ _; omega
    · intro t flag f g hk _ _; have := oPot_pos ambient tagDefs R L t flag; omega
  | succ k ih =>
    obtain ⟨ihA, ihZ, ihM, ihOM, ihO⟩ := ih
    refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · -- alignofCtype
      intro ty f g hk hf hg
      have hpos := pot_pos ambient tagDefs R L ty
      cases f with
      | zero => omega
      | succ f =>
      cases g with
      | zero => omega
      | succ g =>
      obtain ⟨an, ty_⟩ := ty
      cases ty_ <;> simp only [alignofCtype_lemFuel]
      case Basic bty => cases bty <;> rfl
      case Array0 c n =>
        rw [pot_array] at hk hf hg
        exact ihA c f g (by omega) (by omega) (by omega)
      case Atomic c =>
        rw [pot_atomic] at hk hf hg
        exact ihA c f g (by omega) (by omega) (by omega)
      case Struct t =>
        split
        · rename_i s l membrs flex heq
          have hl : lookup tagDefs t = some (l, StructDef membrs flex) := lookup_of_entry heq
          rw [pot_struct ambient tagDefs R L an t _ hl] at hk hf hg
          have hcong : ∀ (acc : Nat) (memb : Member), memb ∈ membrs →
              max (memberAlign_lemFuel f ambient tagDefs memb.2.2.1 memb.2.2.2.2) acc =
              max (memberAlign_lemFuel g ambient tagDefs memb.2.2.1 memb.2.2.2.2) acc := by
            intro acc memb hmemb
            have hm := mPot_le ambient tagDefs R L hR hLS hLU (Or.inl hl)
              (fun y hy => mem_memberTypes_of_struct membrs flex ⟨memb, hmemb, hy⟩)
            rw [ihM memb.2.2.1 memb.2.2.2.2 f g (by omega) (by omega) (by omega)]
          cases flex with
          | none =>
            simp only
            exact lfoldl_congr membrs _ _ hcong _
          | some fl =>
            obtain ⟨attrs, ident, qs, elemTy⟩ := fl
            simp only
            have hm := pot_member ambient tagDefs R L hR hLS hLU (Or.inl hl)
              (mem_memberTypes_flex membrs attrs ident qs elemTy)
            rw [ihA (mkCtype (.Array0 elemTy none)) f g (by rw [pot_mkArray]; omega)
              (by rw [pot_mkArray]; omega) (by rw [pot_mkArray]; omega)]
            exact lfoldl_congr membrs _ _ hcong _
        · rfl
      case Union0 t =>
        split
        · rename_i s l membrs heq
          have hl : lookup ambient t = some (l, UnionDef membrs) := lookup_of_entry heq
          rw [pot_union ambient tagDefs R L an t _ hl] at hk hf hg
          apply lfoldl_congr
          intro acc memb hmemb
          obtain ⟨ident, at_, al, q, ty⟩ := memb
          dsimp only
          have hm := mPot_le ambient tagDefs R L hR hLS hLU (Or.inr hl)
            (fun y hy => mem_memberTypes_of_union membrs ⟨(ident, (at_, al, q, ty)), hmemb, hy⟩)
          simp only at hm
          rw [ihM al ty f g (by omega) (by omega) (by omega)]
        · rfl
    · -- sizeofCtype
      intro ty f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
      cases g with
      | zero => omega
      | succ g =>
      obtain ⟨an, ty_⟩ := ty
      cases ty_ <;> simp only [sizeofCtype_lemFuel]
      case Basic bty => cases bty <;> rfl
      case Array0 c n =>
        cases n with
        | none => rfl
        | some n =>
          simp only
          rw [pot_array] at hk hf hg
          rw [ihZ c f g (by omega) (by omega) (by omega)]
      case Atomic c =>
        rw [pot_atomic] at hk hf hg
        exact ihZ c f g (by omega) (by omega) (by omega)
      case Struct t =>
        have hA := ihA (Ctype an (.Struct t)) f g (by omega) (by omega) (by omega)
        rw [hA]
        have hO : offsetsof_lemFuel f ambient tagDefs t true = offsetsof_lemFuel g ambient tagDefs t true := by
          rcases hl : lookup tagDefs t with _ | ⟨l, d⟩
          · rw [pot_struct_none ambient tagDefs R L an t hl] at hk hf hg
            exact ihO t true f g (by rw [oPot_of_none ambient tagDefs R L hl]; omega)
              (by rw [oPot_of_none ambient tagDefs R L hl]; omega) (by rw [oPot_of_none ambient tagDefs R L hl]; omega)
          · rw [pot_struct ambient tagDefs R L an t _ hl] at hk hf hg
            cases d with
            | StructDef membrs flex =>
              have hmp := membersPot_le ambient tagDefs R L (structMembers membrs flex true) (W R L (l, StructDef membrs flex))
                (by have := W_self R L (hLS _ _ hl); omega)
                (fun mb hmb => mPot_le ambient tagDefs R L hR hLS hLU (Or.inl hl) (structMembers_types membrs flex true hmb))
              exact ihO t true f g (by rw [oPot_of_struct ambient tagDefs R L hl]; omega)
                (by rw [oPot_of_struct ambient tagDefs R L hl]; omega) (by rw [oPot_of_struct ambient tagDefs R L hl]; omega)
            | UnionDef membrs =>
              exact ihO t true f g (by rw [oPot_of_union ambient tagDefs R L hl]; omega)
                (by rw [oPot_of_union ambient tagDefs R L hl]; omega) (by rw [oPot_of_union ambient tagDefs R L hl]; omega)
        rw [hO]
      case Union0 t =>
        split
        · rename_i s l membrs heq
          have hl : lookup ambient t = some (l, UnionDef membrs) := lookup_of_entry heq
          rw [pot_union ambient tagDefs R L an t _ hl] at hk hf hg
          have hfold : ∀ (init : Nat × Nat), membrs.foldl (fun (acc : Nat × Nat) memb =>
              let (accSize, accAlign) := acc
              let (_, (_, alignOpt, _, ty)) := memb
              (max accSize (sizeofCtype_lemFuel f ambient tagDefs ty),
               max accAlign (memberAlign_lemFuel f ambient tagDefs alignOpt ty))) init =
            membrs.foldl (fun (acc : Nat × Nat) memb =>
              let (accSize, accAlign) := acc
              let (_, (_, alignOpt, _, ty)) := memb
              (max accSize (sizeofCtype_lemFuel g ambient tagDefs ty),
               max accAlign (memberAlign_lemFuel g ambient tagDefs alignOpt ty))) init := by
            apply lfoldl_congr
            intro acc memb hmemb
            obtain ⟨accSize, accAlign⟩ := acc
            obtain ⟨ident, at_, al, q, ty⟩ := memb
            dsimp only
            have hm := mPot_le ambient tagDefs R L hR hLS hLU (Or.inr hl)
              (fun y hy => mem_memberTypes_of_union membrs ⟨(ident, (at_, al, q, ty)), hmemb, hy⟩)
            simp only at hm
            have hp : pot ambient tagDefs R L ty ≤ mPot ambient tagDefs R L al ty := Nat.le_max_left _ _
            rw [ihZ ty f g (by omega) (by omega) (by omega), ihM al ty f g (by omega) (by omega) (by omega)]
          rw [hfold]
        · rfl
    · -- memberAlign
      intro al ty f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
      cases g with
      | zero => omega
      | succ g =>
      cases al with
      | none =>
        simp only [memberAlign_lemFuel, mPot, alignPot, Nat.max_zero] at *
        exact ihA ty f g (by omega) (by omega) (by omega)
      | some al =>
        cases al with
        | AlignInteger n => simp only [memberAlign_lemFuel]
        | AlignType a =>
          simp only [memberAlign_lemFuel, mPot, alignPot] at *
          have := Nat.le_max_right (pot ambient tagDefs R L ty) (pot ambient tagDefs R L a)
          exact ihA a f g (by omega) (by omega) (by omega)
    · -- offsetsofMembers
      intro members f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
      cases g with
      | zero => omega
      | succ g =>
      simp only [offsetsofMembers_lemFuel]
      have hfold : ∀ (init : List (identifier × ctype × Nat) × Nat), members.foldl (fun (acc : List (identifier × ctype × Nat) × Nat) memb =>
          let (xs, lastOffset) := acc
          let (ident, (_, alignOpt, _, ty)) := memb
          let size := sizeofCtype_lemFuel f ambient tagDefs ty
          let align := memberAlign_lemFuel f ambient tagDefs alignOpt ty
          let x := lastOffset % align
          let pad := if x == 0 then 0 else align - x
          ((ident, ty, lastOffset + pad) :: xs, lastOffset + pad + size)) init =
        members.foldl (fun (acc : List (identifier × ctype × Nat) × Nat) memb =>
          let (xs, lastOffset) := acc
          let (ident, (_, alignOpt, _, ty)) := memb
          let size := sizeofCtype_lemFuel g ambient tagDefs ty
          let align := memberAlign_lemFuel g ambient tagDefs alignOpt ty
          let x := lastOffset % align
          let pad := if x == 0 then 0 else align - x
          ((ident, ty, lastOffset + pad) :: xs, lastOffset + pad + size)) init := by
        apply lfoldl_congr
        intro acc memb hmemb
        obtain ⟨xs, lastOffset⟩ := acc
        obtain ⟨ident, at_, al, q, ty⟩ := memb
        dsimp only
        have hm := mPot_le_membersPot ambient tagDefs R L hmemb
        simp only at hm
        have hp : pot ambient tagDefs R L ty ≤ mPot ambient tagDefs R L al ty := Nat.le_max_left _ _
        rw [ihZ ty f g (by omega) (by omega) (by omega), ihM al ty f g (by omega) (by omega) (by omega)]
      rw [hfold]
    · -- offsetsof
      intro t flag f g hk hf hg
      have hpos := oPot_pos ambient tagDefs R L t flag
      cases f with
      | zero => omega
      | succ f =>
      cases g with
      | zero => omega
      | succ g =>
      simp only [offsetsof_lemFuel]
      split
      · rfl
      · rename_i s l membrs flex heq
        have hl : lookup tagDefs t = some (l, StructDef membrs flex) := lookup_of_entry heq
        rw [oPot_of_struct ambient tagDefs R L hl flag] at hk hf hg
        show offsetsofMembers_lemFuel f ambient tagDefs (structMembers membrs flex flag) =
          offsetsofMembers_lemFuel g ambient tagDefs (structMembers membrs flex flag)
        exact ihOM _ f g (by omega) (by omega) (by omega)
      · rfl

end LayoutStable

/-! ### The concrete measures dominate the potentials, and THE OBLIGATIONS -/

section LayoutObligations
open CerbTagsWf

/-- The entries of a map, in spine order (what both lookups return elements of). -/
def entries (m : CerbTags.TagDefsMap) : List Entry := (fmapElements m).map Prod.snd

theorem lookup_mem_entries {m : CerbTags.TagDefsMap} {t : sym} {v : Entry} (h : lookup m t = some v) :
    v ∈ entries m := by
  unfold lookup at h
  cases hf : lookupEntry m t with
  | none => rw [hf] at h; cases h
  | some p =>
    rw [hf] at h
    simp only [Option.map_some, Option.some.injEq] at h
    subst h
    exact List.mem_map.mpr ⟨p, List.mem_of_find?_eq_some hf, rfl⟩

theorem sum_entries (m : CerbTags.TagDefsMap) :
    ((entries m).map (fun v : Entry => defSize v.2 + 2)).sum = defsWeight m := by
  simp only [entries, defsWeight, List.map_map, Function.comp_def]

theorem W_le_defsWeight (m : CerbTags.TagDefsMap) (R : Entry → Nat) (v : Entry) :
    W R (entries m) v ≤ defsWeight m := by
  have := W_le_total R (entries m) v; rw [sum_entries] at this; exact this

theorem W_le_defsWeight2 (m1 m2 : CerbTags.TagDefsMap) (R : Entry → Nat) (v : Entry) :
    W R (entries m1 ++ entries m2) v ≤ defsWeight m1 + defsWeight m2 := by
  have := W_le_total R (entries m1 ++ entries m2) v
  rw [List.map_append, List.sum_append, sum_entries, sum_entries] at this; exact this

/-- A ctype's tag potential is at most the weight bound of the list. -/
theorem tp_le (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) (ty : ctype) : tp ambient tagDefs R L ty ≤ bound := by
  rcases tp_spec ambient tagDefs R L ty with h0 | ⟨_, _, v', _, htp⟩
  · omega
  · rw [htp]; exact hW v'

theorem pot_le (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) (ty : ctype) : pot ambient tagDefs R L ty ≤ ctype.lemSize ty + bound := by
  unfold pot; have := tp_le ambient tagDefs R L bound hW ty; omega

theorem alignPot_le_size (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) (al : Option alignment) :
    alignPot ambient tagDefs R L al ≤ alignSize al + bound := by
  cases al with
  | none => simp [alignPot]
  | some al =>
    cases al with
    | AlignInteger _ => simp [alignPot]
    | AlignType a =>
      simp only [alignPot, alignSize, alignTypes, List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
      have := pot_le ambient tagDefs R L bound hW a; omega

theorem mPot_le_size (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) (al : Option alignment) (ty : ctype) :
    mPot ambient tagDefs R L al ty ≤ ctype.lemSize ty + alignSize al + bound := by
  have h1 := pot_le ambient tagDefs R L bound hW ty
  have h2 := alignPot_le_size ambient tagDefs R L bound hW al
  unfold mPot; omega

theorem membersPot_le_size (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) (members : List Member) :
    membersPot ambient tagDefs R L members ≤ membersSize members + bound := by
  induction members with
  | nil => simp [membersPot]
  | cons mb rest ih =>
    simp only [membersPot, membersSize, List.map_cons, List.sum_cons] at *
    have := mPot_le_size ambient tagDefs R L bound hW mb.2.2.1 mb.2.2.2.2
    omega

/-- Every type an entry of `m` makes the recursion enter has size at most that
    entry's `defSize`, and the entry's term is inside `defsWeight m`. -/
theorem defSize_le_defsWeight {m : CerbTags.TagDefsMap} {t : sym} {v : Entry} (h : lookup m t = some v) :
    defSize v.2 + 2 ≤ defsWeight m := by
  have h2 : defSize v.2 + 2 ≤ ((entries m).map (fun v : Entry => defSize v.2 + 2)).sum :=
    le_sum_of_mem (fun v : Entry => defSize v.2 + 2) (lookup_mem_entries h)
  rw [sum_entries] at h2; exact h2

/-- A member's potential (a MAX of its type's and its `_Alignas` type's) is
    bounded by its entry's `defSize` plus the weight bound. -/
theorem mPot_le_entry (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) {v : Entry} {mb : Member}
    (hmb : ∀ y ∈ memberTypes1 mb, y ∈ memberTypes v.2) :
    mPot ambient tagDefs R L mb.2.2.1 mb.2.2.2.2 ≤ defSize v.2 + bound := by
  have h1 := pot_le ambient tagDefs R L bound hW mb.2.2.2.2
  have h1' : ctype.lemSize mb.2.2.2.2 ≤ defSize v.2 := le_sum_of_mem ctype.lemSize (hmb _ (mem_memberTypes1_ty mb))
  unfold mPot
  cases hal : mb.2.2.1 with
  | none => simp only [alignPot]; omega
  | some al =>
    cases al with
    | AlignInteger _ => simp only [alignPot]; omega
    | AlignType a =>
      simp only [alignPot]
      have h2 := pot_le ambient tagDefs R L bound hW a
      have h2' : ctype.lemSize a ≤ defSize v.2 := le_sum_of_mem ctype.lemSize (hmb a (mem_memberTypes1_align mb a hal))
      omega

theorem membersPot_le_entry (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) (bound : Nat)
    (hW : ∀ v, W R L v ≤ bound) {l : CerbLocation.Loc} {membrs : List Member} {flex : Option flexible_array_member} (flag : Bool) :
    membersPot ambient tagDefs R L (structMembers membrs flex flag) ≤ defSize (StructDef membrs flex) + bound := by
  suffices hs : ∀ (ms : List Member), (∀ mb ∈ ms, ∀ y ∈ memberTypes1 mb, y ∈ memberTypes (l, StructDef membrs flex).2) →
      membersPot ambient tagDefs R L ms ≤ defSize (StructDef membrs flex) + bound from
    hs _ (fun mb hmb => structMembers_types membrs flex flag hmb)
  intro ms hms
  induction ms with
  | nil => simp [membersPot]
  | cons mb rest ih =>
    simp only [membersPot]
    have h1 := mPot_le_entry ambient tagDefs R L bound hW (v := (l, StructDef membrs flex)) (hms mb (List.mem_cons_self ..))
    simp only at h1
    have := ih (fun mb' h' => hms mb' (List.mem_cons_of_mem _ h'))
    omega

/-! ### THE OBLIGATIONS (the seam twins of the generated `assuming` shape:
    parameters, `(lemHyp : H)`, `(lemFuel : Nat)`, `(lemMeasureLe : μ ≤ lemFuel)`,
    conclusion `worker lemFuel … = wrapper …`) -/

theorem alignofCtype_measure_sufficient (ambient : CerbTags.TagDefsMap) (cty : ctype)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient cty ≤ lemFuel) :
    alignofCtype_lemFuel lemFuel ambient ambient cty = alignofCtype ambient cty := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := pot_le ambient ambient R (entries ambient) _ hW cty
  have h := (layout_stable_aux ambient ambient R (entries ambient) hR (fun _ _ h => lookup_mem_entries h)
    (fun _ _ h => lookup_mem_entries h) (pot ambient ambient R (entries ambient) cty)).1
  exact h cty lemFuel (envBound ambient cty) (Nat.le_refl _) (by unfold envBound at lemMeasureLe; omega) (by unfold envBound; omega)

theorem sizeofCtype_measure_sufficient (ambient : CerbTags.TagDefsMap) (cty : ctype)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient cty ≤ lemFuel) :
    sizeofCtype_lemFuel lemFuel ambient ambient cty = sizeofCtype ambient cty := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := pot_le ambient ambient R (entries ambient) _ hW cty
  have h := (layout_stable_aux ambient ambient R (entries ambient) hR (fun _ _ h => lookup_mem_entries h)
    (fun _ _ h => lookup_mem_entries h) (pot ambient ambient R (entries ambient) cty + 1)).2.1
  exact h cty lemFuel (envBound ambient cty) (Nat.le_refl _) (by unfold envBound at lemMeasureLe; omega) (by unfold envBound; omega)

theorem memberAlign_measure_sufficient (ambient : CerbTags.TagDefsMap) (alignOpt : Option alignment) (ty : ctype)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.memberBound ambient alignOpt ty ≤ lemFuel) :
    memberAlign_lemFuel lemFuel ambient ambient alignOpt ty = memberAlign ambient alignOpt ty := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := mPot_le_size ambient ambient R (entries ambient) _ hW alignOpt ty
  have h := (layout_stable_aux ambient ambient R (entries ambient) hR (fun _ _ h => lookup_mem_entries h)
    (fun _ _ h => lookup_mem_entries h) (mPot ambient ambient R (entries ambient) alignOpt ty + 1)).2.2.1
  exact h alignOpt ty lemFuel (memberBound ambient alignOpt ty) (Nat.le_refl _)
    (by unfold memberBound at lemMeasureLe; omega) (by unfold memberBound; omega)

theorem offsetsofMembers_measure_sufficient (ambient : CerbTags.TagDefsMap)
    (members : List (identifier × (attributes × Option alignment × qualifiers × ctype)))
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.membersBound ambient members ≤ lemFuel) :
    offsetsofMembers_lemFuel lemFuel ambient ambient members = offsetsofMembers ambient members := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := membersPot_le_size ambient ambient R (entries ambient) _ hW members
  have h := (layout_stable_aux ambient ambient R (entries ambient) hR (fun _ _ h => lookup_mem_entries h)
    (fun _ _ h => lookup_mem_entries h) (membersPot ambient ambient R (entries ambient) members + 2)).2.2.2.1
  exact h members lemFuel (membersBound ambient members) (Nat.le_refl _)
    (by unfold membersBound at lemMeasureLe; omega) (by unfold membersBound; omega)

theorem offsetsof_measure_sufficient (ambient tagDefs : CerbTags.TagDefsMap) (tagSym : sym) (ignoreFlexible : Bool)
    (lemHyp : CerbTagsWf.AcyclicPair ambient tagDefs) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.offsetsofBound ambient tagDefs ≤ lemFuel) :
    offsetsof_lemFuel lemFuel ambient tagDefs tagSym ignoreFlexible = offsetsof ambient tagDefs tagSym ignoreFlexible := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight2 ambient tagDefs R
  have hLS : ∀ t v, lookup tagDefs t = some v → v ∈ entries ambient ++ entries tagDefs :=
    fun _ _ h => List.mem_append.mpr (Or.inr (lookup_mem_entries h))
  have hLU : ∀ t v, lookup ambient t = some v → v ∈ entries ambient ++ entries tagDefs :=
    fun _ _ h => List.mem_append.mpr (Or.inl (lookup_mem_entries h))
  have hp : oPot ambient tagDefs R (entries ambient ++ entries tagDefs) tagSym ignoreFlexible ≤ offsetsofBound ambient tagDefs := by
    unfold offsetsofBound
    rcases hl : lookup tagDefs tagSym with _ | ⟨l, d⟩
    · rw [oPot_of_none ambient tagDefs R _ hl]; omega
    · cases d with
      | StructDef membrs flex =>
        rw [oPot_of_struct ambient tagDefs R _ hl]
        have h1 := membersPot_le_entry ambient tagDefs R (entries ambient ++ entries tagDefs) _ hW (l := l) (membrs := membrs) (flex := flex) ignoreFlexible
        have h2 := defSize_le_defsWeight hl
        simp only at h2
        omega
      | UnionDef membrs => rw [oPot_of_union ambient tagDefs R _ hl]; omega
  have h := (layout_stable_aux ambient tagDefs R (entries ambient ++ entries tagDefs) hR hLS hLU
    (oPot ambient tagDefs R (entries ambient ++ entries tagDefs) tagSym ignoreFlexible)).2.2.2.2
  exact h tagSym ignoreFlexible lemFuel (offsetsofBound ambient tagDefs) (Nat.le_refl _) (by omega) hp

end LayoutObligations

/-! ### reconstructValue: recursion on the ctype being reconstructed, through
    member types read from the tag environment (impl_mem.ml:916-1095). The
    struct arm's member types come out of `offsetsof` — characterized below:
    every `(ident, ty, off)` it returns has `ty` among the definition's
    `memberTypes`, so the potential descends by the same hop inequality. -/

section Reconstruct
open CerbTagsWf

theorem panic_eq_default {α : Type} [Inhabited α] (m d : String) (l c : Nat) (msg : String) :
    (panicWithPosWithDecl m d l c msg : α) = default := rfl

/-- A fold that conses one element per member (the `offsetsofMembers` fold): every
    element of the result is from the seed or from a member. -/
theorem foldl_offs_mem {α : Type} (F : (List (identifier × ctype × Nat) × Nat) → α → (List (identifier × ctype × Nat) × Nat))
    (tyOf : α → ctype)
    (hF : ∀ acc a, ∃ i off, (F acc a).1 = (i, tyOf a, off) :: acc.1) :
    ∀ (l : List α) (acc : List (identifier × ctype × Nat) × Nat), ∀ x ∈ (List.foldl F acc l).1,
      x ∈ acc.1 ∨ ∃ a ∈ l, x.2.1 = tyOf a := by
  intro l
  induction l with
  | nil => intro acc x hx; exact Or.inl hx
  | cons a rest ih =>
    intro acc x hx
    simp only [List.foldl_cons] at hx
    rcases ih (F acc a) x hx with h | ⟨a', ha', hty⟩
    · obtain ⟨i, off, hF'⟩ := hF acc a
      rw [hF'] at h
      rcases List.mem_cons.mp h with h | h
      · exact Or.inr ⟨a, List.mem_cons_self .., by rw [h]⟩
      · exact Or.inl h
    · exact Or.inr ⟨a', List.mem_cons_of_mem _ ha', hty⟩

theorem offsetsofMembers_types (n : Nat) (ambient tagDefs : CerbTags.TagDefsMap) (members : List Member) :
    ∀ x ∈ (offsetsofMembers_lemFuel (n + 1) ambient tagDefs members).1, ∃ mb ∈ members, x.2.1 = mb.2.2.2.2 := by
  intro x hx
  simp only [offsetsofMembers_lemFuel, List.mem_reverse] at hx
  rcases foldl_offs_mem _ (fun mb : Member => mb.2.2.2.2) (fun acc a => ⟨a.1, _, rfl⟩) members ([], 0) x hx with h | h
  · cases h
  · exact h

theorem offsetsof_types (n : Nat) (ambient tagDefs : CerbTags.TagDefsMap) (t : sym) (flag : Bool) :
    ∀ x ∈ (offsetsof_lemFuel (n + 2) ambient tagDefs t flag).1,
      ∃ v : Entry, lookup tagDefs t = some v ∧ x.2.1 ∈ memberTypes v.2 := by
  intro x hx
  simp only [offsetsof_lemFuel] at hx
  split at hx
  · rw [panic_eq_default] at hx; cases hx
  · rename_i s l membrs flex heq
    have hl := lookup_of_entry heq
    obtain ⟨mb, hmb, hty⟩ := offsetsofMembers_types n ambient tagDefs (structMembers membrs flex flag) x hx
    exact ⟨_, hl, by rw [hty]; exact structMembers_types membrs flex flag hmb _ (mem_memberTypes1_ty mb)⟩
  · rename_i s l membrs heq
    have hl := lookup_of_entry heq
    simp only [List.mem_map] at hx
    obtain ⟨mb, hmb, hx⟩ := hx
    refine ⟨_, hl, ?_⟩
    rw [← hx]
    exact mem_memberTypes_of_union membrs ⟨mb, hmb, mem_memberTypes1_ty mb⟩

theorem pot_default (ambient tagDefs : CerbTags.TagDefsMap) (R : Entry → Nat) (L : List Entry) :
    pot ambient tagDefs R L (default : identifier × ctype).2 = 2 := rfl

theorem reconstructValue_stable_aux (ambient : CerbTags.TagDefsMap) (R : Entry → Nat)
    (hR : Ranked (lookup ambient) (lookup ambient) R) (k : Nat) :
    ∀ (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) (f g : Nat),
    pot ambient ambient R (entries ambient) ty ≤ k → pot ambient ambient R (entries ambient) ty ≤ f →
    pot ambient ambient R (entries ambient) ty ≤ g →
    reconstructValue_lemFuel f ambient unionmap funptrmap addr ty bytes =
      reconstructValue_lemFuel g ambient unionmap funptrmap addr ty bytes := by
  have hLS : ∀ t v, lookup ambient t = some v → v ∈ entries ambient := fun _ _ h => lookup_mem_entries h
  induction k with
  | zero => intro _ _ _ ty _ f g hk _ _; have := pot_pos ambient ambient R (entries ambient) ty; omega
  | succ k ih =>
    intro unionmap funptrmap addr ty bytes f g hk hf hg
    have hpos := pot_pos ambient ambient R (entries ambient) ty
    cases f with
    | zero => omega
    | succ f =>
    cases g with
    | zero => omega
    | succ g =>
    have key : ∀ (um : List (Int × identifier)) (fpm : Funptrmap) (ad : Int) (y : ctype) (bs : List AbsByte),
        pot ambient ambient R (entries ambient) y < pot ambient ambient R (entries ambient) ty →
        reconstructValue_lemFuel f ambient um fpm ad y bs = reconstructValue_lemFuel g ambient um fpm ad y bs :=
      fun um fpm ad y bs hy => ih um fpm ad y bs f g (by omega) (by omega) (by omega)
    obtain ⟨an, ty_⟩ := ty
    cases ty_ <;> simp only [reconstructValue_lemFuel]
    case Basic bty => cases bty <;> rfl
    case Array0 c n =>
      cases n with
      | none => rfl
      | some n =>
        simp only
        have hp := pot_array ambient ambient R (entries ambient) an c (some n)
        congr 1
        apply lmap_congr
        intro eb _
        exact key _ _ _ c eb (by omega)
    case Atomic c =>
      have hp := pot_atomic ambient ambient R (entries ambient) an c
      exact key _ _ _ c bytes (by omega)
    case Struct t =>
      have hb : offsetsofBound ambient ambient = (defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) + 2 := by
        unfold offsetsofBound; omega
      have hoffs := offsetsof_types (defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) ambient ambient t true
      to_congr
      all_goals
        intro acc memb hmemb
        obtain ⟨revXs, prevEnd⟩ := acc
        obtain ⟨ident, membTy, off⟩ := memb
        dsimp only
        have hm : (ident, membTy, off) ∈ (offsetsof_lemFuel ((defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) + 2) ambient ambient t true).1 := by
          unfold offsetsof at hmemb; rw [hb] at hmemb; exact hmemb
        obtain ⟨v, hl, hty⟩ := hoffs _ hm
        have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hty
        have h2 := pot_struct ambient ambient R (entries ambient) an t v hl
        rw [key _ _ _ membTy _ (by simp only at h1; omega)]
    case Union0 t =>
      split
      · rename_i s l membrs heq
        have hl := lookup_of_entry heq
        have h2 := pot_union ambient ambient R (entries ambient) an t _ hl
        split
        · rfl
        · rename_i firstIdent at_ al q firstTy rest
          have hfirst : firstTy ∈ memberTypes (l, UnionDef ((firstIdent, (at_, al, q, firstTy)) :: rest)).2 :=
            mem_memberTypes_of_union _ ⟨_, List.mem_cons_self .., mem_memberTypes1_ty (firstIdent, (at_, al, q, firstTy))⟩
          split
          · -- no recorded member: the first member
            simp only
            have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hfirst
            rw [key _ _ _ firstTy _ (by omega)]
          · rename_i a membr heq2
            split
            · rename_i i at2 al2 q2 t2 heq3
              simp only
              have hmem : t2 ∈ memberTypes (l, UnionDef ((firstIdent, (at_, al, q, firstTy)) :: rest)).2 :=
                mem_memberTypes_of_union _ ⟨_, List.mem_of_find?_eq_some heq3, mem_memberTypes1_ty (i, (at2, al2, q2, t2))⟩
              have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hmem
              rw [key _ _ _ t2 _ (by omega)]
            · rename_i heq3
              rw [panic_eq_default]
              have h1 := pot_default ambient ambient R (entries ambient)
              have h3 := W_self R (entries ambient) (hLS _ _ hl)
              rw [key _ _ _ _ _ (by rw [h1]; omega)]
      · rfl

/-- THE OBLIGATION (the seam twin of the generated `assuming` shape). -/
theorem reconstructValue_measure_sufficient (ambient : CerbTags.TagDefsMap) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient ty ≤ lemFuel) :
    reconstructValue_lemFuel lemFuel ambient unionmap funptrmap addr ty bytes =
      reconstructValue ambient unionmap funptrmap addr ty bytes := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := pot_le ambient ambient R (entries ambient) _ hW ty
  exact reconstructValue_stable_aux ambient R hR (pot ambient ambient R (entries ambient) ty) unionmap funptrmap addr ty bytes
    lemFuel (envBound ambient ty) (Nat.le_refl _) (by unfold envBound at lemMeasureLe; omega) (by unfold envBound; omega)

end Reconstruct

end CerbMem
