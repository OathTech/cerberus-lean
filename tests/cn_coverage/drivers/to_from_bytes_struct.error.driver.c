/* cn_coverage ELAB driver: deps/cn/tests/cn/to_from_bytes_struct.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); this driver is fresh
 * authorship for the cerberus-lean CN-coverage lane (see ../README.md).
 * Reason for trivial main: its only function is static (untransmute_to_blob), unreachable from a separate driver TU, and has an empty C body anyway. The corpus TU is still fully
 * elaborated, translated and linked by both pipelines. Verdict: 0. */
int main(void) { return 0; }
