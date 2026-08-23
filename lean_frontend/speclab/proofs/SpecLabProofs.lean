/-
SpecLabProofs — arc-15 S1: the proof-side lib.

PROOF LAYER ONLY ("boring executable specs in the front, Iris party
in the back"): imports the relsem workbench to reason about speclab
STATEMENTS (the SpecLab lib — which never imports back; the in-build
statement-TCB gate + grep floor enforce the direction).

S1 status (the P1 spike's disposition, proof register entry S1-P1):
the concrete-instance EXEC equations
(`app (drive (divmodI8FileOf m) …) … = (NDactive r, st')`) are
PARKED-PRICED — the walker's entry pattern (T5Prefix `entry5_walk`)
needs per-fixture dnms wrappers + state avatars + segment lemmas that
do not exist for the speclab fixtures, and the i8 instance's Core is
1262 lines vs the T5 fixture's 172 (79 rounds, 45 walker-automatic at
k=0), with FOUR law surfaces the slate never exercised (main-driven
drive prefix, Eccall proc-call rounds, block-scope array store_lock
init, Ememop/PtrValidForDeref). Whole-run `app_defeq`/rfl on the
drive is BANNED (D7: compositional chains only). Price: L — its own
slice, sequenced after T5 lands (the symbolic-initializer route then
upgrades sample-∀ to family-∀ in the same campaign).

What IS kernel-checked here at S1: the refutation-structure lemmas —
the exec-statement family is anti-vacuous at the logic level (a
verdict-1 fact refutes the verdict-0 claim on any nonempty run), so
the plant's "unprovable theorem" face is a THEOREM SCHEMA awaiting
only the parked exec equations. The statement-level bridge
(`sample_model_iff_stream`) and the whole pure layer live in the
SpecLab lib (see SpecLabAudit.lean pins).
-/

import SpecLab.DivModFiles
import SpecLab.ByteArrFiles
import SpecLab.ListAppendFiles
import SpecLab.TreeRotFiles
import SpecLab.CnSeedFiles
import RelSem.Machine
import RelSem.RunND

open SpecLab SpecLab.DivMod

set_option autoImplicit false

namespace SpecLabProofs

/-- Distinct verdicts are distinct driver values (the mismatch-index
observable separates: `Specified 1 ≠ Specified 0`). -/
theorem specifiedInt_injective (a b : Int) (h : a ≠ b) :
    specifiedInt a ≠ specifiedInt b := by
  intro he
  apply h
  simpa [specifiedInt, CerbMem.integerIval] using he

/-- VERDICT EXCLUSIVITY: on any nonempty run, `HarnessRunsTo f a` and
`HarnessRunsTo f b` for distinct verdicts are mutually exclusive —
the harness statement family cannot be vacuously green while the
comparator reports a mismatch. -/
theorem harnessRunsTo_exclusive (f : file core_run_annotation)
    (a b : Int) (hab : a ≠ b)
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND (drive f.tagDefs false f ["cmdname"])
          (initial_driver_state f CerbFS.fs_initial_state)) :
    ¬ (HarnessRunsTo f a ∧ HarnessRunsTo f b) := by
  rintro ⟨ha, hb⟩
  obtain ⟨out, tr, st', hmem⟩ := hne
  obtain ⟨r1, hr1, hv1⟩ := ha out tr st' hmem
  obtain ⟨r2, hr2, hv2⟩ := hb out tr st' hmem
  have : r1 = r2 := by
    rw [hr1] at hr2
    injection hr2
  apply specifiedInt_injective a b hab
  rw [← hv1, this, hv2]

