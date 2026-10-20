# Pre-merge audit: fix/item-g-refusals (2e1777b27..aab8193b9)

Trimmed independent audit (one fresh reviewer, about seventeen minutes of run time; scope offered: the two predicates against the OCaml and against what they miss, the allocator proof with axiom census and kernel replay, the witness plants, the retired rows, the register classification, the consumer note; the reviewer was free to look anywhere). Launched by the orchestrator 2026-10-20 with the pre-merge ask outstanding. The reviewer's harness could not write the report file, so the orchestrator saved its final message here verbatim. Dispositions are in the follow-up commit and the landing note.

## Verdict

**MERGEABLE WITH FIXES.** The two refusals are mirrored correctly where they fire, the texts are byte-identical, the theorem statement is unchanged and kernel-clean, and the witness script is non-vacuous. Two things must be fixed before the merge claim: the overlap predicate misses a copy shape both engines still serve (device memory), while every document and both code comments claim it is complete; and the named kernel-replay gate for a proof-changing slice was neither run nor quoted (the reviewer ran it; it is green).

## Findings

### P2-1 — The overlap predicate misses `Prov_device` pointers; both engines still ANSWER an overlapping `memcpy` there, and every claim of completeness is false

- `lean_frontend/CerbMem.lean:3615-3620` (`memcpyOverlap` doc: "the one shape `load`/`store` serve … so every copy that could complete is covered"), `memory/concrete/impl_mem.ml:2701-2705` (same claim), record §2 ("no overlapping copy is served through another provenance"), consumer note §G1 ("Your harness's own overlap refusal becomes redundant at the next re-pin"), CONTRACT §3 row ("REFUSED (D10) in both engines, where upstream answers").
- Claim: `load`/`store` in BOTH engines serve `PV (Prov_device, PVconcrete _)` (`impl_mem.ml:1669-1675`, `:1778-1784`; `CerbMem.lean:2906-2908`, `:3001-3003`), `ptrfromint` mints it for any integer in `device_ranges` (`impl_mem.ml:2226-2227`: `[0x40000000, 0x40000004)`, `[0xABC, 0xAC0)`), the pure `array_shift_ptrval` passes it through (`| _ -> PV (prov, …)`), and `memcpyOverlap`'s `| _, _ => none` / the OCaml `| _ -> ()` let it through.
- Check (both engines, `--nolibc`, prototype only):

  ```
  dev_overlap.c :  char *p = (char*)0xABC; p[0]=1; p[1]=2; p[2]=3; memcpy(p, p + 1, 2); return p[0] + p[1];
    oracle: Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}      (rc 0)
    lean:   Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}      (rc 0)
  dev_overlap2.c:  char *p = (char*)0x40000000; p[0..3]=1,2,3,4; memcpy(p + 1, p, 3); return p[1]*100+p[2]*10+p[3];
    oracle: Defined {value: "Specified(111)", stdout: "", stderr: "", blocked: "false"}    (rc 0)
    lean:   Defined {value: "Specified(111)", stdout: "", stderr: "", blocked: "false"}    (rc 0)
  ```

  An overlapping copy — upstream's TODO case exactly — is served byte-wise and answered as defined. The engines agree (no differential drift), but the ruling the slice implements is "leave as-is or refuse loudly, never answer"; the slice chose refusal and then asserts in five places that no served shape remains. The consumer is told its own overlap hook is redundant; it is not.
