#!/usr/bin/env python3
"""Small bounded unsigned-C grammar for the Core/CoreB comparison campaign.

All templates execute their array/pointer accesses, positive-bound loops,
conditionals, arithmetic, globals/locals and two direct calls. Expressions
contain initialized unsigned operands only; indices and shifts stay bounded.
This construction is a testing recipe, not a proof that generated C is UB-free.
"""

import argparse
from dataclasses import dataclass
import hashlib

VERSION = "bounded-unsigned-v1"
FEATURES = ("arithmetic", "conditionals", "bounded-loops", "globals-locals",
            "direct-calls", "array-pointer-loads-stores")
TEMPLATES = ("array-fold", "pointer-walk", "global-calls", "call-tree")


class Numbers:
    """Stable counter-based parameters, independent of Python's random module."""

    def __init__(self, seed, index):
        self.key = f"{VERSION}:{seed}:{index}"
        self.counter = 0

    def below(self, bound):
        value = hashlib.sha256(f"{self.key}:{self.counter}".encode()).digest()
        self.counter += 1
        return int.from_bytes(value[:8], "big") % bound


@dataclass(frozen=True)
class Program:
    source: str
    template: str
    features: tuple


def expression(numbers, leaves, depth):
    """Grammar U := initialized-U | small-U-literal | (U unsigned-op U)."""
    if depth == 0:
        return leaves[numbers.below(len(leaves))]
    operator = ("+", "*", "^", "|", "&")[numbers.below(5)]
    left = expression(numbers, leaves, depth - 1)
    right = expression(numbers, leaves + [f"{numbers.below(256)}u"], depth - 1)
    return f"({left} {operator} {right})"


def generate(seed, index):
    if seed < 0 or index < 0:
        raise ValueError("seed and index must be nonnegative")
    numbers = Numbers(seed, index)
    template = TEMPLATES[index % len(TEMPLATES)]
    size = 2 + numbers.below(4)
    values = [1 + numbers.below(100) for _ in range(size)]
    constants = [1 + numbers.below(31) for _ in range(5)]
    x, y, k, mask, initial = constants
    expr = expression(numbers, ["v", "i", f"{k}u"], 1 + numbers.below(2))
    # All helper calls are reached. Side effects touch separate global objects,
    # giving real competing call schedules without unsequenced conflicting writes.
    helpers = f"""unsigned ga = {initial}u;
unsigned gb = {mask}u;
unsigned left(unsigned v) {{ ga = ga + v + {x}u; return ga; }}
unsigned right(unsigned v) {{ gb = gb ^ (v + {y}u); return gb; }}
"""
    calls = "left(a[0]) + right(a[1])"
    if template == "call-tree":
        # Calls still execute exactly once each; both sides contain useful pure
        # arithmetic to exercise nested unsequenced expression contexts.
        calls = f"(left(a[0]) ^ {x}u) + (right(a[1]) * {y}u)"
    if template == "pointer-walk":
        access = "unsigned *q = a + i; unsigned v = *q;"
        write = f"*q = {expr} & 255u;"
    else:
        access = "unsigned v = a[i];"
        write = f"a[i] = {expr} & 255u;"
    body = f"""    {access}
    if ((v ^ z) & 1u) {{ v = v + {x}u; }} else {{ v = v ^ {y}u; }}
    {write}
    z = z + v;
"""
    if template == "global-calls":
        loop = f"  unsigned i = 0u;\n  do {{\n{body}    i = i + 1u;\n  }} while (i < {size}u);"
    elif template == "pointer-walk":
        loop = f"  unsigned i = 0u;\n  while (i < {size}u) {{\n{body}    i = i + 1u;\n  }}"
    else:
        loop = f"  for (unsigned i = 0u; i < {size}u; i = i + 1u) {{\n{body}  }}"
    source = f"""/* {VERSION}; seed={seed}; index={index}; template={template}. */
{helpers}int main(void) {{
  unsigned a[{size}] = {{{', '.join(f'{v}u' for v in values)}}};
  unsigned z = {calls};
  unsigned *p = &a[{size - 1}];
{loop}
  *p = (*p + z) & 255u;
  return (int)((a[0] + *p + ga + gb) % 251u);
}}
"""
    return Program(source, template, FEATURES)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--index", type=int, required=True)
    options = parser.parse_args()
    print(generate(options.seed, options.index).source, end="")


if __name__ == "__main__":
    main()
