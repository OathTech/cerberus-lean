/* Z2 probe (isWellAligned_ptrval FunctionNoParams arm, second shape): the
   call shape is rejected by the shared front end (constraint violation);
   here the K&R function pointer is only dereferenced-and-decayed. nolibc. */
int f();
int f() { return 7; }
int main(void) { int (*fp)() = f; int (*g)() = *fp; return g == fp; }
