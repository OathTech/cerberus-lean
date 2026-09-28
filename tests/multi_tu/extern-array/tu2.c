/* extern-array, TU 2: incomplete-type extern declarations (int arr[],
   char msg[]) used for indexing and writing; the writes are visible to TU 1. */
extern int arr[];
extern char msg[];
int sum_arr(void);
int main(void) {
  arr[4] = 50;
  msg[0] = 'J';
  int len = 0;
  while (msg[len]) len++;
  return sum_arr() + len * 100 + (msg[0] == 'J');   /* 60 + 500 + 1 */
}
