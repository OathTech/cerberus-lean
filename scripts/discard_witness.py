#!/usr/bin/env python3
"""discard_witness.py — the engine of scripts/check_attribute_carriage.sh and
scripts/check_discarded_constructs.sh (contract D19; record
lean_frontend/docs/2026-11-20_attribute-preservation-record.md).

A corpus directory holds one-file C programs and `expected.txt`, tab-separated rows
    <name> <class> <payload> [<payload2>]
Each program is copied to a scratch directory and run there under its bare name through BOTH engines:
the oracle (`--pp=ail --ast=ail`, `--cabs-json`, `--exec --batch`, all `--nolibc`) and the Lean engine on
the exported Cabs JSON (staged output for the attribute lines, `--batch` for the verdict). Classes:

  carried  (the oracle must reach the Ail dump and the Lean engine the typed Ail; the program need not have a
           `main`; an argument is one line whatever its layout in the source, since it is carried as tokens)
           payload = the attribute lines both engines must print, joined by ` ;; ` (`-` = none): the lines
           of cabs_to_ail.lem `show_attribute_carriage`, without the forced header's `cerb::hidden` ones.
           Both engines must print exactly these lines, in this order.
  exec     payload = the batch verdict line both engines must print (exit 0 on both).
  ub       payload = the `Undefined {ub: "..."` prefix both engines' verdict lines must start with.
  stop     payload = the oracle's first diagnostic line (exit 1); payload2 = the Lean engine's batch line.
  refusal  payload = the WHOLE refusal text: the oracle must print `internal error: <text>` and the Lean
           engine `PANIC at ... : <text>`, each ending the line; both exit nonzero.
  parse    payload = the oracle's first diagnostic line from `--cabs-json` (exit 1): no JSON, so the Lean
           engine has nothing to run.

`pristine.txt` (name, the pre-change answer) is the negative control: for every row it lists, the pinned
payload must DIFFER from pristine's (a witness that pristine also satisfies proves nothing), and the plant
`pristine` replays those answers as both engines' output and must fail exactly those rows.

Usage: discard_witness.py DIR [--core] [--selftest] [--derive]
  --core      only the names in DIR/core.txt (the row-1 cut)
  --selftest  plants, then the real run; --require-plants=a,b,... names the plants that must RUN (a plant with no
              row to touch is skipped, and a required plant that is skipped fails the selftest); default: all
  --derive    print a fresh expected table from the oracle to stdout (never writes; for review);
              --derive-exec pins accepted programs by their verdict line instead of their attribute lines
Fail-closed: a missing expectation, an unknown class, a file without a row, a row without a file, an empty
corpus, a missing engine each FAIL.
"""
import os, re, subprocess, sys, tempfile, shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORACLE = os.path.join(ROOT, "_build/default/backend/driver/main.exe")
PREFIX = os.path.join(ROOT, "_build/install/default")
LEAN = os.path.join(ROOT, "lean_frontend/.lake/build/bin/cerberus-lean")
PANIC = re.compile(r"^PANIC at \S+ \S+: ")


def run(cmd, cwd, env=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=env, timeout=120)


def first(lines, pred=lambda l: True):
    for l in lines:
        if l.strip() and pred(l):
            return l
    return ""


