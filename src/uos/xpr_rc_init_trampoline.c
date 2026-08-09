#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern char **environ;

static void write_marker(const char *marker)
{
    static const char *paths[] = {
        "/xpr-handoff.log",
        "/dev/console",
        "/dev/kmsg",
    };
    size_t i;
    const char *handoff_fd_text;

    for (i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
        int flags = O_WRONLY | O_APPEND;
        int fd;

        if (i == 0)
            flags |= O_CREAT;
        fd = open(paths[i], flags, 0644);
        if (fd < 0)
            continue;
        (void)write(fd, marker, strlen(marker));
        (void)write(fd, "\n", 1);
        close(fd);
    }

    handoff_fd_text = getenv("XPR_HANDOFF_FD");
    if (handoff_fd_text != NULL) {
        char *end = NULL;
        long handoff_fd = strtol(handoff_fd_text, &end, 10);

        if (end != handoff_fd_text && *end == '\0' && handoff_fd >= 0) {
            (void)write((int)handoff_fd, marker, strlen(marker));
            (void)write((int)handoff_fd, "\n", 1);
            (void)fsync((int)handoff_fd);
        }
    }
}

int main(void)
{
    char *const argv[] = {
        (char *)"busybox",
        (char *)"sh",
        (char *)"/sbin/xpr-rc-init.sh",
        NULL,
    };
    char failure[96];
    int notify;

    write_marker("XPR_RC_TRAMPOLINE_ENTERED");
    (void)setenv("HOME", "/root", 1);
    (void)setenv("PATH", "/opt/xeon-phi-revival/bin:/bin:/usr/bin:/usr/sbin", 1);
    execve("/bin/busybox", argv, environ);

    snprintf(failure, sizeof(failure),
             "XPR_RC_TRAMPOLINE_EXEC_FAILED errno=%d", errno);
    write_marker(failure);

    /* Make a trampoline failure observable to the bounded host runner. */
    notify = open("/sys/class/micnotify/notify/host_notified", O_WRONLY);
    if (notify >= 0) {
        (void)write(notify, "done\n", 5);
        close(notify);
    }

    for (;;)
        pause();
}
