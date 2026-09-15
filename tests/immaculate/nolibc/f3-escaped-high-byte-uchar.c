// F3 control twin (semantics-audit repairs D2): the SAME two bytes written as \x escapes decode on both
// engines to 0xC3 = 195 as unsigned char — MATCH Specified(195); gcc exit 195.
int main(void) { return (unsigned char)"\xc3\xa9"[0]; }
