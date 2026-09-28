#!/usr/bin/env bash
# Record observations for the four cases in this report using an existing build.
set -euo pipefail

repro_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${1:-$repro_dir/../../..}" && pwd)
cd "$repo_root"
export NO_COLOR=1 TERM=dumb LEAN_ABORT_ON_PANIC=1 SKIP_BUILD=1
export CERB_MEM_MAX="${CERB_MEM_MAX:-8G}"
ulimit -c 0

./tools/check_driver_fresh.sh --check-oracle
./tools/check_driver_fresh.sh --check-lean
mkdir -p .tmp
out=$(mktemp -d "$repo_root/.tmp/ub-detection.XXXXXXXX")
./scripts/libc_prep.sh --jsons "$out/libc-json" > "$out/libc-json-paths.txt"
mapfile -t libc_jsons < "$out/libc-json-paths.txt"
[[ ${#libc_jsons[@]} -eq 12 ]]
libc_args=(--libc "$repo_root/tests/libc/libc.core")
for json in "${libc_jsons[@]}"; do
    libc_args+=(--libc-tu "$json")
done

oracle="$repo_root/_build/default/backend/driver/main.exe"
lean="$repo_root/lean_frontend/.lake/build/bin/cerberus-lean"
runtime="$repo_root/_build/install/default"
git rev-parse HEAD > "$out/build-checkout.txt"
sha256sum "$oracle" "$lean" > "$out/binaries.sha256"
sha256sum "$repro_dir"/*.c > "$out/sources.sha256"
date -u +%FT%TZ > "$out/run-date.txt"

capture() {
    local prefix=$1
    shift
    local status=0
    printf '%q ' "$@" > "$prefix.command"
    printf '\n' >> "$prefix.command"
    ./scripts/capped timeout --kill-after=5s 60s "$@" \
        > "$prefix.stdout" 2> "$prefix.stderr" || status=$?
    printf '%s\n' "$status" > "$prefix.status"
}

for source in "$repro_dir"/*.c; do
    name=$(basename "$source" .c)
    capture "$out/$name.compile" "$oracle" --runtime="$runtime" --cabs-json "$source"
    [[ $(cat "$out/$name.compile.status") == 0 ]]
    capture "$out/$name.ocaml" "$oracle" --runtime="$runtime" \
        --exec --batch --mode=random "$source"
    capture "$out/$name.lean" "$lean" --batch --first \
        "${libc_args[@]}" "$out/$name.compile.stdout"
    for engine in ocaml lean; do
        python3 scripts/observations.py inspect --capture "$out/$name.$engine" \
            > "$out/$name.$engine.observation.json"
        printf '%s %s (exit %s):\n' "$name" "$engine" "$(cat "$out/$name.$engine.status")"
        cat "$out/$name.$engine.stdout"
    done
    python3 scripts/observations.py compare --capture "$out/$name.ocaml" \
        --other "$out/$name.lean"
done
printf 'Raw captures, commands and identities: %s\n' "$out"
