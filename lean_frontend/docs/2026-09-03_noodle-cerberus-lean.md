# Noodle report — semantic-discrepancy hunt over cerberus-lean (2026-09-03)

Branch `noodle/semantics` @ base mainline `72164481a`. Charge [USER
2026-09-03], verbatim: "poke and prod at everything that might be wrong
about every surface, and expose subtle errors that we haven't spotted
yet. Mostly the noodlers should focus on semantic discrepancies we might
not have spotted. All of the known discrepancies are not of interest.
We're strictly trying to shake out weirdness that needs fixing."
Addendum [USER 2026-09-03]: every probe suite-ready, integration
recommendation per probe (never integrated here).

INVESTIGATION ONLY: no product code, gate, baseline or doc other than
this record was modified. Probe corpus + runner: `tests/noodle-probes/`
(per-area `results.log` = the verbatim three-engine pins). Binaries:
freshly rebuilt in this worktree from `72164481a` (`make
lean-prelude-src`; `build_cerberus` with DUNE_CACHE=disabled;
`build_lean`; driver-freshness stamps recorded by the helpers). Native
referee: gcc 13.3.0 `-O0 -w`.

Exclusion registers honoured (anything on them is NOT a finding here):
`docs/2026-08-30_parity-detective-report.md`, `tests/immaculate/
baseline.txt`, `docs/upstream-tray/INDEX.md` (18), `scripts/
gcc_oracle_triage.txt`, the fuel ceiling, the ~8M zero-init hang,
PVI-not-PNVI, the concurrency stubs, CerbFS (fail-closed).

Classification: DISCREPANCY (Lean != oracle, both accept) /
ORACLE-SUSPECT (Lean == oracle, both != ISO/gcc on deterministic UB-free
input) / ODDITY / EXCLUDED-KNOWN. Judgments are [AGENT]; quoted engine
lines are verbatim; tallies marked derived.

## 0. Findings register (running; ranked at the end)

### D1 — DISCREPANCY (diagnostic field): UB `loc` lost for UBs raised while executing std.core code

Both engines give the same UB verdict, but the batch line's `loc` field
differs — the oracle reports the C source site, Lean reports `unknown
location`. Every differential harness strips `loc` before comparing
(`extract_verdict_seq` greps `ub:` only), which is why this never
surfaced. Reproducers (nolibc), verbatim:

    tests/noodle-probes/float/float_inf_to_int_ub.c
    oracle: Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
    Lean:   Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "unknown location"}

    (scratch, printf("%d\n") with no argument)
    oracle: Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "<2:18--2:32>"}
    Lean:   Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "unknown location"}

Control (same run): UBs raised from C-derived Core keep the C loc on
both (UB036, UB045c, UB043, UB052a, UB51b, UB045b all print
`file:L:C-C` on Lean).

Mechanism [AGENT, localized]: the OCaml Core parser stamps every
std.core expression, including `undef(<<UB>>)`, with a region located
IN std.core (`parsers/core/core_parser.mly:1571`, `Aloc (region ...)`
+ `PEundef (region ...)`), and std.core lives under `runtime/libcore`,
so `Cerb_location.is_library_location` (util/cerb_location.ml:512)
holds for it. The shared .lem then (a) substitutes the enclosing C
location for library-located undefs (`frontend/model/core_eval.lem:
596-603`: `if Loc.is_library_location undef_loc then loc else
undef_loc`) and (b) refuses to overwrite the thread's `current_loc`
with a library location (`core_run.lem:778-784`). The hand-written
Lean Core parser instead stamps `Loc.unknown` everywhere
(`lean_frontend/CoreParser.lean:201` `loc0 := CerbLocation.unknown`,
`:204` `annots0 := [Aloc loc0]`, `:1097` `PEundef loc0 ub`);
`CerbLocation.isLibraryLocation unknown = false` (CerbLocation.lean:
180-185), so on Lean (a) keeps the unknown loc and (b) overwrites
`current_loc` with unknown whenever std.core code runs. Affected: UB017
(std.core:90 `loaded_ivfromfloat`), the printf-family UBs (UB153a/b,
UB158, Invalid_format — raised in the driver with `current_loc`), and
in principle the 47 `undef(<<DUMMY(...)>>)` sites and any memory-op UB
inside a std.core proc. Not affected: `catch_exceptional_condition`'s
UB036 (a pure `fun`, C loc preserved — verified).

