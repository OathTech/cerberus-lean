/-
  Fresh name generation and digest operations.
  Corresponds to: Cerb_fresh and Digest modules in OCaml.

  This is a leaf module with no imports from generated code,
  avoiding circular dependencies in the build.

  DIGEST REPRESENTATION (arc 5 / S2, documented-deliberate divergence):
  OCaml's `Digest.t` is the RAW 16-byte MD5 string; a Lean `String` must
  be valid UTF-8, so we store digests in `Digest.to_hex` form (32-char
  lowercase hex, native/md5.c). Consequences, each checked:
    * equality: hex is injective on raw digests — `digest_compare = 0`
      agrees exactly with OCaml `Digest.compare = 0` (the only digest
      property the model consumes: symbolEquality/symbol_compare
      (symbol.lem:153-162 via Eq/Ord instances) and
      from_same_translation_unit (symbol.lem:286-288)).
    * ordering: lowercase hex is byte-wise order-isomorphic to the raw
      bytes ('0'..'9','a'..'f' ASCII order = nibble order), so
      digest_compare orders any two digests exactly as OCaml
      Digest.compare (= String.compare on raw bytes) does — symbol-keyed
      map iteration order is preserved.
    * string_of_digest (OCaml `Digest.to_hex`) becomes the identity: our
      rep already IS the to_hex image, so printed digests match OCaml
      byte-for-byte.
  What gets digested also differs: OCaml digests the .c file
  (`Cerb_fresh.set_digest filename` = Digest.file, pipeline.ml:181,
  util/cerb_fresh.ml:7-10); the Lean pipeline never sees the .c — it
  digests the cabs-json input it was handed (Main.lean, per-TU loop).
  Distinct TUs get distinct digests on both sides, and identical-content
  inputs conflate on both sides, so from_same_translation_unit behaves
  isomorphically; the VALUES differ across the two pipelines (they are
  never compared across pipelines — digests never appear in harness
  output).
-/

set_option autoImplicit true

namespace CerberusFresh

/-- Compare two digests (hex-form strings). Returns negative, zero, or
    positive. Corresponds to: Digest.compare (order-isomorphic on the hex
    representation — see the module note). -/
def digest_compare (x y : String) : Int :=
  if x < y then -1 else if x == y then 0 else 1

/-- Convert digest to hex string.
    Corresponds to: Digest.to_hex — the identity here, because our digest
    representation is already the to_hex image (see the module note). -/
def string_of_digest (x : String) : String := x

/-- MD5 of a string's bytes as 32-char lowercase hex (native/md5.c,
    RFC 1321). Equals OCaml `Digest.to_hex (Digest.string s)`; verified
    against the RFC 1321 test vectors and OCaml Digest in
    test/Unit/FreshIntTest.lean. Pure extern: MD5 is a pure function. -/
@[extern "cerb_md5_hex"]
opaque md5Hex : @& String → String

/-- Read the current per-TU digest (native mutable global, native/md5.c).
    Corresponds to: the `Cerb_fresh.digest` ref cell read
    (util/cerb_fresh.ml:7-10). BaseIO variant for hand-written callers
    that must not be dead-code eliminated (CerbTags.lean pattern). -/
@[extern "cerb_digest_get"]
opaque digestIO : @& Unit → BaseIO String

/-- Set the per-TU digest. Corresponds to: `Cerb_fresh.set_digest`
    (util/cerb_fresh.ml:7-10), called once per translation unit before
    its desugar (pipeline.ml:181 mirror: Main.lean per-TU loop). -/
@[extern "cerb_digest_set"]
opaque setDigestIO : @& String → BaseIO Unit

