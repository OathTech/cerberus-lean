/* TU 2 of the tentative-definition linking fixture (arc-5 S2): the
   normal (initialized) definition the tentative one in tu1.c must
   resolve to. */
int shared = 40;

int get_shared(void) {
    return shared;
}
