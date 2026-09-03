# Noodle report — semantic-discrepancy hunt over cerberus-lean (2026-09-03)

Branch `noodle/semantics` @ base mainline `72164481a`. Charge [USER
2026-09-03], verbatim: "poke and prod at everything that might be wrong
about every surface, and expose subtle errors that we haven't spotted
yet. Mostly the noodlers should focus on semantic discrepancies we might
not have spotted. All of the known discrepancies are not of interest.
We're strictly trying to shake out weirdness that needs fixing."
Addendum [USER 2026-09-03]: every probe suite-ready, integration
recommendation per probe (never integrated here).

INVESTIGATION ONLY: no product code, gate, baseline or doc other than
this record was modified. Probe corpus + runner: `tests/noodle-probes/`
(per-area `results.log` = the verbatim three-engine pins). Binaries:
freshly rebuilt in this worktree from `72164481a` (`make
lean-prelude-src`; `build_cerberus` with DUNE_CACHE=disabled;
`build_lean`; driver-freshness stamps recorded by the helpers). Native
referee: gcc 13.3.0 `-O0 -w`.

Exclusion registers honoured (anything on them is NOT a finding here):
`docs/2026-08-30_parity-detective-report.md`, `tests/immaculate/
baseline.txt`, `docs/upstream-tray/INDEX.md` (18), `scripts/
gcc_oracle_triage.txt`, the fuel ceiling, the ~8M zero-init hang,
PVI-not-PNVI, the concurrency stubs, CerbFS (fail-closed).

Classification: DISCREPANCY (Lean != oracle, both accept) /
ORACLE-SUSPECT (Lean == oracle, both != ISO/gcc on deterministic UB-free
input) / ODDITY / EXCLUDED-KNOWN. Judgments are [AGENT]; quoted engine
lines are verbatim; tallies marked derived.

## 0. Findings register (running; ranked at the end)

### D1 — DISCREPANCY (diagnostic field): UB `loc` lost for UBs raised while executing std.core code

Both engines give the same UB verdict, but the batch line's `loc` field
differs — the oracle reports the C source site, Lean reports `unknown
location`. Every differential harness strips `loc` before comparing
(`extract_verdict_seq` greps `ub:` only), which is why this never
surfaced. Reproducers (nolibc), verbatim:

    tests/noodle-probes/float/float_inf_to_int_ub.c
    oracle: Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
    Lean:   Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "unknown location"}

    (scratch, printf("%d\n") with no argument)
    oracle: Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "<2:18--2:32>"}
    Lean:   Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "unknown location"}

Control (same run): UBs raised from C-derived Core keep the C loc on
both (UB036, UB045c, UB043, UB052a, UB51b, UB045b all print
`file:L:C-C` on Lean).

Mechanism [AGENT, localized]: the OCaml Core parser stamps every
std.core expression, including `undef(<<UB>>)`, with a region located
IN std.core (`parsers/core/core_parser.mly:1571`, `Aloc (region ...)`
+ `PEundef (region ...)`), and std.core lives under `runtime/libcore`,
so `Cerb_location.is_library_location` (util/cerb_location.ml:512)
holds for it. The shared .lem then (a) substitutes the enclosing C
location for library-located undefs (`frontend/model/core_eval.lem:
596-603`: `if Loc.is_library_location undef_loc then loc else
undef_loc`) and (b) refuses to overwrite the thread's `current_loc`
with a library location (`core_run.lem:778-784`). The hand-written
Lean Core parser instead stamps `Loc.unknown` everywhere
(`lean_frontend/CoreParser.lean:201` `loc0 := CerbLocation.unknown`,
`:204` `annots0 := [Aloc loc0]`, `:1097` `PEundef loc0 ub`);
`CerbLocation.isLibraryLocation unknown = false` (CerbLocation.lean:
180-185), so on Lean (a) keeps the unknown loc and (b) overwrites
`current_loc` with unknown whenever std.core code runs. Affected: UB017
(std.core:90 `loaded_ivfromfloat`), the printf-family UBs (UB153a/b,
UB158, Invalid_format — raised in the driver with `current_loc`), and
in principle the 47 `undef(<<DUMMY(...)>>)` sites and any memory-op UB
inside a std.core proc. Not affected: `catch_exceptional_condition`'s
UB036 (a pure `fun`, C loc preserved — verified).

Suggested fix (S): make CoreParser stamp std.core nodes with a region
whose file is the std.core path (mirror core_parser.mly:1571 — any
`Loc.region` with a `libcore/`-segment filename satisfies
`isLibraryLocation`), or, cheaper but less faithful, have the loader
tag the parsed file's `Aloc`s as library. Verification: the two
reproducers above print the oracle's `<L:C--L:C>` positions modulo
the already-different rendering (see O1).

### O1 — ODDITY (presentation): batch `loc` rendering differs by design

Oracle `Cerb_location.simple_location` renders `<5:11--5:19>` (no
file); Lean `CerbLocation.stringFromLocation` renders
`file.c:5:11-19`. Never compared by any harness; noted so D1's fix has
a stated target (matching the verdict AND, ideally, the rendering).
[AGENT] defensible; a one-line printer change if parity is wanted.

