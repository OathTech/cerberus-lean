/* cn_coverage driver: deps/cn/tests/cn/implies_associativity.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs; foo only carries the CN associativity assert. Verdict: 0. */
extern void foo(void);

int main(void)
{
    foo();
    return 0;
}
