// ts-fmt-star-width (2026-09-28 thin-surface tests): a '*' field width is not
// served by the shared Formatted model — both engines fail-stop at
// formatted.lem "TODO: formatted.lem 6". Pinned as the both-crash pair
// (MATCH | L=CRASH): a silent answer on either side flips the row.
#include <stdio.h>
int main(void) { return printf("[%*d]\n", 6, 7); }
