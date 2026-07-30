/*
 * Minimal K1OM PID 1 control init for Xeon Phi Revival experiments.
 *
 * This program intentionally avoids shell, BusyBox, Python, package tools, and
 * daemon startup. It writes fixed evidence to the console and idles forever.
 */

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static long xpr_syscall0(long n) {
    return syscall(n);
}

static long xpr_syscall1(long n, long a1) {
    return syscall(n, a1);
}

static long xpr_syscall3(long n, long a1, long a2, long a3) {
    return syscall(n, a1, a2, a3);
}

static void xpr_write_raw(int fd, const char *s) {
    const char *p = s;
    long len = 0;
    while (p[len] != '\0') {
        len++;
    }
    while (len > 0) {
        long rc = xpr_syscall3(SYS_write, fd, (long)p, len);
        if (rc <= 0) {
            return;
        }
        p += rc;
        len -= rc;
    }
}

static void xpr_write_ulong(int fd, unsigned long value) {
    char buf[32];
    int i = 31;
    buf[i] = '\0';
    if (value == 0) {
        xpr_write_raw(fd, "0");
        return;
    }
    while (value != 0 && i > 0) {
        i--;
        buf[i] = (char)('0' + (value % 10));
        value /= 10;
    }
    xpr_write_raw(fd, &buf[i]);
}

static void xpr_emit_to_fd(int fd) {
    xpr_write_raw(fd, "XPR_MIN_INIT_ENTERED\n");
    xpr_write_raw(fd, "PID=");
    xpr_write_ulong(fd, (unsigned long)xpr_syscall0(SYS_getpid));
    xpr_write_raw(fd, "\n");
    xpr_write_raw(fd, "PPID=");
    xpr_write_ulong(fd, (unsigned long)xpr_syscall0(SYS_getppid));
    xpr_write_raw(fd, "\n");
    xpr_write_raw(fd, "XPR_MIN_INIT_IDLE\n");
}

static void xpr_emit_path(const char *path) {
    long fd = xpr_syscall3(SYS_open, (long)path, O_WRONLY | O_NOCTTY, 0);
    if (fd >= 0) {
        xpr_emit_to_fd((int)fd);
        xpr_syscall1(SYS_close, fd);
    }
}

static void xpr_reap(void) {
    int status = 0;
    while (waitpid(-1, &status, WNOHANG) > 0) {
    }
}

int main(void) {
    struct timespec delay;

    signal(SIGCHLD, SIG_IGN);

    xpr_emit_to_fd(1);
    xpr_emit_to_fd(2);
    xpr_emit_path("/dev/console");
    xpr_emit_path("/dev/hvc0");
    xpr_emit_path("/dev/ttyMIC0");

    delay.tv_sec = 5;
    delay.tv_nsec = 0;

    for (;;) {
        xpr_reap();
        xpr_syscall3(SYS_nanosleep, (long)&delay, 0, 0);
    }
}
