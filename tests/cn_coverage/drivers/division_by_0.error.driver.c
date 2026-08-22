/* cn_coverage driver: deps/cn/tests/cn/division_by_0.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Inputs 7,2: y nonzero keeps the C defined (the CN error is the MISSING precondition, not our input). Verdict: 3. */
extern int division(int x, int y);

int main(void)
{
    return division(7, 2);
}
