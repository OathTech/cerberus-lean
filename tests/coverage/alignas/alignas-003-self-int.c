/* Upstream-tray draft 47, `alignas_int_self.c` — fork fix P2d-3 (2026-10-03). The non-character
   form of alignas-001: constraint violation (C11 §6.7.5#5 + §6.5.3.4#1, sentence 2). Both fork
   engines now refuse it with the AlignofInvalidApplication diagnostic. Pristine upstream b9aeedcb4
   raises an uncaught Not_found (rc 125); gcc rejects it. */
struct A { _Alignas(struct A) int c; };
int main(void) { return sizeof(struct A); }
