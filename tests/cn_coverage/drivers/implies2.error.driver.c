/* cn_coverage driver: deps/cn/tests/cn/implies2.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 0 (the CN assert is the error under test; C is identity). Verdict: 0. */
extern int identity(int x);

int main(void)
{
    return identity(0);
}