Suggested fix (S): make CoreParser stamp std.core nodes with a region
whose file is the std.core path (mirror core_parser.mly:1571 — any
`Loc.region` with a `libcore/`-segment filename satisfies
`isLibraryLocation`), or, cheaper but less faithful, have the loader
tag the parsed file's `Aloc`s as library. Verification: the two
reproducers above print the oracle's `<L:C--L:C>` positions modulo
the already-different rendering (see O1).

### O1 — ODDITY (presentation): batch `loc` rendering differs by design

Oracle `Cerb_location.simple_location` renders `<5:11--5:19>` (no
file); Lean `CerbLocation.stringFromLocation` renders
`file.c:5:11-19`. Never compared by any harness; noted so D1's fix has
a stated target (matching the verdict AND, ideally, the rendering).
[AGENT] defensible; a one-line printer change if parity is wanted.

### F1 — ORACLE-SUSPECT (intended gap, upstream TODO): `float` is evaluated AND stored as double; `sizeof(float) == 8`

Both engines, verbatim (`tests/noodle-probes/float/float_single_precision.c`):

    oracle/Lean: Defined {value: "Specified(0)", stdout: "0 100000000 1 16777217 1 0 1 0\n", ...}
    gcc:         1 100000001 0 16777216 0 0 1 1

i.e. `0.1f+0.2f == 0.3f` is false, `(int)(float)16777217` is 16777217,
`(double)(float)0.1 == 0.1` is true. And (`scratch szf.c`):
`sizeof(float)`, `sizeof f`, `sizeof(1.0f)`, `sizeof(f+1.0f)` all print
8 on both engines (gcc 4). Root: `ocaml_frontend/ocaml_implementation.
ml:206-208` `RealFloating Float -> Some 8 (* TODO:hack ==> 4 *)` and
the OCaml-float representation of every floating type
(impl_mem.ml:1155 stores `Int64.bits_of_float` over `sizeof fty`
bytes). ISO: 6.3.1.5 (cast/assignment to float removes extra range and
precision even under FLT_EVAL_METHOD 2), 5.2.4.2.2. Consequence for
the trust story: the differential lanes can never see a float-rounding
bug on the Lean side because the model has no float rounding — the gcc
lane is the only referee, and any probe on this class lands in a
TRIAGED skip. Fix (upstream, M): a Float32 arm in `fvfromint`/
arithmetic/store (round through a 32-bit representation) + `sizeof_fty
Float = 4`; Lean mirrors via CerbFloat. Not a Lean-side action.

### F2 — EXCLUDED-KNOWN (tray 15 class): `(int)NaN` crashes both engines instead of UB017

`tests/noodle-probes/float/float_nan_to_int_ub.c`: oracle exit 125
`Z.Overflow` at `impl_mem.ml:2554 ivfromfloat`; Lean exit 134 `PANIC
at CerbFloat.truncToInt CerbFloat:302:4: nan/inf (OCaml Z.of_float
raises Z.Overflow)` — deliberate message-level parity. Tray 15 already
records the non-finite crash class. Recorded only as an immaculate
crash-pair candidate.

### E1 — ODDITY (oracle ISO-correct, gcc extension): enum constant outside `int` rejected

`tests/noodle-probes/int/int_enum_underlying.c` (`enum { A =
0xFFFFFFFF }`): oracle `constraint violation: integer constant not in
the range of the representable values for its type` (§6.7.2.2p2 cite
in the diagnostic is 6.6#4); Lean `Error {msg: "desugaring failed at
...:4:15-25"}`; gcc accepts (extension, sizeof 4/8). Both-reject,
consistent. Not a finding.

## 1. Coverage (running)

| Area | Probes | oracle==Lean | Findings |
|---|---|---|---|
| Integer semantics | 17 (`tests/noodle-probes/int/`) | 16/16 accepted AGREE (11 value, 5 UB-code), 1 both-reject | E1 |
| Floating point | 11 (`tests/noodle-probes/float/`) | 10/10 AGREE + 1 both-crash | D1, O1, F1, F2 |

(continued below as shards complete)
