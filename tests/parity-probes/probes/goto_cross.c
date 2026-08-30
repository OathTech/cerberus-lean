int main(void) {
  int i = 0, s = 0;
  goto mid;
top:
  s += 10;
mid:
  i++;
  if (i < 3) goto top;
  return s + i;  /* s=20 i=3 -> 23 */
}
