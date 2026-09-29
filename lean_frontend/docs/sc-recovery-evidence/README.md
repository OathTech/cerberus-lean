# Historical evidence for the SC prototype investigation

The governing build plan is the [SC concurrency master plan](../../../SC-CONCURRENCY.md).
This directory and its raw records retain their original names and paths.
They describe the initial investigation, not the state of the new build.

These are bounded diagnostic runs of existing binaries, not fresh-build or
concurrency-correctness certification. All commands preserve stdout, stderr,
exit status, duration, source identity where applicable, and binary hashes.
The same generated semantics appearing in two backends is not independent
semantic evidence.

* `donor-reproductions.json`: two ordered object programs run sequentially and
  under SC on native and Lean donor binaries. The first four Lean invocations
  correctly refused startup because `LEAN_ABORT_ON_PANIC` was missing; these
  are retained as setup failures. The four `corrected-env` runs set it through
  `env` and are the Lean results cited in the plan. Cabs inputs were generated
  from the recorded source paths and saved under `.tmp/sc-recovery`; their
  hashes are recorded instead of the large payloads.
* `donor-selected-cost.json`: one-thread loops, using native `--mode=random` to
  select one execution, at 8/16/32/64 iterations in sequential and SC mode.
  A 10-second timeout gives status 124 at SC sizes 32 and 64. This is not
  exhaustive exploration or a fitted asymptotic analysis. The exact source
  for each size is embedded in the JSON.
* `sequential-controls.json`: separate current-mainline and pristine-upstream
  native runs of three recovered ordinary-object programs. These constrain
  the conservativity requirement; they do not supply a concurrency oracle.
* `artifact-checks.json`: exact provenance/hash checks for the 21 copied inputs,
  local document-link checks, and successful Cabs parsing of the new
  member-before-race-loop input through the current mainline native frontend.
  This checks the planning artifacts and input syntax, not the future executor.

Source heads may move after this record. The binary hashes identify the
executables actually run; no claim that they were freshly rebuilt from the
recorded worktree heads is made. Wall times include process startup/preprocessing
and are single samples. JSON argument arrays omit the external `timeout -k 2s`
wrapper; limits are 15 seconds for object probes and 10 seconds for cost probes.

The repository branch was created from local mainline
`e9f9d049ffaaf005c392495b0f6418d21f4df29f`, which matched the locally stored
origin-tracking ref. Live remote lookup failed with
`Could not resolve hostname github.com: Temporary failure in name resolution`.
Public primary literature was separately reachable through the web research
tool. No remote branch was modified.
