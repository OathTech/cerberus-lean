[[rc::args("int<i32>")]] [[rc::returns("{0} @ int<i32>")]]
int sample(int x) { [[rc::ensures("{False}")]] return 0; }
