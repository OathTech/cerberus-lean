# Semantics forward-work assessment

STATUS: assessment for operator discussion — not a charter. Commissioned
[USER 2026-08-31] with six axes: (1) fidelity to real C, (2) fidelity to
cerberus-upstream, (3) C feature coverage, (4) QoL for other projects,
(5) closing threats to validity, (6) performance/scalability without
trust cost. Goal state, verbatim: "an incredibly faithful, well tested,
and carefully built core semantics that can easily be upstreamed if the
cerberus team choose to do so."

Grounded against: `core/semantics-first` @ 7c66b39a4 (VALIDATION.md,
TODO.md, the split record), `scripts/fork_drift_manifest.txt` (4 section
headers, ~52 file entries), `deps/cerberus-upstream` @ b9aeedcb4
(2026-08-13 — the fork's merge-base; **only ~2.5 weeks old**, far
fresher than feared), the reasoning-era reviews' model-fidelity facts
(now axis-1/5 work items), and the standing queue. Box facts: gcc
13.3.0 present; clang and CompCert absent (installable only at a
network window).

Prices are S/M/L at the project's measured hot factor. Items marked ⊙
are already-registered queue items re-homed under their axis.

---

## Axis 1 — Fidelity to real C code

- **F1.1 The PNVI provenance port (L)** — the single biggest fidelity
  item. The Lean memory model currently runs PVI (integer casts carry
  provenance; `ptrfromint` never fails; taint machinery "Not ported").
  Upstream's PNVI-ae-udi is *the* reference treatment and is what
  Cerberus exists to define. Port the exposure/taint machinery into
  CerbMem behind the same switch discipline upstream uses, mode-by-mode
  differential re-validation (the oracle supports the switches — the
  differential harness extends naturally). Deps: none hard; benefits
  from F5.3/F5.4 landing first so the port is validated by instruments,
  not vibes. This also unlocks the reasoning-era reviews' "FUTURE
  table" of PNVI-grade cast behavior for any downstream logic.
- **F1.2 Real-compiler differential lane (M)** — gcc is on the box.
  Compile the exec corpora at `-O0`, run natively, compare observable
  outcomes (exit codes/stdout) against Lean+oracle for
  defined-behavior programs. Requires a comparability classifier
  (UB/unspecified-order programs excluded — the CI-sweep already built
  exactly this classification; reuse it). Double-counted under axis 5:
  it is the cheapest break in the single-oracle circularity. Clang as
  a second compiler when a network window allows its install.
