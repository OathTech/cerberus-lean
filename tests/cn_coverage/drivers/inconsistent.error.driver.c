/* cn_coverage driver: deps/cn/tests/cn/inconsistent.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs (the CN requires is inconsistent; C body is empty). Verdict: 0. */
extern void f(void);

int main(void)
{
    f();
    return 0;
}
