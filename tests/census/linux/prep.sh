#!/bin/bash
# prep.sh — census (P1f-2, 2026-10-04) minimal kernel configuration for
# preprocessing Linux lib/ TUs with the Cerberus oracle's own cpp. [AGENT]
# No kernel build: the Kbuild-GENERATED inputs are derived here from the
# deps/linux tree by the kernel's own recipes, or stubbed where the recipe is
# a kernel compile step; everything hand-written is in config-src/.
#
#   generated/autoconf.h        config-src/autoconf.h (hand-written, minimal)
#   generated/{asm-offsets,rq-offsets,bounds}.h
#                               config-src stubs (empty; Kbuild compiles C to
#                               make them — out of scope)
#   generated/timeconst.h       Kbuild:21  `echo $(CONFIG_HZ) | bc -q kernel/time/timeconst.bc`
#   arch-generated/asm/*.h      Kbuild generic-y / mandatory-y wrappers
#                               (`#include <asm-generic/X.h>`), arch/x86 Kbuild
#                               + include/asm-generic/Kbuild
#   arch-generated/asm/cpufeaturemasks.h
#                               arch/x86/Makefile:265 awk recipe over a
#                               .config derived from autoconf.h
#   uapi-generated/asm/*.h      include/uapi/asm-generic/Kbuild mandatory-y wrappers
#
# Usage: prep.sh <outdir>   — writes the derived tree, then prints the cerberus
#                             arguments ONE PER LINE (consume with mapfile -t).
# Fail-closed: any missing input or failed recipe exits non-zero.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:?usage: prep.sh <outdir>}"
find_linux() {  # LINUX_DIR, else the nearest deps/linux walking up (libxml2_prep.sh pattern)
    if [[ -n "${LINUX_DIR:-}" ]]; then echo "$LINUX_DIR"; return; fi
    local d="$HERE"
    while [[ "$d" != "/" ]]; do
        [[ -d "$d/deps/linux" ]] && { echo "$d/deps/linux"; return; }
        d="$(dirname "$d")"
    done
}
L="$(find_linux)"
die() { echo "linux prep: ERROR: $*" >&2; exit 1; }
[[ -n "$L" && -f "$L/lib/sort.c" && -f "$L/kernel/time/timeconst.bc" ]] || die "deps/linux not found (set LINUX_DIR)"
command -v bc >/dev/null || die "bc not found (timeconst.h recipe)"
rm -rf "$OUT"; mkdir -p "$OUT/generated" "$OUT/arch-generated/asm" "$OUT/uapi-generated/asm"
for f in autoconf.h asm-offsets.h rq-offsets.h bounds.h; do
    cp "$HERE/config-src/$f" "$OUT/generated/$f"
done
hz=$(sed -n 's/^#define CONFIG_HZ \([0-9]*\).*/\1/p' "$HERE/config-src/autoconf.h")
[[ -n "$hz" ]] || die "CONFIG_HZ missing from autoconf.h"
(cd "$L" && echo "$hz" | bc -q kernel/time/timeconst.bc) > "$OUT/generated/timeconst.h"
grep -q KERNEL_TIMECONST_H "$OUT/generated/timeconst.h" || die "timeconst recipe produced no header"
wrap() { echo "#include <asm-generic/$2>" > "$1/$2"; }
n=0
for h in $(awk '/^[[:space:]]*mandatory-y/{print $3}' "$L/include/asm-generic/Kbuild"); do
    [[ -f "$L/arch/x86/include/asm/$h" ]] || { wrap "$OUT/arch-generated/asm" "$h"; n=$((n+1)); }
done
for h in $(awk '/^[[:space:]]*generic-y/{print $3}' "$L/arch/x86/include/asm/Kbuild"); do
    wrap "$OUT/arch-generated/asm" "$h"; n=$((n+1))
done
for h in $(awk '/^[[:space:]]*mandatory-y/{print $3}' "$L/include/uapi/asm-generic/Kbuild"); do
    [[ -f "$L/arch/x86/include/uapi/asm/$h" ]] || { wrap "$OUT/uapi-generated/asm" "$h"; n=$((n+1)); }
done
[[ $n -gt 0 ]] || die "no asm-generic wrappers generated (Kbuild layout changed?)"
grep '^#define CONFIG_' "$HERE/config-src/autoconf.h" \
    | awk '{v=$3; if (v=="1") v="y"; print $2"="v}' > "$OUT/dot-config"
(cd "$L" && awk -f arch/x86/tools/cpufeaturemasks.awk arch/x86/include/asm/cpufeatures.h "$OUT/dot-config") \
    > "$OUT/arch-generated/asm/cpufeaturemasks.h"
grep -q _ASM_X86_CPUFEATUREMASKS_H "$OUT/arch-generated/asm/cpufeaturemasks.h" || die "cpufeaturemasks recipe failed"
grep -v '^[[:space:]]*\(#.*\)\?$' "$HERE/flags.txt" | sed "s|@L@|$L|g; s|@C@|$OUT|g"
