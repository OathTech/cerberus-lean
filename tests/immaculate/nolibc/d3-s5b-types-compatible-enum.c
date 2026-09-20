// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum read S-5b: `__builtin_types_compatible_p(enum E, …)` —
// cabs_to_ail.lem desugar_expression's builtin arm -> AilTypesAux.are_compatible
// -> normalise_integerType; seeded by `E.are_compatible_seeded`. Expected 1:
// enum E's compatible type is `unsigned int` (GCC's rule, no negative
// enumerator), so the second operand's `int` is NOT compatible.
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
int main(void) { return __builtin_types_compatible_p(enum E, unsigned int) + 2 * __builtin_types_compatible_p(enum E, int); }