### F1 — ORACLE-SUSPECT (intended gap, upstream TODO): `float` is evaluated AND stored as double; `sizeof(float) == 8`

Both engines, verbatim (`tests/noodle-probes/float/float_single_precision.c`):

    oracle/Lean: Defined {value: "Specified(0)", stdout: "0 100000000 1 16777217 1 0 1 0\n", ...}
    gcc:         1 100000001 0 16777216 0 0 1 1

i.e. `0.1f+0.2f == 0.3f` is false, `(int)(float)16777217` is 16777217,
`(double)(float)0.1 == 0.1` is true. And (`scratch szf.c`):
`sizeof(float)`, `sizeof f`, `sizeof(1.0f)`, `sizeof(f+1.0f)` all print
8 on both engines (gcc 4). Root: `ocaml_frontend/ocaml_implementation.
ml:206-208` `RealFloating Float -> Some 8 (* TODO:hack ==> 4 *)` and
the OCaml-float representation of every floating type
(impl_mem.ml:1155 stores `Int64.bits_of_float` over `sizeof fty`
bytes). ISO: 6.3.1.5 (cast/assignment to float removes extra range and
precision even under FLT_EVAL_METHOD 2), 5.2.4.2.2. Consequence for
the trust story: the differential lanes can never see a float-rounding
bug on the Lean side because the model has no float rounding — the gcc
lane is the only referee, and any probe on this class lands in a
TRIAGED skip. Fix (upstream, M): a Float32 arm in `fvfromint`/
arithmetic/store (round through a 32-bit representation) + `sizeof_fty
Float = 4`; Lean mirrors via CerbFloat. Not a Lean-side action.

### F2 — EXCLUDED-KNOWN (tray 15 class): `(int)NaN` crashes both engines instead of UB017

`tests/noodle-probes/float/float_nan_to_int_ub.c`: oracle exit 125
`Z.Overflow` at `impl_mem.ml:2554 ivfromfloat`; Lean exit 134 `PANIC
at CerbFloat.truncToInt CerbFloat:302:4: nan/inf (OCaml Z.of_float
raises Z.Overflow)` — deliberate message-level parity. Tray 15 already
records the non-finite crash class. Recorded only as an immaculate
crash-pair candidate.

### E1 — ODDITY (oracle ISO-correct, gcc extension): enum constant outside `int` rejected

