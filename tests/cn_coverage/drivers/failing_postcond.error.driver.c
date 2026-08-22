/* cn_coverage driver: deps/cn/tests/cn/failing_postcond.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input 41 (x < INT_MAX per the requires). Verdict: 42 (inc returns x+1). */
extern int inc(int x);

int main(void)
{
    return inc(41);
}
