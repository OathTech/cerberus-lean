/* The mode also applies to main's fixed parameters (translation.lem).
 * Run with --args "ab cd": argc, argument contents and the final null
 * pointer must survive the callee-allocated parameter temporaries. */
int main(int argc, char **argv)
{
    if (argc != 3) return 1;
    if (argv[0][0] != 'c' || argv[0][7] != '\0') return 2;
    if (argv[1][0] != 'a' || argv[1][1] != 'b' || argv[1][2] != '\0') return 3;
    if (argv[2][0] != 'c' || argv[2][1] != 'd' || argv[2][2] != '\0') return 4;
    if (argv[argc] != 0) return 5;
    return 0;
}
