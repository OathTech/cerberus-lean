/* cn_coverage driver: deps/cn/tests/cn/spec_after_def.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 1,2 (unconstrained; foo body is empty). Verdict: 0. */
extern void foo(int a, int b);

int main(void)
{
    foo(1, 2);
    return 0;
}
