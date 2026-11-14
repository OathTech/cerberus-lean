#!/usr/bin/env python3
"""Compare fresh Core/CoreB runs under tapes recorded in both directions.

The initial domain is one translation unit, default switches and no C libc.
Only complete defined/UB comparisons can succeed; resource limits, refusals,
missing completion and matching model errors are explicit non-successes.
"""

import argparse
from dataclasses import dataclass
from decimal import Decimal
import hashlib
import json
import math
import os
from pathlib import Path
import resource
import selectors
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


class Incomplete(Exception):
    pass


class Mismatch(Exception):
    pass


def reject_constant(value):
    raise ValueError(f"non-finite JSON number: {value}")


def decode(text):
    # Preserve arbitrary precision; Python's bool == 1 is handled separately
    # by structural() rather than being allowed to hide a payload change.
    def object_fields(pairs):
        fields = {}
        for key, value in pairs:
            if key in fields:
                raise ValueError(f"duplicate JSON object key: {key}")
            fields[key] = value
        return fields
    return json.loads(text, parse_float=Decimal, parse_constant=reject_constant,
                      object_pairs_hook=object_fields)


def structural(value):
    if value is None:
        return ("null",)
    if isinstance(value, bool):
        return ("bool", value)
    if isinstance(value, (int, Decimal)):
        return ("number", Decimal(value))
    if isinstance(value, str):
        return ("string", value)
    if isinstance(value, list):
        return ("array", tuple(map(structural, value)))
    if isinstance(value, dict):
        return ("object", tuple((key, structural(item)) for key, item in sorted(value.items())))
    raise ValueError(f"unsupported JSON value: {type(value).__name__}")


def natural(value):
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


@dataclass
class Trace:
    header: dict
    events: list
    choices: list
    outcome: dict
    end: dict


def parse_trace(data, *, replay=False):
    try:
        rows = [decode(line) for line in data.decode("utf-8").splitlines() if line.strip()]
    except (UnicodeError, ValueError) as error:
        raise Incomplete(f"invalid JSON-lines output: {error}") from error
    rank = {"header": 0, "event": 1, "choice": 2, "outcome": 3, "end": 4}
    groups = {name: [] for name in rank}
    phase = 0
    for row in rows:
        if not isinstance(row, dict):
            raise Incomplete("output record is not an object")
        name = row.get("record")
        if name == "failure":
            raise Incomplete(f"frontend/input failure: {str(row.get('reason'))[:1000]}")
        if name not in rank or rank[name] < phase:
            raise Incomplete(f"unknown or out-of-order record: {name}")
        expected = {"record", name} if name != "end" else {
            "record", "complete", "kind", "visited", "choices"}
        if set(row) != expected:
            raise Incomplete(f"unexpected fields in {name} record")
        phase = rank[name]
        groups[name].append(row)
    for name in ["header", "outcome", "end"]:
        if len(groups[name]) != 1:
            raise Incomplete(f"expected exactly one {name} record, got {len(groups[name])}")
    if rows[0]["record"] != "header" or rows[-1]["record"] != "end":
        raise Incomplete("header/end do not delimit the output")
    header = groups["header"][0]["header"]
    outcome = groups["outcome"][0]["outcome"]
    end = groups["end"][0]
    if not isinstance(header, dict) or not isinstance(outcome, dict):
        raise Incomplete("header/outcome payload is not an object")
    if set(header) != {"version", "input", "prepared", "config", "coreBuild", "coreBBuild", "origin"}:
        raise Incomplete("unexpected choice-header fields")
    if header["version"] != 1 or isinstance(header["version"], bool):
        raise Incomplete("unsupported protocol version")
    if replay and outcome.get("kind") in {"replay-mismatch", "input-error"}:
        raise Mismatch(f"peer rejected a freshly recorded tape: {str(outcome)[:1200]}")
    if end["complete"] is not True:
        raise Incomplete(f"execution did not complete: {str(outcome)[:1200]}")
    if end["kind"] not in {"defined", "undefined", "model-error"} or outcome.get("kind") != end["kind"]:
        raise Incomplete("terminal kind is absent, unsupported or inconsistent")
    if not natural(end["visited"]) or not natural(end["choices"]):
        raise Incomplete("terminal counts are not natural numbers")
    choices = [row["choice"] for row in groups["choice"]]
    if end["choices"] != len(choices):
        raise Incomplete("terminal choice count differs from emitted choices")
    for ordinal, choice in enumerate(choices):
        if not isinstance(choice, dict) or set(choice) != {"ordinal", "kind", "parent", "alternatives", "index"}:
            raise Incomplete("invalid choice record")
        alternatives = choice["alternatives"]
        if (choice["kind"] not in {"nd", "step", "branch"} or
                not natural(choice["ordinal"]) or choice["ordinal"] != ordinal or
                not natural(choice["index"]) or not isinstance(alternatives, list) or
                len(alternatives) < 2 or choice["index"] >= len(alternatives)):
            raise Incomplete("invalid choice ordinal, arity or selected index")
    return Trace(header, [row["event"] for row in groups["event"]], choices, outcome, end)


