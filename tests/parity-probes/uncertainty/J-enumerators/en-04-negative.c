enum E { N = -1 }; int main(void){ return (N < 0) + 2*(sizeof(enum E)==4); }
