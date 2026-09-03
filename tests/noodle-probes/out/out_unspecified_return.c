/* Corner: main returns an indeterminate value: the model's verdict is
   Unspecified('signed int') (a value class, not UB). */
int main(void) { int x; return x; }
