# SC WP0 — independent skeptical review

[AGENT — independent skeptical review, Claude Fable subagent, 2026-09-26.]
Chartered by the orchestrator as the NEW reviewer the house rule requires
for core changes; the two earlier audits were read LAST (§10), after every
finding below had been formed.

Operator's framing, verbatim (relayed by the orchestrator): "We also have a
W0 prototype of the concurrency support. Can you review this? This is
intended to be uncontroversial changes which should be relatively easy to
merge (but you should treat it skeptically)".

**Range reviewed:** `db5e1feb5..e1c1d2c3a` on `arc/sc-wp0` =
`917961adf` (fix(memory): retain completed read state on trapping Bool
loads) + `4e86ea091` (feat(memory): expose passive primitive access
receipts) + `e1c1d2c3a` (docs(sc): resolve WP0 audit findings). Content is
identical to the orchestrator's rebase `review/sc-wp0-rebased-20260926`
(`cbe9a93d8` on `mdd/cerberus-lean` `9bf8cdaa6`) — checked in §9.

**What I did:** read every non-evidence file of the range in full; read the
OCaml `do_load`/`do_store` at the base and the Lean `loadM`/`storeM` before
and after; recomputed every manifest hash and the layer-2 generated-OCaml
delta hash from the pristine upstream tree and the rebased worktree's
generated tree (read-only); cross-checked every evidence JSON's recorded
source hash against the committed blobs; grepped the consumer repository
`cerberus-sl` (read-only) for `MemState` destructuring and `loadM`/`storeM`
unfolding; read the governing plan and design records.

**What I did NOT do:** no build, no gate run, no lake/dune/make/opam (per
charter). Every "verified" below means measured by git/sha256/grep/python3
on committed bytes, or read by eye. Gate verdicts are the orchestrator's to
re-run on the rebased branch.

**Grades:** P1 blocks merge · P2 fix before merge · P3 after · N note.

---

## 1. Findings, most severe first

### F1 — P2 — Consumer exposure is real and unrecorded: five cerberus-sl kernel lemmas become FALSE for observing states

`/home/dev/projects/cerberus-sl` (pin `CERBERUS_LEAN_COMMIT=2b51d2a57`,
`scripts/semantics-pin.env`) proves properties BY UNFOLDING the production
`CerbMem.loadM`/`storeM` over an arbitrary `σ : CerbMem.MemState`. Under
WP0 the following statements are no longer true for every `σ` — not "proof
script breaks", but "theorem false" when `σ.observations = some _`:

| Consumer lemma (file:line) | Statement (paraphrase) | Why false under WP0 |
|---|---|---|
| `CerberusIris/CerberusIris/MemLoc.lean:26` `loadM_loc_indep` | a successful load's `(r, σ')` is the same at every `loc` | the receipt appended to `σ'.observations` carries `loc` (`Access_receipt loc …`) |
| `MemLoc.lean:35` `storeM_loc_indep` | same for stores | same |
| `CerberusIris/CerberusIris/UnseqReads.lean:151` `loadM_lastUsed_only` | `σ' = { σ with lastUsed := σ'.lastUsed }` | `σ'.observations ≠ σ.observations` when observing |
| `CerberusIris/CerberusIris/HeapModel.lean:267` `storeM_active` | exact-state equation ending `… with lastUsed := some id }` | RHS now `recordAccess … { … }` |
| `HeapModel.lean:287` `loadM_active` | exact-state equation `{ σ with lastUsed := some id }` | same |

`MemLoc.lean:5-9` header, verbatim: "`storeM`/`loadM`/`killM` take a
location that reaches only their FAILURE payloads (`failReason err loc`): a
successful result is the same at every location. The lockstep simulation
needs this …". WP0 makes the location reach the SUCCESS state.

Measured exposure (grep, `--include='*.lean'`, `.lake/` excluded):
```
files mentioning MemState ............................ 116
theorem … (loadM|storeM) ............................. 10
lines `unfold … CerbMem.loadM|storeM` ................ 8 (MemLoc ×2, UnseqReads ×2, HeapModel ×2, ExecInv ×1, …)
`{ … : MemState }` literals / `with <field>` updates .. 537 / 49   (transparent to a defaulted field — no breakage)
MemState.mk | MemState.ext | ⟨…⟩ : MemState | extends  0 / 0 / 0 / 0
```
So the structural-pattern risk the charter asked about (`MemState.mk`,
`cases`, `⟨⟩`) is ZERO; the real risk is the semantic one above, which the
charter did not anticipate and no WP0 record or prior audit mentions
(`grep -i "cerberus-sl\|consumer repo\|re-pin"` on both audit records: 0
hits; on the three WP0 records: 0 hits).

