[[rc::args("int<i32>")]] [[rc::returns("{0} @ int<i32>")]]
int sample(int x) { [[rc::ensures("{False}")]] int y = 0; return y; }
