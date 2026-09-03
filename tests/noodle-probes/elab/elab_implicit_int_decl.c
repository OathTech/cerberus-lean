/* Corner: implicit int is NOT C11 (removed in C99): both engines should
   reject; gcc accepts as an extension with a warning. Both-reject control. */
static x = 5;
int main(void) { return x; }
