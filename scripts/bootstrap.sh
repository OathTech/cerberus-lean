#!/usr/bin/env bash
# bootstrap.sh — provision a checkout for building and for the test ladder.
#
# Every step is the documented recipe (lean_frontend/README.md, VALIDATION.md "Provisioning the
# fork-drift oracle", scripts/external_pins.txt) run in order with its exit status checked: a
# failing step stops the script and names the command. Nothing is installed outside this
# directory; no global opam switch, git configuration or shell profile is touched.
#
#   scripts/bootstrap.sh switch     local opam switch ./_opam, the fork's Lem at the pinned
#                                   revision, the OCaml dependencies            [network]
#   scripts/bootstrap.sh sources    the `upstream` git ref; the external corpora and upstream Lem
#                                   cloned into deps/ at their pinned commits   [network]
#   scripts/bootstrap.sh build      generated trees, both engines, speclab (LemLib is fetched by
#                                   Lake on the first build)                    [network once]
#   scripts/bootstrap.sh oracles    the pristine upstream generated tree (fork-drift gate) and
#                                   the independent upstream oracle (rows B10, B12)
#   scripts/bootstrap.sh all        switch, sources, build, oracles, then scripts/preflight.sh
#   scripts/bootstrap.sh worktree NAME [BASE] [--no-build]
#                                   a new branch NAME (from BASE, default HEAD) in worktrees/NAME,
#                                   sharing this checkout's switch and LemLib source, then built
#                                   there from scratch with its own oracles
#
# Steps marked [network] fail inside a sandbox without network access: run those where the
# network is available. Every step is safe to repeat; a step whose result is already present
# and verified is skipped. Heavy builds go through scripts/capped (CERB_MEM_MAX, default here
# 32G). Check the result with scripts/preflight.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
export CERB_MEM_MAX="${CERB_MEM_MAX:-32G}"
OCAML_COMPILER=ocaml-base-compiler.5.4.0
LEM_URL=https://github.com/OathTech/lem-lean.git
UPSTREAM_URL=https://github.com/rems-project/cerberus.git
LEM_UPSTREAM_URL=https://github.com/rems-project/lem.git

say()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die()  { printf '\nbootstrap: FAILED — %s\n' "$*" >&2; exit 1; }
run()  { printf '    $ %s\n' "$*"; "$@" || die "exit $? from: $*"; }
in_switch() { run opam exec --switch="$ROOT" -- "$@"; }
lem_pin() { sed -n 's/^lem-pin=//p' scripts/fork_drift_manifest.txt | head -1; }
merge_base() { sed -n 's/^merge-base=//p' scripts/fork_drift_manifest.txt | head -1; }
usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"; }

do_switch() {
    say "OCaml switch"
    command -v opam > /dev/null || die "opam is not installed"
    [[ -d "${OPAMROOT:-$HOME/.opam}" ]] || die "opam is not initialised: run 'opam init --bare --no-setup' once (it writes ~/.opam; not done by this script)"
    local pin; pin=$(lem_pin); [[ "$pin" =~ ^[0-9a-f]{40}$ ]] || die "no lem-pin in scripts/fork_drift_manifest.txt"
    if [[ -L _opam ]]; then note "./_opam is a link to a shared switch: left alone (never install through it)"; return; fi
    [[ -d _opam ]] || run opam switch create . "$OCAML_COMPILER" --no-switch --no-install --yes
    local have; have=$(opam exec --switch="$ROOT" -- lem -v 2>/dev/null | sed -n 's/.*-g\([0-9a-f]\{7,40\}\)$/\1/p')
    if [[ -n "$have" && "$pin" == "$have"* ]]; then note "lem already at the pin $pin"
    else run opam pin add --switch="$ROOT" lem "git+$LEM_URL#$pin" --yes; fi
    run opam install --switch="$ROOT" --deps-only ./cerberus-lib.opam ./cerberus.opam --yes
}

oracle_lem_rev() { python3 -c 'import sys; sys.path.insert(0, "scripts"); from build_independent_oracle import LEM_REV; print(LEM_REV)'; }
# ONE deps directory for everything: the nearest deps/ at or above this checkout (a worktree
# under worktrees/ shares its parent's), else this checkout's own, created on first use. Taking
# the nearest of any content is what scripts/test_pnvi.sh does; a corpus missing from it is
# cloned into it, never into a second deps/ further in.
deps_dir() {
    local d="$ROOT"
    while [[ "$d" != / ]]; do [[ -d "$d/deps" ]] && { printf '%s\n' "$d/deps"; return; }; d="$(dirname "$d")"; done
    printf '%s\n' "$ROOT/deps"
}
find_in_deps() { local p; p="$(deps_dir)/$1"; [[ -d "$p" ]] && printf '%s\n' "$p"; return 0; }
clone_at() {  # <pin name> <dir relative to deps/> <url> <commit>
    # A corpus already provided by an enclosing checkout (a worktree under worktrees/ finds its
    # parent's deps/, as the lanes do) is verified and used; nothing is cloned twice.
    local found; found=$(find_in_deps "$2")
    set -- "$1" "${found:-$(deps_dir)/$2}" "$3" "$4"
    if [[ -d "$2" ]]; then
        scripts/check_external_pin.sh "$1" "$2" && return
        die "$2 exists but is not a clean checkout of the pinned commit $4 (fix or remove it; this script does not overwrite)"
    fi
    mkdir -p "$(dirname "$2")" || die "cannot create $(dirname "$2")"
    run git clone "$3" "$2"
    run git -C "$2" checkout --detach "$4"
    run scripts/check_external_pin.sh "$1" "$2"
}

