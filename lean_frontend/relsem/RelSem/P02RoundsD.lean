/-
  RelSem.P02RoundsD — PERF-1 generated supply (chunk
  4/4; see P02Rounds.lean header and
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
theorem p02r279_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_569 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar20 [p02meLoadA (0)] 19 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar131 [p02meLoadA (0)] 20 p) := by
  seg_round_eval

@[seg_round]
theorem p02r280_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar131 [p02meLoadA (0)] 20 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar132 [p02meLoadA (0)] 21 p) := by
  seg_round_tau

@[seg_round]
theorem p02r281_mC (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))))
    (hrd1 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar132 [p02meLoadA (0)] 21 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar133 [p02meLoadA (0)] 22 p) := by
  seg_round_tau

@[seg_round]
theorem p02r282_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar133 [p02meLoadA (0)] 22 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar134 [p02meLoadA (0)] 23 p) := by
  seg_round_eval

@[seg_round]
theorem p02r283_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar134 [p02meLoadA (0)] 23 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar135 [p02meLoadA (0)] 24 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_571 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r284_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_571 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar135 [p02meLoadA (0)] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar136 [p02meLoadA (0)] 25 p) := by
  seg_round_eval

@[seg_round]
theorem p02r285_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar136 [p02meLoadA (0)] 25 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar137 [p02meLoadA (0)] 26 p) := by
  seg_round_tau

@[seg_round]
theorem p02r286_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar137 [p02meLoadA (0)] 26 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar138 [p02meLoadA (0)] 27 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_548 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_549 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r287_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_548 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_549 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar138 [p02meLoadA (0)] 27 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar139 [p02meLoadA (0)] 28 p) := by
  seg_round_eval

@[seg_round]
theorem p02r288_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar139 [p02meLoadA (0)] 28 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar69 [p02meLoadA (0)] 29 p) := by
  seg_round_tau

@[seg_round]
theorem p02r289_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar69 [p02meLoadA (0)] 29 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar52 [p02meLoadA (0)] 30 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_546 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r290_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_546 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar52 [p02meLoadA (0)] 30 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar70 [p02meLoadA (0)] 31 p) := by
  seg_round_eval

@[seg_round]
theorem p02r293_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar72 [p02meLoadA (0)] 33 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar56 [p02meLoadA (0)] 34 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_545 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r294_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_545 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar56 [p02meLoadA (0)] 34 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar73 [p02meLoadA (0)] 35 p) := by
  seg_round_tau

@[seg_round]
theorem p02r300_mC (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar78 [p02meLoadA (0)] 40 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar79 [p02meLoadA (0)] 41 p) := by
  seg_round_eval

@[seg_round]
theorem p02r301_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar79 [p02meLoadA (0)] 41 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar80 [p02meLoadA (0)] 42 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_608 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r302_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_608 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar80 [p02meLoadA (0)] 42 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar81 [p02meLoadA (0)] 43 p) := by
  seg_round_eval

@[seg_round]
theorem p02r303_mC (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes (0)).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes (0))[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar81 [p02meLoadA (0)] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar206 [p02meLoadA (0), p02meLoadA (0)] 43 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r304_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar206 [p02meLoadA (0), p02meLoadA (0)] 43 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar207 [p02meLoadA (0), p02meLoadA (0)] 44 p) := by
  seg_round_tau

@[seg_round]
theorem p02r305_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar207 [p02meLoadA (0), p02meLoadA (0)] 44 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar84 [p02meLoadA (0), p02meLoadA (0)] 45 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_609 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_610 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r306_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_609 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_610 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar84 [p02meLoadA (0), p02meLoadA (0)] 45 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar208 [p02meLoadA (0), p02meLoadA (0)] 46 p) := by
  seg_round_eval

@[seg_round]
theorem p02r307_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar208 [p02meLoadA (0), p02meLoadA (0)] 46 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar209 [p02meLoadA (0), p02meLoadA (0)] 47 p) := by
  seg_round_tau

