int main(void) {
  int i = 1;
  i = i++ + 1;   /* UB: unsequenced */
  return i;
}
