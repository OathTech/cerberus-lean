int main(int argc, char* argv[]) {
  int n = 0;
  for (int i = 0; i < argc; i++)
    for (int j = 0; argv[i][j]; j++) n++;
  return n;
}
