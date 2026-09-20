// program-data parameters E-A D3 witness (2026-09-20; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §4).
// Desugar-time enum read S-3: `_Alignas(enum E)` on a non-character member —
// cabs_to_ail_effect.lem get_alignof -> Implementation.alignof_ty (the oracle's
// Ocaml_implementation.alignof resolves the member type through the enum
// registry); seeded by `alignof_ty_seeded` with the enums registered so far.
// (The `_Alignas(enum E) char c` spelling takes the alignment-agnostic path,
// fuel_hypotheses.txt F-A2, and never reaches the read.)
// Before the seed (the desugar entry's enum map is EMPTY, as the oracle's
// registry is at that moment) the Lean side crashed at this read:
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// The standing corpora exercise NONE of the nine seed sites (record §4.1), so
// this case is the permanent differential witness of the seeded read.
enum E { A, B };
struct S { _Alignas(enum E) int i; char c; };
int main(void) { struct S s; s.c = 1; s.i = 2; return s.c + s.i + (int)_Alignof(struct S); }