def compare(left, right, label):
    a = {key: value for key, value in left.header.items() if key != "origin"}
    b = {key: value for key, value in right.header.items() if key != "origin"}
    for field, x, y in [("header", a, b), ("events", left.events, right.events),
                        ("choices", left.choices, right.choices),
                        ("outcome", left.outcome, right.outcome), ("end", left.end, right.end)]:
        if structural(x) != structural(y):
            if isinstance(x, list) and isinstance(y, list):
                first = next((i for i, (p, q) in enumerate(zip(x, y)) if structural(p) != structural(q)), min(len(x), len(y)))
                detail = f"first differing index {first}; lengths {len(x)}/{len(y)}"
            else:
                detail = f"{str(x)[:450]} != {str(y)[:450]}"
            raise Mismatch(f"{label}: {field} differ ({detail})")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_child(command, timeout, memory_bytes, output_bytes):
    """Limit one owned process group, retaining at most output_bytes in memory."""
    def limits():
        resource.setrlimit(resource.RLIMIT_AS, (memory_bytes, memory_bytes))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))

    env = dict(os.environ, LEAN_ABORT_ON_PANIC="1")
    started = time.monotonic()
    output = {"stdout": bytearray(), "stderr": bytearray()}
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               stdin=subprocess.DEVNULL, env=env, cwd=ROOT,
                               start_new_session=True, preexec_fn=limits)
    completed = False
    try:
        with selectors.DefaultSelector() as selector:
            for name, pipe in [("stdout", process.stdout), ("stderr", process.stderr)]:
                os.set_blocking(pipe.fileno(), False)
                selector.register(pipe, selectors.EVENT_READ, name)
            while selector.get_map():
                remaining = timeout - (time.monotonic() - started)
                if remaining <= 0:
                    raise Incomplete(f"child exceeded {timeout:g}s wall limit")
                for key, _ in selector.select(min(remaining, 0.2)):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    if sum(map(len, output.values())) + len(chunk) > output_bytes:
                        raise Incomplete(f"child exceeded {output_bytes} output bytes")
                    output[key.data].extend(chunk)
        remaining = timeout - (time.monotonic() - started)
        if remaining <= 0:
            raise Incomplete(f"child exceeded {timeout:g}s wall limit")
        try:
            code = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired as error:
            raise Incomplete(f"child exceeded {timeout:g}s wall limit") from error
        completed = True
        return code, bytes(output["stdout"]), bytes(output["stderr"])
    except Incomplete as error:
        detail = bytes(output["stderr"][-1500:]).decode("utf-8", errors="replace")
        raise Incomplete(f"{error}; stderr: {detail or '(empty)'}") from error
    finally:
        # Only this Popen's newly created session/process group is targeted.
        # No process-name matching or machine-wide process operation is used.
        # On failure the leader has not been reaped, so its PID cannot have
        # been recycled even if it exited while a child still holds a pipe.
        if not completed:
            try:
                if os.getpgid(process.pid) != process.pid:
                    raise RuntimeError("owned child no longer has its expected process group")
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
        process.stdout.close()
        process.stderr.close()


