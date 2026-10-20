struct S { char a; int b; }; int main(void){ return (int)(long)&((struct S*)0)->b; }
