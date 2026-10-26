#!/bin/bash
# Prepare both oracle-produced libc Core inputs: Normal and inner_arg_temps.
# The text dumps omit calling_convention, extern, funinfo and header tagDefs;
# Main.loadLibc reconstructs metadata from the same twelve parse-only Cabs TUs
# and checks the dump's procedure parameters before stitching the two halves.
# These dumps have the same trust class as cabs-json and std.core: pinned
# oracle-produced inputs, not a separately implemented libc.
#
# Each content-hash pin covers the committed text AND a freshly pretty-printed
# build-tree .co. The lane-loaded install object must also byte-match that .co
# (backend/driver/main.ml:54-77, package cerberus, not cerberus-lib).
# The .co version header is informational; a clean rebuild needs no re-pin if
# the Core text is unchanged. The stock printer's float limitation remains N3
# in VALIDATION.md; no label or literal rewriting participates in preparation.
#
# Usage:
#   --check            verify BOTH pins and BOTH staged objects, then the per-proc
#                      bare-name census of both transports against the reviewed
#                      register tests/libc/bare_name_census.tsv (quotation hygiene
#                      Q4, 2026-10-26: a SPEEDBUMP on the printed spelling of the
#                      -d5 dump, not transport fidelity; scripts/libc_bare_name_census.py)
#   --selftest         --check, then three doctored registers (a row deleted, a
#                      phantom row, a changed count) must each FAIL the census
#   --record           deliberately regenerate BOTH pins and their hashes
#   --jsons <outdir>   verify BOTH pins, then print the twelve shared metadata
#                      JSON paths, one per line in libc's link order
#   --tus              print the twelve TU names in link order
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LIBC_SRC_DIR="$PROJECT_ROOT/runtime/libc"
# runtime/libc/dune:145-155: both conventions use these sources in this order.
LIBC_TUS=(ctype stdio stdlib string time utime unistd stat uio internal vfscanf signal)
LIBC_VARIANTS=(libc libc_inner_arg_temps)

die() { echo "libc_prep: ERROR: $*" >&2; exit 1; }
sha_of() { sha256sum "$1" | awk '{print $1}'; }

require_cerberus
[[ -x "$CERBERUS_BIN" ]] || die "cerberus not built: $CERBERUS_BIN"
MODE="${1:---check}"
case "$MODE" in
  --check|--selftest|--record|--jsons|--tus) ;;
  *) die "usage: libc_prep.sh --check | --selftest | --record | --jsons <outdir> | --tus" ;;
esac
CENSUS_REGISTER="$PROJECT_ROOT/tests/libc/bare_name_census.tsv"
CENSUS_PY="$PROJECT_ROOT/scripts/libc_bare_name_census.py"
if [[ "$MODE" == --tus ]]; then
    printf '%s\n' "${LIBC_TUS[@]}"
    exit 0
fi

regen_dump() { # <variant> <out> [-d5]
    local variant="$1" out="$2" switches=() debug=()
    if [[ "$variant" == libc_inner_arg_temps ]]; then
        switches=(--switches=inner_arg_temps)
    fi
    # -d5 spells every symbol name{number}; its debug chatter and printer warnings go to
    # stderr, kept in a log shown only on failure (the dump file itself is what is read)
    local errlog=/dev/stderr
    if [[ "${3:-}" == -d5 ]]; then debug=(-d5); errlog="$out.stderr"; register_cleanup "$errlog"; fi
    ( cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        "${switches[@]}" --nolibc "${debug[@]}" --pp=core --pp_core_out="$out" \
        "$PROJECT_ROOT/_build/default/runtime/libc/$variant.co" 2>> "$errlog" ) \
      || { [[ "$errlog" != /dev/stderr ]] && tail -20 "$errlog" >&2; die "$variant dump regeneration failed (cerberus rc=$?)"; }
    [[ -s "$out" ]] || die "$variant dump regeneration produced an empty file"
}

