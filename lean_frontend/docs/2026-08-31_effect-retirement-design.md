# Effect retirement: deleting `runEffectful` from the semantics (design note)

Date: 2026-08-31. Branch `arc/effect-retirement` (base: mainline
`58ec50779`). Status: SETTLED CHARTER (R3 — pending its fresh
pre-C1 review) — the fresh adversarial
review returned RATIFY-WITH-AMENDMENTS (applied in R1), the consumer
review returned RATIFY (absorbed in R2, §10 pointer), and all five
operator questions are CLOSED with [USER 2026-08-31] rulings (§9,
now the decision log). This document governs the combined
lem-lean/cerberus-lean implementation arc. §1 is written to be
consumable standalone by the refined-cerberus project.

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

Revision R1 (this document, same date): the fresh adversarial review
of the draft returned RATIFY-WITH-AMENDMENTS; finding F1 was
independently CONFIRMED-IMPOSSIBLE (and strengthened — the const-expr
leg's `Eff.exceptM` carries no state component at all, §3.3). The six
amendments A1–A6 and minors are applied throughout; the load-bearing
one is A1: the draft's "draw order equals elabM run order" claim was
wrong in general, and the corrected construct-time/run-time site
analysis (§3.6) shows one site with **unavoidable oracle
draw-sequence movement**, which amends Q1 into an explicit operator
decision about tolerated, adjudicated oracle renumbering.

Revision R3 (same date; supersedes R2's "final"): (1) Q1b receives
its FINAL ruling — **TOLERATED** [USER 2026-08-31] — together with an
operator PRINCIPLE on order-dependent output (§9, §3.6); the R2
escalation clause is superseded. (2) Finding **S0-F1** (the S0 scan
record, commit `156e57cb8`,
`docs/2026-08-31_S0-scan-record.md`) corrects §2.2/§3.6: lem's
`mapM` is EAGER, so the movement class is broader than the charter's
one site; O2 is REPLACED for the tolerated route by a one-time
adjudicated rebaseline obligation and O6 absorbs the re-emission
procedure. (3) Three new named C1 gate items (§8.1). (4) The §8.3 M2
rider is WITHDRAWN as an erratum (§8.4 — L0 verified NO defect).
(5) L0/L1 outcomes absorbed: slices DONE, deviations adjudicated,
L2 riders registered, §3.2/§4.2 status implemented-and-audited.
(6) S0 census absorbed: the C2 gate-design caveat (partial-def
kernel-cone opacity) and the finalized `unsafeBaseIO` allowlist
(`scripts/unsafebaseio_allowlist.txt`). R3 gets a fresh review
before C1 is briefed.

Revision R2 (same date): (1) all five operator questions are
RULED [USER 2026-08-31] — §9 is now the decision log (Q1a/Q1b/Q2/Q3
ratified as recommended; Q4 ratified in a sharpened per-survivor
form); (2) the consumer review (refined-cerberus, verdict RATIFY
from the consumer seat; lem-lean
`doc/lean-backend/2026-08-31_effect-retirement-external-review.md`
@ `582d901`) is absorbed: the entry-shape decision (§1.3, §3.4 a),
the Lean-side change manifest deliverable (§8.1 C1/C2), the fuel
opt-in classification (§8.3), and the explicit non-goals incl. the
new grep-able obligation O7 (§1.4, §3.5).

Headline findings of the census/analysis (details in §2–§3; also
reported to the orchestrator):

- **F1 (design-level, load-bearing; independently confirmed by the
  R1 adversarial review).** A first-order supply-lifting — the exact
  state analog of the reader lifting — cannot, by itself, reach the
  live `fresh_int` clients: every live path crosses a monadic
  higher-order boundary (`desugM` at the constant-expression seam,
  `elabM` throughout elaboration) where state-passing is not
  type-preserving. Reader lifting survives closures via partial
  application; state lifting has no analogous repair. Strengthening
  from the R1 review: the const-expr leg additionally crosses
  `Eff.exceptM` (`mini_pipeline.lem:55-57`, the exception monad),
  which carries **no state component at all** — so even a backend
  taught to inject state through a declared monad would have no
  carrier on that leg. §3.3 states this precisely; §3.4 proposes the
  resolution (backend feature for the first-order region + bounded
  model accommodations on the arc-13 precedent — generated-OCaml
  TEXT changes, manifest-recorded; oracle dynamic BEHAVIOR gated per
  §3.5/§3.6) and §9 puts the scope amendment to the operator.
- **F4 (R1, from the A1 site analysis, §3.6; CORRECTED in R3 by
  S0-F1).** The elaboration cone's draws split into construct-time
  and run-time classes; monadification maps both to run order. The
  R1 per-static-site classification stands (and m1b —
  `erase_loop_control_aux`'s own local state monad — remains
  required), but its per-CALL-POSITION adjacency conclusion ("18 of
  19 order-preserved, one moved site") was WRONG: lem's `mapM` is
  EAGER (`mapM f = listM (List.map f)`,
  `frontend/model/state.lem:58-59`), so every block statement list
  batches its statements' construct-time draws at block construction
  (in REVERSE statement order), decoupled from each statement's run.
  Movement is a CLASS, not a site — S0-measured (§3.6): 25 pinned
  speclab Core dumps under the charter-narrow trigger alone; 34/39
  speclab dumps + 14/21 tests/corpus pin files + the libc.core hash
  under the witnessed broader class. Movement applies to the
  ORACLE's dynamic draw sequence. Q1b FINAL ruling: TOLERATED (§9);
  the one-time adjudicated rebaseline obligation replaces per-site
  oracle order preservation (§3.5 O2/O6).
- **F2 (census sharpening).** "13 generated runEffectful call sites"
  = 13 grep hits; 9 are applied call sites (Symbol.lean 7,
  Core_run_aux.lean 1, Translation_effect.lean 1), 4 are comment
  mentions in hand-written support files copied into `generated/`
  (CerbTags 2, CerberusFresh 1, CerbDebug 1). No applied
  `runEffectful` site exists for `set_tagDefs`/`reset_tagDefs` or for
  CerbDebug: those two retirements are entirely hand-written/driver
  and native-seam cleanups, with no backend transform involved.
- **F3 (census; precision fixed in R1).** `Core_unstruct` is
  generated and built (`lean_frontend/lakefile.toml:51`) and is
  imported only by `Core_unstruct_auxiliary` — which is itself
  imported by nothing — so the PAIR is Lean-dead; its two
  `Symbol.fresh` sites nevertheless count in the census and would
  trip the new transform's closure guard. §3.4 (e) proposes dropping
  **both modules** from the Lean build list (dropping only
  `Core_unstruct` would break the auxiliary's import).
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
- **Universal form (R1, A2): EVERY constant elaborated from this
  repository and from LemLib has axiom cone ⊆
  `[propext, Classical.choice, Quot.sound]`.** This is derived, not
  sampled: the hand-written census-zero leg, the generated-tree
  census-zero leg, and the (new) recursive LemLib census-zero leg
  establish that no axiom is *declared* anywhere in the two
  codebases, and the standing D14/sorry bans exclude the
  tactic-introduced axioms (`sorryAx`, `ofReduceBool/Nat`) from the
  probed cones — so any axiom reachable from any constant is one of
  Lean's own three. Entry-point `#print axioms` probes remain as
  **end-to-end spot checks** of that derivation, on the fixed entry
  set: `driver2`, `drive`, `RelSem.Cerb.callND`,
  `initial_driver_state`, and the per-phase frontend entries —
  `desugar` (the constant applied at `Main.lean:512`),
  `annotate_program`, `translate`, `link`, `convert_file` —
  exact-allowlist assertions, fail-closed, wired into
  `check_theorem_axioms.sh` (§7.2).
- What remains on the *runtime* trust boundary (declared, gated, not
  axioms): the `@[implemented_by]`/`@[extern]` seams enumerated in
  the §7.2 ratchet's `unsafeBaseIO` allowlist (R1, A5 — not
  digest-only): the per-TU digest machinery
  (`CerberusFresh.digest`/`md5Hex`/`forceIO`), the CerbGlobal
  config/switch refs, the CerberusImpl enum registry, and the
  CerbUtils no-op timing/log refs — the full inventory is an S0
  deliverable (§8.1) and a Q4 input. All are kernel-checked opaques
  whose compiled behavior is native. No proof can unfold them; they
  contribute nothing to any axiom cone.
  (Adjacency note: threading the per-TU digest as an explicit input
  is a possible later arc; it is out of scope here because it costs
  no axiom. Whether the arc's bar is this — "axiom gone" — or the
  strictly larger "no impure pure-signature constants" is put to the
  operator as §9 Q4.)
- Non-kernel proof methods remain gate-banned (D14) — unchanged.
- **Entry shape (R2 — the consumer review's A1 shape question,
  answered as a design decision).** The retired production entry
  (`initial_driver_state` / `initial_core_run_state`) lands as
  **shape (b): a SUPPLY-PARAMETERIZED pure constructor** —
  `initial_driver_state : Nat → … → driver_state × Nat` — with Main
  supplying the concrete initial value. No seed constant is baked
  into the entry. Rationale: matches the driver-seeds-from-
  initial-state design already in the seeding scheme (§3.2, §3.4 a),
  and the consumer states (b) is free for them (their
  never-reads-the-seam property is proved; their theorems gain a
  ∀-supply quantifier they consider a strengthening of the exported
  statements). Provenance: [AGENT] (orchestrator ruling,
  consumer-agreed; the operator can override at the arc's merge
  gates).

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

### 1.4 Explicit non-goals (R2 — consumer assumptions made checkable)

Recorded verbatim-in-substance from the consumer review's A4, so a
future reviewer can check each cheaply:

1. **Entry purity.** The production entry remains a pure,
   termination-checked, CLOSED constructor — modulo exactly the
   shape-(b) supply parameter (§1.3) — with **no IO-flavored
   wrapper**: any such wrapper reintroduces the class of thing this
   arc deletes. The consumer quantifies over the entry verbatim.
2. **No new nondeterminism.** Supply threading is deterministic
   state-passing and must introduce **no new ND branch points** —
   stated as obligation **O7** (§3.5), checkable by grep on the ND
   structure: the arc's diffs add no new applications of the ND
   node/branch builders (the `ND.bind` fanout / `nd`/`msum`-family
   constructors) anywhere in the migrated cone. The consumer's
   production equation rests on proved singleton step lists +
   `runND` collapse on the positive sequential path.
3. **Symbol-numbering shifts are consumer-invisible.** Their
   theorems are over authored Core with directly-constructed
   symbols; elaboration-side numbering is invisible to them today —
   consumer-confirmed (review A4.3), already governed by O3/O6.

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

Order note for (b), CORRECTED in R1 (the draft's "draw order equals
`elabM` run order" was false in general — review MAJOR-1): in a
strict language the draws split into two classes. **Construct-time
draws** fire when an `elabM` value is *built* — evaluation prefixes
of defs and match arms, and first-position bind heads (e.g.
`wrapped_fresh_symbol`'s `let sym = Symbol.fresh () in return ...`,
`translation_effect.lem:63-65`; `sym_loop` at `translation.lem:3800`).
**Run-time draws** fire when the state function is *applied* —
draws inside raw `fun st ->` lambdas (`with_block_objects`' const-
alias mints, `translation_effect.lem:102-111`) and inside bind
continuations. The dynamic sequence is a deterministic interleaving
of the two classes; monadification maps BOTH classes to run order,
so the sequence is preserved only where construction is adjacent to
run (no intervening draw). Where it is not — the eager-HOF-argument
pattern — the order moves, for the oracle too. §3.6 does the
per-site analysis; the surviving reason `elab_state` is the right
carrier stands (it is live at every run-time firing point), but the
order argument is per-site, not global. R3/S0-F1 correction: the
eager-HOF-argument pattern includes `E.mapM self ss` itself — lem's
`mapM` is `listM (List.map f)` (`frontend/model/state.lem:58-59`),
EAGER — so block statement lists batch construct-time draws at block
construction, in REVERSE statement order (lem's generated OCaml
evaluates the `List.map` cons right-to-left; S0 record §1, witnessed
verbatim). Under the Q1b TOLERATED ruling no per-site order argument
is attempted for the migration: the movement is expected, its scope
is the S0 measurement, and the pinned artifacts rebaseline once
(§3.5 O2/O6).

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
   `CerbTags.tagDefs ()` at **11 applied sites** (plus 2 comment
   mentions at `:250,1180` — count corrected in R1): the layout
   family's default-budget wrappers (`:477,483,492,496`),
   `offsetsof` callers (`:650,772`), the union-arm lookups
   (`:404,463` — a deliberate mirror of upstream's asymmetry, see
   §4.2), the member-lookup arm (`:787`), and the member-shift pair
   (`:1185,1186`). Comment at `Main.lean:852-854`: "CerbMem's
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

**R3 status: IMPLEMENTED AND AUDITED** (lem-lean arc branch: feature
commits `383b996` supply / `195b683` reader_consumer / `40df3a8`
fuel budgets; record `doc/lean-backend/2026-08-31_L1-features-record.md`
@ `a51615e`; fresh-audit response `4bff8b7` — verdict
MERGE-SAFE-WITH-NOTES, MAJOR-1 fixed). Standing evidence at the
audit-response tree, verbatim from the record: full suite exit 0,
47/47 generation, **41/41 negative probes** (derived breakdown: 15
pre-slice + 14 supply + 1 reader + 7 reader_consumer + 4
fuel-budget), all compiled pins green (supply draw-sequence binary
at 12 checks + the kernel-pinned `rfl` short-circuit shapes),
`nonlean-regress` byte-identical (893 artifact rows / 216 exit
rows / 9 emitters). The audit's MAJOR-1 (short-circuit `&&`/`||`
right operands threaded strictly — an O1 defect) is fixed via
branch-arm threading with kernel-pinned semantics; it is the
standing exhibit for why O1 is load-bearing.

**L1 deviations, adjudicated charter-conformant (R3, per the
orchestrator's absorption ruling):** (i) G-type accepts `natural` as
well as `nat` (both map to Lean `Nat`) — a documented superset of
the spec's `unit -> nat`, blessed; (ii) defs carrying a Lean
target_rep are EXCLUDED from supply lifting (their bodies are dead
text and their call sites emit the rep, which cannot take a supply)
— a deliberate, documented divergence from the reader pre-pass,
blessed (the alternative silently injects state into a hand-written
rep). **L2 riders registered:** the paren-split application-spine
strictness pin + in-code note (the L1 delta audit's NOTE-1, relayed
— to land as a lem-side test + comment in L2), and the lem-side
review-doc erratum of §8.5.

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
  (`mini_pipeline.lem:127-133`). R1 strengthening: `Eff` is the
  plain exception monad (`mini_pipeline.lem:55-57
  module Eff = Exception`), whose type carries **no state
  component** — so on this leg even a hypothetical backend feature
  that injects state through a *declared* monad has no carrier to
  inject into; the only expressible threading is a value-type change
  (`Eff.exceptM (value * nat)`), i.e. a model edit.
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

The arc-1 record anticipated this. Verbatim from
`2026-08-18_effects-totality-design.md` §7c, whose heading reads
"fresh as an explicit choice-stream input (user question,
2026-08-18)": "Ruled direction for the eventual honest treatment of
`fresh` (parked until a verified-translation arc needs it): an
explicit CONSUMED stream/counter input — i.e. state threading, not
reader ... threading through the desugar/translation monads the
model already has." (Provenance note, R1 minor-6: the record itself
carries no [USER]/[AGENT] marker on the "Ruled direction" sentence —
flagged for operator re-marking rather than back-attributed here.)
The fork has executed
that pattern twice — desugar (arc-13) and run-time minting (arc-2/13)
— each time as: *supply as a field of the already-threaded state,
monadic mint in the model, `ocaml` target_rep redirect keeping the
oracle on the ambient counter, oracle output preserved and gated*.
TODO.md's standing entry describes the same end state ("the
fresh-symbol supply threaded through the machine state").

Proposal — the lem feature carries the first-order region; bounded
model accommodations (m1, m1b, m2 below) carry the supply across the
monadic boundaries, on the in-tree precedent. Framing per R1 A4,
stated once and relied on throughout: the accommodations change
generated-OCaml **text** — the §6.4 diff is nonempty by design,
every hunk manifest-recorded — while oracle dynamic **behavior** is
a separately-gated property (O2/O6, with the §3.6 per-site analysis
and its one movement site). "OCaml-output-preserving" is not claimed
of the accommodations as a class.

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
explicitly. This IS the §1.3 entry-shape decision (R2): shape (b),
a supply-parameterized pure constructor with no baked seed — the
form the consumer's re-export consumes statement-visibly.

**(b) Model accommodation m1 — the elaboration monad.** `elab_state`
(`translation_effect.lem:24-40`) gains a `fresh_supply : nat` field;
`elab_init` takes its seed; monadic mints
(`fresh_elab_sym : symbol_description -> elabM sym`, plus a bare
`fresh_elab_int : elabM nat` for `record_object_types_marker`) are
added, built from the **pure** `Symbol.fresh_given_int`
(`symbol.lem:262`) exactly as `core_run.lem:115-121` does today, with
`declare ocaml target_rep` redirects to `Fork_renumber` variants that
draw ambiently — the oracle keeps drawing from its single ambient
counter **at the migrated positions**; its dynamic draw *sequence*
moves per the S0-measured class (R3 — §3.6/§3.6.1; Q1b TOLERATED),
handled by the one-time adjudicated rebaseline of O2/O6.
The 19 live sites migrate (15 in `translation.lem`, 4 in
`translation_effect.lem`): direct `let sym = Symbol.fresh* ...`
becomes a bind on the mint; the two lambda sites become the monadic
map (`876`: `mapi`-lambda → `mapM` over the indexed list; `3954`:
`list_init` → a threaded build), and `translation_effect.lem:107`'s
`foldl` threads the supply through its accumulator.
`translate`'s entry (`translation.lem:4524`) seeds `elab_init` from
the supply parameter that the (a)-lifted signature hands it.

**(b') Model accommodation m1b — the loop-control erasure monad
(found by the §3.6 site analysis).** `erase_loop_control_aux`
(`translation.lem:3300-3311`) draws inside its OWN local state monad
(`St.stateM ... erase_loop_control_state` — a second monadic carrier
the draft's m1 did not cover): `with_fresh_labels` mints
continue/break label syms inside a raw `fun st ->` lambda. The pass
is run to completion atomically from the function-definition
elaboration prefix (`translation.lem:4355 let stmt =
erase_loop_control stmt in`), so its draws are a contiguous block in
the dynamic sequence. Treatment: the pass's state threads the supply
too (a supply component beside `erase_loop_control_state`, seeded
from the elaboration supply at the 4355 call — which becomes a
monadic position — and returned to it). Order-preserved: the pass's
draws stay contiguous at the same position (§3.6 table).

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

**(d) The stream-unification decision** (§9 Q2 — RULED
[USER 2026-08-31]: S1, single-stream). Option S1 (single
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
seeded at 2^20. R1 correction (A1-iv): S2's numbering is
byte-identical to today **as a measured expectation, not by
construction** — the §3.6 movement site reorders draws within the
ambient stream regardless of stream count, and every other site's
construct/run adjacency is an argued property the battery confirms,
not a syntactic identity. S2's real content is narrower: it avoids
the *cross-stream* renumbering S1 adds on top (desugar ids shifting
into the unified stream). Cost: the stratification invariant
survives as a proof obligation on the seeding instead of dying, and
two supplies thread where one would do.

**(e) Core_unstruct**: drop the PAIR `Core_unstruct` +
`Core_unstruct_auxiliary` from the Lean generation/build lists
(`Makefile` module list, `lakefile.toml:51` names both) — the
auxiliary imports the main module, so dropping only one breaks the
build (R1 minor-1); the pair is Lean-dead (F3); the `.lem` file and
the OCaml output are untouched. Recorded as a build-config change,
not a model change. (Alternative if the operator prefers the modules
kept buildable: restructure the two folds target-neutrally; not
recommended — dead-code surgery.)

Model-delta budget of the whole proposal: 2 declare-line swaps
(`symbol.lem`), ~25 mechanical site edits + 1 state field + 2 mint
helpers + redirect declares (m1), 1 supply component + seeded call
position for the erase pass (m1b), ~1 seam signature + call-site
wrap (m2), 0 edits for (e). Every hunk lands in the fork-drift
manifest with its OCaml-side justification (§6.4).

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
- **O2 (m1/m1b/m2 migrations, oracle side; REPLACED in R3 for the
  tolerated route).** The R1 form of this obligation — a per-site
  oracle draw-order-preservation argument via construct/run
  adjacency — is WITHDRAWN: S0-F1 showed the adjacency property
  fails as a class (eager `mapM`/HOF batching, §2.2/§3.6), and the
  Q1b FINAL ruling is TOLERATED. The obligation is now the
  **one-time adjudicated rebaseline**: at C1, every moved pinned
  artifact is enumerated ROW BY ROW (starting set = the S0
  measurement: the 25 D1 speclab dumps; under the broader class
  34/39 speclab dumps + their derived `SpecLab/*Core.lean` pinned
  terms, 14/21 `tests/corpus` pin files, the `tests/libc/libc.core`
  content hash; the 10 fixture goldens regenerate), each delta
  adjudicated as an INSTRUMENT change (dedicated commit,
  justification in the header, movement explained by the migration —
  an unexplained delta remains a finding), and the whole set
  operator-sanctioned at the arc-close merge gates. What survives of
  the R1 form: the migrated OCaml redirects still draw from the
  single ambient counter (the arc-13 backstop `check_ail_window`
  still refuses a re-threaded supply loudly, exit 70), the
  lambda→monadic-map rewrites still preserve LIST order within a
  batch, and the regenerated-OCaml diff review (§6.4) still maps
  every text hunk to the manifest. Note O1 is UNCHANGED and remains
  load-bearing for the lem feature itself (transform-local order
  fidelity — exactly the obligation the L1 audit's MAJOR-1
  short-circuit finding was a defect against, fixed at `4bff8b7`).
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
- **O6 (R1: the movement site; RESCOPED in R3 to the movement CLASS
  and the re-emission procedure).** Under the Q1b FINAL ruling
  (TOLERATED, §9), O6 is the operational half of O2's rebaseline:
  the C1 re-emission procedure for every moved pinned-artifact
  family — (i) `tests/speclab/*.core` dumps re-derived from the
  post-m1 oracle, their derived `SpecLab/*Core.lean` pinned terms
  re-emitted via the standing `speclab-emit-*` drift-gated path,
  family gate expectations re-verified; (ii) `tests/corpus` pins
  (`*.core[.sha256]`, `*_funs.core`) re-derived + the
  `check_fixture_freeze.sh` manifest re-pinned; (iii) the
  `tests/libc/libc.core` content hash re-pinned via `libc_prep.sh`'s
  standing re-derivation discipline; (iv) fixture goldens
  regenerated (`gen_goldens.sh` — not gate-compared, no
  adjudication needed); (v) `tests/verify` dumps expected UNMOVED
  (S0: D1=D2=0 on all 5 pinned) — movement there is a finding, not
  a rebaseline. Every re-pin is an instrument change with its own
  commit and justification, never absorbed; exhaustive-mode
  verdict-SET rows (the Fmap-enumeration caveat, S0 §3.2) are
  checked semantically per gate item (a) of §8.1 C1.
- **O7 (R2: no new nondeterminism — non-goal 2 of §1.4, stated as a
  checkable obligation).** The supply transform and the m1/m1b/m2
  migrations add **zero** new ND branch points: a grep over the
  arc's diffs for the ND node/branch builders (`ND.bind` fanout,
  `nd`/`msum`-family constructors) shows no new applications in the
  migrated cone; discharged at each C-slice gate alongside O1-O6 and
  recorded in the slice's gate log. Supply threading is
  deterministic state-passing — an ND-visible change is a defect,
  not a tuning point.

### 3.6 Construct-time vs run-time draws: the site analysis (R1, A1; CORRECTED in R3 per S0-F1)

**R3 status of this section.** The E/R classification below (per
STATIC site) is correct and stands — S0 re-verified the site census
and calibrated the classes empirically (S0 record §1). The table's
"preserved" VERDICT column and the R1 "non-decouplers" paragraph are
**WITHDRAWN**: they answered the per-call-position adjacency
question, and S0-F1 proved that question has a different answer —
lem's `mapM` is EAGER (`mapM f = listM (List.map f)`,
`frontend/model/state.lem:58-59`), so `E.mapM self ss`
(`translation.lem:3684`, and the block form at `:3714` via
`with_block_objects decls (E.mapM self ss)`) constructs EVERY
statement's computation up front: each block batches its statements'
E-draws at construction, in REVERSE statement order (right-to-left
`List.map` cons evaluation in the generated OCaml; S0's two-`while`
witness, verbatim in the S0 record §1, shows the 2-id eager-batch
signature). Under monadification the batch disperses to run order —
movement with no `const` declaration anywhere. Plain nested blocks
are transparent to the batch; blocks under `if`/`while`/`do`/
`switch` are barriers (S0 calibration). Under the Q1b FINAL ruling
(TOLERATED) no adjacency argument is attempted: the table remains as
the E/R record that DEFINES which draws move (E-draws in eager list
positions and the `with_block_objects` alias mints move; R-draws in
bind continuations keep their relative run positions), and the
movement's measured scope is §3.6.1.

Monadification (m1/m1b/m2) maps every draw to its run position. The
analysis below classifies each of the 19 live elaboration-cone sites
by current firing class — **E** (construct-time: evaluation prefix /
first bind head) or **R** (run-time: raw `fun st ->` lambda, or bind
continuation). Read the per-row "preserved" verdicts as the
superseded R1 adjacency claims, kept for the record.

| Site | Draw | Class | Post-m1 position | Verdict |
|---|---|---|---|---|
| `translation_effect.lem:65` | `wrapped_fresh_symbol` head | E | head of its bind chain | preserved (adjacent: constructed as bind head, run immediately) |
| `translation_effect.lem:70` | `wrapped_fresh_symbol_` head | E | same | preserved |
| `translation_effect.lem:107` | const-alias mints in `with_block_objects`' `fun st ->` | R | head of the composite, BEFORE the body | **MOVED** (see below) |
| `translation_effect.lem:178` | `record_object_types_marker` prefix | E | head of its chain | preserved |
| `translation.lem:876` | `mapi` batch (`fresh_funarg`) | E-batch | contiguous `mapM` at same position | preserved (batch stays contiguous; list order kept) |
| `translation.lem:1871` | `let_sym` (AilEcast) | R (inside 3rd bind continuation) | same chain position | preserved |
| `translation.lem:3305,3306` | continue/break syms in `with_fresh_labels`' `fun st ->` (the m1b monad) | R | same position inside the erase pass | preserved, GIVEN m1b (pass draws are run-order internally — every draw in that monad is R; the pass block stays contiguous at `translation.lem:4355`) |
| `translation.lem:3800` | `sym_loop` (while) arm prefix | E | head of the arm's chain | preserved (adjacent) — but movable RELATIVE to :107 when inside a const block |
| `translation.lem:3836-3838` | `sym_loop`/`sym_case`/`sym_e` (do) arm prefix | E | head of the arm's chain | preserved (same caveat) |
| `translation.lem:3954,3955` | `case_syms` batch + `default_sym` (switch) | E-batch in a continuation | contiguous mints at same position | preserved |
| `translation.lem:4235` | `sym_global` | E (prefix in the globals fold step) | same position | preserved; note the draw is unconditional but UNUSED on the external-object branch — the mint must stay unconditional to keep numbering |
| `translation.lem:4265` | `e_sym` | R (continuation) | same | preserved |
| `translation.lem:4354` | `ret_label` (fn-def prefix) | E | head of the fn-def chain | preserved (order vs the :4355 erase-pass block and :4361 kept by emitting mints in prefix order) |
| `translation.lem:4361` | variadic `Symbol.fresh ()` | E (same prefix) | same | preserved |
| `translation.lem:4414` | `ret_sym` | E (later prefix) | same | preserved |

**The movement site, precisely.** `with_block_objects binds ma`
(`translation_effect.lem:101-125`): `ma` — the elaborated block body
— is an eagerly-evaluated ARGUMENT (constructed first; in OCaml's
right-to-left argument order, before `binds`), while the const-alias
mints (`if qs.Ctype.const then let sym' = Symbol.fresh () ...`,
unconditional on any switch — the fold always draws for
const-qualified binds) fire inside the returned `fun st ->`, i.e. at
run, between `ma`'s construction and `ma`'s run. Current dynamic
order: [ma's E-draws] [alias mints] [ma's R-draws]. Any
monadification yields [alias mints] [all of ma's draws in source
order] (or, placing the mints after the body, [ma] [mints]) — the
E/R interleaving is **not expressible in single-phase monadic
order**, and no .lem restructuring recovers it either, because
post-retirement every draw needs the supply and the supply exists
only in the run. Movement is therefore unavoidable, and it applies
to the ORACLE (the redirects draw at the migrated positions).
Triggering inputs: a block with ≥1 const-qualified local whose body
contains construct-time draws — e.g. `{ const int k = 3;
while (1) { ... } }` (the alias mint currently draws AFTER
`while_N`'s `sym_loop`; post-m1 it draws before). Live draw-bearing
callers: `translation.lem:3556`, `:3698`, `:3714` (the `:3684` and
`:4251` calls pass `[]` binds — no draws; `:4369` wraps function
args in `no_qualifiers` — `const` is false, no draws). R3: this
site's mint condition was S0-confirmed empirically (const scalar/
array/`* const` draw; pointee-const does not), and the site is now
ONE MEMBER of the S0-F1 movement class — scope and ruling in
§3.6.1.

**Non-decouplers, corrected (R3).** The R1 paragraph here claimed
`mapM`/`foldlM` construct per-element computations during their own
run — **FALSE for lem's `mapM`** (S0-F1; the eager
`listM (List.map f)` definition), which is exactly the block
statement-list position. What DOES hold, S0-recalibrated:
`track_temporary_objects` draws nothing itself; expression,
assignment, call, `if`, `return`, and cast STATEMENTS contribute
zero construct-time draws (S0 probe: the `while` id is invariant
when they are prepended); `switch`'s case/default mints fire at run
(the :3954-3955 classification confirmed); the two entry
`runStateM`s (`translation.lem:4524`, `mini_pipeline.lem:133`) run
the constructed value immediately. The E-draw statement forms are
`while`/`do` (arm prefixes) — and top-level definitions elaborate in
reverse order too, so post-m1 source-order sequencing reorders even
single-E-statement regions relative to each other (S0 §1).

### 3.6.1 The S0 measurement (DONE, `156e57cb8`) and the tolerated route

The §8.1 S0 scan ran (scanner `scripts/s0_order_scan.py` over the
oracle's own `--pp=ail`; 102 files across the symbol-visible pin
corpora; raw rows in `docs/2026-08-31_S0-scan-results.tsv`; record
`docs/2026-08-31_S0-scan-record.md`). Verdict: **NONTRIVIAL** — not
the "possibly zero" hoped for:

- Charter-narrow trigger (D1, const+loop co-residence): **25 pinned
  speclab `.core` dumps** (applist/getarr/lookup/memcpy/pairswap —
  the `mkHarness` const arrays co-resident with codec loops).
- Witnessed broader class (D2, the S0-F1 eager-batch movement):
  34/39 speclab dumps (+ TreeRot; DivMod stays clean), **14 of 21
  `tests/corpus` pin files** (families p04-p08, p14, p15), and the
  **`tests/libc/libc.core` content-hash pin** (8 of 12 libc.co TUs
  D2-hit). `tests/verify`'s 5 pinned dumps: clean under both.
- Verdict-only baselines (exec/elab/multi-tu etc.) see no symbol
  ids; main-mode differentials are additionally id-canonicalized
  and compare oracle-vs-Lean in the same run, so coordinated
  two-sided movement is invisible to them. Residual caveat:
  exhaustive-mode verdict SETS could in principle surface
  symbol-keyed enumeration-order changes — C1 gate item (a), §8.1.

**The Q1b FINAL ruling and the recorded trade** (R3). Per the R2
ruling's own escalation clause this NONTRIVIAL verdict would have
escalated to the staged pre-slice — but S0-F1 dissolved that
option's premise (staging the ONE site no longer makes m1
order-preserving; the class moves regardless). Final ruling
[USER 2026-08-31]: **TOLERATED**, full stop. Considered and
rejected, with the trade taken knowingly:

- *Construct-time pre-minting* (reproduce today's two-phase draw
  order monadically by pre-minting eager batches): rejected — it
  bakes the accident of eager `List.map` evaluation order into the
  model as permanent back-compat machinery, in reverse statement
  order, forever.
- *Staged pre-slice* (move the mints on both targets first, then an
  order-preserving m1): rejected — S0-F1 broke its premise; a
  faithful staging would have to reproduce the entire eager-batch
  interleaving, which is pre-minting again.
- Cost accepted knowingly: the fork's oracle Core dumps diverge
  textually from un-forked upstream on affected inputs —
  up-to-renaming only — carried by the fork-drift manifest and the
  §8.1 C1 upstream-divergence enumeration deliverable.

The rebaseline procedure and scope are O2/O6 (§3.5).

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
implementations read the global today (enumerated at implementation
time from the 11 applied read sites of §2.4: the
load/store/allocate family and the `sizeof/alignof/offsetof` ival
entries). CerbMem's default-budget wrappers then take `tagDefs` as
an argument and the 11 reads become parameter uses. The mini-run works unchanged: `run_const_expr_driver`
seeds the lifted callees with `tds`, which now flows to the mem-op
call sites (this *replaces* the with-extent global set, and closes it
correctly rather than ambiently).

**Feature specification (R1, A6 — brought to §3.2 grade so Q3 stays
a live option; R3 status: IMPLEMENTED in L1, commit `195b683` — 7
negative probes green, the reader_seed seed-name pickup
probe-verified per the L1 record).**
`declare {lean} reader_consumer val f`,
target-scoped; storage: a `reader_consumer : Targetset.t` field
beside `reader` in `const_descr`.

- *Semantics.* `f` must carry a Lean `target_rep` (it is an extern
  boundary — that is the point); its generated call sites receive
  ALL reader parameters as extra leading arguments, in the same
  global sorted order as lifted-def binders
  (`lean_backend.ml:366-381`), before `f`'s own arguments; the
  pre-pass fixpoint treats a use of `f` exactly like a use of a
  reader constant (callers get lifted). The hand-written
  implementation declares the matching leading parameters
  explicitly.
- *Injection routing (the reader_seed interaction).* Call-site
  emission goes through `reader_inject_name`
  (`lean_backend.ml:1580-1588`) — the same resolver lifted-def calls
  use — so inside a `reader_seed` def the SEED's first-argument name
  is injected instead of the binder name. This is what makes the
  mini-run correct: `run_const_expr_driver`'s body
  (`mini_pipeline.lem:70-78`) calls into the driver chain, and every
  `reader_consumer` site in that cone picks up `tds` via the
  existing override, with no new seed machinery.
- *Fail-closed guards*, each a generation-time error: RC-rep (no
  Lean target_rep on the declared val); RC-mix (the same val also
  declared `reader`, `reader_seed`, `supply`, or — transitionally —
  `effectful`); RC-inst (a consumer call inside an `Instance`
  method — the caller cannot be lifted, same as the reader instance
  gap); RC-rel (a consumer use inside `Indreln`/lemma contexts).
  Bare references need no guard: partial application over reader
  parameters is type-preserving (§3.1), so a bare `reader_consumer`
  reference is repaired exactly like a bare lifted-def reference.
- *Tests.* `tests/comprehensive`: a consumer val called from plain,
  lifted, and `reader_seed` contexts (asserting the seed-name
  pickup), plus a bare-reference/HOF use; `negative/`: one
  reproducer per guard asserting the error fragment.
- *Non-Lean invariance.* As §6.1: the declaration is a
  `Targetset`-scoped no-op for every other backend; covered by the
  same invariance test and the L0 golden-hash net.

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
- **Model accommodations m1/m1b/m2** (cerberus slice): the
  generated-OCaml diff is nonempty by design; every hunk maps to a
  `scripts/fork_drift_manifest.txt` entry with its redirect
  (`check_fork_drift.sh` re-pins the layer-2 hashes on review); the
  oracle's dynamic draw sequence moves per the tolerated class (R3)
  and rebaselines once under O2/O6's adjudication (single-supply
  coherence still asserted by the arc-13 `check_ail_window`
  backstop); the divergence-from-upstream class is documented by C1
  deliverable (c).

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

