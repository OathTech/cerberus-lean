/-
  CerbFuel — the fuel-exhaustion atom, message, and driver budget.

  Hand-written seam (lean_frontend/handwritten_copy.manifest), imported
  by the GENERATED Nondeterminism.lean via
  `declare {lean} extra_import \`CerbFuel\`` (nondeterminism.lem; the
  debug.lem:4 mechanism), so that the `declare {lean} fuel val …`
  sentinel arms of the nine ND-typed fueled workers can name these
  constants. It sits BELOW Nondeterminism in the import order and
  therefore cannot mention `kill_reason`; the kill value itself
  (`CerbND.fuelExhaustedKill`) and every lemma live in CerbND.lean.

  Design record: docs/2026-09-02_fuel-arc-design.md (§1.1 the export,
  §1.3 the parametricity argument, §2 the trust story, §4 the budget).
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

/-- The fuel budget of the coupled driver family (`driver2`,
    `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`, `hack`,
    `nd_bind`, `CerbND.ndDefaultFuel`) — design note §4. The citable
    name for the consumer's side condition (`k + 2 ≤ CerbFuel.driverFuel`);
    the wrapper `rfl`s in CerbND.lean (`driver2_wrapper_defeq`,
    `nd_bind_wrapper_defeq`, `runND_eq`, `drive_wrapper_defeq`) pin the
    generated wrappers to this constant, and `driverFuel_eq` gives the
    numeral.

    COMMIT-1 VALUE (mechanism commit, §6): equal to `lemDefaultFuel`
    (= 10^6, lem-lean lean-lib/LemLib.lean) so that the generated
    wrappers — still emitted at the library default in this commit —
    are `rfl`-equal to `driverFuel` and the FUEL harness class is
    witnessed by real lane rows before the budget moves. The budget
    commit changes this numeral to 100000000 (= 10^8) together with the
    six L1 budget declares. -/
def driverFuel : Nat := 1000000

end CerbFuel
