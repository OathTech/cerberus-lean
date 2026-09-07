# Codex charter — trust-surface risk map, BASELINE pass (2026-09-07)

**Role:** independent risk auditor. **Read-only on every source, script,
test, baseline and pin.** You deliver ONE record file (plus, optionally,
small plain-text evidence files) on this branch. You touch nothing else.

This charter was written by the orchestrator [AGENT] under the operator's
ruling [USER 2026-09-05], verbatim:

> "A good thing to schedule at the end of this would be a whole-project
> risk map which says whether there has been movement wrt the trust
> surface. We're doing a lot of surgery, all reasonable, but we'll want to
> make sure we aren't disturbing the core cerberus correctness properties."

and the master plan's step 1 (`lean_frontend/docs/2026-09-05_master-plan.md`
§3, revision 9): "Risk-map BASELINE by an independent auditor — now …
per trust surface: moved/unmoved · evidence · residual risk · mover.
Repeated at step 7." [USER 2026-09-07]: "We can use codex as a separate
risk auditor."

## 0. Anchors (fixed by the orchestrator; do not choose your own)

| Anchor | Value |
|---|---|
| Baseline A — the semantics-first split record | cerberus-lean `7c66b39a4` (`lean_frontend/docs/2026-08-31_semantics-first-split.md` is its record) |
| Baseline B — mainline at end of 2026-08-31 (after the effect-retirement C1/C2 landed) | cerberus-lean `ae1a5448c`; lem pin then `045dcb0` |
| HEAD under audit | cerberus-lean `df1fdaf02` (= `mdd/cerberus-lean`), lem-lean `f6542f8` (= `mdd/lean-backend` = `deps/lem-pinned` = opam `lem` = every Lake `LemLib` rev) |
| Upstream Cerberus merge-base | `b9aeedcb4` (`deps/cerberus-upstream/`, pristine) |
| Consumer | `refined-cerberus` `main`; its `scripts/semantics-pin.env` names the cerberus commit it builds against — READ it, do not edit that repo |

Report every surface against BOTH baselines where they differ; A is the
definitional "product = the semantics" point, B is where the 2026-08-31
seam rulings were made. Cite commits by SHA; quote outputs verbatim;
label every tally you compute as derived.

## 1. Deliverable — the record, ordered sections

File: `lean_frontend/docs/2026-09-07_risk-map-baseline.md` on this branch.
Every section ends with a four-field verdict line for its surface:
`VERDICT: <UNMOVED | MOVED-WITH-RULING | MOVED-UNRULED | UNKNOWN> · evidence: <what you measured, with the command or file:line> · residual risk: <one sentence> · mover: <a named task from TODO.md / the master plan, or NONE>`.
"Cited by a record" is not evidence; only what you re-derived or re-ran
on this worktree counts. Where you could not measure, write UNKNOWN and
say why — never infer.

### §1 The oracle (the fork's OCaml is the working oracle)
1. `git diff <baseline> HEAD -- '*.lem'` for A and for B: list EVERY hunk
   and classify it: (a) Lean-target-only declare line (`declare {lean} …`,
   `fuel_measure`, `structural`, `fuel val`, target_rep) — no OCaml
   effect; (b) a body/type change visible to OCaml; (c) other. Any (b)
   or (c) is a finding: name it, and check whether the fork-drift
   manifest's reviewed 22 generated deltas already cover it.
2. Re-run `scripts/check_fork_drift.sh` (no `--refresh`, no dev-skip)
   AND, independently of it, re-hash the fork's `ocaml_frontend/generated`
   tree against `deps/cerberus-upstream/ocaml_frontend/generated`: report
   the differing-file set and whether it equals the manifest's 22.
3. The pristine-vs-fork EXECUTION lane (`python3 scripts/test_upstream_oracle.py`
   after `scripts/build_independent_oracle.py … --out .validation-foundations/independent-oracle-v2`,
   both through `scripts/ce`): run it; report its classification counts
   and read the one "reviewed difference" yourself (`scripts/upstream_oracle_differences.json`).
4. Hand-written oracle files (`util/cerb_fresh.ml`, `ocaml_frontend/fork_renumber.ml`,
   `backend/driver/main.ml`, …): diff against `deps/cerberus-upstream`;
   for each hunk say what behaviour it changes and which record reviewed it.