`tests/noodle-probes/int/int_enum_underlying.c` (`enum { A =
0xFFFFFFFF }`): oracle `constraint violation: integer constant not in
the range of the representable values for its type` (§6.7.2.2p2 cite
in the diagnostic is 6.6#4); Lean `Error {msg: "desugaring failed at
...:4:15-25"}`; gcc accepts (extension, sizeof 4/8). Both-reject,
consistent. Not a finding.

## 1. Coverage (running)

| Area | Probes | oracle==Lean | Findings |
|---|---|---|---|
| Integer semantics | 17 (`tests/noodle-probes/int/`) | 16/16 accepted AGREE (11 value, 5 UB-code), 1 both-reject | E1 |
| Floating point | 11 (`tests/noodle-probes/float/`) | 10/10 AGREE + 1 both-crash | D1, O1, F1, F2 |

(continued below as shards complete)

## 2. Shard 2 — pointers, layout, provenance (`ptr/`, nolibc) and allocation/string.h (`mem/`, libc)

### U1 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): usual arithmetic conversions with `size_t` compute at 32 bits

`tests/noodle-probes/int/int_size_t_uac_rank.c` (`size_t n = 5000000000`):

    oracle/Lean: Defined {value: "Specified(0)", stdout: "705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705\n", ...}
    gcc:         5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001
    upstream @ b9aeedcb4 (SZ.c scratch): identical to the fork oracle

`n + 1`, `n * 2`, `n / 2 + 1`, `u + n` (unsigned int on the left),
`n + c`, `s + n`, `1 + n` are all wrong; `n + u` (size_t on the left) is
right; and `n == 705032704` is TRUE — a comparison, so control flow
diverges from every conforming compiler. Unaffected operand types
(SZ2.c scratch): `uintptr_t`, `unsigned long`, `long`, `ptrdiff_t`,
`intptr_t`, `intmax_t`, `int64_t`/`uint64_t` (typedef'd to long long in
the libc headers). The operand truncation only bites for operand values
>= 2^32; the RESULT is re-wrapped in size_t (so `n - 1` for n == 0 is
correct: `int_size_t_minus_one_idiom.c`, control).

Mechanism [AGENT, localized, oracle-side]: `frontend/model/ail/
ailTypesAux.lem` `lt_integer_rank_ISO` ends with `| _ -> (* TODO: this
is probably wrong for macro types *) false`, so `Size_t` (Cerberus's
own `integerType` constructor, not `Unsigned Long`) has no rank
relative to `int`/`unsigned int`/`char`/`short` in either direction.
`frontend/model/translation.lem:1444-1477` (`usual_arithmetic_
conversion_aux`) therefore skips the "unsigned operand of >= rank"
branch and falls to the last resort: both operands are converted to
`make_corresponding_unsigned` of the SIGNED operand's type — `unsigned
int`. Verbatim Core (oracle `--pp=core`, `size_t k = SIZE_MAX + 3`):

    Specified(wrapI_add('size_t', if all_values_representable_in('size_t', 'signed int') then
      __conv_int__('signed int', a_679) else __conv_int__('unsigned int', a_679), ...))

ISO C11 6.3.1.8p1 (rank of size_t = rank of its underlying unsigned
long > int). Both engines mirror (shared .lem). Fix (upstream, S):
give the macro types their implementation's rank in
`lt_integer_rank_ISO` (Size_t/Ptrdiff_t/Intptr_t/… via the impl's
underlying type); the differential lanes will not move (both sides
change together); the gcc lane's pinned pair flips to AGREE.
Trust-story note: this is the largest class found — `size_t`
arithmetic is ubiquitous in the libxml2/CN targets, where operand
values stay < 2^32 so the lanes never see it.

### P1 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): pointer difference over pointers-to-arrays divides by the INNER element size

`tests/noodle-probes/ptr/ptr_array_ptrdiff_scaling.c`:

    oracle/Lean: Defined {value: "Specified(0)", stdout: "8 3 2 2 4 8\n", ...}
    gcc:         2 1 2 2 1 8
    upstream:    8 3 2 2 4 8

`&a[2] - &a[0]` on `int a[3][4]` is 8 (32 bytes / sizeof(int)), `(p+1)
- p` on `int (*p)[4]` is 4, `&c[1]-&c[0]` on `char c[2][3]` is 3;
struct/scalar element arrays are correct. Mechanism: `translation.lem:
2189-2191` passes the pointee type (`int[4]`), and `memory/concrete/
impl_mem.ml:1961-1967` (`diff_ptrval` `valid_postcond`) strips one
`Array` layer before dividing; `lean_frontend/CerbMem.lean:2184-2187`
mirrors it with a cite ("strip ONE Array layer off diff_ty"). ISO C11
6.5.6p9 (difference in units of the pointed-to type). Fix (upstream,
S): do not strip; the translation already provides the pointed-to
type. Lean: delete the mirrored strip in the same slice.

### P2 — ORACLE-SUSPECT (TRUE BUG vs the PVI model, upstream-confirmed): provenance is lost through ANY integer arithmetic

`tests/noodle-probes/ptr/ptr_intptr_arith_roundtrip.c`
(`unsigned long u = (unsigned long)&a[0]; int *q = (int*)(u + 4ul);`):

    oracle/Lean: Undefined {ub: "UB043_indirection_invalid_value", ...}
    gcc: 20        upstream (prov3.c scratch): UB043

Same with `+ 0`, `^ 0`, `* 1`, via an intermediate variable, and with
matched `unsigned long` operands (so it is independent of U1). Only
the arithmetic-free `(int*)(unsigned long)p` round trip works (the
parity-detective's `intptr_roundtrip.c`). Mechanism [AGENT]:
`impl_mem.ml:2464-2490` `op_ival` carefully `combine_prov`s, but the
elaboration routes every C arithmetic operator through
`__conv_int__`/`wrapI_*`, whose evaluators `mk_conv_int`
(`frontend/model/core_eval.lem:57-80`) and `mk_wrapI` (`:29-46`)
rebuild the result with `Mem.integer_ival n` — a fresh `IV (Prov_none,
n)` — even when the value is in range. The default model is PVI
(`impl_mem.ml:627` `is_PNVI` false without `SW_PNVI`), i.e. exactly
the model whose point is provenance through integers. Fix (upstream,
S-M): in-range `mk_conv_int` returns the original `ival`; `mk_wrapI`
re-attaches the operand provenance (or use `Mem.op_ival` results
directly). Upstream should rule whether exec-PVI is meant to be this
lossy; if it is, document it — today `p = (T*)(((uintptr_t)p + 15) &
~15)` is UB043 under Cerberus.

### L1 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): `strncmp(s1, s2, 0)` compares one character

`tests/noodle-probes/mem/mem_strncmp_zero.c`: oracle/Lean
`Specified(2)`, gcc 1; `mem_strlen_strcmp_edges.c` prints `-23` in the
strncmp column. `runtime/libc/src/string.c:85-90`:
`while ((*s1 && *s1 == *s2) && --n > 0) ...; return (*s1 - *s2);` —
the n test is after the first character compare (and `--n` on 0 wraps).
ISO C11 7.24.4.4p2-3. Fix (upstream libc, S): `if (n == 0) return 0;`.

### L2 — ORACLE-SUSPECT (minor): libc `calloc` has no nmemb*size overflow check

`runtime/libc/src/stdlib.c:125-134`: `malloc(nmemb * size)` — C17
7.22.3.2 requires NULL on overflow. `mem_calloc_overflow.c` also shows
the U1 truncation of `SIZE_MAX / 2 + 2` (the product becomes
4294967298 rather than 2) and then RC-3 on the Lean side (below).

### R1 — EXCLUDED-KNOWN (RC-3 with a new trigger): 4 GiB `malloc` never touched is OOM-KILLED on Lean, lazy on the oracle

`mem_malloc_4gb_lazy.c`: oracle `Specified(2)`, gcc 2, Lean exit 137
(capped OOM witness at 6G). The parity-detective RC-3 byte-list
representation; recorded because the trigger (a legal, untouched
large allocation whose SIZE is program-computed) is a different shape
from the multi-MB static arrays already on the register. No new
mechanism.

### D2 — DISCREPANCY (diagnostic field): UB024's `loc` is `other_location(Concrete)` on Lean

`tests/noodle-probes/ptr/ptr_to_int_narrow_ub.c` (`int i = (int)p;`):

    oracle: Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}
    Lean:   Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "other_location(Concrete)"}

Different mechanism from D1: `lean_frontend/CerbMem.lean:2297`
`memFail (MerrIntFromPtr)` drops the `loc` parameter that `intfromptr`
receives, taking `memFail`'s default `CerbLocation.other "Concrete"`
(`:1787`); the OCaml is `fail ~loc MerrIntFromPtr` (`impl_mem.ml:
2459`). Fix (S): `memFail MerrIntFromPtr loc`. Sibling default-loc
`memFail` sites (`:2226-2233` isWellAligned, `:2499-2528` va_*) map to
non-UB `Other` errors and never print a loc, so UB024 is the only
verdict-line consequence found.

### E2 — EXCLUDED-KNOWN (tray 10, string-literal form): oracle crashes on `"\?"` inside a string literal; Lean and gcc agree

`ptr_string_literals.c`: oracle exit 125 `Failure("decode_character_
constant, started like an octal constant, but failed: ?")` from
`translation.ml:3032` (string-literal path); Lean prints the gcc
output byte-for-byte (`... 39 63 0 4`). Tray 10 records the
character-constant form; this is the same decoder reached from string
literals — addendum candidate. Immaculate ORACLE_CRASH pair.

### O2 — ODDITY: relational comparison of pointers to distinct objects yields a value, not UB

`ptr_cross_object_lt_ub.c`: oracle/Lean `Specified(2)` (i.e. `&a < &b`
is 0 — address order in the concrete allocator), gcc exit 1. ISO
6.5.8p5 makes it UB; the PVI concrete model compares addresses
(`impl_mem.ml` `lt_ptrval`, `PERMISSIVE` default). Known model stance;
no referee. Not a finding.

### Non-findings worth recording (so nobody re-chases them)

- Exhaustive-mode trace COUNTS agree on every probe that completes on
  both engines (8/8, 2/2, 40/40, 140/140, 280/280, 67650/67650). The
  `ptr_struct_assign.c` unsequenced form looked like a count divergence
  (Lean timeout vs "10" oracle lines) — the 10 was this runner's
  20-line display truncation; the oracle completes 67,650 traces in
  ~100 s, Lean does not finish in 60 s: RC-4 perf class.
- `_Bool` from 256/65536/2^32/pointers, `_Bool` ++/-- : all correct
  (only the float→_Bool case, tray 15, is wrong).
- `free(NULL)`: no `UB_CERB005_free_nullptr` is raised (correct).
- `(unsigned)-0.5` → 0 (correct; `(unsigned)-1.5` → UB017, correct).

## Coverage after shard 2

| Area | Probes | oracle==Lean | Findings |
|---|---|---|---|
| Integer semantics (`int/`) | 19 | 18/18 accepted AGREE, 1 both-reject | U1 (via int_size_t_uac_rank), E1 |
| Floating point (`float/`) | 11 | 10/10 AGREE + 1 both-crash | D1, O1, F1, F2 |
| Pointers/layout/provenance (`ptr/`) | 19 | 18/18 accepted AGREE, 1 oracle-crash (Lean right) | D2, P1, P2, E2, O2 |
| Allocation/string.h (`mem/`) | 11 | 9/9 completing AGREE, 2 Lean OOM (RC-3) | L1, L2, R1 |

## 3. Shards 3-5 — control/evaluation (`ctl/`), library (`lib/`), elaboration (`elab/`), verdict surface (`out/`)

Control flow, evaluation order and the verdict surface are clean: 15/15
`ctl/` probes and 4/4 `out/` probes agree three ways (incl. the
two-outcome unsequenced SET and trace counts). The library and
elaboration surfaces produced a cluster of oracle-shared defects, each
re-verified on un-forked upstream @ b9aeedcb4 and each mirrored exactly
by Lean.

### L3 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): FILE-buffered stdout is dropped at termination and reordered against the printf proxy

    tests/noodle-probes/lib/lib_stdio_unflushed_lost.c   fputs("out", stdout); return 0;
    oracle/Lean: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}      gcc: out
    lib_stdio_exit_unflushed_lost.c (… exit(0))           oracle/Lean stdout " 5\n"          gcc: out 5
    lib_stdio_puts_after_putchar.c  putchar('\n'); puts("xy");  oracle/Lean stdout "\n"     gcc: \nxy\n

Controls that DO work: newline-terminated `fputs("out\n")`, explicit
`fflush`, `puts` alone, `fputs; fputc; fwrite; putc; putchar('\n')`
(`lib_stdio_fflush_control.c` and scratch Q1-Q3, Q7, Q8, P1, P2).
ISO C11 7.22.4.4p4 (exit flushes all streams), 5.1.2.2.3, 7.21.3.
[AGENT] mechanism sketch, oracle-side: `printf`/`putchar` are std.core
proxies writing straight into the driver's stdout record, while
`fputs`/`puts`/`fputc` go through the C libc's FILE buffer
(`runtime/libc/src/stdio.c`, `puts` = `fputs` + `putc_unlocked`,
:813-818) whose contents reach the record only on a flush; neither
`return` from main nor `exit()` flushes it, and the `putchar` proxy
leaves the FILE in a state where the next buffered write is lost. Not
localized further (libc + driver interplay). Fix (upstream, S-M): flush
all FILEs on the exit path; route the proxies through the same buffer
or flush it before proxy writes. Trust-story note: harness stdout
comparisons cannot see any `fputs`/`puts` output that is not
newline-terminated — a coverage hole that hides on both sides equally.

### L4 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): atexit handlers do not run on return from main

`lib_atexit_order.c`: oracle/Lean stdout `m`, value 4; gcc `m21`.
Control `lib_atexit_exit_control.c` (`exit(4)`): all engines `m1`. ISO
C11 5.1.2.2.3 (return from main ≡ `exit(status)`), 7.22.4.4p3. Fix
(upstream, S): the driver's main-return path must call libc `exit`.

### L5 — ORACLE-SUSPECT (crash on legal input, upstream-confirmed): `%*d` kills both engines

`lib_printf_star_width.c`: oracle `Failure("internal error: TODO:
formatted.lem 6")` exit 125; Lean `PANIC at _private.LemLib.0.
failwithIImpl LemLib:171:2: TODO: formatted.lem 6` exit 134
(message-level parity); gcc `[   9]`. ISO C11 7.21.6.1p5. Not on any
register (tray 16 is the snprintf return value). Tray candidate; fix
(upstream, S): implement `*` width/precision from the argument list in
formatted.lem.

### L6 — ORACLE-SUSPECT (over-strict, upstream-confirmed): `%x`/`%X`/`%o` with an `int` argument are UB153b

`lib_printf_hex_int_arg.c` (`printf("[%x][%X][%o]\n", 255, 255, 8)`):
oracle/Lean `UB153b_illtyped_argument_for_format`; gcc `[ff][FF][10]`.
Every real C program does this; ISO C11 7.21.6.1p9 with 6.5.2.2p6
(signed/unsigned interchangeable as arguments when the value is
representable in both) makes it well-defined. `%u` with -1
(`lib_printf_uint_neg_arg.c`) is the strict-UB control (both UB153b,
defensible). Fix (upstream, S): accept the signed counterpart when the
value is representable. Note: `%hhd`/`%hd` with int arguments are
accepted (correct).

### E3 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): `?:` in a static-storage initialiser is "not a compile-time constant"

`elab/elab_const_expr_ternary_init.c` (`static int a = (3 > 2) ? 10 :
20;`): oracle `constraint violation: initializer element is not a
compile-time constant` (desugaring); Lean `Error {msg: "desugaring
failed at …"}`; gcc 10. `1 ? 10 : 20` and a block-scope static behave
the same (CE10, CE14); `?:` in enum constants, array sizes and case
labels is accepted (`elab_const_expr_ternary_contexts.c`, CE11/12/15).
ISO C11 6.6p3, p6, p7. Fix (upstream, S): add the conditional arm to
the desugarer's initializer constant evaluator.

### E4 — ORACLE-SUSPECT (TRUE BUG, upstream-confirmed): string literals cannot initialise char-array members/elements

`elab/elab_string_member_init.c` (`char a[2][3] = {"ab", "cd"};`) and
`elab_string_struct_member_init.c` (`struct W { char c[3]; } w =
{{"ab"}};`): oracle `constraint violation: initializing 'char' with an
expression with a non arithmetic type 'char*'` (typing); Lean
`typechecking failed`; gcc 99 / 98. All six shapes tried reject
(scratch SI1-SI6: struct member with/without braces, member followed
by another member, nested struct, 2-D array, array of structs). Only a
TOP-LEVEL `char s[3] = "abc"` works. ISO C11 6.7.9p14 (+p20). This is
a very common idiom (`char names[][8] = {...}`) — likely a visible
slice of the 766 oracle-reject rows in the ci sweep. Fix (upstream,
S-M): the initializer typing must treat a string literal against an
array-of-char (sub)object as p14, before brace elision.

### E5 — ORACLE-SUSPECT (tray-09-adjacent, upstream-confirmed): `"hello" + 1` is not an address constant

`elab/elab_addr_const_string_plus.c`: both reject "not a compile-time
constant"; gcc 101. `static int *q = arr + 2;` and `&arr[1]` are
accepted (`elab_const_expr_static_init.c`), so the gap is the
string-literal base. ISO C11 6.6p9. Addendum candidate for tray 09.

### E6/E7 — controls, by design: K&R definitions ("found K&R-style declaration (unsupported)") and implicit int (parse error) are both-reject on both engines; gcc accepts both as extensions/obsolescent forms. Not findings.

### O3 — ODDITY: `strtok` is absent from the Cerberus libc (both engines: unknown procedure). O4 — ODDITY: `strtol`-family calls make exhaustive mode explode (libc-internal nondeterminism): `lib_strtol_edges.c` completes in 0.3 s single-trace on both engines with gcc's values, but no engine finishes exhaustive enumeration in 60 s. D3 — documented divergence, not a finding: `Error {msg:}` text for `Illformed_program` differs by design (`Main.lean:389-391` declares it; oracle `pp_errors.ml:501`).

## Coverage after shards 3-5

| Area | Probes | oracle==Lean | Findings |
|---|---|---|---|
| Control/evaluation (`ctl/`) | 15 | 15/15 AGREE (3-way) | — |
| Library, libc mode (`lib/`) | 24 | 22/22 completing AGREE; 1 both-crash; 1 both-timeout | L3, L4, L5, L6, O3, O4 |
| Elaboration (`elab/`) | 18 | 12/12 accepted AGREE; 6 both-reject | E3, E4, E5, (E6, E7 controls) |
| Verdict surface (`out/`) | 4 | 4/4 AGREE | — |

## 4. Seam read — `CerbMem.lean` vs `impl_mem.ml` (delegated line-by-line audit, then probe-confirmed)

An Explore agent read both files fully for load/store/alloc/kill/
memcpy/memcmp/realloc/ptr-comparison/ptrfromint/intfromptr/shift/
copy_alloc_id and reported 18 candidate divergences (its verbatim list
is condensed here; its verified-matching list covered `abst`/`repr`
provenance handling, load/store arm order, eq/lt/diff_ptrval, memcpy/
memcmp/realloc, varargs, max/min_ival, op_ival). I probed every
C-observable claim; five reproduce and are Lean-side (un-forked
upstream == fork oracle on all five). `tests/noodle-probes/seam/`.

### D4 — DISCREPANCY (VALUE-LEVEL): `__cerbvar_copy_alloc_id` returns the wrong pointer

    seam_copy_alloc_id.c:  int x = 1, y = 2; int *p = __cerbvar_copy_alloc_id((uintptr_t)&y, &x); return *p;
    oracle (fork and upstream): Defined {value: "Specified(2)", ...}
    Lean:                        Defined {value: "Specified(1)", ...}

`impl_mem.ml:2766-2770` runs `intfromptr` on the pointer only for its
range check and returns `ptrfromint ival` — address AND provenance
come from the integer. `CerbMem.lean:2547` `def copyAllocId (_ :
IntegerValue) (pv : PointerValue) := memReturn pv` returns the pointer
unchanged (no comment, under a bare `Misc` header). This is the
RefinedC builtin (`builtins.lem:470`) — i.e. the one the successor
verifier (`refined-cerberus`) is most likely to lean on. Fix (S):
mirror the two-call OCaml; also the UB024 failure path.

### D5 — DISCREPANCY (verdict class): device-range integer→pointer casts

    seam_device_range_load.c:  int *p = (int*)0xABC; int y = *p; return 3;
    oracle: Defined {value: "Specified(3)", ...}        Lean: Undefined {ub: "UB043_indirection_invalid_value", ...}

`impl_mem.ml:620-624` hard-codes `device_ranges = [(0x40000000,
0x40000004); (0xABC, 0xAC0)]`; `ptrfromint` (`:2164-2167`) yields
`Prov_device`, and load/store (`:1611-1617`, `:1718-1724`) accept via
`is_within_device`. `CerbMem.lean:2275-2283` has no device arm, and
its comments at `:1940-1942`, `:1985-1988`, `:2048-2050` assert "the
device_ranges list is empty in this pipeline" — false as written.
Fix (S): port the device arms (or, if the ranges are judged an upstream
artefact, declare the divergence in-code with the correct fact).

### D6 — DISCREPANCY (verdict class): `free` of provenance-less / device pointers

    seam_free_no_provenance.c: free((int*)0x1234)
    oracle: Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}
    Lean:   Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "unknown location"}
    seam_free_device_pointer.c: free((int*)0xABC)
    oracle: Defined {value: "Specified(3)", ...}     Lean: Undefined {ub: "UB179a_non_matching_allocation_free", ...}

