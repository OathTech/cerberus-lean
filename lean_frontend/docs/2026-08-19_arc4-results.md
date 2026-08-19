# Arc 4 results: first differential execution

Companion to the charter (`2026-08-19_arc4-exec-pipeline-charter.md`),
decision log D1–D12, frontier doc (`2026-08-19_arc4-s0-frontier.md`),
seam survey / defect register (`2026-08-19_arc4-seam-survey.md`),
corpus scoreboard (`2026-08-19_arc4-s4b-corpus-scoreboard.md`), and kit
disposition (`2026-08-19_arc4-prototype-kit-disposition.md`).

## Headline

C programs execute end-to-end through the Lean pipeline and match OCaml
cerberus: **103/106 on tests/minimal** (85 value-match + 18 UB-match,
ZERO mismatches/fails/crashes/timeouts; the 3 non-matches are OCaml-side:
one upstream TODO-crash, two prototype skip-on-Error semantics where both
sides in fact agree). Charter bar was ≥95: exceeded; every non-match
classified. The differential harness (`test_exec.sh`, ported from the
prototype) passes in DEFAULT mode — zero open mismatches — and gates
regressions via a committed baseline.

## Arc trajectory (per-slice, all worker-committed, all
orchestrator-verified)

| slice | result |
|---|---|
| S0 | "silent" rc=1 root-caused (stderr-lost sorry panic in generated BEq core_step2); 105-file frontier map |
| S1a | BEq fix (priority-override instances, OCaml poly-eq parity) → first Active result ever; 0→62 executing |
| S2 | harness ported + Main --batch + first baseline: 73/105 |
| S3a | symbol-id-stream collision (one-line C fix, OCaml invariant mirrored): 91/105, crash class emptied |
| S3b | struct/union concrete memory model (impl_mem.ml port) + ND-order fix + 2 effect-erasure DCE bugs: 97/105 |
| S3c | seam cheap-batch (float parsing/truncation, ptr-diff UB, div/rem semantics, NoProvPtr, decode): 102/105 |
| S4/S4b | signature-level elab differential (102/105 SAME); coverage corpus 95.7%, debug 97.6%, csmith smoke 3/3 |
| S1r | easy_update un-sorried (fuel declare); driver2 sorryAx-free GATED; arc-2 obligations landed (+1 test → 103/106) |

## Success conditions

1. ≥95/105 matching: **103/106** ✓ (all non-matches classified).
2. driver2 cone sorryAx-free, gate-enforced ✓; zero sorry target_reps on
   the execution path ✓ (concurrency stubs remain the declared boundary).
3. Standing gates green at every commit ✓ (356/356 build, unit 4/4,
   purity/cones/totality enforcing, parse ALL, core 105/106 with the
   known 078 Core-text red — whose EXECUTION differential now matches).
4. Model edits declares-only ✓ (audit-verified per batch); ZERO lem
   backend changes this arc — pins untouched at `574e326`, no pin dance
   needed.
5. Prototype kit: harness ported with preserved comparison semantics;
   full port/skip/defer disposition recorded; coverage + debug baselines
   committed (reporting-mode scoreboards); csmith kit ported, smoke run
   clean (oracle yield 12% is the recorded scale bottleneck).

## Defect register (mirror-OCaml doctrine, D8)

30 survey findings: **12 FIXED** (5, 6, 7, 10, 12, 18a, 20, 22, 26, 28 +
findings 1–4/17 as the S3b batch), **1 documented-deliberate** (18b enum
registry stub — now known to be a UB-soundness miss via debug/compat-04),
**~17 OPEN** with corpus cross-references. Two register-pattern additions
from this arc: effect-erasure (three instances: runEffectful, set_tagDefs,
with_tagDefs — every effectful seam must be armored or natively
sequenced) and description-sensitive symbol equality.

## Next-arc pricing (data-backed by the scoreboard)

1. libc/builtin procedure linking — 20 coverage FAILs, the single
   largest parity item.
2. Varargs (register 15) + enum registry (18b).
3. Real Core/ctype pretty-printer — unlocks body-level elab differential
   and fixes the Unspecified(<ctype>) textual class.
4. Register burn-down (~17 open defects; readonly allocations, memcpy
   checks, byte-provenance policy, constraint pruning...).
5. csmith at scale (bottleneck is upstream cerberus strictness on csmith
   output, not our side); creduce needs a networked window.
6. flexible_array_member sorryAx residue (import-leaf limitation —
   C-tier lem-backend item).
