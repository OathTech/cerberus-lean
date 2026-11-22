# Pre-merge review: `arc/impl-profile` (the implementation profile as a parameter) — 2026-11-22

Reviewer: Claude Fable 5.2 (agent), independent of the worker. Under review: `arc/impl-profile` at `44a206e0b`
(S1 `0c3817aef`, S2 `1c1ac30c4`, S3 `44a206e0b`), base mainline `77229f846`. Read: the scoping, the charter, the
record, `git diff 77229f846..HEAD`, contract D20, SUPPORTED, VALIDATION, the three consumer notes, tray report 100.
Quoted machine output is verbatim; counts marked "derived" are mine. All scratch lived under the worktree's
`.tmp/review/` and was deleted. Severities: P1 blocking, P2 should-fix before the merge (or an explicit operator
waiver), P3 note.

## Verdict

**No P1.** I found no wrong answer under `hafnium` on either engine, no reader left on the default, no capture
besides the one fixed, and the kernel replay passes at the tip. **Six P2**, none of them a behaviour defect of the
executed semantics: two statements of the contract and the notes are wider than the tree bears out (findings 1, 2),
one refusal is emitted in the wrong class (3), one guard covers one direction only (4), one tally is wrong in three
places including the upstream-facing report (5), and the default-profile gates were not all run on the final tree
(6). My recommendation: fix 1, 2 and 5 in the documents (and 3 in code, or register it), have the orchestrator's
battery close 6 at the tip, decide 4 with the operator, then merge.

What I did NOT do: a full row 1 (`test_unit.sh`) or any Tier A/B execution row except the two named in finding 6;
a re-derivation of the claim that the generated OCaml is byte-identical through S1 (no base build in this worktree);
a timing comparison against a base-built oracle; any run of the symbolic or CHERI memory models; a build of
cerberus-sl, cerberus-caesium or refinedc-lean against this tip.

## What I ran