`impl_mem.ml:1470-1476`: function pointer → `MerrOther`; `Prov_none`
concrete → `MerrOther "...lacking a provenance"`; `Prov_device` →
`return ()`. `CerbMem.lean:1904` and the catch-all `:1920` map all of
these to `Free_non_matching` (UB179a). `MerrOther` is not UB-mapped
(`mem_common.lem`), so the oracle's verdict is an Error line. Fix (S):
mirror the three arms. (The `loc: "unknown location"` is D1 again —
the `free` proxy lives in std.core.)

### D7 — DISCREPANCY (verdict class): `free(p + 1)` on a live block

    seam_free_interior_pointer.c: char *p = malloc(8); free(p + 1);
    oracle: Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<2:39--2:50>"}
    Lean:   Error {msg: "MerrUndefinedFree Free_out_of_bound"}

`impl_mem.ml:1515-1549` tests `is_dynamic addr` FIRST (→
`Free_non_matching` → UB179a), then dead, then lookup, then `addr =
alloc.base`. `CerbMem.lean:1905-1914` does dead → lookup → `addr !=
alloc.base → Free_out_of_bound` (which `mem_common.lem:283-284` maps
to a non-UB Other error) → only then the dynamic test, and tests
`dynamicAddrs.contains alloc.base` where the OCaml tests the pointer's
`addr`. Fix (S): reorder to the OCaml's check sequence.

