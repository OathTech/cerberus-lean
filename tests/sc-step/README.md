# tests/sc-step — fixtures of the SC S1a step lane (`scripts/test_sc_step.py`)

Charter: `lean_frontend/docs/2026-09-29_sc-s1-charter.md` §3.10 (rows E and F's
control), §3.11 (plants). The lane's differential rows A–D run over the existing
sequential corpora (`tests/minimal`, `tests/immaculate/nolibc`, `tests/debug`,
`tests/float`, `tests/coverage`; `tests/libc_exec` under `--libc`), not over this
directory.

| File | Row | Expectation (independently specified in the header) |
|---|---|---|
| `loop-nogl.c` | E | deterministic `while (1) {}`; no globals: startup transitions = 1 (one lifecycle transition enters `main`'s body at the boundary); `SCExhausted` at every budget ≥ 1 with `core_reductions = budget − 1`; memory unchanged from budget 1 on |
| `loop-glob.c` | E | the same loop with one initialised global: startup transitions = 2 (the global's body boundary, then `main`'s); the global's initialiser costs reductions the header states |
| `par-control.c` | F control | a Cerberus par block (`{-{ … ||| … }-}`): both engines must report `SCUnsupported {msg: "sc: fork (Step_spawn_threads2, Core par): S1b"}` (plant P4) |

Row E is Lean-only at an explicit small `--fuel` chosen by the lane so budget
exhaustion precedes fuel exhaustion; `drive` at the same fuel ends only in the fuel
kill (the oracle has no fuel and never ends on these loops).
