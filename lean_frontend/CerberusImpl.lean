import CerbStopSites
/-
  Hand-written Lean implementations for Cerberus implementation-defined behaviour.
  Corresponds to: ocaml_frontend/ocaml_implementation.ml (DefaultImpl module).
  No process state: the enum's compatible type is program data (an ambient reader of
  the lem model, see below); every function here is a function of its arguments.

  These functions are referenced by `declare lean target_rep` in implementation.lem
  and work with the Lem-generated types from IntegerType.lean and Ctype.lean.

  ABI: LP64 (x86_64-apple-darwin), matching Cerberus DefaultImpl.
-/

import IntegerType
import Ctype
import CerbTagsWf

namespace CerberusImpl

/-! ## Target Configuration -/

/-- Maximum alignment in bytes (LP64).
    Corresponds to: DefaultImpl.max_alignment in ocaml_implementation.ml:151-152 -/
def max_alignment : Nat := 8

/-- DefaultImpl.sizeof_pointer / alignof_pointer — ocaml_implementation.ml:
    117-121 `Some 8` (the record fields impl_mem.ml reads at :153-158,
    :219-225, :1160-1164, :2134; zero-discrepancy literal census #2 — CerbMem
    reads these instead of its own literal). -/
def sizeof_pointer : Option Nat := some 8
def alignof_pointer : Option Nat := some 8

/-! ## Integer Type Properties -/

/-! ## The enum's compatible type is PROGRAM DATA (program-data parameters E-A, 2026-09-20;
    `docs/2026-09-20_program-data-parameters-EA-DA-record.md`)

The OCaml keeps DefaultImpl's mutable `registered_enums` (ocaml_implementation.ml:
124-150: `register_enum` decides GCC's rule and pushes, `typeof_enum` looks it up
and fails on an unregistered tag); the Lean side has NO registry and no
effect-erased read any more: the map from enum tag to its compatible integer
type is an ambient READER of the lem model (`declare {lean} reader val
enum_definitions`, implementation.lem) — the desugarer records the decided
type in `A.sigma.enum_definitions`, the elaborator carries it into the Core
file's `enumDefs`, linking merges it, and the entries pass the map wherever
the generated code takes `_lemReader_enum_definitions`. The lem-side layout
vals (`Implementation.sizeof_ity` etc.) are SHARED wrappers that normalise
FIRST through the one reader consumer `Implementation.normalise_integerType`
(its rep `normalise_integerType` below) and then call the type-only reps
below on the normalised type; the hand-written memory model receives the map
through its `reader_consumer` stubs (CerbMem) and resolves an `Enum` exactly
where impl_mem.ml resolves it through the registry. Keys compare by
`symbolEquality` (digest + number, description-insensitive — the
`Symbol.symbol_compare` parity of ocaml_implementation.ml:137,145). -/

/-- The enum map: tag ↦ its compatible integer type (the value of the lem reader
    `Implementation.enum_definitions`; the same information the OCaml registry
    holds, as data). -/
abbrev EnumDefs := Fmap sym integerType

/-- Fail-closed stub backing implementation.lem's `enum_definitions` target-coverage
    rep. The reader mechanism rewrites every applied `enum_definitions ()` site to the
    `_lemReader_enum_definitions` parameter, so this constant is never emitted at an
    applied call site; if it ever runs, that is a reader-lifting defect — fail loudly
    (the CerbTags.tagDefsUnreachable shape; `failwithI`, seam hygiene 2026-09-19). -/
def enumDefinitionsUnreachable (_ : Unit) : EnumDefs :=
  failwithI (CerbStop.render (.invariant (CerbStopSites.enumReader "CerberusImpl.enumDefinitionsUnreachable: applied enum_definitions () site survived reader lifting")))

/-- The named lookup — `Ocaml_implementation.typeof_enum` (ocaml_implementation.ml:
    144-150) over the map instead of the registry: the registered compatible type,
    or the oracle's `failwith` text on an unregistered tag (REACHABLE on a Core-text
    input naming an enum tag no C source declared — the .core path's map is empty, as
    the oracle's registry is there). -/
def lookupEnum (enumDefs : EnumDefs) (tag_sym : sym) : integerType :=
  -- the spine scan with `symbolEquality` (digest + number, description-insensitive) —
  -- the same lookup shape as the tag lookups (CerbTagsWf.lookupEntry) and the
  -- `Symbol.symbol_compare` parity of the OCaml registry (ocaml_implementation.ml:145)
  match (fmapElements enumDefs).find? (fun (k, _) => symbolEquality k tag_sym) with
  | some (_, ity) => ity
  | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.enumMissing s!"Ocaml_implementation.typeof_enum: '{show_symbol tag_sym}' was not registered")))

/-- Resolve an `Enum` through the map and leave every other type as it is — the
    `match ity with Enum tag_sym -> typeof_enum tag_sym | _ -> ity` step the OCaml
    layout functions perform before their own match (ocaml_implementation.ml:80-85,
    :56-57; impl_mem.ml:2369-2372, :2407-2410). -/
def resolveEnum (enumDefs : EnumDefs) : integerType → integerType
  | .Enum0 tag_sym => lookupEnum enumDefs tag_sym
  | ity => ity

/-- register_enum — the Lean rep of `Implementation.register_enum`: the pure `true`.
    The OCaml rep still writes DefaultImpl's registry (ocaml_implementation.ml:129-142)
    and answers `false` on a duplicate tag; on Lean the compatible type is recorded in
    the sigma by the desugarer instead, and the duplicate case is caught by the
    `Map.member tag_sym st.tag_definitions` check just before this call
    (cabs_to_ail_effect.lem register_tag_definition) — so both engines take the same
    branch and this value is never consulted. -/
