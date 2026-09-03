/* Corner: an indeterminate (unspecified) value as a controlling expression:
   the model's treatment (nondeterministic branch, unspecified result, or
   UB) — verdict-SET agreement probe (ISO C11 6.3.2.1p2 makes the read UB
   when the address is never taken; Cerberus reports Unspecified). */
int main(void) { int x; return x ? 1 : 2; }
