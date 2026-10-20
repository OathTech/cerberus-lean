int main(void){ int x = 2, r = 0; switch (x) { case 1: r += 1; if (x) { lab: r += 10; break; } case 2: r += 100; goto lab; } return r; }
