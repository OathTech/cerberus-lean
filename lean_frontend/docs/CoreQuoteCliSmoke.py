"""D2 CLI checks; run from the repository root after preparing metadata/tu JSONs.

These check flag routing, literal elaboration and refusal/output behaviour.
They do not implement D3's independent whole-file representation comparison.
"""
import os
from pathlib import Path
import shutil
import subprocess

root = Path.cwd()
out = root / ".tmp/core-quote-d2"
frontend = root / "lean_frontend"
runtime = root / "_build/install/default"
exe = frontend / ".lake/build/bin/cerberus-lean"
fixture = root / "tests/fixtures/001-return-literal/cabs.json"
env = dict(os.environ, LEAN_ABORT_ON_PANIC="1")
paths = (out / "libc-json-paths.txt").read_text().splitlines()
assert len(paths) == 12 and all(Path(p).is_file() for p in paths)
libc = ["--libc", root / "tests/libc/libc.core"]
for path in paths:
    libc += ["--libc-tu", path]


def run(label, args, expected=0, cwd=root):
    command = ["/usr/bin/time", "-f", "%e seconds; %M KB peak RSS; exit %x",
               "-o", out / (label + ".time"), root / "scripts/capped", *args]
    result = subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True)
    (out / (label + ".stdout")).write_text(result.stdout)
    (out / (label + ".stderr")).write_text(result.stderr)
    assert result.returncode == expected, (label, result.returncode, result.stdout, result.stderr)
    print(label, (out / (label + ".time")).read_text().strip(), flush=True)
    return result


def cli(label, args, expected=0, prefix=runtime):
    return run(label, [exe, "--runtime", prefix, "--fuel", "1000000", *args], expected)


def elaborate(name):
    path = out / (name + ".lean")
    text = path.read_text()
    assert text.startswith("import Core_run_aux\n")
    assert text.count("\ndef quotedCore : file core_run_annotation :=") == 1
    assert "import Main" not in text and "import CerbQuote" not in text
    run(name + "-elaborate", ["lake", "env", "lean", path], cwd=frontend)
    print(name, path.stat().st_size, "bytes", flush=True)


result = cli("fixture", ["--quote-core", out / "Fixture.lean", fixture],
             prefix="./_build/install/default")
assert result.stdout == "" and result.stderr == ""
elaborate("Fixture")
result = cli("linked-and-libc", ["--quote-core", out / "Linked.lean",
             "--quote-libc", out / "Libc.lean", *libc, out / "tu1.json", out / "tu2.json"])
assert result.stdout == "" and result.stderr == ""
elaborate("Linked")
elaborate("Libc")
result = cli("library-only", ["--quote-libc", out / "LibcOnly.lean", *libc])
assert result.stdout == "" and result.stderr == ""
assert (out / "LibcOnly.lean").read_bytes() == (out / "Libc.lean").read_bytes()

for label, args, code, marker in [
    ("missing-path", ["--quote-core"], 1, "require an output path"),
    ("missing-libc", ["--quote-libc", out / "Rejected.lean", fixture], 1, "requires --libc"),
    ("duplicate-flag", ["--quote-core", "a", "--quote-core", "b", fixture], 2, "cannot be repeated"),
    ("exec-option", ["--quote-core", "a", "--call", "main", fixture], 2, "cannot be combined"),
    ("same-path", ["--quote-core", "a", "--quote-libc", "a", *libc, fixture], 2, "distinct output paths"),
]:
    result = cli(label, args, code)
    assert marker in result.stderr

bad_output = out / "missing-parent/Failed.lean"
result = cli("output-error", ["--quote-core", bad_output, fixture], 1,
             prefix="./_build/install/default")
assert result.stdout.startswith('Error {msg: "Core quotation failed: output ')
assert not bad_output.exists()

# Alter only a private runtime copy; add a supported parsed NaN to an unused fun.
nan_prefix = out / "nan-runtime"
core = nan_prefix / "lib/cerberus-lib/runtime/libcore"
if nan_prefix.exists():
    shutil.rmtree(nan_prefix)
shutil.copytree(runtime / "lib/cerberus-lib/runtime/libcore", core)
shutil.copytree(runtime / "lib/cerberus-lib/runtime/libc/include",
                nan_prefix / "lib/cerberus-lib/runtime/libc/include")
# Dune inputs are read-only; replace only our copied file with a fresh test input.
(core / "std.core").unlink()
(core / "std.core").write_text(
    (runtime / "lib/cerberus-lib/runtime/libcore/std.core").read_text() +
    "\nfun core_quote_nan_probe (): floating := nan\n")
nan_fixture = out / "nan-fixture.json"
nan_fixture.write_text(fixture.read_text().replace("./_build/install/default", str(nan_prefix)))
for existing in [False, True]:
    target = out / ("NaNExisting.lean" if existing else "NaNAbsent.lean")
    target.unlink(missing_ok=True)
    if existing:
        target.write_text("existing destination\n")
    result = cli("nan-" + str(existing), ["--quote-core", target, nan_fixture], 1, nan_prefix)
    assert 'Error {msg: "Core quotation failed: CerbQuote refused stdlib.Float.NaN:' in result.stdout
    assert target.read_text() == "existing destination\n" if existing else not target.exists()
assert not list(out.glob("*.cerb-quote-*"))
print("D2 CLI: three emitted literals elaborate; library-only agrees; eight refusal/output controls pass")
