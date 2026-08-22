/* cn_coverage driver: deps/cn/tests/cn/spec_after_curly_brace.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 1,2 (unconstrained). Verdict: 0 (foo returns 0). */
extern int foo(int x, int y);

int main(void)
{
    return foo(1, 2);
}
