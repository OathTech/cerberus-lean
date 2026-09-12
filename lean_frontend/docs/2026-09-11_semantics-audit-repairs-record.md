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
