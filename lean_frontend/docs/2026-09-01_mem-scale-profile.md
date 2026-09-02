# Memory-scale profile — the measurement record (arc/mem-scale P0)

Date: 2026-09-01. Branch `arc/mem-scale` @ mainline `bbdbacaff`.
Worker: P0 (measurement-first slice). Companion: the draft charter
`2026-09-01_mem-scale-design.md`. Status: **investigation only — no
code changes to the semantics in this slice.**

Provenance convention: `[AGENT]` = this worker's judgement;
`[USER …]` = operator ruling as transmitted by the orchestrator;
quoted outputs are verbatim; every derived number is labelled
*derived* and its arithmetic is shown.

## 0. Headline

The detective report's class-(b) root cause 3
(`2026-08-30_parity-detective-report.md` §3 RC-3) attributed two
Lean OOMs — a 13.3 MB stack array and a 64 KB by-value struct — to
"per-byte boxed-list memory representation" with "The OCaml side
pays a far smaller constant". Treated here as a hypothesis and
tested under a cgroup RSS cap:

**Verdict [AGENT]: REFUTED as stated.** Both inputs run to the
oracle's verdict under the 32 G cap with **no OOM**; Lean's peak RSS
is within 2–3 % of the oracle's on both (13.3 MB array: oracle
3.10 GB vs Lean 3.05 GB; 64 KB struct, exhaustive mode: oracle
1.87 GB vs Lean 1.93 GB). The recorded OOMs were an artefact of the
detective runner's `ulimit -v 4000000` — a *virtual address space*
limit, which Lean's allocator breaches at ~1.7 GB RSS (VmPeak 6.25 GB
on this input) while OCaml's does not (its virtual ≈ resident). The
`scripts/capped` header already warns of exactly this mechanism
(`prlimit --as` "kills Lean spuriously — per-thread address-space
reservation").

What IS true, measured: (1) both engines pay roughly 200–250 bytes
of resident memory per *uninitialised* object byte and 700–1000 bytes
per *zero-initialised static* byte — the per-byte-boxed shape is
shared with upstream by construction, so the constant is upstream's
too; (2) Lean is 1.4–1.5× slower in wall time on a single trace of
the aggregate paths and ~5× in exhaustive mode on many-execution
fan-outs (the ND runner's per-execution constant, not the memory
model); (3) aggregate loads are QUADRATIC in the element count on
BOTH engines (wall exponents ≈ 2.0 at 16 K → 256 K bytes): Lean's
mechanism is `drop`-based re-slicing in the array arm of
`reconstructValue`, upstream's is a per-call `List.length` guard in
`abst` — the same complexity class by different mechanisms, so the
in-place Lean fix (charter C1) takes Lean BELOW upstream's class —
see §5.4 and §4; (4) one genuine Lean-only constant-factor divergence exists in the
bytemap's *keys*: 48-bit addresses exceed Lean's small-`Int` range,
so every key is a heap-allocated big integer (OCaml's Zarith keeps
them immediate) — see §5; (5) the ceilings this study actually
hit on the Lean side are NOT memory: (i) the already-registered
`lemDefaultFuel = 10^6` totalisation budget (TODO.md "Step-runner
execution ceiling") — 100 K loop iterations, a 100 KB
`memset`/`memcpy`, and a 10^6-element local initialiser all die with
`lem: fuel exhausted` on both the `--first` and exhaustive drivers;
and (ii) a NEW, deterministic, SILENT hang on zero-initialised static
aggregates of more than ~7–8 million elements (`char g[8000000]`
hangs; `char g[7000000]` and `int g[2500000]` complete; the oracle
completes the 10 M-byte case in 246 s / 7.7 GB), shown by experiment
to be a stack-depth ceiling — a non-tail recursion over the element
list whose overflow the runtime does not report (§6.2–6.3). That one
is a fail-open-by-silence defect and is registered in TODO.md.

## 1. Method

- Binaries: rebuilt via `scripts/common.sh` `build_cerberus`
  (`DUNE_CACHE=disabled`) and `build_lean` (capped); both builds were
  incremental no-ops on an already-built tree, and the driver
  freshness stamps were recorded and re-verified
  (`tools/check_driver_fresh.sh --check-oracle/--check-lean`: OK).
  Oracle sha256 prefix `c93bbfebd196f782`, Lean `91c805fb050f76be`.
- Cap: every engine run under `CERB_MEM_MAX=32G scripts/capped`
  (cgroup-direct mode; `memory.max` read back as 34359738368,
  `memory.swap.max` 0). A cgroup kill exits 137 with the KILLED
  banner; a timeout (600 s, 900 s for the reproduction) exits 124.
- Measurement: `/usr/bin/time -v` around `timeout` around the
  engine; `Maximum resident set size (kbytes)` and `Elapsed (wall
  clock)` are read from its output. RSS of the waited-for descendant
  tree propagates through `timeout` (rusage semantics). Baseline RSS
  of an empty `main` is measured per mode and subtracted for the
  *derived* per-byte figures.
- Engines: oracle `--exec --batch --mode=exhaustive` (nolibc: with
  `--nolibc`); Lean `--batch --first` (single trace) and `--batch`
  (exhaustive), fed the oracle's `--cabs-json` of the same file; libc
  mode adds `--libc tests/libc/libc.core --libc-tu <12 jsons>` from
  `scripts/libc_prep.sh --jsons`. `LEAN_ABORT_ON_PANIC=1` throughout
  (a panic exits 134).
- Instruments (committed): `tests/mem-scale-probes/measure.sh`
  (per-file runner, TSV row per engine), `gen_probes.sh` (the
  corpus, deterministic), `run_all.sh` (the sweep),
  `micro/` (a Lake package with one executable timing the `CerbMem`
  byte-path primitives in isolation; requires `CerberusLean` by path,
  same one-way shape as speclab). Raw per-run `.out/.err/.time`
  files live under the ephemeral `.tmp/memscale/` and are not
  committed; the TSVs under `tests/mem-scale-probes/results/` are.
- Box: 32 CPUs, 125 GB RAM, shared; one heavy run at a time
  (engines run strictly sequentially). `perf` is unavailable
  (`perf_event_paranoid = 4`; changing it is a forbidden global
  change), hence the micro-benchmark route for hot-path attribution.

## 2. Reproduction of the two detective cases (task 1)

Inputs copied verbatim: `tests/suite/parsing/array.c`
(`int b [3333333];` = 13,333,332 bytes) and
`tests/gcc-torture/breakdown/not_supported/bitfields/pr20621-1.c`
(`struct big { int i[0x4000]; }` = 65,536 bytes, passed by value
twice: `foo (gb, 0) + foo (gb, 1)`). libc mode, as the detective's
`run_probe.sh` ran them. Verbatim TSV rows
(`probe mode engine exit wall_s maxrss_kb verdict note`; the
4,620-fold verdict column abbreviated to `x4620`):

```
det_pr20621-1	libc	oracle	0	18.12	1872880	VAL:Specified(0)x4620	-
det_pr20621-1	libc	lean-first	0	4.05	230688	VAL:Specified(0)	-
det_pr20621-1	libc	lean-exh	0	54.08	1925564	VAL:Specified(0)x4620	-
det_array	libc	oracle	0	17.36	3097984	VAL:Specified(0)	-
det_array	libc	lean-first	0	27.66	3051268	VAL:Specified(0)	-
det_array	libc	lean-exh	0	27.57	3050536	VAL:Specified(0)	-
```

Observations [AGENT]:
- No OOM, no kill, no panic on either input under a 32 G RSS cap.
  Lean's `--first` run of the 64 KB struct case sits at the libc-mode
  *baseline* RSS (230 MB, see §3 `z_base`).
- The oracle does NOT "answer immediately" on the 13.3 MB array: it
  takes 17.4 s and 3.10 GB — *derived* (3,097,984 − 110,100 KB) /
  13,333,332 B ≈ **229 B per object byte**. Lean: (3,051,268 −
  230,524) / 13,333,332 ≈ **217 B per object byte**, 27.7 s.
- The 64 KB struct case is an *exhaustive-mode fan-out*: the
  unsequenced `foo(gb,0) + foo(gb,1)` yields 4,620 executions on BOTH
  engines (verdict sequences identical). Lean exhaustive is 3× the
  oracle's wall time at equal RSS; Lean `--first` (the analogue of the
  oracle's `--mode=random`) is 4 s.

The artefact, reproduced directly (`.tmp/memscale/ulimit_test.sh`,
verbatim output):

```
## Lean, det_array (13.3MB), libc mode, ulimit -v 4000000 (detective's runner setting)
INTERNAL PANIC: out of memory
Command terminated by signal 6
wall=17.50 s maxrss=1734140 KB exit=0
## Lean, same, NO ulimit (cgroup-capped only): VmPeak sampled
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0 VmPeak=6247084 KB
## Oracle, det_array, ulimit -v 4000000
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
wall=18.29 s maxrss=3098436 KB exit=0
```

Lean dies at 1.73 GB *resident* because its *virtual* footprint
(6.25 GB peak) crosses the 4 GB address-space limit; the oracle at
3.10 GB resident passes because OCaml's virtual footprint tracks its
resident one. The detective's "OOM" rows for these two files are
therefore measurement artefacts of `ulimit -v`, not evidence about
the representation. (The parity conclusion is unchanged — both files
AGREE with the oracle once run under an RSS cap; the detective's
`ulimit -v 4000000` should be replaced by `scripts/capped` in
`tests/parity-probes/run_probe.sh` and `scripts/test_ci_sweep.sh` —
listed as a follow-up in the charter.)

## 3. Scaling study (task 2) — the sweep

Corpus: `tests/mem-scale-probes/probes/` (34 files, `gen_probes.sh`);
results: `tests/mem-scale-probes/results/2026-09-01_sweep.tsv`
(header lines record time, cap, timeout, engines, binary hashes).
Classes a/b/c/d nolibc, e libc, `z_base` both. Timeout 600 s (the
10 M rows of `a_zero_global`/`b_zero_local`: 300 s re-runs after the
first sweep process was stopped externally at 00:44 UTC with those
two probes outstanding; the `a_zero_global_10000000` oracle row was
then re-measured at 600 s — see the row order in the TSV). Tables
below are produced by `tests/mem-scale-probes/summarize.py` from the
TSV; the raw rows are verbatim, the two "Derived" tables are computed
from them as their captions state.

### Raw rows (verbatim from the TSV; verdict column: distinct verdicts × count)

| probe | mode | engine | exit | wall_s | maxrss_kb | verdict | note |
|---|---|---|---|---|---|---|---|
| z_base | nolibc | oracle | 0 | 0.08 | 43788 | VAL:Specified(7) | - |
| z_base | nolibc | lean-first | 0 | 0.13 | 77828 | VAL:Specified(7) | - |
| z_base | nolibc | lean-exh | 0 | 0.08 | 78648 | VAL:Specified(7) | - |
| z_base | libc | oracle | 0 | 0.46 | 110100 | VAL:Specified(7) | - |
| z_base | libc | lean-first | 0 | 2.76 | 230524 | VAL:Specified(7) | - |
| z_base | libc | lean-exh | 0 | 2.83 | 230520 | VAL:Specified(7) | - |
| a_uninit_local_1000 | nolibc | oracle | 0 | 0.09 | 43516 | VAL:Specified(7) | - |
| a_uninit_local_1000 | nolibc | lean-first | 0 | 0.05 | 78004 | VAL:Specified(7) | - |
| a_uninit_local_1000 | nolibc | lean-exh | 0 | 0.04 | 78440 | VAL:Specified(7) | - |
| a_zero_global_1000 | nolibc | oracle | 0 | 0.07 | 44308 | VAL:Specified(7) | - |
| a_zero_global_1000 | nolibc | lean-first | 0 | 0.09 | 78192 | VAL:Specified(7) | - |
| a_zero_global_1000 | nolibc | lean-exh | 0 | 0.07 | 78592 | VAL:Specified(7) | - |
| b_zero_local_1000 | nolibc | oracle | 0 | 0.07 | 47628 | VAL:Specified(7) | - |
| b_zero_local_1000 | nolibc | lean-first | 0 | 0.12 | 80228 | VAL:Specified(7) | - |
| b_zero_local_1000 | nolibc | lean-exh | 0 | 0.12 | 80512 | VAL:Specified(7) | - |
| d_loop_1000 | nolibc | oracle | 0 | 0.26 | 46800 | VAL:Specified(-25) | - |
| d_loop_1000 | nolibc | lean-first | 0 | 0.70 | 91520 | VAL:Specified(-25) | - |
| d_loop_1000 | nolibc | lean-exh | 0 | 0.64 | 92284 | VAL:Specified(-25) | - |
| e_memcpy_1000 | libc | oracle | 0 | 0.62 | 110924 | VAL:Specified(7) | - |
| e_memcpy_1000 | libc | lean-first | 0 | 3.15 | 232492 | VAL:Specified(7) | - |
| e_memcpy_1000 | libc | lean-exh | 0 | 3.28 | 232572 | VAL:Specified(7) | - |
| c_struct_arg_1024 | nolibc | oracle | 0 | 0.86 | 83060 | VAL:Specified(0)x4620 | - |
| c_struct_arg_1024 | nolibc | lean-first | 0 | 0.08 | 77920 | VAL:Specified(0) | - |
| c_struct_arg_1024 | nolibc | lean-exh | 0 | 2.09 | 124428 | VAL:Specified(0)x4620 | - |
| c_struct_ret_1024 | nolibc | oracle | 0 | 0.08 | 44944 | VAL:Specified(7) | - |
| c_struct_ret_1024 | nolibc | lean-first | 0 | 0.10 | 77884 | VAL:Specified(7) | - |
| c_struct_ret_1024 | nolibc | lean-exh | 0 | 0.09 | 78728 | VAL:Specified(7) | - |
| c_struct_arg_4096 | nolibc | oracle | 0 | 1.72 | 168468 | VAL:Specified(0)x4620 | - |
| c_struct_arg_4096 | nolibc | lean-first | 0 | 0.10 | 81976 | VAL:Specified(0) | - |
| c_struct_arg_4096 | nolibc | lean-exh | 0 | 2.92 | 210916 | VAL:Specified(0)x4620 | - |
| c_struct_ret_4096 | nolibc | oracle | 0 | 0.17 | 50208 | VAL:Specified(7) | - |
| c_struct_ret_4096 | nolibc | lean-first | 0 | 0.12 | 83148 | VAL:Specified(7) | - |
| c_struct_ret_4096 | nolibc | lean-exh | 0 | 0.16 | 83164 | VAL:Specified(7) | - |
| a_uninit_local_10000 | nolibc | oracle | 0 | 0.08 | 45760 | VAL:Specified(7) | - |
| a_uninit_local_10000 | nolibc | lean-first | 0 | 0.09 | 77996 | VAL:Specified(7) | - |
| a_uninit_local_10000 | nolibc | lean-exh | 0 | 0.11 | 78404 | VAL:Specified(7) | - |
| a_zero_global_10000 | nolibc | oracle | 0 | 0.18 | 52036 | VAL:Specified(7) | - |
| a_zero_global_10000 | nolibc | lean-first | 0 | 0.10 | 84028 | VAL:Specified(7) | - |
| a_zero_global_10000 | nolibc | lean-exh | 0 | 0.16 | 83460 | VAL:Specified(7) | - |
| b_zero_local_10000 | nolibc | oracle | 0 | 0.38 | 89436 | VAL:Specified(7) | - |
| b_zero_local_10000 | nolibc | lean-first | 0 | 0.92 | 105888 | VAL:Specified(7) | - |
| b_zero_local_10000 | nolibc | lean-exh | 0 | 0.76 | 106464 | VAL:Specified(7) | - |
| d_loop_10000 | nolibc | oracle | 0 | 2.33 | 66584 | VAL:Specified(15) | - |
| d_loop_10000 | nolibc | lean-first | 0 | 7.09 | 247744 | VAL:Specified(15) | - |
| d_loop_10000 | nolibc | lean-exh | 0 | 6.41 | 248324 | VAL:Specified(15) | - |
| e_memcpy_10000 | libc | oracle | 0 | 2.62 | 130712 | VAL:Specified(7) | - |
| e_memcpy_10000 | libc | lean-first | 0 | 7.57 | 245952 | VAL:Specified(7) | - |
| e_memcpy_10000 | libc | lean-exh | 0 | 7.06 | 247144 | VAL:Specified(7) | - |
| c_struct_arg_16384 | nolibc | oracle | 0 | 6.10 | 509728 | VAL:Specified(0)x4620 | - |
| c_struct_arg_16384 | nolibc | lean-first | 0 | 0.69 | 95640 | VAL:Specified(0) | - |
| c_struct_arg_16384 | nolibc | lean-exh | 0 | 8.47 | 561100 | VAL:Specified(0)x4620 | - |
| c_struct_ret_16384 | nolibc | oracle | 0 | 0.32 | 62524 | VAL:Specified(7) | - |
| c_struct_ret_16384 | nolibc | lean-first | 0 | 0.34 | 96804 | VAL:Specified(7) | - |
| c_struct_ret_16384 | nolibc | lean-exh | 0 | 0.35 | 96876 | VAL:Specified(7) | - |
| c_struct_arg_65536 | nolibc | oracle | 0 | 40.67 | 2050564 | VAL:Specified(0)x4620 | - |
| c_struct_arg_65536 | nolibc | lean-first | 0 | 5.85 | 146120 | VAL:Specified(0) | - |
| c_struct_arg_65536 | nolibc | lean-exh | 0 | 218.45 | 1956504 | VAL:Specified(0)x4620 | - |
| c_struct_ret_65536 | nolibc | oracle | 0 | 4.96 | 130736 | VAL:Specified(7) | - |
| c_struct_ret_65536 | nolibc | lean-first | 0 | 5.55 | 155360 | VAL:Specified(7) | - |
| c_struct_ret_65536 | nolibc | lean-exh | 0 | 5.78 | 155216 | VAL:Specified(7) | - |
| a_uninit_local_100000 | nolibc | oracle | 0 | 0.19 | 67276 | VAL:Specified(7) | - |
| a_uninit_local_100000 | nolibc | lean-first | 0 | 0.18 | 98668 | VAL:Specified(7) | - |
| a_uninit_local_100000 | nolibc | lean-exh | 0 | 0.19 | 98396 | VAL:Specified(7) | - |
| a_zero_global_100000 | nolibc | oracle | 0 | 0.54 | 141516 | VAL:Specified(7) | - |
| a_zero_global_100000 | nolibc | lean-first | 0 | 0.49 | 145228 | VAL:Specified(7) | - |
| a_zero_global_100000 | nolibc | lean-exh | 0 | 0.39 | 145576 | VAL:Specified(7) | - |
| b_zero_local_100000 | nolibc | oracle | 0 | 2.95 | 491316 | VAL:Specified(7) | - |
| b_zero_local_100000 | nolibc | lean-first | 0 | 6.53 | 385944 | VAL:Specified(7) | - |
| b_zero_local_100000 | nolibc | lean-exh | 0 | 6.66 | 385664 | VAL:Specified(7) | - |
| d_loop_100000 | nolibc | oracle | 0 | 17.86 | 285836 | VAL:Specified(-97) | - |
| d_loop_100000 | nolibc | lean-first | 134 | 8.86 | 330624 | NONE | - |
| d_loop_100000 | nolibc | lean-exh | 134 | 8.89 | 330860 | NONE | - |
| e_memcpy_100000 | libc | oracle | 0 | 11.44 | 401516 | VAL:Specified(7) | - |
| e_memcpy_100000 | libc | lean-first | 134 | 11.38 | 462196 | NONE | - |
| e_memcpy_100000 | libc | lean-exh | 134 | 11.57 | 461500 | NONE | - |
| c_struct_arg_262144 | nolibc | oracle | 0 | 538.06 | 7637168 | VAL:Specified(0)x4620 | - |
| c_struct_arg_262144 | nolibc | lean-first | 0 | 114.00 | 376040 | VAL:Specified(0) | - |
| c_struct_arg_262144 | nolibc | lean-exh | 124 | 600.02 | 542440 | NONE | TIMEOUT(600s); |
| c_struct_ret_262144 | nolibc | oracle | 0 | 77.09 | 388704 | VAL:Specified(7) | - |
| c_struct_ret_262144 | nolibc | lean-first | 0 | 100.65 | 377332 | VAL:Specified(7) | - |
| c_struct_ret_262144 | nolibc | lean-exh | 0 | 100.59 | 378300 | VAL:Specified(7) | - |
| a_uninit_local_1000000 | nolibc | oracle | 0 | 1.36 | 268404 | VAL:Specified(7) | - |
| a_uninit_local_1000000 | nolibc | lean-first | 0 | 1.85 | 292104 | VAL:Specified(7) | - |
| a_uninit_local_1000000 | nolibc | lean-exh | 0 | 2.14 | 292308 | VAL:Specified(7) | - |
| a_zero_global_1000000 | nolibc | oracle | 0 | 9.02 | 942716 | VAL:Specified(7) | - |
| a_zero_global_1000000 | nolibc | lean-first | 0 | 6.20 | 760824 | VAL:Specified(7) | - |
| a_zero_global_1000000 | nolibc | lean-exh | 0 | 4.85 | 760496 | VAL:Specified(7) | - |
| b_zero_local_1000000 | nolibc | oracle | 0 | 48.76 | 4583228 | VAL:Specified(7) | - |
| b_zero_local_1000000 | nolibc | lean-first | 134 | 1.25 | 106036 | NONE | - |
| b_zero_local_1000000 | nolibc | lean-exh | 134 | 1.20 | 106860 | NONE | - |
| d_loop_1000000 | nolibc | oracle | 0 | 203.42 | 2497884 | VAL:Specified(63) | - |
| d_loop_1000000 | nolibc | lean-first | 134 | 12.37 | 451992 | NONE | - |
| d_loop_1000000 | nolibc | lean-exh | 134 | 10.64 | 453528 | NONE | - |
| e_memcpy_1000000 | libc | oracle | 0 | 137.48 | 3132008 | VAL:Specified(7) | - |
| e_memcpy_1000000 | libc | lean-first | 134 | 25.00 | 1278484 | NONE | - |
| e_memcpy_1000000 | libc | lean-exh | 134 | 26.64 | 1277984 | NONE | - |
| a_uninit_local_10000000 | nolibc | oracle | 0 | 13.25 | 2316328 | VAL:Specified(7) | - |
| a_uninit_local_10000000 | nolibc | lean-first | 0 | 18.82 | 2265284 | VAL:Specified(7) | - |
| a_uninit_local_10000000 | nolibc | lean-exh | 0 | 18.16 | 2265968 | VAL:Specified(7) | - |
| a_zero_global_10000000 | nolibc | oracle | 124 | 301.70 | 6979976 | NONE | TIMEOUT(300s); |
| a_zero_global_10000000 | nolibc | lean-first | 124 | 300.23 | 2717724 | NONE | TIMEOUT(300s); |
| b_zero_local_10000000 | nolibc | oracle | 124 | 300.44 | 4930848 | NONE | TIMEOUT(300s); |
| b_zero_local_10000000 | nolibc | lean-first | 134 | 1.10 | 104984 | NONE | - |
| b_zero_local_10000000 | nolibc | lean-exh | 134 | 1.10 | 104948 | NONE | - |
| a_zero_global_10000000 | nolibc | oracle | 0 | 245.74 | 7696808 | VAL:Specified(7) | - |

### Derived: per-byte resident cost (maxrss − z_base baseline of the same mode/engine) / N, and wall per byte

| class | N | engine | ΔRSS_kb | B/byte | wall_s | µs/byte | status |
|---|---|---|---|---|---|---|---|
| a_uninit_local | 1000 | oracle | -272 | -279 | 0.09 | 90.00 | ok |
| a_uninit_local | 1000 | lean-first | 176 | 180 | 0.05 | 50.00 | ok |
| a_uninit_local | 1000 | lean-exh | -208 | -213 | 0.04 | 40.00 | ok |
| a_zero_global | 1000 | oracle | 520 | 532 | 0.07 | 70.00 | ok |
| a_zero_global | 1000 | lean-first | 364 | 373 | 0.09 | 90.00 | ok |
| a_zero_global | 1000 | lean-exh | -56 | -57 | 0.07 | 70.00 | ok |
| b_zero_local | 1000 | oracle | 3840 | 3932 | 0.07 | 70.00 | ok |
| b_zero_local | 1000 | lean-first | 2400 | 2458 | 0.12 | 120.00 | ok |
| b_zero_local | 1000 | lean-exh | 1864 | 1909 | 0.12 | 120.00 | ok |
| d_loop | 1000 | oracle | 3012 | 3084 | 0.26 | 260.00 | ok |
| d_loop | 1000 | lean-first | 13692 | 14021 | 0.7 | 700.00 | ok |
| d_loop | 1000 | lean-exh | 13636 | 13963 | 0.64 | 640.00 | ok |
| e_memcpy | 1000 | oracle | 824 | 844 | 0.62 | 620.00 | ok |
| e_memcpy | 1000 | lean-first | 1968 | 2015 | 3.15 | 3150.00 | ok |
| e_memcpy | 1000 | lean-exh | 2052 | 2101 | 3.28 | 3280.00 | ok |
| c_struct_arg | 1024 | oracle | 39272 | 39272 | 0.86 | 839.84 | ok |
| c_struct_arg | 1024 | lean-first | 92 | 92 | 0.08 | 78.12 | ok |
| c_struct_arg | 1024 | lean-exh | 45780 | 45780 | 2.09 | 2041.02 | ok |
| c_struct_ret | 1024 | oracle | 1156 | 1156 | 0.08 | 78.12 | ok |
| c_struct_ret | 1024 | lean-first | 56 | 56 | 0.1 | 97.66 | ok |
| c_struct_ret | 1024 | lean-exh | 80 | 80 | 0.09 | 87.89 | ok |
| c_struct_arg | 4096 | oracle | 124680 | 31170 | 1.72 | 419.92 | ok |
| c_struct_arg | 4096 | lean-first | 4148 | 1037 | 0.1 | 24.41 | ok |
| c_struct_arg | 4096 | lean-exh | 132268 | 33067 | 2.92 | 712.89 | ok |
| c_struct_ret | 4096 | oracle | 6420 | 1605 | 0.17 | 41.50 | ok |
| c_struct_ret | 4096 | lean-first | 5320 | 1330 | 0.12 | 29.30 | ok |
| c_struct_ret | 4096 | lean-exh | 4516 | 1129 | 0.16 | 39.06 | ok |
| a_uninit_local | 10000 | oracle | 1972 | 202 | 0.08 | 8.00 | ok |
| a_uninit_local | 10000 | lean-first | 168 | 17 | 0.09 | 9.00 | ok |
| a_uninit_local | 10000 | lean-exh | -244 | -25 | 0.11 | 11.00 | ok |
| a_zero_global | 10000 | oracle | 8248 | 845 | 0.18 | 18.00 | ok |
| a_zero_global | 10000 | lean-first | 6200 | 635 | 0.1 | 10.00 | ok |
| a_zero_global | 10000 | lean-exh | 4812 | 493 | 0.16 | 16.00 | ok |
| b_zero_local | 10000 | oracle | 45648 | 4674 | 0.38 | 38.00 | ok |
| b_zero_local | 10000 | lean-first | 28060 | 2873 | 0.92 | 92.00 | ok |
| b_zero_local | 10000 | lean-exh | 27816 | 2848 | 0.76 | 76.00 | ok |
| d_loop | 10000 | oracle | 22796 | 2334 | 2.33 | 233.00 | ok |
| d_loop | 10000 | lean-first | 169916 | 17399 | 7.09 | 709.00 | ok |
| d_loop | 10000 | lean-exh | 169676 | 17375 | 6.41 | 641.00 | ok |
| e_memcpy | 10000 | oracle | 20612 | 2111 | 2.62 | 262.00 | ok |
| e_memcpy | 10000 | lean-first | 15428 | 1580 | 7.57 | 757.00 | ok |
| e_memcpy | 10000 | lean-exh | 16624 | 1702 | 7.06 | 706.00 | ok |
| c_struct_arg | 16384 | oracle | 465940 | 29121 | 6.1 | 372.31 | ok |
| c_struct_arg | 16384 | lean-first | 17812 | 1113 | 0.69 | 42.11 | ok |
| c_struct_arg | 16384 | lean-exh | 482452 | 30153 | 8.47 | 516.97 | ok |
| c_struct_ret | 16384 | oracle | 18736 | 1171 | 0.32 | 19.53 | ok |
| c_struct_ret | 16384 | lean-first | 18976 | 1186 | 0.34 | 20.75 | ok |
| c_struct_ret | 16384 | lean-exh | 18228 | 1139 | 0.35 | 21.36 | ok |
| c_struct_arg | 65536 | oracle | 2006776 | 31356 | 40.67 | 620.57 | ok |
| c_struct_arg | 65536 | lean-first | 68292 | 1067 | 5.85 | 89.26 | ok |
| c_struct_arg | 65536 | lean-exh | 1877856 | 29342 | 218.45 | 3333.28 | ok |
| c_struct_ret | 65536 | oracle | 86948 | 1359 | 4.96 | 75.68 | ok |
| c_struct_ret | 65536 | lean-first | 77532 | 1211 | 5.55 | 84.69 | ok |
| c_struct_ret | 65536 | lean-exh | 76568 | 1196 | 5.78 | 88.20 | ok |
| a_uninit_local | 100000 | oracle | 23488 | 241 | 0.19 | 1.90 | ok |
| a_uninit_local | 100000 | lean-first | 20840 | 213 | 0.18 | 1.80 | ok |
| a_uninit_local | 100000 | lean-exh | 19748 | 202 | 0.19 | 1.90 | ok |
| a_zero_global | 100000 | oracle | 97728 | 1001 | 0.54 | 5.40 | ok |
| a_zero_global | 100000 | lean-first | 67400 | 690 | 0.49 | 4.90 | ok |
| a_zero_global | 100000 | lean-exh | 66928 | 685 | 0.39 | 3.90 | ok |
| b_zero_local | 100000 | oracle | 447528 | 4583 | 2.95 | 29.50 | ok |
| b_zero_local | 100000 | lean-first | 308116 | 3155 | 6.53 | 65.30 | ok |
| b_zero_local | 100000 | lean-exh | 307016 | 3144 | 6.66 | 66.60 | ok |
| d_loop | 100000 | oracle | 242048 | 2479 | 17.86 | 178.60 | ok |
| d_loop | 100000 | lean-first | 252796 | 2589 | 8.86 | 88.60 | PANIC |
| d_loop | 100000 | lean-exh | 252212 | 2583 | 8.89 | 88.90 | PANIC |
| e_memcpy | 100000 | oracle | 291416 | 2984 | 11.44 | 114.40 | ok |
| e_memcpy | 100000 | lean-first | 231672 | 2372 | 11.38 | 113.80 | PANIC |
| e_memcpy | 100000 | lean-exh | 230980 | 2365 | 11.57 | 115.70 | PANIC |
| c_struct_arg | 262144 | oracle | 7593380 | 29662 | 538.06 | 2052.54 | ok |
| c_struct_arg | 262144 | lean-first | 298212 | 1165 | 114.0 | 434.88 | ok |
| c_struct_arg | 262144 | lean-exh | 463792 | 1812 | 600.02 | 2288.89 | TIMEOUT |
| c_struct_ret | 262144 | oracle | 344916 | 1347 | 77.09 | 294.08 | ok |
| c_struct_ret | 262144 | lean-first | 299504 | 1170 | 100.65 | 383.95 | ok |
| c_struct_ret | 262144 | lean-exh | 299652 | 1171 | 100.59 | 383.72 | ok |
| a_uninit_local | 1000000 | oracle | 224616 | 230 | 1.36 | 1.36 | ok |
| a_uninit_local | 1000000 | lean-first | 214276 | 219 | 1.85 | 1.85 | ok |
| a_uninit_local | 1000000 | lean-exh | 213660 | 219 | 2.14 | 2.14 | ok |
| a_zero_global | 1000000 | oracle | 898928 | 921 | 9.02 | 9.02 | ok |
| a_zero_global | 1000000 | lean-first | 682996 | 699 | 6.2 | 6.20 | ok |
| a_zero_global | 1000000 | lean-exh | 681848 | 698 | 4.85 | 4.85 | ok |
| b_zero_local | 1000000 | oracle | 4539440 | 4648 | 48.76 | 48.76 | ok |
| b_zero_local | 1000000 | lean-first | 28208 | 29 | 1.25 | 1.25 | PANIC |
| b_zero_local | 1000000 | lean-exh | 28212 | 29 | 1.2 | 1.20 | PANIC |
| d_loop | 1000000 | oracle | 2454096 | 2513 | 203.42 | 203.42 | ok |
| d_loop | 1000000 | lean-first | 374164 | 383 | 12.37 | 12.37 | PANIC |
| d_loop | 1000000 | lean-exh | 374880 | 384 | 10.64 | 10.64 | PANIC |
| e_memcpy | 1000000 | oracle | 3021908 | 3094 | 137.48 | 137.48 | ok |
| e_memcpy | 1000000 | lean-first | 1047960 | 1073 | 25.0 | 25.00 | PANIC |
| e_memcpy | 1000000 | lean-exh | 1047464 | 1073 | 26.64 | 26.64 | PANIC |
| a_uninit_local | 10000000 | oracle | 2272540 | 233 | 13.25 | 1.32 | ok |
| a_uninit_local | 10000000 | lean-first | 2187456 | 224 | 18.82 | 1.88 | ok |
| a_uninit_local | 10000000 | lean-exh | 2187320 | 224 | 18.16 | 1.82 | ok |
| a_zero_global | 10000000 | oracle | 6936188 | 710 | 301.7 | 30.17 | TIMEOUT |
| a_zero_global | 10000000 | lean-first | 2639896 | 270 | 300.23 | 30.02 | TIMEOUT |
| b_zero_local | 10000000 | oracle | 4887060 | 500 | 300.44 | 30.04 | TIMEOUT |
| b_zero_local | 10000000 | lean-first | 27156 | 3 | 1.1 | 0.11 | PANIC |
| b_zero_local | 10000000 | lean-exh | 26300 | 3 | 1.1 | 0.11 | PANIC |
| a_zero_global | 10000000 | oracle | 7653020 | 784 | 245.74 | 24.57 | ok |

### Derived: growth exponents between consecutive sizes (log(ratio)/log(size ratio); 1 = linear, 2 = quadratic); ok rows only

| class | engine | N₁→N₂ | wall exponent | ΔRSS exponent |
|---|---|---|---|---|
| a_uninit_local | lean-exh | 1000→10000 | 0.44 | nan |
| a_uninit_local | lean-exh | 10000→100000 | 0.24 | nan |
| a_uninit_local | lean-exh | 100000→1000000 | 1.05 | 1.03 |
| a_uninit_local | lean-exh | 1000000→10000000 | 0.93 | 1.01 |
| a_uninit_local | lean-first | 1000→10000 | 0.26 | -0.02 |
| a_uninit_local | lean-first | 10000→100000 | 0.30 | 2.09 |
| a_uninit_local | lean-first | 100000→1000000 | 1.01 | 1.01 |
| a_uninit_local | lean-first | 1000000→10000000 | 1.01 | 1.01 |
| a_uninit_local | oracle | 1000→10000 | -0.05 | nan |
| a_uninit_local | oracle | 10000→100000 | 0.38 | 1.08 |
| a_uninit_local | oracle | 100000→1000000 | 0.85 | 0.98 |
| a_uninit_local | oracle | 1000000→10000000 | 0.99 | 1.01 |
| a_zero_global | lean-exh | 1000→10000 | 0.36 | nan |
| a_zero_global | lean-exh | 10000→100000 | 0.39 | 1.14 |
| a_zero_global | lean-exh | 100000→1000000 | 1.09 | 1.01 |
| a_zero_global | lean-first | 1000→10000 | 0.05 | 1.23 |
| a_zero_global | lean-first | 10000→100000 | 0.69 | 1.04 |
| a_zero_global | lean-first | 100000→1000000 | 1.10 | 1.01 |
| a_zero_global | oracle | 1000→10000 | 0.41 | 1.20 |
| a_zero_global | oracle | 10000→100000 | 0.48 | 1.07 |
| a_zero_global | oracle | 100000→1000000 | 1.22 | 0.96 |
| a_zero_global | oracle | 1000000→10000000 | 1.44 | 0.93 |
| b_zero_local | lean-exh | 1000→10000 | 0.80 | 1.17 |
| b_zero_local | lean-exh | 10000→100000 | 0.94 | 1.04 |
| b_zero_local | lean-first | 1000→10000 | 0.88 | 1.07 |
| b_zero_local | lean-first | 10000→100000 | 0.85 | 1.04 |
| b_zero_local | oracle | 1000→10000 | 0.73 | 1.08 |
| b_zero_local | oracle | 10000→100000 | 0.89 | 0.99 |
| b_zero_local | oracle | 100000→1000000 | 1.22 | 1.01 |
| c_struct_arg | lean-exh | 1024→4096 | 0.24 | 0.77 |
| c_struct_arg | lean-exh | 4096→16384 | 0.77 | 0.93 |
| c_struct_arg | lean-exh | 16384→65536 | 2.34 | 0.98 |
| c_struct_arg | lean-first | 1024→4096 | 0.16 | 2.75 |
| c_struct_arg | lean-first | 4096→16384 | 1.39 | 1.05 |
| c_struct_arg | lean-first | 16384→65536 | 1.54 | 0.97 |
| c_struct_arg | lean-first | 65536→262144 | 2.14 | 1.06 |
| c_struct_arg | oracle | 1024→4096 | 0.50 | 0.83 |
| c_struct_arg | oracle | 4096→16384 | 0.91 | 0.95 |
| c_struct_arg | oracle | 16384→65536 | 1.37 | 1.05 |
| c_struct_arg | oracle | 65536→262144 | 1.86 | 0.96 |
| c_struct_ret | lean-exh | 1024→4096 | 0.42 | 2.91 |
| c_struct_ret | lean-exh | 4096→16384 | 0.56 | 1.01 |
| c_struct_ret | lean-exh | 16384→65536 | 2.02 | 1.04 |
| c_struct_ret | lean-exh | 65536→262144 | 2.06 | 0.98 |
| c_struct_ret | lean-first | 1024→4096 | 0.13 | 3.28 |
| c_struct_ret | lean-first | 4096→16384 | 0.75 | 0.92 |
| c_struct_ret | lean-first | 16384→65536 | 2.01 | 1.02 |
| c_struct_ret | lean-first | 65536→262144 | 2.09 | 0.97 |
| c_struct_ret | oracle | 1024→4096 | 0.54 | 1.24 |
| c_struct_ret | oracle | 4096→16384 | 0.46 | 0.77 |
| c_struct_ret | oracle | 16384→65536 | 1.98 | 1.11 |
| c_struct_ret | oracle | 65536→262144 | 1.98 | 0.99 |
| d_loop | lean-exh | 1000→10000 | 1.00 | 1.09 |
| d_loop | lean-first | 1000→10000 | 1.01 | 1.09 |
| d_loop | oracle | 1000→10000 | 0.95 | 0.88 |
| d_loop | oracle | 10000→100000 | 0.88 | 1.03 |
| d_loop | oracle | 100000→1000000 | 1.06 | 1.01 |
| e_memcpy | lean-exh | 1000→10000 | 0.33 | 0.91 |
| e_memcpy | lean-first | 1000→10000 | 0.38 | 0.89 |
| e_memcpy | oracle | 1000→10000 | 0.63 | 1.40 |
| e_memcpy | oracle | 10000→100000 | 0.64 | 1.15 |
| e_memcpy | oracle | 100000→1000000 | 1.08 | 1.02 |

### 3.1 Reading the sweep [AGENT]

Fixed costs (`z_base`): nolibc oracle 43.8 MB / Lean 77.8 MB; libc
oracle 110.1 MB / Lean 230.5 MB (the pinned libc Core text + 12
metadata TUs loaded per run; 2.8 s of Lean start-up in libc mode).
All per-byte figures below subtract these. Rows for N ≤ 10 K are
noise-dominated (ΔRSS within a few MB of zero) and are not used for
fits; the exponents quoted are from N ≥ 100 K unless stated.

(a) Uninitialised local array — `allocateObject` `none` branch.
Linear in both engines, both in time and in resident memory:
oracle 230–241 B/byte, Lean 213–224 B/byte (ΔRSS exponent ≈ 1.0 from
100 K → 1 M → 10 M on both); wall 1.3–1.9 µs/byte on both (Lean 1.4×
the oracle at 10 M). 10 M bytes: oracle 13.3 s / 2.27 GB, Lean 18.8 s
/ 2.19 GB. This is the detective's `int b[N]` shape; the two engines
are within 5 % in memory.

(a') Zero-initialised STATIC array — `allocateObject` `some` branch
(`memValueToBytes` of an N-element `MVarray` then per-byte insert).
Linear, larger constant, ORACLE heavier: oracle 921–1001 B/byte,
Lean 685–699 B/byte; wall oracle 5.4–9.0 µs/byte, Lean 3.9–6.2. At
10 M bytes the oracle takes 5:14.6 and 7.70 GB; Lean HANGS (§6.2).

(b) Zero-initialised LOCAL array (`= {0}`) — the initialiser goes
through the front end as an N-element list and then the store path.
Linear but very heavy on BOTH engines, oracle heavier: oracle 4,583–
4,648 B/byte (1 M bytes: 48.8 s, 4.58 GB), Lean 3,144–3,155 B/byte at
100 K; at 1 M Lean exhausts fuel in the front end (§6.1). A Core-size
cost inherited from upstream's desugaring, not a memory-model cost.

(c) By-value struct (a one-member `char b[N]` struct). Single-trace:
wall exponents 16 K → 64 K → 256 K are ≈ 2.0 on BOTH engines
(`c_struct_ret`: oracle 1.98 then 1.98; Lean 2.01 then 2.09 —
`c_struct_ret_262144` oracle 77.1 s vs Lean 100.7 s at ~300 MB ΔRSS
each; `c_struct_arg` `--first` 5.85 s → 114 s for 4× the bytes).
Resident memory stays linear (~1.2–1.35 KB per struct byte on both
— the value is materialised as an N-element `MVarray` in the Core
value AND as N `AbsByte`s several times over). Exhaustive mode on
`c_struct_arg` (4,620 executions from unsequenced argument
evaluation, both engines): oracle 40.7 s / 2.05 GB at 64 K and
538 s / 7.6 GB at 256 K; Lean 218 s / 1.96 GB at 64 K and TIMEOUT
(600 s) at 256 K with 0.54 GB — Lean's exhaustive runner is ~5× the
oracle's wall time here at equal or lower memory. §3b gives the
like-for-like single-trace oracle (`--mode=random`) rows.

(d) Sequential byte loop. Per-iteration cost dominates on both:
oracle 178–203 µs and ~2.5 KB of RESIDENT memory per iteration (the
oracle retains ~2.5 GB for a 1 M-iteration loop!), Lean ~89 µs and
~2.6 KB per iteration up to the fuel ceiling at 100 K (§6.1). The
per-step retention is thus upstream-shaped (both drivers keep
per-step data alive — the ND trace/history), not a Lean memory-model
property; Lean is 2× FASTER per step here.

(e) `memset` + `memcpy` (libc mode). Oracle 114–137 µs/byte and ~3 KB
resident per byte (1 M: 137 s, 3.0 GB); Lean ~114 µs/byte and 2.4 KB
resident per byte until fuel exhaustion at 100 K. The interpreted
libc `memset` loop dominates (same per-step shape as (d));
`memcpyM`'s per-byte load/store is a constant factor on top.

Cross-class attribution (derived from the class differences):
- allocation of unspecified bytes: ~215 B and ~1.8 µs per byte in
  Lean (map node + big-integer key + transient list cell); oracle
  ~235 B and ~1.4 µs (map node + record + GC overhead);
- serialisation of a value into bytes (`memValueToBytes` + insert):
  (a') − (a) ≈ +480 B/byte Lean, +690 B/byte oracle;
- aggregate LOAD (`readBytesFrom` + `reconstructValue`): the only
  super-linear TIME path, ≈ 2.0 exponent on both engines (§5.4);
- per-Core-step retention: ~2.5 KB/step on both engines (§5.7).

### 3b. Like-for-like single trace: oracle `--mode=random` vs Lean `--first`

The oracle's exhaustive rows conflate the interpreter's per-execution
cost with the fan-out; `--mode=random` (one trace) is the analogue of
Lean `--first`. Verbatim rows (`tests/mem-scale-probes/results/2026-09-01_oracle-random.tsv`):

```
c_struct_arg_1024	nolibc	oracle-random	0	0.03	44740	VAL:Specified(0)	-
c_struct_arg_4096	nolibc	oracle-random	0	0.06	49272	VAL:Specified(0)	-
c_struct_arg_16384	nolibc	oracle-random	0	0.32	62916	VAL:Specified(0)	-
c_struct_arg_65536	nolibc	oracle-random	0	4.03	129292	VAL:Specified(0)	-
c_struct_arg_262144	nolibc	oracle-random	0	74.39	359492	VAL:Specified(0)	-
c_struct_ret_65536	nolibc	oracle-random	0	5.80	129536	VAL:Specified(7)	-
c_struct_ret_262144	nolibc	oracle-random	0	72.73	389484	VAL:Specified(7)	-
det_pr20621-1	libc	oracle-random	0	1.40	142940	VAL:Specified(0)	-
```

Derived, single trace, oracle-random vs Lean `--first` (Lean rows
from §3 / §2):

| probe | oracle-random wall / ΔRSS | Lean --first wall / ΔRSS | Lean/oracle wall | exponent 64K→256K (oracle / Lean) |
|---|---|---|---|---|
| c_struct_arg_65536 | 4.03 s / 85.5 MB | 5.85 s / 68.3 MB | 1.45× | — |
| c_struct_arg_262144 | 74.39 s / 315.7 MB | 114.00 s / 298.2 MB | 1.53× | 2.10 / 2.14 |
| c_struct_ret_65536 | 5.80 s / 85.7 MB | 5.55 s / 77.5 MB | 0.96× | — |
| c_struct_ret_262144 | 72.73 s / 345.7 MB | 100.65 s / 299.5 MB | 1.38× | 1.82 / 2.09 |
| det_pr20621-1 (libc) | 1.40 s / 32.8 MB | 4.05 s / 0.2 MB | 2.9× gross; ≈1.4× net of the 2.8 s libc start-up | — |

[AGENT] On a single trace the two engines are within 1.5× in wall
time and within 15 % in resident memory on the by-value aggregate
cases, and BOTH are quadratic in the aggregate size. The 3–5×
exhaustive-mode gap is the ND runner's per-execution constant times
4,620 executions, not the memory model.

## 4. Micro-benchmark: the byte-path primitives in isolation (task 3 evidence)

`tests/mem-scale-probes/micro/` — one executable importing `CerbMem`
and timing each primitive on synthetic inputs (`memscale-micro <case>
<N> [hi]`; `hi` places the bytes at the concrete allocator's real
region near `0xFFFFFFFFFFFF` so the keys are 48-bit; `lo` at 0x1000
so they fit Lean's small-`Int` range). Wall time is the in-process
monotonic clock around the timed call (the pre-built input is forced
before the first clock read and the result forced before the
second); peak RSS is `/usr/bin/time -v` over the whole process, so
it includes the pre-built input where there is one. Verbatim TSV
(`results/2026-09-01_micro.tsv`):

```
# memscale-micro 2026-09-02T01:22:38Z cap=32G; columns: case N base wall_ms maxrss_kb result (ms from the in-process monotonic clock around the timed call; maxrss from /usr/bin/time -v over the whole process incl. pre-built inputs)
case	N	base	ms	maxrss_kb	result
replicate	100000	lo	1	11164	result=100000
replicate	1000000	lo	7	39724	result=1000000
replicate	10000000	lo	109	322284	result=10000000
alloc	100000	lo	19	13048	result=100000
alloc	1000000	lo	216	56132	result=1000000
alloc	10000000	lo	2323	480072	result=10000000
read	100000	lo	7	15256	result=100000
read	1000000	lo	72	86776	result=1000000
read	10000000	lo	749	793468	result=10000000
serialize_chararray	100000	lo	7	21212	result=100000
serialize_chararray	1000000	lo	137	127796	result=1000000
serialize_chararray	10000000	lo	1353	1315568	result=10000000
bytesToInt	100000	lo	1	11056	result=0
bytesToInt	1000000	lo	17	39768	result=0
bytesToInt	10000000	lo	105	322304	result=0
store_loop	100000	lo	16	13276	result=100000
store_loop	1000000	lo	204	56180	result=1000000
store_loop	10000000	lo	2479	480120	result=10000000
load_loop	100000	lo	5	13072	result=100000
load_loop	1000000	lo	73	56168	result=1000000
load_loop	10000000	lo	776	480064	result=10000000
alloc	1000000	hi	439	117764	result=1000000
alloc	10000000	hi	4704	1104932	result=10000000
read	1000000	hi	238	148312	result=1000000
read	10000000	hi	2643	1418188	result=10000000
store_loop	1000000	hi	481	117848	result=1000000
store_loop	10000000	hi	5381	1105680	result=10000000
reconstruct_chararray	16384	lo	109	11140	result=16384
reconstruct_chararray	65536	lo	1801	17232	result=65536
reconstruct_chararray	262144	lo	28424	41796	result=262144
reconstruct_chararray	524288	lo	113540	74480	result=524288
reconstruct_intarray	16384	lo	29	9124	result=4096
reconstruct_intarray	65536	lo	458	11104	result=16384
reconstruct_intarray	262144	lo	7089	23364	result=65536
reconstruct_intarray	524288	lo	29109	37592	result=131072
copy_chararray	16384	lo	113	13184	result=32768
copy_chararray	65536	lo	1788	21180	result=131072
copy_chararray	262144	lo	28889	56256	result=524288
```

Derived (RSS − the ~8 MB process baseline, / N; and ms / N):

| case | what it isolates | B/byte at 10 M (lo) | B/byte at 10 M (hi) | ns/byte (lo, 10 M) | growth 1 M → 10 M (wall) |
|---|---|---|---|---|---|
| replicate | `List.replicate` of the shared unspecified byte (allocation list only) | 32 | — | 11 | 15.6× (exp 1.19) |
| alloc | `writeBytesTo` on an empty state = per-byte `TreeMap.insert` (uninitialised allocation) | 48 | 112 | 232 / hi: 470 | 10.8× (exp 1.03) |
| read | `readBytesFrom` over a resident N-byte map (per-byte lookup + list build) | 80 | 144 | 75 / hi: 264 | 10.4× (exp 1.02) |
| serialize_chararray | `memValueToBytes` of an N-element `MVarray` of `MVinteger` (repr) | 134 | — | 135 | 9.9× (exp 0.99) |
| bytesToInt | `bytesToInt` over N bytes (one big integer) | 32 | — | 10 | 6.2× (exp 0.79) |
| store_loop | N single-byte `writeBytesTo` at consecutive addresses (map update) | 48 | 112 | 248 / hi: 538 | 12.2× (exp 1.08) |
| load_loop | N single-byte `readBytesFrom` (map lookup) | 48 | — | 78 | 10.6× (exp 1.03) |

| case | what it isolates | 16 K → 64 K → 256 K → 1 M wall (ms) | exponent per step |
|---|---|---|---|
| reconstruct_chararray | `reconstructValue` of `char[N]` (abst, array arm) | 109 → 1801 → 28424 → 113540 | 2.02, 1.99, 2.00 |
| reconstruct_intarray | `reconstructValue` of `int[N/4]` (abst, array arm, 4-byte elements) | 29 → 458 → 7089 → 29109 | 1.99, 1.98, 2.04 |
| copy_chararray | read + abst + repr + write of `char[N]` (the by-value copy path) | 113 → 1788 → 28889 | 1.99, 2.01 |

Readings [AGENT]:
- `alloc` (lo) = **48 B/byte**: exactly one `Std.TreeMap` inner node
  (header + size + key + value + 2 children = 6 words) per byte; the
  unspecified `AbsByte` is shared (one object) and the input list is
  consumed as the fold proceeds (peak 480 MB < replicate's 322 MB +
  map). `alloc` (hi) = **~110 B/byte**: the 48-bit keys add ~62 B per
  byte — the heap big-integer per key (§5.1). Reading the state back
  (`read`) adds one cons cell per byte (~31 B) and, at `hi`, another
  big integer per address computed.
- The driver's measured ~215–225 B/byte for an uninitialised
  allocation (§3 (a)) therefore decomposes as ≈ 110 B (map node +
  big-integer key) + the Core-side value/trace residue; the OCaml's
  ~230–240 B/byte is map node (48 B) + record (32 B) + `Some` (16 B)
  under a ~2× GC space factor.
- `serialize_chararray` = ~131 B/byte at 10 M (the input `MVarray` of
  `MVinteger` cells ≈ 72 B/element plus the output `AbsByte` list ≈
  72 B/byte, partly overlapping in lifetime) — the (a') − (a) delta
  in §3 (~480 B/byte) is this plus the Core value's own copies.
- `reconstruct_*` growth: see the second table — the array arm's
  wall time grows with exponent ≈ 2 while `bytesToInt`/`read`/
  `serialize` grow linearly, corroborating §5.4 in isolation.

## 5. Hot-path localisation (task 3)

Code paths named in classic terms, cited file:line (worktree @
`bbdbacaff`), each with its OCaml counterpart and the micro-benchmark
evidence from §4.

### 5.1 Allocation of an uninitialised object — linear, shared constant

`CerbMem.lean:1504-1531 allocateObject`, `none` branch (:1529-1530):
`writeBytesTo st' alignedAddr (List.replicate size ⟨Prov_none,none,none⟩)`;
`writeBytesTo` (:1455-1460) is a left fold of `Std.TreeMap.insert`
per byte. Mirrors `impl_mem.ml:1288-1325` exactly (OCaml: `repr
(MVunspecified ty)` = `List.init size (fun _ -> AbsByte.v Prov_none
None)` then `List.fold_left IntMap.add`). Complexity: n log n time,
one map node per byte resident. Mechanisms:
- `List.replicate` shares ONE `AbsByte` object across all cons cells
  (Lean `replicate` copies the pointer), so the resident cost per
  byte is the map node only; the list is transient.
- **Keys are big integers.** `bytemap : Std.TreeMap Int AbsByte`
  keyed by the 48-bit address (`lastAddress = 0xFFFFFFFFFFFF`,
  `MemState`, :122). Lean boxes `Int` as a scalar only within
  `LEAN_MIN_SMALL_INT..LEAN_MAX_SMALL_INT` = `INT_MIN..INT_MAX`
  (lean.h:1588-1589, 32-bit range on 64-bit hosts); every address key
  and every `acc.2 + 1` step (:1458) therefore allocates a heap
  big-integer object. OCaml's `IntMap = Map.Make(Z)` keeps Zarith
  values ≤ 2^62 immediate. This is a genuine Lean-only constant,
  quantified in §4: the bare bytemap costs 48 B/byte and 232 ns/byte
  with small keys, 112 B/byte and 470 ns/byte at the real address
  range (`alloc lo` vs `alloc hi`; lookups 75 vs 264 ns/byte). `Nat` would be scalar
  up to 2^63 (`LEAN_MAX_SMALL_NAT`), but `Address := Int` is part of
  the mirrored signature (see the charter).
- Semantic redundancy shared with upstream: `readBytesFrom` (:1462-
  1466) and OCaml `fetch_bytes` (:708-722) both default an ABSENT key
  to the unspecified byte, so the allocation-time write of
  unspecified bytes is observationally redundant on both sides — the
  lever a sparse instance would pull (charter C4).

### 5.2 Allocation of a zero-initialised static / stored aggregate — linear, larger shared constant

`allocateObject` `some val_` branch (:1525-1528) and `storeM`
(:1667-1733, `doStore` :1683-1684): `memValueToBytes` (:580-676)
then `writeBytesTo`. The array arm (:635-642) mirrors OCaml
`repr` (:1193-1200): reversed cons accumulation then
`reverse.flatten` — linear. Per byte the serialised `AbsByte` is a
fresh 3-field object (32 B) plus a `some (v : UInt8)` cell (16 B),
resident in the map; the input `MVarray` of `MVinteger ity (IV prov
n)` elements costs ~48 B/element transient on top of the Core value
itself. The oracle's `AbsByte.t` record + `Some char` is the same
shape (32 + 16 B) under a GC with ~2× space overhead. Hence both
engines land at 700–1000 B/byte on `a_zero_global` (§3).

### 5.3 The struct arm of `memValueToBytes` — quadratic in member count (Lean AND OCaml)

`:643-660`: `accBs ++ List.replicate pad paddingByte ++ bs` inside a
left fold over members — `List.append` in a left fold, quadratic in
the number of members × bytes. This mirrors `impl_mem.ml:1202-1214`
(`acc @ List.init pad padding_byte @ bs`, the same left-fold append),
so it is a shared upstream shape, not a divergence. Only bites on
structs with many members (kernel structs: tens to hundreds); the
probes here have one member, so it is not exercised — flagged, not
measured.

### 5.4 The array arm of `reconstructValue` — QUADRATIC in Lean; the oracle's `abst` is quadratic too, by a different mechanism

Lean `:735-744`: for each of the `n` elements,
`bytes.drop (i * elemSize) |>.take elemSize` — `List.drop` walks
`i·elemSize` cells, so the arm costs Σ_i i·elemSize = Θ(n²·elemSize/2)
pointer chases per aggregate load (time; space stays linear since
`drop` shares tails and `take` allocates `elemSize` cells per
element). The Lean header (:678-680) documents the changed INVARIANT
("bytes is exactly the sizeof(ty) slice … recursive calls re-slice")
but not its complexity consequence.

OCaml `abst` (impl_mem.ml:916-994) is consume-and-return-rest in
shape (`self elem_ty cs` returns the unconsumed suffix, :990-993), BUT
its entry guard `if Z.lt (Z.of_int (List.length bs)) (sizeof cty)
then failwith "abst, |bs| < sizeof(ty)"` (:929-930) runs
`List.length` over the REMAINING list at every recursive call — for an
n-element array that is Σ_i (n−i)·elemSize = Θ(n²·elemSize/2) as
well. So upstream is quadratic in the element count on aggregate
loads by its own mechanism; the measurements agree: wall exponents
at 16K→64K bytes are 1.98 (oracle) vs 2.01 (Lean) on `c_struct_ret`
(§3 fits), and the oracle's exhaustive 64K→256K step is 13.2×
(exponent 1.86). [AGENT] Corrected reading: this is NOT a Lean-only
divergence in complexity class — both engines are Θ(n²) here — it is
a Lean-only *mechanism* (re-slicing) mirroring an upstream
*mechanism* (length re-check). Lean's constant is larger (§3: Lean
`--first` 5.85 s vs oracle-exhaustive-per-execution far less; direct
single-trace comparison in §3b `oracle-random` rows).

Reached by every load of an array-typed lvalue, every by-value struct
containing an array (`c_struct_*`), and — via `MVarray` inside
`MVstruct` — every struct copy. The struct arm (:759-770) has the
same `drop off |>.take` shape per member (quadratic in members ×
bytes; OCaml's struct arm walks with `L.split_at` per member AND the
per-call `List.length`, so that one is shared too).

Fix shape (charter C1, trust class 0): one linear chunking pass
(`List.splitAt elemSize` threaded through the fold — OCaml's
consume-and-return-rest shape WITHOUT its length re-check) with the
equality theorem `reconstructValue' … = reconstructValue …` proved by
induction on `n` from the list lemma `(l.drop (i·e)).take e =
chunk i` — an ordinary functional-equality proof over lists. Upstream
has a matching fix candidate (hoist the `List.length` guard out of
the recursion, or check once at the top-level call) for the
upstream tray — it would make the ORACLE linear on aggregate loads
and is where the differential corpus's economics actually bind.

### 5.5 `bytesToInt` / `splitBytesProv` / `provFromIntegerBytes` — linear

`:512-530` `bytesToInt`: one `any` pass, one accumulating fold
(`acc + (v <<< (i*8))` — note the accumulator is a big integer past
4 bytes, so each step allocates; for 8-byte scalars this is
negligible), one `length`. `:537-565` linear folds. No super-linear
path.

### 5.6 `memcpyM` — linear per byte through the ND monad

`:1980-1992`: per byte one `loadM` + one `storeM` via `nd_bind`,
mirroring `impl_mem.ml:2635-2644`. Each byte does the full
`readBytesFrom`/`reconstructValue`/`memValueToBytes`/`writeBytesTo`
cycle for a 1-byte `unsigned char` — constant work per byte, but a
large constant (each step allocates the big-integer address, a
1-element list, a `MemValue`, a footprint). The libc `memset` is
interpreted C (a Core loop), so `e_memcpy_N` is dominated by the
interpreter's per-step cost and, at 100 K, by the fuel ceiling (§6).

### 5.7 The driver-vs-primitive residue (open)

The driver spends ~1.9 µs and ~220 B per uninitialised byte (§3 (a),
10 M); the isolated primitive (`alloc hi`, §4) accounts for 0.47 µs
and 112 B. The remaining ~1.4 µs and ~110 B per byte are outside
`writeBytesTo` itself. [AGENT] Candidate, NOT verified here: in the
driver the `MemState` reaching `allocateObject` may be SHARED
(referenced from the ND tree / trace / the pre-state kept for a
`Killed` result), in which case `Std.TreeMap.insert`'s in-place
update degrades to persistent path copying (~log₂ N ≈ 23 node
allocations per insert) — a uniqueness-loss mechanism that a
refcount-instrumented run (`IO.getRC`-style probe, or a debug build
printing `lean_is_exclusive` at the fold) would confirm or refute in
minutes. The same question applies to the oracle's constant (its
`IntMap` is always persistent). Listed for S1's profiling step, not
acted on.

### 5.8 What is NOT in the memory model

- `d_loop_N`: Lean RSS grows with iteration count on BOTH engines but
  Lean's slope is steeper (§3) — the ND/driver step machinery retains
  per-step data; out of this arc's scope (interpreter), flagged.
- `b_zero_local_N` (`char a[N] = {0}`): heavy on both engines and
  heavier on the ORACLE (§3): the desugared initialiser is a Core
  value/expression of N elements, a front-end/Core-size cost the
  semantics inherit from upstream; not a memory-model cost.
- `c_struct_arg_N` exhaustive: 4,620 executions from unsequenced
  argument evaluation on both engines; Lean's exhaustive runner is
  3–5× slower in wall time at equal RSS (`CerbND.lean:89-131
  runNDFuel`, list-append accumulation mirroring smt2.ml:75-82).
  Semantics-shaped; the per-execution constant is the interpreter's.

## 6. Ceilings that are NOT the memory representation (found by this study)

### 6.1 `lemDefaultFuel` — the binding Lean ceiling on long executions

`d_loop_100000`, `d_loop_1000000`, `e_memcpy_100000`,
`e_memcpy_1000000` and `b_zero_local_1000000` all end on the Lean
side with (verbatim stderr head) `lem: fuel exhausted` and exit 134
(abort under `LEAN_ABORT_ON_PANIC`), on BOTH `--first` and exhaustive
drivers, after 1–12 s, at ≤ 460 MB RSS. The oracle completes all of
them (`d_loop_1000000`: see §3; `b_zero_local_1000000`: 48.8 s,
4.58 GB). This is the already-registered "Step-runner execution
ceiling" (TODO.md small items; design space in
`docs/2026-08-31_stack-ceiling-design.md`): `lemDefaultFuel = 10^6`,
onset ≈ 1.7e4 loop iterations. Two refinements to that record from
this study [AGENT]: (i) the ceiling is reached through a libc
`memset` of 100 KB as readily as through a user loop (the libc C is
interpreted Core); (ii) `b_zero_local_1000000` exhausts fuel in
1.25 s at baseline RSS — i.e. in the FRONT-END/translation of a
10^6-element initialiser, not in the step runner, so a second
fuel-bounded recursion (desugaring/translation of initialiser lists)
has the same 10^6 shape. Fuel is lem-side; out of this arc; it is,
however, the first wall a kernel-shaped program hits on the Lean
driver, well before memory does.

### 6.2 A Lean-side HANG on a ≥ 8 M-element zero-initialised global (new; fail-closed violated)

`a_zero_global_10000000` (`char g[10000000];` at file scope, touch
two elements): the oracle completes (5:14.59 wall, 7,696,892 KB).
The Lean `--first` run stopped consuming CPU after ~3.8 s at 2.7 GB
RSS and sat there until the 600 s timeout. Live inspection while
hung (`/proc`, verbatim):

```
    PID STAT WCHAN                    ELAPSED     TIME   RSS COMMAND
2914351 Sl   futex_do_wait              05:37 00:00:03 2715296 …/cerberus-lean --batch --first …
tid=2914351 state=S utime=1 stime=0 wchan=futex_do_wait
tid=2914355 state=S utime=0 stime=0 wchan=ep_poll
tid=2914361 state=S utime=265 stime=114 wchan=futex_do_wait
VmPeak:	 4412076 kB
VmRSS:	 2715296 kB
Threads:	3
```

All three threads blocked (main and the worker that did the work
both on futexes; the third is the libuv poller); cgroup
`memory.events` shows `max 0 oom 0` (no memory pressure; cap 32 G);
no output, no panic, no message. `Main.lean` spawns no tasks. This
is a runtime-level deadlock candidate (Lean runs `main` on a worker
thread; the worker parked on a futex after ~3.8 s of work), and it
is a **fail-open-by-silence** defect regardless of cause: the driver
neither completes nor fails noisily. §6.3 below records the
standalone reproduction / size bisection performed after the sweep.
It is NOT the detective's case (that one completes, §2) and it is not
memory exhaustion; it is filed as its own item for the charter
(C9) and TODO.

### 6.3 Hang reproduction and onset (standalone runs after the sweep)

Deterministic: reproduced 3/3 (sweep `--first`, sweep exhaustive,
re-run `--first` with a 300 s timeout — all three parked at 2.72 GB
RSS with ~3–5 s CPU). Size bisection, Lean `--first`, verbatim rows
(`results/2026-09-01_hang-bisect.tsv`):

```
a_zero_global_2000000	nolibc	lean-first	0	5.76	1452000	VAL:Specified(7)	-
a_zero_global_3000000	nolibc	lean-first	0	8.12	2139376	VAL:Specified(7)	-
a_zero_global_5000000	nolibc	lean-first	0	14.38	3558348	VAL:Specified(7)	-
a_zero_global_7000000	nolibc	lean-first	0	20.86	4951452	VAL:Specified(7)	-
a_zero_global_8000000	nolibc	lean-first	124	90.20	2658428	NONE	TIMEOUT(90s);
a_zero_global_9000000	nolibc	lean-first	124	90.09	2682528	NONE	TIMEOUT(90s);
a_zero_global_int_1750000	nolibc	lean-first	0	9.67	2730676	VAL:Specified(7)	-
a_zero_global_int_2500000	nolibc	lean-first	0	13.90	3939528	VAL:Specified(7)	-
Command exited with non-zero status 124
noabort wall=90.09 maxrss=2719368 exit=124
stackexp	8M	LEAN_STACK_SIZE_KB=1048576	Command exited with non-zero status 124 wall=90.09 maxrss=2658956 exit=124 
stackexp	8M	LEAN_STACK_SIZE_KB=4194304	Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} wall=22.50 maxrss=5967020 exit=0 
stackexp	5M	LEAN_STACK_SIZE_KB=2048	Command exited with non-zero status 124 wall=90.00 maxrss=235232 exit=124 
stackexp	5M	LEAN_STACK_SIZE_KB=512	Command exited with non-zero status 124 wall=90.00 maxrss=231716 exit=124 
```

Derived: 2 M → 7 M is linear (≈ 700 B/byte, ≈ 2.9 µs/byte, matching
§3 (a')); the peak RSS at 7 M (4.95 GB) exceeds the hung runs'
plateau (2.66–2.72 GB at 8 M, 9 M and 10 M alike), so the hang is not
a memory threshold — it occurs part-way through building the state,
at an N-independent point. Onset: 7 M completes, 8 M hangs. **The
driver is ELEMENT-count driven, not byte-count driven**: `int
g[2500000]` (the same 10 M bytes as 2.5 M elements) completes in
13.9 s / 3.94 GB, and `int g[1750000]` (7 M bytes) in 9.7 s. So the
trigger is an aggregate of more than ~7–8 × 10^6 ELEMENTS, and the
constant plateau is consistent with a recursion that reaches a fixed
depth (a stack-depth ceiling whose handler blocks) rather than with a
size-keyed resource. `LEAN_ABORT_ON_PANIC` unset: identical hang
(`noabort wall=90.09 maxrss=2719368 exit=124`) — no panic is being
swallowed. The `stackexp` rows above vary the Lean main-thread stack
(`LEAN_STACK_SIZE_KB`, honoured by `lean_run_main`): if a larger
stack moves the onset up and a smaller one moves it down, the cause
is a non-tail recursion over the element list whose overflow handler
deadlocks instead of printing "Stack overflow detected. Aborting."
(the message the runtime carries); see the rows for the outcome
— OUTCOME: at 1 GB (`LEAN_STACK_SIZE_KB=1048576`) the 8 M case
still hangs (2.66 GB plateau); at 4 GB it COMPLETES (`Specified(7)`,
22.5 s, 5.97 GB); and the 5 M case, which completes at the default,
HANGS at both 2 MB and 0.5 MB — parking at ~235 MB, i.e. very early.
The onset moves with the stack size in both directions: **the cause
is a non-tail recursion whose depth is proportional to the aggregate's
element count, overflowing the `lean_run_main` thread's stack, with
the overflow going UNREPORTED** (no "Stack overflow detected.
Aborting.", no exit — the process blocks). Two defects, then: the
recursion (class-0 fix: tail-recursive rewrite + `f = fTR` equality
theorem, once the function is located by running the 8 M input
stage-by-stage under a small `LEAN_STACK_SIZE_KB`), and the runtime's
silent overflow on that thread (a Lean upstream report). The
implied default main-thread stack must be large (7 M frames fit) —
consistent with Lean sizing that thread from the unlimited hard
`RLIMIT_STACK`; that is a runtime detail to confirm, not assumed here. Without `perf`,
`gdb` or `/proc/PID/syscall` (ptrace-scoped) the blocked futex
cannot be attributed further in this environment; the two live
threads' state is recorded verbatim in §6.2. Candidate mechanisms
[AGENT], for the follow-up item, in the order to test: (i) a Lean
runtime lock taken re-entrantly on the path that handles a resource
failure (the plateau RSS is constant across runs); (ii) an
`ST.Ref`/`IO.Ref` `modify` re-entered on the same ref (the driver's
survivors are listed in `scripts/unsafebaseio_allowlist.txt`);
(iii) a task-manager wait with no runnable worker. Whatever the
cause, the defect class is "no output, no exit" — fail-open by
silence — and belongs on TODO with the reproduction recipe:
`tests/mem-scale-probes/probes/a_zero_global_10000000.c`, Lean
`--batch --first`, nolibc, under `scripts/capped`.

## 7. Verdict on the detective hypothesis, and what replaces it

| Claim in RC-3 (2026-08-30) | Status | Evidence |
|---|---|---|
| `array.c` (13.3 MB) — "Lean: INTERNAL PANIC out of memory at the 4GB cap" | **REFUTED** as a memory finding | completes under a 32 G RSS cap at 3.05 GB (oracle 3.10 GB); the panic reproduces ONLY under `ulimit -v 4000000` (virtual), §2 |
| `pr20621-1.c` (64 KB by value ×2) — "Lean OOMs after ~35s … implies super-linear space" | **REFUTED** | exhaustive: 54 s / 1.93 GB (oracle 18 s / 1.87 GB), 4,620 identical verdicts; `--first` 4 s at baseline RSS. Space is linear (ΔRSS exponent ≈ 1.0 on all `c_struct_*` rows); TIME is quadratic — on both engines (§3, §3b) |
| "linear time, ~1KB+ resident per object byte" (scaling probe) | **PARTIAL** | linear time confirmed; resident cost is ~215–225 B/byte uninitialised (Lean) vs ~230–240 (oracle); ~700 (Lean) vs ~920–1000 (oracle) zero-initialised static. The oracle's constant is NOT "far smaller" — it is the same or larger |
| "one boxed struct + cons cell per byte … by-value copies re-materialize lists" as THE root cause | **PARTIAL → re-attributed** | the per-byte-boxed shape is upstream's (`AbsByte.t IntMap.t`), so the constant is inherited; the two Lean-specific costs are big-integer map keys (§5.1) and the `drop`-based re-slicing in `reconstructValue` (§5.4) — and the latter's complexity class is shared with upstream's `List.length` guard |
| Fix direction: "chunked byte arrays or a sparse map" | **DEFERRED to a measured target** | the charter ranks the in-place class-0 fixes first and makes the refinement track conditional on a stated target (design §4) |

The two ceilings the Lean driver ACTUALLY hits before memory, in
order of onset: the `lemDefaultFuel` totalisation budget (§6.1;
~1.7e4 loop iterations / 10^6-element initialisers) and the 10 M-byte
zero-initialised-global hang (§6.2–6.3). Neither is the memory
representation.

Harness follow-up (charter C2): replace `ulimit -v` with
`scripts/capped` in `tests/parity-probes/run_probe.sh:43,51`,
`scripts/test_ci_sweep.sh:222,252,258`,
`scripts/test_libc_exec.sh:82,90,97`; then re-run the detective's
class-(b) rows. The detective's honest-bounds line "KNOWN-DIVERGENT
at … multi-MB objects / >64KB by-value aggregates" should be amended
by that re-run, not by this record.
