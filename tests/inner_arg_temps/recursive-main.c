/* Counterexample to the charter's recursive-main refusal premise:
 * both engines return 7 in Normal and inner_arg_temps modes.
 * See lean_frontend/docs/2026-10-21_inner-arg-temps-park.md. */
static int depth;
int main(void)
{
    if (depth == 0) {
        depth = 1;
        return main();
    }
    return 7;
}
