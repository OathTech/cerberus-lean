/* Corner (multi-TU): same-named internal-linkage objects and functions in
   two TUs are distinct (ISO C11 6.2.2p3). tu1 owns main. */
static int counter = 100;
static int bump(void) { return ++counter; }
int other_bump(void);
int main(void) { return bump() + other_bump(); }   /* 101 + 1 = 102 */
