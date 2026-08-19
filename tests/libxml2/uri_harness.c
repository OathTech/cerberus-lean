/* uri_harness.c — arc-5 S3 STRETCH / arc-6 S4 GATE: differential harness
 * over libxml2's xmlParseURISafe (uri.c recursive-descent RFC 3986 parser),
 * linked as 5 TUs: uri_harness.c + uri.c + xmlstring.c + xmlmemory.c +
 * globals.c (globals.c: xmlMalloc & co. are global function-pointer
 * VARIABLES defined there — probe report, execution datapoint). Corpus:
 * valid / invalid / edge-case URIs; per-URI observation line + accumulated
 * checksum, exactly the chvalid battery convention.
 *
 * Arc-6 S4: corpus grown 10 → 16 (indices 10-15, RFC 3986 edge classes:
 * IPv6 literal, empty components, scheme-only, lone fragment,
 * percent-encoded reserved chars with mixed hex case, empty authority) and
 * the harness is GATING: test_libxml2_uri.sh pins every lane's expectation
 * against tests/libxml2/uri_baseline.txt fail-closed, and LEAN_LIBC must
 * agree with ORACLE_LIBC byte-for-byte (16/16).
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
    /* --- arc-6 S4 additions (RFC 3986 edge classes) ------------------- */
    "http://[::1]:8080/v6",                      /* IP-literal host (IPv6, §3.2.2) + port */
    "http://@example.com:/x",                    /* empty userinfo + empty port: RFC-3986-valid class,
                                                    but libxml2's xmlParse3986Port requires >=1 digit
                                                    (deps/libxml2/uri.c:341-365) — expected rc=1 both sides */
    "s:",                                        /* minimal scheme, empty path */
    "#",                                         /* lone empty fragment */
    "/a%2Fb%2fc",                                /* pct-encoded reserved '/', upper+lower hex */
    "//",                                        /* network-path ref, empty authority */
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
