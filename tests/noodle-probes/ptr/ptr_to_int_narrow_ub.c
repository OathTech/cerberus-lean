/* Corner: converting a pointer to an integer type too narrow to hold it
   (ISO C11 6.3.2.3p6: result is impl-defined; if not representable, UB).
   Cerberus reports UB024. Verdict-class agreement probe. */
int main(void) {
  int x = 3;
  int *p = &x;
  int i = (int)p;
  return i & 1;
}
