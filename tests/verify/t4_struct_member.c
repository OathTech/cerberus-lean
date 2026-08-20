/* T4 (arc-7 verification slate): THE EXIT-CRITERION TARGET.
   struct-layout points-to (member offsets): member write/read of a
   symbolic v through a second member's write (frame across offsets).
   Theorem shape: forall v, outcomes = {Specified(v)}, no UB. */
struct S { int a; int b; };

int memb(int v) {
  struct S s;
  s.a = v;
  s.b = 7;
  return s.a;
}

int main(void) { return memb(42); }
