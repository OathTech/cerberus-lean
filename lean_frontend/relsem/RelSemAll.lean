/-
  RelSem — spike/relsem (2026-08-19): relational semantics skeleton
  (Layer 2) over the generated fuel opsem. See
  docs/2026-08-19_relsem-spike.md for the design record.
-/

import RelSem.ExecModel
import RelSem.Machine
import RelSem.RunND
import RelSem.Cerberus
import RelSem.Call
import RelSem.FuelHooks
-- (RelSem.IrisCoupling — the arc-7 paper-only coupling sketch —
-- DELETED at arc-18 R3: zero importers; the realized coupling is the
-- modules below; record docs/2026-08-20_arc7-s4-iris-coupling.md.)
-- arc-7 S4: the iris-lean coupling (language instance, SC state
-- interpretation, WP rules, THE adequacy theorem).
-- arc-9 S2: the WP-workbench layers (L1 kits + L2 walker) + their
-- exactness pins (Kit/Audit, enforced in-build via RelSem.Audit).
import RelSem.Tactics.AppEqAttr
import RelSem.Tactics.AppWalk
import RelSem.Kit.AppEq
import RelSem.Kit.Env
import RelSem.Kit.Eval
import RelSem.Kit.Mem
import RelSem.Kit.Round
import RelSem.Kit.Loop
import RelSem.Kit.Audit
import RelSem.IrisLang
import RelSem.IrisState
import RelSem.IrisRules
import RelSem.IrisAdequacy
-- arc-16 S1: the per-step language instance (the Iris refounding).
import RelSem.PerStep
import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.PerStepSmoke
import RelSem.MemLocal
import RelSem.CerbHeapRA
import RelSem.CerbHeapWP
import RelSem.CerbHeapDemo
-- arc-18 C2: the heap-route walk substrate (the one-route migration's
-- rules + adequacy bridges over CerbMemInterp).
import RelSem.CerbHeapWalk
-- arc-16 S3: the runner-observation algebra + the wp-tactic layer.
-- (The dormant S3 half — PerStepPeel + the wpk_round_* law library —
-- was DELETED at arc-18 C2 per the Q1 [USER] ruling; archive = the
-- arc-16 S3 record, last commit carrying the files cited in
-- docs/2026-08-25_arc18-c2-one-route.md.)
import RelSem.PerStepRunner
-- arc-18 C2: the transitional OwnP surface (the disentangled
-- interpretation the ambient family + smokes still bind; C5-bound).
import RelSem.PerStepOwnP
-- arc-17 S0: the discharge-engine substrate — the named-state
-- emitter (derive_state/derive_state_step) + the memoized
-- ground-fact discharger backing wp_side.
import RelSem.DeriveState
import RelSem.WpGround
-- arc-17 S2: the law-driven round evaluator (memory-round successors
-- through the Kit law chain; the S1-registered input #1).
import RelSem.RoundEval
-- arc-17 S1: the per-construct law registry (fixture-independent
-- construct laws; the equation-supply frontier).
import RelSem.ConstructLaws
import RelSem.PerStepTactics
import RelSem.PerStepTacSmoke
-- arc-16 S4: the threaded effect state (∀-seed statement family) +
-- the T1 threaded acceptance fixture.
import RelSem.Threaded
import RelSem.T1Threaded
import RelSem.T2Threaded
import RelSem.T3Threaded
-- arc-7 S4: the T1 program term (emitted, drift-gated) + the WP-route
-- smoke theorems.
import RelSem.T1Core
import RelSem.T1File
import RelSem.T1
-- arc-7 S5a: the T2–T5 slate program terms (emitted, drift-gated) +
-- the T2 app-equation chain.
import RelSem.SlateCore
import RelSem.SlateFiles
import RelSem.SlateWP
import RelSem.T2AppEq
import RelSem.T2
import RelSem.T3AppEq
import RelSem.T3
-- (T5Fixture — the arc-9 ambient-era fixture layer — RETIRED at
-- arc-18 R4 with T5Prefix/T5Iter: the T5 flagship now lives in
-- RelSem.T5 over the T5W walk supply.)
import RelSem.T5Walks
import RelSem.T5Inv
import RelSem.T5Seam
import RelSem.T5Spine
import RelSem.T5
-- arc-17 S2: the completed acceptance probe (un-parked — the whole
-- t6 run through the law-driven round evaluator; ∀-seed theorems).
import RelSem.T6Probe
-- arc-18 R2: the segment layer + faces
import RelSem.Segment
import RelSem.SegmentFaces
import RelSem.T7Walks
import RelSem.T7
-- arc-17 S2: the guarded ∀-seed T4 statement + apartness hypothesis
-- + the evaluator-driven prefix (theorem = enumerated remaining work;
-- the in-file frontier note is the S2 record's park).
import RelSem.T4Threaded
import RelSem.T4Defs
import RelSem.T4AppEq
import RelSem.T4
-- arc-18 R6: the breadth-campaign corpus (batch 1, EASY tier).
import RelSem.Corpus.E1
import RelSem.Corpus.E2
import RelSem.Corpus.E3
import RelSem.Corpus.E4
import RelSem.Corpus.E5
-- arc-18 R6: batch 2 (CENSUS tier).
import RelSem.Corpus.C4
import RelSem.Corpus.C5
import RelSem.Corpus.C3A
import RelSem.Corpus.C3B
-- arc-7 S1: the in-build axiom audit (golean pattern) — a lib member,
-- so `lake build RelSem` elaborates it and drift fails the build.
import RelSem.Audit
