/* 2^-1075 is exactly half a subnormal quantum: tie to even = 0; 0.75 quanta rounds up; 1.5 quanta ties to the even 2 quanta (expect 7) */
int main(void) { int a = 0x1p-1075 == 0.0; int b = 0x1.8p-1075 == 0x1p-1074; int c = 0x1.8p-1074 == 0x1p-1073; return a * 4 + b * 2 + c; }
