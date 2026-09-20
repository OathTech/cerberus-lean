// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum reads S-8 and S-9: `sizeof` of an ENUM-typed arithmetic
// expression — cabs_to_ail.lem desugar_expression's sizeof arm types the operand
// (GenTyping.annotate_expression: usual arithmetic conversions ->
// AilTypesAux.integer_promotion -> normalise_integerType; seeded by
// `annotate_expression_seeded`) and then reads its ctype
// (Translation_aux.qualified_ctype_of -> GenTypesAux.interpret_gen* ->
// normalise_integerType; seeded by `qualified_ctype_of_seeded` — the ninth
// site, found by THIS witness after the first eight seeds: record §4.5 W17).
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
int main(void) { return (int)sizeof((enum E)1 + 1); }
