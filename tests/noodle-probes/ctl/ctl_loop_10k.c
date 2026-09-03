/* Corner: a 10,000-iteration loop with accumulation (under the documented
   lemDefaultFuel onset of ~1.7e4 iterations). */
int main(void) {
  long s = 0;
  for (int i = 0; i < 10000; i++) s += i;
  return (int)(s % 251);       /* 49995000 % 251 = 49995000 - 251*199183 = 67 */
}
