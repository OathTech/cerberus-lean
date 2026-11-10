# Worker charter: the cerberus re-pin for lem TODO 54 (closes the pin invariant)

Date 2026-11-10. Orchestrator [AGENT]. Branch `arc/todo54-repin`, worktree `worktrees/cerberus-lean-arc/todo54-repin`,
base = mainline `mdd/cerberus-lean` `b66374eac`. Roadmap: `docs/2026-11-10_roadmap-maintenance-and-reporting.md`,
active item 1 ([USER 2026-11-10]). A second worker (the reporting slice, documents only) runs in
`worktrees/cerberus-lean-docs/reporting`: do not touch it or the primary checkout.

## Goal

The lem mainline `mdd/lean-backend` is at `2220010` (the landing note over `df9743c`, TODO 54: unreferenced binders
bound `_name`, `termination_by structural` only where the derived definition recurses). The cerberus pins are still
`e6d8db5`. Re-pin cerberus to `2220010`, regenerate, and land a tree with ZERO linter warnings in the generated
modules. Read first: lem-lean `doc/lean-backend/2026-11-07_consumer-note-cerberus-unreferenced-binders.md` (the
recipe and the expected delta), its record and review beside it, and this repo's last re-pin record
`docs/2026-10-25_lean-4.35-cerberus-record.md` for the shape.

## What the orchestrator has already done (shared state, outside your worktree)

`deps/lem-pinned` is reset to `2220010` and the shared opam switch's `lem` is upgraded to it BEFORE you start (the
orchestrator's message confirms it with `lem -v`). You do not run `opam` package commands.

## M1: the re-pin

- Every pin site to `2220010`'s full hash: `lean_frontend/lakefile.toml`'s `[[require]]` `rev`, then the three Lake
  manifests through `scripts/ce` + `scripts/capped` `lake update LemLib` in each package (if a step needs the network
  and fails, STOP and report the exact command for the operator to run; do not hand-edit a manifest's hash without
  saying so), `scripts/fork_drift_manifest.txt`'s `lem-pin`, the README's newcomer pin command, the dated lines in
  `lean_frontend/CLAUDE.md`. `check_pin_sites.sh` is the judge.
- `scripts/ce make clean-prelude-src prelude-src lean-prelude-src`, both engines rebuilt. The generated OCaml must be
  byte-identical to the base (prove it: a tree diff of `ocaml_frontend/generated/` before/after = empty). The Lean
  delta must be exactly the measured one — 147 `termination_by` clauses removed, 601 binders renamed `_name`, 75
  derived-`Inhabited` binders to `_`, 52 modules, no double underscore, token-level — classify every hunk; any other
  hunk is a finding to report, not to absorb.
- Hand-written code that breaks (a named argument on a renamed parameter, a measure proof naming a binder): fix at
  the site, minimal, listed in the record. No `set_option`, no heartbeat or recursion-depth change, no linter option.
- Zero warnings: after the capped build of every root, the stored Lake logs (`.lake/build/lib/lean/**/*.trace`, the
  `log` entries with `level` `warning`) carry none for modules of the tree; delete the stale artefacts of modules no
  longer in the tree (`Core_unstruct`, the `relsem/` remnants) BY NAMED PATH and say which. Hand-written warnings, if
  any remain, are fixed properly. Then add `-DwarningAsError=true` to the root package's `moreLeanArgs` if and only
  if the whole tree (tests and speclab included) builds clean under it; if not, report what blocks it.
- Gates you run: `check_pin_sites.sh`, `check_fork_drift.sh` (+ `--selftest`; the `[source-content]`/`[expected-
  semantic]` rows must NOT move: OCaml identical), `check_handwritten_sync`, `check_failure_reach.sh` (+ selftest;
  rows keyed by position may move: re-key by the gate's own path with a dated note, classes unchanged),
  `check_fuel_forms.sh` (+ selftest), `gen_fuel_parametricity.py`, `check_theorem_axioms.sh`, `check_exec_totality.sh`,
  `check_lakefile_roots.sh`, `libc_prep.sh --check`, the CoreQuote digests (`test_unit.sh core-quote-test`: generated
  Lean text of definitions changed, so say whether any quotation digest moves and why).
- KERNEL REPLAY is owed (named trust gate): every `*_lemMeasureProofs` module, the Props-only seams, `CerbMem*Facts`,
  the exemplar: `lake env leanchecker <modules>` through `capped`, modules and exit status quoted.

## M2: the two riders

- `scripts/inner_arg_temps_lane.py`: the baseline hash of a RESOURCE row must not include the kill KIND (memory cap
  versus wall clock), as the file's own comment at the `same_failure` helper already states; the 2026-11-09 landing
  notes `68470dc91` and `03c8b4451` record the flake. Fix the hash, re-record ONLY the affected rows through the
  lane's own `--record-baseline` path, extend the lane's selftest with the KILL-versus-TIMEOUT case, run `--gate`.
- A row in lem-lean's TODO is NOT yours to write (another repository); instead list in your record the two GNU make
  recipe-override warnings (`Makefile:10`, `ocamlbuild.mk:20`) for the orchestrator to log there.

## M3: the record

`docs/2026-11-10_todo54-repin-record.md` (what moved, the hunk classification table, the hand-written fixes, the
warning census before/after as DERIVED counts, every gate's last lines verbatim, the replay), VALIDATION/LADDER only
where a statement about warnings or the lane changed, the container doc's pin line is the orchestrator's. Consumer
notes for cerberus-caesium and cerberus-sl: generated binder names changed (`x` to `_x` where unreferenced), which
matters to any consumer proof that names a generated binder by named argument; definitions are otherwise unchanged.

## Process

Focused gates only; never `scripts/release.py` (the orchestrator runs Tier A on M1 and the battery on the tip). Every
make/dune command through `/home/dev/projects/cerberus-lean-proj/scripts/ce`; every lake/lean through
`scripts/capped`, `CERB_MEM_MAX=32G`. Check `/proc/loadavg` (< 12) and `free -g` before heavy jobs; long runs through
the harness's background execution; no poller, watcher or sleep loop; never `pgrep -f`/`pkill`. No network; `/tmp`
unreadable; scratch under the worktree's `.tmp/`, deleted at the end. Commits per milestone on green gates, messages
state what was verified, provenance tags, never quote the operator, end with
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing pushed; no mainline commit. A blocker the charter
does not resolve: a committed park record and a stop. A build approaching an hour: stop and report.
Report: hashes, `git diff --stat b66374eac..HEAD`, gate lines verbatim, the classification table, what was not done.
