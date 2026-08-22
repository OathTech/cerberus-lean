/* cn_coverage driver: deps/cn/tests/cn/block_type.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs: two local ints; block_notype_1 wants uninitialised W(p), block_notype_2 writes 7. Verdict: 7. */
extern void block_notype_1(int *p);
extern void block_notype_2(int *p);

int main(void)
{
    int a;
    int b;
    block_notype_1(&a);
    block_notype_2(&b);
    return b;
}
