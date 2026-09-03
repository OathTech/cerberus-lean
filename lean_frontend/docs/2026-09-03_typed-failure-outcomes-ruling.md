# Typed failure outcomes for in-process consumers — ruling and scheduling (2026-09-03)

Trigger: Z2 audit finding Z2-FL-03 (`2026-09-03_zero-discrepancy-Z2-audit.md`,
`tests/z2-probes/float/`): without `LEAN_ABORT_ON_PANIC=1` the Lean
driver prints a PANIC and CONTINUES with the `Inhabited` default —
`(int)NaN` yields `Defined {value: "Specified(0)", …}` exit 0 where the
oracle is `Z.Overflow` exit 125. Every `panic!`/`failwithI` mirror of an
OCaml `failwith`/`assert`/uncaught exception has this shape. The harness
scripts all set the flag (binary-level crash-class parity); the Z1 slice
adds a startup refusal without it. But a consumer that calls `drive`
IN-PROCESS (refined-cerberus, the customer) never sees the flag: for the
semantics AS A MATHEMATICAL OBJECT, the failure site DENOTES the default
value — the definition disagrees with the oracle exactly where the oracle
crashes.

## Ruling [USER 2026-09-03], verbatim

> "Re the judgement, yes, I think we should structure this so that
> *consumers* of the semantics get the property we care about, i.e
> conformance to the ocaml oracle. This means we should fail-closed into
> the correct behavior. Understood re the design change, we should
> schedule this (can it wait for the current set of fixes to land?)"

Reading [AGENT]: the property owed to consumers is oracle conformance of
the DEFINITIONS, not of the binary under a harness flag. A failure site
must denote a distinguished failure outcome (fail-closed into the
oracle's own failure class), never a default value.

## Sequencing [AGENT recommendation, adopted pending the design pass]

It waits for the current fixes (Z1 → Z2 fix phase → Z3 → Z4) because:

1. Z2's fix phase disposes every hand-written failure site in-code and
   the audit already lists them (§2.x rows, the `failwith`/`assert`
   mirrors: Z-10/14/16/22, Z2-M-02, …) — that enumeration is the design
   pass's input; doing the conversion first would redo it.
2. Z1/Z2 own the `CerbMem.lean`/`Main.lean` hunks the conversion touches.
3. Nothing is unsafe in the interim for the lanes: all harnesses run with
   `LEAN_ABORT_ON_PANIC=1` (Z1 quotes the grep) and Z1's startup refusal
   makes the binary fail-closed without it. The in-process consumer gap
   is REAL and DECLARED, not silently open — see the consumer note below.

Interim rule for Z1–Z3 (so the later pass is a mechanical conversion):
mirror one-sided oracle crashes as `panic!` carrying the OCaml text (Q4),
never as a memory-monad `Error` — a typed `Error` verdict is a different
failure CLASS from a tool crash (charter §1.2(a)), so the correct typed
outcome does not exist yet; inventing it per site is the design pass.

## Scope sketch for the design pass (to be decided WITH the operator before any brief)

- Census: every `panic!` and every `LemLib.failwithI`-reachable site in
  the exec cone, partitioned into (i) hand-written seams (Z2's list) and
  (ii) lem-generated failure sites (the `.lem` `failwith`/pattern-match
  failures the OCaml raises on).
- Outcome design: a distinguished driver outcome for "the oracle would
  crash here" (a tool-failure class distinct from `Undefined`/`Error`,
  classified like exit 125 by the harnesses), reached by construction
  from every (i) site; the fuel arc's opaque-atom + runner-leaf pattern
  (`docs/2026-09-02_fuel-arc-design.md`) is the template to test first.
- The hard part is (ii): lem has no exception effect on the Lean target;
  options range from a lem-backend mechanism (subject to the lem-lean
  aims: minimal blast radius for non-Lean users, obviously-right output,
  reviewable upstream) to proving each (ii) site unreachable under the
  front end's guards. Decide per class, not globally.
- Consumer contract: refined-cerberus states which outcome its theorems
  quantify over; second design review by that team before merge (the
  fuel-arc practice).
- Trust surface: the reference model's answers on non-crashing inputs
  must be unchanged (differential battery, zero movement) — the change
  is only where the oracle crashes.

## Consumer note (for relay to refined-cerberus by the operator)

Until this arc lands: `drive` is oracle-conformant on every input where
no failure site is reached; on inputs where the oracle crashes with an
uncaught exception, the Lean definition currently returns the
`Inhabited` default of the failing site (observable in-process as a
value, not as a failure). The set of such sites is enumerated in the Z2
audit; none is reachable from the 1,953-point gcc corpus, the exec
baselines or the immaculate lane (all run with the abort flag and would
have shown a CRASH class). Theorems about `drive` on inputs that reach a
failure site are about the default, not the oracle — treat them as
PROVISIONAL per refined-cerberus's own rule.

## Provenance

[USER 2026-09-03]: the ruling quoted above. [AGENT] (orchestrator): the
reading, the sequencing recommendation and its reasons, the interim rule,
the scope sketch, the consumer note. [AGENT] (Z2 auditor, `9e86fe67c`):
the finding and its probe. Docs-only; nothing merged or pushed.
