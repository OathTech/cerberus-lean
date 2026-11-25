#!/usr/bin/env python3
"""impl_profile_witness.py -- the engine of scripts/check_impl_profile.sh (contract D20;
record lean_frontend/docs/2026-11-22_impl-profile-record.md).

The implementation profile is a property of the RUN on each engine: `--impl-profile=default`
is upstream's DefaultImpl (plain char signed), `--impl-profile=hafnium` upstream's HafniumImpl
(plain char unsigned). It is read by the desugarer's constant evaluation, Ail typing, the
elaboration, Core's signedness tests, the integer ranges and the memory model's store and
load. It is NOT read by the preprocessor (the host's `cc -E`) or the parser, so the Cabs JSON
export is the same under every profile. This lane is the ONLY validation of the second
profile.

PREREQUISITE: gcc on the path. The pinned lines are gcc's answers and are re-derived from gcc
on every run; without gcc the lane FAILS (it never skips).

For every program of tests/impl_profile/ and BOTH profiles:
  oracle : main.exe --exec --batch --impl-profile=P            (exhaustive)
  Lean   : main.exe --cabs-json, then
           cerberus-lean --batch --impl-profile=P               (exhaustive)
  gcc    : gcc -std=c11 -w -O0 -funsigned-char (hafnium) / -fsigned-char (default)
and the document exported with `--impl-profile=hafnium` must equal the one exported with
`--impl-profile=default` byte for byte.

expected.tsv: name TAB mode(nolibc|libc) TAB kind TAB A TAB B [TAB C TAB D]   (newline as \\n)
  kind gcc : A = the verdict under hafnium, B = under default: BOTH engines must print it,
             byte for byte with equal exit codes, and it must be gcc's line live:
             `Defined {value: "Specified(<rc>)", stdout: "<stdout>", stderr: "", blocked: "false"}`.
  kind stop: A = the oracle's verdict, B = the Lean engine's, under either profile (bit-fields
             are not supported by upstream; the profile is not reached).
  kind host: the preprocessor row. A, B = both engines' verdict under hafnium, default;
             C, D = gcc's line under -funsigned-char, -fsigned-char, the DECLARED DIFFERENCE:
             `#if` arithmetic on a character constant is the host preprocessor's (C17
             6.10.1#4 lets it differ from the same expression elsewhere), and the limit
             macros are identifiers there. The engines must agree with each other at A, B;
             gcc must still print C, D; and C must differ from A (or the row shows nothing).

Refusals: an unknown selector on each engine (exit 2), a repeated selector on each, Core
quotation under hafnium, and `--impl-profile=hafnium` on the VIP driver (exit 2: a non-default
profile is accepted under the concrete memory model only; the default is the control).

Negative control: tests/impl_profile/pristine_hafnium.tsv records what PRISTINE upstream
c3ff8c53f answers under HafniumImpl, driven through its library as RefinedC drives it
(tests/impl_profile/pristine_probe.ml; recorded 2026-11-22): a crash in the concrete memory
model's store on every program that stores a plain char above 127, and one silently mixed
answer. `--pristine-live PREFIX` re-derives the file's lines from a pristine installation
(optional; needs ocamlfind and that installation).

The libc leg: the oracle's libc object and the Lean engine's libc dump are built once, under
the default profile; every run checks that the 12 libc sources elaborate (`--pp=core`, without
`--sequentialise --rewrite`) to the same Core text under both profiles.

--selftest = the plants, then the verdict. All but one TAMPER WITH RECORDED OBSERVATIONS in
memory (no engine is rebuilt): engines replaying pristine, an engine's hafnium verdict replaced
by its own default one, tampered pins, exit codes and gcc answers, a refusal accepted. ONE
runs the engines: `live-ignored` executes the oracle and the Lean driver with the selector
OMITTED on every nolibc gcc row and feeds those runs in as the hafnium observations.
--derive prints the gcc-pinned rows for expected.tsv (the pins come from gcc, never from the
engines). Fail-closed: a missing tool, an unlisted or unpinned program are failures."""
import concurrent.futures
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORACLE = os.path.join(ROOT, "_build/default/backend/driver/main.exe")
PREFIX = os.path.join(ROOT, "_build/install/default")
LEAN = os.path.join(ROOT, "lean_frontend/.lake/build/bin/cerberus-lean")
CORPUS = os.path.join(ROOT, "tests/impl_profile")
PROFILES = ("hafnium", "default")
GCC_FLAG = {"hafnium": "-funsigned-char", "default": "-fsigned-char"}
# $GCC_BIN if set, else the first gcc on the path: the one rule of every lane that runs gcc.
GCC = shutil.which(os.environ.get("GCC_BIN") or "gcc")
GCC = os.path.abspath(GCC) if GCC else GCC   # the compile runs in a scratch directory
VIP = os.path.join(ROOT, "_build/default/backend/driver/main_vip.exe")
LIBC_TUS = "ctype stdio stdlib string time utime unistd stat uio internal vfscanf signal".split()
ENV = dict(os.environ, CERB_INSTALL_PREFIX=PREFIX, LEAN_ABORT_ON_PANIC="1")


