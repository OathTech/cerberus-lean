/* No ordinary statement join is reached: return bypasses its marked suffix. */
static int marker;
static int leave(void) {
  return 7;
  marker = 99;
  return 9;
}
int main(void) {
  return leave();
}
