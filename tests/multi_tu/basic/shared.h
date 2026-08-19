/* Shared header for the 2-TU linking fixture (arc-5 S2).
   The struct is declared in BOTH TUs: each TU gets its own tag symbol
   (different per-TU digests), so passing `struct pair` by value across
   the TU boundary exercises the cross-TU tag-compatibility path
   (ctype_aux.lem:113: from_same_translation_unit FALSE → name+member
   structural compatibility — the reason real digests are required). */
struct pair {
    int a;
    int b;
};

int helper(struct pair p);
