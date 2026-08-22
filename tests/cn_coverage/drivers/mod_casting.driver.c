/* cn_coverage driver: deps/cn/tests/cn/mod_casting.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 7u,3 (y > 0 per the requires). Verdict: 1 (= 7%3 unsigned). */
extern unsigned int mod(unsigned int x, int y);

int main(void)
{
    return (int) mod(7u, 3);
}
