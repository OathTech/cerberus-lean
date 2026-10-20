int main(void){ int *arr[1]; { int x = 5; arr[0] = &x; } return arr[0] == 0; }
