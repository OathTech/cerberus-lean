/* The store completes at a real join; the following return evaluates UB. */
static int zero;
static int marker;
int main(void) {
  marker = 7;
  return 1 / zero;
}
