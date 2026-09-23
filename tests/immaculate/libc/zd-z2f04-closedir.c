/* Z2-F-04 pin, updated by the SC filesystem repair (2026-09-23).
   Native still crashes in the Core proxy: a store(signed int*) receives Specified(1).
   Lean now stops earlier, at opendir("."), with a typed missing-directory-stream
   coverage error. No fresh descriptor, success, errno or C UB is fabricated.
   Pinned ORACLE_CRASH with the full Lean error payload. This is a coverage gap,
   not completed directory support or agreement with the later native failure.
   See lean_frontend/docs/2026-09-23_sc-filesystem-baseline-review.md and the
   boundary register's SC-D07/SC-D14. The C program and source line are unchanged. */
#include <dirent.h>
int main(void) { DIR *d = opendir("."); return d ? closedir(d) + 10 : 99; }
