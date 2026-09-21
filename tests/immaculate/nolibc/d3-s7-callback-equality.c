// program-data parameters E-A, pre-merge audit E1 witness (2026-09-20/21; record
// lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md §10; the
// reproducer is the Codex audit's, 2026-09-20_enum-premerge-audit.md E1).
// Desugar-time enum read S-7: GNU `typeof(({ … }))` — the statement expression is
// typed by GenTyping.annotate_expression with the BLOCK-typing callback
// `GenTyping.annotate_block ret_ty`, and the enum/integer compatibility decision
// inside the block (the pointer equality `&e == &n`) reads the enum map. The
// callback used to be constructed at the call site — OUTSIDE the seed — so on Lean it
// was already applied to the desugar entry's EMPTY map and the seed could not re-seed
// it (a `reader_seed` does not re-seed closures constructed outside its extent); the
// fix builds the callback inside `Mini_pipeline.annotate_expression_seeded`. Before the
// fix the Lean side crashed here while the oracle ran it (verbatim, this head):
//   PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered
// Expected on both engines: Specified(3).
enum E {A,B}; int main(void){typeof(({enum E e=A; unsigned int n=0; &e==&n;})) x=3;return x;}
