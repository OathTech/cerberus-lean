struct S { int v[4]; }; int main(void){ int arr[8] = {1,2,3,4,5,6,7,8}; struct S *p = (struct S*)arr; struct S *q = (struct S*)(arr+2); *p = *q; return arr[0] + arr[1]*10; }