def die(msg):
    print("check_impl_profile: FAIL -- " + msg)
    sys.exit(1)


def run(cmd, cwd, timeout=300):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=ENV, timeout=timeout)


def enc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n")


def dec(s):
    out, i = [], 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            out.append("\n" if s[i + 1] == "n" else s[i + 1])
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def verdict(proc, drop):
    """An engine's verdict: its whole stdout (a batch line may hold newlines), or, when it
    printed nothing there, its first diagnostic line on stderr."""
    out = proc.stdout.rstrip("\n")
    if out:
        return out
    for l in proc.stderr.splitlines():
        if l.strip() and drop not in l:
            return l
    return ""


def read_rows():
    rows = []
    with open(os.path.join(CORPUS, "expected.tsv")) as f:
        for n, l in enumerate(f, 1):
            if not l.strip() or l.startswith("#"):
                continue
            c = l.rstrip("\n").split("\t")
            if c[1:2] not in (["nolibc"], ["libc"]) or c[2:3] not in (["gcc"], ["stop"], ["host"]) \
                    or len(c) != (7 if c[2] == "host" else 5):
                die(f"expected.tsv:{n}: malformed row")
            rows.append(dict(name=c[0], mode=c[1], kind=c[2], a=dec(c[3]), b=dec(c[4]),
                             gcc_a=dec(c[5]) if c[2] == "host" else None, gcc_b=dec(c[6]) if c[2] == "host" else None))
    names = [r["name"] for r in rows]
    if len(set(names)) != len(names):
        die("expected.tsv: duplicate program")
    on_disk = sorted(f[:-2] for f in os.listdir(CORPUS) if f.endswith(".c"))
    if sorted(names) != on_disk:
        die(f"expected.tsv rows != tests/impl_profile/*.c (both directions): {sorted(set(names) ^ set(on_disk))}")
    return rows


def pin(row, profile, engine):
    if row["kind"] == "stop":
        return row["a"] if engine == "oracle" else row["b"]
    return row["a"] if profile == "hafnium" else row["b"]


def gcc_line(scratch, name, profile):
    exe = os.path.join(scratch, f"{name}.{profile}.gcc")
    c = run([GCC, "-std=c11", "-w", "-O0", GCC_FLAG[profile], "-o", exe, name + ".c"], scratch)
    if c.returncode != 0:
        return "GCC-COMPILE-FAILED: " + (c.stderr.splitlines() or [""])[0]
    r = subprocess.run([exe], cwd=scratch, capture_output=True, timeout=60)
    # the batch line escapes its stdout field; these programs print ASCII and newlines only
    out = r.stdout.decode("latin-1").replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')
    return f'Defined {{value: "Specified({r.returncode})", stdout: "{out}", stderr: "", blocked: "false"}}'


def libc_args(scratch):
    """The Lean driver's libc mode: the pinned Core dump and the 12 metadata translation
    units (one export: a Cabs document is the same under every profile)."""
    d = os.path.join(scratch, "libc_tus")
    os.makedirs(d, exist_ok=True)
    args = ["--libc", os.path.join(ROOT, "tests/libc/libc.core")]
    for tu in LIBC_TUS:
        out = os.path.join(d, f"libc_{tu}.json")
        p = run([ORACLE, "--runtime=_build/install/default", "--nolibc", "--cabs-json",
                 "-I", "runtime/libc/include", "-I", "runtime/libc/include/posix", f"runtime/libc/src/{tu}.c"], ROOT)
        if p.returncode != 0 or not p.stdout:
            die(f"libc metadata export failed for {tu}.c: {p.stderr[:200]}")
        with open(out, "w") as f:
            f.write(p.stdout)
        args += ["--libc-tu", out]
    return args


