/* Corner: UB classification for >> by an amount >= width (ISO C11 6.5.7p3). */
int main(void) {
  int one = 1; int w = 32;
  int r = one >> w;
  return r & 1;
}
