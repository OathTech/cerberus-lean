# Semantics-audit repairs — record (2026-09-11)

Charter: [2026-09-11_codex-charter-semantics-audit-repairs.md](2026-09-11_codex-charter-semantics-audit-repairs.md).
Worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/semantics-audit-repairs`,
branch `arc/semantics-audit-repairs`, starting HEAD `40bb7fe7767f46ac9dc9cb6ea7f330b3eb9aa159`
(the charter commit, on mainline `54f007187`), `git status --porcelain` empty at start.
Worker: Claude (Fable 5.1) [AGENT]; the operator cannot be asked during the run — anything
unresolved is written here as an open question. Every command ran from the worktree with
`source /home/dev/projects/cerberus-lean-proj/scripts/env.sh`; every lake/lean invocation
went through `scripts/capped` with `CERB_MEM_MAX=48G`; `DUNE_CACHE=disabled` for the
gate runs; one heavy job at a time. Quoted outputs are verbatim; derived tallies are
labelled derived; judgments are [AGENT].

Evidence directory: `2026-09-11_semantics-audit-repairs-evidence/` (plain text).

## 0. Reading-list verification — where the tree and the charter differ

[AGENT] Every §1 fact touched was re-read in the tree before use. Two immaterial
differences (recorded, not stop events — neither changes a deliverable's meaning):

1. **Failure-reach register.** Charter §1 says `CerbFloat.truncToInt` AND
   `CerbFloat.of_string`'s malformed-input `panic!` have rows in
   `scripts/failure_reach_register.txt`. The tree has ONE `CerbFloat` row (`:71`,
   `CerbFloat.truncToInt`); `of_string`'s `panic!` has no row (the census's exec
   closure evidently does not reach it — `of_string` is reached from
   `CerbMem.strFval` ← `Mem.str_fval` ← `translation.lem:209`, front-end side, and
   from `CoreParser.lexNumLit`). Consequence: D1's rewrite is gated by
   `check_failure_reach.sh` as the charter says; whether a row appears is what the
   gate reports, not a prediction.
2. **Exec-path mirror target for finding 4.** Charter §1 names `Cerb_floating.of_string`
   (`util/cerb_floating.ml:8-16`, strips one trailing `f`, then `float_of_string`).
   The tree: the CONCRETE model's `str_fval` — the exec-path target, `mem.lem:361-367`
   `declare ocaml target_rep function str_fval = \`Impl_mem.str_fval\`` /
   `declare lean target_rep function str_fval = \`CerbMem.strFval\`` — is
   `memory/concrete/impl_mem.ml:2523-2524` `let str_fval str = float_of_string str`
   (no suffix strip). `Cerb_floating.of_string` is the target of the lem-level
   `Float.of_string` (`frontend/model/float.lem:82`), used by the defacto model
   (`defacto_memory.lem:1268-1269`), outside the concrete exec cone. Both reach the same
   C routine `caml_float_of_string` (`runtime/floats.c`); the only difference is the
   suffix strip, and the C lexer separates the suffix into `suffix_opt`
   (`cabs_json.ml:93-94` `json_of_cabs_floating_constant (s, suffix_opt)`), so no
   suffix reaches either. The D1 goal's "with or without one trailing f/F/l/L" is kept
   as the charter fixes it.
3. **`caml_float_of_hex` rounding.** Charter §1 describes it as "a 64-bit accumulator with
   round-to-odd on excess digits followed by one conversion, i.e. a correctly rounded
   result". The tree (`_opam/.opam-switch/sources/ocaml-compiler.5.4.0/runtime/floats.c:355`
   and `:369`) is `f = (double) (int64_t) m;` followed by `if (exp != 0) f = ldexp(f, exp);`
   — TWO roundings when the result is subnormal (the int64→double conversion rounds the
   ≤60-bit mantissa to 53 bits; `ldexp` then rounds again to the subnormal's shorter
   precision). For NORMAL results `ldexp` is exact and the result is correctly rounded.
   [AGENT] This is a prediction from source reading; the charter's D1 stop rule ("the fork
   oracle disagrees with correct rounding on a D1 battery row") is the mechanism that
   observes it. D1's battery includes the subnormal shapes the charter lists; a long-mantissa
   subnormal (the double-rounding shape) is included as an adversarial row so the question
   is OBSERVED, not left as a reading (see §2).
4. **`CabsImport.lean` already contains `partial def`s** (`jsonToExpression` etc., pre-existing,
   `:286-`). Charter §3 forbids `partial def` "in changed modules"; reading [AGENT]: the
   rule forbids INTRODUCING them (the same sentence treats the pre-existing `Float` externs
   as "the boundary, not a licence for new ones"). D2 adds none.
