#ifndef DEVMODE_H
#define DEVMODE_H


#if defined(DEV)
    #include <stdio.h>
    #define dputchar(c) putchar(c)
    #define dputs(msg) puts(msg)
    #define dprintf(fmt, ...) printf(fmt, ## __VA_ARGS__)
#else
    #define dputchar(c)
    #define dputs(msg)
    #define dprintf(fmt, ...)
#endif


#endif // DEVMODE_H
