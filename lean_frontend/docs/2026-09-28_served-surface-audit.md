# Served-surface audit — every hand-written seam that can answer without a model (2026-09-28)

[AGENT — fresh adversarial audit, Claude Fable subagent, 2026-09-28], chartered by the orchestrator as decision D3 of
the draft contract (`git show docs/contract-draft-20260928:lean_frontend/CONTRACT.md`, §4.2). Branch
`audit/served-surface-20260928`, one commit, no push.

**Mainline pin audited:** `mdd/cerberus-lean` = `a7dc36e2fd278af983dc38054d671c5f4652a4db` (the CerbFS path-hotfix
landing). Code read in this worktree at that commit; probes run against the PRIMARY checkout's already-built binaries
at the same commit (`_build/default/backend/driver/main.exe`, `lean_frontend/.lake/build/bin/cerberus-lean`), read-only.

## 0. Summary

- **One P1.** The numeric identity of a function pointer — `(intptr_t)&f`, the bytes of a stored function pointer,
  `%p` of a function pointer cast to `void *` — is SERVED on both engines and DIFFERS: the value is the function
  symbol's fresh number, `CerbMem` mirrors `impl_mem.ml` arm for arm, but the two engines' fresh-symbol supplies are
  offset (the oracle's Core parser draws a fresh number for every `std.core`/impl symbol before the user TU; Lean's
  `CoreParser` mints hash symbols and draws nothing). Measured nolibc: oracle = Lean + 483 on every channel
  (`530` vs `47`, `502` vs `19`, `0x283` vs `0xa0`); libc mode: oracle `530`, Lean `645`. No lane observes it — the
  one corpus row that casts a function pointer to an integer (`tests/coverage/ptr3/ptr3-001-funcptr-to-int.libc.c`)
  only tests `x != 0`. Under the contract's §1 this is the fifth outcome. §2 finding P1-1.
