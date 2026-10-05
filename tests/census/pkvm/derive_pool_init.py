#!/usr/bin/env python3
"""derive_pool_init.py — census (P1f-2) run-time derivation of census_pool_init.

[AGENT] 2026-10-05 (pre-merge audit M2). The case study's page_alloc.c is
SPDX GPL-2.0-only, so this BSD repository carries NO text from it. Instead, at
run time, this script:

  1. extracts hyp_pool_init (from its two signature lines to the first line
     that is exactly "}") from the case study's own page_alloc.c;
  2. checks that the extracted text is byte-for-byte the audited version
     (sha256 pin below) and that each pattern below matches exactly once;
  3. makes the one documented substitution: get_order((nr_pages + 1) <<
     PAGE_SHIFT) -> max_order, where max_order is a new last parameter, and
     renames the function census_pool_init. REASON: the case study gives
     get_order an empty body (a CN-frontend workaround), so hyp_pool_init
     uses the value of a non-void function that fell off its end (UB088);
     pkvm_init.c records that, the other drivers need a usable pool;
  4. writes <outdir>/page_alloc_census.c: `#include` of the case study's
     page_alloc.c followed by the derived function (it must share
     page_alloc.c's TU because it calls the static __hyp_put_page).

The output carries GPL-2.0-only text and lives only under the census output
directory; it is never committed. Prints the output path. Any mismatch exits
non-zero with the reason (fail-closed).
"""
import hashlib
import os
import sys

SIG_OLD = ("int hyp_pool_init(struct hyp_pool *pool, u64 pfn, unsigned int nr_pages,\n"
           "\t\t  unsigned int reserved_pages)\n")
SIG_NEW = ("int census_pool_init(struct hyp_pool *pool, u64 pfn, unsigned int nr_pages,\n"
           "\t\t  unsigned int reserved_pages, u8 max_order)\n")
CALL_OLD = "get_order((nr_pages + 1) << PAGE_SHIFT)"
CALL_NEW = "max_order"
# sha256 of the extracted hyp_pool_init (page_alloc.c:685-791 at case study 460fb6b6e)
PINNED_SHA256 = "98665f6a09537b51c167e66221bbb231d7940ace53ad3e63b3749fb86ca26e34"


def die(msg):
    sys.stderr.write(f"derive_pool_init: ERROR: {msg}\n")
    sys.exit(1)


def main():
    if len(sys.argv) != 3:
        die("usage: derive_pool_init.py <case-study-dir> <outdir>")
    src = os.path.abspath(os.path.join(sys.argv[1], "page_alloc.c"))
    out_dir = os.path.abspath(sys.argv[2])
    try:
        with open(src, encoding="utf-8", newline="") as f:
            text = f.read()
    except OSError as e:
        die(f"cannot read {src}: {e}")
    if text.count(SIG_OLD) != 1:
        die(f"hyp_pool_init signature found {text.count(SIG_OLD)} times in {src} (expected exactly 1)")
    start = text.index(SIG_OLD)
    end = text.find("\n}\n", start)
    if end < 0:
        die("no closing '}' line after hyp_pool_init")
    func = text[start:end + 3]
    sha = hashlib.sha256(func.encode("utf-8")).hexdigest()
    if sha != PINNED_SHA256:
        die(f"extracted hyp_pool_init has sha256 {sha}, pinned {PINNED_SHA256} (case study drifted?)")
    if func.count(CALL_OLD) != 1:
        die(f"'{CALL_OLD}' occurs {func.count(CALL_OLD)} times in hyp_pool_init (expected exactly 1)")
    derived = func.replace(SIG_OLD, SIG_NEW, 1).replace(CALL_OLD, CALL_NEW, 1)
    if "get_order(" in derived or "hyp_pool_init" in derived:
        die("derived text still mentions get_order( or hyp_pool_init")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "page_alloc_census.c")
    with open(out, "w", encoding="utf-8", newline="") as f:
        f.write("// SPDX-License-Identifier: GPL-2.0-only\n")
        f.write(f"/* GENERATED at run time by tests/census/pkvm/derive_pool_init.py from\n"
                f" * {src} (hyp_pool_init, sha256 {PINNED_SHA256});\n"
                f" * the only edits: renamed census_pool_init, new last parameter max_order,\n"
                f" * and {CALL_OLD} -> {CALL_NEW}. NEVER COMMITTED. */\n")
        f.write(f'#include "{src}"\n\n')
        f.write(derived)
    print(out)


if __name__ == "__main__":
    main()
