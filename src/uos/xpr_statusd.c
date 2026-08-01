/* Minimal project-owned status endpoint for clean-root boot evidence. */

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main(void) {
    const char reply[] = "XPR_CLEAN_ROOT_READY\nXPR_MPSS_READY_NOTIFIED\n";
    struct sockaddr_in address;
    int listener;

    listener = socket(AF_INET, SOCK_STREAM, 0);
    if (listener < 0) {
        return 1;
    }
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(31337);
    if (bind(listener, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        listen(listener, 4) != 0) {
        close(listener);
        return 2;
    }
    for (;;) {
        int client = accept(listener, 0, 0);
        if (client >= 0) {
            (void)write(client, reply, sizeof(reply) - 1);
            close(client);
        }
    }
}
