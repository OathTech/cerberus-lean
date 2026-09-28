// fmt-014: %e is not a conversion the model parses: the whole format is an
// Invalid_format UB in both engines (the model serves only d i o u x X f c s p
// %). The format deliberately has NO newline: the UB payload embeds the format
// text unescaped, and a raw newline there breaks the batch protocol in both
// engines (recorded in docs/2026-09-28_thin-surface-tests-record.md).
#include <stdio.h>
int main(void) { return printf("[%e]", 1.0); }
