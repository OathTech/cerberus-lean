# ACL2Lean design-donor review (for the arc-16 part-2 charter)

[AGENT] review, 2026-08-24. Genre: design-donor review, same series as
`notes/2026-08-21_lithium-source-review.md` and the brick-wp review.
Subject: `deps/ACL2Lean` @ `5ec2a4b` (tag `v0.1.0` at `06ccb8e`,
2026-08-19). Consumer context read first: container CLAUDE.md
(canon-first + trick filter), the arc-16 charter and S0–S3 records
(worktree `cerberus-lean-iris-refounding`), especially the S3
compute-forward park (`2026-08-24_arc16-s3-laws-and-tactics.md` §5, §7:
whnf inlining a full `driver_state` carrying `core_file` blows the
default heartbeat budget inside ONE `whnf`, ~10.4 GB RSS). This review
feeds the part-2 items: reflection-backed discharge, certificate/trace
replay for the wp-tactics, and the "giant terms in goals are a
representation smell" design principle.

Read surface: README.md, docs/OVERVIEW.md, CLAUDE.md, docs/LEXICON.md
(skimmed via OVERVIEW), TODO.md, docs/notes/{project-history,
bump-inventory}, docs/plans/{soundness-experiment-findings,
proof-producing-checker}, docs/archive/overview-historical-notes,
validation/README.md, and source: `ACL2Lean/` (EvalOpt, Logic surface,
ProofLogTypes, Replay/Driver/{Reflect,DevQuery}, Replay/{Runner,
WorldTransport}, Lemmas survey, NodeCore survey), `Tests/Coverage/
Harness.lean`, `Tests/driver-coverage.golden`, the one in-tree proof
log (`acl2_samples/pattern-tests/p8-clausify-detail.proof-log`),
ReplayMain.lean. All paths below are repo-relative under
`/home/dev/projects/cerberus-lean-proj/deps/ACL2Lean/`.

## 0. License and provenance (the vendoring record)

- `LICENSE`: **BSD 3-Clause**, "Copyright (c) 2026, The ACL2Lean
  Authors". `AUTHORS`: Mike Dodds, Alok Singh, Claude (Anthropic) —
  **in-house project, permissive license**. Vendoring and derivation
  are unencumbered (no Yolo-rule issue).
- The `acl2/` submodule (the instrumented ACL2 fork, pinned
  `e8d78e5`) carries upstream ACL2's own license and is **NOT
  initialized in this checkout** (`git submodule status` shows `-`).
- Checkout state caveat: the ~91 captured `.proof-log` build inputs
  are **gitignored by design** and only ONE survives in-tree
  (`p8-clausify-detail.proof-log`, 5.7 KB). This clone cannot
  `lake build` or re-run the tool without rebuilding the ACL2 fork
  and recapturing (their own docs say exactly this, fail-closed —
  OVERVIEW § Getting started). This review is therefore a SOURCE
  review; no build was run.

Scale: 183 `.lean` files; `ACL2Lean/` ≈ 70.4K lines (the README's
"~70,000 untrusted lines" checks out), `Tests/` ≈ 5.7K, of which the
mirror/waypoint/lifting layer is ≈ 22.5K.

What v0.1.0 actually is: the J Moore sorting corpus + pattern books
replayed end to end — `Tests/driver-coverage.golden:1` reads
`REPLAYED 116/116 (116 unconditional + 0 conditional)`; 21 mirror
products (6 Basics + 15 Sorting, instantiated at `Int`/`Option Int`),
cones pinned to `{propext, Classical.choice, Quot.sound}`;
independently validated via leanprover/comparator + nanoda
(`validation/README.md`). The docs are unusually honest about scope
(see §7).

---

## 1. Q1 — Certificate format

**The certificate is an s-expression EVENT STREAM emitted by an
instrumented producer, reconstructed into a tree, at three nested
granularities.** Evidence: the surviving log
`acl2_samples/pattern-tests/p8-clausify-detail.proof-log` and the
datatypes in `ACL2Lean/ProofLogTypes.lean`.

