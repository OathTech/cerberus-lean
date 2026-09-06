#!/usr/bin/env bash
# Side-effect-free shell interface to observations.py. Production comparisons
# consume saved captures; text helpers exist for the historical extractor plants.
OBSERVATION_CODEC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/observations.py"

observation_capture() { # <unique-prefix> <command> [args...]; original status
    local prefix="$1" rc=0
    shift
    mkdir -p "$(dirname "$prefix")" || return 125
    if [[ -e "$prefix.stdout" || -e "$prefix.stderr" || -e "$prefix.status" || -e "$prefix.capture-error" ]]; then
        printf '%s\n' 'capture prefix reused; original evidence retained' > "$prefix.capture-error"
        echo "OBSERVATION ERROR: capture prefix already exists: $prefix" >&2
        return 125
    fi
    printf '%s\n' 'capture not completed' > "$prefix.capture-error" || return 125
    printf '%q ' "$@" > "$prefix.command" || return 125
    printf '\n' >> "$prefix.command" || return 125
    # Deliberately separate engine diagnostics from the semantic batch stream.
    "$@" > "$prefix.stdout" 2> "$prefix.stderr" || rc=$?
    printf '%s\n' "$rc" > "$prefix.status" || return 125
    rm "$prefix.capture-error" || return 125
    # Compatibility display for existing classifiers, NEVER the parser's input.
    # The original bytes (including NUL, if malformed) are retained above.
    cat "$prefix.stdout" "$prefix.stderr"
    return "$rc"
}

observation_tokens() { # <capture-prefix> [codec options]
    local prefix="$1"; shift
    python3 "$OBSERVATION_CODEC" tokens --capture "$prefix" "$@"
}

observation_expected_exit() {
    python3 "$OBSERVATION_CODEC" expected-exit --capture "$1"
}

observation_compare() { # <left-prefix> <right-prefix> [codec options]
    local left="$1" right="$2"; shift 2
    python3 "$OBSERVATION_CODEC" compare --capture "$left" --other "$right" "$@"
}

extract_verdict_seq() { # legacy text-only plant API; production uses captures
    printf '%s\n' "$1" | python3 "$OBSERVATION_CODEC" tokens
}

expected_exit_for() { # legacy text-only plant API
    printf '%s\n' "$1" | python3 "$OBSERVATION_CODEC" expected-exit
}
