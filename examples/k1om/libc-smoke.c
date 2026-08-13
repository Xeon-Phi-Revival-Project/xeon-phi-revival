#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *text = malloc(32);
    if (text == NULL)
        return 1;
    snprintf(text, 32, "XPR libc smoke %d", 42);
    puts(text);
    free(text);
    return 0;
}
