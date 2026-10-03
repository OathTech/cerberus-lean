/* Upstream-tray draft 47, `alignas_self.c` — fork fix P2d-3 (2026-10-03). `_Alignas(T)` with T the
   struct being defined: T is incomplete until its closing brace (C11 §6.7.2.3#4), so this is a
   constraint violation (§6.7.5#5 + §6.5.3.4#1, sentence 2). Both fork engines now refuse it with
   the AlignofInvalidApplication diagnostic. Pristine upstream b9aeedcb4 does not terminate (rc 124);
   gcc rejects it. */
struct A { _Alignas(struct A) char c; };
int main(void) { return sizeof(struct A); }
