/* cn_coverage driver: deps/cn/tests/cn/array_shift_mismatch.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input: a two-int array (non-null per the requires). Verdict: 1 iff f returns &a[1] (= p+1 per the body). */
extern int *f(int *p);

int main(void)
{
    int a[2] = {0, 0};
    return f(a) == &a[1];
}
