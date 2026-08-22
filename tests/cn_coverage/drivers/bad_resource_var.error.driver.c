/* cn_coverage driver: deps/cn/tests/cn/bad_resource_var.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input: an owned int 41 (RW(p), X < INT_MAX per the requires). Verdict: 42 (inc adds 1 in place). */
extern void inc(int *p);

int main(void)
{
    int a = 41;
    inc(&a);
    return a;
}
