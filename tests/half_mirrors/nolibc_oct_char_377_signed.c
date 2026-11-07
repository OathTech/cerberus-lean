/* control: '\377' wraps to -1 with a signed char (decode.ml wrapI). gcc 13 and every engine: Specified(1). Unmoved. */
int main(void) { return '\377' == -1 ? 1 : 2; }
