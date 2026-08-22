/* cn_coverage driver: deps/cn/tests/cn/division_return_size.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 9,2L (y != 0 per the requires). Verdict: 4. */
extern int different_size(int x, long y);

int main(void)
{
    return different_size(9, 2L);
}
