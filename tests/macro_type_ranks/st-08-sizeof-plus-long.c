int main(void){ return _Generic(sizeof(int) + 1L, unsigned long: 1, default: 2); }
