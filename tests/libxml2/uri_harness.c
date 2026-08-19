/* uri_harness.c — arc-5 S3 STRETCH: differential harness over libxml2's
 * xmlParseURISafe (uri.c recursive-descent RFC 3986 parser), linked as
 * 5 TUs: uri_harness.c + uri.c + xmlstring.c + xmlmemory.c + globals.c
 * (globals.c: xmlMalloc & co. are global function-pointer VARIABLES defined
 * there — probe report, execution datapoint). Corpus: valid / invalid /
 * edge-case URIs; per-URI observation line + accumulated checksum, exactly
 * the chvalid battery convention. Whatever fraction of this runs through
 * the LEAN pipeline is recorded as the arc-6 baseline
 * (tests/libxml2/uri_baseline.txt) — reporting, not a pass/fail bar.
 */
#include <libxml/uri.h>
#include <stdio.h>

static const char *tests[] = {
    "http://user@example.com:8080/a/b?q=1#frag", /* valid: every component */
    "http://exa mple.com/",                      /* invalid: raw space (probe error path) */
    "//host/a/b",                                /* network-path reference */
    "mailto:someone@example.com",                /* scheme + opaque-ish path, no authority */
    "a/b/../c?x=%41",                            /* relative ref, dot-segments + pct-encoding */
    "",                                          /* empty string (valid empty reference) */
    "http://example.com:8080000000/",            /* oversized port digits */
    "urn:example:animal:ferret:nose",            /* urn scheme */
    "?query#frag",                               /* query+fragment only */
    "http://%zz/",                               /* invalid pct-escape in host */
};

#define NTESTS (sizeof(tests) / sizeof(tests[0]))

static const char *ordash(const char *s) { return s != NULL ? s : "-"; }

int main(void) {
    unsigned int h = 5381u;
    unsigned int i;
    for (i = 0u; i < (unsigned int)NTESTS; i++) {
        xmlURIPtr uri = NULL;
        int rc = xmlParseURISafe(tests[i], &uri);
        printf("uri %u rc=%d", i, rc);
        h = h * 33u + (unsigned int)(rc + 1000);
        if (uri != NULL) {
            printf(" scheme=%s server=%s port=%d path=%s query_raw=%s fragment=%s",
                   ordash(uri->scheme), ordash(uri->server), uri->port,
                   ordash(uri->path), ordash(uri->query_raw),
                   ordash(uri->fragment));
            h = h * 33u + (unsigned int)(uri->port + 1000);
            h = h * 33u + (unsigned int)(uri->scheme != NULL)
                        + 2u * (unsigned int)(uri->server != NULL)
                        + 4u * (unsigned int)(uri->path != NULL)
                        + 8u * (unsigned int)(uri->query_raw != NULL)
                        + 16u * (unsigned int)(uri->fragment != NULL);
            xmlFreeURI(uri);
        }
        printf("\n");
    }
    printf("uri_harness n=%u h=%u\n", (unsigned int)NTESTS, h);
    return (int)(h % 1000000007u);
}
