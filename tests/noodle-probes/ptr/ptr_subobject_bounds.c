/* Corner: indexing past the end of an INNER array of a 2-D array but
   within the outer object (a[0][4] aliases a[1][0]). ISO C11 6.5.6p8 makes
   this UB (pointer arithmetic is per-array-object); Cerberus's PVI bounds
   are per-allocation so both engines are expected to return the value.
   Verdict-class agreement probe (documents the model's stance). */
int main(void) {
  int a[2][4] = {{1,2,3,4},{5,6,7,8}};
  int *p = &a[0][0];
  return a[0][4] + p[7];   /* 5 + 8 = 13 */
}