| Instrument | Result |
|---|---|
| 98 single-purpose programs (mine: preprocessor, limit macros, constant evaluation, typing, arithmetic, conversions, store/load, 18 in libc mode), both profiles, oracle exhaustive, Lean exhaustive, gcc 13 `-funsigned-char`/`-fsigned-char` | `agree all three: 182 of 196`; the 14 others are classified in findings 2 and 12 (no `hafnium`-only engine disagreement) |
| 20 more libc-mode programs (printf conversions, string and allocation functions) | `agree all three: 35 of 40`; the 5 others in finding 12 |
| 6 of those programs under `--sequentialise --rewrite`, `--typecheck-core`, `--switches=PNVI_ae_udi` (oracle), `--first`, `--switches=PNVI_ae_udi` (Lean), and the VIP driver `main_vip.exe` | every mode equal to the batch answer under each profile |
| Lean `--call g --call-args 200` under each profile | `Specified(1)` (hafnium), `Specified(2)` (default) |
| Exported Cabs JSON under `default` vs `hafnium`, the profile line removed, 98 programs and 3 libc sources | `pairs=98 differing=0` (finding 1) |
| `libc.co` rebuilt into scratch by the dune recipe (`--sequentialise --rewrite`, the 12 sources) under each profile | byte-identical, 2940074 bytes each; the printed rewritten Core identical, 88943 lines (finding 11) |
| `scripts/check_impl_profile.sh --selftest --pristine-live <pristine prefix>` | the three verdict lines of the record's section 4 reproduced; 19 of 19 `OK   pristine-live` |
| Kernel replay at the tip, from `lean_frontend/`, `scripts/ce ../scripts/capped lake env leanchecker <132 modules>` (`CERB_MEM_MAX=32G`): every `*_auxiliary` and `*_lemMeasureProofs` module, `CerberusImpl`, `CerbMem`, `CerbMemDefaultFacts`, `CerbMemAccessFacts`, `CerbND`, `CerbDecode`, `CabsImport`, `CerbCall`, `AilTypesAux`, `Implementation`, `Core_eval`, `Defacto_memory`, `Driver`, `Translation`, `GenTyping`, `Cabs_to_ail`, `Mini_pipeline`, `Formatted`, ten `Unit.*` test modules | `leanchecker exit=0` (83 s wall); negative control (a module that does not exist): exit 1 |
| `lake build --no-build CerberusLean cerberus-lean` (is the build the tip's?) | `All targets up-to-date (411 jobs).`; `check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; …)` |
| `scripts/test_golden.sh`, `scripts/test_multi_tu.sh` at the tip | `Golden tests: 10 passed, 0 failed, 0 skipped`; `SUMMARY: total=8 match=8 fail=0` / `ALL PASSED` |
| Tray 100's patch against pristine `c3ff8c53f` | `git apply --check`: `Checking patch frontend/model/ail/ailTypesAux.lem...`, rc 0; the cited lines (`ailTypesAux.lem:26`, `ocaml_implementation.ml:378`, `:413`, `impl_mem.ml:780`, `:971`, `core_eval.lem:1075`, `:1085`, `ctype_aux.lem:249`) are what the report says they are |

## Findings

### 1. (P2) The mixed-configuration guard's stated reason does not hold: the Cabs JSON does not depend on the profile

The charter, contract D20 (ii), the comments in `CabsImport.labelsOfParsed` and `backend/driver/main.ml`, the record
and the refinedc-lean note all justify the `impl_profile` field by saying the preprocessor's and the parser's results
are already in the document, so importing under another profile would be a mixed configuration. Measured: the
exported document is byte-identical under the two profiles apart from the field itself.

```
pairs=98 differing=0
libc_ctype same
libc_stdio same
libc_string same
```

(98 programs covering character constants above `\177`, `CHAR_MIN`/`CHAR_MAX`, casts in array bounds, enumerators,
case labels, static assertions; each exported with `--impl-profile=default` and `=hafnium`, compared with the
`"impl_profile"` line removed.) The reason is structural: Cabs carries a character constant as its spelling
(`"val": [ null, "\\200" ]`), `CHAR_MIN` as the identifier `__cerbvar_CHAR_MIN`, and the preprocessor is the host's
`cc -E`, which never sees the flag. Nothing profile-dependent is decided before the desugarer, which runs on the
Lean side under the run's instance. A default-exported document relabelled by hand runs under `hafnium` and gives
the answer of a hafnium export (`relabel.json`: `Defined {value: "Specified(1)", …}`, exit 0).

So the guard is a label-consistency check between two command lines, not a protection against a mixed
configuration. It is fail-closed and does no harm to the semantics, but:

- the contract states a trust property the field does not carry (record integrity; gates are reserved for trust
  properties and say what they guarantee);
- it has a cost: `CabsImport.parseJson*` now bind the profile, every pre-existing JSON of every consumer is refused,
  and the refinedc-lean note tells the consumer to re-export its corpus under the profile it imports under, which
  the measurement shows changes one line;
- it does not bind the oracle's own run: the differential's oracle side is a separate `--exec` invocation, and
  nothing ties its flag to the export's.

Disposition I suggest: either keep the field and state it for what it is (a declared label, future-proofing against
a profile-reading parser or preprocessor, and a check that the two command lines agree), correcting D20 (ii), the
two code comments, the record and the refinedc-lean note; or drop the import-side binder and keep the field as
metadata. That is a design choice for the operator; the texts are wrong either way as they stand.

### 2. (P2) The preprocessor does not read the profile; D20, VALIDATION and the notes say every phase does

Contract D20 ("selected once at the entry point of each engine and read by every phase"), VALIDATION's lane row and
the charter's principle (which lists the limit macros) are wider than the tree. `#if` arithmetic is evaluated by the
host `cc -E`. One program, mine:

```c
#include <limits.h>
int main(void) {
  int r = 0;
#if CHAR_MAX > 127
  r += 1;
#endif
#if CHAR_MIN < 0
  r += 2;
#endif
#if '\377' < 0
  r += 4;
#endif
  if (CHAR_MAX > 127) r += 8;
  if (CHAR_MIN < 0) r += 16;
  if ('\377' < 0) r += 32;
  return r;
}
```

```
hafnium: oracle=Specified(12) lean=Specified(12) gcc -funsigned-char=Specified(9)
default: oracle=Specified(52) lean=Specified(52) gcc -fsigned-char=Specified(54)
```

Under `hafnium`, in one translation unit, `'\377' < 0` is true in `#if` and false in an expression, and
`CHAR_MAX > 127` is false in `#if` (the macro expands to the identifier `__cerbvar_CHAR_MAX`, which is 0 there) and
true in an expression. The two engines agree with each other in every case, so this is not a differential defect.
The first is permitted by C11 6.10.1p4 (implementation-defined) and matches what RefinedC's own frontend does (host
cpp, no `char` define), so for refinedc-lean it is parity with the donor; it still differs from the lane's referee.
`__CHAR_UNSIGNED__` is likewise not defined under `hafnium`. The value in `#if` also follows the host: on an
aarch64 host both profiles would see an unsigned `'\377'` there. The second (`CHAR_MIN`/`CHAR_MAX` unusable in
`#if`) is upstream's, exists under the default too (the `default` line above: gcc's 54 has the `#if CHAR_MIN < 0`
arm the engines lack), and is finding 12's first item.

