/* R6 EASY e5 (arc-18 breadth campaign): 9-arm literal disjunction
   chain — deps/libxml2/uri.c:79 IS_MARK shape (short-circuit ||
   ladder). Census row §2.
   Theorem shape: forall seed, outcomes(is_mark(42)) =
   {Specified(1)}, no UB. */
int is_mark(int c)
{
  if (c == '-' || c == '_' || c == '.' || c == '!' || c == '~' ||
      c == '*' || c == 39 || c == '(' || c == ')') {
    return 1;
  }
  return 0;
}

int main(void) { return is_mark(42); }