- **Development level**: world events in file order — `(:DEFTHM name
  :FORMULA … :TFORMULA …)`, `(:DEFUN name :FORMALS … :BODY …)`,
  `(:TYPE-PRESCRIPTION … :LEAVES …)`, `(:RULES …)`,
  `(:GROUND-ZERO-RULES …)`, closing `(:CAPTURE-END :BOOKS …
  :STATUS :COMPLETE)`. The world the statement is proved over is
  PROJECTED from these events (`Development.toWorld`).
- **Clause level**: `(:STEP :CLAUSEID "Goal" :PROCESSOR
  PREPROCESS-CLAUSE :RESULT :PROVED :RUNES … :INPUTCLAUSE …)` — one
  event per waterfall-processor application per clause, linked into a
  tree by clause-id lineage ("the inverse of ACL2's `waterfall1-lst`";
  unlinkable structure hard-fails — `ClauseTree.lean`, OVERVIEW
  stage 4).
- **Rewrite-step level**: inside a `:STEP`, `:REWRITES` carries
  per-literal atoms: `(:REWRITE-STEP :RUNE (:DEFINITION IMPLIES)
  :ORIGIN … :EQUIV EQUAL :LHS … :RHS …)` plus recorded `:SUBST`
  (substitutions), `:PATH` (congruence position frames —
  `ProofLogTypes.lean:22-37` `PathFrame`), and clausify sub-events
  (`:CLAUSIFY-EXPAND/-NEG/-SPLIT/-OUT`, `:DEDUP-DROP`,
  `:COMPLEMENT-CLOSE`).

Key format decisions worth copying:

1. **Record the CHOICE, not the derivation.** Every atom names the
   rule (rune), the position (`:PATH`), the substitution (`:SUBST`),
   and both sides (`:LHS`/`:RHS`). The consumer does **no inference**
   (governing rule, their CLAUDE.md "The checker does no inference"):
   it RECOMPUTES the instance and equality-checks it against the
   record — e.g. `NodeCore/Congruence.lean:343-357` checks
   `substTerm σvars σterms r.lhs == lhs` and hard-fails with
   "emission gap" on mismatch. Missing information is fixed by MORE
   INSTRUMENTATION at the producer, never a Lean-side heuristic.
