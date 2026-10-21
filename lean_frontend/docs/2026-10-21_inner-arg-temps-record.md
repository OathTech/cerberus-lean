# The inner_arg_temps elaboration mode

Worktree branch: `feature/inner-arg-temps`. Starting implementation:
`e32c16709`; dispatch charter: `a8b20cbb6`.

## I0 — upstream PR 1020

[AGENT 2026-10-21, relayed by the operator] Adopt upstream
`f10329b44287ab79ed5017ff68431d5c5953ebd7` before enabling the Lean
driver's mode. The fork retains the defect; upstream's witness demonstrates
it. The separate floating-to-`_Bool` backport and I1b await operator rulings.

The shared `translation.lem` change is upstream's unmodified hunk. It factors
the Normal convention's argument conversion into a helper and uses that
helper for both conventions. Pointer arguments already converted to `_Bool`
are no longer sent through `loaded_ivfromfloat` under `inner_arg_temps`.
Both engines are generated from the same source. The upstream C witness,
expected output and test-list entry are adopted.

Before the patch, the freshly built fork oracle produced the following
outputs with
`_build/default/backend/driver/main.exe --runtime=_build/install/default --exec --batch tests/ci/0344-ptr-to-_Bool-param.c`,
adding `--switches=inner_arg_temps` for the second run. Timing trailers omitted.

Normal, exit 0:

```text
Defined {value: "Specified(0)", stdout: "0 0 1 1 1 9 1 0\n", stderr: "", blocked: "false"}
```

`inner_arg_temps`, exit 1:

```text
Error {msg: "ill-formed program: `PEctor: one of the operands was ill-typed ==> Civfromfloat('_Bool', 1) <====> ['_Bool'; 1]'"}
```

Fork-drift pins (single rows plus a dated NOTE):

- `frontend/model/translation.lem` content:
  `e99043b7e282fdaff5b2df2fa25ef5f5b116a8fe23796eacb617908cf7fa5a75`.
- `translation.ml` label-normalized generated delta against pristine upstream:
  `32d184cce426a27eb4efbd43a29816ca3a2f516b03fbf5452f5afc251dce328d`.

The regenerated fork oracle returns the upstream expected output in both
Normal and `inner_arg_temps` modes (exit 0 in each). The Normal libc dump
retains its content pin:
`d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a`.

The CI scoreboard gains only the adopted witness. Its exhaustive nolibc
run is `CERB_SKIP`: the oracle reaches the lane's 30-second CPU timeout.
This is not differential agreement. The single-file invocation of
`scripts/test_exec.sh tests/ci/0344-ptr-to-_Bool-param.c` failed (exit 1):

```text
[1/1] CERB_SKIP 0344-ptr-to-_Bool-param (Cerberus timeout: TIMEOUT(cpu 30.11s of 30.13s wall; timeout 30s))
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=1 cerb_floor=0 cerb_inconsistent=0
FAILED: zero comparisons happened (all files skipped) — vacuous run
```

The eight call arguments in the upstream witness introduce many evaluation
orders. Its libc single-trace check is separate from this exhaustive
scoreboard entry. No existing scoreboard row changes.

The Normal Lean libc run (`--batch --first --runtime=_build/install/default
--libc tests/libc/libc.core`, with the twelve metadata TUs from
`scripts/libc_prep.sh --jsons` and the witness's exported Cabs JSON) also
returns the exact upstream expected line, exit 0. The switched Lean run
remains for I1/I2, which enable that driver configuration and its libc dump.

Focused checks:

```text
Build completed successfully (402 jobs).
check_fork_content: OK — 88 source files content/mode-pinned
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
libc_prep: OK (content hash verified: pin + regenerated dump == d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a, 4188542 bytes)
```

Existing compiler warnings are visible in the builds. The generated-code
warning class is already tracked in `TODO.md` as a lem-backend follow-up;
the initial build also replayed handwritten deprecation/unused warnings.
No warning suppression or dependency change is introduced by I0.

Tier A: `CERB_MEM_MAX=32G python3 scripts/release.py --mode fast` completed
with exit 0. The launch was delayed until the measured one-minute load was
below 6 (4.68 at 01:54:01 UTC). Verbatim runner conclusion:

```text
PASSED A14.2 (180.6s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The minimal, coverage, debug and float baseline checks each report
`0 regression(s), 0 improvement(s)`. The Normal libc lane reports
`SUMMARY: match=42 diff=0` and `ALL MATCH RECORDED BASELINE`; URI is unchanged
at 16/16 and CN at 213 entries. A9 remains at its recorded
`SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (the same five
signature differences documented in the PNVI S4 record). The PNVI lane's
baseline check passes. No existing baseline row moved.

I0 is green at its required checkpoint boundary. This is Tier A evidence,
not the slice's full close-out battery. No proof module was edited, so the
charter does not require a separate kernel replay for I0.
