/* the midpoint below DBL_MIN is 2.22507385850720113605...e-308: ...011e-308 rounds down (largest subnormal), ...012e-308 rounds up (DBL_MIN) (expect 3) */
int main(void) { int a = 2.2250738585072011e-308 == 0x0.fffffffffffffp-1022; int b = 2.2250738585072012e-308 == 0x1p-1022; return a * 2 + b; }
