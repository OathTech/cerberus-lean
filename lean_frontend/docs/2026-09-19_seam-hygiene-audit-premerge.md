# Pre-merge audit — `arc/seam-hygiene` (seam hygiene: opaque failures, explicit switch arms, a named OOM kill; 2026-09-19)

**Range:** `0457732e1..34b8e15a8` — six commits (`0eafc94a4` charter; `db640b214` interim STOP record; `fce1de9f8` H1; `ee1eaf94d` H2; `dde3b766b` H3; `34b8e15a8` record + evidence). Base = mainline `mdd/cerberus-lean` `0457732e1` (the primary checkout is parked there; no rebase needed at the time of writing).
**Head audited:** `34b8e15a8`, checked out as branch `audit/seam-hygiene` in `worktrees/cerberus-lean-audit/seam-hygiene`.
**Who:** an INDEPENDENT pre-merge auditor (Claude, Fable 5.1) — [AGENT auditor] throughout. I wrote none of the range. Every claim marked *reproduced* is my own run in this worktree at `34b8e15a8` after a full rebuild of BOTH engines (§2.0); quoted outputs are verbatim; tallies are labelled derived. The standing rulings the range implements — charter §0: [USER 2026-09-18] *"Great, charter the planned slice"*, [USER 2026-09-17] *"Makes sense, Let's do the sequence as you propose. We should do this soon but it's not a blocker"*, [USER 2026-09-08] *"we should \*NOT\* be building anything new out-of-policy"*, and the three FENCE EXTENSIONS the orchestrator granted 2026-09-19 ([AGENT orchestrator]; record §0) — are not questioned here; whether the code implements EXACTLY them, with NO behaviour change, is.
**Evidence:** [`2026-09-19_seam-hygiene-audit-evidence/`](2026-09-19_seam-hygiene-audit-evidence/) (README there: my rebuild log, the hunk classifier + its output, three Lean probes + outputs, the codec plants, the register column diff and seal plants, the census plants, the switch-refusal transcripts, the immaculate crash-row extraction, the record-quote check, the FULL battery's summary/lane list/tails, the `--with-lean` report). Scratch under the git-ignored `.tmp/audit/`.

**What I ran (all at `34b8e15a8`; one heavy job at a time; box load 1.2–54 during the session — other agents' builds; recorded per step in the evidence).** Read in the prescribed order: charter (§0 rulings verbatim, §1 facts, §2 deliverables, §3 fence/stops), record + evidence dir, container `CLAUDE.md`, `lean_frontend/CLAUDE.md`, the arc-14 effect-erasure note, `scripts/check_failure_reach.{sh,py}`, the consumer's request items 3–5, 7 and 9 (read-only), then the full diff of the three code commits (1 305 + 366 + 372 diff lines) and the docs commits. **Rebuilt before any before/after claim** (§2.0): the primed worktree was STALE on both sides — `tools/check_lem_sync.sh --check` → `CERB_LEM_SYNC_STALE` (OCaml generated tree), `tools/check_driver_fresh.sh --check-lean` → `CERB_DRIVER_STALE` (11 hand-written seams not propagated), `--check-oracle` → `CERB_DRIVER_STALE` — so I ran `make clean-prelude-src prelude-src`, `build_cerberus`, `make lean-prelude-src`, `build_lean` (stamps: oracle `bin bbc73bd9…` / `src 2b8b5768…`; lean `bin a4c5fef9…` / `src 795a0367…` — the lean stamp equals the worker's FULL-run B4 line, `release-full-tails.txt`). Reproduced: `python3 scripts/release.py --mode full` (Tier A + B, 39 lanes) CLEAN at the head; `scripts/check_failure_reach.sh` (+ census kept for my plants); `python3 scripts/test_observations.py`; `--with-lean` three-engine report; three auditor Lean probes through `scripts/lean_probe.sh` (never uncapped); a mechanical hunk classifier over every seam-file hunk of the three code commits; a column-by-column register diff with seal recomputation; 17 codec plant cases × 3 policies against BOTH the base and the head codec; 5 register-seal plants; 3 census plants on a scratch root; the CLI switch refusal on both engines; the immaculate lane's 11 `MATCH | L=CRASH` rows re-read from the FULL run's raw captures.

## 0. Verdict

**MERGE-WITH-FIXES.** No MAJOR finding. The slice's core claim — NO behaviour change — holds by mechanical classification of every seam-file hunk (§2.1: 109 failure-leaf swaps, all `panic! m` → `failwithI m` with byte-identical text or a `<Module>.<fn>: ` prefix; 7 guard wrappings whose default arms reappear byte-identical; the `oomKill` naming, the identity stubs and the structural `BEq`), by the register's 98 rows changing in the `token` (+14 derived `msg` key) and `seal` columns ONLY, by 1 156 ordered-pair agreement of the structural `BEq MemValue` with the retired impl, and by the FULL battery at the head: **`full: passed; 39/39 selected commands completed successfully. Source unchanged: True.` — 39/39 PASSED, 0 FAILED, no baseline row moved; row 10 `{822, 28, 7, 2}`, `--plant` `plant_ok: 51`, `--with-lean` Lean column `{817, 28, 12, 2}` identical to the part-two record (§2.7)**. The kernel claim holds and is NOT vacuous (§2.2: the orchestrator's two `rfl` probes fail at the head; the test's `#guard_msgs` pattern goes RED on the pre-H1 `combineProv` text; `failwithI` prints as `opaque`; I stated the reduction of five arms to their defaults as `rfl` lemmas myself). The codec fix is exactly the origin-set move (§2.3: 0 `batch` rows differ base vs head over 17 cases; FUEL wins over origin; forged origins fall to the fail-closed class). Four MINOR findings, all record/doc integrity or a latent shape with a one-line fix, none needing a re-gate beyond `test_unit.sh` + `--mode fast` if M4 is taken: **M1** a "verbatim" gate line in the record that matches no evidence file (`375 files` — the evidence says `377`); **M2** three rows of the evidence per-site table name a self-locating prefix the code does not carry; **M3** `VALIDATION.md:1027-1030` still lists the deleted `CerbMem.beqMemValueSafe` as a boundary row with a live VF-3 obligation (the sibling "15 registered rows" text IS in the record's open items; this one is not); **M4** `CerbSwitch`'s derived `Inhabited` default MOVED (`.strict_reads` → `.pointer_arith .PERMISSIVE`) because the new constructor was placed first — kernel-visible, unclaimed, no consumer in the tree. Ten NOTEs. Recommended before merge: M1–M3 as a record/docs amendment commit (docs-only; no re-gate needed beyond a `test_unit.sh` sanity run); M4 either fixed (append the four constructors after the existing ones; `test_unit.sh` + `--mode fast`) or explicitly accepted in the record.

## 1. Findings

Grades: MAJOR = a trust gap, a hidden real difference, or a ruling not implemented; MINOR = a fail-open shape, an overclaim/misquote in a normative document or record, a mirror deviation, or an unclaimed definitional change, each with a small fix; NOTE = precision, process, or a residual the merge need not wait for. Severities are [AGENT auditor] judgments.

### M1 — MINOR — record §2.6 quotes a gate line "verbatim" that appears in no evidence file (375 vs 377 files)

**Where:** `lean_frontend/docs/2026-09-18_seam-hygiene-record.md:199` — `check_theorem_axioms: C2 ratchet OK (375 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; …)` presented under "Gates at the H1 commit (verbatim …)".
**Reproduction:** `08-check_record_quotes.out.txt` — of 168 quoted lines, this one is not a substring of any evidence file. The H1 evidence has `check_theorem_axioms: C2 ratchet OK (377 files scanned recursively: … the 38 pinned …` (`test_unit_h1_verdicts.txt:488`); the BEFORE evidence has `374 files` (`check_theorem_axioms_before.txt:3`); no evidence file contains `375 files`. The pin count (38) and the rest of the line agree; the file count itself is environment-sensitive (374 before, 377 in the worker's H1/H3 evidence, 378 in my FULL run's A1 — the scanner walks scratch `.lean` files too), so the NUMBER is immaterial and the RULE is the point.
**Why it matters:** the house rule is "quoted outputs are verbatim" (container `CLAUDE.md`, Record integrity); a hand-edited number in a verbatim block is exactly what the rule forbids, even when immaterial.
**Fix:** amend the record line to the evidence's text (`377 files`), or mark it as derived/paraphrased.

### M2 — MINOR — the evidence per-site table names a prefix the code does not carry on 3 rows

**Where:** `…seam-hygiene-evidence/h1-site-table.md` rows `CerbMem.lean | 828`, `| 837` (`REPLACE + prefix `CerbMem.memValueToBytes_append:``) and `| 1190` (`REPLACE + prefix `CerbMem.reconstructValue_indexed:``).
**Reproduction** (`01-classify_hunks.out.txt` + my table check, quoted in §2.8): at `fce1de9f8:lean_frontend/CerbMem.lean:828/837` the lines read `failwithI "CerbMem.memValueToBytes: the concrete memory model requires …"` and `:1190` reads `failwithI s!"CerbMem.reconstructValue: unknown function pointer: {ptrAddr}"` — the SAME prefix as the paired worker, exactly as the record §2.1 explains (the `rfl` pair-equality theorems force identical leaf messages; E8). The table was evidently written before that constraint was discovered and not re-derived. The other 107 rows carry the claimed token/prefix.
**Fix:** correct the three rows (or regenerate the table from the tree); the record text needs no change.

### M3 — MINOR — `VALIDATION.md` still lists the deleted `CerbMem.beqMemValueSafe` as an enumerated runtime-boundary row with a live obligation

**Where:** `lean_frontend/VALIDATION.md:1027-1030`: *"`CerbMem.beqMemValueSafe`, implemented by the unsafe `beqMemValueImpl` — the opaque equality used by `BEq MemValue`; the native implementation is pinned, but its agreement with the logical declaration is not proved. The supported profile's VF-3 retains this correspondence obligation"* — in the list introduced as the seams "enumerated and machine-pinned (`scripts/unsafebaseio_allowlist.txt`, gate-enforced both directions)". After H3 (`dde3b766b`) there is no such opaque, no such allowlist row, and the obligation is discharged structurally (`beqMemValue` is kernel-transparent; §2.5). Related stale text the record DOES list as open: `:722` "15 registered rows since 2026-09-05" (now 12). `lean_frontend/TODO.md:232` also still carries the `beqMemValueSafe` correspondence residual (F7).
**Why it matters:** VALIDATION is the trust story; a normative list that names a boundary row the gate no longer pins is an overclaim in the wrong direction (it claims an obligation that no longer exists — harmless to soundness, but the 2026-09-06 document review (D2) added this bullet precisely to make the list exhaustive and exact).
**Fix:** one docs commit: strike/move the bullet to history (pointing at `docs/2026-09-18_seam-hygiene-record.md` §5.3), fix `:722` to 12, retire the TODO residual. Outside the charter's fence (only §3 was fenced), so an operator call — the record should list it as an open item at minimum.

### M4 — MINOR — `CerbSwitch`'s derived `Inhabited` default moved because the new constructor was placed first (kernel-visible, unclaimed, no consumer found)

**Where:** `lean_frontend/CerbGlobal.lean` (fence extension 2): `inductive CerbSwitch where | pointer_arith (mode : PointerArithMode) | strict_reads | …  deriving BEq, Inhabited, Repr`. Lean's derived `Inhabited` picks the FIRST constructor: at the base `default = .strict_reads`; at the head `default = .pointer_arith .PERMISSIVE`.
**Reproduction** (`02-AuditProbeDefault.out.txt`, *reproduced*): `example : (default : CerbGlobal.CerbSwitch) = .pointer_arith .PERMISSIVE := rfl` elaborates; `example : (default : CerbGlobal.CerbSwitch) = .strict_reads := rfl` → `error: Type mismatch … default = CerbGlobal.CerbSwitch.strict_reads`.
**Consumers:** none found — every `CerbSwitch` occurrence outside `CerbGlobal.lean` in the hand-written seams and the 219 generated modules is a `CerbGlobal.has_switch CerbGlobal.CerbSwitch.<ctor>` call (`Core_run.lean:424`, `Formatted.lean:494`, `Mini_pipeline.lean:111`, `Translation.lean:716`; `Global.lean:61` abbreviates the type); no `default`, `get!`, `head!` or `failwithI` at that type; `global.lem:60-100` only declares the type and `has_switch`. So no runtime or lane behaviour changes and no committed theorem mentions it.
**Why it matters:** the slice's claim is "no behaviour change; the default arms byte-identical"; this is a definitional value the kernel can see that changed without being stated, and a constructor-order-dependent derived instance is a latent hazard the record's E-list should have caught (the record §4.1 says "the new constructors break nothing" — true for every USE in the tree, not for the derived instance).
**Fix (either):** append the four new constructors AFTER the existing ones (restores `default = .strict_reads`; `Repr` order irrelevant; re-run `test_unit.sh` and `--mode fast`), or keep the order and record the moved default in the record/consumer note as deliberate. Adding `example : (default : CerbGlobal.CerbSwitch) = .strict_reads := rfl` to `OpaqueFailureTest.lean` would pin it either way.

### N1 — NOTE — `oomKill`'s new docstring cites impl_mem.ml lines that are −3 off in this tree

`CerbMem.lean:2094-2101` (the H3 docstring): *"impl_mem.ml:1255-1256 and :1260-1261"*; this tree: `grep -n 'Concrete.allocator: failed' memory/concrete/impl_mem.ml` → `1259:` and `1264:` (the `if z < zero` at :1258, `if z' <= zero` at :1263). The allocator's pre-existing per-line comments (`-- :1252`, `-- :1255-1256 (draft 44 fix)`, `-- :1260-1261`) carry the same offset (the fork's draft-44 comment at :1256-1257 shifted them) and were outside the fence; the record's E5 corrected the eight arms' cites but not these. Mirror-OCaml cite precision; one-line fix.

### N2 — NOTE — the `intfromptr` guard comment inverts the implication

`CerbMem.lean:2773-2776` and record §4.2: *"Guarded by the coarser `is_PNVI ()` … it implies both"*. The OCaml test is `has_switch (SW_PNVI AE) || has_switch (SW_PNVI AE_UDI)` (`:2454`); `is_PNVI () = List.exists (function SW_PNVI _ → true …)` (`switches.ml:156-157`) is IMPLIED BY that test, not the other way (it is also true under `SW_PNVI PLAIN`, where the OCaml takes the default arm). The guard therefore fires on a SUPERSET of the OCaml's condition — the fail-closed direction, unobservable under the refused set, and the right choice — but the sentence should read "is implied by both / over-approximates".

### N3 — NOTE — `doLoad`'s header comment now contradicts the arm two lines below it

`CerbMem.lean:2391-2393`: *"the PNVI `expose_allocations` arm :1562-1566 and SW_strict_reads :1593-1598 are switch-conditioned, refused set — Z-24"* — pre-shift line numbers (this tree :1570 and :1601-1606) and "refused set" as if not ported, immediately above H2's explicit `else if CerbGlobal.has_switch .strict_reads then …` guard (`:2411`). The record §4.2 says the older `:NNNN` comments were left as they predate the +8 shift; this one also states the pre-H2 SHAPE. Two-line comment fix.

### N4 — NOTE — record §2.2's FAIL transcript has no evidence file (disclosed)

`record.md:129-133` quotes the register gate's first RED run (the mis-keyed `maxIval`/`minIval` rows); the record says *"verbatim, from the worker's terminal — that log was overwritten by the re-run"*. Honest, but a verbatim block with no file behind it; my quote check lists exactly these five lines as MISSING (`08-check_record_quotes.out.txt`). No fix possible; recorded so the reader knows those five lines rest on the worker's transcription.

### N5 — NOTE — the KEPT origin in `IMMACULATE_PANICS` is inferred, not witnessed

`scripts/observations.py:78-80`: `b'_private.CerberusImpl.0.CerberusImpl.typeof_enum_impl'` — the mangled name of a `private unsafe def` inside `namespace CerberusImpl` (`CerberusImpl.lean:62-69`), by analogy with the retired `_private.CerbDecode.0.…` entry that WAS lane-witnessed. No corpus program reaches the unregistered-enum panic, so the string is never exercised; the codec plant (`test_observations.py`) uses the same fabricated line. Fail-closed if wrong (an unknown origin reads `unreviewed panic origin`), so acceptable; recorded for awareness.

### N6 — NOTE — the oracle CLI ACCEPTS `--switches=strict_reads`; the Z-24 refusal is the Lean driver's, and no lane passes switches to the oracle

*Reproduced* (`04-switch_refusal_oracle_vs_lean.out.txt`, `04-switch_refusal_lean.out.txt`): fork oracle `--switches=strict_reads` on a trivial program → `Defined {value: "Specified(0)", …}` rc 0 (the same as without); `cerberus-lean --batch --switches=strict_reads /dev/null` → `cerberus-lean: refused — --switches=strict_reads: semantics switches (PVI/PNVI/strict_pointer_arith/CHERI/…) are not supported by this port — matched (default-switch) mode is the harness contract and CerbGlobal's switch set is permanently empty …` rc 2 (likewise `--switches strict_reads` and `--switches=PNVI`); `grep -rn switches scripts/*.sh scripts/*.py` → no lane passes any. VALIDATION §3 (c) states exactly this contract ("REFUSED (`Main.refuseFlag`, exit 2, attributed) … Matched default-switch mode is the harness contract"); my brief's "refused on both engines" is not the contract and the record does not claim it. The observability argument for the eight arms is therefore: the Lean engine cannot be given a switch, and the harness never gives the oracle one.

### N7 — NOTE — the SET branches are refusals of the whole operation, not ports of the OCaml arm

E.g. `loadM`'s set branch kills on EVERY load when `SW_strict_reads` is set, where the OCaml (`:1601-1606`) fails only on `MVunspecified` and otherwise returns; `eqPtrval`'s set branch kills where the OCaml returns `Z.equal addr1 addr2`. This is the charter's chosen shape (§2 H2: "`<loud kill: … is not ported …>`", the `zap_dead_pointers` precedent) and is unreachable under the refused set; a consumer must read `has_switch … = false` as the ONLY configuration these definitions model, not as "the switch is supported". The docstring at `CerbMem.lean:2305-2325` says this correctly.

### N8 — NOTE — codec: a trailing space after the origin is absorbed by the free-form location field

`LEAN_PANIC = rb'PANIC at ([^ \r\n]+) [^\r\n]+:[0-9]+:[0-9]+: (.+)'`: my plant `PANIC at _private.LemLib.0.failwithIImpl  LemLib:168:2: <msg>` (two spaces) is ACCEPTED under immaculate/litmus at the head (`03-codec_plants.out.txt`) because the origin group is still exactly the accepted constant and the second space belongs to the location field. Not fail-open in substance (the origin is exact); pre-existing regex shape; newline/CR inside the origin fall to `fatal engine diagnostic` (fail-closed) on both codecs.

### N9 — NOTE — the register seal protects the eight class columns, not the justification text

`06-seal_plants.out.txt`: editing `reach`, `token` or `msg` without `--reseal` → `SEAL MISMATCH` (plus `NEW`/`STALE` for key moves) rc 1; editing `need` → `OK` rc 0. By design (`check_failure_reach.py:SEALED`, the file header); pre-existing; stated so no one reads "every row sealed" as covering the invariant prose.

### N10 — NOTE — process: the primed audit worktree was stale on both sides (as the worker's was, E9)

`00-rebuild.log`: `CERB_LEM_SYNC_STALE` (OCaml generated tree), `CERB_DRIVER_STALE` ×2. Rebuilt before any claim; both freshness checks `OK` afterwards. `scripts/new-worktree.sh`'s priming copies `_build`/`generated/` from the primary checkout, which had itself moved past its binaries — a second occurrence of the same shape; worth a look at the priming recipe (outside this slice).

## 2. The scope items — what I did, verbatim outputs, verdict

### 2.0 Rebuild (precondition)

`00-rebuild.log`, verbatim key lines:
```
== 2026-09-19T04:44:33Z HEAD=34b8e15a8 load=18.29 6.00 2.78
== [1] tools/check_lem_sync.sh --check (OCaml generated tree vs .lem)
CERB_LEM_SYNC_STALE: frontend .lem sources changed since generation (stamp src 0ea744e44bd25235b4db5b42660406f178879ca5194c707640feb4f814e3793c, tree 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d) — generated/ is STALE
rc=1
== [1b] make clean-prelude-src prelude-src (regenerate the OCaml tree)
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
rc=0
== [2] build_cerberus 04:45:17
check_driver_fresh: recorded oracle stamp (bin bbc73bd92c78627417a9b77b42bd5f761c9c5a0a91927757d07ad09f3838d253, src 2b8b576816681316ce0c0b690dc78a63f813ac8a7391f976bdf4684a18f47634)
rc=0
== [3] make lean-prelude-src 04:45:35
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
rc=0
== [4] build_lean 04:46:16
check_driver_fresh: recorded lean stamp (bin a4c5fef9c6684cd6623acf0d8839e498f5d14e9fb720254642170fc717b908ff, src 795a03670377b004e9f10c9e6bc8e6861fec9e32988e2648504f69c219363e81)
rc=0
== [5] freshness 04:50:25
check_driver_fresh: lean OK (bin a4c5fef9c6684cd6623acf0d8839e498f5d14e9fb720254642170fc717b908ff, src 795a03670377b004e9f10c9e6bc8e6861fec9e32988e2648504f69c219363e81)
rc=0
check_driver_fresh: oracle OK (bin bbc73bd92c78627417a9b77b42bd5f761c9c5a0a91927757d07ad09f3838d253, src 2b8b576816681316ce0c0b690dc78a63f813ac8a7391f976bdf4684a18f47634)
rc=0
== DONE 2026-09-19T04:50:25Z
```
Verdict: both engines correspond to `34b8e15a8` for every run below.

### 2.1 No behaviour change, by diff (item 1)

**Method** (`01-classify_hunks.py`): every hunk of `fce1de9f8`, `ee1eaf94d`, `dde3b766b` in a seam file (`CerbMem|CerbFS|CerbDecode|CerbUtils|CerberusImpl|CerbLocation|CerbFloat|CoreParser|Main|CerbGlobal|CerbMemAllocatorProofs`) is classified mechanically: (a) removed/added lines pair 1:1 and each pair is `panic!` → `failwithI` at the same column with the remainder byte-identical, or with a `<Module>.<fn>: ` prefix inserted immediately after the opening `"`/`s!"`; (a′) `Main.lean`'s `panic! e` → `failwithI s!"Main.loadCoreImpl: {e}"`; (imp) a bare `import LemLib`; (b) every removed CODE line reappears among the added lines modulo an `else ` prefix / indentation / trailing `--` comment, and every other added code line is a comment, a `has_switch`/`is_PNVI` guard, a `kill`/`NDkilled` line or `else`; (b′) pure insertion of exactly those; (c) the OOM literal ↔ `oomKill`; (d) CerbUtils identities; (e) the `BEq` block; (doc) prose-only; (f) anything else. Verbatim summary lines:
```
== fce1de9f8: seam-file hunks by class: {'a': 67, 'imp': 4}
== ee1eaf94d: seam-file hunks by class: {'g:CerbGlobal(fence ext 2)': 3, "b'": 3, 'f': 3, 'b': 4, 'doc': 1}
== dde3b766b: seam-file hunks by class: {'e': 1, 'c': 3, 'd': 1}
    {'a:same-text': 90, 'TOTAL': 109, 'a:prefixed': 18, "a':var-wrapped": 1}
```
The three `ee1eaf94d` hunks the classifier left as `f` I read by hand and all three are prose: `-2297,20 +2305,33` (the Z2-M-20 docstring rewrite), `-2550,26 +2584,35` (the gt/le/ge guards — all three `memReturn (a1 ⋚ a2)` lines reappear as `else memReturn …` — plus two docstring lines of `diff_ptrval`'s `/-- … -/` that contain the unquoted phrase "is not ported"), `-2728,8 +2783,9` (the `eff_array_shift_ptrval` docstring). **(f) count after reading: 0.** Derived tallies: 109 leaf swaps = 98 register rows + 11 out-of-closure (matches the record); 19 self-locating prefixes (18 + `Main`'s wrapped variable) = the record's 19; the prefixed sites are exactly `targetPtrSize`, `sizeofCtype` ×2, `alignofCtype` ×2, `intToBytes`, `memValueToBytes` ×4, `reconstructValue` ×2, `casePtrval`, `maxIval`, `minIval`, `concurReadIval`, `arrayShiftPtrval`, `CerbLocation.simpleLocation`, `Main.loadCoreImpl`. The `g` class (CerbGlobal, fence extension 2) is the four constructors, the `PointerArithMode` inductive, `has_strict_pointer_arith`'s body (`false` → `has_switch (.pointer_arith .STRICT)`, still `= false` by `rfl`) and eight `rfl` lemmas — see M4 for the one definitional side-effect.

**Remaining `panic!` in hand-written seams at the head** (`grep -n 'panic!' lean_frontend/*.lean`, code lines only): `CerberusImpl.lean:69` (`pure (panic! "Ocaml_implementation.typeof_enum: tag was not registered …")` inside the `private unsafe def typeof_enum_impl` — the KEPT enum seam) and `CerbTags.lean:34` (`tagDefsUnreachable`, the reader-lifting tripwire); every other hit is a comment or `Main.lean:1217`'s refusal TEXT. Neither is a register row (the register has 0 `panic!` tokens, §2.6). **Verdict: the claim holds.**

### 2.2 The kernel claim (item 2)

`02-AuditProbeA.out.txt` (*reproduced*, `scripts/lean_probe.sh`, fresh build) — the orchestrator's two probes FAIL at the head, and only they:
```
../.tmp/audit/probes/AuditProbeA.lean:12:79: error: Tactic `rfl` failed: The left-hand side
  CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
is not definitionally equal to the right-hand side
  CerbMem.Provenance.Prov_none
…
../.tmp/audit/probes/AuditProbeA.lean:13:51: error: Tactic `rfl` failed: The left-hand side
  CerbMem.bytesToInt [] false
is not definitionally equal to the right-hand side
  none
opaque failwithI : {α : Type} → [Inhabited α] → String → α
'failwithI' does not depend on any axioms
```
(`#print failwithI` prints the `opaque` keyword — the text-independent fact the test checks via `.opaqueInfo`; `LemLib.lean:176-177` `@[implemented_by failwithIImpl, never_extract] opaque failwithI … := default`.) **Non-vacuity of `#guard_msgs`-on-failing-`rfl`** (`02-AuditProbeVacuity.out.txt`): the pre-H1 text of `CerbMem.combineProv` (`0457732e1:CerbMem.lean:268-282`, byte-identical body, `panic!` leaves) copied as `combineProvOld`, the test's guard block pointed at it → RED:
```
../.tmp/audit/probes/AuditProbeVacuity.lean:36:0: error: ❌️ Docstring on `#guard_msgs` does not match generated message:

- error: Tactic `rfl` failed: The left-hand side
-   AuditVacuity.combineProvOld (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
- is not definitionally equal to the right-hand side
-   CerbMem.Provenance.Prov_none
 
- ⊢ AuditVacuity.combineProvOld (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none = CerbMem.Provenance.Prov_none
```
(all `-` lines: NO message was generated because `rfl` SUCCEEDED on the transparent leaf — the loud direction), while the committed test's own block on the head `CerbMem.combineProv` in the same file is GREEN, and `example : combineProvOld (.Prov_symbolic 0) .Prov_none = .Prov_none := rfl` elaborates — the pre-H1 defect, shown. **The eight arms reduce to their defaults** — the test's ten `has_switch … = false := rfl` examples and its `gtPtrval` example build in A1; my OWN statements (same probe, all elaborated without error): `eqPtrval loc (PV Prov_none (PVconcrete none a1)) (PV Prov_none (PVconcrete none a2)) = memReturn (a1 == a2) := rfl`; the same for `Prov_device`/`Prov_device`; `lePtrval … = memReturn (decide (a1 ≤ a2)) := rfl`; `ltPtrval … = memReturn (decide (a1 < a2)) := rfl`; `intfromptr loc ty ity (PV prov (PVconcrete none addr)) = (match minIval ity with | .IV _ mn => match maxIval ity with | .IV _ mx => if addr < mn || mx < addr then memFail MerrIntFromPtr loc else memReturn (.IV prov addr)) := rfl` (the `is_PNVI` guard vanishes definitionally); and the guard shapes abstractly via the named lemmas (`rw [CerbGlobal.has_switch_pointer_arith_permissive_eq]; rfl`, `rw [CerbGlobal.has_switch_zero_initialised_eq, Bool.and_false]; rfl`). **Verdict: holds; the test is not vacuous.**

### 2.3 The codec fix (item 3, fence extension 1)

By reading (`scripts/observations.py:68-80, 210-221`): the only accept-set changes are `LEMLIB_FAILWITHI_ORIGIN = b'_private.LemLib.0.failwithIImpl'` (replacing the never-printed `b'LemLib.failwithIImpl'`) and `IMMACULATE_PANICS = {b'_private.CerberusImpl.0.CerberusImpl.typeof_enum_impl'}` (was eight seam site names); `failure_message` is reached only under `litmus`/`immaculate` (`parse():296`), so `batch` cannot change. *Reproduced* `python3 scripts/test_observations.py` → `Ran 24 tests … OK`. **My plants** (`03-codec_plants.py/.out.txt`: 17 cases × 3 policies, BASE `0457732e1` codec vs HEAD, loaded side by side):
```
batch-policy rows that differ base vs head: 0
```
and, under `immaculate`/`litmus`, the differences are exactly: the mangled origin ACCEPTED (was rejected), the old literal REJECTED (was accepted), the stale seam origins `CerbMem.casePtrval`/`CerbFloat.truncToInt` REJECTED under immaculate (were accepted), the KEPT `typeof_enum_impl` origin ACCEPTED under immaculate only, and a "stdout beside" case that now rejects with `unexpected stdout beside internal failure` instead of `unreviewed panic origin` (both fail-closed). Unknown origins and the `CerbTags` tripwire origin: rejected under every failure policy on both codecs. **FUEL interplay:** mangled or stale origin + `lem: fuel exhausted` → `fuel exhausted; exploration incomplete` under all three policies on both codecs (`FUEL_RECORD` at `parse():293` precedes `failure_message`). **Forged origins:** newline or CR inside the origin → `fatal engine diagnostic; no completed observation` (fail-closed); prefix-extended (`…failwithIImplX`) and embedded-space origins → `unreviewed panic origin`; a trailing space → accepted (N8). **The immaculate lane's crash rows** (`03-immaculate_crash_rows.out.txt`, from the FULL run's B5 raw captures `.lerr`/`.l.status`/`.l.tokens`): all nine former seam-`panic!` rows have status 134, token `INTERNAL_ERROR`, origin `_private.LemLib.0.failwithIImpl`, and a message that is a base `panic!` literal verbatim (`f3-raw-high-byte-*` ×3 and `g5-decode-multichar`: `decode_character_constant: invalid char constant ==> …`; `g4-bswap64-overflow`; `offsetof-union-member`: `CerbMem.sizeofCtype: Union tag not a UnionDef …`; `zd-z2fl03-nan-to-int`) or the base literal as the suffix of a self-locating prefix (`zd-z2m02-device-funptr-call`: `CerbMem.casePtrval: case_ptrval`) or the unchanged `refusal` helper's rendering (`zd-z2f04-closedir`: the helper and its argument strings are untouched in the range); the two other `MATCH | L=CRASH` rows (`g2-memcmp-uninit`, `zd-z2m01-aligned-alloc-zero-zero`) are typed `MODEL_FAILURE` kills, status 1, no panic head — as the record says. B5: `PASSED` at the head with the committed baseline (§2.7). **Verdict: exactly the origin-set move; `batch` unchanged; the head moved, the message did not.**

### 2.4 The eight arms (item 4)

Each guard checked against THIS tree's `memory/concrete/impl_mem.ml` (printed with line numbers, §evidence) and the Lean at the head:

| Lean def (HEAD line) | OCaml test, this tree | guard placement / default | kill text cites |
|---|---|---|---|
| `eqPtrval` :2567 | `:1860 if Switches.(has_switch SW_strict_pointer_equality)` inside the `(PVconcrete, PVconcrete)` arm | inside the concrete/concrete arm after the pure `sameProv` let; default `if sameProv then memReturn (addr1 == addr2) else msum …` byte-identical | `:1860-1861` ✓ |
| `lt/gt/le/gePtrval` :2606/:2618/:2629/:2640 | `:1897/:1915/:1930/:1947` inside the concrete/concrete arm | inside that arm; `else memReturn (a1 < a2)` etc. byte-identical | `:1897-1903/:1915-1921/:1930-1938/:1947-1955` ✓ (ranges include the `else` line) |
| `diffPtrval` :2649 | `:1978 if … (SW_pointer_arith `PERMISSIVE)` wrapping the whole match | wraps the whole match after the `errorPostcond` let; default match byte-identical | `:1978-1983` ✓ |
| `effArrayShiftPtrval` :2827 | `:2345-2346` (Prov_some), `:2357-2358` (Prov_none), device `:2362-2364` unguarded | concrete arm: `(prov ≠ Prov_device) && (STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE))`; default `memReturn (.PV prov (.PVconcrete none (addr + offset)))` byte-identical (the Prov_symbolic arm kills before) | `:2345-2354, 2357-2360` ✓ |
| `allocateObject` :2191 | `:1318 if Switches.(has_switch SW_zero_initialised)` inside `match init_opt with None ->` (`:1312-1331`); the `Some` branch (`:1332-`) has no test | `initOpt.isNone && has_switch .zero_initialised` hoisted before the unchanged body — equivalent since the OCaml tests only in the `None` branch | `:1318-1324` ✓ |
| `loadM.doLoad` :2411 | `:1601-1606` after the `_Bool` trap check (`:1587-1599`) | `if isTrap … else if has_switch .strict_reads then kill else (NDactive …)` — same order as the OCaml; default byte-identical | `:1601-1606` ✓ |
| `ptrfromint` | `:2154 if is_PNVI ()` | already in the shape (unchanged in the range) | — |
| `intfromptr` :2777 | `:2454 has_switch (SW_PNVI `AE) || has_switch (SW_PNVI `AE_UDI)` | `if CerbGlobal.is_PNVI () then kill else <default>` — over-approximating guard, documented in-code (N2 wording) | `:2454-2461` ✓ |

`SW_pointer_arith`'s payload: `inductive PointerArithMode | PERMISSIVE | STRICT` mirrors `switches.ml:5` (`SW_pointer_arith of [ `PERMISSIVE | `STRICT ]`), read at `:64-67` (`strict_pointer_arith`/`permissive_pointer_arith`) ✓; `has_strict_pointer_arith` is now the OCaml body `has_switch (SW_pointer_arith `STRICT)` (`:159-160`) ✓. `SW_forbid_nullptr_free` `:1474` and `SW_zap_dead_pointers` `:1518/:1552` were already in the shape. VALIDATION §3 (c) classes the arms as unobservable and the switch set as refused (N6 for the exact contract). **Verdict: the eight guards sit where the OCaml tests, the defaults are byte-identical, the cites are this tree's.**

### 2.5 H3 (item 5)

`oomKill`: `example : CerbMem.oomKill = (Other (MerrOther "Concrete.allocator: failed (out of memory)") : kill_reason mem_error) := rfl` elaborates (`02-AuditProbeA.out.txt`); both kill sites use it (classifier class (c), 2 lines). `#print axioms` (*reproduced*):
```
'CerbMem.allocator_below_request_kills' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.oomKill' does not depend on any axioms
CerbMem.allocator_below_request_kills : ∀ (st : CerbMem.MemState) (sz align : Int),
  st.lastAddress - sz < 0 → CerbMem.allocatorStep sz align st = (NDkilled CerbMem.oomKill, st)
```
`test/Unit/AllocatorSoundnessTest.lean` is unchanged in the range (`git diff --stat` empty). **Structural `BEq MemValue`** (`05-AuditProbeBeq.lean/.out.txt`): the retired impl's body copied VERBATIM from `0457732e1:CerbMem.lean:230-243` as a `partial def beqOld`, against the head instance `==`, on ALL ORDERED PAIRS of 34 adversarial values (nested arrays of differing inner/outer lengths, `[]` vs `[[]]`, structs differing only in a member's ctype / member name / tag / member order / emptiness, unions differing only in member name / tag / payload, unspecified values of different ctypes, pointers differing only in provenance, integers differing only in `ity`, NaN alone and nested, a 4-deep struct→array→union→struct nest):
```
ordered pairs checked: 1156 (values: 34); new==true on 34; DISAGREEMENTS: 0
non-reflexive under the new instance: [fnan, aNaN] (expected exactly the NaN carriers: fnan, aNaN)
```
(both directions by construction; `nA,nB`, `st1,st1c`, `un1,un1b`, `u0,u2`, … all `(false, false)` both ways; `deep1,deep1'` `(true, true)`.) **Identity stubs:** `grep -rn 'logRef\|timingStackRef\|STD_impl\|begin_timing_impl\|end_timing_impl' --include=*.lean --include=*.lem --include=*.sh --include=*.py …` → only comments/history in `unsafebaseio_allowlist.txt`, `check_theorem_axioms.sh` and docs; the 13 generated callers are `CerbUtils.STD_ "§…" (…)` (two explicit arguments; `cabs_to_ail_effect.lem:1601-1626`); `STD_ s x = x`, `begin_timing s = ()` by `rfl` (probe A). **Census** (*reproduced* in A1 and on my scratch root): `boundary-opaque population = the 12 registered rows exactly-once`, `seam population = the 25 pinned path-qualified counted rows`; the allowlist/`OPAQUE_WANT` deletions are exactly `begin_timing`, `end_timing`, `STD_`, `beqMemValueSafe` (4 opaques) and the 13 PIN + 3 KEEP rows for `timingStackRef`, `logRef`, `STD_impl`, `begin_timing_impl`, `end_timing_impl`, `beqMemValueImpl` (diff read). **Plants** (`07-census_plants.out.txt`, on a scratch copy of `scripts/` + `lean_frontend/`; the unplanted control reaches both census legs green and fails only at a later build-dependent leg): a re-planted `opaque begin_timing` → `FAIL — boundary-opaque census: UNREGISTERED opaque CerbUtils.lean:begin_timing (x1)`; `opaque bounded_integer` turned into a `def` → `FAIL — … registered opaque CerbUtils.lean:bounded_integer found 0 time(s)`; a re-planted `private unsafe def STD_impl` → `FAIL — C2 ratchet leg 3: … census row(s) not matching the pinned population`. **Verdict: holds; every direction RED when planted.**

### 2.6 The register (item 6)

*Reproduced* gate (`06-check_failure_reach_gate.out.txt`):
```
check_failure_reach: instrument built + census taken in 7 s (FAILURE_REACH rows 21249, FAILURE_RANGE rows 11307; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1253,"handwritten:pure_or_unresolved":121})
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
```
`--selftest`: B11.1 of my FULL run (§2.7). **Column diff** (`06-register_column_diff.out.txt`, base vs head row by row):
```
rows base/head: 233/233; tally line identical: True; header lines identical: True
changed-column patterns: {('token', 'seal'): 84, ('token', 'msg', 'seal'): 14}
rows with any change outside token/msg/seal: 0 []
token transitions: Counter({('panic!', 'failwithI'): 98})
panic! rows remaining at head: 0
seal recompute (sha256 of 8 sealed cols)[:16] == seal column: base bad=0 head bad=0
reach classes of the 98 token-changed rows: {'UNREACHABLE-BY-INVARIANT': 48, 'REACHABLE': 44, 'UNKNOWN': 6}
```
(the 14 `msg` moves are the derived 60-char keys following the prefixed messages; the charter's 44/48/6 reach split reproduces.) **Seal plants** (`06-seal_plants.out.txt`): reach class flipped → `SEAL MISMATCH … reach=UNKNOWN` + tally mismatch (rc 1); token flipped back → `SEAL MISMATCH` + `NEW pure exec-closure site` + `STALE register row` (rc 1); `msg` de-prefixed → the same triple (rc 1); `need` edited → `OK` (N9); the reach flip RESEALED → `OK … REACHABLE=47 UNKNOWN=20` (the counts move visibly — a review change looks like this). **Verdict: holds; the seal is genuine.**

### 2.7 Sequential invariance (item 7)

`python3 scripts/release.py --mode full --out .tmp/audit/release-full` at `34b8e15a8`, no tree writes during the run (my evidence directory was created only after it ended; `source_identity` hashes tracked diffs + `git ls-files --others --exclude-standard`, so the ignored `.tmp/` is invisible to it). `summary.txt`, verbatim:
```
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```
Lane lines (`09-release-full-lanes.txt`), verbatim:
```
PASSED A1 (362.1s)
PASSED A2 (31.2s)
PASSED A3 (54.2s)
PASSED A4 (23.7s)
PASSED A4b (25.0s)
PASSED A4c (3.2s)
PASSED A5 (24.1s)
PASSED A6 (2.3s)
PASSED A6b (3.7s)
PASSED A7 (10.6s)
PASSED A8 (9.0s)
PASSED A9 (17.0s)
PASSED A10 (17.2s)
PASSED A11 (58.6s)
PASSED A12.1 (4.9s)
PASSED A12.2 (4.5s)
PASSED B1 (610.1s)
PASSED B2 (23.0s)
PASSED B3 (15.1s)
PASSED B4 (45.6s)
PASSED B5 (67.3s)
PASSED B6.1 (164.7s)
PASSED B6.2 (2.3s)
PASSED B6.3 (9.3s)
PASSED B6.4 (8.5s)
PASSED B6.5 (9.0s)
PASSED B6.6 (9.8s)
PASSED B6.7 (8.4s)
PASSED B7 (1300.2s)
PASSED B8.1 (13.4s)
PASSED B8.2 (231.7s)
PASSED B8.3 (6.3s)
PASSED B8.4 (15.9s)
PASSED B9 (1299.7s)
PASSED B10.1 (115.6s)
PASSED B10.2 (1.7s)
PASSED B11.1 (15.0s)
PASSED B11.2 (6.6s)
PASSED B12 (417.4s)
```
Row 10 / `--plant` / the register gate + selftest / the libxml2 row, verbatim tails from the lane logs:
```
=== A1 (test_unit.sh) — selected lines:
  opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl); oomKill named; STD_/timing identities; structural BEq MemValue agrees with 
  Total: 12 passed, 0 failed
  check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
  check_theorem_axioms: C2 ratchet OK (378 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
  check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)
      check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consis
  check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent
=== B5
    TRIPWIRE       g6-hash-collision   
    KILL           illtyped-store      
  OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lea
=== B10.1
  859/859 semantic_agreement: corpus/p12_pt_midpoint (pristine 0.0s, fork 0.0s)
  Independent oracle scope: tier-b; 859 rows in 115.4s; source unchanged: True
  Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/seam-hygiene/.tmp/audit/release-full/B10.1/independent-oracle/report.json
=== B10.2
  3/3 plant_ok: plant/withheld-row:minimal/112-allocator-exhausted-single-request.c — minimal/112-allocator-exhausted-single-request.c: with its register row -> reviewed_difference; row withheld -> difference (completed semantic observations differ)
  Independent oracle scope: plant; 53 rows in 1.6s; source unchanged: True
  Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/seam-hygiene/.tmp/audit/release-full/B10.2/independent-oracle/report.json
=== B11.1
    UNPLANTED:
      check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every
  check_failure_reach: SELFTEST OK (5 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally — and the unplanted register green)
=== B11.2
  check_failure_reach: instrument built + census taken in 6 s (FAILURE_REACH rows 21249, FAILURE_RANGE rows 11307; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1253,"handwritten:pure_or_unresolved":121})
  check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row
=== B12
  4/4 semantic_agreement: libxml2/chvalid/chvalid_battery_03 (pristine 56.7s, fork 53.4s)
  Independent oracle scope: libxml2_chvalid; 4 rows in 417.3s; source unchanged: True
  Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/seam-hygiene/.tmp/audit/release-full/B12/independent-oracle/report.json

```
Three-engine report (`python3 scripts/test_upstream_oracle.py --with-lean`, report-only column; `10-with-lean.txt`), verbatim:
```
Independent oracle scope: tier-b; 859 rows in 255.1s; source unchanged: True
Three-engine report (Lean column, NOT gating): {'lean_agreement': 817, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}; Lean≠fork rows: 40: minimal/073-exit.libc.c, minimal/074-abort.libc.c, minimal/097-null-ptr-arith.undef.c, coverage/builtin/builtin-006-exit.libc.c, coverage/expr/expr-007-bitfield-ops.c, coverage/io/io-004-puts.libc.unsupported.c, coverage/libc/libc-002-calloc.c, coverage/libc/libc-011-memset.c, coverage/libc/libc-012-strlen.c, coverage/mem/mem-007-zero-size-array.c, coverage/misc/misc-001-void-ptr-arith.c, coverage/union3/union3-004-union-copy.c, coverage/union3/union3-005-union-return.c, debug/libc-01-memset.libc.c, debug/libc-02-strlen.libc.c, debug/ub-static-reject.c, debug/valid-04-exit-before-oob.c, bytes/byte_is_not_char.c, bytes/no_add.c, bytes/no_shift_left.c, bytes/no_shift_right.c, bytes/only_unsigned_char.c, immaculate/nolibc/f3-raw-high-byte-char-const, immaculate/nolibc/f3-raw-high-byte-int, immaculate/nolibc/f3-raw-high-byte-uchar, immaculate/nolibc/g4-bswap64-overflow, immaculate/nolibc/g5-decode-multichar, immaculate/nolibc/g5-decode-question, immaculate/nolibc/offsetof-union-member, immaculate/nolibc/r5-hex-subnormal-double-rounding, immaculate/nolibc/zd-e2-ptr-string-literals, immaculate/nolibc/zd-z2fl03-nan-to-int, immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc, immaculate/nolibc/zd-z2m02-device-funptr-call, immaculate/libc/g2-memcmp-uninit, immaculate/libc/g5-escape-roundtrip, immaculate/libc/s4b-memcmp-hugesize, immaculate/libc/zd-z2f04-closedir, immaculate/libc/zd-z2m01-aligned-alloc-zero-zero, immaculate/libc/zd-z2m01-aligned-alloc-zero
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/seam-hygiene/.tmp/upstream-oracle-3zfwte2r/report.json
```
(started 06:23:31Z at load 0.94; 255.1 s; rc 0; the 40 Lean≠fork rows are listed verbatim in `10-with-lean.txt`.) **Identical** to the part-two record's line (`2026-09-17_address-space-bound-part-two-record.md:378`: `{'lean_agreement': 817, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}`, the same 40 rows): the Lean column did not move — the nine immaculate seam-crash rows remain `lean_difference` (a Lean crash beside a fork/pristine crash with different text), as before H1; their message texts are unchanged (§2.3).
**No pre-existing baseline row moved** — every baseline lane reports its committed state. **Verdict: 39/39 PASSED with `Source unchanged: True` at `34b8e15a8` (04:59–06:23 UTC, 84 min wall, box load 0.9–35); zero movement of any baseline row; row 10, `--plant`, the register gate + selftest, the chvalid row and the Lean column all at the head and all equal to the orchestrator's lines.**

### 2.8 Record integrity (item 8)

`08-check_record_quotes.out.txt`: 168 quoted lines (fenced blocks + 4-space verbatim blocks); after stripping the record's own `row N:` labels and ` | ` joins, 162 resolve to an evidence file or to the base `observations.py` (the three pre-H1 code lines at `record.md:220-222`), and **6 do not**: the five lines of the lost first RED run (`:129-133`, N4) and the `375 files` line (`:199`, M1). Per-site table vs the H1 tree (`fce1de9f8`): 110 rows (109 REPLACE + 1 KEEP); every REPLACE line carries `failwithI`, the KEEP line carries `panic!`; **3 rows name a prefix the line does not carry** (M2); the only `failwithI` line in those files not listed is a comment (`CerbMem.lean:201`). Derived tallies labelled "derived" (§2.1, §5.3). Provenance: `[USER …]` only on the pointer quotes (§0); `[AGENT]`/`[AGENT orchestrator]` on every decision and the three fence extensions (§0, each with its scope). Charter §1 errata E1–E9 stated; E5 gives this tree's impl_mem.ml cites and I verified each (§2.4) — the allocator's own cites were not corrected (N1). Open items honest and still open: `CerbTags.lean:34` (confirmed the only other `panic!`), the VALIDATION gate-table count (confirmed `:722` says 15; now 12), `SW_PNVI` without a constructor / `intfromptr`'s coarser guard (confirmed), `load`'s PNVI `expose_allocations` arm `:1570` not in the shape (confirmed), `test_observation_lanes.py:59` (confirmed a fuel line). **Not listed:** M3 (`VALIDATION.md:1027-1030`), M4, N1–N3.

## 3. Verified clean (checked and found correct; by my own reproduction unless marked "by reading")

- Every seam-file hunk of the three code commits is one of (a)/(a′)/(imp)/(b)/(b′)/(c)/(d)/(e)/(doc); the (f) count is 0 (§2.1). The default arms of all eight guards are byte-identical (§2.1, §2.4).
- The two orchestrator probes fail by `rfl` at the head; `failwithI` is `opaque`; the `#guard_msgs` pattern is RED on a transparent leaf; five arms reduce to their defaults by `rfl` in my own statements (§2.2).
- `observations.py`: the origin acceptance is exactly the two constants; `batch` byte-identical over 17 × cases; FUEL precedes origin; unknown/forged origins fail closed (§2.3); `test_observations.py` 24/24.
- The eight OCaml arms, this tree's lines, the guard placements, the kill texts, `PointerArithMode`'s mirror of `switches.ml:5/64-67` (§2.4).
- `oomKill` by `rfl`; the axiom trio; `AllocatorSoundnessTest.lean` untouched; 1 156-pair `BEq` agreement; nothing reads the deleted refs; census 16 → 12 / 38 → 25 with three RED plants (§2.5).
- Register: 98 rows × {token, seal} (+14 msg keys), nothing else; seals recompute; gate GREEN both directions; plants RED (§2.6).
- FULL battery clean at the head; row 10 + `--plant`; `--with-lean` (§2.7).
- Fence: `git diff --name-only 0457732e1..34b8e15a8` outside `lean_frontend/docs/` = the nine seam files + `CerbGlobal.lean` (ext. 2) + `CerbMemAllocatorProofs.lean` + `OpaqueFailureTest.lean` + `lakefile.toml` + `test_unit.sh` + `VALIDATION.md` + `lean_frontend/CLAUDE.md` + `check_theorem_axioms.sh` (ext. 3) + `observations.py` + `test_observations.py` (ext. 1) + the register + the allowlist — all fenced or extended; no `.lem`/`.ml`/generated/Makefile/dune; `handwritten_copy.manifest` unchanged; no `native_decide`/`decide`-on-literal proof steps, option bumps, `partial` or new `unsafe` in the range (by reading; the `BEq` witness's two `rfl`s and `main`'s runtime check are not proofs).
- "Nothing new out of policy" ([USER 2026-09-08]): no new semantics, no new artefact class; the one restated theorem is the charter's; the hermetic test is `rfl`/`#guard_msgs`/one `#eval` environment check (by reading).
- The CLI contract: the Lean driver refuses every `--switches` spelling with exit 2 and the attributed text; no lane passes switches to the oracle (§2.4, N6).

## 4. What I did not check

- The pristine-oracle lane's `--corpus ci`/csmith reporting corpora and Tier C rows (not in the FULL selection; unchanged inputs in this range).
- A runtime witness of the KEPT `typeof_enum_impl` panic origin (no corpus reaches it; N5).
- The worker's `lean_probe` transcripts at the charter head (`probe-before.txt`) — I did not rebuild the base; the pre-H1 defect is instead shown on the base's own `combineProv` text (§2.2).
- `test_observation_lanes.py`'s 93 plants beyond running them in the FULL battery (B9 PASSED); `test_parse.sh:178`'s widened `INTERNAL_ERROR_EXPECTED` class (no `*.error.c` inputs exist, as the record says).
- Whether the consumer (cerberus-sl, read-only to me) mentions `default : CerbSwitch` anywhere (M4's consumer scan covered this repo only).
- A rebase of the range onto a moved mainline (the mainline is still `0457732e1` at the time of writing).

## 5. Provenance

[AGENT auditor] throughout; no [USER] ruling is created or revised here. Quotations marked `[USER …]` are copied from the charter/record/brief. All measurements 2026-09-19 04:42–06:28 UTC on the audit worktree at `34b8e15a8` (rebuilt 04:44–04:50), box load recorded per step. Scratch under `.tmp/audit/` (git-ignored) may be deleted; everything cited is in the evidence directory beside this report. Nothing was pushed, merged or committed on any mainline; the audited branch, the primary checkout, the consumer repo and every other worktree were not touched.