### Seam candidates NOT observable from C today (recorded for the mirror doctrine; each is an undeclared divergence in the Lean text)

- `ptrfromint` maps `n = 0` to NULL even with a provenance (`CerbMem.lean:2282` vs `impl_mem.ml:2163-2173`) — unobservable because P2 strips provenance on every arithmetic path before the cast (probe S2: both `1`).
- `killM`: dead-allocation arm ignores `isDynamic` (OCaml `failwith`s for static kills); missing allocation → UB179a where OCaml → UB009 via `get_allocation` (`:1906-1909` vs `:1527-1534`, `:669-675`); non-dynamic kill of NULL fails where OCaml succeeds (`:1901-1903` vs `:1465-1469`).
- `allocateObject`/`allocateRegion` clamp size/align to ≥ 1 (`:1849-1850`, `:1877` vs `:1290`, `:1247-1258`) — `int a[0]` is rejected by the front end (probe S8), so unreachable; `req_addr_opt` ignored where OCaml `failwith`s (`:1845` vs `:1291-1297`); `allocateRegion` stores the caller's `pref` where OCaml hard-codes `PrefMalloc` (`:1884` vs `:1428-1429`).
- `memValueToBytes` integer arm wraps silently where `bytes_of_int` asserts (`:591-602`/`:504-510` vs `:1096-1113`) — `conv_int` precedes every store.
- `effArrayShiftPtrval` delegates to the pure shift (`:2303-2304` vs `:2244-2356`): no null→UB046 arm (Lean panics `:1506-1507`), void-element GNU case differs, union-member tag kept where OCaml drops it — unreachable (`PtrArrayShift` is emitted only under strict/PNVI/CHERI, `translation.lem:2112-2119`).
- `reconstructValue`: zero-sized-element array short-circuit (`:951` vs `:986-994`); unspecified pointer ctype keeps pointee qualifiers (`:931` vs `:1056-1057`).
- `reallocM`'s `get_allocation` failure passes no loc though its own comment quotes `other "Concrete.realloc"` (`:2402-2403` vs `:2683`).
- `isWellAlignedPtrval` splits one OCaml message into two and adds a `FunctionNoParams` arm (`:2225-2228` vs `:2067-2070`) — message text only.
- CHERI stubs return values where OCaml `assert false` (`:1759-1764`, `:2548` vs `:2175-2191`).
- Stale cites (low): `:2425` (→ `impl_mem.ml:1704-1710`, `1776-1787`), `:563` (→ `:1202`), `:2175` (→ `1954-2063`), `:2389` (→ `:2679`), `:2344` (→ `:2664-2666`), `:2311` (→ `2635-2645`), and the false "device_ranges is empty" statement at `:1940-1942`.