class Engines:
    """The two engines' observations of one program; `plant` doctors them (selftest)."""

    def __init__(self, scratch, plant=None, pristine=None):
        self.scratch, self.plant, self.pristine = scratch, plant, pristine or {}
        self.env = dict(os.environ, CERB_INSTALL_PREFIX=PREFIX, LEAN_ABORT_ON_PANIC="1")

    def oracle(self, name, *args):
        return run([ORACLE, "--runtime=" + PREFIX, "--nolibc", *args, name + ".c"], self.scratch)

    def observe(self, name):
        o = {}
        ail = self.oracle(name, "--pp=ail", "--ast=ail")
        o["ail_rc"] = ail.returncode
        o["oracle_attrs"] = [l[len("attribute: "):] for l in ail.stdout.splitlines()
                             if l.startswith("attribute: ") and "cerb::hidden" not in l]
        ex = self.oracle(name, "--exec", "--batch")
        o["oracle_rc"] = ex.returncode
        o["oracle_line"] = first((ex.stdout + "\n" + ex.stderr).splitlines(), lambda l: "Time spent" not in l)
        cj = self.oracle(name, "--cabs-json")
        o["parse_rc"] = cj.returncode
        o["parse_line"] = first(cj.stderr.splitlines())
        o["lean_attrs"], o["lean_rc"], o["lean_line"], o["lean_typed"] = [], None, "", False
        if cj.returncode == 0:
            with open(os.path.join(self.scratch, name + ".json"), "w") as f:
                f.write(cj.stdout)
            st = run([LEAN, name + ".json"], self.scratch, self.env)
            o["lean_typed"] = "typechecking succeeded" in st.stdout
            o["lean_attrs"] = [l.strip()[len("attribute: "):] for l in st.stdout.splitlines()
                               if l.strip().startswith("attribute: ") and "cerb::hidden" not in l]
            lb = run([LEAN, "--batch", name + ".json"], self.scratch, self.env)
            o["lean_rc"] = lb.returncode
            o["lean_line"] = first((lb.stdout + "\n" + lb.stderr).splitlines(), lambda l: "switches:" not in l)
        return o

    def doctor(self, name, o):
        p, o = self.plant, dict(o)
        if p == "pristine" and name in self.pristine:
            # both engines answer as pristine upstream did
            was = self.pristine[name]
            lines = [] if was == "-" else was.split(" ;; ")
            o["oracle_attrs"], o["lean_attrs"] = lines, list(lines)
            o["oracle_line"] = o["lean_line"] = was
            o["oracle_rc"] = o["lean_rc"] = o["ail_rc"] = 0
            o["parse_rc"], o["lean_typed"] = 0, True
        elif p == "lean-drops-carried":
            o["lean_attrs"] = [l for l in o["lean_attrs"] if not l.startswith("carried ")]
        elif p == "oracle-drops-carried":
            o["oracle_attrs"] = [l for l in o["oracle_attrs"] if not l.startswith("carried ")]
        elif p == "lean-fixed":
            o["lean_attrs"], o["lean_typed"] = [], True
            o["lean_line"] = 'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}'
            o["lean_rc"] = 0
        elif p == "args-truncated":
            # both engines' argument lists cut after their first token (a comparison that sees only the
            # start of an argument, as one reading a multi-line argument's first line would)
            cut = lambda l: re.sub(r"\((\S+) [^@]*\) @", r"(\1) @", l)
            o["oracle_attrs"] = [cut(l) for l in o["oracle_attrs"]]
            o["lean_attrs"] = [cut(l) for l in o["lean_attrs"]]
        elif p == "parse-accepted":
            # the oracle's parser lets the program through (as pristine does for `cerb::with_address` and
            # `#pragma pack`): a `parse` row must not hold
            o["parse_rc"] = 0
        elif p == "refusal-truncated":
            o["oracle_line"] = o["oracle_line"][:-12]
        return o


def check(row, o):
    """-> list of failure strings (empty = the row holds)."""
    cls, pay = row[1], row[2]
    bad = []
    if cls == "carried":
        want = [] if pay == "-" else pay.split(" ;; ")
        if o["ail_rc"] != 0:
            bad.append(f"the oracle did not reach the Ail dump (rc {o['ail_rc']})")
        if not o["lean_typed"]:
            bad.append("the Lean engine did not reach the typed Ail (no `typechecking succeeded` in its staged output)")
        if o["oracle_attrs"] != want:
            bad.append(f"oracle attribute lines {o['oracle_attrs']!r} != pinned {want!r}")
        if o["lean_attrs"] != want:
            bad.append(f"Lean attribute lines {o['lean_attrs']!r} != pinned {want!r}")
    elif cls == "exec":
        for who in ("oracle", "lean"):
            if o[who + "_line"] != pay or o[who + "_rc"] != 0:
                bad.append(f"{who} line {o[who + '_line']!r} (rc {o[who + '_rc']}) != pinned {pay!r} (rc 0)")
    elif cls == "ub":
        for who in ("oracle", "lean"):
            if not o[who + "_line"].startswith(pay):
                bad.append(f"{who} line {o[who + '_line']!r} does not start with {pay!r}")
    elif cls == "stop":
        if o["oracle_rc"] != 1 or o["oracle_line"] != pay:
            bad.append(f"oracle line {o['oracle_line']!r} (rc {o['oracle_rc']}) != pinned {pay!r} (rc 1)")
        want = row[3] if len(row) > 3 else None
        if want is None:
            bad.append("a stop row needs the Lean engine's line as a fourth field")
        elif o["lean_rc"] in (0, None) or o["lean_line"] != want:
            bad.append(f"Lean line {o['lean_line']!r} (rc {o['lean_rc']}) != pinned {want!r} (rc nonzero)")
    elif cls == "refusal":
        if o["oracle_rc"] == 0 or o["oracle_line"] != "internal error: " + pay:
            bad.append(f"oracle line is not `internal error: <the pinned text>`: {o['oracle_line']!r}")
        ll = o["lean_line"]
        if o["lean_rc"] in (0, None) or not PANIC.match(ll) or PANIC.sub("", ll) != pay:
            bad.append(f"Lean line is not `PANIC at ...: <the pinned text>`: {ll!r}")
    elif cls == "parse":
        if o["parse_rc"] != 1 or o["parse_line"] != pay:
            bad.append(f"oracle --cabs-json line {o['parse_line']!r} (rc {o['parse_rc']}) != pinned {pay!r} (rc 1)")
    else:
        bad.append(f"unknown class {cls!r}")
    return bad


