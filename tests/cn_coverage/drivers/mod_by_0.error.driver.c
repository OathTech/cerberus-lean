/* cn_coverage driver: deps/cn/tests/cn/mod_by_0.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 7,3: y nonzero keeps the C defined (the CN error is the missing precondition). Verdict: 1. */
extern int mod(int x, int y);

int main(void)
{
    return mod(7, 3);
}
