# Consumer note for cerberus-caesium: the implementation profile is a parameter (your filing 1 of 2026-10-16) (2026-11-22)

From: the `arc/impl-profile` worker [AGENT]. Contract D20; record `2026-11-22_impl-profile-record.md`.

Your filing asked for plain-`char` signedness as a parameter of the semantics, in the shape of the switch set, with
a driver selector for upstream's `HafniumImpl` and a lane under it. That is what was built:

- `class CerberusImpl.ImplProfile where char_is_signed : Bool`; `CerberusImpl.defaultImpl` (signed) and
  `CerberusImpl.hafniumImpl` (unsigned, Caesium's `char`) are plain values. Select in process with
  `letI : CerberusImpl.ImplProfile := CerberusImpl.hafniumImpl`, at the drivers with `--impl-profile=hafnium`.
- Under `hafnium`, `case '\377':` reads 255 on both engines, and execution is consistent with it (store, load,
  promotions, the ranges): 22 witness programs equal to `gcc -funsigned-char`, `scripts/check_impl_profile.sh`.

At your re-pin: every definition that reads the profile gained the binder `[CerberusImpl.ImplProfile]` (order
`[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`). The full list, the default instance's `rfl` lemmas
and what a proof needs are in `2026-11-22_consumer-note-cerberus-sl-impl-profile.md`; the Cabs JSON's new
`impl_profile` field and the importer's refusal of a document exported under another profile are in
`2026-11-22_consumer-note-refinedc-lean-impl-profile.md`. Core quotation (your `--module` flow) is refused under a
non-default profile: a quoted module does not record the profile it was elaborated under, so under `hafnium` you run
the pipeline in process or through the driver, not from a quotation.

`hafnium` is validated by that one lane and nothing else in this repository.