2. **Fail-closed with TYPED frontiers.** Unreplayable steps throw a
   TAGGED error (`Reflect.lean:79-91` `frontierTag` /
   `throwFrontier`), classified by tag, never by message-string
   prefix ("a prefix is a shared namespace a real defect's message
   could accidentally inhabit"). No silent skip, no sorry; a
   frontiered theorem shows on the scoreboard as a kept hypothesis or
   a named failure.
3. **Verdict-only leaves are a RATIFIED carve-out, not a loophole.**
   Where the producer itself has no internal proof record (ACL2's
   decision procedures), the certificate carries a discharge node
   with the precise obligation, and the consumer closes that LEAF by
   its own kernel-checked decision procedure — scoped to leaves only;
   using it to shortcut a recorded step is forbidden
   (`docs/plans/2026-06-09_direct-proof-emission.md`).
4. **Provenance is part of the format**: `.proof-log.meta` sidecars
   with source/include-closure hashes, fatal capture
   (`scripts/check-log-provenance.sh`); producer identity (ACL2
   commit hash) in the log header.
5. Cost note: the format is verbose text — 5.7 KB for one trivial
   theorem. They accepted this; certificate size never appears as a
   measured concern in their docs.

**Our analogue** (wp-tactic / automation traces for certificate
replay): a trace atom = (law name, joint/position in the peeled
structure, the fed equation or side-condition instance, expected
before/after state names). The arc-9/11 `app_walk` certificate
emitter already exists in this genre; the ACL2Lean lessons to add are
the typed-frontier discipline, the recompute-and-check (never infer)
consumer contract, and producer-provenance in the artifact.

---

## 2. Q2 — Reflection plumbing (the highest-value question)

**Headline: ACL2Lean is NOT a verified-checker-applied-by-reflection
system, and it got there deliberately.** The architecture is:
once-proved GENERIC LEMMAS + untrusted MetaM orchestration emitting
proof TERMS + kernel COMPUTATION for all ground side conditions over
reflected first-order data. Three architectures were tried in
sequence (`docs/notes/2026-08-18_project-history.md` ch. 1–2):

1. Tactic replay with heuristic fallbacks — killed in days (no bridge
   between ACL2's rule level and Lean's arithmetic).
2. A VERIFIED REWRITER (`evalReplace_sound`: a once-proved generic
   replacement-soundness theorem —
   `docs/plans/2026-03-24_soundness-experiment-findings.md`). Partly
   proved, then superseded: the generic theorem needed
   well-formedness preconditions and argument-list congruence bridges,
   and a Bool checker's verdict still has to be turned into a proof
   of the target statement.
3. The **proof-producing checker**
   (`docs/plans/2026-04-04_proof-producing-checker.md`): same
   dispatch as the Bool checker, but `proveNode : Ctx → ProofNode →
   MetaM Expr` — each node emits the application of a once-proved
   lemma. This is what shipped.

And a RATIFIED design invariant fell out of it (their CLAUDE.md L1):
**"a monolithic `Derivation` inductive with one soundness theorem is
prohibited"** — consolidations are fragment-local (own datatype, own
soundness lemma) behind judgment `Prop`s. This is a direct, earned
data point AGAINST the maximal form of our part-2 "reified step
representation + once-proved soundness theorem" sketch, from a system
whose logic is far SIMPLER than ours (first-order, total, no binders
in values).

What the reflection layer actually consists of — all of it liftable
as PATTERN, some as near-verbatim code:

- **Reified object language + reflection functions.**
  `Reflect.lean:21-71`: `reflectInt/Symbol/Number/Atom/SExpr/DefMap/
  World` — SExpr data → `Expr` literals. Canonicity invariants of
  reflected literals are re-proved BY KERNEL COMPUTATION: the
  `Symbol.mk`/`Number.rational` literals embed a defeq-cast
  `rfl : true = true` against `canonSym/canonRat … = true`
  (`Reflect.lean:26-40`) — the subset-type side condition costs one
  whnf, not a proof.
- **The single ground-fact discharger**: `proveByDecide`
  (`Reflect.lean:102-120`) — synthesize the `Decidable` instance,
  `whnf` at transparency `.all` on `decide p inst`, demand
  `Bool.true`, emit `of_decide_eq_true p inst rfl`. "NOT heuristic:
  no simp set, no search." Plus a MEMO CACHE keyed by the whole Prop
  `Expr` (`Reflect.lean:93-113`) — measured motivation: 3,869 calls
  ≈ 3.4 s on ONE theorem before memoization; only successes cached.
- **The once-proved law library** (~10.3K lines,
  `Replay/Lemmas/`): fuel-robust congruence lemmas per arity/position
  (`evalOpt_congr_unary/binary_left/…/if_then`, Core.lean:420-578),
  defn-unfold lemmas, chaining (`fuel_chain_eq`), substitution
  lemmas, world transport. Statement shape everywhere:
  `∃ N, ∀ f ≥ N, evalOpt f w e a = evalOpt f w e b`
  (`Reflect.lean:141-162`) — **fuel-robustness pushed into the
  statement**, so certificates carry no fuel arithmetic and steps
  chain by monotonicity. (Our runner-observation algebra
  `runNDFuel_*` in S3's PerStepRunner is the same move at the
  observational level.)
