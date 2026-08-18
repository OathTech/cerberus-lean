# Arc 3 merge checklist (awaiting operator sign-off — do not merge without it)

State at close: both arc branches gate-green; pins aligned at the lem arc
tip (`60932e8` = Lake manifest = deps/lem-pinned = opam-installed lem);
full re-certification done from pins alone (no PATH overrides).

Merge order (ff-only, exactly — per playbook):
1. lem-lean: `git merge --ff-only arc/totality-sweep` into `mdd/lean-backend`.
   ff preserves commit ids, so `60932e8` remains valid everywhere after
   the merge — no opam/Lake re-pin of the COMMIT is needed.
2. cerberus-lean: flip `lean_frontend/lakefile.toml` rev
   `arc/totality-sweep` → `mdd/lean-backend` (same commit), `lake update
   LemLib` (manifest hash unchanged), commit; re-run the full gate;
   `git merge --ff-only arc/totality-sweep` into `mdd/cerberus-lean`.
3. Post-merge: update container CLAUDE.md pins/known-issues and ROADMAP
   (arc 3 marked merged; totality gate now part of the standing gate).
4. Prune arc worktrees; primaries rebuilt + certified on merged tips.

Validation gate (must be green at every step): lem-lean `make` +
comprehensive `make lean` (incl. negative lane); cerberus OCaml
prelude+dune, `lake build` 354/354, `test_unit.sh` 4/4 incl. purity CLEAN
+ axiom cones OK + totality CLEAN(0 allowlisted) ENFORCING,
`test_parse.sh` ALL, `test_core.sh` 104/105 (078-float-special is the
known red).

Audit: 2-agent adversarial audit run at arc close (scope: gate soundness,
sentinel honesty, OCaml-artifact neutrality, lem guard coverage);
dispositions in the decision log. The merge itself requires explicit
operator sign-off per the playbook — the ask is unconditional.
