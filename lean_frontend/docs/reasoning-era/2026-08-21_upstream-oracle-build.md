# Upstream oracle build probe — deps/cerberus-upstream @ b9aeedcb4

Date: 2026-08-21. Worker: build-probe (offline sandbox).
Mission: does the un-forked upstream cerberus at the fork's merge-base
build OFFLINE with the existing project toolchain, and does it produce a
working oracle for the three-way differential (Lean vs fork-oracle vs
upstream-oracle)?

**OUTCOME: BUILDS OFFLINE, ORACLE WORKS.** No new opam packages, no
network, no global state, no source edits (git status shows only
untracked `ocaml_frontend/generated/`, `sibylfs/generated/`, `_build/`,
lem.log files — all build artifacts). The fork's shared switch and the
fork's opam-pinned lem (`Lem 237867b`, the arc-8 lem-lean head) generate
and compile upstream's .lem cleanly — the forked lem's OCaml backend is
compatible with the merge-base sources (lem.log: warnings only, 242
lines, non-exhaustive-pattern class; sibylfs lem.log empty).

## Recipe (verified end-to-end)

```bash
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
cd /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream
SW=/home/dev/projects/cerberus-lean-proj/cerberus-lean   # shared switch, path form
opam exec --switch=$SW -- make prelude-src               # lem -> OCaml + sibylfs (clean)
opam exec --switch=$SW -- dune build backend/driver/main.exe   # driver builds (menhir warnings only)
opam exec --switch=$SW -- dune build cerberus.install    # REQUIRED for libc runs: builds libc.co
```

- Binary: `deps/cerberus-upstream/_build/default/backend/driver/main.exe`;
  `--version` → verbatim `git-cn-pin-18-gb9aeedcb4`.
- Runtime: `--runtime=$PWD/_build/install/default` (populated by the
  `*.install` targets). **Gotcha:** `dune build cerberus-lib.install`
  alone installs libcore but NOT `libc.co` — non-`--nolibc` runs then die
  with `Failure("file libc.co not found")` (main.ml:76). `libc.co` is
  built by `runtime/libc/dune` (runs the freshly built cerberus on the
  libc sources) and installed by the `cerberus` package →
  `_build/install/default/lib/cerberus/runtime/libc/libc.co`. So build
  `cerberus.install`, not just the lib.
- Runtime invocation needs NO opam env: direct
  `main.exe --runtime=... --nolibc --exec --batch --mode=exhaustive f.c`
  works from a clean shell (verified: sa_csmith_168 → Specified(28)).
  `opam exec` is only needed at build time (dune/lem/menhir on PATH).
- dune version constraint fine: switch has dune 3.23.1, upstream
  dune-project is `(lang dune 3.21)` + `(using coq 0.8)` (identical file
  to the fork's; coq 0.8 would break on dune ≥3.24 — same caveat as the
  prototype).
