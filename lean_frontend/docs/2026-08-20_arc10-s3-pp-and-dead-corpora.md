# Arc-10 S3 + S3b: pp-placeholder text class + dead-corpora wiring

Date: 2026-08-20. Worker slice S3/S3b of the robustness arc
(`2026-08-20_arc10-robustness-charter.md` + ADDENDUM; decision log
D1-D4). Worktrees: CERB `arc/robustness` (base c78804e77), LEM
read-only (no lem changes were needed). Everything quoted as harness
output is verbatim; derived tallies are labeled derived.

## S3 — the pp-placeholder ctype text class (register triage row 2)

### Before (verbatim, re-verified this slice)

```
[1/1] MISMATCH 0006-return_var_unspec: Lean=VAL:Unspecified(<ctype>) Cerberus=VAL:Unspecified('signed int')
[1/1] MISMATCH 0007-inits: Lean=VAL:Unspecified(<ctype>) Cerberus=VAL:Unspecified('signed int')
[1/1] MISMATCH 0046-jump_inside_lifetime: Lean=VAL:Unspecified(<ctype>) Cerberus=VAL:Unspecified('signed int')
[1/1] MISMATCH mem-006-uninitialized-read: Lean=VAL:Unspecified(<ctype>) Cerberus=VAL:Unspecified('signed int')
```

(coverage mem-006 is a 4th in-class file, found this slice — the S0
triage row listed only the 3 ci files + mem3-004, the latter corrected
to finding-11 in D2.)

### Mechanism

Real mirrors of the OCaml printers, file:line-cited at every
definition; placement notes in the files themselves:

- **CerbMem.lean** (the Lean import graph forces the shared mirrors
  below Core.lean — CerbPP imports Core → Mem → CerbMem): `ppSymbol` /
  `ppSymbolRaw` / `ppIdentifier` (Pp_symbol.to_string_pretty
  pp_symbol.ml:12-35, to_string :5-10, pp_identifier :99-103), the
  ctype chain `ppIntegerBaseCtype`/`ppIntegerCtype`/`ppFloatingCtype`/
  `ppBasicCtype`/`ppCtype` (Pp_core_ctype pp_core_ctype.ml:18-90),
  `stringOfProvenance` (impl_mem.ml:550-558), `stringFromIntegerValue`
  (impl_mem.ml:576-580 incl. the debug≥3 provenance form),
  `stringFromPointerValue` (impl_mem.ml:563-572), `stringFromMemValue`
  (impl_mem.ml:591-615) — now TOTAL (was `partial`; structural mutual
  recursion), which also discharges the "stringFromMemValue still
  partial" half of register row 21.
- **CerbFloat.lean**: exact decimal formatting on the IEEE-754
  decomposition (integer arithmetic, round-half-even on the exact
  binary value — glibc printf semantics): `string_of_float` (OCaml
  stdlib string_of_float = valid_float_lexem ∘ format_float "%.12g",
  full %g mirror incl. %e-style switchover and trailing-zero strip)
  and `formatFixed` (C `%.<prec>f`; the Decode.format_string_of_float
  referent, decode.ml:228-232). This closes the
  format_string_of_float stub (triage row 11's #29-class, "may fold
  into S3" — folded).
- **CerbPP.lean**: the Core-value layer — `stringFromCore_value` full
  Pp_core.pp_value mirror (pp_core.ml:276-337: object values, loaded
  values incl. the load-bearing `Unspecified('<ctype>')` squotes at
  :308, struct/union/array shapes), `stringFromCore_core_base_type`
  (pp_core.ml:177-211), `stringFromSymbol_prefix` (pp_symbol.ml:80-96),
  typed delegations for stringFromCtype/stringFromCore_ctype/
  stringFromMemValue/stringFromMem_mem_value/stringFromPointerValue/
  format_string_of_float.
- **Main.lean** `batchExitValue`: now mirrors batch_drive's exit
  selection (driver_ocaml.ml:162-171) ∘ string_of_batch_exit (:42-52)
  exactly — Specified-integer keeps the provenance-erasing explicit
  branch; everything else prints via the real pp_value mirror (the
  previous `OtherValue(...)` wrapper text was itself a divergence —
  OCaml prints the bare pp_value form).

Documented-deliberate divergences (in-code, per the mirror doctrine):
`Vctype` payloads print the Pp_core_ctype text instead of OCaml's
Pp_ail human printer (pp_core.ml:333-334) — the Ail declarator printer
is the pretty-printer-arc residual; `ppIdentifier` omits the debug≥5
location prefix; NaN sign ("-nan") not reproduced. All debug-only
paths, never in compared verdicts.

### Enumerated residual (counted)

CerbPP's "Residual placeholders" section: **25 functions** (derived
count from the file's per-line tags, which are the normative census):
[AIL] 6, [CORE-PP] 8, [CABS] 3, [DEFACTO] 4 (dead model, polymorphic
by necessity), [CMM] 2 (declared concurrency boundary), [PRETTY] 2
(pp_pretty human/decimal forms, no generated caller today). All
residual outputs are "<...>"-bracketed so any leak into compared text
stays an honest mismatch. Register row 2 (ctype text class):
**CLOSED**.
Rows folded/shrunk: row 11 #29-class (format_string_of_float) closed;
row 21's stringFromMemValue-partial half closed (the gate-scan
extension half stays parked per D1).

