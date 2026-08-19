# Arc 5 charter: libc/builtin linking + multi-TU ("link & libc")

Date: 2026-08-19. Mode: long-cycle autonomous under the orchestrator/
worker doctrine (container CLAUDE.md): orchestrator scopes and verifies,
workers commit (green gates only), merge is the operator's. DRAFT until
operator-blessed (blessed via goal launch, 2026-08-19).

## Objective

Close the single largest parity gap — **procedure linking** (libc,
builtins, malloc/free/memcpy/realloc/errno: 20 coverage-corpus FAILs,
all `Illformed_program: calling an unknown procedure`) — and land
**multi-TU support**, so that real library code runs through the Lean
pipeline. Exit criterion with teeth: **libxml2's `chvalid.c` executes
differentially through the LEAN pipeline** (the probe proved the OCaml
oracle side; `notes/2026-08-19_libxml2-probe.md` has the no-autogen
config recipe). Stretch: the probe's 4-TU `uri.c` harness. Every step
serves both the coverage scoreboard (obj 2/6) and the libxml2 north star.

## Design inputs — TWO lineages, both mandatory (operator directive)

The prototype solved libc/builtins in its own ways; OCaml cerberus is
semantic ground truth. The discipline for this arc:
- **OCaml = what** (behavior): every mechanism mirrors how OCAML cerberus
  resolves these procedures under `--nolibc` and with libc — with
  file:line citations, per the mirror doctrine (divergence = defect).
- **Prototype = how** (design donor, obj 5): where the prototype has a
  working Lean-side design (builtin dispatch tables, libc shims, harness
  patterns), import the DESIGN with provenance recorded (prototype
  file:line in a comment alongside the OCaml citation). Import designs,
  not semantics: when prototype behavior and OCaml behavior disagree,
  OCaml wins and the divergence is recorded against the prototype.
- The S5 audit checks BOTH lineages: OCaml citations against cited code,
  prototype attributions present where designs were imported.

## Slices

**S0 — dual-lineage survey (before any code).** One worker, three maps:
(a) GROUND TRUTH: how OCaml cerberus resolves each of the failing
procedures — builtin dispatch? core-level libc (runtime/libc .core
files)? driver intrinsics? memory-model intrinsics? Trace malloc, free,
memcpy, memcmp, realloc, errno, printf-family, exit/abort specifically;
note what `--nolibc` includes vs excludes and how `test_exec.sh`'s
current flags interact. (b) DONOR: how the prototype solved each
(its interpreter ran 100% of tests/minimal and 13-fail on ci — it has
working answers; catalog them with file:line). (c) OUR GAP: for each of
the 20 coverage FAILs + the varargs-decl-tolerance issue, the exact
missing piece in our pipeline (CoreParser stdlib loading? Core_linking
not invoked? builtin table absent in the Lean driver?). Output: a
per-procedure resolution table with a design decision per row
(mirror-X-import-Y), committed as the arc's design doc. No fixes in S0.

**S1 — linking/builtins implementation.** Per the S0 design. Likely
shape (S0 may revise): enable the same libc/builtin surface OCaml uses,
via the generated `Core_linking` module (already in the build) and/or a
builtin dispatch mirroring the OCaml driver's, reusing prototype
dispatch-table design. Varargs: decl-TOLERANCE only (unused varargs
decls must not block linking); varargs EXECUTION stays register-15 OPEN.
Batch-wise by procedure family; full differential after each batch;
coverage baseline updated with justification per moved file.

**S2 — multi-TU.** (a) Mechanism: OCaml links multiple TUs (find its
path — Core_linking exists in the model for a reason); implement the
Lean-side equivalent, OR a documented TU-concatenation stopgap if real
linking is disproportionate (S0 prices both; concatenation interacts
with the 2^20 symbol-offset invariant — analyze before choosing).
(b) Digests: `CerberusFresh.digest` is permanently `""`
(from_same_translation_unit vacuously true — register item); mirror
pipeline.ml's MD5-per-TU if real linking lands, else document the
stopgap's soundness argument. Demonstrated by the S3 harness.

