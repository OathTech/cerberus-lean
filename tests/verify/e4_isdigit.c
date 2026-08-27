/* R6 EASY e4 (arc-18 breadth campaign): range-pair char-class
   predicate — deps/libxml2/uri.c:127 ISA_DIGIT shape (>= '0' &&
   <= '9', short-circuit &&). Census row §2.
   Theorem shape: forall seed, outcomes(is_digit(53)) =
   {Specified(1)}, no UB. */
int is_digit(int c)
{
  if (c >= '0' && c <= '9') {
    return 1;
  }
  return 0;
}

int main(void) { return is_digit(53); }
