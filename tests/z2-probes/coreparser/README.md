# coreparser/ — CoreParser.lean vs core_parser.mly probes (Z2, 2026-09-03)

Reachability frame (reader A, verified): `CoreParser.parseFile` parses exactly
three inputs in the executable pipeline — `runtime/libcore/std.core`, the
`.impl` file (both modes; both also parsed by the OCaml grammar), and the
pinned `--pp=core` dump `tests/libc/libc.core` (`--libc` mode; the oracle
uses the in-memory `libc.co` AST instead — a pp-ROUND-TRIP class). C TUs are
never parsed from Core text. Engines/binaries as in `../mem/README.md`.

| Probe | Mode | What it tests | fork oracle | upstream | Lean | Class | Proposed lane |
|---|---|---|---|---|---|---|---|
| `strtod_inf.c` | libc | `tests/libc/libc.core:53897/53906` `pure(Specified(inf))` (the pp's `string_of_float` of +∞, `pp_core.ml:279-282`) inside `proc decfloat`'s overflow path; `CoreParser.lean:1072,1321-1328` lexes `inf` as an identifier → `PEsym` (the OCaml grammar has no float literal at all, `core_lexer.mll:290-291`) | 10 executions, each `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | same | 10 executions, each `Error {msg: "Unresolved_symbol: Symbol(_, 13557763317115745599, _) at unknown location"}` | **BUG-FIX, CONFIRMED** (verdict class: Defined vs Error) — every `strtod`/`strtof` overflow (and the 4 `inf`/`nan` sites in the dump) is broken in libc mode. Fix (S): `pPexprAtom` maps `inf`/`nan`(/`-inf`) to `PEval (Vobject (OVfloating …))`; add a tripwire that no parsed binder is named `inf`/`nan` | libc_exec DIFF pin → MATCH after the fix |
| `strtof_fltmax.c` | libc | `libc.core:41698` `Specified(3.40282347e+38)` — FLT_MAX printed with `%.12g` (17 digits needed), so the Lean-parsed double ≠ the oracle's in-memory value; probe at the `strtof` overflow boundary | exit 124 (timeout 60 s, exhaustive) | exit 124 | exit 124 | NOT SETTLED — all three engines exceed 60 s (three `strtof` calls in exhaustive mode); rerun single-trace with a larger bound in Z4's measurement lane. The dump-lossiness itself is an INSTRUMENT finding: regenerate the pinned dump with an exact float printer (`%.17g`/hex) or pin it as a declared boundary | reporting-only |

Derived: 2 probes; 1 LEAN≠ORACLE confirmed (10/10 executions), 1 not settled.
