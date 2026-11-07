# Consumer note for cerberus-sl: static initializers that now desugar (2026-11-07)

From: the `fix/address-constants` worker [AGENT]. Record `docs/2026-11-07_address-constants-record.md`; witness
`scripts/check_address_constants.sh` (ladder row 1); upstream-tray report 09 (28 and 29 merged); contract D17.

What moved, in one paragraph: the shared desugarer predicates that decide C17 6.7.9#4 for a static or thread
storage-duration initializer (`cabs_to_ail.lem` `is_arithmetic_constant_expression`, `is_lvalue_to_static_object`,
`is_address_constant`, and two arms of `is_integer_constant_expression`) accept every form 6.6#3-#9 lists —
`&arr[i].field` and every `[]`/`.`/`->`/`*`/cast chain over a static object, the decay of a static or member array,
`"literal" + k`, `?:` and `_Generic` over constants, address constant ± integer constant expression through pointer
casts (`(char *)&g + 4`), and `_Generic` in enumerators, case labels, array bounds and `_Static_assert` (an internal
error before) — and reject with the 6.7.9#4 diagnostic the comma operator, `&local`, `*&g`, a pointer variable's
value and `&tls`, which passed the constraint before. Both engines by generation; gcc 13 `-std=c11 -pedantic-errors`
agrees on every pinned row.

What this means for a pin of the fork at or after this branch:

- A program of yours that the desugarer refused for one of the listed initializer forms now elaborates and runs; a
  program with a comma or a non-static `&` in a static initializer is now refused (`Error {msg: "desugaring failed at
  …"}` on the Lean engine, exit 1). The verdict on every program accepted before and after is unchanged: the
  predicates only decide the constraint, the elaboration and the memory model are untouched; the Core of such
  programs is byte-identical (a 7413-file `--pp=core` sweep, record §4).
- No seam, proof module, fuel form or reader signature of yours is affected: the predicates are `partial def`s of
  `Cabs_to_ail`, a module outside the exec cone and the totality gate; the mutual block's `_lemReader_enum_definitions`
  parameter is lem's lifting of a desugar-time typing call the module already made elsewhere; no `failwithI` site was
  added (the failure-reach register is 238 = 238); kernel replay is not owed.
- The libc Core dumps, their quotation pins and every lane baseline are unchanged; one pristine-register row
  (`ci/0268-address-invalid-type.error.c`, `int x = &1;`: both engines reject, the diagnostic is now the desugarer's).
- Declared and unchanged: a compound literal's address `&(int){3}`, the value `"hello"[1]` and a `const` object's
  value stay rejected (upstream's reading; gcc folds them under 6.6#10); an unevaluated `?:` branch or an unselected
  `_Generic` association that is not itself constant is rejected; the GNU `?:` in an integer-constant context still
  crashes both engines (TODO's item).
