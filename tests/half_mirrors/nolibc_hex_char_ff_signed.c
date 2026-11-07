/* control: '\xff' wraps to -1 with a signed char. gcc 13 and every engine: Specified(1). Unmoved. */
int main(void) { return '\xff' == -1 ? 1 : 2; }
