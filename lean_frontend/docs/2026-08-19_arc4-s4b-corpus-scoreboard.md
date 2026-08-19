# Arc 4 / S4+S4b — elab differential, corpus scoreboard, csmith smoke

Date: 2026-08-19. Slices S4 (stage differential minimum) and S4b (corpus
expansion) of the exec-pipeline arc (charter:
`2026-08-19_arc4-exec-pipeline-charter.md`; kit dispositions:
`2026-08-19_arc4-prototype-kit-disposition.md`). Post-S3c substrate:
tests/minimal at 102/105, zero Lean-side fixables open.

Everything here is REPORTING mode — none of these numbers gate this arc.
The two committed baselines (`scripts/exec_coverage_baseline.txt`,
`scripts/exec_debug_baseline.txt`) are the obj-2 parity scoreboard; the
per-failure classification below (cross-referenced against the
seam-survey defect register, `2026-08-19_arc4-seam-survey.md`) is what
prices the next arc. All defects RECORDED, none fixed in this slice
(harness/corpus/docs-only latitude).

## S4 — `scripts/test_elab.sh`: elaborated-Core differential (reporting)

Granularity achieved: **signature-level** — declaration names, kinds
(fun/proc/procdecl/builtin/glob/tagdef), arities, aggregate member names.
OCaml side: `cerberus --nolibc --pp core` →
`scripts/extract_core_sig.py`; Lean side: new `cerberus-lean --pp-core`
mode (Main.lean `ppCoreSignature`, symbol naming mirrors
`Pp_symbol.to_string_pretty`); both sides through
`scripts/canonicalize_ids.py`, sorted, diffed.

**LIMITATION (prominent, deliberate): bodies are NOT compared.** The
Lean pipeline has no real Core pretty-printer (CerbPP.lean is
placeholders, generated Pp.lean a stub) and building one was explicitly
out of scope (charter S4). Body-level elaborated-Core differential =
recorded next-arc item, contingent on a Lean Core PP.

Result on tests/minimal: **102/105 SAME, 3 DIFF, 0 fails** — and all
3 DIFFs are one explained visibility class, not semantic divergence:
OCaml's pp only prints declarations located in the main file
(`pp_core.ml` `pp_cond`), while the Lean dump prints everything it
translated. 073/074 (.libc) show stdlib.h's 43 procdecls Lean-side only;
098 shows stddef.h's `max_align_t` unnamed struct. (The Lean pipeline's
injected GCC-builtin procdecls are filtered by the harness for the same
reason — documented in test_elab.sh's header.) Corollary: corpora that
define functions in headers (csmith) will DIFF wholesale at this stage;
test_elab.sh is a tests/minimal-class tool until body-level PP exists.

## S4b — tests/coverage corpus (199 files, 21 categories, ported verbatim)

Copied verbatim from `cerberus-lean-prototype/tests/coverage` (verified
`diff -r` clean; 199 .c files, no exclusions needed — every file runs
under the harness without harming it; the 5 io printf tests carry their
`.unsupported.c` suffix from the prototype and are counted as expected
failures). Runner: `./scripts/test_exec.sh tests/coverage`;
baseline: `scripts/exec_coverage_baseline.txt` (status per file +
per-category summary in header comments).

```
SUMMARY: total=199 match=148 ub_match=7 ub_diff=0 mismatch=7 fail=20 crash=0 timeout=0 cerb_skip=13
```

Headline: **155/182 comparable matching (85%)** counting FAILs against
us; **155/162 (95.7%)** of both-sides-executed comparisons; **0 crashes,
0 timeouts** — the exec substrate never falls over on a 2× larger corpus.

Per category (n / match+ub_match / of-comparable):

