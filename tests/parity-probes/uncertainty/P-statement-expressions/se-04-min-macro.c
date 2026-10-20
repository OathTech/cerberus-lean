#define min(a,b) ({ int _a=(a), _b=(b); _a<_b?_a:_b; })
int main(void){ return min(3, 2); }