- **F1.3 GNU dialect coverage for Linux-adjacent C (staged S per
  extension; M overall)** — statement expressions, `typeof`,
  attributes, the `__builtin_*` family (partially mirrored already in
  CerbUtils), with inline asm as an explicit reject-cleanly boundary
  (contracted primitive territory, never semantics). Follow upstream's
  own GNU support file-by-file; anything upstream lacks is out of
  scope (we mirror, we don't extend the language).
- **F1.4 Bitfields (M)** — kernel-pervasive; flagged as a silent
  coverage hole by the corpus-2 review. Assess upstream's support
  level first (S probe), then port/enable + differential tests.
- **F1.5 Float semantics breadth (S-M)** — the tests/float lane is
  small; extend the differential float corpus (rounding modes,
  special values, conversions) against the oracle and gcc. CerbFloat's
  lawful-Ord work is done; the untested surface is arithmetic edge
  behavior.
- **F1.6 Varargs (M)** — upstream has a va_list model; ours is
  unassessed. Probe (S) then decide; snprintf-class consumers are
  realistically contracted primitives for downstream users either way.
- **F1.7 Trap representations + locking stores: surface and test (S)**
  — two real, implemented semantics discovered *by code reading*
  during the reasoning-era reviews (`_Bool` trap-rep UB; locking
  stores transitioning allocations to read-only — the string-literal
  mechanism). Neither has a targeted test today. Add pinned
  differential/unit tests for both; cheap, real fidelity
  documentation.
- **F1.8 The killed-not-UB inventory as pinned tests (S)** — the
  reviews enumerated the outcome class (OOM kill, MerrWIP arms,
  `Free_out_of_bound → none`, panic sites). Pin each with a negative
  test so the behavior is documented and guarded rather than folk
  knowledge.

## Axis 2 — Fidelity to cerberus-upstream

- **F2.1 File the tray (S prep + operator network task)** — ~16
  drafted reports + 3 prepared PR branches (bswap64, char-escapes,
  pp-roundtrip; each worktree clean, one commit, "drop before merge"
  descriptions in place — ready shape). The two oracle-wrong findings
  pinned Lean-right (decode `\?`, hex escaped-char) are the strongest
  openers: they demonstrate the differential method's value to
  upstream in one email.
- **F2.2 Upstream re-sync (M, network-gated)** — good news from the
  grounding: the pin (b9aeedcb4) is dated **2026-08-13** — about 2.5
  weeks stale, not months. A fetch at the next window measures the
  real delta; the rebase cost is dominated by the arc-13 renumbering
  machinery (`fork_renumber.ml` + 3 ocaml-only target_reps), which
  was *designed* for upstream re-convergence and may partially
  dissolve if upstream takes the renumbering upstream. Do F2.3 first
  so the re-sync lands with a triaged delta.
- **F2.3 Fork-delta triage for upstreaming (S-M)** — the manifest's
  ~52 entries classified into: (a) upstreamable improvements (the
  Lean-target lem declarations are benign multi-target additions; the
  totalization is target-conditional and demonstrates good lem
  hygiene; the oracle fixes), (b) fork-permanent (the drift gate
  itself, Lean build glue), (c) dissolvable-on-resync. Output = the
  upstreaming menu, the concrete artifact an upstream conversation
  needs.
- **F2.4 The byte-identity discipline write-up (S)** — codify the
  maintenance rules (target-conditional lem, regen gates, zero
  OCaml-movement proofs) as a short doc written for upstream's eyes;
  it is the property that makes the fork *safe to take*.

## Axis 3 — Coverage of C features

- **F3.1 ⊙ printf/Monadic_parsing totalization (S)** — the parked
  tail of the threadB totalization; finish for totality-gate
  completeness (runtime behavior already exercised by the lanes; this
  closes the exec-cone census to zero partials).
- **F3.2 ⊙ pr44468 offsetof unknown-tag panic (S)** — known defect,
  reproducer in hand, the CI sweep's one new find.
- **F3.3 ⊙ CoreParser enum-ctype literal arm (S)** — parser
  completeness; reproducers exist.
- **F3.4 Mine the CI-sweep's non-comparable set (M)** — 2,186 files,
  1,316 comparable, zero mismatches; the ~870 non-comparable files
  are the coverage frontier *already classified by reason* (libc
  modes, front-end rejects, unsupported features). Turn the sweep
  data into a ranked feature-gap list; feeds F1.3/F1.4/F1.6 with
  real-world frequency data instead of guesses.
- **F3.5 ⊙ Prototype disposition (S)** — bare-mirror into
  deps/mirrors + delete the 1.2G checkout (operator word pending);
  its 13 tests/ci failures die with it (superseded coverage).
- **F3.6 Elab-lane and immaculate follow-ups (S each)** — the
  registered small gaps in those lanes' records.
- CHERI: excluded by standing ruling; noted only.

## Axis 4 — QoL for other projects (the successor repo is customer #1)

- **F4.1 Package as a clean Lake dependency (M)** — the successor
  RefinedC-retrofit repo will `require` this repo. Needs: a stable,
  documented exec-facing module surface (driver entry points, CerbND,
  the Call/Machine exec machinery, outcome types), consumer-facing
  lakefile targets that don't drag test exes, version tags, and a
  one-page API doc. The split already adjudicated the exec-facing
  set; this formalizes it.
- **F4.2 ⊙ `--args` flag (S)** — argv-parameterized driver execution
  (argv parity already verified); any consumer's input-family testing
  wants it.
- **F4.3 ⊙ Oracle `--batch` allocation-census line (S)** — the leak
  observable's oracle-differential leg; also an upstream-patch
  candidate.
- **F4.4 Stable machine-readable outcome/trace format (S-M)** — a
  versioned JSON schema for driver outcomes (and optionally step
  traces) so consumers and differential tooling stop parsing pretty
  output.
- **F4.5 ⊙ Step-runner stack-ceiling GUARD (S)** — fail-noisy
  detection (the FIX is axis-6 F6.1).
- **F4.6 Driver diagnostics pass (S)** — standardize the loud-panic
  and error message formats (machine-readable class + human line).
- **F4.7 Build-speed and footprint guidance (S)** — document the
  measured 2×48G-safe parallelism, CERB_MEM_MAX practice, and the
  module-DAG facts for consumers.

## Axis 5 — Threats to validity (adversarial about our own trust story)

- **F5.1 The single-oracle circularity (the headline threat)** — the
  model and the oracle are generated from the SAME .lem sources. The
  differential empire therefore validates the lem→Lean translation
  and the hand-written seams — it CANNOT detect a bug in the shared
  .lem semantics itself. VALIDATION.md already states this honestly;
  the work is shrinking it: (a) **F1.2** (gcc lane — external ground
  truth for defined behavior); (b) **expand externally-pinned
  expectations (S-M)** — tests/bytes already compares against
  committed upstream .exec records (9 files); import more
  external-expectation corpora wholesale (upstream's own expected
  outputs; GCC torture-suite executables' outputs via F1.2); (c)
  **CompCert's reference interpreter as a third semantics (S-M,
  network-gated install)** — `ccomp -interp` on the defined-behavior
  corpus is the closest thing to a second formal C semantics
  available off-the-shelf.
- **F5.2 The lem backend in the generation TCB (S)** — state the
  argument properly in VALIDATION.md: a backend translation bug
  produces OCaml/Lean divergence, which the differential battery
  *does* catch (different targets, uncorrelated failure) — the
  circularity is .lem-shared-semantics only. Add one seeded
  backend-bug mutation test to demonstrate the catch (rides F5.4).
- **F5.3 Construct-coverage instrumentation (M)** — a debug-mode
  counter in the driver tallying Core-constructor and memory-action
  hits; run the battery, publish the coverage table. Converts "well
  tested" from adjective to number, and its gaps feed axis 3 with
  data. (The reasoning era's census machinery is gone; this is a
  fresh, small, exec-side counter.)
- **F5.4 Mutation-score experiment (M)** — generalize the
  plant-test doctrine: seed N deliberate model bugs (wrong UB arm,
  off-by-one in memcpy, dropped store, swapped evaluation order),
  run the battery per mutant, report the catch rate and the
  survivors. The single best piece of quantitative evidence for the
  "well tested" claim an upstream conversation could ask for.
- **F5.5 CoreParser hash-id residual (S probe, M if acted on)** — the
  collision tripwire fail-stops, so soundness is guarded; the
  residual is fragility (MurmurHash64A numbering). A probe prices
  interned sequential ids; only act if the price is small — the
  tripwire is an acceptable steady state.
- **F5.6 ⊙ Elaboration-in-statement probe (M)** — shrink the C→Core
  trust link to the parser alone by starting differential points from
  the pinned C AST. Long-registered; genuinely axis-5.
- **F5.7 Baseline-freshness gate (S)** — the split found stale
  generated trees masking a real movement. Add a cheap freshness
  check (regen content-hash vs baseline provenance) so baselines
  cannot silently rot again.

## Axis 6 — Performance/scalability (trust-free by construction)

Operator framing, verbatim: "performance is also worth thinking about
if there are untrusted things we can do to make the semantics more
scalable. This is a nice thing about Lean — we can build optimizations
that don't affect our trust story." Every item below is classified by
its trust-preservation pattern: **(a) equivalence-proved swap**
(faster structure + kernel-checked equivalence lemma — strictly
trust-free), **(b) executable-face swap** (`@[implemented_by]`/csimp:
the definitional model unchanged; the swapped executable is
re-validated continuously by the differential battery — honestly
stated, the battery *samples* the swap's correctness, it does not
prove it; the executable face was already in the trust story on
exactly these terms), **(c) pure engineering** (no semantic surface).
Profile-before-design applies to everything not already measured.

- **F6.1 Fix the step-runner stack ceiling (M; pattern b or c)** —
  the real scalability bug: a few thousand loop iterations overflow
  the process stack in the step/ND recursion. The fix is making the
  run loop iterative/tail-recursive (or trampolined) at the
  *executable* face; the definitional fuel semantics is untouched.
  This gates everything long-running (big libxml2 TUs, kernel-scale
  functions) and is the top axis-6 item.
- **F6.2 Interpreter asymptotics audit (S probe → priced follow-up)**
  — the reasoning era measured O(depth²)-class accumulation in
  *proof-side* normalization; the question is whether the interpreter
  itself has analogous asymptotics on big programs (state threading,
  environment/map rebuilds, memory-map copies per store). One
  profiling pass over a large TU (chvalid.c / a big csmith file)
  with Lean's profiler answers it; fixes then classify as (a) or (b).
- **F6.3 Hot-path data structures (probe S; fixes M as pattern a/b)**
  — the Fmap/assoc-list structures in env/memory hot paths are
  correctness-first choices. If F6.2 fingers them: RBMap/HashMap
  swaps via equivalence lemmas (pattern a) or implemented_by (b).
  Profile first; no speculative swaps.
- **F6.4 Lane wall-clock (c)** — the 2.7h csmith full pass and the
  ~8min libxml2 lane bound the validation cycle. Cheap wins: the
  measured-safe 2× parallel build/run, sharding more lanes, driver
  startup amortization (batch mode reuse). A 10× faster battery is
  more validation per day (axis 5), bigger corpora feasible (axis 1),
  and every win is inherited by the successor repo (axis 4).
- **F6.5 Memory footprint (c, probe S)** — the 48G-cap era findings
  were proof-side, but the driver's footprint on big TUs is
  unmeasured; one profiling pass. Smaller footprint = more
  parallelism at fixed RAM.
- **F6.6 ND-branch evaluation strategy (b; M)** — the exhaustive
  runner forks per ND choice; branchy programs pay exponentially.
  Candidates: memoized/DAG-shared continuation evaluation, or
  single-trace-first with exhaustive-on-demand. The definitional
  outcome-set semantics is untouched; the runner is executable face.
- **F6.7 Driver-vs-oracle benchmark (S)** — measure Lean driver
  wall-clock against the OCaml oracle on the standard corpora and
  publish the ratio in VALIDATION.md. If competitive: a strong
  upstreamability talking point ("the Lean target costs you
  nothing"); if badly behind: F6.2/F6.3 get their targets. Either
  way, a number we should have.

## Suggested prioritization (operator decides)

1. **The S-basket, one slice** (F1.7, F1.8, F3.1–F3.3, F4.2, F4.5,
   F5.7, F6.7, F2.4): ~9 small items, each independently green, most
   long-registered. Clears the debt ledger and produces the
   benchmark number.
2. **F1.2 gcc differential lane (M)** — the best validity-per-cost
   move on the board; external ground truth at last (with F5.1b's
   external-expectation expansion riding along).
3. **F5.3 + F5.4 coverage + mutation instruments (M+M)** — makes
   "well tested" quantitative before the big fidelity work, so the
   PNVI port lands against instruments.
4. **F6.1 stack-ceiling fix + F6.2 asymptotics probe (M+S)** —
   scalability for kernel-sized inputs; gates big-TU work.
5. **F2.3 fork-delta triage (S-M)**, then **F2.2 re-sync + F2.1 tray
   filing at the next network window** — the upstream conversation,
   properly armed.
6. **F1.1 the PNVI port (L)** — the flagship, once instruments and
   re-sync are in place.
7. **F4.1 Lake packaging (M)** — timed to the successor repo's start.

## Upstreamability checklist (honest standing)

| Property | Standing |
|---|---|
| Multi-target lem discipline (target-conditional lem, OCaml byte-identity proven per change) | **Strong** — the fork's defining discipline; F2.4 writes it up for upstream eyes |
| Provenance/attribution (AI authorship declared, licenses respected, mirror citations per seam) | **Strong** — already in the shop-window docs |
| Validation story | **Strong and honest** (VALIDATION.md incl. does-not-establish clauses); becomes *quantitative* with F5.3/F5.4 |
| Code quality of hand-written seams | Good; the A-road polish basket is the known, priced debt |
| Docs | Fresh post-split (README/DESIGN/VALIDATION) |
| Delta hygiene vs upstream | **The gap**: ~52 manifest entries un-triaged for upstreamability (F2.3), pin 2.5 weeks stale (F2.2 — cheap) |

**Verdict: near-ready.** The blockers are administrative, not
technical: triage the delta (F2.3), re-sync the pin (F2.2), file the
tray (F2.1). The technical properties upstream would care about —
byte-identity discipline, zero OCaml-side movement, the differential
method itself — are the fork's strengths, and the tray's
oracle-wrong-Lean-right findings are the natural door-opener.

## Open questions

1. Compiler availability: gcc 13.3 is on-box (F1.2 can start now);
   clang and CompCert's `ccomp` need a network window — install both?
2. Network window scheduling for F2.1/F2.2 (fetch upstream, file the
   tray, push).
3. Appetite for the PNVI port (L) this season vs after the successor
   repo is running — it is the largest single item on the board.
4. Prototype final disposition (bare-mirror + delete) — standing
   confirmation.
5. Does the successor repo consume the semantics via Lake-git
   dependency (argues for F4.1 sooner) or vendored copy (later)?
