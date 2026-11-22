# The implementation profile is a parameter: plain `char` signedness selectable on both engines — slice record (2026-11-22)

Branch `arc/impl-profile`, base mainline `77229f846`. Charter `2026-11-22_worker-charter-impl-profile.md`; scoping
`2026-11-20_impl-profile-scoping.md` (its option (b) is what was built). Worker: Claude Fable 5.2 (agent). Decisions
no ruling covers are marked [AGENT]. Quoted machine output is verbatim; counts marked "derived" are mine. Commits:
S1 `0c3817aef`, S2 `1c1ac30c4`, S3 `44a206e0b`; the pre-merge review `987c2c51c`
(`2026-11-22_impl-profile-premerge-review.md`, with its dispositions); the dispositions' code and witnesses
`901ec9c03` and their documents in the commit after it. **Section 7 records what changed after the review; where
sections 1 to 6 said something the review showed to be wrong they are corrected in place and say so.**

## 0. Rulings

[USER 2026-11-22]: start now; execution under unsigned plain `char` is made consistent by fixing upstream's start-up
binding in the fork (a fork-ahead fix with a tray report), neither refused nor mirrored; the second configuration is
validated by a witness lane alone. [AGENT 2026-11-22, orchestrator] (the charter): the selector is upstream's profile
name (`default`, `hafnium`); the default stays `DefaultImpl` with every baseline, pin and digest byte-identical; the
class is named for the implementation and carries today's one differing field; the second configuration is
consumer-configured and covered by the witness lane only; the pristine-oracle gate does not cover it; `--impl` (the
Core `.impl` file), Morello/CHERI and contract D6 are untouched.

## 1. What exists now

One configuration value, a property of the RUN, in the types on the Lean side, selected once at the entry point of
each engine:

