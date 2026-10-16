# Stop paths — inventory and options for Q-A (default-path consistency) and Q-B (the global controlled-outcome policy) (2026-10-08)

**Status: READ-ONLY INVENTORY + OPTIONS NOTE. It decides nothing.** Pre-design input for the operator, who scopes
the actual design pass after reading it. Branch `docs/stop-paths-inventory-20261008` over mainline `c4284b08f`.
Author: the inventory agent [AGENT]. No build, lake, dune, make, opam or release.py was run; the oracle was not
executed. Every claim is tagged **[AGENT]** (this agent's reading or judgement) or **MEASURED** (a read-only
command run in this pass, listed with its verbatim output in §8; cells that cite a register row, a baseline row or a
grep count are MEASURED). The only [USER] rulings cited are the ones the brief supplied and the ones already in committed
docs, each with its source. This worktree carries no `lean_frontend/generated/` tree, so generated-tree
sites are taken from the sealed register `scripts/failure_reach_register.txt` (the gate's own inventory), not from
a grep of generated text.

## 0. Summary — read this first

- **Q-A (default-path consistency).** Hand-written seams on the DEFAULT exec path carry **79 (A)-shaped sites** that
  mirror an upstream `failwith` / `assert false` / uncaught exception: 45 pure `failwithI` sites in `CerbMem.lean`
  (register rows), 7 monadic fail-stops in `CerbMem.lean` (C-TF1's typed kills, NOT in the register — one of them is
  R-PNVI-09), and 27 pure sites in six other seams. Reach (register classes, MEASURED): **10 REACHABLE** with
  committed both-crash witnesses, **4 UNKNOWN**, **6 UNREVIEWED** (monadic, outside the pure-site census),
  **59 UNREACHABLE-BY-INVARIANT**. Plus **(B) 3** print-then-kill/crash/UB sites, **(C) 2** "FIXME: This is wrong"
  function-pointer arms, **(D) 10** question-TODOs on defined arms. The generated tree holds **128** further
  (A)-by-construction rows (shared `.lem` `failwith`s both engines run; 5 REACHABLE, 14 UNKNOWN, 109 UNREACHABLE) that
  a Lean-side sweep cannot touch without the lem failure-monad arc. Already refusals today (not in the sweep):
  **37 sites** (CerbFS 25, PNVI 11, `CerbFloat.formatFixed` 1). §3.
- **Q-B (every non-verdict way a run ends).** **16 distinct outcome kinds** today, on **four wire shapes**: exit 2 +
  stderr `cerberus-lean: refused — …` (CLI), exit 134 + stderr `PANIC at _private.LemLib.0.failwithIImpl …: <msg>`
  (every pure `failwithI`: refusals AND mirrored crashes, told apart only by message prefix), exit 1 + stdout
  `ModelFailure {msg: …}` (the 7 C-TF1 typed kills), and exit 1 + a verdict-shaped `Error {msg: …}` line (fuel
  kill, OOM kill, the 12 config-dead switch kills, the asm desugar refusal, CLI usage errors). cerberus-sl's theorems
  name exactly two of the sixteen: `.Killed st CerbND.fuelExhaustedKill` and `Interface.oomOutcome`. §4.
- **The structural fact that bounds every Q-B option [AGENT]:** a PURE site (CerbFS's 25, the PNVI pure refusals,
  `formatFixed`, the 45+27 default-path mirrors) has no channel but `failwithI` — a typed outcome there needs a type
  change (the parked twin design / the queued lem failure-monad arc). Only MONADIC sites (9 today) can carry a typed
  kill cheaply. So a GLOBAL controlled outcome as one MECHANISM is not available now; a global PROTOCOL (one message
  grammar, one classifier, one exit-code table) is. §5.0.
- **Prior art that already answers most of Q-B** and must not be re-derived here: the 2026-09-16 scoping note and
  implementation plan R1 (`Stopped of interp_stop = Exhausted | FailStop of string | Unsupported of
  unsupported_feature * string` on both shared outcome types; its S0 prototype `arc/lean-only-outcomes-S0` @
  `8f8c4dfe7` unmerged by design; WP-O → WP0 → S1-pre → WP1 → WP2 queued, none executed — §2). Its WP2 IS the
  "refusals" work package. A new opaque atom for refusals (option 2a below) is exactly what that note rejected.
- **Recommended option for Q-B [AGENT]: Option 3 now (the protocol), Option 2b later (the queued plan's
  `Stopped (Unsupported …)`), never 2a; 2c (pure sites) belongs to the lem failure-monad arc.** Keeping (a) as the
  MECHANISM is the ruling; making the TEXT protocol global is the cheap "global policy" (a) admits. §5.5.
- **Interaction:** fix the protocol first (one helper, one grammar, one codec rule), then run the Q-A sweep once
  through it, so every site is touched once now and ZERO times when the mechanism changes (the helper changes, not
  the sites). §6.
- **Open questions:** 12, each with a recommendation. §7.

## 1. Rules this note respects

- **No innovation versus upstream**, [USER 2026-10-03] (as recorded in `docs/2026-10-04_pnvi-ae-udi-design.md` §1.1):
  the fork does not innovate with respect to Cerberus upstream unless something is very obviously a bug; it is
  poorly placed to resolve semantic discrepancies, so it does not, and falls back to loudly rejecting (either as
  unsupported, or matching upstream). Also: Cerberus TODO cases are not resolved unless the answer is extremely
  obvious or there is a similarly obvious bug. Both sanctioned shapes — mirror the crash, or refuse
  as unsupported — appear in the inventory; this note never proposes a third behaviour for a defined arm.
- **No magic modes**, [USER 2026-09-30] (same source §1.1): deviations are not fixed with special magic-mode paths
  that work only in one situation. Applied: no option below proposes a stop that fires only under one
  caller or one flag.
- **The PNVI rulings this note is downstream of**, [USER 2026-10-05], design §1.4: the recommendations accepted
  except for mirroring crashes and obviously wrong behaviour, which should be refusals; and design §H: item 1
  agreed; item 2 should in the end be made consistent, but is fairly minor; for item 3, if (b) is done it should be
  a global policy, which need not be a refusal as such but must not be an uncontrolled crash, and (a) is fine for
  now. (a) = the CerbFS shape (`failwithI "… refused — …"`, exit 134 under
  `LEAN_ABORT_ON_PANIC`); (b) = a dedicated controlled outcome.
- **The consumer's relied-on items** (VALIDATION §3b, the consumer's statement of 2026-10-03; MEASURED in §5.4):
  the run outcomes `CerbND.runNDFuel`, `.Killed st CerbND.fuelExhaustedKill`, `Interface.oomOutcome = DErr_memory`;
  the address-space-top parameter; the run digest; the enum reader; the fail-closed arity matcher. None may change
  without cerberus-sl's agreement.
- **Gates**, [USER 2026-10-07] (`docs/2026-10-05_pnvi-s1-switch-parameter-record.md` §14): a classic case of gate
  cruft; gates are not to be adversarially robust unless they are trust surfaces; revisit for what is actually
  proportionate. Applied: nothing below proposes a new
  gate; the one lane whose behaviour an option moves is a TRUST SURFACE (row 14, `test_pnvi.sh`) and is named.
- **The contract**, CONTRACT §1 (adopted [USER 2026-09-28], D1 agreed): an execution ends in exactly one of (1) the
  oracle's verdict, (2) "A loud refusal — a nonzero exit and a message that names the unsupported feature and the
  boundary it belongs to", (3) a resource outcome, (4) a registered deviation. "There is no fifth outcome." Every
  kind in §4 is placed against this list.

## 2. Prior art (the typed-failure lineage) — what is already decided, what is queued

[AGENT] reading of committed records; each line cites its source. Q-B is NOT a fresh question; it is the refusal
chapter of an arc that has a design, a review, a prototype and a plan.

| Date | Record | What it settled | Status today |
|---|---|---|---|
| 2026-09-03 | `docs/2026-09-03_typed-failure-outcomes-ruling.md` | [USER 2026-09-03] ruled that the structure should give consumers of the semantics the property that matters, conformance to the OCaml oracle, hence fail-closed into the correct behaviour. A failure site must denote a distinguished outcome, never a default value. Interim rule: mirror one-sided oracle crashes as a panic with the OCaml text. | ruling stands |
| 2026-09-05 | `docs/2026-09-05_typed-failure-outcomes-design.md` R0/R1 | [USER 2026-09-05] agreed with decision 4 as the lowest-risk approach: MONADIC sites first through their monads' kill channel; PURE sites = hygiene + a sealed register + gate (interim). | R1 applied |
| 2026-09-07 | `docs/2026-09-07_pure-failure-reachability-census.md`, `…correspondence-design.md` | Census option C (status quo + register); the twin design PARKED with named flip conditions (a DISCARDABLE reachable site; a REACHABLE step-level site where the oracle succeeds; growth of the well-typed-reachable set beyond 4; a ruling valuing the logical property over oracle conformance). | parked; register = the tripwire |
| 2026-09-08 | `docs/2026-09-08_monadic-failstop-record.md` (C-TF1) | Seven `memM` `panic!` arms → `CerbFail.failStopMem` = `kill (Error0 modelFailStopLoc msg)`; batch record `ModelFailure {msg}` exit 1; codec `MODEL_FAILURE` → CRASH class. | LANDED |
| 2026-09-16 | `docs/2026-09-16_structural-outcome-constructors-design.md` (D2 R0) | B′ (constructors on the `Loc` mirror type) WITHDRAWN — [USER 2026-09-16] expressed wariness of epicycles and asked for the overall design and orientation with respect to the oracle to be revisited. | SUPERSEDED |
| 2026-09-16 | `docs/2026-09-16_lean-only-outcomes-scoping-note.md` R0+R1, `…review-response.md`, `…implementation-plan.md` R0+R1, `…S0-checkpoint-record.md` | Recommendation **B**: `Stopped of interp_stop` on BOTH shared outcome types (`kill_reason`, `Undefined.t`), `interp_stop = Exhausted \| FailStop of string \| Unsupported of unsupported_feature * string`; "A third opaque atom would make three unprovably-distinct `Error0`s" (D2 R0 §1 item 3); the codec's `refusal(prefix)` / `model refused: ` text convention named as the thing to replace. [USER 2026-09-16] approved landing the docs branch and running the slice → S0 prototype run (`arc/lean-only-outcomes-S0` @ `8f8c4dfe7`, unmerged by design). Plan R1: WP-O (pristine-oracle instrument, [USER 2026-09-16] directed that it be added before further work is executed) → WP0 (lem-lean `inhabited_exclude`) → S1-pre → WP1 → **WP2 refusals**. Consumer cost measured in S0: 12 constructor-match blocks + 1 literal + 18 alias uses (then refined-cerberus; cerberus-sl recounted in §5.4 below). | docs LANDED; WP-O/WP0/WP1/WP2 QUEUED, none executed (MEASURED: `interp_stop`, `Stopped`, `KillKind`, `CerbRefuse` absent from `lean_frontend/*.lean`, `frontend/model/*.lem`, `scripts/`); listed as queued item 2 in `docs/2026-09-19_concurrency-pause-note.md` §4 |
| 2026-09-30 | ruling D1 in lem-lean's linksem findings record (`doc/lean-backend/2026-09-28_linksem-findings.md`, Native seams) and [the 77ad4fa re-pin record](2026-09-30_lem-repin-77ad4fa-record.md) §4 ([USER 2026-09-30] agreed to D1) | The lem Lean backend should eventually emit fallible functions in an error monad (effect analysis), replacing the temporary `lemSeq` seam — the only route by which PURE failure sites gain a typed outcome. | QUEUED; needs its own design pass |
| 2026-10-05/07 | design §G/§H, S3/S4 records | PNVI-path (A)/(B)/(C) → refusals in shape (a) (`pnviRefusal`, `pnviRefuseM`); default path untouched; §H ruling 2 and 3 → this note's Q-A and Q-B. | LANDED (S4) |

