/-
  RelSem.P02RoundsA — PERF-1 generated supply (chunk
  1/4; see P02Rounds.lean header and
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
theorem p02r0_hi_lo_mA_mB_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam0 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar1 [] 1 p) := by
  seg_round_eval

@[seg_round]
theorem p02r4_hi_lo_mA_mB_mC (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar4 [] 4 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar5 [] 5 p) := by
  seg_round_eval

@[seg_round]
theorem p02r5_hi_lo_mA_mB_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar5 [] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar6 [] 6 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_563 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r6_hi_lo_mA_mB_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_563 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar6 [] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar7 [] 7 p) := by
  seg_round_eval

@[seg_round]
theorem p02r7_hi_lo_mA_mB (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar7 [] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar8 a) [p02meLoadA a] 7 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r8_hi_lo_mA_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar8 a) [p02meLoadA a] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar9 a) [p02meLoadA a] 8 p) := by
  seg_round_tau

@[seg_round]
theorem p02r9_hi_lo_mA_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar9 a) [p02meLoadA a] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar10 [p02meLoadA a] 9 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_564 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_565 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r10_hi_lo_mA_mB (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_564 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hrd1 : lookup_env p02s_a_565 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar10 [p02meLoadA a] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar11 a) [p02meLoadA a] 10 p) := by
  seg_round_eval

@[seg_round]
theorem p02r11_hi_lo_mA_mB (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar11 a) [p02meLoadA a] 10 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar12 a) [p02meLoadA a] 11 p) := by
  seg_round_tau

@[seg_round]
theorem p02r12_hi_mA (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hp0 : 0 < a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar12 a) [p02meLoadA a] 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar13 [p02meLoadA a] 12 p) := by
  seg_round_guard_gtT

@[seg_round]
theorem p02r13_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar13 [p02meLoadA a] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar14 [p02meLoadA a] 13 p) := by
  seg_round_tau

@[seg_round]
theorem p02r14_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar14 [p02meLoadA a] 13 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar15 [p02meLoadA a] 14 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_558 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_559 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r15_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_558 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_559 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar15 [p02meLoadA a] 14 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar16 [p02meLoadA a] 15 p) := by
  seg_round_eval

@[seg_round]
theorem p02r16_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar16 [p02meLoadA a] 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar17 [p02meLoadA a] 16 p) := by
  seg_round_tau

@[seg_round]
theorem p02r17_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar17 [p02meLoadA a] 16 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar18 [p02meLoadA a] 17 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_553 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_554 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r18_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_553 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_554 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar18 [p02meLoadA a] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar19 [p02meLoadA a] 18 p) := by
  seg_round_eval

@[seg_round]
theorem p02r19_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar19 [p02meLoadA a] 18 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar20 [p02meLoadA a] 19 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_569 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r20_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_569 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar20 [p02meLoadA a] 19 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar21 [p02meLoadA a] 20 p) := by
  seg_round_eval

@[seg_round]
theorem p02r24_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar24 [p02meLoadA a] 23 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar25 [p02meLoadA a] 24 p) := by
  seg_round_eval

@[seg_round]
theorem p02r25_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar25 [p02meLoadA a] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar26 [p02meLoadA a] 25 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_578 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r26_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_578 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar26 [p02meLoadA a] 25 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar27 [p02meLoadA a] 26 p) := by
  seg_round_eval

@[seg_round]
theorem p02r27_hi_mA (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar27 [p02meLoadA a] 26 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar28 a) [p02meLoadA a, p02meLoadA a] 26 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r30_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar30 a) [p02meLoadA a, p02meLoadA a] 28 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar31 [p02meLoadA a, p02meLoadA a] 29 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_579 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_580 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r31_hi_mA (a : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_579 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))))
    (hrd1 : lookup_env p02s_a_580 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hp0 : 0 < a) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar31 [p02meLoadA a, p02meLoadA a] 29 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar32 a) [p02meLoadA a, p02meLoadA a] 30 p) := by
  seg_round_arith_sub

@[seg_round]
theorem p02r32_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar32 a) [p02meLoadA a, p02meLoadA a] 30 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar33 a) [p02meLoadA a, p02meLoadA a] 31 p) := by
  seg_round_eval

@[seg_round]
theorem p02r33_hi_mA (a : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar33 a) [p02meLoadA a, p02meLoadA a] 31 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar34 a) [p02meLoadA a, p02meLoadA a] 32 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_577 (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r34_hi_mA (a : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_577 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar34 a) [p02meLoadA a, p02meLoadA a] 32 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar35 a) [p02meLoadA a, p02meLoadA a] 33 p) := by
  seg_round_eval

@[seg_round]
theorem p02r35_hi_mA (a : Int) (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocBS)
    (hb : ∀ i : Nat, (hi : i < (xBytes b).length) → p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes b)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar35 a) [p02meLoadA a, p02meLoadA a] 33 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar36 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 33 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r36_hi_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar36 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 33 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar37 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 34 p) := by
  seg_round_tau

@[seg_round]
theorem p02r37_hi_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar37 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 34 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar38 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 35 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_584 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_585 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647 - a))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r38_hi_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_584 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))))
    (hrd1 : lookup_env p02s_a_585 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647 - a)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar38 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 35 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar39 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 36 p) := by
  seg_round_eval

@[seg_round]
theorem p02r39_hi_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar39 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 36 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar40 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 37 p) := by
  seg_round_tau

@[seg_round]
theorem p02r40_hi (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hp0 : 0 < a)
    (hp1 : 2147483647 - a < b) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar40 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 37 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar41 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 38 p) := by
  seg_round_guard_gtT