@[seg_round]
theorem p02r308_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar209 [p02meLoadA (0), p02meLoadA (0)] 47 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar87 [p02meLoadA (0), p02meLoadA (0)] 48 p) := by
  seg_round_guard_ltF

@[seg_round]
theorem p02r309_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar87 [p02meLoadA (0), p02meLoadA (0)] 48 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar88 [p02meLoadA (0), p02meLoadA (0)] 49 p) := by
  seg_round_tau

@[seg_round]
theorem p02r310_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar88 [p02meLoadA (0), p02meLoadA (0)] 49 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar89 [p02meLoadA (0), p02meLoadA (0)] 50 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_603 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_604 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r311_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_603 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_604 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar89 [p02meLoadA (0), p02meLoadA (0)] 50 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar90 [p02meLoadA (0), p02meLoadA (0)] 51 p) := by
  seg_round_eval

@[seg_round]
theorem p02r312_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar90 [p02meLoadA (0), p02meLoadA (0)] 51 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar91 [p02meLoadA (0), p02meLoadA (0)] 52 p) := by
  seg_round_tau

@[seg_round]
theorem p02r313_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar91 [p02meLoadA (0), p02meLoadA (0)] 52 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar92 [p02meLoadA (0), p02meLoadA (0)] 53 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_598 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_599 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r314_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_598 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))))
    (hrd1 : lookup_env p02s_a_599 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar92 [p02meLoadA (0), p02meLoadA (0)] 53 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar93 [p02meLoadA (0), p02meLoadA (0)] 54 p) := by
  seg_round_eval

@[seg_round]
theorem p02r315_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar93 [p02meLoadA (0), p02meLoadA (0)] 54 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar94 [p02meLoadA (0), p02meLoadA (0)] 55 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_614 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r316_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_614 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar94 [p02meLoadA (0), p02meLoadA (0)] 55 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar95 [p02meLoadA (0), p02meLoadA (0)] 56 p) := by
  seg_round_eval

@[seg_round]
theorem p02r317_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar95 [p02meLoadA (0), p02meLoadA (0)] 56 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar96 [p02meLoadA (0), p02meLoadA (0)] 57 p) := by
  seg_round_tau

@[seg_round]
theorem p02r318_mC (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))))
    (hrd1 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar96 [p02meLoadA (0), p02meLoadA (0)] 57 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar97 [p02meLoadA (0), p02meLoadA (0)] 58 p) := by
  seg_round_tau

@[seg_round]
theorem p02r319_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar97 [p02meLoadA (0), p02meLoadA (0)] 58 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar98 [p02meLoadA (0), p02meLoadA (0)] 59 p) := by
  seg_round_eval

@[seg_round]
theorem p02r320_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar98 [p02meLoadA (0), p02meLoadA (0)] 59 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar99 [p02meLoadA (0), p02meLoadA (0)] 60 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_616 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r321_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_616 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar99 [p02meLoadA (0), p02meLoadA (0)] 60 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar100 [p02meLoadA (0), p02meLoadA (0)] 61 p) := by
  seg_round_eval

@[seg_round]
theorem p02r322_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar100 [p02meLoadA (0), p02meLoadA (0)] 61 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar101 [p02meLoadA (0), p02meLoadA (0)] 62 p) := by
  seg_round_tau

@[seg_round]
theorem p02r323_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar101 [p02meLoadA (0), p02meLoadA (0)] 62 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar102 [p02meLoadA (0), p02meLoadA (0)] 63 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_593 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_594 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r324_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_593 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_594 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar102 [p02meLoadA (0), p02meLoadA (0)] 63 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar103 [p02meLoadA (0), p02meLoadA (0)] 64 p) := by
  seg_round_eval

@[seg_round]
theorem p02r325_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar103 [p02meLoadA (0), p02meLoadA (0)] 64 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar104 [p02meLoadA (0), p02meLoadA (0)] 65 p) := by
  seg_round_tau

