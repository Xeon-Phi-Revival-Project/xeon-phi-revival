/* K1OM libffi call, aggregate, floating-point, and closure acceptance test. */
#include <ffi.h>

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    long first;
    long second;
} pair_t;

static long sum8(long a, long b, long c, long d,
                 long e, long f, long g, long h)
{
    return a + b + c + d + e + f + g + h;
}

static double add_double(double a, double b)
{
    return a + b;
}

static float add_float(float a, float b)
{
    return a + b;
}

static pair_t swap_pair(pair_t value)
{
    pair_t result = {value.second, value.first};
    return result;
}

static void closure_add(ffi_cif *cif, void *result, void **args, void *userdata)
{
    long bias = *(long *)userdata;
    (void)cif;
    *(long *)result = *(long *)args[0] + *(long *)args[1] + bias;
}

static void require_status(const char *name, ffi_status status)
{
    if (status != FFI_OK) {
        fprintf(stderr, "%s failed: ffi_status=%d\n", name, (int)status);
        exit(10);
    }
}

int main(void)
{
    ffi_cif cif;
    void *values[8];
    long integers[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    ffi_type *long_args[8] = {
        &ffi_type_slong, &ffi_type_slong, &ffi_type_slong, &ffi_type_slong,
        &ffi_type_slong, &ffi_type_slong, &ffi_type_slong, &ffi_type_slong
    };
    long long_result = 0;
    int index;

    setvbuf(stdout, NULL, _IONBF, 0);
    puts("stage=sum8-prep");
    for (index = 0; index < 8; ++index)
        values[index] = &integers[index];
    require_status("sum8 prep",
                   ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 8,
                                &ffi_type_slong, long_args));
    puts("stage=sum8-call");
    ffi_call(&cif, FFI_FN(sum8), &long_result, values);
    printf("sum8=%ld\n", long_result);
    if (long_result != 36)
        return 20;

    {
        puts("stage=double");
        double left = 1.25;
        double right = 2.5;
        double result = 0.0;
        ffi_type *args[2] = {&ffi_type_double, &ffi_type_double};
        void *argv[2] = {&left, &right};
        require_status("double prep",
                       ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2,
                                    &ffi_type_double, args));
        ffi_call(&cif, FFI_FN(add_double), &result, argv);
        printf("double=%.2f\n", result);
        if (fabs(result - 3.75) > 0.0001)
            return 21;
    }

    {
        puts("stage=float");
        float left = 1.5f;
        float right = 2.25f;
        float result = 0.0f;
        ffi_type *args[2] = {&ffi_type_float, &ffi_type_float};
        void *argv[2] = {&left, &right};
        require_status("float prep",
                       ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2,
                                    &ffi_type_float, args));
        ffi_call(&cif, FFI_FN(add_float), &result, argv);
        printf("float=%.2f\n", (double)result);
        if (fabsf(result - 3.75f) > 0.0001f)
            return 22;
    }

    {
        puts("stage=strlen");
        const char *text = "k1om-libffi";
        size_t result = 0;
        ffi_type *args[1] = {&ffi_type_pointer};
        void *argv[1] = {&text};
        require_status("strlen prep",
                       ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1,
                                    &ffi_type_ulong, args));
        ffi_call(&cif, FFI_FN(strlen), &result, argv);
        printf("strlen=%lu\n", (unsigned long)result);
        if (result != 11)
            return 23;
    }

    {
        puts("stage=pair");
        pair_t input = {10, 20};
        pair_t result = {0, 0};
        ffi_type pair_type;
        ffi_type *elements[3] = {
            &ffi_type_slong, &ffi_type_slong, NULL
        };
        ffi_type *args[1] = {&pair_type};
        void *argv[1] = {&input};
        pair_type.size = 0;
        pair_type.alignment = 0;
        pair_type.type = FFI_TYPE_STRUCT;
        pair_type.elements = elements;
        require_status("pair prep",
                       ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1,
                                    &pair_type, args));
        ffi_call(&cif, FFI_FN(swap_pair), &result, argv);
        printf("pair=%ld,%ld\n", result.first, result.second);
        if (result.first != 20 || result.second != 10)
            return 24;
    }

    {
        puts("stage=closure");
        ffi_closure *closure;
        void *code = NULL;
        ffi_type *args[2] = {&ffi_type_slong, &ffi_type_slong};
        long bias = 7;
        long result;
        closure = ffi_closure_alloc(sizeof(*closure), &code);
        if (closure == NULL || code == NULL) {
            fprintf(stderr, "closure allocation failed\n");
            return 25;
        }
        require_status("closure cif prep",
                       ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2,
                                    &ffi_type_slong, args));
        require_status("closure prep",
                       ffi_prep_closure_loc(closure, &cif, closure_add,
                                            &bias, code));
        result = ((long (*)(long, long))code)(4, 5);
        printf("closure=%ld\n", result);
        ffi_closure_free(closure);
        if (result != 16)
            return 26;
    }

    printf("k1om_libffi_smoke_ok pid=%ld\n", (long)getpid());
    return 0;
}