- **Giant terms as NAMED CONSTANTS, never in goals.**
  `derive_world` (`DevQuery.lean:100-115`): the world — the one
  fixture-scale term, every defun of the book — is reflected ONCE
  into a top-level `def` with `hints := .abbrev` +
  `enableRealizationsForConst`, "a concrete (fast-reducing) def".
  Statements are `∀ env, EvTrue worldConst env ⟦Φ⟧`; the reflected
  world `Expr` is pointer-shared across every use in a book
  (`Reflect.lean:96-97`). Replayed theorems are `addDecl`'d
  constants "applied O(1) thereafter" (`Runner.lean:640-641`).
- **The concrete-column whnf trick (with a named abstraction).**
  `WorldTransport.lean:24-40` (the P3c reconciliation): equation-
  lemma generation for `callBuiltin`'s 55-arm match **dies at a FIXED
  200k-heartbeat whnf budget that `set_option maxHeartbeats 0` does
  NOT lift**. The generic route (`∀ name ∉ builtins, …`) is
  therefore abandoned; instead, for each CONCRETE name,
  `∀ args, callBuiltin "N" args = none` closes by `rfl` **with
  `args` still abstract** — "the compiled decision tree splits on
  the name column first". Demand-scoped, finite, name-by-name. This
  passes the trick filter as stated: one sentence names the
  abstraction (match compilation column order) and the next instance
  gets it free.
- **Budget management**: internal per-unit-of-work guards
  (`Runner.tryReplay` 3M user heartbeat-units per theorem, 10M per
  admission, `tryDischarge` 1M per DP leaf), with book-level
  `maxHeartbeats 0` retained only at 10 of 29 measured sites, each
  with its measured total at the site (`Tests/Coverage/
  Harness.lean:126-158` — 19 sites came in under the 200k default
  and their raises were DELETED; "the default is the alarm").
  Kernel depth is the other axis: `--tstack=524288` (512 MB thread
  stacks) in the lakefile and `maxRecDepth 1000000` at the deepest
  waypoint declarations (`docs/notes/2026-08-19_bump-inventory.md`
  W8) — kernel replay of deep first-order proof terms is
  DEPTH-hungry even when width is controlled.

**How much is liftable for our verified-verifier slice?** The code
itself is SExpr-specific and small; what transfers is architecture:

- `proveByDecide` + memo (~40 lines) lifts nearly verbatim as our
  side-condition discharger inside wp-tactics (S3's `wp_side` =
  `assumption | rfl | decide` is its unmemoized baby form).
- The named-constant discipline is the answer to the S3 park (§4
  below).
- The concrete-column lesson bears directly on any reified
  `symStep`/Core-shape dispatcher we build: wide matches over
  reified constructors are kernel-cheap ONLY entered by a concrete
  discriminant; never rely on equation lemmas of a wide match, and
  keep the discriminant column first.
- The proof-producing-not-verified-checker verdict, plus L1
  (fragment-local soundness, no monolithic Derivation), should be
  cited in the part-2 charter as the canon-first lineage record for
  whatever discharge engine we choose. Notably: what our part 2
  calls "reflection" (once-proved laws + kernel computation of side
  conditions at concrete instances) is what ACL2Lean DOES; what it
  is not is a deep-embedded checker with a global soundness theorem.

---

## 3. Q3 — Replay economics

Measured numbers found (all from their own dated records; none
re-measured here):

- **Corpus**: 116/116 theorems replayed (golden header), 21 mirror
  products, 71 DP probes (✓62 ◌9 ✗0).
- **Cold build ≈ 2 h** measured 2026-08-16
  (`docs/archive/2026-08-19_overview-historical-notes.md` §E),
  dominated by two coverage modules at **~50 min and ~8 min**; after
  the 2026-08-18 perf arc those two are **477 s and 423 s**
  (OVERVIEW, fresh-clone inventory: `Tests.Coverage.
  BSsortsEquivalent` 476,930 ms; `BSqsort` 422,680 ms). Whole-build
  never re-measured — they say so.
