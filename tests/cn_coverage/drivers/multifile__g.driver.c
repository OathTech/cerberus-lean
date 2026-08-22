/* cn_coverage driver: deps/cn/tests/cn/multifile/g.c (linked with
 * multifile/f.c — g and f are mutually recursive across the two TUs).
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Declaration from the corpus header g.h (include-by-reference).
 * Input: g(25) = 25 mod 12 per the g.h spec (25 -> f(13) -> g(1) -> 1).
 * Verdict: 1. */
#include "g.h"

int main(void)
{
    return g(25);
}
