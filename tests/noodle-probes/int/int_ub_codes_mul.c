/* Corner: UB classification for signed multiplication overflow of promoted
   unsigned short operands (ISO C11 6.5p5, 6.3.1.1p2). */
int main(void) {
  unsigned short a = 65535, b = 65535;
  unsigned r = a * b;     /* int * int overflows: UB */
  return r & 0xff;
}
