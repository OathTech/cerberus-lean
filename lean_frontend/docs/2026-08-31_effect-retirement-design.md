# Effect retirement: deleting `runEffectful` from the semantics (design note)

Date: 2026-08-31. Branch `arc/effect-retirement` (base: mainline
`58ec50779`). Status: DRAFT — core document, pending fresh adversarial
review, then governs the combined lem-lean/cerberus-lean implementation
arc. §1 is written to be consumable standalone by the refined-cerberus
project.

Operator-ratified constraints this note works under, verbatim
provenance [USER 2026-08-31]:

1. **Mechanism route**: fork-local lem BACKEND supply-lifting (state
   analog of the existing reader lifting) — NOT a rewrite of the
   shared .lem model. "Not disturbing the OCaml *output* is a first
   class objective, not quite a red line but certainly extremely
   important."
2. **CerbDebug**: debug output moves OUT of the semantics cone — the
   model returns values, the driver prints.
3. **Arc shape**: combined lem arc — supply-lifting AND
   per-declaration fuel budgets ride the same lem-lean arc/pin dance
   (fuel budgets have their own design note; see §8.3).

Project aims for the lem-lean side, [USER 2026-08-31] verbatim:
"(1) minimal blast radius for non-Lean lem users, (2) obviously right
output for Lean, (3) clean and understandable design, (4) built to be
reviewed by the upstream lem team, and eventually upstreamed as a lem
feature."

Companion input: the 2026-08-31 backend quality review (commissioned
[USER 2026-08-31]; lem-lean
`doc/lean-backend/2026-08-31_backend-quality-review.md`) — this note
adopts its "fix first" preamble as slice L0 (§8.1), its
implementation constraints on the supply feature (§3.2), its
deletion-completeness and sequencing obligations (§3.5, §7), and its
scope question (§9 Q4).

Headline findings of the census/analysis (details in §2–§3; also
reported to the orchestrator):

- **F1 (design-level, load-bearing).** A first-order supply-lifting —
  the exact state analog of the reader lifting — cannot, by itself,
  reach the live `fresh_int` clients: every live path crosses a
  monadic higher-order boundary (`desugM` at the constant-expression
  seam, `elabM` throughout elaboration) where state-passing is not
  type-preserving. Reader lifting survives closures via partial
  application; state lifting has no analogous repair. §3.3 states
  this precisely; §3.4 proposes the resolution (backend feature for
  the first-order region + three bounded, OCaml-output-preserving
  model accommodations on the arc-13 precedent) and §9 puts the
  scope amendment to the operator.
- **F2 (census sharpening).** "13 generated runEffectful call sites"
  = 13 grep hits; 9 are applied call sites (Symbol.lean 7,
  Core_run_aux.lean 1, Translation_effect.lean 1), 4 are comment
  mentions in hand-written support files copied into `generated/`
  (CerbTags 2, CerberusFresh 1, CerbDebug 1). No applied
  `runEffectful` site exists for `set_tagDefs`/`reset_tagDefs` or for
  CerbDebug: those two retirements are entirely hand-written/driver
  and native-seam cleanups, with no backend transform involved.
- **F3 (census).** `Core_unstruct` is generated and built
  (`lean_frontend/lakefile.toml:51`) but imported by nothing in the
  Lean pipeline — its two `Symbol.fresh` sites are Lean-dead code
  that nevertheless count in the census and would trip the new
  transform's closure guard. §3.4 (c) proposes dropping it from the
  Lean build list.
- No fourth `declare {lean} effectful` site exists (repo-wide grep,
  §2.1) and no effectful call site sits inside a generated instance
  method (§8.4, risk R4).

## 1. Problem statement and the customer contract

### 1.1 What `runEffectful` is

Lem permits target-representation functions with pure types but
effectful implementations (a fresh-name counter, mutable tag state).
Lean type-checks purity and optimizes on it: the compiler will
CSE-merge or closed-term-extract two calls of a "pure"
`fresh () : Nat`. The Lean backend's present resolution is to
implement effectful target reps as `BaseIO` externs and cross them
back into pure types at exactly one declared point
(`lem-lean/lean-lib/LemLib.lean:50-60`):

```lean
@[never_extract, noinline]
private unsafe def runEffectful_impl {α : Type} (thunk : Unit → BaseIO α) : α :=
  unsafeBaseIO (thunk ())
@[implemented_by runEffectful_impl]
axiom runEffectful {α : Type} : (Unit → BaseIO α) → α
...
attribute [never_extract] runEffectful
```

The backend wraps each call site of a `declare {lean} effectful` val
in `(runEffectful (fun () => ...))` (`lem-lean/src/lean_backend.ml:2986-2990`)
and emits `@[never_extract, noinline]` on every generated def whose
body contains such a site (`:2088-2090`, `:2229-2235`; visible on
`generated/Symbol.lean:298-329`).

