#!/usr/bin/env python3
"""Compare fresh Core/CoreNice runs under tapes recorded in both directions.

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
    def __init__(self, message, category="incomplete"):
        super().__init__(message)
        self.category = category


class ProtocolFailure(Incomplete):
    def __init__(self, message):
        super().__init__(message, "protocol")


class Mismatch(Exception):
    pass


def stderr_excerpt(data, limit=1500):
    text = data.decode("utf-8", errors="replace") if isinstance(data, bytes) else data
    if len(text) <= limit:
        return text
    notice = "\n... stderr truncated (head and tail retained) ...\n"
    half = (limit - len(notice)) // 2
    return text[:half] + notice + text[-half:]


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


MISSING = object()


def first_difference(left, right, path):
    """Locate one differing observed field; never render a whole payload tree."""
    if isinstance(left, dict) and isinstance(right, dict):
        for key in sorted(left.keys() | right.keys()):
            suffix = "." + key if key.isidentifier() else "[" + json.dumps(key) + "]"
            if key not in left or key not in right:
                return path + suffix, left.get(key, MISSING), right.get(key, MISSING)
            if structural(left[key]) != structural(right[key]):
                return first_difference(left[key], right[key], path + suffix)
    elif isinstance(left, list) and isinstance(right, list):
        for index, (a, b) in enumerate(zip(left, right)):
            if structural(a) != structural(b):
                return first_difference(a, b, f"{path}[{index}]")
        if len(left) != len(right):
            index = min(len(left), len(right))
            return (f"{path}[{index}]", left[index] if index < len(left) else MISSING,
                    right[index] if index < len(right) else MISSING)
    return path, left, right


def leaf_excerpt(value):
    if value is MISSING:
        return "<missing>"
    if isinstance(value, dict):
        return f"<object with {len(value)} fields>"
    if isinstance(value, list):
        return f"<array of length {len(value)}>"
    if isinstance(value, str):
        rendered = repr(value[:120])
        return rendered[:157] + "..." if len(value) > 120 or len(rendered) > 160 else rendered
    rendered = repr(value)
    return rendered[:157] + "..." if len(rendered) > 160 else rendered


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
        raise ProtocolFailure(f"invalid JSON-lines output: {error}") from error
    rank = {"header": 0, "event": 1, "choice": 2, "outcome": 3, "end": 4}
    groups = {name: [] for name in rank}
    phase = 0
    for row in rows:
        if not isinstance(row, dict):
            raise ProtocolFailure("output record is not an object")
        name = row.get("record")
        if name == "failure":
            raise Incomplete(f"frontend/input failure: {str(row.get('reason'))[:1000]}", "frontend")
        if name not in rank or rank[name] < phase:
            raise ProtocolFailure(f"unknown or out-of-order record: {name}")
        expected = {"record", name} if name != "end" else {
            "record", "complete", "kind", "visited", "choices"}
        if set(row) != expected:
            raise ProtocolFailure(f"unexpected fields in {name} record")
        phase = rank[name]
        groups[name].append(row)
    for name in ["header", "outcome", "end"]:
        if len(groups[name]) != 1:
            raise ProtocolFailure(f"expected exactly one {name} record, got {len(groups[name])}")
    if rows[0]["record"] != "header" or rows[-1]["record"] != "end":
        raise ProtocolFailure("header/end do not delimit the output")
    header = groups["header"][0]["header"]
    outcome = groups["outcome"][0]["outcome"]
    end = groups["end"][0]
    if not isinstance(header, dict) or not isinstance(outcome, dict):
        raise ProtocolFailure("header/outcome payload is not an object")
    if set(header) != {"version", "input", "prepared", "config", "coreBuild", "coreNiceBuild", "origin"}:
        raise ProtocolFailure("unexpected choice-header fields")
    if header["version"] != 2 or isinstance(header["version"], bool):
        raise ProtocolFailure("unsupported protocol version")
    if replay and outcome.get("kind") in {"replay-mismatch", "input-error"}:
        raise Mismatch(f"peer rejected a freshly recorded tape: {str(outcome)[:1200]}")
    if end["complete"] is not True:
        category = {"refused": "refusal", "incomplete": "incomplete",
                    "empty": "empty-frontier", "input-error": "input-error",
                    "observation-error": "instrumentation"}.get(outcome.get("kind"), "protocol")
        if outcome.get("kind") == "incomplete":
            if outcome.get("reason") in {"ND traversal fuel exhausted", "model fuel exhausted"}:
                category = "fuel-exhaustion"
            elif outcome.get("reason") == "empty nondeterministic frontier":
                category = "empty-frontier"
        raise Incomplete(f"execution did not complete: {str(outcome)[:1200]}", category)
    if end["kind"] not in {"defined", "undefined", "model-error"} or outcome.get("kind") != end["kind"]:
        raise ProtocolFailure("terminal kind is absent, unsupported or inconsistent")
    if not natural(end["visited"]) or not natural(end["choices"]):
        raise ProtocolFailure("terminal counts are not natural numbers")
    choices = [row["choice"] for row in groups["choice"]]
    if end["choices"] != len(choices):
        raise ProtocolFailure("terminal choice count differs from emitted choices")
    for ordinal, choice in enumerate(choices):
        if not isinstance(choice, dict) or set(choice) != {"ordinal", "kind", "parent", "alternatives", "index"}:
            raise ProtocolFailure("invalid choice record")
        alternatives = choice["alternatives"]
        if (choice["kind"] not in {"nd", "step", "branch"} or
                not natural(choice["ordinal"]) or choice["ordinal"] != ordinal or
                not natural(choice["index"]) or not isinstance(alternatives, list) or
                len(alternatives) < 2 or choice["index"] >= len(alternatives)):
            raise ProtocolFailure("invalid choice ordinal, arity or selected index")
    return Trace(header, [row["event"] for row in groups["event"]], choices, outcome, end)


def project_stutter(trace, allow_breakpoints=False):
    """Erase singleton bookkeeping inside intervals delimited by real choices.

    Each lane is checked against its own node/choice counts before erasure.
    Ordered payloads and genuine choice barriers survive. Different channels
    have no asserted interleaving within one interval in this observation schema.
    """
    def fail(message):
        raise ProtocolFailure("stutter projection: " + message)

    def channels():
        return {"driver": [], "memory": [], "stdout": "", "stderr": ""}

    payloads = {
        "driver": {"function_call": 2, "function_return": 2, "allocate_object": 6,
                   "allocate_region": 5, "kill": 3, "load": 5, "store": 6,
                   "seq_rmw": 6, "array_shift": 4, "member_shift": 4},
        "memory": {"access_receipt": 9},
    }
    def step_info(value):
        arities = {"action": 1, "memop": 0, "tau": 1, "eval": 1, "done": 0, "misc": 1}
        if (not isinstance(value, dict) or set(value) != {"tag", "fields"}
                or not isinstance(value["tag"], str) or value["tag"] not in arities
                or not isinstance(value["fields"], list) or len(value["fields"]) != arities[value["tag"]]):
            fail("unknown step-info shape")
        tag, fields = value["tag"], value["fields"]
        if tag in {"action", "tau", "eval"} and not isinstance(fields[0], str):
            fail("step-info text payload is not a string")
        if tag == "misc" and (not isinstance(fields[0], list)
                              or any(not isinstance(item, str) for item in fields[0])):
            fail("misc step-info payload is not a list of strings")

    config = trace.header.get("config")
    if not isinstance(config, dict) or config.get("observationSchema") != "boundary-channels-v1":
        fail("unsupported observation schema")
    if trace.end.get("complete") is not True:
        fail("incomplete execution")
    if (not natural(trace.end.get("visited")) or not natural(trace.end.get("choices"))
            or trace.end["choices"] != len(trace.choices)):
        fail("invalid terminal counts")
    segments, effects = [], channels()
    nodes, choices, terminal = 0, 0, False
    for event in trace.events:
        if terminal:
            fail("events follow the terminal ND node")
        if not isinstance(event, dict):
            fail("event is not an object")
        if set(event) == {"boundary", "observation"}:
            if not natural(event["boundary"]) or event["boundary"] != nodes:
                fail("observation boundary is not the next ND node")
            observation = event["observation"]
            if not isinstance(observation, dict):
                fail("observation is not an object")
            channel = observation.get("channel")
            if not isinstance(channel, str):
                fail("observation channel is not a string")
            if channel in {"stdout", "stderr"}:
                if set(observation) != {"channel", "text"} or not isinstance(observation["text"], str):
                    fail("invalid output-channel observation")
                effects[channel] += observation["text"]
            elif channel in payloads:
                if set(observation) != {"channel", "events"} or not isinstance(observation["events"], list):
                    fail("invalid effect-channel observation")
                for payload in observation["events"]:
                    if not isinstance(payload, dict) or set(payload) != {"tag", "fields"}:
                        fail("invalid effect payload")
                    tag, fields = payload["tag"], payload["fields"]
                    if (not isinstance(tag, str) or tag not in payloads[channel]
                            or not isinstance(fields, list) or len(fields) != payloads[channel][tag]):
                        fail("unknown effect tag or field shape")
                effects[channel].extend(observation["events"])
            else:
                fail("unknown observation channel; no implicit checkpoint erasure")
            continue
        if (set(event) != {"channel", "node", "kind", "parent", "alternatives", "selected"}
                or event["channel"] != "nd" or not natural(event["node"]) or event["node"] != nodes):
            fail("unknown event shape or inconsistent ND node number")
        nodes += 1
        kind, alternatives, selected = event["kind"], event["alternatives"], event["selected"]
        if not isinstance(kind, str) or not isinstance(alternatives, list):
            fail("invalid ND kind or alternatives")
        if kind == "pause" and allow_breakpoints:
            point = event["parent"]
            expected = {"schema", "procedure", "site", "role", "ailOrigin", "location",
                        "thread", "encounter", "phase", "remainingBudget", "driverSteps"}
            if (alternatives or selected is not None or not isinstance(point, dict)
                    or set(point) != expected or point["schema"] != "corenice-breakpoint-v1"
                    or point["phase"] != "nonmemory"
                    or point["role"] not in {"statement-join", "condition-ready", "loop-body-done", "internal"}
                    or any(not natural(point[key]) for key in
                           ["site", "thread", "encounter", "remainingBudget", "driverSteps"])
                    or point["encounter"] == 0
                    or (point["ailOrigin"] is not None and
                        (not isinstance(point["ailOrigin"], list) or
                         any(not natural(n) for n in point["ailOrigin"])))):
                fail("invalid breakpoint boundary")
            # Erase only the administrative boundary. Its preceding effects
            # stay in this interval, with the original genuine choice barriers.
        elif kind in {"active", "killed", "guard"}:
            if alternatives or selected is not None:
                fail("invalid terminal/guard metadata")
            if kind != "guard":
                if event["parent"] is not None:
                    fail("terminal node has unexpected parent metadata")
                if (kind == "active") != (trace.end["kind"] == "defined"):
                    fail("terminal ND kind differs from the outcome")
                segments.append({"effects": effects, "terminal": kind})
                terminal = True
            else:
                step_info(event["parent"])
        elif kind in {"nd", "step", "branch"}:
            step_info(event["parent"])
            if kind == "branch":
                if alternatives != [{"side": "left"}, {"side": "right"}]:
                    fail("invalid constraint-branch descriptors")
            else:
                for alternative in alternatives:
                    step_info(alternative)
            if (not natural(selected) or selected >= len(alternatives)
                    or (kind == "branch" and len(alternatives) != 2)):
                fail("invalid selected index or branch arity")
            if len(alternatives) > 1:
                descriptor = {"ordinal": choices, "kind": kind, "parent": event["parent"],
                              "alternatives": alternatives, "index": selected}
                if choices >= len(trace.choices) or structural(descriptor) != structural(trace.choices[choices]):
                    fail("branch node does not match its choice-tape entry")
                segments.append({"effects": effects, "branch": descriptor})
                effects = channels()
                choices += 1
        else:
            fail("unknown ND kind")
    if not terminal or nodes != trace.end["visited"] or choices != len(trace.choices):
        fail("terminal, visited-node or branching count does not match the log")
    return segments


def compare(left, right, label, comparison="exact"):
    if comparison not in {"exact", "stutter", "breakpoints"}:
        raise ValueError("unknown comparison profile")
    if left.end.get("complete") is not True or right.end.get("complete") is not True:
        raise Incomplete("cannot compare an incomplete execution", "comparison-profile")
    a = {key: value for key, value in left.header.items() if key != "origin"}
    b = {key: value for key, value in right.header.items() if key != "origin"}
    events_a, events_b = left.events, right.events
    end_a, end_b = left.end, right.end
    if comparison in {"stutter", "breakpoints"}:
        allow_breakpoints = comparison == "breakpoints"
        events_a, events_b = project_stutter(left, allow_breakpoints), project_stutter(right, allow_breakpoints)
        end_a = {key: value for key, value in left.end.items() if key != "visited"}
        end_b = {key: value for key, value in right.end.items() if key != "visited"}
    for field, x, y in [("header", a, b), ("events", events_a, events_b),
                        ("choices", left.choices, right.choices),
                        ("outcome", left.outcome, right.outcome), ("end", end_a, end_b)]:
        if structural(x) != structural(y):
            path, a, b = first_difference(x, y, "$." + field)
            path = path[:597] + "..." if len(path) > 600 else path
            detail = f"{path}: {leaf_excerpt(a)} != {leaf_excerpt(b)}"
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
                    raise Incomplete(f"child exceeded {timeout:g}s wall limit", "resource-timeout")
                for key, _ in selector.select(min(remaining, 0.2)):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    if sum(map(len, output.values())) + len(chunk) > output_bytes:
                        raise Incomplete(f"child exceeded {output_bytes} output bytes", "resource-output")
                    output[key.data].extend(chunk)
        remaining = timeout - (time.monotonic() - started)
        if remaining <= 0:
            raise Incomplete(f"child exceeded {timeout:g}s wall limit", "resource-timeout")
        try:
            code = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired as error:
            raise Incomplete(f"child exceeded {timeout:g}s wall limit", "resource-timeout") from error
        completed = True
        return code, bytes(output["stdout"]), bytes(output["stderr"])
    except Incomplete as error:
        detail = stderr_excerpt(bytes(output["stderr"]))
        raise Incomplete(f"{error}; stderr: {detail or '(empty)'}", error.category) from error
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
        raise ProtocolFailure("recorder did not produce a bounded tape file")
    try:
        tape = decode(path.read_text(encoding="utf-8"))
    except (UnicodeError, ValueError) as error:
        raise ProtocolFailure(f"recorder produced malformed tape JSON: {error}") from error
    expected = {"header": trace.header, "entries": trace.choices}
    if structural(tape) != structural(expected):
        raise ProtocolFailure("written tape differs from the recorder's emitted header/choices")


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


def compare_case(options, build_pair=None, inspect=None, inspect_nice=None):
    """Run four fresh processes; return compact evidence only after all agree.

    A campaign may supply hashes computed once, provided it checks that those
    same binary files stay unchanged for the duration of the campaign.
    """
    memory = options.memory_mb * 1024 * 1024
    output_limit = options.output_mb * 1024 * 1024
    build_a, build_b = build_pair or (sha256(options.core_bin), sha256(options.corenice_bin))
    def child(command):
        timeout = options.timeout
        deadline = getattr(options, "deadline", None)
        if deadline is not None:
            timeout = min(timeout, deadline - time.monotonic())
            if timeout <= 0:
                raise Incomplete("campaign wall limit reached", "resource-timeout")
        return run_child(command, timeout, memory, output_limit)
    scratch = ROOT / ".tmp"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="corenice-diff-", dir=scratch) as directory:
        directory = Path(directory)
        if options.cabs_json:
            cabs = options.input
        else:
            producer = options.producer.resolve(strict=True)
            code, stdout, stderr = child(
                [str(producer), "--runtime=" + str(options.runtime), "--cabs-json", str(options.input)])
            if code != 0:
                raise Incomplete(f"Cabs producer failed ({code}): {stderr_excerpt(stderr)}", "frontend")
            if stderr:
                print("PRODUCER_STDERR: " + stderr_excerpt(stderr), file=sys.stderr)
            cabs = directory / "input.json"
            cabs.write_bytes(stdout)
        common = ["--runtime", str(options.runtime), "--input", str(cabs),
                  "--fuel", str(options.fuel), "--address-space-top", str(options.address_space_top),
                  "--core-build", build_a, "--corenice-build", build_b]
        for argument in options.arg:
            common.extend(["--arg", argument])

        def execute(binary, origin, mode, tape):
            command = [str(binary), *common, "--mode", mode, "--tape", str(tape)]
            if origin == "CoreNice":
                command.extend(getattr(options, "corenice_arg", []))
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
                detail = stderr_excerpt(stderr)
                message = f"{origin} {mode}: {error}; exit={code}; stderr: {detail or '(empty)'}"
                if isinstance(error, Mismatch):
                    raise Mismatch(message) from error
                category = error.category
                if code not in (None, 0) and category == "protocol":
                    category = "process-failure"
                raise Incomplete(message, category) from error
            if code != 0:
                raise Incomplete(f"{origin} {mode}: child exited {code} despite complete output: "
                                 + stderr_excerpt(stderr), "process-failure")
            if stderr:
                print(f"{origin.upper()}_{mode.upper()}_STDERR: "
                      + stderr_excerpt(stderr), file=sys.stderr)
            if trace.header["coreBuild"] != build_a or trace.header["coreNiceBuild"] != build_b or trace.header["origin"] != origin:
                raise Incomplete(f"{origin} {mode}: executable did not attest the requested build pair/origin")
            if mode == "record":
                check_tape_file(tape, trace, output_limit)
            return trace

        tape_a, tape_b = directory / "core.tape.json", directory / "corenice.tape.json"
        a_record = execute(options.core_bin, "Core", "record", tape_a)
        b_replay = execute(options.corenice_bin, "CoreNice", "replay", tape_a)
        comparison = getattr(options, "comparison", "exact")
        compare(a_record, b_replay, "Core record -> CoreNice replay", comparison)
        b_record = execute(options.corenice_bin, "CoreNice", "record", tape_b)
        a_replay = execute(options.core_bin, "Core", "replay", tape_b)
        compare(b_record, a_replay, "CoreNice record -> Core replay", comparison)
        compare(a_record, b_record, "independent recordings under the same policy", comparison)
        if inspect is not None:
            inspect(a_record)
        if inspect_nice is not None:
            inspect_nice(b_record)
        summary = summarize(a_record)
        pauses = [event["parent"] for event in b_record.events
                  if event.get("channel") == "nd" and event.get("kind") == "pause"]
        summary["breakpoint_visits"] = len(pauses)
        summary["breakpoint_sites"] = len({json.dumps([point["procedure"], point["site"]], sort_keys=True) for point in pauses})
        summary["breakpoint_roles"] = {role: sum(point["role"] == role for point in pauses)
                                       for role in sorted({point["role"] for point in pauses})}
        summary["comparison"] = comparison
        return summary


def parse_options(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="one C translation unit (or existing Cabs JSON)")
    parser.add_argument("--cabs-json", action="store_true", help="input is already Cabs JSON")
    parser.add_argument("--producer", type=Path, default=ROOT / "_build/default/backend/driver/main.exe")
    parser.add_argument("--runtime", type=Path, default=ROOT / "_build/install/default")
    parser.add_argument("--core-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/core-diff")
    parser.add_argument("--corenice-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/corenice-diff")
    parser.add_argument("--corenice-arg", action="append", default=[],
                        help="extra Nice runner argument; use = for values beginning with --")
    policy = parser.add_mutually_exclusive_group()
    policy.add_argument("--seed", type=int)
    policy.add_argument("--choices", help="comma-separated branching indices, then branch zero")
    parser.add_argument("--fuel", type=int, default=1000000)
    parser.add_argument("--address-space-top", type=lambda value: int(value, 0), default=0xFFFFFFFFFFFF)
    parser.add_argument("--arg", action="append", default=[], help="program argument, repeatable")
    parser.add_argument("--timeout", type=float, default=30.0, help="wall seconds per child")
    parser.add_argument("--memory-mb", type=int, default=4096, help="virtual memory MiB per child")
    parser.add_argument("--output-mb", type=int, default=16, help="combined stdout/stderr MiB per child")
    parser.add_argument("--comparison", choices=["exact", "stutter", "breakpoints"], default="exact",
                        help="exact trace or explicit branch-delimited stutter projection")
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
    options.corenice_bin = options.corenice_bin.resolve(strict=True)
    return options


def main(argv=None):
    options = parse_options(argv)
    summary = compare_case(options)
    kind = summary["kind"]
    if options.summary_json:
        print(json.dumps(summary, sort_keys=True))
    else:
        token = {"defined": "MATCH_DEFINED", "undefined": "MATCH_UNDEFINED", "model-error": "MATCHED_MODEL_ERROR"}[kind]
        print(f"{token}: {options.input} | {options.comparison} | both recording directions | "
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
