#!/usr/bin/env python3
"""gen_chvalid_battery.py — generate tests/libxml2/chvalid_battery.c.

Arc-5 S3 (charter: lean_frontend/docs/2026-08-19_arc5-libc-linking-charter.md,
exit criterion / success condition 3). Mechanically extracts every interval
boundary from libxml2's chvalid tables (codegen/ranges.inc, textually included
by chvalid.c) and emits a differential test battery:

  * point set: for every interval boundary b in every range table (the six
    xmlCh{S,L}Range tables AND the run boundaries of xmlIsPubidChar_tab),
    the edges b-1, b, b+1; plus the fixed probes 0x0, 0x7F, 0x80, 0xFFFF,
    0x10000, 0x10FFFF.  Sorted, deduplicated.
  * per point, 22 observations packed into a bit vector:
      - the 8 exported (deprecated) functions xmlIsBaseChar .. xmlIsPubidChar
        — cross-TU calls INTO chvalid.c (exercises multi-TU linking),
      - the 8 group macros xmlIs*Q — expanded in the battery TU itself
        (chvalid.h), calling xmlCharInRange cross-TU where applicable,
      - direct xmlCharInRange calls against the 6 exported range groups.
  * results accumulate into a single unsigned checksum (defined behavior:
    unsigned wrap-around only); main prints "chvalid_battery n=<N> h=<H>"
    and returns (int)(h % 1000000007u) — one differential run covers the
    whole battery via verdict value + stdout.

The battery is emitted as SLICES (default 50 points per .c file): the
Cerberus concrete-memory interpreters (both sides) retain dead allocations,
so exec cost grows QUADRATICALLY in battery length — one 1354-point program
blows the 300 s per-invocation resource cap on BOTH sides (measured, OCaml:
100 pts 4 s, 200 pts 16 s, 400 pts 66 s, 1354 pts > 300 s; Lean --first:
100 pts 139 s, extrapolated 200 pts ~560 s). 50-point slices run in ~1 s
(OCaml) / ~35 s (Lean), comfortably inside the caps, and smaller slices
also minimize TOTAL harness time under the quadratic. The slices partition
the same point set; each slice accumulates its own checksum, so the union
of slice verdicts covers the full battery.

Usage:
  gen_chvalid_battery.py RANGES_INC --out-dir DIR [--slice-size N]
  gen_chvalid_battery.py RANGES_INC [-o OUT.c] [--slice A:B] [--verbose-point 0xN]

  --out-dir DIR      emit chvalid_battery_NN.c slice files into DIR
  --slice-size N     points per slice file (default 50)
  --slice A:B        emit only points[A:B] as a single file (minimization)
  --verbose-point C  emit a battery for the single code point C that prints
                     each of the 22 observations on its own line (for
                     classifying a mismatch)

Deterministic: output depends only on the ranges.inc content and the flags.
Fail-closed: any parse anomaly (missing table, count mismatch with the
xmlChRangeGroup descriptors, empty point set) aborts with a nonzero exit.
"""

import argparse
import re
import sys

EXPECTED_SRNG = {
    "xmlIsBaseChar": 197,
    "xmlIsChar": 2,
    "xmlIsCombining": 95,
    "xmlIsDigit": 14,
    "xmlIsExtender": 10,
    "xmlIsIdeographic": 3,
}
EXPECTED_LRNG = {"xmlIsChar": 1}

FIXED_PROBES = [0x0, 0x7F, 0x80, 0xFFFF, 0x10000, 0x10FFFF]

# (exported function, group macro, range-group global or None)
PREDICATES = [
    ("xmlIsBaseChar", "xmlIsBaseCharQ", "xmlIsBaseCharGroup"),
    ("xmlIsBlank", "xmlIsBlankQ", None),
    ("xmlIsChar", "xmlIsCharQ", "xmlIsCharGroup"),
    ("xmlIsCombining", "xmlIsCombiningQ", "xmlIsCombiningGroup"),
    ("xmlIsDigit", "xmlIsDigitQ", "xmlIsDigitGroup"),
    ("xmlIsExtender", "xmlIsExtenderQ", "xmlIsExtenderGroup"),
    ("xmlIsIdeographic", "xmlIsIdeographicQ", "xmlIsIdeographicGroup"),
    ("xmlIsPubidChar", "xmlIsPubidCharQ", None),
]


def die(msg):
    sys.stderr.write("gen_chvalid_battery: ERROR: %s\n" % msg)
    sys.exit(1)