for variant in "${LIBC_VARIANTS[@]}"; do
    co="$PROJECT_ROOT/_build/default/runtime/libc/$variant.co"
    staged="$PROJECT_ROOT/_build/install/default/lib/cerberus/runtime/libc/$variant.co"
    pin="$PROJECT_ROOT/tests/libc/$variant.core"
    pin_hash="$pin.sha256"
    [[ -f "$co" ]] || die "oracle libc object missing: $co (build cerberus.install first)"
    [[ -f "$staged" ]] || die "lane-loaded staging path missing: $staged (from the repository root: opam exec --switch=. -- dune build cerberus.install)"
    cmp -s "$staged" "$co" || die "lane-loaded $variant.co does not byte-match the build-tree object; the owned build/install tree needs rebuilding before any lane can use it"

    if [[ "$MODE" == --record ]]; then
        regen_dump "$variant" "$pin"
        echo "$(sha_of "$pin")  $variant.core" > "$pin_hash"
        echo "libc_prep: PINNED $pin ($(wc -c < "$pin") bytes)"
        echo "libc_prep: content hash: $(cat "$pin_hash")"
        echo "libc_prep: $variant.co version (informational): $(head -1 "$co")"
        continue
    fi

    [[ -f "$pin" ]] || die "pin missing: $pin (review and run libc_prep.sh --record)"
    [[ -f "$pin_hash" ]] || die "content-hash pin missing: $pin_hash"
    pinned_sha="$(awk '{print $1}' "$pin_hash")"
    [[ "$pinned_sha" =~ ^[0-9a-f]{64}$ ]] || die "malformed content-hash pin: $pin_hash"
    [[ "$(sha_of "$pin")" == "$pinned_sha" ]] \
        || die "$variant.core does not match its content-hash pin; the pin pair is inconsistent"
    regen="$(mktemp "$TMP_DIR/${variant}_regen.XXXXXXXXXX.core")" || die "mktemp failed"
    register_cleanup "$regen"
    regen_dump "$variant" "$regen"
    if [[ "$(sha_of "$regen")" != "$pinned_sha" ]]; then
        echo "libc_prep: ERROR: regenerated $variant.co dump does not match its content-hash pin." >&2
        echo "  pinned sha256: $pinned_sha" >&2
        echo "  rebuilt sha256: $(sha_of "$regen")" >&2
        echo "  The oracle object or its pin moved; review before re-pinning." >&2
        exit 1
    fi
    if [[ "$MODE" == --check || "$MODE" == --selftest ]]; then
        echo "libc_prep: OK ($variant: pin + regenerated dump == $pinned_sha, $(wc -c < "$pin") bytes)"
        echo "libc_prep: OK ($variant: lane-loaded staging byte-matches build-tree object)"
        echo "libc_prep: $variant.co version (informational): $(head -1 "$co")"
        # The bare-name census speedbump (Q4): the -d5 dump of the same object, scoped to
        # the procs the pinned text transports, against the reviewed register.
        [[ -f "$CENSUS_REGISTER" ]] || die "census register missing: $CENSUS_REGISTER"
        d5="$(mktemp "$TMP_DIR/${variant}_d5.XXXXXXXXXX.core")" || die "mktemp failed"
        register_cleanup "$d5"
        regen_dump "$variant" "$d5" -d5
        python3 -I "$CENSUS_PY" "$variant" "$d5" "$pin" "$CENSUS_REGISTER" \
            || die "$variant: bare-name census differs from the reviewed register (review tests/libc/bare_name_census.tsv; a new shared bare name inside a transported proc is the shape the name join cannot distinguish)"
        if [[ "$MODE" == --selftest ]]; then
            plant_reg="$(mktemp "$TMP_DIR/census_plant.XXXXXXXXXX.tsv")" || die "mktemp failed"
            register_cleanup "$plant_reg"
            for plant in deleted phantom count; do
                case "$plant" in
                  deleted) grep -v $'^'"$variant"$'\tdecfloat\tcarry\t' "$CENSUS_REGISTER" > "$plant_reg" ;;
                  phantom) { cat "$CENSUS_REGISTER"; printf '%s\tphantom_proc\tx\t2\n' "$variant"; } > "$plant_reg" ;;
                  count)   sed $'s/^'"$variant"$'\tdecfloat\tcarry\t3$/'"$variant"$'\tdecfloat\tcarry\t2/' "$CENSUS_REGISTER" > "$plant_reg" ;;
                esac
                cmp -s "$plant_reg" "$CENSUS_REGISTER" && die "census selftest: plant '$plant' did not alter the register (the row it edits is missing)"
                if python3 -I "$CENSUS_PY" "$variant" "$d5" "$pin" "$plant_reg" > /dev/null 2>&1; then
                    die "census selftest: plant '$plant' PASSED the census ($variant) — vacuous check"
                fi
                echo "libc_prep: census selftest plant '$plant' caught ($variant)"
            done
        fi
    fi
done
if [[ "$MODE" == --check || "$MODE" == --selftest || "$MODE" == --record ]]; then exit 0; fi

# --- --jsons: generate the 12 metadata cabs-jsons ---------------------------
OUTDIR="${2:-}"
[[ -n "$OUTDIR" ]] || die "usage: libc_prep.sh --jsons <outdir>"
mkdir -p "$OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"
for tu in "${LIBC_TUS[@]}"; do
    src="$LIBC_SRC_DIR/src/$tu.c"
    [[ -f "$src" ]] || die "libc source missing: $src"
    out="$OUTDIR/libc_$tu.json"
    # Canonical export convention [USER 2026-10-19]: run from the project
    # root with a relative runtime prefix. cpp then emits portable header
    # positions; do not rewrite source or lexing positions after export.
    # The include directories are the same as runtime/libc/dune:146-153,
    # now spelled relative to the project root; elaboration happens Lean-side.
    ( cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime=_build/install/default \
        --nolibc --cabs-json -I runtime/libc/include -I runtime/libc/include/posix \
        "runtime/libc/src/$tu.c" > "$out" ) \
      || die "cabs-json failed for $tu.c"
    [[ -s "$out" ]] || die "cabs-json produced an empty file for $tu.c"
    echo "$out"
done
