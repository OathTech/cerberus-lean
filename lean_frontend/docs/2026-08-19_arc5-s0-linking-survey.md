# Arc 5 / S0 — dual-lineage linking survey (libc, builtins, multi-TU)

Date: 2026-08-19. Slice: S0 of the arc-5 charter
(`2026-08-19_arc5-libc-linking-charter.md`). NO code changed; this doc is
the slice's only artifact. All OCaml citations are against this worktree's
tree (= `mdd/cerberus-lean` + arc-5 charter commit); prototype citations
are against `cerberus-lean-prototype` (the design donor). Empirical
probes: OCaml `./scripts/cerberus --nolibc --exec --batch
--mode=exhaustive` (the exact `test_exec.sh` OCaml-side flags,
test_exec.sh:281) vs the Lean binary `cerberus-lean --batch <cabs-json>`
(test_exec.sh:289), cabs-json generated without `--nolibc`
(test_exec.sh:285) — matching the harness precisely.

## The failing surface (exact)

The 20 FAILs in `scripts/exec_coverage_baseline.txt`, every one
`Illformed_program: calling an unknown procedure`:

| family | files (20 total) | procedures called |
|---|---|---|
| builtin | builtin-001..005 | `__builtin_ffs`, `__builtin_ctz`, `__builtin_bswap16/32/64` |
| ctrl2 | ctrl2-003-errno.libc | `__builtin_errno` (via `errno` macro) |
| ctrl3 | ctrl3-001-malloc-computed-size.libc | `malloc`, `free` |
| libc | libc-001/003/004/005/006/007/008/009/010/013/014 | `malloc`, `free`, `realloc`, `memcpy`, `memcmp` |
| mem3 | mem3-007-realloc-null.libc | `realloc`, `free` |
| ptr2 | ptr2-009-eff-malloc-shift.libc | `malloc`, `free` |

Adjacent, NOT in the 20: io-001/002/003/005 (`printf`) are UNSUPPORTED
(`*.unsupported.c`); varargs-001..005 are DIFF (linking works, execution
diverges — see §c.iii); builtin-006 (`exit`) is CERB_SKIP because **OCaml
itself fails it under `--nolibc`** (probe: `calling an unknown procedure:
Symbol(66, SD_Id("exit"))` — exit/abort have no std.core proxy; they live
in the real libc.co, excluded by `--nolibc`); mem3-004 is DIFF for
unrelated reasons (string-literal write UB modelling, not linking).

## Map (a) — GROUND TRUTH: how OCaml resolves these under `--nolibc`

### The chain (all stages, with citations)

1. **cpp — cerberus shim headers are ALWAYS in play.**
   `create_cpp_cmd` (backend/driver/main.ml:38-52) adds
   `runtime/libc/include` (+`/posix`) to the include path unless
   `--nostdinc`, and force-includes `runtime/libc/include/builtins.h`
   (main.ml:51) unconditionally. `--nolibc` does exactly two things: it
   drops the `-DCERB_WITH_LIB` macro (main.ml:41) and skips linking the
   compiled C library `libc.co` (`core_libraries`, main.ml:54-78, called
   with `incl = not nolibc && not core_obj` at main.ml:156). So even
   under `--nolibc`, `stdlib.h` declares `malloc` as a plain extern
   (runtime/libc/include/stdlib.h:39), `errno.h` defines
   `errno` → `(*__builtin_errno())` (errno.h:14-15), `builtins.h`
   declares `__builtin_ffs/ctz/bswap*` as `[[cerb::hidden]]` C functions
   (builtins.h:2-11), and `stdarg.h` maps `va_*` to `__cerb_va_*`
   (stdarg.h:7-11, `typedef int va_list`).

