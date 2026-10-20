struct I { char name[4]; int v; }; struct O { struct I i; int w; };
int main(void){ struct O o = { {"ab", 1}, 2 }; return o.i.name[0] + o.w; }
