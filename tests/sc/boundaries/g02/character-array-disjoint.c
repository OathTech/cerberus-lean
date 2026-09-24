unsigned char x[2] = {0, 0};
int main(void) {
  {-{ {x[0] = 1;} ||| {x[1] = 2;} }-};
  return 0;
}