def register_enum (_ : sym) (_ : List Int) : Bool := true

/-! ## Integer Type Properties -/

/-- Whether an integer type is signed.
    Corresponds to: Common.is_signed_ity in ocaml_implementation.ml:79-107,
    instantiated with ~typeof_enum ~char_is_signed:true as DefaultImpl does
    (ocaml_implementation.ml:257). OCaml first resolves Enum through
    typeof_enum, then matches; on Lean the resolution happens BEFORE this
    function — the lem wrapper `Implementation.is_signed_ity` resolves ONLY an
    enum through the reader (`Implementation.resolve_enum`, the OCaml's own
    shape; NOT the alias table — audit E4: `Signed (IntN_t 128)` is `true` on
    both engines), CerbMem resolves through `resolveEnum` — so the `Enum` arm
    here is the OCaml's `assert false`: unreachable by construction, a loud
    leaf. -/
def is_signed_ity (ity : integerType) : Bool :=
  match ity with
  | .Char0 => true      -- char_is_signed = true for DefaultImpl
  | .Bool0 => false
  | .Signed _ => true
  | .Unsigned _ => false
  | .Enum0 _ => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.signedEnum "assert false: Common.is_signed_ity reached an un-normalised Enum (ocaml_implementation.ml:95-96; the callers resolve it first)")))
  | .Size_t => false    -- STD §7.19#2
  | .Wchar_t => true
  | .Wint_t => true
  | .Ptrdiff_t => true  -- STD §7.19#2
  | .Ptraddr_t => false

