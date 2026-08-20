/-
  RelSem.T4 — arc-7 S5a (2026-08-20): **T4, THE EXIT-CRITERION TARGET**
  (struct-layout points-to), through the full WP route per D5.

  The slate theorem (charter T4):

    ∀ v : int-range, outcomes of callND(t4_memb, [v])
                       = {Specified(v)}, no UB

  — s.a := v survives the sibling write s.b := 7 at the pinned struct
  layout (member offsets +0/+4, size 8).

  THE HARNESS-ENVIRONMENT HYPOTHESES (the census boundary, surfaced):
  struct layout and the NEG-store transform's fresh draws read three
  process-global externs the kernel cannot see through (all on the
  declared boundary: with_tagDefs/forceIO census + runEffectful):

    * `CerbTags.tagDefs () = t4File.tagDefs` — the tag table the
      harness establishes before running (Main.lean --call:
      `setTagDefsIO runFile.tagDefs`);
    * `CerberusFresh.digest () = ""` — the TU-digest global at its
      initial (unset) value;
    * `runEffectful (fun () => CerberusFresh.freshIntIO ()) = 1048577`
      — the fresh-int supply at its start-of-process value
      (native/fresh_int.c).

  `T4Statement` quantifies over v UNDER these hypotheses
  (`T4EnvHyp`); everything else is as T1-T3 (statement-TCB: fuel
  opsem only). The Layer-2 residual is `RelSem.T4.t4_app_eq`
  (RelSem/T4AppEq.lean + RelSem/T4Defs.lean — fifty-six driver
  rounds: create/store-unspecified/two member stores through the
  exclusion transform/two loads/kill, both member_shift offsets
  discharged against the pinned layout).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.SlateWP
import RelSem.T4AppEq
import RelSem.T1

set_option autoImplicit false

namespace RelSem.T4

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-- The harness filesystem state (the driver default). -/
def t4Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- THE HARNESS-ENVIRONMENT HYPOTHESIS (header note): the three
    process-global externs at the state the harness establishes. -/
def T4EnvHyp : Prop :=
  CerbTags.tagDefs () = t4File.tagDefs ∧
  CerberusFresh.digest () = "" ∧
  runEffectful (fun () => CerberusFresh.freshIntIO ()) = 1048577

/-- T4's pure spec: the result value is the injected integer,
    Specified (read back through the struct member). -/
def t4Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-- THE T4 HEADLINE STATEMENT (fuel opsem only, under the
    harness-environment hypotheses). -/
def T4Statement : Prop :=
  T4EnvHyp →
  ∀ x : Int, intRange x →
    CallHarnessAdequate t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)

/-- **T4, THE EXIT CRITERION** (through the full WP route per D5). -/
theorem T4 : T4Statement := by
  intro ⟨htags, hdig, hfresh⟩ x hx
  exact callHarnessAdequate_of_app_eq_wp
    (t4_app_eq htags hdig hfresh x hx.1 hx.2) (t4_result_eq x)

/-- T4's direct-route twin (cross-check scaffolding per D5). -/
theorem T4_direct : T4Statement := by
  intro ⟨htags, hdig, hfresh⟩ x hx
  exact callHarnessAdequate_of_app_active
    (t4_app_eq htags hdig hfresh x hx.1 hx.2) (t4_result_eq x)

/-- **T4's UB-freedom** (WP route, same hypotheses). -/
theorem T4_ubFree :
    T4EnvHyp →
    ∀ x : Int, intRange x →
      CallUBFree t4File.tagDefs t4File "memb" [intValue x] t4Fs := by
  intro ⟨htags, hdig, hfresh⟩ x hx
  exact callUBFree_of_app_eq_wp
    (t4_app_eq htags hdig hfresh x hx.1 hx.2)

end RelSem.T4
