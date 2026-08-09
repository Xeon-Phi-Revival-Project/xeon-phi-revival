#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void write_marker(const char *marker)
{
    static const char *paths[] = {
        "/xpr-handoff.log",
        "/dev/console",
        "/dev/kmsg",
    };
    size_t i;

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
}

int main(void)
{
    char *const argv[] = {
        (char *)"busybox",
        (char *)"sh",
        (char *)"/sbin/xpr-rc-init.sh",
        NULL,
    };
    char *const envp[] = {
        (char *)"HOME=/root",
        (char *)"PATH=/opt/xeon-phi-revival/bin:/bin:/usr/bin:/usr/sbin",
        NULL,
    };
    char failure[96];
    int notify;

    write_marker("XPR_RC_TRAMPOLINE_ENTERED");
    execve("/bin/busybox", argv, envp);

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
