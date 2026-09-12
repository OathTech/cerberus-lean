/* twelve random 17-significant-digit decimals (seed 20260911) against their correctly rounded hex spellings, computed with Python's correctly rounded float() (expect 12) */
int main(void) {
  int r = 0;
  r += 9.5071286574294816e-6 == 0x1.3f019d02decf1p-17;
  r += 1.9887989570626296e-29 == 0x1.9360588464438p-96;
  r += 4.0839220951837288e12 == 0x1.db6e5ce627dd5p+41;
  r += 7.2159432789553758e-26 == 0x1.6550f2c2fd5bbp-84;
  r += 6.1538260597875842e15 == 0x1.5dcdf484d9d40p+52;
  r += 0.2854808375903490e17 == 0x1.95b152dde6c85p+54;
  r += 3.6891418260153514e-12 == 0x1.0399abc76e8e0p-38;
  r += 4.0281177244290514e4 == 0x1.3ab25abfc37e5p+15;
  r += 5.7155558070685801e-26 == 0x1.1b054709e441dp-84;
  r += 2.2849299501854278e23 == 0x1.83150a674cbdfp+77;
  r += 1.4991946669642686e-16 == 0x1.59b0d544de8b2p-53;
  r += 8.3537049455840172e-10 == 0x1.cb3ff1fbec6afp-31;
  return r;
}
