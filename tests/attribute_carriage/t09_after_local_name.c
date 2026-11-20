[[rc::args("int<i32>")]] [[rc::returns("{0} @ int<i32>")]]
int sample(int x) { int y [[rc::ensures("{False}")]] = 0; return y; }
