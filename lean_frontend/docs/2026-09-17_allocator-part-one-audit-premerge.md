# Pre-merge audit — `arc/allocator-soundness-address-bound` PART ONE (C1 + C1b, 2026-09-17)

**Range:** `6d9ba82f1..f5b1578dc` — four commits (`7b51b0b43` C1: remedy 1 in `memory/{concrete,vip}/impl_mem.ml`, the Lean mirror `CerbMem.allocator`, the proof seam `CerbMemAllocatorProofs.lean`, the runtime witness `test/Unit/AllocatorSoundnessTest.lean`, drift rows, VALIDATION §3, tray 44's LANDED line; `a2cf688c0` interim record; `f9843725d` C1b: `test_upstream_oracle.py`'s diagnostic projection normalises the position in an OCaml exception HEADER line + 8 plants + doctrine sentences; `f5b1578dc` record amendment). Base `6d9ba82f1` = mainline `mdd/cerberus-lean` `4a23d98aa` + the charter commits; `git merge-base --is-ancestor mdd/cerberus-lean f5b1578dc` → yes, 6 commits ahead (ff-able as of this audit).
**Head audited:** `f5b1578dc`, branch `audit/allocator-part-one` in `worktrees/cerberus-lean-audit/allocator-part-one` (container hook; standing pristine oracle `b9aeedcb4`/lem `3802cb0` built by the hook, `manifest.json` `status: built`).
**Who:** an INDEPENDENT pre-merge auditor (Claude, Fable 5.1) — [AGENT auditor] throughout. I wrote none of the range. Every claim marked *reproduced* is my own run in this worktree; quoted outputs are verbatim; tallies are labelled derived. The rulings the range implements — [USER 2026-09-16] *"unambiguously wrong … allowed to fix ahead of upstream"*, [USER 2026-09-17] *"yes, agreed regarding landing C1 as-is and then working on C2/C3 separately"* — are not questioned; whether the code and the documents implement EXACTLY them is.
**Evidence:** [`2026-09-17_allocator-part-one-audit-evidence/`](2026-09-17_allocator-part-one-audit-evidence/) (README there: probe programs, plant scripts, gate transcripts, verbatim outputs). Scratch under the git-ignored `.tmp/audit/` and `lean_frontend/.tmp/`.

**What I ran (all at `f5b1578dc`, one heavy job at a time, box load 0.2–2.3 throughout, 17:15–18:06 UTC).** Read in the prescribed order: charter, record + evidence dir, tray 44, container `CLAUDE.md`, `lean_frontend/CLAUDE.md`, the full range diff. Reproduced: `release.py --mode fast` (14/14), row 10, `--plant`, `--corpus ci`; `check_fork_drift.sh`; both fixed OCaml models compiled; a standalone Zarith program (pristine body vs remedy 1) and a Lean probe on the ACTUAL `CerbMem.allocator` over the same 42 states; `#print axioms`; two negative controls on the PRE-FIX compiled body (the theorem module fails to build; the witness's expectations fail on the two defect states); 18 hermetic plants against the header projection; my own tokenizer over the `g2-memcmp-uninit` captures; a record-quote check; and **eleven C programs on the pristine oracle, the fork oracle and the Lean engine** to test the range's central classification claim. **Process disclosure:** (1) the hook primes `lean_frontend/generated/` and `.lake` from the MAIN checkout, so this worktree's compiled `CerbMem.olean` was the PRE-FIX body until I ran `make lean-prelude-src` (the Makefile's one copy authority) + a capped rebuild (50 modules, 34 s) — I took the negative controls on that primed state deliberately, then re-took (b) with a saved transcript by swapping the ignored `generated/CerbMem.lean` copy and restoring it byte-identically (`negctrl_b.log`: sync gate OK, 2 modules rebuilt, driver hash `1ee93131…` unchanged, both stamps OK); (2) my `dune build … @memory/vip/all …` relinked `main.exe` (`version.ml`) without the recipe's stamp, so my first row-10 family FAILED CLOSED on `check_driver_fresh.sh --check-oracle` (`gate_chain.log`) — the instrument working as designed; the family was re-run after `release.py`'s exec lanes re-stamped through `build_cerberus`; (3) I ran `tools/check_driver_fresh.sh --record-lean` once after my rebuild, as `common.sh build_lean` does; (4) a backgrounded 65536-iteration reproducer was killed after its two OCaml results (both `out of memory`, ~220 s each) once a one-shot variant superseded it. No tracked file was modified; the audited branch, the primary checkout and the consumer repo were not touched.

## 0. Verdict

**MERGE-WITH-FIXES — one MAJOR finding, on the range's central classification claim, not on the fix.** The code is right: the OCaml body in both models is remedy 1 exactly and nothing else changed in either file; the Lean mirror follows it line by line with the same check ORDER, the same failure text and an unchanged kill-state (42-state agreement with the fixed arithmetic; the only divergence is the documented `align = 0` refusal); `allocator_active_sound` is a GENERAL statement with no hypothesis, TRUE as elaborated (including `align < 0` and `sz < 0`), kernel-only (`propext`, `Classical.choice`, `Quot.sound`), stated on the ACTUAL `allocator`, and it FAILS to build against the pre-fix body (three unsolved goals in exactly the defect branch); the runtime witness matches draft 44's post-fix table, its negative control is genuinely quoted and discriminates (2/4 FAIL on the old body); the header projection hides no text, path or stdout difference in 18 auditor plants and the 8 lane plants; the drift pins re-derive; every gate reproduces the orchestrator's lines with no baseline movement. **But the range classifies the fork≠pristine deviation as "UNOBSERVABLE at upstream's bound (~2^48 bytes of cumulative allocation needed)" in `VALIDATION.md` §3, the drift manifest, the `CerbMem.lean` docstring, the record and upstream-tray draft 44 — and that is false: a 13-line ordinary C program, no flag, makes pristine `b9aeedcb4` return `Specified(6)` (an ACTIVE allocation at address 6, misaligned, ending above the cursor) where the fork and Lean kill with `out of memory`, in 50 ms (M1).** Under the project's own doctrine (VALIDATION §0: *"a delta with no register row is either unobservable on the corpora or a missing case"*) this is a MISSING CASE — a real, reproducible fork≠pristine behaviour absent from the register and from every walked corpus, presented in normative text as impossible to observe; the upstream filing carries the same false sentence and a weaker reproducer than it could. Two MINOR findings: the provenance chain for the C1b projection extension (M2) and off-by-one pristine line cites inherited from the tray and re-asserted as verified (M3). Eight NOTEs. **Required before merge:** M1 (reclassify in the four documents and the docstring; amend tray 44's Reproducer/Impact; add the witness to a walked corpus with a `shared-model-fix` register row — the last two are the operator's call, recommended) and M3; then row 10 (+ the new case's owning lane) re-gated and the record amended. M2, N3, N4, N6 should ride along.

