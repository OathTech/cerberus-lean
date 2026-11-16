/* GNU expression blocks exercise marked pure control under unsequencing. */
int main(void) {
  return ({ if (1) { ; ; } 1; }) + ({ if (0) { ; ; } 2; }) != 3;
}
