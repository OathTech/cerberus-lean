/* cn_coverage driver: deps/cn/tests/cn/has_alloc_id_ptr_eq2.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs: two distinct locals (both with alloc ids per the requires). Verdict: 0 (f returns p==q). */
extern int f(int *p, int *q);

int main(void)
{
    int a = 0;
    int b = 0;
    return f(&a, &b);
}