/-- THE PLANT'S REFUTATION SCHEMA (the "unprovable theorem" face at
the logic level): once the parked exec equation delivers
`HarnessRunsTo divmodI8PlantFile 1` (the gate exe already checks the
verdict EXECUTABLY: Specified(1)), the plant's healthy-shaped claim
is REFUTED. Conditional pending the parked walk — the schema itself
is kernel-checked now. -/
theorem plantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive divmodI8PlantFile.tagDefs false divmodI8PlantFile
            ["cmdname"])
          (initial_driver_state divmodI8PlantFile
            CerbFS.fs_initial_state))
    (h1 : HarnessRunsTo divmodI8PlantFile 1) :
    ¬ DivModI8PlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive divmodI8PlantFile 1 0 (by decide) hne
    ⟨h1, h0⟩

/-! ## arc-15 S2 (R2): the byte-blaster plants' refutation schemas.
    `harnessRunsTo_exclusive` is generic in the file — the R1 schema
    transfers to the array rung with zero new machinery (proof
    register S2-P5: the refutation layer is rung-independent). Same
    epistemic status as S1: the exec equations delivering the
    verdict-3/verdict-1 facts are parked (S1-P1 campaign); the gate
    exe checks them EXECUTABLY today. -/

open SpecLab.ByteArr in
/-- The memcpy off-by-one plant refutes the healthy claim once the
parked exec equation delivers `HarnessRunsTo memcpyPlantFile 3` (the
mismatch-index comparator naming dst byte 0). -/
theorem memcpyPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive memcpyPlantFile.tagDefs false memcpyPlantFile
            ["cmdname"])
          (initial_driver_state memcpyPlantFile
            CerbFS.fs_initial_state))
    (h3 : HarnessRunsTo memcpyPlantFile 3) :
    ¬ MemcpyPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive memcpyPlantFile 3 0 (by decide) hne
    ⟨h3, h0⟩

open SpecLab.ByteArr in
/-- The getarr wrong-index plant refutes the healthy claim once the
parked exec equation delivers `HarnessRunsTo getarrPlantFile 1`. -/
theorem getarrPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive getarrPlantFile.tagDefs false getarrPlantFile
            ["cmdname"])
          (initial_driver_state getarrPlantFile
            CerbFS.fs_initial_state))
    (h1 : HarnessRunsTo getarrPlantFile 1) :
    ¬ GetarrPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive getarrPlantFile 1 0 (by decide) hne
    ⟨h1, h0⟩

/-! ## arc-15 S3 (R3): the list plants' refutation schemas + the
    LEAK layer's exclusivity. `harnessRunsTo_exclusive` transfers
    again (rung-independent, the S2-P5b finding); the leak conjunct
    gets its own exclusivity lemma — the final allocation count is a
    FUNCTION of the outcome, so distinct counts refute each other on
    any nonempty run: the wrong-link plant's `baseline + 1` fact
    refutes its leak-free claim by logic, not just measurement. -/

open SpecLab.ListAppend in
/-- The wrong-link plant refutes the healthy claim once the parked
exec equation delivers `HarnessRunsTo appendLinkPlantFile 255` (the
structural break's length-arm verdict; the gate exe checks it
executably today). -/
theorem appendLinkPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive appendLinkPlantFile.tagDefs false appendLinkPlantFile
            ["cmdname"])
          (initial_driver_state appendLinkPlantFile
            CerbFS.fs_initial_state))
    (h255 : HarnessRunsTo appendLinkPlantFile 255) :
    ¬ AppendLinkPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive appendLinkPlantFile 255 0 (by decide) hne
    ⟨h255, h0⟩

open SpecLab.ListAppend in
/-- The wrong-element plant refutes the healthy claim once the parked
exec equation delivers `HarnessRunsTo appendElemPlantFile 3`. -/
theorem appendElemPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive appendElemPlantFile.tagDefs false appendElemPlantFile
            ["cmdname"])
          (initial_driver_state appendElemPlantFile
            CerbFS.fs_initial_state))
    (h3 : HarnessRunsTo appendElemPlantFile 3) :
    ¬ AppendElemPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive appendElemPlantFile 3 0 (by decide) hne
    ⟨h3, h0⟩