def observe(scratch, row, profile, libc):
    name, nolibc = row["name"], (["--nolibc"] if row["mode"] == "nolibc" else [])
    sel = "--impl-profile=" + profile
    o = {}
    ex = run([ORACLE, "--runtime=" + PREFIX, *nolibc, "--exec", "--batch", sel, name + ".c"], scratch)
    o["oracle"], o["oracle_rc"] = verdict(ex, "Time spent"), ex.returncode
    cj = run([ORACLE, "--runtime=" + PREFIX, *nolibc, "--cabs-json", sel, name + ".c"], scratch)
    o["export_rc"] = cj.returncode
    o["lean"], o["lean_rc"] = "", None
    if cj.returncode == 0:
        doc = os.path.join(scratch, f"{name}.{profile}.json")
        with open(doc, "w") as f:
            f.write(cj.stdout)
        o["export"] = cj.stdout
        # libc mode runs from the repository root: the metadata translation units carry
        # root-relative library positions (the canonical export convention, libc_prep.sh)
        if row["mode"] == "libc":
            lb = run([LEAN, "--batch", sel, *libc, doc], ROOT)
        else:
            lb = run([LEAN, "--batch", sel, doc], scratch)
        o["lean"], o["lean_rc"] = verdict(lb, "switches:"), lb.returncode
    else:
        o["lean"] = "NO-JSON: " + verdict(cj, "Time spent")
    if row["kind"] in ("gcc", "host"):
        o["gcc"] = gcc_line(scratch, name, profile)
    return o


def observe_ignored(scratch, row):
    """Both engines run for real with the selector OMITTED (the live plant)."""
    name = row["name"]
    ex = run([ORACLE, "--runtime=" + PREFIX, "--nolibc", "--exec", "--batch", name + ".c"], scratch)
    lb = run([LEAN, "--batch", os.path.join(scratch, f"{name}.hafnium.json")], scratch)
    return verdict(ex, "Time spent"), verdict(lb, "switches:")


def refusals(scratch, probe):
    """The selector's refusals. Each: (rc, text)."""
    r = {}
    doc = os.path.join(scratch, f"{probe}.default.json")

    def lean(*args):
        p = run([LEAN, "--batch", *args], scratch)
        return (p.returncode, p.stdout + p.stderr)

    def oracle(exe, *args):
        p = run([exe, "--runtime=" + PREFIX, "--nolibc", "--exec", "--batch", *args, probe + ".c"], scratch)
        return (p.returncode, p.stdout + p.stderr)

    r["lean-unknown-selector"] = lean("--impl-profile=morello", doc)
    r["lean-repeated-selector"] = lean("--impl-profile=hafnium", "--impl-profile", "default", doc)
    r["lean-quotation-under-hafnium"] = lean("--impl-profile=hafnium", "--quote-core", os.path.join(scratch, "Quoted.lean"), doc)
    r["oracle-unknown-selector"] = oracle(ORACLE, "--impl-profile=morello")
    r["oracle-repeated-selector"] = oracle(ORACLE, "--impl-profile=hafnium", "--impl-profile=default")
    r["vip-driver-hafnium"] = oracle(VIP, "--impl-profile=hafnium")
    r["vip-driver-default-control"] = oracle(VIP, "--impl-profile=default")
    return r


# (name, required exit code, required text)
REFUSAL_SPEC = [
    ("lean-unknown-selector", 2, "--impl-profile=morello: unknown implementation profile"),
    ("lean-repeated-selector", 2, "option --impl-profile cannot be repeated"),
    ("lean-quotation-under-hafnium", 2, "refused \u2014 Core quotation under --impl-profile=hafnium"),
    ("oracle-unknown-selector", 2, "--impl-profile=morello is refused: unknown implementation profile"),
    ("oracle-repeated-selector", 124, "cannot be repeated"),
    ("vip-driver-hafnium", 2, "--impl-profile=hafnium is refused under the memory model 'VIP memory model'"),
]


