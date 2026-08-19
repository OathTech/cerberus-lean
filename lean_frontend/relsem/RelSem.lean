/-
  RelSem — spike/relsem (2026-08-19): relational semantics skeleton
  (Layer 2) over the generated fuel opsem. See
  docs/2026-08-19_relsem-spike.md for the design record.
-/

import RelSem.ExecModel
import RelSem.Machine
import RelSem.RunNDT
import RelSem.Cerberus
import RelSem.IrisCoupling
-- arc-7 S1: the in-build axiom audit (golean pattern) — a lib member,
-- so `lake build RelSem` elaborates it and drift fails the build.
import RelSem.Audit
