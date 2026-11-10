# `size_t` and the other macro integer types have no integer conversion rank: usual arithmetic conversions with the `int` family compute at 32 bits (and musl's `strcspn`/`strpbrk` and two-way `strstr` inherit it)

**WARNING (2026-11-10): do not apply the patch below as it is.** It gives `wchar_t` the conversion rank of `int`
(so a `wchar_t` operand promotes to `int`) while the model's `wchar_t` range stays the unsigned one
(`memory/concrete/impl_mem.ml:2213`, `:2243` at `c3ff8c53f`; `<stdint.h>`'s `WCHAR_MAX` is 4294967295). One program
that un-patched Cerberus answers correctly then gets a silently wrong answer:

```c
#include <stdint.h>
int main(void) { return WCHAR_MAX > 0; }
```

```
un-forked upstream @ c3ff8c53f:   Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
with this patch (OCaml driver):   Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
with this patch (Lean port):      Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
gcc 13.3.0 (-std=c11 -w -O0):     exit status 1
```

(`--nolibc --exec --batch`, all four run on 2026-11-10.) The patch needs the `wchar_t` minimum and maximum aligned with
the signed alias first (report [62](62-wchar-t-unsigned-range-signed-representation-crash.md) describes that
contradiction and carries the other witnesses). This repository carries the patch and therefore the wrong answer
today; its correction is queued as a fix slice and this warning stays until it lands. `WINT_MAX > 0` and
`(long long)WCHAR_MAX > 0` are 1 on all three (the pre-merge review's probes).

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-04 as a fork-ahead delta (both engines by generation;
record `lean_frontend/docs/2026-11-04_macro-type-ranks-record.md`; witness `scripts/check_macro_type_ranks.sh`);
Draft for upstream, to be filed. The patch below is against `rems-project/cerberus` at `c3ff8c53f`; upstream's tip
`ae70925fc` carries the same code.

**Affected:** `frontend/model/ail/ailTypesAux.lem` at `c3ff8c53f` — `eq_integer_rank` (:455-457) and `lt_integer_rank`
(:459-541), whose inner `lt_integer_rank_ISO` enumerates `_Bool`, the chars, `short`, `int` and `long` and ends in
`| _ -> (* TODO: this is probably wrong for macro types *) false` (:527-529); `frontend/model/translation.lem`
`usual_arithmetic_conversion_aux` (:1414-1477), whose rank bullets fail for any macro-typed operand so that the last
resort (:1466-1472) converts both operands to `make_corresponding_unsigned` of the SIGNED operand's type. The Ail type
checker's `usual_arithmetic_integer_default` (:673-722) has NON-STD `Size_t`-wins and `Intptr_t` arms ahead of its
bullets (:676), so the typing and the translation disagree. Line numbers are `c3ff8c53f`'s; the fork's copies differ
from upstream's only by Lean-target `declare` lines outside the cited regions.

## Description

Cerberus represents `size_t`, `ptrdiff_t`, `wchar_t`, `wint_t` and the `intptr_t`/`intmax_t`/`intN_t`/`int_leastN_t`/
`int_fastN_t` families as their own `integerType` constructors (`frontend/model/ctype.lem`), and an enumeration as
`Enum tag`, rather than as aliases of the implementation's standard types; `Implementation.normalise_integerType`
(`ocaml_implementation.ml` `Common.normalise_integerType_`, DefaultImpl's `type_alias_map`) knows the aliases
(`Size_t → Unsigned Long`, `Ptrdiff_t → Signed Long`, `Wchar_t`/`Wint_t → Signed Int_`, `Intptr_t`/`Intmax_t → Long`,
the N-families by width, an `Enum` through `typeof_enum`) and `le_integer_range`, `are_compatible` and the layout
functions use it — but `lt_integer_rank` and `eq_integer_rank` compare the bare constructors. A macro-typed operand
therefore matches no rank arm: it is "not less than" and "not equal to" everything, in both directions.

In `usual_arithmetic_conversion_aux` the pair (`size_t`, `int`) then fails the same-type test, the both-signed/
both-unsigned bullet, and both "unsigned operand of rank ≥ the other" bullets (`ge_integer_rank` is `le` reversed, and
`le` is `eq || lt`), and reaches the last resort: unless `all_values_representable_in(size_t, int)` (false) both
operands are converted to `make_corresponding_unsigned(int)` = `unsigned int`. The result is re-wrapped in the
(correctly typed) result type, so the narrowing is invisible until an operand or an intermediate exceeds 32 bits — or
wraps at 32 bits: `(size_t)-1 + 1` is `4294967296`, not 0, and `!x` on a `size_t` (elaborated as `x == 0` under the same
conversions) is true whenever the low 32 bits of `x` are zero. The elaborated Core for `n + 1` with `size_t n`
(`--pp=core`, verbatim):

```
Specified(wrapI_add('size_t', if all_values_representable_in('size_t',
  'signed int') then
    __conv_int__('signed int', a_519)
  else
    __conv_int__('unsigned int', a_519), if all_values_representable_in('size_t',
  'signed int') then
    __conv_int__('signed int', a_520)
  else
    __conv_int__('unsigned int', a_520)))
```

The same shape applies to `ptrdiff_t` (asymmetrically: `n + i` is right because `(Ptrdiff_t, Signed Int_)` hits the
`(_, Signed Int_) -> false` row, `i + n` is narrowed), `wchar_t` (narrows a `long` partner; `wchar_t` is also never
promoted to `int`), an enum operand (`e + ul` narrows an `unsigned long`), every `op=` with a macro-typed left operand,
`%`, `|`, `^`, the conditional operator and every comparison. Localisation of the translation side (which function
narrows, and why the type checker's answer differs) is cerberus-caesium's, from their filing draft 05
(`docs/upstream-tray/05-cerberus-size-t-usual-arithmetic-conversion.md`, 2026-11-04), merged here with credit: they
found it at a libxml2 `xmlBufShrink` refinement, where the driver's Core compared `len == 0` at 32 bits while
RefinedC's typing compared at `size_t`.

## Reproducers

`tests/noodle-probes/int/int_size_t_uac_rank.c` (verbatim, both Cerberus engines and the un-forked `c3ff8c53f`):

```c
#include <stddef.h>
#include <stdio.h>
int main(void) {
  size_t n = 5000000000; unsigned u = 1; char c = 1; short s = 1;
  printf("%llu %llu %llu ", (unsigned long long)(n + 1), (unsigned long long)(n * 2), (unsigned long long)(n / 2 + 1));
  printf("%llu %llu %llu ", (unsigned long long)(n + u), (unsigned long long)(u + n), (unsigned long long)(n + c));
  printf("%d %llu %llu\n", n == 705032704, (unsigned long long)(s + n), (unsigned long long)(1 + n));
  return 0;
}
```

```
$ cerberus --nolibc --exec --batch int_size_t_uac_rank.c
Defined {value: "Specified(0)", stdout: "705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705\n", stderr: "", blocked: "false"}
$ gcc -std=c11 -O0 int_size_t_uac_rank.c && ./a.out
5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001
```

The consumer's two (return values): `size_t x = (size_t)1 << 32; return x == 0;` → 1 (gcc 0); `return 0 != x;` → 0
(gcc 1). The library-shaped ones (both engines, verbatim stdout; gcc 13.3.0):

```c
size_t ip = -1, ms = 5, l = 7;  printf("%d %llu %llu\n", (ip+1) > (ms+1), (unsigned long long)(ip+1), (unsigned long long)(l | 63));
   cerberus "1 4294967296 63"   gcc "0 0 63"
size_t v = (size_t)1 << 57;    printf("%d %d %d\n", !v, v == 0, v != 0);
   cerberus "1 1 0"             gcc "0 0 1"
ptrdiff_t d = -1; unsigned long u = 1;  printf("%d %d\n", d < u, u > d);      cerberus "1 1"   gcc "0 0"
int i = 1; ptrdiff_t n = (ptrdiff_t)1 << 33;  printf("%lld %lld\n", (long long)(i + n), (long long)(n + i));   cerberus "1 8589934593"   gcc "8589934593 8589934593"
```

## Observed vs expected

Observed: every arithmetic, bitwise, comparison and compound-assignment operation whose operands are a macro integer
type and a member of the `int` family (or an enum and a wider standard type) is computed after converting both
operands to `unsigned int` — values truncated, unsigned wraparound at 32 bits, comparisons wrong, `!x` wrong — and the
C library the model ships is elaborated the same way: musl's `strcspn` (and `strpbrk`, which calls it) builds its byte
set with `if (!BITOP(byteset, *c, |=)) break;`, and since `!((size_t)1 << 57)` is true the set keeps only its FIRST
character (`strcspn("abcabcabcdabcde-xyzzy", "yx")` is 17 — the `y` — where glibc says 16; `strspn`'s `for (; *c &&
BITOP(…, |=); c++)` form is NOT affected, `&&` not being elaborated through the usual arithmetic conversions:
`strspn(h, "abc")`, `strspn(h, "cba")`, `strspn("xyzzyabc", "zyx")` are `9 9 5` = glibc on the un-forked binary); `twoway_strstr` computes `ip+1` with
`size_t ip = -1` as `4294967296`, so `ip+1 > ms+1` holds, `ms` becomes `SIZE_MAX` and `memcmp(n, n+p, ms+1)` reads
past the needle (`strstr("abcabcabcdabcde-xyzzy", "abcde")` reports `UB_CERB002a_out_of_bound_load` at `string.c:265`
where glibc returns the match at 10).

Expected: C17 6.3.1.1#1 — a typedef'd type has the rank of its definition, and the standard's own rule list has no
place for a type without a rank — and 7.19#2 — `size_t` is an unsigned integer type (`unsigned long` on LP64), so the
third bullet of 6.3.1.8#1 converts the `int` operand to `size_t` and the operation is 64-bit: gcc's lines above; the
same for `ptrdiff_t` (`long`), `wchar_t` (`int`, so it also promotes to `int`, 6.3.1.1#2), an enum (its compatible type,
6.7.2.2#4), and the `intptr_t`/`intmax_t` families.

## Impact

`size_t` arithmetic mixed with `int`-family operands is ubiquitous (`len + 1`, `i < n`, `n * sizeof(T)`, `n - 1`,
`!n`, `len == 0`), and the library itself is affected: string searching with a multi-character set (`strcspn` and
`strpbrk`; `strspn` is not affected) returns the wrong index whenever the set's first character is not the first hit, and any needle of length
≥ 5 takes the two-way `strstr` path's out-of-bounds read. The wrong value appears at ≥ 2^32 and at 32-bit wraparound,
which is why small-program test suites do not see it; comparisons make it a control-flow difference. Both memory models
are affected (the defect is in Ail typing / elaboration, upstream of the memory interface). The typing's NON-STD arms
hide it from anything that takes the Ail type (RefinedC, CN).

## Proposed remedy (the fork's fix, a patch against `c3ff8c53f`)

Give the rank comparisons the implementation's view of the type: normalise both operands through
`Implementation.normalise_integerType` before the ISO comparison, so every type the implementation defines as an alias
has the rank of the type it aliases; add the two `long long` rows the table lacked (6.3.1.1#1's top rank; they answer
exactly what the catch-all answered for the `long long` pairs, which reach it — `usual_arithmetic_integer`'s bullets
call `lt_integer_rank` on equal promoted types); and make the catch-all an `error` so that a future unranked type
fails loudly instead of silently converting. Under CHERI the patch keeps upstream's reading verbatim — bare
constructors, the `intptr_t`-has-the-highest-rank special case on the first operand, the silent `false` — because
`intptr_t` is a capability type there, not an alias, and its rank rule is yours; whether `size_t` should normalise under
CHERI (the same narrowing exists there) is for you to decide. With the patch, every `all_values_representable_in`
conditional on a `size_t` operand disappears from the elaborated Core (247 in the shipped libc), the reproducers print
gcc's lines, and `strcspn`/`strstr` behave.

```diff
--- a/frontend/model/ail/ailTypesAux.lem	(upstream c3ff8c53f)
+++ b/frontend/model/ail/ailTypesAux.lem	(cerberus-lean fix/macro-type-ranks, 2026-11-04)
@@ -451,9 +451,33 @@
   end
 
 
+(* FORK FIX (upstream-tray report 20, 2026-11-04; cerberus-caesium filing 05):
+   the operands of the rank comparisons below. Outside CHERI both operands are
+   normalised through the implementation's alias table BEFORE the comparison, so
+   every integer type the implementation defines as an alias has the conversion
+   rank of the type it aliases (C17 6.3.1.1#1: a typedef has the rank of its
+   type; 7.19#2: size_t is an unsigned integer type, here Unsigned Long;
+   Ptrdiff_t -> Signed Long; Wchar_t/Wint_t -> Signed Int_; Intptr_t/Intmax_t ->
+   Long; the IntN_t/Int_leastN_t/Int_fastN_t families by width; an Enum to its
+   compatible type, 6.7.2.2#4; Char, Bool and Ptraddr_t are fixed points of the
+   normalisation). Upstream compared the bare constructors, so a macro-typed
+   operand matched no rank arm and the ISO table's catch-all answered `false`
+   (its own TODO below): in the Core translation's usual arithmetic conversions
+   the pair (size_t, int) then fell to the last resort and both operands were
+   converted to unsigned int -- size_t arithmetic and comparisons against the
+   int family computed at 32 bits (the same for ptrdiff_t, wchar_t and enum
+   operands). Under CHERI upstream's reading is kept exactly as it is: bare
+   constructors (intptr_t is a capability type there, not an alias -- its rank
+   rule is upstream's, see lt_integer_rank) and the silent catch-all. *)
+val rank_operand: integerType -> integerType
+let rank_operand ity =
+  if Global.is_CHERI () then ity else Implementation.normalise_integerType ity
+
 (* TODO: K this looks wrong, in particular the STD says "No two signed integer types shall have the same rank" *)
 val eq_integer_rank: integerType -> integerType -> bool
 let eq_integer_rank ity1 ity2 =
+  let ity1 = rank_operand ity1 in
+  let ity2 = rank_operand ity2 in
   ity1 = ity2 || eq_integer_rank_base ity1 ity2
 
 val lt_integer_rank: integerType -> integerType -> bool
@@ -523,10 +547,31 @@
     | (Unsigned Long, Unsigned _) ->
         true
     
+    (* FORK FIX (tray 20): long long has the greatest rank of the standard
+       integer types (STD 6.3.1.1#1); these two rows answer exactly what the
+       catch-all below answered for the long long pairs, which reach it (the
+       usual_arithmetic_integer bullets call lt_integer_rank on EQUAL promoted
+       types), so that the catch-all can be loud *)
+    | (_, Signed LongLong) ->
+        false
+    | (_, Unsigned LongLong) ->
+        false
+    
     | _ ->
-        (* TODO: this is probably wrong for macro types *)
-       false
+        if Global.is_CHERI () then
+          (* TODO: this is probably wrong for macro types *)
+          (* FORK (tray 20): upstream's reading, kept for CHERI only *)
+          false
+        else
+          (* FORK FIX (tray 20): outside CHERI the operands are normalised (see
+             rank_operand), so every standard integer type is ranked above and
+             only a constructor the implementation does not alias (Ptraddr_t,
+             CHERI-specific) or a future one reaches here: it fails loudly
+             instead of silently converting *)
+          error "AilTypesAux.lt_integer_rank: unranked integer type after normalisation"
     end in
+  let ity1' = rank_operand ity1 in
+  let ity2' = rank_operand ity2 in
   if Global.is_CHERI () then
     match ity1 with
       (* Bottom: In CHERI C intptr_t types have the highest rank so
@@ -535,10 +580,10 @@
     | Signed Intptr_t -> false
     | Unsigned Intptr_t -> false
     | _ ->
-       lt_integer_rank_ISO ity1 ity2
+       lt_integer_rank_ISO ity1' ity2'
     end
   else
-    lt_integer_rank_ISO ity1 ity2
+    lt_integer_rank_ISO ity1' ity2'
 
 val le_integer_rank: integerType -> integerType -> bool
 let le_integer_rank ity1 ity2 =
```

Not changed by the patch, deliberately — `usual_arithmetic_integer_default`'s NON-STD `(Size_t, _) -> Size_t` and
`Intptr_t` arms: with them the type checker still TYPES `size_t op long long` as `size_t` (gcc: `unsigned long long`)
and `intptr_t op unsigned long` as `intptr_t` (gcc: `unsigned long`); the values agree at 64 bits (only `_Generic` can
tell), but with a signed `Intptr_t` arm the result is typed `intptr_t` and computed unsigned, so `intptr_t a = 5;
unsigned long b = 18446744073709551610UL; a + b` is reported as `UB036_exceptional_condition` where gcc prints
`18446744073709551615` — a false UB that predates and survives the patch. Retiring those arms in favour of the
normalised bullets would make the typing agree with the standard too; the fork left them because a consumer's RefinedC
parity rests on the typing as it is.

## Related findings (not this mechanism)

- A negative value stored into a `wchar_t` object crashes both engines (`bytes_of_int(signed), i= 4294967295, nbits=
  32`): the implementation gives `wchar_t` an unsigned range (`integerImpl`) and a signed alias (`type_alias_map`);
  report 62. With the patch `wchar_t` arithmetic is done in `int`, so `wchar_t w = 100000; (w - 200000) < 0` no longer
  reports a false UB036 (it crashes at the store instead, if stored).
- `__cerbty_int128_t` is an uncaught `Invalid_argument "option is None"` (`Option.get` on DefaultImpl's alias table),
  unchanged.

## Classification

**TRUE BUG.** The code's own comment says the catch-all is "probably wrong for macro types"; 6.3.1.1 leaves no
latitude; the observable consequence is a silently wrong value and a wrong comparison on conforming, UB-free input,
inside user code and inside the shipped C library.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over the Lean port of Cerberus (record
`lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`, finding U1; both engines mirror the shared `.lem`, gcc the
referee), re-verified 2026-09-05 on the un-forked upstream binary; rediscovered independently by cerberus-caesium on
2026-11-04 (their filing draft 05, which localised the translation side and the typing/translation disagreement —
credited above); the `ptrdiff_t` asymmetry, the compound-assignment and `%`/`|`/`^` forms by the fork's true-bug audit
of 2026-11-04; the library consequences (`strcspn`, two-way `strstr`) by the fix's moved rows. Fixed in the fork
2026-11-04 (record above; a 483-program matrix over gcc 13.3.0, pristine `c3ff8c53f` and both fork engines: 196 wrong
before, 0 after on every program both sides complete). Localisation, fix and this report by Claude (Fable 5.1) under
operator direction; per the tray's provenance policy the filed issue carries an AI-provenance note.
