/* cn_coverage driver: deps/cn/tests/cn/issue_113.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs: null pointer and 0 (regression shape only; body is empty). Verdict: 0. */
extern void f(char *p, unsigned x);

int main(void)
{
    f((char *) 0, 0u);
    return 0;
}
