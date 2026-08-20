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
import RelSem.IrisLang
import RelSem.IrisState
import RelSem.IrisRules
import RelSem.IrisAdequacy
-- arc-7 S4: the T1 program term (emitted, drift-gated) + the WP-route
-- smoke theorems.
import RelSem.T1Core
import RelSem.T1File
import RelSem.T1
-- arc-7 S1: the in-build axiom audit (golean pattern) — a lib member,
-- so `lake build RelSem` elaborates it and drift fails the build.
import RelSem.Audit
