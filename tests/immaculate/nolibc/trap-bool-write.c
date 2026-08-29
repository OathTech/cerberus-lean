/* _Bool trap representation: write byte 2 through unsigned char*, read as _Bool */
int main(void) {
  _Bool b = 0;
  unsigned char *p = (unsigned char *)&b;
  *p = 2;
  return b;
}
