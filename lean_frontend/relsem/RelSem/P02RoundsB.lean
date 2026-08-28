/-
  RelSem.P02RoundsB — PERF-1 generated supply (chunk
  2/4; see P02Rounds.lean header and
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
theorem p02r99_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar93 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 73 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar94 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 74 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_614 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r100_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_614 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar94 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 74 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar95 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 75 p) := by
  seg_round_eval

@[seg_round]
theorem p02r101_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar95 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 75 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar96 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 76 p) := by
  seg_round_tau

@[seg_round]
theorem p02r102_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))))
    (hrd1 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar96 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 76 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar97 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 77 p) := by
  seg_round_tau

@[seg_round]
theorem p02r103_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar97 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 77 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar98 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 78 p) := by
  seg_round_eval

@[seg_round]
theorem p02r104_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar98 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 78 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar99 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 79 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_616 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r105_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_616 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar99 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 79 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar100 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 80 p) := by
  seg_round_eval

@[seg_round]
theorem p02r106_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar100 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 80 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar101 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 81 p) := by
  seg_round_tau

@[seg_round]
theorem p02r107_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar101 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 81 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar102 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 82 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_593 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_594 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r108_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_593 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_594 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar102 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 82 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar103 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 83 p) := by
  seg_round_eval

@[seg_round]
theorem p02r109_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar103 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 83 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar104 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 84 p) := by
  seg_round_tau

@[seg_round]
theorem p02r110_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar104 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 84 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar105 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 85 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_591 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r111_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_591 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar105 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 85 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar106 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 86 p) := by
  seg_round_eval

@[seg_round]
theorem p02r114_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar108 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 88 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar109 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 89 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_544 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r115_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_544 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar109 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 89 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar110 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 90 p) := by
  seg_round_tau

@[seg_round]
theorem p02r116_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar110 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 90 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar111 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 91 p) := by
  seg_round_tau

@[seg_round]
theorem p02r117_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar111 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 91 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar112 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 92 p) := by
  seg_round_eval

@[seg_round]
theorem p02r118_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar112 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 92 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar113 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 93 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_656 (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r119_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_656 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar113 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 93 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar114 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 94 p) := by
  seg_round_eval

@[seg_round]
theorem p02r120_mA (a : Int) (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocBS)
    (hb : ∀ i : Nat, (hi : i < (xBytes b).length) → p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes b)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar114 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 94 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar115 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 94 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r121_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar115 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 94 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar116 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 95 p) := by
  seg_round_eval

@[seg_round]
theorem p02r122_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar116 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 95 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar117 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 96 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_655 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r123_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_655 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar117 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 96 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar118 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 97 p) := by
  seg_round_eval

@[seg_round]
theorem p02r124_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar118 b) [p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 97 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar119 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 97 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r125_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar119 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 97 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar120 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 98 p) := by
  seg_round_tau

@[seg_round]
theorem p02r126_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar120 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 98 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar121 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 99 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_650 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_651 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r127_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_650 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hrd1 : lookup_env p02s_a_651 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))))
    (hp0 : 0 < a)
    (hp1 : ¬ 2147483647 - a < b) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar121 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 99 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar122 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 100 p) := by
  seg_round_arith_add_prim (a) (b)

@[seg_round]
theorem p02r128_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar122 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 100 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar123 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 101 p) := by
  seg_round_tau

@[seg_round]
theorem p02r129_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar123 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 101 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar124 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 102 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_657 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r130_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_657 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))))
    (hp0 : 0 < a)
    (hp1 : ¬ 2147483647 - a < b) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar124 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 102 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar61 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 103 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_658 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))) p.f₁) }) := by
  seg_round_conv_ret (a + b)

@[seg_round]
theorem p02r131_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_658 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar61 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 103 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104 p) := by
  seg_round_eval

@[seg_round]
theorem p02term_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104 p)
      = (NDactive (Sum.inr [Step_done2 ((Vloaded (LVspecified (OVinteger (.IV .Prov_none (a + b))))))]),
         p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104 p) := by
  seg_round_term