2. **Core stdlib `std.core` is ALWAYS loaded** — independent of
   `--nolibc`. `load_core_stdlib` (backend/common/pipeline.ml:32-44)
   parses `runtime/libcore/std.core` in StdMode and returns
   `Rstd (ailnames, std_funs)`. std.core contains **libc proxy procs**
   tagged with an `[ailname = "C-name"]` attribute (46 of them):
   `errno_proxy` [`__builtin_errno`] :276, `printf_proxy` [`printf`]
   :289, `exit_proxy` [`__builtin_exit`] :346, `malloc_proxy` :350,
   `realloc_proxy` :360, `free_proxy` :371, `aligned_alloc_proxy` :379,
   `memcpy_proxy` :398, `memcmp_proxy` :410, `ffs_proxy`
   [`__builtin_ffs`] :782 (+ffsl/ffsll), `ctz_proxy` :814,
   `bswap16/32/64_proxy` :826/835/844, plus POSIX fs proxies. Proxy
   bodies are ordinary Core: `malloc_proxy` does `alloc(IvMaxAlignment,
   size)` (std.core:350-357), `free_proxy` does `free(p)` (:371-377),
   `realloc_proxy`/`memcpy_proxy`/`memcmp_proxy` do
   `memop(Realloc/Memcpy/Memcmp, ...)` (:360-368, :398-407, :410-419),
   `ffs_proxy` etc. do `pcall(<builtin_generic_ffs>, n)` (:780-788),
   `printf_proxy` marshals the format string into a `[integer]` via
   `pcall(listFromStr, ...)` then `pcall(<builtin_printf>, xs, args)`
   (:289-297).

3. **The core parser registers the ailname attribute.** In
   `parsers/core/core_parser.mly`, `register_ailname str sym`
   (:157-159) is invoked exactly when a `Proc_decl` carries the
   attribute (`hasAilname attrs` → :1037-1041); StdMode returns
   `Rstd (st.ailnames, fun_map)` (:1076-1080). The map is therefore
   **attribute-string → proxy symbol** ("malloc" ↦ `malloc_proxy`'s
   sym), 46 entries — NOT proc names. `builtin` declarations (e.g.
   `builtin printf` std.core:283) become `BuiltinDecl` fun_map entries
   (:1020-1026) and register NO ailname. `<builtin_X>` tokens in proxy
   bodies lex to `Impl (BuiltinFunction "X")`
   (parsers/core/core_lexer.mll:214; constructor
   frontend/model/implementation.lem:249, string form
   `"builtin_" ^ fname` :395).

4. **Desugar** receives `(ailnames, core_stdlib_fun_map, core_impl)`
   (pipeline.ml:200-203) — used for constant-expression evaluation
   (mini_pipeline.lem:86-93), not name resolution.

5. **Translation substitutes the proxy symbol.** For a function
   designator that is an identifier with `SD_Id str`,
   `translate_function_designator` looks `str` up in
   `stdlib.ailnames` and, on a hit, emits
   `fun_ptrval sym_proxy` instead of the Ail symbol
   (frontend/model/translation.lem:244-251). Declared-but-undefined
   functions also get their funinfo registered under the proxy symbol
   (translation.lem:4317-4324). The translated file carries the whole
   stdlib fun_map: `C.stdlib = stdlib_fun_map` (translation.lem:4529).
   Empirical confirmation: `cerberus --nolibc --pp core
   libc-001-malloc-free.c` shows the call sites as
   `pure(Specified(Cfunction(malloc_proxy)))` /
   `Cfunction(free_proxy)`.

6. **Run-time lookup, stdlib first.** The exec engine is
   `core_reduction.lem` (driver.lem:10 imports Core_reduction;
   `--exec` drives `Driver.drive` via backend/common/driver_ocaml.ml:155-158),
   which shares `call_proc` (frontend/model/core_run.lem:30-70):
   lookup order is `file.stdlib` FIRST, then `core_extern`-redirected
   `file.funs` (:36-51 — a user proc cannot shadow stdlib, noted in the
   source comment); failure is exactly our error string,
   `"calling an unknown procedure"` (:68-69).

