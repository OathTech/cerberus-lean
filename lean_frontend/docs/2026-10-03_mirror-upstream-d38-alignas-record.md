# Mirror upstream: revert draft 38's consult, keep only the `_Alignas` completeness check (record, 2026-10-03)

Branch `fix/mirror-upstream-d38-alignas`, from mainline `mdd/cerberus-lean` at `d6c548847`.
Worker: Claude (Opus 5.5), briefed by the orchestrator. Three tasks, one commit each. Not
merged, not pushed.

## 0. Rulings (verbatim, as relayed in the brief)

- [USER 2026-10-03] "Generally, our rule is that we don't innovate wrt Cerberus-upstream, unless
  something is very very very obviously a bug. We're poorly placed to resolve semantic
  discrepancies, so we don't. ... fall back to loudly rejecting (either as unsupported, or
  matching upstream)."
- [USER 2026-10-03] "We do not resolve Cerberus TODO cases unless the answer is extremely obvious
  or if there's a similarly obvious bug, or for some reason we or some downstream customer need it
  with absolute priority".
- [USER 2026-10-03] "Agree on your recommendations with that framing (we shouldn't revert work
  that allows the iris reasoning to work properly)". The recommendations were:
  - revert draft 38's struct compatibility check to upstream's loud exact-tag rejection, after
    checking with cerberus-sl;
  - drop the union twin (P2d-1);
  - for `_Alignas`, keep only the completeness check and mirror upstream on alignment
    compatibility.
- cerberus-sl's answer (orchestrator relay, 2026-10-03): it does NOT rely on `PEmemberof` cross-TU
  struct compatibility. It is single-TU only, and its rules never evaluate `PEmemberof` on struct
  values. It DOES rely on five other deviations, which must not be touched (task 3, VALIDATION §3).

Decisions this worker took inside the brief are marked [AGENT].

## 1. Task 1: revert draft 38's `core_eval.lem` hunk

### 1.1 What draft 38 was in the fork

D3 of the semantics-audit repairs (`dbe633ec5`, 2026-09-15; corpus and lane `83dc6ba00`; record
`docs/2026-09-11_semantics-audit-repairs-record.md` §D3; TODO entry "Finding 5 + draft 38"; tray
`docs/upstream-tray/38-pememberof-cross-tu-struct-value-tag-identity.md`) made two `.lem` changes:

- `ctype_aux.lem` array arm `(n1_opt, n1_opt)` → `(n1_opt, n2_opt)` (draft 39). This is KEPT.
- `core_eval.lem` `PEmemberof(struct)`: the exact-tag guard also consulted
  `Ctype_aux.are_compatible`. This is REVERTED here.

Draft 37 (the assumed-compatible set in `are_compatible_aux`, 2026-09-10, which stops the
recursive-struct hang) is a separate change and is KEPT.

### 1.2 The change (verbatim diff)

```
--- a/frontend/model/core_eval.lem
+++ b/frontend/model/core_eval.lem
@@ -942,18 +942,7 @@ KKK:              EU.return (PEval (Vloaded (LVspecified (OVstruct tag_sym xs)))
         self pe >>= fun pe' ->
         match Caux.valueFromPexpr pe' with
           | Just (Vobject (OVstruct tag_sym' xs)) ->
-              (* semantics-audit repairs D3 (2026-09-11; upstream-tray draft 38): a struct
-                 defined in two translation units carries a different tag symbol in each,
-                 and a struct VALUE produced in one unit may be member-selected under the
-                 other's type. The value is accepted when the two struct types are
-                 compatible (STD §6.2.7#1) — the SAME consult memValueFromValue performs
-                 where a struct value is stored (core_aux.lem:198-200). Equal tags never
-                 reach are_compatible (the conjunction short-circuits), so single-TU
-                 programs are unchanged; the member lookup below is by identifier STRING
-                 (Symbol.idEqual), so it works on the value's own member list. *)
-              if tag_sym <> tag_sym' && not (Ctype_aux.are_compatible
-                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym))
-                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym'))) then
+              if tag_sym <> tag_sym' then
                 EU.fail $ Illformed_program ("PEmemberof(struct) ==> mismatched tags: " ^ show tag_sym ^ " vs " ^ show tag_sym')
               else match List.lookup memb_ident (List.map (fun (a,_,b) -> (a,b)) xs) with
                 | Nothing ->
```

Checks against upstream:

- `sed -n 930,960p` of the fork's file equals the same range of
  `deps/cerberus-upstream/frontend/model/core_eval.lem`. The only remaining `diff` hunk is the
  Lean-only fuel declares at the end of the file (`1200a1201,1232`).
- The file's sha256 is `e1fc98ed…`. That is exactly the pre-D3 `[source-content]` pin.
- After `make prelude-src`, `diff deps/cerberus-upstream/ocaml_frontend/generated/core_eval.ml
  ocaml_frontend/generated/core_eval.ml` is empty.