@[seg_round]
theorem p02r326_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar104 [p02meLoadA (0), p02meLoadA (0)] 65 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar105 [p02meLoadA (0), p02meLoadA (0)] 66 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_591 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1))))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r327_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_591 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar105 [p02meLoadA (0), p02meLoadA (0)] 66 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar106 [p02meLoadA (0), p02meLoadA (0)] 67 p) := by
  seg_round_eval

@[seg_round]
theorem p02r330_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar108 [p02meLoadA (0), p02meLoadA (0)] 69 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar109 [p02meLoadA (0), p02meLoadA (0)] 70 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_544 Vfalse p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r331_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_544 [p.f₁] = some Vfalse) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar109 [p02meLoadA (0), p02meLoadA (0)] 70 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar110 [p02meLoadA (0), p02meLoadA (0)] 71 p) := by
  seg_round_tau

@[seg_round]
theorem p02r332_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar110 [p02meLoadA (0), p02meLoadA (0)] 71 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar111 [p02meLoadA (0), p02meLoadA (0)] 72 p) := by
  seg_round_tau

@[seg_round]
theorem p02r333_mC (p : T1P)
    (hrd0 : lookup_env p02s_b [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar111 [p02meLoadA (0), p02meLoadA (0)] 72 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar112 [p02meLoadA (0), p02meLoadA (0)] 73 p) := by
  seg_round_eval

@[seg_round]
theorem p02r334_mC (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar112 [p02meLoadA (0), p02meLoadA (0)] 73 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar113 [p02meLoadA (0), p02meLoadA (0)] 74 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_656 (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r335_mC (p : T1P)
    (hrd0 : lookup_env p02s_a_656 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar113 [p02meLoadA (0), p02meLoadA (0)] 74 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar114 [p02meLoadA (0), p02meLoadA (0)] 75 p) := by
  seg_round_eval

@[seg_round]
theorem p02r336_mC (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocBS)
    (hb : ∀ i : Nat, (hi : i < (xBytes b).length) → p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes b)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar114 [p02meLoadA (0), p02meLoadA (0)] 75 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar115 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 75 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r337_mC (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar115 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 75 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar116 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 76 p) := by
  seg_round_eval

@[seg_round]
theorem p02r338_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar116 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 76 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar117 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 77 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_655 (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r339_mC (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_655 [p.f₁] = some (Vobject (OVpointer (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar117 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 77 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar118 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 78 p) := by
  seg_round_eval

@[seg_round]
theorem p02r340_mC (b : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocXS)
    (hb : ∀ i : Nat, (hi : i < (xBytes (0)).length) → p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes (0))[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar118 b) [p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 78 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar210 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 78 { p with aS := p.aS + 1 }) := by
  seg_round_load

@[seg_round]
theorem p02r341_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar210 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 78 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar211 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 79 p) := by
  seg_round_tau

@[seg_round]
theorem p02r342_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar211 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 79 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar121 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 80 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_650 (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))) (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_651 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) p.f₁)) }) := by
  seg_round_tau

@[seg_round]
theorem p02r343_mC (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_650 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0))))))
    (hrd1 : lookup_env p02s_a_651 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar121 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 80 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar212 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 81 p) := by
  seg_round_arith_add_prim_z (b)

@[seg_round]
theorem p02r344_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar212 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 81 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar213 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 82 p) := by
  seg_round_tau

@[seg_round]
theorem p02r345_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar213 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 82 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar124 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 83 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_657 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) p.f₁) }) := by
  seg_round_tau

@[seg_round]
theorem p02r346_mC (b : Int) (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) (p : T1P)
    (hrd0 : lookup_env p02s_a_657 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar124 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 83 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam p02ar61 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 84 { p with f₁ := (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) p02s_a_658 (Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))) p.f₁) }) := by
  seg_round_conv_ret (b)

