union U { unsigned int i; unsigned char b[4]; };
int main(void) {
  union U u;
  u.i = 0x01020304u;
  /* byte order impl-defined but both engines model same platform */
  return u.b[0] + u.b[3];  /* 5 on either endianness */
}
