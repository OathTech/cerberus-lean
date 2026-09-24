struct pair { unsigned char a; unsigned char b; } x = {0, 0};
int main(void) {
  {-{ {x.a = 1;} ||| {x.b = 2;} }-};
  return 0;
}
