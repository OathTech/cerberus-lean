/* cn_coverage support TU: CN executable-runtime allocator entry points,
 * unsigned-long-long flavour, for deps/cn/tests/cn/alloc_token.c (its
 * #ifndef CN_UTILS declarations use unsigned long long sizes, so it needs
 * its own shim TU — cross-TU declaration compatibility).
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Implemented on the Core-stdlib allocator proxies (see cn_alloc_shim_ul.c). */
void *malloc(unsigned long size);
void free(void *p);

void *cn_malloc(unsigned long long size)
{
    return malloc(size);
}

void cn_free_sized(void *p, unsigned long long size)
{
    free(p);
}
