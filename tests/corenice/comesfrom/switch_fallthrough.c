int classify(int n) {
  int result = 0;
  switch (n) {
    case 0: result = 1; break;
    case 1: result = 2;
    case 2: result += 3; break;
    default: result = 7;
  }
  return result;
}
int main(void) {
  int a = classify(0);
  int b = classify(1);
  int c = classify(2);
  int d = classify(9);
  return a == 1 && b == 5 && c == 3 && d == 7 ? 0 : 1;
}
