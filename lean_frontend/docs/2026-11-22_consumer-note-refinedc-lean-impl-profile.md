# Consumer note for refinedc-lean: the implementation profile is selectable; `hafnium` gives RefinedC's plain `char` (2026-11-22)

From: the `arc/impl-profile` worker [AGENT]. Answers the "Plain `char`" item of your `docs/PUBLIC-ALPHA.md` (read at
your primary checkout, `772877a`; the worktree named in my brief no longer exists). Contract D20; record
`2026-11-22_impl-profile-record.md`; pre-merge review `2026-11-22_impl-profile-premerge-review.md`; witness
`scripts/check_impl_profile.sh` (ladder row 1); upstream-tray report 100. Revised the same day after the review: an
earlier text of this note described a profile field in the Cabs JSON and told you to re-export. That field was
removed before the merge; nothing below asks for a re-export.

## What changed for you

Plain-`char` signedness is a parameter of the run, on both engines. Under the `hafnium` profile (upstream's
`HafniumImpl`, the record RefinedC's `cerb_wrapper.ml:44` selects) your two maintained examples give RefinedC's
values, and so does the enumerator case your item asks about:

| Program (the lane's form) | default | hafnium |
|---|---|---|
| `switch` with `case '\377':` and `case '\200':` | labels -1 and -128 | labels 255 and 128 |
| `int a['\377' > 0 ? 2 : 1]` | one element | two elements |
| `enum e { A = '\377' }` | `A == -1` | `A == 255` |

These are `sw_labels`, `array_size` and `enumerator` of `tests/impl_profile/`: under `hafnium` both engines return
what `gcc -funsigned-char` returns, executed, not only desugared.

## How to select it

**In process (your `Pipeline.lean`).** The profile is an instance-implicit class, like the fuel and the switch set.
Supply it where you supply those:

```lean
letI : LemFuel := ⟨defaultFuel⟩
letI : CerberusImpl.ImplProfile := CerberusImpl.hafniumImpl     -- was: nothing; the default was a constant
letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
```

`CerberusImpl.hafniumImpl` and `CerberusImpl.defaultImpl` are plain values, not instances; the repository declares no
instance, so a call with none in scope does not elaborate (that is the check that you chose one). Binder order where
you pass instances positionally: `[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`.

**The driver (your `scripts/differential.py`).** `cerberus-lean --batch --impl-profile=hafnium …`, both spellings
(`--impl-profile hafnium`); the oracle driver takes the same flag for its own `--exec` run. An unknown name is
refused, exit 2. In an OCaml client of the library, the call is upstream's: `Ocaml_implementation.(set
(HafniumImpl.impl))`, once, before `load_core_stdlib`.

**The Cabs JSON needs nothing.** The export is byte-identical under the two profiles (the document carries character
constants as their spellings and the limit macros as identifiers) and records no profile; `CabsImport.parseJson*`
are unchanged and take no instance. Your existing exports stay valid. The profile is selected where the document is
desugared and run, not where it is produced. That also means nothing ties the two sides of a differential together:
give the same profile to the oracle's `--exec` run and to the Lean run yourself.

## What will change at the re-pin

Every definition of the desugaring, typing, elaboration and execution cone that reads the profile gained the binder
`[CerberusImpl.ImplProfile]`; the list is in `2026-11-22_consumer-note-cerberus-sl-impl-profile.md`. Your call sites
of `Cabs_to_ail.desugar` and the typing entry need an instance in scope.

## What reads the profile, and what does not

It is read by the desugarer's constant evaluation, Ail typing, the elaboration, Core's signedness tests, the integer
ranges and the memory model's store and load. Under `hafnium`: a character constant above `\177` is positive
(`'\377'` is 255); `CHAR_MIN` is 0 and `CHAR_MAX` 255 in expressions; `(char)200` is 200; plain `char` promotes and
compares as an unsigned type; a `char` object stores and loads 0..255. `signed char` and `unsigned char` are
unchanged, and `char` stays a distinct type (`_Generic` picks the `char` association under both profiles). Sizes,
alignments and every other implementation-defined choice are the same in the two profiles.

**The preprocessor does not read it.** Preprocessing is the host's `cc -E` and gets no signedness flag, exactly as in
upstream RefinedC's frontend, so this is parity with RefinedC, and it differs from `gcc -funsigned-char`:

- `#if '\377' < 0` is evaluated by the host preprocessor (true on an x86-64 host) while `'\377' < 0` in an
  expression is false under `hafnium`. C17 6.10.1#4 permits the two to differ.
- `CHAR_MIN` and `CHAR_MAX` (every `<limits.h>` macro) are identifiers in `#if` and evaluate as 0 there, under
  either profile (upstream's scheme; tray 101).
- `__CHAR_UNSIGNED__` is not defined under `hafnium` (the pre-merge review's observation; no flag reaches the
  preprocessor).

The lane pins one program of this kind (`preprocessor_if`): both engines answer 12 under `hafnium` where
`gcc -funsigned-char` answers 9.

Your own `AilToCaesium/HafniumImpl.lean` (the layout side, `char` unsigned) now agrees with the frontend when you
select `hafniumImpl`; under `defaultImpl` the two disagree as before.

## Limits you should know

- `hafnium` is validated by the witness lane alone: 28 programs. No other lane of this repository runs under it.
  Your end-to-end comparison of the two examples is the check your item asks for; this note does not replace it.
- Core quotation (`--quote-core`) is refused under `hafnium`.
- The oracle accepts `hafnium` under the concrete memory model only.
- The libc is built under the default profile; it stands for both on the measurement that its sources elaborate to
  identical Core under the two (repeated by the lane on every run).
- Bit-fields are unsupported upstream, so a `char` bit-field is refused under both profiles.
- On un-patched upstream, `HafniumImpl` with execution crashes or answers from a mixed configuration (tray report
  100). RefinedC's frontend does not execute, so its own use is not affected; a comparison that executes upstream
  Cerberus under `HafniumImpl` is.