- **Heartbeat census** (Harness.lean:150-158): per-book elaboration
  cost ranges 5k → 12.43M user units (1 unit = 1000 heartbeats) —
  i.e. the heaviest single book burns ~62× the per-theorem guard.
- **proveByDecide**: 3,869 calls ≈ 3.4 s on one theorem pre-memo
  (`Reflect.lean:93-98`).
- **ACL2-side vs Lean-side time: NOT RECORDED.** No doc I read
  compares replay time to ACL2's original proof time. For this
  corpus ACL2 certifies in seconds, so the honest reading is that
  kernel replay is 2–3 orders slower than the oracle's search — the
  project optimized replay from "unaffordable" to "tens of minutes
  per corpus", not to parity.
- **Certificate sizes: not recorded**; single data point 5.7 KB for
  a trivial theorem, 91 logs at the 2026-08-19 audit.

Where the costs concentrated, and what fixed them (the perf-arc
shape, from `WorldTransport.lean` header + `Runner.lean`
`crossBookRegistry`):

1. **Quadratic cross-world re-replay** — a dependency theorem
   re-replayed inside every consumer's world. Fix: the WORLD
   TRANSPORT — a once-proved `evalOpt_world_mono` behind two
   DECIDABLE side conditions (`worldExtendsCheck`,
   `newKeysCoverCheck`) discharged by `mkDecideProof` at reflected
   concrete worlds, one PER-PAIR transport constant
   (`tryBuildPairTransport`, `WorldTransport.lean` bottom), then
   O(1) statement transport per theorem. Meta-level Bool pre-check
   BEFORE spending kernel time (`Runner.lean` "compiled, cheap").
2. **Recurring ground side conditions** — fixed by the memo cache.
3. **Fuel bookkeeping** — never paid: the `∃N ∀f≥N` statement shape.
4. **Residual concentration**: DP leaves (a fixed `simp_all` +
   `omega` kit under a split loop — their bump-inventory W1 names it
   the fragile hot spot) and sheer kernel DEPTH (tstack/maxRecDepth).

**The transferable economics lesson**: kernel replay became
affordable exactly where work was (a) hoisted into `addDecl`'d
constants applied O(1), (b) memoized, or (c) turned into one
decidable check over concrete reflected data — and stayed expensive
where proofs are deep chains of small steps. That maps cleanly onto
our S3 finding that the named-state regime is seconds and
compute-forward is unbounded.

---

## 4. Q4 — Term representation under load (against our giant-terms
smell)

**There is no interning, hash-consing, or index table anywhere.**
`SExpr` is a plain inductive; terms are re-reflected structurally.
Their load management is entirely by WHERE terms live, not how they
are stored:

1. **The one giant term (the world) is a named `.abbrev` constant**
   (`derive_world`, DevQuery.lean:100-115), reflected once,
   pointer-shared as an `Expr`, and referenced by NAME in every
   statement and goal. It unfolds only inside kernel `whnf`/`decide`
   on demand — it is never displayed, never elaborator-traversed,
   never inlined into a goal.
2. **Proofs are built as `Expr`s in MetaM, not by tactic scripts** —
   there is no goal state to blow up. The elaborator/whnf-in-goal
   pathology we hit in S3 structurally cannot occur; the kernel sees
   each finished term once at `addDecl`, and mid-sized intermediates
   are pinned with `mkExpectedTypeHint` (`@id ty pf`) so the kernel
   checks them at the intended type.
3. **Once checked, a fact becomes a constant applied O(1)** (the D1
   registry, cross-book transport, per-admission constants —
   Runner.lean:640-641, 723-726).
4. The price they still pay is DEPTH (512 MB stacks, maxRecDepth
   raises at the deepest declarations) — naming constants controls
   width/duplication, not proof-term depth.