Failure scenario: cerberus-sl re-pins to a mainline containing WP0; `lake
build` fails in `MemLoc`, `UnseqReads`, `HeapModel` (and transitively the
simulation that "needs this"); the consumer discovers WP0's design
consequence by build breakage, with no note telling them the remedy.

Remedy for cerberus-sl (recorded here so the note can carry it): every
falsified lemma holds under the hypothesis `σ.observations = none`, which
every primitive preserves (immediate from `recordAccess`'s `none` arm; the
shape of `MemoryAccessProofs.load_erasure` is the template). Alternatively
state them over `stopObserving σ`.

One-line fix (docs-only, no runtime change): add a dated consumer-exposure
paragraph to `2026-09-25_sc-wp0-passive-access.md` (or a new record) naming
the five lemmas and the `observations = none` remedy, and draft the re-pin
note that per the container CLAUDE.md "goes to cerberus-sl". This is the
one item I grade "fix before merge": WP0's own truth claim "uncontroversial
/ easy to merge" is what it contradicts.

### F2 — P3 — The committed "final" evidence was produced on a dirty tree at `head = 917961adf`, and the record does not say so

```
== access-full-validation.json   source_before.head = 917961adf…  diff_sha256 = cb28d2a7…  status: "M  … ?? …" (11 staged, 12 untracked)
== access-three-engine.json      source_before.head = 917961adf…  diff_sha256 = cb28d2a7…
== access-cost.json              head               = 917961adf…  diff_sha256 = cb28d2a7…
```
I verified that all 15 `tested_changed_source_sha256` entries (and the
cost report's 8 `sources`) equal the committed blobs at `4e86ea091` — e.g.
`scripts/LADDER.md 8db503be…`, `lean_frontend/CerbMem.lean 580c4f7b…`,
`memory/concrete/impl_mem.ml 534d25dd…` all MATCH `4e86ea091` (see §7
table) — so the run's CONTENT is the reviewed content. But
`2026-09-25_sc-wp0-passive-access.md:172-176` says "The final candidate
passed **40/40 Tier A+B commands** … with source unchanged" and names no
head. Audit 2 (`…independent-audit.md`, verbatim) already wrote: "the run
itself was made on dirty `917961ad` before the second commit was finalized.
Its clean source identity must not be misrepresented as having run at
commit `4e86ea09` directly." — the docs commit `e1c1d2c3a` did not carry
that into the record. A clean-`4e86ea091` 40/40 exists only as audit 1's
run, referenced (hash `727eda80…`) from `review-response-validation.json`.

Fix: one sentence in the record ("the committed final reports were produced
on the pre-commit tree at 917961adf whose changed-file hashes equal
4e86ea091; the clean-head 40/40 is audit 1's run, hash 727eda80…").

### F3 — P3 — The row-13 harness runs both executables WITHOUT the per-test memory cap

`scripts/test_memory_access.py:100` builds Lean under `../scripts/capped`
(good) but `:122-124` runs the binaries as
```
subprocess.run(['/usr/bin/time', '-f', '%M', '-o', str(rss_file), *command], cwd=ROOT, capture_output=True, timeout=60, env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1'})
```
— no cgroup cap. The house convention (`scripts/common.sh:390-399`,
verbatim): "The cap is now RESIDENT memory via a per-test cgroup
(`scripts/capped`, the same mechanism every lake/lean build runs under),
keeping the intended 4 GB blast radius per test on BOTH sides … Usage in a
harness … `"${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" <cmd…>`". The
`--cost` mode streams 400 000 stores with capture on; a drain regression
would grow memory unboundedly with only the 60 s timeout as backstop.
Measured RSS today is ~9–30 MiB, so the practical risk is small; the
deviation from a stated convention is the finding. Fix: prefix the command
with `scripts/capped` under `CERB_TEST_MEM_MAX` (fail-closed like the shell
harnesses).

### F4 — P3 — Front-door documents do not know about the new surface

- `lean_frontend/CLAUDE.md` at `e1c1d2c3a`: `grep -c "memory-access-test\|MemoryAccess"` → `0`. Its "Current unit tests" list enumerates every `lean_exe`; its Scripts table enumerates every harness; neither names `memory-access-test`, `test_memory_access.py` or `backend/memory_probe/`.
- `memory-access-test` is NOT in `scripts/test_unit.sh` `UNIT_TESTS` (row 1) — so `Unit.MemoryAccessProofs` (the erasure theorems) is compiled ONLY by row 13; `build_lean` (`lake build CerberusLean cerberus-lean`) does not touch it. Acceptable (row 13 is Tier A) but must be said where the gate narrative lives.
- `lean_frontend/SUPPORTED.md:27` "Domain" row (mainline): "Concurrency/weak memory is not implemented by this profile: `CerbConcurrency` contains stubs …" — still true, but the concrete model now carries an opt-in diagnostic receipt buffer and an oracle-interface extension; one clause ("an opt-in, disabled-by-default access-receipt diagnostic, Tier A row 13, is not SC execution") keeps the shop window honest.

### F5 — P3 — The shared-lem TYPE addition is not reconciled with [USER 2026-09-04] in any WP0 record

`frontend/model/mem_common.lem` +21 adds `observed_provenance`,
`representation_byte_view`, `access_receipt 'ptr 'value`, generated into
BOTH targets; the generated-OCaml delta is a NEW fork-drift layer-2 row.
The standing ruling, verbatim from `docs/2026-09-05_typed-failure-outcomes-design.md:41`:
"[USER 2026-09-04] … 'we don't change the lem structure for ocaml' —
Lean-only declares are fine, `.lem` bodies and the OCaml output are not
touched". WP0 touches the OCaml output. My judgement: this is inside the
ruling's purpose (it targeted Lean-motivated restructuring of shared
functions; here no lem function or body changes, the type is consumed
identically by the OCaml oracle and by Lean, and a single lem source is the
mirror-doctrine-correct alternative to a hand-copied type pair) — but the
records cite neither the ruling nor the argument (`grep -i "lem structure"`
on the three WP0 records: 0). Fix: one paragraph citing the ruling and the
exception argument; the operator may want to confirm.

### F6 — N — Store-hook placement differs between OCaml and Lean (harmless; note it in-code)

OCaml (`memory/concrete/impl_mem.ml:1729-1731` at head) records INSIDE the
first `update`, i.e. before the union-member update (`:1702-1709`), before
`print_bytemap`, and before the `is_locking` read-only update that follows
`do_store` in the caller. Lean (`CerbMem.lean:2553-2555`) records AFTER
union-member and read-only bookkeeping. Final states are equal because the
receipt reads nothing from the state and no intervening step can fail; but
the Lean comment `-- :1687 last_used` does not say the order is deliberate.
Mirror doctrine: "mirror the OCaml with file:line cites, or document the
divergence in-code as deliberate". One comment line.

### F7 — N — The refused `strict_reads` arm returns `st`, not `loadedState`

`CerbMem.lean:2492-2493`: the loud-kill arm for the refused switch returns
`st` (pre-read state) while OCaml would have `last_used` updated there too.
Dead arm (`CerbGlobal.has_switch_*_eq : … = false := rfl`), so no
behaviour; the mirror is imprecise by one token. Cosmetic.

### F8 — N — Field-count correction to the charter

`MemState` at head has **15** fields (14 + `observations`), not 16 as the
charter said; OCaml `mem_state` at `memory/concrete/impl_mem.ml:484-504`
has 15 (`observations` placed before `requested`). The restored docstring
"15 fields" is correct. [derived tally from the two structure bodies]

### F9 — N — Fuel numerals `17`/`64` in the Python harness

Not scanned by `check_no_fuel_numerals.sh` (it scans `.lean` only, by
design — `common.sh:401-410` "[USER 2026-09-03] 'Defaults that are chosen
eg. in test suites are fine'"). Two distinct fuels producing identical
transcripts is a small fuel-independence witness. Fine.

### F10 — N — Symbolic/CHERI stubs are type-correct by inspection; still uncompiled

Signature (`ocaml_frontend/memory_model.ml:51-54`): `type access_receipt =
(pointer_value, mem_value) Mem_common.access_receipt`; `begin_observing:
mem_state -> mem_state option`; `stop_observing: mem_state -> mem_state`;
`take_observations: mem_state -> (access_receipt list * mem_state) option`.
Each stub defines the manifest type identically and the three values with
matching annotated types; `Mem_common` is referenced QUALIFIED so no `open`
is needed (symbolic has `open Mem_common` only at `:244`, VIP none — both
fine). `pointer_value`/`mem_value`/`mem_state` are defined earlier in each
file (the stubs sit after `serialise_mem_state`). Only four implementors
exist (`memory/{concrete,cheri-coq,symbolic,vip}`; grep for `: Memory =
struct` finds Concrete and CHERIMorello; symbolic/vip are file-level
modules). Residual: z3/coq-dependent builds uncompiled — disclosed in the
record; acceptable for a fork that does not ship those models.

### F11 — N — Evidence volume and labelling

`lean_frontend/docs/sc-wp0-evidence/` = 184 KiB, 14 files, all JSON/txt
(no archives). The two `*-before-final-rebase.json` files are labelled
historical in the record (`passive-access.md:191-192`). Fine under the
repo rule; F2 is the only labelling gap.

### F12 — N — `assert`-based instrument controls

`test_memory_access.py:69-82` implements the 8 controls with Python
`assert`; under `python3 -O` they vanish silently. LADDER row 13 invokes
plain `python3`, so this is latent. Prefer explicit `raise`.

---

## 2. R-A — Mirror fidelity

### 2.1 The `_Bool` repair

OCaml base, `git show db5e1feb5:memory/concrete/impl_mem.ml` (do_load), verbatim:
```
1564:       let bs = fetch_bytes st.bytemap addr (Z.to_int (sizeof ty)) in
1565:       let (taint, mval, bs') = abst (find_overlaping st) ~addr st.last_used_union_members st.funptrmap ty bs in
1567:       begin if Switches.(has_switch (SW_PNVI `AE) || has_switch (SW_PNVI `AE_UDI)) then
1568:         expose_allocations taint
1571:       end >>= fun () ->
1575:       update (fun st -> { st with last_used= alloc_id_opt }) >>= fun () ->
1577:       begin match bs' with
1578:         | [] ->
1587:             begin if AilTypesAux.is_Bool ty then
1590:               match mval with
1591:                 | MVunspecified _ ->
1592:                     fail ~loc (MerrTrapRepresentation LoadAccess)
1593:                 | MVinteger (_, (IV (_, n))) when is_trap n ->
1594:                     fail ~loc (MerrTrapRepresentation LoadAccess)
```
Lean base (`git show db5e1feb5:lean_frontend/CerbMem.lean`), verbatim:
```
2428:    let fail_ (err : mem_error) := (NDkilled (failReason err loc), st)
2448:      if isTrap then fail_ (MerrTrapRepresentation LoadAccess)
2454:      else (NDactive (fp, mv), { st with lastUsed := allocOpt })
```
Lean head (`CerbMem.lean:2477-2489`):
```
      let loadedState := recordAccess loc LoadAccess ty pv allocOpt addr bytes mv none
        { st with lastUsed := allocOpt }
      …
      if isTrap then
        (NDkilled (failReason (MerrTrapRepresentation LoadAccess) loc), loadedState)
```
- Is the repaired trap-path state exactly OCaml's? On OCaml's trap path the
  state is the input state with `last_used := alloc_id_opt` (the only
  `update` before the check), plus — under PNVI switches only —
  `expose_allocations taint`. PNVI is in the refused set (Z-24), so in
  matched mode: `lastUsed` only. `abst` is pure (returns
  `(taint, mval, bs')`). Lean's `loadedState` = `{ st with lastUsed :=
  allocOpt }` (+ receipt when observing). **Exact.** Nothing else
  (`last_used_union_members`, taint, bytes) moves on either side.
- Anything else still divergent on that path: only F7 (dead arm).
  Pre-existing and out of scope: OCaml's `| _ -> fail (MerrWIP "load, bs'
  <> []")` arm is not modelled in Lean (`abst` consumes exactly `sizeof
  ty` bytes, so `bs' = []` always).
- Why no lane caught the pre-repair divergence: `lastUsed` has no reader in
  the Lean seams outside `CerbMem.lean` (`grep -l lastUsed lean_frontend/*.lean
  speclab/**/*.lean` minus CerbMem → none); the OCaml reader is
  `serialise_mem_state` (UI dump). A UB kill ends the run and the lanes
  project value/stdout/stderr/blocked, not memory state. The divergence
  was unobservable by every differential lane by construction; the new
  `MonadicFailstop` arms + `memory_probe.ml` make it observable. Before
  transcript, verbatim (`sc-wp0-evidence/bool-lean-before.txt:1-2`):
  ```
  FAIL [2] Bool trap retains completed read state
  FAIL [2] unspecified Bool trap retains completed read state
  ```

### 2.2 The receipt hooks

Load — OCaml head `:1607-1609`:
```
      update (fun st -> record_access loc LoadAccess ty (PV (prov, ptrval_))
        alloc_id_opt addr bs mval None
        { st with last_used= alloc_id_opt }) >>= fun () ->
```
`bs` is the PRE-abst fetched representation (`fetch_bytes st.bytemap addr
(sizeof ty)`, `:1564`), not `bs'`. Lean's `bytes := readBytesFrom st addr
size` is the same list; `mv` = `mval`; `pv` = `PV (prov, ptrval_)` (the
ORIGINAL pointer, both sides); `allocOpt` = `alloc_id_opt`; `none` = `None`.
Placement: after reconstruction, with the `last_used` update, before the
trap check — same on both sides. **Symmetric.**

Store — OCaml head `:1726-1731` records `pre_bs` (the `repr` output before
addressing), `Some is_locking`, `alloc_id_opt`, inside the first `update`.
Lean `:2553-2555` records `bytes` from `memValueToBytes` (the mirror of
`repr`), `some isLocking`, `allocOpt.map Prod.fst`. Content symmetric;
placement asymmetry = F6 (harmless).

`view_byte`/`viewByte`: four provenance arms map one-to-one; `copy_offset`
via `Z.of_int` / Lean `Option Int` direct; byte via `Z.of_int (Char.code
c)` / `Int.ofNat v.toNat` — both 0..255, `None` = unspecified. **Symmetric.**

API: `begin_observing` idempotent prefix-preserving, `take_observations`
reverses once and leaves `Some []`, `stop_observing` drops — textually
parallel on both sides (`impl_mem.ml:529-537` / `CerbMem.lean:186-195`).

## 3. R-B — Passivity

- Disabled path: `record_access … | None -> st` and `recordAccess … | none
  => st` — the input state object, no byte-list traversal. `observations =
  None/none` in `initial_mem_state` and the Lean default. No other
  path is touched (diff read in full: the only runtime edits are the two
  hook sites, the trap arm, the field, and the five API functions).
- Erasure theorems (`test/Unit/MemoryAccessProofs.lean:19-29`) are stated
  over the PRODUCTION `loadM`/`storeM` (imported from `CerbFailProofs` →
  `CerbMem`; no copies), for arbitrary `es ts l t p s` and `[LemFuel]`;
  `eraseNode` keeps the action and applies `stopObserving` to the state, so
  the equation covers every arm including kills (the kill arms return `st`
  on both sides and `split` closes them). Tactics: `simp only`, `split`,
  `simp_all only [recordAccess]` — kernel-checked, no `native_decide`, no
  option bumps, no `sorry` (grep: 0). `#print axioms` (evidence
  `access-proof-axioms.txt:15-17`, verbatim):
  ```
  info: test/Unit/MemoryAccessProofs.lean:42:0: 'MemoryAccessProofs.load_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
  info: test/Unit/MemoryAccessProofs.lean:43:0: 'MemoryAccessProofs.store_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
  info: test/Unit/MemoryAccessProofs.lean:44:0: 'MemoryAccessProofs.lift_returned_state' depends on axioms: [propext]
  ```
  The standard three. (The theorems prove enabled-vs-disabled equivalence
  of the CURRENT primitives; "byte-identical to before" across versions is
  a differential claim, carried by the 40/40 + three-engine runs, not by
  the kernel — the record says so at `:88-91`.)
- Gate coverage of the new files: `check_no_fuel_numerals.sh:94` scans
  `lean_frontend/test/**/*.lean` → both new files scanned (`top := 65536`
  is a named test value, not the banned default; `LemFuel.mk fuel` is a
  variable, F4 bans numerals). `check_theorem_axioms.sh:59-65,586` census
  + D14 grep leg over `lean_frontend/test` → covered. `check_lakefile_roots`
  concerns the `CerberusLean` lib roots only — the new `lean_exe` is
  outside its object, correctly. `check_failure_reach`/`check_fuel_forms`
  concern the exec cone/fuel'd workers; `recordAccess` is not fuel'd and
  has no failure leaf → nothing to register.

## 4. R-C — The shared lem change

- Manifest source-content rows (6) — recomputed at `e1c1d2c3a`, all six
  equal (`sha256sum` vs `scripts/fork_drift_manifest.txt [source-content]`):
  `e95bbe82… mem_common.lem`, `3ff58a23… cheri-coq`, `534d25dd… concrete`,
  `3ec2b3c5… symbolic`, `b4333a24… vip`, `99236fce… memory_model.ml`.
- Layer-2 row recomputed with the gate's own formula (`check_fork_drift.sh:236-238`) from the pristine tree `deps/cerberus-upstream/ocaml_frontend/generated/mem_common.ml` and the rebased worktree's `ocaml_frontend/generated/mem_common.ml` (both read-only):
  ```
  0471d6a212c273c515d525173d8003c7d10d559e5f91758820708ec69e52e6d5  -
  manifest row: 0471d6a212c273c515d525173d8003c7d10d559e5f91758820708ec69e52e6d5 mem_common.ml
  ```
  Equal. The delta body is exactly the three types + their comments (the
  `+` lines quoted in my session; no `-` lines).
- Lean uses the GENERATED type: `CerbMem.lean:19 import Mem_common`, `:150
  abbrev AccessReceipt := access_receipt PointerValue MemValue`; generated
  `Mem_common.lean:184-188` `inductive access_receipt (ptr value : Type) …
  Access_receipt : CerbLocation.Loc → access_kind → ctype → ptr → Option
  Int → Int → List representation_byte_view → value → Option Bool → …`.
  `Loc.t` → `CerbLocation.Loc` via `loc.lem:7 declare lean target_rep`.
  No hand copy. Good.
- Ruling reconciliation: F5.

## 5. R-D — Consumer exposure

F1 in full. Additional facts: cerberus-sl consumes seams by overwriting
`generated/<seam>.lean` with the pin's `lean_frontend/<seam>.lean`
(`scripts/setup-cerberus-dep.sh:84-90`), so `CerbMem.lean` at the next pin
is exactly WP0's. `observations` as an identifier: 5 hits, all prose in
docstrings about Iris "observations" — no field-name collision. The WP0
records' silence on the consumer is the P2.

## 6. R-E — The OCaml interface

F10. Failure scenario for upstream-building configurations: a downstream
that builds `mem_symbolic`/`mem_cheri_coq` (the fork's driver `dune` has
symbolic commented out at `backend/driver/dune:13`; cheri at `:37` needs
coq) hits any type error first; by inspection there is none. Grade N with
the disclosed residual.

## 7. R-F — The new gate/row/exe/probe

- Fail-closed: `validate()` = rc 0 ∧ stderr empty ∧ whole-stdout byte
  equality; 8 instrument controls (6 mutations + rc + stderr) run before
  every gate run; `LEAN_ABORT_ON_PANIC=1`; `raise SystemExit` on first
  failing run; report written incrementally. Expectations are DERIVED
  (LP64 arithmetic in `expected()`), not recorded — a genuine independent
  specification. Good.
- Builds: `tools/check_handwritten_sync.sh`, `tools/check_lem_sync.sh
  --check-lean`, `dune build --root . backend/memory_probe/{access,memory}_probe.exe`,
  `../scripts/capped lake build memory-access-test`. The run step: F3.
- `--cost`: measurement only (`passed` never depends on time/RSS;
  `LADDER.md` row 13: "no timing threshold is a semantic gate"). Good.
- Is a Tier A row justified TODAY? What row 13 protects: (i) the `_Bool`
  trap-state mirror (a real mirror-doctrine property, otherwise invisible
  to every lane — §2.1); (ii) the erasure theorems' compilation (they are
  built by NOTHING else — F4); (iii) OCaml↔Lean receipt-content parity, a
  mirror property of two hand-written seams. (i)–(iii) are trust
  properties of the SHIPPED sequential semantics, not of a future SC
  feature; (iii) matters only once a consumer exists. I accept the row on
  (i)+(ii); had the trap-state check been folded into `monadic-failstop-test`
  (row 1, where it already lives) and the proofs into an existing exe, the
  row would be a discipline point. Reasonable either way; not a finding.