| category | n | matching | comparable | notes |
|---|---:|---:|---:|---|
| arith3 | 6 | 6 | 6 | 100% |
| builtin | 6 | 0 | 5 | **worst** — all FAIL (libc/builtin linking), 1 CERB_SKIP |
| compound | 12 | 12 | 12 | 100% |
| conv | 18 | 18 | 18 | 100% |
| ctrl | 12 | 12 | 12 | 100% |
| ctrl2 | 3 | 2 | 3 | 1 FAIL (errno.libc — linking) |
| ctrl3 | 5 | 3 | 4 | 1 FAIL (malloc.libc — linking), 1 CERB_SKIP |
| eval2 | 15 | 15 | 15 | 100% |
| expr | 12 | 11 | 11 | 1 CERB_SKIP (bitfields, OCaml-side) |
| io | 5 | — | — | 4 UNSUPPORTED (printf, expected), 1 CERB_SKIP |
| libc | 14 | 0 | 11 | **worst** — 11 FAIL (linking), 3 CERB_SKIP |
| mem | 10 | 8 | 9 | 1 MISMATCH (Unspecified pp, below), 1 CERB_SKIP |
| mem3 | 8 | 6 | 8 | 1 DIFF (string-literal write, below), 1 FAIL (linking) |
| misc | 11 | 10 | 10 | 1 CERB_SKIP |
| ptr | 12 | 12 | 12 | 100% |
| ptr2 | 15 | 14 | 15 | 1 FAIL (malloc.libc — linking) |
| ptr3 | 8 | 6 | 6 | 2 CERB_SKIP (lt/le null ptr: OCaml "Memory WIP") |
| store2 | 5 | 5 | 5 | 100% |
| struct | 10 | 10 | 10 | 100% |
| union3 | 7 | 5 | 5 | 2 CERB_SKIP (union copy/return, OCaml-side) |
| varargs | 5 | 0 | 5 | **worst** — all DIFF (varargs stubs) |

Best 3: eleven categories are perfect; the biggest perfect ones are
**conv (18/18), eval2 (15/15), ctrl + compound + ptr (12/12 each)** —
the arithmetic/conversion/control/pointer core is at full parity.
Worst 3: **libc (0/11), varargs (0/5), builtin (0/5)** — all three are
single-cause categories (see classification).

### Coverage failure classification (→ defect register)

| class | files | register cross-ref |
|---|---|---|
| **libc/builtin procedure linking** — Lean links only std.core; OCaml under `--nolibc` still resolves malloc/free/memcpy/memcmp/realloc/errno and `__builtin_{ffs,ctz,bswap*}`; Lean fails `Illformed_program: calling an unknown procedure` | 20 FAIL: builtin-001..005, libc-001/003..010/013/014, ctrl2-003, ctrl3-001, mem3-007, ptr2-009 | S1a frontier finding "libc procs not linked" (073/074 class), now sized: **the single largest parity item, 20 files + 2 in tests/minimal** |
| **varargs stubs** — every va_* program dies `UB019_lvalue_not_an_object` where OCaml returns a value | 5 DIFF: varargs-001..005 | survey finding **15** (open, backlog) |
| **read-only string literals** — write to a string literal returns 0 instead of UB033_modifying_string_literal | 1 DIFF: mem3-004 | survey finding **11** (read-only prefixes, open) |
| **Unspecified batch payload pp** — Lean prints `Unspecified(<ctype>)` (CerbPP placeholder) vs OCaml `Unspecified('signed int')`; same verdict, textual mismatch only | 1 MISMATCH: mem-006 | NEW (harness-level): the documented `batchExitValue` deviation in Main.lean becomes corpus-visible; needs a ctype printer (same next-arc item as body-level PP) |
| **CERB_SKIP (OCaml-side, no oracle)** — bitfields, zero-size array, void-ptr-arith, union copy/return, `lt_ptrval/gt_ptrval` null "Memory WIP", libc procs unknown even to OCaml (exit/calloc/memset/strlen/puts) | 13 | not Lean defects; upstream oracle limits, recorded |

## S4b — tests/debug corpus (90 pre-minimized reproducers, ported verbatim)

Copied verbatim from `cerberus-lean-prototype/tests/debug` (kit
disposition: PORT). Baseline: `scripts/exec_debug_baseline.txt`.

```
SUMMARY: total=90 match=65 ub_match=18 ub_diff=0 mismatch=2 fail=0 crash=0 timeout=0 cerb_skip=5
```

Headline: **83/85 comparable matching (97.6%)**, 0 fails/crashes/
timeouts. The prototype's entire distilled divergence corpus — including
all 16 unseq, 10 intfromptr, 7 float, 8 struct, 9 conv reproducers —
passes except two:

