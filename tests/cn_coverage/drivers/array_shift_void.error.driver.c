/* cn_coverage driver: deps/cn/tests/cn/array_shift_void.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Input: a 4-byte allocation from the corpus _malloc wrapper (spec: W bytes over size). Store then reload one byte. Verdict: 7. */
extern void *_malloc(unsigned long size);

int main(void)
{
    unsigned char *p = _malloc(4);
    p[0] = 7;
    return p[0];
}
