# Concurrency feature branch — working brief (2026-09-04)

Branch `feature/concurrency`, worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-feature/concurrency`,
based on mainline `mdd/cerberus-lean` @ `1b57bcf26` plus the scoping
note `docs/2026-09-04_concurrency-scoping.md` (read it first — it is the
charter input: measured state, the oracle problem, phases 0–2, the
deconfliction table). This brief is the operating contract for the agent
working the branch. Provenance: the orchestrator [AGENT], at the
operator's direction [USER 2026-09-04] ("set up a worktree / branch
suitable for an agent to work on, with the explicit briefing that main
and other worktrees are held by you").

## Ownership — what is yours and what is not

- **Yours:** this worktree and branch `feature/concurrency`, and nothing
  else. Commit here; work on sub-branches of it if you like, inside this
  worktree.
- **Held by the sequential orchestrator (do not touch, do not commit, do
  not check out):** the primary checkout `cerberus-lean/` (parked on
  `mdd/cerberus-lean`), the mainline itself, `lem-lean/` and its
  worktrees under `worktrees/lem-lean-*`, the sequential arc worktree
  `worktrees/cerberus-lean-arc/*`, the docs worktrees
  `worktrees/cerberus-lean-docs/*`, the `upstream-pr-*` worktrees,
  `deps/` (read-only for everyone; `deps/lem-pinned` is the opam pin
  source), `refined-cerberus/` (another agent's repo; read-only), the
  container `CLAUDE.md` and `scripts/`.
- **Merges:** `feature/concurrency` merges ff-only into `mdd/cerberus-lean`
  ONLY through the orchestrator, after a rebase over whatever sequential
  arcs landed, with the unconditional pre-merge audit and operator
  sign-off. You never merge, never push, never touch mainline. When you
  believe a slice is mergeable, say so in your record and stop.
- **Rebases:** the sequential arcs will move the mainline under you
  (`arc/fuel-parameter-cerberus` C1 and C2 first; then Z3, Z4). Rebase
  `feature/concurrency` onto `mdd/cerberus-lean` at each sequential
  merge (the orchestrator announces them); the expected textual
  collisions are in the scoping note §4 (`driver.lem` different hunks;
  one line in `Main.lean`'s flag loop; `CerbGlobal.lean`).

## Working practices that bind you (the repo's, summarised; the container `CLAUDE.md` is authoritative)

- Every `lake`/`lean`/Lean-binary invocation through `scripts/capped`
  with `CERB_MEM_MAX=32G`; lanes run SERIALLY; never two differential
  lanes at once on this box; do not run the sequential battery (Tier A/B)
  while the orchestrator's workers are running theirs — ask via the
  operator if unsure. `ulimit -c 0`.
- Commit only on green gates for what you changed; one coherent commit
  per slice; commit messages state what was verified. Records are dated
  files in `lean_frontend/docs/`; decisions carry `[USER]`/`[AGENT]`
  provenance; quoted outputs verbatim, derived tallies labelled.
- Fail-closed, fail-noisy: no `2>/dev/null` on build steps; no `partial`
  in the execution cone (the totality gate); no `sorry`; no new axioms
  (the census gates); no `native_decide`/`bv_decide`; no heartbeat or
  maxRecDepth bumps (a bump is a defect — report it). Hand-written Lean
  files are listed in `lean_frontend/handwritten_copy.manifest` and
  copied by `make lean-prelude-src`; the sync gate refuses otherwise.
- Mirror-OCaml doctrine for hand-written seams: cite `file:line`; the
  concurrency MODEL is `.lem` and is generated — do not hand-write what
  the generator produces.
- No magic values ("No magic values", `lean_frontend/DESIGN.md` §4):
  fuel, bounds, scheduler choices are quantified parameters, never
  numerals in definitions; the fuel-parameter arc's `[LemFuel]`,
  `fuel_measure`, `structural` declares (lem-lean
  `doc/lean-backend/DESIGN.md`) are the mechanisms — the scheduler's
  nondeterminism is ND branching, which the runner already enumerates.
- The semantics is a reasoning artifact for refined-cerberus: a design
  choice a theorem cannot quantify over or unfold is a defect
  (`docs/2026-09-03_reasoning-artifact-audit.md`).
- Any change to shared `.lem` bodies is a fork feature that changes the
  OCaml oracle too: allowed HERE only for the concurrency arm the OCaml
  side lacks (scoping note §2 O1), cited against upstream history,
  recorded, and tray-drafted (`docs/upstream-tray/`). Do not restructure
  `.lem` for Lean's sake ([USER 2026-09-04] "we don't change the lem
  structure for ocaml").

## Environment caveat (temporary)

The opam-installed `lem` is `742506d` (the fuel-parameter lem). Until
slice C1 of the fuel arc merges, `make lean-prelude-src` on THIS tree
FAILS at the five numeric fuel declares (`frontend/model/driver.lem:1915-1918`,
`nondeterminism.lem:574`) — the new lem refuses them by design. The
worktree's primed `generated/` and binaries are the mainline's (built
with lem `3c88f0d`) and are fine for running probes and the existing
lanes. Do not "fix" the declares here: C1 deletes them on the sequential
side; rebase when the orchestrator announces C1's merge. Until then,
Phase 0's first tasks need no regeneration: recovering upstream's
pre-2019 `perform_action_request2` concurrency arm from
`deps/cerberus-upstream`'s history (read-only), the litmus corpus and
herd7 plan, and the Phase-1 design questions (scoping note §5).

## Phase 0 — first tasks (from the scoping note §3)

1. Archaeology: find the last upstream revision where `--concurrency`
   worked (`git -C deps/cerberus-upstream log -S"perform_action_request2"`
   and the `concurrency_state` plumbing); record the commit, the shape of
   the arm, and what it relied on (SMT constraints via `smt2.ml`?).
2. The litmus oracle plan: which corpus (Nienhuis's validation set; the
   RC11 paper tests), herd7 availability (network window — ask the
   operator), the lane's contract (allowed-outcome SETS agree three ways:
   OCaml, Lean, herd).
3. A written Phase-0 charter (dated record) with the restored arm's
   design, the ND treatment of scheduling, the fuel treatment of the
   cmm modules, the fate of the 23 unreferenced `sorry` target_reps in
   `cmm_csem.lem`, and the exit criteria — for operator sign-off BEFORE
   code, per the design-pass rule.