/-! ## Type normalisation — the alias table and `normalise_integerType_`

    DefaultImpl's `type_alias_map` (ocaml_implementation.ml:154-171): the
    three N-families alias through ONE function `n_t_aliases` (8 → Ichar,
    16 → Short, 32 → Int_, 64 → Long, `_ → None`); `Intmax_t`/`Intptr_t` →
    Long; `wchar_t`/`wint_t` → Signed Int_; `size_t` → Unsigned Long;
    `ptrdiff_t` → Signed Long. `Common.normalise_integerType_` (:37-66)
    applies `Option.get` to the N-family lookups (:39-44), so a width
    outside {8, 16, 32, 64} — `__cerbty_int128_t`, builtins.lem:19/53 —
    is an uncaught `Invalid_argument "option is None"` on the oracle,
    mirrored as a fail-stop (zero-discrepancy Z2-I-03, ruling Q4).
    Zero-discrepancy Z2-I-01: the previous `normalise_integerType` had NO
    `Signed/Unsigned (IntN_t | Int_leastN_t | Int_fastN_t | Intmax_t |
    Intptr_t)` aliasing, so ailTypesAux.lem:302-303's `(Signed (IntN_t _),
    _) -> fail ()` arms — "inaccessible because of the normalisation" on
    the oracle — were reachable on Lean through the DIRECT `__cerbty_intN_t`
    spellings (the shared <stdint.h> typedefs int32_t as plain `signed
    int`, so ordinary C never produced IntN_t): pin
    tests/immaculate/nolibc/zd-z2i01-cerbty-int32-uac.c. Z2-I-02: the
    previous `.Ptraddr_t => .Unsigned .Long` arm computed where the
    OCaml's `| ity -> ity` (:65-66) keeps Ptraddr_t (and the shared model
    then errors "WIP … Ptraddr_t") — mirrored. -/

/-- `n_t_aliases` — ocaml_implementation.ml:155-160. -/
def n_t_aliases : Nat → Option integerBaseType
  | 8 => some .Ichar
  | 16 => some .Short
  | 32 => some .Int_
  | 64 => some .Long
  | _ => none

/-- `aux_ibty` of `Common.normalise_integerType_` — ocaml_implementation.ml:38-50,
    with `Option.get` (:40/:42/:44) mirrored as a fail-stop. -/
def aux_ibty : integerBaseType → integerBaseType
  | .IntN_t n | .Int_leastN_t n | .Int_fastN_t n =>
    match n_t_aliases n with
    | some ibty => ibty
    -- KIND classification left to the operator (Z2 record §10): the model
    -- WRITES `Option.get` on its own alias table (a deliberate "must be
    -- aliased" assertion, kind 1) but the missing entry is a width the
    -- implementation never defined (kind 2 shape); either reading gives no
    -- meaning to `__cerbty_int128_t` on DefaultImpl — a loud fail-stop
    | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.aliasMissing s!"DefaultImpl.type_alias_map has no alias for an N-family width of {n} (ocaml_implementation.ml:39-44, :155-160: Option.get raises on the oracle); zero-discrepancy Z2-I-03")))
  | .Intmax_t => .Long     -- :45-46, :162
  | .Intptr_t => .Long     -- :47-48, :163
  | ibty => ibty           -- :49-50

/-- The alias part of `Common.normalise_integerType_` (ocaml_implementation.ml:37-66
    instantiated with DefaultImpl's type_alias_map, :154-171): every arm but the
    Enum one. An `Enum` cannot be normalised without the program's enum map, so
    here it is the UNREACHABLE-BY-INVARIANT leaf: the type-only layout reps below
    are called on types the lem wrappers (`Implementation.sizeof_ity` etc.) have
    already normalised through `normalise_integerType`, and CerbMem resolves an
    Enum through `resolveEnum` before it reaches them. -/
def normalise_aliases : integerType → integerType
  | .Signed ibty => .Signed (aux_ibty ibty)      -- :52-53
  | .Unsigned ibty => .Unsigned (aux_ibty ibty)  -- :54-55
  | .Enum0 _ => failwithI (CerbStop.render (.invariant (CerbStopSites.normaliseEnum "CerberusImpl.normalise_aliases: an un-normalised Enum reached a type-only layout rep (Implementation.normalise_integerType / CerbMem resolveEnum normalise first — unreachable by construction)")))
  | .Wchar_t => .Signed .Int_                    -- :58-59, :164 (TODO: check — upstream's own note)
  | .Wint_t => .Signed .Int_                     -- :60-61, :165
  | .Size_t => .Unsigned .Long                   -- :62-63, :166
  | .Ptrdiff_t => .Signed .Long                  -- :64-65, :167
  | ity => ity                                   -- :65-66 (Char, Bool, Ptraddr_t)

/-- `Common.normalise_integerType_` in full, over the enum map: the Enum arm is
    the lookup (:56-57 `Enum tag_sym -> typeof_enum tag_sym`), every other arm the
    alias table. -/
def normalise_integerType_in (enumDefs : EnumDefs) : integerType → integerType
  | .Enum0 tag_sym => lookupEnum enumDefs tag_sym
  | ity => normalise_aliases ity

/-- THE reader consumer (`declare {lean} reader_consumer val normalise_integerType`,
    implementation.lem): the generated call sites pass every declared reader in the
    global sorted order — `enum_definitions`, then `tagDefs` — before the type; only
    the enum map is consulted. -/
def normalise_integerType (enumDefs : EnumDefs)
    (_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) (ity : integerType) : integerType :=
  normalise_integerType_in enumDefs ity

/-- Size of an integer type in bytes.
    Corresponds to: DefaultImpl.sizeof_ity in ocaml_implementation.ml:172-201,
    arm for arm: the type is normalised FIRST (:173), so the N-families,
    Intmax_t/Intptr_t, Enum, wchar_t/wint_t/size_t/ptrdiff_t never reach
    the match — their arms are `assert false` (:188-193, :195-200) and are
    mirrored as fail-stops (unreachable after a total normalisation). Since
    E-A (2026-09-20) the normalisation here is the ALIAS part only: an Enum is
    resolved before this function (the lem wrapper / CerbMem's resolveEnum),
    so this is a function of the type alone.
    Zero-discrepancy Z2-I-01/03: the previous per-width arithmetic
    (`(n+7)/8`, nested `if`s) computed a size for EVERY width where the
    oracle aliases four widths and crashes on the rest. -/
def sizeof_ity (ity : integerType) : Option Nat :=
  match normalise_aliases ity with
  | .Char0 | .Bool0 => some 1                                            -- :174-176
  | .Signed ibty | .Unsigned ibty =>                                     -- :177-193
    some (match ibty with
      | .Ichar => 1
      | .Short => 2
      | .Int_ => 4
      | .Long | .LongLong => 8
      | .IntN_t _ | .Int_leastN_t _ | .Int_fastN_t _ | .Intmax_t | .Intptr_t =>
        failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofBase "assert false: DefaultImpl.sizeof_ity reached an un-normalised base type (ocaml_implementation.ml:188-193)"))))
  | .Enum0 _ | .Wchar_t | .Wint_t | .Size_t | .Ptrdiff_t =>
    failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofType "assert false: DefaultImpl.sizeof_ity reached an un-normalised type (ocaml_implementation.ml:195-200)")))
  | .Ptraddr_t => some 8                                                 -- :201

/-- Precision (number of value bits) of an integer type.
    Corresponds to: Common.precision_ity in ocaml_implementation.ml -/
def precision_ity (ity : integerType) : Option Nat :=
  match sizeof_ity ity with
  | some n =>
    if is_signed_ity ity then some (8 * n - 1) else some (8 * n)
  | none => none

/-- Size of a floating type in bytes.
    Corresponds to: DefaultImpl.sizeof_fty in ocaml_implementation.ml:206-212,
    which returns 8 for ALL three real floating types — including its
    literal `(* TODO:hack ==> 4 *)` on Float and `(* TODO:hack ==> 16 *)`
    on LongDouble (OCaml's float IS 64-bit, so every floating_value is
    represented in 8 bytes; the natural 4/16 sizes are explicitly hacked
    to 8 there). We mirror the BEHAVIOR, hack included, for byte-level
    parity with the OCaml concrete memory model. -/
def sizeof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 8      -- OCaml: Some 8 (* TODO:hack ==> 4 *)
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 8  -- OCaml: Some 8 (* TODO:hack ==> 16 *)

/-- Alignment of an integer type in bytes.
    Corresponds to: DefaultImpl.alignof_ity in ocaml_implementation.ml:214-243
    — textually the same table as sizeof_ity (:172-201), normalisation
    first, `assert false` on the un-normalised arms; hence `= sizeof_ity`. -/
def alignof_ity : integerType → Option Nat
  := sizeof_ity

/-- Alignment of a floating type in bytes.
    Corresponds to: DefaultImpl.alignof_fty in ocaml_implementation.ml:247-253
    — 8 for all three real floating types, same TODO:hack comments as
    sizeof_fty (see above); behavior mirrored, hack included. -/
def alignof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 8      -- OCaml: Some 8 (* TODO:hack ==> 4 *)
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 8  -- OCaml: Some 8 (* TODO:hack ==> 16 *)

/-! ## Helper: construct ctype with empty annotations (moved here from CerbMem.lean with the
    layout block, merge-base bump stage 1, 2026-10-29) -/

def mkCtype (ty_ : ctype_) : ctype := Ctype ([] : List annot) ty_

/-! ## Layout computation — ocaml_implementation.ml:437-580 at c3ff8c53f (offsetsof / sizeof / alignof)

    MOVED here from CerbMem.lean by the merge-base bump stage 1 (2026-10-29), as
    upstream b3e11ea33 moved the three functions from impl_mem.ml:98-273 into
    ocaml_implementation.ml (the DefaultImpl module this file mirrors). Upstream
    moved the bodies verbatim apart from threading `tagDefs` through every call,
    so the per-line `impl_mem.ml:NNN` cites below still name the text at
    b9aeedcb4 that the port was written against; at c3ff8c53f: offsetsof
    :437-466, sizeof :467-520, alignof :521-580. Two things did change upstream
    with the move: the union arm of `sizeof` now reads the THREADED map (:502)
    while `alignof`'s union arm still reads the Tags global (:566); and the
    "requires a complete implementation" failures became
    `raise Missing_implementation_detail "sizeof a POINTER"` etc. (still crashes).
    The Lean worker below keeps BOTH union arms on `ambient` (the global's mirror)
    deliberately, and restating the stable proof's single potential `tp`
    (CerberusImpl_lemMeasureProofs.lean) for a per-function lookup was deferred to
    stage 2, where the Tags removal (736690a65) makes the two maps one. [AGENT
    2026-10-29] CORRECTED 2026-10-30 (pre-merge review P1/P2, record §6b): the
    claim that this is unobservable at every stage-1 call site was WRONG. It is
    observable at two sites. (i) Desugar time, `cabs_to_ail_effect.lem`
    `get_alignof` on a union-containing type (two `_Alignas` on one declaration,
    an aligned redeclaration): upstream's alignof union arm reads the Tags
    global, which is UNSET during desugaring, so the oracle crashes with
    `Failure("Tags definitions must be set by Tags.set_tagDefs before any use")`
    — where the one-map wrapper `alignof_ty` below answers from the explicit map
    (and pristine b9aeedcb4 answered through `alignof_proxy`): a Lean-answers /
    oracle-crashes divergence, registered in VALIDATION §3 pending the ruling on
    736690a65's one alignof line (`Pmap.find tag_sym tagDefs`), which makes the
    oracle answer again. (ii) Elaboration time, `offsetof` over a
    union-containing struct (`tests/immaculate/nolibc/offsetof-union-member.c`):
    both engines crash, in DIFFERENT arms — upstream in alignof's union arm via
    `offsetsof`, this worker in `sizeofCtype`'s union arm (`ambient` is the
    empty elaboration-time table) — a pinned crash pair; with the backport both
    union arms must read the threaded map here too, or the pair becomes a
    Lean-only crash (measured 2026-10-30 on a patched pristine build, record §6b).
    CLOSED at M6c ([USER] ruling, record §6c): the fork oracle carries 736690a65's
    alignof line, and `CerbMem.offsetofIval` — the one call that passed two
    different maps — passes the explicit map twice; every call of these workers
    is now one-map, exactly upstream's post-736690a65 shape; both sites answer
    on both engines (pins zd-ta-alignas-union-*, offsetof-union-member MATCH).

    The section header that follows is the one the block carried in CerbMem.lean. -/

/-! ## Layout computation — impl_mem.ml:98-273 (offsetsof / sizeof / alignof)

    OCaml's sizeof/alignof take `?(tagDefs= Tags.tagDefs ())` (optional,
    defaulting to the global) and offsetsof takes tagDefs explicitly;
    the family THREADS `~tagDefs` through every recursive call
    (impl_mem.ml:111-119 `sizeof ~tagDefs`/`alignof ~tagDefs`, :150
    :160 :168-169 :214 :226 etc.). The Lean workers mirror that: an
    explicit `tagDefs` parameter threaded through the mutual block; the
    default-budget wrappers supply `CerbTags.tagDefs ()`, mirroring the
    OCaml optional-arg default (every impl_mem-internal NON-layout call
    site uses the default).
    The threading is semantically LIVE at elaboration time: the
    AilEoffsetof fold (translation.lem:2730 → offsetof_ival,
    impl_mem.ml:2193) runs BEFORE the Tags global is populated
    (main.ml:304-305 sets it post-elaboration), so nested-struct
    offsetof resolves ONLY through the threaded map. The pre-fix Lean
    ambient-read shortcut panicked exactly there (pr44468, the CI
    sweep's finding; 2026-09-01 S-basket item 1).
    UPSTREAM ASYMMETRY, MIRRORED DELIBERATELY: the Union arms of both
    sizeof and alignof look the tag up in the GLOBAL
    (`Pmap.find tag_sym (Tags.tagDefs ())`, impl_mem.ml:173, :255)
    even though their member folds thread ~tagDefs — so
    elaboration-time offsetof over a union-containing struct CRASHES
    upstream (probed 2026-09-01: oracle exit 125, "Tags definitions
    must be set"; Lean mirrors with the unknown-tag panic — immaculate
    row offsetof-union-member pins the pair). Upstream-tray candidate.

    Integer/float leaf sizes come from CerberusImpl (the DefaultImpl port),
    exactly like OCaml routes them through `(Ocaml_implementation.get ())`
    — no local size constants are kept here.

    DECLARED (zero-discrepancy Z2-M-11): the layout family computes on
    Nat where the OCaml computes on Z — `al_n.toNat` (memberAlign's
    _Alignas arm, impl_mem.ml:118 `al_n`; at the old base b9aeedcb4 alignof's
    folds read it through `Z.to_int al_n`, :248/:267, which raised Overflow on
    a huge _Alignas — REACHABLE (a front-end-accepted `_Alignas(2^62)`) and
    registered as ISO-fix register R7, the R3 class: Lean computes the
    unbounded answer. R7 RETIRED 2026-10-30 (merge-base bump stage 1, record
    `docs/2026-10-29_merge-base-bump-stage1-record.md` §4.7): upstream
    b3e11ea33 moved the layout into `Ocaml_implementation.alignof_ty`, which
    computes on Z, so the oracle now gives the same unbounded answer
    (historical note; see `alignofCtype_lemFuel`), `lastOffset % align` /
    `maxOffset % align` / `maxSize % maxAlign` (:123/:169-171/:189-191
    `Z.modulus … 0` raises Division_by_zero where Lean's `% 0` is the
    identity), `n.toNat * sizeof` (:151 `Z.mul n`). Reachability of any
    difference: an alignment of 0 or a negative array size. Alignments
    come from alignof (≥ 1 for every complete type) or from a front-end-
    validated `_Alignas` (≥ 1 or a type); array sizes are front-end
    non-negative; the member-less struct that would make an alignment 0
    is UB061 on the shared front end (tests/z2-probes/mem/empty_struct.c:
    UB061 on fork, upstream and Lean). Unreachable by construction. -/

/-- `(Ocaml_implementation.get ()).sizeof_pointer` — impl_mem.ml:153-158 (and
    :219-225 alignof_pointer, :1160-1164, :2134): `None -> failwith "the
    concrete memory model requires a complete implementation"`. Read from the
    CerberusImpl record mirror (zero-discrepancy literal census #2: was the
    literal 8). alignof_pointer = sizeof_pointer = 8 in DefaultImpl. -/
