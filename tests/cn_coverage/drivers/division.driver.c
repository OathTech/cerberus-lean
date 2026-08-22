/* cn_coverage driver: deps/cn/tests/cn/division.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 7,2 (y != 0 per the requires). Verdict: 3 (= 7/2, the ensures). */
extern int division(int x, int y);

int main(void)
{
    return division(7, 2);
}
