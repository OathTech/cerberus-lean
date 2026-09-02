/* Minimal hand-written config.h for running libxml2 TUs through Cerberus.
 * Provenance: the arc-5 libxml2 probe (2026-08-19), Part B "Preprocessing
 * recipe" (no-autogen; recipe restated in scripts/libxml2_prep.sh — the
 * probe note itself is in no commit). Deliberately omitted: XML_THREAD_LOCAL,
 * HAVE_FUNC_ATTRIBUTE_DESTRUCTOR, HAVE_DLOPEN.
 */
#define HAVE_DECL_GETENTROPY 0
#define HAVE_DECL_GLOB 0
#define HAVE_DECL_MMAP 0
#define HAVE_STDINT_H 1
