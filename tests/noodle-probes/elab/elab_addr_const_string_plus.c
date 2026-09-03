/* Corner: an address constant formed from a string literal plus an integer
   constant (ISO C11 6.6p9) in a static initialiser. gcc returns 101 ('e').
   Both Cerberus engines: "initializer element is not a compile-time
   constant" — while `static int *q = arr + 2;` IS accepted (see
   elab_const_expr_static_init.c). Adjacent to upstream-tray 09. */
static const char *s = "hello" + 1;
int main(void) { return *s; }
