Axiomatic model .cat files in isla-cat:

| License      | Files                             | From      |
| ------------ | --------------------------------- | --------- |
| MIT          | runtime/bmc/c11.cat               | memalloy  |
| GPL 2.0+     | runtime/bmc/linux.cat             | linux     |
| GPL 2.0+     | runtime/bmc/linux_without_rcu.cat | linux     |

---

The following file is derived from the U. Cambridge Cppmem project:

| License      | Files                             | From      |
| ------------ | --------------------------------- | --------- |
| BSD 3-Clause | frontend/concurrency/cmm_csem.lem | cppmem    |
| BSD 3-Clause | backend/common/auxl.ml            | cppmem    |
| BSD 3-Clause | backend/bmc/bmc_types.ml          | cppmem    |

(see the license notice there)

---

The fragment of the C standard library is based on the musl-libc and BSD:

| License      | Files                                  | From      |
| ------------ | -------------------------------------- | --------- |
| MIT          | runtime/libc/src/*.{c,h}               | musl-libc |
| BSD 4-Clause | runtime/libc/include/posix/sys/ioctl.h | BSD       |
| BSD 4-Clause | runtime/libc/include/posix/sys/cdefs.h | BSD       |

(see LICENSE file in that directory)

---

A slightly modified version of SibylFS is included:

| License      | Files                  | From      |
| ------------ | ---------------------- | --------- |
| ISC          | sibylfs/*              | SibylFS   |

(see LICENSE file in that directory)

---

The web interface contains MIT-licensed javascript:

| License | Files                              | From         |
| ------- | ---------------------------------- | ------------ |
| MIT     | public/src/js/clike.js             | codemirror   |
| MIT     | public/src/js/core.js              | codemirror   |
| MIT     | public/src/js/gas.js               | codemirror   |
| MIT     | public/src/js/herd.js              | codemirror   |
| MIT     | public/src/js/ocaml.js             | codemirror   |
| MIT     | public/src/js/panzoom.js           | panzoom      |
| MIT     | public/src/js/placeholder.js       | codemirror   |
| MIT     | public/src/css/codemirror.css      | codemirror   |
| MIT     | public/src/css/goldenlayout-\*.css | goldenlayout |

---

The following files were generated from the WG14 N1570 document:

| Files              |
| ------------------ |
| tools/n1570.html   |
| tools/n1570.json   |
| tools/n1570_2.html |

---

In the test/ directory:

| License      | Files                                           | From                                 |
| ------------ | ----------------------------------------------- | ------------------------------------ |
| BSD 3-Clause | tests/freebsd/{cat.c,echo.c}                    | FreeBSD                              |
| GPL          | tests/gcc-torture/*.{c,h}                       | GCC torture tests                    |
| BSD 4-Clause | tests/gcc-torture/breakdown/success/pr20527-1.c | Bzip2 (as part of GCC torture tests) |
| BSD 4-Clause | tests/gcc-torture/execute/pr20527-1.c           | Bzip2 (as part of GCC torture tests) |
| BSD 3-Clause | tests/tcc/*                                     | TinyCC                               |
| Apache 2.0   | tests/hacl-star/*                               | hacl-star                            |
| BSD 2-Clause | tests/csmith/runtime/csmith.h                   | Csmith                               |
| BSD 2-Clause | tests/csmith/runtime/csmith_minimal.h           | Csmith                               |
| BSD 2-Clause | tests/csmith/runtime/custom_stdint_x86.h        | Csmith                               |
| LGPL         | tests/csmith/runtime/custom_limits.h            | Csmith                               |
| BSD 2-Clause | tests/csmith/runtime/safe_math.h                | Csmith                               |

---

Native helpers of the Lean frontend (`lean_frontend/native/`):

| License                                   | Files                        | From                                                                 |
| ----------------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| Cerberus (this repository's LICENSE)      | lean_frontend/native/md5.c   | written in this repository (commit 8c4fbdd8b, arc 5 S2, 2026-08)     |

Provenance as verifiable from the file and its history (entry added
2026-09-02): `md5.c` is an in-repo, single-shot implementation of the MD5
algorithm as specified in RFC 1321 (the 64-entry T table and the per-round
rotation amounts are the algorithm's published constants), mirroring OCaml's
`Digest.string`/`Digest.to_hex` for the per-TU digest seam. It is NOT a copy
of the RSA Data Security, Inc. reference implementation (no `MD5_CTX` /
`MD5Init`/`MD5Update`/`MD5Final`, no `FF`/`GG`/`HH`/`II` macros, no RSA
copyright notice) and carries no third-party notice of any kind; it is
covered by this repository's license like the rest of the Lean frontend.
