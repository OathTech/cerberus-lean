/* cn_coverage driver: deps/cn/tests/cn/missing_resource.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs: a local int address and 5 (x < 12 per the requires). Verdict: 5 (f returns x). */
extern int f(int *p, int x);

int main(void)
{
    int a = 0;
    return f(&a, 5);
}
