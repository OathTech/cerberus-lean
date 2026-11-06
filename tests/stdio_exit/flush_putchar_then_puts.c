/* tray 24 reproducer 3 (the "unlocalised" loss): putchar then puts. gcc: "\nxy\n". */
#include <stdio.h>
int main(void) { putchar(10); puts("xy"); return 0; }