open SpecLab.ListAppend in
/-- LEAK EXCLUSIVITY: distinct final-allocation counts are mutually
exclusive on any nonempty run — the leak observable cannot be
vacuously "leak-free" while the map size says otherwise. -/
theorem finalAllocs_exclusive (f : file core_run_annotation)
    (a b : Nat) (hab : a ≠ b)
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND (drive f.tagDefs false f ["cmdname"])
          (initial_driver_state f CerbFS.fs_initial_state)) :
    ¬ (HarnessFinalAllocs f a ∧ HarnessFinalAllocs f b) := by
  rintro ⟨ha, hb⟩
  obtain ⟨out, tr, st', hmem⟩ := hne
  exact hab ((ha out tr st' hmem).symm.trans (hb out tr st' hmem))

open SpecLab.ListAppend in
/-- The wrong-link plant's LEAK refutation: once the exec equation
delivers the `baseline + 1` fact (the orphaned node; checked
executably by the gate exe), the plant's leak-free claim is REFUTED
— the teardown conjunct is anti-vacuous at the logic level. -/
theorem linkPlantLeak_refutes_leakFree
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive appendLinkPlantFile.tagDefs false appendLinkPlantFile
            ["cmdname"])
          (initial_driver_state appendLinkPlantFile
            CerbFS.fs_initial_state))
    (hleak : LinkPlantLeakClaim) :
    ¬ HarnessFinalAllocs appendLinkPlantFile driverBaseline := by
  intro h0
  exact finalAllocs_exclusive appendLinkPlantFile
    (driverBaseline + 1) driverBaseline (by decide) hne ⟨hleak, h0⟩

/-! ## arc-15 S4 (R4): the tree plants' refutation schemas.
    `harnessRunsTo_exclusive` and `finalAllocs_exclusive` transfer
    once more (rung-independent — the S2-P5b finding, third
    confirmation); the drop plant gets BOTH refutation faces (verdict
    AND leak), and the swap plant demonstrates the observable's
    separation: its leak face is the BASELINE (leak-free broken
    target), so only its verdict refutes. Epistemic status as at
    S1-S3: the exec equations delivering the refuting facts are
    parked (the exec-equation campaign); the gate exe checks them
    EXECUTABLY today (Specified(7) / Specified(255) / allocations
    baseline+1). -/

open SpecLab.TreeRot in
/-- The wrong-child-swap plant refutes the healthy claim once the
parked exec equation delivers `HarnessRunsTo swapPlantFile 7` (the
locus val's first wire byte — the mismatch index localizes the
un-rotated node). -/
theorem swapPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive swapPlantFile.tagDefs false swapPlantFile
            ["cmdname"])
          (initial_driver_state swapPlantFile
            CerbFS.fs_initial_state))
    (h7 : HarnessRunsTo swapPlantFile 7) :
    ¬ SwapPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive swapPlantFile 7 0 (by decide) hne
    ⟨h7, h0⟩

open SpecLab.TreeRot in
/-- The dropped-subtree plant refutes the healthy claim once the
parked exec equation delivers `HarnessRunsTo dropPlantFile 255`
(structural breaks land in the length arm). -/
theorem dropPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive dropPlantFile.tagDefs false dropPlantFile
            ["cmdname"])
          (initial_driver_state dropPlantFile
            CerbFS.fs_initial_state))
    (h255 : HarnessRunsTo dropPlantFile 255) :
    ¬ DropPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive dropPlantFile 255 0 (by decide) hne
    ⟨h255, h0⟩

