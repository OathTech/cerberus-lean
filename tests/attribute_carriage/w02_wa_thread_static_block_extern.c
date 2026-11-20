[[cerb::with_address("0x1000")]] _Thread_local static int g; int main(void) { extern _Thread_local int g; return 0; }
