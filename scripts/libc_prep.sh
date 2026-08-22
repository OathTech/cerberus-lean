#!/bin/bash
# libc_prep.sh — deterministic preparation of the C-libc artifacts for the
# Lean pipeline's --libc mode (arc-6 S1).
#
# Two artifacts, one trust story (charter S5 / decision D5: the dump is
# ORACLE-PRODUCED INPUT, same trust class as cabs-json and std.core —
# pinned + drift-checked like the libxml2 config, libxml2_prep.sh pattern):
#
# 1. tests/libc/libc.core — the PINNED unlinked libc Core text dump.
#    Produced by the stock invocation verified in the S0 survey
#    (docs/2026-08-19_arc6-s0-survey.md §a.1; no OCaml patching):
#
#        cerberus --nolibc --pp=core --pp_core_out=<out> \
#            _build/default/runtime/libc/libc.co
#
#    read_core_object with is_lib=false pretty-prints the marshalled
#    core_dump (backend/common/pipeline.ml:648-672; print_core at :668-670).
#    libc.co itself is built by runtime/libc/dune:132-141 (cerberus --nolibc
#    -I include -I include/posix --sequentialise --rewrite over the 12 libc
#    TUs), so the pinned text is the oracle's sequentialised+rewritten libc.
#    This script FAILS (fail-closed, both directions) if the regenerated
#    dump differs from the pin: either _build/libc.co moved (oracle drift)
#    or the pin is stale. Pin identity (arc-13 audit fix, B-F5): a
#    CONTENT-HASH pin — tests/libc/libc.core.sha256 holds the sha256 of
#    the dump text; the check verifies the committed pin AND the freshly
#    regenerated dump against it. This is rebuild-independent: a clean
#    rebuild that re-derives the same dump text passes with no re-pin.
#    (The old version-string pin, tests/libc/libc.co.version, recorded a
#    git-describe line that went '-dirty'/stale on every rebuild and is
#    DELETED; the libc.co header line is now logged informationally only.)
#
#    KNOWN LIMITATION of the text form (S0 survey §a.1 + S1 finding): the
#    stock pp omits the extern map, funinfo, main, AND all tagDefs whose
#    definition site is in an #include'd header (pp_cond,
#    ocaml_frontend/pprinters/pp_core.ml:745-746: show_include=false drops
#    non-main-file decls — only `struct fl` survives). Those are
#    reconstructed Lean-side from artifact 2.
#
# 2. The 12 libc METADATA TUs: cabs-json of the same 12 sources libc.co is
#    built from, in the same order and with the same include flags as
#    runtime/libc/dune:132-141 (minus --sequentialise --rewrite, which are
#    Core-to-Core BODY passes applied after elaboration; extern/funinfo/
#    tagDefs are produced by elaboration itself — translation.lem:4505-4540 —
#    so the metadata is pass-invariant). The Lean pipeline frontends these
#    through its own desugar/typecheck/translate and keeps ONLY the
#    metadata; bodies come from the pinned dump. The jsons are regenerated
#    on demand (oracle-produced, derived from in-repo pinned sources; not
#    committed).
#
# Usage:
#   scripts/libc_prep.sh --check              verify the pin (drift check)
#   scripts/libc_prep.sh --record             (re)pin tests/libc/libc.core
#   scripts/libc_prep.sh --jsons <outdir>     verify pin, then generate the
#                                             12 metadata cabs-jsons into
#                                             <outdir> and print their paths
#                                             in link order, ONE PER LINE
#   scripts/libc_prep.sh --tus                print the 12 TU names in the
#                                             dune link order, one per line
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LIBC_CO="$PROJECT_ROOT/_build/default/runtime/libc/libc.co"
LIBC_SRC_DIR="$PROJECT_ROOT/runtime/libc"
PIN="$PROJECT_ROOT/tests/libc/libc.core"
PIN_HASH="$PROJECT_ROOT/tests/libc/libc.core.sha256"

