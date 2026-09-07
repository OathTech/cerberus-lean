# Pure failure — the correspondence design (twin, connection theorem, typed exhaustion)

**Status: PARKED design, 2026-09-07 [AGENT orchestrator] — pending the operator's
reading of the reachability census.** Master plan revision 9, step 2. The operator
asked ([USER 2026-09-07] "let's do the reachability census and try to understand
whether this is worthwhile") before ruling on §8; the census
(`2026-09-07_pure-failure-reachability-census.md`) measured, over the 231 pure
sites of the execution closure: **DISCARDABLE positions: 0** (178 TAIL, 53
NON-TAIL all used) — so the F1 discard class has no instance in this tree and
there is no execution discrepancy for the twin to fix today; REACHABLE 48 (36
declared CerbFS refusals, 12 both-crash of which 4 on well-typed UB-free C),
UNKNOWN 17; the 3 always-on-path exhaustion sentinels (`hack`, `to_pure`,
`to_pures`) need exactly one iteration at `finalize` (the `Step_done` shape,
core_run.lem:1557-1589) and the other 5 have concrete data measures — i.e. the
pending register closes by the existing `fuel_measure … assuming` route, without
a twin. The census's recommendation is option C (status quo + register + the
one-iteration measures). This design therefore stays on file as the answer IF
its flip conditions arrive: a DISCARDABLE site that is REACHABLE (the lem probe
`tests/failure-probes/discarded_failures.lem` and the census's NON-TAIL
classifier are the tripwires), a REACHABLE step-level site where the oracle
succeeds, growth of the well-typed-reachable set beyond 4, or an operator ruling
that values the logical property over oracle conformance. Nothing here is
authorized for dispatch; §8 lists the decisions that would be the operator's. Inputs: the typed-failure design
(`2026-09-05_typed-failure-outcomes-design.md`, R0/R1), the census and
proposal (`2026-09-06_failure-census-and-correspondence.md`), the audit F1
reproducer (`2026-09-05_whole-project-release-gate-audit.md` §3 F1), the
risk-map baseline (`2026-09-07_risk-map-baseline.md` §3), and the lem fuel
design (`lem-lean/doc/lean-backend/2026-09-03_fuel-parameter-design.md`).

## 0. The rulings this design answers, verbatim

- [USER 2026-09-05], on the audit's F1 (OCaml raises on a discarded `failwith`,
  Lean drops it): "(1) agree, the aim should be to provide the most faithful C
  semantics, per the intent of the authors". → A discarded deliberate failure
  IS a discrepancy (kind-1). The referent is the authors' intent.
- [USER 2026-09-05], on the audit's proposed generator transform: "(2) unsure,
  this feels like it does touch the trust surface because it increases the gap
  between 'obviously right' and what Lean does. Is there a route where we prove
  the two are equivalent?" → This document is that route.
- [USER 2026-09-05], on the typed-failure scope (R1): "yes agree, this seems
  the lowest risk approach" → monadic sites first, through their monads'
  existing channels; the pure group was left as hygiene + register. This
  design is the successor for the pure group; R1's monadic half is unchanged.
- [USER 2026-09-04], the arc's design rule: "sticking to our principle that we
  don't change the lem structure for ocaml is a very good design rule … we
  have to do more work, but it's just bounded kernel checked work"; "we
  maintain the lem structure, and we get additional properties we want
  without any trust decrease". → No `.lem` body changes; a Lean-only
  generation mode; every added property is a kernel-checked theorem.
- [USER 2026-09-03], no magic values: "any instance of a value that can be
  quantified over by a context / theorem is fine … Any and all magic values
  that are hardcoded and can't be quantified over are definitionally bugs
  (unless they mirror lem or ISO-C design choices)". → Outcomes are VALUES a
  theorem can case on; nothing is chosen for them.

## 1. The problem, precisely

`failwith` has two readings, both legitimate for lem:

