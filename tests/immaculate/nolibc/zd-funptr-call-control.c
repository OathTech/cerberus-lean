/* P1-1 control: function pointers that are stored, round-tripped through
   void*, compared and called stay served and must MATCH. */
int f(void) { return 1; }
int g(void) { return 2; }
int main(void) {
  int (*t[2])(void) = {f, g};
  void *v = (void*)t[0];
  int (*back)(void) = (int(*)(void))v;
  return back() * 10 + t[1]() + (t[0] == f) * 100 + (t[1] != f) * 200;
}
