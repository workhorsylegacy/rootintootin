
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c -Wall -Werror db.c -o db.o
	ar rcs db.a db.o
	gcc -g -c -Wall -Werror file_system.c -o file_system.o
	ar rcs file_system.a file_system.o
	gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre
	ar rcs regex.a regex.o
	gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o
	ar rcs shared_memory.a shared_memory.o

	ldc -g -w -of server server.d language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d rootintootin_process.d app_builder.d db.d db.a file_system.d file_system.a shared_memory.d shared_memory.a regex.d regex.a ../dornado/ioloop.d -L="-lmysqlclient" -L="-lpcre" ${CORELIB}

	ldc -g -w -of application application.d language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d rootintootin_process.d app_builder.d db.d db.a shared_memory.d shared_memory.a file_system.d file_system.a regex.d regex.a ../dornado/ioloop.d -L="-lmysqlclient" -L="-lpcre" ${CORELIB}

clean:
	rm *.o
	rm *.a