def check(rows, obs, ref, pristine):
    """-> list of (row-or-check name, message). Empty = green."""
    bad = []
    for row in rows:
        for profile in PROFILES:
            o, where = obs[(row["name"], profile)], f"{row['name']} [{profile}]"
            for engine in ("oracle", "lean"):
                want = pin(row, profile, engine)
                if o[engine] != want:
                    bad.append((where, f"{engine} != pinned line\n      got : {enc(o[engine])[:200]}\n      want: {enc(want)[:200]}"))
            if o["oracle_rc"] != o["lean_rc"]:
                bad.append((where, f"exit codes differ: oracle {o['oracle_rc']}, lean {o['lean_rc']}"))
            if row["kind"] == "gcc" and o["gcc"] != pin(row, profile, "oracle"):
                bad.append((where, f"pinned line != gcc {GCC_FLAG[profile]} live\n      gcc : {enc(o['gcc'])[:200]}"))
            if row["kind"] == "host":
                want = row["gcc_a"] if profile == "hafnium" else row["gcc_b"]
                if o["gcc"] != want:
                    bad.append((where, f"recorded gcc line != gcc {GCC_FLAG[profile]} live\n      gcc : {enc(o['gcc'])[:200]}"))
        if row["kind"] == "host" and row["gcc_a"] == row["a"]:
            bad.append((row["name"], "the preprocessor row's gcc line equals the engines' under hafnium: it declares no difference"))
        if obs[(row["name"], "hafnium")].get("export") != obs[(row["name"], "default")].get("export"):
            bad.append((row["name"] + " [export]", "the Cabs JSON exported under hafnium differs from the one exported under default"))
    for name, rc, text in REFUSAL_SPEC:
        got_rc, got = ref[name]
        if got_rc != rc or text not in got:
            bad.append(("refusal " + name, f"want exit {rc} and the text {text!r}; got exit {got_rc}: {got.strip()[:160]}"))
    # the VIP driver under the default profile runs, and answers as the concrete driver does
    crc, ctext = ref["vip-driver-default-control"]
    if ref["probe-verdict"] not in ctext:
        bad.append(("refusal vip-driver-default-control", f"the VIP driver under the default profile did not print the probe's verdict (exit {crc}): {ctext.strip()[:160]}"))
    # the recorded pristine observations must show the defect the fix removes (static, every run)
    hp = {r["name"]: r for r in rows}
    differing = [n for n, line in pristine.items() if n in hp and hp[n]["kind"] == "gcc" and line != pin(hp[n], "hafnium", "oracle")]
    crashes = [n for n in differing if "bytes_of_int(signed)" in pristine[n]]
    if not crashes or len(differing) == len(crashes):
        bad.append(("pristine control", "pristine_hafnium.tsv must record at least one store crash and one silently mixed answer"))
    return bad


def read_pristine():
    out = {}
    with open(os.path.join(CORPUS, "pristine_hafnium.tsv")) as f:
        for l in f:
            if l.strip() and not l.startswith("#"):
                n, v = l.rstrip("\n").split("\t")
                out[n] = dec(v)
    if len(out) < 10:
        die("pristine_hafnium.tsv: fewer than 10 recorded observations (vacuity guard)")
    return out


def pristine_live(prefix, rows, recorded):
    """Re-derive pristine's verdict under HafniumImpl through its installed library."""
    def front(var, d):  # the pristine library first, the ambient switch's own paths kept
        return d + (os.pathsep + os.environ[var] if os.environ.get(var) else "")
    env = dict(os.environ, OCAMLPATH=front("OCAMLPATH", os.path.join(prefix, "lib")),
               CAML_LD_LIBRARY_PATH=front("CAML_LD_LIBRARY_PATH", os.path.join(prefix, "lib/stublibs")),
               CERB_INSTALL_PREFIX=prefix)
    bad = 0
    for row in rows:
        if row["name"] not in recorded:
            continue
        p = subprocess.run(["ocaml", os.path.join(CORPUS, "pristine_probe.ml"), "hafnium", row["name"] + ".c"],
                           cwd=CORPUS, capture_output=True, text=True, env=env, timeout=300)
        lines = [l for l in (p.stdout + "\n" + p.stderr).splitlines() if l.strip() and not l.startswith("profile selected")]
        got = next((l for l in lines if l.startswith("Defined ")), None) or next((l for l in lines if l.startswith("failed:")), None) or (lines or [""])[0]
        ok = got == recorded[row["name"]]
        bad += not ok
        print(f"  {'OK  ' if ok else 'FAIL'} pristine-live {row['name']}: {got[:150]}")
    if bad:
        die(f"{bad} recorded pristine observation(s) differ from the live pristine library at {prefix}")
    print(f"check_impl_profile: pristine-live OK ({len(recorded)} recorded observations re-derived from {prefix})")


