# Generated Core/CoreB baseline campaign

This is bounded differential testing of the duplicated execution path. It is
not a proof of CoreB equivalence, a claim about all C, or an exhaustive search
of the generated programs' schedules. Build the two entrypoints as described
in [the interpreter/runner notes](interpreter-runner.md).

From the repository root:

```sh
python3 -m unittest discover -s tests/coreb -p 'test_*.py'
python3 scripts/coreb_campaign.py --smoke
python3 scripts/coreb_campaign.py --pilot
python3 scripts/coreb_campaign.py --manifest tests/coreb/campaign.json
```

Use the optional box memory wrapper around these commands where available.
The runner also bounds each owned child by virtual memory, wall time and
combined stdout/stderr, and bounds the whole campaign by wall time. Runs are
sequential. `--producer`, `--runtime`, `--core-bin` and `--coreb-bin` select
explicit local builds; the ordinary defaults are the repository build paths.
No host-specific location is embedded in the implementation.

## Input and path sampling

`scripts/coreb_generate.py` has four templates: array folding, pointer walking,
global helpers and nested call expressions. Its unsigned-expression grammar
uses initialized unsigned operands with addition, multiplication and bitwise
operators. Arrays have 2–5 elements, loops execute a positive fixed bound,
pointer accesses stay within those arrays, and the result is reduced to
0–250 before conversion to signed `int`. Two helper calls change separate
global objects. Their unsequenced evaluation supplies genuine competing Core
choices; a run without observed choices cannot meet the ND denominator.

The six named feature families execute in every template. In a completed
defined run, main has executed its helpers, positive-bound loop, loop-body
conditional, array accesses and final pointer update. Counts require observed
loads, stores, memory receipts and two helper returns as well. This combines
feature-directed construction with actual execution evidence; it does not
infer arbitrary C feature coverage from source keywords. It is not a proof
that the generator is UB-free: unexpected UB and model errors are classified.

Input parameters come from SHA-256 of generator version, seed, index and a
counter. Seeds are `1701`, `2718`, `31415`, `65537`; input ordinal `n` chooses
seed `n % 4` and index `n // 4`. Input diversity is checked after removing the
seed/index comment. The smoke covers all four templates with 16 programs;
the pilot uses 100. The campaign manifest fixes the generator hash, resources
and completion targets after that pilot.

Each input first records the all-zero path. The second path selects index 1
at its first actual multi-successor choice, then defaults to zero. Optional
third/fourth samples change the next actual positions of the first tape. No
path is counted just because a different random seed was requested. Each
sample executes four fresh processes: Core record → CoreB replay, CoreB record
→ Core replay, plus comparison of the two independent recordings. Ordered
events, choices, terminal outcome and completion counts must all match; only
header origin is erased.

The report counts distinct tapes separately for each input (the sum is
`distinct_input_tape_pairs`), selected alternative indices, actual choice
kinds and observed effect tags. Both directions are required for every counted
path. A completed defined input contributes once to its feature denominators;
the ND target separately requires two distinct completed defined tapes for
that input. UB, matched model errors, incomplete runs, refusal and mismatch
never contribute a defined path. Matched model errors fail acceptance. Any
comparison failure, unattempted input or missing frozen target fails acceptance.

## Inspecting and reproducing a case

```sh
python3 scripts/coreb_generate.py --seed 1701 --index 0 > .tmp/generated.c
python3 scripts/coreb-diff.py .tmp/generated.c --choices 1 --summary-json
```

The compact JSON summary includes selected indices/arities, actual tape and
outcome hashes, and observed effect counts. The ordinary command gives a short
human-readable status. A campaign failure names its seed, index, choice prefix
and diagnostic. Matched unexpected UB/model errors retain those same compact
reproduction coordinates and the outcome hash in `nondefined_cases`; failures
also have typed categories (frontend, refusal, resource, instrumentation or
other incomplete) and per-category counts. Reconstruct that source and run the same prefix with the
recorded build pair and manifest limits. Minimization is currently manual:
reduce the source, generate a fresh valid tape, and retain the reduction only
if the actual mismatch persists. A tape invalidated by source reduction is not
a semantic counterexample. No automatic shrinking claim is made.

Generated C, Cabs JSON, tapes and raw traces live only in temporary directories
and are removed after each comparison. Binary hashes are computed once per
campaign; file identity, timestamps and sizes are checked around every run to
reject a concurrent rebuild. This is a local drift check, not protection from
an adversarial file replacement. Commit small reproductions and conclusions,
not raw campaign dumps.

## Pilot and frozen acceptance

The 2026-11-14 pilot completed 100 distinct programs and 200 defined path
comparisons, each in both recording directions, in 58.544 seconds. All six
features had 100 completed inputs; all 100 inputs completed two distinct tapes.
There were 1,300 actual branch decisions (1,200 index 0 and 100 index 1), no
mismatches, no incomplete runs, no UB and no model errors. Template counts were
28 array-fold and 24 each of the other three templates. The command was the
`--pilot` invocation above with explicit local producer/runtime/binary paths.

The tested executable SHA-256 pair was
`123096e18fb5f7f06e0d47d78f7b90f6efc57727511549a45e81dc43b883431c`
(Core) and
`bc5742f213a28d18697b7452c8fa87915e92b888aade0c0f012b549697e8aa00`
(CoreB). Native hashes are build-instance identities, not portable release IDs.

The frozen [manifest](../../../tests/coreb/campaign.json) retains the scoped
targets: 1,000 completed defined programs, at least 50 per feature, and at least
100 generated inputs with two distinct defined tapes. It requests two samples
per input with a 20-minute campaign bound, 15 seconds per child, 4 GiB virtual
memory per child, 16 MiB combined child output and fuel 1,000,000. Freezing the
manifest after the successful pilot does not itself claim the full campaign
has passed.

The full frozen campaign then passed on the same executable pair in 659.017
seconds: 1,000 distinct defined programs, 2,000 distinct input/tape pairs and
8,000 fresh interpreter processes across both recording directions. Each
feature reached 1,000 defined inputs, and all 1,000 inputs completed two distinct
defined tapes. It observed 13,000 branch decisions (12,000 index 0, 1,000 index
1), 119,912 driver loads, 59,184 driver stores, 181,096 memory access receipts
and 4,000 helper returns. Template counts were 252 each for array-fold and
pointer-walk, 248 each for global-calls and call-tree. There were zero mismatches,
incomplete runs, UB outcomes, model errors or unattempted inputs.

The campaign loaded harness tree `f2afeae5940141c44a8e8e365ee2de552402519d`
with canonical manifest hash
`a22c44f428ae9f74b1f25deac2765a98a34a8ee5c0223b459420cc78038d605b`.
Subsequent reviewed changes retain compact nondefined reproduction recipes and
typed failure categories; they do not alter these successful comparisons or
their denominator. Eighteen focused Python checks passed after those diagnostic
changes. Raw campaign reports and traces are reconstructible and are not kept.
