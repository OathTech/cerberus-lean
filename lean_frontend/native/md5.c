/* MD5 digest + per-TU digest global for CerberusFresh (arc 5 / S2).

   Mirrors the OCaml digest machinery used by the multi-TU frontend:
     * OCaml `Digest.string`/`Digest.file` = MD5 (RFC 1321); the frontend
       sets a per-translation-unit digest before each TU's parse/desugar
       (`Cerb_fresh.set_digest filename`, backend/common/pipeline.ml:181,
       ref cell in util/cerb_fresh.ml:7-10) and every Symbol.fresh draws
       it (frontend/model/symbol.lem:238 `Symbol (digest()) ...`).
     * cerb_md5_hex: MD5 of a Lean string's bytes, rendered as 32-char
       lowercase hex — i.e. Digest.to_hex(Digest.string s). We store
       digests in hex form (Lean strings must be UTF-8; raw MD5 bytes are
       not). Equality is preserved exactly, and ordering too: lowercase
       hex is byte-wise order-isomorphic to the raw 16-byte string
       ('0'<'1'<...<'9'<'a'<...<'f' in ASCII matches nibble order), so
       CerberusFresh.digest_compare over hex agrees with OCaml
       Digest.compare (= String.compare over raw bytes) on the order of
       any two digests. Divergence record: see CerberusFresh.lean.
     * cerb_digest_get/set: the Cerb_fresh.digest ref cell
       (util/cerb_fresh.ml:7-10; init "" — matched here: get before any
       set returns "").

   MD5 core: RFC 1321 reference-style, single-shot over the whole buffer
   (the frontend digests whole files; no streaming needed).

   Calling convention (Lean ≥ 4.29 new code generator): the RealWorld
   token is erased, so BaseIO externs receive only their explicit
   arguments and return the result value DIRECTLY (no
   lean_io_result_mk_ok wrapper). cerb_md5_hex is a PURE extern (MD5 is a
   pure function) — no BaseIO. Effect-armoring for the mutable global
   lives on the Lean side (CerberusFresh.lean, CerbTags.lean pattern). */
#include <lean/lean.h>
#include <stdint.h>
/* no <string.h>: leanc's clang ships only compiler-builtin headers;
   the two uses below are hand-rolled loops */

/* ---------------- MD5 (RFC 1321) ---------------- */

typedef uint32_t u32;

/* K[i] = floor(abs(sin(i+1)) * 2^32)  (RFC 1321 §3.4 T table) */
static const u32 md5_K[64] = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
};

/* per-operation left-rotate amounts (RFC 1321 §3.4 rounds 1-4) */
static const uint8_t md5_S[64] = {
    7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
};

static u32 md5_rotl(u32 x, uint8_t c) {
    return (x << c) | (x >> (32 - c));
}

/* Process one 64-byte block (little-endian word load). */
static void md5_block(u32 state[4], const uint8_t *p) {
    u32 M[16];
    for (int i = 0; i < 16; i++)
        M[i] = (u32)p[4*i] | ((u32)p[4*i+1] << 8)
             | ((u32)p[4*i+2] << 16) | ((u32)p[4*i+3] << 24);
    u32 A = state[0], B = state[1], C = state[2], D = state[3];
    for (int i = 0; i < 64; i++) {
        u32 F;
        int g;
        if (i < 16)      { F = (B & C) | (~B & D);  g = i; }
        else if (i < 32) { F = (D & B) | (~D & C);  g = (5*i + 1) & 15; }
        else if (i < 48) { F = B ^ C ^ D;           g = (3*i + 5) & 15; }
        else             { F = C ^ (B | ~D);        g = (7*i) & 15; }
        u32 tmp = D;
        D = C;
        C = B;
        B = B + md5_rotl(A + F + md5_K[i] + M[g], md5_S[i]);
        A = tmp;
    }
    state[0] += A; state[1] += B; state[2] += C; state[3] += D;
}

/* MD5 of (data, len) → 16 bytes out (RFC 1321 §3.1-3.5: pad 0x80,
   zeros to 56 mod 64, 64-bit little-endian bit length; digest is the
   little-endian bytes of state A,B,C,D). */
