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
