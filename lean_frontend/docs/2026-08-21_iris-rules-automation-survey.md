# Iris-line proof rules and automation: imports for the Cerberus-Lean workbench

Date: 2026-08-21

Status: v1 research report. This is a design survey, not an authorization to
change the proof layer. It assesses the T5 worktree based at `b44bbdfbf`, the
pinned `iris-lean` commit `34390a0133986385c62bf59a6eb01938945b48ec`, and
the vendored RefinedC commit `25f706d417df2b18b23c5cbadde46468c1b1262c`.

## Executive decision

The workbench should not import a second C semantics, a refinement-type
front-end, or a large relational logic in order to finish T5. Its current
architecture is already unusually close to the best transferable part of
RefinedC/Lithium and Islaris:

- rules are ordinary proved lemmas;
- dispatch is deterministic and goal-directed;
- semantic obligations are exposed rather than guessed;
- the final theorem remains an interpreter-only proposition; and
- aggressive proof search ends in ordinary, kernel-checked certificates.

The highest-value v2 work is narrower:

1. Separate discovery from certificate replay explicitly, using a small trace
   language and a mandatory checked replay mode. Yolo, a July 2026 Lean paper
   instantiated for Iris-Lean, is direct evidence for this architecture.
2. Finish the loop algebra already planned locally: variable-cost and early-exit
   composition, with named guard/body/exit cutpoints.
3. Extend law applicability from “goal head matches” to “goal head plus a
   deterministic query of relevant facts in the local proof state”. This is the
   largest useful delta from Lithium, Islaris, and Diaframe.
4. Introduce one checked call-interface shape and one call-composition rule
   before multi-TU work. Melocoton's predicate-transformer interfaces and
   BRiCk's `CallReady` layer are the useful patterns; their semantics and ghost
   layers are not.
5. Add collection views and element extraction/reassembly rules before arrays.
   CN, Islaris, RefinedC, Yolo, and the existing `bigSepM2` port all point in the
   same direction.

Later credits and fuel are not substitutes for each other. Later credits are a
logical resource for eliminating guarded propositions; fuel bounds execution.
They are orthogonal. Nevertheless, later credits are already in the pin and do
not shorten T5 because the current `OwnP` instance assigns zero laters per
physical step and treats one interpreter application as an atomic step.
Likewise, finite fuel does not subsume Transfinite Iris: a family of bounded
finite-execution theorems is not a liveness or termination-preserving refinement
theorem. Transfinite machinery is simply outside the present statement and
slate.

For the queued executable-versus-axiomatic concurrency comparison, investigate
Trillium before Simuliris if the desired relation is “implementation trace
refines an abstract model trace”. Use Simuliris if the problem is genuinely a
bilateral source/target simulation with source undefined behavior. Neither is a
T5 dependency, and either would be a large new layer.

## Evidence and scope

Claims are tagged as follows:

- **[P]** read from the cited paper;
- **[C]** read from source code in this workspace;
- **[A]** abstract, project page, or publisher metadata only;
- **[D]** local project documentation;
- **[I]** inference or recommendation made in this report.

The paper bundle is in
[`papers/iris-litreview-2026-08-21/`](papers/iris-litreview-2026-08-21/).
The folder is covered by the repository's existing `/lean_frontend/docs/papers/`
ignore rule. BRiCk has no research paper that I could identify; its entry below
is therefore code/documentation evidence only.

The 2023–2026 venue sweep was relevance-filtered rather than a bibliography of
everything built on Iris. I checked the Iris publication index and targeted
POPL, PLDI, ICFP, OOPSLA, CPP, CAV, and ITP searches. I retained work that adds
a proof rule, automation architecture, certificate technique, or directly
reusable representation/composition pattern for the stated slate. Protocol,
distributed-systems, persistent-memory, probabilistic, and domain-specific
concurrency papers without such a delta are outside this report; the separate
weak-memory survey covers that concurrency line in more depth. **[A,I]**

The “would it shorten T5?” test is applied literally:

- **T5-now** means the still-active first-loop proof;
- **next** means nested loops, arrays, early exit, and call composition;
- **later** means real libxml2/allocator code or concurrency; and
- **no** means the item is intellectually relevant but not workbench leverage.

## 1. What the workbench already has

The local evidence is important because several apparent literature gaps have
already been closed.

