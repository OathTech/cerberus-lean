# External SC operational consumer

This separate Lake package imports the provider by path. Its six kernel
statements use the actual exported definitions: history preservation, Core
choice membership, physical byte accounting, disabled observation, ownership
restoration preserving a memory assertion, and model faults distinct from UB.
It has no application-logic dependency or fixed semantic fuel.

From this directory, with the project environment loaded:

```sh
../../../scripts/capped lake build
```

The toolchain and dependency revision match the provider. Building this example
does not build or modify the customer repository. The statements do not claim
whole-program safety, ISO/Cmm adequacy, or public SC checker completeness.
