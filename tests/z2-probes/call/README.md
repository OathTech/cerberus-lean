# call/ — CerbCall.lean (`--call`) vs the test_verify.sh wrapper TU (Z2, 2026-09-03)

`CerbCall.driveCall` has no OCaml twin; its oracle twin is the TU
`scripts/test_verify.sh render_wrapper` emits (`#define main cerb_fixture_main_`
/ `#include "<file>"` / `#undef main` / `int main(void) { return f(<args>); }`),
run on both oracles in nolibc mode; Lean runs `cerberus-lean --batch --call f
--call-args <ints> <file>.json`. Binaries as in `../mem/README.md`. Classes [AGENT].

| Probe | Lean `--call` | fork oracle (wrapper TU) | upstream (wrapper TU) | Class | Proposed lane |
|---|---|---|---|---|---|
| `bool_param.c` (+ `bool_param_wrapper.c`), `--call f --call-args 2` | exit 1 `Undefined {ub: "UB012_lvalue_read_trap_representation", stderr: "", loc: "tests/z2-probes/call/bool_param.c:6:25-26"}` | `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | same | **BUG-FIX (harness fidelity), CONFIRMED** — charter Z-60: `CerbCall.lean:36-40` declares "the call-site `conv_int` range conversion is NOT reproduced — an injected integer must fit the parameter type" but nothing ENFORCES it (`:94-103` stores the raw value; `CerbMem.loadM:1978-1984` then trips the `_Bool` trap check), where the wrapper's call site converts `2` → `1` (`translation.lem:948-953` → `std.core:32-33`). Fix: reproduce `conv_int` at injection (M) or refuse out-of-range / non-{0,1} `_Bool` injections loudly with an attributed message (S) | test_verify call-point row (three-way) — RED until fixed |
| `errno_order.c` (+ `errno_order_wrapper.c`), `--call f --call-args 1` | `Defined {value: "Specified(65528)", stdout: "", stderr: "", blocked: "false"}` | `Defined {value: "Specified(65524)", stdout: "", stderr: "", blocked: "false"}` | same | **BUG-FIX (harness fidelity), CONFIRMED** — `CerbCall.lean:182-184` allocates the 4-byte `errno` object inside `callFinish`, AFTER `injectArgs` (`:227-229`); `driver.lem drive` allocates errno BEFORE `main`'s argument temporaries (`translation.lem:964-966` `pcreate … PrefFunArg`), so the parameter object sits 4 bytes higher on the oracle (65524 vs 65528 = the errno slot). Any address-dependent value differs. Fix (S): allocate errno first in `driveCall` | test_verify call-point row — RED until fixed |

Derived: 2 probes, 2 CONFIRMED Lean≠wrapper-oracle (both `--call`-harness only, not matched-mode C).
