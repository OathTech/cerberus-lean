# Effects + totality design note (arc 1, slice 1)

Status: DRAFT — ends at the slice-1 USER CHECKPOINT (design ruling).
Charter: `2026-08-18_arc1-effects-totality-charter.md`. Pattern source:
golean (`deps/golean/docs/2026-07-18_totality-fuel-decision.md`,
`2026-07-21_eval-totalization-correspondence.md`).

## 1. Census (measured on `arc/effects-totality` @ bd9824e37, lem dff1957)

Effects — 6 effectful vals in 3 model files, 315 generated call sites:

| Effect | Vals | Sites | Where |
|---|---|---|---|
| debug | `get_level`, `print_debug` | **302** | everywhere (30 modules) |
| fresh | `fresh_int` | 8 | Symbol (7 wrappers), Translation_effect |
| tagDefs | `tagDefs`, `set_tagDefs`, `reset_tagDefs` | 5 | Ctype_aux (reads), Core_unstruct |

Transitive caller closure of the 13 non-debug sites: **263 defs** across the
pipeline. But restricted to the **execution slice** (Core_run, Core_reduction,
Core_eval, Driver, Defacto_memory, Core_aux — the fuel-opsem TCB):

- `fresh` usage: **zero**. All fresh flows through desugar/translation.
- tagDefs usage: **reads only** (6 sites, all in Defacto_memory via
  `get_structDef`/`get_unionDef`/`get_membersDefs`); writes happen only in
  desugaring (`register_tag_definition`) and Core_unstruct.
- debug: stubbable (§3).

Totality — 444 `partial def` in the built tree = **306 lem-generated**
(Cabs_to_ail 50, Core_aux 37, Core_rewrite 16, Defacto_memory 15,
GenTyping 14, Core_reduction 11, …) + 138 hand-written parsing infra
(CoreParser 87, CabsImport 37 — not proof-path).

## 2. Structural findings (change the problem)

- **F1 — HOL precedent for debug stubs**: `debug.lem` already declares
  `hol target_rep function get_level u = 0`. Debug effects are semantically
  inert; theorem-prover targets stub them.
- **F2 — the model already has the tagDefs seam**: `ctype_aux.lem` defines
  `get_structDef_with_tagDefs` (parameterized) with `get_structDef` as the
  global-reading convenience wrapper. tagDefs is set-then-frozen: written
  during desugar, read-only during execution.
- **F3 — defacto_memory is already monadic**: own state monad `impl_memM`
  with `get`/`put`; `fresh_allocation_id` is *already threaded through
  monad state*, and `print_debugM` exists. The effectful externs in the
  Lean port are conveniences of the port, not structural necessities of
  the model.
- **F4 — nondeterminism is already reified**: `ndM` is a constructor tree
  (`NDnd`/`NDguard`/`NDbranch`/`NDstep`) with explicit state. Outcome-set
  (exhaustive) semantics is first-class in the model; the fuel opsem
  interprets this tree. No ND design work needed at the lem level.
- **F5 — lem has a termination-settings hook**: `try_termination_proof`
  consults per-constant termination settings; the backend already emits
  `def` (Lean equation compiler) when set, `partial def` otherwise. A fuel
  mode slots into existing machinery.
- **F6 — TCB scoping**: goal 2's theorem substrate is the *Core execution*
  semantics. Desugar/translation are *translators*: in the TCB the way the
  OCaml C parser is — validated differentially (goal 1), not proved over.
  The scaffold (never_extract + unsafe externs) is sound for translators
  indefinitely; it must merely never be reachable from proof-path terms.

## 3. Effects design options

- **O-A: full monadic lifting** (the `549e2ac` sketch at full generality).
  Backend effect inference; the 263-def closure re-typed into an effect
  monad in Lean output. Honest everywhere; largest lem feature; churns the
  entire generated surface; most upstream-review risk.
