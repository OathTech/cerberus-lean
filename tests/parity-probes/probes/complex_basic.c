#include <complex.h>
int main(void) {
  double complex z = 3.0 + 4.0*I;
  double m = creal(z)*creal(z) + cimag(z)*cimag(z);
  return (int)m;  /* 25 */
}
