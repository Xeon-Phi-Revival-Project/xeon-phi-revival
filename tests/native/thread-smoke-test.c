#include <pthread.h>
#include <stdio.h>

static void *worker(void *arg) {
    return arg;
}

int main(void) {
    pthread_t thread;
    void *result = 0;
    if (pthread_create(&thread, 0, worker, (void *)123) != 0) {
        puts("pthread_create failed");
        return 1;
    }
    if (pthread_join(thread, &result) != 0) {
        puts("pthread_join failed");
        return 2;
    }
    printf("pthread result=%ld\n", (long)result);
    return result == (void *)123 ? 0 : 3;
}
