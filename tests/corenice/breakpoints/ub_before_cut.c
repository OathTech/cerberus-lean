/* The first marked statement does not complete, so its join must not fire. */
static int zero;
int main(void) {
  int value = 1 / zero;
  return value;
}
