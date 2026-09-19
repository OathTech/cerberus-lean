import CerbMem
import CerbGlobal
import Lean.Elab.Command

/-! # OpaqueFailureTest — the hand-written seams' failure leaves have NO kernel equation

Seam-hygiene slice H1 (2026-09-18, charter `docs/2026-09-18_charter-seam-hygiene.md`
§2 H1; the consumer's request cerberus-sl `docs/2026-09-18_hidden-state-upstream-note.md`
§1 item 3). Before H1 every registered hand-written failure site was Lean's `panic!`, a
TRANSPARENT definition that reduces to `default`: the orchestrator's two probes

    example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := rfl
    example : CerbMem.bytesToInt [] false = none := rfl

COMPILED at the charter head `0eafc94a4` (evidence: the slice record §H1) — the kernel
model continued with a default value where the binary aborts and the oracle raises. H1
routes every such site through LemLib's `failwithI`, an `opaque` constant with no
equations (LemLib.lean:167-178), so an error branch is not provably equal to ANY value.

This test pins that property the way the build can check it:
  * the two identities above are NOT provable by `rfl` — each is a `#guard_msgs` on a
    FAILING `rfl`: if the leaf ever becomes transparent again, `rfl` succeeds, the
    expected error is missing, and the build is RED (the guard's failure direction is
    the loud one);
  * `failwithI` is an `opaque` constant in the compiled environment (a text-independent
    check of the same fact);
  * positive controls: the DEFAULT arms of the same functions still reduce by `rfl`
    (so the guards above are not vacuous — the functions themselves are transparent,
    only the failure leaf is opaque), and a registered arm still typechecks.

No proof method beyond `rfl`/`#guard_msgs`; no option bumps; kernel-only. -/

namespace OpaqueFailureTest

/-! ## The non-equations (the orchestrator's two probes, now failing) -/

/-- error: Tactic `rfl` failed: The left-hand side
  CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
is not definitionally equal to the right-hand side
  CerbMem.Provenance.Prov_none

⊢ CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none = CerbMem.Provenance.Prov_none
-/
#guard_msgs in
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := by rfl

/-- error: Tactic `rfl` failed: The left-hand side
  CerbMem.bytesToInt [] false
is not definitionally equal to the right-hand side
  none

⊢ CerbMem.bytesToInt [] false = none
-/
#guard_msgs in
example : CerbMem.bytesToInt [] false = none := by rfl

/-! ## The leaf is opaque in the environment (text-independent) -/

open Lean Elab Command in
#eval show CommandElabM Unit from do
  let env ← getEnv
  match env.find? ``failwithI with
  | some (.opaqueInfo _) => pure ()
  | some _ => throwError "OpaqueFailureTest: `failwithI` is no longer an `opaque` constant — the seams' failure leaf would have kernel equations again"
  | none => throwError "OpaqueFailureTest: `failwithI` not found in the environment"

/-! ## Positive controls -/

-- the DEFAULT arms of the same functions reduce (the functions are transparent; only the leaf is not)
example : CerbMem.combineProv .Prov_none .Prov_none = .Prov_none := rfl
example : CerbMem.combineProv .Prov_device .Prov_none = .Prov_device := rfl
example : CerbMem.combineProv (.Prov_some 3) (.Prov_some 3) = .Prov_some 3 := rfl
example : CerbMem.bytesToInt [{ value := none }] false = none := rfl

-- registered arms still typecheck at their declared types (the seam compiled; these name them)
#check (CerbMem.casePtrval : _)
#check (CerbMem.targetPtrSize : Nat)
#check (CerbMem.bytesToInt : List CerbMem.AbsByte → Bool → Option Int)

/-! ## H2 — the switch-conditioned arms reduce to their defaults (seam-hygiene H2, 2026-09-19)

`CerbMem` writes every switch-conditioned arm of impl_mem.ml as
`if CerbGlobal.has_switch … then <loud kill> else <default>`; the switch set is the
empty list (`CerbGlobal.switches = []`), so each test is `false` by `rfl` and each arm
reduces to its default — the statement a consumer proves through. -/

example : CerbGlobal.has_switch .strict_pointer_equality = false := rfl
example : CerbGlobal.has_switch .strict_pointer_relationals = false := rfl
example : CerbGlobal.has_switch (.pointer_arith .PERMISSIVE) = false := rfl
example : CerbGlobal.has_switch (.pointer_arith .STRICT) = false := rfl
example : CerbGlobal.has_switch .zero_initialised = false := rfl
example : CerbGlobal.has_switch .strict_reads = false := rfl
example : CerbGlobal.has_switch .forbid_nullptr_free = false := rfl
example : CerbGlobal.has_switch .zap_dead_pointers = false := rfl
example : CerbGlobal.is_PNVI () = false := rfl
example : CerbGlobal.has_strict_pointer_arith () = false := rfl

-- hence an arm IS its default: gt_ptrval on two concrete pointers is the address comparison
example (loc : CerbLocation.Loc) (a1 a2 : Int) :
    CerbMem.gtPtrval loc (.PV .Prov_none (.PVconcrete none a1)) (.PV .Prov_none (.PVconcrete none a2))
      = CerbMem.memReturn (decide (a1 > a2)) := rfl

end OpaqueFailureTest

def main : IO Unit := do
  IO.println "opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl)"