Both trees were regenerated with the switch's lem (`lem -v`:
`Lem lean-backend-v0.1.0-alpha.1-20-g77ad4fa`): `make prelude-src` rc 0 and
`make lean-prelude-src` rc 0. `Core_eval_lemMeasureProofs` needed no edit (the arm's recursion
is unchanged), and the Lean build is green (§1.6).

### 1.3 Fork-drift manifest

The edits are single rows plus a dated header note "fix/mirror-upstream-d38-alignas task 1".
There was no `--refresh`.

- `[source-content]`: `frontend/model/core_eval.lem` moves from `4ade27ce…` back to `e1fc98ed…`.
- `[expected-semantic]`: the `core_eval.ml` row is REMOVED. The generated file is
  byte-identical to upstream again.

Layer 2 went from 31 to 30 differing generated files. Verbatim:

```
check_fork_content: OK — 86 source files content/mode-pinned
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 matches lem -v lean-backend-v0.1.0-alpha.1-20-g77ad4fa (hex prefix))
```

### 1.4 Every moved row, measured

Three engines plus gcc were run on every `tests/multi_tu_tray` case, 2026-10-03:

- fork oracle: `_build/default/backend/driver/main.exe --runtime=_build/install/default --nolibc --exec --batch --mode=exhaustive tu1.c tu2.c`;
- pristine: the same flags on `.validation-foundations/independent-oracle-v2` (`b9aeedcb4`);
- Lean: `cerberus-lean --batch` on the fork's `--cabs-json`, with `LEAN_ABORT_ON_PANIC=1`;
- gcc: `gcc -std=c11 -O0 -w`.

Each engine has a 30 s timeout. The `Time spent` trailer lines of the OCaml engines are omitted
below; nothing else is.

```
== arr-1-2-arg
fork: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
pristine: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
lean: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
gcc: exit 7
== arr-1-2-return
fork: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
pristine: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
lean: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(63, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"} | rc=1
gcc: exit 7
== arr-2-2-arg
fork: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
pristine: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
lean: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} | rc=0
gcc: exit 7
== arr-2-2-return
fork: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
pristine: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
lean: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(76, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"} | rc=1
gcc: exit 7
== arr-incomplete-ptr-return
fork: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
pristine: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
lean: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(53, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"} | rc=1
gcc: exit 7
== fam-vs-array-return
fork: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(533, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
pristine: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(533, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"} | rc=1
lean: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(50, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"} | rc=1
gcc: exit 7
== node
fork: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"} | rc=1
pristine:  | rc=124
lean: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"} | rc=1
gcc: exit 7
```

(gcc also printed its flexible-array ABI note for `fam-vs-array-return`; that is not a verdict.)

The moved rows and why each one moved:

| Row | Before (mainline `d6c548847`) | After | Justification |
|---|---|---|---|
| `multi_tu_tray/node`, both fork engines | `Defined Specified(7)` | `Error … mismatched tags: … SD_Id("node") …` rc 1 | The consult is gone. Draft 37 still makes `are_compatible` terminate, so the guard is reached, and the guard is upstream's. Pristine never reaches it (rc 124, draft 37). |
| `multi_tu_tray/arr-2-2-return`, both fork engines | `Defined Specified(7)` | `Error … Symbol(558…)/Symbol(76…)` rc 1 | Upstream's guard rejects this compatible cross-TU value. The fork OCaml output is now byte-equal to pristine's. |
| `multi_tu_tray/arr-incomplete-ptr-return`, both fork engines | `Defined Specified(7)` | `Error … Symbol(536…)/Symbol(53…)` rc 1 | Same reason as `arr-2-2-return`. |
| `arr-1-2-return`, `fam-vs-array-return`, both argument rows | unchanged | unchanged | Already rejected by the guard, or never reach it (the argument path). |
| Pristine register `multi_tu_tray/node` | fork side `0 / aac62ecb… / e3b0c442…` | fork side `1 / a5e73a6c… / e3b0c442…`; citations draft 37 + tray README + this record; rationale rewritten | The row STAYS. Pristine still hangs; that is draft 37 alone. |
| Pristine register `multi_tu_tray/arr-2-2-return` | `shared-model-fix` row | REMOVED | The fork now equals pristine (`semantic_agreement`). |
| Pristine register `multi_tu_tray/arr-incomplete-ptr-return` | `shared-model-fix` row | REMOVED | Same reason. |
| LADDER row 6b (`--failure-class-projection tests/multi_tu_tray`) | 7/7 MATCH (2 Error + 5 Defined) | 7/7 MATCH (5 Error + 2 Defined) | Both fork engines moved together. The `Error` texts differ only in symbol numbers, which the row's projection elides. |
| Row 10 (pristine gate) counts | `{'semantic_agreement': 950, 'matching_failure': 37, 'reviewed_difference': 7, 'interface_agreement': 2}` (the 2026-10-03 total-arith record, `docs/2026-10-03_total-arith-and-bookkeeping-record.md:706`) | `{'semantic_agreement': 952, 'matching_failure': 37, 'reviewed_difference': 5, 'interface_agreement': 2}` | Two rows moved from `reviewed_difference` to `semantic_agreement`: `arr-2-2-return` and `arr-incomplete-ptr-return` (read from the report). The total is unchanged at 996. |
| Row 10 `--plant` withheld-row plant | picked `multi_tu_tray/arr-2-2-return` | picks `minimal/112-allocator-exhausted-single-request.c` | The plant takes the first `shared-model-fix` row with a completing pristine side. It is still RED-on-withhold (`plant_ok`). LADDER row 10's text is updated. |

