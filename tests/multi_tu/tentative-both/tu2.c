/* tentative-both, TU 2: extern declaration only. */
extern int t;
int bump(void);
int main(void) { int a = t; bump(); bump(); return a * 100 + t; }   /* 2 */
