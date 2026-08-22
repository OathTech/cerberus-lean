/* cn_coverage driver: deps/cn/tests/cn/mod_precedence.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs; the three functions encode their own expected constants (10, 2, 79 per the ensures). Verdict: 91 (their sum). */
extern int mod_no_parenthesis(void);
extern int multiply_then_mod(void);
extern int divide_multiply_mod_add_subtract(void);

int main(void)
{
    return mod_no_parenthesis() + multiply_then_mod()
        + divide_multiply_mod_add_subtract();
}