/-- Pure-signature read of the per-TU digest, for the generated code's
    call sites (`Symbol.fresh` etc. call `CerberusFresh.digest ()` in
    pure position — symbol.lem:44-46 declares no effect annotation, and
    OCaml's `Cerb_fresh.digest` is likewise an ordinary pure-typed ref
    read). Armoring is the CerbTags.lean pattern exactly:
    @[never_extract, noinline] on the impl and never_extract on the
    opaque, so a closed application `digest ()` can neither be cached as
    a startup constant (it would freeze the pre-set "" value) nor be
    CSE-hoisted across the per-TU set sites. Within one TU the value is
    constant, so intra-TU sharing — the only sharing never_extract
    permits inside a single evaluation — is semantically harmless.
    Normative soundness invariant: docs/2026-08-22_arc14-effect-erasure-
    invariant.md (arc-14 S1 F5, sem:S17). -/
@[never_extract, noinline]
private unsafe def digest_impl (_ : Unit) : String :=
  unsafeBaseIO (digestIO ())

@[implemented_by digest_impl]
opaque digest : Unit → String
attribute [never_extract] digest

/-- IO-positioned evaluation barrier (native/md5.c cerb_force_thunk).
    `forceIO (fun () => e)` evaluates `e` exactly at this point of the
    IO bind chain. Needed wherever a PURE computation reads mutable
    native state (the per-TU digest via `digest ()`) and is written
    between two writes of that state: the Lean compiler sinks pure lets
    to their use sites, so without the barrier the computation can be
    deferred past a LATER `setDigestIO` and observe the wrong TU's
    digest (caught by test/Unit/FreshIntTest.lean testDigestGlobal).
    Armoring mirrors CerbTags.with_tagDefs exactly (unsafe extern +
    @[never_extract, noinline] impl + @[implemented_by] on an
    irreducible constant; the whole-extent-in-C rationale of arc-4
    S3b): the thunk is applied inside the C call, extern calls are
    never reordered, and the closure boundary blocks let-sinking out
    of the body.

    AXIOM DELETED (arc-17 S2b, 2026-08-25 — the [USER 2026-08-24]
    temporal-mover execution for this entry): this was `axiom forceIO`
    from arc-5 S2 until arc-17 S2b. The old docstring already stated
    the witness — "`fun f => pure (f ())` inhabits the type" — and it
    is now an `opaque` carrying that witness explicitly, so the KERNEL
    checks it and nothing is postulated. The constant stays
    IRREDUCIBLE (opaque — the compiler cannot inline-and-beta-reduce
    the closure away, and no proof can unfold it), implemented_by
    still routes execution through the C-side barrier (behavior
    re-verified by test/Unit/FreshIntTest.lean testDigestGlobal — the
    test that found the original sinking bug). Result: this constant
    can NEVER appear in any axiom cone; the runtime trust is exactly
    the implemented_by boundary (declared, gated — RelSem/Audit.lean
    asserts the axiom-form absence build-fatally). -/
@[extern "cerb_force_thunk"]
private unsafe opaque forceThunkIO {b : Type} : (@& (Unit → b)) → BaseIO b :=
  fun f => pure (f ())  -- explicit witness (arc-17 S2b): kills the
                        -- synthesized-sorryAx inhabitant (see
                        -- CerbTags.withTagDefsIO)

@[never_extract, noinline]
private unsafe def forceIO_impl {b : Type} (f : Unit → b) : BaseIO b :=
  forceThunkIO f

@[implemented_by forceIO_impl]
opaque forceIO {b : Type} : (Unit → b) → BaseIO b :=
  fun f => pure (f ())
attribute [never_extract] forceIO

/- freshIntIO DELETED (effect-retirement C1, charter sections 3.4/7.1):
   the fresh counter is no longer an extern — `fresh_int` is a lem
   SUPPLY on the Lean target (every transitive caller threads the
   counter explicitly; entry points are supply-parameterized, Main
   seeds the single stream). native/fresh_int.c, the 2^20 ambient-base
   stratification, and the Main startup floor probe are gone with it.
   The digest machinery above stays — its opaque conversion is a C2
   deliverable (Q4 ruling). -/

end CerberusFresh
