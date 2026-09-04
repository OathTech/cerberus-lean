/-
  CerbFuel — the fuel-exhaustion atom and message.

  Hand-written seam (lean_frontend/handwritten_copy.manifest), imported
  by the GENERATED Nondeterminism.lean via
  `declare {lean} extra_import `CerbFuel`` (nondeterminism.lem; the
  debug.lem:4 mechanism), so that the `declare {lean} fuel val …`
  sentinel arms of the ND-typed fueled workers can name these
  constants. It sits BELOW Nondeterminism in the import order and
  therefore cannot mention `kill_reason`; the kill value itself
  (`CerbND.fuelExhaustedKill`) and every lemma live in CerbND.lean.

  THE FUEL IS A PARAMETER, NOT A CONSTANT (fuel-parameter arc, 2026-09-04;
  [USER 2026-09-03]: fuel "is an execution parameter that 'doesn't matter'
  … a parameter which can be chosen as 10^8 or any other value when
  calling the interpreter"; "Any and all magic values that are hardcoded
  and can't be quantified over are definitionally bugs"). Every fuel'd
  generated function and everything reaching one takes the LemLib class
  `[LemFuel]` (lem-lean doc/lean-backend/2026-09-03_fuel-parameter-design.md
  R1); the executable instantiates it ONCE from `--fuel N` (Main.lean —
  the only place a fuel numeral may live), a theorem quantifies over it.
  The former budget constant `CerbFuel.driverFuel = 10^8` and LemLib's
  `lemDefaultFuel = 10^6` are DELETED (docs/2026-09-04_fuel-parameter-C1-record.md).

  Design record of the exhaustion outcome: docs/2026-09-02_fuel-arc-design.md
  (§1.1 the export, §1.3 the parametricity argument, §2 the trust story).
  Option C ruled [USER 2026-09-02].

  MIRROR-OCAML NOTE: fuel has NO upstream counterpart — the lem model's
  recursion is unbounded and the OCaml oracle runs it as is; fuel is a
  Lean-target totalization artifact (arc 3). Nothing here corresponds to
  any OCaml text, by construction (every consumer of these names is a
  `{lean}`-scoped declare or hand-written Lean).
-/

import CerbLocation

namespace CerbFuel

/-- The distinguishing atom of the fuel-exhaustion kill. A pure, kernel-
    checked `opaque` WITH a value: it inhabits `Loc`, it compiles to
    `Loc.other "lem: fuel exhausted"` at runtime, and NO proof can unfold
    it. It is not in the model's vocabulary: no `.lem` term, no Core text,
    no JSON input can mention it. Registered on the boundary-opaque census
    (scripts/check_theorem_axioms.sh; VALIDATION.md) — present exactly
    once, no `unsafe`, no `@[implemented_by]`, no `@[extern]`.

    Soundness rests on this constant being OPAQUE (design note §1.3):
    every theorem about runs is uniform in its interpretation, so a
    provable "every outcome is `Killed _ fuelExhaustedKill` or good"
    holds under the reading where the atom is a location no model term
    denotes. Turning this into a `def` would silently break that
    argument — the census is what makes the change loud. -/
opaque fuelExhaustedLoc : CerbLocation.Loc := CerbLocation.Loc.other "lem: fuel exhausted"

/-- The kill's message. A plain `def` — REPORTING-ONLY (it is what Main
    prints as `Error {msg: "lem: fuel exhausted"}` and what the harnesses
    classify on: scripts/common.sh `classify_fuel_outcome`); it carries no
    soundness. It exists as a named constant only because a lem `declare`
    cannot carry a string literal (the backtick lexer excludes `"`). -/
def fuelExhaustedMsg : String := "lem: fuel exhausted"

end CerbFuel
