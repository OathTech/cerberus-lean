# Park: recursive main does not take the expected refusal

2026-10-21, branch `feature/inner-arg-temps`, implementation at `df141854f`.
I0 (`56ac1e5ae`), I1 (`c717da401`) and I2 (`df141854f`) each passed their
complete Tier A boundary. I2 also passed all four libc quotation comparisons
and literal kernel replays. No existing baseline moved.

[AGENT 2026-10-21] Apply the dispatch's park condition: the charter's
recursive-main refusal premise is false for the active execution path.
Do not implement the proposed refusal classification or change the shared
model without a new ruling. This commit preserves two focused witnesses
and this diagnosis; it is not a completed I3 checkpoint.

## Counterexample and measured result

`tests/inner_arg_temps/recursive-main.c` makes one recursive call to main,
guarded by a static depth variable, then returns 7. The oracle and Lean
each produce the following complete batch verdict in both Normal and
`inner_arg_temps` modes, exit 0:

```text
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

The switched Lean run reports `cerberus-lean switches: [inner_arg_temps]`
on stderr. This is execution, not the declared unsupported stop required
by the charter. The oracle's dumped body contains a `ccall` to main.

The independent `main-args.c` control, run with `--args "ab cd"`, returns
`Specified(0)` on both engines in both modes. Its switched oracle dump has
`proc main (argc: loaded integer, argv: loaded pointer)`: the switch is
active, and main receives the loaded-value parameter convention. The
translation comment/code mismatch remains confirmed.

Initial Lean probe invocations omitted the runtime or misplaced `--batch`
and were refused at the CLI. They are not execution evidence; the results
above use the corrected canonical argument order reproduced below.

## Why the cited guard does not stop this program

- `frontend/model/core_run.lem:967-970` contains the switch/main check and
  the recursive-main `Step_error` cited by the charter.
- The driver's active call reduction is instead
  `frontend/model/core_reduction.lem:1386-1405`, in `step_ctx`. Its `Eccall`
  arm returns `Step_ccall2`, resolves the function symbol, and calls
  `Core_run.call_proc` directly. It does not perform that switch/main check.
- `frontend/model/driver.lem:1346-1352` executes the `Step_ccall2` action
  and continues the driver. Both generated engines exhibit this path's
  successful recursive execution.

This finding does not establish that arbitrary recursive-main programs
work, or that the separate guard is globally unreachable. It disproves
the blanket refusal premise needed by the proposed lane. No model code
was changed to manufacture the expected stop.

## Reproduce

From the repository root after the documented build/runtime staging:

```sh
mkdir -p .tmp/inner-arg-temps-repro
CERB_MEM_MAX=4G opam exec --switch=. -- ./scripts/capped \
  _build/default/backend/driver/main.exe --runtime=_build/install/default \
  --nolibc --exec --batch --mode=exhaustive --switches=inner_arg_temps \
  tests/inner_arg_temps/recursive-main.c
CERB_MEM_MAX=4G opam exec --switch=. -- ./scripts/capped \
  _build/default/backend/driver/main.exe --runtime=_build/install/default \
  --nolibc --cabs-json tests/inner_arg_temps/recursive-main.c \
  > .tmp/inner-arg-temps-repro/recursive-main.json
CERB_MEM_MAX=4G LEAN_ABORT_ON_PANIC=1 ./scripts/capped \
  lean_frontend/.lake/build/bin/cerberus-lean --batch \
  --runtime=_build/install/default --switches=inner_arg_temps \
  .tmp/inner-arg-temps-repro/recursive-main.json
```

Remove the switch from both execution commands for the Normal controls.
For the argument witness, use `main-args.c` / its exported JSON and add
`--args "ab cd"` before the input on both execution commands. Remove the
scratch reproduction directory when done.

## Pending ruling and uncompleted work

The orchestrator needs to resolve whether the slice should validate the
active model's recursive-main behavior, or whether a separately authorized
shared-model refusal is required. Neither direction has been selected.
The I3 lane, baseline, plants and fuzzing round, and I4 documentation,
consumer note, tray report and full close-out battery remain unfinished.
The later [charter amendment](2026-10-21_codex-charter-inner-arg-temps.md)
authorizes upstream `3230aa494` as the separate
[I0b backport](2026-10-21_inner-arg-temps-i0b-record.md) and defers approved
I1b work to the quotation-hygiene slice. Those rulings do not settle the
recursive-main finding. Nothing has been pushed or filed externally.
