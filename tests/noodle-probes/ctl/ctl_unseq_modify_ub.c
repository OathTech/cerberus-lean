/* Corner: `a[i] = i++` modifies i and reads it unsequenced (ISO C11
   6.5p2): UB035. Verdict-class agreement probe. */
int main(void) {
  int a[4] = {0}; int i = 1;
  a[i] = i++;
  return a[1] + a[2];
}
