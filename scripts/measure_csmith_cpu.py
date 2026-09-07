#!/usr/bin/env python3
"""NON-GATING per-engine CPU export from the unmodified csmith corpus lane.

Run after sourcing the container's scripts/env.sh. The lane itself stages
inputs, invokes both engines, and assigns statuses. A shell-local cleanup
hook copies only its completed GNU time records and status.txt before rm;
it changes neither engine invocation nor the lane's classification code.
The entire lane runs under scripts/capped, CERB_MEM_MAX=48G. No build is
performed: SKIP_BUILD=1 requires the lane's normal freshness checks.

Each input has oracle and lean rows. Status is the joint lane classification
on BOTH rows. A side the lane did not execute has NA resource/exit fields;
it is never reported as zero CPU or as agreement. CPU is GNU time user+sys
(including timeout's waited-for children), with its 0.01 s precision.
The TSV and adjacent .meta.txt are compact evidence; raw logs remain in the
printed worktree-local run directory. --collect exports a completed run
again without executing engines. Lane regressions are reported, not hidden:
instrument exit 0 certifies export integrity, NOT baseline agreement.
"""

import argparse
import collections
import csv
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("input", "engine", "exit", "wall_s", "cpu_s", "maxrss_kb", "status")
STATUSES = set("MATCH UB_MATCH UB_DIFF MISMATCH DIFF FAIL TIMEOUT HANG LEAN_CRASH "
               "LEAN_ERROR CERB_SKIP CERB_INCONSISTENT UNSUPPORTED UNSUPPORTED_PASS "
               "CERB_FLOOR FUEL".split())
# The exact rm operation still runs. Retention is restricted to this
# checkout's exec-test scratch directory; no file is rewritten in place.
# An incomplete/missing copy makes collection fail closed.
HOOK = r'''
rm() {
    local p f
    for p in "$@"; do
        case "$p" in
            "$FC_REPO"/.tmp/scripts/exec-test.*)
                if [[ -d "$p" && -f "$p/status.txt" ]]; then
                    for f in "$p"/*.time "$p/status.txt"; do
                        [[ -f "$f" ]] || continue
                        command cp -- "$f" "$FC_RUN/retained/" || return 1
                    done
                fi
                ;;
        esac
    done
    command rm "$@"
}
export -f rm
exec "$@"
'''


def checked(cmd, cwd=None):
    return subprocess.check_output(cmd, cwd=cwd, text=True).strip()


