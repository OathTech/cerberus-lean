/* R6 SIZE-LADDER z1 (arc-18 breadth campaign): LONG STRAIGHT-LINE —
   20 sequential updates through the argument object (the write1
   ladder at depth 20). Purpose: measure where the substrate bends
   (rounds, mint wall-clock, equation size) — a found cliff is a
   BETTER-ABSTRACTIONS work item, never pushed through.
   chain20(5) = 5 + 210 = 215.
   Theorem shape: forall seed, outcomes(chain20(5)) =
   {Specified(215)}, no UB. */
int chain20(int x)
{
  x = x + 1;
  x = x + 2;
  x = x + 3;
  x = x + 4;
  x = x + 5;
  x = x + 6;
  x = x + 7;
  x = x + 8;
  x = x + 9;
  x = x + 10;
  x = x + 11;
  x = x + 12;
  x = x + 13;
  x = x + 14;
  x = x + 15;
  x = x + 16;
  x = x + 17;
  x = x + 18;
  x = x + 19;
  x = x + 20;
  return x;
}

int main(void) { return chain20(5); }