None of the documents mentions the preprocessor. Wanted: a sentence in D20's "where the claim stops", in SUPPORTED's
row and in the refinedc-lean note ("Limits you should know"), and "every phase" narrowed to the phases after
preprocessing. The lane has no `#if` program; one pinned row (engine-pinned, kind `stop`-like or a new kind, since
gcc is not the referee here) would keep the statement honest.

### 3. (P2) The mixed-profile refusal is emitted as a parse error, not as a refusal

The guard's text says `REFUSED`, the record's table says "refuses", and the lane pins exit 1:

```
cerberus-lean: parse error: parseJson: REFUSED: mixed implementation profiles — this cabs-json was exported under 'hafnium_aarch64-none-eabi' (plain char unsigned) and is being imported under a profile with plain char signed; export and import must select the same profile (cerberus --impl-profile / cerberus-lean --impl-profile)
Error {msg: "cabs-json parse error: parseJson: REFUSED: mixed implementation profiles \226\128\148 this cabs-json was exported under …"}
rc=1
```

A well-formed document under the wrong profile, and one naming an unsupported profile, are declared refusals in the
project's sense: every other one in the driver is a `cerberus-lean stop [… "REFUSAL" …]` record with exit 2
(the unknown selector, the import-time library-location refusal `refuseLibraryLocations`, quotation under
`hafnium`). Here the batch output is an `Error {msg: …}` verdict line, the form a differential harness reads as a
program-level error and may pair with an oracle error. Exit 1 is the right class for the missing and the ill-typed
field (they match the missing `digest`). It is the wrong class for the mismatch and the unsupported-profile arms.
The cause is placement: the check lives in the pure decode function. Fix: return the recorded name from the decode
and judge it in `Main` through `CerbStop.exitRefusals`, or register the class as deliberate in D20.

### 4. (P2) The quotation refusal closes one direction of the mixed configuration and leaves the other open; the filer's flow is not served

Core quotation is refused under `hafnium` because the quoted module does not record the profile. The same argument
applies in the other direction and nothing guards it: a module quoted under the default (no record of the profile
either) replayed by a consumer under its own `hafniumImpl` instance is the same mixed configuration, with constants
already evaluated signed. cerberus-caesium is exactly that consumer: its flow is quotation
(`scripts/probes/w4-full-corpus-quotation.py`, `scripts/certificate-pipeline.py`), its target's `char` is unsigned,
and it filed the request this slice answers (its tray item 02, which asks for agreement "on the Cabs JSON and on the
Core"). After this slice it can select `hafniumImpl` in process and still feed default-quoted Core to it.

The refusal itself is a sound fail-closed choice. What is missing: (a) the caesium note should say plainly that the
filing is not served for the quotation flow, and that a default quotation must be replayed at `defaultImpl`;
(b) the durable fix is the one TODO item (ii) already names, recording the profile in the quoted module (a `def` the
consumer can compare, or a parameter the module is closed over), which closes both directions. Related, by code
inspection only (not run): the refusal list at `Main.lean:2045-2058` does not refuse quotation under
`--switches=PNVI_ae_udi`, and the quoted module does not record the switch set either; whether elaboration reads the
switch set is the question that decides if that is the same gap.

### 5. (P2) The pristine tally is wrong in the record, the S2 commit message and tray report 100

The record's section 4 says "Pristine: 9 crashes, 1 silently mixed answer …, 8 agreeing front-end results, 1
refusal"; tray report 100 says "9 end in the `bytes_of_int(signed)` assertion …, 1 gives the mixed answer above, 8
answer as `gcc -funsigned-char` does"; the S2 commit message says "9 store crashes". The recorded file and the live
pristine library say 8 crashes, 1 mixed, 9 agreeing, 1 refusal (derived from `tests/impl_profile/pristine_hafnium.tsv`:
8 lines with `bytes_of_int(signed)`, 10 `Defined`, 1 other; the record's own table has 8 `CRASH` rows; my
`--pristine-live` run printed 8 `failed: bytes_of_int(signed)` lines). The lane's "the pristine-pair plant fails 9
rows" is right (8 crashes plus the mixed answer) and is probably where the 9 came from. The tray report is the
upstream-facing document: fix it and the record; the commit message stands (history is not rewritten), so the
correction belongs in the record.

### 6. (P2) Default-profile gates on the final tree are owed before the merge

The record says so itself: after the worker's last code change (the import guard moved behind the existing decodes,
the Lean driver rebuilt) it did not re-run rows 2, 5, 6, 14, 15, the golden tests, `check_runtime_resolution`,
`test_stops` and `test_unit.sh --core-quote-libc`; and Tier A rows 3, 4, 4b, 4c, 6b, 8-13 and most of Tier B were
never run on this branch. Every one of those lanes imports Cabs JSON through the changed function, and S2 changed
generated OCaml in the oracle. The "every existing lane unchanged under the default" acceptance of the charter is
therefore established for row 1, row 7, `test_verify` and the pristine-oracle gate only. I closed two of the gaps
at the tip (golden `10 passed, 0 failed`, row 6 `total=8 match=8 fail=0`). The rest is the orchestrator's battery at
`44a206e0b`; the merge should wait for it, and the landing record should quote it rather than the pre-final runs.

