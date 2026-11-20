int f(int x) [[unsequenced]] { return x; } int main(void) { return f(0); }
