/* cn_coverage driver: deps/cn/tests/cn/cnfunction_mismatched_args1.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 4. Verdict: 5 (c_bw_or returns x|1). */
extern int c_bw_or(int x);

int main(void)
{
    return c_bw_or(4);
}