Consequence [AGENT]: the "dedicated controlled outcome" of §H ruling 3 already has a designed, reviewed and
prototyped shape — `Stopped (Unsupported feature detail)` — and a queued slot (WP2). This note's job for Q-B is
therefore to (i) inventory what WP2 would convert, (ii) say what can be done BEFORE WP2 under shape (a), and (iii)
say what WP2 cannot reach (pure sites) so the operator is not surprised later.

## 3. Q-A inventory — the DEFAULT exec path, every mirrored stop

### 3.0 Method (MEASURED; commands in §8)

- Pure sites: the sealed register (`scripts/failure_reach_register.txt`, header tally line verbatim:
  `# tally: sites=239 exec=237 unresolved-owner=2 reviewed-TAIL=176 reviewed-NON-TAIL=63 UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22 discardable=0`),
  cross-read against a `grep -n` of `failwithI|failStopMem|pnviRefusal|pnviRefuseM|oomKill` over
  `lean_frontend/CerbMem.lean` at `c4284b08f` (Lean line numbers below are THIS tree's) and the `impl_mem.ml`
  cites each Lean site carries in-code.
- Monadic sites (`failStopMem`, `CerbFail.failStopKill`, `pnviRefuseM`, the switch-gated kills): grep only — the
  register is a PURE-site census (its header: "the pure failure sites (`failwithI`/`panic!`)"); their reach is
  UNREVIEWED unless a lane row witnesses them (CONTRACT §3 says the same of R-PNVI-08/-10).
- Upstream forms: `grep -n -E 'failwith|assert false|Printf\.printf|Printf\.fprintf|prerr_endline|print_endline|FIXME|HACK' memory/concrete/impl_mem.ml` over `:277-2830` (the design's own window), read against the function bodies.
- Reach witnesses: the register's `need/invariant/witness` column; the committed baselines `tests/immaculate/baseline.txt`
  (31 rows carry a crash token: 18 `MATCH | L=CRASH`, 6 `DIFF | L=CRASH`, 7 `ORACLE_CRASH | L=<verdict>`),
  `scripts/gcc_oracle_baseline.txt` (18 `SKIP_LEAN_CRASH`), `scripts/exec_coverage_baseline.txt` (2 `UNSUPPORTED`),
  `tests/pnvi_lane/baseline.txt` (7 `REFUSAL` rows).
- Classification scheme: design §G.0's (A) upstream crash / `failwith` / `assert`; (B) debug-print-then-kill; (C) a
  defined arm upstream itself says is wrong; (D) a defined arm whose TODO is only a question — proposed [AGENT].

### 3.1 CerbMem.lean — PURE (A) mirrors on the default path (45 register rows; MEASURED rows, [AGENT] class)

Shape today for every row: `failwithI "<OCaml text or a Lean paraphrase citing the OCaml site>"` → under
`LEAN_ABORT_ON_PANIC` a `PANIC at _private.LemLib.0.failwithIImpl …` on stderr, SIGABRT, exit 134; in-process the
opaque `default` (LemLib: `@[implemented_by failwithIImpl, never_extract] opaque failwithI … := default`).

| Lean (`CerbMem.lean`) | OCaml (`impl_mem.ml`) | Upstream form | Reach (register) | Witness / invariant (register text, abridged) |
|---|---|---|---|---|
| :436 `targetPtrSize` | :2182 | `failwith "… complete implementation sizeof POINTER"` | UNREACHABLE-BY-INVARIANT | LP64 `sizeof_pointer = some 8` |
| :531 `offsetsof` unknown tag | :1067/:1073 `Pmap.find` | uncaught `Not_found` | UNREACHABLE | typing: complete struct types are in `tagDefs` |
| :559 / :560 / :562 `sizeofCtype` Void / incomplete array / function | :134-135 | `assert false` ×3 | UNREACHABLE ×3 | `sizeof` of an incomplete type is a constraint violation (GenTyping) |
| :566 / :570 `sizeofCtype` INTEGER / FLOAT `none` | :1196 (shape) | `failwith "the concrete memory model requires a complete implementation"` | UNREACHABLE ×2 | kernel-provable: `CerberusImpl.sizeof_ity/fty` never `none` |
| :594 `sizeofCtype` Union tag not UnionDef | (`Tags.tagDefs` lookup) | `assert false` / `Not_found`; oracle text `Failure("Tags definitions must be set…")` | **REACHABLE** | `tests/immaculate/nolibc/offsetof-union-member.c` — both crash; "WELL-TYPED UB-FREE C — a model bug (upstream asymmetry, tray candidate)"; baseline `offsetof-union-member MATCH \| L=CRASH` |
| :612 / :614 `alignofCtype` Void / function | :198-199 / :216-218 | `assert false` ×2 | UNREACHABLE ×2 | as sizeof |
| :618 / :622 `alignofCtype` INTEGER / FLOATING `none` | (shape :1196) | `failwith` ×2 | UNREACHABLE ×2 | kernel-provable |
| :643 / :654 `alignofCtype` Struct / Union tag kind | — | `assert false` / `Not_found` | UNREACHABLE ×2 | tag-kind consistency (desugarer invariant) |
| :736 / :737 `bytesToInt` `[]` / `> 16` | :777-780 | `assert false` ×2 | UNREACHABLE ×2 | LP64 integer sizes 1,2,4,8 |
| :781 `splitBytesProv` empty | :434 | `failwith` | UNREACHABLE | sizeof ≥ 1 |
| :951 / :963 `memValueToBytes_lemFuel` INTEGER / FLOAT `none` | (shape :1196) | `failwith` ×2 | UNREACHABLE ×2 | kernel-provable (two further textual twins at :1079/:1088 sit in `memValueToBytes_append_lemFuel`, which has NO register row — outside the exec closure, MEASURED) |
| :1330 `reconstructValueAbst` unknown function pointer | :1049 | `failwith ("unknown function pointer: " ^ …)` | **REACHABLE** | `tests/failure-probes/reach/funptr_reload.c` — both crash; "input class IMPLEMENTATION-DEFINED (int→function-pointer conversion, §6.3.2.3p5; no call, no UB)" |
| :1419 unknown struct tag | :1067/:1073 | `Not_found` | UNREACHABLE | typing (load ctype complete) + dominance (sizeof first) |
| :1439 empty UnionDef | :1114 (`UnionDef ((first_membr_def :: _) as membrs)`) | match failure | UNREACHABLE | C forbids empty unions |
| :1461 recorded union member not in UnionDef | :1122 | `assert false` | **UNKNOWN** | "needs a memory well-formedness invariant (unionmap records only members of that union)" |
| :1462 Union tag not UnionDef | :1128 | `assert false` | UNREACHABLE | tag-kind consistency |
| :1466 type without a known size | :978-983 | `assert false` | UNREACHABLE | typing |
| :1529 `typeofMval` `MVarray []` | :1161-1162 | `assert false` | UNREACHABLE | zero-length arrays rejected |
| :1616 `casePtrval` (the `Prov_device` half) | :1858 | `failwith "case_ptrval"` | **REACHABLE** | `tests/immaculate/nolibc/zd-z2m02-device-funptr-call.c` — both crash; "input class UB (call through a forged function pointer)"; design §G.3 row 3 |
| :1649 / :1658 `maxIval` | :2446 / :2443 | `failwith` / `assert false` | UNREACHABLE ×2 | structural |
| :1675 / :1677 `minIval` | :2475 / :2479 | `failwith` / `assert false` | UNREACHABLE ×2 | structural |
| :1727 `integerDiv_t` | :1967 | uncaught `Division_by_zero` | UNREACHABLE | dominance (IntDiv guarded; sizeof(elem) ≥ 1) |
| :1733 `integerRem_t` | :2481-2482 | uncaught `Division_by_zero` | **REACHABLE** | `tests/immaculate/{libc,nolibc}/zd-z2m01-aligned-alloc-zero*` (3 baseline rows `MATCH \| L=CRASH`) — `aligned_alloc(0, n)`, both crash |
| :1740 `integerRem_f` | :2483-2484 | uncaught `Division_by_zero` | UNREACHABLE | every `rem_f` divisor nonzero |
| :1777 `opIval` IntExp negative | :2490 | `Z.pow` `Invalid_argument` | UNREACHABLE | UB136/137 guards first |
| :1793 `offsetofIval` | :2245 | `failwith "Concrete.offsetof_ival: invalid memb_ident"` | UNREACHABLE | Ail typing |
| :1975 `arrayShiftPtrval` `PVnull` | :2259-2261 | `(* TODO: this seems to be undefined in ISO C *)` … `failwith ("TODO(pure shift a null pointer should be undefined behaviour), offset:" ^ …)` | **REACHABLE** | `tests/minimal/097-null-ptr-arith.undef.c` — both crash; "input class UB"; `gcc_oracle_baseline` `SKIP_LEAN_CRASH`; design §G R9 / §G.3 row 1 |
| :1976 `arrayShiftPtrval` `PVfunction` | :2263 | `failwith "Concrete.array_shift_ptrval, PVfunction"` | **UNKNOWN** | "the tested route ((char*)main + 1) is dominated by `isWellAligned_ptrval` … another route … is not excluded"; design §G R10 / §G.3 row 2 |
| :1999 `memberShiftPtrval` `PVfunction` | :2284 | `failwith "Concrete.member_shift_ptrval, PVfunction"` | **UNKNOWN** | "untested route (((struct S*)main)->x) — bounded effort" |
| :2011 / :2019 `bytefromint` / `intfrombyte` | :2776 / :2780 | `assert` ×2 | UNREACHABLE ×2 | byte range |
| :2238 / :2240 / :2242 / :2244 `deriveCap` / `capAssignValue` / `nullCap` / `ptrTIntValue` | :2220-2235 | `assert false (* CHERI only *)` ×4 | UNREACHABLE ×4 | `CerbGlobal.is_CHERI` is the plain `def false` |

Derived: 45 rows — REACHABLE 5, UNKNOWN 3, UNREACHABLE-BY-INVARIANT 37. (The 46th CerbMem default-path pure row,
`intToBytes` :721, is (B) — §3.4.) Not registered because outside the exec closure (MEASURED: no row): :1688
`concurReadIval` (:2406 `failwith "TODO: concurRead_ival"`), :2246 `cheri_pointer_hash_printf`, :2248
`get_intrinsic_type_spec` (:2187-2188) — dead code for `drive`; listed so the grep reconciles.

### 3.2 CerbMem.lean — MONADIC (A) mirrors on the default path (7 sites; C-TF1's typed kills; no register rows)

Shape today: `CerbFail.failStopKill msg = Error0 modelFailStopLoc msg` inside `NDkilled` (or `failStopMem msg =
CerbFail.failStopND msg`) → batch stdout `ModelFailure {msg: "…"}`, exit 1 (single execution); the codec tokenises
`MODEL_FAILURE` and the immaculate lane pins it as `L=CRASH` ("the typed fail-stop (exit 1)" — `TODO.md` item (c)).
In-process: a kill value, not a default (the point of C-TF1).

| Lean | OCaml | Upstream form | Reach | Note |
|---|---|---|---|---|
| :2514 `allocator` alignment 0 | :1258 `quomod` | uncaught `Division_by_zero` | UNREVIEWED | C-TF1 record: "Alignment zero remains the recorded pending-decision refusal" |
| :2542 `allocateObject` requested address | :1335 | `failwith "TODO: cerb::with_address() is yet implemented"` | UNREVIEWED | needs the fork-only `cerb::with_address` attribute |
| :2668 `killM` dead static free | :1572 | `failwith "Concrete: FREE was called on a dead allocation"` | UNREVIEWED (in-code: "Unreachable from C through malloc/free"; witnessed on both oracles only via libc-body injection, Z-77; `tests/noodle-probes/dynamic-addrs/results.log` carries the text, MEASURED) | design §G.3 last row |
| :3465 `effArrayShiftPtrval` `PVfunction` | :2298 | `failwith "Concrete.eff_array_shift_ptrval, PVfunction"` | UNREVIEWED — design §H.1: "reachability from C unmeasured — the one route tried stops earlier on the oracle" | **R-PNVI-09**, reclassified a default-path look-alike (`std.core:188/196/212/217` emit `PtrArrayShift` in default mode) |
| :3617 `memcmp` non-integer byte | :2703 (in-code cite :2658-2659) | `assert false` | **REACHABLE** [AGENT reading of the baseline]: `g2-memcmp-uninit MATCH \| L=CRASH`, `ts-memcmp-struct-padding MATCH \| L=CRASH` (the C-TF1 record: "immaculate plants replace just the existing memcmp crash witness") | the oracle crashes exit 125, Lean kills `ModelFailure` exit 1 — class (a) both-fail |
| :3813 `va_list` noninitial | :2760 | `assert (n = 0)` | UNREVIEWED | — |
| :3832 `callIntrinsic` | :2190-2191 | `assert false (* CHERI only *)` | UNREVIEWED; config-dead | — |

Two further monadic fail-stops are Lean-only guards, not mirrors (excluded from the (A) count): :2998 (`storeM`:
the allocation resolved for a `Prov_symbolic` store is absent — "unreachable: resolveIota's precondition found it")
and :3551 (`effArrayShiftPtrval`: a `Prov_symbolic` pointer reached the `Prov_some`/`Prov_none` arms — "unreachable:
the `Prov_symbolic` arm matches first"). Both are on the PNVI path only.

### 3.3 The other hand-written seams — PURE (A) mirrors (27 register rows)

| File | Rows | Upstream referent | Reach (register) | Witnesses |
|---|---|---|---|---|
| `CerbDecode.lean` | 7 | `decode.ml:162-200` (invalid/empty/hex/octal char constants) | REACHABLE 2 (one route, two arms), UNREACHABLE 5 | `tests/failure-probes/reach/args_backslash.c` (`--args "a\b"`): both crash; "input class HARNESS BOUNDARY" |
| `CerberusImpl.lean` | 6 | `ocaml_implementation.ml:146-149` (`typeof_enum` miss) + the `assert false` un-normalised arms | UNKNOWN 1 (`lookupEnum`), UNREACHABLE 5 | re-reviewed 2026-09-22 (audit N2): no both-crash pair exists on the oracle route |
| `CerbFloat.lean` | 1 (`truncToInt`) | `Z.of_float` raises `Z.Overflow` | REACHABLE | `zd-z2fl03-nan-to-int MATCH \| L=CRASH`; "input class UB ((int)NaN)" (the file's other row, `formatFixed`, is an existing REFUSAL — §3.8) |
| `CerbUtils.lean` | 4 | `ocaml_gcc_builtins.ml` (`ctz 0`, `bswap16/32` range, `bswap64` `Z.to_int64` overflow) | REACHABLE 1 (`bswap64`), UNREACHABLE 3 | `g4-bswap64-overflow MATCH \| L=CRASH`; "input class LEGAL C (uint64_t ≥ 2^63) — ORACLE-WRONG (tray 12), mirrored" |
| `CerbLocation.lean` | 1 (`outerBbox`) | `cerb_location.ml:109-110` `assert` | UNREACHABLE | constructor discipline (`Loc.regions []` refused at JSON import) |
| `CerbStepInstances.lean` | 8 (`beqCoreStep2` functional-value arms) | OCaml polymorphic `compare` raises `Invalid_argument "compare: functional value"` | UNREACHABLE 8 | only `==` against the nullary `Step_blocked2` |

Lean-only pure leaves on the exec closure that mirror nothing upstream (excluded from the (A) count, listed to
reconcile the register): `CerbFunMapInstances.lean` 1 (phantom instance, UNREACHABLE), `CoreParser.lean` 1
(`scanHashCollisions` fuel-0 arm, UNKNOWN, Core-text route only), `Main.lean` 1 (`loadCoreImpl`, UNKNOWN, harness
code). Existing refusals (`CerbFS.lean` 25, `CerbFloat.formatFixed` 1, the PNVI rows) are §3.8.

### 3.4 (B) — print-then-kill / print-then-crash / print-then-verdict (3 sites)

| OCaml | What upstream does | Lean today | Reach | Shape class [AGENT] |
|---|---|---|---|---|
| :1716-1723 `store` | four `Printf.printf "STORE …"` to the TOOL's stdout, then `fail ~loc (MerrOther "store with an ill-typed memory value")` — an `Error` VERDICT | `CerbMem.lean:2956` `fail_ (MerrOther "store with an ill-typed memory value")`, the kill WITHOUT the print (in-code: "OCaml's diagnostic printfs (:1674-1680) are not mirrored, the failure is") → batch `Error {msg: …}` exit 1 | UNREVIEWED (monadic). In-Lean probe `tests/immaculate/illtyped-store.lean` pins the kill and its ordering; its header: "The C front end + elaborator always store a value converted to the store's ctype, so no C-source program reaches it through either pipeline". MEASURED: the text appears in no committed baseline | (B) print-then-KILL, the kill a verdict class the oracle also gives — the SAME shape as PNVI R16 (:2331-2334, refused `R-PNVI-10`); design §F.14 names :1716 "the project's existing treatment of a default-path (B)" |
| :1141-1144 `bytes_of_int` | `Printf.printf "failed: bytes_of_int(%s), i= %s, nbits= %d, [%s ... %s]\n"` to stdout, then `assert false` | `CerbMem.lean:721` `intToBytes`: `failwithI s!"CerbMem.intToBytes: failed: bytes_of_int(…) … (impl_mem.ml:1105-1109 assert false)"` — the crash WITHOUT the print | **UNKNOWN** (register: "needs a value-representability invariant (stored integer values lie in their type's range: Core conv_int/wrapI precede stores)") | (B) print-then-CRASH = an (A) crash with a debug print in front |
| :734-737 `is_atomic_member_access` | `Printf.fprintf stderr "addr: %s <--> alloc.base: %s\n"` + `"\|lvalue_ty\|: …"` to the TOOL's stderr, then `return true` → the `AtomicMemberof` UB verdict | `CerbMem.lean:2887/:2904` (load), `:2987/:3015` (store): the UB mirrored, the print not (in-code "INSTRUMENT note (zero-discrepancy Z2-M-17) … the tool stream, not the program's `stderr:` verdict field; not mirrored (tests/z2-probes/mem/atomic_member_stderr.c: identical …") | reachable (a UB verdict both engines give; Z2-M-17 probe MEASURED identical verdicts, per the in-code note) | (B)-shaped print before a CORRECT verdict — instrument noise, not a semantics arm [AGENT] |

### 3.5 (C) — defined arms upstream calls wrong (2 sites)

| OCaml | Upstream text (verbatim) | Lean today | Reach [AGENT] |
|---|---|---|---|
| :1044-1049 `abst`, pointer-to-function arm | `(* FIXME: This is wrong. A function pointer with the same id in different files might exist. *)` then `IntMap.find_opt n funptrmap` → `PVfunction (Symbol (file_dig, n, SD_Id name))`, else `failwith ("unknown function pointer: …")` | `CerbMem.lean:1318-1330`: the defined arm mirrored ("OCaml's own FIXME about same-id symbols across files, :1044, applies unchanged"); the `none` arm is the (A) row of §3.1 | the DEFINED arm is taken by every load of a function pointer previously stored to memory — CONTRACT §3: "Function pointers SUPPORTED, including round trips through integers and `void*` (libc's `atexit` uses one)"; refusing it would stop libc mode |
| :1864-1868 `case_funsym_opt` | the same FIXME; `IntMap.find_opt addr st.funptrmap` → `Some (Symbol …)`, else `None` | `CerbMem.lean:1619-1626` `caseFunsymOpt`, mirrored | every call through a function pointer held in memory |

[AGENT] observation for the operator: the FIXME's hazard is two TUs assigning the same symbol id to different
functions. Since arc-13 the fork renumbers under ONE ambient supply (`docs/2026-08-22_arc13-s0-scheme-decision.md`;
`check_ail_window`), so the collision the comment fears may be structurally excluded ON THE FORK — unverified here;
§7 Q5 asks for a multi-TU witness through `scripts/test_multi_tu.sh` before anything is concluded.

### 3.6 (D) — question-TODOs on defined default arms (10 sites; all mirrored today)

From design §G.3's last row plus three found in this pass: `:2209` (`(* TODO: check (in particular is that ok to
only allow device pointers when there is no provenance? *)`), `:1515` (`kill` of a `Prov_device` pointer — `(* TODO:
should that be an error ?? *)` → `return ()`), `:1041/:1053` (`(* TODO: check *)` on the null function pointer and
the pointer arms of `abst`), `:1619` (`(* TODO: might be nicer to have that part of the Ocaml_implementation
interface *)`), `:2110` (`(* TODO: catch builtin function types *)`), `:2277` (`member_shift_ptrval` on `PVnull`:
`(* TODO: unsure, this might just be undefined (gcc-torture assumes the following behaviour though) *)`), `:2482`
(`(* TODO: conversion? *)`); plus `:2385-2387` (`max_ival` of `_Bool` = 255, "TODO: not sure about this (maybe it
should be 1 …)" — mirrored, `CerbMem.lean` in-code), `:1128-1131` (`typeof` of an array from its FIRST element — "TODO:
checking all the elements would be stupidly slow", mirrored at `CerbMem.lean:1518`), and the type-level `:307`
(`(* TODO: hack hack hack ==> OCaml's float are 64bits *)` — Lean's `Float` is binary64 too; nothing to decide).
Proposed treatment [AGENT]: MIRROR all ten, as §H ruled for the PNVI (D) sites and as [USER 2026-10-03] requires
(TODO cases are not resolved unless the answer is extremely obvious).

### 3.7 The generated tree — (A) by construction (128 register rows; MEASURED tally)

Every generated failure site is a lem `failwith`/`error`/incomplete-pattern leaf of the SHARED `.lem` model — the
OCaml oracle runs the identical source and raises at the same point, so each is a both-crash mirror by construction
(the fork-drift gate pins the generated OCaml). Register tally: `Core_reduction_aux` 34, `Core_reduction` 33 (2
REACHABLE, 9 UNKNOWN), `Core_aux` 15, `Core_eval` 9, `Driver` 9 (1 REACHABLE), `Implementation` 8 (1 UNKNOWN),
`Formatted` 7 (2 REACHABLE), `Core_run_aux` 5, `Ctype_aux` 4 (UNKNOWN), `Utils` 2, `Builtins` 1, `Translation_aux` 1.
REACHABLE 5: `step_action` Fence (`atomic_fence.c`, libc mode — "class (c) concurrency-feature refusal" in the
register's own words), `process_impl_proc` `any_bounded_int()` (`zd-any-bounded-int-crash`, CONTRACT §4.1 lists it
as a REFUSED area with witness), `can_advance` `Step_error2` (`zd-z2f04-closedir`, oracle-witnessed; Lean hits the
CerbFS refusal first), `Formatted.convert` `%.*d` and `printf_aux` `%*d` (`ts-fmt-star-precision/-width`; "WELL-TYPED
UB-FREE C — class (c)"). A Lean-side text sweep cannot reach these: their text is lem's, and a Lean-only
`failure_outcome` declare is the mechanism the 2026-09-05 design assigned to the declare-consolidation / failure-monad
work (R1 (1)). Proposed treatment [AGENT]: OUT of the Q-A sweep; the five reachable rows are already CONTRACT-listed
refusals-by-class; their attribution happens when the lem arc gives them a channel.

### 3.8 Not in the sweep, listed so the census reconciles

- **Existing refusals (37 sites, shape (a)):** `CerbFS.lean` 25 (`fsRefusal`: "CerbFS refusal (fail-closed fs-model
  boundary): …", every row REACHABLE, immaculate `DIFF | L=CRASH` ×6 rows); PNVI 11 (9 pure register rows for
  R-PNVI-01 ×2, -01b, -02, -03, -04, -05, -06, -07 — `pnviRefusal`: "PNVI_ae_udi refusal (unsupported upstream arm):
  R-PNVI-nn: …"; 2 monadic `pnviRefuseM` for -08, -10 — ALSO a `failwithI` panic, "At run time the leaf aborts first,
  as every refusal does" (`CerbMem.lean:2257-2266`)); `CerbFloat.formatFixed` 1 ("CerbFloat.formatFixed: refused —
  printing a NaN with %f …", coverage lane `UNSUPPORTED` ×2 via the `.unsupported.c` convention).
- **Lean-only loud kills for REFUSED switches (12 sites, config-dead):** `CerbMem.lean:2553, 2647, 2683, 2861, 3084,
  3115, 3127, 3137, 3147, 3193, 3471, 3529` — `kill (Other (MerrOther "…: SW_… is set but the … arm (impl_mem.ml:…) is
  not ported — switches are refused (Z-24)"))`. Unreachable: `judgeSwitches` refuses every such set at the CLI
  (`check_cli_refusals.sh`). If ever reached they would print as an ordinary `Error {msg: …}` verdict line, exit 1 —
  the harness would see an Error, not a refusal. Relevant to Q-B's protocol (§4 kind 10), not to Q-A.
- **Lean-only unreachable guards:** `CerbMem.lean:2998, :3551` (§3.2), `CerbFunMapInstances`, `CoreParser`,
  `Main.loadCoreImpl` (§3.3).

### 3.9 Counts (derived) and the reach picture

| Class | Hand-written sites | Of which REACHABLE / UNKNOWN / UNREVIEWED / UNREACHABLE | Generated |
|---|---|---|---|
| (A) crash mirrors | **79** = CerbMem pure 45 + CerbMem monadic 7 + other seams 27 | 10 / 4 / 6 / 59 | 128 (5 / 14 / — / 109) |
| (B) print-then-… | **3** (:1716 kill, :1141 crash, :734 UB) | 0 / 1 / 2 (monadic or verdict) / 0 | — |
| (C) "This is wrong" defined arms | **2** (:1044, :1864) | both taken by every function-pointer load/call from memory [AGENT] | — |
| (D) question-TODO defined arms | **10** | all live defined arms | — |
| Existing refusals (shape (a)) | 37 | 25 CerbFS + 4 PNVI REACHABLE under the switch; rest unreachable/UNKNOWN | — |
| Lean-only config-dead switch kills | 12 | 0 (CLI refuses the switch) | — |

The ten REACHABLE hand-written (A) sites, each with a committed both-crash witness: `sizeofCtype` Union
(`offsetof-union-member`), `reconstructValue` unknown funptr (`funptr_reload.c`), `casePtrval` device
(`zd-z2m02-device-funptr-call`), `integerRem_t` (`zd-z2m01-aligned-alloc-zero*`), `arrayShiftPtrval` null
(`097-null-ptr-arith.undef.c`), `memcmp` byte (`g2-memcmp-uninit`, `ts-memcmp-struct-padding`), `CerbDecode`
(`args_backslash.c`), `truncToInt` (`zd-z2fl03-nan-to-int`), `bswap64` (`g4-bswap64-overflow`). Their input
classes per the register: UB ×3, implementation-defined ×1, legal-C-oracle-wrong ×1 (tray 12), well-typed-UB-free
model bug ×1 (tray candidate), harness boundary ×1, libc-boundary/unspecified-byte ×1.

### 3.10 Proposed classification and treatment, per class [AGENT] — proposals, not decisions

Reading of §H ruling 2 (eventual consistency): apply the §G.0 rule to the default path — (A) → a loud refusal
NAMED as such; (B) → refuse; (C) → refuse when reached; (D) → mirror — UNLESS doing so would (i) stop a SUPPORTED
surface where the oracle answers (the §G R15 lesson: "a refusal here would stop pKVM"), or (ii) mislabel an upstream
BUG as an unsupported feature (the no-innovation rule names two honest labels, unsupported or matching upstream;
"unsupported" for a bug is neither).

| Class | Sites | Proposed treatment [AGENT] | Observable effect under shape (a) | Lane movement (MEASURED where stated) |
|---|---|---|---|---|
| (A) REACHABLE both-crash where the oracle's crash is a plausible model limit (`casePtrval` device, `arrayShift` null TODO-failwith, `integerRem_t`, `truncToInt`, `CerbDecode`, `memcmp` byte) | 6 | **REFUSE-TEXT**: keep the mechanism, replace the bare OCaml text with the shared refusal grammar carrying the OCaml text as detail (`kind = upstream-crash`) | exit code and class unchanged (134 / `ModelFailure` exit 1); message changes | immaculate `MATCH \| L=CRASH` rows compare the crash CLASS, not the text (codec `--policy immaculate`; VALIDATION §1(a) "the coarse crash policy") → no movement; `gcc_oracle` `SKIP_LEAN_CRASH` is a status token → no movement; `tests/pnvi_lane/baseline.txt` pins the LEAN-side hash on `BOTH_FAIL` rows ("Lean side hash-pinned too") — `tests/minimal` runs under the switch there, so `097-null-ptr-arith` MOVES (one re-baseline on the trust-surface lane, row 14) |
| (A) REACHABLE both-crash where the register calls the oracle WRONG or the input LEGAL (`bswap64` tray 12; `offsetof-union-member` "model bug (upstream asymmetry, tray candidate)"; `funptr_reload` implementation-defined, no UB) | 3 | **REFUSE-TEXT with `kind = upstream-crash-believed-wrong(tray n)`** — never "unsupported"; each needs a tray draft if it has none | as above | as above |
| (A) UNKNOWN / UNREVIEWED (`:1461`, `:1976`, `:1999`, `lookupEnum`; the 6 monadic incl. R-PNVI-09) | 10 | **REFUSE-TEXT**, same grammar; for the monadic six the message is the only change (they already are typed kills) | none observable (no witness) | none |
| (A) UNREACHABLE-BY-INVARIANT | 59 | **REFUSE-TEXT for uniformity** (the operator's consistency direction), OR leave verbatim — a dead arm's text is unobservable; the register row's invariant is the truth either way | none | none; BUT every converted row's 60-char `msg` KEY changes → the register must be re-sealed (`check_failure_reach.py --reseal`), one commit, classes unchanged (§7 Q10) |
| (B) `:1141` print-then-`assert false` | 1 | treat as (A): REFUSE-TEXT (the print is tool stdout; the crash is the behaviour) | none (UNKNOWN reach) | none |
| (B) `:1716` print-then-`fail MerrOther` (= R16's shape) | 1 | **operator's reading needed (§7 Q4)**: REFUSE for strict consistency with R-PNVI-10, or KEEP the kill because it is the oracle's own verdict class and the print is tool noise; zero measured reach either way | if REFUSE: a kill becomes a panic/`Stopped`, class moves Error → refusal on an unreached arm | none |
| (B) `:734` print-then-UB-verdict | 1 | **KEEP** (a correct verdict; Z2-M-17 measured identical) — propose the (B) rule be read as "print before a crash or an ambiguity kill", not "any print" | none | none |
| (C) `:1044`, `:1864` | 2 | **MIRROR (keep)** — refusing stops every function-pointer load from memory (libc `atexit`); file a tray report; verify the single-supply invariant (§7 Q5) | none | none |
| (D) | 10 | **MIRROR (keep)** | none | none |
| generated (A) | 128 | **OUT of scope** (lem text; the failure-monad arc) | — | — |

## 4. Q-B inventory — every distinct way a run ends other than a normal verdict (MEASURED shapes; [AGENT] placement)

Exit codes and streams from `Main.lean` (`:1240-1345`, `:1498-1520`, `:1384-1498`, `:1650-1671`), `CerbND.lean`
(`:98-123`), `CerbFail.lean`, `CerbFS.lean`, `CerbMem.lean`, `scripts/fuel_classify.sh`, `scripts/observations.py`,
`scripts/test_exec.sh` (header + `:604-715`), `scripts/test_immaculate.sh` (`:95-120`), `scripts/pnvi_lane.py`
(`:20-40`, `:94-135`), `scripts/check_cli_refusals.sh`, `scripts/check_asm_refusal.sh`, `scripts/cap_oom.regex`,
`scripts/common.sh:436-446`. "cerberus-sl names it" = the name appears in a theorem statement of
`/home/dev/projects/cerberus-sl` (grep counts in §5.4).

| # | Kind | Produced by | Exit | Stream and shape | How the lanes classify it | CONTRACT §1 slot | cerberus-sl names it? |
|---|---|---|---|---|---|---|---|
| 1 | CLI refusal (flags, switches, runtime, library locations, non-UTF-8 JSON, batch UB payload, `--fuel`/`--address-space-top` values, `--parse-core` switches, `LEAN_ABORT_ON_PANIC` unset) | `Main.lean` — 12 `cerberus-lean: refused — …` sites (`refuseFlag`, `refuseSwitches`, `refuseRuntime`, `refuseLibraryLocations`, …) | **2** | stderr one line `cerberus-lean: refused — <flag\|boundary>: <feature> (see …)`; nothing on stdout | `check_cli_refusals.sh` asserts exit 2 + prefix + feature text (row 1, a speedbump per LADDER); `pnvi_lane.py` → `CLI_REFUSAL`; `test_exec.sh`: exit 2 is not ≥128 → `LEAN_ERROR`/`FAIL` class | (2) loud refusal | no |
| 2 | CLI usage error | `Main.lean:1495, 1612, 1677, 1689, 1695` (`--switches requires an argument`, `--call-args without --call`, …) | **1** | stderr `cerberus-lean: <text>` — NO `refused —` prefix | not pinned anywhere (MEASURED: no lane greps these texts) | (2) in spirit, unattributed in form [AGENT] | no |
| 3 | Front-end failure incl. the asm refusal (D9) and linking errors | shared `.lem` desugar/typing (`Main.lean:754`, `:1185`) | **1** | stdout `Error {msg: "desugaring failed at <loc>"}` (oracle: exit 1, stderr `… error: feature not yet supported: inline assembly (asm statement) is unsupported`) | `check_asm_refusal.sh` asserts the Lean line + exit 1 and the oracle message (row 1); codec: an `Error` verdict; VALIDATION §1(a) "front-end rejections … exit class identical" | (2) by CONTRACT §3 (D9), but VERDICT-shaped on the wire [AGENT] | no |
| 4 | CerbFS refusal | `CerbFS.lean:109-158`, 25 pure `failwithI (fsRefusal …)` | **134** (SIGABRT) | stderr `PANIC at _private.LemLib.0.failwithIImpl LemLib:…: CerbFS refusal (fail-closed fs-model boundary): <op> — …`; stdout empty | immaculate: codec `INTERNAL_ERROR` → `CRASH` → pinned `DIFF \| L=CRASH` (6 rows); `test_exec`: `LEAN_CRASH` or `UNSUPPORTED` if expected; the refusal MESSAGE is pinned nowhere (CONTRACT §4.1 "Limit: the immaculate and coverage witnesses pin the crash CLASS … not the refusal message") | (2) | no (their docs: `failwithI` is "an opaque value the mirror does not model") |
| 5 | PNVI refusal | `pnviRefusal` (9 pure rows) + `pnviRefuseM` (2 monadic) — all `failwithI` | **134** | stderr `PANIC at …: PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-nn: …` | `pnvi_lane.py` recognises `REFUSAL_PREFIX` + `REFUSAL_ID` → `REFUSAL R-PNVI-nn ORACLE_CRASH\|ORACLE_VERDICT` rows (7 in the baseline), never agreement; the REFUSAL-CRASH rule both directions; elsewhere a crash | (2) | no |
| 6 | `%f`-of-NaN refusal | `CerbFloat.formatFixed` pure `failwithI` | **134** | stderr `PANIC at …: CerbFloat.formatFixed: refused — printing a NaN with %f …` | coverage lane `UNSUPPORTED` (2 rows; the `.unsupported.c` naming convention carries the expectation) | (2) | no |
| 7 | Mirrored pure crash (OCaml text) | the 45 + 27 (A) pure sites of §3.1/§3.3, the 128 generated rows | **134** | stderr `PANIC at _private.LemLib.0.failwithIImpl …: <OCaml text or paraphrase>` | immaculate `MATCH \| L=CRASH` when the oracle crashes too (18 rows), codec accepts ONLY the LemLib panic origin (`LEMLIB_FAILWITHI_ORIGIN`; anything else `ProtocolError('unreviewed panic origin')`); `gcc_oracle` `SKIP_LEAN_CRASH` (18); `test_exec` `LEAN_CRASH`/`UNSUPPORTED` keyed on exit ≥128 + first `PANIC` line | (4)(a) when both crash; a BUG otherwise | no |
| 8 | Typed model fail-stop (C-TF1) | the 7 monadic sites of §3.2 (`failStopKill`/`failStopMem`) | **1** | stdout `ModelFailure {msg: "<OCaml text>"}` (`CerbFail.batchRecord`; `Main` tests `loc == CerbFail.modelFailStopLoc` at runtime) | codec `MODEL_FAILURE` → immaculate `CRASH` token → `L=CRASH` (2 rows); "never semantic agreement" | (4)(a) | generically: `Error0` appears 7× (`liftKill`'s arm, `RoundStore`), `modelFailStopLoc` once in a probe, `failStopKill` 0× |
| 9 | Fuel exhaustion | `CerbND.runNDFuel` leaf and the ND-typed absorbing workers (kill) / the pure `fuelExhausted(With)` sentinel (panic) | **1** (kill) / **134** (panic) | stdout `Error {msg: "lem: fuel exhausted"}` / stderr `lem: fuel exhausted` | `classify_fuel_outcome` → `FUEL:kill` / `FUEL:panic`, fatal in default mode, never agreement; codec `FUEL_RECORD` → `ProtocolError('fuel exhausted; exploration incomplete')` | (3) resource, [USER 2026-09-03] accepted fuel as a reasonable exception | **YES** — `.Killed st CerbND.fuelExhaustedKill` (361 refs) |
| 10 | Allocator out-of-memory kill | `CerbMem.oomKill = Other (MerrOther "Concrete.allocator: failed (out of memory)")` | **1** | stdout `Error {msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}` — a VERDICT line (mirrors upstream's own failure) | an `Error` verdict; immaculate `zd-ta-alignas-huge-desugar ORACLE_CRASH \| L=ERR:{…out of memory…}` (the oracle crashes on `Z.to_int` where Lean answers OOM) | (1) where both answer; a one-sided row otherwise (registered) | **YES** — `Interface.oomOutcome` (374 refs), `DErr_memory` (11) |
| 11 | Lean-only config-dead switch kills | the 12 `CerbMem` H2 sites (§3.8) | **1** | stdout `Error {msg: "…: SW_… is set but … is not ported — switches are refused (Z-24)"}` | would be an ordinary `Error` verdict — unattributed; unreachable (CLI refuses) | (2) in intent, verdict-shaped on the wire [AGENT] | no |
| 12 | Cgroup memory-cap kill | `scripts/capped` (64G default, `CERB_MEM_MAX`) | **137** | stderr `capped: OOM-KILLED …` (`cap_oom.regex`) | `is_cap_kill` → immaculate `KILL` token; `test_exec` oracle-side `CERB_SKIP`; a (b)-VIOLATION if the oracle completes | (3) | no |
| 13 | Timeout / HANG | `timeout ${TIMEOUT_SECS}s` | **124** | none | `classify_exit124`: `TIMEOUT` vs `HANG` (CPU/wall < 0.1), both fatal in default mode | (3) | no |
| 14 | `LEAN_ABORT_ON_PANIC` behaviour | `Main.lean:1512-1516` | **2** if unset (startup refusal, kind 1); if set, every kind-4..7 panic becomes SIGABRT **134** after printing `PANIC at …` | — | every harness sets it (`scripts/common.sh run_cerberus_lean`); the Z2-FL-03 finding: without it a panic prints and CONTINUES with `default` → a crash-to-VALUE conversion | the guard that keeps (4)(a)/(2) from degrading to a fifth outcome | no (an in-process consumer never sees the flag — the 2026-09-03 ruling's gap) |
| 15 | Lean-only internal errors | `Main.lean:1251-1253` (`runND returned no executions`), `:1480-1481` (`refuseSwitches returned`) | **1** / **2** | stdout `Error {msg: "cerberus-lean: …"}` / stderr `cerberus-lean: internal error: …` | an `Error` verdict / unpinned | (2) in intent | no |
| 16 | Mirrored driver/core-run `Other` kills (`Illformed_program`, `Found_empty_stack`, …) | shared `.lem` driver | **1** | stdout `Error {msg: "<driverErrorBatchMsg>"}` | verdicts; class (a) text (`Illformed_program` text pinned modulo symbol id, tray 17) | (1)/(4)(a) | `driver_error` 61 refs (the type, not these kills) |

Derived: 16 kinds; 4 wire shapes (exit 2 + stderr prefix; exit 134 + `PANIC` line; exit 1 + `ModelFailure`
record; exit 1 + `Error {msg}` verdict line) plus 2 host shapes (137, 124). Refusals in the CONTRACT sense occupy
THREE of the four wire shapes (kinds 1, 3, 4–6) and the message prefixes differ per module (`cerberus-lean: refused
— `, `CerbFS refusal (…): `, `PNVI_ae_udi refusal (…): `, `…: refused — `). The codec's own `refusal(prefix)` action
with its default `--refusal-prefix 'model refused: '` (observations.py:376) is used by one test only
(`scripts/test_observation_lanes.py:70`, MEASURED) — a vestige of the concurrency prototype's convention, named as
such in D2 R0 §1 item 3.

## 5. Options for Q-B

### 5.0 The structural fact that bounds every option [AGENT]

A stop can be CONTROLLED (a value a theorem can case on and a printer can render) only where the site returns into a
monad with a kill channel. Of the 37 existing refusals, 34 are PURE (`CerbFS` 25 — their types mirror the lem `fs`
interface, `FsState × Sum FsError Nat`; the 9 PNVI register rows; `formatFixed`), and `CerbFS.lean`'s header records
WHY the pure channel was not used: "an FsError becomes errno + -1 through driver.lem store_error and a C program can
absorb it". Of the 79 default-path (A) mirrors, 72 are pure. So:

- a typed outcome at a MONADIC site costs a helper and a printer (C-TF1 did it in one slice for 7 sites);
- a typed outcome at a PURE site costs a TYPE change — either the parked twin (`_chk` cone + connection theorem) or
  the queued lem failure-monad translation (fallible functions in `Except`), both lem-level, both with a consumer
  signature impact of their own;
- the only thing that IS global today is the TEXT: every pure stop ends as `PANIC at _private.LemLib.0.failwithIImpl
  …: <message>` and the codec already requires exactly that origin.

### 5.1 Option 1 — keep (a) exactly as it is

- **What:** nothing changes; the Q-A sweep (if any) edits message strings only.
- **Cost:** zero now. Standing costs: three refusal prefixes and four wire shapes (§4); the harness tells a refusal
  from a mirrored crash by per-lane text rules (`pnvi_lane.py` `REFUSAL_PREFIX`; the coverage lane by file name;
  immaculate not at all — `L=CRASH` covers refusals, fail-stops and crashes alike, CONTRACT §4.1's stated limit); an
  in-process consumer sees the `Inhabited` default at every pure refusal (the 2026-09-03 gap, still open for the
  pure group by R1's own terms).
- **Consumer impact:** none of the five relied-on items changes (MEASURED §5.4: nothing in cerberus-sl names a
  refusal, `fsRefusal`, `pnviRefusal`, `failStopMem` or `LEAN_ABORT_ON_PANIC`).
- **Verdict [AGENT]:** the ruling ((a) is fine for now); fine as the MECHANISM; insufficient as a "global policy"
  because the policy today is four conventions, not one.

### 5.2 Option 2 — a typed controlled-outcome constructor in the ND/driver outcome type

Three sub-variants, which prior art has already ranked:

- **2a — a third opaque location atom** (`refusalLoc`, the C-TF1 pattern: `Error0 refusalLoc msg`, a `Refused
  {msg}` record). Cheapest mechanism; zero consumer signature change (`Error0` passes through `liftKill`
  unchanged). **REJECTED by the adopted doctrine** [AGENT reading]: D2 R0 §1 item 3 — "A third opaque atom would make
  three unprovably-distinct `Error0`s"; the scoping note's P2/P3/P5 (distinct by `noConfusion`, no reserved string, no
  census + parametricity argument); [USER 2026-09-16]'s wariness of epicycles. It would also label a
  refusal with a runtime `BEq` on `Loc` that a crafted Cabs JSON `Loc_other` can forge (scoping note §1 item 4). Not
  recommended.
- **2b — `Stopped of interp_stop` with `Unsupported of unsupported_feature * string`** = the queued plan R1
  (§2). Reaches: the 9 monadic refusal/fail-stop sites now; every kill-channel site; the pure `Undefined.t` evaluator
  channel for exhaustion. Does NOT reach pure sites (its own §2 "Not claimed": "The pure-failure axis (233 …) is
  untouched"). Cost: a shared-TYPE extension on both outcome types (dead in OCaml; fork-drift manifest rows; a tray
  proposal), WP0 in lem-lean first (`inhabited_exclude`), the codec policy rename (`model-failure` → `stop`), 22
  scripts/gates per the S0 wire addendum, a consumer migration (S0 measured 12 non-exhaustive match blocks + 1
  literal + 18 alias uses against refined-cerberus; cerberus-sl today: `liftKill`'s 3-arm match on `kill_reason`
  (`PrimOutcome.lean:355-358`) and every `rcases`/`match` on `nd_status`/`kill_reason` go non-exhaustive — 21 + 17
  mentions, §5.4). Sequenced behind WP-O ([USER 2026-09-16]: WP-O before further work is executed).
  **This is the designed answer to §H ruling 3's "(b)"; it needs no new design here, only its slot.**
- **2c — pure sites too** (the parked twin, or the lem failure-monad arc [USER 2026-09-30]). The only route to a
  single mechanism for ALL stops. Changes the TYPE of every fallible pure function (`sizeofCtype`,
  `reconstructValue(Abst)`, `arrayShiftPtrval`, the CerbFS entry points, …) → the consumer's frozen rows
  (`docs/freeze/s7-rows.txt`, 1884 lines, MEASURED) move wholesale; cerberus-sl's 4695 enum-reader-adjacent
  references and 343 `initial_driver_state` sites are the scale of what would be re-elaborated. A design pass of its
  own, with the operator; not scoped here.

### 5.3 Option 3 — a CLI/harness-level mapping only (the protocol, not the mechanism)

- **What:** ONE refusal grammar for every stop that is a refusal in the CONTRACT §1(2) sense, emitted by ONE helper per
  channel (pure: a string builder feeding `failwithI`, replacing `fsRefusal`/`pnviRefusal`/the `formatFixed` text;
  monadic: the same builder feeding the kill), e.g. `cerberus-lean refusal — <kind>: <boundary>: <detail> (<upstream
  cite>)` with `kind ∈ {unsupported-feature, upstream-crash, upstream-crash-believed-wrong(tray n), model-invariant}`
  as an ENUMERATION in the helper (so the P3 "feature names are an enumeration, not text" spirit holds at the Lean
  level even while the wire is text); ONE classifier function in `scripts/observations.py` producing a `REFUSAL(<kind>)`
  token that `test_immaculate.sh`, `test_exec.sh`, `pnvi_lane.py` and the coverage lane consume (so `L=CRASH` splits
  into `L=CRASH` / `L=FAILSTOP` / `L=REFUSAL` — `TODO.md` item (c)'s renaming, now with a reason); the CLI's exit-2
  path adopts the same grammar and the 5 usage-error sites (kind 2) join it; `Main` cannot intercept a panic, so
  exit 134 STAYS for pure sites (the ruling tolerates it: (a) is fine for now).
- **Cost:** text edits at ~37 existing refusal sites + the Q-A conversions, one helper per channel, one codec
  function, three lane consumers, the immaculate re-record with label changes only (classes unchanged), the pnvi
  lane's `REFUSAL_PREFIX` moved onto the shared grammar (its `R-PNVI-nn` ids stay as the `detail`), the register
  re-seal (msg keys). No build-rule change; no gate added.
- **Consumer impact:** zero on the five items (strings are reporting-only; `failwithI` stays opaque; no type moves).
- **What it does NOT give:** the in-process consumer still sees `default` at pure sites; `Stopped` distinctness is
  not delivered; the process still dies by SIGABRT at a pure refusal. It is the honest statement of what (a) IS,
  made uniform.

### 5.4 Consumer impact — the exact items, MEASURED (`grep -rn --include='*.lean'` over `/home/dev/projects/cerberus-sl`, `.lake/` excluded; pin `scripts/semantics-pin.env` `CERBERUS_LEAN_COMMIT="2b51d2a57…"`)

| cerberus-sl name / relied-on item | refs | Option 1 | Option 2a | Option 2b | Option 2c | Option 3 |
|---|---|---|---|---|---|---|
| `CerbND.runNDFuel` | 540 | unchanged | unchanged | unchanged NAME; result type's `nd_status` gains a constructor → every exhaustive `match`/`rcases` (21 `nd_status`, 311 `.Killed`, 300 `.Active` mentions) re-checked | signature of the pure functions it runs over changes | unchanged |
| `.Killed st CerbND.fuelExhaustedKill` | 361 | unchanged | unchanged | becomes `Stopped0 Exhausted` by the plan (R7 "the consumer's exhaustion-only disjunct retained"; S0: 18 alias uses rely on the `rfl`) | as 2b | unchanged |
| `Interface.oomOutcome = .Killed s (.Other (.DErr_memory (.MerrOther "…out of memory")))` | 374 (`DErr_memory` 11) | unchanged | unchanged | unchanged (an `Other` kill) | unchanged value; types above it move | unchanged |
| `liftKill : kill_reason mem_error → kill_reason driver_error` (3-arm match, `PrimOutcome.lean:355-358`) | 1 def, 17 `kill_reason` mentions | unchanged | unchanged (`Error0` arm) | **non-exhaustive** → one arm added | as 2b | unchanged |
| `Error0 l s` generic kills | 7 | — | a refusal would be one more `Error0` they cannot distinguish | distinct constructor | — | — |
| address-space top (`AdmittedTop`, `initial_driver_state supply top …`) | 230 / 343 | unchanged | unchanged | unchanged | unchanged | unchanged |
| run digest (`sym_digest`, `P.digest`) | 379 | unchanged | unchanged | unchanged | unchanged | unchanged |
| enum reader (`enumDefs`, `resolveEnum`, …) | 4695 | unchanged | unchanged | unchanged | pure reader functions may change type | unchanged |
| fail-closed arity matcher (`match_pattern`/`typecheck_pattern`) | 89 | unchanged | unchanged | unchanged | may change type | unchanged |
| any refusal text / `failwithI` / `LEAN_ABORT_ON_PANIC` in a theorem | 0 (`failwithI` appears only in doc comments and the mirror's "opaque value" notes) | — | — | — | — | — |

The 1884-row freeze (`docs/freeze/s7-rows.txt`) moves under 2b (fingerprints of declarations mentioning the extended
types) and wholesale under 2c; not at all under 1 and 3.

### 5.5 Recommendation [AGENT]

**Option 3 now; Option 2b as already queued; never 2a; 2c with the lem failure-monad arc's own design pass.**
Reasons: (i) §H ruling 3 asks for a GLOBAL policy if (b) is done and says (a) is fine for now — Option 3 is the
global policy (a) can carry, and it is what WP2 would otherwise have to invent at conversion time; (ii) Option 2b is
designed, reviewed and prototyped, with the operator's sequencing (WP-O first) — re-deciding it here would be the
"epicycle" risk in reverse; (iii) 2a contradicts the adopted doctrine verbatim; (iv) every Option-3 site edit is
ALSO the edit 2b needs (the helper's body changes from a string to `Stopped (Unsupported feature detail)`; the sites
do not), so Option 3 is not throw-away work; (v) consumer impact of Option 3 is zero on all five items.
Price: an immaculate re-record (labels), a pnvi-lane re-baseline (one Lean-side hash on `097-null-ptr-arith` if its
text changes; `REFUSAL_PREFIX` relocation), one register re-seal, and the honest caveat that the process still aborts
at pure refusals until 2c.

## 6. How Q-A and Q-B interact

- **Order.** Fix Q-B's PROTOCOL first (the helper + grammar + codec token: a small slice), then run the Q-A sweep ONCE
  through the helper. Converting Q-A sites first in today's three ad-hoc prefixes would touch ~79 strings twice.
  The Q-B MECHANISM (2b) can follow at any time without touching a Q-A site: it changes the helper's body.
- **Should the sweep wait for 2b itself?** No [AGENT]: 2b is behind WP-O and WP0 (two repos, the pin dance); the
  operator rated Q-A a minor item; under the helper the sweep is text-only and 2b-compatible by construction.
  Waiting would leave the default path inconsistent with the PNVI path for the whole WP-O/WP0 interval for no
  saving.
- **What the sweep must NOT do** (both questions): convert a (C)/(D) defined arm that a supported surface takes
  (`:1044`/`:1864`); relabel an upstream BUG as "unsupported" (kind field); touch generated text; add a gate; change
  any of the five consumer items; change the default-set verdict of any lane row (the PNVI arc's zero-default-movement
  invariant is the model — the sweep's acceptance is "class movement zero; label/hash movement enumerated in
  advance").
- **R-PNVI-09** belongs to Q-A (a default-path monadic (A)); it is converted with the other six monadic sites, text
  only until 2b.
- **The (B) `:1716` reading (§7 Q4)** is the one Q-A item whose answer depends on how the operator wants the §G.0 (B)
  rule read; it should be ruled before the sweep, not discovered during it.

## 7. Open questions for the operator — each with a recommendation [AGENT]

1. **Scope of the Q-A sweep: hand-written seams only?** Recommendation: yes. The 128 generated rows are lem text
   both engines run; their attribution is the failure-monad arc's.
2. **Convert all 79 hand-written (A) sites or only the 20 with REACHABLE/UNKNOWN/UNREVIEWED reach?** Recommendation:
   all 79 through the helper — the stated aim is consistency and the marginal cost of the 59 dead arms is a text edit
   plus one register re-seal; keep the OCaml text as the `detail` field so the both-crash correspondence stays legible
   in the message.
3. **The `kind` enumeration.** Recommendation: four kinds — `unsupported-feature` (CerbFS, PNVI, `%f`-NaN, Fence…),
   `upstream-crash` (a both-crash where the input class is UB or a model limit), `upstream-crash-believed-wrong(tray
   n)` (bswap64 tray 12; `offsetof-union-member`; `funptr_reload`), `model-invariant` (Lean-only guards). Never
   "unsupported" for a bug.
4. **(B) `:1716` print-then-`fail MerrOther`: refuse (strict consistency with R-PNVI-10) or keep the kill (it is the
   oracle's verdict class; the print is tool stdout)?** Recommendation: keep, and record the (B) rule as "a debug
   print before a crash or an ambiguity kill"; `:734` likewise keeps. If the operator prefers strict consistency,
   refusing is observationally free (zero measured reach) and costs one site. Either way, rule it before the sweep.
5. **(C) `:1044`/`:1864`: mirror, and verify the single-supply invariant moots the FIXME?** Recommendation: MIRROR
   (refusing stops libc `atexit` and every function-pointer load from memory); add a `tests/multi_tu/` witness (two
   TUs each defining a static function, a pointer to one stored and reloaded) through `scripts/test_multi_tu.sh`;
   file a tray report either way (the FIXME is upstream's).
6. **Q-B shape: adopt Option 3 now and leave 2b in its queued slot?** Recommendation: yes (§5.5). Explicitly
   decline 2a.
7. **The monadic inconsistency — `pnviRefuseM` panics (exit 134) where `failStopMem` kills (`ModelFailure`, exit 1):
   align now?** Recommendation: NOT now — the only typed kill available today is `modelFailStopLoc`, and labelling an
   unsupported feature as a "model fail-stop" is the wrong kind; align when 2b gives `Stopped (Unsupported …)`.
   Record the inconsistency in CONTRACT §3's PNVI row meanwhile.
8. **CLI usage errors (kind 2, 5 sites, exit 1, unattributed): fold into the exit-2 grammar?** Recommendation: yes;
   trivial, binary-level, zero consumer impact.
9. **The 12 config-dead switch kills (kind 11): attribute their text?** Recommendation: fold into the sweep as text
   only (they are unreachable; low priority); their kind is `unsupported-feature`.
10. **Register re-seal.** Converting a row's text changes its 60-char `msg` key; the gate requires `--reseal` "in a
    commit that states the justification". Recommendation: accept — one commit, classes unchanged, the justification
    "protocol text sweep, no class edit"; the sealed classes remain the review.
11. **Is the asm refusal's verdict shape (kind 3: `Error {msg: "desugaring failed at …"}`, exit 1, both engines)
    "controlled" enough?** Recommendation: leave it — it is upstream's own refusal shape in the shared `.lem`
    (contract D9), attested by `check_asm_refusal.sh`; note it in CONTRACT §1 as the one refusal that is
    verdict-shaped by inheritance.
12. **Immaculate label split (`L=CRASH` → `L=CRASH`/`L=FAILSTOP`/`L=REFUSAL`, `TODO.md` item (c)).** Recommendation:
    do it with Option 3 (the codec token exists for `MODEL_FAILURE` already; `REFUSAL` is the missing one); a
    re-record with label-only movement, classes pinned unchanged.

## 8. Provenance and commands (MEASURED; verbatim outputs where quoted)

All commands run read-only in `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-docs/stop-paths-inventory`
at `c4284b08f` (and read-only in `/home/dev/projects/cerberus-sl` at `6e360da`, `/home/dev/projects/cerberus-lean-proj/lem-lean/lean-lib`). No file outside this note was written.

- C1 register tally (header line 28, verbatim): `# tally: sites=239 exec=237 unresolved-owner=2 reviewed-TAIL=176 reviewed-NON-TAIL=63 UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22 discardable=0`
- C2 `awk -F'\t' 'NR>29 && NF>=8 {g=($1 ~ /generated\//)?"generated":"handwritten"; print g"\t"$8}' scripts/failure_reach_register.txt | sort | uniq -c` →
  `5 generated REACHABLE · 14 generated UNKNOWN · 109 generated UNREACHABLE-BY-INVARIANT · 39 handwritten REACHABLE · 8 handwritten UNKNOWN · 64 handwritten UNREACHABLE-BY-INVARIANT` (per-file split in the same run: `CerbMem.lean` 41/5/9 UNREACHABLE/UNKNOWN/REACHABLE, `CerbFS.lean` 25 REACHABLE, `CerbDecode` 5/0/2, `CerberusImpl` 5/1/0, `CerbFloat` 0/0/2, `CerbUtils` 3/0/1, `CerbStepInstances` 8, `CerbLocation` 1, `CerbFunMapInstances` 1, `CoreParser` 0/1/0, `Main` 0/1/0; generated: `Core_reduction_aux` 34, `Core_reduction` 22/9/2, `Core_aux` 15, `Core_eval` 9, `Driver` 8/0/1, `Implementation` 7/1/0, `Formatted` 5/0/2, `Core_run_aux` 5, `Ctype_aux` 0/4/0, `Utils` 2, `Builtins` 1, `Translation_aux` 1).
- C3 `grep -P '^lean_frontend/CerbMem.lean\t' scripts/failure_reach_register.txt | wc -l` → 55 CerbMem rows; PNVI refusal rows among them: lines 66, 67, 86, 87, 88, 92, 99, 110, 120 (9) → 46 default-path rows, of which `intToBytes` (line 82) is (B).
- C4 `grep -n -E 'failwithI|failStopMem|pnviRefusal|pnviRefuseM|fsRefusal|oomKill|panic' lean_frontend/CerbMem.lean` → the Lean line numbers of §3.1/§3.2/§3.8 (48 pure `failwithI` lines on the default path incl. :1079/:1088 in `memValueToBytes_append_lemFuel`, which has no register row; `failStopMem`/`failStopKill` at :2514, :2542, :2668, :2998, :3465, :3551, :3617, :3813, :3832; `pnviRefuseM` at :3248, :3496; switch kills at :2553, :2647, :2683, :2861, :3084, :3115, :3127, :3137, :3147, :3193, :3471, :3529; `def oomKill` :2464).
- C5 `grep -n -E 'failwith|assert false|Printf\.printf|Printf\.fprintf|prerr_endline|print_endline|FIXME|HACK' memory/concrete/impl_mem.ml | awk -F: '$1>=277 && $1<=2830'` → 63 lines, the upstream forms quoted in §3; the function bodies read at `:300-312, :676-694, :770-782, :960-990, :1028-1036, :1038-1050, :1090-1130, :1136-1146, :1156-1164, :1190-1198, :1510-1518, :1565-1575, :1712-1724, :1858-1868, :2115-2136, :2272-2300, :348-356`.
- C6 baseline rows: `grep -E 'L=CRASH|ORACLE_CRASH|CRASH' tests/immaculate/baseline.txt | grep -v '^#'` → 31 rows, re-counted per token with `grep -c -E '^[^#].* MATCH \| L=CRASH'` etc. (18 `MATCH | L=CRASH`: `f3-raw-high-byte-{char-const,int,uchar}`, `g2-memcmp-uninit`, `g4-bswap64-overflow`, `g5-decode-multichar`, `offsetof-union-member`, `ts-fmt-s-null`, `ts-fmt-star-precision`, `ts-fmt-star-width`, `ts-memcmp-struct-padding`, `zd-any-bounded-int-crash`, `zd-z2f04-closedir`, `zd-z2fl03-nan-to-int`, `zd-z2m01-aligned-alloc-zero{,-nolibc,-zero}`, `zd-z2m02-device-funptr-call`; 6 `DIFF | L=CRASH`: `zd-f1-truncate-negative-length`, `zd-fs-path-plain-control`, `zd-fs-path-subdir-create`, `zd-fs-pathleak-dot-slash`, `zd-fs-stdin-read`, `zd-z2f01-lseek-whence`; 7 `ORACLE_CRASH | L=<verdict>`: `g5-decode-question`, `s4b-memcmp-hugesize`, `zd-e2-ptr-string-literals`, `zd-r2-crash-digit9`, `zd-ta-alignas-huge-{desugar,sizeof,union-alignof}`); `grep -E 'SKIP_LEAN_CRASH' scripts/gcc_oracle_baseline.txt` → 18 rows; `grep UNSUPPORTED scripts/exec_coverage_baseline.txt` → `fmt-007-f-nan-sign.unsupported.c`, `fmt-007b-f-nan-negated.unsupported.c`; `grep -E 'REFUSAL' tests/pnvi_lane/baseline.txt` → 7 rows (R-PNVI-01 ×4, -05, -06, -07).
- C7 message reach: for each of 17 default-site texts, `grep -rl -F -- "<text>" scripts tests corpus` excluding `.c/.lean/.py/.sh/README` → only `scripts/failure_reach_register.txt` (and `tests/immaculate/baseline.txt` for `Division_by_zero`/`Z.Overflow`, `tests/pnvi_lane/baseline.txt` for `case_ptrval`, `tests/noodle-probes/dynamic-addrs/results.log` for `FREE was called on a dead`); `ill-typed memory value`, `eff_array_shift_ptrval, PVfunction`, `with_address`, `abst, |bs|`, `memcmp: non-integer`, `va_list: assert`, `alignment 0` → no baseline file.
- C8 cerberus-sl counts (`grep -rn --include='*.lean' -E "<name>" . | grep -v '/.lake/' | wc -l`): `runNDFuel` 540 · `fuelExhaustedKill` 361 · `oomOutcome` 374 · `DErr_memory` 11 · `\.Killed` 311 · `\.Active` 300 · `Error0` 7 · `modelFailStopLoc` 1 · `failStopKill` 0 · `CerbFail\.` 1 · `nd_status` 21 · `kill_reason` 17 · `AdmittedTop|addressSpaceTop|address_space_top` 230 · `runDigest|sym_digest` 379 · `resolveEnum|lookupEnum|register_enum|enumDefs` 4695 · `match_pattern|typecheck_pattern` 89 · `initial_driver_state` 343 · `driver_error` 61; `failwithI|pnviRefusal|fsRefusal|failStopMem|failStopND|LEAN_ABORT_ON_PANIC|refused` → doc comments only (no theorem statement); `| .Undef0|| .Other || .Error0` → 3 lines, all `PrimOutcome.lean` (`liftKill`); `wc -l docs/freeze/s7-rows.txt` → 1884; `Interface.lean:177-178` `def oomOutcome … := .Killed s (.Other (.DErr_memory (.MerrOther "Concrete.allocator: failed (out of memory)")))`; `Adequacy.lean:417-426` the startup-OOM theorem's conclusion `(∃ st, o.1 = .Killed st CerbND.fuelExhaustedKill) ∨ (∃ st, o.1 = oomOutcome st)`.
- C9 wire shapes: `Main.lean:1240-1345` (batch printer, exit policy `| [(.Active _, _, _)] => return 0 | [(.Killed _ _, _, _)] => return 1 | _ => return 0`), `:1512-1516` (`LEAN_ABORT_ON_PANIC` guard, exit 2), `grep -c 'cerberus-lean: refused' lean_frontend/Main.lean` → 12, `IO.Process.exit 1` sites `:1495, 1612, 1677, 1689, 1695`; `CerbFail.lean` (`failStopKill`, `failStopND`, `batchRecord "ModelFailure {msg: …}"`); `CerbND.lean:98-123`; `scripts/fuel_classify.sh` (`FUEL_KILL_BATCH_LINE='Error {msg: "lem: fuel exhausted"}'`, `FUEL_PANIC_LINE='lem: fuel exhausted'`); `scripts/observations.py:48-59, 68-86, 195-230, 282, 333, 376` (`MODEL_FAILURE`, `FATAL`, `FUEL_RECORD`, `CAP_OOM`, `LEAN_PANIC`, `LEMLIB_FAILWITHI_ORIGIN = b'_private.LemLib.0.failwithIImpl'`, `IMMACULATE_PANICS = set()`, `refusal(prefix)`, `--refusal-prefix 'model refused: '`); `grep -rn -F 'model refused' scripts tests lean_frontend` → `scripts/test_observation_lanes.py:70` plus three docs; `scripts/pnvi_lane.py:94-95, 134-135` (`REFUSAL_PREFIX`, `REFUSAL_ID`, `CLI_REFUSAL` on exit 2 + `cerberus-lean: refused — `); `scripts/test_exec.sh:37-38, 97-99, 604-664`; `scripts/test_immaculate.sh:95-120`; `scripts/common.sh:436-446` (`is_cap_kill`), `scripts/cap_oom.regex` = `^capped: (OOM-KILLED|OOM event recorded in cgroup)([ (]|$)`; `scripts/check_cli_refusals.sh:21-27`; `scripts/check_asm_refusal.sh:15-23`; `lem-lean/lean-lib/LemLib.lean:210-236` (`@[implemented_by failwithIImpl, never_extract] opaque failwithI {α} [Inhabited α] (msg : String) : α := default`).
- C10 prior-art status: `grep -rn -E 'KillKind|CerbRefuse|Loc\.refusal|refusalKill|kindOf' lean_frontend/*.lean scripts/*.sh scripts/*.py` → none; `git branch -a | grep -i lean-only` → `arc/lean-only-outcomes-S0`, `docs/lean-only-outcomes-S0-record`, `docs/lean-only-outcomes-plan-review`, `docs/d2-structural-outcomes-response`; `git tag | grep park` → `park/effect-spike-content-landed`, `park/reasoning-era-20260831`, `park/spike-relsem-20260819` (no park tag for the outcomes arc); the records read: `docs/2026-09-03_typed-failure-outcomes-ruling.md`, `2026-09-05_typed-failure-outcomes-design.md` (§2.1, §2.5, §5, R1), `2026-09-07_pure-failure-correspondence-design.md` (§0-1), `2026-09-07_pure-failure-reachability-census.md` (Q3, §recommendation), `2026-09-08_monadic-failstop-record.md`, `2026-09-16_structural-outcome-constructors-design.md` (§0-2), `2026-09-16_lean-only-outcomes-scoping-note.md` (§0-4, §7, landing line), `2026-09-16_lean-only-outcomes-implementation-plan.md` (§1-3, R1.8-R1.10), `2026-09-16_lean-only-outcomes-S0-checkpoint-record.md` (§0), `2026-09-19_concurrency-pause-note.md` (§4 item 2), `2026-09-28_cerbfs-refuse-all-record.md`, `2026-10-04_pnvi-ae-udi-design.md` (§0, §1, §F, §G, §H), `2026-10-05_pnvi-s1-switch-parameter-record.md` (§14), `CONTRACT.md` (§1-5), `VALIDATION.md` (§1, §3 PNVI paragraph, §3b), `SUPPORTED.md`, `TODO.md:424-440`, `scripts/LADDER.md` rows 1 and 14.

[USER] provenance: only the rulings cited in §1 and §2, each with its committed source. Everything else here is
[AGENT] or MEASURED as marked. Nothing was decided; nothing was built, pushed or merged.
