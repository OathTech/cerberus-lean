// ts-fmt-s-null (2026-09-28 thin-surface tests): %s given a null pointer —
// both engines fail-stop in the pointer shift of the character scan
// ("TODO(pure shift a null pointer should be undefined behaviour)", OCaml
// impl_mem / CerbMem.arrayShiftPtrval) instead of reporting UB. Pinned as the
// both-crash pair (MATCH | L=CRASH).
#include <stdio.h>
int main(void) { char *p = 0; return printf("[%s]\n", p); }