- **New leg, LemLib census**: zero `axiom` declarations across the
  LemLib package scanned **recursively** —
  `.lake/packages/LemLib/lean-lib/**/*.lean`, which includes the
  subdirectory sources (`LemLib/Num.lean`, `LemLib/Set_extra.lean`,
  `LemLib/List_extra.lean`, ...) that a flat `lean-lib/*.lean` glob
  would miss (R1, A3). Same comment-stripping scanner as the
  generated-tree census; fail-closed on a missing package dir AND on
  an empty recursive file list.
- **Exec-entry exact census**: the `#print axioms` probes (today:
  exemplars + `driver2`, sorryAx/DAEMON/ofReduce-free,
  `check_theorem_axioms.sh:225-319`) are extended to the full §1.3
  entry set and tightened from ban-lists to an **exact allowlist**:
  every reported axiom must be one of
  `propext, Classical.choice, Quot.sound`; anything else fails with
  the constant named. Per the A2 restatement these probes are the
  end-to-end spot checks of the universal census-derived claim — the
  census legs are the load-bearing gate, the probes the vacuity
  check on real cones. **C2 gate-design caveat (R3, from the S0
  census, measured):** `#print axioms` UNDERREPORTS across
  `partial def`/opaque boundaries — S0 measured `desugar`'s kernel
  cone clean while its COMPILED path reaches `runEffectful` (the
  Cabs_to_ail chain is partial-defs; the const-expr seam is dirty
  underneath). The kernel-cone probes therefore prove exactly the
  KERNEL claim (which is what the customer contract needs) and MUST
  NOT be used as primary evidence that the effect machinery is gone
  — the source-scan census legs (zero axiom declarations, the
  `runEffectful` grep-ban) are the primary evidence; the probes are
  spot checks only.
