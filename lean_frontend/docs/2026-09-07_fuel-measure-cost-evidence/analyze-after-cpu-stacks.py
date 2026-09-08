#!/usr/bin/env python3
"""Analyze cpu-stack-sampler.c traces with the measured binary's symbol table.

D3 variant: classify the generic context-search bound separately from tag-environment bounds.

Usage: python3 analyze-after-cpu-stacks.py BINARY TRACE [TRACE...]
Self = interrupted PC. Inclusive = symbol occurs anywhere on sampled stack,
counted once per sample. Return addresses are resolved at address-1. Measure
union counts each sample once, including runtime/library work underneath a
visible measure frame. Optimized-away frames and inline-only arithmetic may
be missed; these are sampling estimates, not exact accounting.
"""
import bisect
import collections
from pathlib import Path
import re
import struct
import subprocess
import sys


def symbols(binary):
    result = []
    for line in subprocess.check_output(
            ["nm", "-n", "-S", "--defined-only", str(binary)], text=True).splitlines():
        fields = line.split()
        if len(fields) == 4 and fields[2] in {"t", "T"}:
            start, size = (int(s, 16) for s in fields[:2])
            result.append((start, size, fields[3]))
    return sorted(result)


def analyze(binary, trace):
    syms = symbols(binary)
    starts = [s[0] for s in syms]
    data = trace.read_bytes()
    magic, base, interval = struct.unpack_from("=3Q", data)
    assert magic == 0x464353414d504c31
    assert (len(data) - 24) % (98 * 8) == 0

    def resolve(address):
        offset = address - base
        i = bisect.bisect_right(starts, offset) - 1
        if i >= 0 and offset < syms[i][0] + syms[i][1]:
            return syms[i][2]
        return "[shared-library/or-unresolved]"

    direct, inclusive, groups = (collections.Counter() for _ in range(3))
    n = truncated = 0
    for start in range(24, len(data), 98 * 8):
        row = struct.unpack_from("=98Q", data, start)
        pc, depth = row[:2]
        assert 0 < depth <= 96
        assert not any(row[2 + depth:])
        n += 1
        truncated += depth == 96
        self_symbol = resolve(pc)
        stack = {resolve(a - 1) for a in row[2:2 + depth]}
        stack.add(self_symbol)
        stack.discard("[shared-library/or-unresolved]")
        direct[self_symbol] += 1
        inclusive.update(stack)
        search = any("CerbTagsWf_branchBound" in s for s in stack)
        env = any("CerbTagsWf_" in s and "CerbTagsWf_branchBound" not in s and re.search(
            r"Bound|defsWeight|defSize|alignSize|membersSize", s) for s in stack)
        expr = any("lemSize" in s and "generic__" in s for s in stack)
        ctype = any("lemSize" in s and "_ctype_" in s for s in stack)
        other = any("lemSize" in s or re.search(r"all\w*Bound", s) for s in stack)
        for category, present in (("context-search bounds", search),
                                  ("environment measures", env),
                                  ("generic expression measures", expr),
                                  ("ctype measures", ctype),
                                  ("all measures union", search or env or expr or ctype or other),
                                  ("rest", not (search or env or expr or ctype or other))):
            groups[category] += int(present)
    assert n
    print(f"trace={trace.name} samples={n} interval_us={interval} depth_limit_hits={truncated}")
    print("Derived inclusive groups (groups can overlap; union and rest partition samples):")
    for name, count in groups.items():
        print(f"{count:6d} {100 * count / n:7.2f}% {name}")
    for name, counter in (("Top self symbols", direct), ("Top inclusive symbols", inclusive)):
        print(name + ":")
        for symbol, count in counter.most_common(25):
            print(f"{count:6d} {100 * count / n:7.2f}% {symbol}")
    print("All visible measure symbols: self_samples inclusive_samples symbol")
    for symbol, count in inclusive.most_common():
        if "lemSize" in symbol or re.search(r"all\w*Bound", symbol) or (
                "CerbTagsWf_" in symbol and re.search(r"Bound|defsWeight|defSize|alignSize|membersSize", symbol)):
            print(direct[symbol], count, symbol)
    return n, direct, inclusive


if __name__ == "__main__":
    for trace in sys.argv[2:]:
        analyze(Path(sys.argv[1]), Path(trace))
