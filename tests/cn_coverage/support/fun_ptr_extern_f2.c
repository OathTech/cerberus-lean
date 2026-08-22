/* cn_coverage support TU for deps/cn/tests/cn/fun_ptr_extern.c.
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * fun_ptr_extern.c takes the address of and (via a function pointer) calls
 * the extern f2, which it only specifies (spec: requires true; ensures
 * true). Any total implementation satisfies that; return y keeps the
 * call_site(5, 42) verdict readable. */
int f2(int x, int y)
{
    return y;
}