- Surface growth vs [USER 2026-09-08] verbatim (`docs/2026-09-11_codex-charter-…:16`):
  "we should *NOT* be building anything new out-of-policy" — that ban's
  operative content is "no new enumeration/literal/semantics-evaluation
  program proofs or artefact surface". WP0 adds no program proofs; it adds
  two probe exes + one lean_exe + one harness under the LATER direction
  `SC-CONCURRENCY.md:11-17` "[USER, 2026-09-24] … seek early mainline
  landings whenever work can be audited cleanly … land necessary,
  independently validated foundations" and `:24` "[USER, 2026-09-25 …]
  The MVP delivers a coherent and correct executable SC model", plus the
  records' "the user then directed 'proceed with WP0'" (`bool-load-repair.md:11`,
  a relayed quote — I could not locate its verbatim source outside the WP0
  records; the plan's `:291` row says "proceed with minimal WP0" as the
  re-review's conclusion). The later, specific direction governs; the
  surface is the minimum the plan's WP0 row (`:180`) demands ("with its
  real diagnostic consumer"). Within policy, provided the operator's
  "proceed with WP0" is as reported.
- `memory-access-test` in row 1? **No** (`test_unit.sh:15-40` UNIT_TESTS has
  no such entry; grep 0) — only row 13. F4.
