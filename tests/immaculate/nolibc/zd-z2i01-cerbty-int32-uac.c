/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-I-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/impl/cerbty_int32_uac.c. The DIRECT `__cerbty_int32_t` spelling is
   `Signed (IntN_t 32)` (builtins.lem); ocaml_implementation.ml:37-54 `normalise_integerType_`
   aliases IntN_t/Int_leastN_t/Int_fastN_t/Intmax_t/Intptr_t through the type_alias_map
   (:154-171: 8→Ichar, 16→Short, 32→Int_, 64→Long; Intmax_t/Intptr_t→Long) while
   CerberusImpl.normalise_integerType had no such arm, so ailTypesAux.lem:302-303's
   `(Signed (IntN_t _), _) -> fail ()` became reachable on Lean only (PANIC
   `AilTypesAux.le_integer_range: internal error`, exit 134) where both oracles answer
   `Specified(1)`. Ordinary C is unaffected (the shared <stdint.h> typedefs int32_t as plain
   signed int). Pinned DIFF | L=CRASH; the Z2-I-01 fix re-records MATCH. nolibc. */
int main(void) { __cerbty_int32_t s = -1; unsigned int u = 1; return (s + u) == 0; }
