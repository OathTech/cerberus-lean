/* R6 SIZE-LADDER z2 (arc-18 breadth campaign): WIDE CONTEXT — eight
   locals all live to the end (8 scratch objects). Purpose: measure
   the driver-atom vocabulary's width limit (registered variants
   cover 1-2 scratches; 8 is the expected cliff — recorded, never
   pushed through). wide8(1) = 8*1 + 36 = 44. */
int wide8(int x)
{
  int va = x + 1;
  int vb = x + 2;
  int vc = x + 3;
  int vd = x + 4;
  int ve = x + 5;
  int vf = x + 6;
  int vg = x + 7;
  int vh = x + 8;
  return va + vb + vc + vd + ve + vf + vg + vh;
}

int main(void) { return wide8(1); }