- `check_lakefile_roots.sh` / `check_no_fuel_numerals`: §3.

## 8. R-G — Evidence integrity

Recorded source hashes vs committed blobs (python3 over `git show`):
```
e95bbe82ea28 frontend/model/mem_common.lem                 917961adf:diff  4e86ea091:MATCH e1c1d2c3a:MATCH
534d25dde092 memory/concrete/impl_mem.ml                   917961adf:diff  4e86ea091:MATCH e1c1d2c3a:MATCH
99236fced4e1 ocaml_frontend/memory_model.ml                917961adf:diff  4e86ea091:MATCH e1c1d2c3a:MATCH
580c4f7b92e8 lean_frontend/CerbMem.lean                    917961adf:diff  4e86ea091:MATCH e1c1d2c3a:diff 075f4ebc59c7
88744bb514dc backend/memory_probe/access_probe.ml          917961adf:ABSENT 4e86ea091:MATCH e1c1d2c3a:MATCH
75653632559f lean_frontend/test/Unit/MemoryAccess.lean     917961adf:ABSENT 4e86ea091:MATCH e1c1d2c3a:MATCH
409549e8c4f9 lean_frontend/test/Unit/MemoryAccessProofs.lean 917961adf:ABSENT 4e86ea091:MATCH e1c1d2c3a:MATCH
307747a649fd scripts/test_memory_access.py                 917961adf:ABSENT 4e86ea091:MATCH e1c1d2c3a:MATCH
8db503be34dba887 4e86ea091 scripts/LADDER.md   (= membership_sha256 of the final run)
b7f8af05b9b63fc4 4e86ea091 lean_frontend/lakefile.toml
8e4627e6cf84d38b 4e86ea091 scripts/fork_drift_manifest.txt
5b841df0d6d84dc8 4e86ea091 backend/memory_probe/dune
```
(`CerbMem.lean` differs at `e1c1d2c3a` by the docstring only — the
review-response's `only_lean_change_is_docstring: true` and the addendum's
byte comparison agree; hash `075f4ebc…` matches the addendum's table.)

- `access-full-validation.json`: `mode=full`, `status=passed`, 40 lanes,
  `selected` includes `A13`, `source_unchanged=True`,
  `artifact_issues=[]`, `release_certification = "incomplete:
  reporting/adoption/audit exits require separate evidence"` (honest).
- `access-three-engine.json`: `status=reported`, `comparison.status=passed`,
  `historical_lean_difference_list_equal` present; counts 835/28/7/2 are the
  record's claim — I did not recompute them from the raw report (not
  committed; the JSON carries `raw_report_sha256`).
