#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <unistd.h>

static int old_root_log_fd = -1;
static int new_root_log_fd = -1;

static void write_one(int fd, const char *text)
{
    if (fd < 0)
        return;
    (void)write(fd, text, strlen(text));
    (void)write(fd, "\n", 1);
    (void)fsync(fd);
}

static void mark(const char *text)
{
    write_one(old_root_log_fd, text);
    write_one(new_root_log_fd, text);
}

static void fail(const char *stage)
{
    char line[128];

    snprintf(line, sizeof(line), "XPR_SWITCH_HELPER_FAILED stage=%s errno=%d",
             stage, errno);
    mark(line);
    for (;;)
        pause();
}

int main(int argc, char **argv)
{
    char log_path[512];
    char *const init_argv[] = { (char *)"/sbin/init", NULL };
    char *const init_env[] = {
        (char *)"HOME=/root",
        (char *)"PATH=/opt/xeon-phi-revival/bin:/bin:/usr/bin:/usr/sbin",
        NULL,
    };

    if (argc != 3 || getpid() != 1)
        return 2;
    if (snprintf(log_path, sizeof(log_path), "%s/xpr-handoff.log", argv[1])
        >= (int)sizeof(log_path))
        return 2;

    old_root_log_fd = open("/xpr-switch-helper.log",
                           O_WRONLY | O_CREAT | O_APPEND, 0644);
    new_root_log_fd = open(log_path, O_WRONLY | O_CREAT | O_APPEND, 0644);
    mark("XPR_SWITCH_HELPER_ENTERED");

    if (chdir(argv[1]) != 0)
        fail("chdir-newroot");
    mark("XPR_SWITCH_HELPER_CHDIR_OK");

    if (mount(".", "/", NULL, MS_MOVE, NULL) != 0)
        fail("move-root");
    mark("XPR_SWITCH_HELPER_MOVE_ROOT_OK");

    if (chroot(".") != 0)
        fail("chroot");
    if (chdir("/") != 0)
        fail("chdir-root");
    mark("XPR_SWITCH_HELPER_CHROOT_OK");

    execve(argv[2], init_argv, init_env);
    fail("exec-init");
    return 127;
}