### 7. (P3) The witness lane: what it covers and what it does not

Sound as built: pins derived from gcc and re-checked against gcc on every run, both engines pinned byte for byte
with exit codes, the pristine observations re-derivable (`--pristine-live`: 19 of 19), the plants red on exactly
the declared rows. Limits worth recording next to it:

- The plants tamper with recorded observations in memory; none rebuilds an engine with the capture put back (the
  worker did that once by hand, per the record). Acceptable for a cheap row; say so in VALIDATION.
- Construct classes with no program in `tests/impl_profile/` (derived by grep over the 22 sources): function
  argument and return conversions through `char`, floating conversions to and from `char`, unions, `_Atomic char`,
  heap objects (`malloc`/`realloc`: `Mem.realloc` is one of the 13 declared consumers and has no witness), file-scope
  and `static` `char` initialisers apart from one struct, wide constants, any `#if`. My probes of each agree on both
  engines and with gcc under `hafnium`, so these are gaps in the lane, not defects. A float case is a cheap, sharp
  witness: `double d = 200.0; char c = (char)d;` is defined under `hafnium` and
  `UB017_out_of_range_floating_integer_conversion` under `default` on both engines.
- The bit-field row pins two refusals and is honest about not being compared with gcc.
- Row 1 now needs `gcc` on the path (fail-closed if absent). That is a new prerequisite of the per-commit row;
  the README's prerequisites should name it if they do not.

### 8. (P3) `hafnium` is accepted by the VIP driver with no validation

`backend/driver/main.ml` is copied into `main_vip.ml`, so `cerberus-vip --impl-profile=hafnium` is accepted; only the
CHERI case is refused. D20 says the claim stops at the VIP, symbolic and CHERI models, which is honest. My six
programs gave the concrete model's answers on `main_vip.exe` under both profiles. Under the project's own refusal
doctrine, a declared refusal under a memory model the lane never runs would be the tighter choice; at least the
flag's `--help` text could say which model the witness covers.

### 9. (P3) Rule W3's edges

The pattern misses `instance (priority := low) : CerberusImpl.ImplProfile := …` (the first colon is the
priority's), `attribute [instance] CerberusImpl.defaultImpl` (and `defaultImpl` is an `abbrev` of class type, so
this one line would make it a global default), and a header broken across lines; it does catch
`@[instance] def … : CerberusImpl.ImplProfile`. The script declares W3 a speedbump with W1's edges, so this is a
note; the `attribute [instance]` shape is the one I would add, since it is the cheapest way to create the hidden
default by accident.

### 10. (P3) The Lean threading and the compatibility wrappers

- No reader pins the default: `defaultImpl`/`hafniumImpl` occur in the seams only in `Main.lean` (the selector's
  default, the quotation refusal, the self-test) and an error string in `CabsImport`; nowhere in the generated
  tree; otherwise in tests, each at an explicit instance (derived by grep). `is_signed_ity`'s `Char` arm is the one
  read. The three seams that branch on signedness (`CerbDecode.wrapChar`, `CerbMem.maxIval`/`minIval`) go through it.
- `CerbMem.reconstructValue(_lemFuel)` binding the profile rather than pinning the default is, in my view, right
  for cerberus-sl: the bridge `loadM_reconstruct_eq_reconstructValue` then holds at every profile, where a pinned
  wrapper would have needed a profile hypothesis or been false under `hafniumImpl`. The cost is real and the note
  states it accurately: cerberus-sl names the wrappers in 15 files (derived), each of which needs an instance in
  scope at the re-pin. The phrase "default-pinned" in rule W2 and in `lean_frontend/CLAUDE.md` now means the switch
  set only; the `CerbMem` docstring says so, the W2 text does not.
