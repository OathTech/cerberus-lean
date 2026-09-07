#!/usr/bin/env bash
# Actual native subprocess probes for gcc_run's stream separation.
# No semantic engine builds or substitutions; retain all raw captures.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
ulimit -c 0
WORK=$(mktemp -d "$TMP_DIR/gcc-capture.XXXXXXXXXX")
register_cleanup "$WORK"
python3 - "$SCRIPT_DIR/test_gcc_oracle.sh" > "$WORK/helper.sh" <<'PYCODE'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
print(s[s.index('gcc_run() {'):s.index('\nfile_num=0')])
PYCODE
source "$WORK/helper.sh"
GCC_BIN=$(command -v gcc)
GCC_COMPILE_TIMEOUT=30
GCC_RUN_TIMEOUT=5
GCC_RUN_SERIAL=0
file_num=1
gcc_run "$PROJECT_ROOT/tests/immaculate/nolibc/zd-d5-device-range-load.c" "$WORK/probe" -O0 -w
[[ "$G_STATUS" == ok && "$G_EXIT" == 139 ]] || { echo "GCC capture: stable SIGSEGV rejected: $G_STATUS/$G_EXIT" >&2; exit 1; }
[[ ! -s "$OBSERVATION_RUN_DIR/1.gcc.1.run1.program.stderr" && ! -s "$OBSERVATION_RUN_DIR/1.gcc.1.run2.program.stderr" ]]
echo 'GCC capture: stable signal with launcher diagnostics retained — PASS'
cat > "$WORK/stable.c" <<'C'
#include <stdio.h>
int main(void) { const unsigned char bytes[] = {0,128,255}; fwrite(bytes,1,3,stderr); return 3; }
C
file_num=2
gcc_run "$WORK/stable.c" "$WORK/probe" -O0 -w
[[ "$G_STATUS" == ok && "$G_EXIT" == 3 ]] || { echo "GCC capture: stable stderr rejected: $G_STATUS/$G_EXIT" >&2; exit 1; }
printf '\000\200\377' > "$WORK/expected.stderr"
cmp "$WORK/expected.stderr" "$OBSERVATION_RUN_DIR/2.gcc.2.run1.program.stderr"
cmp "$WORK/expected.stderr" "$OBSERVATION_RUN_DIR/2.gcc.2.run2.program.stderr"
echo 'GCC capture: NUL/high-byte program stderr preserved — PASS'
cat > "$WORK/varying.c" <<'C'
#include <stdio.h>
#include <unistd.h>
int main(void) { fprintf(stderr,"pid=%ld\n",(long)getpid()); return 3; }
C
file_num=3
gcc_run "$WORK/varying.c" "$WORK/probe" -O0 -w
[[ "$G_STATUS" == nondet ]] || { echo "GCC capture: varying program stderr accepted: $G_STATUS/$G_EXIT" >&2; exit 1; }
[[ "$(cat "$OBSERVATION_RUN_DIR/3.gcc.3.run1.status")" == 3 && "$(cat "$OBSERVATION_RUN_DIR/3.gcc.3.run2.status")" == 3 ]]
echo 'GCC capture: varying program stderr rejected — PASS'
cat > "$WORK/descendant.c" <<'C'
#include <stdlib.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
int main(void) {
  pid_t child = fork();
  if (child < 0) return 80;
  if (!child) {
    volatile unsigned char *p = malloc(256u * 1024u * 1024u);
    if (!p) _exit(81);
    for (size_t i = 0; i < 256u * 1024u * 1024u; i += 4096) p[i] = 1;
    _exit(82);
  }
  int status;
  if (waitpid(child, &status, 0) != child) return 83;
  return WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL ? 0 : 84;
}
C
file_num=4
saved_cap=("${CAPPED_TEST[@]}")
CAPPED_TEST=(env CERB_MEM_MAX=128M "$CAPPED_BIN")
gcc_run "$WORK/descendant.c" "$WORK/probe" -O0 -w
CAPPED_TEST=("${saved_cap[@]}")
[[ "$G_STATUS" == killed && "$(cat "$OBSERVATION_RUN_DIR/4.gcc.4.run1.status")" == 0 ]] \
    || { echo "GCC capture: successful parent hid descendant OOM: $G_STATUS/$G_EXIT" >&2; exit 1; }
is_cap_kill 0 "$OBSERVATION_RUN_DIR/4.gcc.4.run1.stderr"
echo 'GCC capture: actual descendant OOM despite parent exit zero rejected — PASS'
echo "GCC capture: 4/4 probes passed; raw evidence $OBSERVATION_RUN_DIR (kept under CERB_OBSERVATION_DIR; removed on exit 0)"