## 5. Shards 6-7 — misc corners (`misc/`) and multi-TU (`mtu/`)

13 misc probes + 3 two-TU probes: all agree oracle==Lean (see the two
READMEs). Notables: O5 — `scanf` is unusable in libc mode (`vscanf`
unknown procedure); O6 — `(x & 0) + 3` with indeterminate `x` is
`UB036_exceptional_condition` on both engines (an unspecified operand
of signed `+` is classified as an exceptional condition rather than
producing an Unspecified value; gcc 3) — oracle-side classification
oddity, worth an upstream question.

## 6. Final ranking, counts and integration

### Counts (derived, this record)

- Probes committed: 141 C files in 10 directories (`int` 19, `float` 11,
  `ptr` 19, `mem` 11, `ctl` 15, `lib` 24, `elab` 18, `out` 4, `misc` 13,
  `seam` 5, `mtu` 3×2 files) + ~90 scratch bisection probes (not
  committed; the record quotes them where load-bearing).
- DISCREPANCY (Lean != oracle): **7** — D4 (value-level), D5, D6, D7
  (verdict class), D1, D2 (diagnostic `loc` field). [D3 is documented
  and excluded.]
- ORACLE-SUSPECT (both engines != ISO/gcc, upstream-confirmed): **14**
  — U1, P1, P2, L1, L2, L3, L4, L5, L6, E3, E4, E5, F1, (F2 excluded as
  tray-15 class).
