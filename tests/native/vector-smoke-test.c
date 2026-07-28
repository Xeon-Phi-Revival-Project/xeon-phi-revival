#include <stdio.h>

int main(void) {
    double a = 1.0;
    double b = 10.0;
    double values[8] __attribute__((aligned(64)));

    __asm__ __volatile__(
        "vbroadcastsd %[a], %%zmm0\n\t"
        "vbroadcastsd %[b], %%zmm1\n\t"
        "vaddpd %%zmm1, %%zmm0, %%zmm2\n\t"
        "vmovapd %%zmm2, %[values]\n\t"
        : [values] "=m"(values)
        : [a] "m"(a), [b] "m"(b)
        : "memory"
    );

    printf("vector sum first=%0.1f last=%0.1f\n", values[0], values[7]);
    return values[0] == 11.0 && values[7] == 11.0 ? 0 : 1;
}
