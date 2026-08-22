# Arc-14 merge checklist — SKELETON (finalize after S4)

Status: DRAFT. Heads and gate results below are as of the S3 boundary;
S4 (the re-mark) may add a fix-or-record batch that moves them. Every
`[ ]` is checked at execution time; merges are ff-only, operator-gated,
with the unconditional pre-merge audit ask.

## Heads at S3 (to re-confirm after S4)

- LEM `arc/immaculate` @ `3ddcafb` (B1 553df2a → B5 3ddcafb; 6 commits).
- CERB `arc/immaculate` @ <S3 docs commit — fill> (S0 677551e76 → …).
- Lake pins (lean_frontend + relsem): `3ddcafb`. opam lem still
  `11d4b4c` (worktree-lem regeneration discipline in force until step 3).

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

- [ ] S4 re-mark GRADE reported to the operator VERBATIM (charter
  success condition 2) + the re-mark's fix-or-record batch folded in.
- [ ] Standing-rules promotions folded into the container playbook at
  merge (results doc §6): cache-disabled build-rule validation;
  audit-plant rebuild-after-revert; (candidate) bars-are-exclusive.
- [ ] Upstream tray: filings 10 + 11 in `notes/upstream/` + INDEX —
  operator filing window (network + GitHub; re-verify against current
  master first, per the tray checklist).
- [ ] be:G2 regen leg: when ott is installable (network window),
  run `language/Makefile`'s rule, byte-compare ast.ml, resolve
  grammar-first (the two pre-registered shape divergences), re-gate.
- [ ] Residual register (28 entries, results doc §2) carried into the
  next planning surface; no GRAVE remainder is unregistered.
- [ ] Docs de-staled this arc: lean_frontend/CLAUDE.md (seam rows, lem
  mechanisms incl. the priority lattice + Set coherence + St module,
  arc-14 status line); the lane's wording (D3 NIT) — verify no other
  doc still describes pre-arc-14 seam behavior.