| Capability | Local status | Consequence |
|---|---|---|
| Goal-directed rule registry | `@[app_eq]` is a scoped environment extension backed by `DiscrTree`; rule variables become wildcards and specificity/priority orders candidates. **[C]** | Do not replace it with Rocq typeclass search. Add richer applicability around this index. |
| Kernel-aware discovery | The walker uses kernel WHNF to expose redexes before law lookup and guards dispatch by the actual equality goal. **[C]** | This is stronger than a syntax-only port of Lithium's fixed tactic cascade. |
| Small certificates | The current emitter seals each round, builds fieldwise state bridges, proves scalar leaves separately, and avoids giant unary `Nat.div` reductions; the 21-round T5 entry block kernel-checks in about five seconds at `b44bbdfbf`. **[C,D]** | Certificate structure, not just search time, is a first-class design constraint. |
| Loop composition | `iter_compose_from` and `iter_compose` are pure `Nat`-induction/transitivity theorems over a closed-form state family. They are deliberately not registered because the invariant cannot be inferred from the goal. `_exit` and `_var` remain planned. **[C]** | The human-chosen invariant boundary is correct; automate its body, not its invention. |
| Iris bridge | `OwnP.lean` contains `ownP_adequacy`, invariance, and deterministic atomic/pure lifting rules. The `OwnPGS` instance uses `numLatersPerStep _ := 0`. **[C]** | The current application-equation route already has the right clean adequacy seam. |
| Recent Iris core | Later credits, total WP/adequacy, least fixpoints, `bigSepM2`, full proof mode, and a DiscrTree-backed proof-mode instance synthesizer are present at the pin. **[C]** | These are not candidate ports. Missing work is automation and domain rules around them. |
| Measured payoff | T1–T4 contain 5,966 Layer-2 hand-proof lines; the calibration replaced an approximately 700-line segment by five tactic lines with two explicit semantic steps. **[D]** | Any v2 item should beat a very strong loop-free baseline rather than merely reduce cosmetic syntax. |

## 2. RefinedC/Lithium against `app_walk`

