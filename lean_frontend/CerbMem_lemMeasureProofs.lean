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
                           fuel-free since C4 — the layout oracle it reads is measured)
    reconstructValue(Abst) under `CerbTagsWf.Acyclic ambient` (PNVI arc S2)

  The five LAYOUT obligations (memberAlign / offsetsofMembers / offsetsof / sizeofCtype /
  alignofCtype) moved to CerberusImpl_lemMeasureProofs.lean with the layout block
  (merge-base bump stage 1, 2026-10-29); the reconstruction proofs below use its
  potentials and layout facts through `open CerberusImpl`.

  Shape = the C2 template (Core_run_aux_lemMeasureProofs.lean): strong
  induction on the size bound; `key` rewrites the direct children; the list
  folds by membership-relative congruence (`to_congr`). Kernel-only tactics;
  no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import CerbMem
import CerberusImpl_lemMeasureProofs
import CerbMeasureLemmas
import Ctype_lemMeasureProofs
import CerbTagsWf

set_option autoImplicit false

open CerbMeasureLemmas
open CerberusImpl

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

theorem memValueToBytes_stable_aux (enumDefs : CerberusImpl.EnumDefs) (k : Nat) :
    ∀ (ambient : CerbTags.TagDefsMap) (funptrmap : Funptrmap) (v : MemValue) (f g : Nat),
    memValueSize v ≤ k → memValueSize v ≤ f → memValueSize v ≤ g →
    memValueToBytes_lemFuel f enumDefs ambient funptrmap v = memValueToBytes_lemFuel g enumDefs ambient funptrmap v := by
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
            memValueToBytes_lemFuel f enumDefs ambient fpm y = memValueToBytes_lemFuel g enumDefs ambient fpm y :=
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

/-- THE OBLIGATION (the seam twin of the generated shape; its `[LemFuel]`
    went at C4 with the layout oracle's — audit F-A5). -/
theorem memValueToBytes_measure_sufficient (enumDefs : CerberusImpl.EnumDefs) (ambient : CerbTags.TagDefsMap) (funptrmap : Funptrmap)
    (val_ : MemValue) (lemFuel : Nat) (lemMeasureLe : memValueSize val_ ≤ lemFuel) :
    memValueToBytes_lemFuel lemFuel enumDefs ambient funptrmap val_ = memValueToBytes enumDefs ambient funptrmap val_ :=
  memValueToBytes_stable_aux enumDefs (memValueSize val_) ambient funptrmap val_ lemFuel (memValueSize val_)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)


/-! ### reconstructValue(Abst): recursion on the ctype being reconstructed, through
    member types read from the tag environment (impl_mem.ml:916-1096). The
    struct arm's member types come out of `offsetsof` — characterized below:
    every `(ident, ty, off)` it returns for a tag that RESOLVES has `ty` among
    the definition's `memberTypes`, so the potential descends by the same hop
    inequality. Both arms of `reconstructValueAbst_lemFuel` guard their tag lookup
    and select the union member BEFORE any recursion (hotfix
    fix/fuel-forms-carriers option (d), 2026-09-20 — record
    docs/2026-09-20_fuel-forms-carriers-hotfix-record.md §3): every failure
    leaf is a WHOLE result, fuel-independent, closed by `rfl`; no equation about
    LemLib's opaque `failwithI` is needed (none exists — the pre-hotfix
    `panic_eq_default` rewrote leaves the recursion entered, which seam-hygiene
    H1 made opaque, and under `Acyclic` alone the old shape was unprovable in
    principle: record §3.1). -/

section Reconstruct
open CerbTagsWf

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

theorem offsetsofMembers_types (n : Nat) (enumDefs : CerberusImpl.EnumDefs) (ambient tagDefs : CerbTags.TagDefsMap) (members : List Member) :
    ∀ x ∈ (offsetsofMembers_lemFuel (n + 1) enumDefs ambient tagDefs members).1, ∃ mb ∈ members, x.2.1 = mb.2.2.2.2 := by
  intro x hx
  simp only [offsetsofMembers_lemFuel, List.mem_reverse] at hx
  rcases foldl_offs_mem _ (fun mb : Member => mb.2.2.2.2) (fun acc a => ⟨a.1, _, rfl⟩) members ([], 0) x hx with h | h
  · cases h
  · exact h

