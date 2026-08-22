// G4 control: __builtin_ctz on a normal value should MATCH both sides
// (ctz(8) = 3). Present so the lane proves the builtins path is live.
int main(void) { return __builtin_ctz(8); }
