# Fuel-parameter arc — consumer assessment from refined-cerberus (2026-09-03)

Relayed by the operator; verbatim. Input to the fuel-parameter arc
(design note: lem-lean `doc/lean-backend/2026-09-03_fuel-parameter-design.md`).

> Refinement 1: it is broader than the driver. I measured the pinned
> port. The generated tree seals at least six fuelled recursions behind
> fixed wrappers: the scheduler loop, the single-thread loop, the exit
> routine, a printing helper, and the nondeterminism monad's own bind.
> And there are two constants, not one. The driver family uses 10^8,
> while LemLib's default of 10^6 sits behind the expression-step
> recursions. Our own adequacy exports already carry hypotheses bounding
> an expression's potential by that second constant, so we have baked
> the same defect into 60 sites of our statements. The request should be
> about the port's fuel discipline as a whole, not about drive.
>
> Refinement 2: classify it as an interface defect, not a mirror
> discrepancy. The cerberus-lean team's standing rule is zero execution
> discrepancies against the OCaml oracle. On that axis, fuel is
> invisible: OCaml diverges where Lean exhausts, and nothing observable
> differs below the bound. The defect is in the port's interface for
> reasoning, which is a different category under their rules. Framing it
> that way avoids a pointless argument about whether Lean "computes what
> OCaml computes", and puts it where it belongs, in the lem-lean
> backend's fuel scheme.

## Orchestrator response [AGENT 2026-09-03]

Agreed on both, and both are how the arc is scoped:

- Refinement 1 matches the measurement in the design note §2: two
  constants (`CerbFuel.driverFuel = 10^8` on the driver family;
  `LemLib.lemDefaultFuel = 10^6` at 77 generated wrapper sites in 16
  files plus ~12 hand-written `CerbMem` call sites). The arc is the
  port's fuel discipline as a whole: ONE caller-supplied fuel threaded
  by the reader lifting to every fuel'd function; every fixed wrapper
  and both constants deleted; a gate against fuel numerals.
- Refinement 2 is the classification the ruling record uses: the
  "No magic values" principle (`DESIGN.md` §4) is a DESIGN principle
  about the interface consumers reason against, not an execution-
  discrepancy class. Fuel wrappers were proof-support machinery, and
  the standing rule for that machinery is "no semantic/execution effect"
  — which they satisfy below the bound; the defect is that the bound is
  not the consumer's to choose. Owner: the lem-lean backend's fuel
  scheme (the lem half is in flight), then the cerberus seams.
- Consumer impact to expect in the arc's change manifest: the 60
  hypothesis sites bounding an expression's potential by 10^6 restate
  over the quantified fuel (`∀ fuel, fuel ≥ needed → …`, or a single
  fuel hypothesis at the entry); the ∀-fuel exemplar
  (`test/Unit/FuelExemplar.lean`) is the pattern; a consumer design
  review of the lem design note precedes either merge.
