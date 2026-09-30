/* SC S1a rows A-C fixture (charter §3.11 plant P1's lane witness): two UNSEQUENCED calls with
   distinct side effects, so drive's saved-step picks have alternatives whose order is
   observable (exhaustive on the pre-slice oracle: 40 executions — the interleavings of the
   two calls' own steps — with `Specified(23)` and `Specified(13)` in the pick order). A step
   that commits an unchosen alternative (P1: alternative 0 runs before alternative i) changes
   the verdict sequence; the sc-step corpus is compared in rows A-C like the existing corpora
   (the oracle and `drive` are the expected answer; no baseline file: cross-engine agreement
   is required). */
static int last = 0;
static int set(int v) { last = v; return v; }
int main(void) {
  int r = set(1) + set(2);
  return last * 10 + r;
}