## 1. Findings

Grades as in the 2026-09-17 WP-O audit: MAJOR = a trust gap, a hidden real difference, or a ruling not implemented; MINOR = a fail-open shape, an overclaim in a normative document, or a mirror deviation, each with a small fix; NOTE = precision, process, or a residual the merge need not wait for. Severities are [AGENT auditor] judgments.

### M1 — MAJOR — the deviation is OBSERVABLE at upstream's own bound by an ordinary program; "UNOBSERVABLE … ~2^48 bytes of cumulative allocation needed" is false, so the register is missing a case and the upstream filing a reproducer

**Where the claim is made:** `lean_frontend/VALIDATION.md:436` (the entry's title *"UNOBSERVABLE `shared-model-fix` deviation — content-pinned, NO register row"*) and `:458-461` (*"pristine differs ONLY in the exhausted regime, which at upstream's bound needs ~2^48 bytes of cumulative allocation in one run — no corpus program does that, so row 10 sees no difference and the register has no row"*), `:463-465` (*"becomes OBSERVABLE … once the address-space bound is a parameter"*); `scripts/fork_drift_manifest.txt:9`; `lean_frontend/CerbMem.lean:2077` (*"UNOBSERVABLE at upstream's bound"*); the record `:212`, `:449`, `:461`; tray 44 `:44-46` (*"No C program reaches the regime at the default bound … the cumulative size of every `create`/`alloc` in one run would have to exceed about 2^48 bytes"*), `:82-83` (*"at the default bound this is about 2^48 bytes, so no test program is affected today"*), `:125`, `:149`; the charter §1 "Observability" paragraph (the premise the worker was given — the error originates in the tray's analysis, pre-range, and the range propagates it into normative documents).

**Why the reasoning fails:** the cursor does not have to fall by 2^48. The exhausted regime is `z = last_address − sz < 0` and the defect window is `−align/2 < z < 0`: ONE request of `cursor + k` bytes with `1 ≤ k < align/2` enters it, `size_t` is 64-bit here (`sizeof(size_t)=8`, `SIZE_MAX=18446744073709551615` — `repro/sizes-bigstatic-loop.out.txt`), and a program reads its own cursor as `(uintptr_t)malloc(1)` (`impl_mem.ml` allocator: `last_address := addr`). Two model facts fix the offsets: `malloc` is `std.core:350` `alloc(IvMaxAlignment, size)` behind `malloc_proxy (size_ptr: pointer)`, whose call site `create`s an 8-byte argument temporary before `alloc` runs, so the cursor at `alloc` is `a − 8`; and `IvMaxAlignment` is 8 (measured: a request of `a − 16` lands at low byte 8 on both oracles, `repro/variants.out.txt` v5). The window is therefore requests of `a − 7`, `a − 6`, `a − 5` (`z = −1, −2, −3`; pristine `z' = z + (z mod 8) = 6, 4, 2`).