| file | result | register cross-ref |
|---|---|---|
| compat-04-funcptr-enum-int | DIFF: Lean=12, OCaml=UB041_function_not_compatible | survey finding **18b** (enum registry stub): `typeof_enum` normalizes enum → `Signed Int_`, so the call-compat check cannot distinguish `int(int)` from `int(enum color)` and misses the UB |
| varargs-01-ptr-valist | DIFF: Lean=UB019, OCaml=0 | survey finding **15** (varargs stubs) — same class as coverage varargs |

CERB_SKIPs (5): libc-01/02 (.libc memset/strlen — OCaml-side unknown
proc), ub-static-reject (OCaml rejects statically), valid-04 (exit.libc),
plus ub-inconsistent as CERB_INCONSISTENT (OCaml `--exec` succeeds but
`--cabs-json` fails — named "inconsistent" in the prototype for exactly
this; oracle-side quirk, recorded).

## S4b — csmith smoke (N=25)

`scripts/fuzz_csmith.sh` ported (minimal driver → test_exec.sh;
prototype csmith flags kept: `--no-argc --no-bitfields --max-funcs 3
--max-block-depth 3 --max-block-size 4 --max-expr-complexity 3`).
Runtime header: `tests/csmith/csmith_cerberus.h` +
`safe_math.h` ported from the prototype (safe_math verbatim; the shim
has ONE documented adaptation — `platform_main_end` is a macro returning
the checksum from main instead of calling `exit()`, since neither side
of this differential links a C library). Csmith's include is satisfied by
copying the two headers next to the generated files — no sandbox blocker,
NOT a networked-window item.

Smoke run: N=25, deterministic seeds 1001–1025
(`CSMITH_SEED_START=1000`), TIMEOUT_SECS=15.

```
SUMMARY: total=25 match=3 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 timeout=0 cerb_skip=22
```

- **3/25 reach a comparison; 3/3 MATCH** (checksums 18, 255, 255).
  **0 bugs found** — no FAIL/MISMATCH/DIFF/LEAN_CRASH/TIMEOUT.
- **22/25 are ORACLE-side skips**, fully classified, with Lean-side
  parity verified per file:
  - 14× OCaml **internal error** `Translation called on Ail program with
    an invalid node` (translation_effect.ml track_temporary_objects —
    upstream cerberus limitation on csmith's temporary-object shapes).
    The Lean pipeline panics with the IDENTICAL message on all 14 (same
    lem-generated translation) — exact failure parity, not a Lean defect.
  - 8× **strict-C11 constraint violations** in csmith 2.3.0 output
    (6× invalid pointer-comparison operand pairs, 1× incompatible
    pointer assignment, 1× non-constant initializer). These fail
    `--cabs-json` generation itself, so the Lean side never sees them.
- 25/25 generate; 17/25 compile through cabs-json (8 constraint
  violations don't); 3/25 clear the full Lean pipeline (14 stop at the
  shared invalid-node translation limit) — and those 3 match.

Next-arc note (scale fuzzing is charter-NEXT-arc): oracle yield is the
bottleneck (12%), not the Lean pipeline. Yield tuning candidates: more
`--no-*` flags / csmith options that avoid the invalid-node and
pointer-comparison shapes; or oracle-side triage of the upstream
internal error.

## Recorded-not-fixed summary (next-arc pricing)

1. **libc/builtin linking** — 22 files across corpora (20 coverage + 073/
   074 minimal). Single mechanism (link OCaml's `--nolibc`-resident
   builtins/impls into the Lean run). Largest single parity win
   available.
2. **varargs** (finding 15) — 6 files. Second-largest single-cause block.
3. **enum registry** (finding 18b) — 1 file today (compat-04), but it is
   the survey's known stub made corpus-visible; UB041-class soundness gap
   (Lean returns a value where OCaml flags UB).
4. **read-only prefixes** (finding 11) — 1 file (mem3-004), also a
   UB-miss class.
5. **ctype printing for batch Unspecified payloads** + body-level Core
   PP — 1 MISMATCH today (mem-006) + the test_elab body-granularity
   ceiling; one shared work item (a real Core/ctype pretty-printer).
6. Oracle-side records: cerberus invalid-node internal error (csmith),
   strict constraint-violation rejections (csmith), the 13+5 CERB_SKIP
   classes above, ub-inconsistent's exec/cabs-json disagreement.