def targetPtrSize : Nat :=
  match CerberusImpl.sizeof_pointer with
  | some n => n
  | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.targetPtrSize "CerberusImpl.targetPtrSize: the concrete memory model requires a complete implementation")))

/- The threaded tag environment is the Fmap itself (the same value the
   ambient global holds); enumeration-spine conversion happens only at
   the tag-LOOKUP arms (`CerbTagsWf.lookupEntry` = `fmapElements … |>.find?
   symbolEquality`, the exact pre-threading per-arm lookup named ONCE so
   the C4 sufficiency proofs can speak about it; leaf-type sizeof/alignof
   pay no conversion). -/
private abbrev TagDefs := CerbTags.TagDefsMap


/-! ARC-7 S4 TOTALIZATION (fuel; arc-3 pattern): the layout oracles and
    the (de)serializers below were `partial def`s — kernel-opaque, no
    equations: nothing could compute through a memory operation by
    unfolding, and the exec-totality gate requires equations. Each is now a fuel'd
    worker `*_lemFuel` (fuel decremented once per recursion layer;
    exhaustion = the OPAQUE `fuelExhaustedWith` sentinel, LemLib —
    a fake value provable equal to something would be a lie, D4
    transparency doctrine) + the original name as the wrapper started at
    the AMBIENT fuel (`[LemFuel]`, `LemFuel.fuel` — the fuel-parameter arc
    2026-09-04: the caller's parameter, never a constant; the former
    `lemDefaultFuel` is deleted), rfl-defeq to the worker at every
    instance, so every call site and every runtime behavior at a
    sufficient fuel is unchanged. `stringFromMemValue` (pp-only, never
    on a computed path) is total since arc-10 S3 (structural mutual
    recursion — no fuel needed). C4 (2026-09-05): the five layout
    wrappers below the block are MEASURED (fuel-free) under the
    acyclicity hypothesis — see their header. -/

