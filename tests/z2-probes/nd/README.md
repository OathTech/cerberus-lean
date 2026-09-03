# nd/ — CerbND.lean vs smt2.ml runND / driver_ocaml.ml batch_drive probes (Z2, 2026-09-03)

Engines and binaries as in `../mem/README.md`. Question: batch mode prints
executions in ENUMERATION ORDER — is the order identical (the noodle's
"counts agree" left order unverified)? And which trace does Lean's `--first`
pick vs the oracle's single-trace mode?

| Probe | Mode | What it tests | fork oracle (exhaustive) | upstream | Lean (exhaustive) | Class | Proposed lane |
|---|---|---|---|---|---|---|---|
| `order3.c` | nolibc | 3 unsequenced calls → 6 interleavings, each a DISTINCT value (digits of the call order + 6) | `EXECUTION 0:` `Specified(129)` / `1:` `138` / `2:` `219` / `3:` `237` / `4:` `318` / `5:` `327` (full lines: `Defined {value: "Specified(129)", stdout: "", stderr: "", blocked: "false"}` …) | identical, same order | identical, same order | AGREE — ORDER IDENTICAL on a 6-way enumeration | exec nolibc MATCH (6-verdict sequence) |
| `order2.c` | nolibc | 2-way | `EXECUTION 0:` `Specified(12)` / `1:` `Specified(21)` | same | same | AGREE (order identical) | exec nolibc MATCH |
| `order_ptreq.c` | nolibc | the memory model's own `msum` fork (`eq_ptrval` differing provenance, impl_mem.ml:1877-1880 / `CerbMem.eqPtrval`) | `EXECUTION 0:` `Specified(10)` / `1:` `Specified(10)` | same | same | AGREE (2 traces both sides; values coincide because `&x+1 != &y` here — the fork itself is the witness) | exec nolibc MATCH |

Single-trace modes (verbatim, `.tmp/z2/nd_first.log`; oracle = fork, `--nolibc --exec --batch`):

- oracle with NO `--mode` (3 runs): `Specified(327)`, `Specified(138)`, `Specified(318)` — the DEFAULT mode is `Random` (`backend/driver/main.ml:438-441`: `Arg.(value & opt (enum ["exhaustive", Exhaustive; "random", Random]) Random & info ["mode"] …)`), and it is genuinely random across runs.
- oracle `--mode=random` (5 runs): `138`, `237`, `129`, `138`, `318`.
- Lean `--batch --first` (3 runs): `Specified(327)` ×3 — deterministic, and it is the LAST execution of the exhaustive order (`EXECUTION 5`), not the first.

[AGENT] classification: INSTRUMENT (no execution discrepancy — exhaustive order and set agree). Two notes for the lanes: (i) no oracle mode reproduces Lean's `--first` pick, so a `--first` lane is sound ONLY on single-verdict programs, and only an exhaustive run can establish single-verdict-ness — the lanes that pair Lean `--first` with an oracle single run must state that precondition (or run the oracle exhaustive and require one execution); (ii) `--first` follows the FIRST branch at every choice point (`CerbND.lean:210` `| (_, branch) :: _ => runND1Fuel fuel branch st'`); that trace is the one both engines' exhaustive enumeration prints LAST (`EXECUTION 5`), i.e. the batch printing order is the reverse of the branch order on both sides — consistent, but worth a one-line note in `Main.lean`'s `--first` help text.