@[seg_round]
theorem p02r133_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar12 a) [p02meLoadA a] 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar126 [p02meLoadA a] 12 p) := by
  seg_round_guard_gtF

@[seg_round]
theorem p02r134_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar126 [p02meLoadA a] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar127 [p02meLoadA a] 13 p) := by
  seg_round_tau

@[seg_round]
theorem p02r135_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar127 [p02meLoadA a] 13 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar15 [p02meLoadA a] 14 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_558 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_559 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r136_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_558 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_559 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar15 [p02meLoadA a] 14 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar128 [p02meLoadA a] 15 p) := by
  seg_round_eval

@[seg_round]
theorem p02r137_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar128 [p02meLoadA a] 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar129 [p02meLoadA a] 16 p) := by
  seg_round_tau

@[seg_round]
theorem p02r138_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar129 [p02meLoadA a] 16 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar18 [p02meLoadA a] 17 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_553 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_554 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r139_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_553 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_554 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar18 [p02meLoadA a] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar130 [p02meLoadA a] 18 p) := by
  seg_round_eval

@[seg_round]
theorem p02r140_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar130 [p02meLoadA a] 18 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar20 [p02meLoadA a] 19 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_569 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r141_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_569 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar20 [p02meLoadA a] 19 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar131 [p02meLoadA a] 20 p) := by
  seg_round_eval

@[seg_round]
theorem p02r142_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar131 [p02meLoadA a] 20 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar132 [p02meLoadA a] 21 p) := by
  seg_round_tau

@[seg_round]
theorem p02r143_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))))
    (hrd1 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar132 [p02meLoadA a] 21 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar133 [p02meLoadA a] 22 p) := by
  seg_round_tau

@[seg_round]
theorem p02r144_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar133 [p02meLoadA a] 22 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar134 [p02meLoadA a] 23 p) := by
  seg_round_eval

@[seg_round]
theorem p02r145_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar134 [p02meLoadA a] 23 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar135 [p02meLoadA a] 24 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_571 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r146_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_571 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar135 [p02meLoadA a] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar136 [p02meLoadA a] 25 p) := by
  seg_round_eval

@[seg_round]
theorem p02r147_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar136 [p02meLoadA a] 25 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar137 [p02meLoadA a] 26 p) := by
  seg_round_tau

@[seg_round]
theorem p02r148_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar137 [p02meLoadA a] 26 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar138 [p02meLoadA a] 27 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_548 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_549 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r149_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_548 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_549 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar138 [p02meLoadA a] 27 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar139 [p02meLoadA a] 28 p) := by
  seg_round_eval

@[seg_round]
theorem p02r150_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar139 [p02meLoadA a] 28 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar69 [p02meLoadA a] 29 p) := by
  seg_round_tau

@[seg_round]
theorem p02r151_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar69 [p02meLoadA a] 29 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar52 [p02meLoadA a] 30 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_546 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r152_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_546 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar52 [p02meLoadA a] 30 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar70 [p02meLoadA a] 31 p) := by
  seg_round_eval

@[seg_round]
theorem p02r155_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar72 [p02meLoadA a] 33 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar56 [p02meLoadA a] 34 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_545 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r156_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_545 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar56 [p02meLoadA a] 34 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar73 [p02meLoadA a] 35 p) := by
  seg_round_tau

@[seg_round]
theorem p02r162_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar78 [p02meLoadA a] 40 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar79 [p02meLoadA a] 41 p) := by
  seg_round_eval

@[seg_round]
theorem p02r163_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar79 [p02meLoadA a] 41 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar80 [p02meLoadA a] 42 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_608 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r164_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_608 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar80 [p02meLoadA a] 42 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar81 [p02meLoadA a] 43 p) := by
  seg_round_eval

