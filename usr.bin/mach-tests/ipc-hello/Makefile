.include <src.opts.mk>
PROG= ipc-hello
SRCS= ipc-hello.c
BINDIR?= /usr/bin

MK_MAN=no
CFLAGS= -I${.CURDIR}/../../../include/apple
LDFLAGS+= -lmach -pthread

.include <bsd.prog.mk>
