# `[[cerb::with_address("...")]]` on an object ends the run in an uncaught `Failure` in the concrete allocator

**Affected:** `memory/concrete/impl_mem.ml` @ `c3ff8c53f`, `allocate_object` (:1118):
`failwith "TODO: cerb::with_address() is yet implemented"`, with the call of `allocator_with_address` commented out
on the next line. The request reaches it from `frontend/model/translation.lem` :4308 (`decode_with_address` on the
attributes of a `Decl_object`, which adds the `ACerb_with_address` annotation) through
`frontend/model/core_reduction.lem` :635/:657 (`get_with_address`, passed to `CreateRequest2`).

## Description

The attribute is one of Cerberus's own extension attributes. The front end reads it (one string argument, on the
attributes the desugaring stores for an object with linkage) and asks the memory model for the object at that
address; the concrete memory model answers with a `failwith`, so a program that writes the attribute where the front
end reads it ends in an internal error instead of a verdict or a declared "unsupported" message. Where the front end
does not read it (another placement, another number of arguments) the attribute has no effect.

## Reproducers

```c
[[cerb::with_address("0x1000")]] int g; int main(void) { return 0; }
```

Upstream:

```
cerberus: internal error, uncaught exception:
          Failure("TODO: cerb::with_address() is yet implemented")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Impl_mem.Concrete.allocate_object in file "memory/concrete/impl_mem.ml", line 1118, characters 12-68
```

The same end for `int g [[cerb::with_address("0x1000")]];`, for the second declarator of
`int a, g [[cerb::with_address("0x1000")]];`, for a block-scope `[[cerb::with_address("0x1000")]] extern int g;`
and for the attribute's tokens coming from a macro. These run to `Specified(0)` with the attribute ignored:

```c
[[cerb::with_address("0x1000", "x")]] int g; int main(void) { return 0; }
[[cerb::with_address]] int g; int main(void) { return 0; }
int main(void) { [[cerb::with_address("0x1000")]] int y = 0; return y; }
```

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @
`c3ff8c53f`.)

## Fork status

Refused in the fork, at the parser: an attribute named `cerb::with_address` is a declared stop wherever it is
written and whatever its arguments (`unimplemented keyword '[[cerb::with_address]] (refused, contract D19: ...)'`),
so no C program reaches the `failwith` through this attribute, and the forms upstream ran with the attribute
ignored stop too (fork contract D19; witness `tests/attribute_carriage/y_*.c`). The fork gives the attribute no
meaning and does not change the allocator.
