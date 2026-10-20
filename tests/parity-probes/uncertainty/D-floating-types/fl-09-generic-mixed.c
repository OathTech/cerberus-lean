int main(void){ return _Generic(1.0f + 1.0, double: 1, float: 2, default: 3); }
