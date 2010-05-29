
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c db.c -o db.o
	ar rcs db.a db.o

	gcc -g -c inotify.c -o inotify.o
	ar rcs inotify.a inotify.o

	ldc -g -of app app.d language_helper.d rootintootin.d child_process.d parent_process.d tcp_server.d http_server.d helper.d ../dornado/ioloop.d ${CORELIB}
	ldc -g -of main main.d language_helper.d helper.d rootintootin.d rootintootin_server.d http_server.d tcp_server.d ui.d parent_process.d child_process.d db.d db.a inotify.d inotify.a ../dornado/ioloop.d -L="-lmysqlclient" ${CORELIB}