- **O-B: stratified honesty (RECOMMENDED)**:
  1. *debug* → pure stubs on the proof path (`get_level = 0`,
     `print_debug _ _ = ()`), HOL-style, via ordinary `lean` target_reps.
     Kills 302/315 sites. (Execution keeps IO externs only if we decide
     debug output from the Lean pipeline is worth a dual-flavor mechanism —
     default: no; differential debugging uses the OCaml side.)
  2. *tagDefs on the execution slice* → **reader-style threading**,
     backend-lifted: a `declare {lean} reader val tagDefs`-class mechanism
     making defs that (transitively) read tagDefs take it as an extra
     Lean-side argument, seeded at the opsem entry point. Reader lifting is
     argument-threading only — no bind restructuring — and the measured
     scope is ~75 exec-slice defs. Aligns with F2 (the model's own
     `_with_tagDefs` shape) without touching `.lem`.
  3. *fresh + tagDefs-writes* (desugar/translation only) → keep the
     scaffold, marked execution-only. Their honest treatment becomes part
     of a later "verified translation" arc if ever wanted; F6 says it is
     not on the goal-2 critical path.
- **O-C: scaffold everywhere, prove around it** — rejected: memory ops
  read tagDefs, so the exec slice would have unsafe externs reachable from
  proof-facing terms. Fails the TCB statement.

## 4. Totality design (golean pattern, adapted)

1. **Structural first**: most of the 306 recursions are over syntax/value
   trees (ctype, expr, mem_value). Flip these to plain `def` via lem's
   existing termination settings (per-family declares; Lean's equation
   compiler does the work). Expect a long tail that needs small backend
   fixes rather than fuel.
2. **Fuel only at genuinely non-structural points**: the driver/reduction
   step loops and env-mediated recursions. New declare (strawman syntax:
   `declare {lean} fuel val core_steps`) emitting a fuel'd worker
   (`f_fuel : Nat → …`, sentinel on zero — composed into the existing
   error/ndM channel, no new carrier) + a thin wrapper at default fuel so
   call sites are unchanged (golean's exact shape; their cost line —
   "fuel large enough" side conditions, dischargeable — accepted).
3. Fuel is decremented only at the declared points, never on structural
   descent: it bounds step counts/nesting depth, not value size.

## 5. TCB statement (the design's honesty contract)

Proof path (exec slice, post-design): pure defs, tagDefs by argument,
debug stubbed, ND as tree interpretation, fuel explicit. Axioms: none
reachable except the declared boundary list (DAEMON Inhabited fallbacks —
audited separately, Phase 1). Scaffold (`runEffectful` + unsafe externs):
reachable only from translator stages; the correspondence obligation
execution↔proof is *definitional equality per def* (same generated code,
differing only in the three seams above), not a simulation proof.

## 6. Slice-2 exemplar (proposal — CHARTER DEVIATION, flagged)

The charter named `fresh_int` as the exemplar. The census shows fresh is
NOT on the proof path; the representative exemplar is:

- **tagDefs-read reader lifting** through `get_structDef` →
  `Defacto_memory.get_membersDefs` → one memory op, seeded at an entry
  point; `fresh-int-test` stays green via scaffold (unchanged, execution);
  a new unit test exercises the lifted path.
- **One fuel'd family**: a small non-structural exec-slice recursion
  (candidate: the `core_steps`-style loop in Core_run or the ctype
  resolution in Defacto_memory), plus one structural family flipped to
  total `def` via termination settings.
