/* cn_coverage driver: deps/cn/tests/cn/multifile/f.c (linked with
 * multifile/g.c — f and g are mutually recursive across the two TUs).
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Declarations from the corpus headers f.h/g.h (include-by-reference).
 * Inputs: the corpus test_c exercises f(12), f(25) with its CN asserts;
 * then f(25) = 25 mod 12 per the f.h spec. Verdict: 1. */
#include "f.h"

extern void test_c(void);

int main(void)
{
    test_c();
    return f(25);
}
