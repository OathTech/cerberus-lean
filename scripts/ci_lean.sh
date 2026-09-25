#!/usr/bin/env bash
# CI entry for an explicitly provisioned, project-scoped environment.
# Uses the same runner as local certification; never installs shared packages.
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for tool in python3 git opam lem dune lake timeout; do
    if ! command -v "$tool" >/dev/null; then
        echo "Lean CI prerequisite missing: $tool; load the project toolchain/environment before this entry" >&2
        exit 2
    fi
done
if [[ $# -eq 0 ]]; then set -- --mode full; fi
exec python3 "$script_dir/release.py" "$@"
