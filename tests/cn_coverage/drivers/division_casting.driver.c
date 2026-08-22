/* cn_coverage driver: deps/cn/tests/cn/division_casting.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 9u,2 (y > 0 per the requires). Verdict: 4 (= 9/2 unsigned). */
extern unsigned int division(unsigned int x, int y);

int main(void)
{
    return (int) division(9u, 2);
}
