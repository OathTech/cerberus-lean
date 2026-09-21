enum E { A, B }; int main(void) { return ({ (enum E)1 + 1; }); }
