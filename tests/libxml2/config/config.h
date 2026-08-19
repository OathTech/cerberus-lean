/* Minimal hand-written config.h for running libxml2 TUs through Cerberus.
 * Provenance: notes/2026-08-19_libxml2-probe.md, Part B "Preprocessing
 * recipe" (no-autogen recipe). Deliberately omitted: XML_THREAD_LOCAL,
 * HAVE_FUNC_ATTRIBUTE_DESTRUCTOR, HAVE_DLOPEN.
 */
#define HAVE_DECL_GETENTROPY 0
#define HAVE_DECL_GLOB 0
#define HAVE_DECL_MMAP 0
#define HAVE_STDINT_H 1
