# Test-depth map: first actions — record

Date: 2026-09-28. Branch: `arc/contract-enforcement`. Author: the orchestrator [AGENT].
Occasion: [USER 2026-09-28] "(B) that we identify trust surfaces which are less well-tested than others, if any
exist. That's the real miss wrt the bug, we knew that SybllFS wasn't a well-tested mirror, but that wasn't clearly
documented". Measurement: `docs/2026-09-28_test-depth-map.md` (fresh reviewer, static counts, no runs).

## Claims re-measured by the orchestrator before acting

- **C-program stdin refuses** (the map derived it from code only). Measured: `getchar()` under `--batch --first
  --libc …` → `PANIC … CerbFS refusal (fail-closed fs-model boundary): read fd 0 count 1024 …`, rc 134. The oracle
  returns `Specified(7)` (EOF) with `</dev/null` and also when the host feeds it `xyz`: SibylFS models an empty stdin,
  so the witness is independent of the harness's stdin.
- **Non-batch CLI exits 0 on UB.** Measured on `1/0`: Lean prints `Killed (undefined behaviour) … UB045a` with rc 0;
  the oracle's non-batch `--exec` also exits 0. Consistent, but never compared; documented in CONTRACT §3.2 as not the
  compared interface.

## Actions

- CONTRACT §3.2: "How deeply each part is tested", the deep core and a table of the thinly tested parts with measured
  counts; the libc row marked thinly tested; the stdin row corrected to REFUSED; the Core-text row restated (no mode
  executes user Core text); §4.1 lists every refusal witness.
- Witness `tests/immaculate/libc/zd-fs-stdin-read.c`, pinned `DIFF | L=CRASH`.
- `scripts/check_cli_refusals.sh` in row 1: `--concurrency`, `--switches=PNVI_ae_udi` and
  `--switches=strict_pointer_arith` must exit 2 with their named refusal; a control without the flag must not be
  refused. Plants run by hand: a broken driver (`/bin/false`) and a refuse-everything driver both FAIL it.

## Not done here (proposed to the operator)

Adding lane rows for the thin surfaces (the map's §2 actions: libc battery and one exhaustive libc row, `%f` and
printf-spec rows, `realloc`/`memcpy`/`memcmp`, `snprintf`/`errno`/`exit`, multi-TU cases, a UTF-8 argv probe) and a
`--first` membership check.