def parse_ranges_inc(text):
    """Return (intervals, pubid_tab). intervals = list of (low, high)."""
    intervals = []

    # --- hardening (arc-5 audit 1, F4): the set of xmlCh[SL]Range table
    # declarations FOUND in ranges.inc must equal the set CONSUMED below.
    # A new/unknown table would otherwise be silently excluded from the
    # boundary point set — fail hard instead.
    found_tables = set(re.findall(r"xmlCh[SL]Range\s+([A-Za-z0-9_]+)\s*\[\]", text))
    consumed_tables = set(
        ["%s_srng" % n for n in EXPECTED_SRNG]
        + ["%s_lrng" % n for n in EXPECTED_LRNG]
    )
    if found_tables != consumed_tables:
        die(
            "ranges.inc table set drift: found %s, consumed %s "
            "(extra: %s; missing: %s) — a new/unknown table requires a "
            "deliberate generator + EXPECTED_* update and re-baseline"
            % (
                sorted(found_tables),
                sorted(consumed_tables),
                sorted(found_tables - consumed_tables) or "none",
                sorted(consumed_tables - found_tables) or "none",
            )
        )

    # --- the six range tables -----------------------------------------
    for name, kind, expected in (
        [(n, "srng", c) for n, c in sorted(EXPECTED_SRNG.items())]
        + [(n, "lrng", c) for n, c in sorted(EXPECTED_LRNG.items())]
    ):
        m = re.search(
            r"xmlCh[SL]Range\s+%s_%s\[\]\s*=\s*\{(.*?)\};" % (name, kind),
            text,
            re.S,
        )
        if not m:
            die("table %s_%s not found in ranges.inc" % (name, kind))
        pairs = re.findall(r"\{\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)\s*\}", m.group(1))
        if len(pairs) != expected:
            die(
                "table %s_%s: %d intervals, expected %d (ranges.inc changed? "
                "update EXPECTED_* and re-baseline)" % (name, kind, len(pairs), expected)
            )
        for lo, hi in pairs:
            lo, hi = int(lo, 16), int(hi, 16)
            if lo > hi:
                die("table %s_%s: inverted interval {%#x, %#x}" % (name, kind, lo, hi))
            intervals.append((lo, hi))

    # cross-check against the xmlChRangeGroup descriptors
    for name in EXPECTED_SRNG:
        m = re.search(
            r"xmlChRangeGroup\s+%sGroup\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*," % name, text
        )
        if not m:
            die("group descriptor %sGroup not found" % name)
        nb_s, nb_l = int(m.group(1)), int(m.group(2))
        if nb_s != EXPECTED_SRNG[name] or nb_l != EXPECTED_LRNG.get(name, 0):
            die(
                "group %sGroup descriptor (%d,%d) disagrees with expected (%d,%d)"
                % (name, nb_s, nb_l, EXPECTED_SRNG[name], EXPECTED_LRNG.get(name, 0))
            )

    # --- xmlIsPubidChar_tab[256] --------------------------------------
    m = re.search(r"xmlIsPubidChar_tab\[256\]\s*=\s*\{(.*?)\};", text, re.S)
    if not m:
        die("xmlIsPubidChar_tab not found")
    bytes_ = [int(b, 16) for b in re.findall(r"0x[0-9a-fA-F]{2}", m.group(1))]
    if len(bytes_) != 256:
        die("xmlIsPubidChar_tab: %d bytes, expected 256" % len(bytes_))
    if any(b not in (0, 1) for b in bytes_):
        die("xmlIsPubidChar_tab: non-boolean byte")

    return intervals, bytes_


def pubid_runs(tab):
    """Maximal runs of 1s in the 256-entry table, as (low, high) intervals."""
    runs = []
    start = None
    for i, b in enumerate(tab):
        if b and start is None:
            start = i
        elif not b and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, 255))
    return runs


def build_points(intervals):
    pts = set()
    for lo, hi in intervals:
        for b in (lo, hi):
            for p in (b - 1, b, b + 1):
                if p >= 0:
                    pts.add(p)
    pts.update(FIXED_PROBES)
    return sorted(pts)


