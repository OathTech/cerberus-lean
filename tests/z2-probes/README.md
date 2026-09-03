# tests/z2-probes — the Z2 seam-audit probe corpus (2026-09-03, branch audit/z2-seams)

Reproducers for the C-observable candidates of
`lean_frontend/docs/2026-09-03_zero-discrepancy-Z2-audit.md`, one directory
per seam, each with a `README.md` table (probe · what it tests · three-engine
lines VERBATIM · class · proposed lane). Runner: `run_z2.sh` (fork oracle /
un-forked upstream / Lean; full-line compare — `LINE-DIFF` when only a
non-`value` field differs). ADDITIVE, NON-GATING: to be evaluated for
integration into the standard suites (each row names its proposed lane).

| dir | seam | probes | Lean≠oracle confirmed | refuted / controls |
|---|---|---|---|---|
| `mem/` | CerbMem.lean vs impl_mem.ml | 16 | 5 runs / 3 findings (`aligned_alloc(0,·)`, `device_funptr_call`, `free_funptr`=Z-07) | 8 AGREE, 4 both-reject |
| `nd/` | CerbND.lean vs smt2.ml runND | 3 (+ single-trace runs) | 0 (trace ORDER identical) | 3 AGREE |
| `main/` | Main.lean batch renderers | 2 | 2 (`batchEscape` stdout/stderr bytes) | — |
| `coreparser/` | CoreParser.lean vs core_parser.mly | 2 | 1 (`inf` in libc.core → `Unresolved_symbol`) | 1 not settled (timeout) |
| `impl/` | CerberusImpl.lean | 4 | 1 (`__cerbty_int32_t` normalisation → Lean panic) | 3 AGREE (the `<stdint.h>` route) |
| `float/` | CerbFloat.lean | 3 | 0 (+1 INSTRUMENT: panic-without-flag → value) | 2 claims refuted / not evidenced |
| `fs/` | CerbFS.lean residuals | 2 | 1 (`lseek` invalid whence) | 1 both-crash |
| `call/` | CerbCall.lean vs wrapper TU | 2 | 2 (`_Bool` injection; errno allocation order) | — |

Derived totals: 34 probe programs, 12 Lean≠oracle runs (9 distinct findings incl. the two `--call` harness rows and the Z-07 re-witness), 3 reader claims REFUTED by probe, 2 not settled.
