/* Corner: K&R (identifier-list) function definition — obsolescent but legal
   C11 (6.9.1p6, 6.11.7). Parameters get default promotions. */
int add(a, b) int a; int b; { return a + b; }
int main(void) { return add(2, 3); }
