/* Minimal project-owned status endpoint for clean-root boot evidence. */

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#ifndef XPR_STATUS_PORT
#define XPR_STATUS_PORT 31337
#endif

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
    address.sin_port = htons(XPR_STATUS_PORT);
    if (bind(listener, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        listen(listener, 4) != 0) {
        close(listener);
        return 2;
    }
    for (;;) {
        int client = accept(listener, 0, 0);
        if (client >= 0) {
            int logfd;
            char buffer[512];
            ssize_t length;
            (void)write(client, reply, sizeof(reply) - 1);
            logfd = open("/run/xpr-os-init", O_RDONLY);
            if (logfd >= 0) {
                while ((length = read(logfd, buffer, sizeof(buffer))) > 0) {
                    (void)write(client, buffer, (size_t)length);
                }
                close(logfd);
            }
            close(client);
        }
    }
}
