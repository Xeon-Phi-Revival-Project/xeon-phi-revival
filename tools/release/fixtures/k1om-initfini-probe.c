int initfini_probe(void) { return 1; }

int (*initfini_constructor)(void)
    __attribute__((section(".init_array"))) = initfini_probe;
int (*initfini_destructor)(void)
    __attribute__((section(".fini_array"))) = initfini_probe;
