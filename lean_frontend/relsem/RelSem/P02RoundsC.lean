/-
  RelSem.P02RoundsC — PERF-1 generated supply (chunk
  3/4; see P02Rounds.lean header and
  scripts/gen_p02_supply.py). BLOCK-GRANULAR DEFAULT: @[seg_block]
  SegStep facts for the straight-line pure-control runs (Floyd cut
  points + the Hoare sequence rule via link_ctl/SegStep.trans),
  @[seg_round] anchors at the cut points. NO per-round heartbeat
  budgets (the pinned-discovery regime; a slow lemma is a loud
  build failure, never a budget).
-/

import RelSem.P02Rounds
import RelSem.P02Guard
import RelSem.SegRun

set_option autoImplicit false
set_option maxHeartbeats 2000000
set_option maxErrors 400

namespace RelSem.P02

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Corpus
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  mkByte allocX allocXS mr0 mr1)
open RelSem.P01 (L0)

/-- FamShape at any P02-family instance (all rfl; chunk-local copy —
    consumed by this chunk's block facts). -/
private def p02ShapeC (ar : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (p02fam ar tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

@[seg_round]
theorem p02r193_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar159 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 69 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar160 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 70 p) := by
  seg_round_tau

@[seg_round]
theorem p02r194_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar160 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 70 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar161 [p02meLoadA a, p02meLoadA a, p02meLoadA a] 71 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_631 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_632 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r195_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_631 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648))))))
    (hrd1 : lookup_env p02s_a_632 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar161 [p02meLoadA a, p02meLoadA a, p02meLoadA a] 71 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar162 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 72 p) := by
  seg_round_arith_sub

@[seg_round]
theorem p02r196_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar162 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 72 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar163 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 73 p) := by
  seg_round_eval

@[seg_round]
theorem p02r197_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar163 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 73 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar164 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 74 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_622 (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r198_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_622 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar164 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 74 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar165 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 75 p) := by
  seg_round_eval

@[seg_round]
theorem p02r199_lo_mB (a : Int) (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocBS)
    (hb : ∀ i : Nat, (hi : i < (xBytes b).length) → p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes b)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar165 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 75 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar166 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 75 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r200_lo_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar166 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 75 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar167 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 76 p) := by
  seg_round_tau

@[seg_round]
theorem p02r201_lo_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar167 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 76 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar168 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 77 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_636 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_637 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648 - a))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r202_lo_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_636 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))))
    (hrd1 : lookup_env p02s_a_637 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648 - a)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar168 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 77 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar169 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 78 p) := by
  seg_round_eval

@[seg_round]
theorem p02r203_lo_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar169 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 78 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar170 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 79 p) := by
  seg_round_tau

@[seg_round]
theorem p02r204_mB (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : ¬ b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar170 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 79 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar171 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 80 p) := by
  seg_round_guard_ltF

@[seg_round]
theorem p02r205_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar171 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 80 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar172 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 81 p) := by
  seg_round_tau

@[seg_round]
theorem p02r206_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar172 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 81 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar173 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 82 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_617 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_618 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r207_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_617 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_618 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar173 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 82 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar174 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 83 p) := by
  seg_round_eval

@[seg_round]
theorem p02r208_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar174 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 83 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar175 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 84 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_641 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r209_lo_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar175 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 84 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar176 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 85 p) := by
  seg_round_tau

@[seg_round]
theorem p02r210_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_641 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar176 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 85 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar177 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 86 p) := by
  seg_round_eval

@[seg_round]
theorem p02r211_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar177 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 86 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar178 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 87 p) := by
  seg_round_tau

@[seg_round]
theorem p02r212_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar178 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 87 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar179 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 88 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_593 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_594 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r213_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_593 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_594 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar179 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 88 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar180 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 89 p) := by
  seg_round_eval

@[seg_round]
theorem p02r214_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar180 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 89 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar104 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 90 p) := by
  seg_round_tau

@[seg_round]
theorem p02r215_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar104 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 90 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar105 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 91 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_591 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r216_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_591 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar105 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 91 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar106 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92 p) := by
  seg_round_eval

@[seg_round]
theorem p02r219_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar108 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar109 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 95 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_544 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r220_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_544 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar109 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 95 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar110 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 96 p) := by
  seg_round_tau

@[seg_round]
theorem p02r221_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar110 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 96 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar111 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 97 p) := by
  seg_round_tau

@[seg_round]
theorem p02r222_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar111 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 97 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar112 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98 p) := by
  seg_round_eval

@[seg_round]
theorem p02r223_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar112 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar113 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 99 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_656 (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r224_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_656 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar113 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 99 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar114 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 p) := by
  seg_round_eval

@[seg_round]
theorem p02r225_mB (a : Int) (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocBS)
    (hb : ∀ i : Nat, (hi : i < (xBytes b).length) → p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes b)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar114 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar115 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r226_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar115 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar116 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 101 p) := by
  seg_round_eval

@[seg_round]
theorem p02r227_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar116 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 101 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar117 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 102 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_655 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r228_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_655 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar117 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 102 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar118 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 p) := by
  seg_round_eval

@[seg_round]
theorem p02r229_mB (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar118 b) [p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar119 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r230_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar119 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar120 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 104 p) := by
  seg_round_tau

@[seg_round]
theorem p02r231_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar120 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 104 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar121 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 105 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_650 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_651 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r232_mB (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_650 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hrd1 : lookup_env p02s_a_651 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : ¬ b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar121 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 105 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar122 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 106 p) := by
  seg_round_arith_add_prim (a) (b)