- Fix: either add the `Prov_device`/`Prov_device` arm (intersecting ranges, `n > 0`) in both engines with a text of the same shape (the message's `allocation {id}` has no id here; say "device memory") plus a witness in `check_item_g_refusals.sh`, or keep the gap as a named, [USER]-signed residual and correct every completeness claim (code comments, record, CONTRACT D10, VALIDATION §3(c), consumer note). Either is a few lines; the second still needs the consumer note corrected.

### P2-2 — The kernel-replay gate was skipped for a proof-changing slice

- `lean_frontend/docs/2026-10-20_item-g-refusals-record.md` §6 (gates), commit message: `grep -ci leanchecker` → 0 in both; no mention of a replay anywhere in the record or the consumer note.
- Claim: the container's standing rule ([USER 2026-10-18], container `CLAUDE.md` "Kernel replay is a named trust gate") requires `lake env leanchecker` over the affected modules before the slice-exit claim for any slice that changes proofs, with modules and exit status quoted; "a failed or skipped replay is a red gate, never a note". This slice changes `CerbMemAllocatorProofs.lean` (new `split` arm) and `test/Unit/FuelExemplar.lean` (simp set).
- Check (the reviewer's run, from `lean_frontend/`, `CERB_MEM_MAX=32G`, via `scripts/ce` and `../scripts/capped`):

  ```
  lake env leanchecker CerbMemAllocatorProofs Unit.FuelExemplar     → (no output)   rc=0   (1.6 s wall)
  lake env leanchecker NoSuchModuleXYZ  (negative control)          → uncaught exception: Could not find any oleans for: NoSuchModuleXYZ   rc=1
  ```

  Content is green; the gate is red by the rule until the record quotes a run. Fix: run it on the final tree and quote modules + exit status in §6.

### P3-1 — The consumer note understates the cerberus-sl breakage: a general theorem becomes FALSE, not merely harder to prove

- `lean_frontend/docs/2026-10-20_consumer-note-cerberus-caesium-item-g-refusals.md` §"If you unfold `CerbMem.allocator` in proofs"; record §7.
- Claim: the note says literal-alignment unfoldings need `CerbMem.alignmentRefused` in a simp set (true for `Adequacy.lean:339` `errno_room_iff` and `HeapModelAlloc.lean:45` `allocator_active_shape`, both `simp only [ndRun, CerbMem.allocator] at h` + `split`, each gaining an arm). It omits `/home/dev/projects/cerberus-sl/CerberusIris/CerberusIris/HeapModelAlloc.lean:59`:

  ```lean
  theorem allocator_cases (sz align : Int) (st : MemState) (hne : align ≠ 0) :
      (∃ id a st', ndRun (CerbMem.allocator sz align) st = (.NDactive (id, a), st')) ∨
      ndRun (CerbMem.allocator sz align) st = (.NDkilled oomKill, st)
  ```

  For `align = 3`, `sz` small, the new arm returns `(NDkilled (failStopKill (failwithI …)), st)`: neither disjunct holds, so the statement is false at the re-pin and needs a hypothesis (`alignmentRefused align = false`) or a third disjunct. `Adequacy.lean:336` and the `allocatorSound`/`allocator_cases` chain described in its header depend on it.
- Fix: state this in the consumer note (and record §7) before the re-pin.

### P3-2 — Record §5: a derived tally is wrong and its explanation is confused

- Record §5, failure-reach bullet: "the hand-written monadic count went 2 → 3 (the memcpy site; the allocator's leaf is inside an existing-shape arm)".
- Check: `python3 -I scripts/failure_census.py` on HEAD → `"handwritten:monadic_ascribed": 3` (`CerbMem.pnviRefuseM` :2266, `CerbMem.allocator` :2553, `CerbMem.memcpyM` :3644); on the base commit's hand-written files (HEAD~1, generated tree linked) → `"handwritten:monadic_ascribed": 1` (`CerbMem.pnviRefuseM`). The count went 1 → 3; both new sites are counted, the allocator's included. Correct the line; the conclusion (no register row, pure count 239 unchanged) stands.

### Note — Refusal precedence over other UB is broader than the record states

- Record §2 and the consumer note say an overlapping copy that is also out of bounds is refused before the loop's bound. The same holds for every access check, e.g. a dead object: `dead_overlap.c: p = malloc(8); free(p); memcpy(p, p + 1, 2);` → oracle `Failure("Concrete.memcpy: refused - … (allocation 3: destination [281474976710624, 281474976710626) and source [281474976710625, 281474976710627), n = 2) …")` rc 125; Lean the same text, rc 134 — the DeadPtr UB is never reported. Permitted by the ruling; say it generally ("before any access check") so the consumer is not surprised by a lost use-after-free verdict.

### Note — Process (record §8, self-reported)

- Processes were located by `pgrep -f` pattern and killed after a cwd check. The box rule is kill only PIDs you started; the record says so itself. Nothing to fix in the tree; the orchestrator should carry the lesson.

## Checked, no finding

- **Overlap predicate, served shapes other than device:** `Prov_none` concrete pointers fail at the first byte (`impl_mem.ml:1667/:1776`; probe `none_overlap.c` → `Undefined {ub: "UB_CERB002a_out_of_bound_load", …}` on both, rc 1); `Prov_symbolic` dies in the pure `array_shift_ptrval` (`failwith "… found a Prov_symbolic"`, R-PNVI-06); `PVnull`/`PVfunction` fail in `load`. `memcpy(p, p, n)`, `n = 0`, adjacent halves, two objects, realloc (new ← old, two allocations; `realloc_proxy` std.core:360) behave as claimed (witness controls). Different allocations never share addresses (allocator decrements, never reuses).
- **Lean ↔ OCaml mirror of the predicate and order:** `id1 == id2 && n > 0 && a1 < a2 + n && a2 < a1 + n` ≡ `Z.equal id1 id2 && Z.gt size_n Z.zero && Z.lt a1 (a2+n) && Z.lt a2 (a1+n)`; both fire at application, before any load (OCaml `failwith` outside the monad; Lean `failwithI` at `memM`, `@[never_extract]` on both the opaque and its implementation, LemLib.lean:225-233). Texts byte-identical (`memcpyOverlapRefusal` vs the `Printf.sprintf`, `alignmentRefusal` vs its sprintf; Int/Z rendering agrees incl. negatives).
- **Alignment predicate:** `align != 0 && !(align > 0 && (toNat align &&& (toNat align - 1)) == 0)` agrees with `not (equal align zero) && not (gt align zero && equal (logand align (pred align)) zero)` on every Int: 0 excluded on both, negatives refused on both, `1` and every power of two pass, others refused. Placement identical: after the `z < 0` out-of-memory kill, before the remainder (OCaml `:1292-1308`; Lean `allocator` after the pre-existing `align == 0` arm, which is OCaml's `quomod` Division_by_zero). `_Alignas` of a non-power-of-two is a front-end constraint violation; `malloc`'s alignment is 8; `create` uses `alignof` (powers of two). Method of the measurement (oracle-only temporary instrument over the exec lanes, reverted) is sound because the Lean allocator mirrors the oracle on every lane; the lanes listed cover the `tier-b` pristine corpora (`test_upstream_oracle.py:63-65`) except `cli`; libxml2_chvalid/ci/csmith are declared unmeasured.
- **Runtime shape of the Lean leaves:** the `allocator` arm `NDkilled (failStopKill (failwithI …))` aborts at construction (witness: exit 134 with the text, no verdict printed); `Main` refuses to start without `LEAN_ABORT_ON_PANIC` (Z2-FL-03), so no kill is observable in the driver; in the kernel it is `Error0 modelFailStopLoc <opaque String>`, a kill. `memcpyM`'s leaf is the plain `failwithI` at `memM`, as `pnviRefuseM`.
- **Theorem statement unchanged:** `git diff HEAD~1 HEAD -- lean_frontend/CerbMemAllocatorProofs.lean` has no `theorem`/hypothesis lines; `#check` gives `∀ (st st' : MemState) (sz align id a : Int), allocatorStep sz align st = (NDactive (id, a), st') → align ∣ a ∧ 0 < a ∧ a + sz ≤ st.lastAddress ∧ st'.lastAddress = a`.
- **Axioms** (`lake env lean` scratch, all four): `CerbMem.allocator_active_sound`, `CerbMem.allocator_below_request_kills`, `FuelExemplar.allocator_errno`, `FuelExemplar.exemplar_certified_shipped_forall` each `depends on axioms: [propext, Classical.choice, Quot.sound]`.
- **Kernel replay:** rc=0 on `CerbMemAllocatorProofs Unit.FuelExemplar` (P2-2 is about the record, not the content).
- **Witness script:** real run `check_item_g_refusals: OK (16 cases: …)` rc 0 in 16 s, final line byte-equal to the record's quoted line; `--selftest` rc 0 in 35 s with `answer 14`, `lean-answer 16`, `refuse-all 9`, `lean-no-abort 10`, `lean-other-text 7` as pre-derived. The plants cover an answering engine (both/Lean-only), a refuse-everything pair (caught by the controls), a message without death, and an altered text; the control set includes realloc, an OOB-but-non-overlapping UB, each lane alignment 1/2/4/8/16 via `aligned_alloc`/`malloc`/`create`, the size-clause DUMMY UB and the zero-alignment crash on both engines. Fail-closed on missing binaries or runtime; `set -uo pipefail`.
- **Retired rows:** `scripts/exec_coverage_baseline.txt` row + header count 27 → 26, `tests/libc_exec/baseline.txt` row, both files `git rm`'d. `git grep` finds no other baseline, fixture manifest or lane referencing either file; `scripts/upstream_oracle_differences.json` has no row for them; `tests/z2-probes/` is not a lane (README keeps the historical AGREE; record §7 says so). Dated records left as history, as stated. The pristine lane (`tier-b` corpora include `coverage` and `libc_exec`) walks neither now that both are deleted.
- **Failure-reach register:** both sites classified `monadic_ascribed` / `NDkilled_Error0_loc` by `failure_census.py` (enclosing declarations typed at `memM`); the gate covers the pure group only; no row needed.
- **Fork-drift manifest:** `sha256sum memory/concrete/impl_mem.ml` = `65f601377cff…2566c`, matches the re-pinned `[source-content]` row; dated NOTE present; no generated/.lem/std.core change.
- **Hand-written ↔ generated sync:** `CerbMem.lean`, `CerbMemAllocatorProofs.lean`, `CerbFail.lean` byte-identical to their `generated/` copies (the built binary is from the reviewed text).
- **libc `memmove`:** `runtime/libc/src/string.c:22` dispatches to `memcpy` only when the regions do not overlap (musl shape); overlapping `memmove` uses its own loops — unaffected by G1.
- **Docs and provenance:** CONTRACT §3 row + D10, §3 refused-parts sentence, §4.1 witness list; VALIDATION §3(c), inventory, gate table; SUPPORTED Domain row; LADDER row 1; test_unit.sh wiring (`--selftest`); tray INDEX and drafts 56/57 "Fork-ahead refusal" paragraphs (status Draft, correctly not presented as upstream fixes). `[USER]` appears only for the two rulings; everything else is `[AGENT]`; the commit message and docs paraphrase, no quoted user text found. Quoted machine outputs the reviewer could reproduce (witness OK line, refusal texts and addresses) match.
