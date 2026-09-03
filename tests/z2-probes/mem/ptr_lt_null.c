/* Z2 CONTROL (lt_ptrval null arm text): impl_mem.ml:1898-1900 MerrWIP
   "lt_ptrval ==> one null pointer" — mirrored by CerbMem.ltPtrval. nolibc. */
int main(void) { int x; int *p = &x; return p < (int*)0; }
