int main(void) {
  _Bool b1 = 0.5;   /* true */
  _Bool b2 = 256;   /* true (not truncation to 0) */
  _Bool b3 = 0;
  return b1 + b2 + b3 + 40;  /* 42 */
}