| Reading | Who has it | `let x = failwith "m" in n + 1` |
|---|---|---|
| **Logical**: `failwith` is an undefined constant of the result type | lem's prover targets (Isabelle/HOL/Coq); our Lean mirror (`LemLib.failwithI`: `opaque … := default`, 1,536 generated sites; `failwith` 28; `fuelExhausted` 104; `fuelExhaustedWith` 15 — counts derived by grep over `lean_frontend/generated/*.lean`) | `n + 1` (the binding is dead; `rfl`) |
| **Strict**: `failwith` raises; the computation stops | OCaml (`Failure`), i.e. the oracle and the authors' intent | raises |

The mirror implements the logical reading faithfully. The ruling picks the
strict reading as the semantics of record. The gap is not a bug in either
implementation; it is a missing THIRD artifact: a Lean definition with the
strict reading, connected to the mirror by a theorem.

Measured facts (census, cold-reproduced on `de9f6d361`, hashes matched):

| Quantity | Value |
|---|---|
| Failure sites in the whole tree (hand-written + generated) | 1,644 |
| Pure sites in the execution dependency closure | 231 (126 generated, 105 hand-written) |
| Generated monadic sites in the closure | 67 (37 ND channel, 26 `t0` channel, 4 in `Core_eval.call_function` needing a constructor) |
| Hand-written monadic (memM) arms | 7 (`CerbMem.lean`; the R1 slice's subject) |
| Discard mechanisms demonstrated at the lem level (OCaml exit 2, Lean prints `1`, `rfl`-provable, axiom-free) | 5: unused binding, unused argument, tuple projection, discarded `List.map` result, discarded callback result (`tests/failure-probes/discarded_failures.lem`) |
| Reachable fuel'd workers whose exhaustion is an OPAQUE value sentinel (fail-open) | 8: `are_compatible_aux`, `are_compatible_params_aux0`, `are_compatible_params0`, `hack`, `to_pure`, `to_pures`, `many`, `many1` (`scripts/fuel_forms_pending.txt`) |

Consequences today: (i) a theorem about `f xs` can be about a value the oracle
never produces; (ii) `∀ fuel` statements over `drive` are not TRUE in general
(a pending worker can exhaust silently); (iii) fuel monotonicity for `drive`
is not even STATABLE ("no exhaustion at fuel n" has no expression when the
sentinel is an opaque inhabitant).

## 2. Design principles applied

1. **The mirror stays the reference and stays as it is.** Its text is the
   line-by-line reading of the lem; its trust argument is unchanged.
2. **One source, two readings, both generated.** The strict artifact is
   produced by the SAME backend from the SAME typed lem, in the same run. No
   hand-written second model (the 2026-09-04 boundary ruling against in-repo
   mirror models applies: reasoning layers belong to the consumer).
3. **The connection is a theorem, per function, kernel-checked**, with a
   generated statement and a uniform proof — the fuel-sufficiency pattern
   (`f_measure_sufficient`) exactly.
4. **No lem body or type changes; no new numerals; no per-function choice.**
   Lean-only generation mode; the fallible cone is computed, not declared.
5. **Fail-closed on the surface**: every fallible site on the strict path is a
   typed outcome; there is no inhabitant-default anywhere on that path.

## 3. The design

### 3.1 The outcome type (LemLib)

```lean
structure Failure where
  site    : FailureSite      -- stable, generated: module, definition, ordinal
  message : String           -- the lem source string, byte-for-byte

inductive Outcome (α : Type) where
  | value     : α → Outcome α
  | failed    : Failure → Outcome α
  | exhausted : Outcome α      -- fuel ran out (typed, absorbing)
```

with `Outcome.bind` and the absorption laws proved once:
`bind (failed f) k = failed f`, `bind exhausted k = exhausted`,
`bind (value a) k = k a`. `exhausted` is inside the type deliberately (D-3):
one absorbing element for both stop reasons keeps every propagation and
monotonicity proof uniform; the two remain distinguishable to the printer.

### 3.2 The strict twin `f_chk` (generated, Lean-only)

For every definition `f` in the **fallible cone** of the declared entry —
functions whose body contains a failure site or calls a fallible function,
computed transitively by the backend from the typed lem — emit alongside the
mirror:

- `f_chk : (f's parameters) → Outcome α`: the mirror's body with every
  fallible sub-call bound through `Outcome.bind`, every `failwith msg` site
  replaced by `.failed ⟨site, msg⟩`, every non-fallible sub-call left as a
  direct call (no duplication outside the cone), in **the order the pinned
  OCaml toolchain evaluates the emitted code** — `let` sequencing left to
  right; application and tuple operands as ocamlopt orders them (right to
  left in practice, unspecified by the language) — so that with two failing
  operands the twin reports the failure the oracle reports. That order is a
  property of the pinned toolchain, fixed by probe (§3.4, §6), not derivable
  from the lem text alone.
- fuel'd workers: `f_lemFuel_chk (lemFuel : Nat) …` with `| 0 => .exhausted`
  and the same recursion structure as `f_lemFuel`; measured wrappers keep
  their shape: `f_chk xs := f_lemFuel_chk (μ xs) xs`; ambient wrappers keep
  theirs: `f_chk := f_lemFuel_chk LemFuel.fuel`.
- the cone itself is EMITTED as a register (`generated/fallible_cone.txt`,
  one line per function with its site count) and gate-checked both ways:
  every reachable failure site lies in a cone function; every cone function
  is reachable or explicitly marked unreachable (the totality gate's
  vocabulary). The register is a derived artifact, never hand-edited.

### 3.3 Monadic code: the existing channels, plus one lift

R1 stands: a failure site INSIDE a monadic body uses that monad's own stop
channel — `NDkilled (Error0 loc msg)` for the ND family (`memM` is `ndM …`,
`Nondeterminism.lean:1995`), `Exception` for `exceptM`, the `t0` state-
exception result — carrying a **distinguished model-failure reason** so a
model fail-stop is never confused with the model's ordinary UB or error (R1
group M). A monadic function's twin therefore returns the SAME monad; what
changes is how it consumes PURE fallible sub-calls: through one generated
lift per monad,

