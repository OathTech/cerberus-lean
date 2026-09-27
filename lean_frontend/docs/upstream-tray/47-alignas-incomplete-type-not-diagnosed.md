# `_Alignas(type-name)` never checks that the type is complete: a §6.5.3.4#1 constraint violation is accepted, and the program then hangs or crashes with `Not_found` instead of being diagnosed

**Affected:** `frontend/model/cabs_to_ail.lem` (upstream `master` @ `b9aeedcb4`),
`desugar_alignment_specifier` (`:2757-2761`) and its consumer's `AlignType` arm
(`:2853-2874`); `frontend/model/ail/ailTypesAux.lem:1288-1293`
(`agnostic_alignment_requirement_ord`).

C11 §6.7.5#5: "The first form is equivalent to `_Alignas (_Alignof (type-name))`."
§6.5.3.4#1, last sentence: "The `_Alignof` operator shall not be applied to a function
type or an incomplete type." So `_Alignas(T)` with an incomplete or function `T` is a
constraint violation and requires a diagnostic (§5.1.1.3#1).

Cerberus already diagnoses exactly this constraint for the EXPRESSION form: `AilEalignof`
in `frontend/model/ail/genTyping.lem` checks `AAux.is_function ty || AAux.is_incomplete
sigm ty` and raises `AlignofInvalidApplication` (`constraint.lem:87`, "§6.5.3.4#1, sentence
2"). The alignment SPECIFIER path never reaches that check:

```
and desugar_alignment_specifier loc align_spec =
  match align_spec with
    | AS_type tyname ->
      desugar_type_name tyname >>= fun (_, ty) ->
      E.return (Just (Ctype.AlignType ty))
```

and the consumer then compares alignments without asking whether `al_ty` has one:

- for a CHARACTER-typed member, `agnostic_alignment_requirement_ord` returns `Just LT`
  before looking at `al_ty` (`ailTypesAux.lem:1290-1291`), and the `Just LT` arm stores
  `AlignType al_ty` unexamined (`cabs_to_ail.lem:2872-2873`);
- for any other member, the `Nothing` arm calls `alignof_ty al_ty` on the incomplete type,
  which raises `Not_found` inside the implementation's layout code.

No later pass checks the stored `AlignType`.

## Reproducers

```c
/* alignas_self.c — char member, the struct being defined (incomplete until its closing brace) */
struct A { _Alignas(struct A) char c; };
int main(void) { return sizeof(struct A); }
```

```c
/* alignas_fwd.c — char member, a forward-declared struct */
struct Fwd;
struct A { _Alignas(struct Fwd) char c; };
int main(void) { return sizeof(struct A); }
```

```c
/* alignas_int_self.c — non-character member */
struct A { _Alignas(struct A) int c; };
int main(void) { return sizeof(struct A); }
```

```c
/* alignas_ok_control.c — control: a complete type */
struct B { int x; };
struct A { _Alignas(struct B) char c; };
int main(void) { return sizeof(struct A); }
```

## Observed vs expected

Run 2026-09-27: pristine upstream `b9aeedcb4` built with upstream Lem `3802cb0`
(`--exec --batch --nolibc`, 30 s bound); gcc 13.3.0 `-std=c11 -fsyntax-only`.

| Program | gcc | pristine upstream |
|---|---|---|
| `alignas_self.c` | `error: invalid application of '__alignof__' to incomplete type 'struct A'`, rc 1 | no output, **rc 124** (does not terminate) |
| `alignas_fwd.c` | `error: invalid application of '__alignof__' to incomplete type 'struct Fwd'`, rc 1 | `cerberus: internal error, uncaught exception: Not_found`, **rc 125** |
| `alignas_int_self.c` | `error: invalid application of '__alignof__' to incomplete type 'struct A'`, rc 1 | `cerberus: internal error, uncaught exception: Not_found`, **rc 125** |
| `alignas_ok_control.c` | rc 0 | `Defined {value: "Specified(4)", …}`, rc 0 |

Expected on the first three: a constraint-violation diagnostic citing §6.5.3.4#1 (via
§6.7.5#5), as for `_Alignof(struct A)` in an expression.

Why `alignas_self.c` does not terminate: `struct A`'s only member carries `AlignType
(struct A)`, so computing `alignof(struct A)` asks for the member's alignment, which is
`alignof(struct A)` again. The tag table has a by-value self-edge that §6.7.2.1#3 and
§6.5.3.4#1 together make impossible for a correctly diagnosed program.

## Impact

Minor in frequency, but the failure shapes are the bad ones: an accepted constraint
violation followed by non-termination or an uncaught internal exception, rather than the
diagnostic the standard requires and gcc gives. Any downstream reasoning that assumes a
well-founded layout for every program the frontend accepts (layout recursion terminates;
the tag table is acyclic through by-value and alignment edges) is broken by the first
reproducer.

## Proposed remedy

Check the §6.5.3.4#1 constraint where the specifier is desugared, reusing the existing
constraint constructor:

```
    | AS_type tyname ->
      desugar_type_name tyname >>= fun (qs, ty) ->
      E.is_complete_object ty >>= fun is_complete ->
      if AilTypesAux.is_function ty || not is_complete then
        E.constraint_violation loc (AlignofInvalidApplication qs ty)
      else
        E.return (Just (Ctype.AlignType ty))
```

(or a dedicated `AlignasInvalidApplication` if the message should name `_Alignas`). The
fix slice must confirm that the tag being defined is reported incomplete inside its own
member list; §6.7.2.3#4 makes it incomplete until the closing brace, and the
`alignas_self.c` case depends on it. The `Just LT` shortcut and the `Nothing` arm then
only ever see complete types.

## Classification

**TRUE BUG**, minor: a missed constraint diagnostic (§6.5.3.4#1 via §6.7.5#5) whose
consequences are non-termination (`alignas_self.c`) and uncaught internal exceptions
(`alignas_fwd.c`, `alignas_int_self.c`). ISO-unambiguous; gcc agrees.

## Provenance

Found by this project's C4 pre-merge audit (finding F-A2,
`lean_frontend/docs/2026-09-05_fuel-parameter-C4-audit-premerge.md` §5.2, the
`alignas_self.c` case, 2026-09-05); widened to the forward-declared and non-character
shapes and re-run on all engines on 2026-09-27 by the orchestrator. Operator ruling
[USER 2026-09-27]: "yes, 'constraint violation' - and this goes in the tray if it isn't
there already". Drafted by Claude (Opus 5.5) under operator direction; the filed issue
carries an AI-provenance note per the tray's policy (`INDEX.md`, "Provenance labeling
policy").

## Fork status (2026-09-27) — not yet fixed in the fork

The fork's OCaml oracle behaves as upstream on all four programs (rc 124 / 125 / 125 / 0,
verbatim above). The Lean port fails loudly but differently: `alignas_self.c`
`CerbMem.memberAlign: fuel exhausted` (rc 134); `alignas_fwd.c` `PANIC … CerbMem.alignofCtype:
Struct tag not a StructDef (OCaml: assert false / Not_found)` (rc 134); `alignas_int_self.c`
`Error {msg: "desugaring failed at …:1:35-36"}` (rc 1) where the oracle crashes with
`Not_found`; the control agrees (`Specified(4)`). The operator has ruled the fork fix a
constraint violation (next-phase plan §11, item P2d-3); once landed, all three engines give
the same diagnostic and this draft's pristine rows become register rows until upstream fixes
it.
