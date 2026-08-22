/* cn_coverage support TU: CN executable-runtime allocator entry points,
 * size_t (= unsigned long) flavour, for deps/cn/tests/cn/mask_ptr.c and
 * simplify_array_shift.c (their #ifndef CN_UTILS declarations).
 * Corpus files license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Implemented on the Core-stdlib allocator proxies (malloc/free/
 * aligned_alloc claim their C names via std.core ailnames — available under
 * --nolibc, the oracle mode of this lane). cn_free_sized drops the size
 * argument: the proxy free needs only the pointer. */
void *malloc(unsigned long size);
void free(void *p);
void *aligned_alloc(unsigned long alignment, unsigned long size);

void *cn_malloc(unsigned long size)
{
    return malloc(size);
}

void cn_free_sized(void *p, unsigned long size)
{
    free(p);
}

void *cn_aligned_alloc(unsigned long alignment, unsigned long size)
{
    return aligned_alloc(alignment, size);
}
