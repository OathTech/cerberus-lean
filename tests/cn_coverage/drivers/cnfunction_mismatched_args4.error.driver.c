/* cn_coverage driver: deps/cn/tests/cn/cnfunction_mismatched_args4.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 4,2. Verdict: 6 (c_bw_or returns x|y). */
extern int c_bw_or(int x, int y);

int main(void)
{
    return c_bw_or(4, 2);
}
