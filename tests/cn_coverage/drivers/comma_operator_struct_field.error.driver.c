/* cn_coverage driver: deps/cn/tests/cn/comma_operator_struct_field.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * The global b has an unnamed struct type, so only calls cross the TU boundary. Verdict: 0 (g returns b.a, zero-initialised). */
extern void f(void);
extern int g(void);

int main(void)
{
    f();
    return g();
}
