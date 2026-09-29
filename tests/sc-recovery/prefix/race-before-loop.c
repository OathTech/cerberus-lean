/* A bounded selected execution is incomplete. The provider state must retain
   the race; exhaustion is neither successful completion nor a safety verdict. */
int main(void) {
  int x = 0;
  {-{ { x = 1; } ||| { x = 2; } }-};
  while (1) {}
  return x;
}
