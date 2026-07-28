#include <stdio.h>
#include <string.h>

int main(void) {
    const char *path = "/tmp/k1om-file-io-smoke.txt";
    const char *message = "k1om file io ok\n";
    char buffer[64];

    FILE *out = fopen(path, "w");
    if (!out) {
        puts("fopen write failed");
        return 1;
    }
    if (fputs(message, out) < 0) {
        puts("fputs failed");
        fclose(out);
        return 2;
    }
    if (fclose(out) != 0) {
        puts("fclose write failed");
        return 3;
    }

    FILE *in = fopen(path, "r");
    if (!in) {
        puts("fopen read failed");
        return 4;
    }
    if (!fgets(buffer, sizeof(buffer), in)) {
        puts("fgets failed");
        fclose(in);
        return 5;
    }
    fclose(in);
    remove(path);

    if (strcmp(buffer, message) != 0) {
        puts("file content mismatch");
        return 6;
    }

    puts("file io ok");
    return 0;
}
