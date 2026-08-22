/* cn_coverage driver: deps/cn/tests/cn/implies3.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No meaningful inputs (the CN requires is inconsistent; C body returns 0). Verdict: 0. */
extern int foo(void);

int main(void)
{
    return foo();
}
