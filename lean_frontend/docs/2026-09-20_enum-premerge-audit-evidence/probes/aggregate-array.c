enum E { A=-1,B }; struct S {char c; enum E a[2];}; int main(void){struct S x={2,{A,3}}; struct S y=x; return sizeof x+_Alignof(struct S)+y.a[0]+y.a[1];}
