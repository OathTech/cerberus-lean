/* argv handling: count + first-char sum; run with --args "ab cd" */
int main(int argc, char **argv) {
  int s = argc * 10;
  for (int i = 1; i < argc; i++) s += argv[i][0];
  return s;  /* argc=3: 30 + 'a' + 'c' = 30+97+99 = 226 -> exit truncates? Specified(226) in batch */
}
