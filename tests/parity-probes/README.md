# parity-probes — the parity-detective lane (2026-08-30)

Additive probe lane from the parity-detective slice (branch
`probe/parity-detective`; report:
`lean_frontend/docs/2026-08-30_parity-detective-report.md`). NOTHING
here is a gate: no baseline, no CI wiring. It exists so every claim in
the report has a runnable artifact.

## Contents

| Path | What |
|------|------|
| `run_probe.sh` | single-file differential runner (oracle exhaustive batch vs Lean exec via cabs-json), comparison semantics replicated from `scripts/test_ci_sweep.sh`; prints both outputs + an agreement verdict. Libc mode by default, `--nolibc` for the ci-lane mode. Needs `scripts/ce` env + libc jsons prepped (see header). |
| `probes/*.c` | targeted beyond-testset probe programs (bitfields, VLAs, varargs, compound literals, designated inits, FAM, anonymous members, wide strings, _Complex, _Generic, long double, funcptr edges, qualifiers, Duff, seqpoint UB, recursion depth, UB corners, libc file-I/O seams, argv). Per-probe verdicts: report §3. |
| `sweep-2026-08-30/` | fresh full-corpus `test_ci_sweep.sh` TSVs at mainline a8f86112d (fresh-built binaries; the committed `tests/ci_sweep/results/` are the older 2026-08-22-era run and were left untouched), plus `csmith-fresh-lanes.txt` — verbatim summaries of the three fresh-seed csmith lanes (320 programs, 54 comparable, 0 bugs). |

## Headline repros (all minimized, all in `probes/`)

- `fgetc_eof.c` — both engines accept and complete; Lean answers 10,
  oracle 2. CerbFS read-ignores-offset hole (declared divergence,
  `lean_frontend/CerbFS.lean` header).
- `fseek_read.c` — Lean 119 vs oracle 42 (seek ignored).
- `fread_seq.c` — Lean 1 vs oracle 22 (sequential reads restart at 0).
- `oracle_2d_struct_init.c` — 3-line 2-D-struct-array init crashing
  BOTH engines with the identical upstream-tray-08 "invalid node"
  internal error (the dominant fresh-csmith skip cause).

## Running

```bash
scripts/ce scripts/libc_prep.sh --jsons .tmp/pd/libcjson   # once
scripts/ce tests/parity-probes/run_probe.sh tests/parity-probes/probes/fgetc_eof.c
```
