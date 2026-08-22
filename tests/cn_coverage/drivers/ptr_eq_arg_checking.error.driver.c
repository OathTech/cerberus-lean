/* cn_coverage driver: deps/cn/tests/cn/ptr_eq_arg_checking.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs: a local unsigned address and 0 (the CN requires is the ill-typed ptr_eq under test; C body is empty). Verdict: 0. */
extern void f(unsigned int *x, unsigned int y);

int main(void)
{
    unsigned int a = 0u;
    f(&a, 0u);
    return 0;
}
