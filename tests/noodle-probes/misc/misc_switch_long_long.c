/* Corner: switch on a long long controlling expression with case constants
   beyond int range (ISO C11 6.8.4.2p3-5). */
int main(void) {
  long long v = 5000000000LL;
  switch (v) { case 5000000000LL: return 1; case -5000000000LL: return 2; case 0: return 3; default: return 4; }
}
