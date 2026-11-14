#!/usr/bin/env python3
"""Generate the owned CoreB Lem sources and package their Lean names.

This is a separate Lem invocation, not a copy of generated Core output. Model
and handwritten inputs are owned copies listed in frontend/coreb/sources.json.
The only Lean transformation maps whole import names and encloses declarations
in namespace CoreB. In particular, strings, terms and proofs are not rewritten.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
IMPORT = re.compile(r"^import ([A-Za-z_][A-Za-z_0-9.]*)[ \t]*$", re.MULTILINE)


def package(text: str, owned_modules: set[str]) -> str:
    # Scan only the header. An import-looking line inside a comment or a body
    # string must neither be rewritten nor move the namespace boundary.
    imports = []
    pos = 0
    while pos < len(text):
        if text[pos].isspace():
            pos += 1
        elif text.startswith("--", pos):
            newline = text.find("\n", pos)
            pos = len(text) if newline < 0 else newline + 1
        elif text.startswith("/-", pos):
            depth = 1
            pos += 2
            while depth and pos < len(text):
                if text.startswith("/-", pos):
                    depth += 1
                    pos += 2
                elif text.startswith("-/", pos):
                    depth -= 1
                    pos += 2
                else:
                    pos += 1
            if depth:
                raise ValueError("unterminated Lean header comment")
        elif match := IMPORT.match(text, pos):
            imports.append(match)
            pos = match.end()
        else:
            break
    if not imports:
        raise ValueError("expected Lean imports before the declaration body")
    end = imports[-1].end()
    header = text[:end]
    for match in reversed(imports):
        if match[1] in owned_modules:
            header = header[:match.start(1)] + "CoreB." + header[match.start(1):]
    body = text[end:]
    return header + "\n\nnamespace CoreB\n" + body + "\nend CoreB\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-baseline", action="store_true",
        help="also require owned inputs and raw generated bodies to equal Core",
    )
    args = parser.parse_args()
    manifest = json.loads((ROOT / "frontend/coreb/sources.json").read_text())
    sources = manifest["lem"]
    helpers = manifest["handwritten"]
    modules = {entry["module"] for entry in sources + helpers}
    modules.update(entry["module"] + "_auxiliary" for entry in sources)
    substitutions = {entry["source"]: entry["owned"] for entry in sources}
    original_inputs = subprocess.check_output(
        ["make", "--no-print-directory", "-s", "lean-source-list"],
        cwd=ROOT, text=True,
    ).splitlines()
    if not substitutions.keys() <= set(original_inputs):
        raise ValueError("owned Lem source missing from the original input list")
    for entry in sources + helpers:
        owned = ROOT / entry["owned"]
        if not owned.is_file():
            raise ValueError(f"missing owned source: {owned}")
        if args.check_baseline:
            original = (ROOT / entry["source"]).read_bytes()
            baseline = subprocess.check_output(
                ["git", "show", manifest["baseline"] + ":" + entry["source"]], cwd=ROOT,
            )
            if original != baseline or owned.read_bytes() != baseline:
                raise ValueError(f"source differs from the recorded baseline: {owned}")

    scratch = ROOT / ".tmp"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="coreb-generation-", dir=scratch) as tmp:
        command = [
            "lem", "-wl", "ign", "-wl_rename", "warn", "-wl_pat_red", "err",
            "-wl_pat_exh", "warn", "-outdir", tmp, "-cerberus_pp", "-lean",
        ]
        for source in original_inputs:
            command.extend([substitutions[source]] if source in substitutions else ["-i", source])
        subprocess.run(command, cwd=ROOT, check=True)
        raw = Path(tmp)
        expected = {entry["module"] + suffix + ".lean"
                    for entry in sources for suffix in ("", "_auxiliary")}
        actual = {path.name for path in raw.glob("*.lean")}
        if actual != expected:
            raise ValueError(f"unexpected Lem outputs: missing={expected-actual}, extra={actual-expected}")
        outputs = {}
        for filename in sorted(expected):
            text = (raw / filename).read_text()
            if args.check_baseline:
                original = (ROOT / "lean_frontend/generated" / filename).read_text()
                # The first line records the intentionally different input path.
                if text.splitlines()[1:] != original.splitlines()[1:]:
                    raise ValueError(f"raw generated body differs from Core: {filename}")
            outputs[filename] = package(text, modules)
        for entry in helpers:
            outputs[entry["module"] + ".lean"] = package(
                (ROOT / entry["owned"]).read_text(), modules,
            )
        destination = ROOT / "lean_frontend/generated/CoreB"
        destination.mkdir(parents=True, exist_ok=True)
        stale = {path.name for path in destination.glob("*.lean")} - outputs.keys()
        if stale:
            raise ValueError(f"stale CoreB modules; remove explicitly before generation: {sorted(stale)}")
        for filename, text in outputs.items():
            (destination / filename).write_text(text)
    print(f"CoreB: generated and packaged {len(outputs)} modules")
    if args.check_baseline:
        print("CoreB baseline: owned inputs and raw generated bodies equal Core (source-path header excepted)")


if __name__ == "__main__":
    main()