def identity(repo):
    lines = ["repo=" + str(repo), "head=" + checked(["git", "rev-parse", "HEAD"], repo)]
    lines.append("instrument_sha256=" + hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    for rel in ("scripts/test_csmith_corpus.sh", "scripts/test_exec.sh",
                "scripts/common.sh", "scripts/exec_csmith_corpus_baseline.txt",
                "lean_frontend/lake-manifest.json",
                "_build/default/backend/driver/main.exe",
                "lean_frontend/.lake/build/bin/cerberus-lean"):
        path = repo / rel
        lines.append("sha256 " + hashlib.sha256(path.read_bytes()).hexdigest() + " " + rel)
    corpus = hashlib.sha256()
    for path in sorted((repo / "tests/csmith").rglob("*")):
        if path.is_file() and path.suffix in {".c", ".h"}:
            corpus.update(str(path.relative_to(repo)).encode() + b"\0")
            corpus.update(hashlib.sha256(path.read_bytes()).digest())
    lines.append("corpus_source_sha256=" + corpus.hexdigest())
    return lines


def rusage(path):
    data = path.read_text()

    def field(label, pattern):
        matches = re.findall(r"^\s*" + re.escape(label) + r": (" + pattern + r")$", data, re.M)
        if len(matches) != 1:
            raise ValueError(f"missing/ambiguous {label}: {path}")
        return matches[0]

    user = float(field("User time (seconds)", r"\d+\.\d+"))
    system = float(field("System time (seconds)", r"\d+\.\d+"))
    wall = field("Elapsed (wall clock) time (h:mm:ss or m:ss)", r"\d+(?::\d+){1,2}\.\d+")
    seconds = 0.0
    for part in wall.split(":"):
        seconds = seconds * 60 + float(part)
    rss = field("Maximum resident set size (kbytes)", r"\d+")
    rc = field("Exit status", r"\d+")
    signal = re.findall(r"^Command terminated by signal (\d+)$", data, re.M)
    if signal:
        if len(signal) != 1:
            raise ValueError(f"ambiguous signal: {path}")
        rc = str(128 + int(signal[0]))
    return rc, f"{seconds:.2f}", f"{user + system:.2f}", rss


def collect(run, output):
    log = (run / "lane.log").read_text()
    rc = int((run / "lane.exit").read_text())
    lines = (run / "retained/status.txt").read_text().splitlines()
    statuses = {}
    for line in lines:
        name, status = line.split()
        if name in statuses or not name.endswith(".c") or status not in STATUSES:
            raise ValueError("invalid/duplicate lane status: " + line)
        statuses[name] = status
    displayed = re.findall(r"^\[(\d+)/(\d+)\] (\w+) (\S+)", log, re.M)
    if not displayed or len(displayed) != len(statuses):
        raise ValueError("empty/incomplete lane or status/display count mismatch")
    if [int(x[0]) for x in displayed] != list(range(1, len(statuses) + 1)):
        raise ValueError("nonconsecutive lane indices")
    if any(int(x[1]) != len(statuses) for x in displayed):
        raise ValueError("lane did not finish its selected input list")
    if {x[3].removesuffix(":") + ".c": x[2] for x in displayed} != statuses:
        raise ValueError("TSV status source differs from lane's displayed classification")
    summaries = re.findall(r"^SUMMARY: total=(\d+) .*$", log, re.M)
    checks = re.findall(r"^Baseline check: (\d+) regression\(s\), (\d+) improvement\(s\)$", log, re.M)
    if summaries != [str(len(statuses))] or len(checks) != 1:
        raise ValueError("missing/ambiguous lane summary or baseline verdict")
    if rc != (1 if int(checks[0][0]) else 0):
        raise ValueError(f"lane exit {rc} inconsistent with baseline verdict {checks}")
    rows, used = [], set()
    for name, status in statuses.items():
        for engine, suffix in (("oracle", "cerb"), ("lean", "lean")):
            path = run / "retained" / (name[:-2] + "." + suffix + ".time")
            if path.exists():
                values = rusage(path)
                used.add(path.name)
            else:
                if engine == "oracle" or status not in {"CERB_SKIP", "CERB_FLOOR", "CERB_INCONSISTENT"}:
                    raise ValueError(f"missing required rusage: {path}")
                values = ("NA",) * 4
            rows.append((name, engine, *values, status))
    if used != {p.name for p in (run / "retained").glob("*.time")}:
        raise ValueError("extra/unmatched timing records")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(FIELDS)
        writer.writerows(rows)
    meta = (run / "run.meta.txt").read_text()
    meta += "\n" + "\n".join(line for line in log.splitlines() if line.startswith(
        ("SUMMARY:", "REGRESSION:", "improvement:", "changed (", "Baseline check:", "BASELINE OK", "FAILED:")))
    meta += f"\nlane_exit={rc}\nexported_inputs={len(statuses)}\nexported_engine_rows={len(rows)}\n"
    meta += "derived_status_tally=" + repr(dict(sorted(collections.Counter(statuses.values()).items()))) + "\n"
    output.with_suffix(".meta.txt").write_text(meta)
    print(f"CPU export OK: {len(statuses)} inputs, {len(rows)} engine rows; lane exit={rc}; {output}")
    return rows


def run_lane(repo, args, overrides=None):
    if not os.environ.get("GIT_CONFIG_GLOBAL"):
        raise ValueError("source the container scripts/env.sh first")
    for key in ("CERB_DRIVER_FRESH_OVERRIDE", "CERB_ORACLE_BIN_OVERRIDE", "CERB_LEAN_BIN_OVERRIDE", "CSMITH_BASELINE"):
        if os.environ.get(key):
            raise ValueError("ambient override refused: " + key)
    parent = repo / ".tmp/fuel-measure-cost"
    parent.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix="cpu-", dir=parent))
    (run / "retained").mkdir()
    env = dict(os.environ, CERB_MEM_MAX="48G", SKIP_BUILD="1", LC_ALL="C",
               TIMEOUT_SECS=str(args.timeout), FC_REPO=str(repo), FC_RUN=str(run),
               CERB_OBSERVATION_DIR=str(run / "observations"))
    if overrides:
        env.update(overrides)
    command = [str(repo / "scripts/capped"), "bash", "-c", HOOK, "cpu-retention",
               str(repo / "scripts/test_csmith_corpus.sh"), "--check-baseline"]
    if args.shard:
        command += ["--shard", args.shard]
    if args.max:
        command += ["--max", str(args.max)]
    before = identity(repo)
    meta = before + ["command=" + shlex.join(command), "CERB_MEM_MAX=48G",
                     "TIMEOUT_SECS=" + str(args.timeout), "SKIP_BUILD=1",
                     "start_utc=" + checked(["date", "-u", "+%FT%TZ"]),
                     "start_uptime=" + checked(["uptime"]), "plant=" + str(bool(overrides))]
    (run / "run.meta.txt").write_text("\n".join(meta) + "\n")
    print("CPU run directory: " + str(run), flush=True)
    with (run / "lane.log").open("w") as log:
        proc = subprocess.Popen(command, cwd=repo, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout:
            log.write(line)
            log.flush()
            row = re.match(r"^\[(\d+)/(\d+)\] (\w+) (\S+)", line)
            if row and (int(row[1]) % 50 == 0 or row[1] == row[2]):
                print(f"CPU progress: {row[1]}/{row[2]} {row[3]} {row[4]}", flush=True)
            elif line.startswith(("Error:", "SUMMARY:", "REGRESSION:", "Baseline check:", "capped:")):
                print(line.rstrip(), flush=True)
        rc = proc.wait()
    (run / "lane.exit").write_text(str(rc) + "\n")
    if identity(repo) != before:
        raise ValueError("source/engine identities changed during timing")
    with (run / "run.meta.txt").open("a") as meta_file:
        meta_file.write("end_utc=" + checked(["date", "-u", "+%FT%TZ"]) + "\n")
        meta_file.write("end_uptime=" + checked(["uptime"]) + "\n")
    return run


def selftest(repo):
    print("PLANT MODE: CPU instrument selftest; no semantics evidence", flush=True)
    parent = repo / ".tmp/fuel-measure-cost"
    parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="selftest-", dir=parent) as temp:
        temp = Path(temp)
        fixture = temp / "known.time"
        fixture.write_text("\tUser time (seconds): 1.25\n\tSystem time (seconds): 0.75\n"
                           "\tElapsed (wall clock) time (h:mm:ss or m:ss): 1:02.50\n"
                           "\tMaximum resident set size (kbytes): 12345\n\tExit status: 124\n")
        assert rusage(fixture) == ("124", "62.50", "2.00", "12345")
        fixture.write_text("malformed rusage\n")
        try:
            rusage(fixture)
        except ValueError:
            pass
        else:
            raise AssertionError("malformed rusage accepted")
        stub = temp / "engine"
        stub.write_text('''#!/usr/bin/env python3
import sys, time
if "--cabs-json" in sys.argv:
    print("{}")
    sys.exit(0)
name = sys.argv[-1]
if "sa_csmith_002.c" in name:
    print('Error {msg: "CPU instrument plant refusal"}')
    sys.exit(1)
start = time.process_time()
budget = 2.0 if "sa_csmith_003.json" in name else 0.20
while time.process_time() - start < budget:
    pass
print('Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}')
''')
        stub.chmod(0o755)
        args = argparse.Namespace(timeout=1, shard=None, max=3)
        run = run_lane(repo, args, {"CERB_ORACLE_BIN_OVERRIDE": str(stub), "CERB_LEAN_BIN_OVERRIDE": str(stub)})
        rows = collect(run, temp / "plant.tsv")
        by_key = {(r[0], r[1]): r for r in rows}
        assert len(rows) == 6
        assert by_key["sa_csmith_001.c", "lean"][-1] == "MATCH"
        assert by_key["sa_csmith_002.c", "lean"][2:] == ("NA", "NA", "NA", "NA", "CERB_SKIP")
        assert by_key["sa_csmith_003.c", "lean"][2] == "124"
        assert by_key["sa_csmith_003.c", "lean"][-1] == "TIMEOUT"
        for engine in ("oracle", "lean"):
            cpu = float(by_key["sa_csmith_001.c", engine][4])
            assert 0.18 <= cpu <= 0.40, cpu
        (run / "retained/sa_csmith_001.lean.time").unlink()
        try:
            collect(run, temp / "invalid.tsv")
        except ValueError:
            pass
        else:
            raise AssertionError("missing executed-side rusage accepted")
    print("CPU instrument SELFTEST OK: exact rusage, real CPU stub, MATCH/CERB_SKIP/TIMEOUT, missing/malformed records refused")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", type=Path, default=ROOT, help="target checkout (own oracle, Lean and lane)")
    parser.add_argument("--output", type=Path, help="new output TSV; must not exist")
    parser.add_argument("--timeout", type=int, default=15)
    parser.add_argument("--shard", help="lane's K/M shard")
    parser.add_argument("--max", type=int, default=0, help="lane's first N inputs (470 = small_arrays)")
    parser.add_argument("--collect", type=Path, help="export a completed run without rerunning")
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.timeout < 1 or args.max < 0:
        parser.error("timeout must be positive and max nonnegative")
    if args.selftest:
        selftest(args.repo.resolve())
        return
    if not args.output:
        parser.error("--output is required")
    if args.output.exists() or args.output.with_suffix(".meta.txt").exists():
        parser.error("output evidence already exists; choose a new path")
    run = args.collect.resolve() if args.collect else run_lane(args.repo.resolve(), args)
    collect(run, args.output.resolve())


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit("CPU instrument ERROR: " + str(error))
