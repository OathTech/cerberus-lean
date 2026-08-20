/* T2 (arc-7 verification slate): pure-step + bind; the no-signed-overflow
   precondition is FORCED by the UB-freedom obligation.
   Theorem shape: forall a b with INT_MIN <= a+b <= INT_MAX,
   outcomes = {Specified(a+b)}, no UB. */
int add(int a, int b) { return a + b; }

int main(void) { return add(30, 12); }
