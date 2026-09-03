/* Corner: the conditional operator in a static-storage initialiser is an
   integer constant expression (ISO C11 6.6p3, p6, p7). gcc returns 10.
   Both Cerberus engines: "constraint violation: initializer element is not
   a compile-time constant" (desugaring). */
static int a = (3 > 2) ? 10 : 20;
int main(void) { return a; }
