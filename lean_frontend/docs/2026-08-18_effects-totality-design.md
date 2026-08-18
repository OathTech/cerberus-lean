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
