# Golden fixture: return42

Minimal C program that returns 42. Used as the end-to-end smoke test
for the Lean pipeline.

## Files

- `source.c` — the C source
- `expected.txt` — expected final return value (42)
- `cabs.json` — (generated) OCaml `--cabs-json` output. Regenerate with:
  ```
  ./scripts/cerberus --cabs-json tests/fixtures/return42/source.c \
      > tests/fixtures/return42/cabs.json
  ```

As pipeline stages get working, additional goldens go here:
- `ail.txt` — AIL after desugaring
- `typed_ail.txt` — AIL after typechecking
- `core.txt` — Core after translation
- (the final result is already in `expected.txt`)

## Run

```
./scripts/test_golden.sh return42
```