@[seg_round]
theorem p02r165_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar81 [p02meLoadA a] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar82 a) [p02meLoadA a, p02meLoadA a] 43 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r166_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar82 a) [p02meLoadA a, p02meLoadA a] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar83 a) [p02meLoadA a, p02meLoadA a] 44 p) := by
  seg_round_tau

@[seg_round]
theorem p02r167_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar83 a) [p02meLoadA a, p02meLoadA a] 44 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar84 [p02meLoadA a, p02meLoadA a] 45 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_609 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_610 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r168_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_609 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hrd1 : lookup_env p02s_a_610 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar84 [p02meLoadA a, p02meLoadA a] 45 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar85 a) [p02meLoadA a, p02meLoadA a] 46 p) := by
  seg_round_eval

@[seg_round]
theorem p02r169_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar85 a) [p02meLoadA a, p02meLoadA a] 46 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar86 a) [p02meLoadA a, p02meLoadA a] 47 p) := by
  seg_round_tau

@[seg_round]
theorem p02r170_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar86 a) [p02meLoadA a, p02meLoadA a] 47 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar140 [p02meLoadA a, p02meLoadA a] 48 p) := by
  seg_round_guard_ltT

@[seg_round]
theorem p02r171_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar140 [p02meLoadA a, p02meLoadA a] 48 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar141 [p02meLoadA a, p02meLoadA a] 49 p) := by
  seg_round_tau

@[seg_round]
theorem p02r172_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar141 [p02meLoadA a, p02meLoadA a] 49 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar89 [p02meLoadA a, p02meLoadA a] 50 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_603 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_604 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r173_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_603 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_604 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar89 [p02meLoadA a, p02meLoadA a] 50 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar142 [p02meLoadA a, p02meLoadA a] 51 p) := by
  seg_round_eval

@[seg_round]
theorem p02r174_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar142 [p02meLoadA a, p02meLoadA a] 51 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar143 [p02meLoadA a, p02meLoadA a] 52 p) := by
  seg_round_tau

@[seg_round]
theorem p02r175_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar143 [p02meLoadA a, p02meLoadA a] 52 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar92 [p02meLoadA a, p02meLoadA a] 53 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_598 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_599 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r176_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_598 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_599 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar92 [p02meLoadA a, p02meLoadA a] 53 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar144 [p02meLoadA a, p02meLoadA a] 54 p) := by
  seg_round_eval

@[seg_round]
theorem p02r177_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar144 [p02meLoadA a, p02meLoadA a] 54 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar94 [p02meLoadA a, p02meLoadA a] 55 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_614 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r178_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_614 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar94 [p02meLoadA a, p02meLoadA a] 55 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar145 [p02meLoadA a, p02meLoadA a] 56 p) := by
  seg_round_eval

@[seg_round]
theorem p02r182_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar148 [p02meLoadA a, p02meLoadA a] 59 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar149 [p02meLoadA a, p02meLoadA a] 60 p) := by
  seg_round_eval

@[seg_round]
theorem p02r183_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar149 [p02meLoadA a, p02meLoadA a] 60 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar150 [p02meLoadA a, p02meLoadA a] 61 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_630 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r184_lo_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_630 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar150 [p02meLoadA a, p02meLoadA a] 61 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar151 [p02meLoadA a, p02meLoadA a] 62 p) := by
  seg_round_eval

@[seg_round]
theorem p02r185_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar151 [p02meLoadA a, p02meLoadA a] 62 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar152 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 62 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r188_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar154 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 64 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar155 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 65 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_624 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r189_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_624 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar155 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 65 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar156 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 66 p) := by
  seg_round_neg_lit

@[seg_round]
theorem p02r190_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar156 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 66 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar157 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 67 p) := by
  seg_round_tau

@[seg_round]
theorem p02r191_lo_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar157 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 67 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar158 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 68 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_625 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483647))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_626 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r192_lo_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_625 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (-2147483647))))))
    (hrd1 : lookup_env p02s_a_626 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hp0 : ¬ 0 < a)
    (hp1 : a < 0) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar158 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 68 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar159 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 69 p) := by
  seg_round_arith_sub

end RelSem.P02
