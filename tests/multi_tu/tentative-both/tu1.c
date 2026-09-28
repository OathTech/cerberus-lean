/* tentative-both, TU 1: two tentative definitions of the same object in one
   TU (allowed: they are one definition), and the object is also declared
   extern in TU 2 without any initialised definition anywhere: it is
   zero-initialised. */
int t;
int t;
int bump(void) { return ++t; }
