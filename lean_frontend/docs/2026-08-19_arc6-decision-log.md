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

**D9 [USER]** — Incoming external artifact: the operator has tasked a
SEPARATE agent (outside this session) to write a weak-memory+Iris
survey, to be dropped in "lean_backend/docs" (operator's phrasing —
likely lean_frontend/docs in cerberus-lean or doc/notes in lem-lean;
watch both), possibly with gitignored papers alongside. Consequences:
(1) an externally-authored file appearing in a docs dir is EXPECTED, not
contamination — audits and workers must not flag it as a foreign-file
finding (this entry is the provenance record); (2) the spike doc's
[AGENT] prior-art anchor list is superseded by that survey on arrival;
(3) the survey is operator-commissioned INPUT — it gets read at arc-7
charter time, not auto-committed by us (the other agent owns its own
commit/untracked decision).

**D9a [USER]** — Location confirmed by the operator: the external
weak-memory survey lands in `lean_frontend/docs` (cerberus-lean).

**D10 [AGENT]** — S1 boundary passed (verified: unit 4/4 w/ 280 parser
tests, minimal/coverage/debug baselines rc 0, test_core minimal 100% —
THE KNOWN-RED 078 IS GREEN (pp-only ProcDecl form was its cause; the
"known red" baseline language in mainline docs must be updated at merge),
libc_exec + uri baselines clean, uri 10/10 BYTE-FOR-BYTE with libc).
Worker [AGENT:S1] calls endorsed, esp.: (a) libc metadata reconstructed
by frontending the same 12 TUs through OUR OWN pipeline — the identical
lem code that produced libc.co's metadata; TCB-consistent with D3 (no
new oracle trust beyond the pinned body dump); (b) explicit --libc flags
(standing corpora untouched by construction); (c) 006-snprintf recorded
as varargs-classified DIFF, not stubbed — the S2 flip will surface as
deliberate baseline drift. Register additions from S1: survey erratum
(68 globs); silent-misparse class + test_core's parse-success-only blind
spot (parses ≠ parses-correctly — the PEif/;-layout fixes show textual
round-trip gaps; candidate future gate: pp-roundtrip comparison);
has_proto verified-dead finding (upstream-reportable oddity).

**D11 [AGENT]** — S2 boundary passed (verified: coverage now 183/199
comparable — 172+11, exactly the 5 predicted moves; libc_exec 7/7; unit
4/4). Register 15 FIXED with dual-lineage citations. Worker [AGENT:S2]
call specially endorsed: the orchestrator's brief specified a va_arg
ctype check that DOES NOT EXIST in the oracle (impl_mem.ml:2731 is a
TODO comment) — worker refused to add it per the mirror doctrine.
Doctrine works in both directions: worker briefs are not ground truth,
the cited OCaml is. Remaining coverage non-matches: 3 mismatch
(mem3-004 pp placeholder, 2 provenance-fork defect-8) + 13 skips.
Next: S3 perf (opens lem-lean lane — Fmap representation + PROVED
equivalence lemmas per D7 doctrine upgrade; pin dance at close).

**D12 [AGENT]** — S3 boundary passed (verified both repos: lem 40d063e,
cerberus 3d7dc5bdd; unit 4/4, minimal baseline rc 0, battery slice
MATCH at ~96s, uri baseline clean). Bar met: 28→4 slices, ratio 1.7×
flat, ZERO movement everywhere; lookup_equiv kernel-checked with the
retired implementation as test-only reference (D7 doctrine satisfied;
the general order theorem documented-deliberate with bounded-exhaustive
kernel-evaluated #guards). Endorsed [AGENT:S3] subtlety: legacy Fmap's
BEq-insert/cmp-lookup mixed semantics for sym/identifier reproduced via
buckets — the zero-movement bar caught what a naive key-map would have
silently changed. NEW REGISTER ITEMS: stack ceiling re-probed (~1.4k
iterations; QUIET EXIT-0 failure mode is the concerning half — harness
sees missing verdict, but silent-success-shaped death needs a guard some
arc); lem tests/backends leantests pre-existing srcDir breakage;
oracle-key-order folds as possible future parity alignment. REGEN NOTE
until close-out: arc lem required (PATH+LEMLIB) — opam lem still emits
retired names; pin dance at close.

**D13 [AGENT]** — S4 + relsem-continuation boundaries passed (verified:
uri GATE PASS 16/16; ci sweep agreement 110/114 stable across my re-run;
ladder tiers live; spike commit 7bd884ad3 with runNDT_sound proved and
ExecModel absorbing the concurrency instance as fields-only). ANOMALY
for the audit: my ci re-run split skip/inconsistent differently than the
worker's recorded baseline (128+18-overlaid vs 110+18-disjoint; the 114
comparable and 110 agreements are IDENTICAL) — the oracle cabs-json
bridge classification appears run-sensitive; audit must characterize
(harness counting bug vs genuine oracle nondeterminism) before the ci
baseline is trusted as a scoreboard. Register promotion: finding 11
(read-only allocations) is now CORPUS-FORCED (ci 0086 semantic DIFF) —
top of next-arc queue. Prototype ci head-to-head: ours 4 (1 semantic)
vs ~13 historical, base caveat recorded.

**D14 [USER]** — Ban (operator, near-verbatim): "ban bv_decide and other
non-kernel-checked proof methods completely", citing golean's policy in
action. [AGENT] verified golean's mechanism (deps/golean
proofs/Audit.lean): in-build transitive-axiom audit, allowlist =
classical trio, build-failing — catches sorryAx, ofReduceBool
(native_decide/bv_decide), and rogue axioms uniformly, coverage by
import-closure construction. Codified in container CLAUDE.md.
Enforcement rollout: (1) THIS ARC's audit-fix batch — extend
check_theorem_axioms.sh: ofReduceBool/ofReduceNat always-fatal in every
probed cone (alongside sorryAx); grep-ban native_decide/bv_decide in
hand-written proof files (test/Unit, lem-side LemLibTest); (2) ARC 7 —
adopt the golean Audit.lean in-build pattern for RelSem and proof libs
(exact-axiom-set assertions). Coincidence noted: audit-2 F1 (the #guard
"kernel-evaluated" mislabel) is the same trust-class boundary this ban
patrols — corrected language rides in the same batch.