- ODDITY: O1, O2, O3, O4, O5, O6, E1, E6, E7.
- EXCLUDED-KNOWN: F2 (tray 15 class), E2 (tray 10 string-literal form
  — addendum), R1 (RC-3 new trigger), D3 (declared).

### Ranked

1. **D4** `__cerbvar_copy_alloc_id` returns the input pointer (value
   divergence; RefinedC builtin) — S.
2. **U1** `size_t` (and `uint64_t` typedef'd to unsigned long long is
   fine; `Size_t` the macro type) arithmetic with `int`/`char`/`short`/
   left-`unsigned` computes at 32 bits, incl. comparisons — upstream
   `ailTypesAux.lem` rank TODO — S upstream; Lean moves with it.
3. **P2** provenance lost through any integer arithmetic under PVI
   (`mk_conv_int`/`mk_wrapI`) — S-M upstream.
4. **P1** pointer-to-array difference divides by the inner element —
   S upstream + delete the mirrored strip in `CerbMem.lean:2184-2187`.
5. **D5/D6/D7** CerbMem `free`/device-pointer verdict classes — S each.
6. **E4** string literals cannot initialise char-array members/elements
   (very common idiom; likely a slice of the 766 oracle rejects) — S-M
   upstream.
7. **L3/L4** stdio flush and atexit on return from main — S-M upstream;
   also a harness coverage hole (unflushed `fputs` output invisible).
