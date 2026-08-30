int main(void) {
  double z = 0.0;
  double n = z / z;           /* NaN */
  double inf = 1.0 / z;       /* +inf */
  return (n != n) + (inf > 1e308) + (-inf < -1e308);  /* 3 */
}
