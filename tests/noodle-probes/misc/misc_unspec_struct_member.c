/* Corner: reading an unwritten member of a partially assigned struct whose
   address was taken (so 6.3.2.1p2 UB does not apply; value indeterminate). */
int main(void) { struct S { int a, b; } s; int *p = &s.a; *p = 1; return s.b & 1; }
