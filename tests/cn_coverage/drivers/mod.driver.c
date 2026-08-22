/* cn_coverage driver: deps/cn/tests/cn/mod.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 7,3 (y != 0 per the requires). Verdict: 1 (= 7%3, the ensures). */
extern int mod(int x, int y);

int main(void)
{
    return mod(7, 3);
}