- **Toy theorem** over the exemplar output (e.g. a `get_membersDefs`
  lookup lemma, or determinism of the fuel'd step on a trivial program) —
  the reasoning smoke test the scaffold cannot pass.

## 7. CHECKPOINT RULINGS (user, 2026-08-18 — slice 1)

All four recommendations ruled as recommended: **O-B stratified honesty**;
**debug stubbed everywhere** (revisit on pain); **reader lifting as a lem
declare class** (upstreamable); **exemplar swapped to tagDefs+fuel** (the
charter's fresh_int exemplar is superseded — fresh stays scaffold-only in
translator stages, its honest treatment deferred to a possible future
verified-translation arc). Q5 (fuel declare shape) deliberately left to
slice-2 iteration.

## 7a. Slice-2 findings (implementation, 2026-08-18)

- Debug stubs (2a): 315 → 16 runEffectful sites; gate at baseline.
- Reader lifting (2b): implemented in lem (`declare {lean} reader val`,
  lem-lean `b51ef11`) — fixpoint pre-pass per module (emission renders
  last-to-first, so in-order registration was unsound; caught by the
  transitivity test), parameter injection at the bare-Constant rendering
  (exactly once), fail-closed on instance methods. Applied to `tagDefs`:
  full cerberus build green with only **two hand-written seed sites**
  (`desugar`, `drive` in Main.lean), both seeded from the live global via
  the hardened accessor (`CerbTags.tagDefs`, now `never_extract`).
- Debug stubs NARROWED the reader closure sharply: GenTyping/AilTypesAux
  no longer lift at all (their effect use was debug-only); the tagDefs
  read closure is desugar-init + Defacto_memory + Core_run/Driver.
- **Seed-freshness argument**: OCaml's global is also unset during
  desugaring (desugar threads tag defs in its own monad state; only later
  stages call set_tagDefs), so entry seeding ≡ OCaml behavior — EXCEPT
  across mid-phase writes: the single `with_tagDefs` rebinding site
  (mini_pipeline, WIP translator glue) and any set-then-read within one
  lifted region (Core_unstruct — audit when the pipeline reaches it).
  Recorded as a correctness obligation for the Phase-2 desugar arc, not a
  blocker: the execution slice seeds at `drive` AFTER registration, which
  is unconditionally correct.

## 7b. Slice-2c findings — totality exemplar + reasoning smoke test

- The existing lem hook works unchanged for the structural case:
  `declare {lean} termination_argument f = automatic` (placed AFTER the
  definition) flips emission from `partial def` to `def`, and Lean's
  equation compiler accepts `core_object_type_of_ctype` (ctype-structural).
  No new lem feature needed for this class — the totality work for the
  ~306 generated partials is a declare-audit sweep plus fixes for
  whatever the checker rejects.
- `zeros_aux` REJECTED as expected: its Struct/Union cases recurse on
  member types fetched from tagDefs — env-mediated recursion, golean's
  `.defined` class exactly. Reverted to `partial`, designated the first
  fuel candidate. The fuel declare (Q5) remains the one unimplemented
  mechanism; its design should carry a sentinel expression per declare
  (generic honest fuel-out values don't exist without type knowledge).
- **Reasoning smoke test green** (`effects-proof-test`, in the unit
  gate): three SYMBOLIC `rfl` theorems over the now-total
  `core_object_type_of_ctype` (impossible over `partial def` — no
  equations) and a lookup theorem over reader-lifted `get_membersDefs`
  (impossible over the extern scaffold — the state was invisible). Plain
  `rfl`, no native_decide, no axioms beyond the kernel.

## 7d. Slice-2d findings — the fuel declare (implemented)

`declare {lean} fuel val f = \`sentinel\`` landed in lem (64fa622): total
worker (structural on an explicit Nat), self-calls rewritten to the
decremented binder, point-free wrapper at LemLib.lemDefaultFuel so call
sites are unchanged and proofs unfold wrapper → worker definitionally.
Fail-closed on multi-clause/mutual/instances/reader-combination. Applied
to `zeros_aux` with sentinel `CerbMem.zerosFuelExhausted ()` (a hand-
written panic helper — lem's backtick strings cannot contain double
quotes, so string-literal sentinels are expressed via helpers). Lake pin
moved to the lem arc branch per the charter pin-dance. Proof test grew a
wrapper-defeq theorem and a fuel-symbolic integer-case theorem, both rfl.
The exemplar chartered for slice 2 is now COMPLETE: reader + structural
totality + fuel + theorems, all gated.

## 7c. fresh as an explicit choice-stream input (user question, 2026-08-18)

Ruled direction for the eventual honest treatment of `fresh` (parked until
a verified-translation arc needs it): an explicit CONSUMED stream/counter
input — i.e. state threading, not reader (consumption must advance, which
is exactly what reader cannot express). With the canonical stream 0,1,2,…
this is extensionally identical to OCaml's `Cerb_fresh.int`, preserving
symbol numbering and hence stage-by-stage differential comparability.
Mechanism when needed: a `declare {lean} state val` sibling of the reader
declare, threading through the desugar/translation monads the model
already has. Two alternatives considered and rejected:
- splittable supply (UniqSupply-style, reader-shaped): keeps the cheap
  transform but numbering diverges from OCaml — breaks the differential
  instrument for exactly the stages it would serve;
- ND choice stream (oracle sense): over-general — fresh is deterministic
  bookkeeping, not latitude; supply-quantified theorems would pay a
  permanent tax for envelope width the OCaml semantics does not have.

## 8. Open questions as posed (for the record)

1. O-B (stratified) vs O-A (full lifting) — is execution-slice honesty +
   translators-in-TCB acceptable as the goal-2 stance? (Recommended: yes;
   it matches "OCaml parser stays a trusted front".)
2. Debug on the Lean execution path: stub everywhere (lose Lean-side debug
   output, simplest) or dual-flavor (keep IO externs for execution)?
   (Recommended: stub everywhere; revisit on pain.)
3. Reader-lifting mechanism shape: new declare class in lem (upstreamable,
   recommended) vs hand-maintained parameterized shadow defs in the
   support files (no lem change, more drift risk)?
4. Exemplar swap per §6 (recommended) or keep fresh_int as chartered?
5. Fuel declare naming/shape — bless the strawman or iterate at slice 2?

## 9. Scale plan (slice 3, 2026-08-18)

**Effects: the goal-2 path is already converted.** After the exemplar, the
13 remaining runEffectful sites are all translator-stage (fresh + tagDefs
writes), which the O-B ruling leaves on the scaffold indefinitely. No
further effects work is needed for the fuel-opsem TCB. Deferred, with
recorded designs: fresh → consumed-stream state threading (§7c, a
'declare {lean} state val' sibling) when a verified-translation arc wants
it.

**Totality: one mechanical arc remains for the exec slice.** ~90 of the
306 lem-generated partials are execution-slice (Core_aux 37,
Defacto_memory 15, Core_reduction 11, Core_eval/Core_run/Core_typing ~20).
Strategy per the exemplar: batch `termination_argument = automatic`
declares, let Lean's checker adjudicate, fuel the rejects (the driver/
core_run step loops return ndM — honest error-channel sentinels exist).
Proposed as the next arc (**arc 2: totalize-exec-slice**), mechanical
enough for batched work, exit = zero partials in the exec-slice modules +
the proof test extended per converted family. Translator-stage partials
(Cabs_to_ail 50 etc.) can wait for their pipeline arcs.

**Known hazards carried forward** (all recorded above): instance-method
reader gap (fail-closed will fire visibly if pipeline work puts a lifted
call in an instance); with_tagDefs rebinding in mini_pipeline (Phase-2
desugar obligation); fuel wrappers restart the budget per external call
(right for depth-bounding; revisit if a cross-call budget is ever needed).

**Lem feature census for upstreaming** (Phase 4 input): effectful (fixed),
reader, fuel, termination_argument (pre-existing), extra_import,
skip_instances — all declare-scoped, no .lem model restructuring anywhere.

## 10. PRE-MERGE AUDIT RESULTS (2 adversarial agents, 2026-08-18) — CORRECTIONS

The audit refuted several of this note's claims. Corrections, binding over
anything above:

- **§1/§5/§9 are WRONG that the execution slice is fresh-free.**
  `Symbol.fresh` is called from `core_run.lem:585` (the Load action) and
  `core_reduction.lem:1251,1294` (SeqRMW/Neg) — so `runEffectful` + the
  unsafe extern counter ARE reachable from the opsem. The census grep was
  defeated by generated-code whitespace (`fresh  ()` vs pattern `fresh (`)
  and by counting where runEffectful SITES live instead of which stages
  CALL them. Honest fresh treatment is therefore ON the goal-2 critical
  path (see §11 options). Corollary: the never_extract protection being
  one-level-deep (audit) means closed applications of step functions are
  in the hazard class until this is fixed.
- **§7b's "no axioms beyond the kernel" is WRONG.** All six theorems
  depend on the DAEMON axiom (∀ {α : Type}, α — False-implying, hence the
  axiom environment is inconsistent for external checkers). The theorems
  remain non-vacuous as rfl-proofs (deletion-tested by the audit), but
  they certify nothing to a consumer until DAEMON is repaired. DAEMON
  repair (real Inhabited derivation or Nonempty-bounded axiom) is promoted
  to a top Phase-1 priority.
- **§5's axiom boundary list was incomplete**: besides DAEMON, sorryAx is
  on the exec slice (`easy_update_mem_value` target_rep in Defacto_memory
  — a known Phase-1 item — plus ~76 instance-fallback sorries in exec
  modules), and runEffectful (via fresh, above).
- **§7a's seed-freshness argument fails for the desugar seed TODAY**, not
  just in a future arc: `Cabs_to_ail` → `evalIntegerConstantExpression` →
  mini_pipeline's `with_tagDefs` extent runs the driver on the STALE entry
  seed (e.g. `int a[sizeof(struct S)]`), and worse, reads are SPLIT within
  that extent: hand-written CerbMem reads the swapped global while
  generated code reads the stale parameter. The `drive` seed remains
  correct. Note mini_pipeline.lem is port-local glue, not upstream model —
  it can be restructured freely (objective 3 does not protect it).
- **§4 deviations reconciled**: fuel decrements on ALL self-calls of a
  fuel'd def (whole-def fuel), not only non-structural ones; and the
  zeros_aux sentinel is a panic-returning-default, not an error-channel
  value. Both intended for the exemplar; §4's stronger phrasing withdrawn.
- Lem-side mechanism fixes landed in response (lem arc a15696b): pre-pass
  Val_def granularity (class-method poisoning), fuel-wrapper attributes,
  honest one-level-deep comment, infix-gap documentation.
- Theorem-strength notes accepted: wrapper-defeq certifies shape only;
  fuel recursion is not yet exercised by any theorem.

## 11. Replanning input: is the requirement set satisfiable? (2026-08-18)

The audit sharpened a real three-way tension at exec-slice fresh:
(a) honesty (no hidden state under theorems), (b) objective 3 (declares
only, no .lem restructuring), (c) OCaml-identical observable behavior.
Pick any two cleanly; all three need one of these relaxations:

- **R1 — backend monadification, scoped**: a `declare {lean} state val`
  that threads a counter through the fresh closure on the exec slice
  (step_ctx/core_action_step and callers), Lean-output-only. Keeps (b)
  and (c); costs the O-A machinery we hoped to avoid (bends objective 4's
  "keep lem reasonable" — this is a real compiler feature, upstream
  review risk).
- **R2 — small upstreamable .lem patch**: thread the fresh counter
  through the EXISTING core-run thread state (the model already threads
  state everywhere else; OCaml upstream might well accept explicit
  threading as an improvement). Bends (b)'s letter, arguably keeps its
  spirit ("mergeable with upstream").
- **R3 — relax numbering parity for exec-slice bookkeeping symbols**:
  derive names deterministically from data already in scope. Bends (c)
  for traces/goldens (final verdicts likely unaffected); requires R1- or
  R2-style plumbing anyway to get the in-scope data — so R3 alone does
  not close the gap.

Also required regardless of choice: DAEMON repair (Phase 1, promoted) and
mini_pipeline restructuring (port-local, unprotected). The requirement
set is NOT unsatisfiable on current evidence — but it requires choosing
R1 or R2, and that choice is the user's.