- `access-cost.json`: 39/39 `passed`, RSS/wall per run; head/dirty: F2.
- `bool-repair-evidence.json`: base `e9f9d049f` with a dirty `diff_sha256`
  and two untracked probe files — the ORIGINAL pre-rebase witness, labelled
  as such in the record (`bool-load-repair.md:5-8`). Fine.
- Provenance tags after the docs commit: present in all three records
  (`[AGENT]`/`[USER]` on every decision paragraph I checked). Good.
- Total 184 KiB, no archives: F11.

## 9. R-H — The "uncontroversial / easy to merge" claim

Every way the range is NOT purely additive/passive:
1. **Oracle interface change** — `module type Memory` gains one type + three
   values; four implementors edited; two of them (symbolic, CHERI) never
   compiled by anyone in this effort.
2. **Shared lem type** — the generated OCaml oracle surface changes (new
   layer-2 fork-drift row), touching the [USER 2026-09-04] ruling (F5).
3. **`MemState` gains a field** — transparent to the fork's own code and to
   the consumer's 537 struct literals, but it falsifies five consumer
   theorems for observing states (F1).
4. **Behavioural change on a failure path** — the `_Bool` trap now returns
   the post-read state. Correct per OCaml; unobservable by lanes;
   observable by any consumer lemma about killed-load states (none found
   in cerberus-sl today).
