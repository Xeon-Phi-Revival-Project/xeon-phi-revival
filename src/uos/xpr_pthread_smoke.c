#include <pthread.h>
#include <stdio.h>

static void *worker(void *argument) {
    return argument;
}

int main(void) {
    pthread_t thread;
    void *value = 0;
    if (pthread_create(&thread, 0, worker, (void *)42) != 0) {
        return 1;
    }
    if (pthread_join(thread, &value) != 0 || value != (void *)42) {
        return 2;
    }
    puts("XPR_PTHREAD_OK");
    return 0;
}
