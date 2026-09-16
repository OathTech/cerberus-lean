# Lean-only outcomes — a scoping note that revisits the design in total (2026-09-16)

**Status:** SCOPING NOTE for the operator. It proposes a design and measures its blast radius; it authorizes nothing and supersedes the D2 design note R0 of the same day (`2026-09-16_structural-outcome-constructors-design.md`, whose recommendation B′ is WITHDRAWN here). Author: the orchestrator [AGENT]. Base: mainline `a15da65f8`.

## 0. Why this note exists, and what it does and does not take as given

[USER 2026-09-16], verbatim: "I'm a bit wary of 'epicycles', funny coding tricks which are downstream of rulings that we made that had unintended effects. So perhaps we should revisit the overall design and orientation wrt the oracle here? If we're adding magic unreachable code paths, I worry we're getting backed into something that is worse than our original ruling anticipated" — and: "can you write a scoping note that revisits this decision in total. Let's see what a clean design looks like here, and what the blast radius would be of making this cleaner. We want to holistically optimize for the best and most principled design (not bake in rulings from when we understood less)".

**Taken as the frame (not under review):** the two properties the operator named — (1) faithfully mirroring upstream Cerberus aside from actual bugs, (2) a clean interface for reasoning — and the standing rules that serve them: zero Lean-vs-oracle execution discrepancies (VALIDATION §0), the four aims, no magic values ([USER 2026-09-03]: "values that limit the semantics or limit the ways the customer can reason about the semantics" are forbidden), the reasoning-artifact lens ([USER 2026-09-03]: can a theorem quantify over it, unfold it, state it without a rendered string?), fail-closed and fail-noisy, mirror-OCaml doctrine.

**Under review (listed so nothing is baked in silently):** [USER 2026-09-02] Option C — the exhaustion sentinel as a kernel-checked `opaque` location atom, and that design's rejection of "Option B (a new `kill_reason` constructor) … it changes the shared `.lem` type and therefore the generated-OCaml text / fork-drift surface, for a constructor the oracle never uses"; the relayed brief constraint [USER 2026-09-04] "we don't change the lem structure for ocaml" AS READ to cover shared TYPES (its evident target was shared BODIES restructured for Lean's convenience); [refined-cerberus 2026-09-02] "we withdraw our request's suggestion of a new `kill_reason` constructor" — withdrawn, in their own words, "under the operator's ordering rule (trust surface stable, 'obviously right' w.r.t. upstream)", i.e. in deference to a rule, not on a technical objection; the 2026-09-05 typed-failure design's Group M (a SECOND atom, "the fuel arc's Option C, second atom"); and D2 R0's B′.

## 1. The phenomenon: outcomes the oracle has no value for

