#include <pthread.h>
#include <stdio.h>

static void *worker(void *unused) {
    (void)unused;
    return (void *)123;
}

int main(void) {
    pthread_t thread;
    void *result = 0;
    if (pthread_create(&thread, 0, worker, 0) || pthread_join(thread, &result)) return 1;
    printf("XPR toolkit pthread result=%ld\n", (long)result);
    return result == (void *)123 ? 0 : 1;
}
