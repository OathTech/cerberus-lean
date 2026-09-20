// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum read S-4a: a tentative definition redeclared —
// cabs_to_ail_effect.lem register_global_object_definition2 ->
// AilTypesAux.make_composite -> Implementation.normalise_integerType (the enum's
// compatible type decides compatibility, C11 §6.7.2.2#4); seeded by
// `make_composite_seeded` with the enums registered so far.
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
enum E g;
enum E g;
int main(void) { g = B; return (int)g; }
