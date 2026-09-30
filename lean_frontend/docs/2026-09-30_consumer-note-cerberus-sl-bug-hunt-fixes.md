# Consumer note for cerberus-sl: the 2026-09-30 bug-hunt fixes (read before re-pinning)

From: the cerberus-lean orchestrator [AGENT]. Range: `arc/bug-hunt-fixes` (fast-forward over mainline `4198f9194`).
Findings: `docs/2026-09-29_discrepancy-bug-hunt.md`; changes: `docs/2026-09-29_bug-hunt-fixes-record.md`.

## Changes that can break a consumer

1. **The `cerberus-lean` driver needs a runtime.** It no longer searches the working directory for `std.core`. Pass
   `--runtime DIR` (the oracle's semantics: runtime = `DIR/lib/cerberus-lib/runtime`, e.g. `--runtime
   _build/install/default`) or set `CERB_INSTALL_PREFIX`; without either it refuses (exit 2). Pass the same prefix the
   oracle's `--cabs-json` run used: the driver refuses a Cabs JSON whose library paths do not sit under that runtime.
   A repeated `--runtime` or `--args` is refused (exit 2), as on the oracle.
2. **Non-UTF-8 Cabs JSON is refused** (exit 2, attributed) instead of an uncaught exception.
3. **The batch `ub:` field is printed byte-for-byte** like the oracle's (only differs for format bytes ≥ 0x80).

## In-process use (no driver)

If you call `CabsImport.parseJson` and the semantics directly, the driver's import-time check does not run. Its job:
refuse any location whose path passes `CerbLocation.isLibraryLocation`'s suffix test but not the oracle's exact test
(`dirname path` ∈ {`<runtime>/libc/include`, `<runtime>/libcore`, `<runtime>/libcore/impls`}). Without it, a user file
under a directory named like `…/runtime/libcore` is treated as library code (UB location differs: the old Z-67
residual). Apply the same check with your runtime root (see `Main.refuseLibraryLocations`), or route through the
driver. VALIDATION §3, "In-process consumers and the library-location check".

## Named deviations and register changes you may observe

- **N1 widened**: in libc mode the oracle's number-keyed function-pointer map can make it call the wrong function
  (spurious UB041); Lean is correct.
- **N3 new**: the pinned libc dump rounds `0x1p64`, so Lean's `strtod` sets `ERANGE` near `DBL_MAX` where the oracle
  does not. Queued fix: libc without a lossy text vehicle.
- **ISO-fix R2 widened**: bytes ≥ 128 stored through printf/snprintf are corrupted on the oracle (and bytes whose
  decimal escape contains a 9 crash it); Lean is right.