The [RefinedC paper](https://plv.mpi-sws.org/refinedc/paper.pdf)
([local PDF](papers/iris-litreview-2026-08-21/2021-refinedc.pdf)) presents
Lithium as a restricted separation-logic language supporting predictable,
goal-directed proof search without backtracking. **[P]** The vendored code is
more informative than that slogan.

| Dimension | Lithium / RefinedC | Current workbench | Import decision |
|---|---|---|---|
| Rule language | Typing and ownership rules are lemmas whose premises are normalized into a restricted family of Lithium connectives. **[P,C]** | Computed-RHS equality lemmas reduce one interpreter form to the next; semantic premises remain ordinary Lean goals. **[C]** | Keep the equality language. A wholesale Lithium DSL would duplicate the authoritative interpreter and contaminate the useful statement boundary. |
| Main strategy | `liStep` is an explicit ordered cascade: user tactic, extensible rules, separation, conjunction, wand, quantifiers, side conditions, context lookup, cases, modalities, and terminal forms. **[C]** | The walker normalizes, queries a conclusion-LHS `DiscrTree`, tries most-specific laws, and stops at semantic boundaries. **[C]** | Import the explicit phase taxonomy as metadata/diagnostics, not the Rocq implementation. |
| Applicability | Rule classes use input/output modes and typeclass hints; `FindInContext` queries the spatial context by a key. `liSep` first looks for exact context matches, then safe simplification, related/subsumption rules, and generic simplification. **[C]** | Applicability is primarily the goal's LHS plus theorem unification; facts are solved after rule selection. **[C]** | Add an optional context-query/applicability witness to `@[app_eq]` laws. This is the most important missing feature. |
| Choice policy | The paper's architecture avoids proof-search backtracking. The current source still has a bounded `rep <- n` combinator, so “never backtracks” is not literally true of every modern Lithium tactic. **[P,C]** | Deterministic priority/specificity; semantic obligations are explicit. **[C]** | Preserve deterministic default behavior. If bounded alternatives are ever added, expose the bound and the chosen rule in the trace. |
| Side conditions | Pure obligations can be shelved and solved separately; the interpreter distinguishes decomposition from side-condition solvers. **[C]** | The laws-only/semantic-obligation split stops cleanly but lacks a uniform typed residual inventory. **[C]** | Add residual classes (`semantic`, `arithmetic`, `defeq bridge`, `missing law`) and stable reporting. Do not silently invoke a broad solver. |
| Performance discipline | The source uses scoped opacity, `change_no_check`, `notypeclasses refine`, specialized bridge lemmas, controlled environment lets, and avoidance of expensive unification. Comments record even 1–2% micro-optimizations. **[C]** | Kernel-WHNF discovery and per-stage proof assembly directly address Lean's elaborator/kernel recursion behavior. **[C]** | Import the measurement discipline, not Rocq primitives. Maintain separate discovery, elaboration, and kernel-check budgets. |
| Certificate production | Lithium applies proved lemmas while interpreting the goal, so ordinary Rocq proof terms are produced. **[P,C]** | The emitter already learned that one large proof term is unacceptable and decomposes rounds/leaves into named obligations. **[C]** | Go one step further: record a compact discovery trace and replay it into the existing small-certificate emitter. |
| Statement shape | RefinedC translates annotated C into a deep Caesium program and proves semantic typing/ownership specifications. This is foundational, but the generated program and specification are part of its proof-facing statement. **[P,C]** | The final theorem quantifies over the Cerberus interpreter only; Iris and workbench artifacts disappear through adequacy. **[D]** | Treat Caesium as a contrast. Do not import its front-end or statement shape. |

Bottom line: `app_walk` already has Lithium's central insight—design rules for a
deterministic interpreter—but its rule lookup is more syntactic than Lithium's
full proof-state search. The v2 delta is a small, indexed context query and a
typed residual protocol, not “port Lithium”.

## 3. Per-paper findings

### 3.1 Core automation and authoritative-semantics relatives

| Work | Proof rules contributed | Automation / certificate architecture | Statement shape and portability | Verdict and slate impact |
|---|---|---|---|---|
| **RefinedC + Lithium**, PLDI 2021 ([paper](https://plv.mpi-sws.org/refinedc/paper.pdf), [PDF](papers/iris-litreview-2026-08-21/2021-refinedc.pdf)) | Ownership/refinement typing rules, function specifications, subsumption, context lookup, array/struct resource rules. Rules are deliberately shaped as Lithium premises. **[P,C]** | Restricted goal language; ordered deterministic interpreter; typeclass-indexed rules; controlled context search; side-condition shelving; extensive Rocq performance engineering. **[P,C]** | Foundational, but its deep Caesium term and refined type/spec are proof-facing. Code is deeply Rocq/Ltac/IPM-specific; the architecture is portable. **[P,C]** | **IMPORT-DESIGN.** Context-keyed applicability and residual classes shorten arrays/calls; no wholesale port and limited T5-now gain. |
| **Islaris**, PLDI 2022 ([paper](https://www.cl.cam.ac.uk/~jp622/islaris.pdf), [PDF](papers/iris-litreview-2026-08-21/2022-islaris.pdf)) | Rules walk authoritative Isla traces, represent registers as collections, expose memory/code-pointer resources, and use a code-address assertion for reusable block/function specs. Loop proofs use step-indexed recursive assumptions. **[P]** | Adapts Lithium. Deterministic `findR(r)` and `findM(a)` queries replace nondeterministic resource choice; symbolic Isla/SMT simplifies traces before Rocq; optional translation validation checks that simplification. The paper separately reports automation and final `Qed` time. **[P]** | Closest trust-shape relative: the final result is about the authoritative trace semantics; Iris is discharged by adequacy. Its Isla trace language and Rocq tactics are not portable, but address/register lookup and checked trace simplification are. **[P,I]** | **IMPORT-RULE/DESIGN.** Add keyed state/resource lookup, code-address/callee specs, and separate proof-check metrics. Directly useful for arrays/calls; trace replay may help T5-now. |
| **Diaframe 2.0**, OOPSLA 2023 ([paper](https://iris-project.org/pdfs/2023-oopsla-diaframe2-final.pdf), [PDF](papers/iris-litreview-2026-08-21/2023-diaframe2.pdf)) | General rule formats encode current goal, successor goal, and optionally required logical state; abduction and transformer hints support framing and logical atomicity. **[P]** | Minimizes backtracking, selects rules from both program and logical state, supports “near-applicability” under connectives, and keeps feature modules declarative. Proof rules and automation are foundationally justified. **[P]** | Rocq typeclasses and proof-mode tactics need redesign in Lean. The pinned proof mode already has a custom DiscrTree instance engine, so the indexing substrate exists. **[C,I]** | **IMPORT-DESIGN.** Add required-fact patterns and near-applicability only after the simple context query. Strong next-slate value; little pure T5-now value. |
| **CN**, POPL 2023 ([paper](https://www.cl.cam.ac.uk/~cp526/popl23.pdf), [PDF](papers/iris-litreview-2026-08-21/2023-cn.pdf)) | First-class resources, iterated separating-conjunction resource inference, pointer arithmetic rules, and a syntactic restriction on ghost variables that guarantees their inference. **[P]** | Predictability comes from reducing refinement typing to decidable propositional reasoning and restricting specification syntax; automation uses external solvers in the deployed tool. **[P,C]** | Cerberus-native, but not the project's desired proof boundary: it adapts/abstracts the C semantics and its solver/tool chain is not an ordinary Lean-kernel certificate path. **[P,C,I]** | **IMPORT-DESIGN.** Copy ghost-variable modes and collection-resource inference ideas only. Useful for arrays/allocator code; do not copy the trust story or statement language. |
| **VST-A**, POPL 2024 ([paper](https://www.cs.princeton.edu/~appel/papers/vst-a.pdf), [PDF](papers/iris-litreview-2026-08-21/2024-vst-a.pdf)) | A proved control-flow splitting reduction turns an annotated CFG into straight-line Hoare obligations at assertion cutpoints, including loops and non-structural control flow. **[P]** | One foundational reduction performs structural proof decomposition; annotations retain the key human insights while ordinary VST/Rocq proves the residuals. **[P]** | CompCert/Clight/VST details are not portable. The checked “cutpoint plan to smaller obligations” pattern is highly portable and need not alter final statements. **[P,I]** | **IMPORT-DESIGN.** Build a pure, checked block/cutpoint plan over generated Cerberus labels. Medium cost; strong for nested loops and early exit, modest for T5-now. |
| **Yolo: Lazy Proof Automation for Separation Logic**, ITP 2026 ([paper](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2026.6), [PDF](papers/iris-litreview-2026-08-21/2026-yolo.pdf)) | Consequence-frame and heap-entailment simplification: flattening, pure extraction, existential handling, wand application, and cancellation. Operator behavior and reconstruction lemmas are separately extensible. **[P]** | A fast unverified Lean simplifier records a tactic trace; checked mode later replays/reconstructs ordinary proof terms. It uses a mixed shallow/deep representation, list-normalized spatial contexts, and typeclass-extensible operators. The paper instantiates it for Iris-Lean's MoSeL interface and reports interactive and replay time separately. **[P]** | Lean-native and the most portable item in this survey. It is not present in the pin. Unverified mode is only a development preview; acceptance still requires reconstruction and kernel checking. **[P,C]** | **IMPORT-DESIGN, highest priority.** Use a trace/replay split for `app_walk`; reuse Yolo itself later for large Iris resource entailments. Direct T5-now interactive benefit and strong future certificate benefit. |

### 3.2 Loop, call, component, and relational composition

| Work | Proof rules contributed | Automation / certificate architecture | Statement shape and portability | Verdict and slate impact |
|---|---|---|---|---|
| **Simuliris**, POPL 2022 ([paper](https://iris-project.org/pdfs/2022-popl-simuliris.pdf), [PDF](papers/iris-litreview-2026-08-21/2022-simuliris.pdf)) | Source/target focusing, framing, bind rules, source-UB exploitation, and two while rules: coinductive and parameterized-coinductive variants. Postconditions on expressions permit a proof to stop at a recurrence point. It proves fair termination preservation. **[P]** | Mostly interactive Iris reasoning; parameterized coinduction packages the recurrence invariant. **[P]** | It uses a non-step-indexed Iris variant/global invariant rather than the standard pinned program logic. Porting is a large foundational project. **[P,C]** | **IMPORT-RULE, later only.** Its recurrence-point presentation can inform `_exit`/`_var`; the relational logic is for the future source/target concurrency case, not T5. |
| **Melocoton**, OOPSLA 2023 ([paper](https://iris-project.org/pdfs/2023-oopsla-melocoton.pdf), [PDF](papers/iris-litreview-2026-08-21/2023-melocoton.pdf)) | Internal-call rules and an external-call rule parameterized by an interface `function -> arguments -> postcondition -> precondition`; interface implementation, consequence, and linking compose language-local proofs. It handles calls, callbacks, shared representations, and GC. **[P]** | Language-local symbolic proofs skip an external call at its interface and resume from the specified postcondition. **[P]** | Its centralized multi-language semantics uses angelic/demonic multi-relations. Adequacy needs Transfinite Iris to replay step-index-dependent angelic choices. This is far larger than same-language Cerberus call composition. **[P]** | **IMPORT-RULE SHAPE.** Adopt the predicate-transformer call interface and link theorem shape, not Melocoton's semantics. Strong call/multi-TU value; no T5-now value. |
| **DimSum**, POPL 2023 ([paper](https://pub.ista.ac.at/~msammler/paper/dimsum.pdf), [PDF](papers/iris-litreview-2026-08-21/2023-dimsum.pdf)) | Refinement is compositional horizontally and vertically; language-specific link operators, wrappers, and compiler-correctness rules connect modules. Wrappers translate call/return and jump protocols while maintaining a world relating memories/addresses. **[P]** | Proof is organized around reusable module/link/wrapper combinators rather than a symbolic-execution tactic. Angelic and demonic choices encode assumptions and guarantees. **[P]** | Decentralized module semantics is attractive for true cross-language linking, but introducing event modules/wrappers into current theorem statements would violate the immediate pristine-statement goal. **[P,I]** | **IMPORT-DESIGN, later.** First build a same-semantics callee-block rule. Revisit wrappers only for ABI/cross-language theorems. |
| **Trillium**, POPL 2024 ([paper](https://iris-project.org/pdfs/2024-popl-trillium.pdf), [PDF](papers/iris-litreview-2026-08-21/2024-trillium.pdf)) | A language-generic refinement connective relates program traces to abstract model traces, permits stuttering, and transfers safety/liveness under stated fairness conditions. **[P]** | Conservative extension of Iris WP with one refinement-aware step rule; user supplies a state/trace interpretation. **[P]** | Cleaner match than Simuliris when one concrete executable semantics is related to an axiomatic/model transition system. Not present in the pin and requires substantial program-logic/adequacy work. **[P,C,I]** | **IMPORT-RULE, large/later.** First candidate for executable-versus-axiomatic concurrency equivalence; no T5 impact. |
| **A Recipe for Modular Verification of Generic Tree Traversals**, CPP 2026 ([paper](https://iris-project.org/pdfs/2026-cpp-tree-traversals.pdf), [PDF](papers/iris-litreview-2026-08-21/2026-tree-traversals.pdf)) | A zipper is the abstract traversal state; a client-chosen invariant is preserved across action and silent zipper transitions. One blueprint covers pre/in/post order, early abort, structure-changing, array-backed, and variadic trees. **[P]** | RefinedC automates action transitions through calls and uses spatial-context pattern matching for parameters; silent transitions need dedicated hints. The client still supplies the invariant. **[P]** | Rocq/RefinedC implementation is not portable, but the zipper/state-family rule fits `iter_compose` exactly. It is more relevant to future libxml2 traversals than to the first scalar loop. **[P,I]** | **IMPORT-RULE, later.** Add a zipper-indexed composition kit when tree traversal enters the slate; do not generalize T5 around it now. |

### 3.3 Iris-core additions and the recent sweep

| Work | Proof rules contributed | Automation / certificate architecture | Statement shape and portability | Verdict and slate impact |
|---|---|---|---|---|
| **Later Credits**, ICFP 2022 ([paper](https://plv.mpi-sws.org/later-credits/paper-later-credits.pdf), [PDF](papers/iris-litreview-2026-08-21/2022-later-credits.pdf)) | Makes the right to eliminate a later an ownable, splittable resource; supports prepaid invariants and proof patterns needing multiple eliminations per physical step. **[P]** | Proof-mode/library rules manage credits; this is logic infrastructure, not program-walker automation. **[P]** | Already ported in `Iris/Instances/Lib/LaterCredits.lean`. Current `OwnP` produces zero laters per step. **[C]** | **ALREADY-HAVE.** Orthogonal to fuel and irrelevant to T5's coarse atomic step; reconsider for nested ghost abstractions/concurrency. |
| **Transfinite Iris**, PLDI 2021 ([paper](https://iris-project.org/pdfs/2021-pldi-transfinite-iris-final.pdf), [PDF](papers/iris-litreview-2026-08-21/2021-transfinite-iris.pdf)) | Ordinal step indices enable witness extraction and proofs of termination and termination-preserving refinement that finite step indexing cannot support. **[P]** | Foundational change to the Iris model, not a tactic extension. **[P]** | Absent from the pin; porting would be very large. Finite fuel does not logically subsume it, but current theorems intentionally state bounded interpreter behavior rather than liveness. **[C,I]** | **IRRELEVANT-TO-CURRENT-SLATE.** Reconsider only if an unbounded liveness/refinement theorem becomes a declared target. |
| **Building Blocks for Step-Indexed Program Logics**, CPP 2026 ([paper](https://iris-project.org/pdfs/2026-cpp-step-modality.pdf), [PDF](papers/iris-litreview-2026-08-21/2026-step-modality.pdf)) | A physical-step modality abstracts later generation/elimination and subsumes several project-specific flexible-step/later-credit disciplines; demonstrated in Actris, RefinedRust, Perennial, and Trillium. **[P]** | Modular program-logic infrastructure reduces repeated metatheory, not symbolic-execution search. **[P]** | Not present in the pin. Current `OwnP`/application semantics has no multiple-later pressure. **[C]** | **IRRELEVANT-TO-CURRENT-SLATE / upstream candidate later.** Valuable if concurrency or finer physical-step granularity exposes the problem. |
| **Inductive Predicates via Least Fixpoints**, ITP 2025 ([paper](https://iris-project.org/pdfs/2025-itp-inductive.pdf), [PDF](papers/iris-litreview-2026-08-21/2025-inductive-predicates.pdf)) | Monotone least fixpoints define nested representation predicates and a total WP without laters; an `Iris Inductive` command generates fold/unfold/induction support and monotonicity obligations. **[P]** | The user-facing generator is Rocq-Elpi and duplicates some proof-mode plumbing; the paper labels it a prototype. **[P]** | The pin already contains `bi_least_fixpoint`, total WP/lifting/adequacy, and related laws, but not the Elpi-style command. Ordinary Lean datatypes/recursive state families cover current needs. **[C]** | **ALREADY-HAVE core; PARK generator.** Potential ergonomic port for recursive heap predicates, not a T5 item. |
| **RefinedRust**, PLDI 2024 ([paper](https://iris-project.org/pdfs/2024-pldi-refinedrust.pdf), [PDF](papers/iris-litreview-2026-08-21/2024-refinedrust.pdf)) | Refined ownership rules for Rust places, mutable/shared references, lifetimes, and unsafe code; later credits support layered higher-order ghost abstractions. **[P]** | Reuses Lithium's deterministic foundational automation with a Rust-specific front-end and Radium semantics. **[P]** | RustBelt lifetime logic and Radium are irrelevant to Cerberus C statements. The transferable automation is already covered by Lithium; later credits already exist. **[P,C]** | **ALREADY-HAVE / IRRELEVANT type rules.** No T5 or near-slate import. |
| **Modular Verification of Intrusive List and Tree Data Structures**, ITP 2024 ([paper](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2024.19), [PDF](papers/iris-litreview-2026-08-21/2024-intrusive-data-structures.pdf)) | A representation predicate separates intrusive node topology from client-attached data; verified node operations are reused to build cyclic/doubly-linked lists and search trees. **[P]** | Uses Diaframe's goal-directed automation with only small pointer-arithmetic extensions; cyclic structures still require deliberate predicate unfolding and rotation. **[P]** | Mechanized over HeapLang rather than C, so it supplies a representation discipline, not Cerberus step laws. The topology/data split is portable to allocator free lists and libxml nodes. **[P,I]** | **IMPORT-DESIGN, later.** Fold the split into collection/structure views; no T5 effect, strong real-code relevance. |
| **Quiver**, PLDI 2024 ([paper](https://iris-project.org/pdfs/2024-pldi-quiver.pdf), [PDF](papers/iris-litreview-2026-08-21/2024-quiver.pdf)) | Guided abductive/deductive inference completes user specification sketches, inferring spatial resources, refinements, and existential witnesses; it can infer allocator, vector, list, buffer, and partial functional specs. **[P]** | Foundational Rocq implementation; user sketches constrain the search. Inference is much broader and costlier than deterministic rule application. **[P]** | Inferred specs must never become the accepted final theorem accidentally. It is portable only as a development assistant whose output is reviewed and kernel-checked. **[I]** | **IMPORT-DESIGN, PARK.** Consider for invariant/spec suggestions after arrays/calls are stable; not for T5's already-known invariant. |
| **Daenerys / Destabilizing Iris**, PLDI 2025 ([paper](https://iris-project.org/pdfs/2025-pldi-daenerys.pdf), [PDF](papers/iris-litreview-2026-08-21/2025-daenerys.pdf)) | Unstable resources and heap-dependent expression assertions support stronger automated reasoning; this modifies framing/logic infrastructure and connects to SMT-oriented automation. **[P]** | Requires a redesigned logic and automation interface rather than a local derived-rule kit. **[P]** | Absent from the pin and in tension with the goal of keeping the existing Iris bridge small and statement-transparent. **[C,I]** | **IRRELEVANT-TO-US now.** Large foundational cost with no T5/near-slate payoff. |

### 3.4 BRiCk/brick-wp delta

No published BRiCk paper was found. The public
[repository](https://github.com/SkyLabsAI/BRiCk) and local
`deps/brick-wp` tree are therefore **[C,D]**, not paper evidence.

The prior workbench survey already extracted its tactic taxonomy. Only three
deltas remain worth carrying forward:

- `CallReady` packages client-side call chaining around a sealed callee
  specification. This reinforces the Melocoton-inspired call-interface item.
- `NdUnits` collapses C++ evaluation-order nondeterminism using one contract per
  operand/unit. It should stay shelved until a Cerberus fixture exposes genuine
  multi-order `pick` behavior; singleton picks do not justify the layer.
- `GhostModules` provides exclusive registries and capacity credits. No current
  T5/near-slate theorem needs a dynamic module/object registry.

Verdict: **ALREADY-MINED**. Import the call-readiness shape when calls arrive;
do not port the Rocq library or invent traffic for its other abstractions.

## 4. Workbench v2 import slate

Pricing is implementation effort after design agreement, not elapsed research
time: **S** is roughly 1–3 focused days, **M** is roughly 1–2 weeks including
fixtures and kernel-budget validation, and **L** is a multi-week/month-scale
logic or semantics project.

| Rank | Import | Price | Concrete shape | Would it shorten T5 / next slate? | Acceptance gate |
|---:|---|:---:|---|---|---|
| 1 | **Discovery trace + mandatory checked replay** (Yolo) | S | Define a compact trace containing normalization decisions, selected law/name, instantiated arguments, semantic residuals, sealing boundaries, and leaf-evaluation steps. Preview mode may compute the trace without building proofs; checked mode replays it through the existing per-stage emitter. | **T5-now: yes**, mainly interactive latency and reproducibility. Next: yes, by preventing search/certificate complexity from growing together. | Preview output can never close or cache a theorem accepted by CI. Replay must emit ordinary proof terms and the existing axiom/proof-size gates must remain green. Measure discovery, elaboration, and kernel checking separately. |
| 2 | **Finish the pure loop rule family** | S | Add `iter_compose_var` for per-iteration cost and `iter_compose_exit` for a sum type/exit index; factor named guard, body, continue, and exit equations. Keep the state family explicit and rules unregistered. | **T5-now: yes** if the remaining loop path needs exit/fuel variation. Nested loops/early exits: directly. | Rules are pure equality/transitivity/induction theorems with no semantics axioms. At least one symbolic-`n` and one early-exit fixture must kernel-check without expanding all rounds. |
| 3 | **Context-indexed law applicability and typed residuals** (Lithium, Islaris, Diaframe) | S/M | Extend law metadata with an optional required-fact key/query and result class. Query local hypotheses deterministically by head/address/identifier; then instantiate the law. Report residuals as semantic, arithmetic, defeq bridge, ambiguous law, or missing law. | T5-now: possibly small. **Arrays, memory, and calls: yes**, because the correct rule often depends on an address, object, guard fact, or callee spec already in context. | No general proof search or silent backtracking. A trace records every candidate considered and why it failed. Ambiguity is an error unless resolved by explicit priority. |
| 4 | **Checked cutpoint/block plan** (VST-A) | M | Reify only generated control-flow labels and proposed cutpoints, not the semantics. Prove once that composing verified block equations along a valid plan yields the whole application equation. User supplies invariants at loop headers; the walker fills straight-line edges. | T5-now: modest. **Nested loops and early exit: strong**; makes proof structure scale with semantic cutpoints instead of generated syntax. | The plan is untrusted data. A small pure checker theorem validates it, and all block edges remain ordinary `app` equations. No annotation enters final theorem statements. |
| 5 | **Callee-block interface and call composition** (Islaris, Melocoton, BRiCk) | M | Define a sealed internal shape analogous to `CallReady`: pure precondition -> callee application equation -> pure postcondition, plus one rule for a call round to consume it. Allow the spec to be a local hypothesis for recursion. | T5-now: no. **Call composition and multi-TU: direct**, likely the decisive next-slate item after loops/arrays. | Prove a same-semantics call composition theorem first. No event-module, FFI wrapper, or ghost registry until a fixture requires it. Final adequacy still eliminates the interface. |
| 6 | **Collection/structure view + deterministic extraction/reassembly** (Islaris, CN, RefinedC, Yolo, intrusive structures) | M | Give arrays/maps a canonical logical/pure state-family view; index lookup produces an element obligation and a reconstruction equation. For intrusive structures, separate topology from client-attached data. Reuse `bigSepM2` only where spatial Iris ownership is genuinely present; use pure list/map equations in Layer 2 otherwise. | T5-now: no. **Arrays and allocator/libxml buffers/nodes: direct.** | Do not force separation-logic resources into the interpreter-only equality layer. Demonstrate constant proof-script growth across at least three array lengths and one topology/data fixture while kernel terms remain staged. |
| 7 | **Zipper-indexed traversal kit** (CPP 2026 tree traversal recipe) | M | When a real tree walker is selected, represent traversal progress by a zipper state family and separate action transitions from silent zipper transitions. Reuse the same composition skeleton for early abort and array-backed trees. | T5/near slate: no. **Real libxml2 tree walks: strong.** | Defer until a concrete function is selected. The abstract zipper must refine the actual interpreter state through proved equations, not replace it in the theorem statement. |
| 8 | **Relational concurrency layer: Trillium first, Simuliris second** | L | Prototype one tiny finite program/model trace relation through the existing concurrency seam. Choose Trillium for implementation-to-model trace refinement; choose Simuliris for bilateral source/target simulation and source UB. | T5 and sequential slate: no. **Queued concurrency equivalence: direct.** | Separate project charter. Must end in Cerberus behavior/refinement propositions, identify fairness assumptions, and prove adequacy. Do not block sequential workbench evolution. |

### Explicit non-imports

- Do not port Caesium/Radium or put a refined type/spec language into final
  Cerberus theorem statements.
- Do not use `native_decide`, an external solver result, an unverified Yolo
  preview, or a generated CFG plan as the reason Lean accepts a theorem.
- Do not add backtracking merely because current Lithium source contains a
  bounded helper; deterministic, inspectable failure is a workbench advantage.
- Do not adopt Transfinite Iris, the physical-step modality, Daenerys, or a
  full relational logic in anticipation of needs absent from the present slate.
- Do not attempt automatic loop-invariant invention in v2. RefinedC, the 2026
  traversal recipe, and the current `iter_compose` design all retain a human
  invariant boundary.

## 5. Gaps in the pinned `iris-lean`

### Worth upstreaming or packaging now

1. **Generic lazy entailment simplification for MoSeL/Iris-Lean.** Yolo already
   demonstrates this outside the pin. The useful upstream question is whether
   its generic operator interfaces and reconstruction lemmas should become an
   optional Iris-Lean package or remain a separate dependency. It would matter
   once array/call proofs generate large spatial entailments. **[P,C,I]**
2. **A language-parametric WP tactic shell.** The pin's WP tactics are largely
   under `HeapLang/ProofMode.lean`; the generic program logic and `OwnP` lifting
   theorems exist, but there is no small generic registry for a client language's
   primitive WP rules. A reusable shell should expose goal parsing, rule
   indexing, masks, and residual obligations while leaving Cerberus-specific
   rules downstream. **[C,I]**

### Worth tracking, not blocking on

3. **Physical-step modality.** The CPP 2026 construction is absent. It is a
   sensible upstream target if `OwnP` later needs multiple later eliminations or
   concurrency introduces finer physical steps. **[P,C]**
4. **User-facing inductive-predicate generator.** The least-fixpoint foundation
   and total WP already exist, but there is no Lean analogue of the prototype
   `Iris Inductive` command. This is ergonomic, not a foundational gap, and
   ordinary Lean definitions are preferable until recursive spatial predicates
   become repetitive. **[P,C]**

### Separate large libraries, not core-gap tickets

5. **Trillium/Simuliris-style relational program logic.** Neither is present,
   but adding one is a new logic and adequacy development rather than filling a
   missing utility in Iris-Lean. **[C,I]**
6. **Transfinite Iris.** Absent and genuinely different foundational machinery.
   It should be justified by a declared liveness/witness-extraction theorem, not
   by the existence of loops. **[P,C,I]**

### Confirmed non-gaps at `34390a0133`

- later credits and their fancy-update integration;
- `OwnP` adequacy/invariance and deterministic lifting rules;
- total weakest precondition, total lifting, and total adequacy;
- BI least fixpoints and relation closures;
- `bigSepM2` and its map laws;
- proof-mode Löb induction, invariants, big operators, and the standard IPM
  tactics; and
- a scoped, prioritized DiscrTree-based instance registry for proof mode.

## 6. Recommended execution order

For the current branch, the shortest path is:

1. finish T5 with the current emitter and existing explicit state family;
2. land the small loop variants only when the proof reaches the corresponding
   exit/variable-fuel shape;
3. extract a trace IR from actual emitter events and add checked replay;
4. exercise the trace/replay and context-query design on one array and one
   early-exit fixture;
5. add the callee-block interface on the first real call fixture; and
6. only then generalize into cutpoint plans and higher-level collection views.

This sequencing keeps every abstraction demand-driven. It also preserves the
workbench's strongest result so far: proof engineering can be aggressive, but
the exported theorem remains an ordinary proposition about the authoritative
Cerberus interpreter, checked by the Lean kernel.

## References and local paper inventory

- Sammler et al., “RefinedC: Automating the Foundational Verification of C Code
  with Refined Ownership Types,” PLDI 2021,
  [DOI](https://doi.org/10.1145/3453483.3454036).
- Pulte et al., “Islaris: Verification of Machine Code Against Authoritative
  ISA Semantics,” PLDI 2022,
  [DOI](https://doi.org/10.1145/3519939.3523434).
- Gäher et al., “Simuliris: A Separation Logic Framework for Verifying
  Concurrent Program Optimizations,” POPL 2022,
  [DOI](https://doi.org/10.1145/3498689).
- Spies et al., “Later Credits: Resourceful Reasoning for the Later Modality,”
  ICFP 2022, [DOI](https://doi.org/10.1145/3547631).
- Spies et al., “Transfinite Iris,” PLDI 2021,
  [project](https://iris-project.org/transfinite-iris/).
- Sammler et al., “DimSum: A Decentralized Approach to Multi-language
  Semantics and Verification,” POPL 2023,
  [paper](https://pub.ista.ac.at/~msammler/paper/dimsum.pdf).
- Guéneau et al., “Melocoton: A Program Logic for Verified Interoperability
  Between OCaml and C,” OOPSLA 2023,
  [paper](https://iris-project.org/pdfs/2023-oopsla-melocoton.pdf).
- Mulder and Krebbers, “Proof Automation for Linearizability in Separation
  Logic,” OOPSLA 2023, [DOI](https://doi.org/10.1145/3586043).
- Pulte et al., “CN: Verifying Systems C Code with Separation-Logic Refinement
  Types,” POPL 2023, [DOI](https://doi.org/10.1145/3571194).
- Qin et al., “VST-A: A Foundationally Sound Annotation Verifier,” POPL 2024,
  [DOI](https://doi.org/10.1145/3632911).
- Gäher et al., “RefinedRust: A Type System for High-Assurance Verification of
  Rust Programs,” PLDI 2024,
  [paper](https://iris-project.org/pdfs/2024-pldi-refinedrust.pdf).
- Hermes and Krebbers, “Modular Verification of Intrusive List and Tree Data
  Structures in Separation Logic,” ITP 2024,
  [DOI](https://doi.org/10.4230/LIPIcs.ITP.2024.19).
- Mulder et al., “Quiver: Guided Abductive Inference of Separation Logic
  Specifications in Coq,” PLDI 2024,
  [DOI](https://doi.org/10.1145/3656413).
- Timany et al., “Trillium: Higher-Order Concurrent and Distributed Separation
  Logic for Intensional Refinement,” POPL 2024,
  [DOI](https://doi.org/10.1145/3632851).
- Dardinier et al., “Destabilizing Iris,” PLDI 2025,
  [DOI](https://doi.org/10.1145/3729284).
- Krebbers, van der Maas, and Tassi, “Inductive Predicates via Least Fixpoints
  in Higher-Order Separation Logic,” ITP 2025,
  [paper](https://iris-project.org/pdfs/2025-itp-inductive.pdf).
- Somers et al., “Building Blocks for Step-Indexed Program Logics,” CPP 2026,
  [DOI](https://doi.org/10.1145/3779031.3779095).
- Elbeheiry et al., “A Recipe for Modular Verification of Generic Tree
  Traversals,” CPP 2026,
  [DOI](https://doi.org/10.1145/3779031.3779110).
- Mikhalchuk, Gladshtein, and Sergey, “Lazy Proof Automation for Separation
  Logic,” ITP 2026,
  [DOI](https://doi.org/10.4230/LIPIcs.ITP.2026.6).
