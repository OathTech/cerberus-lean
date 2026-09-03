/* Corner: negative subscript on an interior pointer is defined (6.5.6p8):
   p = a+2; p[-2] == a[0]. */
int main(void) { int a[3] = {5, 6, 7}; int *p = a + 2; return p[-2] + p[-1]; }   /* 11 */
