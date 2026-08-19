# Arc 5 decision log (link & libc)

Orchestrator/worker doctrine; dual-lineage discipline (OCaml = what,
prototype = how). Format: **D<n>** — decision / why / alternatives.

**D1** — Lane: branch `arc/libc-linking`, worktree
`worktrees/cerberus-lean-arc/libc-linking`. Charter blessed via the goal
launch (DRAFT marker removed). No lem-lean worktree unless a backend
need emerges. Native-objects note: this worktree primes native/*.o from
the post-arc-4 primary (current); any native/*.c change requires `make
lean-native-obj` (arc-4 gotcha, now in CLAUDE.md).

**D2** — S0 boundary passed (survey-only commit, verified). Findings
accepted; scoping consequences: (a) S1 collapses to the single [A] seam
(ailname attribute capture in CoreParser + attribute-keyed map in Main,
~50-80 LOC) — expected to flip all 20 FAILs; post-fix, probe the 4 io
.unsupported files and un-mark any that now pass (instrument commit).
(b) NO printf work ever (generated Formatted.lean is the OCaml mirror;
the prototype's missing printf is its hole, not ours). (c) NO
varargs-decl work (decls link fine; execution stays register-15 OPEN
with the prototype donor design catalogued for a later arc). (d) S2 =
REAL linking via generated Core_linking (~80-120 LOC) + native MD5
digests (~150 LOC C; native change → lean-native-obj + floor gotcha) —
concatenation REJECTED on probed static-merging semantics. (e) exit/
abort: OCaml itself fails them under --nolibc — parity already holds,
no work. Prototype negative knowledge recorded: its name-keyed
exit/abort Eccall hacks are flagged do-not-import.

**D3** — S1 boundary passed (verified: minimal 103/106 held, coverage
167+11=178/199 comparable, unit 4/4). 20/20 linking FAILs flipped
(target 20, bar ≥18); success condition 2 EXCEEDED. Second in-seam
defect (builtin_ prefix not stripped per core_lexer.mll:209-219) was
masked by the ailnames miss — found because the worker validated the
full proxy dispatch chain, not just the first symptom class. Four io
files un-marked with byte-identical printf stdout (generated
Formatted.lean — no format-interpreter work needed, confirming S0's
prototype-hole analysis). Residual coverage non-matches now EXACTLY the
pre-priced register set: 5 varargs (reg 15), mem3-004 (pp placeholder),
2 provenance-fork (defect 8). Audit flag carried: pImplConstant's
lenient unknown-name fallback (OCaml raises; unreachable on
OCaml-produced .core) — S5 audit item.
