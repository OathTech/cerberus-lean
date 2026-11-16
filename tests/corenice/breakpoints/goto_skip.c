/* Entry jumps past both ordinary joins; entering the return label is not a cut. */
static int marker;
int main(void) {
  goto done;
  marker = 99;
done:
  return marker;
}
