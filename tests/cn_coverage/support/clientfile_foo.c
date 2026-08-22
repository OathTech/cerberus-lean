/* cn_coverage support TU for deps/cn/tests/cn/accesses_on_spec/clientfile.c.
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * clientfile.c calls foo, which its header libfile.h only specifies
 * (spec: requires myval == 1 and i == 1; ensures return == 0). This fresh
 * implementation satisfies that spec; myval is the tentative definition the
 * clientfile TU gets from libfile.h. */
extern int myval;

int foo(int i)
{
    if (i == myval) {
        return 0;
    } else {
        return 1;
    }
}