do_sources() {
    say "Upstream git ref"
    if git remote get-url upstream > /dev/null 2>&1; then
        [[ "$(git remote get-url upstream)" == *rems-project/cerberus* ]] || die "remote 'upstream' is $(git remote get-url upstream), not rems-project/cerberus"
    else
        run git remote add upstream "$UPSTREAM_URL"
        run git config remote.upstream.tagOpt --no-tags   # this repository's config only
    fi
    # --no-tags: upstream's tags do not belong in this fork's tag namespace.
    git rev-parse --verify -q upstream/master > /dev/null && note "upstream/master present" \
        || run git fetch --no-tags upstream master:refs/remotes/upstream/master
    git cat-file -e "$(merge_base)^{commit}" 2>/dev/null || die "the pinned merge-base $(merge_base) is not in this clone"
    say "External corpora into deps/ (pins: scripts/external_pins.txt)"
    local name commit url dir
    while read -r name commit url; do
        case "$name" in ''|\#*) continue ;; esac
        case "$name" in
            cn) dir=cn ;; libxml2) dir=libxml2 ;; pkvm) dir=CN-pKVM-buddy-allocator-case-study ;;
            *) die "scripts/external_pins.txt names '$name', which this script does not know where to put" ;;
        esac
        clone_at "$name" "$dir" "$url" "$commit"
    done < scripts/external_pins.txt
    say "Upstream Lem (source of the independent oracle's Lem build)"
    local lem rev; lem=$(find_in_deps lem-upstream); rev=$(oracle_lem_rev)
    [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || die "cannot read LEM_REV from scripts/build_independent_oracle.py"
    if [[ -z "$lem" ]]; then
        lem="$(deps_dir)/lem-upstream"; mkdir -p "$(dirname "$lem")" || die "cannot create $(dirname "$lem")"
        run git clone "$LEM_UPSTREAM_URL" "$lem"
    fi
    git -C "$lem" cat-file -e "$rev^{commit}" 2>/dev/null || die "$lem does not contain the oracle's Lem revision $rev (fetch it there: git -C $lem fetch origin)"
    note "upstream Lem with $rev: $lem"
}

do_build() {
    say "Build (generated trees, both engines, speclab)"
    [[ -d _opam ]] || die "no ./_opam: run 'scripts/bootstrap.sh switch' first"
    # --root .: in a worktree nested under another checkout dune would otherwise take the outer
    # checkout as its root and fail with "Don't know how to build".
    in_switch make prelude-src
    in_switch dune build --root . backend/driver/main.exe cerberus-lib.install
    in_switch tools/check_driver_fresh.sh --record-oracle   # this binary, from these sources
    in_switch dune install --root . --prefix "$ROOT/_build/local-install" cerberus-lib
    in_switch dune build --root . cerberus.install
    in_switch make lean-prelude-src
    in_switch ./scripts/capped make lean-native-obj
    run bash -c 'cd lean_frontend && ../scripts/capped lake build CerberusLean cerberus-lean'
    in_switch tools/check_driver_fresh.sh --record-lean
    run bash -c 'cd lean_frontend/speclab && ../../scripts/capped lake build'
    [[ -e _build/install/default/lib/cerberus-lib/runtime/libcore/std.core ]] || die "the runtime was not staged (std.core missing after the build)"
    [[ -x lean_frontend/.lake/build/bin/cerberus-lean ]] || die "the Lean driver is missing after the build"
}

