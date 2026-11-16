#!/usr/bin/env python3
"""Package the existing constructor-quotation instrument for CoreNice.

This is independent of the semantic ownership manifest. Constructor-label
strings remain unchanged deliberately: they are the structural name-forgetting
map used for comparing the baseline ASTs. Rendering and runtime states are not
part of this instrument. NaN and untracked comparator provenance refuse.
"""
import argparse
import json
from pathlib import Path
from generate_corenice import package

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    recipe = json.loads((ROOT / "frontend/corenice/instruments.json").read_text())["quote"]
    source = (ROOT / recipe["source"]).read_text()
    marker = recipe["end_before"]
    if source.count(marker) != 1:
        raise SystemExit("CoreNice quote generator: unique quotation/render boundary is missing")
    quotation = source.split(marker)[0] + "end CerbQuote\n"
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
