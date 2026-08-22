/* cn_coverage driver: deps/cn/tests/cn/pointer_to_int_cast.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * No inputs; f casts a local address to int (both sides should verdict this identically, UB or not). Verdict: 0 if defined. */
extern void f(void);

int main(void)
{
    f();
    return 0;
}