@[seg_round]
theorem p02r233_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar122 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 106 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar123 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107 p) := by
  seg_round_tau

@[seg_round]
theorem p02r234_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar123 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar124 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 108 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_657 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r235_mB (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_657 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : ¬ b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar124 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 108 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar61 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 109 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_658 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))) p.f₁) }) := by
  seg_round_conv_ret (a + b)

@[seg_round]
theorem p02r236_mB (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_658 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar61 [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 109 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110 p) := by
  seg_round_eval

@[seg_round]
theorem p02term_mB (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110 p)
      = (NDactive (Sum.inr [Step_done2 ((Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))))]),
         p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110 p) := by
  seg_round_term

@[seg_round]
theorem p02r238_lo (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar170 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 79 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar181 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 80 p) := by
  seg_round_guard_ltT

@[seg_round]
theorem p02r239_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar181 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 80 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar182 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 81 p) := by
  seg_round_tau

@[seg_round]
theorem p02r240_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar182 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 81 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar173 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 82 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_617 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_618 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r241_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_617 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_618 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar173 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 82 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar183 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 83 p) := by
  seg_round_eval

@[seg_round]
theorem p02r242_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar183 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 83 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar175 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 84 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_641 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r243_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_641 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar176 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 85 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar184 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 86 p) := by
  seg_round_eval

@[seg_round]
theorem p02r244_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar184 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 86 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar185 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 87 p) := by
  seg_round_tau

@[seg_round]
theorem p02r245_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar185 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 87 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar179 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 88 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_593 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_594 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r246_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_593 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_594 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar179 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 88 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar186 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 89 p) := by
  seg_round_eval

@[seg_round]
theorem p02r247_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar186 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 89 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar187 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 90 p) := by
  seg_round_tau

@[seg_round]
theorem p02r248_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar187 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 90 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar105 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 91 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_591 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r249_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_591 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar105 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 91 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar188 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92 p) := by
  seg_round_eval

@[seg_round]
theorem p02r252_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar190 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar109 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 95 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_544 Vtrue p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r253_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_544 [p.f₁] = some Vtrue) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar109 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 95 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar191 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 96 p) := by
  seg_round_tau

@[seg_round]
theorem p02r256_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar193 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar194 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 99 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_643 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r257_lo (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_643 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar194 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 99 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar195 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 p) := by
  seg_round_neg_lit

@[seg_round]
theorem p02r258_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar195 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 100 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar196 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 101 p) := by
  seg_round_tau

@[seg_round]
theorem p02r259_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar196 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 101 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar197 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 102 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_644 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483647))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_645 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r260_lo (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_644 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483647))))))
    (hrd1 : lookup_env p02s_a_645 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0)
    (hp2 : b < -2147483648 - a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar197 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 102 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar198 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 p) := by
  seg_round_arith_sub

@[seg_round]
theorem p02r261_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar198 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 103 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar199 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 104 p) := by
  seg_round_tau

@[seg_round]
theorem p02r262_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar199 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 104 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar200 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 105 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_649 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r263_lo (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_649 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar200 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 105 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar61 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 106 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_658 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648))))) p.f₁) }) := by
  seg_round_eval

@[seg_round]
theorem p02r264_lo (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_658 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar61 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 106 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar201 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107 p) := by
  seg_round_eval

@[seg_round]
theorem p02term_lo (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar201 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107 p)
      = (NDactive (Sum.inr [Step_done2 ((Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483648))))))]),
         p02fam p02ar201 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107 p) := by
  seg_round_term

@[seg_round]
theorem p02r266_mC (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes (0)).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes (0))[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar7 [] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar202 [p02meLoadA (0)] 7 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r267_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar202 [p02meLoadA (0)] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar203 [p02meLoadA (0)] 8 p) := by
  seg_round_tau

@[seg_round]
theorem p02r268_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar203 [p02meLoadA (0)] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar10 [p02meLoadA (0)] 9 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_564 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_565 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r269_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_564 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_565 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar10 [p02meLoadA (0)] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar204 [p02meLoadA (0)] 10 p) := by
  seg_round_eval

@[seg_round]
theorem p02r270_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar204 [p02meLoadA (0)] 10 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar205 [p02meLoadA (0)] 11 p) := by
  seg_round_tau

@[seg_round]
theorem p02r271_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar205 [p02meLoadA (0)] 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar126 [p02meLoadA (0)] 12 p) := by
  seg_round_guard_gtF

@[seg_round]
theorem p02r272_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar126 [p02meLoadA (0)] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar127 [p02meLoadA (0)] 13 p) := by
  seg_round_tau

@[seg_round]
theorem p02r273_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar127 [p02meLoadA (0)] 13 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar15 [p02meLoadA (0)] 14 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_558 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_559 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r274_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_558 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_559 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar15 [p02meLoadA (0)] 14 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar128 [p02meLoadA (0)] 15 p) := by
  seg_round_eval

@[seg_round]
theorem p02r275_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar128 [p02meLoadA (0)] 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar129 [p02meLoadA (0)] 16 p) := by
  seg_round_tau

@[seg_round]
theorem p02r276_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar129 [p02meLoadA (0)] 16 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar18 [p02meLoadA (0)] 17 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_553 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_554 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r277_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_553 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_554 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar18 [p02meLoadA (0)] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar130 [p02meLoadA (0)] 18 p) := by
  seg_round_eval

@[seg_round]
theorem p02r278_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar130 [p02meLoadA (0)] 18 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar20 [p02meLoadA (0)] 19 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_569 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

end RelSem.P02
