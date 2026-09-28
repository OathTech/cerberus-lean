// ts-fmt-star-precision (2026-09-28 thin-surface tests): a '*' precision is
// not served either — both engines fail-stop at "TODO: Formatted.convert, *
// prec". Pinned as the both-crash pair (MATCH | L=CRASH).
#include <stdio.h>
int main(void) { return printf("[%.*d]\n", 3, 7); }