def derive(o, as_exec=False):
    if o["parse_rc"] != 0:
        return ["parse", o["parse_line"]]
    if o["ail_rc"] == 0 and not as_exec:
        return ["carried", " ;; ".join(o["oracle_attrs"]) or "-"]
    if o["oracle_rc"] == 0:
        return ["exec", o["oracle_line"]]
    if o["oracle_line"].startswith("internal error: "):
        return ["refusal", o["oracle_line"][len("internal error: "):]]
    if o["oracle_line"].startswith("Undefined {ub:"):
        return ["ub", o["oracle_line"].split(",")[0]]
    return ["stop", o["oracle_line"], o["lean_line"]]


def read_table(path, need=2):
    rows = {}
    if not os.path.exists(path):
        return rows
    for n, line in enumerate(open(path), 1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        f = line.split("\t")
        if len(f) < need or f[0] in rows:
            sys.exit(f"discard_witness: FAIL — {path}:{n}: malformed or duplicate row")
        rows[f[0]] = f
    return rows


def observe_all(d, names):
    """Run both engines once on every program (the plants doctor these observations, not the engines)."""
    scratch = tempfile.mkdtemp(prefix="discard-witness.", dir=os.path.join(ROOT, ".tmp"))
    try:
        eng = Engines(scratch)
        obs = {}
        for n in names:
            shutil.copy(os.path.join(d, n + ".c"), scratch)
            obs[n] = eng.observe(n)
        return obs
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


def one_run(obs, names, expected, pristine, plant=None, quiet=False):
    eng = Engines(None, plant, {k: v[1] for k, v in pristine.items()})
    failed = {}
    for n in names:
        bad = check(expected[n], eng.doctor(n, obs[n]))
        if bad:
            failed[n] = bad
            if not quiet:
                print(f"  FAIL {n} [{expected[n][1]}]")
                for b in bad:
                    print(f"       {b}")
    return failed


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    d = os.path.abspath(args[0])
    name = "discard_witness(" + os.path.basename(d) + ")"
    core, selftest, der = "--core" in args, "--selftest" in args, "--derive" in args or "--derive-exec" in args
    os.makedirs(os.path.join(ROOT, ".tmp"), exist_ok=True)
    for exe in (ORACLE, LEAN):
        if not os.access(exe, os.X_OK):
            sys.exit(f"{name}: FAIL — engine missing: {exe}")
    files = sorted(f[:-2] for f in os.listdir(d) if f.endswith(".c"))
    if not files:
        sys.exit(f"{name}: FAIL — empty corpus")
    if der:
        scratch = tempfile.mkdtemp(prefix="discard-witness.", dir=os.path.join(ROOT, ".tmp"))
        try:
            eng = Engines(scratch)
            for n in files:
                shutil.copy(os.path.join(d, n + ".c"), scratch)
                print("\t".join([n] + derive(eng.observe(n), "--derive-exec" in args)))
        finally:
            shutil.rmtree(scratch, ignore_errors=True)
        return
    expected = read_table(os.path.join(d, "expected.txt"), 3)
    pristine = read_table(os.path.join(d, "pristine.txt"), 2)
    missing = [n for n in files if n not in expected]
    extra = [n for n in expected if n not in files]
    if missing or extra:
        sys.exit(f"{name}: FAIL — files without a row: {missing}; rows without a file: {extra}")
    if not pristine:
        sys.exit(f"{name}: FAIL — no negative control (pristine.txt is empty or absent)")
    for n, row in pristine.items():
        if n not in expected:
            sys.exit(f"{name}: FAIL — pristine.txt names {n}, which has no expectation")
        if row[1] == expected[n][2]:
            sys.exit(f"{name}: FAIL — {n}: the pinned answer equals pristine's (the row is no witness of the change)")
    names = files
    if core:
        names = [l.strip() for l in open(os.path.join(d, "core.txt")) if l.strip() and not l.startswith("#")]
        unknown = [n for n in names if n not in expected]
        if unknown or not names:
            sys.exit(f"{name}: FAIL — core.txt is empty or names unknown programs: {unknown}")
        pristine = {n: r for n, r in pristine.items() if n in names}
        if not pristine:
            sys.exit(f"{name}: FAIL — the core cut holds no negative-control row")
    obs = observe_all(d, names)
    if selftest:
        print(f"{name}: SELFTEST — plants doctor the engines' recorded observations (nothing in the tree is touched)")
        multi = [n for n in names if expected[n][1] == "carried" and re.search(r"\(\S+ [^@]*\) @", expected[n][2])]
        table = [n for n in names if expected[n][1] == "carried" and "carried " in expected[n][2]]
        plants = {
            "pristine": ("exact", sorted(n for n in pristine if n in names)),
            "lean-drops-carried": ("all", table),
            "oracle-drops-carried": ("all", table),
            "args-truncated": ("all", multi),
            "lean-fixed": ("some", None),
            "refusal-truncated": ("all", [n for n in names if expected[n][1] == "refusal"]),
            "parse-accepted": ("all", [n for n in names if expected[n][1] == "parse"]),
        }
        required = [a.split("=", 1)[1].split(",") for a in args if a.startswith("--require-plants=")]
        required = required[0] if required else list(plants)
        unknown = [p for p in required if p not in plants]
        if unknown:
            sys.exit(f"{name}: FAIL — unknown plant(s) required: {unknown}")
        ok, ran, skipped = True, 0, []
        for p, (mode, rows) in plants.items():
            if mode != "some" and not rows:
                # a plant with no row to touch proves nothing: it is SKIPPED, never counted as caught
                skipped.append(p)
                good = p not in required
                print(f"  PLANT {'SKIPPED' if good else 'REQUIRED BUT SKIPPED'} [{p}] no row of this corpus for it to touch")
                ok = ok and good
                continue
            failed = one_run(obs, names, expected, pristine, plant=p, quiet=True)
            ran += 1
            if mode == "exact":
                good, what = sorted(failed) == rows, f"fails exactly the {len(rows)} negative-control rows"
            elif mode == "all":
                good, what = all(n in failed for n in rows), f"fails all {len(rows)} rows it touches"
            else:
                good, what = len(failed) > 0, f"fails {len(failed)} rows"
            print(f"  PLANT {'OK ' if good else 'NOT CAUGHT'} [{p}] {what}")
            ok = ok and good
        if not ok:
            sys.exit(f"{name}: SELFTEST FAILED")
        print(f"{name}: SELFTEST OK ({ran} plants ran and were caught; {len(skipped)} skipped: {', '.join(skipped) or 'none'})")
    failed = one_run(obs, names, expected, pristine)
    by = {}
    for n in names:
        by[expected[n][1]] = by.get(expected[n][1], 0) + 1
    tally = ", ".join(f"{k} {v}" for k, v in sorted(by.items()))
    if failed:
        sys.exit(f"{name}: FAIL — {len(failed)} of {len(names)} rows")
    print(f"{name}: OK — {len(names)} programs on both engines ({tally}); {len([n for n in pristine if n in names])} "
          f"negative-control rows differ from pristine")


if __name__ == "__main__":
    main()
