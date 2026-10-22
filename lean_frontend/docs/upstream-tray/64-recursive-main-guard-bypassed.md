# Recursive-main guard is bypassed by the driver's Eccall reduction

Draft, 2026-10-21. Report only; no model change or external submission.
Checked in the fork based on upstream `b9aeedcb4`, with upstream backports
`f10329b44` and `3230aa494`; neither changes the call reduction described here.

`frontend/model/core_run.lem:967-970` tests the `inner_arg_temps` switch
and the callee's identity against `file.main`, then constructs a
`Step_error` for recursive calls to main. The active driver's call path
does not reach that guard. `frontend/model/core_reduction.lem:1386-1405`,
the `step_ctx` Eccall arm, returns `Step_ccall2`, resolves the function
pointer, and directly invokes `Core_run.call_proc`. The driver consumes
that action at `frontend/model/driver.lem:1346-1352`.

Consequently, bounded recursion into main executes under the switch.
The same behavior appears in the generated OCaml and Lean engines.
The issue is the unreachable guard and the misleading unsupported-path
diagnosis, not a request to prohibit recursive main or alter C semantics.

Reproduce after the documented build, from the repository root:

```sh
opam exec --switch=. -- ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --nolibc --exec --batch --mode=exhaustive \
  --switches=inner_arg_temps tests/inner_arg_temps/recursive-main.c
```

Observed, exit 0:

```text
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

`tests/inner_arg_temps/recursive-main-args.c`, with `--args "ab cd"`,
makes two nested calls with shortened argc/argv pairs and checks the
outer frame after return. It gives `Specified(42)`. Both witnesses
agree across both engines and both calling conventions; GCC exits 7
and 42 respectively. Reproduction details and the lane witnesses are in the
[slice record](../2026-10-21_inner-arg-temps-record.md#park-resolution).

The witness establishes that the driver bypasses this guard. It does
not establish that the guard is unreachable from every other entry point,
or that arbitrary recursive-main programs terminate. Maintainers can
decide whether to remove/clarify the guard or reconcile the two reduction
paths. The fork follows the active driver behavior and adds no refusal.

Classification: misleading dead guard on the active driver path; report only.
Release-lane validation is recorded in the
[completion record](../2026-10-22_inner-arg-temps-completion-record.md).
AI provenance: discovered and checked by Codex while implementing the
2026-10-21 inner_arg_temps slice. No external duplicate search or submission
has been performed for this draft.