mutual

/-- Member alignment with the `align_opt` (_Alignas) override —
    impl_mem.ml:115-122 (the align_opt match inside offsetsof; the same
    three-way match is repeated verbatim at impl_mem.ml:179-186 for union
    sizeof and inside the struct/union alignof folds). -/
def memberAlign_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs)
    (alignOpt : Option alignment) (ty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerberusImpl.memberAlign: fuel exhausted" 1
  | lemFuel + 1 =>
    match alignOpt with
    | none => alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs ty
    | some (AlignInteger al_n) => al_n.toNat
    | some (AlignType al_ty) => alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs al_ty

/-- THE struct-layout oracle: fold over the raw member quadruples,
    padding each member up to its (possibly _Alignas-overridden)
    alignment. Mirrors the fold at impl_mem.ml:112-127. Returns
    ([(ident, ty, offset)], last_offset) where last_offset is the end of
    the last member BEFORE trailing padding — exactly OCaml's `maxoffset`.
    (Alignment 0 is impossible for valid C members; Lean's `% 0 = id` +
    truncated subtraction make it degrade to pad = 0 instead of OCaml's
    Division_by_zero.) -/
def offsetsofMembers_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs)
    (members : List (identifier × (attributes × Option alignment × qualifiers × ctype)))
    : List (identifier × ctype × Nat) × Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerberusImpl.offsetsofMembers: fuel exhausted" ([], 0)
  | lemFuel + 1 =>
    let (xs, maxoffset) := members.foldl (init := (([] : List (identifier × ctype × Nat)), 0))
      fun (acc : List (identifier × ctype × Nat) × Nat) memb =>
        let (xs, lastOffset) := acc
        let (ident, (_, alignOpt, _, ty)) := memb
        let size := sizeofCtype_lemFuel lemFuel enumDefs ambient tagDefs ty          -- impl_mem.ml:112 (sizeof ~tagDefs)
        let align := memberAlign_lemFuel lemFuel enumDefs ambient tagDefs alignOpt ty -- impl_mem.ml:113-119 (alignof ~tagDefs)
        let x := lastOffset % align                   -- impl_mem.ml:123
        let pad := if x == 0 then 0 else align - x    -- impl_mem.ml:124
        ((ident, ty, lastOffset + pad) :: xs, lastOffset + pad + size)  -- impl_mem.ml:125
    (xs.reverse, maxoffset)

