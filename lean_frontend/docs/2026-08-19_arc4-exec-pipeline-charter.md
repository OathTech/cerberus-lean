# Arc 4 charter: first differential execution ("exec pipeline")

Date: 2026-08-19. Mode: **long-cycle autonomous** — agent orchestrates,
makes and logs judgement calls, does not pause except for the emergency
exit defined below. Merge requires explicit operator sign-off and is NOT
part of the arc.

## Objective

C programs run through the FULL Lean pipeline — Cabs JSON → desugar →
typecheck → translate → **execute** — and the results are differentially
validated against OCaml cerberus on `tests/minimal`, with the differential
wired as an enforcing, baseline-tracked gate. This is the Phase-2/obj-2
frontier and the first point where the arc-1–3 substrate (pure, total,
gate-certified exec slice) actually executes programs.

## Probed state (2026-08-19 — the docs were stale)

- On `int main(void){return 42;}`: desugar, typecheck, and translation all
  SUCCEED (the recorded "desugar fails on stdlib Fmap entries" is fixed);
  execution reaches `CerbND.runND` and dies SILENTLY with rc=1 — no panic
  message, no "executions:" line. Root cause unknown (S0).
- `CerbND.runND` is real (hand-written exhaustive ND runner; the recorded
  "runND_proxy sorry" is stale). `easy_update_mem_value_aux` IS still
  sorry-target_rep'd — it is the memory-WRITE path, a certain blocker for
  any program that stores; it is also why driver2's cone carries sorryAx
  (arc-3 D9).
- Oracles available: OCaml `--exec` (probe returns rc=42 ✓), `--batch`
  (driver-verdict format), `--pp {cabs,ail,core}`;
  `scripts/canonicalize_ids.py` for id-insensitive Core comparison.

## Slices

**S0 — diagnose + frontier map.** Root-cause the silent rc=1
(LEAN_ABORT_ON_PANIC, stderr discipline, minimal driver probes; suspects:
runtime `sorry` evaluation, stack overflow in deep ND recursion, silent
IO-error path in Main). Sweep ALL of `tests/minimal` through the pipeline
recording the per-stage pass/fail frontier — decisions about S1–S3 scope
are made on that table, not on guesses. De-stale `lean_frontend/CLAUDE.md`
(pipeline status, runND) and ROADMAP's Phase-2 line.

**S1 — execution unblocked.** Fix the first-crash root cause. Eliminate
the `easy_update_mem_value_aux` sorry: preferred order (a) lem-backend
handling for the blocking shape (it is the self-shadowing partial
application `let f = f loc is_strong` — probe-first in tests/comprehensive
if a backend extension is needed), (b) hand-written Lean implementation
behind the existing target_rep seam (CerbMem-style latitude, mirroring the
OCaml semantics exactly), — never (c) restructuring the .lem model.
Same treatment for any further execution-path stub S0 uncovers.

**S2 — the differential harness: PORT, don't rebuild (obj 5).** The
prototype already has the harness this arc needs, battle-tested:
`cerberus-lean-prototype/scripts/test_interp.sh` runs OCaml
`cerberus --exec --batch` vs a Lean `--batch` interpreter with
return-value extraction, UB-code comparison, per-test timeouts,
exhaustive/deterministic modes, `--sequentialise`, and exclude lists.
Port it into `cerberus-lean/scripts/test_exec.sh`, retargeted at the
GENERATED pipeline binary (which likely needs a `--batch` output mode in
`Main.lean` matching the prototype's format — hand-written latitude).
Keep the ported harness fail-closed with absolute paths and a committed
baseline file (`test_core.sh` pattern: regression vs baseline fails the
gate even mid-arc). Survey the rest of the prototype's differential kit
while there and record a port/skip disposition for each:
`test_coverage.sh` + the 199-file/21-category `tests/coverage` corpus,
float/debug corpora, `test_pp*.sh` mismatch finders,
`fuzz_csmith.sh`/`gen_csmith.sh`/`creduce_interestingness.sh`,
`strip_core_json.py`. Prototype stays read-only (obj 5: reuse without
design bending — no absorbing its hand-written interpreter).

**S3 — corpus sweep to the bar.** Fix mismatches batch-wise (delegate
mechanical batches; orchestrator re-runs gates on every batch — agent
green is never accepted). Every persistent mismatch gets a classified
record (bug class, affected tests, plan). Model edits remain
declares-only; hand-written Lean and lem-backend changes are the
correction surfaces.

**S4 — stage differentials as debugging demands.** At minimum: elaborated
Core vs OCaml `--pp core` (via canonicalize_ids) wired as
`scripts/test_elab.sh` in reporting mode; Ail-level diff only if S3
debugging shows it pays. These are tools for S3, not ends.

**S4b — corpus expansion (after the minimal bar is met).** Run the ported
harness over the prototype's `tests/coverage` corpus (199 files, 21
semantic categories) and commit the result as a TRACKED reporting-mode
baseline — numbers recorded per category, not gated this arc; it becomes
the obj-2 parity scoreboard. Float/debug corpora likewise if they run.
csmith fuzzing: check whether the csmith binary exists in the sandbox; if
yes a smoke run (small N) with findings recorded; if no, record as a
networked-window item. Fuzzing at scale is explicitly NEXT-arc.