open SpecLab.TreeRot SpecLab.ListAppend in
/-- The dropped-subtree plant's LEAK refutation: once the exec
equation delivers the `baseline + 1` fact (the orphaned middle
subtree — `TreeRot.orphanedAt` = 1 at the pinned instance, checked
executably by the gate exe), the plant's leak-free claim is REFUTED
— rotation's allocation-neutrality conjunct is anti-vacuous at the
logic level. -/
theorem dropPlantLeak_refutes_leakFree
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive dropPlantFile.tagDefs false dropPlantFile
            ["cmdname"])
          (initial_driver_state dropPlantFile
            CerbFS.fs_initial_state))
    (hleak : DropPlantLeakClaim) :
    ¬ HarnessFinalAllocs dropPlantFile driverBaseline := by
  intro h0
  exact finalAllocs_exclusive dropPlantFile
    (driverBaseline + 1) driverBaseline (by decide) hne ⟨hleak, h0⟩

/-! ## arc-15 S5 (R5): the CN-seed swap plant's refutation schema.
    `harnessRunsTo_exclusive` transfers a fourth time
    (rung-independent — the S2-P5b finding is now a series). The
    lookup family has no schema: no pinned layer (the CoreParser
    enum-ctype gap, registered) — its plant's red face lives in the
    differential lane only. Epistemic status as at S1-S4: the exec
    equation delivering `HarnessRunsTo pairSwapPlantFile 9` is parked
    (the exec-equation campaign); the gate exe checks it EXECUTABLY
    today (Specified(9)). -/

open SpecLab.CnSeed in
/-- The lost-update plant refutes the healthy claim once the parked
exec equation delivers `HarnessRunsTo pairSwapPlantFile 9` (the
mismatch-index comparator naming post-state cell 1's low byte). Off
the diagonal the index is structurally forced
(`CnSeed.swapPlant_blind_iff`: verdict 0 ⟺ a = b — the
kernel-characterized blind set). -/
theorem pairSwapPlantClaim_refuted_of_run
    (hne : ∃ out tr st',
      (out, tr, st') ∈
        CerbND.runND
          (drive pairSwapPlantFile.tagDefs false pairSwapPlantFile
            ["cmdname"])
          (initial_driver_state pairSwapPlantFile
            CerbFS.fs_initial_state))
    (h9 : HarnessRunsTo pairSwapPlantFile 9) :
    ¬ SwapPlantHealthyClaim := by
  intro h0
  exact harnessRunsTo_exclusive pairSwapPlantFile 9 0 (by decide) hne
    ⟨h9, h0⟩

/-! ## In-build axiom pins (captured verbatim at S1; growth fails the
    build — the SpecLabAudit discipline, proofs-side). -/

/-- info: 'SpecLabProofs.specifiedInt_injective' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLabProofs.specifiedInt_injective
/-- info: 'SpecLabProofs.harnessRunsTo_exclusive' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.harnessRunsTo_exclusive
/-- info: 'SpecLabProofs.plantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.plantClaim_refuted_of_run
/-- info: 'SpecLabProofs.memcpyPlantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.memcpyPlantClaim_refuted_of_run
/-- info: 'SpecLabProofs.getarrPlantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.getarrPlantClaim_refuted_of_run
/--
info: 'SpecLabProofs.appendLinkPlantClaim_refuted_of_run' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms SpecLabProofs.appendLinkPlantClaim_refuted_of_run
/--
info: 'SpecLabProofs.appendElemPlantClaim_refuted_of_run' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms SpecLabProofs.appendElemPlantClaim_refuted_of_run
/-- info: 'SpecLabProofs.finalAllocs_exclusive' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.finalAllocs_exclusive
/-- info: 'SpecLabProofs.linkPlantLeak_refutes_leakFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.linkPlantLeak_refutes_leakFree
/-- info: 'SpecLabProofs.swapPlantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.swapPlantClaim_refuted_of_run
/-- info: 'SpecLabProofs.dropPlantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.dropPlantClaim_refuted_of_run
/-- info: 'SpecLabProofs.dropPlantLeak_refutes_leakFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLabProofs.dropPlantLeak_refutes_leakFree
/--
info: 'SpecLabProofs.pairSwapPlantClaim_refuted_of_run' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms SpecLabProofs.pairSwapPlantClaim_refuted_of_run

end SpecLabProofs
