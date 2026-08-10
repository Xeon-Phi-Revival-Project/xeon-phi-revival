#include <dlfcn.h>
#include <stdio.h>

int main(void)
{
    void *handle = dlopen("libm.so.6", RTLD_NOW);

    if (handle == NULL)
        return 1;
    if (dlsym(handle, "cos") == NULL) {
        dlclose(handle);
        return 2;
    }
    dlclose(handle);
    puts("xpr-dlopen-smoke: ok");
    return 0;
}
