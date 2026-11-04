int main(void){ return _Generic(1L + 1LL, long long: 1, long: 2, default: 3); }