/-- offsetsof — impl_mem.ml:98-129. Struct: offsetsofMembers over the
    member list, with the flexible array member appended as an ordinary
    member (its stored element ctype, verbatim per impl_mem.ml:104-108)
    unless `ignoreFlexible`. Union: every member at offset 0, last_offset
    0 (impl_mem.ml:128-129). Missing tag: OCaml's Pmap.find raises
    Not_found — panic here.
    Tag lookup uses symbolEquality (digest+nat, description-INSENSITIVE
    — OCaml's symbol_compare/Pmap key order, symbol.lem), NOT the derived
    BEq which also compares the description. Same for every tag lookup in
    this file. -/
def offsetsof_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs) (tagSym : sym)
    (ignoreFlexible : Bool := false) : List (identifier × ctype × Nat) × Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerberusImpl.offsetsof: fuel exhausted" ([], 0)
  | lemFuel + 1 =>
    match CerbTagsWf.lookupEntry tagDefs tagSym with
    | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.offsetsof "CerberusImpl.offsetsof: unknown tag (OCaml: Pmap.find Not_found)")))
    | some (_, (_, StructDef membrs_ flexibleOpt)) =>
      let membrs := match flexibleOpt with
        | none => membrs_
        | some (FlexibleArrayMember attrs ident qs ty) =>
          if ignoreFlexible then membrs_
          else membrs_ ++ [(ident, (attrs, none, qs, ty))]  -- impl_mem.ml:107-108 (raw stored ctype)
      offsetsofMembers_lemFuel lemFuel enumDefs ambient tagDefs membrs
    | some (_, (_, UnionDef membrs)) =>
      (membrs.map (fun (ident, (_, _, _, ty)) => (ident, ty, 0)), 0)

/-- sizeof — impl_mem.ml:131-194.
    Struct (impl_mem.ml:162-171): offsetsof last_offset (ignore_flexible —
    the flexible member is uncounted except through alignof's trailing
    padding), padded up to alignof(struct).
    Union (impl_mem.ml:172-192): max member size padded up to max member
    alignment (align_opt honored).
    Void/incomplete-Array/Function PANIC, mirroring OCaml `assert false`
    (impl_mem.ml:134-135) — a 0-sized value flowing onward is the
    panic-optimized-into-value hazard (arc-14 S1 F1, sem:S7; the previous
    "return 0" divergence carried provenance, not a rationale). -/
def sizeofCtype_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs) (cty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerberusImpl.sizeofCtype: fuel exhausted" 0
  | lemFuel + 1 =>
    match cty with
    | Ctype _ ty_ =>
      match ty_ with
      | .Void0 => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofVoid "CerberusImpl.sizeofCtype: Void (impl_mem.ml:134-135 assert false)")))
      | .Array0 _ none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofIncompleteArray "CerberusImpl.sizeofCtype: incomplete array (impl_mem.ml:134-135 assert false)")))
      | .Function _ _ _ | .FunctionNoParams _ =>
        failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofFunction "CerberusImpl.sizeofCtype: function type (impl_mem.ml:134-135 assert false)")))
      | .Basic (.Integer ity) =>
        match CerberusImpl.sizeof_ity (CerberusImpl.resolveEnum enumDefs ity) with      -- impl_mem.ml:136-141
        | some n => n
        | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofInteger "CerberusImpl.sizeofCtype: the concrete memory model requires a complete implementation sizeof INTEGER")))
      | .Basic (.Floating fty) =>
        match CerberusImpl.sizeof_fty fty with      -- impl_mem.ml:143-148
        | some n => n
        | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofFloat "CerberusImpl.sizeofCtype: the concrete memory model requires a complete implementation sizeof FLOAT")))
      | .Array0 elemCty (some n) => n.toNat * sizeofCtype_lemFuel lemFuel enumDefs ambient tagDefs elemCty  -- impl_mem.ml:150-151 (sizeof ~tagDefs)
      | .Pointer _ _ => targetPtrSize               -- impl_mem.ml:153-158
      | .Atomic innerCty => sizeofCtype_lemFuel lemFuel enumDefs ambient tagDefs innerCty    -- impl_mem.ml:160-161 (sizeof ~tagDefs)
      | .Struct tagSym =>                           -- impl_mem.ml:162-171
        let (_, maxOffset) := offsetsof_lemFuel lemFuel enumDefs ambient tagDefs tagSym (ignoreFlexible := true)  -- impl_mem.ml:168 (threaded)
        let align := alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs cty  -- impl_mem.ml:169 (alignof ~tagDefs)
        let x := maxOffset % align
        if x == 0 then maxOffset else maxOffset + (align - x)
      | .Union0 tagSym =>                           -- impl_mem.ml:172-192
        -- GLOBAL read, deliberately: impl_mem.ml:173 is
        -- `Pmap.find tag_sym (Tags.tagDefs ())` — NOT ~tagDefs (the
        -- upstream asymmetry; see the section header note).
        match CerbTagsWf.lookupEntry ambient tagSym with
        | some (_, (_, UnionDef membrs)) =>
          let (maxSize, maxAlign) := membrs.foldl (init := ((0 : Nat), (0 : Nat)))
            fun (acc : Nat × Nat) memb =>
              let (accSize, accAlign) := acc
              let (_, (_, alignOpt, _, ty)) := memb
              (max accSize (sizeofCtype_lemFuel lemFuel enumDefs ambient tagDefs ty),
               max accAlign (memberAlign_lemFuel lemFuel enumDefs ambient tagDefs alignOpt ty))
          -- trailing padding up to the max alignment — impl_mem.ml:189-191
          let x := maxSize % maxAlign
          if x == 0 then maxSize else maxSize + (maxAlign - x)
        | _ => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.sizeofUnion "CerberusImpl.sizeofCtype: Union tag not a UnionDef (OCaml: assert false / Not_found)")))
      | .Byte => 1                                  -- impl_mem.ml:193-194

