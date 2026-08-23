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
import RelSem.IrisCoupling
-- arc-7 S4: the iris-lean coupling (language instance, SC state
-- interpretation, WP rules, THE adequacy theorem).
-- arc-9 S2: the WP-workbench layers (L1 kits + L2 walker) + their
-- exactness pins (Kit/Audit, enforced in-build via RelSem.Audit).
import RelSem.Tactics.AppEqAttr
import RelSem.Tactics.AppWalk
import RelSem.Kit.AppEq
import RelSem.Kit.Eval
import RelSem.Kit.Mem
import RelSem.Kit.Round
import RelSem.Kit.Loop
import RelSem.Kit.Audit
import RelSem.IrisLang
import RelSem.IrisState
import RelSem.IrisRules
import RelSem.IrisAdequacy
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
import RelSem.T5Fixture
import RelSem.T5Prefix
import RelSem.T5Iter
import RelSem.T5Ladder
import RelSem.T4Defs
import RelSem.T4AppEq
import RelSem.T4
-- arc-7 S1: the in-build axiom audit (golean pattern) — a lib member,
-- so `lake build RelSem` elaborates it and drift fails the build.
import RelSem.Audit
