/* cn_coverage driver: deps/cn/tests/cn/and_or_precedence.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs satisfy g1 precondition disjuncts: (0,0) the left, (1,1) the right. Verdict: 0. */
extern void g1(int x, int y);

int main(void)
{
    g1(0, 0);
    g1(1, 1);
    return 0;
}