**Reproduction** (*reproduced*; `repro/w1-minus7.c` — the whole program:)
```c
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a - 7));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
```
run as row 10 runs `tests/minimal` (`--nolibc --exec --batch --mode=exhaustive`), verbatim (`repro/window.out.txt`, `repro/w1-lean-and-print.out.txt`):
```
### w1-minus7    / pristine Defined {value: "Specified(6)", stdout: "", stderr: "", blocked: "false"} [rc=0]
### w1-minus7    / fork     Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w2-minus6    / pristine Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"} [rc=0]
### w2-minus6    / fork     Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w3-minus5    / pristine Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"} [rc=0]
### w3-minus5    / fork     Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w4-minus4    / pristine Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w4-minus4    / fork     Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w5-minus8    / pristine Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w5-minus8    / fork     Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [rc=1]
### w1-minus7  / LEAN (fork --nolibc --cabs-json bridge; cerberus-lean --batch; LEAN_ABORT_ON_PANIC=1; capped) Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [bridge rc=0 lean rc=1]
### w3-minus5  / LEAN (…) Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""} [bridge rc=0 lean rc=1]
```
(the two edge controls `a − 4` and `a − 8` kill on all three engines — the window is exactly the arithmetic's). The self-checking variant `repro/w1-overlap.c` exits `Specified(106)` on pristine = address 6 + 100 (the new object `[6, a − 1)` ends ABOVE the cursor `a − 8`, i.e. overlaps the live argument temporary) + 0 (NOT 8-aligned) — the full defect signature of draft 44, at the default bound, 50 ms wall. Lean = fork on every case (zero-discrepancy holds; the Lean column of a three-engine report would read `lean_agreement` with `pristine ≠ fork`).

**Consequences.** (a) The §3 entry's class label and its "becomes OBSERVABLE only once the bound is a parameter" sentence are wrong; the drift manifest header, the docstring and the record repeat it. (b) VALIDATION §0 `:120-125` says the register *"is the ONLY permitted list of fork≠pristine behaviours OBSERVED on the walked corpora … a delta with no register row is either unobservable on the corpora or a missing case"* — this is the second disjunct: a behaviour any walked corpus could witness with a 13-line file has no row and no case, so the inventory is incomplete by the doctrine's own test (row 10's `{822, 28, 3, 2}` is honest about the corpora it walks and silent about this). (c) Tray 44, to be filed upstream, states *"No C program reaches the regime at the default bound"* and offers only the arithmetic as reproducer, when the program above is the far stronger filing. (d) The C3 rationale ("observable at a tiny bound only through the fork-only flag, which pristine does not have") loses its premise — the tiny-bound lane stays useful, but it is not the only witness.

**Fix (recommended before merge):** (1) reword the four documents and the docstring: "UNOBSERVED on the walked corpora (no corpus program requests within `align/2` of its cursor); OBSERVABLE at upstream's bound by `<the witness>`"; strike the 2^48 sentences. (2) Add the witness (w1 with the w4 control if wanted) to a walked corpus — `tests/immaculate/nolibc/` fits (single file, nolibc, class-pinned baseline; the row would be `MATCH` fork = Lean) — and a `shared-model-fix` register row (pristine `status 0` / `Specified(6)`; fork `status 1` / the `Error` line; citations tray 44 + record + this audit) so row 10 reads `reviewed_difference` on it and the three-engine report shows `pristine ≠ fork = Lean`; the register becomes 4 rows and the §0 sentence "exactly 3 rows" moves with it. This is the operator's call ([USER]-class territory: register rows); the alternative — keep the case out of the walked corpora — would leave a known, reproducible fork≠pristine behaviour outside the inventory, which is the fail-open shape the doctrine forbids. (3) Amend tray 44's Reproducer and Impact with the program and its three-engine output, and correct "No C program …". Then re-gate row 10 (+ `test_immaculate.sh --check-baseline` for the new case) and amend the record.

### M2 — MINOR — the provenance chain for the C1b projection extension rests on an unquoted proposal

**Where:** `VALIDATION.md:473-474` and the sentence around it (*"[USER 2026-09-17], verbatim: 'yes, agreed regarding landing C1 as-is and then working on C2/C3 separately', given on the orchestrator's proposal that this projection be extended to the header"*), `scripts/test_upstream_oracle.py:215-217`, `LADDER.md` row 10, record §S1 `:307-312`.
**Claim audited:** the doctrine sentences "quote the ruling verbatim and do not overclaim". The quotation is verbatim (it matches my brief character for character) and the [USER] tag is right — assent to a proposal is a user-called decision. But the words assent to "landing C1 as-is" and "working on C2/C3 separately"; the projection extension is item (1) of a three-part orchestrator proposal that is paraphrased (record `:13-16`) and quoted nowhere, so a reader of VALIDATION §3 cannot verify from the record what exactly was ruled on. The container rule makes [USER]/[AGENT] provenance load-bearing; a normative document should carry a verifiable chain.
**Fix:** quote the orchestrator's proposal text (1) verbatim in record §S1 beside the ruling (the orchestrator has it), and let §3 cite "record §S1" for it. One paragraph; no code.

### M3 — MINOR — the pristine rounding-line cites are off by one, in the upstream filing and in the range's new normative text, and the record asserts them re-verified

**Where:** `VALIDATION.md:440` (*"Pristine `b9aeedcb4` `memory/concrete/impl_mem.ml:1253` (VIP twin `:208`) aligns the new base with …"*); `CerbMem.lean:2081` (*"Pristine :1253 rounded"*); tray 44 `:3` (*"the rounding line is `:1253`"*), `:15` (`(* :1253 *)` on the `let z'` line), `:8` (VIP `:202-211`); record §1 (*"All §1 cites re-verified and CORRECT … `:1247-1262` (`:1253` the rounding line)"*), §C1.1 does not repeat it.
**Reproduction** (`awk` over the standing oracle's `git archive` of `b9aeedcb4`, and over `git show 6d9ba82f1:memory/concrete/impl_mem.ml` — identical at these lines):
```
1252	      let z = sub st.last_address sz in
1253	      let (q,m) = quomod z align in
1254	      let z' = sub z (if q < zero then neg m else m) in
```
and VIP `207 let z … / 208 let (q,m) = quomod … / 209 let z' = sub z (if q < zero …)`. The rounding line is `:1254` (VIP `:209`); `:1253`/`:208` are the `quomod` lines. The post-fix cites the worker wrote (`:1252`, `:1255-1256`, `:1258`, `:1259`, `:1260-1261`, `:1263-1270`; VIP `:207`, `:210-218`, `:202-225`) all resolve correctly (§2.2) — only the pristine-side cites inherited from the tray are off. Cosmetic in effect, but the tray goes to upstream and the record claims verification.
**Fix:** `:1253` → `:1254`, VIP `:208` → `:209` in the four places (tray, VALIDATION §3, the docstring, record §1's erratum list gains one line).

### N1 — NOTE — the prose gloss "disjoint from everything at or above the cursor" needs `sz ≥ 0`; the kernel statement is exact and needs nothing

`allocator_active_sound` is stated with no hypothesis and is true as elaborated: for `sz < 0` the conclusion `a + sz ≤ st.lastAddress` holds while `a` EXCEEDS the cursor (measured on both engines, `alloc_arith.out.txt` / `lean_alloc_probe.out.txt`: `last=8 sz=-4 align=4: active addr=12 cursor'=12`) — the "disjoint" reading is only meaningful for `sz ≥ 0`, which every C caller satisfies (`sizeof`, `size_t`). For `align < 0` the Euclidean remainder is still `≥ 0`, so `align ∣ a ∧ 0 < a` hold (`last=9 sz=4 align=-4: active addr=4` — pristine gave 6 here: a second pre/post difference, unreachable from C since alignments are positive). The prose in `CerbMemAllocatorProofs.lean:40-41`, VALIDATION §3 `:452-453` and `lean_frontend/CLAUDE.md:257` (the `CerbMem.lean:2101-2104` CONTRACT summary states the bound without the gloss) should say "the new object's end `a + sz` is at or below the cursor (disjoint, for `sz ≥ 0`)". No change to the theorem.

### N2 — NOTE — the ruled projection's residual blind spot: two DIFFERENT `assert` sites in the same OCaml function and file are now one failure

Plant H12 (`plants/header_projection_plants.out.txt`): header `impl_mem.ml, line 2659, characters 16-22: Assertion failed` + `Raised at …memcmp.get_bytes.(fun) in file …, line 2659` vs the same shapes at `line 2701, characters 10-16` → `matching_failure`; the PRE-C1b projection read this pair as different (`pre-C1b=differs post-C1b=same`). Inherent to normalising the header position "exactly as frames" (frames already had it for two call sites in one function); recorded so the class is not mistaken for a gap. No fix proposed.

### N3 — NOTE — three verbatim lines in record §S1 have no evidence-file backing

`check_record_quotes.out.txt`: 72 fenced lines checked, 3 missing — `row10 rc=1 wall=114s`, `three-engine rc=1 wall=252s`, and `Independent oracle: failed; {'semantic_agreement': 822, 'matching_failure': 27, 'reviewed_difference': 3, 'interface_agreement': 2, 'difference': 1}; …/.tmp/c1-three-engine/report.json` (record `:258`, `:261`, `:263`) — sourced from the deleted `.tmp/c1-*.log`; the row-10 verdict line with the `bid3d5si` path IS in `c1-row10-difference-g2-memcmp-uninit.txt`. 36/36 runner timing tokens present. Fix: append the three lines to that evidence file (the record's header already allows "a lane log summarised there", but the record-gate-tails rule wants them on file).

### N4 — NOTE — two small record inaccuracies

(a) §C1.2: *"the immaculate `zd-z2m01-*` rows are class pins `MATCH | L=CRASH`"* — only `zd-z2m01-aligned-alloc-zero-zero` is; the other two are `ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", …}` (`tests/immaculate/baseline.txt:149-151`). The point (no baseline pins the refusal TEXT) holds. (b) Open item 4 declares `VALIDATION.md` §5's lane-table row for `test_upstream_oracle.py (+ --plant)` still lists the pre-C1b plants — confirmed still true at the head; ride along with M1's doc pass.

### N5 — NOTE — side-observation, OUT OF RANGE: `(size_t)x + 1` is truncated to 32 bits on all three engines

Found while building M1's reproducer (it is why my first attempts missed the window). `repro/trunc2.out.txt` (both oracles, libc): `(size_t)a+1=4294962425 (unsigned long)a+1=281474976705785 (uintptr_t)a+1=281474976705785 (size_t)a+0=4294962424 … plain ulong: (size_t)b+1=4294962497 … (uintptr_t)c+1=281474976705857` — any arithmetic on a `(size_t)`-cast operand truncates modulo 2^32; the same value cast as `(unsigned long)`, or cast AFTER the addition, does not; no pointer provenance is needed. `repro/trunc3.c` (nolibc, no printf): `Specified(1)` on pristine, fork and Lean. A shared-model front-end/semantics defect candidate for the upstream tray (a `size_t` typedef vs `Size_t` builtin conversion, presumably); pre-existing, untouched by this range, zero-discrepancy holds. Recommend a tray draft; not a merge item.

### N6 — NOTE — `check_theorem_axioms.sh`'s `#print axioms` legs do not name the two new theorems (record open item 3)

The legs that pin proof seams BY NAME (`PROBE4` `MEMSCALE_THMS`, `PROBE5` `FUEL_THMS`, `scripts/check_theorem_axioms.sh:775-905`) do not list `CerbMem.allocator_active_sound` / `allocator_below_request_kills`. The routes to a non-standard axiom are covered anyway: the D14 grep-ban leg scans the 49 manifest-listed seam files (the new one included — *reproduced* in A1: `D14 grep-ban OK (… 49 hand-written seam files …)`), the `^axiom` census and comment-stripped ratchet cover `lean_frontend/*.lean`, `check_sorry_token` covers the text, and LemLib's zero-axiom census the import. No fail-open shape; belt-and-braces gap. Fix: two names + `import CerbMemAllocatorProofs` in `PROBE4` (out of the worker's fence — the orchestrator's one-liner).

### N7 — NOTE — worktree priming vs a branch that edits a hand-written seam (process, fail-closed both times)

The hook primes `generated/` and `.lake` from the main checkout, so in an audit worktree of such a branch `check_handwritten_sync` FAILS until `make lean-prelude-src` runs (`test_unit.sh`/`build_lean` refuse — correct); and any `dune build` outside the `build_cerberus` recipe relinks `main.exe` (`version.ml`) and trips `check_driver_fresh --check-oracle` (row 10 refused — correct). Both are documented behaviours doing their job; recorded for the next auditor. The primed pre-fix `CerbMem.olean` also made the negative controls cheap (§2.3/§2.4).

### N8 — NOTE — `HEADER_POSITION` accepts a `lines N-M` header form and CRLF endings

The regex's `lines? [0-9]+(?:-[0-9]+)?` matches `File "…", lines 10-12, characters …:` (a form OCaml's `Assert_failure`/`Match_failure` printers never emit) — a harmless superset (plant H9); a CRLF-terminated header is normalised with the `\r` kept inside the preserved text group on both sides (plant H13 — my expectation was wrong, the code is right). No change needed.

## 2. The scope items — what I did, verbatim outputs, verdict

### 2.1 The OCaml fix vs remedy 1

**Diff read** (`git diff 6d9ba82f1..f5b1578dc -- memory/`): one hunk per file, `+10 −3` each, identical text at indent 6/4 — `if z < zero then fail (MerrOther "Concrete.allocator: failed (out of memory)") else let (_, m) = quomod z align in let z' = sub z m in if z' <= zero then fail (…same text…) else return z'`, preceded by a two-line fork comment citing draft 44; the `let (q,m)` / `if q < zero then neg m else m` lines deleted; `put`/`return` untouched. That is remedy 1 as draft 44 `:100-103` and the charter §1 state it: fail on `z < 0` BEFORE rounding, `z' = z − m` with the Euclidean `m`, the `z' ≤ 0` kill kept, the dead branch gone, the text unchanged in both models. Nothing else changed in either file (`git diff --stat`: 13 lines each).
**Both models compiled** (*reproduced*, `ocaml_models_build.out.txt`): `dune build @memory/concrete/all @memory/vip/all backend/driver/main.exe cerberus-lib.install` → `ocamlopt memory/vip/.mem_vip.objs/native/cerb_frontend__Impl_mem.{cmx,o}`, `ocamlopt memory/concrete/…Impl_mem.{cmx,o}`, `dune rc=0`; installed `_build/install/default/lib/cerberus-lib/mem/{concrete,vip}`. `memory/dune` `(dirs cheri-coq concrete symbolic vip)`: `symbolic` (`libraries z3`) fails here — `(no z3/lwt/cohttp/coq in the switch)`; `cheri-coq` is package `cerberus-cheri`. Neither is built by the ladder recipe nor touched by the range.
**The arithmetic, evaluated myself** (`alloc_arith.ml` — the pristine and the new bodies copied verbatim, `Z.quomod = ediv_rem`; 42 states; `alloc_arith.out.txt`), the states the brief names, verbatim `NEW` then `PRISTINE`:
```
ediv_rem (-1) 4 = (-1, 3)
ediv_rem 7 (-4) = (-1, 3); ediv_rem (-7) (-4) = (2, 1); ediv_rem (-7) 4 = (-2, 1)
last=3 sz=4 align=4: killed(out of memory) cursor'=3          | PRISTINE: active addr=2 cursor'=2
last=7 sz=8 align=8: killed(out of memory) cursor'=7          | PRISTINE: active addr=6 cursor'=6
last=2 sz=4 align=4: killed(out of memory) cursor'=2          | PRISTINE: killed(out of memory) cursor'=2
last=8 sz=4 align=4: active addr=4 cursor'=4                  | PRISTINE: active addr=4 cursor'=4
last=8 sz=-4 align=4: active addr=12 cursor'=12               | same
last=8 sz=4 align=1: active addr=4 cursor'=4                  | same
last=4 sz=4 align=1: killed(out of memory) cursor'=4          | same
last=8 sz=0 align=4: active addr=8 cursor'=8                  | same
last=0 sz=0 align=4: killed(out of memory) cursor'=0          | same
last=4 sz=4 align=4: killed(out of memory) cursor'=4          | same   (cursor == sz)
last=7 sz=4 align=4: killed(out of memory) cursor'=7          | same   (cursor = sz + align − 1)
last=100 sz=4 align=1180591620717411303424: killed(out of memory) cursor'=100   | same   (align = 2^70)
last=9 sz=4 align=-4: active addr=4 cursor'=4                 | PRISTINE: active addr=6 cursor'=6
last=-1 sz=0 align=4: killed(out of memory) cursor'=-1        | PRISTINE: active addr=2 cursor'=2
last=8 sz=4 align=0: Division_by_zero                         | same
last=3 sz=4 align=0: killed(out of memory) cursor'=3          | PRISTINE: Division_by_zero
last=281474976710655 sz=281474976710656 align=16: killed(out of memory) cursor'=281474976710655   | PRISTINE: active addr=14 cursor'=14
last=281474976710655 sz=281474976710662 align=16: killed(out of memory) cursor'=281474976710655   | PRISTINE: active addr=2 cursor'=2
```
(the `|` column is derived from the file's second block). NEW ≠ PRISTINE on exactly seven of the 42 states: the two defect states, `(9,4,−4)`, `(−1,0,4)`, `(3,4,0)` and the two upstream-bound window states — every one in the `z < 0` regime or the `align ≤ 0` corner; every `z ≥ 0` state is unchanged. **Verdict: remedy 1 exactly; nothing else; both models build.**

### 2.2 The Lean mirror

`CerbMem.allocator` (`CerbMem.lean:2110-2125`) against `impl_mem.ml:1247-1270`, every cite checked by `awk` (`:1252` `let z`, `:1255-1256` the kill, `:1258` `quomod`, `:1259` `let z'`, `:1260-1261` the second kill, `:1263` `return z'`, `:1264-1270` `put … return (alloc_id, addr)`; VIP `:202`, `:207`, `:210-218`, `:225`) — all resolve. **Order of the two checks:** OCaml tests `z < zero` at `:1255` and reaches `quomod` (where `align = 0` raises `Division_by_zero`) only at `:1258`; Lean tests `z < 0` first and `align == 0` second — the SAME order, so for `align = 0 ∧ z < 0` both engines give the out-of-memory kill (*reproduced*: `last=3 sz=4 align=0: killed(out of memory) cursor'=3` in both `## NEW` blocks) and for `align = 0 ∧ z ≥ 0` the OCaml raises and Lean refuses (the pre-existing Z2 §10 kind-2 artifact ruling; `MonadicFailstop.lean:34` re-pins the refusal text with its cite moved `:1252 → :1258`). The pre-fix Lean checked `align == 0` FIRST — for `align = 0` both engines then gave an artifact outcome whatever `z` was, so no pre-fix behavioural difference existed either; the record's "the refusal MOVED after the kill" is the faithful order, not a divergence. **Failure text** byte-for-byte `"Concrete.allocator: failed (out of memory)"` at all four sites (two OCaml, two Lean). **Kill-path state:** the Lean returns `st` on both kills; the OCaml `fail`s before `put` — unchanged on both (every `killed` line above has `cursor' = last`). **The mirror on the ACTUAL `CerbMem.allocator`** (`AuditAllocProbe.lean` via `lean_probe.sh`, through `allocatorStep`): `diff` of the two `## NEW` blocks →
```
34c34
< last=8 sz=4 align=0: Division_by_zero
---
> last=8 sz=4 align=0: killed[other kind]
36c36
< last=4 sz=4 align=0: Division_by_zero
---
> last=4 sz=4 align=0: killed[other kind]
```
— identical on the other 40 states; the two differences are the documented refusal arm. `Int emod/ediv: (-1)%4=3 (-1)/4=-1; 7%(-4)=3 7/(-4)=-1; (-7)%(-4)=1 (-7)/(-4)=2; (-7)%4=1 (-7)/4=-2` = Zarith's `ediv_rem` line above. **Verdict: faithful; same order; same text; same state.** (M3: the docstring's pristine cite `:1253`.)

### 2.3 The theorem

**Statement as elaborated** (*reproduced*, `lean_alloc_probe.out.txt`):
```
allocator_active_sound : ∀ (st st' : MemState) (sz align id a : Int),
  allocatorStep sz align st = (NDactive (id, a), st') →
    align ∣ a ∧ 0 < a ∧ a + sz ≤ st.lastAddress ∧ st'.lastAddress = a
allocator_below_request_kills : ∀ (st : MemState) (sz align : Int),
  st.lastAddress - sz < 0 →
    allocatorStep sz align st = (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st)
'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator_below_request_kills' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocatorStep' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator' depends on axioms: [propext, Classical.choice, Quot.sound]
```
GENERAL: quantified over every state, size and alignment, no hypothesis — as the record claims. TRUE as stated: for `align ≠ 0` the Euclidean `m = z % align ≥ 0` (`Int.emod_nonneg`, for negative divisors too), `a = z − m = align · (z / align)` (`Int.emod_def`) so `align ∣ a`; `0 < a` is the surviving guard; `a ≤ z = lastAddress − sz` gives `a + sz ≤ lastAddress`; `align = 0` is the refusal arm, never active. `align < 0` and `sz < 0` checked by evaluation above (N1 on the prose). **`Address` honest:** `#check` prints `a + sz ≤ st.lastAddress` with no coercion; `example : CerbMem.Address = Int := rfl`, `example (st : MemState) : (st.lastAddress : Int) = st.lastAddress := rfl`, `example (a b : Int) : a % b = Int.emod a b := rfl` all elaborate (probe rc 0). **`allocatorStep` observes the SAME allocator:** `match allocator sz align with | ND f => f st` on `CerbMem.allocator` itself (`CerbMemAllocatorProofs.lean:25-28`), the `CerbFail.step` shape restated; the driver reaches that `allocator` through `allocateObject` (`CerbMem.lean:2147` `nd_bind (allocator size alignN)`) and `allocateRegion` (`nd_bind (allocator sizeN alignN)`), the `mem.lem:94/:97` target_reps. **Tactics (read):** `simp only`, `split at h`, `simp at h` (constructor clash), `rename_i`, `obtain`, `subst`, `have … Int.emod_nonneg / Int.emod_def / Int.not_le`, `generalize`, `refine … <;> omega`; `allocator_below_request_kills` is `simp [allocatorStep, allocator, h]`. No `decide`, no `native_decide`/`bv_decide`/`ofReduce*`, no option bumps; the D14 grep leg scans the file (A1 verbatim: `check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 49 hand-written seam files + LemLibTest.lean)`). **Negative control (a)** (*reproduced*, `negctrl_a_theorem_vs_old_body.lake.log`, re-taken in `negctrl_b.log`): with `generated/CerbMem.lean` = the pre-fix body,
```
error: generated/CerbMemAllocatorProofs.lean:37:89: unsolved goals
error: generated/CerbMemAllocatorProofs.lean:56:4: unsolved goals
case isFalse.isTrue
h✝ : (st.lastAddress - sz) / align < 0
h :
  (if st.lastAddress - sz + (st.lastAddress - sz) % align ≤ 0 then …
error: generated/CerbMemAllocatorProofs.lean:65:44: unsolved goals
error: build failed
```
— the `q < 0` branch with `+ m` is exactly where the old body is unsound; the theorem is load-bearing, not vacuous. **Census (N6):** the by-name `#print axioms` legs do not list the theorems; every route to a non-standard axiom is covered by the other legs. **Verdict: general, true, kernel-only, on the real allocator; one belt-and-braces gap (N6); one prose caveat (N1).**

### 2.4 The runtime witness

`test/Unit/AllocatorSoundnessTest.lean`: `cases` = cursor 3/(4,4) → `outOfMemory 3`, 7/(8,8) → `outOfMemory 7`, 2/(4,4) → `outOfMemory 2`, 8/(4,4) → `active 0 4 4` — draft 44's four states with the post-fix outcomes (§2.1's table). Negative control: the four quoted pre-fix strings are byte-equal to `c1-prefix-negative-control.txt` (grep 4/4, `test:1 evidence:1` each) and are the values my own pristine arithmetic gives. **Would it fail against the old body?** *Reproduced* on the compiled pre-fix `CerbMem.allocator` through the same observer shape (`negctrl_b_witness_on_old_body.out.txt`):
```
FAIL cursor 3, request (4, 4): got Outcome.active 0 2 2, expected Outcome.outOfMemory 3
FAIL cursor 7, request (8, 8): got Outcome.active 0 6 6, expected Outcome.outOfMemory 7
PASS cursor 2, request (4, 4): got Outcome.outOfMemory 2, expected Outcome.outOfMemory 2
PASS cursor 8, request (4, 4): got Outcome.active 0 4 4, expected Outcome.active 0 4 4
```
(2 of 4 fail — the two defect states; the trailer's "3 expected" in my probe is my mis-typed prediction). Registered: `lakefile.toml:259-263` (`[[lean_exe]] name = "allocator-soundness-test" … root = "Unit.AllocatorSoundnessTest"`), `scripts/test_unit.sh:29` in `UNIT_TESTS`; `test_unit.sh` builds every exe through `"$SCRIPT_DIR/capped" lake build` (`:72`). Ran (*reproduced*, `lean_build.log` and A1): `allocator-soundness-test: OK (4/4 states; kernel theorem CerbMem.allocator_active_sound compiled)`, `exit=0`. **Verdict: as chartered; genuinely discriminating.**

### 2.5 The projection extension (C1b)

**Read:** `HEADER_POSITION = ^( *File "[^"\n]*"), lines? [0-9]+(?:-[0-9]+)?, characters [0-9]+-[0-9]+(:[^\n]*)$` (`re.M`), applied after `TIME_SPENT` and `FRAME_POSITION` in `project_diagnostics` (`:233-236`); group 1 (path) and group 2 (`: <text>` to end of line) are kept; `project_diagnostics(` has exactly two occurrences — its definition and the one `.stderr` call in `record_of` (`:244`) — so stdout is never projected. No Cerberus source emits a `File "…"`-shaped diagnostic (grep over `ocaml_frontend backend util frontend parsers` incl. generated: none; `Cerb_location` prints `file:line:col`); only OCaml's `Assert_failure`/`Match_failure` printer does. **Can it mask a genuine difference?** My 18 plants (`plants/header_projection_plants.out.txt`): header position only → `matching_failure`; header + frames → `matching_failure`; header PATH differs → `difference`; TEXT after the colon differs → `difference`; exception KIND differs (header vs `Failure(…)`) → `difference`; a header-shaped line in STDOUT differing in position → `difference` (stdout raw); a Cerberus diagnostic quoting `line N, characters A-B` → `difference`; header not at line start → `difference`; header whose TEXT contains a position → `difference`; header position only but stdout non-empty / statuses 125 vs 134 / status 0 → `difference`; status 1 → `matching_failure`; unicode/space path → `matching_failure` — `18 plants, 1 FAIL` where the one "FAIL" is my mis-expectation H13 (N8). The residual: H12 (N2). **The lane's 8 plants** (*reproduced*, `row10-plant.log`): all `PLANT OK`, `plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}` (50 `PLANT OK` lines + the withheld-row plant, derived). **Doctrine:** the ruling is quoted verbatim once (VALIDATION §3 `:473-474`); §0 `:142-144` and LADDER row 10 point to it; the class descriptions match the plants (a Cerberus diagnostic and a header-shaped stdout line named as compared raw). Provenance chain: M2. **Register:** `git diff 6d9ba82f1..f5b1578dc -- scripts/upstream_oracle_differences.json` empty; `schema 2 rows 3`, all `shared-model-fix` (`multi_tu_tray/{node,arr-2-2-return,arr-incomplete-ptr-return}`). **The "unobservable" claim:** refuted — M1. **Verdict: the extension implements what was proposed and hides nothing but positions; the classification it was introduced to accompany is wrong.**

### 2.6 Drift manifest, VALIDATION §3, tray

`sha256sum memory/concrete/impl_mem.ml memory/vip/impl_mem.ml` → `97a5da4c290f3000a3016b988ef50752ea10caaabc31fa2c86f707284324286b`, `4bc49e634bae47d38e1c1009c9c9679eb3a34c228baf6478770818e614944e90` = the manifest rows `:374`, `:376` exactly; `check_fork_drift.sh` (*reproduced*): `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)`. Header note `:1-14`: dated `2026-09-16 [AGENT]`, cites draft 44 and the [USER 2026-09-16] ruling, names both moved pins, states "single-row edits, not a wholesale --refresh". VALIDATION §3 entry `:436-465`: cites `CerbMem.allocator_active_sound` and `allocator_below_request_kills` by name, the witness by exe name, both files' fix lines correctly — and describes the deviation as UNOBSERVABLE (M1) with the pristine cite off by one (M3). Tray 44's LANDED line quotes `7b51b0b438052d47551009b9f65464d3030e9bf3` = `git rev-parse 7b51b0b43`. **Verdict: pins re-derive; gate green; header as chartered; the §3 entry's classification is the MAJOR finding.**

### 2.7 Sequential invariance — the gates at `f5b1578dc`, *reproduced*

`python3 scripts/release.py --mode fast` (`release-fast.log`; 17:49:50–17:56:55Z):
```
PASSED A1 (159.1s) … PASSED A2 (28.8s) … A3 (50.9s) … A4 (22.4s) … A4b (23.8s) … A4c (3.0s) … A5 (21.6s) … A6 (2.1s) … A6b (3.5s) … A7 (10.2s) … A8 (8.7s) … A9 (16.3s) … A10 (16.4s) … A11 (57.5s)
fast: passed; 14/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```
per-lane last lines: A2/A3/A4/A4b `BASELINE OK`, A4c `ALL AT COMMITTED EXPECTEDS`, A5 `ALL MATCH RECORDED BASELINE`, A6/A6b/A7/A8 `ALL PASSED`, A9 `SUMMARY: total=111 same=108 diff=3 ocaml_fail=0 lean_fail=0`, A10 `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)`, A11 `BASELINE OK (213 entries, exact match)`, A1 `Total: 11 passed, 0 failed` + every gate line green. Row 10 / `--plant` / `--corpus ci` (`row10_chain.log`; 17:58:41–18:02:55Z):
```
Independent oracle scope: tier-b; 855 rows in 114.8s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}; …/.tmp/audit/row10/report.json
Independent oracle scope: plant; 53 rows in 1.5s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/.tmp/audit/row10-plant/report.json
22/242 matching_incomplete: ci/0023-jump1.c (pristine 30.0s, fork 30.0s)
24/242 matching_incomplete: ci/0025-jump3.c (pristine 30.0s, fork 30.0s)
Independent oracle scope: ci; 242 rows in 137.2s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 134, 'matching_incomplete': 2, 'matching_failure': 106}; …/.tmp/audit/corpus-ci/report.json
```
All equal the orchestrator's lines in my brief (counts identical). **No pre-existing baseline row moved** (every baseline lane at its committed state; row 10's 28 `matching_failure` = WP-O's 28, the 3 rows = the register). **`immaculate/libc/g2-memcmp-uninit`** (`check_g2.out.txt`, my own tokenizer over the fresh captures):
```
lane status: matching_failure | reason: same failure under diagnostic projection; no semantic result
statuses: 125 125 | stdout sha equal: True | raw stderr sha equal: False | diagnostic sha equal: True
  HEADER  < File "memory/concrete/impl_mem.ml", line 2659, characters 16-22: Assertion failed
          > File "memory/concrete/impl_mem.ml", line 2664, characters 16-22: Assertion failed
differing line pairs by kind: {'header-position-only': 1, 'frame-position-only': 13, 'OTHER': 0, 'equal': 6}
VERDICT: header+frame positions ONLY
```
— `matching_failure` for the diagnosed reason (the assert header line shifted 2659 → 2664 by C1's +5 lines) and for no other. **Verdict: all four gates reproduce; nothing moved; the one re-classified case is exactly as diagnosed.**

### 2.8 Record integrity

`check_record_quotes.out.txt`: `fenced lines checked: 72; missing from evidence dir (+ the three source files): 3` (N3), `runner timing tokens in prose: 36; not found … 0`. Provenance: `[USER` ×12, `[AGENT` ×9; every worker decision is tagged [AGENT] with a reason (E7's amendment, the `allocatorStep` restatement, the C1.2 order, the S1 recommendation); [USER] only on quoted rulings. Charter §1 errata: E1–E10 all stated (`errata listed: ['1' … '10']`); E1–E3 are material and correct for C2 (verified by reading `mini_pipeline.lem:163`); E4–E6 are proof-engineering facts consistent with the proof; the "All §1 cites re-verified and CORRECT" sentence is wrong on `:1253` (M3). **CONSUMER RE-PIN NOTE — "C1 changes NO signature":** true — `git diff 6d9ba82f1 f5b1578dc -- lean_frontend/CerbMem.lean | grep -E '^[-+](def|structure|theorem|abbrev|instance|inductive) '` → none; the new module is additive; `MemState`, `initialMemState`, `initial_driver_state`, `drive` untouched; the one text change (the refusal message's cite) is stated. Open items honest and still open (2–7); M1 is, naturally, not among them. **Verdict: sound, with N3/N4/M3.**

## 3. Verified clean (checked and found correct; by my own reproduction unless marked "by reading")

- Remedy 1 verbatim in both OCaml models; the diff hunks are byte-identical modulo indent; nothing else in either file; both compile and install.
- Lean mirror: same check order, same failure text at four sites, kill-state unchanged, cites resolve; 40/42 states identical to the fixed arithmetic, the 2 differing states the documented `align = 0` refusal.
- Theorem: general, no hypothesis, true (incl. `align < 0`, `sz < 0`), kernel-only cones, on the real allocator, `Address` definitional; fails against the pre-fix body (3 unsolved goals).
- Witness: draft 44's states and post-fix outcomes; negative control byte-equal to the evidence; 2/4 fail on the old body; registered in `lakefile.toml` and `test_unit.sh`; built under the cap; OK 4/4.
- Projection: 18 auditor plants + 8 lane plants; stdout never projected; text/path/kind differences all `difference`.
- Drift pins re-derive; `check_fork_drift` OK; header dated and cited; tray LANDED hash correct; register unchanged (3 rows).
- Gates: `fast: passed; 14/14`, `Source unchanged: True`; row 10 `{822, 28, 3, 2}`; `--plant` `{1, 1, 51}`; `ci` `{134, 2, 106}`; `g2-memcmp-uninit` header + frames only.
- Fence (by reading `git diff --stat`): only chartered files (+ the C1b extension's three files under the [USER 2026-09-17] ruling); no `.lem`, no baseline, no register row, `CERBERUS_REV`/`LEM_REV` untouched; `handwritten_copy.manifest` and `lakefile.toml` roots extended as the house rules require (`check_lakefile_roots: OK (218 roots …)`).
- "Nothing new out of policy" ([USER 2026-09-08]): one GENERAL theorem, a runtime exit-code test — no enumeration proof, no new artefact class (by reading).
- Zero-discrepancy on the new behaviour: Lean = fork on every one of my eleven programs (the witness, its controls, the truncation probe).

## 4. What I did not check

- The FULL Tier A+B gate at the head: the worker's `release_full rc=0 … 37/37` at `f9843725d` is a claim I did not reproduce (B1, B4–B9, B11, B12 not re-run; `f5b1578dc` on top is docs/evidence-only). I ran Tier A (14/14) and the row-10 family at the head.
- The full `--with-lean` three-engine report (the worker's `{813, 28, 12, 2}`); I ran the Lean engine on my own programs only.
- `--corpus csmith`, `--corpus libxml2_chvalid` (row 12).
- The VIP model END TO END: no lane links or executes `mem_vip` (the driver links `mem_concrete`); its fix is verified by compilation, textual identity with the concrete hunk, and the shared arithmetic only.
- The root cause of N5 (the `(size_t)` cast-then-add truncation) — recorded, not diagnosed.
- A rebase: the mainline has not moved (`4a23d98aa` is an ancestor; 6 commits ahead).
- The consumer repo (`cerberus-sl`, read-only): the re-pin note's claims about its files were taken from the charter, not re-counted.

## 5. Provenance

[AGENT auditor] throughout; no [USER] ruling is created or revised here. Quotations marked `[USER 2026-09-16]`/`[USER 2026-09-17]` are copied from the charter/record/brief. All measurements 2026-09-17 17:15–18:06 UTC on the audit worktree at `f5b1578dc`, box load 0.2–2.3 (no other agent's heavy work observed). Scratch under `.tmp/audit/` and `lean_frontend/.tmp/` (git-ignored) may be deleted; everything cited is in the evidence directory beside this report. Nothing was pushed, merged or committed on any mainline; the audited branch, the primary checkout and the consumer repo were not touched; the only tree writes are this report and its evidence directory, committed once on `audit/allocator-part-one`.
