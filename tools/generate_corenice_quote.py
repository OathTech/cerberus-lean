#!/usr/bin/env python3
"""Package the existing constructor-quotation instrument for CoreNice.

This is independent of the semantic ownership manifest. Constructor-label
strings remain unchanged deliberately. Only comesfrom metadata on Esave/Erun and the strong-tail control
are erased; every original AST field is still compared. Rendering and runtime states are not
part of this instrument. NaN and untracked comparator provenance refuse.
"""
import argparse
import json
from pathlib import Path
from generate_corenice import package

ROOT = Path(__file__).resolve().parents[1]


def erase_incoming_fields(quotation: str) -> str:
    """Erase added Nice control fields; retain every original quoted payload."""
    for constructor, field in [("Esave", "_incoming"), ("Erun", "_origin")]:
        pattern = f"  | generic_expr_.{constructor} x0 x1 x2 =>"
        if quotation.count(pattern) != 1:
            raise ValueError(f"expected one original {constructor} quotation arm")
        quotation = quotation.replace(pattern,
            f"  | generic_expr_.{constructor} x0 x1 x2 {field} =>", 1)
    quotation = quotation.replace("| generic_expr_.Esseq x0 x1 x2 =>",
        "| generic_expr_.Esseq x0 x1 (_tail, x2) =>")
    return quotation


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    recipe = json.loads((ROOT / "frontend/corenice/instruments.json").read_text())["quote"]
    source = (ROOT / recipe["source"]).read_text()
    marker = recipe["end_before"]
    if source.count(marker) != 1:
        raise SystemExit("CoreNice quote generator: unique quotation/render boundary is missing")
    quotation = erase_incoming_fields(source.split(marker)[0] + "end CerbQuote\n")
    output = "/- Generated instrument; regenerate with tools/generate_corenice_quote.py. -/\n" + package(quotation, set(recipe["owned_imports"]))
    destination = ROOT / recipe["output"]
    if args.check:
        if not destination.exists() or destination.read_text() != output:
            raise SystemExit("CoreNice quote instrument differs; regenerate it")
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(output)


if __name__ == "__main__":
    main()