def emit(points, out, verbose_point=None):
    w = out.write
    w("/* chvalid battery slice — GENERATED by tests/libxml2/gen_chvalid_battery.py.\n")
    w(" * DO NOT EDIT. Regenerate all slices:\n")
    w(" *   tests/libxml2/gen_chvalid_battery.py <libxml2>/codegen/ranges.inc \\\n")
    w(" *       --out-dir tests/libxml2/battery\n")
    w(" * Arc-5 S3 differential battery over libxml2 chvalid.c; see the\n")
    w(" * generator's docstring for the point-set construction.\n")
    w(" */\n")
    w("#include <libxml/chvalid.h>\n")
    w("#include <stdio.h>\n\n")

    if verbose_point is not None:
        w("int main(void) {\n")
        w("    unsigned int c = %#xu;\n" % verbose_point)
        for fn, mac, grp in PREDICATES:
            w('    printf("%s %%d\\n", %s(c) != 0);\n' % (fn, fn))
            w('    printf("%s %%d\\n", %s(c) != 0);\n' % (mac, mac))
        for _, _, grp in PREDICATES:
            if grp is not None:
                w('    printf("xmlCharInRange:%s %%d\\n", xmlCharInRange(c, &%s) != 0);\n'
                  % (grp, grp))
        w("    return 0;\n")
        w("}\n")
        return

    n = len(points)
    w("#define BATTERY_N %du\n\n" % n)
    w("static const unsigned int points[%d] = {" % n)
    for i, p in enumerate(points):
        if i % 8 == 0:
            w("\n    ")
        w("%#xu%s" % (p, "" if i == n - 1 else ", "))
    w("\n};\n\n")
    w("int main(void) {\n")
    w("    unsigned int h = 5381u;\n")
    w("    unsigned int i;\n")
    w("    for (i = 0u; i < BATTERY_N; i++) {\n")
    w("        unsigned int c = points[i];\n")
    w("        unsigned int bits = 0u;\n")
    w("        /* exported functions: cross-TU calls into chvalid.c */\n")
    for fn, _, _ in PREDICATES:
        w("        bits = (bits << 1) | (unsigned int)(%s(c) != 0);\n" % fn)
    w("        /* group macros expanded in THIS TU (libxml/chvalid.h) */\n")
    for _, mac, _ in PREDICATES:
        w("        bits = (bits << 1) | (unsigned int)(%s(c) != 0);\n" % mac)
    w("        /* direct xmlCharInRange over each exported range group */\n")
    for _, _, grp in PREDICATES:
        if grp is not None:
            w("        bits = (bits << 1) | (unsigned int)(xmlCharInRange(c, &%s) != 0);\n" % grp)
    w("        h = h * 33u + bits;   /* unsigned wrap-around: defined */\n")
    w("    }\n")
    w('    printf("chvalid_battery n=%u h=%u\\n", (unsigned int)BATTERY_N, h);\n')
    w("    return (int)(h % 1000000007u);\n")
    w("}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ranges_inc")
    ap.add_argument("-o", "--output", default="-")
    ap.add_argument("--out-dir", default=None,
                    help="emit chvalid_battery_NN.c slice files into DIR")
    ap.add_argument("--slice-size", type=int, default=50)
    ap.add_argument("--slice", default=None, help="A:B — emit only points[A:B]")
    ap.add_argument("--verbose-point", default=None,
                    help="single code point; print all 22 observations")
    args = ap.parse_args()

    try:
        with open(args.ranges_inc) as f:
            text = f.read()
    except OSError as e:
        die(str(e))

    intervals, tab = parse_ranges_inc(text)
    intervals = intervals + pubid_runs(tab)
    points = build_points(intervals)
    if not points:
        die("empty point set")

    if args.out_dir is not None:
        import os
        if args.slice is not None or args.verbose_point is not None:
            die("--out-dir excludes --slice/--verbose-point")
        if args.slice_size < 1:
            die("bad --slice-size")
        os.makedirs(args.out_dir, exist_ok=True)
        nslices = (len(points) + args.slice_size - 1) // args.slice_size
        total = 0
        for k in range(nslices):
            chunk = points[k * args.slice_size:(k + 1) * args.slice_size]
            total += len(chunk)
            path = "%s/chvalid_battery_%02d.c" % (args.out_dir, k)
            import io
            buf = io.StringIO()
            emit(chunk, buf)
            with open(path, "w") as f:
                f.write(buf.getvalue())
        if total != len(points):
            die("internal: slice partition lost points")
        sys.stderr.write(
            "gen_chvalid_battery: %d intervals -> %d points -> %d slices of <=%d\n"
            % (len(intervals), len(points), nslices, args.slice_size)
        )
        return

    if args.slice is not None:
        try:
            a, b = args.slice.split(":")
            points = points[int(a):int(b)]
        except ValueError:
            die("bad --slice %r" % args.slice)
        if not points:
            die("--slice selected an empty point set")

    verbose_point = int(args.verbose_point, 0) if args.verbose_point else None

    if args.output == "-":
        emit(points, sys.stdout, verbose_point)
    else:
        import io
        buf = io.StringIO()
        emit(points, buf, verbose_point)
        with open(args.output, "w") as f:
            f.write(buf.getvalue())
    sys.stderr.write(
        "gen_chvalid_battery: %d intervals -> %d points\n"
        % (len(intervals), len(points))
    )


if __name__ == "__main__":
    main()
