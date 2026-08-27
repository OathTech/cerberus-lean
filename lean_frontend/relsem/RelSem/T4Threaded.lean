/-
  RelSem.T4Threaded — V0 (2026-08-27): THE T4 STATEMENT, HONEST-
  UNPROVED, in the consistency-freshness house shape.

  tests/verify/t4_struct_member.c: `int memb(int v)` — struct member
  store/read through `struct S { int a; int b; }` (the arc-7 exit
  criterion program).

  THE FRESHNESS FINALIZATION (V0, the Q3 amendment — "guards die
  now"): T4 is the program whose exec path READS the fresh-symbol
  supply (the NEG-store transform's two draws), and the arc-16 S4 P3
  falsifier showed a drawn symbol can CAPTURE a static binding at a
  colliding seed (seed = `a_529`'s hash number; the unrestricted
  ∀-seed statement is false under the capture reading). The former
  guard — `T4SeedApart`/`t4MinStaticSym`, a per-program numeric bound
  in the headline hypothesis — is DELETED; the statement now
  quantifies over CONSISTENT EXECUTIONS (the can't-happen-ND
  formulation, relsemcore/RelSem/Threaded.lean §CONSISTENCY): the
  excluded runs are exactly those whose own draw window captures the
  program's static vocabulary (`t4Prior`) — named for what they are,
  assume-not-assert. Anti-vacuity: `consistentRun_of_supply_le`
  (proved once) + the per-program bound check at proof time.

  TOMBSTONE (the V0 kill basket — record
  docs/2026-08-27_v0-statements-and-ban.md): the guarded ∀-seed proof
  (`verify_fn membSpec; seg_auto` over T4Walks' two evaluator-minted
  walk drives, wa 44 + wb 12 rounds) and its engine room are DELETED;
  the statement stands as an HONEST-UNPROVED TARGET for the V3b
  memory-views slice (struct field points-to).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.SlateFiles

set_option autoImplicit false

namespace RelSem.T4

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- The harness filesystem. RE-HOMED from the deleted
    RelSem/T4Walks.lean at V0 (text unchanged). -/
def t4Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T4's pure spec: the result value is the injected integer,
    Specified (read back through the struct member). -/
def t4Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-- The threaded harness-environment hypotheses: the tag-table and
    TU-digest externs at the state the harness establishes
    (hypothesis-pins on opaque externs — the ambient discipline;
    UNCHANGED by the freshness finalization, which replaced only the
    seed guard). -/
def T4EnvHypThr : Prop :=
  CerbTags.tagDefs () = t4File.tagDefs ∧
  CerberusFresh.digest () = ""

/-! ## THE STATEMENT (honest-unproved target; consistency-freshness
    house shape — the SeedApart guard is REPLACED by quantification
    over consistent executions) -/

/-- THE T4 HEADLINE (fuel opsem only): under the environment
    hypotheses, for every int-range x, every CONSISTENT outcome of
    `callND(memb, [intValue x])` — the execution's own draw window
    non-capturing against `t4Prior` — is `Active x`, Specified.
    HONESTY LABEL: UNPROVED (V0 target; V3b re-proof). -/
def T4ThreadedStatement : Prop :=
  T4EnvHypThr →
  ∀ x : Int, intRange x →
    CallHarnessAdequateCns t4Prior t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)

/-- The UB-freedom companion. HONESTY LABEL: UNPROVED. -/
def T4ThreadedUBFreeStatement : Prop :=
  T4EnvHypThr →
  ∀ x : Int, intRange x →
    CallHarnessUBFreeCns t4Prior t4File.tagDefs t4File "memb"
      [intValue x] t4Fs

end RelSem.T4
