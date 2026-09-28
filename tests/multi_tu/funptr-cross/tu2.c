/* funptr-cross, TU 2: calls through tu1's table (including tu1's static
   function) and passes its OWN static function to tu1's apply. Expected:
   10 * 3 + 7 + 21 = 58. (Equality of a pointer to `inc` taken here with the
   table entry taken in tu1 is deliberately NOT part of the result: both
   engines evaluate it to 0, which ISO 6.5.9#6 does not allow — recorded in
   docs/2026-09-28_thin-surface-tests-record.md as a shared-model observation.) */
extern int (*table[2])(int);
int apply(int (*f)(int), int v);
static int neg(int x) { return -x; }
int main(void) {
  int a = table[0](5);            /* 10, tu1's static twice */
  int b = table[1](6);            /* 7 */
  int c = apply(neg, -21);        /* 21, tu2's static via tu1 */
  return a * 3 + b + c;
}
