enum E { A = 1 }; int main(void){ return (int)(sizeof(enum E) + 10*sizeof(A)); }