@[seg_round]
theorem p02r347_mC (b : Int) (p : T1P)
    (hrd0 : lookup_env p02s_a_658 [p.f₁] = some (Vloaded (LVspecified (OVinteger (.IV .Prov_none b))))) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam p02ar61 [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 84 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam (p02ar214 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85 p) := by
  seg_round_eval

@[seg_round]
theorem p02term_mC (b : Int) (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam (p02ar214 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85 p)
      = (NDactive (Sum.inr [Step_done2 ((Vloaded (LVspecified (OVinteger (.IV .Prov_none b)))))]),
         p02fam (p02ar214 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85 p) := by
  seg_round_term

@[seg_block]
theorem p02blk0 {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 3
      ⟨ctlOf (p02fam p02ar1 [] 1 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar4 [] 4 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar1 [] 1)) (famO := (p02fam p02ar2 [] 2)) (cO := ctlOf (p02fam p02ar2 [] 2 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar2 [] 2)) (famO := (p02fam p02ar3 [] 3)) (cO := ctlOf (p02fam p02ar3 [] 3 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar3 [] 3)) (famO := (p02fam p02ar4 [] 4)) (cO := ctlOf (p02fam p02ar4 [] 4 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))

@[seg_block]
theorem p02blk1 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 3
      ⟨ctlOf (p02fam p02ar21 [p02meLoadA a] 20 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar24 [p02meLoadA a] 23 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar21 [p02meLoadA a] 20)) (famO := (p02fam p02ar22 [p02meLoadA a] 21)) (cO := ctlOf (p02fam p02ar22 [p02meLoadA a] 21 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar22 [p02meLoadA a] 21)) (famO := (p02fam p02ar23 [p02meLoadA a] 22)) (cO := ctlOf (p02fam p02ar23 [p02meLoadA a] 22 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar23 [p02meLoadA a] 22)) (famO := (p02fam p02ar24 [p02meLoadA a] 23)) (cO := ctlOf (p02fam p02ar24 [p02meLoadA a] 23 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))

@[seg_block]
theorem p02blk2 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam (p02ar28 a) [p02meLoadA a, p02meLoadA a] 26 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam (p02ar30 a) [p02meLoadA a, p02meLoadA a] 28 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam (p02ar28 a) [p02meLoadA a, p02meLoadA a] 26)) (famO := (p02fam (p02ar29 a) [p02meLoadA a, p02meLoadA a] 27)) (cO := ctlOf (p02fam (p02ar29 a) [p02meLoadA a, p02meLoadA a] 27 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam (p02ar29 a) [p02meLoadA a, p02meLoadA a] 27)) (famO := (p02fam (p02ar30 a) [p02meLoadA a, p02meLoadA a] 28)) (cO := ctlOf (p02fam (p02ar30 a) [p02meLoadA a, p02meLoadA a] 28 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl)))

@[seg_block]
theorem p02blk3 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar53 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar55 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar53 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50)) (famO := (p02fam p02ar54 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51)) (cO := ctlOf (p02fam p02ar54 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar54 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51)) (famO := (p02fam p02ar55 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52)) (cO := ctlOf (p02fam p02ar55 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk4 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar57 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar59 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar57 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54)) (famO := (p02fam p02ar58 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55)) (cO := ctlOf (p02fam p02ar58 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar58 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55)) (famO := (p02fam p02ar59 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56)) (cO := ctlOf (p02fam p02ar59 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl)))