7. **Builtins dispatch at run time.**
   `Core_reduction.process_impl_proc` (core_reduction.lem:963-1084)
   handles `Impl (BuiltinFunction _)` pcalls: "errno" :978 (returns
   `th_st.errno`), "exit" :990 (`Step_done`), "generic_ffs" :1007,
   "ctz" :1022, "bswap16/32/64" :1038/1053/1068 — the arithmetic lives
   in Builtins.gcc_builtin_* (builtins.lem:506-521 →
   ocaml_frontend/ocaml_gcc_builtins.ml). Filesystem-ish builtins
   (printf among them) are classified by
   `Core_reduction_aux.is_fs_function` (core_reduction_aux.lem:8-42)
   and dispatched as `Step_fs2` (core_reduction.lem:1402-1409) →
   `step_fs_proc` (core_reduction_aux.lem:44+; printf :63-73 →
   `FS_PRINTF`) → driver.lem:404-414 → `Formatted.printf`
   (formatted.lem — the real format-string interpreter). `errno`'s
   object is allocated and zeroed at program setup
   (driver.lem:1844-1852); memops resolve in
   `perform_memop_request2` (driver.lem:761-886: Memcpy :810,
   Memcmp :815, Realloc :824) → `Mem.memcpy/memcmp/realloc`
   (mem.lem:192-201 → memory/concrete/impl_mem.ml:2635/2649/2668).

### The crisp answer: why does OCaml resolve malloc under `--nolibc` and we don't?

**`--nolibc` excludes only `libc.co` (the compiled-from-C library); it
never excludes `std.core`, and malloc/free/realloc/memcpy/memcmp/errno/
printf/ffs/ctz/bswap are std.core PROXIES bound to C names via
`[ailname = ...]` attributes that the core parser registers and the
translation stage substitutes.** Our Lean pipeline loads the same
std.core and successfully parses the same proxies — but
`CoreParser.lean` parses and then **discards** the `[ailname = ...]`
attribute (pProcDecl, lean_frontend/CoreParser.lean:1502-1521: `let
_attrs ← ...`), and `Main.lean`'s `loadCoreStdlib` builds the ailnames
map from **declaration names** instead (Main.lean:23-36) — so it
contains `"malloc_proxy"`, `"ffs_proxy"`, ... (110 entries, verbose run
confirms "ailnames: 110 entries") but not `"malloc"` or
`"__builtin_ffs"`. `Map.lookup "malloc" stdlib.ailnames` (the generated
Translation.lean, same model code as translation.lem:247) misses, the
Ail symbol survives to run time, `call_proc` finds nothing, and we get
`calling an unknown procedure: Symbol(56, SD_Id("malloc"))` (empirical,
libc-001). One wrinkle proving the same diagnosis from the other side:
for `printf` the surviving symbol is HASH-based
(`Symbol(17935029242910440579, SD_Id("printf"))`) — our decl-name map
accidentally contains `"printf"` via the `builtin printf` DECLARATION
(std.core:283), so translation substituted the builtin's CoreParser
symbol; `call_proc` then failed anyway because a `BuiltinDecl` is not a
`Proc` (core_run.lem:38-42 matches `Proc` only). In OCaml, ailnames
never contains builtin-decl names, only proc attributes.

Everything DOWNSTREAM of the substitution already exists on the Lean
side (verified in the generated build):
- `Core_reduction.process_impl_proc` dispatch generated in full
  (lean_frontend/generated/Core_reduction.lean:470: errno, exit,
  generic_ffs, ctz, bswap16/32/64);
- gcc builtin arithmetic: CerbUtils.lean:97-135
  (`gcc_builtin_generic_ffs/ctz/bswap16/32/64`);
- memops: CerbMem.lean `memcpyM` :1507, `memcmpM` :1517, `reallocM`
  :1533-1578 (with impl_mem.ml:2668-2696 citations in-source), wired
  via mem.lem:196-201 lean target_reps;
