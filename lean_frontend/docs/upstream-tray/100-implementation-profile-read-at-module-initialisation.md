# `AilTypesAux.is_signed_ity` reads the implementation profile at module initialisation, so `Ocaml_implementation.set` selects a mixed configuration

**Affected:** `frontend/model/ail/ailTypesAux.lem` @ `c3ff8c53f`, :25-26

```
val     is_signed_ity: integerType -> bool
let is_signed_ity = Implementation.is_signed_ity
```

`Implementation.is_signed_ity` has the OCaml target representation `(Ocaml_implementation.get()).is_signed_ity`
(`frontend/model/implementation.lem`), so the point-free binding is generated as

```
ocaml_frontend/generated/ailTypesAux.ml:33:let is_signed_ity:integerType ->bool=  (Ocaml_implementation.get()).is_signed_ity
```

a top-level value: `get ()` is called once, when the module is initialised, and the record field it returns is kept.

## Description

`Ocaml_implementation.set` (`ocaml_frontend/ocaml_implementation.ml` :413-425) lets a client select an
implementation record once; `HafniumImpl` differs from `DefaultImpl` in one property, plain `char` unsigned (:378).
Every reader of the selected record calls `get ()` when it runs, except this one binding, which has already read
`DefaultImpl`'s function before any client code can call `set`. After `set HafniumImpl.impl`:

| Reads the selected record (plain `char` unsigned) | Stays on `DefaultImpl` (plain `char` signed) |
|---|---|
| the character-constant decoder (`ocaml_frontend/decode.ml` :204-210) | the usual arithmetic conversions on promoted types (`ailTypesAux.lem` :649-717) |
| Ail typing through `Implementation.is_signed_ity` and `integerImpl ()` | the elaboration's `is_signed_integer_type` / `is_unsigned_integer_type` tests (`translation.lem`), `ctype_aux.lem` :249 |
| the ranges of `char`, so `CHAR_MIN` / `CHAR_MAX` (`memory/concrete/impl_mem.ml` `min_ival` / `max_ival`) | Core's `is_signed` / `is_unsigned` (`core_eval.lem` :1075, :1085; read by `std.core`) |
| | the concrete memory model's store (`repr`, `impl_mem.ml` :971) and load (`int_of_bytes`, :780), both through `AilTypesAux.is_signed_ity` |

So a value the front end and the range checks treat as an in-range unsigned `char` is stored through the signed
encoder. A client that only runs the front end (parse, desugar, type) sees the selected profile throughout the
programs measured here; a client that elaborates and executes does not.

Under the default record the two columns agree, which is why the driver (which calls `set` only for the CHERI
memory model) does not show it.

## Reproducers

The driver has no option that selects `HafniumImpl`; the reproducer drives the installed library the way a client
that calls `set` does (`Cerb_global.set_cerb_conf`, `Ocaml_implementation.(set (HafniumImpl.impl))`,
`load_core_stdlib`, `load_core_impl`, then `c_frontend_and_elaboration`, `core_passes`, `Core_linking.link`,
`interp_backend`). The script is `tests/impl_profile/pristine_probe.ml` in the fork (an OCaml toplevel script, no
build step):

```
OCAMLPATH=<prefix>/lib CAML_LD_LIBRARY_PATH=<prefix>/lib/stublibs ocaml pristine_probe.ml hafnium r1.c
```

```c
/* r1.c */ int main(void) { char c = (char)200; return c > 0; }
```

Upstream, default record: `Defined {value: "Specified(0)", ...}`. Upstream, `HafniumImpl`:

```
profile selected: hafnium_aarch64-none-eabi
Exception: Assert_failure ("memory/concrete/impl_mem.ml", 932, 6).
failed: bytes_of_int(signed), i= 200, nbits= 8, [-128 ... 127]
```

A silently mixed answer, no crash:

```c
/* walk.c */
int main(void) {
  unsigned int w = 0x80ff7f01u;
  char *p = (char *)&w;
  int r = 0;
  for (int i = 0; i < 4; i++) if (p[i] < 0) r += 1 << i;
  if (p[1] + p[2] == 0x7f + 0xff) r += 16;
  return r;
}
```

Upstream, `HafniumImpl`: `Specified(12)` -- the bytes 0xff and 0x80 load as negative values (the answer for signed
plain `char`), while `CHAR_MIN` is 0 in the same configuration. `gcc -funsigned-char`: 16.

Of 19 programs run this way under `HafniumImpl` (the fork's `tests/impl_profile/`, the programs that do not need
the C library; recorded in `tests/impl_profile/pristine_hafnium.tsv`): 9 end in the `bytes_of_int(signed)` assertion
(each stores a plain `char` above 127), 1 gives the mixed answer above, 8 answer as `gcc -funsigned-char` does
(switch labels, array sizes, enumerators, `CHAR_MIN`/`CHAR_MAX`, character constants, `_Generic`: front-end and
range results), 1 is a bit-field program upstream does not support. Under the default record all 18 supported
programs answer as `gcc -fsigned-char` does.

(Measured 2026-11-22 on the un-forked upstream library installed from `c3ff8c53f`.)

## Suggested fix

Make the binding a function of its argument, so the record is read at each call (a `diff -u` against `c3ff8c53f`):

```diff
--- a/frontend/model/ail/ailTypesAux.lem
+++ b/frontend/model/ail/ailTypesAux.lem
@@ -23,7 +23,7 @@
 
 (* == Predicates on integerTypes ============================================ *)
 val     is_signed_ity: integerType -> bool
-let is_signed_ity = Implementation.is_signed_ity
+let is_signed_ity ity = Implementation.is_signed_ity ity
 
 (* STD §6.2.5#6, sentence 4 *)
 val is_unsigned_ity: integerType -> bool
```

The generated OCaml becomes `let is_signed_ity ity:bool= ((Ocaml_implementation.get()).is_signed_ity ity)`. Under
the default record nothing changes. No other top-level value of the model or of the hand-written OCaml reads the
record at initialisation: with `get` instrumented to record every call made before `set`, the un-patched binding is
the one call reported, and with the patch none is (the fork's driver on programs with and without the C library
and on its Cabs export path, 2026-11-22).

## Fork status

Fixed in the fork (contract D20), with the patch above, a registered fork-ahead delta. The fork's two engines take
`--impl-profile=default|hafnium` (the oracle driver calls `set` before any phase runs) and under `hafnium` both
answer as `gcc -funsigned-char` does on the 21 supported programs of `tests/impl_profile/`, the three C-library
programs included; `scripts/check_impl_profile.sh` runs them under both profiles and replays the upstream answers
recorded above as its negative control.
