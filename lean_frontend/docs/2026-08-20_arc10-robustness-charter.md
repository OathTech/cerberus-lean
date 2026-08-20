# Arc 10 charter: register burn-down + csmith at scale ("robustness")

Date: 2026-08-20. Mode: long-cycle autonomous under the orchestrator/
worker doctrine, running as a PARALLEL STREAM alongside arc 9 (the
workbench). BLESSED by operator via launch, 2026-08-20 ("Great,
launch it"). Fully offline. Branch pair:
`arc/robustness` in BOTH repos (lem WILL change — full pin dance at
close; merges SERIALIZE with arc 9 per the playbook: whichever stream
closes second rebases on the moved mainline, re-gates, re-asks).

## Objective

Harden the substrate while arc 9 builds the proof workbench: burn
down the defect register (the corpus-forced and largest-debt items)
and run the csmith differential kit at real scale — converting
adversarial fuzz coverage and register debt into fixed defects or
priced, recorded parks. Exit criteria with teeth: the tests/ci
scoreboard strictly improved (finding 11 closed), the expr-family
sorried-BEq debt eliminated or priced, and a sustained csmith sweep
with EVERY mismatch classified.

## Parallel-stream discipline (binding)

- **Write surface (this stream):** cerberus-lean `CerbMem.lean`,
  `CerbPP.lean`, harness scripts (`scripts/` csmith kit + baselines),
  test corpora/baseline files, docs/register records; lem-lean
  `src/lean_backend.ml`, `lean-lib/` (Ord/BEq instances), lem
  comprehensive tests.
- **FORBIDDEN surfaces (arc 9's turf + collision zones):**
  `lean_frontend/relsem/` (anything), `tests/verify/`,
  `CerbND.lean` (load-bearing for arc-9 proofs — the stack-ceiling
  register item is explicitly OUT of this arc for that reason), the
  iris Lake pin. A fix that genuinely needs a forbidden surface is
  PARKED with pricing, never improvised.
- **Known shared touch-point:** `lean_frontend/lakefile.toml` /
  `lake-manifest.json` — this stream bumps the LemLib rev when
  lean-lib changes land; arc 9 may bump the iris rev. Different
  entries, same files: expected trivial rebase conflict at the
  second merge; resolved at rebase + full re-gate, recorded.
- Mid-arc lem consumption: per-worktree checkout lem (PATH-prepend +
  LEMLIB — the arc-8 D2 pattern) for regeneration; the opam pin moves
  only in the closing pin dance. The opam-installed lem is
  switch-global — this stream must NOT upgrade it mid-arc (arc-9
  worktrees share the switch).

## Slices

**S0 — register triage + csmith shakedown (no fixes).** (a) Enumerate
the FULL open register from the results docs (arcs 4-8: ~12 items
incl. finding 11 read-only allocations, pp-placeholder text class,
R1 Sum-Ord, R2 4.28 eager-init, expr-family sorried BEq,
set-comprehension stub, Let_defs binder note, column-0 emission) into
a single triage table: in-scope-fix / park-with-pricing /
out-of-scope(forbidden surface), each with the evidence cite.
(b) csmith shakedown: verify the arc-4 kit runs end-to-end today
(gen, differential, creduce interestingness), fix kit rot only, pick
run parameters (program size, per-test timeouts BOTH sides, memory
caps — csmith loops interact with the stack ceiling: choose generator
flags to keep iteration counts under ~1k, and classify ceiling hits
as a KNOWN bucket, never silent). No fixes in S0.

**S1 — finding 11: read-only allocations.** The ci-corpus-forced
item. Mirror the OCaml oracle's read-only allocation handling in
CerbMem (impl_mem citations per the mirror doctrine; prototype
attributed if a design is lifted). Bar: the forced ci files flip to
MATCH; ci scoreboard strictly improved; zero movement elsewhere.

**S2 — lem C-tier batch: BEq/Ord debt.** (a) R1: real `Ord (Sum a b)`
in LemLib (+ BEq if missing) — unblocks deriving on Sum-typed fields.
(b) The expr-family sorried BEq/Ord/SetType comparison bodies
(~1135 `:= sorry` sites, the largest remaining generated-sorry
population): replace backend sorry-emission with real derived
comparisons where derivable (the arc-8 S1 derivation pattern applied
to comparisons: per-constructor structural compare with `[Ord tv]`
bounds), fail-closed elsewhere (skip_instances / hand instance — NO
sorry fallback for newly-covered shapes; existing uncovered shapes
may keep the registered residual, explicitly counted before/after).
Probe-first in tests/comprehensive; EVERY lem checkpoint pairs with
cerberus-scale regeneration + capped build (standing April lesson).
Census the before/after sorry counts (derived, labeled). If the full
family resists one arc, land the derivation mechanism + the expr
family specifically, park the tail with counts.

**S3 — pp-placeholder text class.** Implement the placeholder
pretty-printer class in CerbPP mirroring the OCaml printer for the
covered constructs (citations); differential-validate where the
oracle's text output is comparable (test_elab/pp harness modes);
classify the remainder. Bar: the register item closes or shrinks to
an enumerated residual.

**S4 — csmith at scale.** Sustained sweep with the S0 parameters
(budget-bound: run until the triage queue, not the generator, is the
bottleneck; report the N achieved — no silent caps). EVERY mismatch:
reduce (creduce), classify (bug class, side, affected construct),
then fix (in-scope surfaces, batched, re-swept) or register with the
reducer artifact committed. Oracle-side crashes/timeouts are
findings about the harness envelope, recorded not hidden. Standing
corpora + baselines must stay zero-movement under their existing
flags throughout.

**S5 — close-out.** Results doc (scoreboard deltas, sorry-census
before/after, csmith tally + classification table), decision log,
register updated (closed/parked/new), docs de-stale, 2-agent
adversarial audit — mandatory scopes: (a) mirror-citation fidelity
(CerbMem/CerbPP against cited OCaml); (b) BEq derivation soundness
(derived comparisons agree with OCaml poly-eq semantics — the
CerbStepInstances parity precedent; spot differential evidence);
(c) baseline honesty (no baseline moved without justification; csmith
classifications match the artifacts); (d) parallel-stream discipline
(zero commits touching forbidden surfaces — checkable from the
diffstat). Fix-or-record; full pin dance prep; merge checklist.
Stop. Do not merge (and serialize with arc 9's merge per doctrine).

## Success conditions (machine-checkable)

1. tests/ci scoreboard strictly improved with finding 11's forced
   files → MATCH; minimal/coverage/debug/libc/uri/chvalid baselines
   zero-movement at every commit.
2. Generated sorry census: expr-family comparison bodies eliminated
   (real derived instances, kernel-visible) or the residual counted
   and parked with pricing; before/after counts in the results doc
   (derived, labeled). No new sorry/axiom/opaque anywhere (arc-8
   absence gates + tree-wide census stay green — they are enforcing).
3. csmith: sweep executed at the S0-chosen scale, N reported, 100%
   of mismatches classified with committed reducer artifacts; fixes
   re-swept clean.
4. pp text class: implemented + validated per S3, register item
   closed or enumerated-residual.
5. Zero commits on forbidden surfaces (audit-verified); the lakefile
   touch-point handled per the discipline section.
6. lem changes probe-first with comprehensive coverage incl. negative
   probes; every lem checkpoint cerberus-scale-validated; pins
   aligned at close (branch heads = opam pin = Lake pin).
7. Records complete; branches gate-green; merge checklist ready;
   mainlines untouched by this stream until its operator-gated merge.

## Risks / pre-declared calls

- BEq derivation is the delicate center (comparison SEMANTICS must
  match OCaml's polymorphic compare where the model relies on it —
  the arc-4 CerbStepInstances lesson). Fable-grade worker; parity
  evidence demanded in the audit.
- csmith triage can flood: the queue is explicitly allowed to close
  the arc with registered-not-fixed items; fixing everything is NOT
  the bar — classifying everything IS.
- Stack-ceiling hits in fuzzed programs: known bucket, counted,
  NOT chased into CerbND (forbidden surface).
- Sum-Ord/BEq LemLib additions change lean-lib → Lake pin bump
  mid-arc in THIS stream's worktree only; coordinate nothing with
  arc 9 beyond the declared touch-point.
- 4.28 eager-init (R2) may complicate lem-suite panic tests added in
  S2 — the arc-8 leg-1/leg-2 test pattern is the workaround; a
  lem-suite toolchain bump is NOT in scope (register mover stands).

## Autonomy protocol

As arcs 4-9: workers commit (green gates only, one coherent commit
per slice/batch, verbatim outputs), orchestrator scopes and
independently verifies at every boundary, decision log with
[USER]/[AGENT] provenance, capped builds only, merge lives with the
operator (unconditional audit ask). Model mix: Opus for mechanical
batches (csmith triage, pp tables), Fable for lem-backend derivation
and CerbMem seams. Workers within this stream stay sequenced; the
stream runs concurrently with arc 9 on disjoint worktrees. EMERGENCY
EXIT always permitted, nature declared. Tripwires: any fix demanding
a forbidden surface (park instead); comparison-semantics divergence
that cannot be cleanly mirrored; any gate keepable-green only by
weakening; machine-global state.

## ADDENDUM (2026-08-20, applied at the S2 boundary; provenance in D3)

- **[USER] S3b — dead-corpora wiring** ("may as well roll this into
  arc-10"): (a) FLOAT — wire tests/float (69 files, copied arc-4,
  never wired) into a test_exec.sh lane + committed baseline;
  expected-failure classification against the upstream float-mul
  boundary entry (a differential there may indict the ORACLE —
  classify, never "fix" to match a wrong oracle). (b) BYTES — run
  tests/bytes (14 files) against their committed .exec/.elab
  expecteds as oracle-independent CerbMem probes. Both priced S
  (notes/2026-08-20_prototype-test-migration-survey.md).
- **[USER] S4 opens with csmith CONFIGURATION EXPLORATION** — "making
  csmith work properly was something we struggled with in the
  prototype... try a few different configurations, try to figure out
  how to make csmith cover as much as possible." The prototype's
  setup is NOT final; the S0 V/NV lanes are provisional input. Sweep
  configs across feature axes, measure per-config oracle-runnable
  yield AND construct coverage reaching the Lean side, choose a lane
  PORTFOLIO. Deterministic seeds + verbatim tallies throughout.
- **[AGENT] S4 additions** (migration survey): deterministic
  list-lane over the in-tree 1,669-file upstream csmith corpus; the
  prototype's interesting_cases/union_unspecified reproducer seeded
  into triage.
