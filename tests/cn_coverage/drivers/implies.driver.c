/* cn_coverage driver: deps/cn/tests/cn/implies.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 0 (makes the CN implication antecedent true). Verdict: 0 (identity). */
extern int identity(int x);

int main(void)
{
    return identity(0);
}
