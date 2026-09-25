#!/usr/bin/env python3
"""Admission tests for the production totality gate; no Lean build required."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="totality-plant-") as temporary:
    tree = Path(temporary)
    (tree / "scripts").mkdir()
    generated = tree / "lean_frontend/generated"
    generated.mkdir(parents=True)
    for source in (root / "lean_frontend/generated").glob("*.lean"):
        shutil.copyfile(source, generated / source.name)
    shutil.copyfile(root / "lean_frontend/CerbND.lean", tree / "lean_frontend/CerbND.lean")
    gate = tree / "scripts/check_exec_totality.sh"
    shutil.copyfile(root / "scripts/check_exec_totality.sh", gate)
    allow = tree / "scripts/exec_totality_allowlist.txt"
    shutil.copyfile(root / "scripts/exec_totality_allowlist.txt", allow)
    env = os.environ.copy()
    env.pop("ENFORCE", None)

    def check(label, rc, message, **overrides):
        result = subprocess.run(["bash", str(gate)], env=env | overrides,
                                capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        if result.returncode != rc or message not in output:
            raise AssertionError(f"{label}: rc={result.returncode}\n{output}")
        print(f"  PLANT OK [{label}] rc={rc}: {message}")

    check("baseline", 0, "CLEAN")
    target = generated / "Core_eval.lean"
    original = target.read_text()
    target.write_text(original + "\npartial def readinessPlant : Nat := readinessPlant\n")
    check("default enforces partial", 1, "PARTIAL Core_eval.readinessPlant")
    check("explicit report", 0, "REPORT ONLY", ENFORCE="0")
    check("invalid mode", 2, "ENFORCE must be 0 or 1", ENFORCE="true")
    check("empty mode", 2, "ENFORCE must be 0 or 1", ENFORCE="")
    target.write_text(original)
    original_allow = allow.read_text()
    allow.write_text(original_allow + "\nCore_eval.readinessPlant\n")
    check("stale allowlist", 1, "STALE allowlist entry: Core_eval.readinessPlant")
    allow.unlink()
    check("missing allowlist", 1, "missing allowlist")
    allow.write_text(original_allow)
    target.unlink()
    check("missing module", 1, "MISSING")
    target.write_text(original)
    shim = tree / "bin"
    shim.mkdir()
    (shim / "python3").write_text("#!/bin/sh\nexit 2\n")
    (shim / "python3").chmod(0o755)
    check("scanner failure", 1, "SCANNER FAILED", PATH=f"{shim}:{env['PATH']}")
    check("restored baseline", 0, "CLEAN")
print("test_exec_totality: OK (8 plants and 2 clean controls)")