# The 12 TUs in the exact order of the oracle's libc link
# (runtime/libc/dune:132-141; order matters: main.ml:150-156 folds the
# frontend over the file list and Core_linking.link folds link_aux in
# list order, so extern/funinfo merge order mirrors the oracle's).
LIBC_TUS=(ctype stdio stdlib string time utime unistd stat uio internal vfscanf signal)

die() { echo "libc_prep: ERROR: $*" >&2; exit 1; }

require_cerberus
[[ -x "$CERBERUS_BIN" ]] || die "cerberus not built: $CERBERUS_BIN"
[[ -f "$LIBC_CO" ]] || die "oracle libc object missing: $LIBC_CO (dune build it first)"

regen_dump() { # <out>
    local out="$1"
    ( cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --pp=core --pp_core_out="$out" "$LIBC_CO" ) \
      || die "dump regeneration failed (cerberus rc=$?)"
    [[ -s "$out" ]] || die "dump regeneration produced an empty file"
}

co_version() { head -1 "$LIBC_CO"; }
sha_of() { sha256sum "$1" | awk '{print $1}'; }

MODE="${1:---check}"
case "$MODE" in
  --record)
    mkdir -p "$(dirname "$PIN")"
    regen_dump "$PIN"
    echo "$(sha_of "$PIN")  libc.core" > "$PIN_HASH"
    echo "libc_prep: PINNED $PIN ($(wc -c < "$PIN") bytes)"
    echo "libc_prep: content hash: $(cat "$PIN_HASH")"
    echo "libc_prep: libc.co version (informational): $(co_version)"
    exit 0
    ;;
  --check|--jsons|--tus) ;;
  *) die "usage: libc_prep.sh --check | --record | --jsons <outdir> | --tus" ;;
esac

if [[ "$MODE" == "--tus" ]]; then
    printf '%s\n' "${LIBC_TUS[@]}"
    exit 0
fi

# --- the pin drift check (always, fail-closed; content-hash pin, B-F5) ------
[[ -f "$PIN" ]] || die "pin missing: $PIN (run libc_prep.sh --record)"
[[ -f "$PIN_HASH" ]] || die "content-hash pin missing: $PIN_HASH (run libc_prep.sh --record)"
PINNED_SHA="$(awk '{print $1}' "$PIN_HASH")"
[[ "$PINNED_SHA" =~ ^[0-9a-f]{64}$ ]] || die "malformed content-hash pin: $PIN_HASH"
if [[ "$(sha_of "$PIN")" != "$PINNED_SHA" ]]; then
    die "pinned libc.core does not match its content-hash pin ($PIN_HASH) — the pin pair is inconsistent; re-review and re-pin deliberately (--record)"
fi
REGEN="$(mktemp "$TMP_DIR/libc_regen.XXXXXXXXXX.core")" || die "mktemp failed"
register_cleanup "$REGEN"
regen_dump "$REGEN"
if [[ "$(sha_of "$REGEN")" != "$PINNED_SHA" ]]; then
    {
        echo "libc_prep: ERROR: regenerated libc.co dump does not match the content-hash pin."
        echo "  pinned  sha256: $PINNED_SHA"
        echo "  rebuilt sha256: $(sha_of "$REGEN")"
        echo "  Either the oracle's libc.co moved or the pin is stale. Refusing to proceed."
        echo "  First differences vs the pinned text:"
        diff "$PIN" "$REGEN" | head -10
    } >&2
    exit 1
fi