@[seg_block]
theorem p02blk5 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar70 [p02meLoadA a] 31 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar72 [p02meLoadA a] 33 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar70 [p02meLoadA a] 31)) (famO := (p02fam p02ar71 [p02meLoadA a] 32)) (cO := ctlOf (p02fam p02ar71 [p02meLoadA a] 32 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar71 [p02meLoadA a] 32)) (famO := (p02fam p02ar72 [p02meLoadA a] 33)) (cO := ctlOf (p02fam p02ar72 [p02meLoadA a] 33 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk6 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 5
      ⟨ctlOf (p02fam p02ar73 [p02meLoadA a] 35 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar78 [p02meLoadA a] 40 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar73 [p02meLoadA a] 35)) (famO := (p02fam p02ar74 [p02meLoadA a] 36)) (cO := ctlOf (p02fam p02ar74 [p02meLoadA a] 36 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar74 [p02meLoadA a] 36)) (famO := (p02fam p02ar75 [p02meLoadA a] 37)) (cO := ctlOf (p02fam p02ar75 [p02meLoadA a] 37 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar75 [p02meLoadA a] 37)) (famO := (p02fam p02ar76 [p02meLoadA a] 38)) (cO := ctlOf (p02fam p02ar76 [p02meLoadA a] 38 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar76 [p02meLoadA a] 38)) (famO := (p02fam p02ar77 [p02meLoadA a] 39)) (cO := ctlOf (p02fam p02ar77 [p02meLoadA a] 39 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar77 [p02meLoadA a] 39)) (famO := (p02fam p02ar78 [p02meLoadA a] 40)) (cO := ctlOf (p02fam p02ar78 [p02meLoadA a] 40 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))))

@[seg_block]
theorem p02blk7 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 3
      ⟨ctlOf (p02fam p02ar145 [p02meLoadA a, p02meLoadA a] 56 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar148 [p02meLoadA a, p02meLoadA a] 59 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar145 [p02meLoadA a, p02meLoadA a] 56)) (famO := (p02fam p02ar146 [p02meLoadA a, p02meLoadA a] 57)) (cO := ctlOf (p02fam p02ar146 [p02meLoadA a, p02meLoadA a] 57 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar146 [p02meLoadA a, p02meLoadA a] 57)) (famO := (p02fam p02ar147 [p02meLoadA a, p02meLoadA a] 58)) (cO := ctlOf (p02fam p02ar147 [p02meLoadA a, p02meLoadA a] 58 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar147 [p02meLoadA a, p02meLoadA a] 58)) (famO := (p02fam p02ar148 [p02meLoadA a, p02meLoadA a] 59)) (cO := ctlOf (p02fam p02ar148 [p02meLoadA a, p02meLoadA a] 59 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))

