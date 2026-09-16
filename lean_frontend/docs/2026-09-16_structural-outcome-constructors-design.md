# Structural outcome constructors (D2) — design note R0, for the operator's scope review (2026-09-16)

**Status: SUPERSEDED 2026-09-16** by `2026-09-16_lean-only-outcomes-scoping-note.md` — the operator asked to revisit the design in total rather than repair it ([USER 2026-09-16]: "I'm a bit wary of 'epicycles' … revisit the overall design and orientation wrt the oracle"); recommendation B′ below is WITHDRAWN (its dead mirror arms are the epicycle the scoping note names). Kept as history. Original status: DRAFT for review with the operator BEFORE any charter (master plan rev 10 §3 step 5b: "a design note reviewed WITH the operator before dispatch (the step-2 rule)"). Author: the orchestrator [AGENT]. Base: mainline `a15da65f8`. This note proposes; it authorizes nothing.

## 0. The rulings this design answers, verbatim

- [USER 2026-09-11], on the orchestrator's review of the whole-project semantics audit, decision D2 — "Structural constructors for exhaustion, unsupported feature, model failure and UB, replacing the two opaque location atoms. The audit and the open TODO item now both argue for it": **"D2: agree"**.
- [USER 2026-09-03], the typed-failure ruling (`docs/2026-09-03_typed-failure-outcomes-ruling.md`): "Re the judgement, yes, I think we should structure this so that *consumers* of the semantics get the property we care about, i.e conformance to the ocaml oracle. This means we should fail-closed into the correct behavior."
- [USER 2026-09-03], the reasoning-artifact lens: "I think this basically is a result of thinking of the semantics as an execution artifact, not a reasoning artifact. Where else might we have baked this in?" — applied as: can a theorem quantify over it, unfold it, state it without reference to process environment or a rendered string?
- [USER 2026-09-03], no magic values, the general form: "any instance of a value that can be quantified over by a context / theorem is fine. Defaults that are chosen eg. in test suites are fine. Any and all magic values that are hardcoded and can't be quantified over are definitionally bugs (unless they mirror lem or ISO-C design choices)"; the aim: "to forbid values that limit the semantics or limit the ways the customer can reason about the semantics".
- [USER 2026-09-02], the fuel-arc Option C ruling (`docs/2026-09-02_fuel-arc-design.md`): "Yes, this seems reasonable. But we'll want to do a 2nd design review before merge to make sure we actually achieved this cleaner picture and it serves the refined-cerberus project needs." — and, the same design's record of Option B's rejection: "Option B (a new `kill_reason` constructor) REJECTED: it changes the shared `.lem` type and therefore the generated-OCaml text / fork-drift surface, for a constructor the oracle never uses"; refined-cerberus [2026-09-02]: "we withdraw our request's suggestion of a new `kill_reason` constructor."
- [USER 2026-09-05], P2: "unsure, this feels like it does touch the trust surface because it increases the gap between 'obviously right' and what Lean does. Is there a route where we prove the two are equivalent?" — trust-surface changes need a proof route.
- [USER 2026-09-10], the regularity test for a shared-model change: "It sounds like this is actually a more regular design than the current lem? I.e we use the same mechanism as elsewhere in the cerberus design?"
- Standing: mirror-OCaml doctrine (a divergence in a hand-written seam is a defect unless documented in-code as deliberate); zero Lean-vs-oracle execution discrepancies; fail-closed, fail-noisy; the [USER 2026-09-08] ban on new out-of-policy proof surface.

## 1. The problem, precisely

