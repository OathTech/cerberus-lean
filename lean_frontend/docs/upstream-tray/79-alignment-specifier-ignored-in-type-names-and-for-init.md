# An alignment specifier is ignored in a type name and on a `for`-init declaration

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`: `desugar_type_name` (:3320-3321, `(* TODO: align_specs is ignored here *)`); the `CabsSfor (Just (FC_decl ...))` arm registers the object with alignment `Nothing` (:4339, :4342, :4345, :4349, :4351) where the block-scope arm calls `desugar_alignment_specifiers` (:4002).

## Description

C17 6.7.5#2 permits an alignment specifier in the type name of a compound literal and in the declaration specifiers of any declaration (a `for`-init declaration is one, 6.8.5#3); in every other type name it is a constraint violation. The object is created at its type's natural alignment in the two permitted forms, and the violation is accepted in the others.

## Reproducers

Compound literal:

```c
int main(void) { char pad = 0; char *p = &(_Alignas(64) char){0}; return ((unsigned long)p % 64 != 0) + pad; }
```

Upstream: `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0.

For-init:

```c
int main(void) { char pad = 0; for (_Alignas(64) char c = 0; ; ) return ((unsigned long)&c % 64) != 0; return pad; }
```

Upstream: `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0.

`_Alignof` type name:

```c
int main(void) { return _Alignof(_Alignas(16) int); }
```

Upstream: `Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}`. gcc: rejects.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W7, W8; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

The for-init form is FIXED by mirroring the block-scope arm (both engines answer 0). The compound literal is a declared REFUSAL (Ail's `AilEcompound` has no alignment; building one is upstream's design decision). Every other type name gets the constraint violation of 6.7.5#2 (`IllegalAlignas_type_name`).

## Patch

For the for-init arm (commit `4b260827c`): before `mk_desug_init ()`, `desugar_alignment_specifiers ident_loc ty specifs.alignment_specifiers >>= fun align_opt ->` (with the block arm's `IllegalAlignas_register` check) and `align_opt` in place of the five `Nothing`.