5. **New Tier A row + new lean_exe + two OCaml exes + a Python harness** —
   permanent gate surface for a feature with no consumer yet (§7).
6. **Manifest rows** — 6 source pins moved + 1 new layer-2 row (verified).
7. **VALIDATION.md/LADDER.md edits** — one row each, consistent with
   mainline's 14 commits (their LADDER edit is at row 1 line 40; WP0's at
   line 58; VALIDATION hunks at 237/749/1113 vs WP0's at 630/632).

Judgement: the RUNTIME change is small, disabled-by-default, kernel-proved
erasable, and mirrored file:line; its own validation is unusually thorough
for its size. "Uncontroversial" is nonetheless overstated on one axis — it
changes the semantic surface the consumer proves against (F1) and nobody
wrote that down. "Easy to merge" mechanically: yes (§10).

## 10. R-I — Merge mechanics

```
$ git merge-tree --write-tree mdd/cerberus-lean e1c1d2c3a ; echo exit=$?
5cb478318a97876df571fab06898c6fff1c56ec0
exit=0
```
No conflicts. Rebased branch `review/sc-wp0-rebased-20260926` = `cbe9a93d8`;
`git diff mdd/cerberus-lean cbe9a93d8 --stat` tail = `35 files changed, 4604
insertions(+), 10 deletions(-)` = the candidate's; the two patch texts
differ only in one hunk header offset (`@@ -630,6 +630,7` → `@@ -632,6
+632,7`, VALIDATION.md). Content-identical. Nothing in mainline's 14
commits (README pin line, fork-drift merge-base fix, pin-site leg, alpha
tags) interacts with WP0's paths semantically; the fork-drift gate's
merge-base pin (`[meta] merge-base=`) is unchanged by WP0 (its manifest
edit adds rows only). SUPPORTED.md's "no concurrency" remains true; F4
lists the sentence that should be added. Row 13's LADDER text says "No SC
execution claim." — consistent.

