/* Corner: comparing a pointer to a dead (out-of-scope) automatic object
   for equality: the value is indeterminate (ISO C11 6.2.4p2). Cerberus
   tracks dead allocations. Verdict-class agreement probe. */
int *leak(void) { int x = 1; return &x; }
int main(void) {
  int *p = leak();
  int y = 2;
  return p == &y;
}