**Application to factoring `core_file` out of goal states**: this is
the donor's clearest endorsement of the S3 record's own named
canonical fix. The S3 park (§5) showed compute-forward whnf inlines
a `driver_state` carrying the whole program term; ACL2Lean's pattern
says: give every fixture (and every reachable intermediate state the
tactics must name) a top-level `.abbrev`-style constant — a
`derive_state`/`derive_core` analogue of `derive_world` — emitted by
metaprogram from the parsed artifact, and make the wp-tactic layer
step from named state to named state, computing successor states
ONCE in the meta layer (which is also HeapLang ProofMode's
architecture, already named in S3 §7). The donor adds two concrete
mechanisms we had not written down: `hints := .abbrev` +
`enableRealizationsForConst` for the emitted constants, and the
meta-level Bool pre-check before any kernel decide on state-sized
data.

---

## 5. Trust architecture (and the nanoda pattern)

Their TCB, product path: Lean kernel + the zero-import mirror spec
file + one 7-line `TotalOrder Int` instance (README:29-41). The
~70K-line pipeline is untrusted by construction. One level down, the
**three-property separation** is the discipline worth quoting
(OVERVIEW § Trust model): (1) logical soundness — kernel-certified;
(2) statement authenticity (it is the NAMED theorem) — engineering
evidence only (hashes, hand pins, tamper tests); (3) replay fidelity
(the proof retraces the oracle, no Lean-side shortcut) — engineering
evidence only (frontiers, seam gates, generated templates). "Both
(2) and (3) must never be reported as kernel guarantees." Our PROOF.md
genre already distinguishes proved-vs-gated; adopting their explicit
three-property naming would sharpen it.

**Independent validation** (`validation/README.md`): the 21 products
are re-checked by leanprover/comparator — statement match
constant-by-constant over `lean4export`ed terms against a zero-import
`Challenge.lean`, permitted-axioms pinned to the classical trio, then
the whole exported environment replayed from EMPTY by BOTH Lean's
kernel (`Environment.replay`) and **nanoda** (independent Rust
kernel). Negative controls demonstrated (a flipped challenge
statement rejected, two organic rejections during drafting). Also
note the honest sandbox scoping: the landrun layer is declared a
free speedbump, not a property ("do not harden it") — their
two-standard rule applied to their own harness.

**Worth importing for our audit gates?** Yes, at milestone
granularity, with a priced caveat. Our analogue of `Challenge.lean`
is the theorem slate's statements — but ours are NOT zero-import:
they reach the generated semantics tree, so the statement-match
closure is the whole generated environment and the export/replay is
large. Feasibility experiment (S): export the relsem environment,
run comparator statement-match + axiom pinning on T1–T4's committed
statements, attempt nanoda replay; if nanoda chokes on scale, the
Lean-kernel-replay-from-empty half alone is already an independent
re-check of our in-build axiom gates from OUTSIDE our build. This is
a genuinely new gate class for us (all our current axiom gates run
inside the build being audited).

## 6. What maps to us vs what does not

Maps:
- Certificate discipline (§1), the ground-fact discharger + memo,
  the named-constant/state regime, fuel-robust statement shapes, the
  concrete-column whnf rule, budget-as-tripwire with measured
  per-site notes, the three-property trust vocabulary, comparator/
  nanoda as an external audit gate, the frontier-tag mechanism.
- Sociology maps too: same operator, same doctrine family
  (fail-closed, no-inference, bumps-are-defects, two-standard rule)
  — import friction is near zero.

Breaks:
- **Logic**: theirs is first-order, total, quantifier-free-ish over
  a deep-embedded untyped term language with a small trusted
  evaluator. Ours is dependent Lean + Iris: WP goals carry
  higher-order predicates, separation-logic contexts, and a monadic
  semantics. Nothing in ACL2Lean touches framing, ghost state, or
  invariants — the donor covers only the PURE/side-condition/
  kernel-computation stratum of our stack, i.e. exactly the part-2
  discharge engine, not the WP calculus (Iris/HeapLang + brick-wp
  remain the donors there).