## 11. Comparison with the two prior audits (read last)

| Topic | Audit 1 (`audit/sc-wp0-20260925`) | Audit 2 (`audit/sc-wp0-independent-20260925`) | This review |
|---|---|---|---|
| `_Bool` repair semantics | accepted; ran gates; noted `lastUsed` "has no reader outside the UI state dump" | accepted; extracted OLD body and executed it — the strongest witness | agree (§2.1) |
| Hook placement/content | accepted; noted store-order asymmetry ("Lean appends after…, OCaml before; receipt content and final state agree") | accepted; same observation | agree; I ask for the in-code note (F6) |
| Erasure theorems | standard three axioms, plant P3 | same, "no vacuity premise" | agree (§3) |
| Layer-2 row | "hash-pinned … gate green" | not recomputed | **recomputed independently** (§4) |
| Evidence identity | 15/15 hashes equal 4e86ea091 | **caught the dirty-`917961ad` head** and warned against misrepresentation | agree with audit 2; the record still doesn't say it (F2) |
| Consumer (cerberus-sl) | not considered | not considered | **F1 — missed by both** |
| [USER 2026-09-04] lem ruling | not considered | not considered | F5 |
| Per-test cap on exe runs | not considered | not considered | F3 |
| Front docs (CLAUDE.md/SUPPORTED) | D2 (VALIDATION row) — fixed | — | F4 (the remaining ones) |
| Provenance tags | D1 — fixed in e1c1d2c3a | — | verified present |
| Symbolic/CHERI uncompiled | R1 residual | "two material limits" | N (F10) |

Where I disagree: audit 2's "Ready for exact-head landing approval" and the
review-response's "No runtime remediation is needed" are right about the
RUNTIME; both under-weigh the consumer, which the container CLAUDE.md names
as THE consumer and to which "re-pin notes go". Audit 1's `stateEq` "all 14
sequential `MemState` fields" is correct (14 + `observations` = 15; the
charter's "16th" is the miscount, F8).

## 12. VERDICT

**Merge-ready after the listed P2 (F1), which is docs-only.** The runtime
change is a faithful mirror (§2), passive by default with kernel-checked
erasure (§3), its shared-type and manifest claims recompute exactly (§4),
its evidence content is the committed content (§8), and the rebase is
content-identical and conflict-free (§10). It is not "uncontroversial" in
the one respect that matters to the fork's stated consumer: five
cerberus-sl kernel lemmas stated over arbitrary `MemState` become false for
observing states, and no record says so — write the consumer-exposure
paragraph and the re-pin note before the ff-only merge (F1), and state the
evidence head honestly (F2, trivially co-fixable). F3–F5 may follow the
merge; F6–F12 are notes. Merge authority rests with the operator; nothing
here is a sign-off.