### §2 Execution behaviour
1. Rebuild from scratch in THIS worktree with the cache disabled
   (`scripts/ce`; `DUNE_CACHE=disabled`; `make lean-prelude-src`;
   `../scripts/capped lake build` under `CERB_MEM_MAX=48G`) and run the
   FULL Tier A + Tier B battery per `scripts/LADDER.md` (the ladder's tables
   are the membership; `python3 scripts/release.py --mode full` executes
   them — use it, but ALSO run `./scripts/test_unit.sh` and the four
   `test_exec.sh` baseline lanes directly, so the runner is not your only
   witness). Quote every SUMMARY / BASELINE / rc line verbatim.
2. Movement analysis: for every baseline file under `scripts/*baseline*.txt`,
   `tests/libc_exec/baseline.txt`, `tests/immaculate/baseline.txt`,
   `tests/litmus/*` (if present), `scripts/gcc_oracle_baseline.txt`:
   `git diff <baseline> HEAD -- <file>` and attribute EVERY moved row to
   exactly one of: an ISO-fix register entry (R1–R3, `VALIDATION.md` §2),
   a ruled re-record (name the record and the [USER] line), an instrument
   re-record (name the commit), or UNEXPLAINED (a finding).
3. The exception classes (a)–(d) in `VALIDATION.md` §1: are they the same
   four as at baseline B? Quote both versions if not.
4. The csmith corpus: do NOT run the full 1,669-file sweep (2.7 h; the
   2026-09-06 sweep is on record). Run ONE shard (`--shard 2/6`) and
   confirm the two registered pending rows (`sa_csmith_369/371`) are the
   only movement; read `docs/2026-09-06_csmith-sweep-post-p0.md`.

