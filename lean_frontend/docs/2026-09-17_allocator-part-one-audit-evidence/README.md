# Evidence — pre-merge audit of `arc/allocator-soundness-address-bound` PART ONE (`6d9ba82f1..f5b1578dc`), 2026-09-17

Companion to `../2026-09-17_allocator-part-one-audit-premerge.md`. Every file here is the auditor's own probe program,
plant script or gate transcript, or its verbatim output, taken in the audit worktree
`worktrees/cerberus-lean-audit/allocator-part-one` at `f5b1578dc` (branch `audit/allocator-part-one`). [AGENT auditor]
throughout. Scratch lived under the git-ignored `.tmp/audit/` and `lean_frontend/.tmp/`; everything cited by the report
is copied here.

## The arithmetic (report §2.1, §2.2)

| file | what |
|---|---|
| `alloc_arith.ml`, `alloc_arith.out.txt` | Standalone Zarith program (`Z.quomod = ediv_rem` as `impl_mem.ml:9`): the PRISTINE body (`b9aeedcb4`, pre-fix) and the NEW body (remedy 1) on 42 states — draft 44's four, negative `sz`, `align = 1`, `sz = 0`, cursor `= sz`, cursor `= sz + align − 1`, huge `align`, `align < 0`, negative cursor, `align = 0`, and six states at upstream's bound `0xFFFFFFFFFFFF`. Compiled with the switch's `ocamlfind ocamlopt -package zarith`. |
| `AuditAllocProbe.lean`, `lean_alloc_probe.out.txt` | The SAME 42 states on the ACTUAL `CerbMem.allocator` through `CerbMem.allocatorStep`; the theorem statements as elaborated (`#check`); `#print axioms` for both theorems, `allocatorStep` and `allocator`; `rfl` witnesses that `Address`/`StorageInstanceId` are `Int` and that Int `%`/`/` are `emod`/`ediv`. Run via `scripts/lean_probe.sh` (capped). The `## NEW` block diffs against the OCaml `## NEW` block in exactly the two `align = 0 ∧ z ≥ 0` states (OCaml `Division_by_zero` vs the documented Lean refusal). |

## Negative controls (report §2.3, §2.4)

