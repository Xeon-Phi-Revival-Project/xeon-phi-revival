#include <math.h>
#include <stdio.h>

int main(void) {
    double value = sqrt(144.0);
    printf("sqrt=%0.1f\n", value);
    return value == 12.0 ? 0 : 1;
}
