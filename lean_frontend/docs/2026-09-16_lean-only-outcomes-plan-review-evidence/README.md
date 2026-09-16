# Evidence for the implementation-plan review

[AGENT] Bounded review probes against the S0 prototype
`8f8c4dfe7bf30c8733d2ea9590f8f5ef3c4a930b`, Lem `f6542f8`, Lean 4.32.2,
and OCaml 5.4.0. The proposed implementation plan is `bfca41724`.

- `PrefixStop.lean` imports the preserved S0 traversal candidate. Four kernel
  lemmas show that earlier legacy failures hide any stop reason, and distinguish
  this outcome from the old layering and a completed intermediate callback.
  The S0 module's 14 lemmas are rechecked before these four. Axiom output is
  limited to the standard `propext` and `Quot.sound`.
- `NativeOrder.ml` uses reduced undefined-result payloads and the generated
  `Exception`/`State_exception` modules from S0. It compares the old layering
  with direct recursive collectors, using no stop producers. The controls
  expose skipped native failures in EU and state-action construction, and
  changed callback order. The copied generated modules have only their unused
  `open Utils` line removed to compile in isolation; their definitions are
  unchanged. Lem's installed native library supplies `Lem_list.map`.
- `default_alias.lem` uses an already underivable type to exercise `Inh_none` in
  the current generator. Its direct-field fallback is excluded, while the
  aliased version is emitted. This is an inspection of generated output; the
  resulting file is not claimed to compile.
- `default_mono.lem` demonstrates the current tier-1 selection's generation-time
  failure despite a second constructor with a usable default. That nonzero
  exit is the expected result.
- `results.txt` is the unedited final reproduction transcript. Linter warnings
  come from the unchanged S0 probe. It includes source and selected imported
  artifact hashes; the runner records and checks each expected exit outcome.

From the project workspace, with the S0 prototype already built:

```sh
./scripts/ce cerberus-lean/scripts/capped python3 \
  worktrees/cerberus-lean-docs/S0-plan-review/lean_frontend/docs/2026-09-16_lean-only-outcomes-plan-review-evidence/reproduce.py \
  --prototype /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/lean-only-outcomes-S0
```

Adjust the script path if the docs move. The runner requires the specified
prototype revision, uses its existing compiled Lean modules, selects its pinned
Lean toolchain, and builds probes in a temporary directory removed on exit.
It does not modify or rebuild the prototype or install any dependency.

These controls do not implement `inhabited_exclude`, certify the proposed final
Lem collectors, or reproduce a C-program discrepancy. Their purpose is to
separate established local facts from the remaining design obligations.
