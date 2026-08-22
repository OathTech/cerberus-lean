/* cn_coverage driver: deps/cn/tests/cn/implies_precedence.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 0,0 (satisfy the left disjunct of the CN assert). Verdict: 0 (foo returns 0). */
extern int foo(int x, int y);

int main(void)
{
    return foo(0, 0);
}