5. **Lean name of the compatibility entry.** lem emits the reader-lifted wrapper as
   `Ctype_aux.are_compatible0` (`generated/Ctype_aux.lean:119`; the `0` suffix is the
   backend's disambiguation), not `are_compatible`. D3(a)'s unit test names it so.

## D0 — Snapshot

[AGENT] Tier A was run TWICE before any change. The first run (`.tmp/d0-fast`, started
2026-09-11T23:32:38Z) had every lane PASSED but ended `Source unchanged: False` /
`rc=1`: I had written this record's skeleton and the evidence directory into the tree
WHILE it ran, and the runner counts that as a changed source. My error, not the tree's;
the run is discarded as a certification. The second run, with the tree untouched
throughout, is the baseline:

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d0-fast2
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/semantics-audit-repairs/.tmp/d0-fast2
RUN A1: ./scripts/test_unit.sh
PASSED A1 (147.7s)
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2 (27.6s)
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3 (52.1s)
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4 (23.0s)
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b (18.4s)
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c (3.1s)
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5 (23.2s)
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6 (2.2s)
RUN A7: ./scripts/test_parse.sh
PASSED A7 (9.6s)
RUN A8: ./scripts/test_core.sh
PASSED A8 (8.3s)
RUN A9: ./scripts/test_elab.sh
PASSED A9 (16.1s)
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10 (17.0s)
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11 (57.9s)
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

A1's gate lines and every lane's verdict line: `2026-09-11_semantics-audit-repairs-evidence/d0-tierA-verdicts.txt`. The
lines this slice must hold fixed (verbatim, from that run):

```
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
Total: 7 passed, 0 failed
A2: Baseline check: 0 regression(s), 0 improvement(s)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
A6: SUMMARY: total=2 match=2 fail=0
A7: batch diagnostic producers: 8/8 passed
A11: BASELINE OK (213 entries, exact match)…
```

Direct `./scripts/test_unit.sh`: `rc=0`, `Total: 7 passed, 0 failed`; its gate lines are in
`2026-09-11_semantics-audit-repairs-evidence/d0-test-unit-verdicts.txt` (same partition / fork-drift / failure-reach lines
as above).

Pristine upstream oracle, built once from the worktree root with the charter's command
(`scripts/ce python3 scripts/build_independent_oracle.py --lem-repo …/lem-lean
--cerberus-repo …/cerberus-lean --out .validation-foundations/independent-oracle-v2`):
`cerberus-generation: passed (19.368s)`, `cerberus-build: passed (12.602s)`, `rc=0`;
manifest `sources.cerberus.commit = b9aeedcb4dd438763b0eef7f95ac19e93875d7de`;
`artifacts.oracle.path = .validation-foundations/independent-oracle-v2/cerberus/_build/default/backend/driver/main.exe`,
`artifacts.runtime.root = …/independent-oracle-v2/cerberus/_build/install/default`
(the "pristine" engine in every three-engine table below).

D2's regression reference: `2026-09-11_semantics-audit-repairs-evidence/cabs-json-before.sha256` — the sha256 of the
`--cabs-json` stdout of every `tests/minimal/*.c` present at D0 (106 rows; none is the
empty-output hash).

## D1 — Correctly rounded floating-literal conversion (finding 4) — DONE; STOP RULE FIRED on battery row 106

### The conversion (`lean_frontend/CerbFloat.lean`, the "String → Float parsing" section)

[AGENT] `of_string` now parses the literal text to an exact rational and rounds it ONCE,
in `Nat` arithmetic, to the nearest binary64 (IEEE 754-2019 §4.3.1 roundTiesToEven),
assembling the bits with `Float.ofBits`; no `Float` operation precedes that assembly
(`Float.ofNat`/`scaleB`/`ofScientific`, the audited defect, are gone from the module).

1. *Parse* (`parseDecimal` / `parseHex`, `Option`-valued; malformed → the existing
   `panic!` mirror of OCaml's `Failure`, message text unchanged): decimal
   `D* [. D*] [(e|E) [+|-] D+]` → `(m, e10, nd)` with value `m · 10^e10`, `m < 10^nd`;
   hexadecimal (after `0x`/`0X`) `H* [. H*] [(p|P) [+|-] D+]` → `(m, e2, nb)` with value
   `m · 2^e2` (`e2 = p − 4·fracDigits`), `m < 2^nb`. A missing binary exponent is `p0`
   as in `caml_float_of_hex`; an exponent marker without digits is malformed, as for
   `strtod` (the OCaml wrapper requires the whole string consumed, `floats.c:420-421`).
   The sign (`-`/`+`) and one trailing `f`/`F`/`l`/`L` are handled as before.
2. *Guards* (`scaledToBits`): with `m ≥ 1`, an exponent `e > emax + 1` (= 1024) means
   `m · base^e ≥ 2^1025`, above every finite value's rounding range → ±inf; an exponent
   with `e + digits < emin − (p−1) − 1` (= −1075) means the value is below
   `2^−1075`, half the smallest subnormal → ±0. These keep the exact arithmetic bounded
   by the FORMAT, not by the exponent text (`1e999999999` must not build `10^999999999`).
   Everything else is rounded exactly.
3. *Round* (`roundToBinary64Bits neg num den`, `den > 0`): the binade `E` with
   `2^E ≤ num/den < 2^(E+1)` from `Nat.log2 num − Nat.log2 den` plus one comparison; the
   quantum exponent `qe = max(E − 52, −1074)` (normal: `p − 1` fraction bits below the
   leading bit; subnormal: the fixed quantum `2^(emin − (p−1))`); `q = ⌊num · 2^−qe / den⌋`
   with remainder `r`; `2r > d` → `q+1`, `2r < d` → `q`, tie → the even `q`; `q < 2^52` →
   subnormal encoding (exponent field 0, fraction `q`; also ±0 when `q = 0`);
   otherwise a carry `q = 2^53` renormalises to `2^52` one binade up; exponent field
   `qe + 52 + bias`; a field ≥ `2^11 − 1` → ±inf. Sign, biased exponent and trailing
   significand are OR-ed into the `UInt64` per IEEE 754-2019 §3.4.
4. *Constants*: the only numerals are the §3.4 table-3.5 parameters, named and cited in
   the module — `binary64Precision = 53`, `binary64ExpWidth = 11`, `binary64Emax = 1023`
   (= the bias), `binary64Emin = 1 − emax = −1022`, `binary64FracBits = p − 1 = 52`,
   `binary64MinQuantumExp = emin − (p−1) = −1074`, `binary64ExpFieldMax = 2^w − 1`.

Mirror targets and cites are in the module comment (rewritten; the "deliberate,
documented divergence" wording is deleted): `Impl_mem.str_fval = float_of_string`
(`impl_mem.ml:2523-2524`, the exec path) / `Cerb_floating.of_string`
(`util/cerb_floating.ml:8-16`, lem-level); `caml_float_of_string` → `caml_float_of_hex`
(`runtime/floats.c:286-374`) for hex, glibc `strtod` for decimal. The Lean signature of
`of_string : String → Float` is unchanged; no other declaration of the module changed.

Pre-build probe (`.tmp/FloatProbe.lean`, `lake env lean --run` under the cap) — every
bit pattern equalled the Python `float()`/`float.fromhex()` reference computed BEFORE the
Lean side was built (e.g. `1e23 → 0x44b52d02c7e14af6`, `1.7976931348623158e308 →
0x7fefffffffffffff`, `1.7976931348623159e308 → 0x7ff0000000000000`,
`2.2250738585072011e-308 → 0xfffffffffffff`, `2.2250738585072012e-308 → 0x10000000000000`,
`-0.0 → 0x8000000000000000`, `1e999999999 → inf`, `1e-999999999 → 0`,
`0x8000000000000BFp-1082 → 0x8000000000001`).

Builds: `make lean-prelude-src` rc=0 (`check_handwritten_sync: OK (46 hand-written files
byte-identical …)`); `CERB_MEM_MAX=48G ../scripts/capped lake build CerberusLean
cerberus-lean` → `✔ [392/392] Built «cerberus-lean»:exe`, `Build completed successfully
(392 jobs).`, rc=0, 36 s wall (00:01:41Z → 00:02:17Z). The only compiler warning is the
pre-existing `String.dropRight` deprecation at the unchanged suffix-strip line.

### The battery — observed on the fork oracle and gcc BEFORE the Lean build, then on Lean

Method: 26 files were drafted in `.tmp`; each was run on the fork oracle
(`main.exe --runtime=_build/install/default --nolibc --exec --batch --mode=exhaustive`) and
compiled+run with `gcc -O0 -w` FIRST (`…-evidence/d1-oracle-gcc-observed.txt`, verbatim);
after the Lean build, 24 of them were placed in `tests/float/` and the lane
`./scripts/test_exec.sh tests/float` run (`…/d1-float-lane` verdicts below); the two others
are evidence-directory probes run in the lane's single-file mode. Columns: file · fork
oracle value · Lean value · gcc exit · lane status · where the file lives.

| file | oracle | Lean | gcc | lane | where |
|---|---|---|---|---|---|
| `081-hex-audit-260-zeros` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `082-hex-control-1p0` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `083-hex-tie-54th-bit-down` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `084-hex-tie-54th-bit-up` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `085-hex-sticky-116-bits` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `086-hex-1001-bit-mantissa` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `087-hex-1001-bit-sticky` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `088-hex-frac-only-cancel` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `089-hex-max-finite` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `090-hex-first-overflow` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `091-dec-overflow-boundary` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `092-hex-min-normal` | `Specified(1)` | `Specified(1)` | 1 | MATCH | tests/float |
| `093-hex-max-subnormal` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `094-dec-min-normal-midpoint` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `095-hex-min-subnormal` | `Specified(7)` | `Specified(7)` | 7 | MATCH | tests/float |
| `096-dec-half-min-subnormal` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `097-hex-tie-p-1075` | `Specified(7)` | `Specified(7)` | 7 | MATCH | tests/float |
| `098-hex-negative-zero` | `Specified(0)` | `Specified(0)` | 1 | MATCH | evidence probe (withdrawn) |
| `099-hex-forms` | `Specified(31)` | `Specified(31)` | 31 | MATCH | tests/float |
| `100-dec-2p53-ties` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `101-dec-1e23-tie` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `102-dec-point-one-sums` | `Specified(3)` | `Specified(3)` | 3 | MATCH | tests/float |
| `103-dec-long-midpoint` | `Specified(7)` | `Specified(7)` | 7 | MATCH | tests/float |
| `104-dec-random-17-digits` | `Specified(12)` | `Specified(12)` | 12 | MATCH | tests/float |
| `105-suffixes` | `Specified(63)` | `Specified(63)` | 63 | MATCH | tests/float |
| `106-hex-subnormal-long-mantissa` | `Specified(0)` | `Specified(1)` | 1 | MISMATCH | evidence probe (STOP row) |

Verbatim lane lines:

```
$ ./scripts/test_exec.sh tests/float
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0
$ ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float    # after the 24 rows were appended
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
rc=0
$ ./scripts/test_gcc_oracle.sh --no-csmith tests/float      # subset run, no baseline check: observe the new rows
  Compared:     93  (agree=93 agree_nd=0 triaged=0 DISAGREE=0)
SUMMARY: total=93 compared=93 agree=93 agree_nd=0 triaged=0 disagree=0 o2_agree=14
rc=0
$ ./scripts/test_exec.sh -v lean_frontend/docs/2026-09-11_semantics-audit-repairs-evidence/d1-probe-106-hex-subnormal-long-mantissa.c
[1/1] MISMATCH d1-probe-106-hex-subnormal-long-mantissa: Lean=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"} Cerberus=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=1 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
rc=1
$ ./scripts/test_exec.sh -v lean_frontend/docs/2026-09-11_semantics-audit-repairs-evidence/d1-probe-098-hex-negative-zero.c
[1/1] MATCH d1-probe-098-hex-negative-zero: VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
rc=0
```

Baseline rows added (NEW rows only; no existing row changed): `scripts/exec_float_baseline.txt`
+24 rows `081-hex-audit-260-zeros.c MATCH` … `105-suffixes.c MATCH` (appended after
`080-nan-inf.c MATCH`); `scripts/gcc_oracle_baseline.txt` +24 rows inserted after
`tests/float/080-nan-inf.c AGREE -`, sorted by key, at the lane's observed statuses:
`tests/float/081-hex-audit-260-zeros.c AGREE O2_AGREE`, `082 AGREE -`, `083 AGREE -`,
`084 AGREE -`, `085 AGREE -`, `086 AGREE O2_AGREE`, `087 AGREE -`, `088 AGREE -`,
`089 AGREE O2_AGREE`, `090 AGREE -`, `091 AGREE -`, `092 AGREE -`, `093 AGREE O2_AGREE`,
`094 AGREE -`, `095 AGREE -`, `096 AGREE -`, `097 AGREE O2_AGREE`, `099 AGREE -`,
`100 AGREE -`, `101 AGREE -`, `102 AGREE -`, `103 AGREE -`, `104 AGREE -`, `105 AGREE -`
(the O2 column is the lane's name-keyed `cksum mod 10` spot tier, taken as printed).

Unit test (fence: `test/Unit/**` new test + `lakefile.toml` `[[lean_exe]]` +
`scripts/test_unit.sh` registration): `test/Unit/FloatLiteralTest.lean` →
`float-literal-test`, 42 executable bit-pattern pins of `of_string` against the Python/gcc
correctly-rounded references (`42 literal pins checked` / `All float-literal pins passed`,
rc=0). It pins what no C program reaches: the SIGN path (`-0.0`, `-0x0p0`, `-1.5`,
`-0x1p1024`, `-0x1p-1075`, `-1e-999999999` → bit 63 set) — the C lexer strips the sign, so
only `CoreParser.lexNumLit` feeds a signed string — and the correctly rounded value of the
stop row `0x8000000000000BFp-1082 → 0x0008000000000001`. (Note for the orchestrator:
`scripts/LADDER.md` Tier A row 1 says "7/7 exes"; there are now 8. The fence limits my
LADDER edits to row 6b, so the count is left for the orchestrator; `test_unit.sh` prints the
derived total.)

### STOP — row 106: the fork oracle disagrees with correct rounding

[AGENT] Charter D1(b) / §3: "If ANY battery row shows the fork oracle disagreeing with
correct rounding (the oracle wrong, Lean right), STOP … quote both verdicts." Observed:

* `0x8000000000000BFp-1082` = `(2^59 + 191) · 2^−1082` = `2^−1023 + (191/256)·2^−1074`, i.e.
  0.746 of a subnormal quantum above `2^−1023`; the nearest binary64 is
  `2^−1023 + 2^−1074` = `0x1.0000000000002p-1023` (bits `0x0008000000000001`). Two
  independent correctly-rounded references agree: Python `float.fromhex` (§0 pre-computation)
  and gcc (exit 1 on the probe file).
* Fork oracle: `Defined {value: "Specified(0)", …}` rc 0 — it computes `0x1p-1023`
  (bits `0x0008000000000000`).
* Lean (this D1): `Defined {value: "Specified(1)", …}` rc 0 — correctly rounded.
* Cause, read in the mirror target `runtime/floats.c` (§0 item 3): `caml_float_of_hex`
  rounds the 60-bit mantissa `0x8000000000000BF` to 53 bits at `f = (double)(int64_t) m`
  (:355) — the low 7 bits `0x3F < 0x40` round DOWN to `2^59 + 128` — and then `ldexp(f,
  −1082)` (:369) rounds AGAIN to the subnormal quantum: `2^−1023 + 2^−1075` is now an exact
  tie and ties-to-even lands on `2^−1023`. Double rounding; the exact value was above the
  tie. The same double rounding cannot occur for a NORMAL result (`ldexp` is exact there),
  which is why rows 081–105 all MATCH: the defect needs a mantissa longer than 53 bits AND a
  subnormal result. Python's model of the two steps (`math.ldexp(float(m), -1082)`)
  reproduces the oracle's `0x1p-1023` exactly (§0 pre-computation).
* Pristine upstream is not consulted here: the conversion is OCaml's runtime, identical in
  both builds; no Cerberus source is involved.

The row is NOT a `tests/float` file (it would be a red `MISMATCH` in lane A4b, and a
recorded-MISMATCH baseline row would be an ISO-fix-register-shaped exception the charter
forbids for this slice); it lives at `…-evidence/d1-probe-106-hex-subnormal-long-mantissa.c`
with its verbatim runs above. **Open question for the operator (mirror versus ISO):** (i)
mirror `caml_float_of_hex` exactly — 60-bit round-to-odd accumulator, round to 53 bits,
then round to the target precision — on the HEX path only (the decimal path, `strtod`, is
correctly rounded in every range; the mirror is a small, fully specifiable `Nat` step on
top of the D1 core, and the D1 unit pin for row 106 would then move to `0x0008000000000000`),
tray-filing the OCaml runtime bug upstream (OCaml, not Cerberus: `runtime/floats.c`); or
(ii) keep correct rounding (gcc's answer; C11 §6.4.4.2#3 permits either adjacent value for
hex, so BOTH engines are conforming) and give the row an ISO-fix-register entry — which the
charter's §0 says this slice does not get. Under either ruling everything else in D1 stands.
Per the charter's stop rule, D2–D5 are NOT started in this run.

### Withdrawn row 098 (`-0x0p0`) — a different question, recorded

[AGENT] The drafted negative-zero row `union { double d; unsigned char b[8]; } u; u.d =
-0x0p0; return u.b[7] >> 7;` is not a literal-conversion test: the C lexer yields the
UNSIGNED literal `0x0p0` and `-` is unary minus in the AST, so `of_string` never sees a
sign on the C path (its sign handling is CoreParser-only and is pinned in the unit exe).
Observed: fork oracle `Specified(0)` (sign bit clear), Lean `Specified(0)` (MATCH — the
port mirrors the oracle), gcc exit 1 (IEEE negation of +0 is −0). Isolating probes
(`…-evidence/d1-negzero-probes.txt`): `double z = 0.0; u.d = -z` → oracle `Specified(0)`,
gcc 1; `u.d = 0.0 * -1.0` → oracle `Specified(1)`, gcc 1; `u.d = -1.5` → both 3. So
Cerberus's unary minus on a floating ZERO yields +0 where IEEE 754 §5.5.1 / C11 Annex F
give −0 (the evaluator plausibly forms `0 − x`); multiplication and non-zero negation agree.
This is an oracle-vs-ISO question on unary minus, outside this slice (no of_string
involvement; both engines agree) — an open question / tray candidate for the orchestrator.
The row is kept as an evidence probe, not a lane file (the gcc lane would read it
`DISAGREE`).

### D1 acceptance (d) — Tier A green with zero movement; failure-reach unchanged

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d1-fast   # started 2026-09-12T00:08:13Z
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/semantics-audit-repairs/.tmp/d1-fast
RUN A1: ./scripts/test_unit.sh
PASSED A1 (152.3s)
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2 (27.2s)
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3 (51.8s)
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4 (22.5s)
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b (24.0s)
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c (3.1s)
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5 (22.5s)
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6 (2.1s)
RUN A7: ./scripts/test_parse.sh
PASSED A7 (10.2s)
RUN A8: ./scripts/test_core.sh
PASSED A8 (8.3s)
RUN A9: ./scripts/test_elab.sh
PASSED A9 (15.6s)
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10 (18.0s)
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11 (58.1s)
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
Total: 8 passed, 0 failed
A2: Baseline check: 0 regression(s), 0 improvement(s)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
$ ./scripts/test_unit.sh        # direct
Total: 8 passed, 0 failed
rc=0
$ ./scripts/test_verify.sh      # Tier B row 4, named by D1(d): Core-text floats (tests/verify + corpus/ pins)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
rc=0
```

[AGENT] Zero movement: every existing row of every Tier A lane holds (`0 regression(s), 0
improvement(s)` on A2/A3/A4/A4b; A5 libc_exec `match=12 diff=0`; A11 `BASELINE OK (213
entries, exact match)`). `check_failure_reach` reports the SAME 233 rows as D0: the
rewrite neither added nor moved a pure failure site in the exec closure (the one
`panic!` of `of_string` kept its message; §0 item 1). Fuel partition unchanged; fork-drift
layer 2 unchanged (22). Full verdict file: `2026-09-11_semantics-audit-repairs-evidence/d1-tierA-verdicts.txt`.

### D1 acceptance (b), gcc lane — the full Tier B row 7 run with the 24 new ledger rows

```
$ ./scripts/test_gcc_oracle.sh --check-baseline     # started 2026-09-12T00:23:32Z; 00:23:32 up 5 days,  8:59,  ? user,  load average: 0.95, 1.50, 4.00
  Compared:     1909  (agree=1897 agree_nd=0 triaged=12 DISAGREE=0)
SUMMARY: total=1987 compared=1909 agree=1897 agree_nd=0 triaged=12 disagree=0 o2_agree=195 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
rc=0
2026-09-12T00:47:04Z   (end)
```

[AGENT] 1987 rows = the 1963 of D0 + the 24 new `tests/float` rows; every new row AGREE
(the `-O2` spot tier where the lane's name key selected it); no existing row moved. Wall
time 26 min — inside the tripwire, and a pre-justified Tier B differential measurement.

## State at hand-over (STOP after D1, per charter §3)

Done and committed on `arc/semantics-audit-repairs`:

* **D0** — Tier A snapshot green (`dbdf36a5e`), pristine oracle built, 106 cabs-json hashes.
* **D1** — the correctly rounded conversion, its 24-row `tests/float` battery (all MATCH,
  all AGREE), the 42-pin unit exe, the two baselines' NEW rows, Tier A green with zero
  movement, `test_verify` 127/127, the full gcc lane green (this commit).

Not started, by the stop rule: **D2** (byte-preserving Cabs bridge), **D3** (cross-TU
struct-value compatibility), **D4** (tray/registers/docs), **D5** (full battery). No
`.lem`, `cabs_json.ml`, `CabsImport.lean`, manifest, tray, TODO/VALIDATION or LADDER
edit was made. (Drafts of D2's test files existed only under the ephemeral `.tmp/` and
are not part of the record; the next worker re-derives them from charter D2.)

Open questions for the orchestrator / operator, in priority order:

1. **Row 106 — mirror versus ISO for hexadecimal literals whose result is subnormal and
   whose mantissa exceeds 53 bits.** The fork oracle (OCaml's `caml_float_of_hex`)
   double-rounds; correct rounding (gcc, Python, this D1) differs by one quantum. Ruling
   options are written out in §D1 "STOP". Either way D1's decimal path and every
   normal-range hex result are unaffected. If (i) mirror: one extra `Nat` step on the hex
   path — round the exact mantissa to 60 significant bits with round-to-odd (sticky), round
   THAT to 53 bits ties-to-even, then round to the target quantum as now — plus moving the
   unit pin for the row to `0x0008000000000000`, a `tests/float` row at the oracle's
   `Specified(0)` (gcc would read it `DISAGREE` → a `TRIAGED_FLOAT` ledger entry), and an
   upstream-OCaml tray draft. If (ii) ISO: an ISO-fix-register row R4 + the same tray draft,
   and the probe becomes an immaculate-style pinned DIFF.
2. **Unary minus on a floating zero** (§D1 "Withdrawn row 098"): both fork engines give +0
   for `-z` with `z = 0.0` (and for `-0x0p0`), gcc/IEEE give −0; `0.0 * -1.0` and `-1.5`
   agree on all three. Not this slice's surface (no conversion involved; the engines agree);
   a tray candidate against the evaluator's negation of floats. Probe files and verdicts
   are in the evidence directory.
3. **`scripts/LADDER.md` Tier A row 1** says "7/7 exes"; `test_unit.sh` now runs 8 (the
   new `float-literal-test`). The fence limits my LADDER edits to row 6b — the orchestrator
   may update the count (the "280 parser tests" in the same cell is also stale: the exe
   reports 292).
4. **Charter §1 errata** (§0 above): the failure-reach register has no `of_string` row (only
   `truncToInt`); the exec-path mirror target is `Impl_mem.str_fval = float_of_string`
   (`impl_mem.ml:2523-2524`), `Cerb_floating.of_string` being the lem-level target;
   `caml_float_of_hex` is correctly rounded only for normal-range results; the Lean name of
   the compatibility wrapper is `Ctype_aux.are_compatible0`.

---

# Resumption (2026-09-15) — D1b → D2 → D3 → D4 → D5

Worker: Claude (Fable 5.1) [AGENT], resuming at `c7dd0ba29` (the orchestrator's
resumption-note commit on top of D1 `c807ce603`). Pre-flight, verbatim:
`check_driver_fresh: oracle OK (bin bfd9ff8317dc63e3…)`, `check_driver_fresh: lean OK (bin
f3409f596dabc4e4…)`, pristine manifest `status: built`, `git status --porcelain` empty. The
charter's §6/§7 were read in full; where §7 and §0/§1 disagree, §7 was followed.

## D1b — ISO-fix register R5 (the row-106 ruling) — DONE

**The ruling, verbatim from the charter §6** — [USER 2026-09-15]: "Great, agree on your
recommendation. Go ahead with the worker" — on the orchestrator's recommendation: *admit the
row as ISO-fix register entry R5, keep the correctly rounded conversion; pin the row as a
Lean-right / oracle-wrong pair in the immaculate lane; add the code marker; draft the upstream
report against the OCaml runtime with a Cerberus-facing note; register the row in VALIDATION
§2; resume D2–D5 now, with the ruling's consequences as a final D1b; carry the errata below.*
The ISO clause (charter §7, verbatim from `tools/n1570.json` §6.4.4.2#3): "For hexadecimal
floating constants when FLT_RADIX is a power of 2, the result is correctly rounded."

**Observations re-made on this head before any edit** (all verbatim in
`…-evidence/d1b-r5-observations.txt`): OCaml 5.4.0 toplevel
`float_of_string "0x8000000000000BFp-1082" = float_of_string "0x1.0000000000002p-1023"` →
`false`, `%h` forms `0x0.8p-1022` vs `0x0.8000000000001p-1022`; Python `float.fromhex` →
`True`, bits `0x8000000000001`; `floats.c:355` `f = (double) (int64_t) m;`, `:369` `if (exp !=
0) f = ldexp(f, exp);` (line numbers confirmed in the switch's sources); gcc exit 1; fork oracle
`Defined {value: "Specified(0)", …}` rc 0; pristine upstream `Defined {value: "Specified(0)",
…}` rc 0; Lean `Defined {value: "Specified(1)", …}` rc 0.

1. **VALIDATION §2** — one new row `**R5**` in the 8-column shape (oracle behaviour = the
   `str_fval` → `caml_float_of_hex` double rounding with the scope sentence; ISO clause quoted;
   2nd oracle gcc + Python; tray `ocaml/01` + 40; pin `r5-hex-subnormal-double-rounding` DIFF /
   `L=VAL:{value: "Specified(1)", …}`; Lean site `CerbFloat.lean` `roundToBinary64Bits` with the
   marker; ruling `**ADMITTED** [USER 2026-09-15]` with the operator's words as quoted in the
   charter). The R4 paragraph is untouched. [AGENT] The paragraph's sentence "today the markers
   are `CerbDecode.lean` R1/R2" is now incomplete (R5's marker exists) — left as is per the
   charter's "leave the R4 paragraph as it is"; noted for the orchestrator.
2. **Code marker** — `lean_frontend/CerbFloat.lean:142-161`, a `--` block immediately before
   `roundToBinary64Bits`'s docstring containing the literal token `-- ISO-fix register R5`,
   naming §6.4.4.2#3, `floats.c:355,369`, the scope, the second oracles, the tray drafts and the
   pin. The token appears ONCE in the seams (`grep -rn -- '-- ISO-fix register R5'
   lean_frontend/*.lean` → `CerbFloat.lean:142` only). Two stale sentences in the D1 module
   comment were corrected in the same edit (they said the row lived at `tests/float/106` and
   that the pins were `tests/float/081-106`; the row was never a `tests/float` file — it is the
   evidence probe, now the immaculate pin; pins are `081-105` + the R5 immaculate row).
3. **Pin** — NEW `tests/immaculate/nolibc/r5-hex-subnormal-double-rounding.c` (first comment
   line names R5; body = the evidence probe's program). Lane run 1 (no baseline row): the ONE
   deviation was the new file, printed as
   `DIFF           r5-hex-subnormal-double-rounding  O[VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}] L[VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}]`
   / `DEVIATION: r5-hex-subnormal-double-rounding expected [<absent>] got [DIFF | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}]`,
   rc=1 — no other DEVIATION/MISSING line (every existing row held). Baseline row added exactly
   as the lane prints it, in the file's (locale) sort position after `pr44468`, plus a 7-line
   header note (ORACLE-WRONG, R5, flips to MATCH when the OCaml runtime is fixed):
   ```
   r5-hex-subnormal-double-rounding DIFF | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
   ```
   Lane run 2 (verbatim):
   ```
   OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
   rc=0
   ```
   [AGENT] That OK line enumerates R1–R3 only; it is printed by `scripts/test_immaculate.sh`,
   which is OUTSIDE this slice's fence — the text is now incomplete (R5 is a fourth pinned
   non-MATCH row). Open question for the orchestrator (a one-line message edit).
   **gcc lane** (Tier B row 7; `--check-baseline` is defined for the full corpus only, so a
   subset run on `tests/immaculate/nolibc` observed the new row):
   ```
   [16/30] AGREE  tests/immaculate/nolibc/r5-hex-subnormal-double-rounding.c: gcc=1 lean={1}
     Compared:     12  (agree=9 agree_nd=0 triaged=3 DISAGREE=0)
   SUMMARY: total=30 compared=12 agree=9 agree_nd=0 triaged=3 disagree=0 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=5 skip_lean_fail=2 skip_ub=9 triaged_addr=2 triaged_ub=1
   rc=0
   ```
   NEW row in `scripts/gcc_oracle_baseline.txt` (inserted in the immaculate block's key order,
   after `offsetof-union-member.c`): `tests/immaculate/nolibc/r5-hex-subnormal-double-rounding.c AGREE -`.
   [AGENT, derived] The O2 column `-` follows the lane's own rule (`test_gcc_oracle.sh:538-540`:
   `-O2` spot tier iff `cksum(key) mod 10 == 0`; this key's cksum `953628241` ≡ 1, so no O2 run
   — the log has no O2 line for the file; the control `tests/float/081-…` ≡ 0 matches its
   recorded `O2_AGREE`). The full `--check-baseline` run in D5 is the observation that confirms
   the row.
4. **Tray** — (a) NEW `docs/upstream-tray/ocaml/README.md` (what this project is, how a
   runtime report arises) + `ocaml/01-float-of-hex-double-rounding-subnormal.md` (Affected
   `runtime/floats.c:286-372` at OCaml 5.4.0 · Description · Reproducer: the OCaml one-liner
   verbatim + the C program · Observed vs expected with the exact-arithmetic argument · Impact ·
   Proposed remedy: round once — integer-domain pre-rounding at the subnormal quantum, or carry
   the sticky bit to the target precision · Classification TRUE BUG · Provenance with the AI
   note). (b) NEW main-tray `40-float-literal-hex-subnormal-double-rounding-inherited.md`
   (INHERITED / minor; `str_fval` delegates to the runtime; remedy = wait for the runtime fix or
   parse hex constants exactly in Cerberus; cross-references `ocaml/01`; carries the fork, pristine
   and gcc/Python runs verbatim). Number 40 because the charter reserves "the array-bound typo
   draft" (D4) as 39. `INDEX.md`: row 40 after row 38 with a slotting note (ranks with the
   questions — not a Cerberus bug), and a one-line `ocaml/` pointer in "Other upstreams" next to
   the `lean4/` entries (it also names `lem/`, which the INDEX did not mention; README §6 does).
5. **Unit pin** — `test/Unit/FloatLiteralTest.lean` keeps `("0x8000000000000BFp-1082",
   0x0008000000000001)`; its header and the row's comment now say R5 / [USER 2026-09-15] (the
   comment avoids the exact marker token so the seam carries it once).
6. **LADDER Tier A row 1** (fence addition, §6): `7/7 exes` → `8/8 exes`; nothing else on the row
   (its "280 parser tests" is also stale — the exe reports 292 — but the fence says count only).

Build after the edits: `make lean-prelude-src` → `check_handwritten_sync: OK (46 hand-written
files byte-identical …)`; `CERB_MEM_MAX=48G ../scripts/capped lake build CerberusLean
cerberus-lean` → `✔ [392/392] Built «cerberus-lean»:exe`, `Build completed successfully (392
jobs).`, rc=0 (02:51:40Z → 02:52:50Z); only the pre-existing `String.dropRight` deprecation
warning at `CerbFloat.lean:288`; stamp re-recorded, `check_driver_fresh: oracle OK (bin
bfd9ff83…)` / `lean OK (bin 95431e7e…)`. No Lean signature changed (comment-only edits to the
two `.lean` files). Files changed by D1b: `lean_frontend/CerbFloat.lean`,
`lean_frontend/test/Unit/FloatLiteralTest.lean`, `lean_frontend/VALIDATION.md`,
`tests/immaculate/nolibc/r5-hex-subnormal-double-rounding.c` (new), `tests/immaculate/baseline.txt`
(+1 row, +7 header lines), `scripts/gcc_oracle_baseline.txt` (+1 row), `scripts/LADDER.md` (row
1), `docs/upstream-tray/ocaml/{README,01-…}.md` (new), `docs/upstream-tray/40-….md` (new),
`docs/upstream-tray/INDEX.md`, this record, `…-evidence/d1b-r5-observations.txt`.

## D2 — Byte-preserving Cabs bridge (finding 3) — DONE

### The bridge before and after

[AGENT] The C lexer's `s_char_sequence` (`parsers/c/c_lexer.mll:434-457`) yields one fragment
per s-char — an escape sequence as its source TEXT, or ONE raw source byte — and a character
constant's body likewise. The exporter wrote every fragment with `json_of_string s = `String s`
(`cabs_json.ml:73`), and Yojson 3.0.0 (`lib/write.ml`) escapes only `"`, `\`, `0x00-0x1F` and
`0x7F` — a byte ≥ 0x80 was copied RAW, the JSON was not UTF-8, and `IO.FS.readFile`
(`Main.lean:280`) refused it where the oracle succeeds on every shape that never decodes the
bytes. Fix (charter shape): `json_of_bytes` maps byte `b < 0x80` to itself and `b ≥ 0x80` to
the scalar U+00`b` (two UTF-8 bytes, `0xC0 | b>>6`, `0x80 | b&0x3F`), so the JSON is always
valid UTF-8 and the Lean side reads ONE `Char` per source byte with `c.toNat` = the byte — the
project's byte-carrier convention (`docs/2026-09-09_batch-diagnostic-bytes-record.md`: "Model
bytes carried in Chars"). Decoding (decode.ml / CerbDecode) is untouched on both sides.

**Every `` `String `` / `json_of_string` site of `backend/lean_export/cabs_json.ml`, classified**
(line numbers AFTER the edit; the edit added 26 lines at :75-100):

| site | what | class | reason |
|---|---|---|---|
| `:13` `tag name` | constructor tag | TEXT | schema names, ASCII |
| `:14` `tag0 name` | nullary constructor | TEXT | schema names, ASCII |
| `:30` `("file", `String (Cerb_position.file p))` | file name | TEXT | file names are Unicode text (charter: identifiers/filenames stay TEXT) |
| `:44` `Loc_other s` | location description | TEXT | diagnostic text |
| `:63` `("name", `String s)` in `json_of_identifier` | C identifier | TEXT | identifiers are text (the lexer's identifier class is ASCII/UCN) |
| `:73` `json_of_string` | the text encoder | TEXT | kept for every text field |
| `:91` `json_of_bytes` (NEW) | the byte encoder | BYTES | this fix |
| `:114` integer constant `String s` | digit text | TEXT | ASCII by the lexer's token class |
| `:121` floating constant `String s` | digit text | TEXT | ASCII by the lexer's token class |
| `:129` character-constant body | c-char sequence | **BYTES** → `json_of_bytes` | one raw source byte or an escape's text; decoded later in the model |
| `:146` string-literal fragments | s-char fragments | **BYTES** → `json_of_bytes` | as above |
| `:324` `CabsSasm` parts | asm string-literal fragments | **BYTES** → `json_of_bytes` | the same `(loc, strs)` fragment shape as `:146` (asm parts are string literals) |
| `:600, :602` attribute argument strings (`attr_args`) | `__attribute__`/`[[…]]` arguments | TEXT | consumed as annotation text by `Annot`/CN; the charter names them text. NOTE [AGENT]: the parser builds them from string literals (`c_parser.mly:1780-1785` `located_string_literal`, `String.concat` of the fragments), so a raw byte ≥ 0x80 in an attribute string would still leave the JSON non-UTF-8 — fail-NOISY on the Lean side (`readFile` refuses), never silent; recorded as an open question, not changed here |
| `:657` `EDecl_magic` `str` | magic-comment text | TEXT | CN comment text; same note as attribute args |

Lean importer (`CabsImport.lean`): NEW `getByteStr` (`:98-109`) = `getStr` + a fail-closed
check that every `Char` has `toNat < 256`, else `err "getByteStr" "byte-carrier violation: code
point U+… (≥ 256) in a string-literal fragment or character constant; …"` — an `Except` error
naming the code point, never absorbed; used at `jsonToCharacterConstant` (`:249`),
`jsonToStringLiteral` (`:268`) and the `CabsSasm` parts (`:746`); identifiers/file names keep
`getStr`. Note Z2-J-02 (`:31-48`) rewritten: the both-fail claim is stated FALSE for shapes that
never decode the bytes, with the fix and the convention. No signature changed; no new `partial`.
`CerbDecode.lean` untouched.

### Observations — fork oracle (post-D2 exporter), pristine upstream, gcc, Lean — all verbatim in `…-evidence/d2-oracle-gcc-observed.txt`

Every new file's `--cabs-json` output is `rc=0` and `valid UTF-8` (strict decode). Verdicts
(`--nolibc --exec --batch --mode=exhaustive`; Lean `LEAN_ABORT_ON_PANIC=1 --batch`):

| file | fork oracle | pristine | gcc | Lean |
|---|---|---|---|---|
| `tests/minimal/107-sizeof-multibyte-literal.c` (raw `c3 a9`) | `Specified(3)` rc 0 | `Specified(3)` rc 0 | 3 | `Specified(3)` rc 0 |
| `tests/minimal/108-sizeof-5byte-multibyte-literal.c` (raw `c3 a9 e2 82 ac`) | `Specified(6)` rc 0 | `Specified(6)` rc 0 | 6 | `Specified(6)` rc 0 |
| `tests/minimal/109-escape-hex-all-bytes.c` (256 `\xNN`, 6 indices summed mod 256) | `Specified(2)` rc 0 | `Specified(2)` rc 0 | 2 | `Specified(2)` rc 0 |
| `tests/minimal/110-escape-octal-all-bytes.c` (256 `\NNN`) | `Specified(231)` rc 0 | `Specified(231)` rc 0 | 231 | `Specified(231)` rc 0 |
| `tests/minimal/111-escape-nul-inside-literal.c` (`"ab\0cd"`) | `Specified(159)` rc 0 | `Specified(159)` rc 0 | 159 | `Specified(159)` rc 0 |
| `tests/immaculate/nolibc/f3-escaped-high-byte-uchar.c` (`(unsigned char)"\xc3\xa9"[0]`) | `Specified(195)` rc 0 | `Specified(195)` rc 0 | 195 | `Specified(195)` rc 0 |
| `tests/immaculate/nolibc/f3-raw-high-byte-int.c` (`"é"[0]`) | `Failure("decode_character_constant: invalid char constant ==> \169")` rc 125 | same, rc 125 | 195 | `PANIC … decode_character_constant: invalid char constant ==> Ã (decode.ml:199-200)` rc 134 |
| `tests/immaculate/nolibc/f3-raw-high-byte-uchar.c` (`(unsigned char)"é"[0]`) | `Failure(… ==> \169")` rc 125 | same, rc 125 | 195 | `PANIC …` rc 134 |
| `tests/immaculate/nolibc/f3-raw-high-byte-char-const.c` (`'é'`) | `Failure(… ==> \195\169")` rc 125 | same, rc 125 | 169 | `PANIC … ==> Ã© …` rc 134 |

[AGENT] The three crash-class files present the SAME class on both fork engines: an uncaught
exception / abort at the decoder, no verdict (the oracle's `Failure` message quotes the byte as
OCaml `\169`; Lean's panic message renders the byte-carrier `Char`s through the text path as
`Ã`/`Ã©` — message text, not a verdict token, and the lane compares verdict tokens). The
oracle's message quotes `\169` (0xA9) for the two-fragment literal where Lean's quotes `Ã`
(0xC3): the two decoders reach the fragment list's two bytes in different orders before
failing — an ordering inside a crash, not a verdict difference (both fail-stop at the same
site class, decode.ml:199-200 / its CerbDecode mirror). gcc returns `(char)0xC3` = -61 → exit
195 for the int shape, 195 for the unsigned-char shape and 169 for the multi-char constant
(implementation-defined) — no oracle-independent reference exists for a program the oracle
rejects; the `f3-escaped-…` twin is the reference that does run (195 on all four).

### The bridge probe (D2(d)) — `scripts/test_cabs_bytes_probe.py`, called from `test_parse.sh`

Generates a C file whose literal holds every raw byte `0x80..0xFF` in order, runs the REAL
`--cabs-json`, and asserts fail-closed: (1) rc 0 and the output decodes as strict UTF-8; (2) the
`CabsEstring` fragments are 128 one-character strings whose code points are exactly
`0x80..0xFF` in order (a direct JSON read); (3) Lean `--batch` on that JSON prints
`Defined {value: "Specified(129)", …}` (sizeof = 128 + NUL). The PLANT is the pre-D2 binary
itself — the probe was written BEFORE the exporter was rebuilt and run against the exporter
that still carried the raw write (`…-evidence/d2-bridge-probe.txt`, verbatim):

```
$ python3 scripts/test_cabs_bytes_probe.py --oracle-bin _build/default/backend/driver/main.exe --lean-bin lean_frontend/.lake/build/bin/cerberus-lean     # PRE-D2 oracle bin bfd9ff83…
cabs bytes probe: FAIL at step 1: --cabs-json output is NOT valid UTF-8: 'utf-8' codec can't decode byte 0x80 in position 95461: invalid start byte (raw-byte write reintroduced?)
rc=1
$ python3 scripts/test_cabs_bytes_probe.py …                                                  # POST-D2 oracle bin 8878b2c5…
cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
rc=0
```

### D2(e) — regression: the 106 D0 `--cabs-json` hashes

Before the rebuild the current oracle reproduced all 106 rows of
`…-evidence/cabs-json-before.sha256` (method check, `diff` empty). After the rebuild, restricted
to the same 106 files: `diff` empty — **every D0 hash is byte-identical on the post-D2
exporter** (the unrestricted diff is exactly `106a107,111`, the five new files' rows;
`…-evidence/d2-oracle-gcc-observed.txt`). ASCII inputs are untouched by the encoder, as the
charter requires; no STOP.

Builds: `build_cerberus` (dune → install `_build/local-install` → `cerberus.install`) rc=0,
03:07:xx→03:08:36Z, `check_driver_fresh: recorded oracle stamp (bin 8878b2c5…)`; `make
lean-prelude-src` + `CERB_MEM_MAX=48G ../scripts/capped lake build CerberusLean cerberus-lean`
→ `✔ [392/392] Built «cerberus-lean»:exe`, rc=0 (03:08:4x→03:10:05Z); `check_driver_fresh:
oracle OK (bin 8878b2c5…)` / `lean OK (bin e5cea7e3…)`.

### Acceptance — lanes (key lines verbatim; all in `…-evidence/d2-lanes.txt`)

(a)/(c) `tests/minimal`, exec lane, first run (observe):
```
$ ./scripts/test_exec.sh tests/minimal
[107/111] MATCH 107-sizeof-multibyte-literal: VAL:{value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
[108/111] MATCH 108-sizeof-5byte-multibyte-literal: VAL:{value: "Specified(6)", stdout: "", stderr: "", blocked: "false"}
[109/111] MATCH 109-escape-hex-all-bytes: VAL:{value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
[110/111] MATCH 110-escape-octal-all-bytes: VAL:{value: "Specified(231)", stdout: "", stderr: "", blocked: "false"}
[111/111] MATCH 111-escape-nul-inside-literal: VAL:{value: "Specified(159)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=111 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
```
`scripts/exec_baseline.txt` gains exactly five rows, `107-sizeof-multibyte-literal.c MATCH` …
`111-escape-nul-inside-literal.c MATCH` (appended after `106-…`); no existing row changed.

(b) immaculate lane, first run (observe; the four DEVIATION lines are the four new files and
there is no other DEVIATION/MISSING line):
```
  MATCH          f3-escaped-high-byte-uchar  O[VAL:{value: "Specified(195)", stdout: "", stderr: "", blocked: "false"}] L[VAL:{value: "Specified(195)", stdout: "", stderr: "", blocked: "false"}]
  MATCH          f3-raw-high-byte-char-const  O[CRASH] L[CRASH]
  MATCH          f3-raw-high-byte-int  O[CRASH] L[CRASH]
  MATCH          f3-raw-high-byte-uchar  O[CRASH] L[CRASH]
DEVIATION: f3-escaped-high-byte-uchar expected [<absent>] got [MATCH | L=VAL:{value: "Specified(195)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: f3-raw-high-byte-char-const expected [<absent>] got [MATCH | L=CRASH]
DEVIATION: f3-raw-high-byte-int expected [<absent>] got [MATCH | L=CRASH]
DEVIATION: f3-raw-high-byte-uchar expected [<absent>] got [MATCH | L=CRASH]
```
The lane's label for the crash class is the both-crash pair `MATCH | L=CRASH` (oracle `CRASH`
= uncaught exception exit 125; Lean `CRASH` = abort 134) — recorded as printed, not predicted.
`tests/immaculate/baseline.txt` gains the four rows verbatim (locale-sorted after `argv3-args`)
plus a 7-line header note; no existing row changed.

(g) parse and core lanes on `tests/minimal` with the five new files:
```
$ ./scripts/test_parse.sh          # before the probe step was added
Total:          111
Lean parse:     111 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)
Success rate:   100% (of cerberus successes)
batch diagnostic producers: 8/8 passed
ALL PASSED
$ ./scripts/test_core.sh
Total:          111
Lean parse:     111 ok, 0 failed
Success rate:   100% (of cerberus successes)
ALL PASSED
```
([AGENT] `--pp core` elaborates string literals to `Array(Specified(conv_int('char', N)))…`
and `sizeof` to `Ivsizeof('char[3]')` — ASCII Core text — so the Core-text bridge never carries
the raw bytes; checked on scratch files before the lane.)

gcc lane, subset runs (observe-only; `--check-baseline` is full-corpus only):
```
$ ./scripts/test_gcc_oracle.sh tests/minimal
[107/111] AGREE  tests/minimal/107-sizeof-multibyte-literal.c: gcc=3 lean={3}
[108/111] AGREE O2_AGREE tests/minimal/108-sizeof-5byte-multibyte-literal.c: gcc=6 lean={6}
[109/111] AGREE  tests/minimal/109-escape-hex-all-bytes.c: gcc=2 lean={2}
[110/111] AGREE  tests/minimal/110-escape-octal-all-bytes.c: gcc=231 lean={231}
[111/111] AGREE  tests/minimal/111-escape-nul-inside-literal.c: gcc=159 lean={159}
SUMMARY: total=111 compared=90 agree=90 agree_nd=0 triaged=0 disagree=0 o2_agree=8 skip_lean_crash=1 skip_lean_fail=2 skip_ub=18
$ ./scripts/test_gcc_oracle.sh tests/immaculate/nolibc
[1/34] AGREE  tests/immaculate/nolibc/f3-escaped-high-byte-uchar.c: gcc=195 lean={195}
[2/34] SKIP_LEAN_CRASH  tests/immaculate/nolibc/f3-raw-high-byte-char-const.c: (exit 134) PANIC at … CerbDecode:151:6: decode_cha…
[3/34] SKIP_LEAN_CRASH  tests/immaculate/nolibc/f3-raw-high-byte-int.c: (exit 134) PANIC at … CerbDecode:121:11: decode_ch…
[4/34] SKIP_LEAN_CRASH  tests/immaculate/nolibc/f3-raw-high-byte-uchar.c: (exit 134) PANIC at … CerbDecode:121:11: decode_ch…
SUMMARY: total=34 compared=13 agree=10 agree_nd=0 triaged=3 disagree=0 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=2 skip_ub=9 triaged_addr=2 triaged_ub=1
```
`scripts/gcc_oracle_baseline.txt` gains nine NEW rows at the observed statuses, in key order
(`107 AGREE -`, `108 AGREE O2_AGREE`, `109 AGREE -`, `110 AGREE -`, `111 AGREE -` after
`106-…`; `f3-escaped-high-byte-uchar.c AGREE -`, `f3-raw-high-byte-char-const.c SKIP_LEAN_CRASH -`,
`f3-raw-high-byte-int.c SKIP_LEAN_CRASH -`, `f3-raw-high-byte-uchar.c SKIP_LEAN_CRASH -` before
`g1-ge-funptr.c`). [AGENT, derived] The O2 column follows the lane's stride rule (108's key
≡ 0 mod 10 and the lane printed `O2_AGREE`; the other eight keys ≡ 1, 2, 2, 3, 6, 6, 6, 2 — no
O2 run, `-`). The `SKIP_LEAN_CRASH` class for the three crash files is the lane's own
classification of a Lean abort (the skip ledger; gcc's value for a program the oracle rejects
is not a reference).

(f) fork-drift, before the manifest edit (the gate names the new hash):
```
$ ./scripts/check_fork_drift.sh
check_fork_content: FAIL — source-content drift inside reviewed file(s):
backend/lean_export/cabs_json.ml: expected ('100644', '34f2ddcf61f53b82f11171f95ca8d02181e35034e7b6dc81281f8b746dda1ab0'), actual ('100644', '5f64fc9cadd7064237ef4f3403641a7870be35a06d5a0b07257c7ea6a72c44f3')
check_fork_drift: FAIL — source-content check failed
```
Manifest edit: the ONE `[source-content]` row `backend/lean_export/cabs_json.ml` `34f2ddcf… →
5f64fc9c…` plus a 9-line dated header note in the manifest's existing style (newest first); no
other hunk.

Re-runs after the edits (verbatim):
```
$ ./scripts/check_fork_drift.sh
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
$ ./scripts/test_immaculate.sh
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
$ ./scripts/test_parse.sh          # with the probe step (scripts/test_parse.sh, after test_batch_diagnostics.py)
Total:          111
Lean parse:     111 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)
Success rate:   100% (of cerberus successes)
batch diagnostic producers: 8/8 passed
cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
ALL PASSED
$ ./scripts/test_exec.sh --check-baseline
SUMMARY: total=111 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
```

### D2(h) — Tier A green, zero movement (verbatim; full file `…-evidence/d2-tierA-verdicts.txt`)

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d2-fast   # 03:17:45Z → 03:24:34Z
RUN A1: ./scripts/test_unit.sh
PASSED A1 (148.3s)
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2 (27.5s)
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3 (50.4s)
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4 (22.2s)
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b (23.7s)
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c (3.0s)
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5 (21.7s)
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6 (2.1s)
RUN A7: ./scripts/test_parse.sh
PASSED A7 (10.1s)
RUN A8: ./scripts/test_core.sh
PASSED A8 (8.7s)
RUN A9: ./scripts/test_elab.sh
PASSED A9 (16.3s)
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10 (16.4s)
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11 (57.0s)
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
rc=0
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
Total: 8 passed, 0 failed
A2: Baseline check: 0 regression(s), 0 improvement(s)      # tests/minimal, now 111 rows (5 NEW)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
A6: SUMMARY: total=2 match=2 fail=0
A7: batch diagnostic producers: 8/8 passed / cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
A11: BASELINE OK (213 entries, exact match)
$ ./scripts/test_unit.sh        # direct, 03:24:34Z → 03:27:00Z
Total: 8 passed, 0 failed    (same partition / fork-drift / failure-reach / parametricity lines)
rc=0
```

[AGENT] Zero movement: every existing row of every Tier A lane holds; the immaculate lane
(Tier B) holds with its four NEW rows; `check_failure_reach` reports the same 233 rows (the
importer's new `Except` error is not a pure `panic!`/`failwithI` site; `CerbDecode` is
untouched); fork-drift layer 2 unchanged (22) with the one `[source-content]` pin moved. D2
changed no Lean signature (`getByteStr` is a new private-to-module helper; the importers'
types are unchanged) and introduced no `partial`. Files changed by D2: `backend/lean_export/
cabs_json.ml`; `lean_frontend/CabsImport.lean`; `scripts/test_parse.sh` (+ NEW
`scripts/test_cabs_bytes_probe.py`); NEW `tests/minimal/107…111` and
`tests/immaculate/nolibc/f3-*` (4); `scripts/exec_baseline.txt` (+5 rows),
`tests/immaculate/baseline.txt` (+4 rows, +7 header lines), `scripts/gcc_oracle_baseline.txt`
(+9 rows), `scripts/fork_drift_manifest.txt` (1 row + header note); this record and three
evidence files.


## D3 — Cross-TU struct-value compatibility (finding 5 + draft 38) — the `.lem` change DONE and gated (first commit); STOP RULE FIRED before the corpus/lane pin (second commit not made)

### The `.lem` diff, verbatim (the 10-line comment block in `core_eval.lem` is the only other text; `git show` of the commit has it)

```
--- a/frontend/model/ctype_aux.lem
+++ b/frontend/model/ctype_aux.lem
@@ -97,7 +97,7 @@
     | (Array elem_ty1 n1_opt, Array elem_ty2 n2_opt) ->
         (* STD §6.7.6.2#6 *)
            are_compatible_aux assumed (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
-        && match (n1_opt, n1_opt) with
+        && match (n1_opt, n2_opt) with
--- a/frontend/model/core_eval.lem
+++ b/frontend/model/core_eval.lem
@@ -942,7 +942,19 @@
           | Just (Vobject (OVstruct tag_sym' xs)) ->
+              (* semantics-audit repairs D3 (2026-09-11; upstream-tray draft 38): … *)
-              if tag_sym <> tag_sym' then
+              if tag_sym <> tag_sym' && not (Ctype_aux.are_compatible
+                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym))
+                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym'))) then
                 EU.fail $ Illformed_program ("PEmemberof(struct) ==> mismatched tags: " ^ show tag_sym ^ " vs " ^ show tag_sym')
```

The union case (`core_eval.lem` `OVunion` arm, exact-tag guard) and `memValueFromValue`'s
exact-tag union arm (`core_aux.lem:204-208`) are NOT changed — the "union twin" (open
question; a reproducer would be draft 38's shape with `union` in place of `struct`).

### Why this is the authors' intent and not a new semantics [AGENT]

Two definitions of one struct in different translation units are compatible types (C11
§6.2.7#1: same tag, same members in order, compatible member types). The evaluator ALREADY
treats such a value as the same type where it is STORED: `memValueFromValue`'s
`Struct/OVstruct` arm (`core_aux.lem:198-200`) consults `Ctype_aux.are_compatible` on exactly
these two `Struct` types before building the memory value. The exact-tag guard at member
SELECTION (`PEmemberof`) predates the multi-TU path and contradicts that store-side rule on
the same value: a value the store accepts as `struct S` could not be member-selected as
`struct S`. The repair makes selection consult the same predicate — only when the tags differ
(the conjunction short-circuits; equal tags never reach it), so single-TU programs pay nothing
and change nothing — and makes the predicate correct on the one arm where a typo compared a
bound with itself (the Ail-level twin `ailTypesAux.lem:807-813` compares `(n1_opt, n2_opt)`;
the intent is written twice in the sources and wrong once). Results change only on multi-TU
programs where the guard previously rejected a compatible value or the typo previously
accepted an incompatible one — and, as the STOP below records, the latter is reachable in
matched mode only on the RETURN path.

### Builds and the proof obligation

`opam exec --switch=. -- make prelude-src` rc=0 (`check_lem_sync: recorded … src b1adb559… gen
dcb9c3b1…`); `build_cerberus` rc=0 (→03:30:18Z), `check_driver_fresh: recorded oracle stamp (bin
e40ae8e3…)`; the regenerated `ocaml_frontend/generated/ctype_aux.ml:84-87` reads `Array(
elem_ty1, n1_opt), Array( elem_ty2, n2_opt)) -> … (match (n1_opt, n2_opt) with`. Lean: `make
lean-prelude-src` rc=0 (`check_handwritten_sync: OK (46 …)`), `CERB_MEM_MAX=48G ../scripts/capped
lake build CerberusLean cerberus-lean` → `✔ [392/392] Built «cerberus-lean»:exe`, rc=0
(03:31:4x→03:35:xxZ; the regenerated `Core_eval.lean` recompiled its dependants). **The measure
proof `Core_eval_lemMeasureProofs.lean` needed NO edit**: `step_eval_pexpr_stable_aux` closes the
`PEmemberof` arm by the generic `cases pexpr_ <;> simp (disch := size_lt) only
[step_eval_pexpr_lemFuel, key]` — the arm has the same single recursive call (`self pe`) and the
new `are_compatible0 _lemReader_tagDefs …` sits in the fuel-free continuation. `check_driver_fresh:
oracle OK (bin e40ae8e3…)` / `lean OK (bin e36af96d…)`.

### D3(a) — unit pin `test/Unit/AreCompatibleTest.lean` → exe `are-compatible-test` (lakefile `[[lean_exe]]` + `test_unit.sh` registration, the D1 pattern)

Executable assertions on `are_compatible0 tagDefs` (the reader-lifted wrapper of the lem
`are_compatible`, `generated/Ctype_aux.lean:119`); the cross-TU cases use two tag symbols with
different digests (`Symbol.from_same_translation_unit` is a digest compare) and the same name,
both in one tag environment (the linked program's), verbatim:
```
test: Ctype_aux.are_compatible0 — array-bound arm (finding 5 repair) + cross-TU struct member
  ok   int[1] vs int[2] = false
  ok   int[2] vs int[1] = false
  ok   int[2] vs int[2] = true
  ok   int[] vs int[2]  (§6.7.6.2#6) = true
  ok   int[2] vs int[] = true
  ok   struct S{int a[1]} (TU1) vs struct S{int a[2]} (TU2) = false
  ok   struct S{int a[2]} (TU1) vs struct S{int a[2]} (TU2) = true
  ok   same-TU same tag (fast path) = true
All are_compatible pins passed
```

### D3(b)/(c) — reproducers on the three engines (+ gcc); all verbatim in `…-evidence/d3-reproducers-observed.txt`

Scratch corpus `.tmp/d3/cases/<case>/{tu1.c,tu2.c}` (linked `tu1.c tu2.c`), NOT a lane corpus
(see the STOP). Fork oracle and pristine: `--nolibc --exec --batch --mode=exhaustive`, 60 s
timeout; Lean: per-TU `--cabs-json` then `LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch tu1.json
tu2.json`; gcc `-std=c11 -O0 -w`. `E(m,n)` abbreviates `Error {msg: "ill-formed program:
\`PEmemberof(struct) ==> mismatched tags: Symbol(m, SD_Id("S")) vs Symbol(n, SD_Id("S"))'"}`
rc 1 (for `node` the tag is `node`); `D7` = `Defined {value: "Specified(7)", stdout: "",
stderr: "", blocked: "false"}` rc 0.

| case | TU1 | TU2 | fork oracle (fixed) | Lean (fixed) | pristine | gcc |
|---|---|---|---|---|---|---|
| `node` (draft 38's positive: `struct node {int v; struct node *next;}` in both; value returned by `ident`, `.v` selected) | `ident` | `main` | **`D7`** | **`D7`** | `rc=124` (draft 37's non-termination; 60 s) | 7 |
| `arr-1-2-return` (NEGATIVE: `int a[1]` vs `int a[2]`, value RETURNED then `.a[0]`) | `mk` | `main` | `E(545,502)` | `E(63,19)` | `E(545,502)` | 7 |
| `arr-1-2-arg` (NEGATIVE: same structs, value PASSED by value to `get`) | `get` | `main` | **`D7`** | **`D7`** | `D7` | 7 |
| `arr-2-2-return` (positive twin, equal bounds) | | | `D7` | `D7` | `E(558,502)` | 7 |
| `arr-2-2-arg` (positive twin) | | | `D7` | `D7` | `D7` | 7 |
| `arr-incomplete-ptr-return` (positive twin: member `int (*p)[]` vs `int (*p)[2]`, §6.7.6.1#2 + §6.7.6.2#6; `.n` selected) | | | `D7` | `D7` | `E(536,502)` | 7 |
| `fam-vs-array-return` (`struct S {int n; int a[];}` vs `{int n; int a[2];}`; `.n`) | | | `E(533,502)` | `E(50,19)` | `E(533,502)` | 7 |
| probe `name-arg` (`{int a;}` vs `{int b;}`, PASSED by value) | | | `D7` | `D7` | — | — |
| probe `name-return` (same, RETURNED, `.b`) | | | `E(533,502)` | `E(50,19)` | — | — |

The two fork engines AGREE on every row up to symbol numbering in the `Error` text (the
charter's tolerance); the fixed fork now gives gcc's value on draft 38's reproducer and on
every positive twin; pristine rejects the positive twins at the exact-tag guard and does not
terminate on `node`. [AGENT] `fam-vs-array-return`: Cerberus keeps a flexible array member
outside the member list (`StructDef xs flexible_opt`), so the two definitions differ in member
COUNT and `are_compatible_aux` is false on both engines — recorded as observed; it is not the
charter's "`int a[]` vs `int a[2]`" positive twin (the `int (*p)[]` member is, and is positive).

### THE STOP — a chartered NEGATIVE case completes `Defined` on the fixed fork

Charter D3(c) / §3: "if a NEGATIVE case completes with a `Defined` verdict on the fixed fork,
STOP (compatibility is not load-bearing where you thought — a finding)". **`arr-1-2-arg`** —
the chartered shape "(2) PASSED by value as an argument" — is `Defined {value:
"Specified(7)"}` rc 0 on the fixed fork oracle (and on Lean, and on pristine). Taken as far as
reading and a 10-second probe allow:

* Probe: `struct S {int a;}` (TU1, `int get(struct S s) { return s.a; }`) vs `struct S {int b;}`
  (TU2, `s.b = 7; return get(s);`) — members differing in NAME, plainly incompatible — also
  `Defined {value: "Specified(7)"}` rc 0 on both fork engines. The same pair RETURNED and
  member-selected (`return mk().b;`) → `Error {… mismatched tags …}` rc 1 on both.
* Cause, read in `core_run.lem:960-970` (the `Eccall` argument path the charter §1 named as a
  consult site): the ctype handed to `memValueFromValue` for each argument is
  `Ctype.Ctype [] (Ctype.Pointer Ctype.no_qualifiers ty)` UNLESS `Global.has_switch
  Global.SW_inner_arg_temps` — in the default configuration (matched mode: `CerbGlobal`'s switch
  set is `[]`) a by-value struct argument travels as a POINTER to a caller-side temporary; the
  memvalue built is a pointer value and the `Struct/OVstruct` arm — the consult — is never
  reached on the argument path. The callee then LOADS `s.a[0]` (or `s.a`) through that pointer
  under its own definition: offset 0 in both layouts, hence 7 for `{int a[1]}` vs `{int a[2]}`
  and for `{int a}` vs `{int b}` alike. The typo was therefore unobservable on the argument
  path in matched mode, and its repair changes nothing there.
* Under `--switches=inner_arg_temps` (NOT matched mode; observation only, fork oracle):
  `arr-1-2-arg` → `cerberus: internal error, uncaught exception: Failure("internal error:
  can_advance: Step_error2 ==> …/tu1.c:2:1-39 (cursor: 2:5 - 2:8)the value of a store(struct S)
  didn't match the lvalue type: Specified((struct S){.a= {7, 8}})")` rc 125 — the STORE-side
  consult (`core_run.lem:544` `memValueFromValue (Ctype [] (unatomic_ ty)) cval` on the store
  into the parameter temporary) rejects the incompatible value; `name-arg` likewise rc 125;
  `arr-2-2-arg` → `Defined {value: "Specified(7)"}` rc 0. Compatibility IS load-bearing on the
  argument path under that switch, and the typo repair is observable there (an incompatible
  value is now rejected where the typo accepted it).

Consequences [AGENT]: the typo repair is correct and observable (RETURN path: `arr-1-2-return`
rejected, `arr-2-2-return` / `arr-incomplete-ptr-return` accepted — the selection consult is
compatibility-aware; the unit pins above), and draft 38's reproducer runs to gcc's value on
both fork engines. But the charter's classification of the by-value ARGUMENT shape as a
NEGATIVE case rested on `core_run.lem:968-970` being a consult site in matched mode, which it
is not — a finding the operator/orchestrator should see before anything is PINNED: which
argument-shape row (if any) belongs in a lane corpus, and as what, is their call. Per the
stop rule: the `.lem` change is brought to its own gate and committed (this commit); the
corpus/lane pin — `tests/multi_tu_tray/`, LADDER row 6b, any failure-text projection — is
NOT made, and D4/D5 are NOT started.

### D3(g) — the 60-second lane-classification TRIAL (run as chartered, BEFORE any LADDER edit; observation only — no pin followed)

```
$ ./scripts/test_multi_tu.sh .tmp/d3/cases        # 03:36:37Z → 03:36:41Z
[1] MATCH arr-1-2-arg: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[2] MISMATCH arr-1-2-return:
    ocaml: ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id(\"S\")) vs Symbol(502, SD_Id(\"S\"))'"}
    lean:  ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(63, SD_Id(\"S\")) vs Symbol(19, SD_Id(\"S\"))'"}
[3] MATCH arr-2-2-arg: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[4] MATCH arr-2-2-return: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[5] MATCH arr-incomplete-ptr-return: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[6] MISMATCH fam-vs-array-return:
    ocaml: ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(533, SD_Id(\"S\")) vs Symbol(502, SD_Id(\"S\"))'"}
    lean:  ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(50, SD_Id(\"S\")) vs Symbol(19, SD_Id(\"S\"))'"}
[7] MATCH node: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=7 match=5 fail=2
rc=1
```
[AGENT] As the charter's §1 (ii) said: the `Defined` cases are `MATCH` under the `full`
projection; the two `Error` cases are `MISMATCH` on symbol numbers alone. Had the pin gone
ahead, `node`, `arr-2-2-*`, `arr-incomplete-ptr-return` would have been row-6b `MATCH` cases
and the two `Error` cases would have needed the opt-in failure-text symbol projection. The
projection was NOT implemented (the stop precedes it); `observations.py`, `test_multi_tu.sh`,
`LADDER.md` row 6b and `tests/multi_tu_tray/` are untouched.

### D3(f) — fork-drift manifest (gate-observed hashes; exactly the enumerated hunks)

Four gate runs (evidence file): (1) before any manifest edit — `check_fork_content: FAIL —
source-content drift inside reviewed file(s): frontend/model/core_eval.lem: expected ('100644',
'e1fc98ed…'), actual ('100644', '4ade27ce…'); frontend/model/ctype_aux.lem: expected ('100644',
'5a657d68…'), actual ('100644', 'd7e2ece8…')`; (2) after the two source rows moved —
`check_fork_drift: FAIL — generated-tree differing-file set drifted from the manifest. ---
differing now but not excused (NEW OCaml-token drift): core_eval.ml`; (3) with a placeholder
`[expected-semantic]` row for `core_eval.ml` — `core_eval.ml: excused-diff hash moved (manifest
0000…, live 1b3c441a…)`, `ctype_aux.ml: excused-diff hash moved (manifest afcc21e3…, live
977ee22d…)`; (4) final:
```
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 23 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 …)
```
Hunks: `[source-content]` `frontend/model/core_eval.lem` `e1fc98ed… → 4ade27ce…`,
`frontend/model/ctype_aux.lem` `5a657d68… → d7e2ece8…`; `[expected-semantic]` `ctype_aux.ml`
`afcc21e3… → 977ee22d…` and NEW `core_eval.ml 1b3c441a…` (layer 2: 22 → 23); one dated 8-line
header note. No other hunk.


### D3(d)/(e) — the gate for the `.lem` change: Tier A green, zero movement, partition unchanged (verbatim; full file `…-evidence/d3-gate-verdicts.txt`)

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d3-fast   # 03:41:01Z → 03:47:51Z
RUN A1: ./scripts/test_unit.sh
PASSED A1
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6
RUN A7: ./scripts/test_parse.sh
PASSED A7
RUN A8: ./scripts/test_core.sh
PASSED A8
RUN A9: ./scripts/test_elab.sh
PASSED A9
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
rc=0
Total: 9 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 23 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
A2: Baseline check: 0 regression(s), 0 improvement(s)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
A6: SUMMARY: total=2 match=2 fail=0
A11: BASELINE OK (213 entries, exact match)
$ ./scripts/test_unit.sh        # direct, 03:47:51Z → 03:50:17Z
Total: 9 passed, 0 failed       (same partition / fork-drift (layer 2 = 23) / failure-reach / axiom lines)
rc=0
$ ./scripts/test_immaculate.sh  # Tier B, after the D3 build
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
rc=0
$ ./scripts/test_verify.sh      # Tier B row 4
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
rc=0
```

[AGENT] Zero movement in every Tier A lane and in the two Tier B lanes run (immaculate: its 5
NEW rows from D1b/D2 hold and no existing row moved; verify 127/127); the two `tests/multi_tu/`
cases pass (A6); fuel partition unchanged (81); failure-reach unchanged (233); no Lean signature
changed (`step_eval_pexpr`'s and `are_compatible0`'s types are as before; the arm body changed
inside). The remaining Tier B lanes (gcc full `--check-baseline`, libxml2, csmith, pristine
lane, …) are D5's, which is not started.

## State at hand-over (resumption STOP after D3's first commit, per charter §3)

Done and committed on `arc/semantics-audit-repairs` in this resumption (on top of D0
`dbdf36a5e`, D1 `c807ce603`, the resumption note `c7dd0ba29`):

* **D1b** (`146179d24`) — ISO-fix register R5: VALIDATION §2 row, `CerbFloat.lean` marker, the
  immaculate pin `r5-hex-subnormal-double-rounding` (DIFF, L=Specified(1)) + gcc row (AGREE),
  trays `ocaml/README.md`, `ocaml/01-…`, main-tray 40 + INDEX row and `ocaml/` pointer, unit pin
  annotated, LADDER row 1 `8/8`.
* **D2** (`a43abba65`) — the byte-preserving Cabs bridge: `json_of_bytes` at the three byte
  sites, `getByteStr` fail-closed importer, note Z2-J-02 corrected, 5 `tests/minimal` + 4
  immaculate files with NEW baseline rows (exec +5, immaculate +4, gcc +9), the bridge probe
  in `test_parse.sh` (RED pre-D2 / GREEN post-D2), 106 D0 cabs-json hashes unchanged, manifest
  row moved, Tier A green.
* **D3, first commit** (this commit) — the two `.lem` edits, both engines rebuilt, no proof
  edit needed, unit exe `are-compatible-test` (8 pins), manifest: 2 source rows + `ctype_aux.ml`
  moved + `core_eval.ml` ADDED (layer 2 = 23), Tier A green with zero movement, immaculate +
  verify green; the three-engine table for 7 cases + 2 probes; the 60-second lane trial run
  and recorded (5 MATCH / 2 MISMATCH on symbol numbers).

NOT done, by the stop rule (charter §3, "a NEGATIVE D3 case completes `Defined` on the fixed
fork"): **D3's second commit** (the corpus/lane pin — `tests/multi_tu_tray/`, LADDER row 6b, the
opt-in failure-text symbol projection in `observations.py`/`test_multi_tu.sh`); **D4** (tray 39,
draft 38's fork-status section, INDEX rows 38/39, `node_a.c` header, TODO/VALIDATION edits,
LADDER `test_release.py` check, the negative-zero side-finding draft); **D5** (the full A + B
battery and the record's final tallies). `scripts/observations.py`, `scripts/test_multi_tu.sh`,
`scripts/LADDER.md` row 6b, `tests/multi_tu/`, `scripts/upstream_oracle_differences.json`,
`docs/upstream-tray/38-*.md`, `TODO.md`, `VALIDATION.md` (beyond the R5 row) are untouched.
The scratch corpus `.tmp/d3/cases` is ephemeral; its files are quoted in full in
`…-evidence/d3-reproducers-observed.txt`, so the next worker re-derives it from there.

### Open questions for the orchestrator / operator (priority order)

1. **The STOP finding — the by-value ARGUMENT path is not a compatibility consult in matched
   mode** (`core_run.lem:962-970`: without `SW_inner_arg_temps` the argument is a pointer to a
   caller temporary; `memValueFromValue`'s `Struct` arm is dead there). `arr-1-2-arg` and even
   `{int a}` vs `{int b}` passed by value complete `Specified(7)` on BOTH fork engines and on
   pristine; under `--switches=inner_arg_temps` the fixed fork rejects them (uncaught `Failure`,
   exit 125, at the store-side consult `core_run.lem:544`) and accepts the compatible twin.
   Decision needed: (a) which argument-shape row(s), if any, go into a lane corpus and as what
   (a `MATCH Defined 7` row would pin the offset-0 read as behaviour); (b) whether the
   `inner_arg_temps` observation deserves a tray note (the store-side rejection is an uncaught
   exception rather than a diagnostic — a crash class); (c) whether the charter's D3(c)
   "negative, passed by value" shape is simply withdrawn. The RETURN-path rows are
   unambiguous and ready to pin (`node`, `arr-2-2-return`, `arr-incomplete-ptr-return` as
   `Defined 7` MATCH; `arr-1-2-return` and `fam-vs-array-return` as `Error` rows needing the
   symbol projection).
2. **The union twin** — `core_eval.lem`'s `OVunion` arm and `core_aux.lem:204-208` keep exact
   tag identity; a `union U { int v; … }` defined in two TUs, a `union U` value returned across
   them and member-selected, would fail `PEmemberof(union) ==> mismatched tags` (draft 38's
   shape with `union`); not reproduced in this run (fence).
3. **`fam-vs-array-return`** — `struct S {int n; int a[];}` vs `struct S {int n; int a[2];}`
   is INCOMPATIBLE on both engines (member-count comparison; the FAM lives outside the member
   list). Is that the authors' intent under §6.2.7#1? gcc links and runs it (7). Not changed;
   a tray/ISO question.
4. **The failure-text symbol projection** — not implemented (the stop precedes D3(g)'s pin);
   the trial shows it is needed for the two `Error` rows if they are pinned in a lane.
5. **`scripts/test_immaculate.sh`'s OK line** enumerates the register pins R1–R3 only; R5 is
   now a fourth pinned non-MATCH row (outside this slice's fence; a one-line message edit).
6. **D2 residual** — attribute-argument strings (`cabs_json.ml:600/602`, built from string
   literals by `c_parser.mly:1780-1785`) and `EDecl_magic` text (`:657`) stay `json_of_string`
   per the charter's shape; a raw byte ≥ 0x80 there would still make the JSON non-UTF-8 —
   fail-NOISY on the Lean side (`readFile` refuses), never silent. Should they become
   byte-carriers too, or is annotation text the right class?
7. **gcc lane rows added in D1b/D2** (1 + 9) were observed in subset runs (`--check-baseline` is
   full-corpus only); D5's full `--check-baseline` is the confirming observation. Their O2
   column follows the lane's stride rule (derived; `108` printed `O2_AGREE` in the subset run).
8. **INDEX numbering** — draft 40 exists (R5, Cerberus-facing); 39 is reserved for D4's
   array-bound-typo draft, which is not written. The INDEX row for 40 says so.
9. **The panic message rendering** — Lean's `CerbDecode` panic on a raw high byte prints the
   byte-carrier `Char`s through the text path (`Ã`), the oracle prints OCaml `\195`; message
   text, not a verdict — noted, not a defect claim.

---

# Second resumption (2026-09-15) — D3 second commit → D4 → D5

Worker: Claude (Fable 5.1) [AGENT], resuming at `15dd162e9` (the orchestrator's second
resumption note, charter §8) on top of D3's first commit `dbe633ec5`. Pre-flight, verbatim:
`check_driver_fresh: oracle OK (bin e40ae8e3853b75b0b45792507d0af2ff2d9332ceaa503a2b130d3b733043392e, src 19de18ed…)`,
`check_driver_fresh: lean OK (bin e36af96d9eed60cfac55414d675d354edff4268b0bdfad6031c121137dc3be84, src a0ed1133…)`,
pristine manifest top-level `status: built` (`artifacts.oracle.path = …/independent-oracle-v2/cerberus/_build/default/backend/driver/main.exe`),
`git status --porcelain` empty. Charter §0–§8 read in full; where §7/§8 disagree with
§0–§3, §7/§8 were followed. The scratch corpus `.tmp/d3/cases` no longer existed; the seven
cases were rebuilt from the record's verbatim sources (`…-evidence/d3-reproducers-observed.txt`).

## D3 — second commit: the corpus/lane pin (charter §8 items 1–2) — DONE

### The corpus `tests/multi_tu_tray/` (NEW; §8 item 1)

Seven case directories, each `tu1.c` + `tu2.c` (linked in sorted order, as the trial),
code lines byte-identical to the record's verbatim sources plus a leading comment block per
file naming the case, its classification and `../README.md`: `node`, `arr-1-2-return`,
`arr-1-2-arg`, `arr-2-2-return`, `arr-2-2-arg`, `arr-incomplete-ptr-return`,
`fam-vs-array-return`. `README.md` carries: why the root is separate from `tests/multi_tu/`
(the pristine lane enumerates that directory and fails on a timeout; the cases move there
when upstream fixes drafts 37/38/39); the projection paragraph; a per-case classification
table — `node`, `arr-2-2-return`, `arr-incomplete-ptr-return` positive/compatible `Defined 7`;
`arr-1-2-return` NEGATIVE, incompatible, rejected — the load-bearing pin of the repair;
`fam-vs-array-return` rejected on all three engines, incompatibility by member count (draft
41); `arr-1-2-arg`, `arr-2-2-arg` OBSERVED MODELLING LIMIT — with §8 item 1's sentence quoted
verbatim in its own section, the `core_run.lem:962-970` mechanism and the `inner_arg_temps`
observation; and the record's three-engine table (D3(b)/(c)) verbatim, including the two
probe rows, with a note that its "NEGATIVE" label on the argument row is the charter's
ORIGINAL classification, withdrawn in §8.

**The committed files re-observed on all three engines + gcc BEFORE any lane edit**
(`…-evidence/d3-tray-observed.txt`, verbatim, fork bin `e40ae8e3…`, pristine =
independent-oracle-v2, `LC_ALL=C NO_COLOR=1 TERM=dumb`, 60 s timeouts): every row reproduces
the record's table — same verdict, same rc, same symbol numbers (fork `545/502`, `558/502`,
`536/502`, `533/502`; Lean `63/19`, `50/19`); pristine `node` `rc=124`; gcc exit 7 on all
seven (`fam-vs-array-return` with gcc's FAM-ABI note on stderr). [AGENT] The added comment
lines changed no symbol number, as expected (symbols are per declaration).

### The projection (§8 item 2) — `scripts/observations.py`, opt-in `failure-class`

`Observation.tokens('failure-class')`: for `Error` and `Undefined` verdicts, every payload
field has `SYMBOL_NUMBER = re.compile(rb'Symbol\([0-9]+, ')` substituted by `Symbol(_, `,
then the ordinary `token()`; `Defined`, `InternalError` and `ModelFailure` verdicts are their
`full` tokens byte for byte; `values`/`pin`/`full` are untouched; an unknown projection still
raises `ProtocolError`. `--projection` gains the choice `failure-class` (help text names row
6b). The module docstring states what the projection is, that it exists for LADDER Tier A
row 6b only, and that applying it to an existing row is forbidden (charter §3).

Unit plants (`scripts/test_observations.py`, new
`test_failure_class_projection_elides_symbol_numbers_and_nothing_else`, runs inside
`test_unit.sh` and so in Tier A row 1) — with the lane's two verbatim `arr-1-2-return`
tokens (oracle 545/502, Lean 63/19): `full` and `values` tokens differ, `failure-class`
tokens are equal and equal to the expected elided token; PLANTS — the tag NAME `S`→`T`, the
arm `struct`→`union`, the description `SD_Id`→`SD_None` each still DIFFER under
`failure-class`; a `Defined` token spelling `Symbol(7, x)` in stdout is unchanged and its
`7`→`8` twin differs; an `Undefined` payload IS projected (`Symbol(9, SD_None)` ≡
`Symbol(10, SD_None)` → `Symbol(_, SD_None)`); a mixed sequence is projected per verdict;
`Symbol(545,` without the space is NOT rewritten; the CLI accepts the choice and prints the
same token. [AGENT] Fence reading: `scripts/test_observations.py` is the codec's unit-test
file and D3(g) requires the projection "unit-tested both directions with a plant"; the fence
item `scripts/observations.py` is read to include its test file. Verbatim:
```
$ python3 scripts/test_observations.py
Ran 23 tests in 0.260s
OK
```

### `scripts/test_multi_tu.sh` — the flag `--failure-class-projection` (D3(g) only)

`PROJECTION=full` by default; the flag sets `failure-class`; both `observation_tokens`
calls pass `--projection "$PROJECTION"` (the codec's default IS `full`, so the default path is
unchanged); the banner prints `PROJECTION: full (complete verdict tokens)` or the labelled
opt-in line; usage and header document it. No other script passes the option (grep below).

### LADDER Tier A row 6b — and `test_release.py` accepting the ladder

Row `6b` = `` `./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray` ``
with the Bar cell naming the tray, drafts 37/38/39, the two observed modelling-limit rows and
the WEAKER PROJECTION label ("this row only … every other lane row keeps `full`"). Verbatim:
```
$ python3 scripts/test_release.py        # test_real_membership_expands_every_documented_command parses the REAL LADDER
Ran 16 tests in 3.296s
OK
$ python3 scripts/release.py --list | grep A6
A6      ./scripts/test_multi_tu.sh
A6b     ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray
```

### Lane runs, plants and the grep (all verbatim in `…-evidence/d3-tray-lane-and-plants.txt`)

```
$ ./scripts/test_multi_tu.sh tests/multi_tu_tray        # NO flag: full projection (the trial, re-run on the committed files)
PROJECTION: full (complete verdict tokens)
[2] MISMATCH arr-1-2-return:
    ocaml: ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id(\"S\")) vs Symbol(502, SD_Id(\"S\"))'"}
    lean:  ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(63, SD_Id(\"S\")) vs Symbol(19, SD_Id(\"S\"))'"}
[6] MISMATCH fam-vs-array-return:   (same shape, 533/502 vs 50/19)
SUMMARY: total=7 match=5 fail=2
rc=1
$ CERB_OBSERVATION_DIR=.tmp/d3b/obs ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray        # LADDER row 6b
PROJECTION: failure-class (OPT-IN, LADDER Tier A row 6b only) — Symbol(<digits>, elided to Symbol(_, inside Error/Undefined payloads; Defined tokens full
[1] MATCH arr-1-2-arg: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[2] MATCH arr-1-2-return: 1 execution(s), ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(_, SD_Id(\"S\")) vs Symbol(_, SD_Id(\"S\"))'"}
[3] MATCH arr-2-2-arg: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[4] MATCH arr-2-2-return: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[5] MATCH arr-incomplete-ptr-return: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[6] MATCH fam-vs-array-return: 1 execution(s), ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(_, SD_Id(\"S\")) vs Symbol(_, SD_Id(\"S\"))'"}
[7] MATCH node: 1 execution(s), VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=7 match=7 fail=0
ALL PASSED
rc=0
$ ./scripts/test_multi_tu.sh        # LADDER row 6 (default corpus) — unchanged, full projection
PROJECTION: full (complete verdict tokens)
[1] MATCH basic: 31 execution(s), VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
[2] MATCH tentative: 1 execution(s), VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=2 match=2 fail=0
rc=0
```

Lane-level plants on the row-6b run's KEPT captures (case 2 = `arr-1-2-return`, case 1 =
`arr-1-2-arg`), verbatim results: PLANT A — `observation_tokens 2.oracle/2.lean --projection
full` differ (545/502 vs 63/19), `--projection failure-class` equal → `PLANT A (symbol-only
difference → equal under failure-class): EQUAL`; PLANT B — a copy of `2.lean` with the second
tag NAME `S`→`T` in `.stdout` → `ERR:{msg: "… Symbol(_, SD_Id(\"S\")) vs Symbol(_, SD_Id(\"T\"))'"}`,
`PLANT B (real payload difference under failure-class): DIFFER — MISMATCH preserved`; PLANT C
— a copy of `1.oracle` with `Specified(7)`→`Specified(8)` → `PLANT C: failure-class token ==
full token for a Defined verdict` / `PLANT C: value difference DIFFERs under failure-class`.

Grep (verbatim in the evidence file): the FLAG / the codec OPTION
(`failure-class-projection` | `projection failure-class` | `'failure-class'` |
`--projection "$PROJECTION"`) occurs ONLY in `scripts/LADDER.md`, `scripts/observations.py`,
`scripts/test_multi_tu.sh`, `scripts/test_observations.py`, `tests/multi_tu_tray/README.md`
and the charter; `grep -rn projection scripts/*.sh` shows every other lane's projection use
unchanged (`speclab_observations.sh`/`test_verify.sh` `pin`, `test_ci_sweep.sh`/
`test_gcc_oracle.sh` `values`). The bare phrase "failure-class" also occurs as prose in five
older docs/READMEs ("coarse failure-class pin") — not the flag.

[AGENT] Observation during this step: the oracle BINARY stamp moved once — `oracle OK (bin
e40ae8e3…, src 19de18ed…)` at pre-flight and for the three-engine re-observation; after the
first lane's `build_cerberus` (04:07:13Z) `oracle OK (bin 89a899c5…, src 19de18ed…)`; a
further `build_cerberus` left it at `89a899c5…`. Same SOURCE hash (`19de18ed…`), a dune
relink of `main.exe` with no source change (no OCaml file is modified: `git status` shows
only the fence); both binaries gave identical verdicts on all seven cases (evidence files).
Not a stop event; recorded so the stamp history reads correctly.

Not edited (outside the fence; open questions below): `lean_frontend/docs/2026-09-05_observation-contract.md`'s
comparison matrix (a row for row 6b's labelled projection belongs there) and
`scripts/test_observation_lanes.py` (its multi-TU plants run the DEFAULT `full` path, which is
unchanged).

### The gate for the second commit — Tier A green with zero movement (verbatim; full file `…-evidence/d3b-tierA-verdicts.txt`)

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d3b-fast   # 04:11:21Z → 04:18:10Z
RUN A1: ./scripts/test_unit.sh
PASSED A1 (145.0s)
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2 (27.4s)
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c (3.0s)
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5 (21.4s)
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6 (2.1s)
RUN A6b: ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray
PASSED A6b (3.5s)
RUN A7: ./scripts/test_parse.sh
PASSED A7 (10.1s)
RUN A8: ./scripts/test_core.sh
PASSED A8 (8.7s)
RUN A9: ./scripts/test_elab.sh
PASSED A9 (16.3s)
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10 (16.4s)
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11 (57.2s)
fast: passed; 14/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
rc=0
A1: Total: 9 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 23 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
A1 (test_observations.py, inside test_unit): Ran 23 tests in 0.256s / OK      # the new projection plant included
A1 (test_release.py, inside test_unit):      Ran 16 tests in 3.176s / OK      # the real LADDER with row 6b parses
A2: SUMMARY: total=111 match=90 ub_match=18 … / Baseline check: 0 regression(s), 0 improvement(s)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: SUMMARY: total=93 match=93 … / Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
A6: PROJECTION: full (complete verdict tokens) / SUMMARY: total=2 match=2 fail=0
A6b: PROJECTION: failure-class (OPT-IN, LADDER Tier A row 6b only) — Symbol(<digits>, elided to Symbol(_, inside Error/Undefined payloads; Defined tokens full
     [2] MATCH arr-1-2-return: 1 execution(s), ERR:{msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(_, SD_Id(\"S\")) vs Symbol(_, SD_Id(\"S\"))'"}
     SUMMARY: total=7 match=7 fail=0 / ALL PASSED
A7: batch diagnostic producers: 8/8 passed / cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
A11: BASELINE OK (213 entries, exact match)
$ ./scripts/test_unit.sh        # direct, → 04:20:54Z
Total: 9 passed, 0 failed       (same partition 81 / fork-drift layer 2 = 23 / failure-reach 233 / axiom / parametricity lines; test_observations 23 OK; test_release 16 OK)
rc=0
```

[AGENT] Zero movement in every existing lane row (A2/A3/A4/A4b `0 regression(s), 0
improvement(s)`; A5 12/0; A6 2/2; A11 213 exact); the NEW row A6b is 7/7 MATCH under the
labelled projection; every gate line is identical to the D3 first commit's. No Lean source, no
`.lem`, no manifest and no baseline file changed in this commit (the Lean/OCaml sources are those
of `dbe633ec5`; stamps `oracle OK (bin 89a899c5…, src 19de18ed…)` / `lean OK (bin e36af96d…)`).
Files in this commit: `tests/multi_tu_tray/**` (7 cases + README, NEW), `scripts/observations.py`,
`scripts/test_observations.py`, `scripts/test_multi_tu.sh`, `scripts/LADDER.md` (row 6b), this
record, evidence `d3-tray-observed.txt`, `d3-tray-lane-and-plants.txt`, `d3b-tierA-verdicts.txt`.

## D4 — Tray, registers, stale documents (charter D4 + §8 items 3–8) — DONE

1. **Draft 39** — NEW `docs/upstream-tray/39-are-compatible-array-bound-typo.md`: TRUE BUG /
   minor; Affected `ctype_aux.lem:80` (upstream `b9aeedcb4`, the arm quoted); the one-token
   remedy; the `arr-1-2-return` reproducer with its compatible twins and the three-engine
   runs verbatim (from `…-evidence/d3-tray-observed.txt`); what the typo ALONE does stated as
   READ from the source (the fork fixed both defects in one commit); the unit pins; "file
   together with 37 and 38". Two "Related observations" (§8 item 3): the default-switch-set
   argument path consults no compatibility (`core_run.lem:947-950` upstream = fork
   `:964-967`; `arr-1-2-arg` `Specified(7)` on every engine), and under
   `--switches=inner_arg_temps` the store-side consult (`core_run.lem:527` upstream = fork
   `:544`) rejects with an uncaught `Failure` exit 125 (verbatim from
   `…-evidence/d3-reproducers-observed.txt`). Fork-status section: FIXED at `dbe633ec5`.
   **Draft 38** gains a "Fork status (2026-09-15)" section like 37's: the `.lem` hunk, the
   union arm left as the twin, the `node` three-engine runs verbatim (fork `Specified(7)` rc 0
   / Lean same / pristine `rc=124` / gcc 7) and the twins' verdicts. **INDEX.md**: row 38 +
   FORK STATUS paragraph; NEW row 39 (slotting note: ranks with 37/38, file together); the
   "Added 2026-09-15" paragraph rewritten to carry the §8 item 8 numbering (39/40/41/42);
   NEW rows 41 and 42 in the question tier after 40, each with a slotting note.
2. **`tests/failure-probes/cross_tu_node/node_a.c`** header comment rewritten (comment only;
   code lines untouched): history (draft 37 non-termination → fixed 2026-09-10; draft 38
   exact-tag rejection → fixed 2026-09-15 at `dbe633ec5`) and current state (both fork
   engines `Specified(7)`; pristine still `rc=124`; the same program is the lane case
   `tests/multi_tu_tray/node`).
3. **D1/D2 doc fixes confirmed in the tree:** `CabsImport.lean:31` "Z2-J-02 (CORRECTED and
   FIXED 2026-09-11, semantics-audit repairs D2 — …" states the both-fail claim false for
   non-decoding shapes and the byte-carrier convention; `CerbFloat.lean:104-105` "Any residual
   difference from the oracle is a BUG (VALIDATION.md §0–§1; the former "deliberate,
   documented divergence" …" — the D1 wording is gone. [AGENT] Two OTHER pre-existing
   "DELIBERATE" notes remain in `CerbFloat.lean` and are not D1's: `:40` (the upstream
   `Cerb_floating.mul = (+.)` bug, tray 01, FILED as issue 1009 — the Lean side is right) and
   `:343` (`-nan` printing). Left as they are; not in this slice's fence beyond the module
   comment.
4. **`TODO.md`**: NEW block "Semantics-audit repairs (2026-09-11) — RESOLVED findings and the
   rows they leave" (after "Queued larger work"): findings 4/3/5 + draft 38 RESOLVED with the
   commit shas and record pointer; the **union twin** row (§8 item 7) with the reproducer shape
   (`union U { int v; double d; }` in two TUs, `mk().v` across them → expected
   `PEmemberof(union) ==> mismatched tags`) and the remedy shape; the symbol projection status
   (implemented for row 6b only); the argument-path observed modelling limit; the FAM and
   unary-minus questions (drafts 41/42); the doc residuals outside the fence (observation
   contract matrix; tray README §4; `test_immaculate.sh` header comment; VALIDATION §2's R4
   sentence). **`VALIDATION.md`** — grep of `hex`, `UTF-8`, `non-ASCII`, `cross-TU`, `struct
   value`, `mismatched tags`, `multi_tu`: hits only at §2 R5 (correct), §5's lanes table
   (`test_multi_tu.sh | tests/multi_tu`) and two Tier-membership prose lists (still true).
   Three edits, before/after verbatim in `…-evidence/d4-validation-diff.txt`:
   - §3(b): ONE residual row inserted before "(c)" (§8 item 6), the charter's sentence with
     the site cites — "*Non-UTF-8 bytes in a TEXT field of the Cabs JSON* (magic-comment
     text, `EDecl_magic`, `cabs_json.ml:657`; attribute-argument strings, `:600/602` — WHOLE
     strings, `c_parser.mly:1771-1775` … ): … the bridge REFUSES the file loudly
     (`IO.FS.readFile`: "containing non UTF-8 data") where the oracle proceeds — a fail-noisy
     class-(b) residual on non-UTF-8 SOURCE TEXT, not on literals … Mover: an encoder
     decision for the text fields, a separate slice."
   - §5 lanes table: the stale enumeration (before: the single row `` `test_multi_tu.sh` |
     `tests/multi_tu` | multi-TU linking differential, all entries ``) gains the row for
     LADDER Tier A row 6b naming the LABELLED WEAKER projection and the two observed
     modelling-limit pins; the existing row is unchanged.
   - §9: after claim 5 (before "What remains on the trust boundary") — there is no
     blind-spot LIST in §9, so ONE paragraph was added: "Sampling has blind spots, and they
     are closed by dated records, never quietly: literal-level adversarial inputs (long
     hexadecimal mantissas, raw high bytes in string literals and character constants) were
     untested before 2026-09-11 — … (the corpora had one 21-character hexadecimal literal and
     no executed non-ASCII literal)."
5. **LADDER row 6b / `test_release.py`**: done and verified in the D3 second commit
   (`Ran 16 tests … OK` on the real LADDER; `release.py --list` shows `A6b`; `release.py
   --mode fast` ran it: `PASSED A6b (3.5s)`). No LADDER edit in D4.
6. **§8 item 6 — the per-byte condition, read BEFORE touching anything:** `c_parser.mly:1771-1775`
   `located_string_literal` builds `strs = List.map (fun (loc, s) -> (loc, String.concat "" s))
   (snd $1)` and `(loc, String.concat "" (List.map snd strs), strs)` — the literal's s-char
   fragments are CONCATENATED into one OCaml string per literal piece and again over the
   pieces; `cabs_json.ml:600` emits that whole string (`json_of_string s`) and `:602` each
   piece's whole string (`is`). The branch that holds is "**whole strings**": the attribute
   arguments are NOT emitted per byte/fragment like the literal fragments were. Therefore
   `cabs_json.ml`/`CabsImport.lean` are NOT touched; they stay TEXT, and the VALIDATION §3(b)
   residual row above records the consequence. `EDecl_magic` (`:657`) stays TEXT as directed.
7. **§8 item 5 — `test_immaculate.sh`'s OK line**: read first — it is an `echo` inside `if [[
   $rc -eq 0 ]]` (`:346-347`), a MESSAGE, not verdict logic (the verdict is the
   DEVIATION/MISSING accumulation above it). Edited the one line to add `, R5
   r5-hex-subnormal-double-rounding DIFF`. Lane re-run, verbatim:
   ```
   $ ./scripts/test_immaculate.sh
   OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
   rc=0
   ```
   (no DEVIATION/MISSING line; the header comment `:22-27` still lists R1–R3 — outside the
   one-line fence, noted in TODO.)
8. **Draft 41** — NEW `41-struct-flexible-array-member-vs-sized-array-compatibility-question.md`
   (§8 item 4; the 06/07 shape: Affected (for orientation) / Observation / Question for
   upstream / Impact / Proposed remedy / Classification / Provenance): the
   `fam-vs-array-return` three-engine runs verbatim; the mechanism (`ctype_aux.lem:117`
   member COUNT 1 ≠ 2; `ctype.lem:76-85` `StructDef … * maybe flexible_array_member`); the
   §6.2.7#1 / §6.7.6.2#6 / §6.7.2.1#18 question; UNCLEAR / QUESTION, minor; no fork change.
9. **Draft 42** — NEW `42-unary-minus-floating-zero-sign-question.md` (§6 side finding; §8
   item 8): Affected LOCATED — `translation.lem:1525-1554` (upstream; fork `:1530-1559`), the
   `A.AilEunary A.Minus e` arm elaborates a floating negation as `Caux.mk_op_pe C.OpSub
   zero_pe e'` with `zero_pe = Caux.mk_floating_value_pe Mem.zero_fval`, i.e. `0.0 − x`
   (`core_eval.lem:446` `OpSub -> FloatSub`; `impl_mem.ml:2519,2533`), so `−(+0) = +0`
   under IEEE subtraction where `negate` flips the sign; the four probes RE-OBSERVED on the
   three engines + gcc (`…-evidence/d4-negzero-three-engine.txt`, verbatim): `-z` (z = 0.0)
   and `-0x0p0` → `Specified(0)` on fork/pristine/Lean, gcc 1; controls `0.0 * -1.0` →
   `Specified(1)` everywhere, `-1.5` sign bit 1 everywhere. §6.5.3.3#3 quoted verbatim from
   `tools/n1570.json`; classification UNCLEAR / QUESTION, minor; the concrete model does not
   claim Annex F; no port change (both engines and upstream agree).
10. **§8 item 9 — the panic-message rendering**: Lean's `CerbDecode` panic on a raw high
    byte prints the byte-carrier `Char`s through the text path (`Ã`/`Ã©`) where the oracle
    prints OCaml's `\195\169` — message text inside a crash, class (a); recorded, no change.

Files changed by D4: `docs/upstream-tray/{39,41,42}-*.md` (NEW), `38-*.md`, `INDEX.md`,
`tests/failure-probes/cross_tu_node/node_a.c` (comment), `lean_frontend/TODO.md`,
`lean_frontend/VALIDATION.md` (3 hunks), `scripts/test_immaculate.sh` (1 message line), this
record, evidence `d4-negzero-three-engine.txt`, `d4-validation-diff.txt`. No Lean, `.lem`,
OCaml, baseline or manifest file changed.
