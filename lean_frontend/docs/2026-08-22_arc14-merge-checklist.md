# Arc-14 merge checklist — FINAL (S4b complete; the arc PARKS at the merge ask)

Status: READY FOR THE ASK. Merges are ff-only, operator-gated, with the
unconditional pre-merge audit ask. The arc is PARKED here — no merge
action without the operator's explicit per-merge sign-off.

## Final heads (S4b completion batch)

- LEM `arc/immaculate` @ `861ed81` (9 commits: B1 553df2a … B5 3ddcafb,
  the re-mark basket 3cb656f, RG5 28d592d, RG1-RG4 861ed81 — the lem
  branch MOVED TWICE after the S2 close; the dance below re-pins to the
  final MERGED head).
- CERB `arc/immaculate` @ <the S4b completion commit — the commit
  carrying this file's finalization>.
- Lake pins (lean_frontend + relsem): `861ed81`. opam lem still
  `11d4b4c` (worktree-lem regeneration discipline in force until step 3).
- Re-grades on record: semantics A−, backend B+ (results doc §7).
- PROTECTED: the workbench-v2 worktree is NOT part of this arc — do not
  touch it during the dance (standing reminder from the S0 work order).

## The dance (order is normative: lem first)

1. [ ] **Pre-merge audit ask** (unconditional): propose scope + scale to
   the operator; execute the agreed audits; findings dispositioned.
2. [ ] **lem merge:** `git -C lem-lean merge --ff-only <arc head>` into
   `mdd/lean-backend` (rebase + re-gate + re-ask if the mainline moved).
3. [ ] **opam re-pin:** `git -C deps/lem-pinned reset --hard <merged>`;
   from cerberus-lean: `opam upgrade --switch=. --no-depexts lem`
   (path form; --no-depexts per the arc-8 lesson).
4. [ ] **Lake re-pin to the MERGED lem rev** in BOTH manifests —
   `lean_frontend/lakefile.toml` + `lake update LemLib`, AND
   `lean_frontend/relsem/` (`lake update LemLib`; the B3 lesson: relsem
   is a second pin surface).
5. [ ] **Full regeneration under the opam lem** (now = merged head):
   `make clean-prelude-src prelude-src` (stamp re-records),
   `make clean-lean lean-prelude-src lean-native-obj`, capped builds
   (lean_frontend + relsem). Byte-compare the lean generation against
   the arc tree (expect identical — same lem content).
6. [ ] **The full gate at the merged pins:** Tier A 12/12 + Tier B 3/3 +
   `scripts/test_immaculate.sh` (the arc's new standing lane) green;
   zero movement vs the arc-close baselines.
7. [ ] **cerberus merge:** ff-only into `mdd/cerberus-lean`.
8. [ ] **Close condition:** branch heads = opam pin = Lake pins (all
   three surfaces), gates green on the mainlines.

## Arc-specific riders

- [x] S4 re-mark grades reported verbatim (B+/B+ → A−/B+-held after
  the baskets; results doc §7 + decision log D4/D5) + both fix
  batches folded in (the A− baskets, the S4b completion batch).
- [ ] Standing-rules promotions folded into the container playbook at
  merge (results doc §6): cache-disabled build-rule validation;
  audit-plant rebuild-after-revert; (candidate) bars-are-exclusive.
- [ ] Upstream tray: filings 10-13 in `notes/upstream/` + INDEX —
  operator filing window (network + GitHub; re-verify against current
  master first, per the tray checklist).
- [ ] be:G2 regen leg: when ott is installable (network window),
  run `language/Makefile`'s rule, byte-compare ast.ml, resolve
  grammar-first (the two pre-registered shape divergences), re-gate.
- [ ] Residual register (results doc §2: 24 residuals + the S4b
  REGISTERED-LATER block) carried into the next planning surface; no
  GRAVE remainder is unregistered.
- [ ] Docs de-staled this arc: lean_frontend/CLAUDE.md (seam rows, lem
  mechanisms incl. the priority lattice + Set coherence + St module,
  arc-14 status line); the lane's wording (D3 NIT) — verify no other
  doc still describes pre-arc-14 seam behavior.
