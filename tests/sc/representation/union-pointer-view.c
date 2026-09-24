int main(void){int x;union{int *p;void *v;}u;u.p=&x;return u.v==(void*)&x;}