- The `rfl` lemmas are true and usable, and narrow: they pin the `Char` arm of two functions at two instances. They
  are not, and cannot be, a statement that the default instance reproduces the base's behaviour; that rests on the
  differential baselines (finding 6). `is_signed_ity_of_ne_char` is the useful one for a consumer.
- The consumer note's derived counts check out: 61 hand-written declarations in 14 modules, 261 generated in 21.
- `CabsImport.parseJson*` is a definition that takes the profile without a semantic need (finding 1).

### 11. (P3) The libc under `hafnium`: confirmed with a stronger instrument than the lane's

The lane compares the per-source `--pp=core` text without `--sequentialise --rewrite`; `libc.co` is built with both
flags and linked. I built the object by the dune rule's command under each profile into scratch:
`CO IDENTICAL default vs hafnium` (2940074 bytes), and the rewritten linked Core text is identical (88943 lines).
This closes the scoping's "not established: identity of the binary `libc.co` across profiles". The scratch object
differs from the installed one at byte 85 only in the sense that `cmp` stops there (the header); I did not chase
that. Suggest the lane's wording say which recipe it measures.

### 12. (P3) Observations outside the slice (both profiles, or the default only), for the backlog owner

Found by the probes; none is caused by this branch, none was checked against the base binary.

- `CHAR_MIN`/`CHAR_MAX` are not usable in `#if` (finding 2's program, the `default` line): upstream's
  `__cerbvar_` scheme; C11 5.2.4.2.1 requires it. I found no tray report for it (grep of `upstream-tray/`).
- `L'\xff' == 255` is false under `default` on both engines (gcc: true): the character-constant wrap is applied to a
  wide constant.
- `strncmp("\x80", "\x7f", 1) > 0` is false under `default` on both engines (gcc: true; C11 7.24.4 compares as
  `unsigned char`); under `hafnium` it is true. Tray 30 covers only the zero-length case.
- `strtol`/`strtoul` programs: the oracle prints one `Defined` line, the Lean driver prints several `EXECUTION n:`
  blocks with the same verdict, under both profiles. Whether the lanes normalise this I did not check.
- A `printf` with an ill-typed argument: `UB153b_illtyped_argument_for_format` on both engines, `loc:
  "<717:10--717:40>"` on the oracle and `"<unknown location>"` on Lean, under both profiles.
- `'ab'` (a multi-character constant) is an uncaught exception on the oracle (exit 125) and a mirrored
  `UPSTREAM_CRASH` panic on Lean, under both profiles.

### 13. (P3) Smaller points

- The Lean importer takes the last of two `impl_profile` keys (a default document with a second, hafnium, key
  appended imports under `hafnium`). With finding 1 this has no semantic consequence; noted for completeness.
- The oracle refuses a repeated `--impl-profile` through cmdliner (its own exit code), the Lean driver with exit 2;
  the lane pins only the Lean side's repeat.
- The Lem fix's cost under the default was not measured by the worker or by me (no base-built oracle here). The
  change is one extra call of `Ocaml_implementation.get ()` (a dereference) per signedness test; I expect nothing
  measurable, and say so as an argument, not a measurement. Its behaviour under the default is unchanged by
  construction (the same record is read, later), and on the Lean side `AilTypesAux` is the only olean rebuilt after it (by olean modification times; Lake reports
  the build current).
- The S2 kernel replay in the record covered six modules; the tip-wide replay above covers the rest.
- No quotation of the operator found in the commits or the documents; the rulings are paraphrased and tagged.
  Tray 100 does not speculate about upstream; its reproducer runs on pristine and its patch applies.

## Disposition table

| # | Sev | One line |
|---|---|---|
| 1 | P2 | The Cabs JSON is profile-independent; the guard's stated reason is false in D20, two code comments, the record and the refinedc-lean note |
| 2 | P2 | `#if` is evaluated by the host preprocessor and does not follow the profile; "every phase" overclaims; no document says so |
| 3 | P2 | Mixed and unsupported profile at import: a parse error with exit 1 and an `Error {msg}` verdict, not a REFUSAL stop |
| 4 | P2 | Quotation is guarded in one direction only; cerberus-caesium's quotation flow is not served and the note understates it |
| 5 | P2 | 8 pristine crashes and 9 agreeing, not 9 and 8: record, tray report 100, S2 commit message |
| 6 | P2 | Rows 2, 5, 14, 15, B13 and the never-run rows are owed on the final tree before the merge |
| 7-13 | P3 | Lane coverage and plants; VIP acceptance; W3 edges; threading notes; libc confirmation; pre-existing observations; small points |
