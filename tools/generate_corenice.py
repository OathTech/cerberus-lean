#!/usr/bin/env python3
"""Generate the owned CoreNice Lem sources and package their Lean names.

This is a separate Lem invocation, not a copy of generated Core output. Model
and handwritten inputs are owned copies listed in frontend/corenice/sources.json.
Emit the whole original input environment to preserve Lem's output-sensitive
namespace-opening order; retain only the owned modules from this invocation.
Apply the original recipe's Core_run import fix, then map whole import names
and enclose declarations in CoreNice. Terms, strings and proofs are not rewritten.
"""

import argparse
import difflib
import json
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
IMPORT = re.compile(r"^import ([A-Za-z_][A-Za-z_0-9.]*)[ \t]*$", re.MULTILINE)


def qualify_open(text: str, name: str) -> str:
    """Qualify a local namespace opening, ignoring comments and strings."""
    mask = list(text)
    pos, depth, string = 0, 0, False
    while pos < len(text):
        if depth:
            if text.startswith("/-", pos):
                mask[pos:pos + 2] = "  "
                depth += 1
                pos += 2
            elif text.startswith("-/", pos):
                mask[pos:pos + 2] = "  "
                depth -= 1
                pos += 2
            else:
                if text[pos] != "\n": mask[pos] = " "
                pos += 1
        elif string:
            if text[pos] == "\\":
                mask[pos:pos + 2] = " " * len(text[pos:pos + 2])
                pos += 2
            else:
                if text[pos] == '"': string = False
                if text[pos] != "\n": mask[pos] = " "
                pos += 1
        elif text.startswith("/-", pos):
            mask[pos:pos + 2] = "  "
            depth = 1
            pos += 2
        elif text.startswith("--", pos):
            end = text.find("\n", pos)
            if end < 0: end = len(text)
            mask[pos:end] = " " * (end - pos)
            pos = end
        elif text[pos] == '"':
            mask[pos] = " "
            string = True
            pos += 1
        else:
            pos += 1
    if depth or string:
        raise ValueError("unterminated Lean comment/string while qualifying namespace")
    pattern = re.compile(r"^open " + re.escape(name) + r"[ \t]*$", re.MULTILINE)
    for match in reversed(list(pattern.finditer("".join(mask)))):
        start = match.start() + len("open ")
        text = text[:start] + "_root_.CoreNice." + text[start:]
    return text


def package(text: str, owned_modules: set[str], local_opens: tuple[str, ...] = ()) -> str:
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
            header = header[:match.start(1)] + "CoreNice." + header[match.start(1):]
    body = text[end:]
    for name in local_opens:
        body = qualify_open(body, name)
    return header + "\n\nnamespace CoreNice\n" + body + "\nend CoreNice\n"


def original_postprocess(filename: str, text: str) -> str:
    # Exactly the existing lean-prelude-src sed fix: Lem emits a nonexistent
    # Operators module for SEU.Operators. Keep A and B on the same recipe.
    if filename == "Core_run.lean":
        return re.sub(r"^import Operators\n", "", text, flags=re.MULTILINE)
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-baseline", action="store_true",
        help="also require owned inputs and raw generated bodies to equal Core",
    )
    args = parser.parse_args()
    manifest = json.loads((ROOT / "frontend/corenice/sources.json").read_text())
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
    with tempfile.TemporaryDirectory(prefix="corenice-generation-", dir=scratch) as tmp:
        command = [
            "lem", "-wl", "ign", "-wl_rename", "warn", "-wl_pat_red", "err",
            "-wl_pat_exh", "warn", "-outdir", tmp, "-cerberus_pp", "-lean",
        ]
        for source in original_inputs:
            command.append(substitutions.get(source, source))
        subprocess.run(command, cwd=ROOT, check=True)
        raw = Path(tmp)
        expected = {entry["module"] + suffix + ".lean"
                    for entry in sources for suffix in ("", "_auxiliary")}
        actual = {path.name for path in raw.glob("*.lean")}
        all_modules = [Path(source).stem for source in original_inputs]
        # Lem avoids colliding with Lean's own Std module.
        all_modules = ["Lem_Std" if name == "std" else name[0].upper() + name[1:]
                       for name in all_modules]
        expected_all = {name + suffix + ".lean"
                        for name in all_modules for suffix in ("", "_auxiliary")}
        if actual != expected_all:
            raise ValueError(f"unexpected Lem outputs: missing={expected_all-actual}, extra={actual-expected_all}")
        outputs = {}
        for filename in sorted(expected):
            text = original_postprocess(filename, (raw / filename).read_text())
            if args.check_baseline:
                original = (ROOT / "lean_frontend/generated" / filename).read_text()
                # The first line records the intentionally different input path.
                if text.splitlines()[1:] != original.splitlines()[1:]:
                    delta = difflib.unified_diff(original.splitlines(), text.splitlines(),
                                                fromfile="Core/" + filename,
                                                tofile="CoreNice/" + filename)
                    print("\n".join(list(delta)[:80]), flush=True)
                    raise ValueError(f"raw generated body differs from Core: {filename}")
            # Translation declares its own (inline-operator) namespace. The
            # nested B namespace must not ambiguously open the shared one.
            local_opens = ("Operators",) if filename == "Translation.lean" else ()
            outputs[filename] = package(text, modules, local_opens)
        for entry in helpers:
            outputs[entry["module"] + ".lean"] = package(
                (ROOT / entry["owned"]).read_text(), modules,
            )
        destination = ROOT / "lean_frontend/generated/CoreNice"
        destination.mkdir(parents=True, exist_ok=True)
        stale = {path.name for path in destination.glob("*.lean")} - outputs.keys()
        if stale:
            raise ValueError(f"stale CoreNice modules; remove explicitly before generation: {sorted(stale)}")
        for filename, text in outputs.items():
            (destination / filename).write_text(text)
    print(f"CoreNice: generated and packaged {len(outputs)} modules")
    if args.check_baseline:
        print("CoreNice baseline: owned inputs and raw generated bodies equal Core (source-path header excepted)")


if __name__ == "__main__":
    main()