@[seg_block]
theorem p02blk8 (a : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam (p02ar152 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 62 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam (p02ar154 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 64 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam (p02ar152 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 62)) (famO := (p02fam (p02ar153 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 63)) (cO := ctlOf (p02fam (p02ar153 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 63 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam (p02ar153 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 63)) (famO := (p02fam (p02ar154 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 64)) (cO := ctlOf (p02fam (p02ar154 a) [p02meLoadA a, p02meLoadA a, p02meLoadA a] 64 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk9 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar188 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar190 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar188 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92)) (famO := (p02fam p02ar189 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93)) (cO := ctlOf (p02fam p02ar189 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar189 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93)) (famO := (p02fam p02ar190 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94)) (cO := ctlOf (p02fam p02ar190 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk10 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar191 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 96 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar193 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar191 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 96)) (famO := (p02fam p02ar192 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 97)) (cO := ctlOf (p02fam p02ar192 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 97 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar192 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 97)) (famO := (p02fam p02ar193 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98)) (cO := ctlOf (p02fam p02ar193 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 98 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk11 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar70 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar72 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar70 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 50)) (famO := (p02fam p02ar71 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51)) (cO := ctlOf (p02fam p02ar71 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar71 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 51)) (famO := (p02fam p02ar72 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52)) (cO := ctlOf (p02fam p02ar72 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 52 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk12 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 5
      ⟨ctlOf (p02fam p02ar73 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar78 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar73 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 54)) (famO := (p02fam p02ar74 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55)) (cO := ctlOf (p02fam p02ar74 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar74 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 55)) (famO := (p02fam p02ar75 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56)) (cO := ctlOf (p02fam p02ar75 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar75 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 56)) (famO := (p02fam p02ar76 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 57)) (cO := ctlOf (p02fam p02ar76 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 57 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar76 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 57)) (famO := (p02fam p02ar77 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 58)) (cO := ctlOf (p02fam p02ar77 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 58 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar77 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 58)) (famO := (p02fam p02ar78 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59)) (cO := ctlOf (p02fam p02ar78 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))))

@[seg_block]
theorem p02blk13 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar106 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 86 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar108 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 88 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar106 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 86)) (famO := (p02fam p02ar107 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 87)) (cO := ctlOf (p02fam p02ar107 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 87 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar107 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 87)) (famO := (p02fam p02ar108 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 88)) (cO := ctlOf (p02fam p02ar108 [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 88 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk14 (a : Int) (b : Int) {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar106 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar108 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar106 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 92)) (famO := (p02fam p02ar107 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93)) (cO := ctlOf (p02fam p02ar107 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar107 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 93)) (famO := (p02fam p02ar108 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94)) (cO := ctlOf (p02fam p02ar108 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 94 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk15 {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar70 [p02meLoadA (0)] 31 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar72 [p02meLoadA (0)] 33 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar70 [p02meLoadA (0)] 31)) (famO := (p02fam p02ar71 [p02meLoadA (0)] 32)) (cO := ctlOf (p02fam p02ar71 [p02meLoadA (0)] 32 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar71 [p02meLoadA (0)] 32)) (famO := (p02fam p02ar72 [p02meLoadA (0)] 33)) (cO := ctlOf (p02fam p02ar72 [p02meLoadA (0)] 33 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

@[seg_block]
theorem p02blk16 {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 5
      ⟨ctlOf (p02fam p02ar73 [p02meLoadA (0)] 35 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar78 [p02meLoadA (0)] 40 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar73 [p02meLoadA (0)] 35)) (famO := (p02fam p02ar74 [p02meLoadA (0)] 36)) (cO := ctlOf (p02fam p02ar74 [p02meLoadA (0)] 36 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar74 [p02meLoadA (0)] 36)) (famO := (p02fam p02ar75 [p02meLoadA (0)] 37)) (cO := ctlOf (p02fam p02ar75 [p02meLoadA (0)] 37 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar75 [p02meLoadA (0)] 37)) (famO := (p02fam p02ar76 [p02meLoadA (0)] 38)) (cO := ctlOf (p02fam p02ar76 [p02meLoadA (0)] 38 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar76 [p02meLoadA (0)] 38)) (famO := (p02fam p02ar77 [p02meLoadA (0)] 39)) (cO := ctlOf (p02fam p02ar77 [p02meLoadA (0)] 39 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar77 [p02meLoadA (0)] 39)) (famO := (p02fam p02ar78 [p02meLoadA (0)] 40)) (cO := ctlOf (p02fam p02ar78 [p02meLoadA (0)] 40 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl))))))

@[seg_block]
theorem p02blk17 {GF : Iris.BundledGFunctors}
    [CerbStGS GF] {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState} {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 2
      ⟨ctlOf (p02fam p02ar106 [p02meLoadA (0), p02meLoadA (0)] 67 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩
      ⟨ctlOf (p02fam p02ar108 [p02meLoadA (0), p02meLoadA (0)] 69 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)), S, env, mr, al, bs⟩ :=
  (Seg.SegStep.trans (Seg.link_ctl (famI := (p02fam p02ar106 [p02meLoadA (0), p02meLoadA (0)] 67)) (famO := (p02fam p02ar107 [p02meLoadA (0), p02meLoadA (0)] 68)) (cO := ctlOf (p02fam p02ar107 [p02meLoadA (0), p02meLoadA (0)] 68 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_tau)
      (fun p => rfl))
    (Seg.link_ctl (famI := (p02fam p02ar107 [p02meLoadA (0), p02meLoadA (0)] 68)) (famO := (p02fam p02ar108 [p02meLoadA (0), p02meLoadA (0)] 69)) (cO := ctlOf (p02fam p02ar108 [p02meLoadA (0), p02meLoadA (0)] 69 (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)))
      (p02ShapeC _ _ _) (p02ShapeC _ _ _)
      (fun _ h _ => p02_inv h)
      (fun p _ => by seg_round_eval)
      (fun p => rfl)))

end RelSem.P02
