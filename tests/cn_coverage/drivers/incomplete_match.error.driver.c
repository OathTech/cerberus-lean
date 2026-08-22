/* cn_coverage driver: deps/cn/tests/cn/incomplete_match.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 1 (unconstrained). check_foo has an empty body. Verdict: 0. */
extern void check_foo(int x);

int main(void)
{
    check_foo(1);
    return 0;
}
