// fmt-014: %e — until 2026-11-07 not a conversion the model parsed: the whole
// format was an Invalid_format UB in both engines (a false UB on a conforming
// call; the format deliberately has NO newline: the UB payload embedded the
// format text unescaped, and a raw newline there breaks the batch protocol in
// both engines, recorded in docs/2026-09-28_thin-surface-tests-record.md).
// Since fix/printf-refusals (contract D16, upstream-tray report 68) the parser
// accepts %e and the conversion stage REFUSES it on both engines (not
// implemented; oracle exit 125, Lean abort 134, one attributed text): the lane
// classes the row CERB_SKIP; the row-1 witness scripts/check_printf_refusals.sh
// pins the text.
#include <stdio.h>
int main(void) { return printf("[%e]", 1.0); }
