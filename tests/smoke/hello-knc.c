#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>

int main(void) {
    struct utsname uts;

    puts("hello from knc");

    if (uname(&uts) == 0) {
        printf("sysname=%s\n", uts.sysname);
        printf("nodename=%s\n", uts.nodename);
        printf("release=%s\n", uts.release);
        printf("machine=%s\n", uts.machine);
    }

    printf("sizeof(void*)=%zu\n", sizeof(void *));
    printf("sizeof(long)=%zu\n", sizeof(long));

    return EXIT_SUCCESS;
}
