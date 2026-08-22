/* cn_coverage driver: deps/cn/tests/cn/mod_with_constants.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 7 for both constant-modulus functions (1, 1), plus the constant case (-2). Verdict: 1 + 1 + (-2) = 0. */
extern int x_mod_three(int x);
extern int x_mod_neg_three(int x);
extern int mod_first_operand_neg(void);

int main(void)
{
    return x_mod_three(7) + x_mod_neg_three(7) + mod_first_operand_neg();
}
