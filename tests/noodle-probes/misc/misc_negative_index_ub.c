/* Corner: a[-1] on the array itself is out of bounds (6.5.6p8 UB).
   Verdict-class agreement probe (Cerberus UB_CERB002a). */
int main(void) { int a[3] = {5, 6, 7}; volatile int i = -1; return a[i] & 1; }