@[seg_round]
theorem p02r41_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar41 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 38 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar42 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 39 p) := by
  seg_round_tau

@[seg_round]
theorem p02r42_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar42 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 39 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar43 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 40 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_572 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_573 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r43_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_572 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_573 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar43 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 40 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar44 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 41 p) := by
  seg_round_eval

@[seg_round]
theorem p02r44_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar44 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 41 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar45 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 42 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_589 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r45_hi_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar45 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 42 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar46 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 43 p) := by
  seg_round_tau

@[seg_round]
theorem p02r46_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_589 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar46 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar47 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 44 p) := by
  seg_round_eval

@[seg_round]
theorem p02r47_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar47 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 44 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar48 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 45 p) := by
  seg_round_tau

@[seg_round]
theorem p02r48_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar48 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 45 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar49 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 46 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_548 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_549 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r49_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_548 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_549 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar49 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 46 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar50 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 47 p) := by
  seg_round_eval

@[seg_round]
theorem p02r50_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar50 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 47 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar51 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 48 p) := by
  seg_round_tau

@[seg_round]
theorem p02r51_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar51 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 48 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar52 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 49 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_546 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r52_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_546 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar52 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 49 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar53 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50 p) := by
  seg_round_eval

@[seg_round]
theorem p02r55_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar55 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar56 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 53 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_545 Vtrue p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r56_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_545 [p.f₁] = some Vtrue) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar56 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 53 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar57 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54 p) := by
  seg_round_tau

@[seg_round]
theorem p02r59_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar59 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar60 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 57 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_590 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r60_hi (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_590 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar60 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 57 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar61 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 58 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_658 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))) p.f₁) }) := by
  seg_round_eval

@[seg_round]
theorem p02r61_hi (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_658 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar61 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 58 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar62 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 p) := by
  seg_round_eval

@[seg_round]
theorem p02term_hi (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar62 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 p)
      = (NDactive (Sum.inr [Step_done2 ((Vloaded (LVspecified (OVinteger (.IV .Prov_none (2147483647))))))]),
         p02fam p02ar62 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 p) := by
  seg_round_term

@[seg_round]
theorem p02r63_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hp0 : 0 < a)
    (hp1 : ¬ 2147483647 - a < b) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar40 a b) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 37 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar63 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 38 p) := by
  seg_round_guard_gtF

@[seg_round]
theorem p02r64_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar63 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 38 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar64 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 39 p) := by
  seg_round_tau

@[seg_round]
theorem p02r65_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar64 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 39 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar43 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 40 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_572 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_573 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r66_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_572 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_573 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar43 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 40 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar65 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 41 p) := by
  seg_round_eval

@[seg_round]
theorem p02r67_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar65 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 41 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar45 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 42 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_589 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r68_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_589 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar46 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar66 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 44 p) := by
  seg_round_eval

@[seg_round]
theorem p02r69_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar66 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 44 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar67 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 45 p) := by
  seg_round_tau

@[seg_round]
theorem p02r70_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar67 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 45 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar49 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 46 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_548 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_549 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r71_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_548 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_549 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar49 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 46 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar68 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 47 p) := by
  seg_round_eval

@[seg_round]
theorem p02r72_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar68 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 47 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar69 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 48 p) := by
  seg_round_tau

@[seg_round]
theorem p02r73_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar69 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 48 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar52 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 49 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_546 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r74_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_546 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar52 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 49 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar70 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50 p) := by
  seg_round_eval

@[seg_round]
theorem p02r77_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar72 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar56 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 53 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_545 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r78_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_545 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar56 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 53 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar73 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54 p) := by
  seg_round_tau

@[seg_round]
theorem p02r84_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar78 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar79 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 60 p) := by
  seg_round_eval

@[seg_round]
theorem p02r85_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar79 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 60 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar80 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 61 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_608 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r86_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_608 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar80 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 61 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar81 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 62 p) := by
  seg_round_eval

@[seg_round]
theorem p02r87_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes a).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes a)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar81 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 62 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar82 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 62 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r88_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar82 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 62 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar83 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 63 p) := by
  seg_round_tau

@[seg_round]
theorem p02r89_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar83 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 63 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar84 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 64 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_609 (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_610 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r90_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_609 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none a)))))
    (hrd1 : lookup_env p02s_a_610 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar84 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 64 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar85 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 65 p) := by
  seg_round_eval

@[seg_round]
theorem p02r91_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar85 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 65 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar86 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 66 p) := by
  seg_round_tau

@[seg_round]
theorem p02r92_mA (a : Int) (b : Int) (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hp0 : 0 < a)
    (hp1 : ¬ 2147483647 - a < b) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar86 a) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 66 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar87 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 67 p) := by
  seg_round_guard_ltF

@[seg_round]
theorem p02r93_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar87 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 67 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar88 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 68 p) := by
  seg_round_tau

@[seg_round]
theorem p02r94_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar88 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 68 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar89 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 69 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_603 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_604 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r95_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_603 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_604 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar89 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 69 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar90 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 70 p) := by
  seg_round_eval

@[seg_round]
theorem p02r96_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar90 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 70 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar91 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 71 p) := by
  seg_round_tau

@[seg_round]
theorem p02r97_mA (a : Int) (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar91 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 71 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar92 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 72 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_598 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_599 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r98_mA (a : Int) (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_598 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_599 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar92 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 72 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar93 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 73 p) := by
  seg_round_eval

end RelSem.P02
