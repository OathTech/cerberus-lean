# Draft — OCaml target: `=` on a user-defined type that contains a set or map raises `Invalid_argument "compare: functional value"`

Target: `rems-project/lem` (OCaml backend / `ocaml-lib`). Drafted
2026-09-03; NOT filed — filing is the operator's call (network +
GitHub). Classification: **KNOWN LIMITATION / question** — a
representation artefact of the OCaml target that makes Lem's default
equality fail at run time where Lem's own semantics (and its
theorem-prover targets) define a value. Whether the Lem authors treat
it as a bug to fix or a limitation to document is their call; we
report it because a Lem user can hit it without warning.

Cited against upstream `lem` `master` @ `3802cb0` (2026-05-13, the
merge base of our fork; `ocaml-lib/pset.ml` and `ocaml-lib/pmap.ml`
are byte-identical to it in our tree).

## Mechanism

- Lem's default equality is OCaml's structural `=`: the `Eq` class's
  `default_instance` is `unsafe_structural_equality`
  (`library/basic_classes.lem:70-71`), whose OCaml representation is
  `infix =` (`:58`). Any user-defined record or variant type without
  its own `Eq` instance gets this default. (Lists, `maybe`, `either`,
  `map`, and tuples up to arity 6 have compositional instances, so they
  are not affected by themselves.)
- On the OCaml target a Lem `set 'a` is `Pset.set`, a record carrying
  its comparator closure: `type 'a set = { cmp : 'a -> 'a -> int; s : 'a
  rep }` (`ocaml-lib/pset.ml:299`); a `map` likewise: `type ('key,'a)
  map = {cmp : 'key -> 'key -> int; m : ('key,'a) rep}`
  (`ocaml-lib/pmap.ml:280`).
- OCaml's structural `=`/`compare` raise `Invalid_argument "compare:
  functional value"` when they reach a closure (`compare` on physically
  identical closures excepted). So `=` on any record or variant that
  contains a set or map field raises, at run time, on the OCaml target.
- Lem's own set equality does not have this problem: `setEqual` is
  represented as the comparator-keyed `Pset.equal`
  (`library/set.lem:54`; `pset.ml:325`), and `instance Eq (set 'a)` uses
  it (`set.lem:57`). Only the *default* structural equality on a
  containing type reaches the closure. Lem's mathematical semantics — as
  realised by the HOL, Isabelle and Coq targets — defines equality on
  such a type; the OCaml target is the deviant.

## Reproducer (Lem)

```lem
open import Pervasives

type config = <| label : nat; members : set nat |>

let c1 : config = <| label = 1; members = {1; 2; 3} |>
let c2 : config = <| label = 1; members = {3; 2; 1} |>

(* Lem semantics: true (same label; equal sets).
   OCaml target: `label` compares equal, then the comparison reaches
   `members`, a Pset.set record whose first field is the comparator
   closure, and raises Invalid_argument "compare: functional value". *)
let same : bool = (c1 = c2)

(* Even reflexive equality raises on the OCaml target. *)
let refl : bool = (c1 = c1)

(* The comparator-keyed equality on the set field itself works. *)
let members_same : bool = (c1.members = c2.members)
```

Expected per Lem's semantics: `same = true`, `refl = true`,
`members_same = true`.

## Verbatim output — TO BE RUN BEFORE FILING

Not executed in the slice that drafted this report. Expected on the
OCaml target: the module's initialisation raises
`Invalid_argument "compare: functional value"` at `same` (or `refl`);
`members_same` alone evaluates to `true`. Run with the upstream `lem
-ocaml` and a small driver, paste the exact exception text here, and
record the OCaml version.

## Impact

Any Lem specification that puts a set or map inside a record or
variant and compares such values with `=` (directly, or via a
derived comparison on a containing type) compiles cleanly and then
fails at run time on the OCaml target only. Nothing at generation time
warns about it. The theorem-prover targets — and our Lean target, whose
`BEq`/`Ord` instances for sets compare the ordered element spines —
compute the value Lem's semantics gives.

## Possible remedies (for the Lem authors to choose among)

1. Document it: a note at `unsafe_structural_equality` / in the OCaml
   backend section of the manual that structural `=` is undefined for
   values containing sets or maps, with `setEqual`/`mapEqual` (or a
   per-type `Eq` instance) as the recommended form.
2. Derive `Eq`/`Ord` instances for user record and variant types on the
   OCaml target from their components (so the set field is compared by
   `Pset.equal`), instead of falling back to polymorphic `=`.
3. Make the OCaml representation closure-free (a comparator registry or
   a comparison-free canonical representation) so polymorphic compare
   works; the largest change.

## Provenance

Found by reading during our fork's OCaml-vs-Lean parity audit of the
Lem library (lem-lean `doc/lean-backend/2026-09-03_parity-fix-record.md`
§2 row X1; ruling `doc/lean-backend/2026-09-03_exception-case-rulings.md`
§2 X1: "an OCaml-backend deviation from lem's own semantics; the Lean
target follows lem (prover-side)"). Found and analysed by an AI agent
(Claude) under human direction; the reproducer above is unexecuted as
noted. Per this tray's labeling policy, the filed issue body must carry
an explicit AI-provenance note.
