import CerbMem
import CerbGlobal
import CerbUtils
import CerbMemAllocatorProofs
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

/-! ## H3 — named kills and hygiene (seam-hygiene H3, 2026-09-19) -/

-- the allocator's kill is a NAMED constant, definitionally the text both engines print
example : CerbMem.oomKill = .Other (.MerrOther "Concrete.allocator: failed (out of memory)") := rfl
-- and the kernel contract is stated with it
#check @CerbMem.allocator_below_request_kills
-- the timing/log stubs are value identities (plain defs; no opaque, no IO.Ref)
example (s : String) (x : Nat) : CerbUtils.STD_ s x = x := rfl
example (s : String) : CerbUtils.begin_timing s = () := rfl
example : CerbUtils.end_timing () = () := rfl

/-! `BEq MemValue` is structural (`CerbMem.beqMemValue`); it must agree with the
    RETIRED `unsafe beqMemValueImpl` — witnessed on these 23 pairs through `==` on
    the build that still carried it (evidence `docs/2026-09-18_seam-hygiene-evidence/
    beq-memvalue-old-witness.txt`); `main` checks the new instance gives the same. -/
namespace BeqWitness
open CerbMem
def c0 : ctype := default
def c1 : ctype := Ctype [] (.Basic (.Integer .Bool0))
def i1 : MemValue := .MVinteger default (.IV .Prov_none 1)
def i2 : MemValue := .MVinteger default (.IV .Prov_none 2)
def i1p : MemValue := .MVinteger default (.IV (.Prov_some 3) 1)
def u0 : MemValue := .MVunspecified c0
def u1 : MemValue := .MVunspecified c1
def f1 : MemValue := .MVfloating default 1.0
def fnan : MemValue := .MVfloating default (0.0 / 0.0)
def p0 : MemValue := .MVpointer c0 (.PV .Prov_none (.PVnull c0))
def p1 : MemValue := .MVpointer c0 (.PV .Prov_none (.PVconcrete none 8))
def a0 : MemValue := .MVarray []
def a1 : MemValue := .MVarray [i1, i2]
def a1' : MemValue := .MVarray [i1, i2]
def a2 : MemValue := .MVarray [i1]
def a3 : MemValue := .MVarray [i2, i1]
def s1 : MemValue := .MVstruct default [(default, c0, i1)]
def s1' : MemValue := .MVstruct default [(default, c0, i1)]
def s2 : MemValue := .MVstruct default [(default, c0, i2)]
def s3 : MemValue := .MVstruct default []
def s4 : MemValue := .MVstruct default [(default, c1, i1)]
def n1 : MemValue := .MVunion default default i1
def n2 : MemValue := .MVunion default default i2
def pairs : List (String × MemValue × MemValue) :=
  [("u0,u0", u0, u0), ("u0,u1", u0, u1), ("i1,i1", i1, i1), ("i1,i2", i1, i2), ("i1,i1p", i1, i1p),
   ("f1,f1", f1, f1), ("fnan,fnan", fnan, fnan), ("p0,p0", p0, p0), ("p0,p1", p0, p1),
   ("a0,a0", a0, a0), ("a1,a1'", a1, a1'), ("a1,a2", a1, a2), ("a1,a3", a1, a3),
   ("s1,s1'", s1, s1'), ("s1,s2", s1, s2), ("s1,s3", s1, s3), ("s1,s4", s1, s4),
   ("n1,n1", n1, n1), ("n1,n2", n1, n2), ("u0,i1", u0, i1), ("a1,s1", a1, s1),
   ("[a1],[a1']", .MVarray [a1], .MVarray [a1']), ("[a1],[a2]", .MVarray [a1], .MVarray [a2])]
/-- the retired impl's answers, verbatim from the witness probe -/
def expected : List (String × Bool) :=
  [("u0,u0", true), ("u0,u1", false), ("i1,i1", true), ("i1,i2", false), ("i1,i1p", false),
   ("f1,f1", true), ("fnan,fnan", false), ("p0,p0", true), ("p0,p1", false),
   ("a0,a0", true), ("a1,a1'", true), ("a1,a2", false), ("a1,a3", false),
   ("s1,s1'", true), ("s1,s2", false), ("s1,s3", false), ("s1,s4", false),
   ("n1,n1", true), ("n1,n2", false), ("u0,i1", false), ("a1,s1", false),
   ("[a1],[a1']", true), ("[a1],[a2]", false)]
-- two of them at the kernel, structurally (no `decide`, no literal enumeration beyond the pin)
example : (a1 == a1') = true := rfl
example : (a1 == a2) = false := rfl
end BeqWitness

end OpaqueFailureTest

def main : IO UInt32 := do
  let got := OpaqueFailureTest.BeqWitness.pairs.map (fun (n, x, y) => (n, x == y))
  if got != OpaqueFailureTest.BeqWitness.expected then
    IO.eprintln s!"opaque-failure-test: FAIL — the structural BEq MemValue disagrees with the retired impl's witness: {repr got}"
    return 1
  IO.println "opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl); oomKill named; STD_/timing identities; structural BEq MemValue agrees with the retired impl on 23 pairs"
  return 0
