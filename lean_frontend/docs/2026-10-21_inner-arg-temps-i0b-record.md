# I0b: upstream floating-to-_Bool backport

2026-10-21, branch `feature/inner-arg-temps`. This implements ruling A in
the [charter amendment](2026-10-21_codex-charter-inner-arg-temps.md).
The recursive-main [park](2026-10-21_inner-arg-temps-park.md) remains in
force for I3/I4. Approved I1b work is deferred to quotation hygiene.

[AGENT 2026-10-21] Append I0b after the existing validated I0–I2 and park
commits, preserving their history. The new ruling arrived after those
checkpoints; inserting I0b between them would rewrite the already
validated commits. The charter amendment accompanies this backport.

## Shared source and witness

Backport upstream `3230aa494c4c18e1b2fea9fd9f0d53dd20f0a324` unchanged in
`frontend/model/translation_aux.lem`, `runtime/libcore/std.core`, and
`runtime/libcore/std_inner_arg_temps.core`. Floating-to-`_Bool` conversion
compares the floating value to zero before any integer truncation.
Both engines are regenerated from the shared Lem source. Adopt upstream
`tests/ci/0343-subzero-floating-to-_Bool.c` and its exact expected output;
add it to the CI test list. Tray 15 is marked fixed upstream, backported.

Before the patch, the freshly built fork oracle gave this wrong result
in both Normal and `inner_arg_temps` modes (libc single trace, exit 0):

```text
Defined {value: "Specified(0)", stdout: "0 0 0 0 1 0 0 0 0 0 0 0 0 1 0\n", stderr: "", blocked: "false"}
```

After regeneration, both engines in both modes produce upstream's
expected result (all four executions exit 0):

```text
Defined {value: "Specified(0)", stdout: "1 1 1 1 1 1 1 1 1 1 1 0 0 1 0\n", stderr: "", blocked: "false"}
```

The I0 witness, 0344, remains correct in those same four configurations:

```text
Defined {value: "Specified(0)", stdout: "0 0 1 1 1 9 1 0\n", stderr: "", blocked: "false"}
```

These checks use the oracle's default single trace and Lean's `--first`,
with libc and the twelve shared metadata TUs. They are not exhaustive
agreement claims. The separate exhaustive nolibc CI invocation fails
because every selected file is skipped, exit 1:

```text
[1/1] CERB_SKIP 0343-subzero-floating-to-_Bool (Cerberus timeout: TIMEOUT(cpu 30.10s of 30.11s wall; timeout 30s))
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=1 cerb_floor=0 cerb_inconsistent=0
FAILED: zero comparisons happened (all files skipped) — vacuous run
```

The witness's fifteen printf arguments admit many evaluation orders.
Only the new 0343 `CERB_SKIP` row is added to the CI baseline; no existing
row changes. Its single-file result is a failure, not a passing gate.

Both tray 15 reproducers also return `Specified(42)` with empty stdout
and stderr in both modes on both engines, using exhaustive nolibc runs:
`tests/parity-probes/probes/bool_conv.c`, and the report's non-finite
`_Bool b = 1e300 * 1e300; return b ? 42 : 7;`. All eight executions exit 0.
The latter checks that this conversion no longer reaches integer
truncation's non-finite exception; it does not claim to fix non-finite
conversion to wider integer types.

## Pins and quotation changes

Single-row manifest edits, without `--refresh`:

| Pin | SHA-256 |
|---|---|
| `translation_aux.lem` source | `c8fd25c5146509d6ddfd7f3bb19272fc9653e142352be126c776f2e71fd5a41d` |
| `std.core` source | `8ebc9ccadea572e29bab5bd8fec558c6cd413c5b5cfd5fcbbc49b526ab0a315a` |
| `std_inner_arg_temps.core` source | `5910f73d116519cc38ba8ef5f32db92a9a060542993ae0cc314a30bde8ec7a00` |
| `translation_aux.ml` generated delta | `f903d7d4637e6287d0e41c0d91b0251d42ca33b626b2a7dd96027a8402dd7464` |

The generated delta is label-normalized against the independently
generated upstream tree. This file was previously byte-identical;
the manifest now accounts for 31 differing generated files instead of
30, with the source inventory still 88 files. The new delta contains
only the approved Bool arm, its import and upstream comments.

Both libc dumps regenerate byte-identically, including symbol numbering.
Neither dump nor its content pin changes:

| Dump | Unchanged SHA-256 |
|---|---|
| Normal `libc.core` | `d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a` |
| `libc_inner_arg_temps.core` | `564da8b27b56fb56e70ebc1a71a2c686beb0c63be01ed5f5216b2bd4867a2240` |

The quoted literals also contain parsed std definitions and their source
positions, so their pins necessarily change with the approved runtime
edit. Both old hashes were reproduced exactly by quoting with the old
std text while keeping the new driver, metadata and unchanged dump.
The temporary staged-file substitutions were restored to their original
symlink targets and verified byte-identical afterward.

An analysis-only comparison accounted for the six-line std position
shift and resolved quotation auxiliary references by content. After
accounting for the changed `loaded_ivfromfloat` body, the remaining
literal source matched in both modes. Auxiliary counts remain 13,324
(Normal) and 12,010 (inner); numbering and factoring change. No
normalization was added to production output, pins or test comparisons.

