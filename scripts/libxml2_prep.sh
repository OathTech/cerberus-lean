#!/bin/bash
# libxml2_prep.sh — deterministic, no-autogen preparation of libxml2 TUs for
# Cerberus (arc-5 S3).
#
# Provenance: notes/2026-08-19_libxml2-probe.md, Part B "Preprocessing recipe
# (reusable; no autogen, no cmake, no network)". The probe established that
# Cerberus's BUILT-IN cpp (`cc -std=c11 -E -CC ... -nostdinc -undef -D__cerb__`
# + its shipped libc headers) handles libxml2 directly — no external `cc -E`
# step. The only build-system artifacts libxml2 needs are two generated
# headers, both pinned under tests/libxml2/config/ in this repo:
#
#   tests/libxml2/config/config.h            hand-written minimal config
#                                            (HAVE_DECL_* 0, HAVE_STDINT_H 1;
#                                            no threads/dlopen/destructor)
#   tests/libxml2/config/libxml/xmlversion.h generated from libxml2's
#                                            include/libxml/xmlversion.h.in by
#                                            the sed recipe below with ALL
#                                            optional modules (@WITH_*@) -> 0
#
# This script (a) fail-closed verifies the pinned xmlversion.h is exactly what
# the recipe regenerates from the source tree (so runs are reproducible and
# drift in deps/libxml2 is detected, not silently absorbed), and (b) emits the
# Cerberus invocation arguments for a TU — matching how the probe actually fed
# Cerberus (its internal cpp; -I config first so the pinned headers win):
#
#     -I <config> -I <libxml2>/include -I <libxml2> -D__inline=inline <tu>
#
# -D__inline=inline: probe defect #2 workaround (vendored timsort.h uses the
# MSVC/GNU `__inline` spelling, which the Cerberus C parser does not know;
# harmless for TUs that never include timsort.h).
#
# Usage:
#   scripts/libxml2_prep.sh --check              verify pins only
#   scripts/libxml2_prep.sh <tu>                 verify pins, then print the
#                                                cerberus args, ONE PER LINE
#                                                (consume with mapfile -t)
#   <tu> is a TU name (chvalid.c), relative path, or absolute path into the
#   libxml2 tree.
#
# Environment:
#   LIBXML2_DIR   libxml2 source tree (default: nearest deps/libxml2 walking
#                 up from the repo root). READ-ONLY — never written to.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/tests/libxml2/config"

die() { echo "libxml2_prep: ERROR: $*" >&2; exit 1; }

# --- locate the libxml2 source tree ----------------------------------------
find_libxml2() {
    if [[ -n "${LIBXML2_DIR:-}" ]]; then
        [[ -d "$LIBXML2_DIR" ]] || die "LIBXML2_DIR=$LIBXML2_DIR is not a directory"
        echo "$LIBXML2_DIR"
        return
    fi
    local d="$PROJECT_ROOT"
    while [[ "$d" != "/" ]]; do
        if [[ -d "$d/deps/libxml2" ]]; then
            echo "$d/deps/libxml2"
            return
        fi
        d="$(dirname "$d")"
    done
    die "libxml2 source not found (set LIBXML2_DIR or provide deps/libxml2 in an ancestor directory)"
}

LIBXML2="$(find_libxml2)"
[[ -f "$LIBXML2/chvalid.c" ]] || die "$LIBXML2 does not look like a libxml2 tree (no chvalid.c)"

# --- the pinned-config determinism check (always; fail-closed) --------------
[[ -f "$CONFIG_DIR/config.h" ]] || die "pinned config missing: $CONFIG_DIR/config.h"
[[ -f "$CONFIG_DIR/libxml/xmlversion.h" ]] || die "pinned config missing: $CONFIG_DIR/libxml/xmlversion.h"
XMLVERSION_IN="$LIBXML2/include/libxml/xmlversion.h.in"
[[ -f "$XMLVERSION_IN" ]] || die "missing $XMLVERSION_IN"

# The recipe (probe Part B, step 2), minimal config: every @WITH_*@ -> 0.
# @MODULE_EXTENSION@ -> .so added over the probe text: the probe's sed left it
# unsubstituted inside LIBXML_MODULE_EXTENSION (dead under WITH_MODULES=0 but
# non-deterministic-looking); pinning it keeps the header token-free.
regen_xmlversion() {
    sed -e 's/@VERSION@/2.15.0/' \
        -e 's/@LIBXML_VERSION_NUMBER@/21500/' \
        -e 's/@LIBXML_VERSION_EXTRA@//' \
        -e 's/@MODULE_EXTENSION@/.so/' \
        -e 's/@WITH_[A-Z0-9_]*@/0/g' \
        "$XMLVERSION_IN"
}

if ! regen_xmlversion | diff -q - "$CONFIG_DIR/libxml/xmlversion.h" >/dev/null; then
    {
        echo "libxml2_prep: ERROR: pinned xmlversion.h does not match the recipe output."
        echo "  Either deps/libxml2 moved or the pin is stale. Refusing to proceed."
        echo "  Recipe output vs pin:"
        regen_xmlversion | diff - "$CONFIG_DIR/libxml/xmlversion.h" | head -20
    } >&2
    exit 1
fi
if grep -q '@[A-Z0-9_]*@' "$CONFIG_DIR/libxml/xmlversion.h"; then
    die "pinned xmlversion.h contains unsubstituted @TOKENS@"
fi

if [[ "${1:-}" == "--check" ]]; then
    echo "libxml2_prep: OK (libxml2=$LIBXML2, pins verified)"
    exit 0
fi

# --- resolve the TU and emit cerberus args ----------------------------------
[[ $# -eq 1 ]] || { die "usage: libxml2_prep.sh --check | <tu.c>"; }
TU="$1"
if [[ -f "$TU" ]]; then
    TU="$(cd "$(dirname "$TU")" && pwd)/$(basename "$TU")"
elif [[ -f "$LIBXML2/$TU" ]]; then
    TU="$LIBXML2/$TU"
else
    die "TU not found: $1 (looked at ./$1 and $LIBXML2/$1)"
fi

# One argument per line, no shell quoting — consume with:  mapfile -t ARGS < <(...)
printf '%s\n' \
    "-I" "$CONFIG_DIR" \
    "-I" "$LIBXML2/include" \
    "-I" "$LIBXML2" \
    "-D__inline=inline" \
    "$TU"
