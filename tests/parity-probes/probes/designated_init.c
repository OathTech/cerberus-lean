struct Inner { int a, b; };
struct Outer { struct Inner in; int arr[4]; int z; };
int main(void) {
  struct Outer o = { .arr = {[2] = 7, [0] = 1}, .in.b = 3, .z = 9 };
  int a[6] = {[4] = 5, [1] = 2};
  return o.in.a + o.in.b + o.arr[0] + o.arr[2] + o.z + a[1] + a[4];  /* 0+3+1+7+9+2+5=27 */
}