A run of the OCaml oracle ends in one of: a value (`Active`), a kill — `Undef loc ubs` (UB), `Error loc msg` (Core's `error(...)`), `Other err` (a model error such as `Illformed_program`) — an **uncaught exception** (`failwith`/`assert`/`Not_found`/`Division_by_zero`/`Z.Overflow`: process death, exit 125, no value), or **non-termination** (no fuel). Lean is total, so it must have a VALUE where OCaml has none. Three Lean-only outcomes follow, plus one axis that is not an outcome at all:

| Lean-only outcome | Produced by | Represented today as | Recognised today by |
|---|---|---|---|
| **Exhaustion** (the totalisation bound) | the zero case of every absorbing worker — 7 in the kill channel (`nd_bind`, `liftND`, `liftAction`; `driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`; `load_character_array_aux`), 3 in the pure-evaluator channel (`full_eval_pexpr`, `eval_pexpr_aux2`, `eval_pexpr_aux_broken`), 3 runner leaves (`CerbND.runNDFuel`/`runND1Fuel`/`runND1TraceFuel`); the sentinel also appears in the zero case of every MEASURED worker's declare (13 `fuel` declare lines spell it) | `Error0 CerbFuel.fuelExhaustedLoc "lem: fuel exhausted"` in `kill_reason`; `Undefined.Error CerbFuel.fuelExhaustedLoc "…"` in `Undefined.t` — the atom is `opaque fuelExhaustedLoc : Loc := Loc.other "lem: fuel exhausted"` | kernel: NOTHING (opaque — no distinctness from any `Error0`); runtime: the printed TEXT (`Error {msg: "lem: fuel exhausted"}`, regex `FUEL_RECORD`, `fuel_classify.sh`); consumer: the constant `CerbND.fuelExhaustedKill` |
| **Model fail-stop** (mirror of an oracle crash) | 7 hand-written `memM` arms (C-TF1) via `CerbFail.failStopMem` | `Error0 CerbFail.modelFailStopLoc msg`, the atom `opaque modelFailStopLoc : Loc := Loc.other "model fail-stop"` | kernel: `≠ Undef0`, `≠ Other` (free), NOT `≠ fuelExhaustedKill`, NOT `≠ Error0 loc _`; runtime: `loc == modelFailStopLoc` (`Main.lean:1077`, a `BEq` on `Loc` — forgeable by a crafted Cabs JSON `Loc_other`, `CabsImport.lean:168`) → `ModelFailure {msg}` |
| **Unsupported feature** (exception class (c)) | CerbFS: 40 register rows of PURE `panic!` (no outcome — an in-process consumer sees the `Inhabited` default: the typed-failure ruling's gap); the CLI's `refuseFlag` (exit 2 before any run); the concurrency prototype's `model refused: …` message-prefix convention (codec `refusal(prefix)`) | no value; a panic; a prefix | text, exit codes |
| *(not an outcome)* **pure failure** | 233 pure `panic!`/`failwithI` sites in the exec closure (48 REACHABLE), all in code that returns a value, not a monad | the `Inhabited` default in-process; loud only under `LEAN_ABORT_ON_PANIC` | the failure-reach register (a gate); the parked twin design would lift them |

Two shared types host the smuggled sentinel: `kill_reason 'err = Undef | Error of Loc.t * string | Other of 'err` (`nondeterminism.lem:24-27`) and `Undefined.t 'a = Defined | Undef | Error of Loc.t * string` (`undefined.lem:1424-1427`), both identical to upstream. The location argument of `Error` is the only slot a Lean-only meaning can occupy without a type change — which is why every design so far has occupied it.

**The epicycle, named.** (1) Totalisation must be Lean-only and "don't change the lem structure for ocaml" was read to cover types → the sentinel went into `Error`'s location as an opaque atom. (2) The atom needed a soundness story → parametricity in the opaque, plus a census gate to keep it opaque. (3) A second Lean-only outcome copied the pattern → two atoms, unprovably distinct, which the whole-project audit named its first structural priority. (4) The proposed repair (B′) would have added constructors to the LOCATION mirror type with dead arms in every mirroring function — the "magic unreachable code paths" the operator is wary of. Each step was locally rational; the sum is a representation nobody would design from scratch.

## 2. What a principled design must satisfy

Derived from the two properties and the standing rules; each is checkable.

- **P1 Oracle fidelity.** Results identical to the oracle on every input the oracle answers. Where the oracle has no value, the Lean outcome is EXPLICIT and its divergence from upstream is VISIBLE (a generated-delta row in the fork-drift manifest, a tray draft) — never hidden inside a mirror slot as a magic string or an opaque value.
- **P2 Reasoning interface.** Each Lean-only outcome is a constructor: distinct from every other outcome by `noConfusion`, unforgeable because no Core text, JSON or model term has syntax for it, case-able and unfoldable, stateable without reference to a rendered string or a location. No side condition on locations for location-facing theorems.
- **P3 No magic values.** No reserved string or numeral carries meaning; feature names are an enumeration, not text.
- **P4 Output boundary.** The batch protocol reports each outcome kind as a structural record, and the lane classifiers match records, not free text.
- **P5 Minimal mechanism.** If a constructor does the work, no census, no parametricity argument, no runtime equality test.
- **P6 Consumer stability.** Existing consumer statements (`Killed st CerbND.fuelExhaustedKill`, `2 ≤ LemFuel.fuel`, the `DriverSafeCtl` shape) hold unchanged or migrate mechanically; the consumer GAINS distinctness for free.

## 3. The design space, from first principles

Where can an outcome the oracle lacks live?

| Option | Where | P1 fidelity | P2 interface | P3 | P4 | P5 | Verdict |
|---|---|---|---|---|---|---|---|
| **A** reserved string in `Error`'s location (`def … := Loc.other "…"`) | mirror slot | hidden divergence | forgeable from JSON (`Loc_other`); "distinct" only by string | violates | text | small | REJECT (the 2026-09-02 table's A′; worse now that forgeability from JSON is known) |
| **C** opaque atom in `Error`'s location (status quo) | mirror slot | hidden divergence; oracle text untouched | unprovable distinctness; not unfoldable; parametricity argument + census gate; runtime `BEq` forgeable | borderline (a distinguished value) | text | atom + census + argument | KEEP ONLY IF nothing better exists |
| **B′** Lean-only constructors on the `Loc` mirror type (D2 R0) | mirror TYPE | type-shape divergence in one seam; dead arms in every mirroring function | distinct, unforgeable, case-able — but every location-facing theorem carries `isMirror` | ok | text or record | producer census | WITHDRAWN (the operator's objection stands: unreachable magic arms) |
| **B-err** constructors in the `'err` parameter's instantiations (`driver_error`, `mem_error`, …) | shared types anyway | visible | loses the `'err`-POLYMORPHISM the fuel kill needs (`nd_bind`'s zero case must be a `kill_reason err` for every `err`) — the same value cannot be `Other` of two different types | ok | record | per-monad churn | REJECT (mechanism, not principle) |
| **B** new constructor(s) on the shared outcome types `kill_reason` AND `Undefined.t` | the outcome types themselves | VISIBLE divergence: dead constructors in OCaml, generated-delta rows, a tray proposal; results unchanged on every input | by construction: distinct, unforgeable (no syntax), case-able, unfoldable, string-free | enumeration for features | structural records | one type extension, ~10 mechanical propagation arms, no census, no argument | **RECOMMENDED** |
| **D** a lem-lean backend mechanism for TARGET-ONLY constructors (declared extra constructors + default propagation arms in generated matches) | Lean type only | OCaml untouched; Lean and OCaml see DIFFERENT types for one lem type | as B | as B | as B | new backend machinery; a permanent two-type story | FALLBACK if upstream refuses B and the fork does not want to carry the delta |

Why B and not C, in the operator's terms: C's divergence from upstream is real but INVISIBLE (a Lean-only meaning inside an OCaml-shaped value); B's is real and VISIBLE (a constructor upstream can see, decline, or adopt). Faithful mirroring is served better by a visible, tray-filed, dead-in-OCaml extension than by a hidden one. And C fails the reasoning-interface property outright: the audit's finding 1 and the reasoning-artifact lens both say so. The 2026-09-02 objection to B — "for a constructor the oracle never uses" — describes exactly the property that makes B honest.

## 4. The recommended design (B), specified

**4.1 Vocabulary (shared Lem, one small type).**
```
type unsupported_feature =            (* closed; extended only by an operator ruling *)
  | UF_filesystem | UF_concurrency | UF_switches
type interp_stop =                    (* "the interpreter stopped": outcomes an executable
  | Exhausted                            semantics may produce and a reference one cannot *)
  | FailStop of string                (* the mirrored crash's message — reporting payload *)
  | Unsupported of unsupported_feature
```
`kill_reason 'err` gains `| Stopped of interp_stop`; `Undefined.t 'a` gains `| Stopped of interp_stop`. One constructor per channel (not one per kind) keeps every propagation arm a single line and gives the whole project one vocabulary type.

**4.2 Shared Lem bodies — mechanical propagation arms, dead in OCaml.** `liftND` and `liftAction` (`nondeterminism.lem:255-270`, `:512-528`): `| Stopped s -> Stopped s`. `Undefined.t`'s two maps (`undefined.lem:1437`, `:1462`): `| Stopped s -> Stopped s`. The exception-undefined lift (`exception_undefined.lem:14-18`): one arm. The driver's four lifts of an evaluator result into a kill (`driver.lem:159-160`, `:184-186`, `:414-417`, `:435-438`, `:444…`): `| Right (Undefined.Stopped s) -> ND.kill (ND.Stopped s)`. About ten arms in four files, each provably semantics-preserving (OCaml never constructs `Stopped`, so every arm is dead there). `ocaml_frontend/dune` compiles warning 8 (non-exhaustive match) as an ERROR (`-w @8…`), so the OCaml build ENFORCES that every arm exists — completeness is checked by the compiler, not by review.

**4.3 Hand-written OCaml (fork-side, dead arms).** `backend/common/driver_ocaml.ml:173-182` (the batch printer: print the same records Lean prints — §4.5 — so the fork oracle, could it ever produce one, would agree byte for byte), `interactive_driver.ml:130-134`, `backend/ocaml/runtime/rt_ocaml.ml:298-308`, `cerbcore.ml:57` if its match is not already open. Three or four files; every arm dead; layer-1 content pins move.

**4.4 Lean.** `CerbND.fuelExhaustedKill {err} : kill_reason err := Stopped Exhausted` (name kept; polymorphic in `err`, as now). `CerbFail.failStopKill msg := Stopped (FailStop msg)`; a new `CerbStop.unsupportedKill feature msg` (defined; populated by the refusal census slice). DELETE `CerbFuel.fuelExhaustedLoc`, `CerbFail.modelFailStopLoc`, their two `OPAQUE_WANT` census rows (16 → 14), the parametricity text, `fuelExhaustedMsg` (or keep as the printer's string). The 13 `fuel` declare lines in `.lem` re-spell the sentinel (`NDkilled (Stopped Exhausted)`, `Result (Undefined.Stopped Exhausted)`) — Lean-only lines. `Main.lean`'s printer matches `Stopped` by constructor; no `BEq` on `Loc`. `FuelFormsTool` (`fuelAtoms`, `absorbingHeads`) learns the new sentinel shape (gate change, plant-tested). The 13 `_zero` lemma statements regenerate. Distinctness lemmas become `noConfusion` one-liners or disappear.

**4.5 Output boundary (P4).** Batch records: `Exhausted {}` (or `Stopped {kind: "exhausted"}`) replacing `Error {msg: "lem: fuel exhausted"}`; `ModelFailure {msg}` (exists) for `FailStop`; `Unsupported {feature: "…", msg: "…"}` for refusals. The codec (`observations.py`) gains the kinds; `FUEL_RECORD`, `fuel_classify.sh`, `test_fuel_plant.sh`, `test_failstop_plant.sh`, the observation-lanes plants update. **No committed baseline holds a FUEL row** (checked 2026-09-16 across all seven baseline files), so the text change moves NO existing row: this is the one moment a structural record is free. The human-readable (non-batch) printer likewise.

**4.6 Upstream.** A tray PROPOSAL draft: "`Stopped of interp_stop` — interpreter-stop outcomes for bounded and mechanised executions of Core; dead in the OCaml interpreter; the fork carries it". Upstream may decline; then the fork carries the delta exactly as it carries drafts 37–39's, visibly.

**4.7 Doctrine to ratify (replacing the 2026-09-04 reading and the 2026-09-02 Option-C precedent).** (i) An outcome the oracle has no value for is a CONSTRUCTOR of the shared outcome types, dead in OCaml, visible in the drift manifest, tray-filed. (ii) No Lean-only value inhabits an OCaml-mirror slot — a location, a string, a numeral — to carry meaning. (iii) Shared TYPE extensions of this class are permitted by ruling; shared BODY changes still require a correctness or termination rationale (propagation arms forced by (i) are the mechanical consequence of the type, not body changes of substance).

## 5. Blast radius, itemized

| Surface | What moves | Size | Visibility / gate |
|---|---|---|---|
| Shared Lem types | `kill_reason`, `Undefined.t` gain `Stopped of interp_stop`; two small new types | 2 + 2 types, one file each (or one `interp_stop.lem`) | fork-drift `[source-content]` rows move; tray draft |
| Shared Lem bodies | ~10 propagation arms in `nondeterminism.lem`, `undefined.lem`, `exception_undefined.lem`, `driver.lem` | ~10 lines | OCaml compiler enforces exhaustiveness (`-w @8`); every arm dead in OCaml |
| Lean-only `.lem` declares | 13 `fuel` sentinel spellings | 13 lines | none (Lean-only) |
| Generated OCaml | `nondeterminism.ml`, `undefined.ml`, `exception_undefined.ml`, `driver.ml` (+ any module the compiler flags) | ~4 files join/move in layer 2 (24 → ~28) | `check_fork_drift` hash pins; pristine lane unchanged in behaviour (OCaml never produces `Stopped`) |
| Hand-written OCaml (fork) | printer + 2–3 matches, dead arms | 3–4 files | layer-1 pins move |
| Lean seams | `CerbFuel` (atom deleted), `CerbFail`, `CerbND`, `CerbFailProofs`, `Main`, new `CerbStop` | −2 opaques; simpler proofs | boundary census 16 → 14 |
| Generated Lean | the two types; 13 `_zero` statements; `Nondeterminism.lean:584`-style lifts | regenerated | `check_fuel_forms` shape (tool update, plant-tested); `check_theorem_axioms` |
| Output boundary | batch records, codec kinds, `fuel_classify.sh`, three plants, human printer | ~6 scripts | zero existing-row movement; plants re-pinned |
| Consumer (refined-cerberus) | `fuelExhaustedKill` name and shape kept; ONE literal spelling of the old term (`Heap.lean:1525`) and `FUEL.md`'s text change; `DriverSafeCtl` unchanged; distinctness gained | small, mechanical | re-pin item; second review before the slice |
| Docs | VALIDATION §1(b)/(c), §7, §9; fuel-arc design §1.3 superseded; typed-failure design Group M superseded; DESIGN.md; TODO (b); master plan step 5b → this note | docs | landing |
| Refusals (`Unsupported`) | vocabulary + record ONLY here; CerbFS's 40 pure panics need a monadic channel to raise a kill — the refusal-census slice's design problem | 0 sites converted here | census gate |
| Pure-failure axis | untouched (233 sites; parked twin) — `interp_stop` gives the twin its `FailStop` vocabulary if it ever goes live | — | failure-reach register |

**Risks, named.** Upstream declines the proposal — the fork carries a small visible delta (already the case for three others). The `Undefined.t` extension touches the pure evaluator's core type — but only through propagation arms the compiler forces; no evaluation rule changes. The generated-OCaml surface moves by ~4 files — reviewed by the drift gate, all hunks dead code. The consumer's one literal term and its docs move — a re-pin item, small. The output records change — no baseline row exists to move; the plants and codec are the only casualties, and they are gates, updated with the change. Effort: one medium slice (comparable to the parser-progress-measure slice), one Lem/Cerberus worktree pair is NOT needed (no lem-tool change), upstream lem unaffected.

## 6. Staging

S1 (one slice): §4.1–4.5 + the tray draft + gates + docs; zero existing-row movement is the gate; refined-cerberus's second review of THIS note precedes the charter (the 2026-09-02 practice). S2 (the refusal census slice, already in the plan): populate `Unsupported` where a monadic channel exists; the pure CerbFS panics follow the census's route. S3: the consumer re-pin. In the master plan: S1 REPLACES step 5b; the frozen vocabulary is what L1's declare consolidation then consumes.

## 7. What this supersedes, and the decisions for the operator

Superseded on adoption: [USER 2026-09-02] Option C (the opaque-atom design) and its Option-B rejection; the type-covering reading of [USER 2026-09-04]; the 2026-09-05 typed-failure design's Group M mechanism (its census and sites stand; its atom goes); D2 R0 (B′). The rulings' RECORDS stay as history; this note is the one that changes the design.

Decisions:
1. **Adopt B and the doctrine of §4.7** — a shared-type extension for Lean-only outcomes, dead in OCaml, visible, tray-filed?
2. **One `Stopped of interp_stop` constructor per channel** (recommended) or one constructor per kind?
3. **The structural `Exhausted` record now** (no baseline cost today) — recommended — or keep the text in S1?
4. **`unsupported_feature` closed at {filesystem, concurrency, switches}** for now?
5. **Second review by refined-cerberus** of this note before any charter (the operator relays)?
6. **If upstream declines**: carry the delta (recommended) or invest in the backend mechanism D?

## 8. Provenance

[USER] quotes verbatim from the 2026-09-16 conversation, `docs/2026-09-02_fuel-arc-design.md` §0/§1.3/§"Why C", `docs/2026-09-05_typed-failure-outcomes-design.md` §0/§2.1, refined-cerberus `docs/2026-09-02_review-of-cerberus-lean-fuel-arc-design.md` §1, the 2026-09-03 rulings as recorded in the orchestrator's memory and `docs/2026-09-03_typed-failure-outcomes-ruling.md`. Facts verified 2026-09-16 at `a15da65f8`: `nondeterminism.lem:18-40,255-270,512-528,545-556,568-571`; `undefined.lem:1424-1462`; `exception_undefined.lem:4-18`; `driver.lem:146-160,184-186,412-444,1907-1912`; `core_eval.lem:1234-1243`; `core_reduction.lem:1552`; `formatted.lem:412`; `defacto_memory.lem:2682-2690`; `backend/common/driver_ocaml.ml:173-182,217`, `interactive_driver.ml:130-134`, `backend/ocaml/runtime/rt_ocaml.ml:298-308`; `ocaml_frontend/dune:7`, `backend/common/dune:5`; `CerbFuel.lean:36-61`; `CerbFail.lean:1-24`; `Main.lean:1070-1115`; `CabsImport.lean:168`; `scripts/check_theorem_axioms.sh:187-204`; `test/Unit/FuelFormsTool.lean:306-308`; `scripts/observations.py:44-51,114,178-184`; `scripts/fuel_classify.sh:47-49`; `scripts/test_fuel_plant.sh`; the seven baseline files (0 FUEL rows); refined-cerberus `Heap.lean:1525`, `FUEL.md:165-200`, `API.lean:62-63`. Analysis and recommendations are [AGENT].