8. **L5** `%*d` crash; **L6** `%x` with int argument UB; **E3** `?:` in
   static initialisers; **E5** `"lit" + 1`; **L1** strncmp n=0; **L2**
   calloc overflow — S each, upstream.
9. **D1/D2** UB `loc` field (CoreParser stamps `Loc.unknown`; `memFail
   MerrIntFromPtr` drops loc) — S each, Lean-side.
10. **F1** float-as-double / `sizeof(float)=8` — upstream TODO:hack, M.

### INTEGRATION column (summary; per-probe rows are in each directory README)

| Class of probe | Count (derived) | Target lane | Expected class | Gate-worthy? |
|---|---|---|---|---|
| 3-way AGREE, deterministic, UB-free, prints or returns | ~78 | `tests/minimal`-style exec lane (`test_exec.sh`) for nolibc; `tests/libc_exec` for libc; return-value-only ones also into the gcc second-oracle corpus | MATCH / AGREE | yes |
| oracle==Lean agreed UB code | 12 | exec lane | UB_MATCH | yes |
| oracle==Lean, differs from gcc (U1, P1, F1, L1, L3, L4, L6 witnesses, long-double/max_align_t/rand impl observers) | ~20 | exec/libc_exec MATCH; gcc lane as pinned TRIAGED pairs (new classes U1/P1/F1/L*) that flip to AGREE on the upstream fix | MATCH + pinned DISAGREE | MATCH side yes; gcc side pin |
| Lean != oracle (D4-D7; D1/D2 loc reproducers) | 5 (+2) | `tests/immaculate/` DIFF rows with the Lean pin (D4-D7); D1/D2 need a loc-aware harness — reporting-only until then | DIFF → MATCH on fix | pinned pair |
| both-reject / both-crash (E1-E7, F2, L5, `%*d`, strtok/vscanf) | 12 | immaculate crash pairs (L5, F2) / reporting-only both-reject controls | CRASH-pair / SKIP | pins only |
| both-slow in exhaustive mode (strtol) | 1 | `--first` reporting lane | — | no |
| Lean OOM (RC-3 witnesses) | 2 | mem-scale probe family | LEAN_KILL | no |

### What I did NOT get to

- `--call` lane (CerbCall per-function differentials), `--args`/argv
  corners beyond the existing parity probe, `CerbPP` (`--pp-core`)
  round-trip corners, CerbND ordering beyond count/set checks.
- Float printf (`%f/%e/%g`) — oracle Invalid_format (known ceiling);
  FLT_EVAL_METHOD questions are moot under F1.
- Realloc/memmove overlap variants beyond the parity probes; `aligned_
  alloc`; `qsort` with non-transitive comparators (UB); errno beyond
  strtol (strtol exhaustive-mode explosion blocks the lane shape).
- A second seam pass over `CerbCall`/`CerbND`/`CerbPP` at the depth
  given to `CerbMem` (the CerbMem pass alone yielded 4 of the 7
  discrepancies — the same method on the other seams is the obvious
  next hunt).
- Tray drafting for the 14 oracle-suspects (each has a minimized
  reproducer and file:line here; drafting is the tray's own slice).

## 7. Provenance

[USER 2026-09-03] the charge and the suite-ready addendum (top).
[AGENT] everything else: probe design, minimization, classification,
localization, pricing, the delegated seam read (an Explore agent, whose
18 items I re-verified by probe where C-observable and otherwise
report as "not observable"), and the upstream attributions (deps/
cerberus-upstream binary @ b9aeedcb4, same libc runtime). Quoted
engine lines are verbatim from `results.log` files or the scratch
runs named inline; tallies are derived. No product code, gate,
baseline or non-record doc was modified; nothing was pushed.
