int a[(char)200 > 0 ? 2 : 1];
int b[(int)(char)-1 == 255 ? 4 : 3];
int main(void) { return (int)(sizeof a / sizeof a[0]) * 10 + (int)(sizeof b / sizeof b[0]); }
