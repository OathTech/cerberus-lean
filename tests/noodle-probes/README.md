# noodle-probes — the semantic-discrepancy hunt corpus (2026-09-03)

Additive probe corpus from the noodler slice (branch `noodle/semantics`,
off mainline `72164481a`; record:
`lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`). NOTHING here is
a gate: no baseline wiring, no CI. Every probe is written suite-ready per
the orchestrator addendum [USER 2026-09-03]: a fixed deterministic C
input exercising ONE semantic corner, ISO cite in the header comment,
and the three engines' verbatim outputs recorded in the directory's
`results.log` (the pin: oracle line, Lean line, gcc exit+stdout, and the
runner's classification). Integration recommendations per probe are in
each directory's README and the record's INTEGRATION column.

## Layout

| Path | What |
|------|------|
| `run_noodle.sh` | three-engine runner: oracle exhaustive batch, Lean `--batch` via cabs-json, native `gcc -O0` (exit + stdout). Same invocations/caps as `tests/parity-probes/run_probe.sh`. `--nolibc` for the ci-lane mode, `--nogcc` to skip native. |
| `<area>/*.c` | one probe per corner; header comment = corner + ISO cite + expected values |
| `<area>/results.log` | verbatim runner output for the whole directory (the recorded pin) |
| `<area>/README.md` | per-probe table: corner, class, integration target |

## Running

```bash
scripts/ce scripts/libc_prep.sh --jsons .tmp/pd/libcjson          # once (libc mode)
scripts/ce tests/noodle-probes/run_noodle.sh --nolibc tests/noodle-probes/int/*.c
```

## Classification vocabulary (the record's)

- DISCREPANCY — Lean != oracle on a program both accept (headline class)
- ORACLE-SUSPECT — Lean == oracle, both != ISO C / gcc on a deterministic UB-free program
- ODDITY — surprising but defensible
- EXCLUDED-KNOWN — on a known register (cited); not a finding