/-- `offsetsof` on a tag KNOWN to resolve (`hl`): every member type it returns
    is among the definition's `memberTypes`. The unknown-tag arm is excluded by
    `hl` — the struct arm of `reconstructValue` supplies it from its own guard. -/
theorem offsetsof_types (n : Nat) (enumDefs : CerberusImpl.EnumDefs) (ambient tagDefs : CerbTags.TagDefsMap) (t : sym) (flag : Bool)
    (v : Entry) (hl : lookup tagDefs t = some v) :
    ∀ x ∈ (offsetsof_lemFuel (n + 2) enumDefs ambient tagDefs t flag).1, x.2.1 ∈ memberTypes v.2 := by
  intro x hx
  simp only [offsetsof_lemFuel] at hx
  split at hx
  · rename_i heq
    simp [lookup, heq] at hl
  · rename_i s l membrs flex heq
    have hl' := lookup_of_entry heq
    rw [hl'] at hl; cases hl
    obtain ⟨mb, hmb, hty⟩ := offsetsofMembers_types n enumDefs ambient tagDefs (structMembers membrs flex flag) x hx
    rw [hty]; exact structMembers_types membrs flex flag hmb _ (mem_memberTypes1_ty mb)
  · rename_i s l membrs heq
    have hl' := lookup_of_entry heq
    rw [hl'] at hl; cases hl
    simp only [List.mem_map] at hx
    obtain ⟨mb, hmb, hx⟩ := hx
    rw [← hx]
    exact mem_memberTypes_of_union membrs ⟨mb, hmb, mem_memberTypes1_ty mb⟩

/-- PNVI arc S2 (2026-10-07): the recursion is `reconstructValueAbst_lemFuel`'s
    (the full `abst` — switch set, `find_overlaping` closure, taint); the
    closure and the instance are fixed through the induction (never recursed
    on), the taint rides along in the pair. -/
theorem reconstructValueAbst_stable_aux [CerbGlobal.Switches] (enumDefs : CerberusImpl.EnumDefs) (ambient : CerbTags.TagDefsMap)
    (findOverlapping : Address → OverlapResult) (R : Entry → Nat)
    (hR : Ranked (lookup ambient) (lookup ambient) R) (k : Nat) :
    ∀ (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) (f g : Nat),
    pot ambient ambient R (entries ambient) ty ≤ k → pot ambient ambient R (entries ambient) ty ≤ f →
    pot ambient ambient R (entries ambient) ty ≤ g →
    reconstructValueAbst_lemFuel f enumDefs ambient findOverlapping unionmap funptrmap addr ty bytes =
      reconstructValueAbst_lemFuel g enumDefs ambient findOverlapping unionmap funptrmap addr ty bytes := by
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
        reconstructValueAbst_lemFuel f enumDefs ambient findOverlapping um fpm ad y bs =
          reconstructValueAbst_lemFuel g enumDefs ambient findOverlapping um fpm ad y bs :=
      fun um fpm ad y bs hy => ih um fpm ad y bs f g (by omega) (by omega) (by omega)
    obtain ⟨an, ty_⟩ := ty
    cases ty_ <;> simp only [reconstructValueAbst_lemFuel]
    case Basic bty => cases bty <;> rfl
    case Array0 c n =>
      cases n with
      | none => rfl
      | some n =>
        simp only
        have hp := pot_array ambient ambient R (entries ambient) an c (some n)
        have hF : (fun eb => reconstructValueAbst_lemFuel f enumDefs ambient findOverlapping unionmap funptrmap addr c eb) =
            (fun eb => reconstructValueAbst_lemFuel g enumDefs ambient findOverlapping unionmap funptrmap addr c eb) :=
          funext fun eb => key _ _ _ c eb (by omega)
        rw [hF]
    case Atomic c =>
      have hp := pot_atomic ambient ambient R (entries ambient) an c
      exact key _ _ _ c bytes (by omega)
    case Struct t =>
      split
      · -- unknown tag: the whole result is the (fuel-independent) leaf
        rfl
      · rename_i p heq
        obtain ⟨s, v⟩ := p
        have hl : lookup ambient t = some v := lookup_of_entry heq
        have hb : offsetsofBound ambient ambient = (defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) + 2 := by
          unfold offsetsofBound; omega
        have hoffs := offsetsof_types (defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) enumDefs ambient ambient t true v hl
        have h2 := pot_struct ambient ambient R (entries ambient) an t v hl
        to_congr
        all_goals
          intro acc memb hmemb
          obtain ⟨taintAcc, revXs, prevEnd⟩ := acc
          obtain ⟨ident, membTy, off⟩ := memb
          dsimp only
          have hm : (ident, membTy, off) ∈ (offsetsof_lemFuel ((defsWeight ambient + defsWeight ambient + defsWeight ambient + 1) + 2) enumDefs ambient ambient t true).1 := by
            unfold offsetsof at hmemb; rw [hb] at hmemb; exact hmemb
          have hty := hoffs _ hm
          have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hty
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
            have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hfirst
            rw [key _ _ _ firstTy _ (by omega)]
          · rename_i a membr heq2
            split
            · rename_i i at2 al2 q2 t2 heq3
              have hmem : t2 ∈ memberTypes (l, UnionDef ((firstIdent, (at_, al, q, firstTy)) :: rest)).2 :=
                mem_memberTypes_of_union _ ⟨_, List.mem_of_find?_eq_some heq3, mem_memberTypes1_ty (i, (at2, al2, q2, t2))⟩
              have h1 := pot_member ambient ambient R (entries ambient) hR hLS hLS (Or.inl hl) hmem
              rw [key _ _ _ t2 _ (by omega)]
            · -- recorded member not in the definition: the whole result is the leaf
              rfl
      · rfl

/-- THE OBLIGATION of the full reconstruction (PNVI arc S2; the seam twin of the
    generated `assuming` shape; register row `CerbMem.reconstructValueAbst_lemFuel`
    in scripts/fuel_hypotheses.txt). -/
theorem reconstructValueAbst_measure_sufficient [CerbGlobal.Switches] (enumDefs : CerberusImpl.EnumDefs) (ambient : CerbTags.TagDefsMap)
    (findOverlapping : Address → OverlapResult) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient ty ≤ lemFuel) :
    reconstructValueAbst_lemFuel lemFuel enumDefs ambient findOverlapping unionmap funptrmap addr ty bytes =
      reconstructValueAbst enumDefs ambient findOverlapping unionmap funptrmap addr ty bytes := by
  obtain ⟨R, hR⟩ := lemHyp
  have hW := W_le_defsWeight ambient R
  have hp := pot_le ambient ambient R (entries ambient) _ hW ty
  exact reconstructValueAbst_stable_aux enumDefs ambient findOverlapping R hR (pot ambient ambient R (entries ambient) ty) unionmap funptrmap addr ty bytes
    lemFuel (envBound ambient ty) (Nat.le_refl _) (by unfold envBound at lemMeasureLe; omega) (by unfold envBound; omega)

/-- THE OBLIGATION of the default-mode compatibility wrapper (statement
    unchanged since the C4 slice): since PNVI arc S2 `reconstructValue_lemFuel` /
    `reconstructValue` are the `.2` of the full reconstruction pinned at
    `⟨CerbGlobal.defaultSwitches⟩` with the closure `noOverlapping`, so this is the
    full obligation's second projection. -/
theorem reconstructValue_measure_sufficient (enumDefs : CerberusImpl.EnumDefs) (ambient : CerbTags.TagDefsMap) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient ty ≤ lemFuel) :
    reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes :=
  congrArg Prod.snd (@reconstructValueAbst_measure_sufficient ⟨CerbGlobal.defaultSwitches⟩ enumDefs ambient
    noOverlapping unionmap funptrmap addr ty bytes lemHyp lemFuel lemMeasureLe)

end Reconstruct

end CerbMem
