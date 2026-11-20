# A `for`-init array whose size comes from its initializer crashes

**Affected:** `frontend/model/cabs_to_ail.lem:4345` @ `c3ff8c53f`: the binding keeps the type before the initializer completes it (`ty`, where :4338-4339 registers `ty'`).

## Description

C17 6.7.9#22: an array of unknown size is completed by its initializer.

## Reproducers

```c
int main(void) { for (int a[] = {1, 2, 3}; ; ) return sizeof a + a[2]; }
```

Upstream: `cerberus: internal error, uncaught exception:` (the Lean port: `UPSTREAM_CRASH ... sizeofIncompleteArray`). gcc: 15.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.3 C7; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