### Validation (verbatim tails)

Unit lane — new `pp-test` exe (test/Unit/PPTest.lean): ctype/value
shape checks + the OCaml 5.4.0 reference transcript for float
formatting, generated this slice with the switch's ocaml:

```
$ ocaml .tmp/pp_ref.ml     (transcript excerpt, full list in PPTest.lean)
SF 1.
SF 1e+30
SF 1.23456789012e+15
SF 4.94065645841e-324
SF 123456789012.
FF 2
FF 4
FF 0.12
FF 0.14
FF 100000000000000000000.000000
```

pp-test: all pass (`All PP tests passed`); test_unit.sh now runs 6
exes:

```
Total: 6 passed, 0 failed
```

Differential — the four in-class files flipped (verbatim):

```
[1/1] MATCH 0006-return_var_unspec: VAL:Unspecified('signed int')
[1/1] MATCH 0007-inits: VAL:Unspecified('signed int')
[1/1] MATCH 0046-jump_inside_lifetime: VAL:Unspecified('signed int')
[1/1] MATCH mem-006-uninitialized-read: VAL:Unspecified('signed int')
```

Movement check against the PRE-S3 baselines (verbatim):

```
Baseline check: 0 regression(s), 3 improvement(s)    (ci)
Baseline check: 0 regression(s), 1 improvement(s)    (coverage)
```

exactly the four in-class files, nothing else moved. Baselines updated
for those four lines (header notes in both files), then re-run at the
committed baselines (verbatim):

```
SUMMARY: total=242 match=91 ub_match=23 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=110 cerb_inconsistent=18
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=199 match=173 ub_match=12 ub_diff=0 mismatch=1 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=13 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

(ci mismatch is now 0; the coverage mismatch=1 is ptr3-006, register
finding 8, S4's queue. Scoreboard: ci agree 114/114 comparable —
derived.)

Full boundary set, all green this commit: capped default-target
`lake build` (593 jobs, `RelSem audit sweep: 2141 declarations …
0 recorded sorryAx exceptions`), test_unit.sh 6/6 + all gates
(`check_exec_totality: CLEAN (16 generated modules + hand-written
CerbND, 0 allowlisted)`), minimal `BASELINE OK` (0/0), debug
`BASELINE OK` (0/0), libc_exec `ALL MATCH RECORDED BASELINE`
(match=7 diff=0), multi_tu `ALL PASSED` (2/2), parse `ALL PASSED`,
core `ALL PASSED`, elab `SUMMARY: total=106 same=103 diff=3` (recorded
state), uri `GATE PASS … (16/16)`.

## S3b(a) — FLOAT lane (tests/float, 69 files)

The last dangling arc-4 corpus deferral (survey §4.1: copied verbatim
in arc 4, never wired). Wired as a test_exec.sh lane with its own
committed baseline (`scripts/exec_float_baseline.txt`), the
debug-corpus pattern; LADDER Tier A row 4b.

**First-sweep tally, verbatim, BEFORE any fixes (and none were
needed)** — run post-S3 at e0d3ad1f7:

```
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=0 cerb_inconsistent=0
```

100% MATCH; final baseline composition: 69× MATCH, 0 oracle-indicting
entries, 0 registered defects, 0 skips. Expected-failure
classification outcome: the upstream float-mul oracle-bug class
(lembugs/2026-08-19_upstream-float-mul.md, declared TEMPORAL boundary)
did NOT surface — this corpus evaluates float arithmetic through the
concrete model's op_fval (impl_mem.ml:2529-2537 / CerbMem.opFval) on
BOTH sides, and the upstream bug lives in the lem-level
Cerb_floating.mul, which nothing here reaches; that is why
072-compound-mul.c MATCHes. The baseline header carries the standing
classification rule for any future float differential (oracle-indicting
hits are boundary-entry evidence, never "fixed" to match). Baseline
re-check after commit of the baseline file (verbatim):

```
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

