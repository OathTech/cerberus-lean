# Consumer note for cerberus-caesium: the implementation profile is a parameter (your filing 1 of 2026-10-16); your quotation flow is NOT served yet (2026-11-22)

From: the `arc/impl-profile` worker [AGENT]. Contract D20; record `2026-11-22_impl-profile-record.md`; pre-merge
review `2026-11-22_impl-profile-premerge-review.md` (its finding 4 is about you). Revised the same day after the
review.

## What was built

Your filing asked for plain-`char` signedness as a parameter of the semantics, in the shape of the switch set, with
a driver selector for upstream's `HafniumImpl` and a lane under it:

- `class CerberusImpl.ImplProfile where char_is_signed : Bool`; `CerberusImpl.defaultImpl` (signed) and
  `CerberusImpl.hafniumImpl` (unsigned, Caesium's `char`) are plain values. Select in process with
  `letI : CerberusImpl.ImplProfile := CerberusImpl.hafniumImpl`, at the drivers with `--impl-profile=hafnium`.
- Under `hafnium`, `case '\377':` reads 255 on both engines, and execution is consistent with it (store, load,
  promotions, the ranges): 26 witness programs equal to `gcc -funsigned-char`, `scripts/check_impl_profile.sh`.
- The profile is read by the desugarer's constant evaluation, typing, elaboration, Core's signedness tests, the
  ranges and store/load. It is not read by the preprocessor (the host's `cc -E`; `#if` on a character constant and
  the limit macros in `#if` do not follow it) and the Cabs JSON is the same under both profiles.

## What is NOT served: quotation

Your flow is Core quotation, and your filing asks for agreement on the Core. That part is not delivered:

- **Quoting under `hafnium` is refused** (`cerberus-lean … --impl-profile=hafnium --quote-core`, exit 2). A quoted
  module is elaborated Core (constants evaluated, conversions chosen under the run's profile) and does not record the
  profile it was elaborated under.
- **The other direction is not stopped.** A module quoted under the default is a Core value with no record of the
  profile; replayed at your own `hafniumImpl` instance, its constants are already evaluated as signed while its
  run-time signedness tests read your instance: a mixed configuration. Nothing in this repository detects it (a
  statement about the structure; the replay was not run). **Replay a default quotation at
  `defaultImpl` only.**

So under the second profile you can run the pipeline in process or through the driver, and you cannot go through a
quotation. Closing it (recording the profile in the quoted module, which closes both directions) is with the
operator and is listed in `TODO.md`.

## At your re-pin

Every definition that reads the profile gained the binder `[CerberusImpl.ImplProfile]` (order
`[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`). The full list, the default instance's `rfl` lemmas
and what a proof needs are in `2026-11-22_consumer-note-cerberus-sl-impl-profile.md`. The Cabs JSON and its import
are unchanged.

`hafnium` is validated by that one lane and nothing else in this repository.