```lean
liftOutcome : Outcome α → ndM α …   -- failed → kill (model-failure reason); exhausted → the fuel kill
```

so the monadic twin binds `liftOutcome (g_chk ys)` where the mirror wrote
`g ys`. The 7 hand-written memM arms (C-TF1) are R1 work and are consumed
here unchanged. The 4 `Core_eval.call_function` sites whose monad lacks a
payload-carrying constructor (`core_run_cause`) need the constructor R1
group M′ describes — an OCaml-visible type change if done in the lem — so
they are lifted at the boundary instead: their twin returns the ND kill one
level up (D-4).

### 3.4 The obligations (generated statements, uniform proofs, gated)

Per pure `f` in the cone:

```lean
theorem f_chk_sound (xs) (v) : f_chk xs = .value v → f xs = v
```

Per fuel'd worker:

```lean
theorem f_lemFuel_chk_sound (n) (xs) (v) : f_lemFuel_chk n xs = .value v → f_lemFuel n xs = v
theorem f_lemFuel_chk_mono  (n m) (xs) (v) : n ≤ m → f_lemFuel_chk n xs = .value v → f_lemFuel_chk m xs = .value v
```

At the executable entry, in the ambient:

```lean
theorem drive_chk_mono (F₁ F₂ : LemFuel) … : F₁.fuel ≤ F₂.fuel →
  @drive_chk F₁ … = .value v → @drive_chk F₂ … = .value v
```

