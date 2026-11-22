# Consumer note for refinedc-lean: the implementation profile is selectable; `hafnium` gives RefinedC's plain `char` (2026-11-22)

From: the `arc/impl-profile` worker [AGENT]. Answers the "Plain `char`" item of your `docs/PUBLIC-ALPHA.md` (read at
your primary checkout, `772877a`; the worktree named in my brief no longer exists). Contract D20; record
`2026-11-22_impl-profile-record.md`; witness `scripts/check_impl_profile.sh` (ladder row 1); upstream-tray report 100.

## What changed for you

Plain-`char` signedness is one parameter of the whole pipeline, on both engines. Under the `hafnium` profile
(upstream's `HafniumImpl`, the record RefinedC's `cerb_wrapper.ml:44` selects) your two maintained examples give
RefinedC's values, and so does the enumerator case your item asks about:

| Program (the lane's form) | default | hafnium |
|---|---|---|
| `switch` with `case '\377':` and `case '\200':` | labels -1 and -128 | labels 255 and 128 |
| `int a['\377' > 0 ? 2 : 1]` | one element | two elements |
| `enum e { A = '\377' }` | `A == -1` | `A == 255` |

These are `sw_labels`, `array_size` and `enumerator` of `tests/impl_profile/`: under `hafnium` both engines return
what `gcc -funsigned-char` returns, executed, not only desugared.

## How to select it

**In process (your `Pipeline.lean`, `CaesiumHarness/Load.lean`).** The profile is an instance-implicit class, like the
fuel and the switch set. Supply it where you supply those, and for the import:

```lean
letI : LemFuel := ⟨defaultFuel⟩
letI : CerberusImpl.ImplProfile := CerberusImpl.hafniumImpl     -- was: nothing; the default was a constant
letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
```

`CerberusImpl.hafniumImpl` and `CerberusImpl.defaultImpl` are plain values, not instances; the repository declares no
instance, so a call with none in scope does not elaborate (that is the check that you chose one). Binder order where
you pass instances positionally: `[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`.

**The producer.** Export with the same profile: `main.exe --impl-profile=hafnium … --cabs-json f.c`. In an OCaml
client of the library, the call is upstream's: `Ocaml_implementation.(set (HafniumImpl.impl))`, once, before
`load_core_stdlib`.

**The driver (your `scripts/differential.py`).** `cerberus-lean --batch --impl-profile=hafnium …`, both spellings
(`--impl-profile hafnium`). An unknown name is a REFUSAL, exit 2.

## What will break until you do

1. **`CabsImport.parseJson`, `parseJsonWithFiles`, `parseJsonWithAllLabels` bind `[CerberusImpl.ImplProfile]`.** Your
   two call sites need an instance in scope.
2. **The Cabs JSON has a new field, `"impl_profile"`** (upstream's profile name: `clang9_x86_64-apple-darwin16.7.0`
   for `default`, `hafnium_aarch64-none-eabi` for `hafnium`), and the importer REFUSES a document whose profile is not
   the instance's, one without the field (every JSON you exported before this pin), and one naming another profile.
   Export under `default`, import under `hafnium` is the mixed configuration and is refused with
   `REFUSED: mixed implementation profiles`. Re-export your corpus with the profile you import under.
3. Every definition of the desugaring, typing, elaboration and execution cone that reads the profile gained the
   binder; the list is in `2026-11-22_consumer-note-cerberus-sl-impl-profile.md`.

## What changes in constant evaluation under `hafnium`

A character constant above `\177` is positive (`'\377'` is 255); `CHAR_MIN` is 0 and `CHAR_MAX` 255; `(char)200` is
200; plain `char` promotes and compares as an unsigned type; a `char` object stores and loads 0..255. `signed char`
and `unsigned char` are unchanged, and `char` stays a distinct type (`_Generic` picks the `char` association under
both profiles). Sizes, alignments and every other implementation-defined choice are the same in the two profiles.

Your own `AilToCaesium/HafniumImpl.lean` (the layout side, `char` unsigned) now agrees with the frontend when you
select `hafniumImpl`; under `defaultImpl` the two disagree as before.

## Limits you should know

- `hafnium` is validated by the witness lane alone: 22 programs. No other lane of this repository runs under it.
  Your end-to-end comparison of the two examples is the check your item asks for; this note does not replace it.
- Core quotation (`--quote-core`) is refused under `hafnium`.
- The libc is built under the default profile; it stands for both on the measurement that its sources elaborate to
  identical Core under the two (repeated by the lane on every run).
- Bit-fields are unsupported upstream, so a `char` bit-field is refused under both profiles.
- On un-patched upstream, `HafniumImpl` with execution crashes or answers from a mixed configuration (tray report
  100). RefinedC's frontend does not execute, so its own use is not affected; a comparison that executes upstream
  Cerberus under `HafniumImpl` is.