/-- alignof — impl_mem.ml:196-273.
    Struct (impl_mem.ml:228-252): max member alignment (align_opt
    honored), the fold seeded with the flexible array member's
    array-of-element alignment when present (else 0).
    Union (impl_mem.ml:253-271): max member alignment, seed 0.
    Void/Function PANIC, mirroring OCaml `assert false` (impl_mem.ml:
    198-199, 216-218) — arc-14 S1 F1, sem:S7 (was: silent 1,
    provenance-only). -/
def alignofCtype_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs) (cty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerberusImpl.alignofCtype: fuel exhausted" 1
  | lemFuel + 1 =>
    match cty with
    | Ctype _ ty_ =>
      match ty_ with
      | .Void0 => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofVoid "CerberusImpl.alignofCtype: Void (impl_mem.ml:198-199 assert false)")))
      | .Function _ _ _ | .FunctionNoParams _ =>
        failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofFunction "CerberusImpl.alignofCtype: function type (impl_mem.ml:216-218 assert false)")))
      | .Basic (.Integer ity) =>
        match CerberusImpl.alignof_ity (CerberusImpl.resolveEnum enumDefs ity) with     -- impl_mem.ml:200-206
        | some n => n
        | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofInteger "CerberusImpl.alignofCtype: the concrete memory model requires a complete implementation alignof INTEGER")))
      | .Basic (.Floating fty) =>
        match CerberusImpl.alignof_fty fty with     -- impl_mem.ml:207-213
        | some n => n
        | none => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofFloat "CerberusImpl.alignofCtype: the concrete memory model requires a complete implementation alignof FLOATING")))
      | .Array0 elemCty _ => alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs elemCty   -- impl_mem.ml:214-215 (alignof ~tagDefs)
      | .Pointer _ _ => targetPtrSize               -- impl_mem.ml:219-225
      | .Atomic innerCty => alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs innerCty   -- impl_mem.ml:226-227 (alignof ~tagDefs)
      | .Struct tagSym =>                           -- impl_mem.ml:228-252
        -- threaded lookup: impl_mem.ml:229 is `Pmap.find tag_sym tagDefs`
        match CerbTagsWf.lookupEntry tagDefs tagSym with
        | some (_, (_, StructDef membrs flexibleOpt)) =>
          let init := match flexibleOpt with        -- impl_mem.ml:234-239
            | none => 0
            | some (FlexibleArrayMember _ _ _ elemTy) =>
              alignofCtype_lemFuel lemFuel enumDefs ambient tagDefs (mkCtype (.Array0 elemTy none))
          membrs.foldl (init := init) fun acc memb =>
            let (_, (_, alignOpt, _, ty)) := memb
            -- ISO-fix register R7, RETIRED 2026-10-30 (historical note; VALIDATION.md
            -- §2): at b9aeedcb4 impl_mem.ml:248 read an `AlignInteger al_n` through
            -- `Z.to_int al_n`, which raised Z.Overflow outside OCaml's native int
            -- range, and the unbounded maximum computed here was the fork's answer
            -- ([USER 2026-10-03]); since upstream b3e11ea33 (the stage-1 base
            -- c3ff8c53f) `Ocaml_implementation.alignof_ty` folds the same maximum
            -- on Z (ocaml_implementation.ml:535-549 at c3ff8c53f) — a plain mirror
            -- (pins zd-ta-alignas-huge-*, MATCH since the bump).
            max (memberAlign_lemFuel lemFuel enumDefs ambient tagDefs alignOpt ty) acc  -- ocaml_implementation.ml:535-549 (was impl_mem.ml:242-251)
        | _ => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofStruct "CerberusImpl.alignofCtype: Struct tag not a StructDef (OCaml: assert false / Not_found)")))
      | .Union0 tagSym =>                           -- impl_mem.ml:253-271
        -- GLOBAL read, deliberately: impl_mem.ml:255 is
        -- `Pmap.find tag_sym (Tags.tagDefs ())` — NOT ~tagDefs (the
        -- upstream asymmetry; see the section header note).
        match CerbTagsWf.lookupEntry ambient tagSym with
        | some (_, (_, UnionDef membrs)) =>
          membrs.foldl (init := (0 : Nat)) fun acc memb =>
            let (_, (_, alignOpt, _, ty)) := memb
            -- R7 (retired, see the struct fold): the union fold mirrors
            -- Ocaml_implementation.alignof_ty's union arm at c3ff8c53f (was impl_mem.ml:267 `Z.to_int al_n`)
            max (memberAlign_lemFuel lemFuel enumDefs ambient tagDefs alignOpt ty) acc
        | _ => failwithI (CerbStop.render (.upstreamCrash (CerbStopSites.alignofUnion "CerberusImpl.alignofCtype: Union tag not a UnionDef (OCaml: assert false / Not_found)")))
      | .Byte => 1                                  -- impl_mem.ml:272-273

