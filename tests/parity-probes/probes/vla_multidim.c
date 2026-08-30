int main(void) {
  int r = 3, c = 4;
  int m[r][c];
  for (int i = 0; i < r; i++) for (int j = 0; j < c; j++) m[i][j] = i*c + j;
  return m[2][3] + (int)(sizeof(m)/sizeof(m[0][0]));  /* 11 + 12 = 23 */
}