- printf: generated/Formatted.lean is the full format interpreter
  (only WIP edges are `failwithI`, mirroring the OCaml `error "TODO"`
  in formatted.lem — e.g. `applyFlagsAndPadding` formatted.lem:287-289
  is `error "TODO: WIP"` in OCaml too); FS_PRINTF → Formatted.printf is
  wired in generated/Driver.lean:265;
- errno startup allocation: driver.lem:1844-1852 is shared model code,
  generated.

## Map (b) — DONOR: how the prototype resolved the same procedures

(Prototype paths below are under `cerberus-lean-prototype/`, abbreviated
`$P`. Surveyed 2026-08-19 against its checked-out tree.)

**Headline: the prototype has NO libc dispatch table and never sees
`[ailname]` attributes.** Its architecture sidesteps our gap entirely:
the OCAML frontend loads std.core, links all TUs (+libc when enabled),
and dumps the ALREADY-LINKED, typechecked Core to JSON
($P/cerberus/backend/driver/main.ml:266-283 — comment: "JSON Core
output - done after linking so libc is included"); the Lean interpreter
parses `stdlib`/`funs`/`extern` maps from that JSON
($P/lean/CerbLean/Parser.lean:1844-1881) and executes the std.core
proxy bodies GENERICALLY. `grep ailname $P/lean/` → zero hits. Per
procedure:

- **malloc/free/realloc**: std.core proxies executed generically →
  Core `alloc`/`kill` actions and `Ememop Realloc`. `callProc` with
  stdlib-first lookup + extern remap:
  $P/lean/CerbLean/Semantics/Step.lean:76-107 (mirror of
  core_run.lem:30-70); Ealloc :866-876; Ekill :880-898; intrinsics
  $P/lean/CerbLean/Memory/Concrete.lean:454-485 (allocate), :777-800
  (kill, dynamic-address check = double-free/free-of-stack UB),
  :1097-1125 (realloc, NULL→malloc at :1104-1107).
- **memcpy/memcmp**: `Ememop` dispatch Step.lean:1353-1431 (memcpy
  :1423-1425, memcmp :1426-1428; mirror of driver.lem memop request);
  impls Concrete.lean:1047-1066 (overlap UB :1055), :1071-1095.
- **errno**: allocated at driver init
  ($P/lean/CerbLean/Semantics/Interpreter.lean:77-87, mirror of
  driver.lem errno allocation), state slot Monad.lean:80, dispatch by
  name match in the impl-proc handler Step.lean:604-613.
- **printf family**: **NOT implemented** — falls to
  `throw .notImplemented "builtin function ... (requires driver
  layer)"` (Step.lean:725-731); its 5 io tests are `.unsupported`
  (same marking our corpus inherited). Dead `stdout` plumbing exists
  (Monad.lean:71-72, :113-119) with no call sites.
- **exit/abort**: `exit` via impl-proc match Step.lean:614-621 (fine),
  but ALSO a name-keyed `Eccall` hack (`funSym.name == some "exit"`
  :1231-1249) and an invented `abort` → hard-coded 127 (:1250-1253;
  `abort` is not in std.core at all). **Not importable — semantically
  wrong (hijacks any user function named exit/abort); recorded as a
  prototype divergence.**
- **ffs/ctz/bswap**: hard-coded match on the stripped `builtin_*`
  impl-constant name, arithmetic inline, Step.lean:598-731
  (generic_ffs :622-645, ctz :646-667, bswap16/32/64 :668-724) —
  a manual transcription of core_reduction.lem:993-1065. We get the
  same arms lem-GENERATED, so nothing to import.
- **varargs**: **fully implemented** as memory-model intrinsics with
  varargs state in the mem state
  ($P/lean/CerbLean/Memory/Types.lean:203-207 `varargs : HashMap Nat
  (Nat × List (Ctype × PointerValue))` + `nextVarargsId`, mirroring
  impl_mem.ml:491-492; va_start/copy/arg/end
  Step.lean:1442-1513, mirroring impl_mem.ml:2698-2704ff). **This is
  the donor design for our CerbMem va-stub gap (register 15)** —
  importable nearly verbatim into CerbMem.lean (the prototype inlined
  it in Step.lean; we should put it behind the mem interface where
  impl_mem.ml has it).
- **multi-TU/digests**: linking done in OCaml pre-dump; Lean takes ONE
  JSON. But symbol identity is handled properly: `Sym` carries a
  required `digest` (Parser.lean:178-189, hard error if absent), `BEq`
  compares digest && id ($P/lean/CerbLean/Core/Sym.lean:107-117,
  mirror of symbol.lem symbolEqual), and `createExternSymmap` is a
  transcription of core_linking.lem (Step.lean:60-70). Supports the
  §c.ii conclusion that real digests are part of the correct design.

**Caveat on "100% on tests/minimal":** the prototype's `make
test-interp` runs `--nolibc` and its harness SKIPS `*.libc.c` files
under that flag ($P/scripts/test_interp.sh:181-190); tests/minimal
contains zero malloc/printf/builtin callers. The prototype's real libc
evidence is its coverage corpus (libc-001..014, builtin-001..005 pass
under --nolibc via the generically-executed std.core proxies — i.e.
the SAME mechanism we are about to fix into our pipeline).

**Import verdict for S1:** the prototype's working answers are all
things our lem-generated pipeline already possesses (callProc,
builtin dispatch, memops, errno init). The genuinely importable donor
designs are (1) the varargs mem-state design (for register 15, later
arc) and (2) negative knowledge: don't hand-roll name-keyed dispatch
(its abort/exit hack), don't expect a printf shortcut (it has none —
but we already have Formatted generated, which the prototype lacked).

## Map (c) — OUR GAP, per mechanism

**Empirical probes** (this worktree's binary, gate-green tree):

| probe | result |
|---|---|
| libc-001 (malloc/free) | `unknown procedure: Symbol(56, SD_Id("malloc"))` |
| builtin-001 (ffs) | `unknown procedure: Symbol(1, SD_Id("__builtin_ffs"))` |
| ctrl2-003 (errno) | `unknown procedure: Symbol(20, SD_Id("__builtin_errno"))` |
| libc-008 (memcpy) | `unknown procedure: Symbol(23, SD_Id("memcpy"))` |
| io-001 (printf) | `unknown procedure: Symbol(<hash>, SD_Id("printf"))` |
| varargs-005 (va_sum) | links & runs; `Undefined UB019_lvalue_not_an_object` at the `va_arg` line (OCaml: Defined 0) |
| decl-only variadic (`int f(const char*, ...);` unused) | **Defined 0 on BOTH sides** |

The pipeline reaches execution in every linking case (desugar,
typecheck, translation all succeed; translation reports funs:50 on
libc-001) — the failure is precisely the missing ailnames substitution
(§a). Refuted hypotheses from the charter: CoreParser stdlib load works
(110 decls parsed, incl. all proxy bodies); the generated Core_linking
module and the builtin dispatch are present; Ail typing is not
involved.

**(i) varargs decl-tolerance:** varargs DECLARATIONS do not break
anything today — probe above returns Defined 0 both sides, and the
whole `<stdio.h>`-including corpus desugars fine. Calls to UNDEFINED
variadic functions (printf) fail only at `call_proc` like every other
undefined function. Calls to DEFINED user variadic functions link and
run; the 5 varargs DIFFs are an EXECUTION gap: `CerbMem.vaStart/vaCopy/
vaArg/vaEnd` are stubs (CerbMem.lean:1587-1590 — vaArg returns a null
pointer, whose deref yields the observed UB019), vs Impl_mem.va_*
(mem.lem:203-216). Varargs execution stays register-15 OPEN per the
charter; no decl-tolerance work is needed in S1.

**(ii) multi-TU:** OCaml's path: per-file frontend fold
(main.ml:151-156; each `c_frontend` run calls `Cerb_fresh.set_digest
filename` = MD5 of file content, pipeline.ml:181 →
util/cerb_fresh.ml:7-10) → `Core_linking.link (f::fs)` (main.ml:278-281;
link/link_aux core_linking.lem:309-316/282-307 — extern-map merge by
IDENTIFIER with tentative-definition resolution, link_extern :10-46;
duplicate normal defs = `DuplicateExternalName`) → `Tags.reset/set_tagDefs`
on the LINKED file (main.ml:281-283) → exec. Cross-TU calls resolve at
run time through `core_extern = Core_linking.create_extern_symmap file`
(core_linking.lem:319-328), consumed by `call_proc`
(core_run.lem:43-47) — and that wiring is ALREADY LIVE in our generated
driver (driver.lem:1512), exercised trivially single-TU. Empirical:
2-file link works in OCaml (`helper` across TUs → 42), including two
same-named `static int v` (each TU keeps its own — 1+41=42).

Our minimal path — REAL linking, not concatenation:
- Missing pieces are small: Main.lean accepts one cabs-json; loop the
  existing desugar→typecheck→translate stages per input file and fold
  the generated `Core_linking.link`. The ambient fresh counter is
  process-global and monotonic (arc-4 S3a floor probe, Main.lean:457+),
  so per-TU symbol ids cannot collide in one process.
- **Digests are REQUIRED for correctness, not cosmetics:**
  `CerberusFresh.digest` is permanently `""` (CerberusFresh.lean:24), so
  `Symbol.from_same_translation_unit` (symbol.lem:286-288) is vacuously
  TRUE; cross-TU struct-tag compatibility (ctype_aux.lem:232-245: same
  TU ⇒ tag symbol EQUALITY, different TU ⇒ name+members compatibility)
  then collapses to symbol equality and cross-TU struct passing goes
  falsely incompatible. Mirror pipeline.ml:181's MD5-per-TU (set before
  each TU's desugar; equality-only consumer). Cheapest exact mirror: a
  public-domain MD5 in `native/` (the `native/*.c` + `make
  lean-native-obj` pattern exists) + a `set_digest` global beside
  `fresh_int`. Cheaper-but-divergent alternative: any injective-enough
  content tag (e.g. 64-bit content hash rendered as hex) — behavior
  differs from OCaml only when two TUs have IDENTICAL content (OCaml
  then treats them as the same TU); if chosen, record the divergence.
- **Concatenation stopgap: REJECT.** Analysis against the invariants:
  (1) symbol identity/2^20 floor is actually fine (single desugar run),
  but (2) static-symbol aliasing is disqualifying — two TUs with
  `static int v = ...` become a C redefinition ERROR when concatenated,
  and two TENTATIVE `static int v;` silently MERGE into one object
  (wrong semantics, no diagnostic); `static` in one TU + `extern`
  references in another silently rebind. (3) It also forecloses the
  differential: OCaml links really, so concatenated-Lean vs linked-OCaml
  compares different programs. libxml2 uses file-scope statics; the S3
  4-TU stretch would hit this immediately.

**(iii) printf:** nothing in the 20 FAILs needs printf. The io files
(UNSUPPORTED, outside the 20) need it — and it comes nearly free: the
whole chain (printf_proxy → FS_PRINTF → Formatted.printf) is generated
and present; no format-interpreter work is required. Recommend: after
the ailnames fix, probe io-001/002/003/005; whatever matches, rename
away `.unsupported` with justification (instrument-change commit per
charter). No real-printf-execution decision point arises; the
prototype-donor format interpreter is NOT needed (we already possess
the OCaml-mirrored one via lem).

## Resolution table (one row per procedure)

Shared fix **[A] = the ailnames repair** (single seam, all rows):
parse-and-keep the `[ailname = "..."]` attribute in
`CoreParser.lean` pProcDecl (:1502-1521, currently discarded) and have
`Main.lean loadCoreStdlib` (:23-36) build the ailnames map from
ATTRIBUTES ONLY (46 entries, OCaml parity: core_parser.mly:157-159,
:1037-1041 registers attrs only — decl names and `builtin` decl names
must NOT be in the map). Everything downstream is already generated
and verified present (§a). Provenance comments per the dual-lineage
rule: OCaml core_parser.mly:1037-1041 beside the CoreParser change.

| procedure | OCaml mechanism (cited) | prototype design (cited) | our gap | proposed fix | coverage files | printf/varargs implication |
|---|---|---|---|---|---|---|
| malloc | std.core:350 `malloc_proxy` [ailname] → `alloc` action; subst. translation.lem:244-251; lookup core_run.lem:36-38 | generic proxy exec; Step.lean:76-107, Concrete.lean:454-485 | ailnames map lacks "malloc" | **[A]** only — alloc path already live | ctrl3-001, libc-001/013, ptr2-009 (+free files) | none |
| free | std.core:371 `free_proxy` → `free(p)` (kill Dynamic) | Step.lean:880-898, Concrete.lean:777-800 | same | **[A]** | libc-001/004/005/006/007/014 | none |
| realloc | std.core:360 → `memop(Realloc)`; driver.lem:824; impl_mem.ml:2668 | Step.lean:1429-1431, Concrete.lean:1097-1125 | same | **[A]**; CerbMem.reallocM already mirrors impl_mem.ml:2668-2696 | libc-003, mem3-007 | none |
| memcpy | std.core:398 → `memop(Memcpy)`; driver.lem:810; impl_mem.ml:2635 | Step.lean:1423-1425, Concrete.lean:1047-1066 | same | **[A]**; CerbMem.memcpyM :1507 present | libc-008/009 | none |
| memcmp | std.core:410 → `memop(Memcmp)`; driver.lem:815; impl_mem.ml:2649 | Step.lean:1426-1428, Concrete.lean:1071-1095 | same | **[A]**; CerbMem.memcmpM :1517 present | libc-010 | none |
| errno | errno.h:14-15 macro → `__builtin_errno`; std.core:276; core_reduction.lem:978; alloc driver.lem:1844-1852 | Interpreter.lean:77-87, Step.lean:604-613 | ailnames lacks "__builtin_errno" | **[A]**; errno alloc + dispatch generated | ctrl2-003 | none |
| printf family | std.core:289 `printf_proxy` [ailname "printf"] → Step_fs2 (core_reduction.lem:1402-1409, _aux.lem:63-73) → driver.lem:404 → Formatted.printf | **absent** — throws notImplemented (Step.lean:725-731); io tests `.unsupported` | ailnames maps "printf" to the WRONG sym (builtin decl, std.core:283) | **[A]** (attr-only map fixes the missym too); then PROBE io files — Formatted.lean generated in full | io-001/002/003/005 (UNSUPPORTED, outside the 20) | variadic call sites pack args via translate_function_call (translation.lem:849-1140, shared code) — NO va_* machinery needed for printf |
| exit / abort | **no --nolibc resolution in OCaml either** (no ailname; live in libc.co: runtime/libc/src/stdlib.c; probe: OCaml fails builtin-006) | name-keyed Eccall hack Step.lean:1231-1253 — **rejected, do not import** | none (parity holds) | nothing in S1; revisit only if the libc story changes (harness lockstep clause) | builtin-006 (CERB_SKIP) | none |
| __builtin_ffs/l/ll | builtins.h:2-4; std.core:782/791/800 → `<builtin_generic_ffs>`; core_reduction.lem:1007; ocaml_gcc_builtins.ml:41 | inline transcription Step.lean:622-645 | ailnames lacks "__builtin_ffs*" | **[A]**; CerbUtils.lean:97 + generated dispatch present | builtin-001 | none |
| __builtin_ctz | builtins.h:5; std.core:814; core_reduction.lem:1022 | Step.lean:646-667 | same | **[A]** | builtin-002 | none |
| __builtin_bswap16/32/64 | builtins.h:8-10; std.core:826/835/844; core_reduction.lem:1038/1053/1068 | Step.lean:668-724 | same | **[A]** | builtin-003/004/005 | none |
| va_start/va_arg/va_copy/va_end | stdarg.h:7-11 → Cabs Eva_* nodes → Ememop; driver.lem:846-865; impl_mem.ml:2698ff (varargs state impl_mem.ml:491-492) | **fully implemented**: Memory/Types.lean:203-207 + Step.lean:1442-1513 — the donor design | linking is FINE; CerbMem.vaStart/Copy/Arg/End are stubs (CerbMem.lean:1587-1590) | none in arc 5 (register 15 OPEN); when opened: mirror impl_mem.ml:2698ff, import prototype mem-state design into CerbMem | varargs-001..005 (DIFF, outside the 20) | this IS the varargs-execution gap; decls & defined-variadic linking already work |

## S1/S2 scoping recommendation

**S1 — one small batch fixes all 20.**
- **Batch 1 (the ailnames repair, [A])**: CoreParser.lean pProcDecl
  returns its attrs (keep `Decl.procDecl` shape or widen to carry
  `Option String`); loadCoreStdlib builds ailnames from attrs only.
  ~50-80 LOC total incl. a few core-parser unit tests (240-test suite
  gains ailname cases; note std.core has both `ailname = "x"` and
  `ailname= "x"` spacings — :398 — the lexer already tolerates this,
  keep it so). Sync `generated/` copies (`make lean-prelude-src`).
  Expected: all 20 FAILs → MATCH/UB_MATCH (bar 2's ≥18 with target 20
  is realistic — every downstream mechanism is verified present;
  residual risk is only that proxies exercise fresh CerbMem paths,
  which is in-batch differential debugging, not new mechanism).
  No harness flag changes needed: OCaml side stays `--nolibc`, and the
  fix gives the Lean side exactly the std.core surface OCaml has under
  `--nolibc` — parity by construction.
- **Batch 2 (printf probe + baseline honesty)**: run io-001/002/003/005;
  whatever matches, strip `.unsupported` with per-file justification
  (instrument-change commit per charter). Expected zero-to-small code
  (Formatted/FS chain is generated); if a Formatted WIP edge
  (`failwithI`) trips, classify-and-defer per charter — do NOT build a
  format interpreter (we already own the OCaml-mirrored one).
- NOT S1: varargs execution (register 15), exit/abort (OCaml parity
  already holds).

**S2 — real linking; concatenation rejected (§c.ii).**
- (a) Main.lean: accept N cabs-json inputs; per-TU
  desugar→typecheck→translate loop; fold generated
  `Core_linking.link`; set tagDefs from the LINKED file
  (main.ml:278-283 mirror). ~80-120 LOC. The run-time side
  (core_extern remap) needs zero work — already live
  (driver.lem:1512).
- (b) Digests: REQUIRED (from_same_translation_unit / cross-TU tag
  compatibility, §c.ii). Mirror pipeline.ml:181 + util/cerb_fresh.ml:
  a `set_digest`/`digest` native global beside `fresh_int`, MD5 of
  file content via a public-domain md5.c in `native/` (~150 LOC C +
  ~15 LOC Lean externs + `make lean-native-obj`). Cheaper alternative
  if that is judged heavy: any injective per-TU content tag (64-bit
  content hash as hex) with a RECORDED divergence (differs from OCaml
  only for identical-content TUs, which OCaml itself conflates). S0
  recommends the native MD5 — it is not disproportionate and closes
  the register item exactly.
- (c) Harness: multi-file fixture support in test_exec.sh (own commit,
  both sides in lockstep) — feeds S3's `libxml2_prep.sh`.
- Nothing in S1/S2 looks disproportionate. The single pre-declared
  risk to watch: batch-1 flips 20 files at once, so the full
  differential (bar 1 + bar 2 sweeps) must run before the commit
  claim, and each moved file gets its baseline justification.

## Scratch

Probes used `scratch-s0/` in the worktree (cabs-json dumps, 2-TU
probe .c files); deleted before commit per doctrine. test_unit.sh run
on the untouched tree before commit: 4/4 green (purity/cones/totality
clean).