# --- the lane-loaded staging check (2026-08-22 hotfix, fail-closed) ---------
# Trust-gap closure (docs/2026-08-22_libc-co-divergence-diagnosis.md §6.2):
# the checks above verify the BUILD-TREE .co ($LIBC_CO), but libc-mode
# oracle runs load a DIFFERENT path — the `cerberus` package's install
# staging (backend/driver/main.ml:55-77 via Cerb_runtime.in_runtime
# ~pkg:"cerberus" with --runtime=_build/install/default →
# util/cerb_runtime.ml:41-48). Nothing else asserted that path exists or
# agrees with the verified artifact; a post-`dune clean` recipe that
# stages only cerberus-lib leaves it missing and every libc-mode oracle
# run dies at startup (Failure("file libc.co not found"), exit 125).
# Assert existence AND byte-identity so --check certifies the artifact
# the lanes actually load, not a sibling path.
STAGED_CO="$PROJECT_ROOT/_build/install/default/lib/cerberus/runtime/libc/libc.co"
if [[ ! -e "$STAGED_CO" ]]; then
    {
        echo "libc_prep: ERROR: lane-loaded staging path missing: $STAGED_CO"
        echo "  The libc-mode oracle loads libc.co from the cerberus package's"
        echo "  install staging, which is NOT created by the cerberus-lib-only"
        echo "  build recipe. Refusing to proceed."
        echo "  Remediation: (cd $PROJECT_ROOT && opam exec --switch=. -- dune build cerberus.install)"
        echo "  (If the path is still missing afterwards, _build was manually"
        echo "  altered — dune trusts its incremental db over the filesystem and"
        echo "  will not re-stage; run dune clean and rebuild per the documented"
        echo "  recipe, lean_frontend/CLAUDE.md Build.)"
    } >&2
    exit 1
fi
if ! cmp -s "$STAGED_CO" "$LIBC_CO"; then
    {
        echo "libc_prep: ERROR: lane-loaded staging libc.co does not byte-match the verified build-tree libc.co."
        echo "  staged (lane-loaded): $STAGED_CO ($(sha_of "$STAGED_CO"))"
        echo "  build tree (verified): $LIBC_CO ($(sha_of "$LIBC_CO"))"
        echo "  The lanes would load an artifact other than the one this check"
        echo "  verified. Refusing to proceed."
        echo "  A mismatch here means _build/install was manually altered (dune"
        echo "  stages this entry as a symlink into _build/default, which cannot"
        echo "  go stale) — and dune trusts its incremental db over the"
        echo "  filesystem, so 'dune build cerberus.install' will NOT repair it."
        echo "  Remediation: (cd $PROJECT_ROOT && opam exec --switch=. -- dune clean)"
        echo "  then rebuild per the documented recipe (lean_frontend/CLAUDE.md"
        echo "  Build), which ends with: dune build cerberus.install"
    } >&2
    exit 1
fi

if [[ "$MODE" == "--check" ]]; then
    echo "libc_prep: OK (content hash verified: pin + regenerated dump == $PINNED_SHA, $(wc -c < "$PIN") bytes)"
    echo "libc_prep: OK (lane-loaded staging verified: $STAGED_CO byte-matches build-tree libc.co)"
    echo "libc_prep: libc.co version (informational): $(co_version)"
    exit 0
fi

# --- --jsons: generate the 12 metadata cabs-jsons ---------------------------
OUTDIR="${2:-}"
[[ -n "$OUTDIR" ]] || die "usage: libc_prep.sh --jsons <outdir>"
mkdir -p "$OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"
for tu in "${LIBC_TUS[@]}"; do
    src="$LIBC_SRC_DIR/src/$tu.c"
    [[ -f "$src" ]] || die "libc source missing: $src"
    out="$OUTDIR/libc_$tu.json"
    # Same cpp surface as the oracle's libc build (runtime/libc/dune:132-141):
    # --nolibc -I include -I include/posix; --cabs-json replaces the Core
    # passes (elaboration happens Lean-side).
    ( cd "$LIBC_SRC_DIR" && opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --cabs-json -I include -I include/posix "src/$tu.c" > "$out" ) \
      || die "cabs-json failed for $tu.c"
    [[ -s "$out" ]] || die "cabs-json produced an empty file for $tu.c"
    echo "$out"
done