**S5 — close-out.** The two arc-2 Phase-2 obligations land here since
execution now exercises them: the sym non-escape check and the
`int a[sizeof(struct S)]` const-expr test. Results doc, decision log,
2-agent adversarial audit (scope at minimum: differential-harness
soundness — does a mismatch REALLY fail the gate; sorry-elimination
correctness vs OCaml semantics; baseline honesty), fix-or-record, pins
synced to arc tips, merge checklist. **Stop. Do not merge.**

## Success conditions (machine-checkable)

1. `./scripts/test_exec.sh` enforcing with committed baseline:
   **≥ 95/105** of `tests/minimal` execute in Lean with verdicts matching
   OCaml; target 105. Every non-matching program (≤ 10) carries a
   classified record. Falling below 95 is a replan trigger, not a bar to
   lower.
2. Kernel-level stub elimination: `driver2`'s axiom cone is
   **sorryAx-free** (checked in `check_theorem_axioms.sh` — extend the
   probe; DAEMON may remain, recorded per arc-3 D9). No sorry target_reps
   on the execution path.
3. All standing gates green at every commit: OCaml prelude+dune build,
   `lake build` full-green, `test_unit.sh` 4/4 (purity CLEAN, cones OK,
   totality CLEAN 0-allowlisted), `test_parse.sh` ALL, `test_core.sh`
   ≥ 104/105.
4. Model `.lem` edits declares-only; any lem-backend change probe-first
   with comprehensive-test coverage incl. negative probes where a guard
   is added; OCaml artifact token-neutral.
5. Prototype-infra disposition: every item in the S2 survey list carries
   a recorded port/skip/defer decision; the ported harness's comparison
   semantics match the prototype's (return value + UB class), verified in
   the audit; the `tests/coverage` differential baseline is committed
   (reporting mode, per-category numbers).
6. Records: `docs/2026-08-19_arc4-decision-log.md` (every judgement call),
   results doc, audit dispositions, de-staled docs; end state = arc
   branches (`arc/exec-pipeline`) gate-green, pins aligned, merge
   checklist ready, mainlines untouched.

## Known risks (pre-declared mitigations)

- Silent-death debugging can rathole → time-box per hypothesis, log, move
  to the next; the frontier MAP (S0) exists precisely so the arc never
  blocks on one program.
- Exhaustive ND may blow up on some corpus programs → per-program timeout
  in the harness; timeout = classified mismatch, recorded, not a hang.
- Fuel exhaustion in real runs → panics are fail-stop under the harness
  (`LEAN_ABORT_ON_PANIC=1`, arc-3 F10); an exhaustion on the corpus is a
  finding to record (and a `lemDefaultFuel` decision to log), never a
  silent wrong answer.
- `easy_update` semantics risk: the hand-written fallback must mirror
  `defacto_memory.lem`/OCaml exactly — audit scope includes it explicitly.

## Autonomy protocol

Orchestrator/worker doctrine (container CLAUDE.md, 2026-08-19): the arc
runs as sequenced subagent workers — S0 diagnosis, S1 fixes, S2 port, S3
mismatch batches, S5 audits. The orchestrator SCOPES each worker exactly
(files, mechanisms, validation commands, park-don't-improvise) and
VERIFIES independently at batch boundaries; WORKERS COMMIT their own work
(only on green gates, one coherent commit per slice, message states what
was verified). Merge lives with the user — checklist prepared, ff-only
execution only on explicit sign-off. Worker model choice is an
orchestrator call per task (delicate vs mechanical). Judgement calls are
the orchestrator's, resolved by project principles (OCaml parity,
declares-only, honest failures, fail-closed gates, no global state),
logged in the decision log. Work on `arc/exec-pipeline` worktrees in both
repos as needed; primaries stay parked. This arc is a single stream;
parallel streams (per the doctrine) would claim disjoint worktrees and
write surfaces.

**EMERGENCY EXIT:** always permitted, nature declared. Tripwires: bar
unreachable (<95 with fixes exhausted), a mechanism found unsound (not
merely laborious), any gate keepable-green only by weakening it, anything
that would require machine-global state.