| file | what |
|---|---|
| `negctrl_a_theorem_vs_old_body.lake.log` | `lake build CerbMemAllocatorProofs` with `generated/CerbMem.lean` = the PRE-FIX body (the worktree hook had primed `generated/` and `.lake` from the mainline, so the compiled `CerbMem.olean` WAS the pre-fix body until the copy step ran): three `unsolved goals` errors — the theorem does not hold of the old allocator. |
| `AuditOldBodyProbe.lean`, `negctrl_b_witness_on_old_body.out.txt`, `negctrl_b.sh`, `negctrl_b.log` | The runtime witness's four cases and EXPECTED outcomes (verbatim from `test/Unit/AllocatorSoundnessTest.lean`) evaluated on the compiled PRE-FIX `CerbMem.allocator`: the two defect states FAIL, the other two PASS. `negctrl_b.sh` is the re-take with the saved output (the ignored `generated/CerbMem.lean` copy swapped to `6d9ba82f1`'s content and restored byte-identically; sync gate, rebuild, stamps and the witness re-verified — transcript `negctrl_b.log`). The probe's trailer string "3 expected" is the auditor's mis-prediction typed before the run; 2 is the correct count (the third state kills pre- and post-fix). |
| `lean_build.sh`, `lean_build.log` | The hand-written copy step (`make lean-prelude-src`, the Makefile's one authority) and the capped rebuild after it (50 modules), the witness exe run, the Lean freshness stamp. |

## The observability reproducers (report §1 M1, §2.5)

All under `repro/`. Engines: pristine = `.validation-foundations/independent-oracle-v2/cerberus/_build/default/backend/driver/main.exe --runtime=…/_build/install/default`; fork = `_build/default/backend/driver/main.exe --runtime=_build/install/default`; Lean = the fork's `--nolibc --cabs-json` bridge then `lean_frontend/.lake/build/bin/cerberus-lean --batch <json>` with `LEAN_ABORT_ON_PANIC=1` under `scripts/capped` (the `tests/minimal` recipe of row 10). Flags as printed in each `.out.txt`.

| file | what |
|---|---|
| `sizes.c`, `sizes-bigstatic-loop.out.txt` | `sizeof(size_t)=8`, `SIZE_MAX=2^64−1` on both oracles; `big-static.c` (one 2^48-byte global) → `Stack overflow` in `Lem_list.replicate` on both (not a route); `loop-1024.c` → 0.25 s per engine. |
| `oom-window-*.c`, `oom-window.nolibc.out.txt`, `oom-window-debug.out.txt` | The auditor's FIRST attempts — both engines `Specified(240)`: the size was 32-bit-truncated by `(size_t)a + 1` (see `trunc*`), so the request never approached the cursor. Kept as the record of the miss. |
| `trunc.c`, `trunc2.c`, `trunc3.c`, `trunc*.out.txt` | Side-observation, OUT OF RANGE: `(size_t)x + 1` is truncated to 32 bits on pristine, fork AND Lean; `(size_t)(x + 1)`, `(unsigned long)x + 1`, `(uintptr_t)x + 1` are not; pointer provenance is not needed (`trunc2`). |
| `loop-65536.c`, `loop-65536.killed-run.out.txt` | 65536 × `malloc(0xFFFFFFF0)` then `malloc(a+1)`: BOTH oracles `out of memory` after ~220 s each (the 8-byte argument temporary of `malloc_proxy` puts the cursor 8 below `a`, so `z = −9`, outside the window). Superseded by the one-shot variants; the backgrounded run was killed after these two results. |
| `oneshot*.c`, `oneshot.three-engines.out.txt` | One-shot `malloc(cursor + 1)` — all three engines `out of memory` (same `z = −9` reason). |
| `v1..v5-declfirst-*.c`, `variants.out.txt` | Declarations-first controls: `v5` (request `a − 16`) lands at low byte 8 on both → the cursor at `alloc` is `a − 8` and malloc's alignment is 8, so the pre-fix window is `z ∈ {−1, −2, −3}` = requests `a − 7 … a − 5`. |
| **`w1-minus7.c`, `w2-minus6.c`, `w3-minus5.c`, `w4-minus4.c`, `w5-minus8.c`, `window.out.txt`, `*.pristine.out`, `*.fork.out`, `*.lean.out`, `w1-lean-and-print.out.txt`** | **THE WITNESS.** At upstream's own bound, no flag: pristine `b9aeedcb4` → `Defined {value: "Specified(6)"}` / `(4)` / `(2)` (an ACTIVE allocation at address 6/4/2); fork → `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}`; Lean = fork. The two edge controls (`a − 4`, `a − 8`) kill on all engines. |
| `w1-overlap.c`, `w1-overlap.out.txt` | Self-checking variant: pristine exits `106` = address 6 + 100 (the new object ends ABOVE the cursor at `alloc` time, i.e. overlaps the live argument temporary) + 0 (NOT 8-aligned); fork killed. |
| `w1-print.c`, `loop-65536-print.c`, `oom-window-printf.c` | libc/printf variants (libc's own start-up allocations shift the cursor; in libc mode `w1-print` kills on both — kept for completeness, not evidence). |

## The projection extension (report §2.5)

| file | what |
|---|---|
| `plants/header_projection_plants.py`, `plants/header_projection_plants.out.txt` | 18 auditor plants against the lane's `compare()`/`project_diagnostics` via `synthetic_record`: 17 as expected; H13 (CRLF header) was the auditor's mis-expectation (the `\r` sits inside the preserved text group on both sides — correct). Each line also reports whether the PRE-C1b projection (`TIME_SPENT` + `FRAME_POSITION` only) would have agreed — H12 (two distinct assert sites in one function) is the residual blind spot. |
| `check_g2.py`, `check_g2.out.txt` | `immaculate/libc/g2-memcmp-uninit` in the auditor's fresh row-10 captures, every differing stderr line classified with the AUDITOR'S OWN tokenizer: 1 header-position-only + 13 frame-position-only + 0 other. |

## Gates at `f5b1578dc` (report §2.7)

| file | what |
|---|---|
| `ocaml_models_build.out.txt` | `dune build @memory/concrete/all @memory/vip/all backend/driver/main.exe cerberus-lib.install` (both fixed models compile; `mem/{concrete,vip}` installed; `symbolic` cannot build in this switch — no `z3`; `cheri-coq` is package `cerberus-cheri`). |
| `check_fork_drift.out.txt` | `check_fork_drift.sh` OK at the head. |
| `gate_chain.sh`, `gate_chain.log` | First chain: the row-10 family FAILED CLOSED on `check_driver_fresh.sh --check-oracle` (the auditor's `dune build` above had relinked `main.exe` — `version.ml` — without the recipe's stamp step); `release.py --mode fast` ran to `passed; 14/14`. |
| `release-fast.log` | The runner transcript: `PASSED A1 … A11`, `fast: passed; 14/14 selected commands completed successfully. Source unchanged: True.` |
| `row10_chain.sh`, `row10_chain.log`, `row10.log`, `row10-plant.log`, `corpus-ci.log` | Second chain after the lanes' own `build_cerberus` re-stamped the oracle: row 10 `passed; {822, 28, 3, 2}`, `--plant` `plants_passed; {1, 1, 51}` (50 `PLANT OK`, 0 `PLANT FAIL`), `--corpus ci` `passed; {134, 2, 106}`. |

## Record integrity (report §2.8)

| file | what |
|---|---|
| `check_record_quotes.py`, `check_record_quotes.out.txt` | Every ``` -fenced line of the record against the evidence directory (+ the three source files): 72 checked, 3 missing (the `rc=1 wall=` lines and the three-engine `failed; {… 'difference': 1}` line of §S1, sourced from deleted `.tmp` logs); 36/36 runner timing tokens present; provenance tag counts; errata E1–E10 present. |

## §A — delta re-read of C1c (`b7fec4d63`, `c58b7d70e`) — `c1c/`

Taken with the 17 files of the two commits checked out into this worktree (tree = `c58b7d70e` outside the audit paths), then restored to `f5b1578dc`.

| file | what |
|---|---|
| `delta_build.sh`, `delta_build.log` | Copy step + capped rebuild on the `c58b7d70e` tree (45 modules; witness OK; stamp). |
| `delta_gates.sh`, `delta_gates.log` | The chain: row 10 (FIRST run — interfered, see below), `--plant`, `--with-lean --only` the two witnesses, `release.py --mode fast`. |
| `d-row10-INTERFERED-by-my-test_elab-run.log`, `d-row10-interference-rows.txt` | The auditor's first delta row-10 run: 15 `difference` rows, all fork status 126/127 "No such file or directory" — the fork `main.exe` was being relinked by the auditor's CONCURRENT `test_elab.sh -v` probe (`test_elab.sh:115-116` `build_cerberus`/`build_lean`). Self-inflicted; the instrument read it fail-closed. |
| `d-row10-2.log` | The CLEAN row-10 re-run (nothing else running): `passed; {822, 28, 5, 2}`; both witnesses `reviewed_difference`. |
| `d-plant.log`, `d-with-lean.log`, `d-release.log`, `d-release-A2-exec.stdout`, `d-release-A9-elab.stdout` | `plants_passed; {1, 1, 51}` (`committed-loads: 5 rows`); three-engine on the witnesses `{'lean_agreement': 2}`; `fast: passed; 14/14 … Source unchanged: True`; A2's two `CERB_SKIP` rows + `0 regression(s), 0 improvement(s)`; A9's `total=113 same=108 diff=5`. |
| `test_elab-v-112.out.txt` | Why A9 reads DIFF for the witnesses: 42 one-sided Lean-side `+procdecl <stdlib.h fn>` / `+tagdef struct {div,ldiv,lldiv}` lines — the lane's documented header-declaration class; `main` agrees. |
| `iso-7.22.3-1-quote-check.out.txt`, `tray44_c58b7d70e.md` | The tray's §7.22.3#1 quotation is a whitespace-normalised substring of `tools/n1570.json` (`True`); the tray text as of `c58b7d70e`. |
| `bigint_quomod.ml`, `bigint_quomod.out.txt` | `Big_int.quomod_big_int` evaluated on negative operands with the switch's `num` library: `(-1) 4 = (-1, 3)`, `(-5) 4 = (-2, 3)`, … — Euclidean, as the tray's history paragraph says. |
| `surviving-claims-grep.out.txt` | `git grep` at `c58b7d70e` for "unobservable/2^48/cumulative", the M3 cites and the D1 claims (`MATCH — fork = Lean`). |
| `check_record_quotes_c1c.out.txt` | The record-quote check on the AMENDED record: 108 fenced lines, 0 missing. |
