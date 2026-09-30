# Bug-hunt fixes, 2026-09-29/30: record

Branch `arc/bug-hunt-fixes` (worktree `worktrees/cerberus-lean-audit/bug-hunt-20260929`), base `86a01dbf9`.
Findings and options: [the bug-hunt record](2026-09-29_discrepancy-bug-hunt.md) (BUG-2..BUG-6, K-5).
Authority: [USER 2026-09-29] "Agree on everything, yes on the fixes". Implementation choices below are
[AGENT] unless marked otherwise; the slice list and the refusal choices (BUG-2's `OPAM_SWITCH_PREFIX`,
BUG-3's import-time refusal, BUG-6/K-5's refusal, BUG-5's stop-if-wide rule) are from the orchestrator's
brief under that ruling. Gate lines are quoted verbatim from the runs; derived tallies are labelled.

## S2: BUG-2 + BUG-3 (runtime location and library-location test)

### What changed

- `Main.lean`: the working-directory search `findRuntimeDir` is deleted. `resolveRuntime` mirrors
  `util/cerb_runtime.ml:38-56`: `--runtime DIR` / `--runtime=DIR` (the oracle's SPECIFIED arm,
  `backend/driver/main.ml:436-438`), else `CERB_INSTALL_PREFIX` (the ENV_VAR arm); runtime =
  `DIR/lib/cerberus-lib/runtime`, built with an OCaml `Filename.concat` mirror (`filenameConcat`), so the
  path strings are the oracle's. `std.core` and the `.impl` file are loaded from `<runtime>/libcore`
  exactly as `pipeline.ml:28-47` builds the paths (these are also the strings `CoreParser` stamps on the
  library nodes). A missing `std.core` (or `.impl`) is refused with the oracle's own wording
  ("couldn't find the Core standard library file (looked at: …)").
- **Deliberate divergences** (documented at `resolveRuntime`):
  - the oracle's OPAM arm (`OPAM_SWITCH_PREFIX`, or the build-tree source root found through `PATH`) is
    NOT mirrored; the run is refused (exit 2, `cerberus-lean: refused — runtime: …`) — per the brief: a
    shared switch's runtime can silently differ;
  - [AGENT] an EMPTY `--runtime`/`CERB_INSTALL_PREFIX` is refused: the oracle would resolve the relative
    `lib/cerberus-lib/runtime` against the working directory, the lookup BUG-2 removed.
- BUG-3: `CerbLocation.isLibraryLocation` stays a pure suffix test (it is a `target_rep` called from
  generated code); `dirname`, `libraryDirs` and the new `isLibraryPathSuffix` are public. At import,
  `Main.refuseLibraryLocations` refuses (exit 2, `refused — library-location classification: …`) any
  file path in the imported Cabs locations — user TUs AND the libc metadata TUs — that passes the suffix
  test and fails the oracle's exact test (`Filename.dirname path` ∈ `<runtime>/{libc/include, libcore,
  libcore/impls}`, `util/cerb_location.ml:512-523`). The file set is collected from the JSON by
  `CabsImport.positionFiles` (every `{"file","line","col"}` object) via the new
  `CabsImport.parseJsonWithFiles`. The two tests then agree on every accepted input: exact ⇒ suffix
  because the resolved runtime always ends in `/runtime`; suffix ⇒ exact by the refusal; the other
  file-carrying locations are the `std.core`/`.impl` stamps (exact by construction), and the `--libc`
  dump's bodies carry no file (`CoreParser.parseFile`, recorded Z1-A1). The docstring now states this;
  the old residual "Z-67" is retired.
- A consequence worth naming [AGENT]: every oracle cabs-json carries the `-include`d
  `<runtime>/libc/include/builtins.h` location, so a cabs-json exported under a DIFFERENT runtime prefix
  than the Lean run's is refused by the same check. This is a second guard against engine/runtime
  mismatch.
- Harnesses: `scripts/common.sh` exports `CERB_INSTALL_PREFIX="$PROJECT_ROOT/_build/install/default"`,
  the prefix every lane passes to the oracle (`run_cerberus`, each lane's `RUNTIME_DIR`). One mechanism
  covers every site of a harness that sources `common.sh` (census, derived: 93 grep hits for the Lean
  binary in 42 files; 6 shell files do not source `common.sh`). Those were updated explicitly:
  `check_cli_refusals.sh` (control passes `--runtime`), and the four standalone probe runners
  `tests/{z2,parity,noodle}-probes/…`, `tests/noodle-probes/dynamic-addrs/run_dynaddr.sh`,
  `tests/mem-scale-probes/measure.sh` (`--runtime="$RUNTIME"`, their oracle's). Python:
  `test_upstream_oracle.py` (Lean env gets the fork bridge's runtime) and `test_cabs_bytes_probe.py`.
  `test_exec.sh`, `test_cn_coverage.sh`, `test_ci_sweep.sh` now check that `CERB_INSTALL_PREFIX` equals
  their `RUNTIME_DIR` and its `std.core` exists (they checked `./runtime/libcore/std.core`). The
  "locates runtime/libcore relative to cwd" comments are corrected. The dated evidence scripts under
  `lean_frontend/docs/*-evidence/` are historical records and were not edited; re-run, they refuse
  loudly (no runtime).
- A site that is missed fails loudly: the driver's exit-2 refusal.
- `common.sh` is content-pinned in `scripts/fork_drift_manifest.txt`: single-row re-pin
  `0f02d01c… -> 3ef7b1ae…` with a dated NOTE (no oracle-source or generated-code change).
- Docs: README (batch usage), `lean_frontend/CLAUDE.md` (end-to-end usage, Main.lean row), VALIDATION
  §3(c) (two new refusal entries; accepted command line) and §6 (gate row), LADDER row 1.

### Witnesses

`scripts/check_runtime_resolution.sh --selftest`, wired into `test_unit.sh` (row 1). It runs the real
oracle (export + its own verdicts) and the Lean driver:
- control program (UB017, the bug hunt's `b6_ub2.c`): `--runtime=DIR`, `--runtime DIR` and
  `CERB_INSTALL_PREFIX` each give the oracle's line;
- a planted working directory with `runtime/libcore/std.core` whose UB017 arm returns `Specified(7)`:
  ignored, from that cwd, under both the flag and the variable;
- `--runtime` beats `CERB_INSTALL_PREFIX` (`cerb_runtime.ml:50-52` order);
- a planted PREFIX with the same `std.core`: Lean serves `Specified(7)` and the oracle, given the same
  prefix, serves `Specified(7)` too (the runtime is really used; non-vacuity);
- refusals: no runtime (from the planted cwd), `OPAM_SWITCH_PREFIX` alone, `--runtime=/nonexistent`,
  empty `CERB_INSTALL_PREFIX`, empty `--runtime`; a cabs-json exported under another prefix;
- BUG-3: a user file `user/runtime/libcore/liblocub.c`, `#line 1 "lib/runtime/libcore/gen.c"`, and a user
  header `runtime/libc/include/myhelp.h` all refuse; the same `liblocub.c` under `user/other/` gives the
  oracle's line (`<2:10--2:15>`).
- plants (`--selftest`): a stub that ignores the runtime and always prints the correct control line, and
  a stub that refuses everything, must both fail the witnesses.

Hand run before the gate existed (verbatim excerpt), planted cwd vs the real runtime:
```
--- from planted cwd
Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}
rc=1
```

### Gates (verbatim verdict lines)

Row 1, `scripts/test_unit.sh` (rc 0):
```
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_failure_reach: OK (230 pure failure sites = the 230 register rows exactly (228 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; …
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d…
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_cli_refusals: OK (3 refused flags pinned: --concurrency, --switches=PNVI_ae_udi, --switches=strict_pointer_arith; control not refused)
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 11 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 17 failing witness(es)
check_runtime_resolution: OK (17 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle)
```
(the `…` marks lines cut at 220 columns by the extraction, not by the gate.)

The first row-1 run failed `check_no_fuel_numerals --selftest` ("PLANT FAIL [green baseline]"): its
allowlist names the exact line `let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline runtimeDir …`, which a
rename had changed. The variable name was restored; the gate was not edited.

Lanes the slice touches (every Lean invocation), each rc 0:
```
test_immaculate.sh     OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_exec.sh --check-baseline   Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
test_multi_tu.sh       SUMMARY: total=8 match=8 fail=0 / ALL PASSED
test_libc_exec.sh      SUMMARY: match=43 diff=0 / ALL MATCH RECORDED BASELINE
test_verify.sh         test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
test_parse.sh          cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129) / ALL PASSED
test_elab.sh           SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
test_libxml2_uri.sh    GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
test_address_space.sh  test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
test_core.sh           Lean parse:     113 ok, 0 failed / ALL PASSED
test_bytes.sh          SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
test_cn_coverage.sh --check-baseline   SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 / BASELINE OK (213 entries, exact match)
```
(Lane name column and `/` joins added; the verdict text is verbatim.)

## S3: BUG-6 + K-5 (non-UTF-8 bytes in the Cabs JSON)

### What changed

- `Main.lean`: every Cabs JSON the driver reads — the input files, `--stdin` (now read as bytes, not by
  `getLine`), and the libc metadata TUs — is read with `IO.FS.readBinFile` and decoded by
  `decodeCabsJson`. A document that is not UTF-8 is REFUSED (exit 2):
  `cerberus-lean: refused — non-UTF-8 Cabs JSON: <input> is not valid UTF-8 (first invalid byte at
  offset N, context "…")`, followed by the feature and the boundary: the exporter copies bytes ≥ 0x80 of
  a file name (real path, `#line`, `#include`; `cabs_json.ml:30`), of a `Loc_other` string (`:44`) and of
  attribute-argument / magic-comment text (`:599`/`:601`, `:657`) raw, and Lean strings are Unicode
  scalar values. It used to die with `uncaught exception: Tried to read file '…' containing non UTF-8
  data.` (rc 1): loud but not attributed. The offset/context come from a small RFC 3629 scanner
  (`firstInvalidUtf8`, diagnostic only; the decision is `String.fromUTF8?`'s).
- VALIDATION §3: the class-(b) row "Non-UTF-8 bytes in a TEXT field of the Cabs JSON" is replaced by a
  §3(c) refusal entry that also lists the file-name and `Loc_other` members; §6 gets the gate row; LADDER
  row 1 names the witnesses.
- No mirror of the oracle's answer is possible here without a byte-carrier encoding of those fields
  (the bug hunt's option (a), named as the mover); the brief chose the refusal (option (b)).

### Witnesses

`scripts/check_cabs_json_utf8.sh --selftest`, wired into `test_unit.sh` (row 1). Each witness exports
the program with the real oracle, asserts the JSON is NOT UTF-8 and that the oracle itself gives a
verdict, then requires the attributed exit-2 refusal: `#line` with a raw 0xE9 (`b4_ln01`), `#line` with
the octal escape `\351` (`b4_s15`), a real file name `caf<0xE9>.c`, an `#include` of `inc/h<0xE9>.h`,
and `[[gnu::deprecated("caf<0xE9>")]]` (K-5, `b4_at01`). Four ASCII controls must equal the oracle's
line. Immaculate rows cannot express a Lean refusal against an oracle answer (the lane's tokens are
verdict lines), so the witnesses are row-1 checks, as the brief allowed. Run against the pre-S3 binary
the script failed exactly the five witnesses (each `got rc=1: uncaught exception: Tried to read file …`)
and passed the controls. Plants: a stub reproducing the pre-fix uncaught exception and a
refuse-everything stub both fail it.

Hand run (verbatim, path shortened to `…`):
```
cerberus-lean: refused — non-UTF-8 Cabs JSON: .tmp/s2/x.sC67/a.json is not valid UTF-8 (first invalid byte at offset 86764, context "gion\",\n          \"begin\": { \"file\": \"caf\233.c\", \"line\": 1, \"col\": 1 },\n          \""). The oracle's --cabs-json exporter copies the bytes ≥ 0x80 of a file name (the real path, a #line or an #include name), of a Loc_other string and of attribute-argument or magic-comment text into the JSON raw (backend/lean_export/cabs_json.ml:30, :44, :599/:601, :657); this port's bridge cannot carry them, because Lean strings are sequences of Unicode scalar values (string-literal and character-constant bytes are byte-carriers and unaffected; see VALIDATION.md §3(c), bug hunt BUG-6/K-5)
rc=2
```
(`\233` is `CerbEscape`'s decimal escape of the byte 0xE9.)

### Gates (verbatim verdict lines)

Row 1, `scripts/test_unit.sh` (rc 0):
```
Total: 16 passed, 0 failed
check_runtime_resolution: OK (17 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle)
check_cabs_json_utf8: selftest plant 'uncaught' caught: 9 failing witness(es)
check_cabs_json_utf8: selftest plant 'refuse-all' caught: 9 failing witness(es)
check_cabs_json_utf8: OK (9 witnesses: 5 non-UTF-8 Cabs JSONs refused with the attributed message (#line raw byte, #line octal escape, real file name, #include name, attribute string); 4 ASCII controls agree with the oracle)
```
Lanes touching the input read path, each rc 0:
```
test_parse.sh          cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129) / ALL PASSED
test_immaculate.sh     OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_exec.sh --check-baseline   Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
test_multi_tu.sh       SUMMARY: total=8 match=8 fail=0 / ALL PASSED
test_libc_exec.sh      SUMMARY: match=43 diff=0 / ALL MATCH RECORDED BASELINE
test_verify.sh         test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```
