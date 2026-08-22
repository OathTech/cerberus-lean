/* cn_coverage driver: deps/cn/tests/cn/ghost_bad_ordering.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 41 (x + n - n < MAXi32 per the requires intent). Verdict: 42 (foo returns x+1). */
extern int foo(int x);

int main(void)
{
    return foo(41);
}
