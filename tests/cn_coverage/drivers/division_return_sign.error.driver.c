/* cn_coverage driver: deps/cn/tests/cn/division_return_sign.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 8,2u (y != 0 per the requires). Verdict: 4. */
extern int different_sign(int x, unsigned int y);

int main(void)
{
    return different_sign(8, 2u);
}
