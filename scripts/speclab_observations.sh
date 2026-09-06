#!/usr/bin/env bash
# Shared execution path for the spec-lab harness families. Source common.sh first.
# Full observations drive engine parity; the model's existing scalar prediction
# remains a separate, explicitly single-outcome reference projection.
speclab_pair() { # <source.c> <label> [nolibc|libc] [exhaustive|first]
    local src="$1" tag="$2" libc="${3:-nolibc}" mode="${4:-exhaustive}"
    local directory orc=0 lrc=0
    mkdir -p "$OBSERVATION_RUN_DIR" || fail "cannot create observation directory"
    directory=$(mktemp -d "$OBSERVATION_RUN_DIR/$tag.XXXXXXXX") || fail "mktemp failed"
    cp "$src" "$directory/input.c" || fail "cannot retain generated harness"
    local oflags=(--exec --batch) lflags=(--batch)
    [[ "$mode" == exhaustive ]] && oflags+=(--mode=exhaustive)
    [[ "$mode" == first ]] && lflags+=(--first)
    if [[ "$libc" == nolibc ]]; then oflags+=(--nolibc)
    elif [[ "$libc" == libc ]]; then lflags+=("${LIBC_ARGS[@]}")
    else fail "unknown spec-lab libc mode: $libc"; fi
    observation_capture "$directory/oracle" timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" "${oflags[@]}" "$src" \
        > "$directory/oracle.display" || orc=$?
    observation_capture "$directory/bridge" timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$src" \
        > "$directory/bridge.display" || fail "cabs-json refused $tag; see $directory"
    [[ -s "$directory/bridge.stdout" ]] || fail "empty Cabs JSON for $tag"
    observation_capture "$directory/lean" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" "${lflags[@]}" \
        "$directory/bridge.stdout" > "$directory/lean.display" || lrc=$?
    ORACLE_OBSERVATION=$(observation_tokens "$directory/oracle" --status "$orc") \
        || fail "incomplete oracle observation for $tag; see $directory"
    LEAN_OBSERVATION=$(observation_tokens "$directory/lean" --status "$lrc") \
        || fail "incomplete Lean observation for $tag; see $directory"
    ORACLE_VERDICT=$(observation_tokens "$directory/oracle" --projection pin) \
        || fail "model prediction needs one oracle outcome; see $directory"
    LEAN_VERDICT=$(observation_tokens "$directory/lean" --projection pin) \
        || fail "model prediction needs one Lean outcome; see $directory"
    [[ "$ORACLE_OBSERVATION" == UB:* ]] && ORACLE_VERDICT="Undefined $ORACLE_VERDICT"
    [[ "$LEAN_OBSERVATION" == UB:* ]] && LEAN_VERDICT="Undefined $LEAN_VERDICT"
    ORACLE_BATCH_LINE=$(cat "$directory/oracle.stdout")
    LEAN_BATCH_LINE=$(cat "$directory/lean.stdout")
    ORACLE_STATUS=$orc
    LEAN_STATUS=$lrc
    return 0
}

run_pair() { speclab_pair "$1" "$2"; }