### §3 The definitions consumers reason about
For each of: the fuel parameter (`[LemFuel]`, `CerbFuel`, `--fuel`),
the measured wrappers and their `_measure_sufficient` obligations, the
absorbing payloads (`_zero` lemmas), the deleted/renamed wrappers since
baseline, `CerbGlobal` plain defs, the `CerbTagsWf.Acyclic` hypotheses,
the Pmap/Fmap laws in LemLib:
- what is the claimed zero-execution-effect, and is it evidenced by a
  THEOREM (name it, run `#print axioms` or the repo's cone gate on it),
  a PIN, or the battery only? Where it is only argued, say so.
- run `scripts/check_fuel_forms.sh` and `scripts/check_no_fuel_numerals.sh`
  and quote their OK lines; re-derive the 81/54/13/8/6 census from the
  tool's table, not from the OK line.
- read the consumer's actual uses: grep `refined-cerberus` (read-only)
  for the cerberus-lean constants it imports; list which of them changed
  signature since baseline B.

### §4 The trust base
1. Axiom census: `scripts/check_theorem_axioms.sh`, `scripts/check_sorry_token.sh`,
   `scripts/check_exec_purity.sh`, `scripts/check_exec_totality.sh` — run,
   quote; then INDEPENDENTLY grep the tree (hand-written, generated, LemLib
   at `deps/lem-pinned/lean-lib`) for `axiom `, `sorry`, `native_decide`,
   `bv_decide`, `ofReduce`, `maxHeartbeats`, `maxRecDepth`, `implemented_by`,
   `extern`, `unsafe`, `partial def`. Reconcile against
   `scripts/unsafebaseio_allowlist.txt` and `scripts/exec_totality_allowlist.txt`
   (both directions).
2. The declared runtime-boundary list (`VALIDATION.md` §9) vs the
   allowlists vs what the grep finds: three sets — report the symmetric
   differences.
3. ISO-fix register: exactly the entries R1–R3? Each with its `-- ISO-fix
   register R<n>` code marker present (grep) and its immaculate pin row?
4. Boundary rows that LEFT or ENTERED since baseline B (e.g. `CerbGlobal`
   left 2026-09-05): for each, the record and the ruling line.

### §5 Gates
1. Diff the gate set: `scripts/test_unit.sh` and `scripts/LADDER.md` at
   baseline B vs HEAD — every gate added, removed, weakened or strengthened.
2. For every gate with a `--selftest`/plant mechanism: run it; quote the
   SELFTEST OK line; then pick ONE plant per gate and confirm by reading
   the code that it is structurally forcing (a vacuous plant is a finding).
3. Environment dependence — the class that bit three times in a week
   (locale; TERM/NO_COLOR styling; dune lock under concurrent batteries):
   run `./scripts/test_unit.sh` twice, once with `LC_ALL=C TERM=dumb`
   and once with `LC_ALL=en_US.UTF-8 TERM=xterm-256color` exported in
   YOUR shell; both must be green; quote both tails. Then read
   `scripts/common.sh` and list every environment variable the harness
   pins or reads.

### §6 Consumer surface
1. Read `refined-cerberus/scripts/semantics-pin.env` and their DECISIONS /
   KNOWN-OPEN-ITEMS (read-only): which cerberus-lean commit do they build
   against; which change manifests (`*-change-manifest.md` in this docs
   dir since baseline B) have they adopted; which of our landed changes
   are NOT yet reflected in their pin.
2. List what became PROVISIONAL for them: hypotheses they must now
   discharge (`Acyclic`), lemmas they were promised (`_zero`, sufficiency,
   Pmap laws) and whether each exists at HEAD with the stated statement.

### §7 Summary table and the two-line answer
One row per surface with the four fields, then the operator's question
answered in two sentences: has the trust surface moved since the split,
and is every movement ruled.

## 2. Rules (binding)

- **Read-only.** No edits under `scripts/`, `tools/`, `lean_frontend/`
  (except your new files under `lean_frontend/docs/`), `frontend/`,
  `backend/`, `util/`, `tests/`, `native/`, pins, manifests, baselines,
  `.gitignore`. If a gate is RED, that is a FINDING to record, never
  something to fix. Do not re-record any baseline. Do not run `--refresh`
  or `--record-baseline` on anything.
- **File fence.** The only files you may create: the record above, and
  plain-text evidence files under `lean_frontend/docs/2026-09-07_risk-map-baseline-evidence/`
  (verbatim command outputs; ≤ 1 MB total; NO archives — `*.tar*` is
  gitignored there by rule [USER 2026-09-06]; runs must be reconstructible
  from the commands you quote). Snapshot rule: `git status --porcelain`
  at the end must list ONLY those paths.
- **Independence.** The records under `lean_frontend/docs/2026-09-0*`
  are INPUTS you check, not ground truth — including those written by a
  previous Codex instance (`2026-09-06_supported-profile.md`,
  `…validation-foundations-*.md`) and by the orchestrator. Where your
  measurement contradicts a record, the contradiction is a finding with
  both values quoted.
- **Environment.** `source /home/dev/projects/cerberus-lean-proj/scripts/env.sh`
  (or prefix with `scripts/ce`). Every `lake`/`lean` invocation through
  `scripts/capped` with `CERB_MEM_MAX=48G`; never `CERB_MEM_MAX=none`;
  if the sandbox denies the cgroup cap, STOP and report. One heavy job at
  a time. Work ONLY in this worktree (`worktrees/cerberus-lean-audit/risk-map-baseline`);
  read other repos in place; never touch `cerberus-lean/` (the primary),
  `worktrees/cerberus-lean-feature/concurrency`, `lem-lean`, `deps/`,
  `refined-cerberus` (Codex's other work lives there — read-only).
- **Never** modify machine-global state; never push; never commit on any
  branch but `audit/risk-map-baseline`; never `2>/dev/null` a gate step.
- **Tripwire.** Any single build/lane pass approaching one hour: stop that
  pass and record it as UNKNOWN with the elapsed time. (The full battery
  as a whole is ~1.5–2 h of many short lanes; that is fine and pre-justified
  here as a differential measurement.)
- **Provenance.** Quote verbatim; mark derived tallies "derived"; your
  judgments are [AGENT auditor]; operator lines are [USER date] and only
  from the records — never paraphrase a ruling as a quote.
- **Stop rules.** Stop and write the record when §1–§7 are done, OR when
  a MOVED-UNRULED verdict appears on the oracle surface (§1) — that one is
  reported immediately, alone, before continuing. Commit the record on
  this branch with a message that states what was run; do not merge.

## 3. Reading list (in order; skim then measure)

`CLAUDE.md` (repo) · `lean_frontend/CLAUDE.md` · `lean_frontend/VALIDATION.md`
(§0–§2, §6–§9) · `scripts/LADDER.md` · `lean_frontend/docs/2026-08-31_semantics-first-split.md`
(baseline A) · `…2026-08-31_trust-basket.md` and `…2026-08-31_effect-retirement-design.md`
(the seam rulings behind baseline B) · `…2026-09-05_whole-project-release-gate-audit.md`
+ `…-response.md` · `…2026-09-05_master-plan.md` §0 (rulings verbatim) ·
`…2026-09-06_supported-profile.md` (a claim set to test) · the
`*-change-manifest.md` files since baseline B (what consumers were told
changed) · `../refined-cerberus/docs/DECISIONS.md` (read-only).
