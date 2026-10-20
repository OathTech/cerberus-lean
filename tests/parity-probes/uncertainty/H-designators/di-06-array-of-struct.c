struct P { int x, y; };
int main(void){ struct P ps[3] = {[1].y = 4, [2] = {5, 6}}; return ps[1].y + ps[2].x*10 + ps[2].y*20 + ps[0].x + ps[1].x; }
