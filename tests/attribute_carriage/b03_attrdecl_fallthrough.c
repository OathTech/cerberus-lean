int main(void) { int x = 0; switch (x) { case 0: x = 1; [[fallthrough]]; case 1: x = 2; } return x - 2; }
