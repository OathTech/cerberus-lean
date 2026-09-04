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

end CerbMem