Nothing else moved. Every Tier A baseline reports 0 regressions and 0 improvements, and the
failure-reach register is unchanged at 233 (the revert removes no failure site). **No finding.**

The pristine-register edit is by hand: two rows deleted, and the `node` row's `fork`, `citation`
and `rationale` rewritten. The fork signature is the one row 10's own report gave for the fork
side (`.tmp/d38/uo-tray/report.json`, `--only multi_tu_tray`, before the edit: status 1, stdout
sha256 `a5e73a6c…`, diagnostic sha256 `e3b0c442…`).

### 1.5 Documents updated

- Tray 38: new "Fork status (2026-10-03) — REVERTED" section. The 2026-09-15 section is kept and
  marked historical.
- Tray 39: a 2026-10-03 update. The fix is kept, but on the tray the guard masks it again.
- Tray INDEX entry 38.
- `TODO.md`: the "Finding 5 + draft 38" entry, "Union twin" (dropped) and the compatibility-trio
  residual.
- `VALIDATION.md` §3: the `shared-model-fix` paragraph is now 1 row, with history. The register
  count paragraph and the lane table row are updated too.
- `scripts/LADDER.md` rows 6b and 10, and `tests/multi_tu_tray/README.md`, which gets a
  post-revert three-engine table; the D3 table is kept as historical.
- The next-phase plan (P2d-1 dropped): see §4. It lives on its own branch.

### 1.6 Gates for task 1 (verbatim tails)

Builds, all rc 0:

```
dune main+lib rc=0
local install rc=0
cerberus.install rc=0
native-obj rc=0
✔ [395/395] Built «cerberus-lean»:exe (1.3s)
Build completed successfully (395 jobs).
✔ [147/148] Built SpecLab (259ms)
Build completed successfully (148 jobs).
```

Tier A (`python3 scripts/release.py --mode fast`, which includes row 1):

```
PASSED A1 (293.1s)
PASSED A2 (33.4s)
PASSED A3 (74.0s)
PASSED A4 (23.7s)
PASSED A4b (24.7s)
PASSED A4c (3.1s)
PASSED A5 (108.9s)
PASSED A6 (4.2s)
PASSED A6b (3.8s)
PASSED A7 (11.0s)
PASSED A8 (8.8s)
PASSED A9 (17.4s)
PASSED A10 (19.2s)
PASSED A11 (61.0s)
PASSED A12.1 (5.3s)
PASSED A12.2 (4.7s)
PASSED A13 (1.6s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

Selected per-lane lines:

```
A1:  Total: 16 passed, 0 failed
A1:  check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; …)
A2:  SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
A2:  Baseline check: 0 regression(s), 0 improvement(s)
A3:  SUMMARY: total=276 match=224 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
A3:  Baseline check: 0 regression(s), 0 improvement(s)
A4:  Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5:  SUMMARY: match=43 diff=0
A6:  SUMMARY: total=8 match=8 fail=0
A6b: SUMMARY: total=7 match=7 fail=0
A10: GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11: BASELINE OK (213 entries, exact match)
```

Pristine-oracle gate (row 10) and its plants:

```
Independent oracle scope: tier-b; 996 rows in 206.7s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 952, 'matching_failure': 37, 'reviewed_difference': 5, 'interface_agreement': 2}; …/.tmp/d38/uo-t1/report.json
3/3 plant_ok: plant/withheld-row:minimal/112-allocator-exhausted-single-request.c — minimal/112-allocator-exhausted-single-request.c: with its register row -> reviewed_difference; row withheld -> difference (completed semantic observations differ)
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/.tmp/d38/uo-t1-plant/report.json
```

gcc lane (`scripts/test_gcc_oracle.sh --check-baseline`):

```
SUMMARY: total=2030 compared=1934 agree=1918 agree_nd=0 triaged=16 disagree=0 o2_agree=197 skip_gcc_compile=4 skip_gcc_stdout=2 skip_lean_crash=18 skip_lean_fail=14 skip_lean_timeout=11 skip_ub=47 triaged_addr=14 triaged_float=1 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
rc=0
```

The gcc lane does not walk `tests/multi_tu_tray`, so draft 38's revert cannot move it. It moved
nowhere.
