/* Recursive main with loaded argc/argv parameters. Run with --args "ab cd".
 * Each call sees its own parameter values; the outer call's values remain
 * live after the recursive calls return. The host C result is 42. */
static int calls;
static char **initial_argv;

int main(int argc, char **argv)
{
    if (calls == 0) {
        if (argc != 3 || argv[argc] != 0) return 1;
        initial_argv = argv;
        calls = 1;
        int result = main(argc - 1, argv + 1);
        if (argc != 3 || argv != initial_argv || argv[argc] != 0) return 2;
        return result;
    }
    if (calls == 1) {
        if (argc != 2 || argv != initial_argv + 1) return 3;
        if (argv[0][0] != 'a' || argv[0][1] != 'b' || argv[0][2] != '\0') return 4;
        calls = 2;
        return main(argc - 1, argv + 1);
    }
    if (calls != 2 || argc != 1 || argv != initial_argv + 2) return 5;
    if (argv[0][0] != 'c' || argv[0][1] != 'd' || argv[0][2] != '\0') return 6;
    if (argv[argc] != 0) return 7;
    return 42;
}
