/* TU 1 of the tentative-definition linking fixture (arc-5 S2).
   Expected: 42. `int shared;` here is a TENTATIVE definition that must
   resolve to tu2.c's initialized definition at link time — the
   LK_tentative → LK_normal arm of link_extern (core_linking.lem:36-46)
   plus redundant-tentative removal / dependency reorder in merge_globs
   (core_linking.lem:255-280). If each TU wrongly kept its own object,
   main's increment would act on a zero-initialized copy and the result
   would be 2, not 42. */
int shared;

int get_shared(void);

int main(void) {
    shared += 2;             /* 40 (tu2 init) + 2 */
    return get_shared();     /* 42, read through the other TU */
}
