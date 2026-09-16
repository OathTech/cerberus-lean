**Bounded evidence for the D2 outcomes design review (2026-09-16).**

These are review probes, not production semantic changes. The response is
[the accompanying review note](../2026-09-16_lean-only-outcomes-review-response.md).

The three Lem files define a shared stop payload and reduced versions of the
two result channels. Locations and UB payloads are strings in this probe.
`Unsupported` includes the diagnostic string recommended by the response.
The installed Lem tool generates both OCaml and Lean without a backend change.

- `Probe.lean` proves elementary stop transport, constructor separation, and
  preservation of an old bind under embedding. Its generic-default equation is
  a negative witness: appending `Stopped` introduces default exhaustion.
- `ProbeBefore.lean` imports the existing compiled provider `Undefined` module
  and proves its current generic default is an ordinary `Error`. This import
  uses the already-built provider, not a rebuilt complete project.
- `Traversal.lean` models the outer-map/inner-sequence pattern in
  `State_exception_undefined.mapM`. Its two negative witnesses show post-stop
  state updates and replacement of a stop by a later outer exception. It is
  a reduced pattern model, not an executed C regression.
- `Native.ml` checks all three stop reasons through the generated bind, kill
  mapping, and channel conversion. It also demonstrates that wildcard
  swallowing compiles with OCaml warning 8 fatal.
- `results.txt` is the captured reproduction run, including source hashes and
  exit statuses. All ten kernel lemmas reported no axioms.

Run from the project workspace, with a built provider checkout:

```sh
./scripts/ce cerberus-lean/scripts/capped python3 \
  worktrees/cerberus-lean-d2-outcomes-response/lean_frontend/docs/2026-09-16_lean-only-outcomes-review-evidence/reproduce.py \
  --provider /home/dev/projects/cerberus-lean-proj/cerberus-lean
```

If the documentation has moved or landed, adjust only the script path. The
provider argument must name the checkout with the existing generated Lean
artifacts and pinned LemLib build. `scripts/ce` supplies the project-scoped
OCaml/Lem environment; the reproduction script selects the provider's Lean
toolchain explicitly. `scripts/capped` bounds the complete probe process tree.
Generation and compilation take place in a temporary directory, removed on
exit; the provider and source files are not modified. The script does not
download dependencies or rebuild the provider.

This checks the small source models and the imported default equation. It
does not prove a complete source-to-native translation theorem, establish
whole-driver fuel refinement, or replace the production migration gates.