def libc_identity(scratch):
    """The oracle's libc object and the Lean engine's libc dump are built once, under the
    default profile. They are used under hafnium on the strength of this measurement: every
    libc source elaborates to the same Core text under both profiles."""
    total = 0
    for tu in LIBC_TUS:
        texts = []
        for profile in PROFILES:
            p = run([ORACLE, "--runtime=_build/install/default", "--impl-profile=" + profile, "--nolibc", "--pp=core",
                     "-I", "runtime/libc/include", "-I", "runtime/libc/include/posix", f"runtime/libc/src/{tu}.c"], ROOT)
            if p.returncode != 0 or not p.stdout:
                die(f"libc elaboration failed for {tu}.c under {profile}: {p.stderr[:200]}")
            texts.append(p.stdout)
        if texts[0] != texts[1]:
            die(f"libc source {tu}.c elaborates to DIFFERENT Core under the two profiles: the default-built libc cannot stand for hafnium's")
        total += texts[0].count("\n")
    return total


def main():
    args = sys.argv[1:]
    selftest, derive = "--selftest" in args, "--derive" in args
    unknown = [a for i, a in enumerate(args) if a not in ("--selftest", "--derive", "--pristine-live")
               and not (i > 0 and args[i - 1] == "--pristine-live")]
    if unknown:
        die(f"unknown argument(s): {unknown}")
    live = args[args.index("--pristine-live") + 1] if "--pristine-live" in args else None
    for tool in (ORACLE, LEAN, VIP):
        if not os.path.exists(tool):
            die(f"missing {tool} (build both engines and cerberus.install first)")
    if not GCC:
        die("gcc not found (GCC_BIN, else gcc on the path): the pinned lines are checked against gcc -funsigned-char / -fsigned-char on every run")
    rows = read_rows() if not derive else [
        dict(name=f[:-2], mode="libc" if f.startswith("libc_") else "nolibc", kind="gcc", a="", b="")
        for f in sorted(os.listdir(CORPUS)) if f.endswith(".c")]
    pristine = read_pristine() if not derive else {}
    if len(rows) < 10:
        die(f"only {len(rows)} programs (vacuity guard)")
    os.makedirs(os.path.join(ROOT, ".tmp"), exist_ok=True)
    scratch = tempfile.mkdtemp(prefix="impl-profile.", dir=os.path.join(ROOT, ".tmp"))
    try:
        for f in os.listdir(CORPUS):
            if f.endswith(".c"):
                shutil.copy(os.path.join(CORPUS, f), scratch)
        if derive:
            for row in rows:
                print("\t".join([row["name"], row["mode"], "gcc"] + [enc(gcc_line(scratch, row["name"], p)) for p in PROFILES]))
            return
        libc = libc_args(scratch) if any(r["mode"] == "libc" for r in rows) else []
        jobs = [(r, p) for r in rows for p in PROFILES]
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
            results = list(ex.map(lambda j: observe(scratch, j[0], j[1], libc), jobs))
        obs = {(r["name"], p): o for (r, p), o in zip(jobs, results)}
        probe = next(r["name"] for r in rows if r["kind"] == "gcc" and r["mode"] == "nolibc")
        ref = refusals(scratch, probe)
        ref["probe-verdict"] = obs[(probe, "default")]["oracle"]
        libc_lines = libc_identity(scratch)
        if live:
            pristine_live(live, rows, pristine)

        if selftest:
            fail = nplants = 0
            moved = sorted(r["name"] for r in rows if r["kind"] in ("gcc", "host") and r["a"] != r["b"])
            pr = sorted(n for n in pristine if any(r["name"] == n and r["kind"] == "gcc" for r in rows)
                        and pristine[n] != pin(next(r for r in rows if r["name"] == n), "hafnium", "oracle"))

            def plant(label, expect, obs2=None, ref2=None, rows2=None):
                nonlocal fail, nplants
                nplants += 1
                bad = check(rows2 or rows, obs2 or obs, ref2 or ref, pristine)
                got = sorted({w.split(" [")[0] for w, _ in bad})
                ok = got == sorted(expect) and bool(expect)
                fail += not ok
                print(f"  {'PLANT OK  ' if ok else 'PLANT FAIL'} [{label}] -> RED on {len(got)} row(s)" + ("" if ok else f": got {got}, want {sorted(expect)}"))

            def swap(engines, source):
                o2 = {k: dict(v) for k, v in obs.items()}
                for (n, p), o in o2.items():
                    if p == "hafnium":
                        for e in engines:
                            s = source(n, e)
                            if s is not None:
                                o[e] = s
                return o2
            gccrow = {r["name"] for r in rows if r["kind"] == "gcc"}
            plant("pristine-pair: both engines answer as pristine upstream under HafniumImpl", pr,
                  swap(("oracle", "lean"), lambda n, e: pristine.get(n) if n in gccrow else None))
            plant("lean-default: the Lean engine ignores the selector", moved, swap(("lean",), lambda n, e: obs[(n, "default")]["lean"]))
            plant("oracle-default: the oracle ignores the selector", moved, swap(("oracle",), lambda n, e: obs[(n, "default")]["oracle"]))
            t = rows[0]["name"]
            rows2 = [dict(r, a=r["a"].replace("Specified(", "Specified(1", 1)) if r["name"] == t else r for r in rows]
            plant("expect-tamper: one pinned line altered", [t], rows2=rows2)
            o2 = {k: dict(v) for k, v in obs.items()}
            o2[(t, "hafnium")]["oracle_rc"] = 99
            plant("oracle-rc: one exit code forced", [t], o2)
            o2 = {k: dict(v) for k, v in obs.items()}
            o2[(t, "default")]["gcc"] = o2[(t, "default")]["gcc"].replace("Specified(", "Specified(7", 1)
            plant("gcc-tamper: gcc's live answer differs from the pin", [t], o2)
            o2 = {k: dict(v) for k, v in obs.items()}
            o2[(t, "hafnium")]["export"] = o2[(t, "hafnium")]["export"] + " "
            plant("export-differs: the Cabs export depends on the profile", [t], o2)
            # the one plant that RUNS the engines: the selector omitted on every nolibc gcc row
            live_rows = [r for r in rows if r["kind"] == "gcc" and r["mode"] == "nolibc"]
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
                live = dict(zip([r["name"] for r in live_rows], ex.map(lambda r: observe_ignored(scratch, r), live_rows)))
            o2 = {k: dict(v) for k, v in obs.items()}
            for n, (ov, lv) in live.items():
                o2[(n, "hafnium")]["oracle"], o2[(n, "hafnium")]["lean"] = ov, lv
            plant(f"live-ignored: both engines RUN with the selector omitted on the {len(live_rows)} nolibc gcc rows",
                  sorted(r["name"] for r in live_rows if r["a"] != r["b"]), o2)
            for name, _, _ in REFUSAL_SPEC:
                r2 = dict(ref)
                r2[name] = (0, obs[(probe, "default")]["lean"])
                plant(f"refusal-accepted: {name} runs instead of refusing", ["refusal " + name], ref2=r2)
            r2 = dict(ref)
            r2["vip-driver-default-control"] = ref["vip-driver-hafnium"]
            plant("vip-control: the VIP driver refuses the default profile too", ["refusal vip-driver-default-control"], ref2=r2)
            if fail:
                die(f"SELFTEST: {fail} plant(s) not caught as declared")
            print(f"check_impl_profile: SELFTEST OK ({nplants} plants red on exactly the declared rows; the pristine-pair plant fails {len(pr)} rows, the selector-ignored plants {len(moved)})")

        bad = check(rows, obs, ref, pristine)
        for w, m in bad:
            print(f"  FAIL {w}: {m}")
        if bad:
            die(f"{len(bad)} finding(s)")
        ngcc = sum(r["kind"] == "gcc" for r in rows)
        nlibc = sum(r["mode"] == "libc" for r in rows)
        moved = sum(r["kind"] == "gcc" and r["a"] != r["b"] for r in rows)
        print(f"check_impl_profile: OK ({len(rows)} programs x 2 profiles, both engines exhaustive; "
              f"{ngcc} gcc-pinned ({nlibc} in libc mode): oracle = Lean = gcc -funsigned-char under hafnium and = gcc -fsigned-char under default, "
              f"byte for byte, exit codes equal, {moved} with different answers under the two profiles; "
              f"{sum(r['kind'] == 'stop' for r in rows)} refusal row identical under both; {sum(r['kind'] == 'host' for r in rows)} preprocessor row "
              f"(the engines agree with each other, gcc's line the declared difference); every Cabs export identical under the two profiles; "
              f"{len(REFUSAL_SPEC)} refusals (unknown and repeated selector on each engine, quotation under hafnium, hafnium on the VIP driver); "
              f"pristine c3ff8c53f under HafniumImpl recorded for {len(pristine)} programs (the negative control)"
              f"; the {len(LIBC_TUS)} libc sources elaborate to identical Core under both profiles ({libc_lines} lines))")
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    main()