Why these are provable uniformly: `f_chk` is `f` with binds inserted; when
every bind takes its `.value` branch the two bodies compute the same term
(soundness is a homomorphism argument, by cases on each bound sub-call using
the callees' `_sound`); monotonicity follows from the absorption laws plus
the workers' structural recursion in `lemFuel` (a body can no longer
"recover from" exhaustion — `exhausted` is absorbing by the bind law, which
is precisely the property the lem fuel design record said the sentinel scheme
could not offer — its R1 list, item 4: "a body may absorb a sub-call's sentinel
and change value at a larger fuel, and with the panic payload `fuelExhausted x`
— opaque — '≠ payload' is not even statable"). The proof is a generated term/tactic per function with a
hand-proof fallback module (`*_lemChkProofs.lean`, the `*_lemMeasureProofs`
pattern); the statements' SHAPE is checked by the gate as the fuel-forms
tool checks `_measure_sufficient` (worker/wrapper heads, positional argument
correspondence, cone ⊆ `[propext, Classical.choice, Quot.sound]`).

What is deliberately NOT stated: `f xs = v ∧ "no failure was evaluated" →
f_chk xs = .value v`. The antecedent has no expression in the mirror. That
direction, and agreement with OCaml on WHICH failure fires first, are
differential: the twin is what the binary executes (§3.5), and the batteries
plus a multiple-failure/evaluation-order probe suite are its evidence.

### 3.5 Execution and observation

The binary executes the twin (`drive_chk`), D-1. A `.failed` outcome prints
in the oracle's failure class — the oracle dies with an uncaught `Failure`
(exit 125, the `internal error, uncaught exception` envelope); the driver
prints a matching envelope naming the site and message and exits 125 — so
the observation codec classifies both as the same completed internal
failure; `.exhausted` keeps today's typed fuel kill (`Error {msg: "lem: fuel
exhausted"}`, exit 1). The mirror is no longer the executed artifact; it
remains the reference definition every theorem is ultimately about, through
`_sound`. The trust argument: the executed artifact is generated from the
same source by the same backend, is kernel-connected to the reading of the
lem text on every successful run, and is differentially tested on every
failing one. Nothing hand-written is added to the model.

## 4. What this closes, and what it changes for consumers

| Item | Before | After |
|---|---|---|
| Audit F1 (kind-1 discrepancy) | Lean succeeds where OCaml raises; `rfl`-provable | the executed twin fails typed; the mirror equation still holds and is labelled as the logical reading |
| The 8 pending fuel rows (fail-open) | opaque sentinel value at exhaustion | `.exhausted` in the twin; each becomes (B) absorbing; `fuel_forms_pending.txt` empties; sufficiency theorems for the measured 54 are unchanged |
| Fuel monotonicity (lem TODO 13, consumer §3 bullet 3) | not statable for `drive` | `drive_chk_mono` generated and kernel-checked; per-worker `_mono` for every fuel'd twin — the 21 ambient-fuelled ones today (13 absorbing + 8 pending) are what `drive_chk_mono` composes; the 54 measured ones are called at their measure and need only `_sound` |
| Consumer contract (A)/(B)/(C) | (C) "gate-checked unreachable" carries the residue | (A) measured or (B) absorbing only, on the strict path |
| `∀ fuel` theorems | true only on measured/absorbing paths | true for every `drive_chk … = .value v` premise |
| The consumer's statements | over `drive`/`driver2` (mirror) with `[LemFuel]` and per-expression bounds | either unchanged (via `_sound`) or restated over `_chk` to gain the failure/exhaustion cases; their choice (D-6); manifests name every renamed constant |

## 5. Costs and risks (to be measured in the vertical slice, not assumed)

- **Generated code size.** The fallible cone is duplicated. The exec closure
  is ~10,400 constants (fuel-forms `closure_size`); the fallible fraction is
  unknown until the backend computes it. Compile time and binary size are
  measured in the slice; the box rule applies.
- **The transform's own correctness** is what the `_sound` theorems check;
  a wrong bind order would still be sound (success agrees) but unfaithful on
  failures — hence the evaluation-order probe suite is part of acceptance.
- **Printer/exit mapping** (§3.5) is an observation-layer change with codec
  and baseline consequences (rows where the oracle crashed and Lean panicked
  become both-internal-failure MATCH; immaculate pins move by re-record with
  justification).
- **Consumer re-pin.** Constants move from the mirror to `_chk` only if they
  choose; `_sound` keeps mirror statements valid. A manifest carries it.
- **Backend complexity** inside the L1 consolidation: the twin is a
  generation MODE, not a declare; L1's grammar gains at most an `entry`
  marker naming the executable root (if `drive` is not already derivable).
- **Strings** (`message : String`): byte-for-byte equality with OCaml waits on
  L4; until then message text is class (a) as today.

## 6. The first vertical slice (proposed; not authorized here)

**lem-lean half** (a same-name branch pair; lem first): the transform for
the five measured mechanisms — let, argument, tuple projection, `List.map`
result, callback result — plus one fuel'd probe; input
`tests/failure-probes/discarded_failures.lem` compiled to both targets.
Acceptance: OCaml output byte-identical to today's (the nine-emitter
non-Lean goldens unchanged); Lean twins generated with `_sound` and `_mono`
proved; `unused_binding_chk n = .failed ⟨site, "…"⟩` and
`positive_control_chk n = .value (n + 1)` by `rfl`/`decide`; the probe
binary now exits with the failure class where OCaml does; a
multiple-failure probe (two failing operands) reports the SAME failure the
OCaml build reports.