static void md5(const uint8_t *data, size_t len, uint8_t out[16]) {
    u32 state[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    size_t n = len;
    const uint8_t *p = data;
    while (n >= 64) {
        md5_block(state, p);
        p += 64;
        n -= 64;
    }
    uint8_t tail[128];
    for (size_t i = 0; i < sizeof tail; i++) tail[i] = 0;
    for (size_t i = 0; i < n; i++) tail[i] = p[i];
    tail[n] = 0x80;
    size_t tail_len = (n < 56) ? 64 : 128;
    uint64_t bitlen = (uint64_t)len << 3;
    for (int i = 0; i < 8; i++)
        tail[tail_len - 8 + i] = (uint8_t)(bitlen >> (8 * i));
    md5_block(state, tail);
    if (tail_len == 128)
        md5_block(state, tail + 64);
    for (int i = 0; i < 4; i++) {
        out[4*i]   = (uint8_t)(state[i]);
        out[4*i+1] = (uint8_t)(state[i] >> 8);
        out[4*i+2] = (uint8_t)(state[i] >> 16);
        out[4*i+3] = (uint8_t)(state[i] >> 24);
    }
}

/* ---------------- Lean externs ---------------- */

/* CerberusFresh.md5Hex : @& String → String (pure)
   = Digest.to_hex (Digest.string s): lowercase hex, like OCaml's
   Digest.to_hex (stdlib digest.ml uses "%02x"). */
LEAN_EXPORT lean_obj_res cerb_md5_hex(b_lean_obj_arg s) {
    const uint8_t *data = (const uint8_t *)lean_string_cstr(s);
    size_t len = lean_string_size(s) - 1;  /* size includes the NUL */
    uint8_t dig[16];
    md5(data, len, dig);
    char hex[33];
    static const char hexdig[] = "0123456789abcdef";
    for (int i = 0; i < 16; i++) {
        hex[2*i]   = hexdig[dig[i] >> 4];
        hex[2*i+1] = hexdig[dig[i] & 0xf];
    }
    hex[32] = '\0';
    return lean_mk_string(hex);
}

/* The per-TU digest global — mirror of Cerb_fresh's `digest` ref cell
   (util/cerb_fresh.ml:7-10): init "", set once per TU, read by every
   Symbol fresh draw. Same native-global pattern as tags.c. */
static lean_object *cerb_digest = NULL;

/* CerberusFresh.digestIO : @& Unit → BaseIO String */
LEAN_EXPORT lean_obj_res cerb_digest_get(b_lean_obj_arg unit) {
    if (cerb_digest == NULL)
        return lean_mk_string("");
    lean_inc(cerb_digest);
    return cerb_digest;
}

/* CerberusFresh.setDigestIO : @& String → BaseIO Unit */
LEAN_EXPORT lean_obj_res cerb_digest_set(b_lean_obj_arg v) {
    if (cerb_digest != NULL)
        lean_dec(cerb_digest);
    lean_inc(v);
    cerb_digest = v;
    return lean_box(0);
}

/* CerberusFresh.forceIO : (Unit → b) → BaseIO b — an IO-positioned
   evaluation barrier. The Lean compiler sinks pure lets to their use
   sites, so a pure stage call (desugar/translate — which read the
   digest global internally via `CerberusFresh.digest ()`) written
   between two setDigestIO actions can be deferred past the LATER set
   and observe the wrong TU's digest (demonstrated by
   test/Unit/FreshIntTest.lean testDigestGlobal, first build of this
   file: both `fresh ()` draws saw the second digest). Evaluating the
   thunk INSIDE an extern BaseIO call pins the evaluation to its
   position in the IO bind chain — extern calls are never reordered —
   and the closure boundary blocks let-sinking out of the body. Same
   whole-extent-in-C rationale as tags.c cerb_tags_with (arc-4 S3b). */
LEAN_EXPORT lean_obj_res cerb_force_thunk(b_lean_obj_arg f) {
    lean_inc(f);
    return lean_apply_1(f, lean_box(0));
}