## S3b(b) — BYTES lane (tests/bytes, 14 files)

Oracle-INDEPENDENT micro-lane (survey §5 bytes row): the committed
`.exec`/`.elab` files are upstream diff-prog.py records
(tests/diff-prog.py:33-37, mode configs tests/bytes/exec.json /
elab.json) — the reference is the RECORD, not the oracle binary (the
oracle only produces the Cabs-JSON input, the pipeline's standing
parse boundary). New `scripts/test_bytes.sh` (LADDER Tier A row 4c),
fail-closed both directions (mismatch exits 1 — probed with a doctored
expected, restored; zero-comparison vacuous pass refused).

Leg semantics (full rationale in the script header):
- EXEC leg, 9 `*.exec.c`: Lean batch `Specified(N)` rendered as
  `return code: (N mod 256)` (POSIX exit-status byte, diff-prog.py's
  process return code) and byte-compared to the committed `.exec`.
- NEG leg, 5 non-exec `.c` (committed `.elab` = `return code: 1`):
  the oracle front-end rejects these at DESUGAR level BEFORE the
  Cabs-JSON boundary (verified: `--cabs-json` exits 1 with the same
  constraint-violation text as the committed `.elab` body), so the
  Lean pipeline is UNREACHABLE for them. The leg pins that boundary
  (JSON emission for one of these files fails the lane loudly).
  RESIDUAL (recorded, not a defect): the Lean desugar's own
  byte-typing rejection rules are unprobed by this corpus — probing
  them needs either an oracle parse-only mode or Lean-side C parsing,
  both out of this arc's scope.

First (and only) sweep — no fixes were needed; verbatim:

```
[MATCH] cast_0_byte.exec.c: return code: 0
[MATCH] cast_256_byte.exec.c: return code: 0
[MATCH] cast_byte_byte.exec.c: return code: 0
[MATCH] cast_byte_uchar.exec.c: return code: 0
[MATCH] cast_load_byte_pointer.exec.c: return code: 0
[MATCH] cast_neg_128_byte.exec.c: return code: 128
[MATCH] cast_neg_1_byte.exec.c: return code: 255
[MATCH] function_return.exec.c: return code: 0
[MATCH] memcpy.exec.c: return code: 0
[NEG_OK] byte_is_not_char.c: front-end reject pinned (committed .elab rc 1)
[NEG_OK] no_add.c: front-end reject pinned (committed .elab rc 1)
[NEG_OK] no_shift_left.c: front-end reject pinned (committed .elab rc 1)
[NEG_OK] no_shift_right.c: front-end reject pinned (committed .elab rc 1)
[NEG_OK] only_unsigned_char.c: front-end reject pinned (committed .elab rc 1)

SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
```

CerbMem byte handling (loads/stores through `[[cerb::byte]]` pointers,
negative-value wrap, byte-wise memcpy) agrees with the upstream
records on every probeable file; zero mismatches to classify.
