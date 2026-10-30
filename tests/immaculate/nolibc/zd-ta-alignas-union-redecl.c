/* merge-base bump stage 1 pin (2026-10-30; pre-merge review P1, record §6b):
   an aligned redeclaration compares the two alignments through
   cabs_to_ail_effect.lem get_compatible_alignment_requirements -> get_alignof;
   with a union type the oracle at c3ff8c53f crashed (the Tags global unset at
   desugar time, see zd-ta-alignas-union-twice.c) where Lean answered 0.
   Pinned MATCH | L=Specified(0) with the 736690a65 alignof line carried ahead. */
union U { int x; double y; };
extern _Alignas(union U) char c;
extern _Alignas(union U) char c;
int main(void) { return 0; }
