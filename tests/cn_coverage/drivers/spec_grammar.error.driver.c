/* cn_coverage driver: deps/cn/tests/cn/spec_grammar.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs; f is empty (g is declared but never defined, so it is not called). Verdict: 0. */
extern void f(void);

int main(void)
{
    f();
    return 0;
}
