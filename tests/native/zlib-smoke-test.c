#include <stdio.h>
#include <string.h>
#include "zlib.h"

int main(void) {
    const char *msg = "knc zlib smoke";
    unsigned char compressed[128];
    unsigned char out[128];
    uLongf clen = sizeof(compressed);
    uLongf olen = sizeof(out);
    int rc = compress2(compressed, &clen, (const Bytef *)msg, strlen(msg) + 1, Z_BEST_SPEED);

    if (rc != Z_OK) {
        printf("compress rc=%d\n", rc);
        return 10;
    }

    rc = uncompress(out, &olen, compressed, clen);
    if (rc != Z_OK) {
        printf("uncompress rc=%d\n", rc);
        return 11;
    }

    printf("zlib version=%s result=%s\n", zlibVersion(), out);
    return strcmp((const char *)out, msg) == 0 ? 0 : 12;
}
