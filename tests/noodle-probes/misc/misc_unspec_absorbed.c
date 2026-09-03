/* Corner: arithmetic that would mathematically absorb an unspecified
   operand (`(x & 0) + 3`): does the model return 3 or Unspecified?
   Verdict-class agreement probe. */
int main(void) { int x; return (x & 0) + 3; }
