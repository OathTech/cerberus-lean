/* cn_coverage driver: deps/cn/tests/cn/double_spec1.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 40 (x < MAXi32 - 1 per the definition requires). Verdict: 42 (the defined foo returns x+2). */
extern int foo(int x);

int main(void)
{
    return foo(40);
}
