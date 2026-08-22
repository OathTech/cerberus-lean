/* cn_coverage driver: deps/cn/tests/cn/division_precedence.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs; the three functions encode their own expected constants (16, 28, 29 per the ensures). Verdict: 73 (their sum). */
extern int divide_no_parenthesis(void);
extern int multiply_then_divide(void);
extern int divide_multiply_add_subtract(void);

int main(void)
{
    return divide_no_parenthesis() + multiply_then_divide()
        + divide_multiply_add_subtract();
}
