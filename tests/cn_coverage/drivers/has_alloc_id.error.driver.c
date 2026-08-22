/* cn_coverage driver: deps/cn/tests/cn/has_alloc_id.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input: address of a local int (non-null per the requires). f only carries a CN assert. Verdict: 0. */
extern void f(int *p);

int main(void)
{
    int a = 0;
    f(&a);
    return 0;
}
