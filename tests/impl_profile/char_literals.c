int main(void) {
  int r = 0;
  if ('\377' == 255) r += 1;
  if ('\377' == -1) r += 2;
  if ('\xff' == '\377') r += 4;
  if ('\200' == 128) r += 8;
  if ('\x80' < 0) r += 16;
  if ('\177' == 127) r += 32;
  if (sizeof('\377') == sizeof(int)) r += 64;
  return r;
}
