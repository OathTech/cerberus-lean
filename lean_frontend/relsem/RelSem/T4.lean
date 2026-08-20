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
      — the sym-supply seed drawn by `initial_core_run_state`
      (generated Core_run_aux). CORRECTED arc-7 S5c (audit-1 F3): this
      is the SECOND process draw, not the first. native/fresh_int.c is
      post-increment from CERB_FRESH_BASE = 1<<20, so the first draw is
      1048576 — consumed by the harness executable's startup floor
      probe (Main.lean, "Sym non-escape floor assertion") BEFORE the
      driver state is constructed; the seed draw observed by the
      pinned-probe run states is therefore 1048577 (and the NEG-store
      transform's two fresh binders are supply increments 1048577 and
      1048578, not further process draws). The hypothesis pins exactly
      the state Main `--call` establishes; test_verify's
      t4-env-witness probe gate-witnesses all three conjuncts
      first-in-process.

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
    process-global externs at the state the harness establishes. The
    third conjunct's 1048577 is the SECOND process draw (the sym-supply
    seed; the startup floor probe consumes the first, 1048576 — the
    F3-corrected account in the header). -/
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

/-- **T4's UB-freedom** (WP route, same hypotheses). RESTATED
    CerbND-shaped in arc-7 S5c (audit-1 F2): conclusion is
    `CallHarnessUBFree`; the seqModel form is only the route's
    intermediate. -/
theorem T4_ubFree :
    T4EnvHyp →
    ∀ x : Int, intRange x →
      CallHarnessUBFree t4File.tagDefs t4File "memb"
        [intValue x] t4Fs := by
  intro ⟨htags, hdig, hfresh⟩ x hx
  exact callHarnessUBFree_of_ubFree (callUBFree_of_app_eq_wp
    (t4_app_eq htags hdig hfresh x hx.1 hx.2))

/-- T4's outcome-SET companion statement (arc-7 S5c, audit-1 F5),
    under the same harness-environment hypotheses. -/
def T4OutcomesStatement : Prop :=
  T4EnvHyp →
  ∀ x : Int, intRange x →
    CerbND.runND (callND t4File.tagDefs t4File "memb" [intValue x])
        (initial_driver_state t4File t4Fs)
      = [(Active (finalize t4File.tagDefs "callND" (drDone x)), [],
          drDone x)]

/-- **T4's outcome-set singleton** (under `T4EnvHyp`). -/
theorem T4Outcomes : T4OutcomesStatement :=
  fun ⟨htags, hdig, hfresh⟩ x hx =>
    runND_active (t4_app_eq htags hdig hfresh x hx.1 hx.2)

end RelSem.T4
