// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum read S-5a: `_Generic` with TWO type associations — the
// overlap check cabs_to_ail.lem find_compatible_generic_association ->
// AilTypesAux.are_compatible -> normalise_integerType (a single association
// never compares and never reaches the read); seeded by
// `find_compatible_generic_association_seeded`.
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
int main(void) { enum E e = B; return _Generic(e, enum E: 7, long: 9, default: 3); }