- **Producer**: their certificates come from an instrumented FOREIGN
  oracle, hence the elaborate provenance/authenticity machinery. Our
  trace producer would be our own wp-tactic layer — authenticity
  collapses to ordinary code review, and half their gate surface has
  no analogue for us.
- **Congruence-per-arity**: their per-arity congruence lemma family
  works because SExpr application is uniform. Our per-construct law
  library (S3's `wpk_*` table) already plays this role at the right
  granularity; nothing to import.
- **Their evaluator is the semantics**; ours (the generated fuel
  opsem) is pinned to an external oracle by differential test. Their
  "interpreter divergence is definitionally a bug, differential-
  tested as a peer" discipline is the same as our oracle lanes —
  convergent evolution, nothing new to take.

## 7. Honesty check (thinner-than-docs findings)

The docs are the most self-deflating I have reviewed in this series —
the trust model repeatedly says what is NOT certified, the golden is
the status page, and the claims audit trail exists. Residual gaps,
for the record:

- **Breadth is small**: one sorting corpus + authored pattern books;
  116 replayed theorems, all first-order list/arithmetic; products
  are INSTANCE mirrors (at `Int`), order-generic capstone open
  (OVERVIEW § product layer — they say this themselves).
- **The statement comes from the untrusted log** (stage 5 "as wired
  today"); `gen-world` (source-side statement derivation) is built
  but NOT wired. Ruled a non-issue on the product path (user-written
  `Prop` + kernel covers it), but the METRIC layer's statements are
  anchored only by hand pins on "a handful of theorems; the rest are
  type/axiom-checked but compared to nothing" (their CLAUDE.md,
  stage 5).
- **Heartbeat practice diverges from our doctrine**: 82
  `maxHeartbeats` sites incl. `0`s (`bump-inventory.md` W8),
  `ReplayMain.lean:87` runs the CLI at `maxHeartbeats := 0`. Their
  own 2026-08-19 hygiene pass measured and pruned to a ruled policy
  (internal per-unit guards + unbounded book sums), which is
  coherent — but it is a WEAKER stance than our "default budget is
  the tripwire" rule, and their W8 self-assessment concedes the deep
  modules are exposed. Do not import the budget numbers, only the
  measured-per-site registration habit.
- **No replay-vs-oracle time comparison and no certificate-size
  data** (§3) — the "economics" story is internal-relative only.
- **This checkout cannot run the tool** (gitignored logs,
  uninitialized submodule) — expected fresh-clone state per their
  own docs, but it means every number above is from their records,
  not re-derived.

## 8. Verdict table

| Item | Verdict | Reason (one line) |
|---|---|---|
| `proveByDecide` + memo (Reflect.lean:93-120) | **LIFT** | Generic ~40-line MetaM ground-fact discharger; drop-in shape for wp-side-condition discharge with memoization we currently lack |
| Frontier-tag mechanism (Reflect.lean:79-91) | **LIFT** | ~15 lines; typed fail-closed frontiers classified by tag, not message text — exactly our fail-noisy doctrine, already implemented |
| `derive_world` named-constant pattern (DevQuery.lean:100-115) | **IMITATE** | The `derive_state`/`derive_core` answer to the S3 whnf park: reflect fixture-scale data once into `.abbrev` constants, goals reference by name |
| Concrete-column whnf rule + 200k-fixed-budget hazard (WorldTransport.lean:24-40) | **IMITATE** | Design rule for any reified symStep dispatch: concrete discriminant first, never generic equation lemmas of wide matches |
| Fuel-robust `∃N ∀f≥N` statement shape | **IMITATE** (partly have) | Keeps fuel out of certificates; our runner-observation algebra is the sibling — check part-2 trace atoms carry no fuel |
| Once-proved transport constants + decidable side conditions (WorldTransport/crossBookRegistry) | **IMITATE** | The addDecl-once-apply-O(1) + meta-precheck-before-kernel-decide economics pattern for repeated obligations |
| Certificate format discipline (record choice; recompute-and-check; provenance trailer) | **IMITATE** | The contract for our wp-trace/certificate-replay lane; extends the arc-11 app_walk emitter |
| comparator + nanoda external validation harness | **IMITATE** (S experiment) | Independent out-of-build re-check of statement match + axiom cones for the theorem slate; feasibility gated on export scale |
| Three-property trust vocabulary (soundness / authenticity / fidelity) | **IMITATE** | Sharpens PROOF.md's claim taxonomy at near-zero cost |
| Proof-producing over verified-checker verdict + L1 anti-monolith invariant | **IMITATE** (as lineage evidence) | Earned pivot record directly constraining part-2's "once-proved soundness" sketch |
| Heartbeat budget NUMBERS / `maxHeartbeats 0` policy | **IGNORE** | Weaker than our doctrine; keep only the measured-per-site registration habit |
| SExpr/evalOpt/Logic/congruence-lemma code | **IGNORE** | ACL2-semantics-specific; our per-construct law library already occupies this layer |
| Instrumented-producer provenance machinery (tags, hash sidecars, pins) | **IGNORE** | Solves foreign-oracle authenticity; our trace producer is in-repo |
| Mirror/waypoint/lifting layer (22.5K lines) | **IGNORE** | Statement-transport between value universes; our statements are natively in the target semantics |

## 9. Priced recommendation for the part-2 charter

What the verified-verifier / discharge-engine slice should take:

1. **Architecture verdict up front** (free — a charter paragraph):
   name ACL2Lean as the lineage for "once-proved fragment-local laws
   + untrusted orchestration emitting kernel-checked applications +
   kernel computation of ground side conditions over named reflected
   data", and cite their verified-rewriter → proof-producing pivot
   and L1 anti-monolith invariant as the evidence that a monolithic
   reified-derivation checker with one soundness theorem is the
   HIGHER-risk shape even in a far simpler logic. If part 2 still
   wants a deep-embedded checker for some fragment, that choice now
   needs post-exhaustion justification under canon-first.
2. **The `derive_state` constant emitter** (S, ~1–2 days): the
   `derive_world` pattern applied to fixtures — per-fixture named
   state/`core_file` constants (`.abbrev` + realizations), emitted
   by metaprogram, consumed by `wp_step`'s named-state regime. This
   is the S3 park's fix #1 with the donor's exact mechanism; saves
   the design iteration of discovering `.abbrev`/realization
   behavior by collision (their P3c record documents precisely which
   naive routes die and why).
3. **`proveByDecide` + memo as the side-condition engine** (S,
   ~half a day): replaces the bare `assumption | rfl | decide` in
   `wp_side`, adds the memo that their measurement shows matters at
   corpus scale (3,869 repeat decisions on one theorem).
4. **Trace/certificate format spec** (S, ~1 day of writing): adopt
   §1's contract for the wp-trace lane (choice-not-derivation, typed
   frontiers, recompute-and-check, no fuel in atoms).
5. **Comparator/nanoda feasibility probe** (S, timeboxed ~1 day,
   operator-gated on network for tool fetch or mirror): export +
   statement-match + axiom-pin T1–T4; report scale numbers before
   deciding whether it becomes a standing gate.

**Estimated saving vs building cold**: modest in code (the liftable
code is ~100 lines), large in avoided design risk — the donor has
already run three architectures to a measured verdict on the exact
axis part 2 must choose on, has field notes on the two kernel-cost
cliffs we would otherwise rediscover by collision (fixed whnf budget
in equation generation; kernel depth needing tstack), and has a
worked, negatively-controlled external-validation harness whose
setup cost (tool pins, landrun-in-sandbox, challenge-file
consequences like module-name embedding in private constants) is
maybe 2–3 days of trial-and-error we skip. Call it ~1–2 weeks of
avoided iteration across the slice, concentrated in items 1–2.
