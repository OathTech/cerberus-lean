// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum read S-4c: an external object declared twice with an enum
// type — cabs_to_ail_effect.lem register_external_object_declaration ->
// AilTypesAux.are_compatible and make_composite -> normalise_integerType; seeded
// by `are_compatible_seeded`/`make_composite_seeded`.
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
extern enum E g;
extern enum E g;
enum E g = B;
int main(void) { return (int)g; }
