# ZERO-DISCREPANCY Z2 — consumer change manifest (for refined-cerberus / cerberus-heaplang)

Date: 2026-09-04. Branch `arc/zero-discrepancy-z2`, slice Z2 (the seam-by-seam
fix phase). Audit (read phase): `docs/2026-09-03_zero-discrepancy-Z2-audit.md`;
slice record: `docs/2026-09-04_zero-discrepancy-Z2-record.md` (§7 is the
authoritative API table; this manifest is its consumer-facing reading, by
the orchestrator [AGENT]). Rulings applied mid-slice: the kind-1/kind-2
split of one-sided oracle crashes (`docs/2026-09-03_logical-semantics-referent-ruling.md`,
on branch `docs/no-magic-values`).

`drive`'s signature and the `CerbND` runners are UNCHANGED. Every change
below is a mirror of upstream Cerberus at a cited `file:line`, or an
in-code declaration with its reachability argument (`grep
"zero-discrepancy Z2-" lean_frontend/*.lean` lists them all).

## 1. What moves for a consumer that pins `drive`

- **Answers change only where Lean was wrong against the oracle**: the
  `IntN_t`/least/fast/Intmax/Intptr aliasing in `CerberusImpl` (a direct
  `__cerbty_int32_t` operand no longer panics); `inf`/`nan` literals in
  the libc Core dump parse as floats (`strtod("1e5000")` now equals the
  oracle); `lseek` with an invalid whence answers EINVAL like SibylFS;
  the remaining CerbMem mirrors (charter rows Z-13…Z-22: no size/align
  clamps, `PrefMalloc` recorded on `allocate_region`, `bytes_of_int`
  asserts, `eff_array_shift_ptrval` incl. its UB046 arm, zero-size
  reconstruct, unspecified-pointer ctype qualifiers dropped, realloc
  loc, the `MerrOther` texts).
- **Deliberate model fail-stops are now `panic!` where they were
  values** (kind 1): `allocate_object` with a requested address,
  `bytes_of_int` out of range, the CHERI intrinsics, `concurReadIval` — in
  process these DENOTE the `Inhabited` default until the typed-outcome
  pass (`docs/2026-09-03_typed-failure-outcomes-ruling.md`); treat inputs
  reaching them as PROVISIONAL, as before.
- **`integerDiv_t`/`integerRem_t`/`integerRem_f` are TOTAL** (unchanged from
  mainline: `Int.tdiv`/`Int.tmod`/`Int.emod`, `CerbMem.lean` — the fix-group-1
  panics were reverted in `5ed6c4a0a`); a zero divisor is the pending §10.1
  decision, not a kind-1 fail-stop (pre-merge audit F1).
- **`aligned_alloc(0, n)` is a PENDING decision** (record §10.1): the
  oracle's `Division_by_zero` is kind 2, so it is NOT mirrored; Lean
  currently answers `Undefined DUMMY(align_alloc)` for `(0, 8)` and a
  loud refusal for `(0, 0)`, pinned as such; the principled answer is a
  shared-model change under operator ruling.
- **Locations**: `PEundef`/`Action` nodes of std.core/impl carry exact
  line/column now; `CerbLocation.stringFromLocation` gains the cursor
  suffix (rendering only).

## 2. API-visible signature changes (from record §7)

| Module | Change |
|---|---|
| `CerbMem` | `intToBytes signed val size` (new leading `signed : Bool`); NEW `allocator`, `zLogand/zLogor/zLogxor`, theorems `eqIval_isSome`/`ltIval_isSome`/`leIval_isSome`; `allocateObject` consumes `reqAddrOpt` (fail-stop on `some`); `allocateRegion` ignores `pref`; private `toUnsigned`/`toSigned` deleted; other listed functions keep their types |
| `CerberusImpl` | NEW `n_t_aliases`, `aux_ibty`, `sizeof_pointer`, `alignof_pointer`; DELETED `sizeof_integerBaseType`; `normalise_integerType` moved earlier, new arms |
| `CoreParser` | `pImplConstant : String → Except String implementation_constant`; `stampLibraryFile (file input : String) (cf : CoreFile)`; NEW `RelocCtx`, `relocFile`, `lineTable`, `resolveByte`; `parseFile`/`parseLibraryFile`/`internSym` unchanged; an anonymous `a_N` tag interns to the same symbol as `__cerbty_unnamed_tag_N` |
| `CerbCall` | `driveCall` UNCHANGED; `injectArg(s)`, `lookupFunBody`, `lookupParamTys` DELETED (the `--call` entry now renders the elaborated call site); NEW helpers listed in record §7; `callFinish` re-typed |
| `CerbLocation` | `stringFromLocation` output gains the cursor suffix (same type) |
| `CerbDecode` | imports `CerberusImpl`; `decode_integer_constant ""` panics |
| `CerbFS` | `fs_lseek` same type (EINVAL on whence ∉ {0,1,2}); `fs_write`/`fs_pwrite` refuse a vanished path |
| `Main` | batch error texts mirror `pp_errors` (binary only) |
| `CerbStepInstances` | uses `ctype.beq_derived` |

## 3. Unchanged

`drive`, `drive_lemFuel`, `CerbFuel.*`, `CerbND.*` runners and lemmas,
every generated module (lem pin unchanged at `3c88f0d`), the memory
representation. The fuel-parameter arc (lem-lean `arc/fuel-parameter`)
is the NEXT re-pin and is the one that changes the reasoning interface
(`[LemFuel]`); this slice does not.

## 4. Gate evidence

Worker battery: record §11 (29/29 lanes, verbatim). Orchestrator re-run:
the boundary-review section appended to the record.