**What exists.** Every Lean-side run outcome is one of `Active result` or `Killed st reason` with `reason : kill_reason err` — lem's type (`frontend/model/nondeterminism.lem:25-27`), shared with OCaml: `Undef0 loc ubs` (undefined behaviour, structural), `Other err` (the model's own error causes, e.g. `Illformed_program`, structural), `Error0 loc msg` (the Core `error(...)` kill: a program location and a message). Two OUTCOMES exist only on the Lean side, because OCaml has no value for them — it crashes (uncaught exception) or never exhausts (no fuel): **fuel exhaustion**, `CerbND.fuelExhaustedKill = Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg`, and **model fail-stop** (C-TF1's typed mirror of the oracle's `failwith`/`assert` crashes), `CerbFail.failStopKill msg = Error0 CerbFail.modelFailStopLoc msg`. Both ride the generic `Error0` constructor and are DISTINGUISHED BY THE LOCATION ARGUMENT, which is a kernel-checked `opaque` with a value: `opaque fuelExhaustedLoc : Loc := Loc.other "lem: fuel exhausted"` (`CerbFuel.lean:54`), `opaque modelFailStopLoc : Loc := Loc.other "model fail-stop"` (`CerbFail.lean:11`). Both are rows of the boundary-opaque census (`scripts/check_theorem_axioms.sh`, `OPAQUE_WANT`, 16 rows).

**Why opaque (the 2026-09-02 argument, still valid on its own terms).** Every theorem about runs is uniform in the interpretation of an `opaque` with no equations, so a provable "every outcome is `Killed _ fuelExhaustedKill` or good" holds under the reading where the atom is a location no model term denotes; a program that genuinely kills makes such a theorem UNPROVABLE rather than false. No distinctness lemma ships, "because of parametricity, not despite its absence" (fuel-arc §1.3). The consumer accepted this and withdrew its constructor request.

**What has changed since 2026-09-02.**

