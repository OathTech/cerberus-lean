/* extern-array, TU 1: array and string definitions with sizes known only
   here; a function that reads them after the other TU wrote to them. */
int arr[5] = { 1, 2, 3, 4, 5 };
char msg[] = "hello";
int sum_arr(void) { int s = 0; for (int i = 0; i < 5; i++) s += arr[i]; return s; }
