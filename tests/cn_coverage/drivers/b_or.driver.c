/* cn_coverage driver: deps/cn/tests/cn/b_or.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 5,3. Verdict: 7 (= 5|3, the ensures). */
extern int f(int x, int y);

int main(void)
{
    return f(5, 3);
}