- Harness-parity flags (fork's scripts/test_exec.sh):
  `--nolibc --exec --batch --mode=exhaustive`. csmith corpus files use
  the corpus-lane substitution (test_csmith_corpus.sh:54):
  `#include "csmith.h"` → `#define CSMITH_MINIMAL` +
  `#include "csmith_cerberus.h"`, with
  `tests/csmith/{csmith_cerberus.h,safe_math.h}` copied next to the file.
  (Running sa_ files RAW with `-DCSMITH_MINIMAL -I tests/csmith/runtime`
  against full csmith.h gives a different program — checksum machinery,
  different exit value — do not mix the two modes when comparing against
  the arc-10 baselines.)
- Scratch/smoke artifacts live in `deps/cerberus-upstream/_build/smoke/`
  (copied witnesses + morphs + a native gcc binary; safe to delete).

## Smoke: tests/minimal (libc mode, exit=0 all three)

```
== 001-return-literal ==
Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
== 006-arith-div ==
Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
== 008-local-var-arith ==
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```
(each followed by a `Time spent: ...` line — strip it when diffing.)

## F-D independent confirmation (arc-10 S4 "upstream is correct" claims)

The S4 root-cause spot-checks were run against the PROTOTYPE's upstream
checkout @ 866be5254. This probe re-ran them on a SECOND, independent
upstream build (b9aeedcb4 = the fork merge-base, built here). All three
claimed values reproduce verbatim; fork spurious verdicts reproduce on
the arc/robustness fork oracle side-by-side. Invocation for all rows:
`--runtime=<tree>/_build/install/default --nolibc --exec --batch
--mode=exhaustive` unless noted.

**csmith_6000098.c** (+ morph = `int __extra_decl(int);` prepended):
```
UPSTREAM base : Defined {value: "Specified(117)", stdout: "", stderr: "", blocked: "false"}
UPSTREAM morph: Defined {value: "Specified(117)", stdout: "", stderr: "", blocked: "false"}
FORK base     : Defined {value: "Specified(187)", stdout: "", stderr: "", blocked: "false"}
FORK morph    : Defined {value: "Specified(138)", stdout: "", stderr: "", blocked: "false"}
```
→ CONFIRMED: upstream = 117 (gcc/Lean value), declaration-morph-stable;
the fork's silent value corruption (187→138) is fork-only.
(Both sides also print 2× the known
`(debug 0): constructValue_aux: is WRONG for union ...` stderr notice.)

**csmith_6000018.c** (headers beside file; no -D — the file self-defines
CSMITH_MINIMAL, adding `-DCSMITH_MINIMAL` on the command line is a
`-Werror` redefinition error on BOTH sides):
```
UPSTREAM: Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}
FORK    : Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<515:10--515:15>"}
```
→ CONFIRMED: upstream = 100 (gcc/Lean), fork UB is spurious.

**sa_csmith_168.c** (corpus-lane substitution applied to
tests/csmith/small_arrays/csmith_168.c):
```
UPSTREAM: Defined {value: "Specified(28)", stdout: "", stderr: "", blocked: "false"}
FORK    : Undefined {ub: "UB010_pointer_to_dead_object", stderr: "", loc: "<752:35--752:51>"}
```
→ CONFIRMED: upstream = 28, fork UB010 spurious.

**ub010_dead_object_reduced.c** (+ two morph placements):
```
FORK base           : Undefined {ub: "UB010_pointer_to_dead_object", stderr: "", loc: "<235:15--235:16>"}  (0.05s)
FORK morph (prepend): Undefined {ub: "UB010_pointer_to_dead_object", stderr: "", loc: "<236:15--236:16>"}
FORK morph (after #include): same UB010 at <236:15--236:16>
UPSTREAM base : exit=124 (timeout) at 120s exhaustive AND 300s default mode
UPSTREAM morph: exit=124 (timeout)
native gcc -O1: non-terminating print loop (2.5GB of "0" lines in 30s;
                still running at 60s with output discarded)
```
→ CONFIRMED in the sense that matters: upstream does NOT report UB010 on
the live object; its non-termination matches native behavior, so the
fork's 0.05s UB verdict is the anomaly. CAVEATS: (a) this witness cannot
yield an upstream/native defined VALUE — it is (observationally)
non-terminating, so it's a fork-vs-upstream discriminator only, not a
three-way value witness; (b) the manifest's morph fingerprint for THIS
file ("+1 unused decl → internal error: can_advance: Step_error2") did
NOT reproduce with either `int __extra_decl(int);` placement (fork stays
UB010) — the fingerprint presumably needs the specific decl/placement
used during reduction; not chased (not this probe's mission), flag for
the F-D register.

## Bottom line for the three-way instrument

Upstream oracle at the exact merge-base is now buildable and runnable
offline in-tree, using only the existing shared switch + forked lem.
Fork-vs-upstream F-D discrimination is reproduced locally on a second
upstream version (866be5254 prototype-checkout AND b9aeedcb4 merge-base
agree on 117/100/28), strengthening the S4 reattribution: F-D is a fork
regression, not drift in one upstream snapshot.

Sandbox note: /tmp is write-only under the nono profile (reads denied);
scratch for smoke runs must live inside the allowed tree (used
`_build/smoke/`).