- **Concurrency (priority 1 of the charter): no defect.** `CerbConcurrency.statically_satisfied := true` has ZERO
  callers in the generated tree — the lem definition it represents is `{hol; isabelle; tex}`-only
  (`frontend/concurrency/cmm_csem.lem:654-656`) and no generated module mentions `CerbConcurrency` — so the stub is
  dead code, not a served default. Every default-mode concurrency construct probed (`_Atomic` loads/stores/RMW,
  `<stdatomic.h>` explicit operations, fences, CAS, the Cerberus `{-{ … ||| … }-}` par statement, unsequenced
  calls, `<threads.h>`) either agrees exactly (verdict sets compared line by line, 40/40 on the unsequenced probe) or
  fails identically on both engines (`TODO[Core_reduction]: Fence`, `CompareExchangeStrong`, `CompareExchangeWeak`,
  the ill-typed `atomic_exchange_explicit`, `threads.h`'s `Tspec_name`). §4.
- **Builtin boundary (priority 2): no divergence found; several claims in the tree are stale.** printf/vprintf/
  vsnprintf, exit, errno and the GCC bit builtins agree on every probe, including the adversarial ones (`%c` of
  127/200/-1/300/0, non-NUL-terminated `%.3s`, `%n`, unknown `%y`, missing/ill-typed arguments, `%f` of 1e300,
  `snprintf` size 0 / NULL / truncation, `exit(-1)`, `exit(256)`, `atexit`, `bswap64` overflow). Two register
  entries describe reachability that does not exist: `any_bounded_int` (Z2-U-02, "reached only by programs that use
  it explicitly") in fact crashes identically on both engines at `Core_reduction`'s `TODO` (the Lean `bounded_integer
  := lo` is dead), and `ctz(0)`'s Lean panic is unreachable behind the `std.core` proxy's `undef`. §5.
- **Debug/PP seams (priority 3): no verdict path reads them.** Every `CerbPP` residual placeholder reaching the
  execution cone sits inside a `CerbDebug.print_debug_pure` thunk (level 0, never forced) or in failure text (class
  (a)); `CerbDebug.warn`/`print_unsupported` map to the oracle's TOOL stderr (not the compared program stderr). §6.
- **Everything else (priority 4):** the default/wildcard arms in `CerbMem`, `CerberusImpl`, `CerbDecode`, `CerbFloat`,
  `CerbUtils`, `CerbLocation`, `CabsImport`, `CoreParser`, `CerbND`, `CerbCall`, the instance seams and `Main` are
  MIRROR (cited), REFUSE, or UNREACHABLE with a reason I re-derived; a handful of hygiene items (P3) where a fallback
  arm returns a normal value where the OCaml `assert false`s. §3 ledger, §7.

## 1. Method, and what I did not do

Method. (1) Read the contract draft, both CLAUDE.md files, the CerbFS hotfix record, VALIDATION §4. (2) Enumerated
the hand-written seams (`lean_frontend/*.lean`, 18 889 lines; 526 `declare lean target_rep`/`declare {lean}` sites
in `frontend/model`, 25 in `frontend/concurrency`). (3) For each seam, grepped every arm that can return a value
without modelling — `| _ =>`, `default`/`Inhabited`, `getD`, `.toNat`, constant bodies (`:= true`, `:= []`, `:= 0`,
`:= .eq`), lookups — read the surrounding code, and checked the cited OCaml (`memory/concrete/impl_mem.ml`,
`ocaml_frontend/*.ml`, `util/*.ml`, `parsers/core/core_parser.mly`). (4) Determined reachability from the generated
tree in the primary checkout (`lean_frontend/generated/`, 219 files) — who calls the seam, under what mode. (5) Wrote
72 probe programs (`.tmp/served-surface-audit/`, ephemeral; 58 are quoted in §8 — the other 14 were drafts superseded
by a corrected variant, e.g. the first `<stdatomic.h>` combinations that failed on one ill-typed call, or the printf
lines both engines reject as UB153b because `%x` was given an `int`) and ran oracle (`--exec --batch --mode=exhaustive`,
`--nolibc` or libc) against Lean (`--cabs-json` → `--batch`, libc mode with the pinned `tests/libc/libc.core` and the
12 metadata cabs-jsons regenerated by the oracle exactly as `scripts/libc_prep.sh --jsons` does), one process at a
time, `timeout` on every run, `LEAN_ABORT_ON_PANIC=1`. Verdict sets were compared line by line (§8 quotes them
verbatim). Both-sides timeouts are `matching_incomplete`, never agreement.

What I did NOT do. No builds (no lake/dune/make/opam). No change to code. CerbFS is out of scope (D2 refuses it);
§3 confirms only its entry-point list. I did not re-run any lane. I did not audit the generated tree itself (shared
lem — mirror by construction) beyond tracing reachability into the seams. I did not audit the `--call` harness mode
(`CerbCall.lean`, port-side only, checked by `test_verify.sh` against a wrapper TU) or `--pp-core`. I did not probe
multi-TU numbering. Derived tallies below are labelled derived; quoted outputs are verbatim.

## 2. Findings, ranked

### P1-1 — function-pointer numeric identity is served and differs (symbol-supply offset)

**Sites (all MIRROR of the OCaml, arm for arm):**

| Lean | OCaml | what |
|---|---|---|
| `lean_frontend/CerbMem.lean:2858` (`intfromptr`: `.PV prov (.PVfunction (Symbol _ n _)) => memReturn (.IV prov n)`) | `memory/concrete/impl_mem.ml:2487-2488` (`PVfunction (Symbol.Symbol (_, n, _)) -> return (mk_ival prov (Z.of_int n))`) | pointer→integer cast returns the symbol number |
| `CerbMem.lean:787-799` (`memValueToBytes`, `.PVfunction (Symbol fileDig n optName)` → `intToBytes false n targetPtrSize`, funptrmap insert) | `impl_mem.ml:1203-1210` | stored function pointer = the symbol number's bytes |
| `CerbMem.lean:1104` / `:1268` (`reconstructValue`, funptrmap hit → `PVfunction (Symbol fileDig ptrAddr.toNat …)`), else a `PVconcrete` carrying the number | `impl_mem.ml:1047` | read-back; `%p` of `(void*)fp` prints the number via `stringFromPointerValue` (`CerbMem.lean:2027`) |

**Root cause is upstream of CerbMem: the fresh-symbol supply.** The oracle's Core parser draws
`Cerb_fresh.int()` for every symbol it parses (`parsers/core/core_parser.mly:184` and `:220`), and `std.core` +
the impl file are parsed BEFORE the user TU is desugared, so user symbols start hundreds later. Lean's `CoreParser`
mints `Symbol "" name.hash.toNat (SD_Id name)` (`lean_frontend/CoreParser.lean:243`) and draws nothing from the
supply, so the user TU starts near zero; in libc mode the 12 libc metadata TUs advance Lean's supply instead, so the
offset flips sign. Both engines are internally consistent (round-trips, equality, calls through `void *` all agree —
`p1_funptr_call` 6/6 executions identical), only the NUMBER leaks.

**Probes (verbatim in §8.A):**

| probe | oracle | cerberus-lean |
|---|---|---|
| `p1_funptr_intptr` `(intptr_t)&f & 0xfff` (nolibc) | `Specified(530)` | `Specified(47)` |
| `p1_funptr_value` `((ul)(void*)main + (ul)(void*)f) % 4096 + eq-tests` | `Specified(2008)` | `Specified(1042)` |
| `p1_funptr_bytes` low two bytes of a stored `int (*)(void)` | `Specified(502)` | `Specified(19)` |
| `p1_funptr_printf` `printf("%p", (void*)fp)` | stdout `(@empty, 0x283)` | stdout `(@empty, 0xa0)` |
| `p1_funptr_intptr_libc` same as the first, libc mode | `Specified(530)` | `Specified(645)` |

Derived: in nolibc mode oracle − Lean = 483 on every channel (530−47, (2008−1042)/2, 502−19, 0x283−0xa0).

**Why no lane saw it.** `tests/coverage/ptr3/ptr3-001-funcptr-to-int.libc.c` is the only corpus row that casts a
function pointer to an integer and it returns `x == 0 ? 1 : 0` (baseline `MATCH`,
`scripts/exec_coverage_baseline.txt:275`). The immaculate `%p` rows print object pointers only.

**Contract reading.** A served, different answer where the oracle answers: the fifth outcome. It is not class (a)
(the verdict, not failure text), not class (d) (no ISO ruling), not a resource outcome. It is also an instance of the
standing operator principle in VALIDATION §5 ("output depending on symbol numbering beyond binding identity is
itself a defect (registered finding + upstream candidate, never accommodated)") — the ORACLE's own value here is a
numbering artefact, moved by the tolerated renumbering class.

**Proposed disposition (for the operator):**
1. `intfromptr` on `PVfunction` → REFUSE (loud, feature-attributed: "function-pointer numeric identity is a
   fresh-symbol number on the oracle; not modelled"). This is the C-visible channel (`(intptr_t)f`, `%p` through
   `uintptr_t`), cheap, and pins a witness (`ptr3-001` would then move from MATCH to a pinned refusal — a lane
   movement to record).
2. The byte channel (`memValueToBytes`/`reconstructValue`) cannot be refused without breaking every program that
   stores a function pointer (they round-trip correctly). REGISTER it as a declared deviation class with the two
   witnesses above (`p1_funptr_bytes`, `p1_funptr_printf`) pinned as DIFF rows in the immaculate lane, and file the
   upstream-tray note (the oracle's function "address" is a symbol id).
3. Do NOT mirror the supply offset (fragile: it is the count of symbols in `std.core`+impl at the pinned oracle).
Both (1) and (2) are required before §1 of the contract is truthful; the alternative — a supply mirror — is the
"fifth outcome by construction" the contract forbids.

### P2 — reachable, no observed divergence, or a contract gap

- **P2-1 `--first` single-trace mode** (`lean_frontend/CerbND.lean` `runND1Fuel`, branch index 0 always; the oracle
  `--mode=random` draws from a time-seeded PRNG, `util/cerb_any.ml:1`, `driver_ocaml.ml`). Documented in the seam
  header as a "deliberate divergence (trace selection only)"; the libc_exec/chvalid lanes run in this mode and are
  sound only for trace-independent programs. The draft contract §2 declares "sequential execution" but not this
  mode: a trace-sensitive program compared in `--first` mode can produce two different served verdicts, both members
  of the exhaustive set. Disposition: name `--first` in CONTRACT §2 as a harness projection outside the §1 promise
  (or restrict the lanes that use it to exhaustive). No probe divergence (all my probes ran exhaustive).
- **P2-2 stale reachability claims in the register** — see P3-1/P3-2; listed here because a register entry that
  claims a served deviation which does not exist misstates the served surface.

### P3 — hygiene (no served divergence; text/reachability corrections)

- **P3-1 `CerbUtils.bounded_integer` (`CerbUtils.lean:61-66`, pins `lo`; `any.lem:6`).** The seam comment and
  VALIDATION's Z2-U-02 say it is "reached only by programs that use it explicitly". It is NOT reachable: the live
  stepper is `Core_reduction` (driver.lem:457-608 `drive_core_thread2` → `Core_reduction.core_step2`), whose builtin
  table has `BuiltinFunction "any_bounded_int" -> error "TODO Core_reduction ==> any_bounded_int()"`
  (`core_reduction.lem:1012-1013`); the table that calls `bounded_integer` (`core_run.lem:1076-1086`) is inside
  `Core_run.core_thread_step2` (`core_run.lem:774`), which no generated module outside `Core_run.lean` references.
  Probes `p2_any_random/fixed/inverted`: oracle `internal error: TODO Core_reduction ==> any_bounded_int()` (rc 125),
  Lean `PANIC … TODO Core_reduction ==> any_bounded_int()` (rc 134) — a mirrored failure, class (a). Disposition:
  reclassify Z2-U-02 UNREACHABLE (mirrored TODO); delete the `lo` pin or make it `failwithI` so it cannot become a
  silent answer if the stepper ever changes.
- **P3-2 `CerbUtils.gcc_builtin_ctz` panic at 0 (`CerbUtils.lean:118-121`).** Unreachable: `std.core:815-825`
  `ctz_proxy` returns `undef(<<DUMMY(__builtin_ctz)>>)` for 0 before `pcall(<builtin_ctz>)`. Probe `p2_ctz0`: both
  `Undefined {ub: "DUMMY(__builtin_ctz)", …}`. Keep (honest mirror of the OCaml assert), note the guard.
- **P3-3 `CerbMem.reconstructValue` fallback `| _ => .MVunspecified ty` (`CerbMem.lean:1212`, `:1326`).** The OCaml
  `abst` asserts false on `Void | Array (_, None) | Function _ | FunctionNoParams _` (`impl_mem.ml:978-983`). The
  Lean arm covers exactly those shapes and returns a VALUE. Believed unreachable — every caller computes `sizeof`
  first, which fails on those shapes on both engines — but it is the pathleak shape (a default where the oracle
  crashes). Disposition: `failwithI "abst: type without a known size (impl_mem.ml:978-983 assert false)"`.
- **P3-4 degenerate comparison instances (`CerbMem.lean:295-304`).** `Ord PointerValue/MemValue/MemState := .eq`,
  `BEq Allocation/MemState := false`, `Ord Footprint` (base address only), `Ord IntegerValue` (`:297`, value only,
  provenance ignored). Reachability re-checked: the only lem structure keyed on `integer_value` is
  `signals: Map.map Mem.integer_value Mem.pointer_value` (`core_run_effect.lem:148`), initialised `Map.empty`
  (`:421`) and never inserted into; `footprint` is only consulted through `overlapping` (`mem.lem:33`). UNREACHABLE;
  the seam's reachability note is accurate. Leave, keep the standing obligation.
- **P3-5 `CerbConcurrency.lean`** (one def, `statically_satisfied … := true`, `:20`). Zero generated callers; the lem
  definition is `{hol; isabelle; tex}`-only, so the target_rep (`cmm_csem.lem:655`) is vestigial. Disposition:
  delete the module and the target_rep (or keep as an explicitly dead-listed stub); either way CONTRACT §3's
  concurrency row can drop the "[audit, high priority]" question — the answer is "unreachable, and default-mode
  atomics run through the shared lem on both engines" (§4).
- **P3-6 `CerbUtils.encode_character_constant` (`:76-77`).** `Int.emod n 256` where the OCaml is
  `Char.chr (Z.to_int n land 0xff)` (`decode.ml:223-225`); `Z.to_int` raises `Overflow` beyond 2^62 — not mirrored,
  unreachable (`%c` arguments are `int`). Leave.
- **P3-7 CerbPP `[AIL]`/`[CORE-PP]` placeholders in the exec cone** (`CerbPP.lean:207-236`): reach
  `Core_eval.lean:112,159`, `Driver.lean:437`, `GenTyping.lean:115,120`, `Cabs_to_ail_effect.lean:1376,1387` only
  inside `CerbDebug.print_debug_pure` thunks (level 0 on both engines) or failure text. Leave; keep the enumerated
  placeholder discipline.

## 3. Ledger

Classification key: MIRROR (matches the OCaml, cite checked), REFUSES (loud, feature-attributed), UNREACHABLE (with
the reason), SERVED-WITHOUT-MODEL (defect candidate). "Disposition" is the proposal, not a decision.

| Site | Returns | Class | Evidence / probe | Disposition |
|---|---|---|---|---|
| `CerbConcurrency.lean:20` `statically_satisfied … := true` | `true` | UNREACHABLE | no `CerbConcurrency` reference in `generated/` (grep); lem def `{hol;isabelle;tex}` (`cmm_csem.lem:654-656`) | delete module + target_rep, or list as dead |
| `CerbMem.lean:2858` `intfromptr` PVfunction arm | symbol number | MIRROR (`impl_mem.ml:2487-2488`) but **SERVED-WITHOUT-MODEL** of the number | `p1_funptr_intptr` 530 vs 47 | **refuse** (P1-1) |
| `CerbMem.lean:787-799` function-pointer bytes | symbol number bytes | MIRROR (`impl_mem.ml:1203-1210`); leaks on inspection | `p1_funptr_bytes` 502 vs 19 | **register + witness** (P1-1) |
| `CerbMem.lean:1104/1268` funptr read-back; `:2027` `stringFromPointerValue` | `PVfunction`/`PVconcrete n` | MIRROR (`impl_mem.ml:1047`; `pp_pointer_value` is at `:598` at this pin — the seam comment's `:563-572` is stale) | `p1_funptr_printf` `0x283` vs `0xa0` | register (P1-1) |
| `CerbMem.lean:1212, 1326` `reconstructValue` `\| _ => .MVunspecified ty` | unspecified value | UNREACHABLE (sizeof fails first); OCaml `assert false` `impl_mem.ml:978-983` | code read | make it `failwithI` (P3-3) |
| `CerbMem.lean:2128-2130` missing bytemap entry → unspecified byte | `{Prov_none, none, none}` | MIRROR (`impl_mem.ml:743-749`) | code read | leave |
| `CerbMem.lean:1711` `isSpecifiedIval := true` | `true` | MIRROR (`impl_mem.ml:2560-2561`) | code read | leave |
| `CerbMem.lean:1713-1718` `eq/lt/leIval` total `some` | `some b` | MIRROR (`impl_mem.ml:2600-2605` at this pin — the seam's tripwire comment still cites `:2556-2562`, stale); makes `PEconstrained`/`NDguard` unreachable (`core_eval.lem:352-380` gated on `Nothing`) | code read | leave; refresh the cite |
| `CerbMem.lean:295-304` degenerate `Ord`/`BEq` instances; `:297` `Ord IntegerValue` value-only | `.eq`/`false`/value order | UNREACHABLE (`signals` map never populated, `core_run_effect.lem:148,421`; footprint never a key) | code read | leave (P3-4) |
| `CerbMem.lean:1903, 2020` `CerbDebug.get_level` arms | bare name / bare number | MIRROR (batch driver level 0 both sides; `pp_symbol.ml:13-19`, `impl_mem.ml:576-580`) | code read | leave |
| `CerbMem.lean` 19 `has_switch …` arms | default arm | MIRROR (`CerbGlobal.switches = []`, every non-default switch refused at the CLI, `Main.lean:1209-1220`) | code read | leave |
| `CerbMem.lean:3057-3061` `update_prefix` non-`Prov_some` → `memReturn ()` | unit | MIRROR (`impl_mem.ml:1356-1362`, OCaml warns on TOOL stderr) | code read | leave |
| `CerbMem.lean:2686-2716` `lt/gt/le/ge_ptrval` wildcard → `MerrWIP` | failure | MIRROR | `p1_funptr_rel` both `Error {msg: "Memory WIP: lt_ptrval"}` | leave |
| `CerbUtils.lean:61-66` `bounded_integer := lo` | `lo` | UNREACHABLE (live stepper errors first, `core_reduction.lem:1012-1013`) | `p2_any_*` both TODO crash | reclassify Z2-U-02; make `failwithI` (P3-1) |
| `CerbUtils.lean:109-170` ffs/ctz/bswap16/32/64 | Z semantics / panics | MIRROR (`ocaml_gcc_builtins.ml:3-51`) | `p2_gcc_builtins2` both `73413210`; `p2_bswap64_big` both overflow-crash; `p2_bswap16_neg` both `65535`; `p2_ctz0` both UB | leave (P3-2 note) |
| `CerbUtils.lean:76-77` `encode_character_constant` | `n mod 256` | MIRROR (`decode.ml:223-225`; `Z.to_int` overflow not mirrored, unreachable) | `p2_printf_c_edge` both `"[\127\|\200\|\255\|,\|\000]\n"` | leave (P3-6) |
| `CerbUtils.lean:88-89` `is_power_of_two` | `n > 0 && …` | MIRROR (`cerb_util.ml:79-84`: `n land (pred n) = zero`, false for 0 and negatives) | code read | leave |
| `CerbUtils.lean:19-31` timing/`STD_` identities | `()` / `x` | MIRROR (value identities; not observable) | code read | leave |
| `CerbDecode.lean:21-25` `readDigit` non-digit → 0 | `0` | UNREACHABLE (lexer-guaranteed digits; the char decoder validates spans first, `:128-144`) | code read | leave |
| `CerbDecode.lean:40-41` empty integer constant | `failwithI` | REFUSES (Z2-DC-01) | code read | leave |
| `CerbDecode.lean:114` `'\?' = 63`; `:183-194` `escaped_char` hex | value | REGISTERED class (d) R1/R2 | register rows pinned in `tests/immaculate` | leave |
| `CerbFloat.lean:287-303` `of_string` malformed → `failwithI`; `:422-433` `truncToInt` nan/inf → `failwithI` | failure | MIRROR (OCaml `Failure`/`Z.Overflow`) | `p4_float_lit` both `1132`; `p4_float_int` both `365`; `p4_float_ub` both UB017 | leave |
| `CerbFloat.lean:346-415` `formatFixed`/`string_of_float` | text | MIRROR (glibc `%.<p>f`/`%.12g`) | `p2_printf_f` both identical incl. 1e300 digits; `p2_printf_f2` identical | leave |
| `CerberusImpl.lean:95` `register_enum := true` | `true` | MIRROR by argument (`cabs_to_ail_effect.lem:1778-1794` catches the redefinition before the call; `enum_compatible_type` `implementation.lem:37-39` = `ocaml_implementation.ml:130-136`) | `p4_enum` both `44008`; `p4_enum_dup` both constraint violation | leave |
| `CerberusImpl.lean:147-152` `n_t_aliases` `\| _ => none`; `:283-298` `alignof_ty` `none` arms | `none` | MIRROR (`ocaml_implementation.ml:155-160`; the `none` is consumed by layout panics) | code read | leave |
| `CerberusImpl.lean:28-29` `sizeof_pointer`/`alignof_pointer = some 8` | LP64 constants | MIRROR (declared configuration) | lanes | leave |
| `CerbGlobal.lean:160-213` mode `none`, every flag `false`, `switches = []` | defaults | MIRROR (matched mode) + REFUSES at CLI for anything else | `refuseFlag` | leave |
| `CerbTags.lean:33-34` `tagDefsUnreachable` | `panic!` | REFUSES (reader-lifting defect if reached) | code read | leave |
| `CerbDebug.lean:28-46` `get_level = 0`, `warn`/`print_*` no-ops | `0` / `()` | MIRROR for verdicts (oracle prints to TOOL stderr, level-gated at 0 except `print_unsupported`, cerb_debug.ml:36-49; tool stderr is not compared) | code read | leave |
| `CerbPP.lean:207-236` residual placeholders | `"<…>"` | UNREACHABLE for verdicts (debug thunks / failure text) | grep of generated callers | leave (P3-7) |
| `CerbPP.lean:36-185` symbol/ctype/value/pointer/float printers | text | MIRROR (cites in-file; `%p` of object pointers) | `p2_printf_p` both `(@2, 0xffffffffffe8)`, `NULL(void)` | leave |
| `CerbLocation.lean:233-240` `simpleLocation` | verdict `loc:` text | MIRROR (`cerb_location.ml:476-491`) | every UB probe agrees byte-for-byte on `loc` | leave |
| `CerbLocation.lean:132-134` `outerBbox []` | `failwithI` | REFUSES (Z2-L-02) | code read | leave |
| `CerbND.lean` `runNDFuel` NDguard/NDbranch arms | continue / both sides | UNREACHABLE (Z-59, re-derived: `PEconstrained` producers `core_eval.lem:352-380` need `Nothing` from eq/lt/le_ival; concrete gives `some`; `ifM`/`addConstraints` callers are `defacto_memory.lem` (dead) and `driver.lem:152` on the `PEconstrained` path) | code read | leave |
| `CerbND.lean` `runND1Fuel` (`--first`) branch 0 | one trace | DECLARED divergence, harness mode | — | name in CONTRACT §2 (P2-1) |
| `CerbCall.lean` (`--call`) `default` annotations, `:293` other-error kill | harness | port-side mode (no oracle counterpart) | test_verify.sh | leave; outside §1 |
| `CabsImport.lean:70-135` every `\| _ =>` | `err …` | REFUSES (fail-closed JSON import; `getNat` rejects negatives/non-integers `:110-120`) | code read | leave |
| `CoreParser.lean:243` `mkSym name.hash` | hash symbol | MIRROR of binding identity only; NOT of the number — the root of P1-1 | `p1_funptr_*` | see P1-1 |
| `CoreParser.lean` 23 parser `\| _ =>` fallthroughs | parse alternatives | parser combinators over the oracle's own `--pp core` text (pinned by hash) | core-parser tests | leave |
| `CerbStepInstances.lean:107-204` structural `false`/`failwithI` on functional payloads | `false`/panic | MIRROR (OCaml compare raises on closures too); only `Step_blocked2` is ever compared (seam header note; the `Step_blocked2` tests sit at `driver.lem:487,921,988,1183` at this pin — the note's `:1376,1410` is stale) | code read | leave; refresh the cite |
| `CerbCtypeInstances.lean:47-51` `Inhabited ctype := Void0` | default | UNREACHABLE (only a `panic!` recovery value; aborted under `LEAN_ABORT_ON_PANIC`, refused otherwise `Main.lean:1234-1239`) | code read | leave |
| `CerbCabsInstances.lean` enum `BEq` `\| _, _ => false` | structural | MIRROR | code read | leave |
| `Main.lean:1321-1323` `--args` split | argv | MIRROR (`backend/driver/main.ml:111-113` `Str.split "[ \t]+"`) | argv lane | leave |
| `Main.lean:1080-1112` batch printer | verdict lines | MIRROR (`driver_ocaml.ml:111-196`) | every probe's line shape | leave |
| `Main.lean:1209-1220` `refuseFlag`; `:1234-1239` `LEAN_ABORT_ON_PANIC` | exit 2 | REFUSES | — | leave |
| `CerbFS.lean:238-541` 32 `fs_*` entry points (`fs.lem:75-171` target_reps) + `fs_initial_state := default` (`:172`) | — | OUT OF SCOPE (D2 refuses); list confirmed: open close write read mkdir pwrite pread rename umask chmod chdir chown link readlink symlink rmdir truncate unlink lseek stat lstat opendir readdir rewinddir closedir + 11 `FsStat` field readers, `fs_string_of_error`, `string_of_fs_state` | driver routes fds 1/2 before CerbFS (`driver.lem:355-365`) | D2 slice |

## 4. Priority 1 — concurrency in default mode

Reachability. `grep -rn CerbConcurrency lean_frontend/generated/` finds only `generated/CerbConcurrency.lean` itself;
`grep -rn statically_satisfied lean_frontend/generated/` likewise. The lem definition is
`let {hol; isabelle; tex} statically_satisfied …` (`cmm_csem.lem:656`) — it is not rendered for OCaml or Lean; the
Lean target_rep at `:655` maps a name nothing emits. The other 24 `LemUnsupported.Cmm.*` target_reps in
`cmm_csem.lem` are likewise unrendered (`grep LemUnsupported lean_frontend/generated/` = 0). `Driver.lean` imports
`Cmm_op`/`Cmm_csem` but its only mention is a type comment (`Driver.lean:468`). Default mode on BOTH engines runs the
shared lem: `Epar` from the par statement (`translation.lem:4203-4208` `A.AilSpar`), `Eunseq`, atomic loads/stores
with memory orders, and `Core_reduction`'s `TODO[Core_reduction]: …` errors for fences and CAS.

Probes (§8.B), all `--nolibc`, oracle exhaustive vs Lean exhaustive, verdict sets compared:

| probe | result |
|---|---|
| `p1_atomic_inc` (`x++`, `x += 2` on `_Atomic int`) | both: constraint violation §6.5.16.2#1 (oracle text) / `Error {msg: "typechecking failed …"}` (class (a)) |
| `p1_atomic_ops` (assign/load `_Atomic int`, `_Atomic unsigned char`, through `_Atomic int *`) | both `Specified(270)` |
| `p1_atomic_struct` (`_Atomic struct` copy in/out) | both `Specified(10)` |
| `p1_at_store` / `p1_at_load` (`atomic_store_explicit` relaxed / `atomic_load_explicit` acquire) | both `Specified(7)` / `Specified(5)` |
| `p1_at_cas`, `p1_stdatomic4` (CAS strong / weak) | both `TODO[Core_reduction]: CompareExchangeStrong` / `…Weak` (oracle rc 125, Lean PANIC rc 134) |
| `p1_at_fence` (`atomic_thread_fence`) | both `TODO[Core_reduction]: Fence` |
| `p1_at_xchg` (`atomic_exchange_explicit`) | both `[Translation => 'AilEcall'] fatal error, the Ail program was ill-typed` |
| `p1_stdatomic5` (`atomic_signal_fence`) | both `ill-formed program: calling an unknown procedure` (symbol NUMBER differs in the text: `Symbol(562, …)` vs `Symbol(86, …)` — class (a), and the same supply offset as P1-1) |
| `p1_par` `{-{ x = 1; \|\|\| x = 2; }-}`, `p1_par_atomic` (3 arms on `_Atomic int`) | both exactly one execution, `Specified(1)` |
| `p1_unseq` `f(&x) + g(&x)` | both 40 verdict lines: 20× `Specified(31)`, 20× `Specified(32)` |
| `p1_unseq_ub` `i++ + i++` | both `Undefined {ub: "UB035_unsequenced_race", stderr: "", loc: "<1:37--1:46>"}` |
| `p1_threads` (`<threads.h>`) | both fail in the header: `TODO: Tspec_name, not resolved` / `desugaring failed at …threads.h:9:9` |

Conclusion: no served default in the concurrency surface; the CONTRACT §3 concurrency row's open question closes as
"unreachable stub; default-mode atomics are the shared lem on both engines; the `--concurrency` flag is refused
(`Main.lean:1213-1214`)". The `Symbol(n, …)` numbers in failure text are the same supply offset as P1-1 — harmless
there (class (a)), decisive in P1-1.

## 5. Priority 2 — the builtin boundary

Where the 36 `builtin` declarations of `runtime/libcore/std.core` are served on Lean (derived from reading
`driver.lem`/`core_reduction.lem`; the generated Lean is the same lem):

| builtin(s) | live dispatch | Lean-specific seam inside | state |
|---|---|---|---|
| `printf`, `vprintf`, `vsnprintf` | `driver.lem:409-450` `FS_PRINTF/FS_VPRINTF/FS_VSNPRINTF` → `Formatted.*` (shared lem) | `CerbPP.stringFromPointerValue` (`%p`), `CerbPP.format_string_of_float` (`%f`), `CerbDecode.encode_character_constant`/`escaped_char` (`%c`, R2), `CerbMem` loads | MIRROR; probes agree (§8.C); `%n` is `WIP: Formatted.convert, CS_n` on both; `%e/%g/%a/%Lf/%#…` are `Invalid_format` UB on both; unsupported flag combinations `TODO: formatted.lem 6` on both |
| `exit` | `core_reduction.lem:1029` | — | MIRROR; `exit(-1)`, `exit(256)`, `atexit` order agree |
| `errno` | `core_reduction.lem:1017-1024`; allocation `driver.lem:1870` | `CerbMem` | MIRROR; `p2_errno_basic` both `Specified(50)`, `p2_errno_strtol` both `Specified(10)` |
| `any_bounded_int` | `core_reduction.lem:1012-1013` `error "TODO …"` | (`CerbUtils.bounded_integer` is only reached from the dead `Core_run.core_thread_step2` table) | mirrored TODO crash on both; register entry Z2-U-02 stale (P3-1) |
| `generic_ffs`, `ctz`, `bswap16/32/64` | `core_reduction.lem:1046-1119` | `CerbUtils.gcc_builtin_*` (`CerbUtils.lean:109-170`) | MIRROR; `p2_gcc_builtins2` both `Specified(73413210)`; overflow both crash; `ctz(0)` both UB via the proxy |
| `rename`, `mkdir`, `stat`, `lstat`, `umask`, `chmod`, `chdir`, `chown`, `opendir`, `readdir`, `rewinddir`, `closedir`, `open`, `write`, `read`, `close`, `pwrite`, `pread`, `link`, `readlink`, `symlink`, `rmdir`, `truncate`, `unlink`, `lseek` (25) | `driver.lem:355-407` → `Fs.fs_*` = CerbFS, except `write` fd 1/2 → `update_stdout/stderr` (`:359-362`) and fd 0 → `error "stdin not supported yet"` (`:357-358`) | CerbFS | OUT OF SCOPE here (D2); entry list confirmed in §3 |

Adversarial printf probes that AGREED (verbatim §8.C): `%c` of 127/200/-1/300/0 (`"[\127|\200|\255|,|\000]\n"`,
return 12 both), `%.3s`/`%.2s` on a non-NUL-terminated 3-byte array, `%d` with a `double`, missing argument,
unknown `%y`, `%f`/`%.0f`(0.5→`0`, 1.5→`2`)/`%.2f`(2.675→`2.67`)/`%08.2f`(-3.5→`000-3.50`)/1e300 (all 301 digits)/
`%.20f`(0.1)/1e22, `float` promotions, `%Lf`, `%a`, `%#…`. Standard input/environment (§8.D, libc mode): `getchar()`
→ EOF both, `read(0, …)` → negative both, `getenv("HOME")` → NULL both.

Probes that did not complete: `p2_errno` (20-digit `strtol` in exhaustive mode) timed out on BOTH sides at 300 s —
`matching_incomplete`, not evidence.

## 6. Priority 3 — CerbDebug / CerbPP

- `debug.lem:27` `declare lean target_rep function get_level u = 0`; the oracle's `Cerb_debug.get_debug_level` is
  the batch driver's level, 0 unless `--debug-level` (not a lane flag). The two `CerbMem` arms conditioned on it
  (`:1903` `name{n}` at level > 4, `:2020` `<prov>:n` at level ≥ 3) therefore take the same branch on both engines.
- `CerbDebug.print_debug_pure`/`print_debug_located` are no-ops; the oracle prints to TOOL stderr only when
  `!debug_level >= level` (`cerb_debug.ml:36-41`) — level 0 in every lane. `warn` prints only when `!debug_level > 1`
  (`:47-49`; the lem `warn` has no `~always`). `print_unsupported` prints unconditionally on the oracle (`:43-45`) —
  its only lem callers (`translation_effect.lem:250-265`) end in an `error` crash on both engines (declared EXC(a)
  Z2-U-01; I confirmed the caller set by grep: `generated/Translation_effect.lean` only).
- The program's `stdout`/`stderr` records compared by the lanes (`test_exec.sh`, VALIDATION §4) come from
  `dres_stdout`/`dres_stderr` (driver `update_stdout/stderr`), never from the tool's stderr. No verdict path reads a
  CerbDebug or CerbPP placeholder value: every `CerbPP.stringFrom{Ail,Core}_*` reference in the exec cone is inside a
  `print_debug_pure` thunk (`Core_eval.lean:112,159`; `Driver.lean:437`; `GenTyping.lean:120`;
  `Cabs_to_ail_effect.lean:1376,1387`) or in an `Error`/typing message (`GenTyping.lean:115`, `Core_reduction.lean:493`
  region) — class (a) text.
- `CerbPP.stringFromCore_value` `.Vctype` arm (`CerbPP.lean:101-108`) is a documented text divergence on a
  debug/`OtherValue`-only path; `batchExitValue` renders `main`'s integer return. Leave.

## 7. What must change before the contract can truthfully be adopted

1. **P1-1 (must):** decide the function-pointer numeric identity: REFUSE `intfromptr` on `PVfunction`
   (`CerbMem.lean:2858`) with a feature-attributed message; REGISTER the byte-inspection/`%p` channel as a declared
   deviation class in VALIDATION §3 and CONTRACT §1(4) with pinned immaculate witnesses (`p1_funptr_bytes`,
   `p1_funptr_printf`, and `ptr3-001` moving MATCH → refusal); add the upstream-tray note (the oracle's function
   address is a fresh-symbol id, moved by the tolerated renumbering class). Until then §1 has a fifth outcome.
2. **P2-1 (must, text):** CONTRACT §2 must name `--first` as a harness projection outside the §1 promise (or the lanes
   that use it must be restricted to trace-independent programs, which is what they implicitly assume).
3. **P3-1 (should):** correct Z2-U-02 (`CerbUtils.lean:44-59` comment, VALIDATION §3): `any_bounded_int` is a
   mirrored `TODO` crash, not a served `lo`; make `bounded_integer` a `failwithI` so a future stepper change cannot
   turn it into a silent answer.
4. **P3-3 (should):** `CerbMem.reconstructValue`'s `| _ => .MVunspecified ty` (`:1212`, `:1326`) → `failwithI`,
   mirroring `impl_mem.ml:978-983`.
5. **P3-5 (should):** delete `CerbConcurrency.lean` + `cmm_csem.lem:655`'s target_rep (dead), and rewrite CONTRACT §3's
   concurrency row from the evidence in §4; the D4 builtin table can adopt §5's dispatch column as its "where served"
   evidence.
6. **Adversarial rows (should, contract §4.3):** add the probes of §8 that are not already corpus rows to
   `tests/immaculate` so the enforcement clause has teeth on this surface: at minimum `p1_funptr_intptr`,
   `p1_funptr_bytes`, `p1_funptr_printf` (pinned per decision 1), `p1_par`, `p1_at_store`, `p1_at_load`,
   `p2_printf_c_edge`, `p2_printf_s_nonul`, `p2_snprintf`, `p2_exit_codes`, `p2_gcc_builtins2`.

## 8. Verbatim probe outputs

Every probe below was run as: oracle `main.exe --runtime=<primary>/_build/install/default [--nolibc] --exec --batch
--mode=exhaustive F.c`; Lean `main.exe --cabs-json F.c > F.json` then, from the primary checkout root,
`LEAN_ABORT_ON_PANIC=1 scripts/capped lean_frontend/.lake/build/bin/cerberus-lean --batch F.json [--libc
tests/libc/libc.core --libc-tu <12 jsons>]`, `timeout 60`/`120`/`300` per run. Lines are the verdict lines of each
engine's output, deduplicated with a count prefix (`Nx`) where the exhaustive set had several; PANIC lines are the
Lean abort's first line; `internal error` lines are the oracle's. Nothing else is quoted.

## A. Function-pointer numeric identity (P1)

### p1_funptr_intptr (nolibc)

```c
#include <stdint.h>
int f(void) { return 1; }
int main(void) { intptr_t x = (intptr_t)&f; return (int)(x & 0xfff); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(530)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(47)", stdout: "", stderr: "", blocked: "false"}
```

### p1_funptr_value (nolibc)

```c
int f(void) { return 1; }
int g(void) { return 2; }
int main(void) {
  unsigned long a = (unsigned long)(void*)main;
  unsigned long b = (unsigned long)(void*)f;
  int same = ((void*)f == (void*)g) ? 100 : 0;
  int eq = ((void*)f == (void*)f) ? 1000 : 0;
  return (int)((a + b) % 4096) + same + eq;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(2008)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1042)", stdout: "", stderr: "", blocked: "false"}
```

### p1_funptr_bytes (nolibc)

```c
int f(void) { return 1; }
int main(void) {
  int (*fp)(void) = f;
  unsigned char *b = (unsigned char *)&fp;
  return b[0] + b[1] * 256;   /* low two bytes of the stored function pointer */
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(502)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(19)", stdout: "", stderr: "", blocked: "false"}
```

### p1_funptr_printf (nolibc)

```c
#include <stdio.h>
int f(void) { return 1; }
int main(void) { int (*fp)(void) = f; printf("%p\n", (void*)fp); printf("%p\n", (void*)&f); return fp(); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1)", stdout: "(@empty, 0x283)\n(@empty, 0x283)\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1)", stdout: "(@empty, 0xa0)\n(@empty, 0xa0)\n", stderr: "", blocked: "false"}
```

### p1_funptr_call (nolibc)

```c
int f(void) { return 1; }
int g(void) { return 2; }
int main(void) { int (*fp)(void) = f; int (*gp)(void) = g; void *v = (void*)fp; int (*back)(void) = (int(*)(void))v; return back() * 10 + gp(); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
6x Defined {value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
6x Defined {value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}
```

### p1_funptr_rel (nolibc)

```c
int f(void) { return 1; }
int g(void) { return 2; }
int main(void) { return ((void*)f < (void*)g) ? 1 : 2; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Error {msg: "Memory WIP: lt_ptrval"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "Memory WIP: lt_ptrval"}
```

### p1_funptr_diff (nolibc)

```c
int f(void) { return 1; }
int g(void) { return 2; }
int main(void) { return (int)((char*)g - (char*)f); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Error {msg: "MerrOther "called isWellAligned_ptrval on function pointer""}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "MerrOther "called isWellAligned_ptrval on function pointer""}
```

### p1_funptr_intptr_libc (libc)

```c
#include <stdint.h>
int f(void) { return 1; }
int main(void) { intptr_t x = (intptr_t)&f; return (int)(x & 0xfff); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(530)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(645)", stdout: "", stderr: "", blocked: "false"}
```

## B. Concurrency constructs in default mode

### p1_atomic_inc (nolibc)

```c
_Atomic int x = 0;
int main(void) { x++; x += 2; int y = x; return y; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x /home/dev/projects/cerberus-lean-proj/.tmp/served-surface-audit/p1_atomic_inc.c:2:25: error: constraint violation: invalid operands to binary expression ('atomic signed int' and 'signed int')
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "typechecking failed at /home/dev/projects/cerberus-lean-proj/.tmp/served-surface-audit/p1_atomic_inc.c:2:23-29"}
```

### p1_atomic_ops (nolibc)

```c
_Atomic int a = 5;
_Atomic unsigned char c = 250;
_Atomic int *p = &a;
int main(void) {
  a = 9;            /* atomic store via assignment */
  int r = a;        /* atomic load */
  c = c;            /* load + store */
  *p = 11;
  int s = *p;
  _Atomic int b = r + s;
  return b + c;     /* 9 + 11 + 250 = 270 */
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(270)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(270)", stdout: "", stderr: "", blocked: "false"}
```

### p1_atomic_struct (nolibc)

```c
struct S { int a; int b; };
_Atomic struct S s = { 1, 2 };
int main(void) { struct S t = s; struct S u = { 3, 4 }; s = u; struct S w = s; return t.a + t.b + w.a + w.b; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}
```

### p1_at_store (nolibc)

```c
#include <stdatomic.h>
_Atomic int a = 5;
int main(void) { atomic_store_explicit(&a, 7, memory_order_relaxed); return a; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

### p1_at_load (nolibc)

```c
#include <stdatomic.h>
_Atomic int a = 5;
int main(void) { int v = atomic_load_explicit(&a, memory_order_acquire); return v; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
```

### p1_at_cas (nolibc)

```c
#include <stdatomic.h>
_Atomic int a = 5;
int main(void) { int exp = 5; _Bool ok = atomic_compare_exchange_strong_explicit(&a, &exp, 42, memory_order_acq_rel, memory_order_relaxed); int exp2 = 0; _Bool ok2 = atomic_compare_exchange_strong_explicit(&a, &exp2, 43, memory_order_seq_cst, memory_order_seq_cst); return (ok ? 100 : 0) + (ok2 ? 1000 : 0) + a + exp2; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: TODO[Core_reduction]: CompareExchangeStrong")
1x internal error: TODO[Core_reduction]: CompareExchangeStrong
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: TODO[Core_reduction]: CompareExchangeStrong
```

### p1_at_fence (nolibc)

```c
#include <stdatomic.h>
int main(void) { atomic_thread_fence(memory_order_release); atomic_thread_fence(memory_order_seq_cst); return 4; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: TODO[Core_reduction]: Fence")
1x internal error: TODO[Core_reduction]: Fence
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: TODO[Core_reduction]: Fence
```

### p1_at_xchg (nolibc)

```c
#include <stdatomic.h>
_Atomic int a = 5;
int main(void) { int ex = atomic_exchange_explicit(&a, 1, memory_order_seq_cst); return ex * 10 + a; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: [Translation => 'AilEcall'] fatal error, the Ail program was ill-typed")
1x internal error: [Translation => 'AilEcall'] fatal error, the Ail program was ill-typed
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: [Translation => 'AilEcall'] fatal error, the Ail program was ill-typed
```

### p1_stdatomic4 (nolibc)

```c
#include <stdatomic.h>
_Atomic int a = 5;
int main(void) {
  int exp2 = 0;
  _Bool bad = atomic_compare_exchange_weak_explicit(&a, &exp2, 99, memory_order_seq_cst, memory_order_seq_cst);
  return (bad ? 1000 : 0) + exp2; /* 0 + 5 */
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: TODO[Core_reduction]: CompareExchangeWeak")
1x internal error: TODO[Core_reduction]: CompareExchangeWeak
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: TODO[Core_reduction]: CompareExchangeWeak
```

### p1_stdatomic5 (nolibc)

```c
#include <stdatomic.h>
int main(void) { atomic_signal_fence(memory_order_acquire); return 3; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(562, SD_Id("atomic_signal_fence"))'"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(86, SD_Id("atomic_signal_fence"))'"}
```

### p1_par (nolibc)

```c
int x = 0;
int main(void) {
  {-{ x = 1; ||| x = 2; }-}
  return x;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

### p1_par_atomic (nolibc)

```c
_Atomic int x = 0;
int main(void) {
  {-{ x = 1; ||| x = 2; ||| x = 3; }-}
  return x;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

### p1_unseq (nolibc)

```c
int f(int *p) { *p = 1; return 1; }
int g(int *p) { *p = 2; return 2; }
int main(void) { int x = 0; int r = f(&x) + g(&x); return r * 10 + x; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
20x Defined {value: "Specified(31)", stdout: "", stderr: "", blocked: "false"}
20x Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
20x Defined {value: "Specified(31)", stdout: "", stderr: "", blocked: "false"}
20x Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}
```

### p1_unseq_ub (nolibc)

```c
int main(void) { int i = 0; int r = i++ + i++; return r; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "UB035_unsequenced_race", stderr: "", loc: "<1:37--1:46>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "UB035_unsequenced_race", stderr: "", loc: "<1:37--1:46>"}
```

### p1_threads (nolibc)

```c
#include <threads.h>
int g = 0;
int worker(void *arg) { (void)arg; g = 5; return 0; }
int main(void) {
  thrd_t t;
  thrd_create(&t, worker, 0);
  thrd_join(t, 0);
  return g;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x /home/dev/projects/cerberus-lean-proj/cerberus-lean/_build/install/default/lib/cerberus-lib/runtime/libc/include/threads.h:9:9: error: feature not yet supported: TODO: Tspec_name, not resolved
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "desugaring failed at /home/dev/projects/cerberus-lean-proj/cerberus-lean/_build/install/default/lib/cerberus-lib/runtime/libc/include/threads.h:9:9:"}
```

## C. Builtin boundary

### p2_any_random (nolibc)

```c
int __any_bounded_int(int, int);
#define any_bounded_int(a,b) __any_bounded_int(a,b)
int main(void) { int x = any_bounded_int(10, 20); return x; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: TODO Core_reduction ==> any_bounded_int()")
1x internal error: TODO Core_reduction ==> any_bounded_int()
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: TODO Core_reduction ==> any_bounded_int()
```

### p2_printf_c_edge (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%c|%c|%c|%c|%c]\n", 127, 200, -1, 300, 0); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(12)", stdout: "[\127|\200|\255|,|\000]\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(12)", stdout: "[\127|\200|\255|,|\000]\n", stderr: "", blocked: "false"}
```

### p2_printf_s_nonul (nolibc)

```c
#include <stdio.h>
int main(void) { char buf[3] = {'a','b','c'}; return printf("[%.3s|%.2s]\n", buf, buf); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(9)", stdout: "[abc|ab]\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(9)", stdout: "[abc|ab]\n", stderr: "", blocked: "false"}
```

### p2_printf_p (nolibc)

```c
#include <stdio.h>
int main(void) { int x; int *p = &x; void *q = 0; return printf("[%p|%p|%p]\n", (void*)p, q, (void*)main) > 0; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1)", stdout: "[(@2, 0xffffffffffe8)|NULL(void)|(@empty, 0x283)]\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1)", stdout: "[(@2, 0xffffffffffe8)|NULL(void)|(@empty, 0xa0)]\n", stderr: "", blocked: "false"}
```

### p2_printf_n (nolibc)

```c
#include <stdio.h>
int main(void) { int n = -1; int r = printf("abc%nde\n", &n); return r * 100 + n; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: WIP: Formatted.convert, CS_n")
1x internal error: WIP: Formatted.convert, CS_n
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: WIP: Formatted.convert, CS_n
```

### p2_printf_unknown (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%y|%d]\n", 5); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "Invalid_format[[%y|%d]
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "Invalid_format[[%y|%d]
```

### p2_printf_missing_arg (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%d %d]\n", 1); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "<2:25--2:47>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "<2:25--2:47>"}
```

### p2_printf_wrong_type (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%d|%s]\n", 3.5, 7); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<2:25--2:52>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<2:25--2:52>"}
```

### p2_printf_f (nolibc)

```c
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%f|%.0f|%.0f|%.1f|%.2f|%10.3f|%-10.3f|%+f|%08.2f]\n", 3.14159, 0.5, 1.5, 2.25, 2.675, 3.14159, 3.14159, 1.0, -3.5);
  r += printf("[%f|%f|%f|%.3f]\n", 1e300, -0.0, 1e-7, 2.0005);
  r += printf("[%.20f]\n", 0.1);
  r += printf("[%f]\n", 1e22);
  return r;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
16x Defined {value: "Specified(458)", stdout: "[3.141590|0|2|2.2|2.67|     3.142|3.142     |+1.000000|000-3.50]\n[1000000000000000052504760255204420248704468581108159154915854115511802457988908195786371375080447864043704443832883878176942523235360430575644792184786706982848387200926575803737830233794788090059368953234970799945081119038967640880074652742780142494579258788820056842838115669472196386865459400540160.000000|0.000000|0.000000|2.001]\n[0.10000000000000000555]\n[10000000000000000000000.000000]\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
16x Defined {value: "Specified(458)", stdout: "[3.141590|0|2|2.2|2.67|     3.142|3.142     |+1.000000|000-3.50]\n[1000000000000000052504760255204420248704468581108159154915854115511802457988908195786371375080447864043704443832883878176942523235360430575644792184786706982848387200926575803737830233794788090059368953234970799945081119038967640880074652742780142494579258788820056842838115669472196386865459400540160.000000|0.000000|0.000000|2.001]\n[0.10000000000000000555]\n[10000000000000000000000.000000]\n", stderr: "", blocked: "false"}
```

### p2_printf_f2 (nolibc)

```c
#include <stdio.h>
int main(void) { float f = 1.1f; return printf("[%f|%5.1f|%.15f]\n", f, f, 1.0/3.0); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(35)", stdout: "[1.100000|  1.1|0.333333333333333]\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(35)", stdout: "[1.100000|  1.1|0.333333333333333]\n", stderr: "", blocked: "false"}
```

### p2_printf_Lf (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%Lf]\n", 1.5L); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "Invalid_format[[%Lf]
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "Invalid_format[[%Lf]
```

### p2_printf_a (nolibc)

```c
#include <stdio.h>
int main(void) { return printf("[%a]\n", 1.0); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "Invalid_format[[%a]
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "Invalid_format[[%a]
```

### p2_printf_specs_ok (nolibc)

```c
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%5d|%-5d|%05d|%+d|% d|%x|%X|%#x|%#o|%o|%u]\n", 42, 42, 42, 42, 42, 255u, 255u, 255u, 8u, 8u, 4294967295u);
  r += printf("[%%|%c|%c|%s|%.3s|%5s|%-5s|%.0s]\n", 'a', 65, "hello", "hello", "hi", "hi", "gone");
  r += printf("[%10.3s|%-10.3s|%.10s]\n", "abcdef", "abcdef", "abc");
  r += printf("[%*d|%-*d|%.*d|%*.*d]\n", 6, 7, 6, 7, 4, 7, 8, 3, 7);
  r += printf("[%i|%d|%d]\n", -0, -2147483647-1, 2147483647);
  r += printf("[%lu|%lx|%llx|%ld|%lld]\n", 18446744073709551615ul, 0xdeadbeefcafebabeul, 0x123456789abcdef0ull, -3L, -4LL);
  r += printf("[%-08d|%08.3d|%.0d|%.0d|%+05d|% 05d|%-+6d]\n", 42, 42, 0, 7, 42, 42, 42);
  r += printf("[%x|%#x|%#X|%#o|%08x|%-8x|%.4x]\n", 0u, 0u, 0xabcu, 0u, 0xabcu, 0xabcu, 0xabcu);
  r += printf("[%5c|%-5c]\n", 'q', 'q');
  r += printf("[%hhd|%hd|%hhu|%hu|%zu|%td|%jd]\n", (signed char)-1, (short)-2, (unsigned char)255, (unsigned short)65535, (unsigned long)5, (long)-6, (long)-7);
  return r;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Failure("internal error: TODO: formatted.lem 6")
1x internal error: TODO: formatted.lem 6
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: TODO: formatted.lem 6
```

### p2_gcc_builtins2 (nolibc)

```c
int main(void) {
  int a = __builtin_ffs(0);           /* 0 */
  int b = __builtin_ffs(-1);          /* 1 */
  int c = __builtin_ffs(0x80000000);  /* 32 */
  int d = __builtin_ffsll(1LL << 40); /* 41 */
  int e = __builtin_ctz(8u);          /* 3 */
  int f = __builtin_bswap16((unsigned short)0x1234) == 0x3412;
  int g = __builtin_bswap32(0xdeadbeefu) == 0xefbeaddeu;
  int h = __builtin_bswap64(1ull) == 0x0100000000000000ull;
  return a + b * 10 + c * 100 + d * 10000 + e * 1000000 + f * 10000000 + g * 20000000 + h * 40000000;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(73413210)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(73413210)", stdout: "", stderr: "", blocked: "false"}
```

### p2_gcc_builtins (nolibc)

```c
int main(void) {
  int a = __builtin_ffs(0);           /* 0 */
  int b = __builtin_ffs(-1);          /* 1 */
  int c = __builtin_ffs(0x80000000);  /* 32 */
  int d = __builtin_ffsll(1LL << 40); /* 41 */
  int e = __builtin_ctz(8u);          /* 3 */
  int f = __builtin_bswap16((unsigned short)0x1234) == 0x3412;
  int g = __builtin_bswap32(0xdeadbeefu) == 0xefbeaddeu;
  int h = __builtin_bswap64(1ull) == 0x0100000000000000ull;
  int i = __builtin_bswap64(0x8000000000000000ull) == 0x80ull;
  return a + b * 10 + c * 100 + d * 10000 + e * 1000000 + f * 10000000 + g * 20000000 + h * 40000000 + i * 80000000;
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Z.Overflow
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)
```

### p2_ctz0 (nolibc)

```c
int main(void) { unsigned z = 0; return __builtin_ctz(z); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "DUMMY(__builtin_ctz)", stderr: "", loc: "<1:41--1:57>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "DUMMY(__builtin_ctz)", stderr: "", loc: "<1:41--1:57>"}
```

### p2_bswap16_neg (nolibc)

```c
int main(void) { int n = -1; return __builtin_bswap16(n); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(65535)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(65535)", stdout: "", stderr: "", blocked: "false"}
```

### p2_bswap64_big (nolibc)

```c
int main(void) { unsigned long long v = 0xffffffffffffffffull; return __builtin_bswap64(v) == v; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x           Z.Overflow
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)
```

### p2_libc_hello (libc)

```c
#include <stdio.h>
#include <stdlib.h>
int main(void) { printf("hello %d\n", 42); exit(3); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(3)", stdout: "hello 42\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(3)", stdout: "hello 42\n", stderr: "", blocked: "false"}
```

### p2_snprintf (libc)

```c
#include <stdio.h>
#include <string.h>
int main(void) {
  char buf[8];
  memset(buf, 'X', 8);
  int a = snprintf(buf, 4, "%d", 123456);      /* -> "123", returns 6 */
  int b = snprintf(buf + 4, 0, "%s", "zzz");   /* size 0: nothing written, returns 3 */
  int c = snprintf(NULL, 0, "%d%d", 12, 34);   /* returns 4 */
  int d = snprintf(buf, 8, "");                /* returns 0, buf = "" */
  return a * 1000 + b * 100 + c * 10 + (d == 0) + (buf[0] == 0 ? 0 : 50000) + (buf[4] == 'X' ? 0 : 60000);
}
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(3001)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(3001)", stdout: "", stderr: "", blocked: "false"}
```

### p2_exit_codes (libc)

```c
#include <stdio.h>
#include <stdlib.h>
int main(void) { printf("before"); exit(-1); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(-1)", stdout: "before", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(-1)", stdout: "before", stderr: "", blocked: "false"}
```

### p2_exit_256 (libc)

```c
#include <stdlib.h>
int main(void) { exit(256); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(256)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(256)", stdout: "", stderr: "", blocked: "false"}
```

### p2_exit_atexit (libc)

```c
#include <stdio.h>
#include <stdlib.h>
void bye(void) { printf("bye\n"); }
int main(void) { atexit(bye); printf("main\n"); exit(7); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(7)", stdout: "main\nbye\n", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(7)", stdout: "main\nbye\n", stderr: "", blocked: "false"}
```

### p2_errno_basic (libc)

```c
#include <errno.h>
int main(void) { int e0 = errno; errno = 5; int e1 = errno; errno = 0; return e0 * 100 + e1 * 10 + errno; }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
5x Defined {value: "Specified(50)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
5x Defined {value: "Specified(50)", stdout: "", stderr: "", blocked: "false"}
```

### p2_errno_strtol (libc)

```c
#include <errno.h>
#include <stdlib.h>
int main(void) { long v = strtol("99999999999", 0, 10); return (v == 99999999999L) * 10 + errno; }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
8192x Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
8192x Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}
```

### p2_errno (libc)

```c
#include <errno.h>
#include <stdlib.h>
int main(void) {
  int e0 = errno;                         /* initial: 0 */
  long v = strtol("99999999999999999999", 0, 10);
  int e1 = errno;                         /* ERANGE */
  errno = 0;
  long w = strtol("42", 0, 10);
  int e2 = errno;                         /* 0 */
  errno = 77;
  return e0 * 1000 + e1 * 10 + e2 + (v == 9223372036854775807L ? 100000 : 0) + (w == 42) + errno * 1000000;
}
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
(no verdict line: the oracle run hit the harness timeout, `timeout 300` -> rc 124 — exhaustive mode over strtol of a 20-digit string)
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
(no verdict line: the Lean run hit the harness timeout, `timeout 300` -> rc 124 — same program; a both-sides timeout, `matching_incomplete` per VALIDATION §4, never agreement)
```

## D. Standard input / environment

### p3_stdin (libc)

```c
#include <stdio.h>
int main(void) { int c = getchar(); return c == EOF ? 1 : c; }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

### p3_read0 (libc)

```c
#include <unistd.h>
int main(void) { char b[4]; long n = read(0, b, 4); return (int)(n < 0 ? 100 : n); }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}
```

### p3_getenv (libc)

```c
#include <stdlib.h>
int main(void) { char *h = getenv("HOME"); return h ? 1 : 2; }
```
oracle `--exec --batch --mode=exhaustive` (libc), distinct verdict lines (count x line):
```
1x Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` --libc <pinned libc.core> --libc-tu <12 jsons>, distinct verdict lines:
```
1x Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

## E. Implementation choices, floats, enums

### p4_enum (nolibc)

```c
enum E { A = -1, B = 5 };
enum F { C = 1, D = 2000000000 };
enum G { H = 1 };
int main(void) {
  int s1 = (A < 0) ? 1 : 0;                 /* signed enum: 1 */
  int s2 = ((enum G)H - 2 < 0) ? 10 : 0;    /* unsigned enum (GCC rule): 0 */
  int s3 = (A + 1u > 0) ? 100 : 0;          /* -1 + 1u = 0 -> 0 */
  unsigned long w = sizeof(enum E) * 1000 + sizeof(enum F) * 10000;
  return s1 + s2 + s3 + (int)w + (D > 0 ? 7 : 0);
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(44008)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(44008)", stdout: "", stderr: "", blocked: "false"}
```

### p4_enum_dup (nolibc)

```c
enum E { A = 1 };
enum E { B = 2 };
int main(void) { return A; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x /home/dev/projects/cerberus-lean-proj/.tmp/served-surface-audit/p4_enum_dup.c:2:1: error: constraint violation: redefinition of 'E'
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Error {msg: "desugaring failed at /home/dev/projects/cerberus-lean-proj/.tmp/served-surface-audit/p4_enum_dup.c:2:1:"}
```

### p4_float_int (nolibc)

```c
int main(void) {
  double a = -0.5, b = 3.99, c = -3.99, d = 1e9, e = 0x1p-1074, f = 2147483647.9;
  long r1 = (long)a, r2 = (long)b, r3 = (long)c, r4 = (long)d, r5 = (long)e;
  int r6 = (int)f;
  unsigned char u = (unsigned char)(255.7);
  return (int)(r1 + r2 + r3 + (r4 / 100000000) + r5 + (r6 == 2147483647) * 100 + u);
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(365)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(365)", stdout: "", stderr: "", blocked: "false"}
```

### p4_float_ub (nolibc)

```c
int main(void) { double x = 1e10; int i = (int)x; return i; }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<1:43--1:49>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<1:43--1:49>"}
```

### p4_float_neg_unsigned (nolibc)

```c
int main(void) { double x = -1.0; unsigned int u = (unsigned int)x; return (int)(u == 4294967295u); }
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<1:52--1:67>"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<1:52--1:67>"}
```

### p4_float_lit (nolibc)

```c
int main(void) {
  double a = 1e400 > 1e308 ? 1.0 : 0.0;      /* inf literal */
  double b = 0x1.8p1;                        /* 3.0 */
  float c = 16777217.0f;                     /* rounds to 16777216 */
  double d = .5, e = 1., g = 1e-400;         /* g underflows to 0 */
  return (int)(a * 100 + b * 10 + (c == 16777216.0f) + d * 2 + e + (g == 0.0) * 1000);
}
```
oracle `--nolibc --exec --batch --mode=exhaustive`, distinct verdict lines (count x line):
```
1x Defined {value: "Specified(1132)", stdout: "", stderr: "", blocked: "false"}
```
cerberus-lean `--batch` , distinct verdict lines:
```
1x Defined {value: "Specified(1132)", stdout: "", stderr: "", blocked: "false"}
```


---
End of record. Probe sources and raw outputs lived in the ephemeral container directory `.tmp/served-surface-audit/` and are reproduced above; the directory is deleted at slice end per the container's doc practice.