**S3 — libxml2 shakedown (the exit criterion).** Commit the probe's
config recipe as `scripts/libxml2_prep.sh` + a pinned scratch config;
run `chvalid.c` through the LEAN pipeline; differential vs OCaml on a
committed test battery (generated: character-class predicates over
boundary code points — the module is pure tables, so the battery is
mechanical). Bar: 100% agreement on the battery (it is a pure predicate
module; any disagreement is a real defect — classify, fix or record).
STRETCH (attempt only if S1+S2 land with slack): the probe's 4-TU
`xmlParseURISafe` harness differentially on a URI corpus; record
whatever fraction works as the arc-6 baseline. NOT in scope: any
verification/proof work on uri.c. When that work comes, its ARCHITECTURE
is the GoLean layering (operator, 2026-08-19; ROADMAP north star):
relational semantics over the fuel opsem, Iris as proof machinery
coupled to the relational layer, final theorems discharged by ADEQUACY
into opsem-only statements — a pure reference parser appears in the
theorem STATEMENT as specification, never as the proof method. This
arc's substrate work must not shape itself toward direct opsem-level
refinement proofs.

**S4 — close-out.** Results doc with coverage-scoreboard deltas and
register movements; decision log; docs de-stale; 2-agent adversarial
audit (mandatory scopes: dual-lineage citation checks; linking-semantics
fidelity — does our resolution order match OCaml's on shadowing edge
cases; baseline honesty); fix-or-record; pins (lem changes not expected
— if any lem change occurs, full pin dance); merge checklist. Stop. Do
not merge.

## Success conditions (machine-checkable)

1. tests/minimal: ≥103/106 maintained, `--check-baseline` rc 0 at every
   commit (regressions are gate failures, full stop).
2. Coverage corpus: ≥18 of the 20 linking FAILs → MATCH/UB_MATCH
   (target 20); overall coverage scoreboard strictly improved; every
   still-failing file classified. Baseline updates each carry a
   justification.
3. chvalid.c through the Lean pipeline: 100% agreement with OCaml on
   the committed battery (shortfall = replan trigger, not a lowered bar).
4. Multi-TU: mechanism landed and exercised by S3; digest story resolved
   (real MD5s or documented stopgap + soundness note).
5. Dual-lineage discipline: every new/changed seam carries OCaml
   citations (or documented-deliberate divergence) AND prototype
   provenance where a design was imported; audit-verified.
6. Standing gates green at every commit (build, unit 4/4 incl. sync,
   purity/cones/totality, parse, core baseline, elab reporting).
7. Records complete; arc branch `arc/libc-linking` gate-green; merge
   checklist ready; mainlines untouched.

## Risks / pre-declared calls

- OCaml's libc is large; scope is the FAILING SURFACE (the 20 files'
  procedures + what chvalid/uri need), not "port all of libc".
- printf-family drags in varargs execution — if S0 shows the failing
  files need real printf (not just linking), the orchestrator decides:
  minimal format-string interpreter mirroring the OCaml driver's
  (prototype has a donor design) vs classify-and-defer. Logged either
  way.
- Concatenation stopgap can alias static symbols across TUs — S0 must
  analyze against the symbol-identity invariants before it is chosen.
- test_exec.sh currently runs `--nolibc` both sides; if S1 changes the
  libc story the harness flags must evolve in lockstep on BOTH sides
  (instrument changes get their own commit + justification).

## Autonomy protocol

As arc 4: workers commit (green gates only, one coherent commit per
slice/batch, verified messages); orchestrator scopes exactly, verifies
independently at every boundary, owns the decision log; judgment calls
logged; emergency exit always available (nature declared). Tripwires:
bar 3 unreachable after honest attempts; a linking design that cannot
satisfy both lineages (mirror conflict with no clean documented
divergence); any gate keepable-green only by weakening. Machine-global
state untouchable; a needed-global-change is an emergency exit, never an
action.
