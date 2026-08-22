/* cn_coverage driver: deps/cn/tests/cn/division_with_constants.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 100 for both constant-divisor functions (10, -10), plus the constant case (-2). Verdict: 10 + (-10) + (-2) = -2. */
extern int divide_by_ten(int x);
extern int divide_by_neg_ten(int x);
extern int division_diff_sign(void);

int main(void)
{
    return divide_by_ten(100) + divide_by_neg_ten(100) + division_diff_sign();
}