1. The reasoning-artifact ruling (2026-09-03) asks of every semantic value: can a theorem quantify over it, unfold it, state it without a rendered string? The atom fails "unfold" by design and fails "without a rendered string" at the output boundary (§1, item 4 below). `TODO.md` small item (b) records exactly this tension: "consumers cannot prove them different from any location … would remove two boundary rows and let theorems case on the kill kind — operator decision (deviates from the C1 Option-C precedent)".
2. A SECOND atom now exists (C-TF1, 2026-09-08). Two Lean-only outcomes that a consumer must treat differently — exhaustion goes away at larger fuel, a fail-stop does not — are two `Error0 <opaque> _` values that the kernel cannot tell apart: `fuelExhaustedKill ≠ failStopKill msg` is UNPROVABLE (both locations opaque), and both are unprovably distinct from a genuine program `Error0 loc msg`. The 2026-09-05 typed-failure design accepted this ("no distinctness lemma ships"); the audit (2026-09-11, finding 1) names it as the first structural priority: "give budget exhaustion, unsupported features, internal model failure, and C undefined behavior distinct structural representations. Current distinctions partly depend on special locations and messages inside a general error constructor."
3. **A refusal kind is coming.** Exception class (c), loud feature-attributed refusals (CerbFS: 40 register rows, today pure `panic!`s; the concurrency prototype's `model refused: …` message-prefix convention, which the observation codec recognises by `refusal(prefix)` — a TEXT convention; the CLI's `refuseFlag`, exit 2), will need a kill-level home once the refusal census (master plan §3 step 4) converts pure refusals to typed outcomes. A third opaque atom would make three unprovably-distinct `Error0`s.
4. **Runtime classification is by text and by a forgeable value.** `Main.lean:1077` prints `ModelFailure {msg}` iff `loc == CerbFail.modelFailStopLoc` — a runtime `BEq` on `Loc` (the opaque compiles to `Loc.other "model fail-stop"`); the harnesses classify fuel by the printed text (`observations.py` `FUEL_RECORD`, `scripts/fuel_classify.sh`). The 2026-09-02 corollary said "no JSON input can mention it": true of the Lean CONSTANT, false of the runtime VALUE — `CabsImport.jsonToLoc` (`CabsImport.lean:168`) maps `{"tag": "Loc_other", "str": s}` to `Loc.other s` for any `s`, and a Cabs location feeds `th_st.current_loc` and thence a `PEerror` kill (the corollary's own trace, fuel-arc §1.3). A crafted Cabs JSON can therefore make a program error print as `ModelFailure`. Not reachable from C source through the real parser (which emits `Loc_other` only for its own synthetic markers), so not a matched-mode discrepancy — but a fail-open shape at the output boundary that a constructor closes for free.

**What must NOT change.** The OCaml oracle's results on every input (it has neither outcome); the printed batch text of every existing lane row (zero movement); the consumer's statements: `fuelExhaustedKill = Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg` by `rfl` (refined-cerberus `Heap.lean:1525` states exactly this term), `fuelExhaustedKill ≠ Undef0 _ _`, `≠ Other _`; the `_zero` lemmas of the 13 absorbing workers (all spell `Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg` through the lem `fuel` declares — the NAMES stay, so no `.lem` edit).

## 2. The vocabulary

Kinds of run outcome, and where each lives today:

| Kind | Meaning | Today | Structural? |
|---|---|---|---|
| Value | `Active result` | — | yes |
| UB | `Killed _ (Undef0 loc ubs)` | lem | yes |
| Model error | `Killed _ (Other cause)` — `Illformed_program`, core-run causes, memory errors | lem | yes |
| Program error kill | `Killed _ (Error0 loc msg)` from Core `error(...)`, `loc` a program location | lem | yes (by exclusion, once the two below are not `Error0` of a program location) |
| Fuel exhaustion | `Killed _ (Error0 fuelExhaustedLoc "lem: fuel exhausted")` | Lean-only atom | NO — opaque location |
| Model fail-stop | `Killed _ (Error0 modelFailStopLoc msg)` | Lean-only atom | NO — opaque location |
| Refusal (class (c)) | pure `panic!` (CerbFS), message prefix (concurrency lane), CLI exit 2 | none | NO — not even a kill |

D2's target: the last three rows become constructors, kernel-distinguishable from each other and from every program location, unforgeable from any input, with the printed text unchanged.

## 3. The options

**A. Transparent definitions** (`def fuelExhaustedLoc := Loc.other "lem: fuel exhausted"`, TODO item (b)'s sketch). Gains kernel decidability against concrete locations and removes two census rows. REJECTED: `Loc.other s` is in the input vocabulary (§1 item 4), so the sentinel becomes FORGEABLE in the kernel too — a theorem about a run of a crafted input could equate a program kill with exhaustion; this breaks the 2026-09-02 soundness argument outright and fails the "impossible by syntax" column that both B and C had.

**B. New constructors on lem's `kill_reason`** (`| Fuel0 | FailStop0 of string | Refusal0 of string`). The semantically right slot. REJECTED on 2026-09-02 for reasons that still hold: a shared `.lem` TYPE change generates dead OCaml constructors, forces exhaustiveness edits at every OCaml/lem match on `kill_reason` (`nondeterminism.lem:263,520`, `driver_ocaml.ml:173-182`, the lem `Other err` arms), moves the fork-drift surface for constructors upstream never uses, and offers upstream nothing (it has neither outcome). The three shared-model changes since (2026-09-10/15/16) were each a termination or correctness repair with an upstream-facing rationale; a Lean-only vocabulary in a shared type is not of that class. Kept as the long-term route IF upstream ever adopts a resource-exhaustion outcome.

**B′ (recommended). Lean-only constructors on the LOCATION seam.** `CerbLocation.Loc` is a hand-written Lean type (`CerbLocation.lean:29-35`) mirroring OCaml's `Cerb_location.t`, reached by generated code ONLY through target_rep smart constructors and functions (`CerbLocation.unknown`/`other`/`withCursor`/…; verified 2026-09-16: no generated module pattern-matches on `Loc`; the consumer's tree names no `Loc` constructor). Add:

```lean
inductive Loc where
  | unknown : Loc
  | other : String → Loc
  | point : Pos → Loc
  | region : Pos → Pos → Cursor → Loc
  | regions : List (Pos × Pos) → Cursor → Loc
  -- Lean-only outcome provenance (D2, 2026-09-16): the port's own outcomes that the
  -- OCaml oracle has no value for. Never constructed by any importer or model term;
  -- producers are exactly CerbFuel / CerbFail / CerbRefuse (constructor-site census).
  | fuelExhausted : Loc
  | modelFailStop : Loc
  | refusal : String → Loc      -- the refused feature, for class (c) refusals
```

with `def CerbFuel.fuelExhaustedLoc : Loc := .fuelExhausted` and `def CerbFail.modelFailStopLoc : Loc := .modelFailStop` (plain `def`s; the two `opaque`s and their census rows go), `Ord`/`BEq`/`Repr` extended (the hand-written `locRank` gains three ranks), the print functions extended so the TEXT IS UNCHANGED (`stringFromLocation .fuelExhausted = "other_location(lem: fuel exhausted)"`, `simpleLocation` likewise — exactly what `Loc.other "…"` prints today, so no lane row moves), `withCursor`/`getFilename`/`isLibraryLocation` identity/`none`/`false` arms.

Why this is REGULAR (the 2026-09-10 test): Cerberus itself uses the location slot for synthetic provenance — `Loc_other of string` marks builtins and internal origins — and the two atoms ALREADY live there as `Loc.other "…"` values. B′ makes the existing convention a constructor instead of a magic string: the no-magic-values ruling applied to a location. Why it is CONTAINED: one hand-written file gains three constructors and their arms; the lem `fuel` declares keep spelling `CerbFuel.fuelExhaustedLoc`; no `.lem` text, no generated OCaml, no fork-drift hunk, no consumer signature changes.

What it buys, kernel-checked:

- **Distinctness by constructor**: `fuelExhaustedKill ≠ failStopKill m`, `fuelExhaustedKill ≠ Error0 l m` and `failStopKill m ≠ Error0 l m'` for every `l` in the mirror image (`isMirror l`, below), all by `Loc.noConfusion` — the column the 2026-09-02 table conceded C could not have.
- **Unforgeability, as a theorem about the importers**: `isMirror : Loc → Bool` (true on the five mirror constructors); `jsonToLoc j = .ok l → isMirror l` (`CabsImport`); the Core-text parser stamps only `CerbLocation.unknown` (`CoreParser.lean:252`, `loc0`); the model's own literal locations are mirror values. So "no model term denotes it" — the 2026-09-02 argument's premise — becomes a PROVED statement about the two input boundaries plus a constructor-site census (the three producers), instead of a parametricity reading of an opaque.
- **A kind projection**: `inductive KillKind | fuel | failStop | refusal | ub | modelError | programError` and `def kindOf : kill_reason err → KillKind` by pattern match (kernel-reducible; `kindOf fuelExhaustedKill = .fuel := rfl`). The batch printer uses `kindOf`, not `BEq` on `Loc`; consumers can state `kindOf o.reason = .fuel ∨ post` and CASE on it — the audit's "downstream statements substantially clearer".
- **Two boundary-opaque rows retired** (16 → 14), replaced by a constructor-site pin in the same gate (plant-tested: an unregistered producer of `.fuelExhausted` is RED).

**C. Keep the atoms; add the projection only.** `kindOf` cannot be defined by pattern match on an opaque — it would need `BEq` at runtime and be kernel-irreducible. REJECTED as not meeting "unfold".

## 4. What the slice would do (proposed; not authorized here)

D0 snapshot (Tier A, pristine build, cabs-json hashes of `tests/minimal` as the bridge-neutrality check). D1 `CerbLocation.Loc` + three constructors, `isMirror`, arms, instances; text-identity of `stringFromLocation`/`simpleLocation` pinned by a unit test against today's strings. D2 `fuelExhaustedLoc`/`modelFailStopLoc` become `def`s; `KillKind`/`kindOf`; the distinctness and importer theorems (`CerbFailProofs`, `CerbND`, a new `CerbOutcome.lean` seam or inside `CerbFail`); `Main` prints via `kindOf`; the census gate: two `OPAQUE_WANT` rows removed, a constructor-site pin added, both plant-tested. D3 `Loc.refusal` + `CerbRefuse.refusalKill feature msg` DEFINED with its `kindOf` arm and the batch text the concurrency lane's convention already prints (`model refused: <feature>: …`) — NO site converted here (the refusal census slice populates it; CerbFS's pure panics are the pure-failure class and need the census first). D4 docs: VALIDATION §1(c)/§9 (the boundary list shrinks; the kind projection stated), fuel-arc design §1.3 erratum (the runtime-value forgeability), `TODO.md` item (b) resolved, the consumer note. D5 full battery + record; zero movement is the gate (the text is unchanged by construction; the differential lanes are the proof).

Fence: `CerbLocation.lean`, `CerbFuel.lean`, `CerbFail.lean`, `CerbFailProofs.lean`, `CerbND.lean` (theorems only), a new `CerbRefuse.lean`/`CerbOutcome.lean`, `Main.lean` (the printer arms), `CabsImport.lean` (the `isMirror` theorem only), `check_theorem_axioms.sh` (the census lists + plants), unit tests, docs. Forbidden: any `.lem`, generated OCaml, baseline row, or printed-text change; any `opaque`/`implemented_by`/`extern`.

## 5. Costs and risks, named

- **Mirror doctrine.** `Loc` gains constructors OCaml's `Cerb_location.t` does not have — a deliberate, documented divergence in a hand-written seam, in the same file that already documents its `Ord` divergence. Justification in-code: they denote outcomes for which OCaml has no VALUE (it crashes or cannot exhaust); a mirror of "no value" cannot be a mirror constructor.
- **A location that is not a location.** The reading is Cerberus's own: `Loc` is provenance, and `Loc_other` is already its synthetic case. The alternative (B) is the right slot at the wrong cost; if upstream ever takes a resource-exhaustion outcome, B′ migrates to B mechanically (one `kindOf` arm each).
- **Consumer**: `fuelExhaustedLoc` becomes a `def` — every existing consumer statement still holds (more unfolds, none break); new constructors on `Loc` — the consumer matches on no `Loc` (grep 2026-09-16); `Ord Loc` gains ranks (no consumer key uses them). Second review by refined-cerberus BEFORE the slice, as the 2026-09-02 ruling required for the atom design it replaces.
- **Soundness argument changes shape**: from parametricity-in-an-opaque (unfalsifiable by construction, uncheckable) to a syntactic invariant (the three producers, the two importers) that is PROVED at the importers and GATED at the producers. This is the P2 route: a proof, not a transform.
- **Text-identity risk**: any place that renders a `Loc` other than the two print functions (e.g. a `Repr` in debug output) prints the constructor name — acceptable; the batch path uses the two functions only (`Main.lean:1075-1110`).

## 6. Decisions for the operator

1. **Adopt B′** (Lean-only constructors on `Loc`) over A (transparent strings — rejected as forgeable), B (lem-level — rejected 2026-09-02, still), C (projection only — fails "unfold")?
2. **Include `Loc.refusal` now**, defined and gated but unpopulated, so the refusal census has its target — or defer it to that slice?
3. **The fuel batch record**: keep `Error {msg: "lem: fuel exhausted"}` (zero movement; the codec's `FUEL_RECORD` unchanged) in this slice, and consider a structural `FuelExhausted {msg}` record as a later codec change with its own baseline movement?
4. **Second review** by refined-cerberus of this note before the slice (the 2026-09-02 requirement, inherited)? The orchestrator cannot write in their repo; the operator relays.
5. **Execution mode**: a Claude Fable subagent under a charter, as for the audit repairs?

## 7. Provenance

[USER] quotes as recorded in `docs/2026-09-02_fuel-arc-design.md` §0, `docs/2026-09-03_typed-failure-outcomes-ruling.md`, the orchestrator's memory of the 2026-09-03 rulings (verbatim there), `docs/2026-09-05_whole-project-audit-response.md` §3, `docs/2026-09-10_codex-charter-are-compatible-assumed-set.md` §0, and the 2026-09-11 conversation (master plan rev 10 §0). Facts verified 2026-09-16 against `a15da65f8`: `CerbFuel.lean:36-61`, `CerbFail.lean:1-24`, `CerbLocation.lean:29-35,59-80,233-268`, `CabsImport.lean:168`, `CoreParser.lean:252`, `Main.lean:1070-1110`, `nondeterminism.lem:25-27,263,520`, `scripts/check_theorem_axioms.sh:187-204`, `scripts/observations.py:44-51,178-184`, refined-cerberus `Heap.lean:1525`, `FUEL.md:165-200`. Analysis and recommendations are [AGENT].
