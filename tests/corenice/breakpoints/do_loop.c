/* Repeated body-to-condition joins in the do-loop lowering. */
static void add(int *value) { *value = *value + 2; }
int main(void) {
  int value = 0;
  do {
    add(&value);
  } while (value < 8);
  return value == 8 ? 0 : 1;
}
