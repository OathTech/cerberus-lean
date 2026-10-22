# Park: inner_arg_temps libc text loses symbol identity

2026-10-21, branch `feature/inner-arg-temps`, after I0b `08fb2d156`.
**Dispositioned, 2026-10-22:** the [transport repair](2026-10-22_inner-arg-temps-transport-record.md)
resumes I3 with a printer fix and two collision checks; the blanket
containment remains until the acceptance tests pass. The original park
diagnosis follows. The earlier recursive-main
park is resolved. This is a distinct false premise in the I2 libc transport.
The [slice record](2026-10-21_inner-arg-temps-record.md#second-park--libc-symbol-loss)
records the decision and provenance. No discrepancy baseline is adopted.

## Finding and why the earlier checks missed it

`ocaml_frontend/pprinters/pp_symbol.ml:12-24` omits numeric identities at
ordinary debug levels and prints `SD_Id`, `SD_ObjectAddress` and
`SD_FunArgValue` with the same name. The inner elaboration creates distinct
value symbols for parameter objects (`translation.lem:4366-4373`), with
names inherited from those objects. The variant dump therefore contains:

```text
proc exit (code: loaded integer): eff unit :=
  let strong code: pointer = create(Ivalignof('signed int'), 'signed int') in
  store('signed int', code, code) ;
```

This is `tests/libc/libc_inner_arg_temps.core:67790-67792`. The original
value parameter and object address are distinct symbols in the oracle's
binary library. `CoreParser.lean:245-252` interns both printed occurrences
by name; the parsed store sees the address in both positions. Metadata
stitching does not recover the lost identity. The source has already been
misrepresented before quotation starts.

I2 checked dump hashes, parameter types, quotation equality with the parsed
library, and replay of the resulting Lean literal. Those checks passed,
but never compared the parsed library with the original `.co` library.
A faithful quotation of the corrupted parse does not establish transport
correctness. I2's earlier green result must not be cited as that evidence.

The oracle continues to use its binary library and produces the expected
results. This is a fork text-import failure, not evidence of an upstream
execution defect. The printer's lossy behavior is reported separately in
[tray 65](upstream-tray/65-inner-arg-temps-core-symbol-loss.md), with its
machine-consumption qualification.

## Failed provisional I3 sweep

The pre-containment development tree, based on `08fb2d156`, ran 186 rows:
113 minimal, 10 fixtures, 16 frontend corpus, 42 libc execution cases,
three main witnesses and the two upstream backport witnesses. Both engines
used `inner_arg_temps`; libc rows used their matched binary/text variants.
Ordinary inputs were exhaustive; libc top-level inputs used single traces,
and the two libc/exhaustive inputs used exhaustive execution. Each engine
was capped at 4G, with 30-second ordinary and 300-second libc timeouts.

The first full run exited 1 with 38 failed rows. Two were an instrument
error: the upstream `.expected` files contain a complete batch verdict,
where the first instrument compared only stdout. After fixing that
comparison, a focused rerun of 0343 and 0344 passed against the complete
expected verdict. No second full sweep was run. The resulting classification
below combines that focused correction with the full run; it is not a
verbatim second-run summary:

| Classification | Rows | Meaning |
|---|---:|---|
| AGREE | 136 | Equal complete exhaustive observations |
| AGREE-FIRST | 7 | Equal single traces, including the two corrected upstream checks |
| BOTH_FAIL | 5 | Minimal 073, 074, 097, 112, 113; not agreement |
| RESOURCE | 2 | Corpus p07_list_sum and p08_list_reverse; both engines killed at 4G, not agreement |
| DIFF | 36 | 32 Lean crashes versus completed oracle observations; four unequal complete observations |

Examples (all under the switch with their matched libc variants):

| Input in tests/libc_exec | Oracle | Lean before containment |
|---|---|---|
| `001-exit.c` | Defined 42 | Exit 134, store of a pointer where signed int was required |
| `005-strlen.c` | Defined 15 | Defined 16 |
| `013-strcpy-strcat.c` | Defined 24, stdout `abcdefghi\|xy\|0123\|368\|9\n` | `UB035_unsequenced_race` |
| `032-strdup.c` | Defined 12, stdout `copy Copy 1\n` | Defined 14, stdout `copy C\237\255\255\255\255 1\n` |
| `038-realloc-libc-mode.c` | Defined 6, stdout `abcde\n` | `UB035_unsequenced_race` |

The four complete-observation differences are the four non-crash examples
above. This is wrong behavior, not a registered limitation that the new
lane may baseline. No claim is made that every failing body has been
individually traced; the symbol-loss diagnosis directly explains the exit
failure and invalidates the transport across the variant library.

## Containment and focused validation

The Lean CLI now refuses any `inner_arg_temps` invocation with `--libc`,
before reading the library, with exit 2 and
`R-IAT-LIBC-SYMBOL-LOSS`. This includes standalone `--quote-libc` and
linked `--quote-core`. It covers custom dumps too: no lossless alternative
has been validated. It does not change the model or the oracle's behavior.
The existing `--call` refusal retains precedence.

The capped build passed (289 jobs). Main introduced no compiler warnings;
the build replayed existing generated/dependency warnings already recorded
in the earlier checkpoints. Six focused checks passed: execution and both
quotation forms, each with the variant and Normal dump under the switch.
Each produced exit 2, the named diagnostic, empty stdout and no quotation
file. An initial ad-hoc check misplaced `--batch` and hit the existing
canonical-position refusal; it is not containment evidence. The corrected
six-check run used canonical argument order.

Normal libc controls still return 42 (`001-exit`) and 15 (`005-strlen`).
The three main witnesses without imported libc pass on both engines in both
modes after containment: main-args 0, recursive-main 7, recursive-main-args
42. Their complete observations have empty stdout/stderr and blocked false;
all engine processes exit 0. GCC 13.3.0, `-std=c11 -Wall -Wextra -O0`,
exits 7 and 42 for the recursive witnesses, with `ab cd` for the latter.
No recursive-main refusal is added.

## Reproduction

From the repository root after the documented build and runtime staging:

```sh
mkdir -p .tmp/iat-libc-repro
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --nolibc --cabs-json \
  tests/libc_exec/005-strlen.c > .tmp/iat-libc-repro/strlen.json
scripts/libc_prep.sh --jsons .tmp/iat-libc-repro/metadata \
  > .tmp/iat-libc-repro/metadata.paths
```

With Bash, build the metadata arguments and compare:

```bash
metadata_args=()
while IFS= read -r path; do metadata_args+=(--libc-tu "$path"); done \
  < .tmp/iat-libc-repro/metadata.paths
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --exec --batch --switches=inner_arg_temps \
  tests/libc_exec/005-strlen.c
CERB_MEM_MAX=4G LEAN_ABORT_ON_PANIC=1 ./scripts/capped \
  lean_frontend/.lake/build/bin/cerberus-lean --batch --first \
  --runtime=_build/install/default --switches=inner_arg_temps \
  --libc tests/libc/libc_inner_arg_temps.core "${metadata_args[@]}" \
  .tmp/iat-libc-repro/strlen.json
```

The oracle returns 15. On I0b `08fb2d156` before containment the Lean command
returns 16; on the parked candidate it refuses with exit 2. For the quotation
checks, replace `--batch --first` by `--quote-core .tmp/iat-libc-repro/linked.lean`,
or by `--quote-libc .tmp/iat-libc-repro/library.lean` and omit the input JSON.
Both now refuse before creating files. For a Normal execution control remove
the switch and use `tests/libc/libc.core`; the result is 15.

The provisional sweep command is `SKIP_BUILD=1 CERB_MEM_MAX=32G
scripts/test_inner_arg_temps.sh --observe`. Before containment it exposed
the discrepancies above; now it fails on its positive libc expectations.
Do not change those expectations into a success baseline for the refusal.

## Gate and remaining work

Tier A containment validation passed, exit 0, with the complete existing
19-command selection. The launch waited for one-minute load below 6
(5.92 at 22:40 UTC). Command:

```sh
DUNE_CACHE=disabled CERB_MEM_MAX=32G ./scripts/capped python3 scripts/release.py \
  --mode fast --out .tmp/inner-arg-temps-i3/park-tier-a
```

Verbatim runner conclusion:

```text
PASSED A14.2 (170.0s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The four exec baselines report zero regressions and zero improvements;
Normal libc is 42 MATCH, multi-TU is 8 and 7 MATCH, and CN retains 213 exact
baseline entries (207 MATCH, 6 UB_MATCH). A9 still reports 108 SAME and
its five recorded DIFF rows. PNVI retains all 164 rows and hashes:
152 AGREE, 3 AGREE-FIRST, 2 BOTH_FAIL and 7 REFUSAL. No existing baseline
moved. This validates containment against the existing tier, not I3
completion. No proof module changed, so the charter does not require
additional kernel replay for this guard. Only this gate-result text was
added after the unchanged-candidate run, along with documentation wording
clarifying the distinction between the two parks.

No new baseline, LADDER/VALIDATION/release row, or completed I3 checkpoint
exists. The provisional lane code is retained for review/resumption; its
`--selftest` and Csmith paths are drafted but have not been run or validated.
The dump/mode mismatch plants passed before containment; the broader safety
refusal now stops the switched branch before that shape check. The existing
variant B13 quotation success requirement is blocked by design, so the full
battery cannot certify this candidate. No pins or expectations were changed
to conceal that failure. The 43 existing commands plus the planned new row
have not been run as a close-out battery.

I4, its translation-comment report, and the fuzz campaign remain outstanding.
I1b remains deferred. Further branch work requires an explicit disposition
of this park and a decision about a lossless library transport. Raw captures
are ephemeral; this record preserves conclusions and reproduction commands.
