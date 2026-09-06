#!/usr/bin/env python3
"""Reproduce CR-1 using production helpers and fake engine results.

Usage: python3 2026-09-05_litmus-exit-status-probe.py /path/to/concurrency
No model, baseline, or generated source is changed. Exit 1 means the
extracted harness accepted an abnormal termination; exit 0 means none
of these plants was accepted. This is not a full test of the repaired lane.
The positive control must pass; missing helper dependencies cannot count as
rejection evidence. Updated for the shared-capture protocol during execution.
"""

import pathlib
import subprocess
import sys
import tempfile


def between(source, start, end):
    return source[source.index(start):source.index(end)]


root = pathlib.Path(sys.argv[1]).resolve()
lane = (root / "scripts/test_litmus.sh").read_text()
common = (root / "scripts/common.sh").read_text()
helpers = "\n".join([
    between(lane, "tokens_of() {", "\nrun_oracle() {"),
    between(lane, "run_all() {", "\n# seq_leg:"),
    between(common, "is_cap_kill() {", "\n# kill_label"),
])

script = r'''
set -uo pipefail
LITMUS_DIR="$1"
OUTPUT_DIR="$1"
MODEL_FLAG=--concurrency=sc
ORACLE_RC="$2"
LEAN_RC="$3"
if [[ -f "$4" ]]; then source "$4"; fi
declare -A SET ERRMSG_O ERRMSG_L
DIFF_FAIL=0
'''+helpers+r'''
verdict() {
    printf '%s\n' 'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}'
}
run_oracle() {
    verdict > "$2.stdout"
    : > "$2.stderr"
    printf '%s\n' "$ORACLE_RC" > "$2.status"
    cat "$2.stdout" > "$2"
    return "$ORACLE_RC"
}
run_lean() {
    verdict > "$3.stdout"
    : > "$3.stderr"
    printf '%s\n' "$LEAN_RC" > "$3.status"
    if [[ "$LEAN_RC" == 137 ]]; then
        printf '%s\n' 'capped: OOM-KILLED (memory.events oom_kill=1)' >> "$3.stderr"
    fi
    cat "$3.stdout" "$3.stderr" > "$3"
    return "$LEAN_RC"
}
kill_label() { printf '%s\n' OOM-KILLED; }
run_all
printf 'oracle_rc=%s lean_rc=%s DIFF_FAIL=%s accepted_SET=%s\n' \
    "$ORACLE_RC" "$LEAN_RC" "$DIFF_FAIL" "${SET[probe.c]-missing}"
if [[ "$DIFF_FAIL" == 0 && "${SET[probe.c]-missing}" == '{Specified(0)}' ]]; then
    exit 42
fi
exit 0
'''

accepted = 0
with tempfile.TemporaryDirectory(prefix="litmus-status-review-") as tmp:
    (pathlib.Path(tmp) / "probe.c").write_text("int main(void) { return 0; }\n")
    for oracle_rc, lean_rc in [(0, 0), (0, 124), (0, 137), (124, 0), (137, 0)]:
        result = subprocess.run(
            ["bash", "-c", script, "_", tmp, str(oracle_rc), str(lean_rc),
             str(root / 'scripts/observations.sh')],
            text=True, capture_output=True, check=False,
        )
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        if oracle_rc == lean_rc == 0:
            if result.returncode != 42:
                raise SystemExit('positive control failed; probe cannot certify rejection')
            continue
        if result.returncode == 42:
            accepted += 1
        elif result.returncode != 0:
            raise SystemExit(f"probe execution failed: {result.returncode}")

print(f"Abnormal-exit plants accepted: {accepted}/4")
raise SystemExit(1 if accepted else 0)
