/* No source loop iteration completes normally; the only exit is continue. */
int main(void) {
  int i = 0;
  while (i++ < 1)
    continue;
  return 0;
}
