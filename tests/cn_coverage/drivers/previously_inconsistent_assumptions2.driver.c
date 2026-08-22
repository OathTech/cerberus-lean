/* cn_coverage ELAB driver: deps/cn/tests/cn/previously_inconsistent_assumptions2.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); this driver is fresh
 * authorship for the cerberus-lean CN-coverage lane (see ../README.md).
 * Reason for trivial main: no safe entry: a() is an intentional infinite loop (upstream issue 551 regression test). The corpus TU is still fully
 * elaborated, translated and linked by both pipelines. Verdict: 0. */
int main(void) { return 0; }