This is an **axiom**. It is declared a *temporal* boundary on both
sides: lem-lean's `doc/lean-backend/DESIGN.md` ("The effect boundary
is one axiom, by design. ... The boundary is *scheduled, not
permanent*", scheduled-not-permanent marked by [USER 2026-08-24],
lem-lean commit `95ac6a5`), and cerberus-lean's boundary list
(`lean_frontend/CLAUDE.md` Status: "the one residual, LemLib's
`runEffectful`, is temporal, lem-side"; backlog entry: TODO.md "Kill
the residual effect axiom"). cerberus-lean itself has zero axiom
declarations — the former `with_tagDefs`/`forceIO` axioms are
kernel-checked opaques since arc-17 S2b — enforced by
`scripts/check_theorem_axioms.sh` (hand-written census = 0,
generated-tree census = 0, boundary opaques present exactly once).

### 1.2 Why it must go now

The successor verification project (refined-cerberus) reasons over
this repository's Core semantics. Its theorems' axiom cones must
bottom out in Lean's three standard axioms. Today, any definition
whose compiled cone touches a `runEffectful` site carries the
`runEffectful` axiom in its `#print axioms` census, and the erasure
claim it represents ("running the thunk and projecting the value is
sound at this site") is exactly the kind of unformalized boundary the
customer cannot absorb.

### 1.3 The contract and the acceptance gate

**Contract (what refined-cerberus may rely on after this arc):**

- `LemLib` (the lem Lean runtime) contains **zero** `axiom`
  declarations. `runEffectful` does not exist under any name.
- For every entry constant of the executable semantics — the set is
  fixed as: `driver2`, `drive`, `RelSem.Cerb.callND`,
  `initial_driver_state`, and the per-phase frontend entries
  (`desugar` entry, `annotate_program`, `translate`, `link`,
  `convert_file`) — `#print axioms` yields a **subset of**
  `[propext, Classical.choice, Quot.sound]`. Exact-list assertion,
  fail-closed, wired into `check_theorem_axioms.sh` (§7.2).
- What remains on the *runtime* trust boundary (declared, gated, not
  axioms): the `@[implemented_by]`/`@[extern]` seams for the per-TU
  digest machinery (`CerberusFresh.digest`/`md5Hex`/`forceIO`) —
  kernel-checked opaques whose compiled behavior is native. No proof
  can unfold them; they contribute nothing to any axiom cone.
  (Adjacency note: threading the per-TU digest as an explicit input
  is a possible later arc; it is out of scope here because it costs
  no axiom. Whether the arc's bar is this — "axiom gone" — or the
  strictly larger "no impure pure-signature constants" is put to the
  operator as §9 Q4.)
- Non-kernel proof methods remain gate-banned (D14) — unchanged.

**Acceptance criterion, stated as a checkable gate:** the arc is done
when the ratcheted `check_theorem_axioms.sh` (§7.2) passes — LemLib
census zero, exec-entry exact axiom census ⊆ the standard three,
`runEffectful` grep-ban clean — AND the full validation battery
(`scripts/LADDER.md` Tier A + Tier B, `test_verify.sh`, speclab
lanes) is green at the same commit pair (lem pin = Lake pin = branch
heads). A green build is not the signal; the differential baselines
are.

Current-state honesty: which entry cones contain `runEffectful`
*today* is measured, not assumed, at implementation-arc S0 (§8.1).
Expectation from the static census: `initial_driver_state` and the
frontend entries are dirty (via `Symbol.fresh*` and the
`initial_core_run_state` seed); `driver2` may already be clean (the
run-time mint is threaded, §2.3); the gate covers the whole entry set
either way.

## 2. Client census, with call-graph evidence

### 2.1 The annotation sites

Repo-wide, exactly three (`grep -rn "declare {lean} effectful"`):

| Site | Val | Type | Lean target_rep |
|---|---|---|---|
| `frontend/model/symbol.lem:231` | `fresh_int` | `unit -> nat` | `CerberusFresh.freshIntIO` (extern, `native/fresh_int.c`) |
| `frontend/model/ctype_aux.lem:29` | `set_tagDefs` | `map sym (Loc.t * tag_definition) -> unit` | `CerbTags.setTagDefsIO` (extern, `native/tags.c`) |
| `frontend/model/ctype_aux.lem:78` | `reset_tagDefs` | `unit -> unit` | `CerbTags.resetTagDefsIO` (extern, `native/tags.c`) |

Applied generated `runEffectful` sites: 9, all `fresh_int` (through
the `Symbol.fresh*` family): `generated/Symbol.lean:299,303,307,311,
323,326,329`, `generated/Core_run_aux.lean:395`,
`generated/Translation_effect.lean:178`. `set_tagDefs` and
`reset_tagDefs` have **zero** applied generated sites: no `.lem` code
calls them (grep over `frontend/model/*.lem`); their only callers are
hand-written `Main.lean` BaseIO calls (§2.4). The remaining 4 grep
hits are doc comments in the hand-written support files
(`generated/CerbTags.lean:6,46`, `generated/CerberusFresh.lean:139`,
`generated/CerbDebug.lean:48` — hand-written files are copied into
`generated/` by `Makefile:303-307` `LEAN_HANDWRITTEN`).

### 2.2 fresh_int: the ambient counter and what already threads

OCaml: `fresh_int = Cerb_fresh.int` (`symbol.lem:229`), the single
global counter (`util/cerb_fresh.ml`). Arc-13 (scheme R-B,
`docs/2026-08-22_arc13-s0-scheme-decision.md`) restored the oracle to
exactly one ambient supply, byte-identical to upstream numbering,
with a dynamic backstop at the desugar seam
(`CERB_FRESH_FLOOR_VIOLATION`).

Lean: `freshIntIO` is a native counter starting at
`CERB_FRESH_BASE = 2^20` (`lean_frontend/native/fresh_int.c`), so that
ambient ids sit strictly above the 0-based desugar-threaded ids
(invariant probed at startup, `Main.lean:1074-1076`). Crucially, two
regions of the model are **already threaded on the Lean target**,
each with an `ocaml` target_rep redirect that keeps the oracle on the
ambient counter (`ocaml_frontend/fork_renumber.ml`):

- **Desugar** (arc-13): `cabs_to_ail_effect.lem:240`
  `fresh_sym_supply` in the `desugM` state; monadic mint
  `fresh_sym_int` (`:627-634`), OCaml redirect
  `Fork_renumber.fresh_sym_int` (`:640`). The two apparent
  `Symbol.fresh* st.symbol_supply` sites (`:1426`, `:1851`) are
  inside comment blocks — dead text.
- **Run-time minting** (arc-2/13): `core_run.lem:108-121`
  `fresh_action_id'`/`fresh_symbol'` mint from the threaded
  `core_run_state` supplies via the pure
  `Symbol.fresh_given_int` (`symbol.lem:262-264`); OCaml redirect
  `Fork_renumber.fresh_symbol'` (`core_run.lem:127`). The run state
  (`core_run_aux.lem:234-254`) carries
  `tid_supply/aid_supply/excluded_supply/sym_supply`.

What remains on the ambient counter — the live Lean-side clients:

**(a) The one seed read.** `core_run_aux.lem:287`:
`sym_supply = Symbol.fresh_int ()` in `initial_core_run_state` ("the
ONE ambient read: everything after init is threaded"). Callers:
`driver.lem:1509-1514` `initial_driver_state` → hand-written
`Main.lean:857`; and `mini_pipeline.lem:151` (the mid-desugar
constant-expression mini-run). Pipeline phase: run-init (and
desugar, via the mini-run).

**(b) The elaboration cone.** `Symbol.fresh*` wrappers
(`symbol.lem:236-273`; each body is
`Symbol (digest()) (fresh_int ()) <descr>`), called from:

- `translation_effect.lem` (phase: elaborate): `:65`
  (`wrapped_fresh_symbol`), `:70` (`wrapped_fresh_symbol_`), `:107`
  (`with_block_objects`, inside a `List.foldl` lambda), `:178`
  (`record_object_types_marker`, bare `Symbol.fresh_int ()`) — all
  in defs returning `elabM` values
  (`elabM 'a = stateM 'a elab_state`, `:41`).
- `translation.lem` (phase: elaborate), 15 live sites: `876` (inside
  a `mapi` lambda: `fresh_funarg`), `1871`, `3305`, `3306`, `3800`,
  `3836`, `3837`, `3838`, `3954` (inside a `list_init` lambda),
  `3955`, `4235`, `4265`, `4354`, `4361`, `4414` (`4412` is a
  comment) — direct `let` positions except the two lambda sites, all
  inside the `elabM` bind structure of `translate_program`. Entry:
  `translation.lem:4524`
  `E.runStateM_errors (translate_program ...) (E.elab_init callconv)`,
  reached from hand-written `Main.lean:555-556` (`translate`).
- `mini_pipeline.lem` (phase: desugar — constant-expression
  evaluation): `evalConstantExpressionAux` (`:86`) runs the
  elaboration monad locally
  (`:133 TranslateEff.runStateM (toCore a_expr) (TranslateEff.elab_init callconv)`;
  `toCore` calls `translate_expression` and two
  `wrapped_fresh_symbol`), builds a driver state (`:151`, draws the
  seed of (a)), and runs the mini driver. Its caller is `desugM`
  monadic code: `cabs_to_ail.lem:1132`
  (`Mini_pipeline.evalIntegerConstantExpression`). So the
  elaboration cone executes **inside desugar** as well.

**(c) Dead code that still generates.** `core_unstruct.lem:260,278`
(`Symbol.fresh` inside `foldl`/`map` lambdas). No importer in the
Lean build (F3); on the OCaml side the module is upstream's
sequentialisation pass, untouched by us.

Order note for (b): in a strict language the fresh draws interleave
with `elabM` execution — a bind chain evaluates its head computation
eagerly but defers continuations, so draws inside continuations fire
when the state monad *runs*. Draw order therefore equals `elabM`
run order. This is why the natural carrier for a threaded supply in
region (b) is the `elab_state` that is already being threaded at
exactly those moments (§3.4).

### 2.3 Which pipeline phases touch the counter (summary)

| Phase | Draws today (Lean) | Threaded already? |
|---|---|---|
| desugar proper | none ambient — `fresh_sym_supply` (0-based, per TU) | yes (arc-13) |
| desugar: const-expr mini-runs | ambient: elaboration draws + one run-seed per mini-run | no |
| AIL typing (`annotate_program`) | none (no fresh sites in GenTyping cone) | n/a |
| elaborate (`translate`) | ambient: all `Symbol.fresh*` draws | no |
| link | none | n/a |
| run init (`initial_driver_state`) | ambient: one seed draw | seed only |
| run (`driver2` steps) | none ambient — `sym_supply/aid_supply/...` | yes (arc-2) |

### 2.4 set_tagDefs / reset_tagDefs: who consumes the global today

The tag-definition *reads* were retired into reader lifting in arc-1
(`ctype_aux.lem:26 declare {lean} reader val tagDefs`; design:
`docs/2026-08-18_effects-totality-design.md`). Writes remained
"execution-only scaffold". Verified current state:

Writers (all hand-written `Main.lean`, mirroring the OCaml driver):
`:553` (per-TU reset, pipeline.ml:253 mirror), `:839-840`
(post-link reset+set, main.ml:284-285 mirror), `:855` (set from
`runFile.tagDefs` before execution). Plus the in-model with-extent
`Ctype_aux.with_tagDefs` used by the mini-run
(`mini_pipeline.lem:77`), whose Lean implementation does the whole
save/set/apply/restore extent in C (`CerbTags.lean:25-40`,
`native/tags.c cerb_tags_with`).

Consumers of the global:

1. **The seed-back reads at the execution entries.** `Main.lean:870`
   `drive (CerbTags.tagDefs ()) false runFile ...` and `:872`
   `RelSem.Cerb.callND (CerbTags.tagDefs ()) runFile fname ...` —
   Main sets the global from `runFile.tagDefs` at `:855` and
   immediately reads it back to seed the reader parameter. This is
   the "load→seed loop" [USER 2026-08-31] decision 2 closes: pass
   `runFile.tagDefs` directly.
2. **The hand-written memory model.** `CerbMem.lean` reads
   `CerbTags.tagDefs ()` at 13 sites — the layout family's
   default-budget wrappers (`:477,483,492,496`), `offsetsof` callers
   (`:650,772`), the union-arm lookups (`:404,463` — a deliberate
   mirror of upstream's asymmetry, see §4.2), and the remaining
   lookup/codec sites. Comment at `Main.lean:852-854`: "CerbMem's
   struct/union layout (sizeof/alignof/offsetsof) reads this global
   during execution."
3. **The mini-run extent.** `run_const_expr_driver`
   (`mini_pipeline.lem:70-78`) is `reader_seed` (its first argument
   `tds` is the injection value for every reader-lifted callee) *and*
   wraps the run in `with_tagDefs tds` so that the hand-written
   memory-model reads (consumer 2) agree with the seed.
4. The generated reader target_rep `CerbTags.tagDefsIO` exists for
   lem's target-coverage check only — "never emitted at applied call
   sites" (`ctype_aux.lem:19-25` comment). Confirmed: no generated
   applied site.

So retiring the writes = closing loop (1) in Main + re-plumbing
consumer (2) + simplifying (3). No backend transform is involved;
§4 specifies the treatment.

### 2.5 CerbDebug: what is actually in the cone

The model's debug output is **already stubbed pure** (arc-1 ruling,
2026-08-18 design note): `debug.lem:27`
`declare lean target_rep function get_level u = 0`; `:40`
`print_debug = CerbDebug.print_debug_pure` (a pure no-op,
`CerbDebug.lean:64`); `ND.print_debug` returns
`Debug.print_debug ...` (`nondeterminism.lem:121-123`) and is
therefore also a no-op on Lean. Generated code references only these
pure forms (widespread, e.g. `generated/AilSyntaxAux.lean:55`
`print_debug_pure` under a constant-0 level test). `printDebugIO`
(`CerbDebug.lean:49`) is referenced by no generated code.

What is effectful today is the *level machinery*: `getLevelIO`/
`setLevelIO` externs over a C global (`CerbDebug.lean:13-17`,
`native/debug.c`), their armoured pure wrappers `get_level`/
`set_level` (`:29-43`), and the single live write —
`Main.lean:1064` setting the level for human-mode Core-run tracing.
The `dbg_trace`-based `CerbDebug.print_debug` (`:56-57`) is the only
reader of the level and is reachable only from hand-written code.

So decision 2's end state is already structurally true of the
generated model (it returns values); the retirement work is deleting
the vestigial level global and moving the driver's verbosity choice
into driver-local state (§5).

## 3. The mechanism: supply lifting

### 3.1 The reader lifting as built (the model for the analog)

Storage: `const_descr` carries `effectful/reader/reader_seed :
Targetset.t` (`lem-lean/src/typed_ast.ml:178-182`);
`declare {targets} reader val f` unions the declared targets into the
field (`src/typecheck.ml:3074-3112`). Backend behavior
(`src/lean_backend.ml`):

- Parameter list: every reader constant contributes one parameter
  `_lemReader_<name> : T` (for `f : unit -> T`), globally sorted
  (`:366-381`).
- Pre-pass (`lean_reader_prepass`, `:383-436`): per-module fixpoint
  at `Val_def` granularity — a def is *lifted* if it uses a reader
  constant or an already-lifted def; the set persists across modules
  in dependency order; `Instance` defs are skipped (fail-closed at
  emission), `reader_seed` defs are never lifted.
- Emission: lifted defs get the reader binders (`:2813-2819`);
  an application `tagDefs ()` is rewritten to the parameter name
  (arity-guarded); a call of a lifted def re-injects the parameters;
  a **bare reference** to a lifted def is repaired by **partial
  application** `(f _lemReader_...)`, and a bare reader reference is
  eta-expanded — both **type-preserving**, which is why a lifted
  function can be passed to `List.map`, stored in a closure, or used
  under a monadic bind with no further ceremony.
- `reader_seed` (`declare {lean} reader_seed val f`): inside `f`'s
  body the injection value is `f`'s own first argument
  (`:256-261`, `reader_inject_name`); cerberus uses it at exactly one
  place, `mini_pipeline.lem:78`.

### 3.2 The supply feature: `declare {lean} supply val`

Specification of the backend feature (the deliverable of the lem
slice). Classic mechanism name: a **state-passing (supply-threading)
transform** — each lifted definition takes the current supply and
returns the next one; a draw is a split of the supply.

**Annotation surface.** `declare {lean} supply val f`, target-scoped
exactly like `reader`. Requirement: `f : unit -> nat` (generation-
time error otherwise). Rationale for not generalizing the supply
element type in v1: the only client is a counter; a general
`next`-function parameter can be added compatibly later. Storage: a
`supply : Targetset.t` field beside `reader` in `const_descr`; new
`Decl_supply` declaration node (grammar rows beside
`src/parser.mly:1025-1033`, `language/lem.ott:836-840`).
Constraint from the 2026-08-31 backend quality review (M1): the
fork's seven annotation words are today globally **reserved
keywords** — a parser regression for all lem users on all targets.
`supply` (and any other word this arc adds) MUST ride the fixed
contextual-keyword mechanism landed in slice L0 (§8.1), never the
current `kw_table` route.

**Implementation constraints** (review-mandated, adopted): model the
feature on the reader-lifting pipeline — the review's verdict is
that it is the best-engineered mechanism in the backend (declare →
typecheck field → `lean_reader_prepass` fixpoint →
`St.reader_lifted` → injection at exactly two emission sites, with
the arity guard). The reader mechanism's stated restrictions apply
**verbatim as this feature's declared restrictions** — no instance
methods, no infix position, seed singularity — and a supply is
strictly harder than a reader (it threads *out* as well as *in*), so
each restriction is a fail-closed guard, not a caveat. No new
process-global `ref`s: all feature state joins the `St` module with
a declared lifetime class; the `on_cr_simple_applied` global hook is
a registered upstreamability debt (review m4) and this arc must not
add to that class. Precondition from review m7: the
tuple-destructuring `Let_def` path duplicates its RHS per bound name
(`lean_backend.ml:2078-2126`) — a duplicated supply draw there would
be a **silent numbering fork**; m7 is fixed in L0 before any supply
threading touches `Let_def`.

**Lifted set.** The same fixpoint as `lean_reader_prepass`, sharing
its traversal (a def is lifted if it uses a supply constant or a
lifted def; `Val_def` granularity; instances skipped fail-closed).

**Signature transform** (the delta from reader — this is where the
state analog stops being a copy):

- extra explicit binder `(_lemSupply_<name> : Nat)` emitted *after*
  the reader binders (fixed order: `[Inhabited]` binders, reader
  binders, supply binder — mirrors `:2288-2291`);
- **the result type changes**: a lifted `f : α → τ` emits as
  `f : Nat → α → τ × Nat`. Reader lifting never changes result
  types; supply lifting must (linear threading).

**Body transform.** A-normalization at supply-relevant positions,
sequenced in **left-to-right depth-first order** — i.e. exactly the
evaluation order of the strict Lean code being replaced (this is the
local half of the order-preservation argument, obligation O1 in
§3.5). Per-form rules: a draw `fresh_int ()` becomes
`let (n, s') := LemLib.supplySplit s` (`supplySplit s = (s, s+1)`, a
LemLib def — greppable, kernel-transparent); a call of a lifted def
binds `let (x, s') := f s a b`; `let`/`match`/`if` thread the supply
through scrutinee-then-arms with each arm returning the pair;
constructor/tuple arguments are hoisted into `let`s in argument
order.

**Fail-closed guards**, each a generation-time error naming the site
and the escape hatches (the reader machinery's guard style,
`:2951-2955` arity guard, instance guard):

- G-λ: a supply draw or lifted-def use **under a lambda** — linear
  state cannot be captured; there is no partial-application repair
  (contrast §3.1). This guard is the honest boundary of the feature
  (§3.3).
- G-bare: a **bare (unapplied) reference** to a lifted def — same
  reason.
- G-inst: inside an `Instance` method (methods cannot take extra
  binders — as reader).
- G-rel: inside `Indreln`/lemma contexts (as reader).
- G-arity: the supply constant applied to anything but one unit
  argument (as reader).
- G-infix: a lifted constant used in infix position (the reader/fuel
  restriction, review-confirmed, applies verbatim).

**Seeding.** Hand-written entry points pass the initial value and
receive the final value in the returned pair — the supply analog of
Main passing `(CerbTags.tagDefs ())` at `Main.lean:870`. A
`declare {lean} supply_seed val` analog of `reader_seed` is
*specifiable* but **not built** in v1: the census (§2.2) shows no
in-model injection point that needs it under the §3.4 split
(fail-closed minimalism; add it when a client exists).

**Composition with reader.** Independent: binder order fixed as
above; call-site injection composes (a def both reader-lifted and
supply-lifted re-injects readers and threads the supply). A
`tests/comprehensive` case must cover the combination, plus fuel
(`fuel` workers already re-inject reader binders on self-calls,
`:3034-3040`; the supply must thread through the decremented
self-call the same way).

**Composition with `effectful`.** None: by end state the `effectful`
declaration class is deleted (§7.1). Transitionally (during the
adoption slice) a val must not carry both — generation-time error.

### 3.3 The reach of the transform, stated honestly (finding F1)

Reader lifting extends through arbitrary higher-order code because
environment-passing is type-preserving: a lifted `f` used as a value
is repaired to `(f env)`, whose type is the original one. Supply
lifting is **linear**: a lifted `f`'s type necessarily grows a
`× Nat` in its result, so a lambda whose body draws, or a lifted def
passed to a higher-order function (`List.map`, `foldl`, a monadic
`>>=`), cannot be threaded without changing the receiving function's
type too. Chasing that type change through the program is precisely
the call-by-value monadic (state) translation — a wholesale rewrite
of the generated code's shape, not a lifting.

Consequence for this census: **every live path to `fresh_int`
crosses such a boundary.**

- The elaboration cone (§2.2 b) draws inside `elabM` bind
  continuations throughout `translation.lem`, plus three literal
  HOF-lambda sites (`translation.lem:876,3954`,
  `translation_effect.lem:107`).
- The constant-expression seam (§2.2 b, mini_pipeline) is invoked
  from `desugM` monadic code (`cabs_to_ail.lem:1132`), and
  `evalConstantExpressionAux`'s own supply-consuming region sits
  under `Eff.exceptM` bind continuations
  (`mini_pipeline.lem:127-133`).
- Even the single seed read (§2.2 a) is reachable from the desugar
  monad via the mini-run.

So the ratified route — backend supply-lifting alone, zero model
delta — cannot retire the axiom. G-λ would fire on essentially every
bind in `translation.lem`. This is not an implementation gap in the
feature; it is the standard reader/state asymmetry.

Alternatives considered for closing the gap in the backend, and
rejected [AGENT]:

- **Monadification** (full state-monad translation of the lifted
  cone, or a "declared-monad absorption" variant where the model
  declares its monads' bind/return so the transform can splice a
  state transformer through them): rejected — output shape diverges
  massively from the OCaml (violates aim 2), the transform's
  subtlety defeats aims 3 and 4, and its blast radius inside
  `lean_backend.ml` dwarfs the problem.
- **Splittable supply** (UniqSupply-style: closures capture a split
  half; reader-shaped, so the cheap transform survives): rejected —
  ids' relative order diverges from the sequential counter; symbol
  order is observable downstream (symbol-keyed `Fmap` iteration,
  label machinery), so the differential-identity argument is
  forfeited. Also rejected in the arc-1 ruling
  (`2026-08-18_effects-totality-design.md` §7c) on the same ground.
- **Leaving the monadic region on `runEffectful`**: fails §1.3.

### 3.4 The proposed division of labor ([AGENT] recommendation; §9 Q1)

The arc-1 ruling anticipated this: "an explicit CONSUMED
stream/counter input — i.e. state threading, not reader ...
threading through the desugar/translation monads the model already
has" (§7c, [USER 2026-08-18] ruled direction). The fork has executed
that pattern twice — desugar (arc-13) and run-time minting (arc-2/13)
— each time as: *supply as a field of the already-threaded state,
monadic mint in the model, `ocaml` target_rep redirect keeping the
oracle on the ambient counter, oracle output preserved and gated*.
TODO.md's standing entry describes the same end state ("the
fresh-symbol supply threaded through the machine state").

Proposal — the lem feature carries the first-order region; exactly
three bounded model accommodations carry the supply across the
monadic boundaries, on the in-tree precedent:

**(a) Backend feature (zero model delta).** `declare {lean} supply
val fresh_int` replaces `symbol.lem:230-231` (the Lean target_rep and
the effectful declare). Auto-lifted, first-order, by the fixpoint:
the `Symbol.fresh*` family (bodies are direct-style;
`fresh_pretty_with_id`'s `let id = fresh_int () in ...` sequences
trivially), `initial_core_run_state` (draw in a record field —
direct), `initial_driver_state` (direct call), and the direct spine
of `mini_pipeline.evalConstantExpressionAux` up to its `Eff` binds.
Generated signatures: e.g.
`Symbol.fresh : Nat → Unit → sym × Nat`,
`initial_driver_state : Nat → file' → fs_state → driver_state × Nat`.
Hand-written `Main.lean:857` passes and receives the supply
explicitly.

**(b) Model accommodation m1 — the elaboration monad.** `elab_state`
(`translation_effect.lem:24-40`) gains a `fresh_supply : nat` field;
`elab_init` takes its seed; monadic mints
(`fresh_elab_sym : symbol_description -> elabM sym`, plus a bare
`fresh_elab_int : elabM nat` for `record_object_types_marker`) are
added, built from the **pure** `Symbol.fresh_given_int`
(`symbol.lem:262`) exactly as `core_run.lem:115-121` does today, with
`declare ocaml target_rep` redirects to `Fork_renumber` variants that
draw ambiently — so the oracle's dynamic draw sequence is unchanged.
The 19 live sites migrate (15 in `translation.lem`, 4 in
`translation_effect.lem`): direct `let sym = Symbol.fresh* ...`
becomes a bind on the mint; the two lambda sites become the monadic
map (`876`: `mapi`-lambda → `mapM` over the indexed list; `3954`:
`list_init` → a threaded build), and `translation_effect.lem:107`'s
`foldl` threads the supply through its accumulator — each with a
per-site OCaml draw-order argument (list order preserved; see O2).
`translate`'s entry (`translation.lem:4524`) seeds `elab_init` from
the supply parameter that the (a)-lifted signature hands it.

**(c) Model accommodation m2 — the const-expr seam.**
`evalConstantExpression`/`evalConstantExpressionAux` carry the supply
explicitly (`Eff.exceptM (value * nat)` through the few `Eff` binds
on the path, `mini_pipeline.lem:127-180`), seeding the local
`elab_init` and the mini-run's `initial_driver_state` and returning
the final value. The `desugM` caller (`cabs_to_ail.lem:1132`) draws
the supply from and restores it to the desugar state via
`modify_inner` — which requires the desugar state's supply and the
ambient supply to be **one stream** (next paragraph), or a second
`desugM` field.

**(d) The stream-unification decision** (§9 Q2). Option S1 (single
stream, recommended): the Lean pipeline threads ONE supply — Main
seeds it once, desugar's existing `fresh_sym_supply` becomes that
stream, const-expr mini-runs and elaboration and the run-init seed
all draw from and return to it. This is exactly the invariant arc-13
restored for the oracle ("one supply, every id a distinct draw —
collisions impossible by construction"), now on the Lean side;
`CERB_FRESH_BASE`, the 2^20 stratification, the startup floor probe
(`Main.lean:1074-1076`) and `native/fresh_int.c` all become
deletable. Cost: Lean-side ids shift relative to today (obligation
O3 — ids are compared only for equality within a run and the
differentials are id-canonicalized, `Main.lean:1071-1073`, but the
claim "no observable output depends on the old stratification" must
be earned by the full battery, and any baseline movement is a
finding). Option S2 (two streams, conservative): keep desugar
0-based per TU; `desugM` gains a second field for the ambient stream
seeded at 2^20; numbering is byte-identical to today by
construction; cost: the stratification invariant survives as a
proof obligation on the seeding instead of dying, and two supplies
thread where one would do.

**(e) Core_unstruct**: drop from the Lean generation/build lists
(`Makefile` module list, `lakefile.toml:51`) — it is Lean-dead (F3);
the `.lem` file and the OCaml output are untouched. Recorded as a
build-config change, not a model change. (Alternative if the
operator prefers the module kept buildable: restructure its two
folds target-neutrally; not recommended — dead-code surgery.)

Model-delta budget of the whole proposal: 2 declare-line swaps
(`symbol.lem`), ~25 mechanical site edits + 1 state field + 2 mint
helpers + redirect declares (m1), ~1 seam signature + call-site wrap
(m2), 0 edits for (e). Every hunk lands in the fork-drift manifest
with its OCaml-side justification (§6.4).

### 3.5 Call-order preservation: the proof obligations for the lanes

Stated as obligations the validation battery must discharge, not as
assumptions. Headline form (2026-08-31 backend quality review,
deletion-readiness item b): **the threaded supply must reproduce the
ambient counter's dynamic call sequence — symbol numbers are
observable via printing and map ordering — explicitly including the
one-shot seed draw at `generated/Core_run_aux.lean:395`.** One
clarification against the in-tree record, flagged rather than
silently adopted: read literally ("the OCaml counter's" sequence),
that bar is stronger than the state the lanes validate today — since
arc-13 scheme R-B, Lean-side desugar ids are deliberately 0-based
per TU while the oracle draws ambiently
(`cabs_to_ail_effect.lem:240` comment, `native/fresh_int.c`), and
the differentials are id-canonicalized (`Main.lean:1071-1073`). The
precise obligation is therefore two-sided: the oracle's dynamic draw
sequence is preserved exactly (O2), and the Lean side reproduces its
own current validated dynamic sequence — the OCaml counter's
*semantics* (sequential distinct draws in call order), not its
values (O1, O3).

- **O1 (transform-local).** The feature's A-normal sequencing emits
  draws in the evaluation order of the pre-transform generated code
  (left-to-right, depth-first, strict). Checked structurally by the
  transform rule + a `tests/comprehensive` case whose draw order is
  pinned in the Lean-side expected output; checked end-to-end by
  byte-identity of the full differential battery.
- **O2 (m1/m2 migrations, oracle side).** Each migrated site's OCaml
  redirect draws ambiently at the same dynamic point as the code it
  replaces (per-site argument; the lambda→monadic-map rewrites
  preserve list order). Discharged by: regenerated-OCaml diff review
  (§6.4), the arc-13 single-supply backstop (`check_ail_window` —
  any re-threading of the oracle refuses loudly, exit 70), fixture
  provenance pins (`test_verify.sh` oracle re-derivation
  byte-equality), and the full battery.
- **O3 (Lean-side renumbering, iff S1).** No observable output
  depends on the retired 2^20 stratification or on today's exact id
  values. Discharged only by the FULL battery including Tier B
  (libxml2, tests/ci) and the Tier C reporting instruments (csmith
  full pass, ci sweep) — any baseline movement fails closed and is
  a finding, not a re-pin.
- **O4 (mini-run seed adequacy).** Ids minted inside a
  constant-expression mini-run are distinct from every id reachable
  in that run's state. Under S1: by construction (single stream).
  Under S2: requires the explicit argument that the mini-run's
  arena/state contain only sub-2^20 desugar ids and name-hash-
  interned std ids (the current invariant, `native/fresh_int.c`
  comment), re-proved for the threaded seeding.
- **O5 (per-TU digest interplay).** Draw values combine with
  `digest()` in `Symbol.fresh*`; the digest machinery is untouched
  (§1.3), and the existing `forceIO` sequencing barriers in Main
  (`Main.lean:496`, `:524`, `:555`) keep their roles. No new
  obligation, recorded to bound the change.

## 4. tagDefs: closing the load→seed loop

### 4.1 Writes and the entry seeds

End state: the linked table is passed as a value; the global dies.

- `Main.lean:870/872`: `drive runFile.tagDefs ...` /
  `RelSem.Cerb.callND runFile.tagDefs ...` (the reader parameters are
  already explicit leading arguments; only the seed expression
  changes from the global read to the value in hand).
- Delete the write sites `Main.lean:553`, `:839-840`, `:855`
  (their OCaml mirrors — pipeline.ml:253, main.ml:284-285 — are
  driver-level bookkeeping for the very global being deleted; the
  divergence is documented in-code per the mirror doctrine).
- Delete `CerbTags.setTagDefsIO`/`resetTagDefsIO`/`tagDefsIO`
  externs, the armoured pure wrappers, and `native/tags.c`; drop the
  `set_tagDefs`/`reset_tagDefs`/`tagDefs` vals' Lean target_reps and
  the two `effectful` declares plus the `reader` declare's val
  `tagDefs` itself **if** no lifted consumer remains — the reader
  parameters stay (they are the mechanism), but the backing val
  loses its extern rep and becomes rep-less/unused on Lean; the
  precise residue is settled at implementation time by the
  target-coverage checker, fail-closed.
- `with_tagDefs`: with no global to save/restore, the C whole-extent
  (`cerb_tags_with`) is purposeless; `run_const_expr_driver` keeps
  only its `reader_seed` role (the seed IS the value). The
  `with_tagDefs` opaque + witness machinery (`CerbTags.lean:73-97`)
  is deleted; the gate's boundary-opaque expectation list shrinks
  (§7.2).

### 4.2 The memory model (the real remaining consumer)

`CerbMem`'s 13 global reads must become parameter passing. The
generated execution slice is already reader-lifted
(`_lemReader_tagDefs` in scope throughout `Core_run`, `Driver`,
`Defacto_memory*`, etc. — 160 occurrences), but the mem-ops are
`target_rep`'d vals (`mem.lem:80-125`) whose bodies lem cannot see,
so the reader fixpoint never marks them and their call sites never
pass the parameter. Proposed mechanism ([AGENT]; the natural
completion of the reader feature, upstream-clean):
**`declare {lean} reader_consumer val f`** — declares a
target_rep'd val to be a reader consumer: its generated call sites
pass the reader parameters as extra leading arguments (callers get
lifted by the ordinary fixpoint), and the hand-written implementation
takes them explicitly. Applied to the mem.lem vals whose CerbMem
implementations read the global today (enumerated from the 13 sites
at implementation time: the load/store/allocate family and the
`sizeof/alignof/offsetof` ival entries). CerbMem's default-budget
wrappers then take `tagDefs` as an argument and the 13 reads become
parameter uses. The mini-run works unchanged: `run_const_expr_driver`
seeds the lifted callees with `tds`, which now flows to the mem-op
call sites (this *replaces* the with-extent global set, and closes it
correctly rather than ambiently).

**The union-arm mirror caveat** (found in this census; must be
preserved deliberately): upstream's `sizeof`/`alignof` union arms
read the GLOBAL even though the rest of the layout family threads
`~tagDefs` (impl_mem.ml:173, :255), so elaboration-time `offsetof`
over a union-containing struct crashes upstream — mirrored today by
CerbMem reading the (empty-at-elaboration) global and panicking
(`CerbMem.lean:260-267`, pinned crash pair
`tests/immaculate/nolibc/offsetof-union-member.c`). Post-retirement,
the value reaching those arms must remain *phase-appropriate*: empty
during desugar/typing/elaboration entries, the linked table at run
time. Elaboration-time entries into the layout family thread their
maps explicitly already and do not pass through the reader (the
`translate` entry takes no reader argument — `Main.lean:556`), so
the parameter feeding the union arms at elaboration time must be
seeded empty, keeping the pinned pair green. This is a named
regression witness for the implementation slice, not a redesign.

## 5. CerbDebug: out of the cone

Per [USER 2026-08-31] decision 2 and the §2.5 census:

- Delete `getLevelIO`/`setLevelIO`, the armoured `get_level`/
  `set_level` wrappers, `printDebugIO`, the `dbg_trace`-based
  `print_debug`, and `native/debug.c`. `Makefile:343` `LEAN_NATIVE`
  loses `debug` (and, per §3.4/§4, `fresh_int` and `tags`; `md5`
  stays — the digest boundary remains).
- `debug.lem`'s Lean reps stay value-shaped as they are
  (`get_level u = 0`, `print_debug → print_debug_pure`, warn/
  output_string no-ops): the generated model keeps returning values;
  nothing prints inside the semantics.
- The driver's verbosity (`Main.lean:1064` and the human-mode
  tracing it enabled) becomes ordinary driver-local state in Main
  (an `IO`-side value passed to Main's own printing, never entering
  generated code). If Core-step tracing at level>0 is wanted later,
  it is a driver feature over returned values (the `--trace-nodes`
  pattern, `Main.lean:877-887`), not a model effect.
- `CerbDebug.lean` shrinks to the pure stubs consumed by generated
  code; its copy in `generated/` follows via the sync gate.

## 6. Blast radius, by the four aims

### 6.1 Aim 1 — minimal blast radius for non-Lean lem users

The annotation is target-scoped by construction: `declare {lean}
supply val` stores `Target_lean` in a `Targetset` on the constant
(`typecheck.ml:3074-3112` pattern); grep evidence that only the Lean
backend consults these fields: writers in `src/typecheck.ml`, readers
in `src/lean_backend.ml`, nothing else (`grep -rln '\.effectful\|\.reader\b\|\.reader_seed' src/*.ml`).
Non-Lean emitters handle `Declaration` nodes through generic
fall-throughs (`src/backend.ml:3179`) and never change their output.
The OCaml/HOL/Coq/tex outputs for a model carrying the new declare
are byte-identical to before — assertable in lem's own test suite
(§6.3). The grammar addition (parser.mly + lem.ott) is additive.

### 6.2 Aim 2 — obviously right output for Lean

The transform is small, first-order, and fail-closed: five guards
(§3.2) with named errors; no silent fallback; the emitted code is
ordinary `let`-sequenced pure Lean whose shape matches the source.
The house rules that make wrongness loud stay in force: the lem-sync
content-hash gate, the sync gate, and O1's pinned-order test.

### 6.3 Aim 3/4 — clean design, reviewable, upstreamable

Feature checklist for the lem slice (mirrors what reader/fuel
already have):

- `tests/comprehensive/test_supply.lem` (+ expected Lean check file):
  draws in every syntactic position the transform sequences;
  reader+supply composition; fuel+supply composition; multi-supply
  ordering.
- A **compiled-code behavioral-equivalence test**, not just
  elaborator asserts: the review's coverage findings are that the
  suite's 586 asserts all evaluate in the elaborator, `effectful` is
  tested one declaration deep, and the CSE/extraction armor has no
  compiled-code test at all. The equivalence claim of this arc —
  threaded supply ≡ counter — must be pinned by a compiled binary
  (the panic-pin pattern) that draws through a lifted chain and
  asserts the exact id sequence, run before (against the effectful
  scaffold) and after (against the threaded code) the swap.
- `tests/comprehensive/negative/`: one reproducer per guard
  (G-λ, G-bare, G-inst, G-rel, G-arity) asserting the generation-time
  error text — these double as the feature's plants.
- A non-Lean-output invariance test: a model with the declare,
  OCaml/HOL outputs asserted byte-identical to the undeclared
  variant.
- Documentation: `doc/lean-backend/DESIGN.md` section (replacing the
  "one axiom, by design" paragraph at end state), lem manual entry
  beside the reader declare.
- No cerberus entanglement: names, tests, and docs speak of supplies
  and counters, not symbols; `reader_consumer` (§4.2) is specified
  the same way.
- St-module discipline: any new backend state joins `St` with a
  lifetime class (`lean_backend.ml:152-310`).

### 6.4 OCaml-output invariance, gated

Two layers, both existing instruments:

- **Lem bump alone** (feature lands, model untouched): regenerate
  `prelude-src` before/after the pin bump; the generated-OCaml tree
  must be byte-identical (certification rule: cache-disabled,
  re-derived trees). Any diff is a fail.
- **Model accommodations m1/m2** (cerberus slice): the generated-
  OCaml diff is nonempty by design; every hunk maps to a
  `scripts/fork_drift_manifest.txt` entry with its redirect
  (`check_fork_drift.sh` re-pins the layer-2 hashes on review), the
  oracle's dynamic behavior is asserted unchanged by O2's
  instruments, and the arc-13 backstop keeps guarding the desugar
  seam thereafter.

## 7. What gets deleted, and the gate ratchet

### 7.1 Deletions at end state

lem-lean:

- `LemLib.lean:31-60`: `runEffectful_impl`, the `runEffectful` axiom,
  its `implemented_by`/`never_extract` attributes, and the scaffold
  commentary (a HISTORY note remains, per the DAEMON precedent at
  `LemLib.lean:20-29`).
- The `effectful` declaration class end-to-end: grammar
  (`parser.mly:1025`, `lem.ott:836`), `Decl_effectful` AST/typecheck
  plumbing, the `const_descr.effectful` field, and — per the review's
  deletion-completeness item (a), so no dead armor lingers — BOTH the
  call-site wrap emission (`lean_backend.ml:2903-2904`,
  `:2986-2990`) AND the full `exp_contains_effectful` attribute
  machinery (`:1539-1554`, `:2088-2090`, `:2229-2235`, and the
  wrapper-attribute carry at `:2474`). Reintroducing
  `declare {lean} effectful` is thereafter a **parse error** — the
  loudest possible plant (§7.3 P1).

cerberus-lean:

- The three annotation lines and `fresh_int`'s Lean target_rep;
  `CerberusFresh.freshIntIO` + `native/fresh_int.c` + the
  `Main.lean:1074-1076` floor probe; `CerbTags` IO externs +
  `native/tags.c` + the `with_tagDefs` opaque machinery; the
  CerbDebug level machinery + `native/debug.c` (§5);
  `Makefile:343 LEAN_NATIVE` shrinks to `md5`.
- The `@[never_extract, noinline]` armour that existed only for the
  effectful/CSE hazard class disappears from generated defs
  automatically (the emitter is deleted) and is *removed
  deliberately* from the hand-written wrappers it protected —
  EXCEPT the digest boundary (`CerberusFresh.digest`/`forceIO`
  armour stays verbatim: that global remains, §1.3). The
  effect-erasure invariant page
  (`docs/2026-08-22_arc14-effect-erasure-invariant.md`) gets a
  scope-shrink addendum rather than deletion (the invariant still
  governs the digest seam).
- `test/Unit/FreshIntTest.lean` is rewritten: the runEffectful
  distinctness probes die with the mechanism; threading laws
  (supply monotonicity/distinctness through a lifted chain) and the
  surviving digest-barrier tests replace them.

### 7.2 The gate ratchet (`check_theorem_axioms.sh` and friends)

- **New leg, LemLib census**: zero `^axiom` declarations across
  `.lake/packages/LemLib/lean-lib/*.lean` (same comment-stripping
  scanner as the generated-tree census; fail-closed on a missing
  package dir).
- **Exec-entry exact census**: the `#print axioms` probes (today:
  exemplars + `driver2`, sorryAx/DAEMON/ofReduce-free,
  `check_theorem_axioms.sh:225-319`) are extended to the full §1.3
  entry set and tightened from ban-lists to an **exact allowlist**:
  every reported axiom must be one of
  `propext, Classical.choice, Quot.sound`; anything else fails with
  the constant named. This is the customer-contract gate.
- **Grep-ban**: `runEffectful` banned outright in `generated/`,
  hand-written `.lean`, and the LemLib copy; `unsafeBaseIO`
  allowlisted at exactly the named digest-boundary impls
  (`CerberusFresh.digest_impl`) — any other occurrence fails.
  `check_exec_purity.sh`'s boundary-honesty header updates to the
  shrunk seam list.
- Boundary-opaque expectation list shrinks: `with_tagDefs` leaves
  (deleted); `forceIO` stays exactly-once.

### 7.3 Plants (each run red-green at the ratchet slice)

- **P1**: add `declare {lean} effectful val x` to a scratch `.lem` —
  lem must refuse (parse error). Wired as a lem
  `tests/comprehensive/negative` case so it is re-asserted forever.
- **P2**: add a scratch `axiom` to a generated file — the existing
  generated-tree census leg goes red (re-run of the standing plant).
- **P3**: add an `axiom` to the LemLib copy — the new LemLib leg
  goes red.
- **P4**: introduce a lambda-captured draw in the lem suite's supply
  test — G-λ generation-time error (the negative test IS the plant).
- **P5**: hand-edit one exec entry to depend on a scratch axiom —
  the exact-census leg goes red naming it (vacuity check for the
  allowlist tightening).

## 8. Arc structure, gates, pairing, risks

### 8.1 Slices

Two-repo pin dance (same-name branch pair), deletion strictly last —
`runEffectful` must still exist while cerberus adopts, so the lem arc
lands in two phases:

- **S0 (cerberus, measurement, docs-only build probes).** `#print
  axioms` census of the §1.3 entry set as-is (which entries carry
  `runEffectful` today — expectation in §1.3, measured not assumed);
  re-verify this note's site census against the rebased tree.
- **L0 (lem-lean, "fix first" preamble — review-mandated, ordered).**
  Lands BEFORE the supply feature, per the 2026-08-31 backend
  quality review's advice-for-the-arc section:
  (i) **M1 contextual-keyword fix** — the seven fork annotation
  words (`fuel`/`reader`/`effectful`/`ground_rep`/`reader_seed`/
  `skip_instances`/`extra_import`) are globally reserved and break
  identifiers for ALL targets; fix the grammar mechanism so
  annotation words are contextual, and `supply` rides the fixed
  mechanism from birth;
  (ii) **m2 non-Lean regression net** — the golden-hash target over
  the 9 non-Lean targets, in the same slice, so the L0/L1 grammar
  work is structurally guarded rather than sweep-luck;
  (iii) **clause-grouping unification** — the duplicated grouping
  (cref-keyed pre-pass `lean_backend.ml:1129-1138` vs name-string
  emission `:2140-2148`) is unified into one shared cref-keyed
  function BEFORE the supply pre-pass adds what would otherwise be a
  third divergent traversal;
  (iv) **m7 tuple-let RHS duplication fix** (`:2078-2126`) — a
  duplicated supply draw is a silent numbering fork; fixed (single
  private def + projections, or fail-closed on threaded RHS) before
  supply threading exists.
  Gate: lem suite + the new non-Lean golden hashes + the §6.4
  byte-identity probe.
- **L1 (lem-lean).** The supply feature (§3.2) + `reader_consumer`
  (§4.2, if ratified — §9 Q3) + the fuel-budget feature (its own
  design note, §8.3) + full test/doc battery (§6.3). `runEffectful`
  and `effectful` remain. Gate: lem suite + lean-lib build + the
  §6.4 byte-identity probe against cerberus @ S0.
- **C1 (cerberus adoption).** Pin bump to L1; `symbol.lem` declare
  swap; m1/m2 migrations (+ S1/S2 stream decision as ratified);
  Core_unstruct build-list drop; Main threading; tagDefs loop
  closure + CerbMem re-plumb + union-arm seeding (§4); CerbDebug
  cleanup (§5). Gate: FULL battery (Tier A+B, test_verify, speclab,
  Tier C reporting for O3), fork-drift manifest review, O1-O5
  discharged and recorded.
- **L2 (lem-lean, deletion).** §7.1 lem-side deletions (axiom +
  effectful class); DESIGN.md rewrite. Gate: lem suite (now with
  P1) + lean-lib.
- **C2 (cerberus, ratchet).** Pin bump to L2; §7.1 cerberus-side
  deletions; §7.2 ratchet + §7.3 plants red-green. Gate: full
  battery + the new legs. Arc closes when branch heads = opam pin =
  Lake pin (both repos), per the standing dance; merges ff-only on
  explicit per-merge sign-off; pre-merge audit ASK is unconditional.

### 8.2 Gate battery per boundary

Every slice boundary: Tier A fast ladder + the gates named in that
slice's row above; C1/C2 additionally Tier B and the certification
rules (cache-disabled validation from re-derived trees; the OCaml
regen byte-compare of §6.4). Worker commits only on green gates, one
coherent commit per slice; orchestrator re-verifies independently.

### 8.3 The fuel-budget pairing

Per [USER 2026-08-31] decision 3, the same lem arc carries
per-declaration fuel budgets (motivation: the step-runner ceiling is
the `lemDefaultFuel` budget of `drive_nonmemory_steps_aux2` —
`docs/2026-08-31_stack-ceiling-design.md`; TODO.md row 1). That
feature gets its **own design note before L1 is briefed**; this
note's only constraints on it: it rides L1 (one pin bump, one
review), its tests join the same suite, and it must not interact
with supply lifting beyond the composition case already covered
(§3.2: fuel self-calls thread the supply like they re-inject
readers). The review additionally locates the attachment point
(budget = one `Targetmap` field beside `fuel_sentinel`, replacing
the hardcoded `lemDefaultFuel` at `lean_backend.ml:2504`) and
mandates adding `lemDefaultFuel` + the budget binder to the
reserved-name contract — inputs for that note, recorded here so the
pairing brief is complete. Also riding the same lem arc as a
separate S-priced fix (review M2, not this note's scope):
`integerDiv` maps to `Int.ediv` where the OCaml oracle truncates
(`Z.div`) — live sites `generated/Defacto_memory_aux.lean:150,
166-193` are masked only by unproven operand nonnegativity; the
remedy (`Int.tdiv` + instance audit) is mirror-doctrine work that
must not be tangled into the supply slices' diffs.

### 8.4 Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | Call-order divergence (transform or migration reorders draws) | O1/O2 structural rules + pinned-order lem test + full battery byte-identity; oracle side additionally `check_ail_window` (refuses loudly) |
| R2 | Lean-side renumbering shift (S1) surfaces an iteration-order-observable | O3: full battery incl. Tier B/C before any claim; baselines fail closed in both directions; fallback = S2 (two streams) is a contained retreat, decided by measurement not re-design |
| R3 | Reader/supply composition bug (binder order, double injection) | fixed binder order in the spec; dedicated composition test; the exec slice exercises it for real in the mini-run (reader_seed + supply) |
| R4 | Instance-method gap (the old `lean_backend.ml:1546-1548` limitation: attributes can't be emitted on instance fields, so effectful calls in instance methods were only one-level protected) | post-retirement the hazard class is deleted with the mechanism — there is nothing to protect; verified: no effectful call site sits in a generated instance method today (all 9 applied sites are in plain `Val_def`s); G-inst keeps the supply analog fail-closed rather than silently under-protected |
| R5 | Union-arm mirror regression (tags) | §4.2 named witness: the pinned `offsetof-union-member` crash pair must stay green; phase-appropriate seeding specified before code |
| R6 | Mid-arc window where lem has the feature and cerberus still uses `effectful` | legal by construction (L1 deletes nothing); the transitional both-annotations error (§3.2) prevents mixing on one val |
| R7 | Grind risk: m1 is ~25 mechanical edits with a full battery per boundary | slice budget per the grind ban; the battery runs are differential-corpus measurement (the sanctioned category), builds stay capped via `scripts/capped` |

## 9. Open questions for the operator

Genuinely open — each blocks a slice from being briefed:

- **Q1 (blocks L1/C1 scope).** Finding F1: the ratified backend-only
  route cannot reach through the `desugM`/`elabM` boundaries
  (§3.3). Ratify (or amend) the §3.4 split: lem supply feature for
  the first-order region + the three bounded model accommodations
  (m1, m2, and the `symbol.lem` declare swap) on the arc-13
  redirect precedent — or direct an alternative (the rejected
  options are recorded in §3.3 with reasons).
- **Q2 (blocks C1 design).** Stream unification: S1 (single threaded
  supply, structural collision-impossibility, deletes the 2^20
  machinery, accepts the O3 renumbering measurement) vs S2 (two
  streams, byte-stable numbering, keeps a stratification
  obligation). §3.4 (d); [AGENT] recommends S1.
- **Q3 (blocks L1 scope).** Include `reader_consumer` (§4.2) in the
  same lem arc? It is the enabling mechanism proposed for the
  CerbMem global's retirement; the alternative (model-visible
  tagDefs parameters on the mem.lem vals) touches shared signatures
  far more broadly. [AGENT] recommends inclusion.
- **Q4 (blocks the arc's success criterion; raised by the
  2026-08-31 backend quality review, deletion-readiness item c).**
  The arc's bar: **"axiom gone"** or **"no impure pure-signature
  constants"**? Beyond `runEffectful` there is a family of
  pure-signature externs in the same hazard class that do NOT thread
  like a counter: `CerberusFresh.digest` (per-TU value; would thread
  as a reader-per-TU, not a supply), the CerbTags surface (retired
  by §4 in this arc anyway), `CerbGlobal` (runtime configuration:
  execution mode, switches — reader-shaped, read-only after startup,
  uncensused here), and kin. Option A ("axiom gone", this note's
  §1.3 contract): the census target is the axiom and the effectful
  machinery; the surviving externs are kernel-checked opaques on the
  declared `implemented_by` boundary — exactly what the customer
  contract requires, and each survivor is enumerable in the ratchet.
  Option B ("no impure pure-signature constants"): additionally
  threads digest and audits/threads CerbGlobal — larger, reader-
  shaped rather than supply-shaped, and not needed for the axiom
  census. [AGENT] recommends Option A for this arc, with the
  survivors named in the §7.2 ratchet's allowlist (so Option B, if
  ever wanted, starts from an enumerated boundary), and the digest
  threading recorded as a possible later arc (§1.3 adjacency note).
  The ruling is the operator's.

(Not operator questions, carried as [AGENT] recommendations subject
to the adversarial review: Core_unstruct build-list drop (§3.4 e);
the union-arm phase-appropriate seeding (§4.2); the FreshIntTest
rewrite (§7.1).)

## 10. Cross-references

- The axiom and its scaffold: `lem-lean/lean-lib/LemLib.lean:31-60`;
  temporal-boundary declarations: lem-lean
  `doc/lean-backend/DESIGN.md` (effect-boundary paragraph),
  `lean_frontend/CLAUDE.md` (Status), `lean_frontend/TODO.md`.
- Reader lifting design + the §7c state-threading ruling:
  `docs/2026-08-18_effects-totality-design.md`.
- The renumbering precedent (scheme R-B) and the oracle backstop:
  `docs/2026-08-22_arc13-s0-scheme-decision.md`,
  `util/cerb_fresh.ml`.
- Effect-erasure invariant (stays, scope-shrunk):
  `docs/2026-08-22_arc14-effect-erasure-invariant.md`.
- Gates: `scripts/check_theorem_axioms.sh`,
  `scripts/check_exec_purity.sh`, `lean_frontend/VALIDATION.md`,
  `scripts/LADDER.md`.
- Fuel-budget companion (pending its own note):
  `docs/2026-08-31_stack-ceiling-design.md`.
- The 2026-08-31 backend quality review (L0 mandates, feature
  constraints, deletion completeness, Q4): lem-lean
  `doc/lean-backend/2026-08-31_backend-quality-review.md`.
