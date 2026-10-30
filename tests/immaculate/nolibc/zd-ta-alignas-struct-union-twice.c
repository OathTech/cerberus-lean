/* merge-base bump stage 1 pin (2026-10-30; pre-merge review P1, record §6b):
   as zd-ta-alignas-union-twice.c with the union reached through a struct
   member (alignof's struct arm recurses into the union arm's global read).
   Pinned MATCH | L=Specified(8) with the 736690a65 alignof line carried ahead. */
union U { int x; double y; };
struct S { char a; union U u; };
_Alignas(struct S) _Alignas(2) char c;
int main(void) { return _Alignof(struct S); }