def check_tape_file(path, trace, limit):
    if not path.is_file() or path.stat().st_size > limit:
        raise Incomplete("recorder did not produce a bounded tape file")
    try:
        tape = decode(path.read_text(encoding="utf-8"))
    except (UnicodeError, ValueError) as error:
        raise Incomplete(f"recorder produced malformed tape JSON: {error}") from error
    expected = {"header": trace.header, "entries": trace.choices}
    if structural(tape) != structural(expected):
        raise Incomplete("written tape differs from the recorder's emitted header/choices")


def summarize(trace):
    """Compact actual-path evidence; no machine state or raw trace is retained."""
    # structural() is deterministic for JSON and keeps type/precision distinctions.
    def digest(value):
        return hashlib.sha256(repr(structural(value)).encode("utf-8")).hexdigest()
    tags = {}
    for event in trace.events:
        observation = event.get("observation", {}) if isinstance(event, dict) else {}
        channel = observation.get("channel")
        for payload in observation.get("events", []):
            tag = f"{channel}:{payload.get('tag', 'unknown')}"
            tags[tag] = tags.get(tag, 0) + 1
    return {
        "observed_tags": tags,
        "kind": trace.end["kind"], "both_directions": True,
        "tape_sha256": digest(trace.choices),
        "outcome_sha256": digest(trace.outcome),
        "indices": [choice["index"] for choice in trace.choices],
        "arities": [len(choice["alternatives"]) for choice in trace.choices],
        "choice_kinds": [choice["kind"] for choice in trace.choices],
        "visited": trace.end["visited"], "events": len(trace.events),
    }


def compare_case(options, build_pair=None):
    """Run four fresh processes; return compact evidence only after all agree.

    A campaign may supply hashes computed once, provided it checks that those
    same binary files stay unchanged for the duration of the campaign.
    """
    memory = options.memory_mb * 1024 * 1024
    output_limit = options.output_mb * 1024 * 1024
    build_a, build_b = build_pair or (sha256(options.core_bin), sha256(options.coreb_bin))
    def child(command):
        timeout = options.timeout
        deadline = getattr(options, "deadline", None)
        if deadline is not None:
            timeout = min(timeout, deadline - time.monotonic())
            if timeout <= 0:
                raise Incomplete("campaign wall limit reached")
        return run_child(command, timeout, memory, output_limit)
    scratch = ROOT / ".tmp"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="coreb-diff-", dir=scratch) as directory:
        directory = Path(directory)
        if options.cabs_json:
            cabs = options.input
        else:
            producer = options.producer.resolve(strict=True)
            code, stdout, stderr = child(
                [str(producer), "--runtime=" + str(options.runtime), "--cabs-json", str(options.input)])
            if code != 0:
                raise Incomplete(f"Cabs producer failed ({code}): {stderr.decode('utf-8', errors='replace')[-1500:]}")
            if stderr:
                print("PRODUCER_STDERR: " + stderr.decode("utf-8", errors="replace")[-1500:], file=sys.stderr)
            cabs = directory / "input.json"
            cabs.write_bytes(stdout)
        common = ["--runtime", str(options.runtime), "--input", str(cabs),
                  "--fuel", str(options.fuel), "--address-space-top", str(options.address_space_top),
                  "--core-build", build_a, "--coreb-build", build_b]
        for argument in options.arg:
            common.extend(["--arg", argument])

        def execute(binary, origin, mode, tape):
            command = [str(binary), *common, "--mode", mode, "--tape", str(tape)]
            if mode == "record":
                if options.seed is not None:
                    command.extend(["--seed", str(options.seed)])
                if options.choices is not None:
                    command.extend(["--choices", options.choices])
            code, stderr = None, b""
            try:
                code, stdout, stderr = child(command)
                trace = parse_trace(stdout, replay=mode == "replay")
            except (Incomplete, Mismatch) as error:
                detail = stderr.decode("utf-8", errors="replace")[-1500:]
                raise type(error)(f"{origin} {mode}: {error}; exit={code}; stderr: {detail or '(empty)'}") from error
            if code != 0:
                raise Incomplete(f"{origin} {mode}: child exited {code} despite complete output: "
                                 + stderr.decode("utf-8", errors="replace")[-1500:])
            if stderr:
                print(f"{origin.upper()}_{mode.upper()}_STDERR: "
                      + stderr.decode("utf-8", errors="replace")[-1500:], file=sys.stderr)
            if trace.header["coreBuild"] != build_a or trace.header["coreBBuild"] != build_b or trace.header["origin"] != origin:
                raise Incomplete(f"{origin} {mode}: executable did not attest the requested build pair/origin")
            if mode == "record":
                check_tape_file(tape, trace, output_limit)
            return trace

        tape_a, tape_b = directory / "core.tape.json", directory / "coreb.tape.json"
        a_record = execute(options.core_bin, "Core", "record", tape_a)
        b_replay = execute(options.coreb_bin, "CoreB", "replay", tape_a)
        compare(a_record, b_replay, "Core record -> CoreB replay")
        b_record = execute(options.coreb_bin, "CoreB", "record", tape_b)
        a_replay = execute(options.core_bin, "Core", "replay", tape_b)
        compare(b_record, a_replay, "CoreB record -> Core replay")
        compare(a_record, b_record, "independent recordings under the same policy")
        return summarize(a_record)


