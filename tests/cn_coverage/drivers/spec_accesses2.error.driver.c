/* cn_coverage driver: deps/cn/tests/cn/spec_accesses2.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 42; the C body adds the zero-initialised global z. Verdict: 42. */
extern int foo(int x);

int main(void)
{
    return foo(42);
}