| Quotation | Before SHA-256 | After SHA-256 |
|---|---|---|
| Normal | `992646e25801b13b66ea9bfa915dda1f788a72a19b5951904d36f88a9a83b279` | `c165410918073f7c01762238e12ff4ec6d527141ec06bc81c7c5508d41fd4873` |
| inner_arg_temps | `ab7cb26e7e38987d871e956d1db05d66f06f58311ca0b776407c81eb47d4bee0` | `920c9638e4fb6d78744b740795eff25ea715814d6f1ca3dfa4c4b6a8432429b3` |

## Reproduction and validation

Use the repository's documented local opam switch and runtime staging.
Regenerate both engines, then build in order from the repository root:

```sh
CERB_MEM_MAX=32G ./scripts/capped opam exec --switch=. -- make prelude-src lean-prelude-src
CERB_MEM_MAX=32G DUNE_CACHE=disabled ./scripts/capped opam exec --switch=. -- dune build --root . backend/driver/main.exe cerberus-lib.install
CERB_MEM_MAX=32G ./scripts/capped opam exec --switch=. -- dune install --root . --prefix "$PWD/_build/local-install" cerberus-lib
CERB_MEM_MAX=32G ./scripts/capped opam exec --switch=. -- dune build --root . cerberus.install
(cd lean_frontend && CERB_MEM_MAX=32G ../scripts/capped lake build CerberusLean cerberus-lean core-quote-test)
```

For each witness, export parse-only Cabs JSON with the oracle's
`--runtime=_build/install/default --nolibc --cabs-json FILE.c`.
Obtain the shared metadata paths with `scripts/libc_prep.sh --jsons`.
Run the oracle with `--runtime=_build/install/default --exec --batch FILE.c`
and Lean with `--batch --first --runtime=_build/install/default --libc DUMP`,
the twelve metadata JSON paths, then the witness JSON. Add
`--switches=inner_arg_temps` to both execution commands and select the
inner dump for the switched pair. Use `scripts/capped` with a 4G cap and
a 30-second timeout for each engine; set `LEAN_ABORT_ON_PANIC=1`.
Compare the complete verdict and decoded stdout with the upstream
`.expected` file, not just process exit status.

The initial `SKIP_BUILD=1` CI invocation correctly refused stale freshness
stamps after the manual build. Recording both freshly rebuilt binaries
with `tools/check_driver_fresh.sh --record-oracle` / `--record-lean`
allowed the measured invocation above; no override was used.

Build, fork-drift (88 source files / 31 generated deltas), and both libc
dump checks pass. Existing generated-code warnings remain visible and
tracked by the Lem-backend follow-up in `TODO.md`; this backport adds no
suppression or resource-limit increase. No proof module changes.

The quotation gate passes in both modes, including standalone and linked
whole-file comparisons, exact pins, alias-path byte determinism,
wrong-cwd refusal, constructor/refusal censuses and four kernel replays.
Verbatim conclusion:

```text
Total: 2 passed, 0 failed
```

All four elaborations and all four `lake env leanchecker` replays exit 0:

| Mode / literal | Elaboration seconds / peak KB | Kernel replay seconds / peak KB |
|---|---|---|
| Normal / standalone | 128.73 / 14879740 | 1.82 / 825648 |
| Normal / linked | 132.24 / 14888668 | 1.83 / 825136 |
| inner / standalone | 132.27 / 14264896 | 1.79 / 824516 |
| inner / linked | 128.54 / 14269532 | 1.85 / 824868 |

These are measured costs, not limits. Validation commands:

```sh
DUNE_CACHE=disabled CERB_MEM_MAX=32G ./scripts/capped ./scripts/test_unit.sh --core-quote-libc
DUNE_CACHE=disabled CERB_MEM_MAX=32G python3 scripts/release.py --mode fast
```

The complete Tier A run passed, exit 0, from 06:04:45 to 06:28:06 UTC.
The source tree remained frozen throughout, with no artifact issues.
Verbatim runner conclusion:

```text
PASSED A14.2 (165.0s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

A1 passed all 20 test executables and the trust checks. Its source census
found zero `sorry` tokens in 346 files; fork-drift accounted for all 88
source files and 31 generated deltas. Lem-sync verified both generated
engines. A1 took 743.4 seconds; PNVI selftest and lane took 108.7 and
165.0 seconds respectively.

Existing lane results match I2, with no existing baseline movement:

| Lane | Result |
|---|---|
| Normal minimal | 113: 90 MATCH, 18 UB_MATCH, 5 CERB_SKIP |
| Coverage | 279: 224 MATCH, 37 UB_MATCH, 16 CERB_SKIP, 2 declared UNSUPPORTED |
| Debug | 90: 66 MATCH, 20 UB_MATCH, 4 CERB_SKIP |
| Floating | 93 MATCH |
| Libc execution | 42 MATCH |
| Multi-TU | 8 full-token matches; 7 failure-class matches |
| CN coverage | 213: 207 MATCH, 6 UB_MATCH; exact baseline match |
| PNVI | 164: 152 AGREE, 3 AGREE-FIRST, 2 BOTH_FAIL, 7 REFUSAL; exact baseline classes and hashes |

The minimal, coverage, debug and float baseline checks each report zero
regressions and zero improvements. A9 retains 108 SAME and the same five
known DIFF rows: 073, 074, 098, 112 and 113. These known differences are
not new agreement claims. The parser, Core parser, byte, libxml2 URI,
address-space and memory-access checks also pass.

The full close-out battery remains part of the unfinished slice, after
the recursive-main ruling and remaining I3/I4 work. Nothing is pushed or
filed externally by this checkpoint.