- **Grep-ban**: `runEffectful` banned outright in `generated/`,
  hand-written `.lean`, and the LemLib copy; `unsafeBaseIO`
  allowlisted at exactly the **enumerated survivor list** (R1, A5 —
  the draft's digest-only allowlist under-censused the population).
  R3: the allowlist is FINALIZED and committed as
  `scripts/unsafebaseio_allowlist.txt` (@ `156e57cb8`; S0 record §4
  — matches the table below exactly, zero out-of-table sites; it is
  the ratchet's machine-readable input at C2). Census (the
  CerbDebug and CerbTags entries are deleted by this arc), with the
  per-survivor classification RULED [USER 2026-08-31] (Q4 sharpened
  form, §9 — every allowlist row carries its class, per the
  no-internal-trust-gaps boundary-list discipline):
  - `CerberusFresh.lean:86` (digest read) — **converted in C2**: the
    kernel-checked-opaque treatment (the `with_tagDefs` pattern,
    house-proven per the consumer review) is a C2 deliverable, not a
    standing allowlist row;
  - `CerbGlobal.lean:64,68,74,101` (config + switches refs — written
    once by Main at startup, reader-shaped after) — **temporal**;
    named mover: a post-arc parameter-plumbing slice;
  - `CerberusImpl.lean:56,222` (the enum registry — a genuinely
    stateful seam: `register_enum` writes during elaboration,
    `typeof_enum` reads later, mirroring OCaml DefaultImpl's ref) —
    **temporal**; named mover: this arc's reader/supply machinery,
    applied in a FOLLOW-UP slice (explicitly NOT in-arc; the
    consumer confirmed no need to accelerate it on their account);
  - `CerbUtils.lean:19,38,41,79` (no-op timing/log refs,
    intentionally unread — retained for OCaml module-shape parity) —
    **permanent-declared**.
  Any occurrence outside the enumerated list fails.
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
  goes red; run TWICE, once in a top-level file and once in a
  **subdirectory** source (`LemLib/Num.lean`) so the recursive glob
  of A3 is itself plant-tested (a flat-glob regression would pass
  the first and miss the second).
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
  re-verify this note's site census against the rebased tree. R1
  additions: (i) the §3.6 corpus scan — bound the input set that
  triggers the movement site (const-qualified block locals followed
  by draw-bearing statements) across the pinned corpora, feeding the
  amended Q1 decision with numbers; (ii) finalize the full
  `unsafeBaseIO` survivor allowlist (§7.2 grep-ban leg) — the A5
  enumeration re-verified, characterized, and recorded as the Q4
  inventory.
  **R3 status: DONE** (`156e57cb8`; record
  `docs/2026-08-31_S0-scan-record.md`). Outcomes absorbed: the scan
  verdict NONTRIVIAL + finding S0-F1 (→ §3.6/§3.6.1, Q1b final);
  the allowlist committed (`scripts/unsafebaseio_allowlist.txt`,
  matches the Q4 table exactly, zero out-of-table sites); the entry
  census measured — dirty today: `initial_driver_state`,
  `translate`; the other seven clean, WITH the §7.2 gate-design
  caveat: `desugar`'s KERNEL cone is clean only because the
  Cabs_to_ail chain is `partial def`s (kernel-opaque) while its
  COMPILED path reaches `runEffectful` via the const-expr seam —
  `#print axioms` underreports across partial-def boundaries.
- **L0 (lem-lean, "fix first" preamble — review-mandated, ordered;
  R3 status: DONE — record
  `doc/lean-backend/2026-08-31_L0-fix-first-record.md` @ `4fd4d50`,
  with item 5 = the §8.5 M2 no-defect escalation).**
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
- **L1 (lem-lean; R3 status: DONE — features `383b996`/`195b683`/
  `40df3a8`, record @ `a51615e`, audit response `4bff8b7`; status,
  evidence, deviations and L2 riders absorbed at §3.2/§4.2).** The
  supply feature (§3.2) + `reader_consumer` (§4.2, ratified — §9
  Q3) + the fuel-budget feature (§8.3, opt-in-only classification
  honored). `runEffectful` and `effectful` remain. Gate: lem suite +
  lean-lib build + the §6.4 byte-identity probe against cerberus @
  S0 — all recorded green in the L1 record + audit addendum.
- **C1 (cerberus adoption).** Pin bump to L1; `symbol.lem` declare
  swap; m1/m1b/m2 migrations under the ratified rulings (§9): Q2 =
  single-stream (S1); Q1b = TOLERATED (final, R3 — the S0-verdict
  escalation clause is superseded; the movement class rebaselines
  once per O2/O6); Core_unstruct pair build-list drop; Main
  threading (entry shape (b), §1.3); tagDefs loop closure + CerbMem
  re-plumb + union-arm seeding (§4); CerbDebug cleanup (§5). Gate:
  FULL battery (Tier A+B, test_verify, speclab, Tier C reporting
  for O3), fork-drift manifest review, O1-O7 discharged and
  recorded, PLUS three NAMED gate items (R3):
  **(a) order-sensitive observables check** — every output that
  iterates symbol-keyed maps/sets (Fmap enumeration order,
  `Core_linking` `topo_order` / linked-definition emission order,
  multi-TU link order, dump section order, exhaustive-mode verdict
  sets) is verified semantically-equivalent-up-to-permutation across
  the rebaseline, and each site where output DOES depend on symbol
  order is registered per the §9 operator principle (a finding and
  an upstream candidate, never accommodated);
  **(b) the L1 deviation-4 cone check** — an explicit check that NO
  supply-lifted `Let_def`-bound top-level VALUE sits in the adopted
  lifted cone (a drawing value binding has per-use state-passing
  semantics under the transform vs the effectful mechanism's
  once-at-init; the census expects only function defs, and this
  check makes that expectation load-bearing — the L1 audit's
  recorded C1-brief obligation);
  **(c) the upstream-divergence enumeration deliverable** — the
  fork-drift-manifest + VALIDATION.md documentation of the tolerated
  renumbering class (which oracle outputs diverge from un-forked
  upstream, textually, up-to-renaming, and why), shipped at C1 and
  finalized at C2.
  **Close-out deliverable (R2, consumer request; recipient:
  refined-cerberus): the LEAN-SIDE CHANGE MANIFEST at the adoption
  pin** — the Lean analog of the §6.4 OCaml-text manifest: an
  enumerated list of changed/renamed definitions in the exec cone,
  specifically covering the entry constructors
  (`initial_driver_state`/`initial_core_run_state`), the driver
  round path (`Driver.lean:273-351` today), `step_ctx`'s cone, the
  memory ops (`loadM`/`storeM`/`allocateObject`), and
  `finalize`/`Driver.hack`, plus the FINAL SIGNATURES of `drive` and
  the entry (including their tagDefs argument's fate) — so the
  consumer's re-certification is scoped, not discovered. Finalized
  again at C2 for the deletion-slice deltas.
- **L2 (lem-lean, deletion).** §7.1 lem-side deletions (axiom +
  effectful class); DESIGN.md rewrite. Gate: lem suite (now with
  P1) + lean-lib.
- **C2 (cerberus, ratchet).** Pin bump to L2; §7.1 cerberus-side
  deletions; §7.2 ratchet + §7.3 plants red-green; the **digest
  kernel-checked-opaque conversion** (the Q4 ruling's promoted
  deliverable — the `with_tagDefs`-pattern explicit-witness
  treatment for `CerberusFresh.digest`, §7.2); the Lean-side change
  manifest finalized for the deletion-slice deltas (recipient:
  refined-cerberus). Gate: full
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
feature gets its **own design note before L1 is briefed** (R3
status note: L1 implemented it @ `40df3a8` along the review's
attachment-point analysis, documented in the L1 record's feature
section + DESIGN.md; NO standalone design note was written — the
L1 record is the de-facto note. FLAGGED for the pre-C1 review
rather than silently blessed: the charter requirement was met in
substance, not in form); this
note's only constraints on it: it rides L1 (one pin bump, one
review), its tests join the same suite, and it must not interact
with supply lifting beyond the composition case already covered
(§3.2: fuel self-calls thread the supply like they re-inject
readers). R2 classification (the consumer review's fuel flag,
adopted as a constraint on the fuel design note): **per-declaration
fuel budgets are OPT-IN ANNOTATION ONLY** — unannotated declarations
keep `lemDefaultFuel` semantics byte-for-byte unchanged (the
consumer's exported statements carry fuel side conditions stated
against `lemDefaultFuel`, and their size accounting tracks the
current plumbing). If the L1 implementation cannot honor that, it is
a **stop-and-report event**, never a silent change. The review additionally locates the attachment point
(budget = one `Targetmap` field beside `fuel_sentinel`, replacing
the hardcoded `lemDefaultFuel` at `lean_backend.ml:2504`) and
mandates adding `lemDefaultFuel` + the budget binder to the
reserved-name contract — inputs for that note, recorded here so the
pairing brief is complete. R3 ERRATUM: the M2 `integerDiv` rider
that stood here is WITHDRAWN — L0 verified NO defect (§8.5); the
rider's factual premise was wrong and no `Int.tdiv` change rides
any slice.

### 8.4 Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | Call-order divergence (transform or migration reorders draws) | O1/O2 structural rules incl. the construct/run adjacency argument (§3.6 table re-verified at implementation) + pinned-order lem test + full battery byte-identity; the ONE known movement site handled per Q1b under O6's adjudication discipline; oracle side additionally `check_ail_window` (refuses loudly) |
| R2 | Lean-side renumbering shift (S1) surfaces an iteration-order-observable | O3: full battery incl. Tier B/C before any claim; baselines fail closed in both directions; fallback = S2 (two streams) is a contained retreat, decided by measurement not re-design |
| R3 | Reader/supply composition bug (binder order, double injection) | fixed binder order in the spec; dedicated composition test; the exec slice exercises it for real in the mini-run (reader_seed + supply) |
| R4 | Instance-method gap (the old `lean_backend.ml:1546-1548` limitation: attributes can't be emitted on instance fields, so effectful calls in instance methods were only one-level protected) | post-retirement the hazard class is deleted with the mechanism — there is nothing to protect; verified: no effectful call site sits in a generated instance method today (all 9 applied sites are in plain `Val_def`s); G-inst keeps the supply analog fail-closed rather than silently under-protected |
| R5 | Union-arm mirror regression (tags) | §4.2 named witness: the pinned `offsetof-union-member` crash pair must stay green; phase-appropriate seeding specified before code |
| R6 | Mid-arc window where lem has the feature and cerberus still uses `effectful` | legal by construction (L1 deletes nothing); the transitional both-annotations error (§3.2) prevents mixing on one val |
| R7 | Grind risk: m1 is ~25 mechanical edits with a full battery per boundary | slice budget per the grind ban; the battery runs are differential-corpus measurement (the sanctioned category), builds stay capped via `scripts/capped` |

### 8.5 Erratum (R3): backend-quality-review M2 (integerDiv) WITHDRAWN

The review's M2 and this charter's former §8.3 rider asserted lem
`integer` division maps to truncating `Z.div` on OCaml vs Euclidean
`Int.ediv` on Lean. **Verified FALSE at the actual call target** (L0
item 5, VERIFIED-NO-DEFECT; record: lem-lean
`doc/lean-backend/2026-08-31_L0-fix-first-record.md` §"Item 5",
commit `9614621`): the chain is `integerDiv` → `Nat_big_num.div`
(`library/num.lem:1405`) → `Big_int_Z.div_big_int` (zarith's
num-compat layer) — **Euclidean**, agreeing with Lean's `Int.ediv`
at every signed corner (measured verbatim both targets, incl.
compiled binaries; `integerMod` likewise). Applying the review's
remedy (`Int.tdiv`) would have INTRODUCED the divergence it warned
about. Parity is now PINNED both targets (`test_integer_div.lem` +
the compiled `lean-div-parity` phase). No generated-Lean semantics
change reaches cerberus-lean from this item; the C1 battery carries
no M2 signature.

Auditor-recommended residue, kept (verified against this tree): raw
truncating `Z.div` DOES exist in the hand-written OCaml memory-model
seams — `memory/vip/impl_mem.ml:1021` (the `IntDiv` arithmetic op)
and `memory/concrete/impl_mem.ml:1393` (prefix-offset naming) — so
the mirror obligation lands THERE when/where those seams are
ported. [AGENT] verification note, flagged not silently folded: the
same grep shows the class also includes the pointer-difference
divisions `memory/vip/impl_mem.ml:718` and
`memory/concrete/impl_mem.ml:1967` (`Z.div` on a possibly-negative
address difference — the ported CerbMem mirror of the concrete
site should be checked for truncation-vs-Euclidean parity as part
of the same obligation).

The review document itself is a committed verbatim record; its copy
on the lem-lean arc branch
(`doc/lean-backend/2026-08-31_backend-quality-review.md` @
`e591865`) receives the same dated erratum in **L2's commit** (this
charter cannot commit there); until then, THIS section is the
correction of record.

## 9. Decision log: the operator questions, all CLOSED (R2; Q1b finalized R3)

Every question below is RULED [USER 2026-08-31] (relayed via the
orchestrator). Summary — Q1a: ratified. Q1b: ratified
tolerated-with-scan at R2, then — after the S0 scan returned
NONTRIVIAL and S0-F1 dissolved the staged option's premise —
**FINAL at R3: TOLERATED**, with an accompanying operator principle
(below). Q2: ratified, single-stream. Q3: ratified, reader_consumer
rides the arc. Q4: ratified in the sharpened per-survivor form
([USER 2026-08-31] verbatim on the sharpened package: "yeah, this
all seems reasonable"). The question texts are kept as the record;
each carries its ruling inline:

- **Q1 (blocks L1/C1 scope; AMENDED in R1).** Two rulings in one,
  because the second is entailed by the first:
  (Q1a) Finding F1 (independently confirmed): the ratified
  backend-only route cannot reach through the `desugM`/`elabM`/
  `Eff.exceptM` boundaries (§3.3). Ratify (or amend) the §3.4
  split: lem supply feature for the first-order region + the
  bounded model accommodations (m1, m1b, m2, and the `symbol.lem`
  declare swap) on the arc-13 redirect precedent — with the A4
  distinction stated plainly: the accommodations change generated-
  OCaml **text** (every hunk manifest-recorded, §6.4), and oracle
  dynamic **behavior** is preserved per O2 at 18 of 19 sites — or
  direct an alternative (the rejected options are recorded in §3.3
  with reasons).
  (Q1b) The movement site (§3.6, F4): `with_block_objects`' oracle
  draw-sequence movement is unavoidable under ANY monadification,
  so — since the "not disturbing the OCaml output" ruling is
  verbatim about output — the operator must choose its handling:
  **(i) staged**: a dedicated pre-slice moves the alias minting to
  an explicitly-sequenced monadic position on BOTH targets first,
  with its own oracle rebaselining and adjudicated fixture-dump
  deltas, so the m1 migration proper is then order-preserving
  against the new baseline; or **(ii) tolerated**: the movement
  rides m1, gated by O6's adjudication discipline (every affected
  pinned output enumerated and rebaselined as an instrument
  change). Both end in the same oracle behavior; the choice is
  audit granularity. The S0 corpus scan (§3.6) sizes the blast
  radius first — if no corpus input triggers the pattern, the
  pinned dumps are unchanged under either option and only the
  numbering-identity claim carries the recorded caveat. [AGENT]
  recommends (ii) with the scan in hand, (i) if the scan shows
  nontrivial fixture churn.
  **RULING [USER 2026-08-31]: Q1a RATIFIED** (the split, with the
  text-vs-behavior framing). **Q1b RATIFIED as recommended**:
  tolerated-with-scan, escalating to the staged pre-slice iff the
  S0 corpus scan shows nontrivial fixture churn.
  **Q1b FINAL RULING (R3) [USER 2026-08-31]: TOLERATED** —
  superseding the escalation clause above (the S0 scan returned
  NONTRIVIAL, but S0-F1 showed staging-the-one-site no longer
  yields an order-preserving m1; §3.6.1). Operator rationale,
  verbatim: "this seems like... the more principled way of doing
  it. We don't bake in some weird back-compat machinery, and we
  stay in sync with the oracle up to renaming (it seems like the
  oracle *should not* depend on naming, that seems like a defect in
  itself)". **Accompanying operator PRINCIPLE (standing):**
  oracle/engine output depending on symbol numbering beyond binding
  identity is itself a defect — any order-dependent-output site
  discovered (C1 gate item (a), §8.1) is registered as a finding
  and an upstream candidate, never accommodated. The pre-minting
  and staged options are recorded considered-and-rejected with the
  trade analysis at §3.6.1; the upstream byte-fidelity cost is
  accepted knowingly (the fork's oracle Core dumps diverge from
  un-forked upstream on affected inputs, textually, up-to-renaming,
  carried by the fork-drift manifest and the §8.1 C1 deliverable
  (c)).
- **Q2 (blocks C1 design; framing corrected in R1 per A1-iv).**
  Stream unification: S1 (single threaded supply, structural
  collision-impossibility, deletes the 2^20 machinery) vs S2 (two
  streams, keeps a stratification obligation). NEITHER option is
  byte-stable "by construction": the §3.6 movement site and the
  per-site adjacency arguments make Lean-side numbering a measured
  property under both; the actual difference is that S1 additionally
  shifts desugar ids into the unified stream (a larger, uniform,
  Lean-side-only renumbering measured by O3), while S2 confines the
  change to the ambient stream. §3.4 (d); [AGENT] still recommends
  S1 — the structural invariant is worth the one-time measured
  shift, and both options pay the same O6 toll.
  **RULING [USER 2026-08-31]: RATIFIED — single-stream (S1).**
- **Q3 (blocks L1 scope).** Include `reader_consumer` (§4.2, now
  specified to §3.2 grade per R1 A6 — guards, tests, and the
  reader_seed injection-routing analysis are in the spec block) in
  the same lem arc? It is the enabling mechanism proposed for the
  CerbMem global's retirement; the alternative (model-visible
  tagDefs parameters on the mem.lem vals) touches shared signatures
  far more broadly. [AGENT] recommends inclusion.
  **RULING [USER 2026-08-31]: RATIFIED — `reader_consumer` rides
  the arc (joins L1 per §8.1).**
- **Q4 (blocks the arc's success criterion; raised by the
  2026-08-31 backend quality review, deletion-readiness item c).**
  The arc's bar: **"axiom gone"** or **"no impure pure-signature
  constants"**? Beyond `runEffectful` there is a family of
  pure-signature externs in the same hazard class that do NOT thread
  like a counter: `CerberusFresh.digest` (per-TU value; would thread
  as a reader-per-TU, not a supply), the CerbTags surface (retired
  by §4 in this arc anyway), and — inventory completed in R1 (A5),
  finalized at S0 — `CerbGlobal` (config + switches refs,
  `CerbGlobal.lean:64,68,74,101`: written once by Main at startup,
  reader-shaped after), `CerberusImpl`'s enum registry
  (`CerberusImpl.lean:56,222`: a genuinely stateful write/read seam
  mirroring OCaml DefaultImpl's ref cell), and `CerbUtils`'s no-op
  timing/log refs (`CerbUtils.lean:19,38,41,79`: intentionally
  unread, shape-parity only). Option A ("axiom gone", this note's
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
  **RULING [USER 2026-08-31]: RATIFIED in the SHARPENED form**
  (operator verbatim on the sharpened package: "yeah, this all seems
  reasonable"): the bar is **axiom gone**, AND the ratchet
  classifies every survivor explicitly — `digest` → kernel-checked
  opaque IN C2 (promoted from allowlist row to a C2 deliverable,
  §7.2/§8.1); CerbUtils no-op refs → permanent-declared; CerbGlobal
  config refs → temporal, mover = a post-arc parameter-plumbing
  slice; CerberusImpl enum registry → temporal, mover = this arc's
  reader/supply machinery applied in a follow-up slice (NOT in-arc;
  the consumer confirmed no need to accelerate).

(Not operator questions — [AGENT] recommendations that stood
through the R1 adversarial review and are carried into the slices:
the Core_unstruct pair build-list drop (§3.4 e); the union-arm
phase-appropriate seeding (§4.2); the FreshIntTest rewrite (§7.1).
The R2 entry-shape decision (§1.3) is likewise [AGENT],
consumer-agreed, overridable at the merge gates.)

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
- The external review record incl. the consumer review
  (refined-cerberus / cerberus-heaplang, verdict **RATIFY from the
  consumer seat**; source of the §1.3 entry-shape question, the
  §8.1 change-manifest deliverable, the §8.3 fuel flag, and the
  §1.4 non-goals): lem-lean
  `doc/lean-backend/2026-08-31_effect-retirement-external-review.md`
  @ commit `582d901`.
- Slice records (R3 absorption sources): S0 —
  `docs/2026-08-31_S0-scan-record.md` + `…_S0-scan-results.tsv` +
  `scripts/s0_order_scan.py` + `scripts/unsafebaseio_allowlist.txt`
  (@ `156e57cb8`, this repo); L0 — lem-lean
  `doc/lean-backend/2026-08-31_L0-fix-first-record.md` (@ `4fd4d50`);
  L1 — lem-lean `doc/lean-backend/2026-08-31_L1-features-record.md`
  (@ `a51615e`, audit addendum @ `4bff8b7`).
