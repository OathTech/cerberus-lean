/* cn_coverage ELAB driver: deps/cn/tests/cn/spec_after_decl.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); this driver is fresh
 * authorship for the cerberus-lean CN-coverage lane (see ../README.md).
 * Reason for trivial main: declaration-only file (foo is declared, never defined). The corpus TU is still fully
 * elaborated, translated and linked by both pipelines. Verdict: 0. */
int main(void) { return 0; }
