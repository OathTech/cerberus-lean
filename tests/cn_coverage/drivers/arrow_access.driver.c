/* cn_coverage driver: deps/cn/tests/cn/arrow_access.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * struct s re-declared here as a compatible type (C11 6.2.7) — the corpus
 * defines it in the .c file, not a header. Inputs: an owned struct with
 * y == 0 (the arrow_access_2 requires). Verdict: 7 (its ensures: y == 7). */
struct s {
  int x;
  int y;
};

extern void arrow_access_1(void);
extern void arrow_access_2(struct s *origin);

int main(void)
{
    struct s o = {0, 0};
    arrow_access_1();
    arrow_access_2(&o);
    return o.y;
}
