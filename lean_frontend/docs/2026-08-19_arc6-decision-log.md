# Arc 6 decision log (libc & speed)

DECISION PROVENANCE (operator directive, goal launch 2026-08-19): every
decision is tagged **[USER]** (made or explicitly directed by the
operator, with the directing message paraphrased) or **[AGENT]** (made
autonomously by the orchestrator or a worker, resolved by project
principles). Mistagging an agent decision as user-decided is a critical
failure. Worker-made calls are tagged [AGENT:worker-slice].

**D1 [USER]** — Arc scope and charter blessed via goal launch; the
prototype-libc prior-art study in S0(a) is an explicit operator
directive ("we already support libc-loading in the prototype — look at
that closely"), as is the GoLean verification framing recorded in the
charter's S3-adjacent note (operator correction, 2026-08-19).

**D2 [AGENT]** — Lane: branch `arc/libc-load`, worktree
`worktrees/cerberus-lean-arc/libc-load`; charter DRAFT marker removed on
launch. No lem-lean worktree unless a backend need emerges (none
expected; any lem change triggers the full pin dance per charter).

**D3 [USER]** — Decision PRINCIPLE for the libc-ingestion path choice
(operator, mid-S0): choose to MINIMIZE THE TCB. The operator's framing
of the tension, near-verbatim: writing our own loading implementation
adds new code; leaning on Cerberus grows the surface that cannot be
reasoned about; a lot depends on what exactly Cerberus already offers.
Relayed to the S0 worker mid-flight with an [AGENT] analytical frame
attached (recorded here so the provenance split is exact): the frame —
that Lean-side linking via the GENERATED (lem-derived) Core_linking sits
inside the reasoned-about surface, that CoreParser is an existing trust
surface whose usage rather than mechanism would grow, and that a
post-link dump oracle-trusts a SEMANTIC transformation unlike the thin
cabs-json syntax boundary — is the orchestrator's analysis in service of
the operator's principle, not an operator statement. S0's survey must
carry a per-path TCB accounting; the unlinked-text-dump feasibility
answer likely decides the path under this principle.

**D4 [USER-initiated / AGENT-scoped]** — Parallel stream opened at the
operator's suggestion ("could we run an iris-lean spike vs the draft
semantics in parallel?"): spike/relsem worktree, SPIKE grade (design +
skeleton deliverable, reporting only, no merge bar this arc). [AGENT]
scoping: iris-lean does not build offline (4.32.2 + Qq — network-window
items), but Layer-2's relational semantics is BY ARCHITECTURE a
definition over our fuel opsem needing no Iris import — so the spike
drafts real 4.29 Lean (step relation over Core configs, fuel-erasure
statement skeletons, ND/oracle parameterization) + a paper design for
the Iris coupling/adequacy, sourced from deps/golean + deps/iris-lean
(read-only). Write surfaces disjoint from arc 6 except one [[lean_lib]]
lakefile line (accepted rebase point; merges serialize per doctrine).

**D5 [AGENT]** — S0 boundary passed (survey-only commit verified). Path
DECISION per the operator's TCB principle (D3 [USER]): **path (i)** —
oracle-produced UNLINKED libc text dump (stock `--pp=core` on libc.co,
no OCaml patching, 4.2MB once vs the prototype's 365MB per test),
ingested by our existing CoreParser (mechanism unchanged, usage grows:
needs `glob` production + restrict/varargs-ctype — 68/191 decls fail
today) and linked by the GENERATED Core_linking. The link step stays
inside the reasoned-about surface; the dump is pinned + drift-checked
oracle input (cabs-json trust class). Caveat owned: stock pp omits
extern/funinfo/main — Lean-side synthesis is S1's real work, cited
against what OCaml's loader reconstructs.

**D6 [AGENT]** — S3 perf RESHAPED per S0 profile: dominant cost is
LemLib Fmap (assoc list, O(n) ops) at every generated-map seam — the
fix is a representation change in lem-lean's lean-lib (opens the
two-repo lane + pin dance at close; behavioral-equivalence argument
required: key-order folds then MATCH the oracle = parity improvement,
not regression risk). CerbMem bytemap secondary. NEW register defect:
stack ceiling (SIGABRT at ~2k-8k-iteration loops) — recorded; S3
addresses it only if the Fmap fix exposes it as next-binding. Park
clause retained. Slice order: S1 libc → S2 varargs → S3 perf
(worktree-sequenced; S3 opens the lem-lean worktree).

**D7 [USER]** — Doctrine (operator, near-verbatim): "we should not
permit any internal trust gaps unless they are truly forced on us by
immovable objects." Codified in container CLAUDE.md (no-internal-trust-
gaps doctrine): in-Lean agreement is a theorem, not a test; kernel-
opaque artifacts are eliminated or sit on the declared boundary list
with an immovable-object justification; internal differentials are
transient migration checks only. Prompted by the operator's Q1 challenge
on the relsem spike (runND bridge → totalize instead, recorded on the
spike branch). [AGENT] immediate applications in THIS arc: S3's Fmap
representation swap must carry PROVED equivalence lemmas for the swapped
operations where feasible (upgrade from the charter's
"behavioral-equivalence argument"); the network-window record: operator
ran push/4.32.2/iris-vendor/mirrors/creduce, all verified (iris-lean now
builds offline — arc-7 prerequisite cleared). Arc-7 charter inputs
queued: totalize CerbND (Layer-2 prereq), extend totality gate to
CerbND, spike Q2-Q4 recommendations for operator review.

**D8 [USER]** — Doctrine refinement (operator, near-verbatim): "some of
these objects will eventually be moved (eg. we should design so we can
eventually support concurrency)." Codified in container CLAUDE.md:
boundary entries now classified PERMANENT vs TEMPORAL; temporal entries
require an expected MOVER and impose a FORWARD-DESIGN constraint
(nothing built today may make the move harder). [AGENT] applications:
concurrency constraints appended to the relsem spike doc (Config keeps
the thread pool; StateInterp parameterized so cmm replaces gen_heap
without reshaping the language instance; adequacy quantifies scheduler
behaviors so weak memory arrives as more behaviors, not a new statement
form). Current temporal inventory: cmm stubs (mover: future concurrency
arc), DAEMON fallbacks (mover: C-tier lem fix), upstream-bug mirrors
(mover: upstream reports/fixes — float sizes, 097), pp placeholders
(mover: pretty-printer arc).