| | Lean | OCaml |
|---|---|---|
| The value | `class CerberusImpl.ImplProfile where char_is_signed : Bool`; plain values `CerberusImpl.defaultImpl` (signed) and `CerberusImpl.hafniumImpl` (unsigned); no instance declared in the repository | upstream's `Ocaml_implementation` record, `DefaultImpl.impl` / `HafniumImpl.impl`, unchanged |
| Driver selector | `cerberus-lean --impl-profile=default\|hafnium` (both spellings), builds the run's instance | `cerberus --impl-profile=default\|hafnium` (fork-only), calls upstream's `set` before any phase |
| In process | `letI : CerberusImpl.ImplProfile := CerberusImpl.hafniumImpl` around the calls, or `@f CerberusImpl.hafniumImpl …` | `Ocaml_implementation.(set (HafniumImpl.impl))` once, before `load_core_stdlib` (RefinedC's `cerb_wrapper.ml:44`) |
| Unknown name | REFUSAL, exit 2 | refused, exit 2 |
| Cabs JSON | unchanged: `CabsImport.parseJson*` take no instance | unchanged: the export is byte-identical under the two profiles and records none (S2 added an `impl_profile` field and an import guard; both REMOVED after the review, section 7) |

The phases that read that one value (an earlier text said "every phase"; the preprocessor and the parser do not,
section 7): the character-constant decoder (`CerbDecode.wrapChar`), Ail typing and the
desugarer's constant evaluation (`Implementation.is_signed_ity` / `precision_ity` / `integerImpl ()`), the
elaboration's and Core's signedness tests (`AilTypesAux.is_signed_integer_type`, `is_signed` in `std.core`), the
`char` range (`CerbMem.maxIval` / `minIval`), store and load (`CerbMem.memValueToBytes` / `reconstructValueAbst`).
This is a structural claim on the Lean side: `CerberusImpl.is_signed_ity`'s `Char` arm is the only place the value
is read, and a definition that reaches it without an instance in scope does not elaborate.

## 2. S1: the threading (zero behaviour change)

- `CerberusImpl.lean`: the class, `defaultImpl` (an `abbrev`: Lean 4.35 warns on a semireducible definition of class
  type), `is_signed_ity [ImplProfile]`, `precision_ity [ImplProfile]`; lemmas `defaultImpl_char_is_signed`,
  `is_signed_ity_char_default`, `precision_ity_char_default` (and the `hafnium` three, S2) by `rfl`;
  `is_signed_ity_of_ne_char` (two instances agree off the `Char` arm).
- `frontend/model/lean_impl_profile.lem` (new, Lean-only, `Makefile` `LEM_SRC_LEAN_ONLY`): the instance reader
  `char_is_signed` and 13 consumers (`Implementation.is_signed_ity_norm`, `precision_ity_norm`;
  `Decode.decode_character_constant`; `Mem.allocate_object`, `load`, `store`, `intfromptr`, `memcpy`, `memcmp`,
  `realloc`, `copy_alloc_id`, `max_ival`, `min_ival`). **No lem-lean change**: the mechanism at pin `2220010`
  lifted through a consumer used in the module that declares it and across two instance readers on one definition.
- Binder order as lem emits it: `[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`.
- [AGENT 2026-11-22] `CerbMem.reconstructValue(_lemFuel)`, the default-SWITCH compatibility wrappers, bind the
  profile and pass it on. Pinning the default profile there would have been a capture of the profile.
- `scripts/check_no_fuel_numerals.sh` rule W3: W1's shape for the new class (a speedbump; three plants).
- Generated OCaml byte-identical in S1 (digest of the tree's `.ml` files before and after). Generated Lean: the
  binder, an added `import CerberusImpl`, re-wrapped heads, two new `Lean_impl_profile` modules; nothing else (a
  token comparison with the binder and the import removed; derived).

### The readers that gained the binder (derived from the tree at S2)

Generated: 261 declarations in 21 modules. Hand-written: 57 declarations in 13 modules (61 in 14 at S2, when the
four `CabsImport` import functions also bound it; removed after the review).
The per-module lists are in the consumer note `2026-11-22_consumer-note-cerberus-sl-impl-profile.md`.

## 3. S2: captures of the profile

**Upstream's.** `frontend/model/ail/ailTypesAux.lem` `let is_signed_ity = Implementation.is_signed_ity` is generated
as a top-level OCaml value reading `(Ocaml_implementation.get()).is_signed_ity` at module initialisation. FIXED: a
function of its argument. Tray report 100 (`upstream-tray/100-implementation-profile-read-at-module-initialisation.md`).

**The search for others**, two instruments, and the claim is as wide as they are:

1. A census of top-level value bindings (no parameters, right-hand side not a syntactic function; whole multi-line
   right-hand sides) of the generated OCaml (338 bindings, derived) and of the hand-written oracle OCaml (451,
   derived; `backend/cn`, `bmc`, `web`, `coq` and tests excluded), reviewed for a read of the profile directly, by
   partial application or through another such binding. One: the binding above.
2. A run-time instrument (scratch, not committed): `Ocaml_implementation.get` recorded a backtrace for every call
   made before `set`, printed by `set`. With the fix: `0 get() call(s) BEFORE set()` on a nolibc program, a libc
   program and the Cabs export. With upstream's binding put back in the generated file:
   `1 get() call(s) BEFORE set()`, `Called from Cerb_frontend__AilTypesAux.is_signed_ity`, and the fork then
   reproduces pristine's crash (`impl_mem.ml`, line 967, `bytes_of_int`). Both files were restored and rebuilt.

Not covered by either: the VIP, symbolic and CHERI memory models' executions (their sources were in the census, not
in the run), `backend/cn` and the other back ends.

**Found on the Lean side.** [AGENT 2026-11-22] Core quotation (`--quote-core`/`--quote-libc`) writes elaborated Core
that a consumer replays under its own instance, and the module does not record the profile: REFUSED under a
non-default profile. This closes ONE direction only (the review's finding 4): a module quoted under the default and
replayed at a consumer's `hafniumImpl` is not stopped. Quotation is not served under the second profile at this
delivery; the question is with the operator.

**Built under the default, by construction.** The oracle's `libc.co` (`runtime/libc/dune`) and the Lean engine's
`tests/libc/libc.core`. They are used under `hafnium` on a measurement the lane repeats on every run: the 12 libc
sources elaborate to identical Core text under both profiles (108125 lines; derived).

## 4. The witness lane (as of S2; section 7 has the lane as it is now)

`scripts/check_impl_profile.sh` (ladder row 1; about 8 s with `--selftest`), engine `scripts/impl_profile_witness.py`,
corpus `tests/impl_profile/`. Both engines exhaustive. hafnium / default: both engines' verdict (they are equal);
gcc: `-funsigned-char` / `-fsigned-char`; pristine: c3ff8c53f under `HafniumImpl` through its library.

| Program | Mode | Both engines, hafnium | Both engines, default | gcc unsigned / signed | Pristine under Hafnium |
|---|---|---|---|---|---|
| `arithmetic` | nolibc | 45 | 82 | 45 / 82 | CRASH `bytes_of_int(signed)` |
| `array_size` | nolibc | 2 | 1 | 2 / 1 | 2 |
| `bitfield` | nolibc | refused (bit-fields) | refused (bit-fields) | 5 / 2 (not compared) | refused (bit-fields) |
| `char_limits` | nolibc | 115 | 108 | 115 / 108 | 115 |
| `char_limits_const` | nolibc | 31 | 12 | 31 / 12 | 31 |
| `char_literals` | nolibc | 109 | 118 | 109 / 118 | 109 |
| `char_pointer_walk` | nolibc | 16 | 12 | 16 / 12 | **12** (mixed) |
| `comparisons` | nolibc | 42 | 85 | 42 / 85 | CRASH `bytes_of_int(signed)` |
| `conversions` | nolibc | 107 | 20 | 107 / 20 | CRASH `bytes_of_int(signed)` |
| `conversions_const` | nolibc | 24 | 13 | 24 / 13 | 24 |
| `enumerator` | nolibc | 42 | 49 | 42 / 49 | 42 |
| `generic` | nolibc | 85 | 85 | 85 / 85 | 85 |
| `libc_mem` | libc | 43 | 52 | 43 / 52 | not run |
| `libc_printf` | libc | 1 + stdout | 0 + stdout | 1 + stdout / 0 + stdout | not run |
| `libc_string` | libc | 127 | 63 | 127 / 63 | not run |
| `promotions` | nolibc | 197 | 58 | 197 / 58 | CRASH `bytes_of_int(signed)` |
| `static_assert_const` | nolibc | 5 | 3 | 5 / 3 | 5 |
| `store_load` | nolibc | 59 | 68 | 59 / 68 | CRASH `bytes_of_int(signed)` |
| `store_load_struct` | nolibc | 27 | 36 | 27 / 36 | CRASH `bytes_of_int(signed)` |
| `string_literals` | nolibc | 109 | 82 | 109 / 82 | CRASH `bytes_of_int(signed)` |
| `sw_labels` | nolibc | 12 | 48 | 12 / 48 | 12 |
| `usual_arith` | nolibc | 53 | 42 | 53 / 42 | CRASH `bytes_of_int(signed)` |

Pristine, these 19 nolibc programs: 8 crashes, 1 silently mixed answer (`char_pointer_walk`: 12 where the unsigned
answer is 16), 9 agreeing front-end results, 1 refusal; the three libc-mode programs were not run on pristine
(derived from `tests/impl_profile/pristine_hafnium.tsv`). CORRECTION (the review's finding 5): an earlier text of
this record, tray report 100 and the S2 commit message said 9 crashes and 8 agreeing; the table above always had 8
crash rows. The commit message stands (no history rewrite). Bit-fields: upstream does not support them, so the plain-`char` bit-field
question is not reached; both engines refuse identically under both profiles.

Verbatim (final S2 tree; the lane then also pinned four JSON-field refusals, since removed):

```
check_impl_profile: SELFTEST OK (15 plants red on exactly the declared rows; the pristine-pair plant fails 9 rows, the selector-ignored plants 20)
check_impl_profile: OK (22 programs x 2 profiles, both engines exhaustive; 21 gcc-pinned (3 in libc mode): oracle = Lean = gcc -funsigned-char under hafnium and = gcc -fsigned-char under default, byte for byte, exit codes equal, 20 with different answers under the two profiles; 1 refusal row(s) identical under both; 8 refusals (mixed configuration both directions, missing field, unsupported profile, unknown and repeated selector, quotation under hafnium); pristine c3ff8c53f under HafniumImpl recorded for 19 programs (the negative control); the 12 libc sources elaborate to identical Core under both profiles (108125 lines))
check_impl_profile: pristine-live OK (19 recorded observations re-derived from /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/_build/install/default)
```

(The third line is from a run with `--pristine-live`, an optional instrument that needs a pristine installation.)

What the lane does not show: anything outside these 22 programs under `hafnium`. No execution, libc or csmith row
runs under the second profile ([USER 2026-11-22] ruling 3), and the pristine-oracle gate cannot (pristine's driver
has no selector).

## 5. Gates

S1 tree (`0c3817aef`), default profile. Each line verbatim; in order: row 1 (exit 0) and four of its gates, row 2
(two lines), row 5 (two lines), row 14:

```
Total: 21 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: forms partition OK (67 MEASURED + 13 ABSORBING + 0 ambient-reachable + 8 ambient-unreachable = 88 fuel'd workers)
check_no_fuel_numerals: SELFTEST OK (34 plants red with the declared label — F1-F6, A1-A3, W1, W3 and W2; E5 indirection a recorded known gap; unplanted set green)
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: match=43 loc_only=2 diff=0
ALL MATCH RECORDED BASELINE
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
```

Kernel replay, S1, from `lean_frontend/`, `scripts/ce ../scripts/capped lake env leanchecker <modules>`: the 30
changed seam and generated modules, the 87 `*_auxiliary` carriers, `Unit.MemoryAccessProofs`, `Unit.FuelExemplar`,
`Unit.ReconstructLegacyTest`, `Unit.TotalityProofTest`, `Unit.EnumDataTest`, `Unit.TranslationFuelTest`:
`leanchecker exit=0` (63 s). Negative control, a module that does not exist: exit 1. S2: `CerberusImpl`,
`CabsImport`, `CerbDecode`, `CerbMem`, `AilTypesAux`, `Unit.RunDigestTest`: `leanchecker exit=0`; control exit 1.

S2, final tree (`1c1ac30c4`): row 1 `Total: 21 passed, 0 failed`, exit 0; row 7 `ALL PASSED`;
`test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)`;
`Independent oracle: passed; {'semantic_agreement': 932, 'reviewed_difference': 43, 'matching_failure': 25, 'interface_agreement': 2}`;
fork drift OK, 108 oracle-surface files and 37 differing generated files (paraphrased).

S2, on the tree before the import guard was moved behind the existing decodes (the Lean driver was rebuilt after;
these were not re-run by the worker): row 2 `BASELINE OK` (0 regressions, 0 improvements); row 5
`match=43 loc_only=2 diff=0`; row 6 `SUMMARY: total=8 match=8 fail=0`; row 14 `BASELINE OK` (164 rows); row 15
`BASELINE OK (inner_arg_temps: 189 rows; classes and both distinct-observation/status hashes exact)`;
`Golden tests: 10 passed, 0 failed, 0 skipped`; `check_runtime_resolution` OK (35 witnesses); `test_stops` OK;
`test_unit.sh --core-quote-libc`: `Total: 2 passed, 0 failed` (the libc literal pins held).

Failures on the way, each a real finding:

- **S1, row 1 RED at the lem-sync gate.** The OCaml stamp hashes every `.lem` source, the Lean-only one included.
  Remedy: the forced regeneration; the generated OCaml digest did not move.
- **S2, row 7 RED.** `scripts/test_batch_diagnostics.py` feeds non-object documents and a hand-built empty
  translation unit. The guard, placed first, pre-empted the existing diagnostics, and the hand-built document lacked
  the field. Fixed: the guard stands after the decode of the translation unit and the digest (every malformed
  document keeps its message), and the hand-built document carries the field.

Fork-drift manifest, single-row edits with dated NOTEs, no `--refresh`: `[files]` 107 → 108
(`lean_impl_profile.lem`); `[source-content]` the new row, `Makefile`, `ailTypesAux.lem`, `backend/driver/main.ml`;
`[expected-semantic]` `ailTypesAux.ml`'s hash (one more hunk; layer 2 stays 37).

## 6. What was not done (as of S3; see section 7 for the state after the review)

- No lane runs under `hafnium` besides the 22 witnesses (by ruling).
- Core quotation under `hafnium` is refused, not supported.
- Morello/CHERI, `--impl`, the other fields of the implementation record: untouched (by ruling). `hafnium` under a
  CHERI memory model is refused by the oracle driver.
- The libc-mode witnesses were not run on pristine under Hafnium.
- The capture search did not execute the VIP, symbolic or CHERI memory models.
- The remaining Tier A and Tier B rows were not run by the worker.
- The one-job-per-lane rule was not kept twice: rows 6 and 7, and `test_verify` with the pristine-oracle gate, ran
  back to back in one background job each.

## 7. After the pre-merge review (2026-11-22)

The review (`2026-11-22_impl-profile-premerge-review.md`, `987c2c51c`): no P1, six P2, P3 notes. Every finding is
dispositioned in that file. Rulings [AGENT 2026-11-22, orchestrator]; code and witnesses `901ec9c03`.

**The charter's premise about the Cabs JSON was wrong, and so was this record.** The charter required a profile
field in the export and an import refusal on the premise that the preprocessor's and the parser's results in the
document depend on the profile. The reviewer measured that they do not (98 documents byte-identical under the two
profiles apart from the label), and the reason is structural: Cabs carries a character constant as its spelling and
`CHAR_MIN` as an identifier, and the preprocessor is the host's. The field and the guard are REMOVED:
`backend/driver/main.ml` writes no field; `CabsImport.lean`, `CabsImportTest.lean`, `RunDigestTest.lean`,
`scripts/test_batch_diagnostics.py` and the ten fixtures are the mainline's text again (`git diff 77229f846` is
empty on all of them; each fixture also equals a fresh export from this tree, 10 of 10). `parseJson*` do not bind
the profile. With the guard gone, the review's finding 3 (its refusal class) has no object. The lane now checks the
measured fact on every run: each program's export under `hafnium` equals its export under `default`.

**The profile is a property of the run.** It is read by the desugarer's constant evaluation, Ail typing, the elaboration, Core's signedness tests, the integer ranges and the memory model's store and load. It is NOT read by the
preprocessor: `#if` arithmetic on a character constant is the host `cc -E`'s (C17 6.10.1#4 permits the difference;
upstream RefinedC's frontend is the same) and the limit macros are identifiers there. No signedness flag is passed
to the preprocessor. Witness `preprocessor_if`: both engines 12 under `hafnium` and 52 under `default`; gcc 9 and 54,
recorded beside the pins as the declared difference and re-checked live.

**Quotation (finding 4): no change, and the gap stated.** Quoting is refused under `hafnium`; a default-quoted module
replayed at a consumer's `hafniumImpl` is not stopped. The quotation flow is not served under the second profile at
this delivery. With the operator.

**Other changes.** `--impl-profile=hafnium` is accepted under the concrete memory model only: the VIP driver (a copy
of `main.ml`) refuses it, exit 2, by one test on `Impl_mem.name`. Rule W3 also catches the priority form,
`attribute [instance]` on the profile values and a header broken across lines. The lane gained five gcc-pinned
programs (function argument and return conversions, floating conversions, a union with a `char` member, an
`_Atomic char`, `realloc` of a `char` buffer holding bytes above 127), the preprocessor row, the VIP refusal with
its default control, the oracle's repeated selector, and one plant that RUNS both engines with the selector
omitted; its other plants tamper with recorded observations and rebuild no engine. gcc is a declared prerequisite
of row 1. The five outside-the-slice observations: tray reports 101 (limit macros in `#if`), 102 (wide character
constants), 103 (`strncmp`); the two Lean-versus-oracle ones (`strtol`'s execution blocks, the `printf` location)
are in `TODO.md`, since the tray holds upstream reports [AGENT 2026-11-22]; the sixth, `'ab'`, is tray 63's.

Pristine under HafniumImpl, now 24 nolibc programs: 12 store crashes, 1 silently mixed answer, 9 agreeing with
`gcc -funsigned-char`, 1 bit-field refusal, and the preprocessor program (12, as the fork; its answer does not
depend on the record) (derived from `pristine_hafnium.tsv`).

The lane and the gates on `901ec9c03`, each a separate job on a still tree, verbatim:

```
check_impl_profile: SELFTEST OK (15 plants red on exactly the declared rows; the pristine-pair plant fails 13 rows, the selector-ignored plants 26)
check_impl_profile: OK (28 programs x 2 profiles, both engines exhaustive; 26 gcc-pinned (4 in libc mode): oracle = Lean = gcc -funsigned-char under hafnium and = gcc -fsigned-char under default, byte for byte, exit codes equal, 25 with different answers under the two profiles; 1 refusal row identical under both; 1 preprocessor row (the engines agree with each other, gcc's line the declared difference); every Cabs export identical under the two profiles; 6 refusals (unknown and repeated selector on each engine, quotation under hafnium, hafnium on the VIP driver); pristine c3ff8c53f under HafniumImpl recorded for 24 programs (the negative control); the 12 libc sources elaborate to identical Core under both profiles (108125 lines))
check_impl_profile: pristine-live OK (24 recorded observations re-derived from /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/_build/install/default)
check_no_fuel_numerals: SELFTEST OK (37 plants red with the declared label — F1-F6, A1-A3, W1, W3 and W2; E5 indirection a recorded known gap; unplanted set green)
Total: 21 passed, 0 failed
Golden tests: 10 passed, 0 failed, 0 skipped
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
SUMMARY: match=43 loc_only=2 diff=0
ALL MATCH RECORDED BASELINE
BASELINE OK (inner_arg_temps: 189 rows; classes and both distinct-observation/status hashes exact)
Total: 2 passed, 0 failed
Independent oracle: passed; {'semantic_agreement': 932, 'reviewed_difference': 43, 'matching_failure': 25, 'interface_agreement': 2}
```

In order: the lane's two lines (inside row 1) and its `--pristine-live` line (a separate run); the speedbump's
selftest; row 1's tally (exit 0); the golden tests; `test_verify.sh`; row 5 (two lines); row 15; the tally of
`test_unit.sh --core-quote-libc` (both libc digests the values they had); the pristine-oracle lane (its line cut
before the report path). Also: `check_runtime_resolution` OK (35 witnesses), `test_stops` OK, fork drift OK (108
files, layer 2 37; `backend/driver/main.ml` re-pinned, single row). Kernel replay: `leanchecker exit=0` over
`CerberusImpl`, `CabsImport`, `CerbDecode`, `CerbMem`, `CerbMemDefaultFacts`, `CerbMemAccessFacts`,
`CerbMem_lemMeasureProofs`, `CerbND`, `CerbCall`, `AilTypesAux`, `Implementation`, the four
`*_lemMeasureProofs` modules of `Core_eval`, `Defacto_memory`, `Driver`, `Translation`, and
`Unit.{RunDigestTest,FuelExemplar,MemoryAccessProofs,ReconstructLegacyTest,TotalityProofTest,EnumDataTest}`; negative
control exit 1. The reviewer's tip-wide replay over 132 modules at `44a206e0b` is in the review.

**Rows the worker did not re-run on `901ec9c03`** (finding 6): Tier A rows 2, 3, 4, 4b, 4c, 6, 6b, 7, 8, 9, 10, 11,
12, 13, 14, and every Tier B row except `test_verify.sh`, `--core-quote-libc` and the pristine-oracle lane. Rows 2,
6, 7 and 14 passed on earlier trees of this branch (sections 5 above) and are not evidence for this one. The
orchestrator's battery on the new tip is the evidence for those rows.

Not done, as it stands: no lane under `hafnium` besides the 28 witnesses (by ruling); quotation under the second
profile (with the operator); the preprocessor does not follow the profile (by ruling); every memory model but the
concrete one refuses `hafnium`; Morello and the other fields of the record are untouched (by ruling); the libc-mode
witnesses were not run on pristine; the capture search did not execute the VIP, symbolic or CHERI models.