do_oracles() {
    say "Pristine upstream generated tree (fork-drift gate)"
    [[ -d _opam ]] || die "no ./_opam: run 'scripts/bootstrap.sh switch' first"
    local mb src="$ROOT/.validation-foundations/fork-drift-upstream"; mb=$(merge_base)
    git cat-file -e "$mb^{commit}" 2>/dev/null || die "the pinned merge-base $mb is not in this clone: run 'scripts/bootstrap.sh sources'"
    # Built under a private name and renamed only after generation succeeded, with the
    # merge-base recorded in a marker: an interrupted run leaves nothing that reads as present.
    local marker="$src/.bootstrap-generated-at" part="$src.partial"
    if [[ -f "$marker" && "$(cat "$marker")" == "$mb" ]] && compgen -G "$src/ocaml_frontend/generated/*.ml" > /dev/null; then
        note "present, generated at the pinned merge-base: $src/ocaml_frontend/generated"
    elif [[ -e "$src/.git" && "$(git -C "$src" rev-parse HEAD 2>/dev/null)" == "$mb" ]] && compgen -G "$src/ocaml_frontend/generated/*.ml" > /dev/null; then
        # provisioned by hand with the VALIDATION.md recipe: its own clone, checked out at the pin
        note "present, a clone at the pinned merge-base: $src/ocaml_frontend/generated"
    else
        [[ ! -e "$src" ]] || die "$src exists but was not completed by this script at merge-base $mb (remove it; this script does not overwrite)"
        rm -rf "$part" || die "cannot remove the leftover $part"
        mkdir -p "$part" || die "cannot create $part"
        # The upstream sources at the pinned merge-base, straight from this clone's object store.
        printf '    $ git archive %s | tar -x -C %s\n' "$mb" "$part"
        git archive "$mb" | tar -x -C "$part" || die "git archive of the merge-base failed"
        in_switch make -C "$part" prelude-src
        compgen -G "$part/ocaml_frontend/generated/*.ml" > /dev/null || die "generation produced no OCaml files in $part"
        printf '%s\n' "$mb" > "$part/.bootstrap-generated-at" || die "cannot write the completion marker"
        run mv "$part" "$src"
    fi
    say "Independent upstream oracle (rows B10, B12)"
    # Upstream Lem's sources at the oracle's pinned revision come from a FULL clone of
    # rems-project/lem (deps/lem-upstream, by `bootstrap.sh sources`). Lake's LemLib clone has
    # the commit but is a partial clone: archiving from it would fetch blobs over the network.
    local lem; lem=$(find_in_deps lem-upstream); lem="${CERB_LEM_REPO:-$lem}"
    [[ -n "$lem" && -d "$lem" ]] || die "no clone of upstream Lem (deps/lem-upstream or CERB_LEM_REPO): run 'scripts/bootstrap.sh sources'"
    git -C "$lem" cat-file -e "$(oracle_lem_rev)^{commit}" 2>/dev/null || die "$lem does not contain the oracle's Lem revision $(oracle_lem_rev)"
    # ensure_independent_oracle.py validates a standing build, builds an absent one, and refuses
    # an invalid one without deleting anything.
    in_switch python3 scripts/ensure_independent_oracle.py --lem-repo "$lem" --cerberus-repo "$ROOT"
    note "for the ladder: export CERB_UPSTREAM_TREE=$src/ocaml_frontend/generated"
}

do_worktree() {
    local name="${1:-}" base=HEAD build=1; shift || true
    [[ -n "$name" && "$name" != -* ]] || die "usage: bootstrap.sh worktree NAME [BASE] [--no-build]"
    for a in "$@"; do case "$a" in --no-build) build=0 ;; -*) die "unknown option $a" ;; *) base="$a" ;; esac; done
    local dst="$ROOT/worktrees/${name//\//-}"
    [[ ! -e "$dst" ]] || die "$dst already exists"
    [[ -d _opam ]] || die "no ./_opam here to share: run 'scripts/bootstrap.sh switch' first"
    say "Worktree $dst on new branch $name (from $base)"
    mkdir -p "$ROOT/worktrees" || die "cannot create worktrees/"
    run git worktree add -b "$name" "$dst" "$base"
    # Shared: the switch (read-only use: never add or remove opam packages through the link) and
    # the LemLib SOURCE clone, so the first Lake build needs no network. Nothing built is copied:
    # the worktree's trees, binaries, stamps and oracles are its own.
    run ln -s "$(cd "$ROOT/_opam" && pwd -P)" "$dst/_opam"
    if [[ -d lean_frontend/.lake/packages ]]; then
        run mkdir -p "$dst/lean_frontend/.lake"
        run cp -a lean_frontend/.lake/packages "$dst/lean_frontend/.lake/packages"
        run rm -rf "$dst/lean_frontend/.lake/packages/LemLib/lean-lib/.lake"
    else note "no LemLib clone here to copy: the worktree's first Lake build will fetch it [network]"; fi
    [[ -x "$dst/scripts/bootstrap.sh" ]] || { note "the base $base predates scripts/bootstrap.sh: build the worktree by the README recipe there (dune needs --root .)"; build=0; }
    if [[ $build -eq 1 ]]; then
        run "$dst/scripts/bootstrap.sh" build
        run "$dst/scripts/bootstrap.sh" oracles
        note "ready: cd $dst && scripts/preflight.sh"
    else note "not built: cd $dst && scripts/bootstrap.sh build && scripts/bootstrap.sh oracles"; fi
    # No --force: build output and the link are ignored files and do not block the removal, so
    # git refuses only when uncommitted work would be lost.
    note "when the branch is merged or dropped: git worktree remove $dst && git branch -d $name"
}

cmd="${1:-}"
case "$cmd" in
    switch)   do_switch ;;
    sources)  do_sources ;;
    build)    do_build ;;
    oracles)  do_oracles ;;
    all)      do_switch; do_sources; do_build; do_oracles
              say "Preflight"; CERB_UPSTREAM_TREE="${CERB_UPSTREAM_TREE:-$ROOT/.validation-foundations/fork-drift-upstream/ocaml_frontend/generated}" scripts/preflight.sh; exit $? ;;
    worktree) shift; do_worktree "$@" ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
printf '\nbootstrap: %s done\n' "$cmd"
