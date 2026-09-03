/* Corner: main may be called recursively in C (unlike C++) (ISO C11
   5.1.2.2.1 says nothing against it; 6.5.2.2). */
int main(void) { static int n; if (n++ < 3) main(); return n; }   /* 4 */
