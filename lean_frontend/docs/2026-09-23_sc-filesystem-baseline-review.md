# Filesystem boundary: one-row instrument update

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


[AGENT, 2026-09-23] The checked filesystem interface changes exactly the
`zd-z2f04-closedir` observation in the immaculate corpus. This record justifies
the explicit instrument update; it does not certify directory support.

The first frozen full run, `fs-integration-full-20260923`, completed all 39
lanes: 37 passed, B5 and B9 failed. Source was unchanged and the runner found
no artifact issues. B5 rejected the stale row; B9 correctly rejected its
positive control, crash-model and ambient-term plants on the same row. The
other 90 of 93 observation plants passed. Earlier progress messages mistakenly
counted completed lanes as passed lanes; that claim was corrected before any
archive, baseline adoption or commit.

The unchanged C program is:

```c
#include <dirent.h>
int main(void) { DIR *d = opendir("."); return d ? closedir(d) + 10 : 99; }
```

Previously the pin was `MATCH | L=CRASH`. The fork-native process still exits
125 with the recorded `can_advance: Step_error2` internal error: a
`store(signed int*)` receives `Specified(1)`. Lean now exits 1 with a complete
`Error` observation identifying the missing `opendir '.'` implementation and
empty diagnostic stderr. The new pin is `ORACLE_CRASH | L=ERR:…` with the
entire error payload, not a substring or weaker comparison.

These failures occur at different boundaries. The native proxy reaches the
known Z2-F-04 failure (SC-D14). Lean stops earlier at its unported directory
stream transition (SC-D07). `runtime/libc/include/posix/dirent.h:10` defines
`DIR` as `int`; `runtime/libcore/std.core:531–540` obtains a numeric directory
descriptor and calls `create_and_store` with `signed int`. This inspection
does not establish the cause of the later pointer-type mismatch or repair it.
The checked port neither reproduces the old invented descriptor nor claims a
successful filesystem result. Neither outcome establishes ISO C UB.

The available SibylFS directory semantics remain a port obligation. Removal
requires implementing directory streams, positions and operation/error
selection, then re-running this actual C path. The native proxy failure must
be reviewed separately against the pinned Core/frontend semantics before any
replacement result is introduced. Fixing one boundary does not discharge the
other. The customer repository remains untouched.

The baseline is re-recorded through the existing instrument and compared by
test identifier against the saved prior file: no missing/new identifiers and
exactly this one changed row are admissible. The fixture's explanatory comment
is updated; its C tokens and line numbers stay unchanged. Header commentary
now distinguishes a pinned error from a returned value. The comparator itself
is unchanged. Raw failed-run captures, re-record output and the exact row delta
are retained with the filesystem evidence. The baseline/header/fixture update
is recorded in a separate instrument commit. The combined working tree passes
all 39 full validation lanes and the 864-case three-engine report; the split
intermediate commits are not claimed to have been independently validated.