def parse_options(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="one C translation unit (or existing Cabs JSON)")
    parser.add_argument("--cabs-json", action="store_true", help="input is already Cabs JSON")
    parser.add_argument("--producer", type=Path, default=ROOT / "_build/default/backend/driver/main.exe")
    parser.add_argument("--runtime", type=Path, default=ROOT / "_build/install/default")
    parser.add_argument("--core-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/core-diff")
    parser.add_argument("--coreb-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/coreb-diff")
    policy = parser.add_mutually_exclusive_group()
    policy.add_argument("--seed", type=int)
    policy.add_argument("--choices", help="comma-separated branching indices, then branch zero")
    parser.add_argument("--fuel", type=int, default=1000000)
    parser.add_argument("--address-space-top", type=lambda value: int(value, 0), default=0xFFFFFFFFFFFF)
    parser.add_argument("--arg", action="append", default=[], help="program argument, repeatable")
    parser.add_argument("--timeout", type=float, default=30.0, help="wall seconds per child")
    parser.add_argument("--memory-mb", type=int, default=4096, help="virtual memory MiB per child")
    parser.add_argument("--output-mb", type=int, default=16, help="combined stdout/stderr MiB per child")
    parser.add_argument("--summary-json", action="store_true", help="emit compact actual-path coverage as JSON")
    options = parser.parse_args(argv)
    if options.fuel < 0 or not 0 < options.address_space_top < 2**64:
        parser.error("fuel must be nonnegative and address-space top must lie in (0, 2^64)")
    if options.seed is not None and not 0 <= options.seed < 2**64:
        parser.error("seed must fit UInt64")
    if not math.isfinite(options.timeout) or options.timeout <= 0 or options.memory_mb <= 0 or options.output_mb <= 0:
        parser.error("child limits must be positive")
    if options.choices is not None:
        try:
            indices = [] if options.choices == "" else [int(value) for value in options.choices.split(",")]
            if any(index < 0 for index in indices):
                raise ValueError("negative index")
        except ValueError:
            parser.error("choices must be comma-separated natural numbers")
        options.choices = ",".join(map(str, indices))
    options.input = options.input.resolve(strict=True)
    options.runtime = options.runtime.resolve(strict=True)
    options.core_bin = options.core_bin.resolve(strict=True)
    options.coreb_bin = options.coreb_bin.resolve(strict=True)
    return options


def main(argv=None):
    options = parse_options(argv)
    summary = compare_case(options)
    kind = summary["kind"]
    if options.summary_json:
        print(json.dumps(summary, sort_keys=True))
    else:
        token = {"defined": "MATCH_DEFINED", "undefined": "MATCH_UNDEFINED", "model-error": "MATCHED_MODEL_ERROR"}[kind]
        print(f"{token}: {options.input} | both recording directions | "
              f"choices={len(summary['indices'])} nodes={summary['visited']} events={summary['events']}")
    return 3 if kind == "model-error" else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Mismatch as error:
        print(f"MISMATCH: {error}", file=sys.stderr)
        sys.exit(1)
    except (Incomplete, OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"INCOMPLETE: {error}", file=sys.stderr)
        sys.exit(2)
