#include <stdio.h>
#include <curses.h>

int main(void) {
    const char *version = curses_version();

    printf("ncurses version=%s\n", version ? version : "(null)");
    return version ? 0 : 10;
}
