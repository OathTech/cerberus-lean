/-
  RelSem — spike/relsem (2026-08-19): relational semantics skeleton
  (Layer 2) over the generated fuel opsem. See
  docs/2026-08-19_relsem-spike.md for the design record.

  2026-08-27 KILL-LIST EXECUTION (operator-ratified, record
  docs/2026-08-27_kill-list-execution.md): the ambient theorem family
  (T1–T4 + AppEq chains' carriers), the arc-7 Iris shell
  (IrisLang/IrisState/IrisRules/IrisAdequacy + SlateWP), the
  transitional OwnP surface (PerStepOwnP/PerStepRunner/PerStepSmoke/
  PerStepTacSmoke), the chase machinery (Tactics/AppWalk/WalkTrace/
  AppEqAttr + Kit/AppEq), the concrete-input theorem slate (T6Probe,
  T7/T7Walks, Corpus/*) and the parked concrete reproducers are
  DELETED. T1Walks/T2Walks/T3Walks are the slimmed trio-clean walk
  supplies (formerly T?AppEq) consumed by the KEPT threaded theorems.
-/

import RelSem.ExecModel
import RelSem.Machine
import RelSem.RunND
import RelSem.Cerberus
import RelSem.Call
import RelSem.FuelHooks
-- the workbench kits (L1) + their exactness pins (Kit/Audit,
-- enforced in-build via RelSem.Audit).
import RelSem.Kit.Env
import RelSem.Kit.Eval
import RelSem.Kit.Mem
import RelSem.Kit.Round
import RelSem.Kit.Loop
import RelSem.Kit.Audit
-- arc-16 S1: the per-step language instance (the Iris refounding).
import RelSem.PerStep
import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.MemLocal
import RelSem.CerbHeapRA
import RelSem.CerbHeapWP
import RelSem.CerbHeapDemo
-- arc-18 C2: the heap-route walk substrate (the one-route migration's
-- rules + adequacy bridges over CerbMemInterp).
import RelSem.CerbHeapWalk
-- arc-17 S0: the discharge-engine substrate — the named-state
-- emitter (derive_state/derive_state_step) + the memoized
-- ground-fact discharger backing wp_side.
import RelSem.DeriveState
import RelSem.WpGround
-- arc-17 S2: the law-driven round evaluator (memory-round successors
-- through the Kit law chain).
import RelSem.RoundEval
-- arc-17 S1: the per-construct law registry (fixture-independent
-- construct laws; the equation-supply frontier).
import RelSem.ConstructLaws
import RelSem.LawRegistry
import RelSem.PerStepTactics
-- arc-16 S4: the threaded effect state (∀-seed statement family).
import RelSem.Threaded
-- the program terms (emitted, drift-gated) + fixture data.
import RelSem.T1Core
import RelSem.T1File
import RelSem.SlateCore
import RelSem.SlateFiles
-- the trio-clean walk supplies (formerly T?AppEq; slimmed at the
-- kill-list execution) + the threaded flagship theorems.
import RelSem.T1Walks
import RelSem.T2Walks
import RelSem.T3Walks
import RelSem.T1Threaded
import RelSem.T2Threaded
import RelSem.T3Threaded
-- arc-18: the segment layer + faces, and the T4/T5 flagships.
import RelSem.Segment
import RelSem.SegmentFaces
import RelSem.T4Walks
import RelSem.T4Threaded
import RelSem.T5Walks
import RelSem.T5Inv
import RelSem.T5Seam
import RelSem.T5Spine
import RelSem.T5
-- arc-7 S1: the in-build axiom audit (golean pattern) — a lib member,
-- so `lake build RelSem` elaborates it and drift fails the build.
import RelSem.Audit
