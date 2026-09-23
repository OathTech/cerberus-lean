# Design note — the run's minting digest as run-state data (for cerberus-sl's review)

**Status:** PROPOSAL [AGENT 2026-09-20], written for cerberus-sl's review before it is chartered; the operator relays it. It replaces the digest half ("route D-A", `declare {lean} reader val digest`) of `2026-09-18_program-data-parameters-design-note.md` §3.2, which the E-A Phase 1 build found structurally blocked (§1 below). It is the shape cerberus-sl itself asked for in `cerberus-sl/docs/2026-09-18_hidden-state-upstream-note.md` item 1 ("carry the digest as DATA: a `sym_digest : string` field of `core_run_state`, seeded by `initial_core_run_state_given`/`initial_driver_state` from the pipeline's TU digest; `fresh_given_int (d : String) (n : Nat)`"), made exact against the model at mainline `5407597d9`. One point needs their decision (§5): the program's digest must be the RUN's seeded digest, not the digest of `main`'s symbol.

## 0. What you need, in your words, and what this delivers

Your interface disclosure 22 (`docs/INTERFACE.md`) names two assumed model properties standing between your conditional theorems and the pinned semantics, and says v1 requires both discharged. This note is about the second: `MintDigestC P` — `MintDigest P := ∀ m, symDigest (fresh_given_int m) = P.digest` — whose only instance today is `Spikes.T11Guard.mintDigest_pin_t11`, a `sorry`, because on the pin `CerberusFresh.digest : Unit → String` is an opaque whose kernel witness is `fun _ => ""` (so the checked model makes every minted digest the library's — the property is not merely unprovable, the checked model contradicts it; your P-call-F note §2.1). Your decision C3.27 rejected the digest-free proof route for the two proxies on principle and chose to wait for "the digest threaded as data".

After this design, `fresh_given_int` takes the digest as its first argument and the run state carries the digest it was seeded with; `MintDigest` becomes `∀ m, symDigest (fresh_given_int P.digest m) = P.digest`, true by `rfl`. Nothing in the run reads a hidden digest any more. (The frontend's own minting during desugaring and elaboration keeps its ambient read — §3.6 — which no consumer theorem touches.)

## 1. Why the reader route failed, in one paragraph

The program-data-parameters arc's first plan made the digest a lem READER (`declare {lean} reader val digest`), like `tagDefs` and, since E-A, `enum_definitions`. The backend's rule is that every lifted function takes ALL declared readers. Declaring the digest a reader lifts `Symbol.fresh*` (`symbol.lem:247-281`), so those functions would have to bind the enum map (`Fmap sym integerType`) and the tag table (`Fmap sym (Loc × tag_definition)`), whose types live in modules DOWNSTREAM of `Symbol` (`ctype.lem` imports `Symbol`; `symbol.lem` imports neither `Ctype` nor `IntegerType`). Lem fails with `LEM internal error: lookup_mod_descr failed to find module 'IntegerType'`; in Lean it would be an import cycle. No module reordering fixes it — the enum map's type mentions `sym`. The E-A record §3.1 has the evidence. Per-function reader subsets would fix it at the price of a lem-lean redesign; this note does not need them.

## 2. The property, stated as the model will provide it

- **Run minting.** `Core_run.fresh_symbol'` (`core_run.lem:115-119`) is the ONE run-time minting site on the Lean target (the generated `Core_run.lean:123-127`; `fresh_given_int`'s only generated caller). It reads the counter `run_st.sym_supply` and will read the digest `run_st.sym_digest` beside it: `(Symbol.fresh_given_int run_st.sym_digest n, <| run_st with sym_supply = n+1 |>)`.
- **Kernel term.** `fresh_given_int d n = Symbol d n SD_None` — a plain definition with no hidden read, `rfl`.
- **The seed.** `initial_driver_state` takes the digest as an explicit entry parameter beside the address-space top (the shape of `2026-09-17_charter-address-space-bound-part-two.md` route A, which the operator approved), and the run state's `sym_digest` is that value. So `symDigest (fresh_given_int P.digest m) = P.digest` by `rfl`, where `P.digest` is the value the entry received (§5).

## 3. The design, exactly (at mainline `5407597d9`)

### 3.1 `symbol.lem`
```
val fresh_given_int: digest -> nat -> sym
let fresh_given_int d n = Symbol d n SD_None
```
(today `:276-278`: `let fresh_given_int n = Symbol (digest()) n SD_None`). `fresh`, `fresh_pretty`, `fresh_cn`, `fresh_pretty_with_id`, `fresh_object_address` (`:247-262, 280-281`) are UNCHANGED — frontend minting, §3.6.

### 3.2 `core_run_aux.lem`
`core_run_state` (`:249` region) gains `sym_digest : Symbol.digest;` beside `sym_supply : nat;`. The constructors (`:271-300`):
```
val initial_core_run_state_given: nat -> Symbol.digest -> map … -> core_run_state
let initial_core_run_state_given sup dg xs = <| …; sym_supply= sup; sym_digest= dg; labeled= xs |>
let initial_core_run_state dg xs = initial_core_run_state_given (Symbol.fresh_int ()) dg xs
```
(OCaml rep of `initial_core_run_state`: `ocaml_frontend/fork_renumber.ml` mirrors the record with `sym_supply = 0`; it gains `sym_digest = Cerb_fresh.digest ()` — the value the global holds at run init, which is what OCaml's minting reads anyway — a documented mirror, byte-identical behaviour.)

### 3.3 `core_run.lem`
```
let fresh_symbol' = State.modify (fun run_st ->
  let n = run_st.sym_supply in
  (Symbol.fresh_given_int run_st.sym_digest n, <| run_st with sym_supply= n+1 |>))
```
OCaml rep `Fork_renumber.fresh_symbol'` (`fork_renumber.ml:49`: `(Symbol.fresh (), run_st)`) UNCHANGED: upstream mints run symbols ambiently from the global; the value equals `run_st.sym_digest` by construction (§3.5), so the differential lanes do not move.

### 3.4 `driver.lem`
```
let initial_driver_state_with address_space_top run_st file fs_state = …          (* unchanged *)
let initial_driver_state address_space_top digest file fs_state =
  initial_driver_state_with address_space_top (Core_run.initial_core_run_state digest (Caux.collect_labeled_continuations_NEW file)) file fs_state
let initial_driver_state_given sup address_space_top digest file fs_state =
  ( initial_driver_state_with address_space_top (Core_run.initial_core_run_state_given sup digest (…)) file fs_state, sup+1 )
```
(today `:1520-1544`). Parameter order: the address-space top stays the first explicit parameter (its slice's rule), the digest second, then `file`, `fs_state`. On the Lean target the supply binder the backend inserts stays ahead: `initial_driver_state (sup : Nat) (address_space_top : Int) (digest : String) (file) (fs_state) : driver_state × Nat`.

Callers: OCaml `backend/common/driver_ocaml.ml:169,210` pass `(Cerb_fresh.digest ())` (the global at that point, selected by the actual input path — §3.5), `backend/web/instance.ml:638` and `backend/ocaml/runtime/rt_ocaml.ml:360` likewise (compiler-forced, dead-equal); `mini_pipeline.lem`'s const-expr mini-run (`initial_driver_state_given`) passes the desugarer's current digest (`Symbol.digest ()` — the same TU's). Lean `Main.lean:1025` passes `runDigest`, `CerbCall.driveCall` the same value; `CerbCall.lean:156`'s `PrefFunArg callLoc (CerberusFresh.digest ()) n` takes it too (a prefix, not an identity — for uniformity).

### 3.5 Which digest the run receives — entry-specific rules
[AGENT 2026-09-22, audit D1 correction] In Lean's Cabs execution pipeline,
**the run's digest is the LAST program Cabs TU's digest**, in `tunits` order
(`cerberus a.c b.c` → `Digest.file "b.c"`). `runDigest` returns `""` for an
empty Cabs list; library and metadata units do not select this value. This is
an entry rule for this pipeline, not a rule for every possible input path.
Lean's `--parse-core` parses and prints Core text; it does not execute it.

OCaml passes the current global at its entry. Both the C frontend and the
Core-text frontend set it: `backend/driver/main.ml:26–32` sends `.core` to
`core_frontend`, whose first action is `Cerb_fresh.set_digest filename`
(`backend/common/pipeline.ml:279–280`). Thus `p.core` supplies its own file
digest, and Core text processed after C replaces the C input's digest.
`.co`/`.o` use `read_core_object` (`pipeline.ml:668`), which preserves the
current global; that value is empty only when nothing has previously set it.
The setter uses `Digest.file filename` (`util/cerb_fresh.ml:88–95`).

The original statement that `.co` and `.core` both set nothing was wrong.
The S0 record §3's OCaml inventory already distinguishes them; its erratum
clarifies the domain of the shared Cabs rule. Consumers must carry the actual
entry digest for other entry paths, never infer it from the absence of Cabs TUs.
The implementation stays unchanged: `runDigest` selects the last Cabs digest
or `""`, and OCaml passes its global. The reviewed differential lanes retain
the same values.

### 3.6 What does NOT change
- Frontend minting (`Symbol.fresh*` during desugaring/elaboration) keeps the ambient `digest()`; `CerberusFresh.digest`/`setDigestIO`/`forceIO` stay for that phase; the effect-erasure page stays open for that one seam. No consumer theorem mentions frontend minting (your proofs quantify over the captured `file`).
- `CoreParser.mkSym`'s `""` digest for the quoted library (`CoreParser.lean:242-243`) — your item 6's premise — is untouched: for a nonempty list of validated Cabs inputs, the selected digest is a 32-hex-digit MD5, and the committed fixture pins one such entry. Library-symbol freshness still requires the per-program hypothesis `symFresh_of_digest`'s `hP : P.digest ≠ ""`; arbitrary entry arguments and `runDigest []` need not satisfy it.
- The reader machinery, the enum map (E-A), the OCaml oracle's behaviour, every baseline.

## 4. Consumer-visible surface (your re-pin)

| Today | After |
|---|---|
| `fresh_given_int (n : Nat) : sym` | `fresh_given_int (d : String) (n : Nat) : sym` |
| `core_run_state` | `+ sym_digest : String` (every full `core_run_state` literal gains it; `{ rs with … }` updates unchanged) |
| `initial_core_run_state_given (sup) (xs)` | `initial_core_run_state_given (sup) (digest) (xs)` |
| `initial_driver_state (sup) (top) (file) (fs)` | `initial_driver_state (sup) (top) (digest) (file) (fs)` |
| `initial_driver_state_given (sup) (top) (file) (fs)` | `… (sup) (top) (digest) (file) (fs)` |
| `MintDigest P` unprovable (`mintDigest_pin_t11` sorry) | `∀ m, symDigest (fresh_given_int P.digest m) = P.digest := fun _ => rfl` |

Your `Lang.lean:69-79` prose ("the driver seeds `sym_supply` from … `initial_driver_state`") and `SymFresh.lean:7-8` ("`fresh_given_int m = Symbol (CerberusFresh.digest ()) m SD_None`") change wording; `HeapNeg.lean:34,135` ("the fresh digest … stays opaque") becomes false in the good direction. The `Neg0` rewrite's minted symbol (`HeadStep.neg_rewrite`) is `fresh_given_int rs.sym_digest rs.sym_supply` in the engine's own terms. If E-A (the enum reader, +1 leading argument `enum_definitions` before `tagDefs` on every reader-taking signature) and this land together, one re-pin covers both.

## 5. The point for your decision — the program's digest is the run's, not `main`'s

`SymFresh.lean:65-68` defines `Program.digest P := symDigest s` for `P.file.main = some s`, "the translation unit's digest, which the frontend stamped on every symbol of the unit (`main` included)". That is the right value for a SINGLE-unit program. For a multi-unit program it is the digest of the unit that DEFINES `main`, while the engine mints with the digest of the LAST unit processed (§3.5) — equal only when `main`'s unit is last. For `cerberus main.c helper.c`, `MintDigest P` as defined through `main` would be FALSE of the engine (both engines mint with `helper.c`'s digest).

Proposal: `Program` carries the run digest as DATA, the same value the driver entry receives — `progOf (F : file Unit) (supply : Nat) (digest : String)` or a field `digest : String` — and `P.digest` is that field; `MintDigest P` then holds by `rfl` for every program the driver can run, single- or multi-unit. Your freshness discipline stays as stated in C3.27 ("a symbol is fresh iff its digest differs from the program's or its number is below the supply"): program symbols from OTHER units differ from the run digest and are fresh by digest; program symbols from the LAST unit share it and are fresh by number (below the supply — `initial_driver_state` seeds `sym_supply` from the frontend's final supply, unchanged); library symbols have `""` and are fresh by digest as long as the run digest is not `""` (§3.6). Nothing you prove today about single-unit programs changes; the definition change is what makes the multi-unit statement true.

If you would rather keep `Program.digest` read off `main`, the alternative is for the engine to mint with `main`'s unit's digest — a semantics change against upstream (which mints with the global's last value) and therefore out of policy for us; we would not do that.

## 6. Verification we would ship with it

- Zero movement on every Tier A/B lane, the pristine-oracle lane included (`test_upstream_oracle.py`, 855 + the seven E-A cases): the digest VALUE every minted symbol carries is unchanged on both engines; only its provenance moves. Any movement is a finding, never a re-baseline.
- Kernel tests: `fresh_given_int d n = Symbol d n SD_None := rfl`; `MintDigest`-shaped `∀ m, symDigest (fresh_given_int d m) = d := rfl` on the generated definition; the entry pin `runDigest tunits = (tunits.getLast h).1` and the shape pin (32 lowercase hex digits, `≠ ""`) on a committed cabs-json fixture; the multi-unit lane (`tests/multi_tu`, sorted-name order both sides) as the differential witness that the LAST unit's digest is the one both engines mint with.
- Registers: the fork-drift manifest's layer-2 rows for the generated `symbol.ml`, `core_run.ml`, `core_run_aux.ml`, `driver.ml`, `mini_pipeline.ml` move (single-row edits + NOTE); layer 1 gains nothing new if `driver_ocaml.ml`/`instance.ml`/`rt_ocaml.ml` are already on the fork's surface (to confirm at chartering); `scripts/unsafebaseio_allowlist.txt` unchanged (the frontend digest seam's rows stay); the effect-erasure page's digest paragraph narrows to "frontend minting only".
- Size [AGENT estimate]: lem 4 files (~20 lines), OCaml 4 call sites + the `fork_renumber.ml` mirror record (~6 lines), Lean `Main.lean`/`CerbCall.lean` (~15 lines) + tests; one slice, one record; after E-A lands.

## 7. Questions for cerberus-sl

1. §5: do you accept `Program.digest` as carried data seeded from the entry (field or `progOf` argument — your preference)?
2. Do you want the definitional `MintDigest` theorem exported from cerberus-lean (a named theorem in a hand-written module next to the generated `Symbol`), or will you state it yourselves from the definition? Either is fine for us; the former gives you a stable name across re-pins.
3. Is there any theorem in your tree that uses `Program.digest` for a PROGRAM symbol's digest (rather than the run's)? `symFresh_of_digest_ne` (`SymFresh.lean:89`) is consistent with §5 (a symbol whose digest differs from the RUN digest is never minted); we found no other use, but you know your tree.
4. Timing: after the enum half (E-A) is audited and landed, as one re-pin for both (+1 reader argument; +1 entry argument, +1 `fresh_given_int` argument, +1 run-state field), or two separate re-pins?
5. Item 7 of your note (`SelectAgreesC`, the matcher's arity behaviour) is the other v1 blocker on our side; it is not part of this note and is queued behind this arc unless you rank it ahead.