end

/-! FUEL-PARAMETER ARC C4 (2026-09-05): the five layout wrappers are
    MEASURED, fuel-FREE, under the hypothesis `CerbTagsWf.Acyclic ambient`
    (`AcyclicPair ambient tagDefs` for `offsetsof`, whose struct tags resolve
    in the threaded map and union tags in the ambient one). The measure is
    `CerbTagsWf.envBound`/`memberBound`/`membersBound`/`offsetsofBound`: the
    structural size of what is asked about plus the environment's weight
    (every entry's member-type sizes + 2 frames per hop) — derived from the
    hop structure in CerbMem_lemMeasureProofs.lean, where the obligations
    `<f>_measure_sufficient (…) (lemHyp : Acyclic …) (lemFuel) (lemMeasureLe :
    μ ≤ lemFuel) : f_lemFuel lemFuel … = f …` are proved in the generated
    `assuming` shape. On an environment violating the hypothesis (a by-value
    cycle a hand-authored Core file can state; the C frontend never emits one —
    CerbTagsWf's header cites the invariant) the wrapper may exhaust: the loud
    `fuelExhaustedWith` sentinel, where the oracle loops. tagDefs: the ambient
    global, mirroring OCaml's `?(tagDefs= Tags.tagDefs ())` optional-arg
    default (unchanged). -/
def memberAlign (enumDefs : EnumDefs) (ambient : TagDefs) (alignOpt : Option alignment) (ty : ctype) : Nat :=
  memberAlign_lemFuel (CerbTagsWf.memberBound ambient alignOpt ty) enumDefs ambient ambient alignOpt ty

/-- Measured + default-tagDefs wrapper (see memberAlign). -/
def offsetsofMembers (enumDefs : EnumDefs) (ambient : TagDefs)
    (members : List (identifier × (attributes × Option alignment × qualifiers × ctype)))
    : List (identifier × ctype × Nat) × Nat :=
  offsetsofMembers_lemFuel (CerbTagsWf.membersBound ambient members) enumDefs ambient ambient members

/-- Measured wrapper (tagDefs explicit, like OCaml offsetsof; hypothesis
    `AcyclicPair ambient tagDefs`). -/
def offsetsof (enumDefs : EnumDefs) (ambient : TagDefs) (tagDefs : TagDefs) (tagSym : sym)
    (ignoreFlexible : Bool := false) : List (identifier × ctype × Nat) × Nat :=
  offsetsof_lemFuel (CerbTagsWf.offsetsofBound ambient tagDefs) enumDefs ambient tagDefs tagSym ignoreFlexible

/-- Measured + default-tagDefs wrapper (see memberAlign). -/
def sizeofCtype (enumDefs : EnumDefs) (ambient : TagDefs) (cty : ctype) : Nat :=
  sizeofCtype_lemFuel (CerbTagsWf.envBound ambient cty) enumDefs ambient ambient cty

/-- Measured + default-tagDefs wrapper (see memberAlign). -/
def alignofCtype (enumDefs : EnumDefs) (ambient : TagDefs) (cty : ctype) : Nat :=
  alignofCtype_lemFuel (CerbTagsWf.envBound ambient cty) enumDefs ambient ambient cty


/-! ## `Implementation.sizeof_ty` / `Implementation.alignof_ty` — upstream b3e11ea33
    (`val sizeof_ty: map Symbol.sym (Loc.t * Ctype.tag_definition) -> Ctype.ctype ->
    integer`, OCaml reps `Ocaml_implementation.sizeof/alignof` above): the Lean reps
    (implementation.lem `declare lean target_rep function sizeof_ty = \`CerberusImpl.sizeof_ty\``,
    reader consumers). Fuel-FREE: they are the measured one-map wrappers (C4), so no
    `[LemFuel]` binder — the generated callers (core_eval.lem's Civsizeof/Civalignof,
    driver.lem's `alignof_ival` closures, cabs_to_ail_effect.lem's `get_alignof` through
    the seed `alignof_ty_seeded`) pass the two readers then the explicit map.
    The reader's tagDefs (the Tags global's mirror) is received and UNUSED: upstream
    passes the explicit map to every arm except alignof's union arm (:566, see the
    section header); the wrappers use the explicit map throughout. At run time both
    maps are the Core file's table; at desugar time (`get_alignof`) the explicit map
    is the desugar state's real table where upstream's global is UNSET
    (`Failure("Tags definitions must be set by Tags.set_tagDefs before any use")`
    on a union-containing type — the oracle crashes where this wrapper answers; the
    pre-merge pseudo-map `alignof_ty` answered too; the alignas witnesses of M4
    never apply the closure to a union, so M4 did not see it; pre-merge review P1,
    record §6b; CLOSED at M6c by the backported alignof line, record §6c). -/
def sizeof_ty (enumDefs : EnumDefs) (_readerTagDefs : TagDefs) (tagDefs : TagDefs) (ty : ctype) : Int :=
  Int.ofNat (sizeofCtype enumDefs tagDefs ty)

def alignof_ty (enumDefs : EnumDefs) (_readerTagDefs : TagDefs) (tagDefs : TagDefs) (ty : ctype) : Int :=
  Int.ofNat (alignofCtype enumDefs tagDefs ty)

end CerberusImpl
