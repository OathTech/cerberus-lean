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
echo "GCC capture: 3/3 probes passed; raw evidence $OBSERVATION_RUN_DIR"