**cerberus half:** one real path — `hack` (pure `value`, pending) through
`finalize` (pure `driver_result`) into `driver2` via `liftOutcome`. Acceptance:
`hack_lemFuel_chk 0 … = .exhausted` (replacing the opaque `fuelExhausted
Vunit` on the strict path), `finalize_chk_sound`, `hack_lemFuel_chk_mono`
kernel-checked; the pending register loses its `hack` row; the full battery
zero movement; the binary still executes the mirror in this slice (D-1 is
applied only when the whole cone is generated).

Only after both halves land does the cone-wide generation follow, then D-1.

## 7. Sequencing with L1 and C-TF1

- **L1 (declare consolidation)** defines the grammar the twin lives under.
  Because the twin is a mode, L1 needs only the entry marker; the
  `termination` family's `fuel` payloads become unnecessary on the strict
  path (exhaustion is `.exhausted`) but stay for the mirror. L1's vocabulary
  should therefore be fixed AFTER this note is ruled and BEFORE the slice.
- **C-TF1 (monadic seams → kill channel)** is independent and proceeds now;
  §3.3 consumes its distinguished reason.
- **Fuel measure cost** (the Codex charter in flight) touches measure terms
  only; the twin reuses the same measures, so there is no conflict.

## 8. Decisions for the operator

| ID | Question | Recommendation [AGENT] |
|---|---|---|
| D-1 | Does the binary execute the twin once the cone is complete (§3.5)? | Yes: the kind-1 ruling is about executed behaviour; the mirror stays the reference via `_sound`. |
| D-2 | Is the fallible cone computed automatically by the backend (emitted register + gate) or declared per function in the lem? | Automatic. 231+ per-function declares would be noise and a per-function CHOICE; the register keeps it inspectable. |
| D-3 | Is fuel exhaustion inside `Outcome` (`exhausted`) or a separate channel? | Inside: one absorbing type, uniform proofs, monotonicity by construction; the printer still distinguishes. |
| D-4 | The 4 `call_function` sites: lift at the ND boundary (Lean-only) or add a `core_run_cause` constructor (an OCaml-visible type change)? | Lift at the boundary; no shared-model change. |
| D-5 | Order: lem probe slice first, then `hack`/`finalize`, then the cone, then D-1? | Yes, exactly that, with an operator review between the probe slice and the cone. |
| D-6 | Do we ask refined-cerberus to restate over `_chk`, or offer both? | Offer both; they decide at their re-pin. |
| D-7 | Failure identity in `Failure.site`: generated stable id (module, definition, ordinal) — acceptable as the kernel-visible identity while messages remain class (a)? | Yes. |

## 9. Provenance

Rulings quoted are [USER] with dates as recorded in the cited documents and
the 2026-09-05 conversation record (`2026-09-05_whole-project-audit-response.md`
§3). Counts are the census's (cold-reproduced) or derived by the grep named
inline. The design choices are [AGENT] proposals awaiting §8.
